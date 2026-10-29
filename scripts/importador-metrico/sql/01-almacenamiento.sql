-- BORRADOR. Solo se ejecuta en PostgreSQL local. No es una migración desplegable todavía.
begin;
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
commit;
