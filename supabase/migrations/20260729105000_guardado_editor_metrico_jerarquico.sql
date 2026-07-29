begin;

-- La cardinalidad de una sección hija se valida por cada unidad padre mediante
-- los triggers diferidos de la versión 16. El guardado anterior la contaba en
-- toda la secuencia y confundía, por ejemplo, «una mudanza por copla» con «una
-- única mudanza en todo el villancico».
create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
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
			escenario_id,
			orden,
			v_ini,
			v_fin,
			forma_id,
			configuracion_id,
			observaciones,
			created_by,
			updated_by
		)
		values (
			(p_datos ->> 'escenario_id')::uuid,
			(p_datos ->> 'orden')::integer,
			(p_datos ->> 'v_ini')::integer,
			(p_datos ->> 'v_fin')::integer,
			(p_datos ->> 'forma_id')::uuid,
			(p_datos ->> 'configuracion_id')::uuid,
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
			configuracion_id = (p_datos ->> 'configuracion_id')::uuid,
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
	delete from public.unidades_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
	loop
		insert into public.unidades_editor_metrico (
			unidad_prueba_id,
			secuencia_prueba_id,
			unidad_padre_id,
			seccion_id,
			orden,
			v_ini,
			v_fin,
			etiqueta,
			observaciones
		)
		values (
			(v_item ->> 'unidad_prueba_id')::uuid,
			v_secuencia_id,
			nullif(v_item ->> 'unidad_padre_id', '')::uuid,
			(v_item ->> 'seccion_id')::uuid,
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
			unidad_prueba_id,
			grupo_eleccion_id,
			opcion_eleccion_id,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'unidad_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			(v_item ->> 'opcion_eleccion_id')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
	loop
		insert into public.desviaciones_editor_metrico (
			secuencia_prueba_id,
			unidad_prueba_id,
			v_ini,
			v_fin,
			dimension,
			relacion_norma,
			metro_observado_id,
			patron_rima_observado_id,
			seccion_observada_id,
			patron_repeticion_observado_id,
			valor_rasgo_observado_id,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'unidad_prueba_id', '')::uuid,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			v_item ->> 'dimension',
			v_item ->> 'relacion_norma',
			nullif(v_item ->> 'metro_observado_id', '')::uuid,
			nullif(v_item ->> 'patron_rima_observado_id', '')::uuid,
			nullif(v_item ->> 'seccion_observada_id', '')::uuid,
			nullif(v_item ->> 'patron_repeticion_observado_id', '')::uuid,
			nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_grupo in
		select *
		from public.grupos_eleccion_metrica
		where configuracion_id = (p_datos ->> 'configuracion_id')::uuid
			and activo
			and alcance = 'secuencia'
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id
			and unidad_prueba_id is null;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	for v_grupo in
		select
			grupo.*,
			unidad.unidad_prueba_id
		from public.unidades_editor_metrico unidad
		join public.grupos_eleccion_metrica grupo
			on grupo.configuracion_id = (p_datos ->> 'configuracion_id')::uuid
			and grupo.activo
			and grupo.alcance = 'unidad'
			and (grupo.seccion_id is null or grupo.seccion_id = unidad.seccion_id)
		where unidad.secuencia_prueba_id = v_secuencia_id
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and unidad_prueba_id = v_grupo.unidad_prueba_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	return v_secuencia_id;
end;
$$;

revoke all on function public.guardar_secuencia_editor_metrico_prueba(jsonb) from public;
grant execute on function public.guardar_secuencia_editor_metrico_prueba(jsonb) to authenticated;

commit;
