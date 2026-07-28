begin;

do $$
declare
	v_forma_id uuid;
	v_config_libre_id uuid;
	v_config_regular_id uuid;
	v_config_irregular_id uuid;
	v_config_endeca_id uuid;
	v_pm_libre_id uuid;
	v_pm_regular_id uuid;
	v_pm_irregular_id uuid;
	v_pm_endeca_id uuid;
	v_pr_libre_id uuid;
	v_pr_regular_id uuid;
	v_pr_irregular_id uuid;
	v_pr_endeca_id uuid;
	v_metro_7_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_termino_libre_id uuid;
	v_fuente_dominguez_id uuid;
	v_fuente_paraiso_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'silva';

	if v_forma_id is null then
		raise exception 'No se encontró la forma silva en el catálogo métrico';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id is null;

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración general importada para silva y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_libre_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id is null;

	select termino_id into v_termino_libre_id
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'silva_libre';

	select configuracion.configuracion_id into v_config_regular_id
	from public.configuraciones_forma configuracion
	join public.vocabularios termino
		on termino.termino_id = configuracion.origen_termino_id
	where configuracion.forma_id = v_forma_id
		and termino.termino = 'silva_de_consonantes_regular';

	select configuracion.configuracion_id into v_config_irregular_id
	from public.configuraciones_forma configuracion
	join public.vocabularios termino
		on termino.termino_id = configuracion.origen_termino_id
	where configuracion.forma_id = v_forma_id
		and termino.termino = 'silva_de_consonantes_irregular';

	select configuracion.configuracion_id into v_config_endeca_id
	from public.configuraciones_forma configuracion
	join public.vocabularios termino
		on termino.termino_id = configuracion.origen_termino_id
	where configuracion.forma_id = v_forma_id
		and termino.termino = 'silva_de_endecasilabos';

	if v_termino_libre_id is null
		or v_config_regular_id is null
		or v_config_irregular_id is null
		or v_config_endeca_id is null
	then
		raise exception
			'No se encontraron la entrada libre o las tres configuraciones de silva importadas';
	end if;

	select count(*) into v_total
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'heptasilabo'
		and numero_silabas = 7;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único metro heptasílabo activo y se encontraron %',
			v_total;
	end if;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'heptasilabo'
		and numero_silabas = 7;

	select count(*) into v_total
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único metro endecasílabo activo y se encontraron %',
			v_total;
	end if;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	select count(*) into v_total
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	if v_total <> 1 then
		raise exception
			'Se esperaba un único tipo de rima consonante activo y se encontraron %',
			v_total;
	end if;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	update public.formas_metricas
	set
		nombre = 'Silva',
		definicion = 'Serie métrica abierta y no estrófica que combina generalmente versos endecasílabos y heptasílabos —o, en alguna configuración, solo endecasílabos—, con rima consonante distribuida sin una organización estrófica fija y con posibilidad de dejar versos sueltos.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'libre',
		nombre = 'Silva libre',
		descripcion = 'Serie abierta de heptasílabos y endecasílabos con rima consonante distribuida libremente, sin organización normativa en pareados y con posibilidad de versos sueltos.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true,
		origen_termino_id = v_termino_libre_id
	where configuracion_id = v_config_libre_id;

	update public.configuraciones_forma
	set
		slug = 'consonantes_regular',
		nombre = 'Silva de consonantes regular',
		descripcion = 'Serie abierta de heptasílabos y endecasílabos organizada regularmente en pareados que repiten el orden 7 + 11. Los versos sueltos se registran como desviaciones respecto de esta norma.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_config_regular_id;

	update public.configuraciones_forma
	set
		slug = 'consonantes_irregular',
		nombre = 'Silva de consonantes irregular',
		descripcion = 'Serie abierta de heptasílabos y endecasílabos en la que predominan los pareados, pero sin repetir un orden métrico fijo. Puede incluir versos sueltos.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_config_irregular_id;

	update public.configuraciones_forma
	set
		slug = 'endecasilabica',
		nombre = 'Silva de endecasílabos',
		descripcion = 'Serie abierta exclusivamente endecasilábica en la que predominan los versos con rima consonante, a menudo organizados en pareados, aunque puede incluir versos sueltos.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_config_endeca_id;

	if not exists (
		select 1
		from public.migracion_termino_destinos
		where termino_id = v_termino_libre_id
			and configuracion_id = v_config_libre_id
	) then
		insert into public.migracion_termino_destinos (
			termino_id,
			tipo_operacion,
			configuracion_id,
			nota
		)
		values (
			v_termino_libre_id,
			'transformar',
			v_config_libre_id,
			'Se conserva la denominación del IP y se documenta su alcance específico para el corpus.'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'C',
		propuesta = 'Configuración de silva con distribución libre de la rima consonante, sin organización normativa en pareados.',
		certeza = 'alta',
		requiere_revision = true
	where termino_id = v_termino_libre_id;

	select patron_metrico_id into v_pm_libre_id
	from public.patrones_metricos where configuracion_id = v_config_libre_id;
	select patron_metrico_id into v_pm_regular_id
	from public.patrones_metricos where configuracion_id = v_config_regular_id;
	select patron_metrico_id into v_pm_irregular_id
	from public.patrones_metricos where configuracion_id = v_config_irregular_id;
	select patron_metrico_id into v_pm_endeca_id
	from public.patrones_metricos where configuracion_id = v_config_endeca_id;

	if v_pm_libre_id is null
		or v_pm_regular_id is null
		or v_pm_irregular_id is null
		or v_pm_endeca_id is null
	then
		raise exception 'Falta algún patrón métrico importado de las configuraciones de silva';
	end if;

	update public.patrones_metricos
	set
		nombre = 'Heptasílabo o endecasílabo en orden libre',
		ambito = 'serie',
		tipo = 'conjunto_permitido',
		descripcion = 'Cada verso puede ser heptasílabo o endecasílabo sin una secuencia posicional fija.',
		estado_revision = 'revisada'
	where patron_metrico_id in (v_pm_libre_id, v_pm_irregular_id);

	update public.patrones_metricos
	set
		nombre = 'Pareado 7 + 11 repetido',
		ambito = 'serie',
		tipo = 'secuencia_repetible',
		descripcion = 'Ciclo de dos posiciones: un heptasílabo seguido de un endecasílabo, repetido durante toda la serie.',
		estado_revision = 'revisada'
	where patron_metrico_id = v_pm_regular_id;

	update public.patrones_metricos
	set
		nombre = 'Endecasílabo repetido',
		ambito = 'serie',
		tipo = 'secuencia_repetible',
		descripcion = 'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
		estado_revision = 'revisada'
	where patron_metrico_id = v_pm_endeca_id;

	delete from public.patron_metrico_opciones
	where patron_metrico_id in (v_pm_libre_id, v_pm_regular_id, v_pm_irregular_id, v_pm_endeca_id);
	delete from public.patron_metrico_posiciones
	where patron_metrico_id in (v_pm_libre_id, v_pm_regular_id, v_pm_irregular_id, v_pm_endeca_id);

	insert into public.patron_metrico_opciones (
		patron_metrico_id, metro_id, orden, nota
	)
	values
		(v_pm_libre_id, v_metro_7_id, 1, 'Medida admitida en orden libre.'),
		(v_pm_libre_id, v_metro_11_id, 2, 'Medida admitida en orden libre.'),
		(v_pm_irregular_id, v_metro_7_id, 1, 'Medida admitida en orden libre.'),
		(v_pm_irregular_id, v_metro_11_id, 2, 'Medida admitida en orden libre.');

	insert into public.patron_metrico_posiciones (
		patron_metrico_id, posicion, metro_id, opcional, alternativa, nota
	)
	values
		(v_pm_regular_id, 1, v_metro_7_id, false, 1, 'Primera posición del pareado regular.'),
		(v_pm_regular_id, 2, v_metro_11_id, false, 1, 'Segunda posición del pareado regular.'),
		(v_pm_endeca_id, 1, v_metro_11_id, false, 1, 'El endecasílabo se repite durante toda la serie.');

	select patron_rima_id into v_pr_libre_id
	from public.patrones_rima where configuracion_id = v_config_libre_id;
	select patron_rima_id into v_pr_regular_id
	from public.patrones_rima where configuracion_id = v_config_regular_id;
	select patron_rima_id into v_pr_irregular_id
	from public.patrones_rima where configuracion_id = v_config_irregular_id;
	select patron_rima_id into v_pr_endeca_id
	from public.patrones_rima where configuracion_id = v_config_endeca_id;

	if v_pr_libre_id is null
		or v_pr_regular_id is null
		or v_pr_irregular_id is null
		or v_pr_endeca_id is null
	then
		raise exception 'Falta algún patrón de rima importado de las configuraciones de silva';
	end if;

	update public.patrones_rima
	set
		nombre = 'Rima libre sin organización en pareados',
		esquema = null,
		tipo_rima_id = v_consonante_id,
		ambito = 'serie',
		comportamiento = 'restricciones',
		fijeza = 'preferente',
		descripcion = 'La rima consonante se distribuye sin un esquema fijo y puede dejar versos sueltos. La configuración no se organiza normativamente mediante pareados.',
		estado_revision = 'revisada'
	where patron_rima_id = v_pr_libre_id;

	update public.patrones_rima
	set
		nombre = 'Pareados consonantes regulares',
		esquema = 'aA | bB | cC | …',
		tipo_rima_id = v_consonante_id,
		ambito = 'serie',
		comportamiento = 'secuencia_repetible',
		fijeza = 'fijo',
		descripcion = 'Cada bloque forma un pareado consonante. Las minúsculas representan heptasílabos y las mayúsculas endecasílabos; la clase de rima se renueva en cada bloque.',
		estado_revision = 'revisada'
	where patron_rima_id = v_pr_regular_id;

	update public.patrones_rima
	set
		nombre = 'Pareados consonantes predominantes',
		esquema = null,
		tipo_rima_id = v_consonante_id,
		ambito = 'serie',
		comportamiento = 'restricciones',
		fijeza = 'preferente',
		descripcion = 'Los pareados organizan predominantemente la serie, pero no siguen una sucesión métrica fija y pueden alternar con versos sueltos.',
		estado_revision = 'revisada'
	where patron_rima_id = v_pr_irregular_id;

	update public.patrones_rima
	set
		nombre = 'Predominio de rima consonante y pareados frecuentes',
		esquema = null,
		tipo_rima_id = v_consonante_id,
		ambito = 'serie',
		comportamiento = 'restricciones',
		fijeza = 'preferente',
		descripcion = 'Predominan los endecasílabos rimados y son frecuentes los pareados, aunque la serie puede incluir versos sueltos.',
		estado_revision = 'revisada'
	where patron_rima_id = v_pr_endeca_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id in (v_pr_libre_id, v_pr_regular_id, v_pr_irregular_id, v_pr_endeca_id);
	delete from public.patron_rima_enlaces
	where patron_rima_id in (v_pr_libre_id, v_pr_regular_id, v_pr_irregular_id, v_pr_endeca_id);
	delete from public.patron_rima_restricciones
	where patron_rima_id in (v_pr_libre_id, v_pr_regular_id, v_pr_irregular_id, v_pr_endeca_id);

	insert into public.patron_rima_posiciones (
		patron_rima_id, bloque, seccion, posicion, ubicacion,
		clase_rima, suelto, opcional, nota
	)
	values
		(v_pr_regular_id, 1, 'pareado', 1, 'final', 'A', false, false, 'Primer verso del pareado.'),
		(v_pr_regular_id, 1, 'pareado', 2, 'final', 'A', false, false, 'Segundo verso del pareado.');

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_numero, valor_texto, descripcion, obligatoria
	)
	values
		(v_pr_libre_id, 'otra', null, 'sin_organizacion_normativa_en_pareados', 'La configuración no se organiza normativamente mediante pareados.', true),
		(v_pr_libre_id, 'versos_sueltos', null, 'admitidos', 'Puede contener versos sueltos.', true),
		(v_pr_irregular_id, 'otra', null, 'pareados_predominantes', 'Los pareados organizan predominantemente la serie.', true),
		(v_pr_irregular_id, 'versos_sueltos', null, 'admitidos', 'Puede contener versos sueltos intercalados.', true),
		(v_pr_endeca_id, 'otra', null, 'predominio_rima_consonante', 'Predominan los versos con rima consonante.', true),
		(v_pr_endeca_id, 'otra', null, 'pareados_frecuentes', 'Los pareados son frecuentes, sin constituir un porcentaje numérico obligatorio.', true),
		(v_pr_endeca_id, 'versos_sueltos', null, 'admitidos', 'Puede contener versos sueltos.', true);

	delete from public.estructuras_secciones
	where configuracion_id in (
		v_config_libre_id, v_config_regular_id, v_config_irregular_id, v_config_endeca_id
	);

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, patron_rima_id, nota
	)
	values (
		v_config_regular_id,
		'pareado',
		'Serie de pareados regulares',
		1,
		1,
		null,
		2,
		2,
		v_pm_regular_id,
		v_pr_regular_id,
		'Cada bloque repite un heptasílabo y un endecasílabo con la misma rima consonante.'
	);

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
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id and forma_id = v_forma_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, forma_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_forma_id,
			'pp. 227-228',
			'Define la silva como combinación asimétrica de endecasílabos, o de endecasílabos y heptasílabos, con rima consonante libremente dispuesta y posibilidad de versos sueltos. Destaca que no se divide en estrofas simétricas.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id and patron_rima_id = v_pr_regular_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, patron_rima_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_pr_regular_id,
			'p. 228',
			'Documenta la silva de consonantes como modalidad ajustada a esquemas de pareados o tercetos. METADRAMA formaliza aquí la sucesión regular de pareados descrita por el IP.',
			'alta',
			'revisada'
		);
	end if;

	select fuente_id into v_fuente_paraiso_id
	from public.fuentes_metricas
	where autoria = 'Isabel Paraíso'
		and titulo = 'Arcadio Pardo y la Teoría Métrica'
		and doi = '10.5944/rhythmica.39977'
	limit 1;

	if v_fuente_paraiso_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, doi, url, cita, nota
		)
		values (
			'artículo',
			'Isabel Paraíso',
			'Arcadio Pardo y la Teoría Métrica',
			2024,
			'Rhythmica. Revista Española de Métrica Comparada, 20-21, 137-150',
			'10.5944/rhythmica.39977',
			'https://revistas.uned.es/index.php/rhythmica/article/view/39977',
			'Paraíso, Isabel. «Arcadio Pardo y la Teoría Métrica». Rhythmica 20-21 (2023), pp. 137-150. Publicado en 2024. DOI: 10.5944/rhythmica.39977.',
			'Contraste terminológico para el alcance moderno de «silva libre»; no sustituye el uso específico definido por METADRAMA para su corpus.'
		)
		returning fuente_id into v_fuente_paraiso_id;
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_paraiso_id
			and configuracion_id = v_config_libre_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, configuracion_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_paraiso_id,
			v_config_libre_id,
			'p. 146',
			'Emplea «silva libre» para una modalidad moderna de base silvística que admite más medidas y suele prescindir de la rima. Su alcance no coincide exactamente con la configuración aurisecular definida por METADRAMA y se registra como contraste terminológico.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 11,
	actualizado_en = now()
where id = true;

commit;
