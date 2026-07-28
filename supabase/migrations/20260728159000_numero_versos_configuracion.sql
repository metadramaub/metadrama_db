begin;

alter table public.configuraciones_forma
	add column numero_versos integer null
		check (numero_versos is null or numero_versos > 0);

do $$
declare
	v_conflictos text;
begin
	select string_agg(format('%s (%s–%s)', nombre, versos_min, versos_max), ', ' order by nombre)
	into v_conflictos
	from public.configuraciones_forma
	where versos_min is distinct from versos_max;

	if v_conflictos is not null then
		raise exception
			'No se puede sustituir el intervalo por numero_versos: hay configuraciones con límites distintos o incompletos: %',
			v_conflictos;
	end if;
end;
$$;

update public.configuraciones_forma
set numero_versos = versos_min
where versos_min is not null;

-- La extensión total solo se declara directamente en estrofas y composiciones
-- simples. En versos, series y formas compuestas se deriva del nivel, de la
-- estructura o de sus repeticiones.
update public.configuraciones_forma configuracion
set numero_versos = null
where configuracion.numero_versos is not null
	and not exists (
		select 1
		from public.formas_metricas forma
		where forma.forma_id = configuracion.forma_id
			and forma.nivel_estructural in ('estrofa', 'composicion')
	);

alter table public.configuraciones_forma
	drop column versos_min,
	drop column versos_max,
	drop column naturaleza_estrofica_id;

comment on column public.configuraciones_forma.numero_versos is
	'Número fijo total de una configuración simple de nivel estrofa o composición. En los demás niveles se deriva de la estructura y las repeticiones.';

create or replace function public.normalizar_extension_configuracion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_nivel text;
begin
	select nivel_estructural
	into v_nivel
	from public.formas_metricas
	where forma_id = new.forma_id;

	if v_nivel is null then
		raise exception 'forma_id debe identificar una forma métrica válida';
	end if;

	if v_nivel not in ('estrofa', 'composicion') then
		new.numero_versos := null;
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_normalizar_numero_versos_configuracion
	on public.configuraciones_forma;

create trigger trigger_normalizar_numero_versos_configuracion
before insert or update of forma_id, numero_versos
on public.configuraciones_forma
for each row
execute function public.normalizar_extension_configuracion_metrica();

create or replace function public.normalizar_extensiones_al_cambiar_nivel_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	if new.nivel_estructural not in ('estrofa', 'composicion') then
		update public.configuraciones_forma
		set numero_versos = null
		where forma_id = new.forma_id
			and numero_versos is not null;
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_normalizar_extensiones_al_cambiar_nivel_metrico
	on public.formas_metricas;

create trigger trigger_normalizar_extensiones_al_cambiar_nivel_metrico
after update of nivel_estructural
on public.formas_metricas
for each row
when (old.nivel_estructural is distinct from new.nivel_estructural)
execute function public.normalizar_extensiones_al_cambiar_nivel_metrico();

update public.catalogo_metrico_estado
set modelo_version = 8,
	actualizado_en = now()
where id = true;

commit;
