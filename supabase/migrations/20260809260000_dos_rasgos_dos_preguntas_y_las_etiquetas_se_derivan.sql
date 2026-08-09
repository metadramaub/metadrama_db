-- Dos rasgos son dos preguntas, y las etiquetas se derivan.
--
-- Tres cosas que cierran la derivación de las opciones.
--
-- 1 · LA ÚLTIMA PREGUNTA QUE NO SE DERIVABA. `rasgos_de_la_serie` del endecasílabo suelto
-- reunía **dos rasgos independientes** en una lista de casillas: el dístico final y el
-- encadenamiento interior, cada uno con un único valor, «Presente». No es un rasgo con dos
-- valores sino dos preguntas de sí o no presentadas juntas, y por eso el grupo no podía
-- declarar sobre qué rasgo preguntaba.
--
-- Se parte en dos. Son dos hechos métricos independientes —que la serie cierre con dístico y
-- que encadene la rima por dentro— y el modelo no debe atarlos porque la pantalla los pinte
-- seguidos. Agruparlos visualmente sigue siendo posible: es presentación, y la presentación
-- puede ordenar por dimensión sin que el dato los una.
--
-- 2 · LAS ETIQUETAS SE DERIVAN. Analizadas las 405 escritas a mano, la regla es una sola: **la
-- etiqueta es el nombre de la entidad**, compuesto con la posición cuando la pregunta es
-- posicional. Se añade a la derivación:
--
--     combinación      el nombre de la variedad
--     rasgo            el nombre del valor, o el del rasgo cuando su único valor es «Presente»
--     rima             el nombre del esquema y su notación
--     metro uniforme   el nombre del metro
--     metro posicional «Verso N · » y el nombre del metro
--     repetición       el nombre de la repetición
--
-- Homogeneizarlas es una mejora, no una pérdida. Hoy la misma clase de opción se rotula de
-- maneras distintas según la forma —«Tipología 7 · ababb», «CDE CDE · rima paralela»,
-- «Redondilla cruzada · abab (cuarteta)»—, porque se escribieron una a una.
--
-- 3 · SE RETIRA `p_aplicar`. Estaba puesto para poder escribir las opciones derivadas en la
-- tabla, y **era un reflejo equivocado**: materializar solo hacía falta mientras las respuestas
-- apuntaran a la opción, y dejaron de hacerlo. Con la respuesta atada al dato del catálogo, las
-- opciones pueden calcularse al leer y no hay nada que sincronizar ni que se pueda
-- desincronizar. La función queda como lo que de verdad es: una comprobación.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Dos rasgos, dos preguntas
-- ---------------------------------------------------------------------------

do $$
declare
	v_grupo uuid;
	v_arq uuid;
	v_orden integer;
	v_alcance text;
	v_distico uuid;
	v_encadenamiento uuid;
	v_n integer;
