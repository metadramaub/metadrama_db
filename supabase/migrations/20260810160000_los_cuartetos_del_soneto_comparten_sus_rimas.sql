-- Los cuartetos del soneto comparten sus rimas, y la pregunta lo dice.
--
-- Los tercetos se arreglaron ayer; los cuartetos tenían el mismo defecto por el otro lado. La
-- pregunta ofrecía `ABBA` y `ABAB` **tomados de la forma Cuarteto** y se hacía una vez por cada
-- cuarteto, de modo que el modelo admitía un soneto `ABBA CDDC`: dos cuartetos abrazados con
-- rimas distintas, que no es un soneto. Que los dos comparten sus dos rimas vivía únicamente en
-- la ayuda al editor, en prosa.
--
-- Ahora son dos esquemas propios del soneto, de dos bloques de cuatro, con las clases A y B
-- compartidas entre ambos:
--
--   ABBA ABBA — Morley y Bruerton llaman a los ocho primeros versos «de rígido orden», y Quilis
--               y Jauralde dan esta disposición como la clásica.
--   ABAB ABAB — el *Diccionario* precisa que `ABBA ABBA` es lo normal «pero que son posibles
--               otras distribuciones, especialmente la que obedece al esquema ABAB ABAB».
--
-- Son las dos que la bibliografía autoriza, ni una más. La sección sigue remitiendo a la forma
-- Cuarteto y heredando de ella medida, extensión e identidad: lo único que no hereda es la rima,
-- según la regla de reutilización.
--
-- Y HACE FALTA UNA PIEZA, que ayer se vio venir. `seccion_id` en el grupo significa **dónde se
-- responde**: el editor plantea la pregunta en cada realización de esa sección. Los dos grupos
-- del soneto necesitan responderse **una sola vez** —su esquema describe las dos realizaciones a
-- la vez—, así que ninguno puede declararla. Pero entonces ninguno podía decir de qué trata, y
-- ambos habrían ofrecido los seis esquemas mezclados en cuanto existieran los de cuartetos.
--
-- `seccion_tratada_id` separa las dos cosas. El grupo dice de qué sección habla sin decir que se
-- pregunte en cada una, y con eso la derivación filtra por el dato en vez de por que no hubiera
-- otro. Solo el soneto la necesita hoy: es la única forma cuya sección con pregunta de rima se
-- repite más de una vez.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El grupo declara de qué sección trata
-- ---------------------------------------------------------------------------

alter table public.grupos_eleccion_metrica
	add column if not exists seccion_tratada_id uuid
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict;

comment on column public.grupos_eleccion_metrica.seccion_tratada_id is
	'De qué sección habla la respuesta, cuando no se pregunta en cada realización de esa sección. `seccion_id` dice dónde se responde; esta dice de qué trata. Los dos grupos del soneto se responden una sola vez y hablan, uno de los cuartetos y otro de los tercetos.';

-- ---------------------------------------------------------------------------
-- 2 · Los dos esquemas de cuartetos, propios del soneto
-- ---------------------------------------------------------------------------

insert into public.esquemas_rima (
	arquitectura_id, seccion_id, slug, nombre, notacion, ambito, tipo_secuencia,
	tipo_rima_id, descripcion, estado_revision
)
select a.arquitectura_id, s.seccion_id, v.slug, v.nombre, v.notacion, 'seccion', 'secuencia',
	(select er.tipo_rima_id from public.esquemas_rima er
	 where er.arquitectura_id = a.arquitectura_id and er.slug = 'cdecde'),
	v.descripcion, 'revisada'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.estructuras_secciones s
	on s.arquitectura_id = a.arquitectura_id and s.tipo_seccion = 'cuarteto'
