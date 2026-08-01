begin;

-- El alias `ambito` de la función de guardado no era la columna `ambito` de los esquemas:
-- nombraba una columna del resultado intermedio de una consulta, la realización que contiene
-- las respuestas que se comparan cuando un grupo declara la norma. Se llama `contenedor`,
-- que es lo que es, para que la misma palabra no signifique dos cosas dentro del esquema.

create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $guardar$
declare
	v_secuencia_id uuid;
	v_item jsonb;
	v_grupo record;
	v_total integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
			using errcode = '42501';
	end if;

	v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;

	if v_secuencia_id is null then
		insert into public.secuencias_editor_metrico (
			escenario_id, orden, v_ini, v_fin, forma_id, arquitectura_id,
			observaciones, created_by, updated_by
		)
		values (
			(p_datos ->> 'escenario_id')::uuid,
			(p_datos ->> 'orden')::integer,
			(p_datos ->> 'v_ini')::integer,
			(p_datos ->> 'v_fin')::integer,
			(p_datos ->> 'forma_id')::uuid,
			(p_datos ->> 'arquitectura_id')::uuid,
			nullif(btrim(p_datos ->> 'observaciones'), ''),
			auth.uid(),
			auth.uid()
		)
		returning secuencia_prueba_id into v_secuencia_id;
	else
		update public.secuencias_editor_metrico
		set
			escenario_id = (p_datos ->> 'escenario_id')::uuid,
			orden = (p_datos ->> 'orden')::integer,
			v_ini = (p_datos ->> 'v_ini')::integer,
			v_fin = (p_datos ->> 'v_fin')::integer,
			forma_id = (p_datos ->> 'forma_id')::uuid,
			arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid,
			observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
			updated_by = auth.uid()
		where secuencia_prueba_id = v_secuencia_id
			and exists (
				select 1 from public.escenarios_editor_metrico
				where escenario_id = (p_datos ->> 'escenario_id')::uuid
			);

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
			orden, v_ini, v_fin, etiqueta, observaciones
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
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
	loop
		insert into public.elecciones_editor_metrico (
			secuencia_prueba_id,
			realizacion_prueba_id,
			grupo_eleccion_id,
			opcion_eleccion_id,
			valor_texto,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			nullif(v_item ->> 'opcion_eleccion_id', '')::uuid,
			nullif(btrim(v_item ->> 'valor_texto'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
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
		from public.grupos_eleccion_metrica
		where arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
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
		join public.grupos_eleccion_metrica grupo
			on grupo.arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
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
		from public.grupos_eleccion_metrica
		where arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
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
$guardar$;

commit;
