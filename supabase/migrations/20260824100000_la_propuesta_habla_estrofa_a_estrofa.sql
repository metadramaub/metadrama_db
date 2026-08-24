-- La propuesta habla estrofa a estrofa
--
-- Segunda migración de A1. `propuesta_elecciones_secuencia` proponía las preguntas de alcance
-- `unidad` **solo cuando la secuencia medía exactamente una estrofa**:
--
--     where g.alcance = 'secuencia'
--        or g.alcance = 'unidad' and a.unidad_versos_min is not null
--           and (p.v_fin - p.v_ini + 1) = a.unidad_versos_min
--
-- Es la mitad del catálogo: **42 de las preguntas activas son de alcance `unidad`**. Con esa
-- cláusula, una redondilla de 472 versos no recibía ninguna propuesta y un sexteto-lira de 192
-- tampoco, aunque su término legado declarase la variedad; solo la acertaban los pasajes de una
-- estrofa suelta. De ahí venían casi todas las secuencias «incompletas».
--
-- La vista pasa a **dar una fila por estrofa**, con el rango de versos de cada una. Es el lenguaje
-- que habla el editor: `api/metrica/editor-pruebas` recibe *unidades* con su `v_ini` y su `v_fin`,
-- que se guardan en `realizaciones_editor_metrico`. *Ojo con `posicion_unidad`, que no sirve para
-- esto: es el verso dentro de la estrofa —«Verso 3 · Tetrasílabo»—, no el número de estrofa.*
--
-- Y con ello entra el segundo depósito de la revisión del vocabulario legado: las **336 tipologías
-- de quintilla** que `secuencias_subtipos_estrofa` guarda estrofa a estrofa desde que se anotaron.
-- Esas **no son propuesta sino anotación**, y la vista las distingue en la columna `origen`:
--
-- - `anotada` — alguien lo miró verso a verso. Se traslada.
-- - `derivada` — se deduce de cómo se catalogó la secuencia. **Puede ser falsa estrofa a estrofa**,
--   y es lo que el editor tiene que revisar.
--
-- Las columnas nuevas van al final para no romper a quien ya lee la vista por nombre.

begin;

create or replace view public.propuesta_elecciones_secuencia as
with reclamado as (
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null
	union
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null
	union
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null
	union
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null
	union
	select e.termino_id, e.grupo_eleccion_id, o.opcion_eleccion_id
	from public.equivalencias_respuestas_legadas e
	join public.opciones_eleccion_metrica o
		on o.grupo_eleccion_id = e.grupo_eleccion_id
		and o.metro_id is not distinct from e.metro_id
		and o.esquema_rima_id is not distinct from e.esquema_rima_id
		and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
		and o.variedad_id is not distinct from e.variedad_id
		and o.repeticion_id is not distinct from e.repeticion_id
		and o.posicion_unidad is not distinct from e.posicion_unidad
),
base as (
	select
		p.secuencia_id, p.estrofa_tipo_id, p.v_ini, p.v_fin, p.arquitectura_propuesta_id,
		a.unidad_versos_min as unidad
	from public.propuesta_metrica_secuencia p
	left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
),
-- Las estrofas de cada secuencia, cuando la arquitectura fija su tamaño. Si no lo fija —el romance,
-- la silva, el endecasílabo suelto— no hay estrofas que recorrer y solo caben las de secuencia.
unidades as (
	select
		b.secuencia_id, b.estrofa_tipo_id, b.arquitectura_propuesta_id,
		b.v_ini + (i - 1) * b.unidad as unidad_v_ini,
		b.v_ini + i * b.unidad - 1 as unidad_v_fin
	from base b
	cross join generate_series(1, (b.v_fin - b.v_ini + 1) / b.unidad) as i
	where b.unidad is not null and b.unidad > 0
		and (b.v_fin - b.v_ini + 1) >= b.unidad
),
-- Lo que se anotó estrofa a estrofa en su día: se traslada, no se propone.
--
-- **Los rangos los pone la anotación, no la rejilla calculada.** Al dividir la secuencia entre el
-- tamaño de la unidad se perdían 38 tipologías: una secuencia de 258 versos no es múltiplo de
-- cinco y a partir de cierto punto la rejilla se desplazaba, y hay además **una estrofa de cuatro
-- versos y otra de tres** que alguien anotó como tales. Quien miró el texto sabe dónde empieza
-- cada estrofa mejor que una división.
anotada as (
	select distinct
		b.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
		o.opcion_eleccion_id, o.nombre as respuesta, g.alcance,
		t.v_ini as unidad_v_ini, t.v_fin as unidad_v_fin
	from base b
	join public.secuencias_subtipos_estrofa t on t.secuencia_id = b.secuencia_id
	join public.esquemas_rima er on er.origen_termino_id = t.subtipo_estrofa_id
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	join public.grupos_eleccion_metrica_resueltos g
		on g.grupo_eleccion_id = o.grupo_eleccion_id
		and g.arquitectura_id = b.arquitectura_propuesta_id
		and g.activo and g.alcance = 'unidad'
),
-- Lo que se deduce del término legado, repetido en cada estrofa de la secuencia.
derivada_unidad as (
	select
		u.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
		r.opcion_eleccion_id, o.nombre as respuesta, g.alcance,
		u.unidad_v_ini, u.unidad_v_fin
	from unidades u
	join reclamado r on r.termino_id = u.estrofa_tipo_id
	join public.grupos_eleccion_metrica_resueltos g
		on g.grupo_eleccion_id = r.grupo_eleccion_id
		and g.arquitectura_id = u.arquitectura_propuesta_id
		and g.activo and g.alcance = 'unidad'
	join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
	-- Si esa pregunta ya está anotada estrofa a estrofa, la anotación cubre la secuencia entera y
	-- no se deriva nada: mezclar los rangos reales con los de la rejilla contestaría dos veces.
	where not exists (
		select 1 from anotada an
		where an.secuencia_id = u.secuencia_id
			and an.grupo_eleccion_id = g.grupo_eleccion_id
	)
),
-- Y lo que se responde una sola vez para toda la secuencia.
derivada_secuencia as (
	select
		b.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
		r.opcion_eleccion_id, o.nombre as respuesta, g.alcance,
		null::integer as unidad_v_ini, null::integer as unidad_v_fin
	from base b
	join reclamado r on r.termino_id = b.estrofa_tipo_id
	join public.grupos_eleccion_metrica_resueltos g
		on g.grupo_eleccion_id = r.grupo_eleccion_id
		and g.arquitectura_id = b.arquitectura_propuesta_id
		and g.activo and g.alcance <> 'unidad'
	join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
)
select secuencia_id, grupo_eleccion_id, pregunta, opcion_eleccion_id, respuesta, alcance,
	unidad_v_ini, unidad_v_fin, 'anotada'::text as origen
