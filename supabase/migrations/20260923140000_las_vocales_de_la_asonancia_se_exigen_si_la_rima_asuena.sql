-- Las vocales de la asonancia se exigen cuando la rima respondida asuena
--
-- Una asonancia se registra diciendo en qué vocales asuena, y esa pregunta existe en las 28
-- arquitecturas que tienen algún esquema asonante. En 16 la rima es asonante por norma y la pregunta
-- es obligatoria, que es lo correcto. En las otras 12 la arquitectura admite los dos regímenes, y
-- ahí el catálogo hacía dos cosas distintas y ninguna buena:
--
--   * **Once la declaraban opcional** —seis octavas agudas, dos tercetos, dos villancicos y el
--     pareado isométrico—. Se decidió así el 29 de agosto de 2026, razonando que el mismo pasaje
--     puede rimar en consonante y que «no hace falta inventar preguntas condicionales, que el modelo
--     no tiene». La consecuencia es que a quien acaba de anotar un pareado consonante se le sigue
--     ofreciendo declarar sus asonancias, que no existen; y que a quien lo anota asonante no se le
--     exige decir en cuáles, que es el dato.
--   * **Y la endecha real heptasílaba con endecasílabo final la declaraba obligatoria** teniendo
--     tres regímenes, que es el error simétrico: exigía vocales aunque el pasaje rimara en
--     consonante.
--
-- Ninguna de las dos cosas es lo que pasa en el verso: **las vocales no son una licencia, son el
-- dato de la asonancia**. Se responden siempre que haya asonancia y no se responden nunca cuando no
-- la hay. Eso es una pregunta condicional, y ahora el modelo tiene dónde ponerla.
--
-- `solo_si_tipo_rima_id` dice de qué régimen depende una pregunta: apunta al mismo término de
-- `vocabularios` que declaran los esquemas de rima, de modo que no se inventa ningún vocabulario
-- nuevo ni engorda la lista de enums en `CHECK`. No es un sistema general de dependencias entre
-- preguntas: es una columna, y hoy la usa un solo rasgo.
--
-- La condición se resuelve contra **lo respondido**, no contra lo que la arquitectura admite, y por
-- eso la comprueba `guardar_anotacion_metrica` y no una vista: una tirada de pareados puede tener
-- unos consonantes y otros asonantes, y entonces la pregunta se hace. Se exige en los dos sentidos
-- —si no se cumple la condición, la respuesta sobra y se rechaza—, para que el dato no quede colgado
-- detrás de una pregunta que ya no se enseña.

begin;

alter table public.grupos_eleccion_metrica
	add column if not exists solo_si_tipo_rima_id uuid references public.vocabularios(termino_id);

-- ---------------------------------------------------------------------------
-- Quién la declara
-- ---------------------------------------------------------------------------
-- Las arquitecturas que no fijan el régimen arriba y ofrecen más de uno abajo. Es la misma regla
-- que aplican la rejilla de la norma y la ficha pública para decidir si etiquetan cada disposición
-- con su régimen: donde lo fija la arquitectura, repetirlo es ruido; donde varía, hay que decirlo.

do $cambio$
declare
	v_asonante uuid;
	v_n integer;
begin
	select termino_id into v_asonante
	from public.vocabularios where categoria = 'tipo_rima' and termino = 'asonante';
	if v_asonante is null then
		raise exception 'No existe el término «asonante» del vocabulario de tipos de rima.';
	end if;

	update public.grupos_eleccion_metrica g
	set solo_si_tipo_rima_id = v_asonante,
		selecciones_min = 1,
		updated_at = now()
	from public.rasgos_metricos r, public.arquitecturas_forma a
	where r.rasgo_id = g.rasgo_id
		and r.slug = 'vocales_asonancia'
		and a.arquitectura_id = g.arquitectura_id
		and g.activo
		and a.tipo_rima_id is null
		and (
			select count(distinct er.tipo_rima_id)
			from public.esquemas_rima er
			where er.arquitectura_id = a.arquitectura_id and er.tipo_rima_id is not null
		) > 1;

	get diagnostics v_n = row_count;
	if v_n <> 12 then
		raise exception 'La condición se ha puesto en % preguntas, no en las doce.', v_n;
	end if;
