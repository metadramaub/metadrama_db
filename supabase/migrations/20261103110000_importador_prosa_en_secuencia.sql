-- Prosa sin extensión dentro de secuencias mínimas; conserva las importaciones existentes.
begin;
-- GENERADO con generar-esquema-sql.mjs. BORRADOR: no aplicar a la DB compartida.
create or replace function public.esquema_documento_minimo() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-ficha-minima/0.2"},"obra_ref":{"type":"string","minLength":1},"metadatos":{"type":"object","properties":{"titulo":{"type":"string","minLength":1},"autor_nombre":{"type":"string","minLength":1},"genero":{"type":"string","minLength":1},"edicion_base":{"type":"string","minLength":1},"fecha_inicio":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fecha_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fuente_fecha":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fundamento_autoria":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","minLength":1}}},"required":["titulo","autor_nombre","genero","edicion_base","fecha_inicio","fecha_fin","fuente_fecha","fundamento_autoria","observaciones"],"additionalProperties":false},"jornadas":{"minItems":1,"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"rotulo_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["numero","v_ini","v_fin","rotulo_literal"],"additionalProperties":false}},"segmentos":{"minItems":1,"type":"array","items":{"type":"object","properties":{"ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"segmentacion":{"type":"string","enum":["provisional","confirmada"]},"origen":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"denominacion_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fuente_id":{"type":"string","minLength":1},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","minLength":1}},"tramos_ref":{"minItems":2,"type":"array","items":{"type":"string","minLength":1}}},"required":["tramo_ref","denominacion_literal","fuente_id","pagina","notas_ref"],"additionalProperties":false},"identificacion":{"anyOf":[{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false},{"type":"null"}]},"candidatas":{"type":"array","items":{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false}},"regla_id":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"detalles_fuente":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"estructura"},"tipo_seccion":{"type":"string","const":"remate"},"nombre":{"type":"string","minLength":1},"n_versos":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"posicion":{"type":"string","const":"final"}},"required":["literal","dimension","tipo_seccion","nombre","n_versos","posicion"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"rasgo_slug":{"type":"string","minLength":1},"valor_slug":{"type":"string","minLength":1}},"required":["rasgo_slug","valor_slug"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"asonancia"}},"required":["literal"],"additionalProperties":false}]}},"desviaciones":{"type":"array","items":{"type":"object","properties":{"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"dimension":{"type":"string","enum":["metro","estructura"]},"relacion_norma":{"type":"string","enum":["menor_que_norma","mayor_que_norma","sobra","falta","otra"]},"metro_observado_slug":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"texto_fuente":{"type":"string","minLength":1},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["v_ini","v_fin","dimension","relacion_norma","nota_ref","texto_fuente","nota"],"additionalProperties":false}},"caracterizaciones":{"type":"array","items":{"type":"object","properties":{"termino":{"type":"string","const":"prosa"},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"tramo_ref":{"type":"string","minLength":1},"literal":{"type":"string","minLength":1}},"required":["termino","v_ini","v_fin","tramo_ref","literal"],"additionalProperties":false}}},"required":["ref","v_ini","v_fin","segmentacion","origen","identificacion","candidatas","regla_id","nota","detalles_fuente","desviaciones"],"additionalProperties":false}},"comprobacion":{"type":"object","properties":{"avisos_longitud":{"type":"array","items":{"type":"object","properties":{"segmento_ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"mensaje":{"type":"string","minLength":1}},"required":["segmento_ref","v_ini","v_fin","mensaje"],"additionalProperties":false}}},"required":["avisos_longitud"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"reglas_version":{"type":"string","minLength":1},"catalogo_revision":{"type":"integer","minimum":0,"maximum":9007199254740991},"extraccion_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},"entradas_sha256":{"type":"object","propertyNames":{"type":"string","minLength":1},"additionalProperties":{"type":"string","pattern":"^[a-f0-9]{64}$"}},"ejecucion":{"type":"object","properties":{"generador":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]}},"required":["generador","modelo","prompt_version"],"additionalProperties":false}},"required":["reglas_version","catalogo_revision","extraccion_sha256","entradas_sha256"],"additionalProperties":false}},"required":["esquema","obra_ref","metadatos","jornadas","segmentos","procedencia"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_documento_minimo() from public,anon,authenticated;

create or replace function public.esquema_extraccion_minima() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-extraccion/0.1"},"obra_ref":{"type":"string","pattern":"\\S"},"estado_revision":{"type":"string","const":"borrador_ia"},"revision_humana":{"type":"object","properties":{"responsable":{"type":"null"},"fecha":{"type":"null"},"resultado":{"type":"string","const":"pendiente"}},"required":["responsable","fecha","resultado"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"fecha":{"anyOf":[{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},{"type":"null"}]},"procedimiento":{"type":"string","enum":["lectura_visual_asistida","ejecucion_prompt"]},"generador":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"type":"string","pattern":"\\S"},"ensayo_controlado":{"type":"boolean"}},"required":["fecha","procedimiento","generador","modelo","prompt_version","ensayo_controlado"],"additionalProperties":false},"metadatos":{"anyOf":[{"type":"object","properties":{"titulo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"genero_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fecha_inicio":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fecha_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_fecha":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"edicion_base":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","pattern":"\\S"}},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria_procedencia":{"type":"string","pattern":"\\S"},"bloque_docx_literal":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["titulo","autoria","genero_literal","fecha_inicio","fecha_fin","fuente_fecha","edicion_base","observaciones","fuente_id"],"additionalProperties":false},{"type":"null"}]},"jornadas":{"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"rotulo_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]}},"required":["numero","rotulo_literal"],"additionalProperties":false}},"tramos":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"jornada":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["id","jornada","v_ini","v_fin","denominacion_literal","n_versos_fuente","fuente_id","pagina","notas_ref"],"additionalProperties":false}},"notas":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"marca":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"texto_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["id","marca","texto_literal","fuente_id","pagina","tramos_ref","v_ini","v_fin"],"additionalProperties":false}},"resumen_fuente":{"type":"array","items":{"type":"object","properties":{"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"porcentaje_literal":{"anyOf":[{"type":"string","pattern":"^\\d+(,\\d+)?$"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["denominacion_literal","n_versos_fuente","porcentaje_literal","fuente_id","pagina"],"additionalProperties":false}},"incidencias":{"type":"array","items":{"type":"object","properties":{"tipo":{"type":"string","pattern":"\\S"},"descripcion":{"type":"string","pattern":"\\S"},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["tipo","descripcion","fuente_id","tramos_ref"],"additionalProperties":false}}},"required":["esquema","obra_ref","estado_revision","revision_humana","procedencia","metadatos","jornadas","tramos","notas","resumen_fuente","incidencias"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_extraccion_minima() from public,anon,authenticated;

-- Valida la procedencia de secuencias unidas por prosa sin alterar las filas de la edición.
create or replace function public.comprobar_origen_minimo(p_fila jsonb,p_original jsonb)
returns void language plpgsql set search_path='' as $$
declare
 refs jsonb:=coalesce(p_fila#>'{origen,tramos_ref}',jsonb_build_array(p_fila#>>'{origen,tramo_ref}'));
 r jsonb; anterior jsonb; prosa jsonb; c jsonb; n integer:=0;
 ord bigint; prev_ord bigint; jornada integer; lo integer; hi integer;
 inicio integer:=(p_fila->>'v_ini')::integer; fin integer:=(p_fila->>'v_fin')::integer;
begin
 if jsonb_array_length(refs)<>(select count(distinct value) from jsonb_array_elements(refs))
   or refs->>0 is distinct from p_fila#>>'{origen,tramo_ref}' then
  raise exception using errcode='23514',message='Referencias de origen inválidas';
 end if;
 for c in select value from jsonb_array_elements(refs) loop
  select t,orden into r,ord from jsonb_array_elements(p_original->'tramos') with ordinality as x(t,orden)
    where t->>'id'=c#>>'{}';
  if r is null or r->>'v_ini' is null or r->>'v_fin' is null then
   raise exception using errcode='23514',message='Fila métrica de origen inexistente o sin rango';
  end if;
  if anterior is null then
   lo:=(r->>'v_ini')::integer; jornada:=(r->>'jornada')::integer;
   if (r->>'fuente_id') is distinct from (p_fila#>>'{origen,fuente_id}') or
      (r->>'denominacion_literal') is distinct from (p_fila#>>'{origen,denominacion_literal}') then
    raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
   end if;
  else
   prosa:=p_original->'tramos'->(prev_ord::integer);
   if ord<>prev_ord+2 or (r->>'v_ini')::integer<>(anterior->>'v_fin')::integer+1 or
      (r->>'jornada')::integer is distinct from jornada or jornada is null or
      (prosa->>'jornada')::integer is distinct from jornada or
      lower(btrim(prosa->>'denominacion_literal')) !~ '^(carta en |pasaje en )?prosa$' or
      prosa->>'denominacion_literal' is null or prosa->>'v_ini' is not null or
      prosa->>'v_fin' is not null or prosa->>'n_versos_fuente' is not null then
    raise exception using errcode='23514',message='La unión requiere prosa sin numeración entre filas consecutivas de una jornada';
   end if;
   if (anterior->>'v_fin')::integer>=inicio and (r->>'v_ini')::integer<=fin then
    n:=n+1;
    if not exists(select 1 from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) p
      where p->>'termino'='prosa' and p->>'tramo_ref'=prosa->>'id'
       and p->>'literal'=prosa->>'denominacion_literal'
       and (p->>'v_ini')::integer=(anterior->>'v_fin')::integer
       and (p->>'v_fin')::integer=(r->>'v_ini')::integer) then
     raise exception using errcode='23514',message='Falta localizar la prosa de la unión';
    end if;
   end if;
  end if;
  hi:=(r->>'v_fin')::integer; anterior:=r; prev_ord:=ord;
 end loop;
 if lo>inicio or hi<fin or lo is null or hi is null then
  raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
 end if;
 if jsonb_array_length(coalesce(p_fila->'caracterizaciones','[]'))<>n then
  raise exception using errcode='23514',message='Caracterización de prosa sin origen o fuera del pasaje';
 end if;
 for c in select value from jsonb_array_elements(p_fila#>'{origen,notas_ref}') loop
  if not exists(select 1 from jsonb_array_elements(p_original->'notas') nota
    where nota->>'id'=c#>>'{}' and exists(select 1 from jsonb_array_elements_text(refs) as z(ref)
      where nota->'tramos_ref' ? ref)) then
   raise exception using errcode='23514',message='Nota sin correspondencia con el tramo original';
  end if;
 end loop;
end;
$$;
revoke all on function public.comprobar_origen_minimo(jsonb,jsonb) from public,anon,authenticated;

-- BORRADOR LOCAL. Crea obras nuevas; no reimporta ni sobrescribe una obra existente.
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
    perform public.comprobar_origen_minimo(v_fila,p_entrada_original);
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

commit;