from anotada
union all
select secuencia_id, grupo_eleccion_id, pregunta, opcion_eleccion_id, respuesta, alcance,
	unidad_v_ini, unidad_v_fin, 'derivada'::text
from derivada_unidad
union all
select secuencia_id, grupo_eleccion_id, pregunta, opcion_eleccion_id, respuesta, alcance,
	unidad_v_ini, unidad_v_fin, 'derivada'::text
from derivada_secuencia;

comment on view public.propuesta_elecciones_secuencia is 'Respuestas propuestas para migrar una secuencia anotada al catálogo nuevo. Una fila por pregunta y, en las de alcance «unidad», una por estrofa con su rango de versos. La columna «origen» distingue lo anotado en su día —que se traslada— de lo derivado del término legado, que el editor debe revisar.';

-- ------------------------------------------------------------------------------ Comprobaciones
do $$
declare
	v_n integer;
	v_dido uuid := '1ee72138-24fd-4af6-bbcc-a01d05bcec55';
begin
	-- 1. Las 336 tipologías anotadas llegan a la propuesta, y llegan como anotadas.
	select count(*) into v_n from public.propuesta_elecciones_secuencia where origen = 'anotada';
	if v_n <> 336 then
		raise exception 'Llegan % respuestas anotadas a la propuesta; se esperaban las 336.', v_n;
	end if;

	-- 2. Ninguna respuesta de alcance «unidad» se queda sin decir a qué estrofa pertenece.
	select count(*) into v_n from public.propuesta_elecciones_secuencia
	where alcance = 'unidad' and unidad_v_ini is null;
	if v_n <> 0 then
		raise exception '% respuestas por estrofa no dicen a qué estrofa pertenecen.', v_n;
	end if;

	-- 3. Y ninguna de secuencia se inventa una.
	select count(*) into v_n from public.propuesta_elecciones_secuencia
	where alcance <> 'unidad' and unidad_v_ini is not null;
	if v_n <> 0 then
		raise exception '% respuestas de secuencia se atribuyen a una estrofa.', v_n;
	end if;

	-- 4. Lo anotado y lo derivado no se pisan: una estrofa no recibe dos respuestas a la misma
	--    pregunta. **Se compara por verso, no por estrofa**, porque hay preguntas que traen una
	--    opción para cada verso de la unidad —el pareado endecasílabo contesta «Endecasílabo» en
	--    el verso 1 y otra vez en el verso 2, y las dos son correctas—.
	select count(*) into v_n from (
		select pe.secuencia_id, pe.grupo_eleccion_id, pe.unidad_v_ini, o.posicion_unidad
		from public.propuesta_elecciones_secuencia pe
		join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = pe.opcion_eleccion_id
		where pe.alcance = 'unidad'
		group by 1, 2, 3, 4 having count(*) > 1
	) x;
	if v_n <> 0 then
		raise exception '% estrofas reciben dos respuestas a la misma pregunta y verso.', v_n;
	end if;

	-- 5. El caso que motivó la migración: el sexteto-lira de 192 versos de «Dido y Eneas» declara
	--    su variedad en el término legado y hasta hoy no la recibía por medir más de una estrofa.
	select count(*) into v_n
	from public.propuesta_elecciones_secuencia pe
	join public.propuesta_metrica_secuencia p on p.secuencia_id = pe.secuencia_id
	where p.obra_id = v_dido and p.v_ini = 187 and pe.alcance = 'unidad';
	if v_n <> 32 then
		raise exception 'El sexteto-lira de Dido recibe % respuestas; son 32 estrofas.', v_n;
	end if;
end $$;

commit;
