begin;

create table if not exists public.demarcador_familias_config (
	familia_id uuid primary key references public.vocabularios (termino_id) on update cascade on delete cascade,
	politica text not null check (politica in ('familia', 'variantes')),
	revisado_por uuid null references public.editores (user_id) on update cascade on delete set null,
	revisado_en timestamptz not null default now(),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

comment on table public.demarcador_familias_config is
	'Decisión editorial sobre si el demarcador identifica una familia raíz o también sus variantes.';

comment on column public.demarcador_familias_config.politica is
	'familia: termina en la forma raíz; variantes: intenta distinguir los hijos después de identificar la familia.';

create or replace function public.ensure_demarcador_familia_raiz()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if not exists (
		select 1
		from public.vocabularios v
		where v.termino_id = new.familia_id
			and v.categoria = 'estrofa_tipo'
			and v.termino_padre_id is null
	) then
		raise exception 'familia_id debe apuntar a una forma estrófica raíz';
	end if;

	if not exists (
		select 1
		from public.vocabularios h
		where h.categoria = 'estrofa_tipo'
			and h.termino_padre_id = new.familia_id
			and coalesce(h.activo, true)
	) then
		raise exception 'familia_id debe tener al menos un hijo activo';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_ensure_demarcador_familia_raiz
	on public.demarcador_familias_config;

create trigger trigger_ensure_demarcador_familia_raiz
before insert or update of familia_id on public.demarcador_familias_config
for each row
execute function public.ensure_demarcador_familia_raiz();

drop trigger if exists trigger_demarcador_familias_config_updated_at
	on public.demarcador_familias_config;

create trigger trigger_demarcador_familias_config_updated_at
before update on public.demarcador_familias_config
for each row
execute function public.actualizar_updated_at();

alter table public.demarcador_familias_config enable row level security;

drop policy if exists "demarcador_familias_config_select_admin_ip"
	on public.demarcador_familias_config;
create policy "demarcador_familias_config_select_admin_ip"
on public.demarcador_familias_config
for select
to authenticated
using (public.auth_is_admin_or_ip());

drop policy if exists "demarcador_familias_config_insert_admin_ip"
	on public.demarcador_familias_config;
create policy "demarcador_familias_config_insert_admin_ip"
on public.demarcador_familias_config
for insert
to authenticated
with check (public.auth_is_admin_or_ip());

drop policy if exists "demarcador_familias_config_update_admin_ip"
	on public.demarcador_familias_config;
create policy "demarcador_familias_config_update_admin_ip"
on public.demarcador_familias_config
for update
to authenticated
using (public.auth_is_admin_or_ip())
with check (public.auth_is_admin_or_ip());

drop policy if exists "demarcador_familias_config_delete_admin_ip"
	on public.demarcador_familias_config;
create policy "demarcador_familias_config_delete_admin_ip"
on public.demarcador_familias_config
for delete
to authenticated
using (public.auth_is_admin_or_ip());

grant select, insert, update, delete on table public.demarcador_familias_config to authenticated;

commit;
