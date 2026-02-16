begin;

create or replace function public.auth_is_admin_or_ip()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and lower(vr.termino) in ('admin', 'ip')
	);
$$;

revoke all on function public.auth_is_admin_or_ip() from public;
grant execute on function public.auth_is_admin_or_ip() to authenticated;

alter table public.vocabularios enable row level security;

drop policy if exists "vocabularios_select_admin_ip" on public.vocabularios;
create policy "vocabularios_select_admin_ip"
on public.vocabularios
for select
to authenticated
using (public.auth_is_admin_or_ip());

drop policy if exists "vocabularios_insert_admin_ip" on public.vocabularios;
create policy "vocabularios_insert_admin_ip"
on public.vocabularios
for insert
to authenticated
with check (public.auth_is_admin_or_ip());

drop policy if exists "vocabularios_update_admin_ip" on public.vocabularios;
create policy "vocabularios_update_admin_ip"
on public.vocabularios
for update
to authenticated
using (public.auth_is_admin_or_ip())
with check (public.auth_is_admin_or_ip());

drop policy if exists "vocabularios_delete_admin_ip" on public.vocabularios;
create policy "vocabularios_delete_admin_ip"
on public.vocabularios
for delete
to authenticated
using (public.auth_is_admin_or_ip());

commit;
