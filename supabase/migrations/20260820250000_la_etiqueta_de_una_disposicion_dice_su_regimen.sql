-- La etiqueta de una disposición dice su régimen
--
-- El pareado tiene dos disposiciones que solo se distinguen por el régimen, y se llamaban
-- «Asonante» y «Consonante». Desde que la ficha imprime el régimen en su propia columna, esas
-- filas se leían **«Asonante · admitida · Asonante»**: no ya repetición, sino duplicación literal.
-- Se les retira el nombre, porque ninguna fuente se lo da y lo que las distingue ya está impreso;
-- la fila cae entonces en su notación, como ya hace el `aabaab` de la sextilla.
--
-- **Pero ese nombre servía además a otro público.** La etiqueta que el editor ofrece se construye
-- con `nombre · notación`, de modo que sin nombre las dos opciones del pareado habrían quedado
-- en «aa» y «aa», indistinguibles. La comprobación evitó el estropicio.
--
-- La salida es la misma regla que la ficha ya aplica a cada fila de rima: **el régimen entra
-- cuando la arquitectura no declara uno solo**. Si lo declara, todas sus disposiciones lo
-- comparten y repetirlo sería ruido; si no lo declara es porque varían, y entonces es
-- justamente lo que las separa. Alcanza a las cuatro arquitecturas del catálogo sin régimen
-- declarado arriba —el pareado, la principal de la endecha real y las dos del villancico— y no
-- toca ninguna otra etiqueta.

begin;

CREATE OR REPLACE FUNCTION public.opciones_eleccion_derivadas()
 RETURNS TABLE(grupo_eleccion_id uuid, etiqueta text, descripcion text, metro_id uuid, esquema_metrico_id uuid, esquema_rima_id uuid, seccion_id uuid, repeticion_id uuid, valor_rasgo_id uuid, variedad_id uuid, posicion_unidad integer, materializa_seccion_id uuid, extension_desde_seccion_id uuid, orden integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
	-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
	-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
	select g.grupo_eleccion_id,
		-- El régimen entra en la etiqueta cuando la arquitectura no declara uno solo: si sus
		-- disposiciones varían, es lo que las distingue, y sin él el pareado ofrecía dos opciones
		-- llamadas «aa». Es la misma regla que la ficha pública aplica a cada fila de rima.
		concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''),
			case when a.tipo_rima_id is null then (
				select tr.etiqueta from public.vocabularios tr where tr.termino_id = er.tipo_rima_id
			) end)::text,
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
$function$
;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'cualquier_medida' and a.activo;

	if v_arq is null then
		raise exception 'El pareado no tiene su arquitectura activa.';
	end if;

	update public.esquemas_rima set nombre = null
	where arquitectura_id = v_arq and slug in ('aa-asonante', 'aa-consonante');

	-- La función se ejecuta: dos opciones que antes decían «aa» dicen ahora su régimen.
	select string_agg(o.nombre, ' | ' order by o.nombre) into v_actual
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id = v_arq and g.dimension = 'rima';

	if v_actual is distinct from 'aa · Asonante | aa · Consonante' then
		raise exception 'Las opciones de rima del pareado salen como «%».', v_actual;
	end if;

	-- Las de la endecha real conservan su nombre y ganan el régimen, sin perder nada.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and g.dimension = 'rima'
		and o.nombre in (
			'Abrazada asonante · abbA · Asonante',
			'Asonancia sostenida en los versos cuartos · [---a]… · Asonante',
			'Cruzada asonante · abaB · Asonante',
			'Cruzada consonante · abaB · Consonante',
			'Versos sueltos · [----]… · Sin rima'
		);
	if v_n <> 5 then
		raise exception 'Solo % de las cinco opciones de la endecha real llevan su régimen.', v_n;
	end if;

	-- Y una arquitectura que sí declara régimen arriba no lo repite en sus opciones.
	if exists (
		select 1
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'soneto' and g.dimension = 'rima'
			and (o.nombre like '%Consonante' or o.nombre like '%Asonante')
	) then
		raise exception 'El soneto ha empezado a repetir su régimen en las opciones.';
	end if;
end $$;

commit;
