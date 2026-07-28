begin;

do $$
declare
	v_forma_terceto_id uuid;
	v_forma_encadenado_id uuid;
	v_configuracion_terceto_id uuid;
	v_configuracion_encadenado_id uuid;
	v_configuracion_octosilabica_id uuid;
	v_patron_metrico_terceto_id uuid;
	v_patron_metrico_encadenado_id uuid;
	v_patron_metrico_octosilabico_id uuid;
	v_patron_rima_encadenado_id uuid;
	v_familia_id uuid;
	v_metro_endecasilabo_id uuid;
	v_metro_octosilabo_id uuid;
	v_tipo_consonante_id uuid;
	v_termino_octosilabo_id uuid;
	v_fuente_dominguez_id uuid;
	v_total integer;
begin
	select forma_id
	into v_forma_terceto_id
	from public.formas_metricas
	where slug = 'terceto';

	select forma_id
	into v_forma_encadenado_id
	from public.formas_metricas
	where slug = 'terceto_encadenado';

	if v_forma_terceto_id is null or v_forma_encadenado_id is null then
		raise exception
			'No se encontraron las formas terceto y terceto_encadenado en el catálogo métrico';
	end if;

	select count(*)
	into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_terceto_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para terceto y se encontraron %',
			v_total;
	end if;

	select configuracion_id
	into v_configuracion_terceto_id
	from public.configuraciones_forma
	where forma_id = v_forma_terceto_id;

	select count(*)
	into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_encadenado_id
		and origen_termino_id is null;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración principal importada para terceto encadenado y se encontraron %',
			v_total;
	end if;

	select configuracion_id
	into v_configuracion_encadenado_id
	from public.configuraciones_forma
	where forma_id = v_forma_encadenado_id
		and origen_termino_id is null;

	select count(*)
	into v_total
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

	select termino_id
	into v_metro_endecasilabo_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	select count(*)
	into v_total
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único metro octosílabo activo y se encontraron %',
			v_total;
	end if;

	select termino_id
	into v_metro_octosilabo_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	select count(*)
	into v_total
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	if v_total <> 1 then
		raise exception
			'Se esperaba un único tipo de rima consonante activo y se encontraron %',
			v_total;
	end if;

	select termino_id
	into v_tipo_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	update public.formas_metricas
	set
		nombre = 'Terceto',
		definicion = 'Estrofa de tres versos endecasílabos con rima consonante en la que, al menos, el primero rima con el tercero. Puede emplearse como unidad autónoma o integrarse en series; cuando el segundo verso anticipa la rima del terceto siguiente, las unidades forman la forma distinta denominada terceto encadenado.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_terceto_id;

	update public.configuraciones_forma
	set
		slug = 'endecasilabico_consonante',
		nombre = 'Terceto endecasilábico consonante',
		descripcion = 'Tres versos endecasílabos con rima consonante entre el primero y el tercero. La forma no presupone por sí sola el encadenamiento con otros tercetos.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 3,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_terceto_id;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_terceto_id;

	if v_total <> 1 then
		raise exception
			'La configuración del terceto tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	select patron_metrico_id
	into v_patron_metrico_terceto_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_terceto_id;

	update public.patrones_metricos
	set
		nombre = 'Tres endecasílabos',
		ambito = 'estrofa',
		tipo = 'secuencia_fija',
		descripcion = 'Una posición endecasilábica por cada uno de los tres versos de la estrofa.',
		estado_revision = 'revisada'
	where patron_metrico_id = v_patron_metrico_terceto_id;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_terceto_id;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_terceto_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		alternativa,
		nota
	)
	select
		v_patron_metrico_terceto_id,
		posicion,
		v_metro_endecasilabo_id,
		false,
		1,
		'Posición endecasilábica fija del terceto.'
	from generate_series(1, 3) as posiciones(posicion);

	-- Los dos patrones heredados describen series completas sin encadenar, no
	-- alternativas de rima de una estrofa aislada. Se conservan para resolver
	-- su destino con el IP, pero no deben contaminar el demarcador del terceto.
	update public.patrones_rima patron
	set
		ambito = 'serie',
		comportamiento = 'pendiente_revision',
		estado_revision = 'borrador'
	from public.vocabularios termino
	where patron.origen_termino_id = termino.termino_id
		and termino.termino in (
			'terceto_sin_encadenar_1_AXABYB',
			'terceto_sin_encadenar_2_XAAYBB'
		);

	update public.formas_metricas
	set
		nombre = 'Terceto encadenado',
		definicion = 'Serie métrica continua de versos endecasílabos con rima consonante, organizada en tercetos encadenados. La rima del segundo verso de cada terceto se retoma en el primero y el tercero del siguiente, de acuerdo con la sucesión ABA | BCB | CDC | … . La cadena se cierra con un serventesio YZYZ, que recupera la rima pendiente del último terceto.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_encadenado_id;

	update public.configuraciones_forma
	set
		slug = 'endecasilabico_consonante',
		nombre = 'Terceto encadenado endecasilábico consonante',
		descripcion = 'Serie abierta de endecasílabos organizada en unidades de tres versos enlazadas por la rima, con cierre en serventesio YZYZ.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_encadenado_id;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_encadenado_id;

	if v_total <> 1 then
		raise exception
			'La configuración del terceto encadenado tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	select patron_metrico_id
	into v_patron_metrico_encadenado_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_encadenado_id;

	update public.patrones_metricos
	set
		nombre = 'Endecasílabo repetido',
		ambito = 'serie',
		tipo = 'secuencia_repetible',
		descripcion = 'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
		estado_revision = 'revisada'
	where patron_metrico_id = v_patron_metrico_encadenado_id;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_encadenado_id;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_encadenado_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		alternativa,
		nota
	)
	values (
		v_patron_metrico_encadenado_id,
		1,
		v_metro_endecasilabo_id,
		false,
		1,
		'El ciclo métrico de un solo verso se repite durante toda la serie.'
	);

	select count(*)
	into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_encadenado_id;

	if v_total <> 1 then
		raise exception
			'La configuración del terceto encadenado tiene % patrones de rima; deben revisarse antes de normalizarla',
			v_total;
	end if;

	select patron_rima_id
	into v_patron_rima_encadenado_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_encadenado_id;

	update public.patrones_rima
	set
		nombre = 'Encadenamiento consonante con cierre en serventesio',
		esquema = 'ABA | BCB | CDC | … | YZYZ',
		tipo_rima_id = v_tipo_consonante_id,
		ambito = 'serie',
		comportamiento = 'secuencia_repetible',
		fijeza = 'fijo',
		descripcion = 'La clase del segundo verso de cada terceto reaparece en el primero y el tercero de la unidad siguiente. El último terceto YZY recibe un verso Z y forma el serventesio final YZYZ.',
		estado_revision = 'revisada'
	where patron_rima_id = v_patron_rima_encadenado_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_rima_encadenado_id;

	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_rima_encadenado_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_encadenado_id;

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
		(
			v_patron_rima_encadenado_id,
			1,
			'terceto',
			1,
			'final',
			'A',
			false,
			false,
			'Primera aparición de la rima exterior de la unidad.'
		),
		(
			v_patron_rima_encadenado_id,
			1,
			'terceto',
			2,
			'final',
			'B',
			false,
			false,
			'Rima que enlaza con la unidad siguiente.'
		),
		(
			v_patron_rima_encadenado_id,
			1,
			'terceto',
			3,
			'final',
			'A',
			false,
			false,
			'Segunda aparición de la rima exterior de la unidad.'
		);

	insert into public.patron_rima_enlaces (
		patron_rima_id,
		bloque_origen,
		posicion_origen,
		ubicacion_origen,
		desplazamiento_bloque,
		bloque_destino,
		posicion_destino,
		ubicacion_destino,
		tipo_enlace,
		obligatorio,
		nota
	)
	values
		(
			v_patron_rima_encadenado_id,
			1,
			2,
			'final',
			1,
			1,
			1,
			'final',
			'misma_rima',
			true,
			'La rima central pasa al primer verso del terceto siguiente.'
		),
		(
			v_patron_rima_encadenado_id,
			1,
			2,
			'final',
			1,
			1,
			3,
			'final',
			'misma_rima',
			true,
			'La rima central pasa al tercer verso del terceto siguiente.'
		);

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_encadenado_id;

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
	values
		(
			v_configuracion_encadenado_id,
			'terceto',
			'Cadena de tercetos',
			1,
			1,
			null,
			3,
			3,
			v_patron_metrico_encadenado_id,
			v_patron_rima_encadenado_id,
			'Cada unidad retoma en sus versos primero y tercero la rima central de la unidad anterior.'
		),
		(
			v_configuracion_encadenado_id,
			'cierre',
			'Verso de cierre del serventesio',
			2,
			1,
			1,
			1,
			1,
			v_patron_metrico_encadenado_id,
			v_patron_rima_encadenado_id,
			'El verso Z añadido al último terceto YZY completa el serventesio YZYZ.'
		);

	insert into public.familias_metricas (
		slug,
		nombre,
		descripcion,
		estado_revision,
		activo
	)
	values (
		'tercetos',
		'Tercetos',
		'Agrupa formas basadas en unidades de tres versos, sin transmitir por sí sola el nivel estructural, la medida ni las reglas de enlace.',
		'revisada',
		true
	)
	on conflict (slug) do update
	set
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo;

	select familia_id
	into v_familia_id
	from public.familias_metricas
	where slug = 'tercetos';

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
			v_forma_terceto_id,
			true,
			1,
			'Unidad estrófica de referencia de la familia.'
		),
		(
			v_familia_id,
			v_forma_encadenado_id,
			false,
			2,
			'Serie construida mediante tercetos enlazados.'
		)
	on conflict (familia_id, forma_id) do update
	set
		es_principal = excluded.es_principal,
		orden = excluded.orden,
		nota = excluded.nota;

	insert into public.forma_relaciones (
		forma_origen_id,
		forma_destino_id,
		tipo_relacion,
		nota,
		estado_revision
	)
	values (
		v_forma_encadenado_id,
		v_forma_terceto_id,
		'relacionada_con',
		'La serie se construye mediante unidades de terceto enlazadas; no es un subtipo porque cambia el nivel estructural.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set
		nota = excluded.nota,
		estado_revision = excluded.estado_revision;

	select termino_id
	into v_termino_octosilabo_id
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'terceto_octosilabo';

	if v_termino_octosilabo_id is not null then
		select configuracion_id
		into v_configuracion_octosilabica_id
		from public.configuraciones_forma
		where origen_termino_id = v_termino_octosilabo_id;

		if v_configuracion_octosilabica_id is null then
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
				origen_termino_id
			)
			values (
				v_forma_encadenado_id,
				'octosilabico',
				'Terceto encadenado octosilábico',
				'Adaptación a versos octosílabos de la serie de tercetos encadenados. Se conserva como configuración provisional hasta confirmar su alcance exacto con el IP.',
				false,
				false,
				'admitida',
				v_tipo_consonante_id,
				null,
				'borrador',
				true,
				v_termino_octosilabo_id
			)
			returning configuracion_id into v_configuracion_octosilabica_id;
		else
			update public.configuraciones_forma
			set
				forma_id = v_forma_encadenado_id,
				slug = 'octosilabico',
				nombre = 'Terceto encadenado octosilábico',
				descripcion = 'Adaptación a versos octosílabos de la serie de tercetos encadenados. Se conserva como configuración provisional hasta confirmar su alcance exacto con el IP.',
				principal = false,
				demarcable = false,
				grado = 'admitida',
				tipo_rima_id = v_tipo_consonante_id,
				numero_versos = null,
				estado_revision = 'borrador',
				activo = true
			where configuracion_id = v_configuracion_octosilabica_id;
		end if;

		select count(*)
		into v_total
		from public.patrones_metricos
		where configuracion_id = v_configuracion_octosilabica_id;

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
				v_configuracion_octosilabica_id,
				'Octosílabo repetido',
				'serie',
				'secuencia_repetible',
				'Un verso octosílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
				'borrador'
			)
			returning patron_metrico_id into v_patron_metrico_octosilabico_id;
		elsif v_total = 1 then
			select patron_metrico_id
			into v_patron_metrico_octosilabico_id
			from public.patrones_metricos
			where configuracion_id = v_configuracion_octosilabica_id;

			update public.patrones_metricos
			set
				nombre = 'Octosílabo repetido',
				ambito = 'serie',
				tipo = 'secuencia_repetible',
				descripcion = 'Un verso octosílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
				estado_revision = 'borrador'
			where patron_metrico_id = v_patron_metrico_octosilabico_id;
		else
			raise exception
				'La configuración octosilábica tiene % patrones métricos; deben revisarse antes de normalizarla',
				v_total;
		end if;

		delete from public.patron_metrico_opciones
		where patron_metrico_id = v_patron_metrico_octosilabico_id;

		delete from public.patron_metrico_posiciones
		where patron_metrico_id = v_patron_metrico_octosilabico_id;

		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id,
			opcional,
			alternativa,
			nota
		)
		values (
			v_patron_metrico_octosilabico_id,
			1,
			v_metro_octosilabo_id,
			false,
			1,
			'Medida documentada por la definición heredada; la configuración permanece pendiente de revisión.'
		);

		if not exists (
			select 1
			from public.migracion_termino_destinos
			where termino_id = v_termino_octosilabo_id
				and configuracion_id = v_configuracion_octosilabica_id
		) then
			insert into public.migracion_termino_destinos (
				termino_id,
				tipo_operacion,
				configuracion_id,
				nota
			)
			values (
				v_termino_octosilabo_id,
				'transformar',
				v_configuracion_octosilabica_id,
				'Configuración provisional de terceto encadenado pendiente de confirmación del IP.'
			);
		end if;
	end if;

	select fuente_id
	into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
		raise exception
			'No se encontró la fuente bibliográfica Métrica española de Domínguez Caparrós (2014)';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and forma_id = v_forma_terceto_id
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
			v_forma_terceto_id,
			'p. 185',
			'Describe el terceto como una combinación de tres versos de arte mayor, normalmente endecasílabos, con rima consonante.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and forma_id = v_forma_encadenado_id
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
			v_forma_encadenado_id,
			'p. 185',
			'Documenta el encadenamiento ABA BCB CDC… y el cierre YZYZ. METADRAMA adopta actualmente este cierre conforme al criterio específico del proyecto.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and patron_rima_id = v_patron_rima_encadenado_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			patron_rima_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_patron_rima_encadenado_id,
			'p. 185',
			'La rima central de cada terceto se convierte en la rima exterior del siguiente; el proyecto formaliza el cierre como último terceto YZY más un verso Z, que completa YZYZ.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 9,
	actualizado_en = now()
where id = true;

commit;
