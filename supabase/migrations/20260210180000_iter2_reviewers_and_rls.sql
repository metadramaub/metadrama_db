-- Iteracion 2: revisores asignados (N:M) + politicas de lectura/revision por asignacion.

-- =========================================================
-- Tabla de asignaciones de revision
-- =========================================================
create table if not exists public.obras_revisores (
  obra_id uuid not null references public.obras (obra_id) on delete cascade,
  revisor_id uuid not null references public.editores (user_id) on delete cascade,
  asignado_por uuid not null references public.editores (user_id),
  created_at timestamptz not null default now(),
  primary key (obra_id, revisor_id)
);

create index if not exists obras_revisores_revisor_idx on public.obras_revisores (revisor_id);
create index if not exists obras_revisores_obra_idx on public.obras_revisores (obra_id);

alter table public.obras_revisores enable row level security;

-- Admin/IP gestionan asignaciones.
drop policy if exists "obras_revisores_select" on public.obras_revisores;
drop policy if exists "obras_revisores_insert" on public.obras_revisores;
drop policy if exists "obras_revisores_update" on public.obras_revisores;
drop policy if exists "obras_revisores_delete" on public.obras_revisores;

create policy "obras_revisores_select"
on public.obras_revisores
for select
to authenticated
using (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and lower(vr.termino) in ('admin', 'ip')
  )
  or revisor_id = auth.uid()
  or exists (
    select 1
    from public.obras o
    where o.obra_id = obras_revisores.obra_id
      and o.editor_asignado = auth.uid()
  )
);

create policy "obras_revisores_insert"
on public.obras_revisores
for insert
to authenticated
with check (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and lower(vr.termino) in ('admin', 'ip')
  )
);

create policy "obras_revisores_update"
on public.obras_revisores
for update
to authenticated
using (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and lower(vr.termino) in ('admin', 'ip')
  )
)
with check (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and lower(vr.termino) in ('admin', 'ip')
  )
);

create policy "obras_revisores_delete"
on public.obras_revisores
for delete
to authenticated
using (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and lower(vr.termino) in ('admin', 'ip')
  )
);

-- =========================================================
-- Autores: lectura para autenticados activos (arregla buscador)
-- =========================================================
alter table public.autores enable row level security;

drop policy if exists "autores_select_authenticated_active" on public.autores;
create policy "autores_select_authenticated_active"
on public.autores
for select
to authenticated
using (
  exists (
    select 1
    from public.editores e
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
  )
);

-- =========================================================
-- Lectura por asignacion de revision (solo SELECT)
-- =========================================================
drop policy if exists "obras_select_assigned_reviewer" on public.obras;
create policy "obras_select_assigned_reviewer"
on public.obras
for select
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = obras.obra_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "jornadas_select_assigned_reviewer" on public.jornadas;
create policy "jornadas_select_assigned_reviewer"
on public.jornadas
for select
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = jornadas.obra_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "cuadros_select_assigned_reviewer" on public.cuadros;
create policy "cuadros_select_assigned_reviewer"
on public.cuadros
for select
to authenticated
using (
  exists (
    select 1
    from public.jornadas j
    join public.obras_revisores r on r.obra_id = j.obra_id
    where j.jornada_id = cuadros.jornada_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "secuencias_select_assigned_reviewer" on public.secuencias_metricas;
create policy "secuencias_select_assigned_reviewer"
on public.secuencias_metricas
for select
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = secuencias_metricas.obra_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "secuencias_metros_select_assigned_reviewer" on public.secuencias_metros;
create policy "secuencias_metros_select_assigned_reviewer"
on public.secuencias_metros
for select
to authenticated
using (
  exists (
    select 1
    from public.secuencias_metricas sm
    join public.obras_revisores r on r.obra_id = sm.obra_id
    where sm.secuencia_id = secuencias_metros.secuencia_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "secuencias_variaciones_select_assigned_reviewer" on public.secuencias_variaciones;
create policy "secuencias_variaciones_select_assigned_reviewer"
on public.secuencias_variaciones
for select
to authenticated
using (
  exists (
    select 1
    from public.secuencias_metricas sm
    join public.obras_revisores r on r.obra_id = sm.obra_id
    where sm.secuencia_id = secuencias_variaciones.secuencia_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "rangos_select_assigned_reviewer" on public.rangos;
create policy "rangos_select_assigned_reviewer"
on public.rangos
for select
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = rangos.obra_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "rangos_autores_select_assigned_reviewer" on public.rangos_autores;
create policy "rangos_autores_select_assigned_reviewer"
on public.rangos_autores
for select
to authenticated
using (
  exists (
    select 1
    from public.rangos ra
    join public.obras_revisores r on r.obra_id = ra.obra_id
    where ra.rango_id = rangos_autores.rango_id
      and r.revisor_id = auth.uid()
  )
);

-- Comentarios por asignacion de revision
alter table public.comentarios_internos enable row level security;

drop policy if exists "comentarios_select_assigned_reviewer" on public.comentarios_internos;
create policy "comentarios_select_assigned_reviewer"
on public.comentarios_internos
for select
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = comentarios_internos.obra_id
      and r.revisor_id = auth.uid()
  )
);

drop policy if exists "comentarios_insert_assigned_reviewer" on public.comentarios_internos;
create policy "comentarios_insert_assigned_reviewer"
on public.comentarios_internos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = comentarios_internos.obra_id
      and r.revisor_id = auth.uid()
  )
  and user_id = auth.uid()
);

-- Cambio de estado por revisor asignado (sin abrir CRUD de contenido)
drop policy if exists "obras_update_assigned_reviewer" on public.obras;
create policy "obras_update_assigned_reviewer"
on public.obras
for update
to authenticated
using (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = obras.obra_id
      and r.revisor_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = obras.obra_id
      and r.revisor_id = auth.uid()
  )
);