cross join (values
	('abbaabba', 'Cuartetos de rima abrazada', 'ABBA ABBA',
		'Los dos cuartetos abrazan sus rimas y comparten las dos clases. Es la disposición normal del soneto, y Morley y Bruerton la describen como de orden rígido.'),
	('abababab', 'Cuartetos de rima cruzada', 'ABAB ABAB',
		'Los dos cuartetos alternan sus rimas y comparten las dos clases. El Diccionario la registra como la otra distribución posible, aunque es rara.')
) as v(slug, nombre, notacion, descripcion)
where f.slug = 'soneto'
	and not exists (
		select 1 from public.esquemas_rima e2
		where e2.arquitectura_id = a.arquitectura_id and e2.slug = v.slug
	);

-- Dos bloques de cuatro. Las clases A y B son las mismas en los dos, que es lo que hace del
-- conjunto un soneto y no dos cuartetos sueltos.
insert into public.esquema_rima_posiciones (esquema_rima_id, bloque, seccion, posicion, clase_rima)
select er.esquema_rima_id, p.bloque, 'cuarteto', p.posicion, p.clase
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
join lateral (values
	('abbaabba', 1, 1, 'A'), ('abbaabba', 1, 2, 'B'), ('abbaabba', 1, 3, 'B'), ('abbaabba', 1, 4, 'A'),
	('abbaabba', 2, 1, 'A'), ('abbaabba', 2, 2, 'B'), ('abbaabba', 2, 3, 'B'), ('abbaabba', 2, 4, 'A'),
	('abababab', 1, 1, 'A'), ('abababab', 1, 2, 'B'), ('abababab', 1, 3, 'A'), ('abababab', 1, 4, 'B'),
	('abababab', 2, 1, 'A'), ('abababab', 2, 2, 'B'), ('abababab', 2, 3, 'A'), ('abababab', 2, 4, 'B')
) as p(slug, bloque, posicion, clase) on p.slug = er.slug
where f.slug = 'soneto'
	and not exists (
		select 1 from public.esquema_rima_posiciones q
		where q.esquema_rima_id = er.esquema_rima_id
	);

-- Lo que cada fuente añade sobre ellos, que es de donde sale que sean dos y no más.
insert into public.afirmaciones_fuentes_metricas
	(fuente_id, esquema_rima_id, localizador, resumen, confianza, estado_revision)
select fu.fuente_id, er.esquema_rima_id, v.localizador, v.resumen, 'alta', 'revisada'
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
join lateral (values
	('abbaabba', 'S. Griswold Morley y Courtney Bruerton', 1968, 'Cap. V, «Soneto»',
		'Describen los ocho primeros versos del soneto como de rígido orden ABBAABBA, frente a los tercetos, que son la parte variable.'),
	('abababab', 'José Domínguez Caparrós', 2016, 'Entrada «soneto», p. 409',
		'Precisa que ABBA ABBA es lo normal en los cuartetos pero que son posibles otras distribuciones, «especialmente la que obedece al esquema ABAB ABAB».')
) as v(slug, autoria, anio, localizador, resumen) on v.slug = er.slug
join public.fuentes_metricas fu on fu.autoria = v.autoria and fu.anio = v.anio
where f.slug = 'soneto'
	and not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		where af.esquema_rima_id = er.esquema_rima_id and af.fuente_id = fu.fuente_id
	);

-- ---------------------------------------------------------------------------
-- 3 · Las dos preguntas del soneto dicen de qué tratan
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica g
set seccion_id = null,
	seccion_tratada_id = s.seccion_id,
	ayuda_editor = 'Los dos cuartetos comparten sus dos rimas. Elige cómo se disponen dentro de cada uno.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.estructuras_secciones s
	on s.arquitectura_id = a.arquitectura_id and s.tipo_seccion = 'cuarteto'
where g.arquitectura_id = a.arquitectura_id and f.slug = 'soneto' and g.slug = 'esquema_cuartetos';

update public.grupos_eleccion_metrica g
set seccion_tratada_id = s.seccion_id, updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.estructuras_secciones s
	on s.arquitectura_id = a.arquitectura_id and s.tipo_seccion = 'terceto'
