-- La medida de base deja de ofrecerse como respuesta al quiebro
--
-- La pregunta del pie quebrado ofrecía tres respuestas por verso candidato —«Verso 1 · Octosílabo»,
-- «Verso 1 · Pentasílabo», «Verso 1 · Tetrasílabo»— en las seis arquitecturas que **declaran dónde
-- cae el quiebro**: quintilla, copla castellana, novena, septilla y las dos oncenas. La primera no
-- es una respuesta. Decir que el verso mide ocho es decir que ahí no hay quiebro, y eso ya lo dice
-- no contestar: `selecciones_min` es cero en las nueve preguntas del quiebro.
--
-- Esa opción de más es la que obligaba al editor a pintar una fila «8 sílabas · BASE», un botón
-- «Marcar como quebrado» y un «Volver a 8» para deshacerlo: tres artefactos para administrar una
-- respuesta que no significaba nada. Con ella fuera, un verso candidato ofrece dos medidas y
-- ninguna marcada, que es exactamente la pregunta.
--
-- **Las opciones son derivadas**, así que esto no borra filas: cambia `opciones_eleccion_derivadas`
-- para que la rama de posiciones declaradas se quede con las alternativas cuyo rol es `quebrado`.
-- Donde el esquema no declara roles no cambia nada, y esa salvedad tiene un caso real: la seguidilla
-- gitana pregunta la medida de su tercer verso, y sus tres alternativas son sus tres respuestas.
--
-- Las dos arquitecturas que preguntan `medida_de_los_quebrados` —copla manriqueña y sextilla de pie
-- quebrado— tampoco se mueven: la norma dice dónde caen sus quiebros y sus alternativas ya son solo
-- las dos medidas.
--
-- *No hay nada que migrar.* En toda la base hay **una sola respuesta posicional anotada**, un
-- tetrasílabo en la posición 1, y ninguna guarda la medida de base.

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
		from public.preguntas_metricas g
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
		from public.preguntas_metricas g
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
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
		join public.metros mt on mt.metro_id = p.metro_id
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is null
			-- **La medida de base no es una respuesta al quiebro.**
			--
			-- Esta rama ofrece todas las alternativas que el esquema declara en un verso, y donde el
			-- verso puede quebrarse esas alternativas son tres: el octosílabo de siempre, el
			-- pentasílabo y el tetrasílabo. Pero la pregunta es «¿hay quiebro, y de qué medida?», y
			-- «Verso 1 · Octosílabo» no la contesta: dice que ahí no lo hay, que es lo que ya
			-- significa no responder —el mínimo de la pregunta es cero—.
			--
			-- Donde el esquema **no** distingue roles la rama no se toca: la seguidilla gitana
			-- pregunta la medida de su tercer verso y sus tres alternativas son las tres respuestas.
			and (
				not exists (
					select 1 from public.esquema_metrico_opciones e2
					where e2.esquema_metrico_id = em.esquema_metrico_id and e2.rol = 'quebrado'
				)
				or exists (
					select 1 from public.esquema_metrico_opciones e3
					where e3.esquema_metrico_id = em.esquema_metrico_id
						and e3.metro_id = p.metro_id
						and e3.rol = 'quebrado'
				)
			)
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
		from public.preguntas_metricas g
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
				-- **Una asonancia aguda se nombra con una sola vocal.** Se nombra por la tónica y la
				-- final, y en un verso agudo no hay vocal después de la tónica: por eso el repertorio
				-- tiene `a`, `e`, `i`, `o`, `u` frente a `a-e`, `o-a`… —los pares valen también para
				-- el esdrújulo, que asuena como el llano ignorando la intermedia—. Donde la norma
				-- **fija** el final agudo, las de dos vocales no pueden darse, y ofrecerlas es ruido.
				and (
					r.slug <> 'vocales_asonancia'
					or rv.nombre not like '%-%'
					or not exists (
						select 1
						from public.arquitectura_rasgos final_ar
						join public.rasgos_metricos final_r on final_r.rasgo_id = final_ar.rasgo_id
						join public.rasgo_valores final_v on final_v.valor_id = final_ar.valor_id
						where final_ar.arquitectura_id = g.arquitectura_id
							and final_r.slug = 'final_acentual'
							and final_v.slug = 'agudo'
							and final_ar.modalidad = 'definitoria'
					)
				)
		) adm on true
		where g.dimension = 'rasgo' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and g.rasgo_id is not null

		union all

		select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			rp.repeticion_id, null::uuid, null::uuid, null::integer,
			rp.materializa_seccion_id, rp.extension_desde_seccion_id,
			row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.preguntas_metricas g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.preguntas_metricas g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$function$;

-- ------------------------------------------------------------------------ Comprobaciones
--
-- **Se leen las opciones, que es lo que ejecuta la función.** Un cuerpo entrecomillado compila sin
-- validarse: si esta guarda se limitara a mirar el dato, la función podría estar rota y `db push`
-- pasaría igual.
do $comprobacion$
declare
	v_con_base integer;
	v_candidatos integer;
	v_seguidilla integer;
	v_medida integer;
begin
	-- Ninguna pregunta del quiebro ofrece ya la medida de base.
	select count(*) into v_con_base
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.metros mt on mt.metro_id = o.metro_id
	where g.slug in ('posiciones_pie_quebrado', 'medida_de_los_quebrados')
		and mt.silabas = 8;

	if v_con_base <> 0 then
		raise exception 'Quedan % respuestas del quiebro ofreciendo la medida de base.', v_con_base;
	end if;

	-- Y siguen ofreciéndose las dos medidas de cada verso candidato: eran 68 con las de base.
	select count(*) into v_candidatos
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.slug = 'posiciones_pie_quebrado';

	if v_candidatos <> 60 then
		raise exception 'El quiebro ofrece % respuestas, y son 60.', v_candidatos;
	end if;

	-- Las dos que preguntan la medida de un quiebro que la norma sitúa, intactas: 8 y 4.
	select count(*) into v_medida
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.slug = 'medida_de_los_quebrados';

	if v_medida <> 12 then
		raise exception 'Las preguntas de medida del quiebro ofrecen % respuestas, y son 12.', v_medida;
	end if;

	-- Y la salvedad: la seguidilla gitana conserva sus tres alternativas.
	select count(*) into v_seguidilla
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.slug = 'medida_tercer_verso';

	if v_seguidilla <> 3 then
		raise exception 'La seguidilla gitana ofrece % medidas, y son 3.', v_seguidilla;
	end if;

	raise notice 'El quiebro ofrece dos medidas por verso candidato y ninguna de base.';
end
$comprobacion$;

commit;
