-- La vista devuelve también la pregunta, derivada
--
-- La respuesta ya no guarda a qué pregunta contesta, pero **el formulario sí necesita saberlo** para
-- pintarla: de la pregunta salen el rótulo, el control y las opciones. Antes de esto, releer una
-- secuencia anotada obligaba al cliente a resolverlo, y el cliente no tiene a mano ni la sección de
-- la realización ni la arquitectura que esa sección reutiliza.
--
-- Así que lo resuelve la vista, que es donde ya se resolvía la opción. **La tabla sigue guardando lo
-- que la respuesta afirma; la vista ofrece lo que hace falta para volver a pintarla.** El camino de
-- lectura del editor no cambia ni una línea.
--
-- La pregunta se busca en dos sitios, y ese segundo es el que cierra la reutilización:
--
--   1. en la arquitectura de la secuencia, dirigida a la unidad o a la parte que corresponda;
--   2. **o en la arquitectura que esa parte reutiliza**, donde la pregunta no tiene sección propia.
--      Es lo que permite releer la rima de la oncena y del septeto compuesto, que no tienen fila de
--      pregunta y hasta hoy ni siquiera podían guardarla.
--
-- Cuando varias preguntas encajan se prefiere **la que de verdad ofrece esa respuesta**, que es lo
-- que ordena el `order by`: una pregunta que no la ofrece encaja por dimensión pero no la explica.

begin;

drop view if exists public.anotacion_elecciones_resueltas;

create view public.anotacion_elecciones_resueltas as
select
	e.*,
	resuelta.grupo_eleccion_id,
	resuelta.opcion_eleccion_id
from public.anotacion_elecciones e
join public.anotaciones_metricas am on am.anotacion_id = e.anotacion_id
left join public.anotacion_realizaciones rz on rz.realizacion_id = e.realizacion_id
left join public.estructuras_secciones sp on sp.seccion_id = rz.seccion_id
left join lateral (
	select g.grupo_eleccion_id, o.opcion_eleccion_id
	from public.grupos_eleccion_metrica g
	left join public.opciones_eleccion_metrica o
		on o.grupo_eleccion_id = g.grupo_eleccion_id
		and o.metro_id is not distinct from e.metro_id
		and o.esquema_metrico_id is not distinct from e.esquema_metrico_id
		and o.esquema_rima_id is not distinct from e.esquema_rima_id
		and o.seccion_id is not distinct from e.seccion_id
		and o.repeticion_id is not distinct from e.repeticion_id
		and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
		and o.variedad_id is not distinct from e.variedad_id
		and o.posicion_unidad is not distinct from e.posicion_unidad
	where g.activo
		and g.dimension = e.dimension
		and g.seccion_tratada_id is not distinct from e.seccion_tratada_id
		and (
			(
				g.arquitectura_id = am.arquitectura_id
				and g.seccion_id is not distinct from (
					case when rz.realizacion_padre_id is not null then rz.seccion_id end
				)
			)
			or (g.arquitectura_id = sp.arquitectura_referenciada_id and g.seccion_id is null)
		)
		-- Un rasgo se distingue por su valor, que pertenece a uno solo: el endecasílabo suelto
		-- tiene cinco preguntas de rasgo y ninguna ambigüedad.
		and (
			e.dimension <> 'rasgo'
			or exists (
				select 1 from public.rasgo_valores rv
				where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = g.rasgo_id
			)
		)
	order by (o.opcion_eleccion_id is not null) desc, g.orden nulls last
	limit 1
) resuelta on true;

comment on view public.anotacion_elecciones_resueltas is
	'Las respuestas con la pregunta y la opción que les corresponden hoy, derivadas de lo que cada una afirma.';

do $comprobacion$
declare
	v_cols integer;
	v_filas integer;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la vista.** Una vista con un lateral mal escrito compila igual y solo falla al
	-- leerse; y sin estas dos columnas el editor no podría volver a pintar lo guardado.
	select count(*) into v_cols
	from information_schema.columns
	where table_name = 'anotacion_elecciones_resueltas'
		and column_name in ('grupo_eleccion_id', 'opcion_eleccion_id', 'dimension', 'seccion_tratada_id');

	if v_cols <> 4 then
		raise exception 'La vista devuelve % de las 4 columnas que el editor necesita.', v_cols;
	end if;

	select count(*) into v_filas from public.anotacion_elecciones_resueltas;
	raise notice 'La vista resuelve y devuelve % filas.', v_filas;
end
$comprobacion$;

commit;
