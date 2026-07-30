begin;

do $$
declare
	v_termino_id uuid := '7baf2cc1-b4e5-43f6-9d7a-e2cd46b9856b'::uuid;
	v_forma_id uuid;
	v_config_simple_id uuid;
	v_config_compuesta_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_5_id uuid;
	v_metro_7_id uuid;
	v_asonante_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'seguidilla';

	if v_forma_id is null or v_forma_id <> v_termino_id then
		raise exception 'No se encontró la forma seguidilla con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para seguidilla y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_simple_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select termino_id into v_metro_5_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'pentasilabo'
		and numero_silabas = 5;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'heptasilabo'
		and numero_silabas = 7;

	select termino_id into v_asonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'asonante';

	if v_metro_5_id is null or v_metro_7_id is null or v_asonante_id is null then
		raise exception
			'Falta el metro pentasílabo, el heptasílabo o el tipo de rima asonante';
	end if;

	delete from public.secuencias_editor_metrico
	where configuracion_id = v_config_simple_id;
	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_config_simple_id;
	delete from public.estructuras_secciones
	where configuracion_id = v_config_simple_id;
	delete from public.patrones_repeticion
	where configuracion_id = v_config_simple_id;
	delete from public.patrones_rima
	where configuracion_id = v_config_simple_id;
	delete from public.patrones_metricos
	where configuracion_id = v_config_simple_id;
	delete from public.configuracion_rasgos
	where configuracion_id = v_config_simple_id;

	update public.formas_metricas
	set
		nombre = 'Seguidilla',
		definicion = 'Forma de arte menor basada en la alternancia de heptasílabos y pentasílabos. La configuración simple consta de cuatro versos 7-5-7-5, con asonancia entre los pares; la compuesta añade un estribillo final de tres versos 5-7-5, cuyos extremos comparten una segunda asonancia.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'simple_7575_asonante',
		nombre = 'Simple · 7-5-7-5',
		descripcion = 'Cuatro versos 7-5-7-5; primero y tercero sueltos, segundo y cuarto con una misma rima asonante.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_asonante_id,
		numero_versos = 4,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_simple_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_simple_id,
		'Esquema fijo 7-5-7-5',
		'estrofa',
		'secuencia_fija',
		'Heptasílabos en las posiciones impares y pentasílabos en las pares.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		alternativa,
		nota
	)
	values
		(v_patron_metrico_id, 1, v_metro_7_id, false, 1, 'Primer heptasílabo.'),
		(v_patron_metrico_id, 2, v_metro_5_id, false, 1, 'Primer pentasílabo.'),
		(v_patron_metrico_id, 3, v_metro_7_id, false, 1, 'Segundo heptasílabo.'),
		(v_patron_metrico_id, 4, v_metro_5_id, false, 1, 'Segundo pentasílabo.');

	insert into public.patrones_rima (
		configuracion_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_simple_id,
		'Esquema fijo -a-a',
		'-a-a',
		v_asonante_id,
		'estrofa',
		'secuencia_fija',
		'fijo',
		'Los versos 1 y 3 quedan sueltos; los versos 2 y 4 comparten asonancia.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	update public.patron_rima_posiciones
	set
		bloque = 1,
		seccion = 'seguidilla_simple',
		nota = case when suelto
			then 'Verso impar suelto.'
			else 'Rima asonante de los versos pares.'
		end
	where patron_rima_id = v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		patron_metrico_id,
		patron_rima_id,
		nota
	)
	values (
		v_config_simple_id,
		'seguidilla_simple',
		'Seguidilla simple',
		1,
		1,
		1,
		4,
		4,
		v_patron_metrico_id,
		v_patron_rima_id,
		'Unidad fija de cuatro versos.'
	);

	insert into public.configuraciones_forma (
		forma_id,
		slug,
		nombre,
		descripcion,
		principal,
		demarcable,
		grado,
		tipo_rima_id,
		numero_versos,
		estado_revision,
		activo,
		orden
	)
	values (
		v_forma_id,
		'compuesta_7575575_asonante',
		'Compuesta · 7-5-7-5 + 5-7-5',
		'Siete versos: una seguidilla simple seguida de un estribillo 5-7-5 con asonancia propia entre sus extremos.',
		false,
		true,
		'canonica',
		v_asonante_id,
		7,
		'revisada',
		true,
		2
	)
	returning configuracion_id into v_config_compuesta_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_compuesta_id,
		'Esquema fijo 7-5-7-5-5-7-5',
		'estrofa',
		'secuencia_fija',
		'La seguidilla simple ocupa las posiciones 1-4 y el estribillo 5-7-5 las posiciones 5-7.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		alternativa,
		nota
	)
	values
		(v_patron_metrico_id, 1, v_metro_7_id, false, 1, 'Cuerpo: primer heptasílabo.'),
		(v_patron_metrico_id, 2, v_metro_5_id, false, 1, 'Cuerpo: primer pentasílabo.'),
		(v_patron_metrico_id, 3, v_metro_7_id, false, 1, 'Cuerpo: segundo heptasílabo.'),
		(v_patron_metrico_id, 4, v_metro_5_id, false, 1, 'Cuerpo: segundo pentasílabo.'),
		(v_patron_metrico_id, 5, v_metro_5_id, false, 1, 'Estribillo: primer pentasílabo.'),
		(v_patron_metrico_id, 6, v_metro_7_id, false, 1, 'Estribillo: heptasílabo central.'),
		(v_patron_metrico_id, 7, v_metro_5_id, false, 1, 'Estribillo: pentasílabo final.');

	insert into public.patrones_rima (
		configuracion_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_compuesta_id,
		'Esquema fijo -a-ab-b',
		'-a-ab-b',
		v_asonante_id,
		'estrofa',
		'secuencia_fija',
		'fijo',
		'El cuerpo presenta -a-a; el estribillo presenta b-b con una asonancia independiente.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	update public.patron_rima_posiciones
	set
		bloque = case when posicion <= 4 then 1 else 2 end,
		seccion = case when posicion <= 4 then 'seguidilla_simple' else 'estribillo' end,
		nota = case
			when posicion <= 4 and suelto then 'Cuerpo: verso impar suelto.'
			when posicion <= 4 then 'Cuerpo: asonancia a de los versos pares.'
			when suelto then 'Estribillo: heptasílabo central suelto.'
			else 'Estribillo: asonancia b de los pentasílabos extremos.'
		end
	where patron_rima_id = v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		configuracion_referenciada_id,
		nota
	)
	values (
		v_config_compuesta_id,
		'seguidilla_simple',
		'Cuerpo',
		1,
		1,
		1,
		4,
		4,
		v_config_simple_id,
		'Reutiliza la configuración simple de cuatro versos.'
	);

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
		v_config_compuesta_id,
		'estribillo',
		'Estribillo final',
		2,
		1,
		1,
		3,
		3,
		'Tres versos 5-7-5; los pentasílabos extremos comparten una asonancia distinta de la del cuerpo.'
	);

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_id is null then
		raise exception
			'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	update public.afirmaciones_fuentes_metricas
	set
		localizador = 'pp. 192-193',
		resumen = 'Describe la seguidilla simple como 7-5-7-5 con asonancia en los pentasílabos pares y la compuesta como adición de un estribillo 5-7-5 con asonancia entre sus extremos. Documenta fluctuaciones de medida y consonancia que el catálogo trata como desviaciones respecto del criterio fijado por el proyecto.',
		confianza = 'alta',
		estado_revision = 'revisada',
		updated_at = now()
	where fuente_id = v_fuente_id
		and forma_id = v_forma_id;

	if not found then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			forma_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_id,
			v_forma_id,
			'pp. 192-193',
			'Describe la seguidilla simple como 7-5-7-5 con asonancia en los pentasílabos pares y la compuesta como adición de un estribillo 5-7-5 con asonancia entre sus extremos. Documenta fluctuaciones de medida y consonancia que el catálogo trata como desviaciones respecto del criterio fijado por el proyecto.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como una forma con configuraciones simple de cuatro versos y compuesta de siete.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_termino_id;

	delete from public.migracion_termino_destinos
	where termino_id = v_termino_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values (
		v_termino_id,
		'conservar',
		v_forma_id,
		'La entrada anterior se conserva como forma; la alternativa 4/7 se expresa mediante dos configuraciones normalizadas.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 37,
	actualizado_en = now()
where id = true;

commit;