end
$cambio$;

-- ---------------------------------------------------------------------------
-- Qué régimen afirma lo respondido
-- ---------------------------------------------------------------------------
-- Una respuesta de rima dice su régimen de dos maneras: eligiendo una disposición del catálogo, que
-- lo lleva en `tipo_rima_id`, o escribiendo el esquema a mano, que lo guarda detrás del punto medio
-- —`abab · asonante`— con el término del vocabulario. **Se compara el término entero**: «asonante»
-- es subcadena de «consonante», y buscarlo suelto daría por asonante todo lo consonante.

create or replace function public.anotacion_afirma_tipo_rima(p_anotacion uuid, p_tipo uuid)
returns boolean
language sql
stable
set search_path to 'public'
as $funcion$
	select exists (
		select 1
		from public.anotacion_elecciones e
		left join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
		where e.anotacion_id = p_anotacion
			and e.dimension = 'rima'
			and (
				er.tipo_rima_id = p_tipo
				or (
					e.esquema_rima_id is null
					and e.valor_texto is not null
					and btrim(split_part(e.valor_texto, '·', 2)) = (
						select v.termino from public.vocabularios v where v.termino_id = p_tipo
					)
				)
			)
	);
$funcion$;

-- ---------------------------------------------------------------------------
-- Las vistas llevan la columna hasta el editor
-- ---------------------------------------------------------------------------

create or replace view public.preguntas_metricas as
SELECT g.grupo_eleccion_id,
    g.arquitectura_id,
    g.slug,
    g.ayuda_editor,
    g.dimension,
    g.alcance,
    g.seccion_id,
    g.selecciones_min,
    g.selecciones_max,
    g.permite_aplicar_global,
    g.activo,
    g.orden,
    g.created_at,
    g.updated_at,
    g.tipo_control,
    g.define_norma,
    g.rasgo_id,
    g.seccion_tratada_id,
    NULL::uuid AS heredada_de,
    g.solo_si_tipo_rima_id
   FROM grupos_eleccion_metrica g
UNION ALL
 SELECT md5(g.grupo_eleccion_id::text || h.seccion_id::text)::uuid AS grupo_eleccion_id,
    h.arquitectura_id,
    g.slug,
    g.ayuda_editor,
    g.dimension,
    'unidad'::text AS alcance,
    h.seccion_id,
    g.selecciones_min,
    g.selecciones_max,
    g.permite_aplicar_global,
    g.activo,
    g.orden,
    g.created_at,
    g.updated_at,
    g.tipo_control,
    g.define_norma,
    g.rasgo_id,
    g.seccion_tratada_id,
    g.arquitectura_id AS heredada_de,
    g.solo_si_tipo_rima_id
   FROM ( SELECT s.seccion_id,
            s.arquitectura_id,
            s.arquitectura_referenciada_id
           FROM estructuras_secciones s
          WHERE s.arquitectura_referenciada_id IS NOT NULL AND NOT (EXISTS ( SELECT 1
                   FROM esquemas_rima er
                     JOIN esquema_rima_posiciones p ON p.esquema_rima_id = er.esquema_rima_id
                  WHERE er.arquitectura_id = s.arquitectura_id AND er.seccion_id IS NULL)) AND NOT (EXISTS ( SELECT 1
                   FROM esquemas_rima er2
                  WHERE er2.arquitectura_id = s.arquitectura_id AND er2.seccion_id = s.seccion_id)) AND NOT (EXISTS ( SELECT 1
                   FROM grupos_eleccion_metrica g2
                  WHERE g2.arquitectura_id = s.arquitectura_id AND g2.activo AND g2.dimension = 'rima'::text AND (g2.seccion_id = s.seccion_id OR g2.seccion_tratada_id = s.seccion_id)))) h
     JOIN grupos_eleccion_metrica g ON g.arquitectura_id = h.arquitectura_referenciada_id AND g.activo AND g.dimension = 'rima'::text AND g.seccion_id IS NULL AND g.seccion_tratada_id IS NULL;