begin
	select g.grupo_eleccion_id, g.arquitectura_id, g.orden, g.alcance
	into v_grupo, v_arq, v_orden, v_alcance
	from public.grupos_eleccion_metrica g
	where g.slug = 'rasgos_de_la_serie';

	if v_grupo is null then
		raise exception 'No está la pregunta rasgos_de_la_serie';
	end if;

	select count(*) into v_n from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo;
	if v_n <> 0 then
		raise exception 'La pregunta tiene % respuestas guardadas y no se puede partir sin migrarlas', v_n;
	end if;

	select rasgo_id into v_distico from public.rasgos_metricos where slug = 'distico_final';
	select rasgo_id into v_encadenamiento from public.rasgos_metricos
	where slug = 'encadenamiento_interior';

	if num_nonnulls(v_distico, v_encadenamiento) <> 2 then
		raise exception 'Faltan los rasgos del dístico final o del encadenamiento interior';
	end if;

	delete from public.opciones_eleccion_metrica where grupo_eleccion_id = v_grupo;
	delete from public.grupos_eleccion_metrica where grupo_eleccion_id = v_grupo;

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, rasgo_id,
		selecciones_min, selecciones_max, tipo_control, estado_revision, activo, orden
	)
	values
		(v_arq, 'distico_final', '¿Cierra con un dístico?',
		 'Déjalo sin marcar cuando la serie no termine en pareado.',
		 'rasgo', v_alcance, v_distico, 0, 1, 'opciones', 'revisada', true, v_orden),
		(v_arq, 'encadenamiento_interior', '¿Encadena la rima por dentro?',
		 'Déjalo sin marcar cuando los versos no enlacen su rima final con el interior del siguiente.',
		 'rasgo', v_alcance, v_encadenamiento, 0, 1, 'opciones', 'revisada', true, v_orden + 1);

	-- Las opciones de las dos nuevas se escriben todavía a mano, como las demás, pero ya son
	-- exactamente las que la derivación produce.
	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, valor_rasgo_id, orden)
	select g.grupo_eleccion_id, r.slug, r.nombre, rv.valor_id, 1
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	join public.rasgo_valores rv on rv.rasgo_id = r.rasgo_id and rv.activo
	where g.slug in ('distico_final', 'encadenamiento_interior')
		and g.arquitectura_id = v_arq;

	select count(*) into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug in ('distico_final', 'encadenamiento_interior');
	if v_n <> 2 then
		raise exception 'Deben quedar dos preguntas nuevas, y hay %', v_n;
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · La derivación produce también la etiqueta
-- ---------------------------------------------------------------------------

drop function if exists public.opciones_eleccion_derivadas();

