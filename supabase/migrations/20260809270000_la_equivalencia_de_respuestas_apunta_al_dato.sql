-- La equivalencia de respuestas legadas apunta al dato, no a la opción.
--
-- Es el mismo desacople que se hizo con las respuestas del editor, y por la misma razón:
-- `equivalencias_respuestas_legadas` declara qué respuesta implica un término legado, y lo
-- declaraba **apuntando a una opción**. Mientras exista esa clave foránea, las opciones no
-- pueden dejar de ser una tabla.
--
-- Son siete filas, todas del soneto: los cuatro términos que llevan el esquema completo en su
-- nombre empiezan por `ABBAABBA` y por tanto implican cuartetos abrazados, pero el esquema
-- «Abrazada» solo puede declarar un origen y esos términos ya están reclamados por sus
-- esquemas de tercetos. Esta tabla existe justamente para eso, para decir a mano lo que la
-- columna única no da de sí.
--
-- Lo que cambia es a qué apunta: al esquema de rima, al metro, al valor de rasgo o a la
-- variedad que el término implica. La pregunta sigue declarándose, porque una misma entidad
-- puede ofrecerse en varias y hay que decir en cuál.
--
-- La vista `propuesta_elecciones_secuencia` se rehace para leerlo así. Sigue devolviendo las
-- mismas 91 respuestas propuestas y las mismas columnas, de modo que la anotación en sombra y
-- el informe por obra no se enteran.

begin;

alter table public.equivalencias_respuestas_legadas
	add column if not exists metro_id uuid references public.metros (metro_id)
		on update cascade on delete restrict,
	add column if not exists esquema_rima_id uuid
		references public.esquemas_rima (esquema_rima_id)
		on update cascade on delete restrict,
	add column if not exists valor_rasgo_id uuid references public.rasgo_valores (valor_id)
		on update cascade on delete restrict,
	add column if not exists variedad_id uuid
		references public.variedades_arquitectura (variedad_id)
		on update cascade on delete restrict,
	add column if not exists repeticion_id uuid
		references public.repeticiones_metricas (repeticion_id)
		on update cascade on delete restrict,
	add column if not exists posicion_unidad integer;

update public.equivalencias_respuestas_legadas e
set metro_id = o.metro_id,
	esquema_rima_id = o.esquema_rima_id,
	valor_rasgo_id = o.valor_rasgo_id,
	variedad_id = o.variedad_id,
	repeticion_id = o.repeticion_id,
	posicion_unidad = o.posicion_unidad
from public.opciones_eleccion_metrica o
where o.opcion_eleccion_id = e.opcion_eleccion_id;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.equivalencias_respuestas_legadas
	where num_nonnulls(metro_id, esquema_rima_id, valor_rasgo_id, variedad_id, repeticion_id) <> 1;
	if v_n <> 0 then
		raise exception 'Quedan % equivalencias sin traspasar su dato', v_n;
	end if;
end;
$$;

-- La vista depende de la columna, así que se rehace después de retirarla.
drop view if exists public.propuesta_elecciones_secuencia;

alter table public.equivalencias_respuestas_legadas drop column opcion_eleccion_id;

alter table public.equivalencias_respuestas_legadas
	add constraint equivalencias_respuestas_legadas_una_entidad
	check (
		num_nonnulls(metro_id, esquema_rima_id, valor_rasgo_id, variedad_id, repeticion_id) = 1
	);

comment on table public.equivalencias_respuestas_legadas is
	'Qué respuesta implica un término legado, cuando no se puede deducir siguiendo `origen_termino_id` porque varios términos comparten destino. Declara el dato del catálogo que el término implica y en qué pregunta se ofrece, no la opción, para que las opciones puedan derivarse.';

create view public.propuesta_elecciones_secuencia as
with derivado as (
	-- Lo que se deduce siguiendo el origen legado de la propia entidad.
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
),
declarado as (
	-- Y lo que se declara a mano, que ahora nombra el dato y se resuelve a la opción que hoy
	-- lo ofrece dentro de esa pregunta.
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
	where o.activo
),
reclamado as (
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from derivado
	union
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from declarado
)
select p.secuencia_id,
	g.grupo_eleccion_id,
	g.nombre as pregunta,
	r.opcion_eleccion_id,
	o.nombre as respuesta,
	g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
join public.grupos_eleccion_metrica g
	on g.grupo_eleccion_id = r.grupo_eleccion_id
	and g.arquitectura_id = p.arquitectura_propuesta_id
	and g.activo
join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
where g.alcance = 'secuencia'
	or g.alcance = 'unidad'
		and a.unidad_versos_min is not null
		and (p.v_fin - p.v_ini + 1) = a.unidad_versos_min;

comment on view public.propuesta_elecciones_secuencia is
	'Las respuestas que el término legado ya contenía, para cada secuencia. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad: si contiene varias, el término decía una sola cosa de todas ellas y darla por buena afirmaría que son idénticas.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'La propuesta de respuestas debe seguir dando 91 filas, y da %', v_n;
	end if;

	select count(*) into v_n
	from pg_constraint
	where confrelid = 'public.opciones_eleccion_metrica'::regclass;
	if v_n <> 0 then
		raise exception 'Todavía hay % claves foráneas hacia las opciones', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