create or replace view public.grupos_eleccion_metrica_resueltos as
SELECT g.grupo_eleccion_id,
    g.arquitectura_id,
    g.slug,
    g.ayuda_editor,
    g.dimension,
    g.alcance,
    g.seccion_id,
    g.selecciones_min,
    g.selecciones_max,
    g.permite_aplicar_global,
    g.activo,
    g.orden,
    g.created_at,
    g.updated_at,
    g.tipo_control,
    g.define_norma,
    g.rasgo_id,
    g.seccion_tratada_id,
        CASE
            WHEN g.dimension = 'rasgo'::text THEN rm.nombre
            WHEN g.dimension = 'repeticion'::text THEN rep.nombre
            ELSE concat_ws(' · '::text, COALESCE(s.nombre, st.nombre),
            CASE g.dimension
                WHEN 'rima'::text THEN
                CASE
                    WHEN g.tipo_control = 'esquema_rima'::text THEN 'Esquema de rima observado'::text
                    ELSE 'Esquema de rima'::text
                END
                WHEN 'metro'::text THEN
                CASE
                    WHEN g.tipo_control = 'serie_medidas'::text THEN 'Medida de cada verso'::text
                    WHEN m.quebrados THEN 'Pie quebrado'::text
                    WHEN m.posicional AND m.posiciones = 1 THEN 'Medida del verso '::text || m.primera_posicion
                    WHEN m.posicional THEN 'Medida de cada verso'::text
                    ELSE 'Medida de los versos'::text
                END
                WHEN 'combinacion'::text THEN 'Variedad'::text
                ELSE NULL::text
            END)
        END AS nombre,
    g.solo_si_tipo_rima_id
   FROM preguntas_metricas g
     LEFT JOIN estructuras_secciones s ON s.seccion_id = g.seccion_id
     LEFT JOIN estructuras_secciones st ON st.seccion_id = g.seccion_tratada_id
     LEFT JOIN rasgos_metricos rm ON rm.rasgo_id = g.rasgo_id
     LEFT JOIN LATERAL ( SELECT COALESCE(bool_and(o.posicion_unidad IS NOT NULL), false) AS posicional,
            COALESCE(bool_or(eo.rol = 'quebrado'::text), false) AS quebrados,
            count(DISTINCT o.posicion_unidad) FILTER (WHERE o.posicion_unidad IS NOT NULL) AS posiciones,
            min(o.posicion_unidad) AS primera_posicion
           FROM opciones_eleccion_metrica o
             LEFT JOIN esquemas_metricos em ON em.arquitectura_id = g.arquitectura_id
             LEFT JOIN esquema_metrico_opciones eo ON eo.esquema_metrico_id = em.esquema_metrico_id AND eo.metro_id = o.metro_id
          WHERE o.grupo_eleccion_id = g.grupo_eleccion_id) m ON g.dimension = 'metro'::text
     LEFT JOIN LATERAL ( SELECT ms.nombre
           FROM repeticiones_metricas rp
             JOIN estructuras_secciones ms ON ms.seccion_id = rp.materializa_seccion_id
          WHERE rp.arquitectura_id = g.arquitectura_id
         LIMIT 1) rep ON g.dimension = 'repeticion'::text;

