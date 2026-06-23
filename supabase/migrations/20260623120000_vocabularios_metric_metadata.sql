begin;

alter table public.vocabularios
	add column if not exists tipo_rima text,
	add column if not exists naturaleza_estrofica text,
	add column if not exists tamanio_unidad_estrofica integer,
	add column if not exists arte_metrico text,
	add column if not exists numero_silabas integer;

alter table public.vocabularios
	drop constraint if exists vocabularios_tipo_rima_check,
	drop constraint if exists vocabularios_naturaleza_estrofica_check,
	drop constraint if exists vocabularios_tamanio_unidad_estrofica_check,
	drop constraint if exists vocabularios_arte_metrico_check,
	drop constraint if exists vocabularios_numero_silabas_check;

alter table public.vocabularios
	add constraint vocabularios_tipo_rima_check
		check (tipo_rima is null or tipo_rima in ('asonante', 'consonante', 'sin_rima', 'mixta')),
	add constraint vocabularios_naturaleza_estrofica_check
		check (
			naturaleza_estrofica is null
			or naturaleza_estrofica in (
				'tirada_continua',
				'estrofa_cerrada',
				'forma_fija',
				'forma_compuesta',
				'forma_irregular'
			)
		),
	add constraint vocabularios_tamanio_unidad_estrofica_check
		check (tamanio_unidad_estrofica is null or tamanio_unidad_estrofica > 0),
	add constraint vocabularios_arte_metrico_check
		check (arte_metrico is null or arte_metrico in ('arte_menor', 'arte_mayor', 'mixto')),
	add constraint vocabularios_numero_silabas_check
		check (numero_silabas is null or numero_silabas > 0);

create or replace function public.recompute_vocabulario_arte_metrico(p_estrofa_tipo_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_total integer;
	v_with_syllables integer;
	v_minor integer;
	v_major integer;
	v_arte text;
begin
	select
		count(*),
		count(metro.numero_silabas),
		count(*) filter (where metro.numero_silabas <= 8),
		count(*) filter (where metro.numero_silabas >= 9)
	into v_total, v_with_syllables, v_minor, v_major
	from public.estrofa_tipo_metros etm
	join public.vocabularios metro
		on metro.termino_id = etm.metro_id
	where etm.estrofa_tipo_id = p_estrofa_tipo_id;

	if v_total = 0 or v_with_syllables <> v_total then
		v_arte := null;
	elsif v_minor = v_total then
		v_arte := 'arte_menor';
	elsif v_major = v_total then
		v_arte := 'arte_mayor';
	else
		v_arte := 'mixto';
	end if;

	update public.vocabularios
	set
		arte_metrico = v_arte,
		updated_at = now()
	where termino_id = p_estrofa_tipo_id
		and categoria = 'estrofa_tipo'
		and arte_metrico is distinct from v_arte;
end;
$$;

create or replace function public.recompute_vocabulario_arte_metrico_from_relation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if tg_op in ('INSERT', 'UPDATE') then
		perform public.recompute_vocabulario_arte_metrico(new.estrofa_tipo_id);
	end if;

	if tg_op = 'DELETE' then
		perform public.recompute_vocabulario_arte_metrico(old.estrofa_tipo_id);
		return old;
	end if;

	if tg_op = 'UPDATE' and old.estrofa_tipo_id is distinct from new.estrofa_tipo_id then
		perform public.recompute_vocabulario_arte_metrico(old.estrofa_tipo_id);
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_recompute_vocabulario_arte_metrico_from_relation
	on public.estrofa_tipo_metros;

create trigger trigger_recompute_vocabulario_arte_metrico_from_relation
after insert or update or delete on public.estrofa_tipo_metros
for each row
execute function public.recompute_vocabulario_arte_metrico_from_relation();

create or replace function public.recompute_vocabulario_arte_metrico_from_metro()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
	v_estrofa_tipo_id uuid;
begin
	if tg_op = 'UPDATE' then
		if old.numero_silabas is not distinct from new.numero_silabas
			and old.categoria is not distinct from new.categoria
		then
			return new;
		end if;
	end if;

	if tg_op = 'DELETE' then
		if old.categoria = 'metro' then
			for v_estrofa_tipo_id in
				select distinct estrofa_tipo_id
				from public.estrofa_tipo_metros
				where metro_id = old.termino_id
			loop
				perform public.recompute_vocabulario_arte_metrico(v_estrofa_tipo_id);
			end loop;
		end if;
		return old;
	end if;

	if tg_op = 'UPDATE' and old.categoria = 'metro' then
		for v_estrofa_tipo_id in
			select distinct estrofa_tipo_id
			from public.estrofa_tipo_metros
			where metro_id = old.termino_id
		loop
			perform public.recompute_vocabulario_arte_metrico(v_estrofa_tipo_id);
		end loop;
	end if;

	if tg_op in ('INSERT', 'UPDATE') and new.categoria = 'metro' then
		for v_estrofa_tipo_id in
			select distinct estrofa_tipo_id
			from public.estrofa_tipo_metros
			where metro_id = new.termino_id
		loop
			perform public.recompute_vocabulario_arte_metrico(v_estrofa_tipo_id);
		end loop;
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_recompute_vocabulario_arte_metrico_from_metro
	on public.vocabularios;

create trigger trigger_recompute_vocabulario_arte_metrico_from_metro
after insert or update of categoria, numero_silabas or delete on public.vocabularios
for each row
execute function public.recompute_vocabulario_arte_metrico_from_metro();

update public.vocabularios
set numero_silabas = case termino
	when 'octosilabo' then 8
	when 'heptasilabo' then 7
	when 'endecasilabo' then 11
	else numero_silabas
end
where categoria = 'metro'
	and termino in ('octosilabo', 'heptasilabo', 'endecasilabo');

select public.recompute_vocabulario_arte_metrico(termino_id)
from public.vocabularios
where categoria = 'estrofa_tipo';

commit;
