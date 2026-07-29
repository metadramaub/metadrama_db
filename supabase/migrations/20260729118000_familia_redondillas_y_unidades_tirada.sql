begin;

do $$
declare
	v_termino_raiz_id uuid := '1affe499-c92d-4cf0-a0f6-46c76a26f88f'::uuid;
	v_termino_regular_id uuid := '1525ae6c-8052-446c-af93-3042341cf610'::uuid;
	v_termino_cruzada_id uuid := 'e42244af-caae-416e-9d5e-49e6c8b7af21'::uuid;
	v_forma_redondilla_id uuid;
	v_forma_cruzada_id uuid;
	v_forma_doble_id uuid;
	v_familia_id uuid;
	v_configuracion record;
begin
	select forma_id into v_forma_redondilla_id
	from public.formas_metricas
	where slug = 'redondilla';

	select forma_id into v_forma_cruzada_id
	from public.formas_metricas
	where slug = 'cuarteta';

	select forma_id into v_forma_doble_id
	from public.formas_metricas
	where slug = 'redondilla_doble';

	if num_nonnulls(
		v_forma_redondilla_id,
		v_forma_cruzada_id,
		v_forma_doble_id
	) <> 3 then
		raise exception
			'No se encontró completo el bloque de redondillas que debe corregirse';
	end if;

	update public.formas_metricas
	set
		origen_termino_id = v_termino_regular_id,
		definicion = 'Estrofa de cuatro versos de arte menor con dos rimas consonantes abrazadas según el esquema abba. El catálogo del proyecto reconoce configuraciones octosilábica, heptasilábica y hexasilábica.',
		updated_at = now()
	where forma_id = v_forma_redondilla_id;

	update public.configuraciones_forma
	set
		origen_termino_id = null,
		updated_at = now()
	where forma_id = v_forma_redondilla_id
		and slug = 'octosilabica_abba';

	update public.formas_metricas
	set
		slug = 'redondilla_cruzada',
		nombre = 'Redondilla cruzada',
		definicion = 'Estrofa de cuatro versos octosílabos con dos rimas consonantes cruzadas según el esquema abab. El proyecto la conserva como una forma de la familia de las redondillas.',
		updated_at = now()
	where forma_id = v_forma_cruzada_id;

	delete from public.forma_aliases
	where forma_id = v_forma_cruzada_id
		and slug_normalizado in ('redondilla_cruzada', 'cuarteta');

	insert into public.forma_aliases (
		forma_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		preferente
	)
	values (
		v_forma_cruzada_id,
		'Cuarteta',
		'cuarteta',
		'equivalente',
		false
	)
	on conflict (forma_id, slug_normalizado) do update
	set
		nombre = excluded.nombre,
		tipo_alias = excluded.tipo_alias,
		preferente = excluded.preferente,
		updated_at = now();

	insert into public.familias_metricas (
		familia_id,
		slug,
		nombre,
		descripcion,
		estado_revision,
		activo,
		origen_termino_id
	)
	values (
		v_termino_raiz_id,
		'redondillas',
		'Redondillas',
		'Familia del proyecto que reúne la redondilla de rima abrazada, la redondilla cruzada y la redondilla doble.',
		'revisada',
		true,
		v_termino_raiz_id
	)
	on conflict (familia_id) do update
	set
		slug = excluded.slug,
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		origen_termino_id = excluded.origen_termino_id,
		updated_at = now()
	returning familia_id into v_familia_id;

	delete from public.familias_formas
	where familia_id = v_familia_id;

	insert into public.familias_formas (
		familia_id,
		forma_id,
		es_principal,
		orden,
		nota
	)
	values
		(
			v_familia_id,
			v_forma_redondilla_id,
			true,
			1,
			'Forma principal de cuatro versos y rima abrazada abba.'
		),
		(
			v_familia_id,
			v_forma_cruzada_id,
			false,
			2,
			'Forma de cuatro versos y rima cruzada abab; cuarteta es alias equivalente.'
		),
		(
			v_familia_id,
			v_forma_doble_id,
			false,
			3,
			'Forma de ocho versos compuesta por dos redondillas enlazadas.'
		);

	-- El editor V2 sigue siendo un espacio de prueba. Sus registros se pueden
	-- reconstruir y deben borrarse antes de sustituir las secciones referenciadas.
	delete from public.secuencias_editor_metrico
	where configuracion_id in (
		select configuracion_id
		from public.configuraciones_forma
		where forma_id in (
			v_forma_redondilla_id,
			v_forma_cruzada_id,
			v_forma_doble_id
		)
	);

	delete from public.estructuras_secciones
	where configuracion_id in (
		select configuracion_id
		from public.configuraciones_forma
		where forma_id in (
			v_forma_redondilla_id,
			v_forma_cruzada_id,
			v_forma_doble_id
		)
	);

	for v_configuracion in
		select
			configuracion.configuracion_id,
			forma.slug as forma_slug,
			case
				when forma.forma_id = v_forma_doble_id then 8
				else 4
			end as extension,
			case forma.slug
				when 'redondilla' then 'Redondilla'
				when 'redondilla_cruzada' then 'Redondilla cruzada'
				else 'Redondilla doble'
			end as nombre_unidad
		from public.configuraciones_forma configuracion
		join public.formas_metricas forma
			on forma.forma_id = configuracion.forma_id
		where configuracion.forma_id in (
			v_forma_redondilla_id,
			v_forma_cruzada_id,
			v_forma_doble_id
		)
			and configuracion.activo
	loop
		insert into public.estructuras_secciones (
			configuracion_id,
			tipo_seccion,
			nombre,
			orden,
			repeticiones_min,
			repeticiones_max,
			versos_min,
			versos_max,
			nota
		)
		values (
			v_configuracion.configuracion_id,
			v_configuracion.forma_slug,
			v_configuracion.nombre_unidad,
			1,
			1,
			null,
			v_configuracion.extension,
			v_configuracion.extension,
			format(
				'Unidad estrófica repetible de %s versos. Una secuencia extensa se descompone automáticamente en estas unidades.',
				v_configuracion.extension
			)
		);
	end loop;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'G',
		propuesta = 'Transformar la antigua raíz en la familia no seleccionable Redondillas.',
		certeza = 'alta',
		requiere_revision = false
	where termino_id = v_termino_raiz_id;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma principal redondilla, con configuraciones octosilábica, heptasilábica y hexasilábica.',
		certeza = 'alta',
		requiere_revision = false
	where termino_id = v_termino_regular_id;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma redondilla cruzada de la familia Redondillas; cuarteta es alias equivalente.',
		certeza = 'alta',
		requiere_revision = false
	where termino_id = v_termino_cruzada_id;

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_raiz_id,
		v_termino_regular_id,
		v_termino_cruzada_id
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		familia_id,
		nota
	)
	values (
		v_termino_raiz_id,
		'transformar',
		v_familia_id,
		'La antigua raíz jerárquica pasa a ser la familia no seleccionable.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values
		(
			v_termino_regular_id,
			'transformar',
			v_forma_redondilla_id,
			'La antigua redondilla regular aporta la identidad de la forma principal.'
		),
		(
			v_termino_cruzada_id,
			'conservar',
			v_forma_cruzada_id,
			'La redondilla cruzada conserva su identidad y recibe cuarteta como alias.'
		);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 29,
	actualizado_en = now()
where id = true;

commit;