CREATE OR REPLACE FUNCTION public.guardar_anotacion_metrica(p_datos jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
	declare
		v_secuencia_id uuid;
		v_escenario_id uuid;
		v_real_id uuid;
		v_real record;
		v_v_ini integer;
		v_v_fin integer;
		v_item jsonb;
		v_grupo record;
		v_total integer;
		v_regimen text;
	begin
		v_secuencia_id := nullif(p_datos ->> 'anotacion_id', '')::uuid;
		v_escenario_id := nullif(p_datos ->> 'escenario_id', '')::uuid;
		v_real_id := nullif(p_datos ->> 'secuencia_id', '')::uuid;

		if num_nonnulls(v_escenario_id, v_real_id) <> 1 then
			raise exception 'Una prueba cuelga de un escenario o de una secuencia real, nunca de las dos ni de ninguna';
		end if;

		v_v_ini := (p_datos ->> 'v_ini')::integer;
		v_v_fin := (p_datos ->> 'v_fin')::integer;

		if v_escenario_id is not null then
			-- **El laboratorio sigue siendo de admin e IP.** Un escenario de pruebas no es de nadie,
			-- así que no hay obra de la que colgar un permiso.
			if not public.auth_is_admin_or_ip() then
				raise exception 'Solo admin o IP pueden usar el editor de pruebas'
					using errcode = '42501';
			end if;
			if not exists (
				select 1 from public.anotacion_escenarios_prueba
				where escenario_id = v_escenario_id
			) then
				raise exception 'El escenario de prueba no existe';
			end if;
		else
			select s.secuencia_id, s.obra_id, s.v_ini, s.v_fin
			into v_real
			from public.secuencias_metricas s
			where s.secuencia_id = v_real_id;

			if not found then
				raise exception 'La secuencia real que se quiere anotar no existe';
			end if;

			-- **El permiso se pide sobre la obra**, no sobre el rol: admin o IP con cualquiera, y el
			-- editor con la suya. Es el mismo predicado que gobierna sus políticas y el que ya regía
			-- `secuencias_metricas` desde siempre.
			if not public.auth_puede_editar_obra(v_real.obra_id) then
				raise exception 'No puedes anotar las secuencias de esta obra'
					using errcode = '42501';
			end if;

			-- **Todas las obras se anotan con el catálogo nuevo.** Aquí hubo un interruptor por obra,
			-- de cuando la anotación en sombra iba a ser el camino de la migración. Dejó de serlo el
			-- 27 de agosto de 2026: migrar se hace a mano, con el informe por obra delante, así que
			-- no hay obras «abiertas» y otras que no.

			-- El rango lo manda la secuencia real. La sombra dice qué es ese pasaje, no dónde
			-- empieza: si además se moviera, el contraste entre modelos no compararía lo mismo.
			v_v_ini := v_real.v_ini;
			v_v_fin := v_real.v_fin;
		end if;

		if v_secuencia_id is null then
			insert into public.anotaciones_metricas (
				escenario_id, secuencia_id, orden, v_ini, v_fin, forma_id, arquitectura_id,
				observaciones, created_by, updated_by
			)
			values (
				v_escenario_id,
				v_real_id,
				coalesce((p_datos ->> 'orden')::integer, 1),
				v_v_ini,
				v_v_fin,
				(p_datos ->> 'forma_id')::uuid,
				nullif(p_datos ->> 'arquitectura_id', '')::uuid,
				nullif(btrim(p_datos ->> 'observaciones'), ''),
				auth.uid(),
				auth.uid()
			)
			returning anotacion_id into v_secuencia_id;
		else
			update public.anotaciones_metricas
			set
				escenario_id = v_escenario_id,
				secuencia_id = v_real_id,
				orden = coalesce((p_datos ->> 'orden')::integer, orden),
				v_ini = v_v_ini,
				v_fin = v_v_fin,
				forma_id = (p_datos ->> 'forma_id')::uuid,
				arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid,
				observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
				updated_by = auth.uid()
			where anotacion_id = v_secuencia_id;

			if not found then
				raise exception 'Secuencia métrica de prueba no encontrada';
			end if;
		end if;

		delete from public.anotacion_desviaciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_elecciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_realizaciones
		where anotacion_id = v_secuencia_id;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
		loop
			insert into public.anotacion_realizaciones (
				realizacion_id, anotacion_id, realizacion_padre_id, seccion_id,
				orden, v_ini, v_fin, etiqueta, observaciones, arquitectura_id
			)
			values (
				(v_item ->> 'realizacion_id')::uuid,
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_padre_id', '')::uuid,
				nullif(v_item ->> 'seccion_id', '')::uuid,
				(v_item ->> 'orden')::integer,
				(v_item ->> 'v_ini')::integer,
				(v_item ->> 'v_fin')::integer,
				nullif(btrim(v_item ->> 'etiqueta'), ''),
				nullif(btrim(v_item ->> 'observaciones'), ''),
				-- La arquitectura de la unidad cuando no es la de su secuencia: la décima aumentada
				-- entre décimas normales. Nulo es el caso corriente, y el disparador comprueba que sea
				-- de la misma forma y esté declarada intercalable.
				nullif(v_item ->> 'arquitectura_id', '')::uuid
			);
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
		loop
			-- El formulario sigue enviando la opción que el editor pulsó, pero lo que se guarda es
			-- el dato del catálogo que esa opción representa. Cuando la respuesta es abierta no hay
			-- opción que resolver y el texto viaja tal cual.
			insert into public.anotacion_elecciones (
				anotacion_id,
				realizacion_id,
				dimension,
				seccion_tratada_id,
				metro_id,
				esquema_metrico_id,
				esquema_rima_id,
				seccion_id,
				repeticion_id,
				valor_rasgo_id,
				variedad_id,
				posicion_unidad,
				valor_texto,
				observaciones
			)
			select
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_id', '')::uuid,
				-- La dimensión la manda el formulario; si no viene, se toma de la pregunta que
				-- ofrecía la opción, que es de donde salía antes el grupo.
				coalesce(nullif(v_item ->> 'dimension', ''), g.dimension),
				coalesce(nullif(v_item ->> 'seccion_tratada_id', '')::uuid, g.seccion_tratada_id),
				o.metro_id,
				o.esquema_metrico_id,
				o.esquema_rima_id,
				o.seccion_id,
				o.repeticion_id,
				o.valor_rasgo_id,
				o.variedad_id,
				o.posicion_unidad,
				nullif(btrim(v_item ->> 'valor_texto'), ''),
				nullif(btrim(v_item ->> 'observaciones'), '')
			from (select nullif(v_item ->> 'opcion_eleccion_id', '')::uuid as elegida) k
			left join public.opciones_eleccion_metrica o
				on o.opcion_eleccion_id = k.elegida
			left join public.grupos_eleccion_metrica g
				on g.grupo_eleccion_id = o.grupo_eleccion_id;
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
		loop
			insert into public.anotacion_desviaciones (
				anotacion_id, realizacion_id, v_ini, v_fin, dimension,
				relacion_norma, metro_observado_id, esquema_rima_observado_id,
				seccion_observada_id, repeticion_observada_id,
				valor_rasgo_observado_id, observaciones
			)
			values (
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_id', '')::uuid,
				(v_item ->> 'v_ini')::integer,
				(v_item ->> 'v_fin')::integer,
				v_item ->> 'dimension',
				v_item ->> 'relacion_norma',
				nullif(v_item ->> 'metro_observado_id', '')::uuid,
				nullif(v_item ->> 'esquema_rima_observado_id', '')::uuid,
				nullif(v_item ->> 'seccion_observada_id', '')::uuid,
				nullif(v_item ->> 'repeticion_observada_id', '')::uuid,
				nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
				nullif(btrim(v_item ->> 'observaciones'), '')
			);
		end loop;

		for v_grupo in
			select *
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and alcance = 'secuencia'
		loop
			-- Se cuenta por lo que la respuesta dice de sí misma: su dimensión, la parte de la que
			-- habla y, en los rasgos, de cuál se trata —que lo dice el valor elegido—.
			select count(*) into v_total
			from public.anotacion_elecciones e
			where e.anotacion_id = v_secuencia_id
				and e.realizacion_id is null
				and e.dimension = v_grupo.dimension
				and e.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
				and (
					v_grupo.dimension <> 'rasgo'
					or exists (
						select 1 from public.rasgo_valores rv
						where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = v_grupo.rasgo_id
					)
				);


			-- **Una pregunta puede estar condicionada al régimen de la rima.**
			--
			-- Las vocales de la asonancia no son una licencia: son obligatorias en cuanto la rima
			-- respondida asuena, y no existen cuando rima en consonante. Las doce arquitecturas que
			-- admiten los dos regímenes la declaran así desde el 23 de septiembre de 2026.
			if v_grupo.solo_si_tipo_rima_id is not null
				and not public.anotacion_afirma_tipo_rima(
					v_secuencia_id, v_grupo.solo_si_tipo_rima_id
				)
			then
				if v_total > 0 then
					select v.termino into v_regimen
					from public.vocabularios v where v.termino_id = v_grupo.solo_si_tipo_rima_id;
					raise exception 'La pregunta «%» solo se responde cuando la rima es %, y esta secuencia no lo dice',
						v_grupo.nombre, coalesce(v_regimen, 'de ese régimen');
				end if;
				continue;
			end if;

			if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
				raise exception 'La pregunta «%» necesita entre % y % respuestas',
					v_grupo.nombre,
					v_grupo.selecciones_min,
					v_grupo.selecciones_max;
			end if;
		end loop;

		-- Una pregunta sin sección se aplica a la unidad entera, que es la realización que no
		-- cuelga de ninguna otra.
		for v_grupo in
			select grupo.*, unidad.realizacion_id
			from public.anotacion_realizaciones unidad
			join public.grupos_eleccion_metrica_resueltos grupo
				on grupo.arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and grupo.activo
				and grupo.alcance = 'unidad'
				and (
					(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
					or grupo.seccion_id = unidad.seccion_id
				)
			where unidad.anotacion_id = v_secuencia_id
		loop
			select count(*) into v_total
			from public.anotacion_elecciones e
			where e.anotacion_id = v_secuencia_id
				and e.realizacion_id = v_grupo.realizacion_id
				and e.dimension = v_grupo.dimension
				and e.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
				and (
					v_grupo.dimension <> 'rasgo'
					or exists (
						select 1 from public.rasgo_valores rv
						where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = v_grupo.rasgo_id
					)
				);


			-- **Una pregunta puede estar condicionada al régimen de la rima.**
			--
			-- Las vocales de la asonancia no son una licencia: son obligatorias en cuanto la rima
			-- respondida asuena, y no existen cuando rima en consonante. Las doce arquitecturas que
			-- admiten los dos regímenes la declaran así desde el 23 de septiembre de 2026.
			if v_grupo.solo_si_tipo_rima_id is not null
				and not public.anotacion_afirma_tipo_rima(
					v_secuencia_id, v_grupo.solo_si_tipo_rima_id
				)
			then
				if v_total > 0 then
					select v.termino into v_regimen
					from public.vocabularios v where v.termino_id = v_grupo.solo_si_tipo_rima_id;
					raise exception 'La pregunta «%» solo se responde cuando la rima es %, y esta unidad no lo dice',
						v_grupo.nombre, coalesce(v_regimen, 'de ese régimen');
				end if;
				continue;
			end if;

			if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
				raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
					v_grupo.nombre,
					v_grupo.selecciones_min,
					v_grupo.selecciones_max;
			end if;
		end loop;

		-- Lo que declara la norma no puede contradecirse dentro de la unidad que lo contiene.
		-- Se comparan conjuntos completos de respuestas, porque una pregunta puede admitir
		-- varias —la medida de cada posición de la estancia, por ejemplo—.
		for v_grupo in
			select *
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and define_norma
		loop
			with recursive ascendencia as (
				select
					realizacion_id,
					realizacion_id as unidad_id
				from public.anotacion_realizaciones
				where anotacion_id = v_secuencia_id
					and realizacion_padre_id is null
				union all
				select
					hija.realizacion_id,
					ascendencia.unidad_id
				from public.anotacion_realizaciones hija
				join ascendencia
					on ascendencia.realizacion_id = hija.realizacion_padre_id
				where hija.anotacion_id = v_secuencia_id
			),
			firmas as (
				select
					-- Una pregunta anclada en una sección se compara dentro de su unidad; una
					-- pregunta de la unidad entera, dentro de la secuencia.
					case when v_grupo.seccion_id is not null then ascendencia.unidad_id end as contenedor,
					eleccion.realizacion_id,
					-- La firma se arma con lo que la respuesta guarda —la entidad, o lo escrito—, y
					-- no con la opción, que ya no se guarda y había que derivar de una vista.
					string_agg(
						public.firma_de_eleccion(eleccion),
						'|' order by public.firma_de_eleccion(eleccion)
					) as firma
				from public.anotacion_elecciones eleccion
				join ascendencia
					on ascendencia.realizacion_id = eleccion.realizacion_id
				-- **Solo las realizaciones de la sección que pregunta.** Una pregunta anclada en la
				-- estancia se compara entre estancias; las respuestas de metro del remate, que es
				-- otra sección de la misma unidad, no son la norma de la estancia y no se comparan.
				join public.anotacion_realizaciones realizacion
					on realizacion.realizacion_id = eleccion.realizacion_id
					and realizacion.seccion_id is not distinct from v_grupo.seccion_id
				where eleccion.anotacion_id = v_secuencia_id
					and eleccion.dimension = v_grupo.dimension
					and eleccion.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
				group by 1, 2
			)
			select count(*)
			into v_total
			from (
				select contenedor
				from firmas
				group by contenedor
				having count(distinct firma) > 1
			) discrepancias;

			if v_total > 0 then
				raise exception
					'La pregunta «%» declara la norma del pasaje: debe responderse igual en todas sus realizaciones',
					v_grupo.nombre;
			end if;
		end loop;

		return v_secuencia_id;
	end;
	$function$;


update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

-- ---------------------------------------------------------------------------------------------
-- La guarda ejecuta lo que vigila
--
-- El riesgo de esta migración es de libro: un cuerpo entrecomillado que nombra una columna que la
-- vista no trae. `db push` lo aceptaría, `npm run check` también, y reventaría al primer guardado.
-- Por eso la guarda **recorre el mismo `record` que recorre la función** y lee en él el campo nuevo:
-- PL/pgSQL lo resuelve en ejecución, así que si la vista no lo trajera, aquí se caería.
-- ---------------------------------------------------------------------------------------------
do $guarda$
declare
	v_grupo record;
	v_asonante uuid;
	v_condicionadas integer := 0;
	v_anotacion record;
	v_incumplen integer := 0;
	v_afirma boolean;
begin
	select termino_id into v_asonante
	from public.vocabularios where categoria = 'tipo_rima' and termino = 'asonante';

	-- 1. El recorrido de la función, con el campo nuevo leído del record.
	for v_grupo in
		select * from public.grupos_eleccion_metrica_resueltos where activo
	loop
		if v_grupo.solo_si_tipo_rima_id is not null then
			v_condicionadas := v_condicionadas + 1;
			if v_grupo.selecciones_min < 1 then
				raise exception
					'La pregunta «%» depende de un régimen y sigue admitiendo cero respuestas.',
					v_grupo.nombre;
			end if;
		end if;
	end loop;

	-- Doce preguntas propias y las que de ellas hereden las partes de otra arquitectura.
	if v_condicionadas < 12 then
		raise exception 'Solo % preguntas han quedado condicionadas al régimen.', v_condicionadas;
	end if;

	-- 2. La función que resuelve el régimen se ejecuta contra lo anotado de verdad.
	for v_anotacion in
		select am.anotacion_id
		from public.anotaciones_metricas am
		join public.arquitecturas_forma a on a.arquitectura_id = am.arquitectura_id
		where exists (
			select 1 from public.grupos_eleccion_metrica g
			where g.arquitectura_id = a.arquitectura_id and g.solo_si_tipo_rima_id is not null
		)
	loop
		v_afirma := public.anotacion_afirma_tipo_rima(v_anotacion.anotacion_id, v_asonante);
		-- Lo anotado antes de esta regla puede no cumplirla: la asonancia se declaraba a voluntad.
		-- No se toca ni se rechaza nada; se cuenta, porque es trabajo que alguien tendrá que
		-- completar la próxima vez que abra esa secuencia.
		if v_afirma and not exists (
			select 1
			from public.anotacion_elecciones e
			join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
			join public.rasgos_metricos r on r.rasgo_id = rv.rasgo_id
			where e.anotacion_id = v_anotacion.anotacion_id and r.slug = 'vocales_asonancia'
		) then
			v_incumplen := v_incumplen + 1;
		end if;
	end loop;

	if v_incumplen > 0 then
		raise notice
			'% secuencias ya anotadas asuenan y no dicen en qué vocales: habrá que completarlas al abrirlas.',
			v_incumplen;
	end if;

	-- 3. Y la asonancia no puede acabar exigida donde la rima es consonante por norma.
	if exists (
		select 1
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.vocabularios v on v.termino_id = a.tipo_rima_id
		where g.solo_si_tipo_rima_id is not null and v.termino <> 'asonante'
	) then
		raise exception 'Alguna pregunta condicionada cuelga de una arquitectura de régimen fijo.';
	end if;
end
$guarda$;

commit;
