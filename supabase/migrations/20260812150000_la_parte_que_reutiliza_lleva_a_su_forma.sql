-- La parte que reutiliza otra forma lleva a su forma.
--
-- «Los cuartetos del soneto riman como el cuarteto endecasílabo» es el dato más pedagógico que
-- guarda el catálogo, y hasta ahora la ficha no podía ni enseñarlo: el servidor resolvía el
-- nombre de la arquitectura referenciada y lo tiraba, y aunque no lo hubiera tirado no tenía con
-- qué enlazarlo, porque la forma de esa arquitectura no viaja en la proyección —`formas` trae la
-- forma pedida y las que se relacionan con ella, no las que sus partes reutilizan—.
--
-- Se añade una clave en la función jerárquica en lugar de reescribir entera la que la sostiene:
-- es aditivo, cabe en veinte líneas y no toca lo que `main` ya lee.

create or replace function public.get_forma_metrica_publica_jerarquica(p_slug text)
returns jsonb
language sql
stable
set search_path to 'public'
as $function$
with
forma_objetivo as (
	select forma_id
	from public.formas_metricas
	where activo and slug = p_slug
),
arquitecturas_objetivo as (
	select arquitectura_id
	from public.arquitecturas_forma
	where activo and forma_id in (select forma_id from forma_objetivo)
)
select public.get_forma_metrica_publica(p_slug) || jsonb_build_object(
	'secciones', coalesce((
		select jsonb_agg(
			to_jsonb(x)
			order by x.arquitectura_id, x.seccion_padre_id nulls first, x.orden, x.slug
		)
		from (
			select
				s.seccion_id,
				s.arquitectura_id,
				s.seccion_padre_id,
				s.slug,
				s.tipo_seccion,
				s.nombre,
				s.nota,
				s.versos_min,
				s.versos_max,
				s.repeticiones_min,
				s.repeticiones_max,
				s.arquitectura_referenciada_id,
				s.primera_realizacion_define_patron,
				s.esquema_metrico_id,
				s.esquema_rima_id,
				s.orden
			from public.estructuras_secciones s
			where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb),
	-- Qué forma hay al otro lado de cada arquitectura reutilizada, para poder enlazarla.
	'formasReferenciadas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.forma_nombre)
		from (
			select distinct
				a.arquitectura_id,
				a.nombre as arquitectura_nombre,
				f.forma_id,
				f.slug as forma_slug,
				f.nombre as forma_nombre,
				f.nivel_estructural
			from public.estructuras_secciones s
			join public.arquitecturas_forma a
				on a.arquitectura_id = s.arquitectura_referenciada_id
			join public.formas_metricas f on f.forma_id = a.forma_id
			where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
				and f.activo
		) x
	), '[]'::jsonb),
	'repeticiones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.arquitectura_id, x.slug)
		from (
			select
				r.repeticion_id,
				r.arquitectura_id,
				r.slug,
				r.tipo,
				r.nombre,
				r.modalidad,
				r.descripcion,
				r.materializa_seccion_id,
				r.extension_desde_seccion_id
			from public.repeticiones_metricas r
			where r.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb),
	'restriccionesRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.esquema_rima_id, x.tipo)
		from (
			select
				x.restriccion_id,
				x.esquema_rima_id,
				x.tipo,
				x.valor_numero,
				x.valor_texto,
				x.esquema_referido_id,
				x.descripcion
			from public.esquema_rima_restricciones x
			join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
			where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$function$;

do $$
declare
	referenciadas jsonb;
begin
	referenciadas := public.get_forma_metrica_publica_jerarquica('soneto') -> 'formasReferenciadas';
	if jsonb_array_length(referenciadas) < 2 then
		raise exception 'el soneto reutiliza dos formas y la proyección devolvió %',
			jsonb_array_length(referenciadas);
	end if;
	if not (referenciadas -> 0 ? 'forma_slug') then
		raise exception 'las formas referenciadas llegan sin slug con el que enlazarlas';
	end if;
end;
$$;
