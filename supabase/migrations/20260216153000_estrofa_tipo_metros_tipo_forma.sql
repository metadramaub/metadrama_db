begin;

alter table public.vocabularios
	add column if not exists tipo_forma text;

alter table public.vocabularios
	drop constraint if exists vocabularios_tipo_forma_check;

alter table public.vocabularios
	add constraint vocabularios_tipo_forma_check
	check (tipo_forma is null or tipo_forma in ('forma_espanola', 'forma_italiana'));

create table if not exists public.estrofa_tipo_metros (
	estrofa_tipo_id uuid not null,
	metro_id uuid not null,
	created_at timestamptz not null default now(),
	constraint estrofa_tipo_metros_pkey primary key (estrofa_tipo_id, metro_id),
	constraint estrofa_tipo_metros_estrofa_tipo_id_fkey foreign key (estrofa_tipo_id) references public.vocabularios (termino_id) on delete cascade,
	constraint estrofa_tipo_metros_metro_id_fkey foreign key (metro_id) references public.vocabularios (termino_id) on delete cascade
);

create index if not exists idx_estrofa_tipo_metros_metro_id
	on public.estrofa_tipo_metros (metro_id);

create or replace function public.validate_estrofa_tipo_metros_categories()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
	v_estrofa_categoria text;
	v_metro_categoria text;
begin
	select categoria into v_estrofa_categoria
	from public.vocabularios
	where termino_id = new.estrofa_tipo_id;

	if v_estrofa_categoria is distinct from 'estrofa_tipo' then
		raise exception using
			errcode = '23514',
			message = 'estrofa_tipo_id debe apuntar a vocabularios.categoria=estrofa_tipo';
	end if;

	select categoria into v_metro_categoria
	from public.vocabularios
	where termino_id = new.metro_id;

	if v_metro_categoria is distinct from 'metro' then
		raise exception using
			errcode = '23514',
			message = 'metro_id debe apuntar a vocabularios.categoria=metro';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_validate_estrofa_tipo_metros_categories
	on public.estrofa_tipo_metros;

create trigger trigger_validate_estrofa_tipo_metros_categories
before insert or update on public.estrofa_tipo_metros
for each row
execute function public.validate_estrofa_tipo_metros_categories();

insert into public.estrofa_tipo_metros (estrofa_tipo_id, metro_id)
select distinct sm.estrofa_tipo_id, sem.metro_id
from public.secuencias_metricas sm
join public.secuencias_metros sem on sem.secuencia_id = sm.secuencia_id
where sm.estrofa_tipo_id is not null
on conflict do nothing;

drop table if exists public.secuencias_metros;

alter table public.estrofa_tipo_metros enable row level security;

drop policy if exists "estrofa_tipo_metros_select" on public.estrofa_tipo_metros;
create policy "estrofa_tipo_metros_select"
on public.estrofa_tipo_metros
for select
to anon, authenticated
using (true);

drop policy if exists "estrofa_tipo_metros_insert_admin_ip" on public.estrofa_tipo_metros;
create policy "estrofa_tipo_metros_insert_admin_ip"
on public.estrofa_tipo_metros
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

drop policy if exists "estrofa_tipo_metros_update_admin_ip" on public.estrofa_tipo_metros;
create policy "estrofa_tipo_metros_update_admin_ip"
on public.estrofa_tipo_metros
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

drop policy if exists "estrofa_tipo_metros_delete_admin_ip" on public.estrofa_tipo_metros;
create policy "estrofa_tipo_metros_delete_admin_ip"
on public.estrofa_tipo_metros
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

commit;