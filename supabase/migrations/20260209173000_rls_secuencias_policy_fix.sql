-- Fix RLS for secuencias tables used by dashboard tab "Secuencias".
-- Read rules:
--   - admin/IP/revisor: can read all rows.
--   - editor: can read rows only for assigned obras.
-- Write rules:
--   - admin/IP: can write all rows.
--   - editor: can write rows only for assigned obras.
--   - revisor: read-only.

-- secuencias_metricas
drop policy if exists "secuencias_select_authenticated" on public.secuencias_metricas;
drop policy if exists "secuencias_insert_authenticated" on public.secuencias_metricas;
drop policy if exists "secuencias_update_authenticated" on public.secuencias_metricas;
drop policy if exists "secuencias_delete_authenticated" on public.secuencias_metricas;

create policy "secuencias_select_authenticated"
on public.secuencias_metricas
for select
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = secuencias_metricas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_insert_authenticated"
on public.secuencias_metricas
for insert
to authenticated
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = secuencias_metricas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_update_authenticated"
on public.secuencias_metricas
for update
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = secuencias_metricas.obra_id
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
		where o.obra_id = secuencias_metricas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_delete_authenticated"
on public.secuencias_metricas
for delete
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = secuencias_metricas.obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- secuencias_metros
drop policy if exists "secuencias_metros_select_authenticated" on public.secuencias_metros;
drop policy if exists "secuencias_metros_insert_authenticated" on public.secuencias_metros;
drop policy if exists "secuencias_metros_update_authenticated" on public.secuencias_metros;
drop policy if exists "secuencias_metros_delete_authenticated" on public.secuencias_metros;

create policy "secuencias_metros_select_authenticated"
on public.secuencias_metros
for select
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_metros.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_metros_insert_authenticated"
on public.secuencias_metros
for insert
to authenticated
with check (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_metros.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_metros_update_authenticated"
on public.secuencias_metros
for update
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_metros.secuencia_id
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
		where sm.secuencia_id = secuencias_metros.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_metros_delete_authenticated"
on public.secuencias_metros
for delete
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_metros.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);
