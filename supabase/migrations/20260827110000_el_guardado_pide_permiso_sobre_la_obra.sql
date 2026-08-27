-- El guardado pide el permiso que corresponde a cada caso
--
-- `guardar_anotacion_metrica` empezaba exigiendo `auth_is_admin_or_ip()` **antes de saber qué se
-- está anotando**, y con eso ningún editor podía guardar nada. Venía de cuando esto era un
-- laboratorio de admin e IP.
--
-- Ahora la comprobación baja a cada rama, porque los dos casos no piden lo mismo:
--
-- - **Un escenario de pruebas** no es de nadie, así que no hay obra de la que colgar un permiso:
--   sigue siendo de admin e IP.
-- - **Una secuencia real** pertenece a una obra, y el permiso se pide sobre ella con
--   `auth_puede_editar_obra`: el mismo predicado que gobierna las políticas de la anotación y el
--   que rige `secuencias_metricas` desde siempre.
--
-- *La función se copia de su definición viva y solo se le mueve esa comprobación.*

begin;

do $$
begin
	if to_regprocedure('public.auth_puede_editar_obra(uuid)') is null then
		raise exception 'No está el predicado de permiso por obra.';
	end if;
	if pg_get_functiondef('public.guardar_anotacion_metrica(jsonb)'::regprocedure)
		not like '%Solo admin o IP pueden usar el editor métrico de prueba%'
	then
		raise exception 'El guardado ya no tiene la comprobación de arriba.';
	end if;
end $$;

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
				grupo_eleccion_id,
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
				(v_item ->> 'grupo_eleccion_id')::uuid,
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
				on o.opcion_eleccion_id = k.elegida;
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
			select count(*) into v_total
			from public.anotacion_elecciones
			where anotacion_id = v_secuencia_id
				and grupo_eleccion_id = v_grupo.grupo_eleccion_id
				and realizacion_id is null;

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
			from public.anotacion_elecciones
			where anotacion_id = v_secuencia_id
				and realizacion_id = v_grupo.realizacion_id
				and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

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
					string_agg(
						coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto),
						'|' order by coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto)
					) as firma
				from public.anotacion_elecciones eleccion
				join ascendencia
					on ascendencia.realizacion_id = eleccion.realizacion_id
				where eleccion.anotacion_id = v_secuencia_id
					and eleccion.grupo_eleccion_id = v_grupo.grupo_eleccion_id
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

do $$
declare
	v_def text := pg_get_functiondef('public.guardar_anotacion_metrica(jsonb)'::regprocedure);
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- La función no se puede llamar desde aquí: acabaría escribiendo, y el permiso que se prueba
	-- depende de quién sea `auth.uid()`. Lo que sí se comprueba es que las tres piezas están donde
	-- deben, y que no se ha caído nada por el camino.
	if v_def like '%Solo admin o IP pueden usar el editor métrico de prueba%' then
		raise exception 'La comprobación de arriba sigue ahí.';
	end if;
	if v_def not like '%auth_puede_editar_obra(v_real.obra_id)%' then
		raise exception 'La secuencia real no pide permiso sobre su obra.';
	end if;
	if v_def not like '%Solo admin o IP pueden usar el editor de pruebas%' then
		raise exception 'El laboratorio ha dejado de pedir admin o IP.';
	end if;
	if v_def not like '%La secuencia real que se quiere anotar no existe%' then
		raise exception 'Se ha llevado por delante la comprobación de la secuencia real.';
	end if;
end $$;

commit;
