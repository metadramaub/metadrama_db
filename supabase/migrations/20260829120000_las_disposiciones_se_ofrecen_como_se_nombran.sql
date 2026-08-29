-- Las disposiciones se ofrecen en el orden en que el catálogo las nombra
--
-- La quintilla tiene ocho tipologías numeradas y el desplegable las ofrecía **4, 5, 3, 1, 7, 6, 2,
-- 8**: la función que deriva las opciones las ordenaba por notación —`aabab`, `aabba`, `abaab`,
-- `ababa`…— y el número de la tipología, que es como se las nombra y como las cita la bibliografía,
-- no pintaba nada.
--
-- Pasa a ordenarse **por el nombre del esquema cuando lo tiene**, y por la notación cuando no. Así
-- la quintilla sale 1 a 8, y las disposiciones sin nombre —el pareado, la octava real— se quedan
-- exactamente donde estaban.
--
-- Lo único que cambia es el `orden` de la opción derivada. Ni las opciones ni las respuestas
-- guardadas se tocan: la respuesta apunta al esquema, no a su posición en la lista.

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
			row_number() over (
				partition by g.grupo_eleccion_id order by er.nombre nulls last, er.notacion, er.slug
			)::integer
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_rima er
			on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
		where g.dimension = 'rima' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
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
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
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
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
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
		where g.dimension = 'rasgo' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and g.rasgo_id is not null

		union all

		select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			rp.repeticion_id, null::uuid, null::uuid, null::integer,
			rp.materializa_seccion_id, rp.extension_desde_seccion_id,
			row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.grupos_eleccion_metrica g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.grupos_eleccion_metrica g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$function$;


do $$
declare
	v_fila record;
	v_esperado integer := 0;
	v_leidas integer := 0;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la función**, leyendo la vista que la envuelve: un cuerpo entrecomillado que
	-- compila no dice nada de si ordena bien.
	for v_fila in
		select o.nombre, o.orden
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = 'Quintilla' and a.nombre = 'Octosilábica consonante' and g.dimension = 'rima'
		order by o.orden
	loop
		v_esperado := v_esperado + 1;
		v_leidas := v_leidas + 1;
		if v_fila.nombre <> ('Tipología ' || v_esperado || ' · ' || (
			case v_esperado
				when 1 then 'ababa' when 2 then 'abbab' when 3 then 'abaab' when 4 then 'aabab'
				when 5 then 'aabba' when 6 then 'abbaa' when 7 then 'ababb' when 8 then 'abbba'
			end)) then
			raise exception 'La quintilla ofrece «%» en el puesto %, y ahí va la tipología %.',
				v_fila.nombre, v_fila.orden, v_esperado;
		end if;
	end loop;

	if v_leidas <> 8 then
		raise exception 'La quintilla ofrece % disposiciones de rima, y son 8.', v_leidas;
	end if;
end $$;

commit;
