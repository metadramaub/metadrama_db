-- Las opciones del editor dejan de ser una tabla y pasan a calcularse al leer.
--
-- Es el final del camino que empezó al auditar las preguntas. Estaban escritas a mano, una a
-- una, 405 filas que había que mantener en paralelo al catálogo; se comprobó que **todas se
-- derivan de él**, se soltó la respuesta del editor y la equivalencia legada de la opción para
-- que nada guardado dependiera de su identidad, y ya no queda razón para almacenarlas.
--
-- La tabla se conserva renombrada como `opciones_eleccion_metrica_manual`, porque es el
-- registro de lo que hubo y permite comparar. La vista toma su nombre, de modo que **las cinco
-- funciones SQL y el editor siguen leyendo lo mismo sin enterarse**.
--
-- POR QUÉ UNA VISTA Y NO UNA REGENERACIÓN. Materializar obligaría a regenerar con cada cambio
-- del catálogo y abriría la puerta a que las dos cosas se separasen, que es el problema que se
-- venía arrastrando. Calculada al leer, la pregunta no puede quedarse vieja: cambiar un esquema
-- cambia el formulario en la siguiente lectura. Con 405 opciones el coste es irrelevante.
--
-- LA IDENTIDAD DE LA OPCIÓN se deriva del contenido —la pregunta, el dato al que apunta y la
-- posición—, de modo que es estable mientras lo sea el catálogo. Ya no hay nada guardado que
-- dependa de ella: ni las respuestas del editor, ni la equivalencia legada, ni ninguna clave
-- foránea, que se retiraron a propósito antes de llegar aquí.
--
-- LAS DESCRIPCIONES PASAN A SALIR DE LA ENTIDAD, y eso corrige errores reales. Las de metro
-- repetían la etiqueta —«El verso 17 tiene 7 sílabas»—. Y las de la quintilla estaban
-- copiadas de la redondilla y eran **falsas**: a `aabab` se le atribuía «dos rimas dispuestas
-- de forma cruzada» y la denominación «Cuarteta», que describen `abab` y no una quintilla. Su
-- esquema, en cambio, dice lo correcto: «abre con un pareado y sigue alternando; la
-- bibliografía la registra como muy rara». Derivar no solo homogeneiza: destapa y arregla.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La derivación produce ya todo lo que la tabla tenía
-- ---------------------------------------------------------------------------

drop view if exists public.propuesta_elecciones_secuencia;
drop view if exists public.elecciones_editor_metrico_resueltas;
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

-- ---------------------------------------------------------------------------
-- 2 · La tabla se aparta y la vista toma su nombre
-- ---------------------------------------------------------------------------

alter table public.opciones_eleccion_metrica rename to opciones_eleccion_metrica_manual;

comment on table public.opciones_eleccion_metrica_manual is
	'Las opciones tal como se escribieron a mano hasta el 9 de agosto de 2026. Ya no se lee: `opciones_eleccion_metrica` es ahora una vista que las deriva del catálogo. Se conserva para poder comparar, y puede retirarse cuando la derivación se haya usado con datos reales.';

-- `security_invoker` conserva el acceso que tenía la tabla: sus trece tablas de origen están
-- todas restringidas a admin/IP con la misma política, y sin esto la vista se leería con los
-- permisos de su dueño y abriría a cualquier autenticado lo que hoy no lo está.
create view public.opciones_eleccion_metrica with (security_invoker = on) as
select
	-- La identidad sale del contenido, así que es estable mientras lo sea el catálogo.
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
	-- El slug también se deriva, del mismo contenido que la etiqueta.
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
	'Las opciones de cada pregunta del editor, calculadas al leer desde el catálogo. No se escriben: cambiar un esquema, un rasgo o una repetición cambia el formulario en la lectura siguiente, sin regenerar nada y sin que puedan quedarse viejas.';

grant select on public.opciones_eleccion_metrica to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · Lo que dependía de la tabla vuelve, leyendo la vista
-- ---------------------------------------------------------------------------

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
	'Las respuestas que el término legado ya contenía, para cada secuencia. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

-- La comprobación pasa a contrastar la derivación con lo que hubo escrito a mano.
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
	'Contrasta las opciones que ahora se derivan con las que se escribieron a mano hasta el 9 de agosto de 2026. Sirve para comprobar que la derivación no perdió nada; cuando la tabla apartada se retire, esta función se va con ella.';

grant execute on function public.opciones_eleccion_derivadas() to authenticated;
grant execute on function public.comparar_opciones_eleccion_metrica() to authenticated;

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then
		raise exception 'La vista debe dar las mismas 405 opciones, y da %', v_n;
	end if;

	select count(*) into v_n from public.comparar_opciones_eleccion_metrica()
	where veredicto = 'difiere de lo que hubo';
	if v_n <> 0 then
		raise exception 'La derivación difiere de lo escrito en % preguntas', v_n;
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

	-- Y la identidad derivada tiene que ser única: si dos opciones colisionaran, el editor
	-- no podría distinguirlas.
	select count(*) into v_n from (
		select opcion_eleccion_id from public.opciones_eleccion_metrica
		group by 1 having count(*) > 1
	) s;
	if v_n <> 0 then
		raise exception '% identidades de opción colisionan', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
