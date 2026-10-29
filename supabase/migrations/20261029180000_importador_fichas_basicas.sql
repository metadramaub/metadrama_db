-- Importador de fichas básicas. Despliegue autorizado el 29 de octubre de 2026.
-- SQL de la candidata compilada y ensayada; solo se actualizan estos comentarios.
-- No incluye la corrección de prosa ni ejecuta recálculos o importaciones.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '120s';
do $precondiciones$
begin
 if not exists(select 1 from pg_available_extensions where name='pg_jsonschema') then
  raise exception 'Falta pg_jsonschema en el servidor';
 end if;
 if to_regclass('public.obras') is null or to_regclass('public.editores') is null
  or to_regprocedure('public.auth_puede_editar_obra(uuid)') is null then
  raise exception 'No se reconoce el esquema editorial esperado';
 end if;
end;
$precondiciones$;

-- Fuente: sql/01-almacenamiento.sql
create extension if not exists pg_jsonschema with schema extensions;

alter table public.editores add column if not exists puede_importar_metrica boolean not null default false;
alter table public.obras add column if not exists tipo_ficha text not null default 'completa'
  check (tipo_ficha in ('minima','completa'));

create or replace function public.auth_puede_importar_metrica() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.editores e join public.vocabularios v on v.termino_id=e.role
    where e.user_id=auth.uid() and coalesce(e.activo,true)
      and (lower(v.termino) in ('admin','ip') or
        (lower(v.termino)='editor' and e.puede_importar_metrica)));
$$;
revoke all on function public.auth_puede_importar_metrica() from public,anon;
grant execute on function public.auth_puede_importar_metrica() to authenticated;

