begin;

do $$
declare
	v_termino_id uuid := '5c7527be-75e8-44b3-bb5e-fbf62174c569'::uuid;
	v_forma_id uuid;
	v_config_clasica_id uuid;
	v_config_doble_id uuid;
	v_patron_metrico_id uuid;
	v_patron_repeticion_id uuid;
	v_seccion_raiz_id uuid;
	v_metro_11_id uuid;
	v_sin_rima_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'sextina';

	if v_forma_id is null or v_forma_id <> v_termino_id then
		raise exception 'No se encontró la forma sextina con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para sextina y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_clasica_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	-- La normalización antigua eliminó `sin_rima` y lo convirtió en NULL.
	-- El catálogo nuevo necesita distinguir explícitamente la ausencia normativa
	-- de rima de un dato todavía no declarado.
	insert into public.vocabularios (
		termino_id,
		categoria,
		termino,
		etiqueta,
		nivel,
		orden,
		activo
	)
	values (
		'587b9a6c-41e8-4e36-9807-da49f19647a6'::uuid,
		'tipo_rima',
		'sin_rima',
		'Sin rima',
		1,
		30,
		true
	)
	on conflict (categoria, termino)
	do update set
		etiqueta = excluded.etiqueta,
		nivel = coalesce(public.vocabularios.nivel, excluded.nivel),
		orden = coalesce(public.vocabularios.orden, excluded.orden),
		activo = true,
		updated_at = now();

	select termino_id into v_sin_rima_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'sin_rima';

	if v_metro_11_id is null then
		raise exception 'Falta el metro endecasílabo';
	end if;

	if v_sin_rima_id is null then
		raise exception 'No se pudo crear o resolver el tipo sin rima';
	end if;

	delete from public.secuencias_editor_metrico
	where configuracion_id = v_config_clasica_id;
	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_config_clasica_id;
	delete from public.estructuras_secciones
	where configuracion_id = v_config_clasica_id;
	delete from public.patrones_repeticion
	where configuracion_id = v_config_clasica_id;
	delete from public.patrones_rima
	where configuracion_id = v_config_clasica_id;
	delete from public.patrones_metricos
	where configuracion_id = v_config_clasica_id;
	delete from public.configuracion_rasgos
	where configuracion_id = v_config_clasica_id;

	update public.formas_metricas
	set
		nombre = 'Sextina',
		definicion = 'Composición fija de endecasílabos organizada en estrofas de seis versos y un remate de tres. Seis palabras finales se permutan entre las estrofas según un orden fijo y reaparecen, una en el interior y otra al final de cada verso, en el remate. La sextina clásica tiene seis estrofas y 39 versos; la doble repite el ciclo estrófico y alcanza 75.',
		nivel_estructural = 'composicion',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'clasica_6x6_mas_3',
		nombre = 'Clásica · 6 × 6 + 3',
		descripcion = 'Seis estrofas de seis endecasílabos y un remate de tres; seis palabras finales siguen una permutación fija.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_sin_rima_id,
		numero_versos = 39,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_clasica_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_clasica_id,
		'Endecasílabo repetido',
		'composicion',
		'secuencia_repetible',
		'Un endecasílabo por cada posición, repetido durante los 39 versos de la composición.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		grupo_repeticion,
		alternativa,
		nota
	)
	values (
		v_patron_metrico_id,
		1,
		v_metro_11_id,
		false,
		'todos_los_versos',
		1,
		'Esta única posición se repite en toda la composición.'
	);

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		nota
	)
	values (
		v_config_clasica_id,
		'sextina',
		'Sextina completa',
		1,
		1,
		1,
		'La extensión total se deriva de seis estrofas de seis versos y un remate de tres.'
	)
	returning seccion_id into v_seccion_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		seccion_padre_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values
		(
			v_config_clasica_id,
			v_seccion_raiz_id,
			'estrofa',
			'Estrofa',
			1,
			6,
			6,
			6,
			6,
			'Cada estrofa contiene seis endecasílabos.'
		),
		(
			v_config_clasica_id,
			v_seccion_raiz_id,
			'remate',
			'Remate',
			2,
			1,
			1,
			3,
			3,
			'Cada verso recupera dos palabras: una en el interior y otra al final.'
		);

	insert into public.patrones_repeticion (
		configuracion_id,
		tipo,
		ambito,
		regla,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_clasica_id,
		'palabra_final',
		'composicion',
		'Seis palabras finales siguen la permutación ABCDEF → FAEBDC → CFDABE → ECBFAD → DEACFB → BDFECA. El remate recupera las seis, una en el interior y otra al final de cada verso.',
		'fija',
		'Seis palabras finales permutadas en seis estrofas y recuperadas en el remate.',
		'revisada'
	)
	returning patron_repeticion_id into v_patron_repeticion_id;

	insert into public.patron_repeticion_posiciones (
		patron_repeticion_id,
		bloque,
		posicion,
		bloque_origen,
		posicion_origen,
		etiqueta_funcional
	)
	select
		v_patron_repeticion_id,
		permutacion.bloque,
		permutacion.posicion,
		case when permutacion.bloque = 1 then null else 1 end,
		case when permutacion.bloque = 1 then null else permutacion.origen end,
		chr(64 + permutacion.origen)
	from (
		values
			(1, 1, 1), (1, 2, 2), (1, 3, 3), (1, 4, 4), (1, 5, 5), (1, 6, 6),
			(2, 1, 6), (2, 2, 1), (2, 3, 5), (2, 4, 2), (2, 5, 4), (2, 6, 3),
			(3, 1, 3), (3, 2, 6), (3, 3, 4), (3, 4, 1), (3, 5, 2), (3, 6, 5),
			(4, 1, 5), (4, 2, 3), (4, 3, 2), (4, 4, 6), (4, 5, 1), (4, 6, 4),
			(5, 1, 4), (5, 2, 5), (5, 3, 1), (5, 4, 3), (5, 5, 6), (5, 6, 2),
			(6, 1, 2), (6, 2, 4), (6, 3, 6), (6, 4, 5), (6, 5, 3), (6, 6, 1)
	) as permutacion (bloque, posicion, origen);

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
		'doble_12x6_mas_3',
		'Doble · 12 × 6 + 3',
		'Doce estrofas de seis endecasílabos y un remate de tres; el ciclo de permutación de las seis palabras finales se completa dos veces.',
		false,
		true,
		'admitida',
		v_sin_rima_id,
		75,
		'revisada',
		true,
		2
	)
	returning configuracion_id into v_config_doble_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_doble_id,
		'Endecasílabo repetido',
		'composicion',
		'secuencia_repetible',
		'Un endecasílabo por cada posición, repetido durante los 75 versos de la composición.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		grupo_repeticion,
		alternativa,
		nota
	)
	values (
		v_patron_metrico_id,
		1,
		v_metro_11_id,
		false,
		'todos_los_versos',
		1,
		'Esta única posición se repite en toda la composición.'
	);

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		nota
	)
	values (
		v_config_doble_id,
		'sextina',
		'Sextina doble completa',
		1,
		1,
		1,
		'La extensión total se deriva de doce estrofas de seis versos y un remate de tres.'
	)
	returning seccion_id into v_seccion_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		seccion_padre_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values
		(
			v_config_doble_id,
			v_seccion_raiz_id,
			'estrofa',
			'Estrofa',
			1,
			12,
			12,
			6,
			6,
			'Cada estrofa contiene seis endecasílabos.'
		),
		(
			v_config_doble_id,
			v_seccion_raiz_id,
			'remate',
			'Remate',
			2,
			1,
			1,
			3,
			3,
			'El remate es simple y recupera las seis palabras.'
		);

	insert into public.patrones_repeticion (
		configuracion_id,
		tipo,
		ambito,
		regla,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_doble_id,
		'palabra_final',
		'composicion',
		'El ciclo ABCDEF → FAEBDC → CFDABE → ECBFAD → DEACFB → BDFECA se completa dos veces con las mismas seis palabras finales. El remate simple recupera las seis.',
		'fija',
		'Seis palabras finales permutadas durante dos ciclos estróficos y recuperadas en el remate.',
		'revisada'
	)
	returning patron_repeticion_id into v_patron_repeticion_id;

	insert into public.patron_repeticion_posiciones (
		patron_repeticion_id,
		bloque,
		posicion,
		bloque_origen,
		posicion_origen,
		etiqueta_funcional
	)
	select
		v_patron_repeticion_id,
		permutacion.bloque + ciclo.desplazamiento,
		permutacion.posicion,
		case
			when permutacion.bloque = 1 and ciclo.desplazamiento = 0 then null
			else 1
		end,
		case
			when permutacion.bloque = 1 and ciclo.desplazamiento = 0 then null
			else permutacion.origen
		end,
		chr(64 + permutacion.origen)
	from (
		values
			(1, 1, 1), (1, 2, 2), (1, 3, 3), (1, 4, 4), (1, 5, 5), (1, 6, 6),
			(2, 1, 6), (2, 2, 1), (2, 3, 5), (2, 4, 2), (2, 5, 4), (2, 6, 3),
			(3, 1, 3), (3, 2, 6), (3, 3, 4), (3, 4, 1), (3, 5, 2), (3, 6, 5),
			(4, 1, 5), (4, 2, 3), (4, 3, 2), (4, 4, 6), (4, 5, 1), (4, 6, 4),
			(5, 1, 4), (5, 2, 5), (5, 3, 1), (5, 4, 3), (5, 5, 6), (5, 6, 2),
			(6, 1, 2), (6, 2, 4), (6, 3, 6), (6, 4, 5), (6, 5, 3), (6, 6, 1)
	) as permutacion (bloque, posicion, origen)
	cross join (values (0), (6)) as ciclo (desplazamiento);

	insert into public.formas_tradiciones (
		forma_id,
		tradicion_id,
		tipo_relacion,
		es_principal,
		nota
	)
	select
		v_forma_id,
		tradicion.tradicion_id,
		'origen',
		true,
		'Domínguez Caparrós atribuye la invención de la sextina al trovador provenzal Arnaut Daniel.'
	from public.tradiciones_metricas tradicion
	where tradicion.slug = 'provenzal'
	on conflict (forma_id, tradicion_id, tipo_relacion)
	do update set
		es_principal = excluded.es_principal,
		nota = excluded.nota,
		updated_at = now();

	insert into public.formas_tradiciones (
		forma_id,
		tradicion_id,
		tipo_relacion,
		es_principal,
		nota
	)
	select
		v_forma_id,
		tradicion.tradicion_id,
		'adaptacion',
		false,
		'La forma fue introducida en la poesía italiana por Dante y cultivada por Petrarca antes de su recepción hispánica.'
	from public.tradiciones_metricas tradicion
	where tradicion.slug = 'italiana'
	on conflict (forma_id, tradicion_id, tipo_relacion)
	do update set
		es_principal = excluded.es_principal,
		nota = excluded.nota,
		updated_at = now();

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
		localizador = 'pp. 216-218',
		resumen = 'Define la sextina como poema de 39 endecasílabos en seis estrofas de seis y remate de tres; formaliza la permutación de las seis palabras-rima y documenta su origen provenzal y transmisión italiana.',
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
			'pp. 216-218',
			'Define la sextina como poema de 39 endecasílabos en seis estrofas de seis y remate de tres; formaliza la permutación de las seis palabras-rima y documenta su origen provenzal y transmisión italiana.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma compuesta con configuraciones clásica de 39 versos y doble de 75; formalizar secciones y permutación léxica.',
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
		'La entrada anterior se conserva como forma; la clásica y la doble son configuraciones normalizadas.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 38,
	actualizado_en = now()
where id = true;

commit;
