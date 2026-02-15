-- Dashboard autores (iteracion 1):
-- - escrituras solo admin/IP
-- - unicidad por nombre_normalizado
-- - refresco de obras.autoria al renombrar autor

alter table public.autores enable row level security;

drop policy if exists "autores_insert_admin_ip" on public.autores;
create policy "autores_insert_admin_ip"
on public.autores
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

drop policy if exists "autores_update_admin_ip" on public.autores;
create policy "autores_update_admin_ip"
on public.autores
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

drop policy if exists "autores_delete_admin_ip" on public.autores;
create policy "autores_delete_admin_ip"
on public.autores
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

create unique index if not exists idx_autores_nombre_normalizado_unique
	on public.autores (nombre_normalizado)
	where nombre_normalizado is not null;

create or replace function public.actualizar_autoria_obras_por_autor()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
	if old.nombre_completo is not distinct from new.nombre_completo then
		return new;
	end if;

	update public.obras o
	set autoria = (
		select array_agg(distinct a.nombre_completo order by a.nombre_completo)
		from public.rangos r
		join public.rangos_autores ra on ra.rango_id = r.rango_id
		join public.autores a on a.autor_id = ra.autor_id
		where r.obra_id = o.obra_id
	)
	where exists (
		select 1
		from public.rangos r2
		join public.rangos_autores ra2 on ra2.rango_id = r2.rango_id
		where r2.obra_id = o.obra_id
			and ra2.autor_id = new.autor_id
	);

	return new;
end;
$$;

drop trigger if exists trigger_actualizar_autoria_por_cambio_autor on public.autores;
create trigger trigger_actualizar_autoria_por_cambio_autor
after update of nombre_completo
on public.autores
for each row
execute function public.actualizar_autoria_obras_por_autor();
