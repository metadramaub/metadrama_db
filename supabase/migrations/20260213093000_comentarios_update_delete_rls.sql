-- Permite editar y borrar comentarios internos al autor y a roles admin/IP.
-- Los handlers de API siguen aplicando reglas de negocio adicionales
-- (por ejemplo, bloqueo de comentarios de tipo "estado").

alter table public.comentarios_internos enable row level security;

drop policy if exists "comentarios_update_owner_or_admin" on public.comentarios_internos;
create policy "comentarios_update_owner_or_admin"
on public.comentarios_internos
for update
to authenticated
using (
	user_id = auth.uid()
	or exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and lower(vr.termino) in ('admin', 'ip')
	)
)
with check (
	user_id = auth.uid()
	or exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and lower(vr.termino) in ('admin', 'ip')
	)
);

drop policy if exists "comentarios_delete_owner_or_admin" on public.comentarios_internos;
create policy "comentarios_delete_owner_or_admin"
on public.comentarios_internos
for delete
to authenticated
using (
	user_id = auth.uid()
	or exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and lower(vr.termino) in ('admin', 'ip')
	)
);