-- No se añade política de UPDATE directo en editores: la gestión existente usa servidor.
-- Esta RPC permite conceder la capacidad sin cambiar el rol ni abrir el laboratorio.
create or replace function public.establecer_permiso_importacion(p_editor uuid,p_permitir boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.auth_is_admin_or_ip() then raise exception using errcode='42501',message='Solo admin/IP puede conceder este permiso'; end if;
  if p_permitir is null then raise exception using errcode='22023',message='Indica el permiso'; end if;
  update public.editores set puede_importar_metrica=p_permitir where user_id=p_editor;
  if not found then raise exception using errcode='22023',message='Editor inexistente'; end if;
end;
$$;
revoke all on function public.establecer_permiso_importacion(uuid,boolean) from public,anon;
grant execute on function public.establecer_permiso_importacion(uuid,boolean) to authenticated;

create table if not exists public.importaciones_metricas (
  importacion_id uuid primary key default gen_random_uuid(),
  obra_id uuid not null references public.obras on delete cascade,
  peticion_id uuid not null,
  importado_por uuid not null references public.editores(user_id),
  importado_en timestamptz not null default now(),
  autor_id uuid not null references public.autores,
  genero_id uuid not null references public.vocabularios(termino_id),
  entrada_original jsonb not null check (jsonb_typeof(entrada_original)='object'),
  datos_confirmados jsonb not null check (datos_confirmados->>'esquema'='versologia-ficha-minima/0.2'),
  -- Hash del texto de JSONB producido por PostgreSQL, diferente del hash canónico local.
  sha256_jsonb text not null check (sha256_jsonb ~ '^[0-9a-f]{64}$'),
  coincidencias_revisadas uuid[] not null default '{}',
  usada_en_corpus boolean not null default true,
  unique (importado_por,peticion_id)
);
alter table public.importaciones_metricas add column if not exists coincidencias_revisadas uuid[] not null default '{}';
create unique index if not exists una_importacion_metrica_vigente_por_obra
  on public.importaciones_metricas(obra_id) where usada_en_corpus;

create table if not exists public.metrica_minima_secuencias (
  secuencia_id uuid primary key references public.secuencias_metricas on delete cascade,
  importacion_id uuid not null references public.importaciones_metricas on delete cascade,
  segmento_ref text not null,
  forma_id uuid references public.formas_metricas,
  arquitectura_id uuid references public.arquitecturas_forma,
  segmentacion text not null check (segmentacion in ('provisional','confirmada')),
  datos_minimos jsonb not null check (jsonb_typeof(datos_minimos)='object'),
  unique (importacion_id,segmento_ref),
  check (arquitectura_id is null or forma_id is not null)
);

create or replace function public.proteger_copia_importacion() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (to_jsonb(new)-'usada_en_corpus') is distinct from (to_jsonb(old)-'usada_en_corpus') then
    raise exception using errcode='23514',message='La copia confirmada es inmutable; una corrección necesita otra importación';
  end if;
  return new;
end;
$$;
drop trigger if exists copia_importacion_inmutable on public.importaciones_metricas;
create trigger copia_importacion_inmutable before update on public.importaciones_metricas
  for each row execute function public.proteger_copia_importacion();

create or replace function public.auth_puede_consultar_importacion(p_obra uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.auth_puede_importar_metrica() or exists (
    select 1 from public.obras o join public.editores e on e.user_id=auth.uid()
    where o.obra_id=p_obra and o.editor_asignado=e.user_id and coalesce(e.activo,true));
$$;
revoke all on function public.auth_puede_consultar_importacion(uuid) from public,anon;
grant execute on function public.auth_puede_consultar_importacion(uuid) to authenticated;

alter table public.importaciones_metricas enable row level security;
alter table public.metrica_minima_secuencias enable row level security;
revoke all on public.importaciones_metricas,public.metrica_minima_secuencias from public,anon,authenticated;
grant select on public.importaciones_metricas,public.metrica_minima_secuencias to authenticated;
drop policy if exists importaciones_consulta on public.importaciones_metricas;
create policy importaciones_consulta on public.importaciones_metricas for select to authenticated
  using (public.auth_puede_consultar_importacion(obra_id));
drop policy if exists metrica_minima_consulta on public.metrica_minima_secuencias;
create policy metrica_minima_consulta on public.metrica_minima_secuencias for select to authenticated
  using (exists (select 1 from public.importaciones_metricas i where i.importacion_id=metrica_minima_secuencias.importacion_id));

-- Las políticas de obras actuales se combinan con OR: una nueva permisiva no cerraría el acceso.
drop policy if exists obras_minimas_limite_consulta on public.obras;
create policy obras_minimas_limite_consulta on public.obras as restrictive for select to authenticated
  using (tipo_ficha='completa' or public.auth_puede_consultar_importacion(obra_id));
drop policy if exists obras_minimas_no_anon on public.obras;
create policy obras_minimas_no_anon on public.obras as restrictive for select to anon
  using (tipo_ficha='completa');

-- La capacidad permite leer la estructura mínima, sin dar permiso de escritura ni v2.
drop policy if exists jornadas_importadas_consulta on public.jornadas;
create policy jornadas_importadas_consulta on public.jornadas for select to authenticated
  using (exists (select 1 from public.obras o where o.obra_id=jornadas.obra_id and o.tipo_ficha='minima')
    and public.auth_puede_importar_metrica());
drop policy if exists secuencias_importadas_consulta on public.secuencias_metricas;
create policy secuencias_importadas_consulta on public.secuencias_metricas for select to authenticated
  using (exists (select 1 from public.obras o where o.obra_id=secuencias_metricas.obra_id and o.tipo_ficha='minima')
    and public.auth_puede_importar_metrica());

create or replace function public.auth_respeta_limite_minima(p_obra uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.obras o where o.obra_id=p_obra and
    (o.tipo_ficha='completa' or public.auth_puede_consultar_importacion(o.obra_id)));
$$;
revoke all on function public.auth_respeta_limite_minima(uuid) from public;
grant execute on function public.auth_respeta_limite_minima(uuid) to authenticated,anon;
-- También limita al antiguo rol revisor, cuyas políticas ven cualquier estructura.
drop policy if exists jornadas_minimas_limite on public.jornadas;
create policy jornadas_minimas_limite on public.jornadas as restrictive for select to authenticated,anon
  using (public.auth_respeta_limite_minima(obra_id));
drop policy if exists secuencias_minimas_limite on public.secuencias_metricas;
create policy secuencias_minimas_limite on public.secuencias_metricas as restrictive for select to authenticated,anon
  using (public.auth_respeta_limite_minima(obra_id));

create or replace function public.impedir_publicacion_minima() returns trigger
language plpgsql set search_path = '' as $$
begin
  if TG_OP='UPDATE' and new.tipo_ficha is distinct from old.tipo_ficha then
    raise exception using errcode='23514',message='El cambio a ficha detallada requiere su operación específica';
  end if;
  if new.tipo_ficha='minima' and (coalesce(new.visible_publico,false) or not exists (
    select 1 from public.vocabularios v where v.termino_id=new.estado
      and v.categoria='estado' and v.termino='borrador')) then
    raise exception using errcode='23514',message='Una ficha mínima conserva borrador técnico y no se publica';
  end if;
  return new;
end;
$$;
drop trigger if exists impedir_publicacion_minima on public.obras;
create trigger impedir_publicacion_minima before insert or update on public.obras
  for each row execute function public.impedir_publicacion_minima();

-- Fuente: sql/02-esquema-documento.sql
-- Contratos generados con generar-esquema-sql.mjs.
create or replace function public.esquema_documento_minimo() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-ficha-minima/0.2"},"obra_ref":{"type":"string","minLength":1},"metadatos":{"type":"object","properties":{"titulo":{"type":"string","minLength":1},"autor_nombre":{"type":"string","minLength":1},"genero":{"type":"string","minLength":1},"edicion_base":{"type":"string","minLength":1},"fecha_inicio":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fecha_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fuente_fecha":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fundamento_autoria":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","minLength":1}}},"required":["titulo","autor_nombre","genero","edicion_base","fecha_inicio","fecha_fin","fuente_fecha","fundamento_autoria","observaciones"],"additionalProperties":false},"jornadas":{"minItems":1,"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"rotulo_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["numero","v_ini","v_fin","rotulo_literal"],"additionalProperties":false}},"segmentos":{"minItems":1,"type":"array","items":{"type":"object","properties":{"ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"segmentacion":{"type":"string","enum":["provisional","confirmada"]},"origen":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"denominacion_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fuente_id":{"type":"string","minLength":1},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","minLength":1}}},"required":["tramo_ref","denominacion_literal","fuente_id","pagina","notas_ref"],"additionalProperties":false},"identificacion":{"anyOf":[{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false},{"type":"null"}]},"candidatas":{"type":"array","items":{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false}},"regla_id":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"detalles_fuente":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"estructura"},"tipo_seccion":{"type":"string","const":"remate"},"nombre":{"type":"string","minLength":1},"n_versos":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"posicion":{"type":"string","const":"final"}},"required":["literal","dimension","tipo_seccion","nombre","n_versos","posicion"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"rasgo_slug":{"type":"string","minLength":1},"valor_slug":{"type":"string","minLength":1}},"required":["rasgo_slug","valor_slug"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"asonancia"}},"required":["literal"],"additionalProperties":false}]}},"desviaciones":{"type":"array","items":{"type":"object","properties":{"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"dimension":{"type":"string","enum":["metro","estructura"]},"relacion_norma":{"type":"string","enum":["menor_que_norma","mayor_que_norma","sobra","falta","otra"]},"metro_observado_slug":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"texto_fuente":{"type":"string","minLength":1},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["v_ini","v_fin","dimension","relacion_norma","nota_ref","texto_fuente","nota"],"additionalProperties":false}}},"required":["ref","v_ini","v_fin","segmentacion","origen","identificacion","candidatas","regla_id","nota","detalles_fuente","desviaciones"],"additionalProperties":false}},"procedencia":{"type":"object","properties":{"reglas_version":{"type":"string","minLength":1},"catalogo_revision":{"type":"integer","minimum":0,"maximum":9007199254740991},"extraccion_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},"entradas_sha256":{"type":"object","propertyNames":{"type":"string","minLength":1},"additionalProperties":{"type":"string","pattern":"^[a-f0-9]{64}$"}}},"required":["reglas_version","catalogo_revision","extraccion_sha256","entradas_sha256"],"additionalProperties":false}},"required":["esquema","obra_ref","metadatos","jornadas","segmentos","procedencia"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_documento_minimo() from public,anon,authenticated;

create or replace function public.esquema_extraccion_minima() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-extraccion/0.1"},"obra_ref":{"type":"string","pattern":"\\S"},"estado_revision":{"type":"string","const":"borrador_ia"},"revision_humana":{"type":"object","properties":{"responsable":{"type":"null"},"fecha":{"type":"null"},"resultado":{"type":"string","const":"pendiente"}},"required":["responsable","fecha","resultado"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"fecha":{"anyOf":[{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},{"type":"null"}]},"procedimiento":{"type":"string","enum":["lectura_visual_asistida","ejecucion_prompt"]},"generador":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"prompt_version":{"type":"string","pattern":"\\S"},"ensayo_controlado":{"type":"boolean"}},"required":["fecha","procedimiento","generador","modelo","prompt_version","ensayo_controlado"],"additionalProperties":false},"metadatos":{"anyOf":[{"type":"object","properties":{"titulo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"genero_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fecha_inicio":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fecha_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_fecha":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"edicion_base":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","pattern":"\\S"}},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria_procedencia":{"type":"string","pattern":"\\S"},"bloque_docx_literal":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["titulo","autoria","genero_literal","fecha_inicio","fecha_fin","fuente_fecha","edicion_base","observaciones","fuente_id"],"additionalProperties":false},{"type":"null"}]},"jornadas":{"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"rotulo_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]}},"required":["numero","rotulo_literal"],"additionalProperties":false}},"tramos":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"jornada":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["id","jornada","v_ini","v_fin","denominacion_literal","n_versos_fuente","fuente_id","pagina","notas_ref"],"additionalProperties":false}},"notas":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"marca":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"texto_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["id","marca","texto_literal","fuente_id","pagina","tramos_ref","v_ini","v_fin"],"additionalProperties":false}},"resumen_fuente":{"type":"array","items":{"type":"object","properties":{"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"porcentaje_literal":{"anyOf":[{"type":"string","pattern":"^\\d+(,\\d+)?$"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["denominacion_literal","n_versos_fuente","porcentaje_literal","fuente_id","pagina"],"additionalProperties":false}},"incidencias":{"type":"array","items":{"type":"object","properties":{"tipo":{"type":"string","pattern":"\\S"},"descripcion":{"type":"string","pattern":"\\S"},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["tipo","descripcion","fuente_id","tramos_ref"],"additionalProperties":false}}},"required":["esquema","obra_ref","estado_revision","revision_humana","procedencia","metadatos","jornadas","tramos","notas","resumen_fuente","incidencias"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_extraccion_minima() from public,anon,authenticated;

-- Fuente: sql/03-guardar.sql
create or replace function public.comprobar_destino_minimo(p_destino jsonb) returns void
language plpgsql stable security definer set search_path = '' as $$
declare v_forma uuid;
begin
  if p_destino is null or p_destino='null'::jsonb then return; end if;
  select forma_id into v_forma from public.formas_metricas
    where slug=p_destino->>'forma_slug' and activo;
  if v_forma is null then raise exception using errcode='23514',message='Forma desconocida o inactiva'; end if;
  if p_destino->>'arquitectura_slug' is not null and not exists (
    select 1 from public.arquitecturas_forma a where a.forma_id=v_forma and a.activo
      and a.slug=p_destino->>'arquitectura_slug') then
    raise exception using errcode='23514',message='Arquitectura ajena a la forma, desconocida o inactiva';
  end if;
end;
$$;
revoke all on function public.comprobar_destino_minimo(jsonb) from public,anon,authenticated;

create or replace function public.normalizar_titulo_importacion(p_titulo text) returns text
language sql immutable set search_path = '' as $$
  select btrim(regexp_replace(translate(lower(coalesce(p_titulo,'')),
    'áéíóúüñ','aeiouun'),'[^[:alnum:]]+',' ','g'));
$$;
revoke all on function public.normalizar_titulo_importacion(text) from public,anon,authenticated;

-- Solo metadatos para resolver identidad; no abre el editor ni las fichas detalladas.
create or replace function public.coincidencias_importacion_metrica(p_titulo text)
returns table(obra_id uuid,titulo text,tipo_ficha text,autores text[])
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede consultar coincidencias de importación';
  end if;
  return query select o.obra_id,o.titulo,o.tipo_ficha,coalesce((
    select array_agg(distinct au.nombre_completo::text order by au.nombre_completo::text)
    from public.atribuciones a join public.atribucion_autores aa on aa.atribucion_id=a.atribucion_id
    join public.autores au on au.autor_id=aa.autor_id where a.obra_id=o.obra_id
  ),array[]::text[])
  from public.obras o
  where public.normalizar_titulo_importacion(p_titulo)<>'' and exists (
    select 1 from unnest(array[o.titulo] || coalesce(o.variantes_titulo,array[]::text[])) t(valor)
    where public.normalizar_titulo_importacion(t.valor)=public.normalizar_titulo_importacion(p_titulo))
  order by lower(o.titulo),o.obra_id;
end;
$$;
revoke all on function public.coincidencias_importacion_metrica(text) from public,anon;
grant execute on function public.coincidencias_importacion_metrica(text) to authenticated;

-- El borrador anterior nunca se desplegó. Evita sobrecargas ambiguas para PostgREST.
drop function if exists public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb);
create or replace function public.guardar_ficha_minima(
  p_peticion uuid,p_autor uuid,p_datos jsonb,p_entrada_original jsonb,
  p_coincidencias_revisadas uuid[] default '{}'
) returns jsonb language plpgsql security definer set search_path = '' as $$
<<importar>>
declare
  v_actor uuid:=auth.uid(); v_obra uuid:=gen_random_uuid(); v_importacion uuid:=gen_random_uuid();
  v_grupo uuid:=gen_random_uuid(); v_atribucion uuid:=gen_random_uuid(); v_secuencia uuid;
  v_anterior public.importaciones_metricas%rowtype;
  v_genero uuid; v_borrador uuid; v_tradicional uuid; v_unica uuid; v_individual uuid;
  v_meta jsonb; v_fila jsonb; v_candidata jsonb; v_detalle jsonb; v_desviacion jsonb;
  v_forma uuid; v_arquitectura uuid; v_inicio integer; v_fin integer;
  v_prev integer; v_num integer; v_total bigint:=0; v_ahora timestamptz:=now();
  v_revisadas uuid[]; v_coincidencias uuid[];
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede importar métrica';
  end if;
  if p_peticion is null or p_autor is null or p_datos is null or p_entrada_original is null
    or jsonb_typeof(p_entrada_original)<>'object' or pg_column_size(p_entrada_original)>10485760
    or pg_column_size(p_datos)>10485760 then
    raise exception using errcode='22023',message='Petición incompleta o documento demasiado grande';
  end if;
  select coalesce(array_agg(distinct id order by id),array[]::uuid[]) into v_revisadas
    from unnest(coalesce(p_coincidencias_revisadas,array[]::uuid[])) ids(id) where id is not null;
  -- La misma clave se serializa incluso entre dos transacciones simultáneas.
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text||':'||p_peticion::text,0));
  select * into v_anterior from public.importaciones_metricas
    where importado_por=v_actor and peticion_id=p_peticion;
  if found then
    if v_anterior.datos_confirmados is distinct from p_datos or v_anterior.autor_id<>p_autor
      or v_anterior.entrada_original is distinct from p_entrada_original
      or v_anterior.coincidencias_revisadas is distinct from v_revisadas then
      raise exception using errcode='23505',message='La petición ya se usó con otros datos';
    end if;
    return jsonb_build_object('obra_id',v_anterior.obra_id,'importacion_id',v_anterior.importacion_id,'repetida',true);
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos) then
    raise exception using errcode='23514',message='El documento no cumple el contrato de ficha mínima';
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_extraccion_minima(),p_entrada_original)
    or (p_entrada_original->>'obra_ref') is distinct from (p_datos->>'obra_ref') then
    raise exception using errcode='23514',message='Falta la extracción original de esta obra';
  end if;
  v_meta:=p_datos->'metadatos';
  if btrim(v_meta->>'titulo')='' or btrim(v_meta->>'edicion_base')='' then
    raise exception using errcode='23514',message='Título y edición no pueden estar vacíos';
  end if;
  if not exists (select 1 from public.autores where autor_id=p_autor
    and btrim(nombre_completo)=btrim(v_meta->>'autor_nombre')) then
    raise exception using errcode='23514',message='Selecciona un autor del catálogo y su nombre vigente';
  end if;
  select termino_id into v_genero from public.vocabularios
    where categoria='genero' and termino=v_meta->>'genero' and coalesce(activo,true);
  select termino_id into v_borrador from public.vocabularios where categoria='estado' and termino='borrador';
  select termino_id into v_tradicional from public.vocabularios where categoria='tipo_atribucion' and termino='tradicional';
  select termino_id into v_unica from public.vocabularios where categoria='modalidad_atribucion' and termino='unica';
  select termino_id into v_individual from public.vocabularios where categoria='composicion_autoria' and termino='individual';
  if v_genero is null or v_borrador is null or v_tradicional is null or v_unica is null or v_individual is null then
    raise exception using errcode='23514',message='Faltan referencias del vocabulario';
  end if;
  if (v_meta->>'fecha_inicio')::integer>(v_meta->>'fecha_fin')::integer then
    raise exception using errcode='23514',message='Fechas invertidas';
  end if;
  -- Un título coincidente pide revisión; no impone identidad, ni siquiera con el mismo autor.
  perform pg_advisory_xact_lock(hashtextextended(public.normalizar_titulo_importacion(v_meta->>'titulo'),1));
  select coalesce(array_agg(c.obra_id order by c.obra_id),array[]::uuid[]) into v_coincidencias
    from public.coincidencias_importacion_metrica(v_meta->>'titulo') c;
  if v_coincidencias is distinct from v_revisadas then
    raise exception using errcode='23505',message='Revisa las coincidencias antes de confirmar que se trata de otra obra';
  end if;
  v_prev:=null; v_num:=0;
  for v_fila in select value from jsonb_array_elements(p_datos->'jornadas') loop
    v_num:=v_num+1; v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if (v_fila->>'numero')::integer<>v_num or v_fin<v_inicio
      or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) then
      raise exception using errcode='23514',message='Jornadas desordenadas, discontinuas o con rangos invertidos';
    end if;
    v_prev:=v_fin;
  end loop;
  if (p_datos#>>'{segmentos,0,v_ini}')::integer<>(p_datos#>>'{jornadas,0,v_ini}')::integer or
    (p_datos->'segmentos'->-1->>'v_fin')::integer<>v_prev then
    raise exception using errcode='23514',message='Jornadas y segmentos no cubren el mismo rango';
  end if;
  if (select count(*)<>count(distinct value->>'ref') from jsonb_array_elements(p_datos->'segmentos')) then
    raise exception using errcode='23514',message='Referencias de segmento repetidas';
  end if;

  insert into public.obras(obra_id,titulo,estado,tipo_ficha,visible_publico,genero_id,
    edicion,fecha_inicio_trad,fecha_fin_trad,fuente_fecha,observaciones)
  values(v_obra,v_meta->>'titulo',v_borrador,'minima',false,v_genero,v_meta->>'edicion_base',
    (v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha',
    (select string_agg(value,E'\n' order by ord) from jsonb_array_elements_text(v_meta->'observaciones') with ordinality as o(value,ord)));
  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id) values(v_grupo,v_obra);
  insert into public.atribuciones(atribucion_id,obra_id,grupo_atribucion_id,tipo_atribucion_id,
    modalidad_atribucion_id,composicion_autoria_id,perfil_metrico,fuente_autoria)
  values(v_atribucion,v_obra,v_grupo,v_tradicional,v_unica,v_individual,true,v_meta->>'fundamento_autoria');
  insert into public.atribucion_autores(atribucion_id,autor_id,orden) values(v_atribucion,p_autor,1);
  insert into public.atribucion_evidencias(atribucion_id,tipo_atribucion_id,fuente_autoria,orden)
    values(v_atribucion,v_tradicional,v_meta->>'fundamento_autoria',1);
  insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin)
    select v_obra,(j->>'numero')::integer,(j->>'v_ini')::integer,(j->>'v_fin')::integer
    from jsonb_array_elements(p_datos->'jornadas') as r(j);
  insert into public.importaciones_metricas(importacion_id,obra_id,peticion_id,importado_por,
    importado_en,autor_id,genero_id,entrada_original,datos_confirmados,sha256_jsonb,coincidencias_revisadas)
  values(v_importacion,v_obra,p_peticion,v_actor,v_ahora,p_autor,v_genero,
    p_entrada_original,p_datos,encode(extensions.digest(convert_to(p_datos::text,'UTF8'),'sha256'),'hex'),v_revisadas);

  v_prev:=null;
  for v_fila in select value from jsonb_array_elements(p_datos->'segmentos') loop
    v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if v_fin<v_inicio or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) or not exists (
      select 1 from public.jornadas j where j.obra_id=v_obra and v_inicio>=j.v_ini
        and importar.v_fin<=j.v_fin) then
      raise exception using errcode='23514',message='Segmentos discontinuos, invertidos o fuera de jornada';
    end if;
    v_prev:=v_fin; v_total:=v_total+v_fin::bigint-v_inicio+1;
    if not exists (select 1 from jsonb_array_elements(p_entrada_original->'tramos') as r(t)
      where t->>'id'=v_fila#>>'{origen,tramo_ref}' and t->>'fuente_id'=v_fila#>>'{origen,fuente_id}'
        and (t->>'denominacion_literal') is not distinct from (v_fila#>>'{origen,denominacion_literal}')
        and (t->>'v_ini')::integer<=v_inicio and (t->>'v_fin')::integer>=importar.v_fin) then
      raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
    end if;
    if exists (select 1 from jsonb_array_elements_text(v_fila#>'{origen,notas_ref}') as r(ref)
      where not exists (select 1 from jsonb_array_elements(p_entrada_original->'notas') as n(nota)
        where nota->>'id'=ref and nota->'tramos_ref' ? (v_fila#>>'{origen,tramo_ref}'))) then
      raise exception using errcode='23514',message='Nota sin correspondencia con el tramo original';
    end if;
    perform public.comprobar_destino_minimo(v_fila->'identificacion');
    v_forma:=null; v_arquitectura:=null;
    if v_fila->'identificacion'<>'null'::jsonb then
      select forma_id into v_forma from public.formas_metricas where slug=v_fila#>>'{identificacion,forma_slug}';
      select arquitectura_id into v_arquitectura from public.arquitecturas_forma where forma_id=v_forma
        and slug=v_fila#>>'{identificacion,arquitectura_slug}';
    end if;
    if v_arquitectura is not null and jsonb_array_length(v_fila->'candidatas')>0 then
      raise exception using errcode='23514',message='Una arquitectura identificada no mantiene candidatas';
    end if;
    if (select count(*)<>count(distinct value) from jsonb_array_elements(v_fila->'candidatas')) then
      raise exception using errcode='23514',message='Candidatas repetidas';
    end if;
    for v_candidata in select value from jsonb_array_elements(v_fila->'candidatas') loop
      perform public.comprobar_destino_minimo(v_candidata);
      if v_forma is not null and ((v_candidata->>'forma_slug') is distinct from
        (v_fila#>>'{identificacion,forma_slug}') or v_candidata->>'arquitectura_slug' is null) then
        raise exception using errcode='23514',message='Candidata incompatible con la forma identificada';
      end if;
    end loop;
    for v_detalle in select value from jsonb_array_elements(v_fila->'detalles_fuente') loop
      if v_detalle ? 'rasgo_slug' and (v_forma is null or
        (v_detalle->>'rasgo_slug'='distico_final' and v_fin::bigint-v_inicio+1<2) or not exists (
          select 1 from public.rasgos_metricos r join public.rasgo_valores rv using(rasgo_id)
          join public.arquitectura_rasgos ar using(rasgo_id)
          join public.arquitecturas_forma a using(arquitectura_id)
          where r.slug=v_detalle->>'rasgo_slug' and rv.slug=v_detalle->>'valor_slug'
            and r.activo and rv.activo and a.activo and a.forma_id=v_forma
            and (ar.valor_id is null or ar.valor_id=rv.valor_id)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Rasgo o valor ajeno a la forma y arquitectura conocidas';
      end if;
      if v_detalle->>'tipo_seccion'='remate' and (
        (v_detalle->>'n_versos')::integer>v_fin::bigint-v_inicio+1 or v_forma is null or not exists (
          select 1 from public.estructuras_secciones s join public.arquitecturas_forma a using(arquitectura_id)
          where a.forma_id=v_forma and a.activo and s.tipo_seccion=v_detalle->>'tipo_seccion'
            and (s.versos_min is null or (v_detalle->>'n_versos')::integer>=s.versos_min)
            and (s.versos_max is null or (v_detalle->>'n_versos')::integer<=s.versos_max)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Detalle revisado sin contexto de catálogo o fuera del pasaje';
      end if;
    end loop;
    for v_desviacion in select value from jsonb_array_elements(v_fila->'desviaciones') loop
      if (v_desviacion->>'v_ini')::integer<v_inicio or (v_desviacion->>'v_fin')::integer>v_fin
        or (v_desviacion->>'v_fin')::integer<(v_desviacion->>'v_ini')::integer
        or not (v_fila#>'{origen,notas_ref}' ? (v_desviacion->>'nota_ref'))
        or not exists (select 1 from jsonb_array_elements(p_entrada_original->'notas') n
          where n->>'id'=v_desviacion->>'nota_ref'
            and n->>'texto_literal'=v_desviacion->>'texto_fuente')
        or (v_desviacion->>'dimension'='metro' and v_desviacion->>'relacion_norma' in ('sobra','falta'))
        or (v_desviacion->>'dimension'='estructura' and v_desviacion->>'relacion_norma' in ('menor_que_norma','mayor_que_norma'))
        or (v_desviacion->>'metro_observado_slug' is not null and not exists (
          select 1 from public.metros where slug=v_desviacion->>'metro_observado_slug' and activo)) then
        raise exception using errcode='23514',message='Desviación fuera del pasaje o sin referencia válida';
      end if;
    end loop;
    v_secuencia:=gen_random_uuid();
    insert into public.secuencias_metricas(secuencia_id,obra_id,v_ini,v_fin,n_versos)
      values(v_secuencia,v_obra,v_inicio,v_fin,v_fin-v_inicio+1);
    insert into public.metrica_minima_secuencias(secuencia_id,importacion_id,segmento_ref,forma_id,
      arquitectura_id,segmentacion,datos_minimos)
    values(v_secuencia,v_importacion,v_fila->>'ref',v_forma,v_arquitectura,v_fila->>'segmentacion',
      v_fila - array['ref','v_ini','v_fin','identificacion','segmentacion']);
  end loop;
  update public.obras set total_versos=v_total::integer where obra_id=v_obra;
  return jsonb_build_object('obra_id',v_obra,'importacion_id',v_importacion,'repetida',false);
end;
$$;
revoke all on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) from public,anon;
grant execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) to authenticated;

-- Fuente: sql/04-consulta.sql
create or replace function public.capacidades_importador_metrico() returns jsonb
language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('puede_importar',public.auth_puede_importar_metrica(),
 'guardado_disponible',public.auth_puede_importar_metrica());
$$;
revoke all on function public.capacidades_importador_metrico() from public,anon;
grant execute on function public.capacidades_importador_metrico() to authenticated;

create or replace function public.listar_fichas_basicas(p_desde integer default 0)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='La sesión no puede consultar fichas básicas';
 end if;
 if p_desde is null or p_desde<0 then raise exception using errcode='22023',message='Página inválida'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(f)), '[]'::jsonb) from (
  select i.importacion_id,i.obra_id,i.datos_confirmados#>>'{metadatos,titulo}' as titulo,
   i.datos_confirmados#>>'{metadatos,autor_nombre}' as autor_nombre,
   e.nombre_completo::text as importado_por,i.importado_en
  from public.importaciones_metricas i join public.obras o using(obra_id)
  join public.editores e on e.user_id=i.importado_por
  where o.tipo_ficha='minima' and i.usada_en_corpus
  order by i.importado_en desc,i.importacion_id limit 51 offset p_desde
 ) f);
end;
$$;
revoke all on function public.listar_fichas_basicas(integer) from public,anon;
grant execute on function public.listar_fichas_basicas(integer) to authenticated;

create or replace function public.consultar_importacion_metrica(p_importacion uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('importacion_id',i.importacion_id,'obra_id',i.obra_id,
  'importado_por',e.nombre_completo,'importado_en',i.importado_en,
  'datos_confirmados',i.datos_confirmados,'entrada_original',i.entrada_original)
 from public.importaciones_metricas i join public.editores e on e.user_id=i.importado_por
 where i.importacion_id=p_importacion and public.auth_puede_consultar_importacion(i.obra_id);
$$;
revoke all on function public.consultar_importacion_metrica(uuid) from public,anon;
grant execute on function public.consultar_importacion_metrica(uuid) to authenticated;

create or replace function public.localizar_importacion_metrica(p_obra uuid)
returns uuid language sql stable security definer set search_path = '' as $$
 select i.importacion_id from public.importaciones_metricas i
 where i.obra_id=p_obra and public.auth_puede_consultar_importacion(i.obra_id)
 order by i.usada_en_corpus desc,i.importado_en desc,i.importacion_id limit 1;
$$;
revoke all on function public.localizar_importacion_metrica(uuid) from public,anon;
grant execute on function public.localizar_importacion_metrica(uuid) to authenticated;

-- Fuente: sql/05-aislamiento.sql

create or replace function public.auth_obra_es_detallada(p_obra uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.obras where obra_id=p_obra and tipo_ficha='completa');
$$;
revoke all on function public.auth_obra_es_detallada(uuid) from public,anon;
grant execute on function public.auth_obra_es_detallada(uuid) to authenticated;

create or replace function public.auth_puede_editar_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists (
  select 1 from public.obras o
  join public.editores e on e.user_id=auth.uid()
  join public.vocabularios vr on vr.termino_id=e.role
  where o.obra_id=p_obra_id and o.tipo_ficha='completa' and coalesce(e.activo,true)
   and (lower(vr.termino) in ('admin','ip')
     or (lower(vr.termino)='editor' and o.editor_asignado=e.user_id)));
$$;

-- Las políticas permisivas antiguas de admin/IP se combinan con OR. Este límite es AND.
-- La operación de importación, SECURITY DEFINER, sigue pudiendo crear la estructura inicial.
do $$
declare t text; operacion text; expresion text;
begin
 for t,expresion in values
  ('obras', 'tipo_ficha=''completa'''),
  ('jornadas','public.auth_obra_es_detallada(obra_id)'),
  ('secuencias_metricas','public.auth_obra_es_detallada(obra_id)'),
  ('cuadros','exists(select 1 from public.jornadas j where j.jornada_id=cuadros.jornada_id and public.auth_obra_es_detallada(j.obra_id))')
 loop
  foreach operacion in array array['insert','update','delete'] loop
   execute format('drop policy if exists %I on public.%I',t||'_basicas_'||operacion,t);
   execute format('create policy %I on public.%I as restrictive for %s to authenticated %s',
    t||'_basicas_'||operacion,t,operacion,
    case operacion when 'insert' then 'with check ('||expresion||')'
     when 'delete' then 'using ('||expresion||')'
     else 'using ('||expresion||') with check ('||expresion||')' end);
  end loop;
 end loop;
end;
$$;

-- Una llamada directa a guardar_anotacion_metrica también queda protegida por el predicado.
-- El trigger cubre además INSERT directo con las políticas generales de admin/IP.
create or replace function public.impedir_v2_en_basica() returns trigger
language plpgsql set search_path = '' as $$
begin
 if new.secuencia_id is not null and exists (
  select 1 from public.secuencias_metricas s join public.obras o using(obra_id)
  where s.secuencia_id=new.secuencia_id and o.tipo_ficha='minima') then
  raise exception using errcode='23514',message='La métrica de una ficha básica se registra mediante el importador';
 end if;
 return new;
end;
$$;
drop trigger if exists impedir_v2_en_basica on public.anotaciones_metricas;
create trigger impedir_v2_en_basica before insert or update on public.anotaciones_metricas
 for each row execute function public.impedir_v2_en_basica();

-- Adaptaciones pequeñas sobre las definiciones existentes, preservando el cálculo detallado.
-- Cada ancla debe ser única: un cambio de implementación exige revisar el borrador.
do $adaptacion$
declare nombre text; ancla text; cambio text; definicion text; firma regprocedure;
begin
 for nombre,ancla,cambio in values
  ('public.formas_de_la_obra(uuid)', 'where sm.obra_id = p_obra_id',
   'where sm.obra_id = p_obra_id and public.auth_obra_es_detallada(sm.obra_id) /* importador:aislado */'),
  ('public.perfil_metrico_unidades()', 'left join public.jornadas j on j.jornada_id = g.jornada_id;',
   'left join public.jornadas j on j.jornada_id = g.jornada_id where public.auth_obra_es_detallada(coalesce(g.obra_id,j.obra_id)); /* importador:aislado */'),
  ('public.gestionar_asignaciones_lote(text,uuid,jsonb)', 'select coalesce(array_agg(r.revisor_id order by r.revisor_id), ''{}''::uuid[]) into v_anteriores',
   'if v_obra.tipo_ficha=''minima'' then raise exception using errcode=''42501'',message=''La asignación de una básica requiere el recorrido de elaboración detallada''; end if; /* importador:aislado */ select coalesce(array_agg(r.revisor_id order by r.revisor_id), ''{}''::uuid[]) into v_anteriores')
 loop
  firma:=nombre::regprocedure;
  definicion:=pg_get_functiondef(firma);
  if position('importador:aislado' in definicion)>0 then continue; end if;
  if (length(definicion)-length(replace(definicion,ancla,'')))/length(ancla) <> 1 then
   raise exception 'Revisar adaptación de %: el ancla ha cambiado',nombre;
  end if;
  execute replace(definicion,ancla,cambio);
 end loop;
 for nombre in select unnest(array[
  'public.recompute_obra_resumen_metricas(uuid)',
  'public.recompute_obra_resumen_estructura(uuid)',
  'public.recompute_artefactos_obra(uuid)',
  'public.analisis_obra_publico_json(uuid)',
  'public.ficha_publica_base_json(uuid,boolean)',
  'public.ficha_publica_dominio_json(uuid,boolean)',
  'public.perfil_artefacto_obra_rango(uuid,integer,integer,text)'])
 loop
  definicion:=pg_get_functiondef(nombre::regprocedure);
  if position('importador:aislado' in definicion)>0 then continue; end if;
  -- La primera entrada al cuerpo PL/pgSQL; no se modifican consultas ni denominadores.
  if position(E'begin\n' in definicion)=0 then raise exception 'Revisar cuerpo de %',nombre; end if;
  definicion:=regexp_replace(definicion,E'begin\n',E'begin\n'
    ||' if exists(select 1 from public.obras where obra_id=p_obra_id and tipo_ficha=''minima'') then'
    ||E'\n  raise exception using errcode=''42501'',message=''La ficha básica requiere el productor combinado, todavía no habilitado'';'
    ||E'\n end if; /* importador:aislado */\n');
  execute definicion;
 end loop;
end;
$adaptacion$;

notify pgrst, 'reload schema';
commit;
