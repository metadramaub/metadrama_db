-- Fase 1 del plan de zona pública (docs/plan-zona-publica.md):
-- Tabla de configuración de secciones públicas (feature flags de contenido) + RLS.
--
-- Dos conceptos ortogonales: esta tabla controla qué SECCIONES están activas y su
-- scope mínimo. NO controla el muro `estado = publicado` (innegociable) ni la
-- atenuación por obra (visible_publico / editor asignado), que viven en código.
--
-- Mergeable sin efecto visible: todo arranca activo y con scope_minimo permisivo.

-- Nota: la comprobación admin/IP usa el helper ya existente
-- public.auth_is_admin_or_ip() (definido en 20260216170000_vocabularios_manage_rls.sql).
-- No duplicamos esa función.

-- =========================================================
-- Tabla de secciones públicas
-- =========================================================
create table if not exists public.secciones_publicas (
  seccion_id text primary key,
  label text not null,
  descripcion text,
  activa boolean not null default true,
  scope_minimo text not null default 'anon'
    check (scope_minimo in ('anon', 'authenticated', 'admin_ip')),
  orden integer not null default 0,
  updated_at timestamptz not null default now()
);

comment on table public.secciones_publicas is
  'Feature flags de contenido para la zona pública. activa = on/off global; '
  'scope_minimo = nivel mínimo de visitante que ve la sección. No sustituye al '
  'muro estado=publicado ni a la atenuación por obra (visible_publico).';

-- Mantener updated_at al modificar.
create or replace function public.touch_secciones_publicas()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_touch_secciones_publicas on public.secciones_publicas;
create trigger trg_touch_secciones_publicas
  before update on public.secciones_publicas
  for each row execute function public.touch_secciones_publicas();

-- =========================================================
-- RLS: lectura para todos (incl. anon, define la propia web); escritura admin/IP.
-- =========================================================
alter table public.secciones_publicas enable row level security;

drop policy if exists "secciones_publicas_select" on public.secciones_publicas;
create policy "secciones_publicas_select"
on public.secciones_publicas
for select
to anon, authenticated
using (true);

drop policy if exists "secciones_publicas_insert" on public.secciones_publicas;
create policy "secciones_publicas_insert"
on public.secciones_publicas
for insert
to authenticated
with check (public.auth_is_admin_or_ip());

drop policy if exists "secciones_publicas_update" on public.secciones_publicas;
create policy "secciones_publicas_update"
on public.secciones_publicas
for update
to authenticated
using (public.auth_is_admin_or_ip())
with check (public.auth_is_admin_or_ip());

drop policy if exists "secciones_publicas_delete" on public.secciones_publicas;
create policy "secciones_publicas_delete"
on public.secciones_publicas
for delete
to authenticated
using (public.auth_is_admin_or_ip());

-- =========================================================
-- Seed de secciones. Idempotente: no pisa valores ya configurados por el admin.
-- Todo arranca activo y con scope permisivo (sin cambio visible al integrar).
-- =========================================================
insert into public.secciones_publicas (seccion_id, label, descripcion, activa, scope_minimo, orden) values
  -- Páginas de la zona pública
  ('catalogo',                   'Catálogo de obras',         'Buscador y listado de obras.',                              true, 'anon', 10),
  ('autores',                    'Autores',                   'Listado y fichas de autores.',                              true, 'anon', 20),
  ('laboratorio',                'Laboratorio',               'Sección experimental (placeholder).',                       true, 'anon', 30),
  ('demarcador',                 'Demarcador',                'Herramienta de demarcación métrica (placeholder).',          true, 'anon', 40),
  -- Sub-secciones de la ficha de obra
  ('ficha.autoria',              'Ficha · Autoría',           'Bloque de autoría en la ficha.',                            true, 'anon', 110),
  ('ficha.autoria.fuentes',      'Ficha · Fuentes de atribución', 'Fuentes/evidencias para la atribución de autoría.',     true, 'anon', 120),
  ('ficha.metrica',              'Ficha · Estructura métrica', 'Código de barras métrico y distribución de formas.',        true, 'anon', 130),
  ('ficha.observaciones',        'Ficha · Observaciones',     'Otras observaciones de la obra.',                           true, 'anon', 140),
  ('ficha.bibliografia',         'Ficha · Bibliografía',      'Bibliografía específica de la obra.',                       true, 'anon', 150),
  ('ficha.comentarios_publicos', 'Ficha · Aclaraciones públicas', 'Comentarios marcados como públicos en la ficha.',       true, 'anon', 160)
on conflict (seccion_id) do nothing;
