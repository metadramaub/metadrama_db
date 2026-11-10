-- Corrige el coste del guardado métrico sin cambiar el catálogo ni los datos anotados.
-- No modifica el nuevo modelo de control de obras. Ensayar sobre copia antes de desplegar.
begin;
set local lock_timeout='5s';
set local statement_timeout='120s';
create temporary table _opciones_antes_guardado on commit drop as
select * from public.opciones_eleccion_metrica;

-- Se permite integrar la derivación en los planes; las referencias quedan cualificadas.
CREATE OR REPLACE FUNCTION public.opciones_eleccion_derivadas()
 RETURNS TABLE(grupo_eleccion_id uuid, etiqueta text, descripcion text, metro_id uuid, esquema_metrico_id uuid, esquema_rima_id uuid, seccion_id uuid, repeticion_id uuid, valor_rasgo_id uuid, variedad_id uuid, posicion_unidad integer, materializa_seccion_id uuid, extension_desde_seccion_id uuid, orden integer)
 LANGUAGE sql
 STABLE

AS $function$
		-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
		-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
		select g.grupo_eleccion_id,
			-- El régimen entra en la etiqueta cuando la arquitectura no declara uno solo: si sus
			-- disposiciones varían, es lo que las distingue, y sin él el pareado ofrecía dos opciones
			-- llamadas «aa». Es la misma regla que la ficha pública aplica a cada fila de rima.
			pg_catalog.concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''),
				case when a.tipo_rima_id is null then (
					select tr.etiqueta from public.vocabularios tr where tr.termino_id = er.tipo_rima_id
				) end)::text,
			er.descripcion,
			null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
			null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
			pg_catalog.row_number() over (
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
			pg_catalog.row_number() over (
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
			from pg_catalog.generate_series(
				1,
				case when em.medida_uniforme then 1
					else coalesce(
						s.versos_max,
						(
							select pg_catalog.sum(h.versos_max)::integer
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
				group by p2.posicion having pg_catalog.count(distinct p2.metro_id) > 1
			)

		union all

		select g.grupo_eleccion_id,
			case when adm.valores = 1 then r.nombre else adm.nombre end::text,
			adm.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
			pg_catalog.row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
		from public.preguntas_metricas g
		join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
		join lateral (
			select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
				rv.descripcion,
				(select pg_catalog.count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
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
			pg_catalog.row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.preguntas_metricas g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			pg_catalog.row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.preguntas_metricas g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$function$;

-- Estas funciones solo se ejecutan como triggers y solo comprueban integridad.
-- Las autorizaciones de escritura siguen en RLS y en la RPC. Las comprobaciones ven toda
-- la anotación sin volver a resolver sus permisos para cada fila en cada evento diferido.
alter function public.validar_estructura_anotacion_diferida() security definer;
alter function public.validar_estructura_anotacion_diferida() set search_path to '';
alter function public.validar_extension_patron_anotacion_realizaciones() security definer;
alter function public.validar_extension_patron_anotacion_realizaciones() set search_path to '';
alter function public.validar_arquitectura_de_realizacion() security definer;
alter function public.validar_arquitectura_de_realizacion() set search_path to '';
alter function public.validar_densidad_de_pareados_regulares() security definer;
alter function public.validar_densidad_de_pareados_regulares() set search_path to '';

CREATE OR REPLACE FUNCTION public.validar_estructura_anotacion(p_secuencia_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
	declare
		v_configuracion_id uuid;
		v_seccion record;
		v_unidad record;
		v_padre record;
		v_total integer;
	begin
		select arquitectura_id into v_configuracion_id
		from public.anotaciones_metricas
		where anotacion_id = p_secuencia_id;

		if v_configuracion_id is null then
			return;
		end if;

		-- Las secciones raíz, cada unidad contra las de su propia arquitectura.
		for v_unidad in
			select realizacion_id,
				coalesce(arquitectura_id, v_configuracion_id) as arquitectura_id
			from public.anotacion_realizaciones
			where anotacion_id = p_secuencia_id
				and realizacion_padre_id is null
				and seccion_id is null
                -- Sin secciones raíz no hay nada que comprobar dentro de esta unidad.
                -- Filtrarlo aquí evita un bucle SQL vacío por cada estrofa y evento diferido.
                and exists (
                    select 1 from public.estructuras_secciones raiz
                    where raiz.arquitectura_id = coalesce(anotacion_realizaciones.arquitectura_id, v_configuracion_id)
                        and raiz.seccion_padre_id is null
                )
		loop
			for v_seccion in
				select *
				from public.estructuras_secciones
				where arquitectura_id = v_unidad.arquitectura_id
					and seccion_padre_id is null
			loop
				select count(*) into v_total
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and realizacion_padre_id = v_unidad.realizacion_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
					raise exception 'Cada unidad admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;

		-- Las secciones internas se buscan por su sección superior, que ya identifica una sola
		-- arquitectura: basta con mirar las de todas las que están en juego en esta secuencia.
		for v_seccion in
			select s.*
			from public.estructuras_secciones s
			where s.seccion_padre_id is not null
				and s.arquitectura_id in (
					select v_configuracion_id
					union
					select arquitectura_id
					from public.anotacion_realizaciones
					where anotacion_id = p_secuencia_id
						and arquitectura_id is not null
				)
		loop
			for v_padre in
				select realizacion_id
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and seccion_id = v_seccion.seccion_padre_id
			loop
				select count(*) into v_total
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and realizacion_padre_id = v_padre.realizacion_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad superior necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null
					and v_total > v_seccion.repeticiones_max
				then
					raise exception 'Cada unidad superior admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;
	end;
	$function$;

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


			-- El formulario sigue enviando la opción que el editor pulsó, pero lo que se guarda es
			-- el dato del catálogo que esa opción representa. Cuando la respuesta es abierta no hay
			-- opción que resolver y el texto viaja tal cual.
            -- Se deriva el repertorio una vez para toda la petición, conservando los triggers por fila.
            with opciones as materialized (select * from public.opciones_eleccion_metrica)
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
				nullif(item.dato ->> 'realizacion_id', '')::uuid,
				-- La dimensión la manda el formulario; si no viene, se toma de la pregunta que
				-- ofrecía la opción, que es de donde salía antes el grupo.
				coalesce(nullif(item.dato ->> 'dimension', ''), g.dimension),
				coalesce(nullif(item.dato ->> 'seccion_tratada_id', '')::uuid, g.seccion_tratada_id),
				o.metro_id,
				o.esquema_metrico_id,
				o.esquema_rima_id,
				o.seccion_id,
				o.repeticion_id,
				o.valor_rasgo_id,
				o.variedad_id,
				o.posicion_unidad,
				nullif(btrim(item.dato ->> 'valor_texto'), ''),
				nullif(btrim(item.dato ->> 'observaciones'), '')
			from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb)) item(dato)
            left join opciones o on o.opcion_eleccion_id = nullif(item.dato ->> 'opcion_eleccion_id', '')::uuid
			left join public.grupos_eleccion_metrica g
				on g.grupo_eleccion_id = o.grupo_eleccion_id;

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
			with grupos as materialized (
                select * from public.grupos_eleccion_metrica_resueltos
                where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
                    and activo and alcance = 'unidad'
            )
            select grupo.*, unidad.realizacion_id
			from public.anotacion_realizaciones unidad
			join grupos grupo
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

do $guarda$
declare
 v_admin uuid;
 v_escenario uuid;
 v_anotacion uuid;
 v_unidad uuid := gen_random_uuid();
 v_forma uuid;
 v_arquitectura uuid;
 v_opcion uuid;
 v_sub text := current_setting('request.jwt.claim.sub',true);
 v_claims text := current_setting('request.jwt.claims',true);
begin
 if exists ((select * from _opciones_antes_guardado except all select * from public.opciones_eleccion_metrica)
  union all (select * from public.opciones_eleccion_metrica except all select * from _opciones_antes_guardado)) then
  raise exception 'La optimización ha cambiado las opciones del catálogo';
 end if;
 select e.user_id into v_admin from public.editores e join public.vocabularios v on v.termino_id=e.role
 where coalesce(e.activo,true) and lower(v.termino) in ('admin','ip') order by e.created_at limit 1;
 select a.forma_id,a.arquitectura_id,o.opcion_eleccion_id into v_forma,v_arquitectura,v_opcion
 from public.formas_metricas f join public.arquitecturas_forma a using(forma_id)
 join public.preguntas_metricas g using(arquitectura_id)
 join public.opciones_eleccion_metrica o using(grupo_eleccion_id)
 join public.esquemas_rima r using(esquema_rima_id)
 where f.slug='redondilla' and a.activo and r.notacion='abba' limit 1;
 if v_admin is null or v_opcion is null then raise exception 'Faltan identidad o catálogo para ejecutar la guarda'; end if;
 perform set_config('request.jwt.claim.sub',v_admin::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
 begin
  insert into public.anotacion_escenarios_prueba(nombre,created_by,updated_by)
  values ('Guarda transitoria de rendimiento',v_admin,v_admin) returning escenario_id into v_escenario;
  v_anotacion:=public.guardar_anotacion_metrica(jsonb_build_object('escenario_id',v_escenario,
   'forma_id',v_forma,'arquitectura_id',v_arquitectura,'orden',1,'v_ini',1,'v_fin',4,
   'unidades',jsonb_build_array(jsonb_build_object('realizacion_id',v_unidad,'orden',1,'v_ini',1,'v_fin',4)),
   'elecciones',jsonb_build_array(jsonb_build_object('realizacion_id',v_unidad,'dimension','rima','opcion_eleccion_id',v_opcion))));
  set constraints all immediate;
  if not exists(select 1 from public.anotacion_elecciones where anotacion_id=v_anotacion and realizacion_id=v_unidad) then
   raise exception 'La guarda no ha conservado la respuesta';
  end if;
  raise exception using errcode='ZX001',message='Deshacer solamente los datos de la guarda';
 exception when sqlstate 'ZX001' then null;
 end;
 perform set_config('request.jwt.claim.sub',coalesce(v_sub,''),true);
 perform set_config('request.jwt.claims',coalesce(v_claims,''),true);
end $guarda$;
-- Las pruebas ejecutables de guardado y permisos acompañan esta migración en
-- scripts/control-obras/probar-guardado-prado-local.mjs; la guarda no deja datos de prueba.
commit;
