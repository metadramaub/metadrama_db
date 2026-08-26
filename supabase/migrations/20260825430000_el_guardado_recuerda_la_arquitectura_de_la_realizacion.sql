-- El guardado recuerda la arquitectura de cada realización
--
-- B5, tercera pieza. La columna existe desde `20260825410000` y la función que guarda una secuencia
-- de prueba insertaba las realizaciones **sin ella**, de modo que marcar una décima como aumentada
-- se perdía al guardar.
--
-- Solo cambia el `insert`: una columna más, tomada del mismo `jsonb` que trae las demás. El
-- disparador diferido se encarga de comprobar que sea de la misma forma y esté declarada
-- intercalable, así que aquí no hay nada que validar.
--
-- *La función se copia de su definición viva y se sustituye solo ese bloque.* Son trescientas
-- líneas: transcribirlas para cambiar dos es la manera conocida de perder algo por el camino.

begin;

do $$
begin
	if not exists (
		select 1 from information_schema.columns
		where table_schema = 'public' and table_name = 'realizaciones_editor_metrico'
			and column_name = 'arquitectura_id'
	) then
		raise exception 'La realización no tiene todavía columna de arquitectura.';
	end if;

	if (select prosrc from pg_proc where proname = 'guardar_secuencia_editor_metrico_prueba')
		like '%etiqueta, observaciones, arquitectura_id%'
	then
		raise exception 'El guardado ya persiste la arquitectura de la realización.';
	end if;

	CREATE OR REPLACE FUNCTION public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
	 RETURNS uuid
	 LANGUAGE plpgsql
	 SECURITY DEFINER
	 SET search_path TO 'public'
	AS $guardar$
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
		if not public.auth_is_admin_or_ip() then
			raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
				using errcode = '42501';
		end if;

		v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;
		v_escenario_id := nullif(p_datos ->> 'escenario_id', '')::uuid;
		v_real_id := nullif(p_datos ->> 'secuencia_id', '')::uuid;

		if num_nonnulls(v_escenario_id, v_real_id) <> 1 then
			raise exception 'Una prueba cuelga de un escenario o de una secuencia real, nunca de las dos ni de ninguna';
		end if;

		v_v_ini := (p_datos ->> 'v_ini')::integer;
		v_v_fin := (p_datos ->> 'v_fin')::integer;

		if v_escenario_id is not null then
			if not exists (
				select 1 from public.escenarios_editor_metrico
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

			-- El interruptor es por obra: anotar en sombra una obra que nadie ha abierto sería
			-- empezar la migración por la puerta de atrás.
			if not exists (
				select 1 from public.obras_editor_metrico_v2
				where obra_id = v_real.obra_id
			) then
				raise exception 'La obra de esta secuencia no está abierta al editor V2';
			end if;

			-- El rango lo manda la secuencia real. La sombra dice qué es ese pasaje, no dónde
			-- empieza: si además se moviera, el contraste entre modelos no compararía lo mismo.
			v_v_ini := v_real.v_ini;
			v_v_fin := v_real.v_fin;
		end if;

		if v_secuencia_id is null then
			insert into public.secuencias_editor_metrico (
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
			returning secuencia_prueba_id into v_secuencia_id;
		else
			update public.secuencias_editor_metrico
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
			where secuencia_prueba_id = v_secuencia_id;

			if not found then
				raise exception 'Secuencia métrica de prueba no encontrada';
			end if;
		end if;

		delete from public.desviaciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id;
		delete from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id;
		delete from public.realizaciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
		loop
			insert into public.realizaciones_editor_metrico (
				realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id,
				orden, v_ini, v_fin, etiqueta, observaciones, arquitectura_id
			)
			values (
				(v_item ->> 'realizacion_prueba_id')::uuid,
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
			insert into public.elecciones_editor_metrico (
				secuencia_prueba_id,
				realizacion_prueba_id,
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
				nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
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
			insert into public.desviaciones_editor_metrico (
				secuencia_prueba_id, realizacion_prueba_id, v_ini, v_fin, dimension,
				relacion_norma, metro_observado_id, esquema_rima_observado_id,
				seccion_observada_id, repeticion_observada_id,
				valor_rasgo_observado_id, observaciones
			)
			values (
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
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
			from public.elecciones_editor_metrico
			where secuencia_prueba_id = v_secuencia_id
				and grupo_eleccion_id = v_grupo.grupo_eleccion_id
				and realizacion_prueba_id is null;

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
			select grupo.*, unidad.realizacion_prueba_id
			from public.realizaciones_editor_metrico unidad
			join public.grupos_eleccion_metrica_resueltos grupo
				on grupo.arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and grupo.activo
				and grupo.alcance = 'unidad'
				and (
					(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
					or grupo.seccion_id = unidad.seccion_id
				)
			where unidad.secuencia_prueba_id = v_secuencia_id
		loop
			select count(*) into v_total
			from public.elecciones_editor_metrico
			where secuencia_prueba_id = v_secuencia_id
				and realizacion_prueba_id = v_grupo.realizacion_prueba_id
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
					realizacion_prueba_id,
					realizacion_prueba_id as unidad_id
				from public.realizaciones_editor_metrico
				where secuencia_prueba_id = v_secuencia_id
					and realizacion_padre_id is null
				union all
				select
					hija.realizacion_prueba_id,
					ascendencia.unidad_id
				from public.realizaciones_editor_metrico hija
				join ascendencia
					on ascendencia.realizacion_prueba_id = hija.realizacion_padre_id
				where hija.secuencia_prueba_id = v_secuencia_id
			),
			firmas as (
				select
					-- Una pregunta anclada en una sección se compara dentro de su unidad; una
					-- pregunta de la unidad entera, dentro de la secuencia.
					case when v_grupo.seccion_id is not null then ascendencia.unidad_id end as contenedor,
					eleccion.realizacion_prueba_id,
					string_agg(
						coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto),
						'|' order by coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto)
					) as firma
				from public.elecciones_editor_metrico eleccion
				join ascendencia
					on ascendencia.realizacion_prueba_id = eleccion.realizacion_prueba_id
				where eleccion.secuencia_prueba_id = v_secuencia_id
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
	$guardar$
;

	-- ------------------------------------------------------------------ Comprobaciones
	if (select prosrc from pg_proc where proname = 'guardar_secuencia_editor_metrico_prueba')
		not like '%etiqueta, observaciones, arquitectura_id%'
	then
		raise exception 'El guardado sigue sin persistir la arquitectura de la realización.';
	end if;

	-- Y no se ha perdido nada por el camino.
	if (select prosrc from pg_proc where proname = 'guardar_secuencia_editor_metrico_prueba')
		not like '%desviaciones_editor_metrico%'
	then
		raise exception 'El guardado ha perdido las desviaciones.';
	end if;
	if (select prosrc from pg_proc where proname = 'guardar_secuencia_editor_metrico_prueba')
		not like '%elecciones_editor_metrico%'
	then
		raise exception 'El guardado ha perdido las elecciones.';
	end if;
end $$;

commit;
