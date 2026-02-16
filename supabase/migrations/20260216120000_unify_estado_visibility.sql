begin;

alter table public.secuencias_metricas
	drop constraint if exists secuencias_metricas_estado_revision_fkey;

drop index if exists public.idx_secuencias_estado;

alter table public.secuencias_metricas
	drop column if exists estado_revision;

delete from public.vocabularios
where categoria = 'estado_revision';

update public.obras o
set visible_publico = false
where coalesce(o.visible_publico, false) = true
	and not exists (
		select 1
		from public.vocabularios v
		where v.termino_id = o.estado
			and v.categoria = 'estado'
			and lower(v.termino) = 'publicado'
	);

create or replace function public.obras_enforce_public_visibility()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
	v_publicado_id uuid;
begin
	select termino_id
	into v_publicado_id
	from public.vocabularios
	where categoria = 'estado'
		and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		raise exception 'No existe estado=publicado en vocabularios';
	end if;

	if coalesce(new.visible_publico, false)
		and new.estado is distinct from v_publicado_id then
		raise exception using
			errcode = '23514',
			message = 'visible_publico solo puede activarse cuando la obra esta en estado publicado';
	end if;

	if tg_op = 'UPDATE'
		and old.estado = v_publicado_id
		and new.estado is distinct from v_publicado_id then
		new.visible_publico := false;
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_obras_enforce_public_visibility on public.obras;

create trigger trigger_obras_enforce_public_visibility
before insert or update on public.obras
for each row
execute function public.obras_enforce_public_visibility();

drop policy if exists "obras_publicas_select" on public.obras;
create policy "obras_publicas_select"
on public.obras
for select
to anon
using (
	visible_publico = true
	and exists (
		select 1
		from public.vocabularios v
		where v.termino_id = obras.estado
			and v.categoria = 'estado'
			and lower(v.termino) = 'publicado'
	)
);

commit;
