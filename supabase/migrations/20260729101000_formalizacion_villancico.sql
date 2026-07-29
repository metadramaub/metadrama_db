begin;

do $$
declare
	v_forma_id uuid;
	v_forma_zejel_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_relaciones_id uuid;
	v_patron_abba_id uuid;
	v_patron_abab_id uuid;
	v_seccion_copla_id uuid;
	v_metro_6_id uuid;
	v_metro_8_id uuid;
	v_fuente_dominguez_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'villancico';

	if v_forma_id is null then
		raise exception 'No se encontró la forma villancico en el catálogo métrico';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para villancico y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select termino_id into v_metro_6_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'hexasilabo'
		and numero_silabas = 6;

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	if v_metro_6_id is null or v_metro_8_id is null then
		raise exception 'Falta el metro hexasílabo u octosílabo';
	end if;

	update public.formas_metricas
	set
		nombre = 'Villancico',
		definicion = 'Forma compuesta de arte menor, normalmente hexasílaba u octosílaba, formada por una cabeza o estribillo inicial y una o más coplas. Cada copla contiene una mudanza, generalmente de cuatro versos con esquema abba o abab, posibles versos de enlace y vuelta, y la repetición total, parcial o implícita del estribillo.',
		nivel_estructural = 'compuesta',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'estructura_habitual',
		nombre = 'Estructura habitual',
		descripcion = 'Cabeza opcional de dos a cuatro versos y una o más coplas con mudanza de cuatro versos, enlace y vuelta opcionales, y repetición del estribillo.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = null,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_id;

	select count(*) into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	if v_total = 0 then
		insert into public.patrones_metricos (
			configuracion_id,
			nombre,
			ambito,
			tipo,
			descripcion,
			estado_revision
		)
		values (
			v_configuracion_id,
			'Hexasílabo u octosílabo',
			'composicion',
			'conjunto_permitido',
			'La forma emplea versos de arte menor, normalmente hexasílabos u octosílabos, sin imponer una secuencia posicional única.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;
	elsif v_total = 1 then
		select patron_metrico_id into v_patron_metrico_id
		from public.patrones_metricos
		where configuracion_id = v_configuracion_id;

		update public.patrones_metricos
		set
			nombre = 'Hexasílabo u octosílabo',
			ambito = 'composicion',
			tipo = 'conjunto_permitido',
			descripcion = 'La forma emplea versos de arte menor, normalmente hexasílabos u octosílabos, sin imponer una secuencia posicional única.',
			estado_revision = 'revisada'
		where patron_metrico_id = v_patron_metrico_id;
	else
		raise exception
			'La configuración del villancico tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_id;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id,
		metro_id,
		orden,
		nota
	)
	values
		(v_patron_metrico_id, v_metro_6_id, 1, 'Medida habitual reconocida por el IP.'),
		(v_patron_metrico_id, v_metro_8_id, 2, 'Medida habitual reconocida por el IP.');

	select count(*) into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único patrón de rima general importado para villancico y se encontraron %',
			v_total;
	end if;

	select patron_rima_id into v_patron_relaciones_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	update public.patrones_rima
	set
		nombre = 'Relaciones entre mudanza, enlace, vuelta y estribillo',
		esquema = null,
		tipo_rima_id = null,
		ambito = 'composicion',
		comportamiento = 'restricciones',
		fijeza = 'preferente',
		descripcion = 'El enlace recupera la rima final de la mudanza; la vuelta enlaza con la cabeza o estribillo. Ambas secciones pueden omitirse según el criterio del IP.',
		estado_revision = 'revisada'
	where patron_rima_id = v_patron_relaciones_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_relaciones_id;

	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_relaciones_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_relaciones_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id,
		tipo,
		valor_texto,
		descripcion,
		obligatoria
	)
	values
		(
			v_patron_relaciones_id,
			'otra',
			'enlace_con_mudanza',
			'Cuando existe, el enlace recupera la rima final de la mudanza.',
			false
		),
		(
			v_patron_relaciones_id,
			'otra',
			'vuelta_con_estribillo',
			'Cuando existe, la vuelta enlaza mediante la rima con la cabeza o estribillo.',
			false
		);

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
		v_configuracion_id,
		'Mudanza en redondilla (abba)',
		'abba',
		null,
		'seccion',
		'secuencia_fija',
		'preferente',
		'Alternativa habitual para la mudanza de cuatro versos.',
		'revisada'
	)
	returning patron_rima_id into v_patron_abba_id;

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
		v_configuracion_id,
		'Mudanza en cuarteta (abab)',
		'abab',
		null,
		'seccion',
		'secuencia_fija',
		'preferente',
		'Alternativa habitual para la mudanza de cuatro versos.',
		'revisada'
	)
	returning patron_rima_id into v_patron_abab_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id,
		bloque,
		seccion,
		posicion,
		ubicacion,
		clase_rima,
		suelto,
		opcional,
		nota
	)
	values
		(v_patron_abba_id, 1, 'mudanza', 1, 'final', 'a', false, false, 'Primera posición de la redondilla.'),
		(v_patron_abba_id, 1, 'mudanza', 2, 'final', 'b', false, false, 'Segunda posición de la redondilla.'),
		(v_patron_abba_id, 1, 'mudanza', 3, 'final', 'b', false, false, 'Tercera posición de la redondilla.'),
		(v_patron_abba_id, 1, 'mudanza', 4, 'final', 'a', false, false, 'Cuarta posición de la redondilla.'),
		(v_patron_abab_id, 1, 'mudanza', 1, 'final', 'a', false, false, 'Primera posición de la cuarteta.'),
		(v_patron_abab_id, 1, 'mudanza', 2, 'final', 'b', false, false, 'Segunda posición de la cuarteta.'),
		(v_patron_abab_id, 1, 'mudanza', 3, 'final', 'a', false, false, 'Tercera posición de la cuarteta.'),
		(v_patron_abab_id, 1, 'mudanza', 4, 'final', 'b', false, false, 'Cuarta posición de la cuarteta.');

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

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
		v_configuracion_id,
		'cabeza',
		'Cabeza o estribillo inicial',
		1,
		0,
		1,
		2,
		4,
		'Puede coincidir total o parcialmente con el estribillo. El IP documenta casos sin cabeza explícita.'
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
		v_configuracion_id,
		'copla',
		'Copla',
		2,
		1,
		null,
		'Cada copla contiene mudanza y puede incluir enlace, vuelta y repetición del estribillo.'
	)
	returning seccion_id into v_seccion_copla_id;

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
			v_configuracion_id,
			v_seccion_copla_id,
			'mudanza',
			'Mudanza',
			1,
			1,
			1,
			4,
			4,
			'Una estrofa de cuatro versos, generalmente redondilla abba o cuarteta abab según la terminología del IP.'
		),
		(
			v_configuracion_id,
			v_seccion_copla_id,
			'enlace',
			'Enlace',
			2,
			0,
			1,
			1,
			null,
			'Uno o más versos opcionales que enlazan por la rima con la mudanza.'
		),
		(
			v_configuracion_id,
			v_seccion_copla_id,
			'vuelta',
			'Vuelta',
			3,
			0,
			1,
			1,
			null,
			'Uno o más versos opcionales que enlazan por la rima con el estribillo.'
		),
		(
			v_configuracion_id,
			v_seccion_copla_id,
			'estribillo',
			'Estribillo repetido',
			4,
			0,
			1,
			1,
			4,
			'Repetición total o parcial; puede quedar sobreentendida.'
		);

	delete from public.patron_repeticion_posiciones posicion
	using public.patrones_repeticion patron
	where posicion.patron_repeticion_id = patron.patron_repeticion_id
		and patron.configuracion_id = v_configuracion_id;

	delete from public.patrones_repeticion
	where configuracion_id = v_configuracion_id;

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
		v_configuracion_id,
		'estribillo',
		'composicion',
		'Tras cada copla se recupera total o parcialmente el estribillo inicial; la repetición completa puede quedar sobreentendida.',
		'canonica',
		'La repetición no se traduce en posiciones fijas porque su extensión depende de la cabeza y puede ser parcial o implícita.',
		'revisada'
	);

	select forma_id into v_forma_zejel_id
	from public.formas_metricas
	where slug = 'zejel';

	if v_forma_zejel_id is not null then
		insert into public.forma_relaciones (
			forma_origen_id,
			forma_destino_id,
			tipo_relacion,
			nota,
			estado_revision
		)
		values (
			v_forma_id,
			v_forma_zejel_id,
			'contrasta_con',
			'Comparten estribillo y coplas; el villancico se diferencia por la forma de la mudanza y por el enlace. La relación se precisará al revisar el zéjel.',
			'revisada'
		)
		on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
		set
			nota = excluded.nota,
			estado_revision = excluded.estado_revision;
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma compuesta con cabeza, copla, mudanza, enlace, vuelta y estribillo.',
		certeza = 'alta',
		requiere_revision = true
	where termino_id = v_forma_id;

	select fuente_id into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
		raise exception
			'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and forma_id = v_forma_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			forma_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_forma_id,
			'pp. 211-212',
			'Describe el villancico como forma fija con cabeza de dos a cuatro versos y una o más estrofas o pies: dos mudanzas simétricas y una vuelta, cuyo primer verso enlaza con la mudanza y cuyo final recupera la rima de la cabeza. Señala el uso habitual de octosílabos o hexasílabos.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 14,
	actualizado_en = now()
where id = true;

commit;
