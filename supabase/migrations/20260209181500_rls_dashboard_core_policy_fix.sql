-- Fix RLS for remaining dashboard core tables.
-- This complements secuencias/secuencias_metros policies.
--
-- Read:
--   - admin/IP/revisor: all obras (and dependent rows)
--   - editor: only rows belonging to assigned obras
-- Write (insert/update/delete):
--   - admin/IP: all
--   - editor: only assigned obras
--   - revisor: read-only

-- =====================================
-- OBRAS
-- =====================================
drop policy if exists "obras_insert_authenticated" on public.obras;
drop policy if exists "obras_update_authenticated" on public.obras;
drop policy if exists "obras_delete_authenticated" on public.obras;

create policy "obras_insert_authenticated"
on public.obras
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

create policy "obras_update_authenticated"
on public.obras
for update
to authenticated
using (
	exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and obras.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and obras.editor_asignado = e.user_id)
			)
	)
);

create policy "obras_delete_authenticated"
on public.obras
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

-- =====================================
-- JORNADAS
-- =====================================
drop policy if exists "jornadas_select_authenticated" on public.jornadas;
drop policy if exists "jornadas_insert_authenticated" on public.jornadas;
drop policy if exists "jornadas_update_authenticated" on public.jornadas;
drop policy if exists "jornadas_delete_authenticated" on public.jornadas;

create policy "jornadas_select_authenticated"
on public.jornadas
for select
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = jornadas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "jornadas_insert_authenticated"
on public.jornadas
for insert
to authenticated
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = jornadas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "jornadas_update_authenticated"
on public.jornadas
for update
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = jornadas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = jornadas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "jornadas_delete_authenticated"
on public.jornadas
for delete
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = jornadas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- =====================================
-- CUADROS
-- =====================================
drop policy if exists "cuadros_select_authenticated" on public.cuadros;
drop policy if exists "cuadros_insert_authenticated" on public.cuadros;
drop policy if exists "cuadros_update_authenticated" on public.cuadros;
drop policy if exists "cuadros_delete_authenticated" on public.cuadros;

create policy "cuadros_select_authenticated"
on public.cuadros
for select
to authenticated
using (
	exists (
		select 1
		from public.jornadas j
		join public.obras o on o.obra_id = j.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where j.jornada_id = cuadros.jornada_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "cuadros_insert_authenticated"
on public.cuadros
for insert
to authenticated
with check (
	exists (
		select 1
		from public.jornadas j
		join public.obras o on o.obra_id = j.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where j.jornada_id = cuadros.jornada_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "cuadros_update_authenticated"
on public.cuadros
for update
to authenticated
using (
	exists (
		select 1
		from public.jornadas j
		join public.obras o on o.obra_id = j.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where j.jornada_id = cuadros.jornada_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.jornadas j
		join public.obras o on o.obra_id = j.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where j.jornada_id = cuadros.jornada_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "cuadros_delete_authenticated"
on public.cuadros
for delete
to authenticated
using (
	exists (
		select 1
		from public.jornadas j
		join public.obras o on o.obra_id = j.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where j.jornada_id = cuadros.jornada_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- =====================================
-- RANGOS
-- =====================================
drop policy if exists "rangos_select_authenticated" on public.rangos;
drop policy if exists "rangos_insert_authenticated" on public.rangos;
drop policy if exists "rangos_update_authenticated" on public.rangos;
drop policy if exists "rangos_delete_authenticated" on public.rangos;

create policy "rangos_select_authenticated"
on public.rangos
for select
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = rangos.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_insert_authenticated"
on public.rangos
for insert
to authenticated
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = rangos.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_update_authenticated"
on public.rangos
for update
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = rangos.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = rangos.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_delete_authenticated"
on public.rangos
for delete
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = rangos.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- =====================================
-- RANGOS_AUTORES
-- =====================================
drop policy if exists "rangos_autores_select_authenticated" on public.rangos_autores;
drop policy if exists "rangos_autores_insert_authenticated" on public.rangos_autores;
drop policy if exists "rangos_autores_update_authenticated" on public.rangos_autores;
drop policy if exists "rangos_autores_delete_authenticated" on public.rangos_autores;

create policy "rangos_autores_select_authenticated"
on public.rangos_autores
for select
to authenticated
using (
	exists (
		select 1
		from public.rangos r
		join public.obras o on o.obra_id = r.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where r.rango_id = rangos_autores.rango_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_autores_insert_authenticated"
on public.rangos_autores
for insert
to authenticated
with check (
	exists (
		select 1
		from public.rangos r
		join public.obras o on o.obra_id = r.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where r.rango_id = rangos_autores.rango_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_autores_update_authenticated"
on public.rangos_autores
for update
to authenticated
using (
	exists (
		select 1
		from public.rangos r
		join public.obras o on o.obra_id = r.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where r.rango_id = rangos_autores.rango_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.rangos r
		join public.obras o on o.obra_id = r.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where r.rango_id = rangos_autores.rango_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "rangos_autores_delete_authenticated"
on public.rangos_autores
for delete
to authenticated
using (
	exists (
		select 1
		from public.rangos r
		join public.obras o on o.obra_id = r.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where r.rango_id = rangos_autores.rango_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- =====================================
-- SECUENCIAS_VARIACIONES
-- =====================================
drop policy if exists "secuencias_variaciones_select_authenticated" on public.secuencias_variaciones;
drop policy if exists "secuencias_variaciones_insert_authenticated" on public.secuencias_variaciones;
drop policy if exists "secuencias_variaciones_update_authenticated" on public.secuencias_variaciones;
drop policy if exists "secuencias_variaciones_delete_authenticated" on public.secuencias_variaciones;

create policy "secuencias_variaciones_select_authenticated"
on public.secuencias_variaciones
for select
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_variaciones.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_variaciones_insert_authenticated"
on public.secuencias_variaciones
for insert
to authenticated
with check (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_variaciones.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_variaciones_update_authenticated"
on public.secuencias_variaciones
for update
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_variaciones.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_variaciones.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_variaciones_delete_authenticated"
on public.secuencias_variaciones
for delete
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_variaciones.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);
