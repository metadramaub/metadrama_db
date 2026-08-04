-- La propuesta llega también con las respuestas, no solo con la forma.
--
-- El término legado de un romance codifica la asonancia: `romance_o-e` dice «romance» y
-- «o-e». La forma ya la resolvía `propuesta_metrica_secuencia`; la asonancia se quedaba en
-- el camino y el editor tenía que volver a elegirla a mano, teniendo el dato delante.
--
-- La cadena para deducirla ya existía entera: el término lo reclama un valor de rasgo, y la
-- opción del formulario apunta a ese mismo valor. Solo faltaba recorrerla.
--
-- Cubre 71 respuestas de ámbito secuencia —todas las asonancias del corpus— y 10 de ámbito
-- unidad, que son los tercetos de los sonetos y las tipologías de sexteto-lira.
--
-- Es la misma fuente para el dashboard y para `npm run migracion:informe`.

begin;

create or replace view public.propuesta_elecciones_secuencia as
with reclamado as (
	-- Qué opción del formulario selecciona la entidad que reclama el término legado.
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null and o.activo

	union all
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null and o.activo

	union all
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null and o.activo

	union all
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null and o.activo
)
select
	p.secuencia_id,
	g.grupo_eleccion_id,
	g.nombre as pregunta,
	r.opcion_eleccion_id,
	o.nombre as respuesta,
	g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
-- La pregunta tiene que ser de la arquitectura que se propone: el mismo valor de asonancia
-- lo ofrecen las cuatro arquitecturas del romance, y solo vale la de esta secuencia.
join public.grupos_eleccion_metrica g
	on g.grupo_eleccion_id = r.grupo_eleccion_id
	and g.arquitectura_id = p.arquitectura_propuesta_id
	and g.activo
join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
where
	g.alcance = 'secuencia'
	-- Una respuesta por unidad solo se propone cuando la secuencia es exactamente una unidad:
	-- si contiene varias, el término legado decía una sola cosa de todas ellas y darla por
	-- buena afirmaría que son idénticas. En Dido y Eneas sabemos que no lo son.
	or (
		g.alcance = 'unidad'
		and a.unidad_versos_min is not null
		and p.v_fin - p.v_ini + 1 = a.unidad_versos_min
	);

comment on view public.propuesta_elecciones_secuencia is
	'Respuestas del formulario que se deducen del término legado de cada secuencia: la asonancia de un romance, el esquema de los tercetos de un soneto, la tipología de un sexteto-lira. Las de ámbito unidad solo aparecen cuando la secuencia es una sola unidad. Es una propuesta para revisar, no una asignación.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

commit;