create function public.opciones_eleccion_derivadas()
returns table (
	grupo_eleccion_id uuid,
	etiqueta text,
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
	-- Rima: el nombre del esquema con su notación, que es lo que lo identifica de un vistazo.
	select g.grupo_eleccion_id,
		concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''))::text,
		null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
		null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by er.notacion, er.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	join public.esquemas_rima er
		on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
	where g.dimension = 'rima'
		and g.tipo_control = 'opciones'
		and g.activo
		and er.tipo_secuencia not in ('abierta', 'restricciones')

	union all

	-- Metro por conjunto: el nombre del metro, precedido del verso cuando la medida varía.
	select g.grupo_eleccion_id,
		case when pos.posicion is null then adm.nombre
			else 'Verso ' || pos.posicion || ' · ' || adm.nombre end::text,
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
	where g.dimension = 'metro'
		and g.tipo_control = 'opciones'
		and g.activo
		and em.medida_uniforme is not null

	union all

	-- Metro por posiciones: la alternativa que admite esa posición concreta.
	select g.grupo_eleccion_id,
		('Verso ' || p.posicion || ' · ' || mt.nombre)::text,
		p.metro_id, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
		p.alternativa::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
	join public.metros mt on mt.metro_id = p.metro_id
	where g.dimension = 'metro'
		and g.tipo_control = 'opciones'
		and g.activo
		and em.medida_uniforme is null
		and p.posicion in (
			select p2.posicion
			from public.esquema_metrico_posiciones p2
			where p2.esquema_metrico_id = em.esquema_metrico_id
			group by p2.posicion
			having count(distinct p2.metro_id) > 1
		)

	union all

	-- Rasgo: el nombre del valor, salvo cuando el rasgo tiene un solo valor y ese valor no
	-- dice nada por sí mismo —«Presente»—, en cuyo caso lo que nombra la opción es el rasgo.
	select g.grupo_eleccion_id,
		case when adm.valores = 1 then r.nombre else adm.nombre end::text,
		null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	join lateral (
		select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
			(select count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
				as valores
		from public.arquitectura_rasgos ar
		join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
		where ar.arquitectura_id = g.arquitectura_id
			and ar.rasgo_id = g.rasgo_id
			and (ar.valor_id is null or ar.valor_id = rv.valor_id)
	) adm on true
	where g.dimension = 'rasgo'
		and g.tipo_control = 'opciones'
		and g.activo
		and g.rasgo_id is not null

	union all

	-- Repetición: su nombre, y el comportamiento que ella misma declara.
	select g.grupo_eleccion_id, rp.nombre::text,
		null::uuid, null::uuid, null::uuid, null::uuid,
		rp.repeticion_id, null::uuid, null::uuid, null::integer,
		rp.materializa_seccion_id, rp.extension_desde_seccion_id,
		row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
	where g.dimension = 'repeticion'
		and g.tipo_control = 'opciones'
		and g.activo

	union all

	-- Combinación: el nombre de la variedad.
	select g.grupo_eleccion_id, v.nombre::text,
		null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
	where g.dimension = 'combinacion'
		and g.tipo_control = 'opciones'
		and g.activo
$function$;

comment on function public.opciones_eleccion_derivadas() is
	'Las opciones que el catálogo produce para cada pregunta del editor, con su etiqueta. Es la única definición de qué se admite y de cómo se rotula: la etiqueta es el nombre de la entidad, compuesto con la posición cuando la pregunta es posicional.';

-- ---------------------------------------------------------------------------
-- 3 · La comprobación deja de prometer que escribe
-- ---------------------------------------------------------------------------

drop function if exists public.generar_opciones_eleccion_metrica(boolean);

create function public.comparar_opciones_eleccion_metrica()
returns table (
	forma text, grupo text, escritas integer, derivadas integer,
	etiquetas_distintas integer, veredicto text
)
language sql
stable
set search_path to 'public'
as $function$
	with derivadas as (
		select d.grupo_eleccion_id, count(*)::integer as n
		from public.opciones_eleccion_derivadas() d
		group by d.grupo_eleccion_id
	),
	escritas as (
		select o.grupo_eleccion_id, count(*)::integer as n
		from public.opciones_eleccion_metrica o
		where o.activo
		group by o.grupo_eleccion_id
	),
	etiquetas as (
		select o.grupo_eleccion_id, count(*)::integer as n
		from public.opciones_eleccion_metrica o
		join public.opciones_eleccion_derivadas() d
			on d.grupo_eleccion_id = o.grupo_eleccion_id
			and d.metro_id is not distinct from o.metro_id
			and d.esquema_rima_id is not distinct from o.esquema_rima_id
			and d.valor_rasgo_id is not distinct from o.valor_rasgo_id
			and d.variedad_id is not distinct from o.variedad_id
			and d.repeticion_id is not distinct from o.repeticion_id
			and d.posicion_unidad is not distinct from o.posicion_unidad
		where o.nombre is distinct from d.etiqueta
		group by o.grupo_eleccion_id
	)
	select f.nombre::text, g.slug::text,
		coalesce(e.n, 0), coalesce(d.n, 0), coalesce(t.n, 0),
		case
			when g.tipo_control <> 'opciones' then 'respuesta abierta, no se genera'
			when d.n is null then 'sin derivar: falta declarar algo'
			when coalesce(e.n, 0) <> d.n then 'difieren las opciones'
			when coalesce(t.n, 0) > 0 then 'coinciden las opciones, difieren etiquetas'
			else 'coincide'
		end::text
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	left join derivadas d on d.grupo_eleccion_id = g.grupo_eleccion_id
	left join escritas e on e.grupo_eleccion_id = g.grupo_eleccion_id
	left join etiquetas t on t.grupo_eleccion_id = g.grupo_eleccion_id
	where g.activo
	order by f.nombre, g.slug
$function$;

comment on function public.comparar_opciones_eleccion_metrica() is
	'Compara las opciones escritas a mano con las que el catálogo deriva, y sus etiquetas. No escribe: mientras las dos convivan, pedir esta comparación es la manera de ver si se han separado.';

grant execute on function public.opciones_eleccion_derivadas() to authenticated;
grant execute on function public.comparar_opciones_eleccion_metrica() to authenticated;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.comparar_opciones_eleccion_metrica()
	where veredicto in ('difieren las opciones', 'sin derivar: falta declarar algo');
	if v_n <> 0 then
		raise exception 'Quedan % preguntas cuyas opciones no se derivan', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