where g.arquitectura_id = a.arquitectura_id and f.slug = 'soneto' and g.slug = 'esquema_tercetos';

-- Las cuatro equivalencias legadas apuntaban al ABBA de la forma Cuarteto. Los términos que las
-- traen empiezan todos por ABBAABBA, así que lo que implican es el esquema nuevo.
update public.equivalencias_respuestas_legadas e
set esquema_rima_id = (
	select er.esquema_rima_id
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto' and er.slug = 'abbaabba'
)
from public.grupos_eleccion_metrica g
where g.grupo_eleccion_id = e.grupo_eleccion_id and g.slug = 'esquema_cuartetos';

-- ---------------------------------------------------------------------------
-- 4 · La derivación filtra por la sección tratada
-- ---------------------------------------------------------------------------

drop view if exists public.propuesta_elecciones_secuencia;
drop view if exists public.grupos_eleccion_metrica_resueltos;
drop view if exists public.elecciones_editor_metrico_resueltas;
drop view if exists public.opciones_eleccion_metrica;
drop function if exists public.comparar_opciones_eleccion_metrica();
drop function if exists public.opciones_eleccion_derivadas();

create function public.opciones_eleccion_derivadas()
returns table (
	grupo_eleccion_id uuid,
	etiqueta text,
	descripcion text,
	metro_id uuid,
	esquema_metrico_id uuid,
	esquema_rima_id uuid,
	seccion_id uuid,
	repeticion_id uuid,
	valor_rasgo_id uuid,
	variedad_id uuid,
	posicion_unidad integer,
	materializa_seccion_id uuid,
	extension_desde_seccion_id uuid,
	orden integer
)
language sql
stable
set search_path to 'public'
as $function$
	-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
	-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
	select g.grupo_eleccion_id,
		concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''))::text,
		er.descripcion,
		null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
		null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by er.notacion, er.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	join public.esquemas_rima er
		on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
	where g.dimension = 'rima' and g.tipo_control = 'opciones' and g.activo
		and er.tipo_secuencia not in ('abierta', 'restricciones')
		and er.seccion_id is not distinct from g.seccion_tratada_id

	union all

	select g.grupo_eleccion_id,
		case when pos.posicion is null then adm.nombre
			else 'Verso ' || pos.posicion || ' · ' || adm.nombre end::text,
		null::text,
		adm.metro_id, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, null::uuid, pos.posicion, null::uuid, null::uuid,
		row_number() over (
			partition by g.grupo_eleccion_id order by pos.posicion, adm.silabas
		)::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join lateral (
		select eo.metro_id, mt.silabas, mt.nombre
		from public.esquema_metrico_opciones eo
		join public.metros mt on mt.metro_id = eo.metro_id
		where eo.esquema_metrico_id = em.esquema_metrico_id
			and (
				not exists (
					select 1 from public.esquema_metrico_opciones e2
					where e2.esquema_metrico_id = em.esquema_metrico_id and e2.rol is not null
				)
				or eo.rol = 'quebrado'
			)
	) adm on true
	join lateral (
		select case when em.medida_uniforme then null::integer else n end as posicion
		from generate_series(
			1,
			case when em.medida_uniforme then 1
				else coalesce(
					s.versos_max,
					(
						select sum(h.versos_max)::integer
						from public.estructuras_secciones h
						where h.seccion_padre_id = s.seccion_id
					),
					a.unidad_versos_max,
					1
				) end
		) as n
	) pos on true
	where g.dimension = 'metro' and g.tipo_control = 'opciones' and g.activo
		and em.medida_uniforme is not null

	union all

	select g.grupo_eleccion_id,
		('Verso ' || p.posicion || ' · ' || mt.nombre)::text,
		null::text,
		p.metro_id, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
		p.alternativa::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
	join public.metros mt on mt.metro_id = p.metro_id
	where g.dimension = 'metro' and g.tipo_control = 'opciones' and g.activo
		and em.medida_uniforme is null
		and p.posicion in (
			select p2.posicion from public.esquema_metrico_posiciones p2
			where p2.esquema_metrico_id = em.esquema_metrico_id
			group by p2.posicion having count(distinct p2.metro_id) > 1
		)

	union all

	select g.grupo_eleccion_id,
		case when adm.valores = 1 then r.nombre else adm.nombre end::text,
		adm.descripcion,
		null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	join lateral (
		select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
			rv.descripcion,
			(select count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
				as valores
		from public.arquitectura_rasgos ar
		join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
		where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = g.rasgo_id
			and (ar.valor_id is null or ar.valor_id = rv.valor_id)
	) adm on true
	where g.dimension = 'rasgo' and g.tipo_control = 'opciones' and g.activo
		and g.rasgo_id is not null

	union all

	select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
		null::uuid, null::uuid, null::uuid, null::uuid,
		rp.repeticion_id, null::uuid, null::uuid, null::integer,
		rp.materializa_seccion_id, rp.extension_desde_seccion_id,
		row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
	where g.dimension = 'repeticion' and g.tipo_control = 'opciones' and g.activo

	union all

	select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
		null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
	where g.dimension = 'combinacion' and g.tipo_control = 'opciones' and g.activo
$function$;

comment on function public.opciones_eleccion_derivadas() is
	'Las opciones que el catálogo produce para cada pregunta del editor, con su etiqueta y su descripción. La etiqueta es el nombre de la entidad, compuesto con la posición cuando la pregunta es posicional; la descripción sale de la entidad y no se escribe aparte.';

create view public.opciones_eleccion_metrica with (security_invoker = on) as
select
	md5(
		d.grupo_eleccion_id::text
		|| coalesce(d.metro_id::text, '')
		|| coalesce(d.esquema_metrico_id::text, '')
		|| coalesce(d.esquema_rima_id::text, '')
		|| coalesce(d.seccion_id::text, '')
		|| coalesce(d.repeticion_id::text, '')
		|| coalesce(d.valor_rasgo_id::text, '')
		|| coalesce(d.variedad_id::text, '')
		|| coalesce(d.posicion_unidad::text, '')
	)::uuid as opcion_eleccion_id,
	d.grupo_eleccion_id,
	regexp_replace(
		lower(translate(d.etiqueta, 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
		'[^a-z0-9]+', '-', 'g'
	) as slug,
	d.etiqueta as nombre,
	d.descripcion,
	d.metro_id,
	d.esquema_metrico_id,
	d.esquema_rima_id,
	d.seccion_id,
	d.repeticion_id,
	null::uuid as rasgo_id,
	d.valor_rasgo_id,
	true as activo,
	d.orden,
	now() as created_at,
	now() as updated_at,
	d.materializa_seccion_id,
	d.extension_desde_seccion_id,
	d.posicion_unidad,
	d.variedad_id
from public.opciones_eleccion_derivadas() d;

comment on view public.opciones_eleccion_metrica is
	'Las opciones de cada pregunta del editor, calculadas al leer desde el catálogo. No se escriben: cambiar un esquema, un rasgo o una repetición cambia el formulario en la lectura siguiente.';

grant select on public.opciones_eleccion_metrica to authenticated;

create view public.elecciones_editor_metrico_resueltas as
select e.*, o.opcion_eleccion_id
from public.elecciones_editor_metrico e
left join public.opciones_eleccion_metrica o
	on o.grupo_eleccion_id = e.grupo_eleccion_id
	and o.metro_id is not distinct from e.metro_id
	and o.esquema_metrico_id is not distinct from e.esquema_metrico_id
	and o.esquema_rima_id is not distinct from e.esquema_rima_id
	and o.seccion_id is not distinct from e.seccion_id
	and o.repeticion_id is not distinct from e.repeticion_id
	and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
	and o.variedad_id is not distinct from e.variedad_id
	and o.posicion_unidad is not distinct from e.posicion_unidad;

comment on view public.elecciones_editor_metrico_resueltas is
	'Las respuestas con la opción que hoy las ofrece, resuelta desde el dato que guardan.';

grant select on public.elecciones_editor_metrico_resueltas to authenticated;

create view public.grupos_eleccion_metrica_resueltos with (security_invoker = on) as
select g.*,
	case
		when g.dimension = 'rasgo' then rm.pregunta
		when g.dimension = 'repeticion' then rep.nombre
		else concat_ws(' · ', coalesce(s.nombre, st.nombre),
			case g.dimension
				when 'rima' then case
					when g.tipo_control = 'esquema_rima' then 'Esquema de rima observado'
					else 'Esquema de rima' end
				when 'metro' then case
					when m.quebrados then 'Medida de los quebrados'
					when m.posicional then 'Medida de cada verso'
					else 'Medida de los versos' end
				when 'combinacion' then 'Variedad'
			end)
	end as nombre
from public.grupos_eleccion_metrica g
left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
left join public.estructuras_secciones st on st.seccion_id = g.seccion_tratada_id
left join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
left join lateral (
	select coalesce(bool_and(o.posicion_unidad is not null), false) as posicional,
		coalesce(bool_and(eo.rol = 'quebrado'), false) as quebrados
	from public.opciones_eleccion_metrica o
	left join public.esquemas_metricos em on em.arquitectura_id = g.arquitectura_id
	left join public.esquema_metrico_opciones eo
		on eo.esquema_metrico_id = em.esquema_metrico_id and eo.metro_id = o.metro_id
	where o.grupo_eleccion_id = g.grupo_eleccion_id
) m on g.dimension = 'metro'
left join lateral (
	select ms.nombre
	from public.repeticiones_metricas rp
	join public.estructuras_secciones ms on ms.seccion_id = rp.materializa_seccion_id
	where rp.arquitectura_id = g.arquitectura_id
	limit 1
) rep on g.dimension = 'repeticion';

comment on view public.grupos_eleccion_metrica_resueltos is
	'Las preguntas del editor con su enunciado calculado al leer. El sujeto es la sección donde se responde, o la sección de la que trata cuando la respuesta es una sola para todas sus realizaciones. El editor pliega en una las preguntas que comparten dimensión y enunciado.';

grant select on public.grupos_eleccion_metrica_resueltos to authenticated;

create view public.propuesta_elecciones_secuencia as
with derivado as (
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null
	union all
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null
	union all
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null
	union all
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null
),
declarado as (
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
reclamado as (
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from derivado
	union
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from declarado
)
select p.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
	r.opcion_eleccion_id, o.nombre as respuesta, g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
join public.grupos_eleccion_metrica_resueltos g
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
	'Las respuestas que el término legado ya contenía, para cada secuencia. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

create function public.comparar_opciones_eleccion_metrica()
returns table (forma text, grupo text, escritas integer, derivadas integer, veredicto text)
language sql
stable
set search_path to 'public'
as $function$
	select f.nombre::text, g.slug::text,
		coalesce((
			select count(*)::integer from public.opciones_eleccion_metrica_manual o
			where o.grupo_eleccion_id = g.grupo_eleccion_id and o.activo
		), 0),
		coalesce((
			select count(*)::integer from public.opciones_eleccion_metrica d
			where d.grupo_eleccion_id = g.grupo_eleccion_id
		), 0),
		case
			when g.tipo_control <> 'opciones' then 'respuesta abierta'
			when coalesce((
				select count(*) from public.opciones_eleccion_metrica_manual o
				where o.grupo_eleccion_id = g.grupo_eleccion_id and o.activo), 0)
			= coalesce((
				select count(*) from public.opciones_eleccion_metrica d
				where d.grupo_eleccion_id = g.grupo_eleccion_id), 0)
			then 'coincide con lo que hubo'
			else 'difiere de lo que hubo'
		end::text
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.activo
	order by f.nombre, g.slug
$function$;

comment on function public.comparar_opciones_eleccion_metrica() is
	'Contrasta las opciones que ahora se derivan con las que se escribieron a mano hasta el 9 de agosto de 2026.';

grant execute on function public.opciones_eleccion_derivadas() to authenticated;
grant execute on function public.comparar_opciones_eleccion_metrica() to authenticated;

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Los cuartetos ofrecen ya los dos esquemas del soneto, no los de la forma Cuarteto.
	select string_agg(o.nombre, ' | ' order by o.nombre) into v_mal
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.slug = 'esquema_cuartetos';
	if v_mal <> 'Cuartetos de rima abrazada · ABBA ABBA | Cuartetos de rima cruzada · ABAB ABAB' then
		raise exception 'La pregunta de los cuartetos ofrece: %', v_mal;
	end if;

	-- Y cada pregunta del soneto ofrece solo lo suyo: ninguna ve los seis esquemas.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.slug = 'esquema_tercetos';
	if v_n <> 4 then
		raise exception 'La pregunta de los tercetos ofrece % opciones en vez de 4', v_n;
	end if;

	-- Los dos esquemas nuevos son dos bloques de cuatro con las mismas clases en ambos.
	select string_agg(p.clase_rima, '' order by p.bloque, p.posicion) into v_mal
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	where er.slug = 'abbaabba';
	if v_mal <> 'ABBAABBA' then
		raise exception 'Las clases de «ABBA ABBA» quedaron como %', v_mal;
	end if;

	select count(*) into v_n
	from public.esquemas_rima er
	where er.slug in ('abbaabba', 'abababab')
		and (
			select count(distinct p.bloque) from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id
		) <> 2;
	if v_n <> 0 then
		raise exception '% esquemas de cuartetos no se reparten en dos bloques', v_n;
	end if;

	-- Los enunciados nombran su sección aunque la pregunta se responda una sola vez.
	select nombre into v_mal from public.grupos_eleccion_metrica_resueltos where slug = 'esquema_cuartetos';
	if v_mal <> 'Cuartetos · Esquema de rima' then
		raise exception 'El grupo de los cuartetos se llama «%»', v_mal;
	end if;
	select nombre into v_mal from public.grupos_eleccion_metrica_resueltos where slug = 'esquema_tercetos';
	if v_mal <> 'Tercetos · Esquema de rima' then
		raise exception 'El grupo de los tercetos se llama «%»', v_mal;
	end if;

	select count(*) into v_n
	from public.grupos_eleccion_metrica_resueltos
	where activo and coalesce(btrim(nombre), '') = '';
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin enunciado', v_n;
	end if;

	-- Ninguna pregunta puede responderse en cada realización de una sección que se repite
	-- mientras su esquema describa todas a la vez: se preguntaría dos veces lo mismo.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	where g.activo and g.dimension = 'rima' and coalesce(s.repeticiones_max, 1) > 1;
	if v_n <> 0 then
		raise exception '% preguntas de rima se responden en cada realización de una sección repetida', v_n;
	end if;

	-- Y lo de siempre: el plegado, las opciones y lo que el término legado proponía.
	select count(*) into v_n from (
		select 1 from public.grupos_eleccion_metrica_resueltos
		where activo group by arquitectura_id, dimension, nombre having count(*) > 1
	) s;
	if v_n <> 3 then
		raise exception 'El editor plegaría % preguntas en vez de las 3 del villancico', v_n;
	end if;

	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then
		raise exception 'Las opciones derivadas dejaron de ser 405 y son %', v_n;
	end if;

	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'La propuesta de respuestas debe seguir dando 91 filas, y da %', v_n;
	end if;

	select count(*) into v_n from public.elecciones_editor_metrico_resueltas
	where opcion_eleccion_id is null;
	if v_n <> 0 then
		raise exception '% respuestas guardadas dejaron de resolverse a una opción', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
