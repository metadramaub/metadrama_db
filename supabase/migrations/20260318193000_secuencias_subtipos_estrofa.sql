begin;

create table if not exists public.secuencias_subtipos_estrofa (
	subtipo_secuencia_id uuid default extensions.uuid_generate_v4() not null,
	secuencia_id uuid not null,
	subtipo_estrofa_id uuid not null,
	v_ini integer not null,
	v_fin integer not null,
	created_at timestamp with time zone default now(),
	updated_at timestamp with time zone default now(),
	constraint secuencias_subtipos_estrofa_pkey primary key (subtipo_secuencia_id),
	constraint secuencias_subtipos_estrofa_v_ini_le_v_fin_chk check (v_ini <= v_fin),
	constraint secuencias_subtipos_estrofa_unique unique (secuencia_id, subtipo_estrofa_id, v_ini, v_fin),
	constraint secuencias_subtipos_estrofa_secuencia_id_fkey foreign key (secuencia_id) references public.secuencias_metricas (secuencia_id) on delete cascade,
	constraint secuencias_subtipos_estrofa_subtipo_estrofa_id_fkey foreign key (subtipo_estrofa_id) references public.vocabularios (termino_id)
);

create index if not exists idx_secuencias_subtipos_secuencia_v_ini
	on public.secuencias_subtipos_estrofa (secuencia_id, v_ini);

create index if not exists idx_secuencias_subtipos_subtipo_id
	on public.secuencias_subtipos_estrofa (subtipo_estrofa_id);

comment on table public.secuencias_subtipos_estrofa is
	'Subtipos estroficos por rango de versos dentro de una secuencia.';

comment on column public.secuencias_subtipos_estrofa.subtipo_estrofa_id is
	'Termino hijo de vocabularios.categoria=estrofa_tipo correspondiente a la estrofa base de la secuencia.';

create or replace function public.validate_secuencias_subtipos_estrofa()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_secuencia record;
	v_subtipo record;
begin
	select sm.secuencia_id, sm.v_ini, sm.v_fin, sm.estrofa_tipo_id
	into v_secuencia
	from public.secuencias_metricas sm
	where sm.secuencia_id = new.secuencia_id
	limit 1;

	if v_secuencia is null then
		raise exception using
			errcode = '23503',
			message = 'La secuencia asociada no existe.';
	end if;

	select v.termino_id, v.categoria, v.termino_padre_id
	into v_subtipo
	from public.vocabularios v
	where v.termino_id = new.subtipo_estrofa_id
	limit 1;

	if v_subtipo is null then
		raise exception using
			errcode = '23503',
			message = 'El subtipo de estrofa no existe.';
	end if;

	if v_subtipo.categoria is distinct from 'estrofa_tipo' then
		raise exception using
			errcode = '23514',
			message = 'subtipo_estrofa_id debe apuntar a vocabularios.categoria=estrofa_tipo';
	end if;

	if v_subtipo.termino_padre_id is null then
		raise exception using
			errcode = '23514',
			message = 'El subtipo de estrofa debe ser hijo de una estrofa base.';
	end if;

	if v_subtipo.termino_padre_id is distinct from v_secuencia.estrofa_tipo_id then
		raise exception using
			errcode = '23514',
			message = 'El subtipo de estrofa debe pertenecer a la estrofa base de la secuencia.';
	end if;

	if new.v_ini < v_secuencia.v_ini or new.v_fin > v_secuencia.v_fin then
		raise exception using
			errcode = '23514',
			message = 'El rango del subtipo debe quedar dentro del rango de la secuencia.';
	end if;

	if exists (
		select 1
		from public.secuencias_subtipos_estrofa s
		where s.secuencia_id = new.secuencia_id
			and (tg_op = 'INSERT' or s.subtipo_secuencia_id <> new.subtipo_secuencia_id)
			and new.v_ini <= s.v_fin
			and new.v_fin >= s.v_ini
	) then
		raise exception using
			errcode = '23514',
			message = 'El rango del subtipo se solapa con otro subtipo de la secuencia.';
	end if;

	return new;
end;
$$;

create or replace function public.cleanup_secuencias_subtipos_on_secuencia_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	if old.estrofa_tipo_id is distinct from new.estrofa_tipo_id
		or old.v_ini is distinct from new.v_ini
		or old.v_fin is distinct from new.v_fin then
		delete from public.secuencias_subtipos_estrofa
		where secuencia_id = new.secuencia_id;
	end if;
	return new;
end;
$$;

drop trigger if exists trigger_validate_secuencias_subtipos_estrofa
	on public.secuencias_subtipos_estrofa;

create trigger trigger_validate_secuencias_subtipos_estrofa
before insert or update on public.secuencias_subtipos_estrofa
for each row
execute function public.validate_secuencias_subtipos_estrofa();

drop trigger if exists trigger_secuencias_subtipos_updated_at
	on public.secuencias_subtipos_estrofa;

create trigger trigger_secuencias_subtipos_updated_at
before update on public.secuencias_subtipos_estrofa
for each row
execute function public.actualizar_updated_at();

drop trigger if exists trigger_cleanup_secuencias_subtipos_on_secuencia_change
	on public.secuencias_metricas;

create trigger trigger_cleanup_secuencias_subtipos_on_secuencia_change
after update of estrofa_tipo_id, v_ini, v_fin on public.secuencias_metricas
for each row
execute function public.cleanup_secuencias_subtipos_on_secuencia_change();

alter table public.secuencias_subtipos_estrofa enable row level security;

drop policy if exists "secuencias_subtipos_select_authenticated" on public.secuencias_subtipos_estrofa;
drop policy if exists "secuencias_subtipos_select_assigned_reviewer" on public.secuencias_subtipos_estrofa;
drop policy if exists "secuencias_subtipos_insert_authenticated" on public.secuencias_subtipos_estrofa;
drop policy if exists "secuencias_subtipos_update_authenticated" on public.secuencias_subtipos_estrofa;
drop policy if exists "secuencias_subtipos_delete_authenticated" on public.secuencias_subtipos_estrofa;

create policy "secuencias_subtipos_select_authenticated"
on public.secuencias_subtipos_estrofa
for select
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip', 'revisor')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_subtipos_select_assigned_reviewer"
on public.secuencias_subtipos_estrofa
for select
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras_revisores r on r.obra_id = sm.obra_id
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
			and r.revisor_id = auth.uid()
	)
);

create policy "secuencias_subtipos_insert_authenticated"
on public.secuencias_subtipos_estrofa
for insert
to authenticated
with check (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_subtipos_update_authenticated"
on public.secuencias_subtipos_estrofa
for update
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
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
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "secuencias_subtipos_delete_authenticated"
on public.secuencias_subtipos_estrofa
for delete
to authenticated
using (
	exists (
		select 1
		from public.secuencias_metricas sm
		join public.obras o on o.obra_id = sm.obra_id
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where sm.secuencia_id = secuencias_subtipos_estrofa.secuencia_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

commit;
