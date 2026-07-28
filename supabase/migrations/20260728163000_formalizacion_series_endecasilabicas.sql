begin;

do $$
declare
	v_forma_suelto_id uuid;
	v_forma_silva_id uuid;
	v_forma_pareado_id uuid;
	v_forma_pareados_id uuid;
	v_config_general_suelto_id uuid;
	v_config_silva_endeca_id uuid;
	v_config_pareados_id uuid;
	v_patron_silva_endeca_id uuid;
	v_patron_pareados_metrico_id uuid;
	v_patron_pareados_rima_id uuid;
	v_familia_pareados_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_termino_pareado_endeca_id uuid;
	v_fuente_dominguez_id uuid;
	v_config record;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_suelto_id
	from public.formas_metricas where slug = 'endecasilabo_suelto';

	select forma_id into v_forma_silva_id
	from public.formas_metricas where slug = 'silva';

	select forma_id into v_forma_pareado_id
	from public.formas_metricas where slug = 'pareado';

	if v_forma_suelto_id is null or v_forma_silva_id is null or v_forma_pareado_id is null then
		raise exception
			'No se encontraron endecasilabo_suelto, silva o pareado en el catálogo métrico';
	end if;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	select termino_id into v_termino_pareado_endeca_id
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'pareado_endecasilabo';

	if v_metro_11_id is null or v_consonante_id is null or v_termino_pareado_endeca_id is null then
		raise exception
			'Falta el metro endecasílabo, la rima consonante o el término pareado_endecasilabo';
	end if;

	-- El pareado es una unidad de dos versos. La antigua entrada
	-- pareado_endecasilabo describe, en cambio, una serie abierta de dísticos.
	update public.formas_metricas
	set
		nombre = 'Pareado',
		definicion = 'Estrofa de dos versos, de igual o diferente medida, unidos por rima consonante o asonante.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_pareado_id;

	select forma_id into v_forma_pareados_id
	from public.formas_metricas
	where slug = 'pareados_endecasilabos';

	if v_forma_pareados_id is null then
		insert into public.formas_metricas (
			forma_id,
			slug,
			nombre,
			definicion,
			nivel_estructural,
			seleccionable,
			residual,
			estado_revision,
			activo,
			origen_termino_id
		)
		values (
			v_termino_pareado_endeca_id,
			'pareados_endecasilabos',
			'Pareados endecasílabos',
			'Serie métrica abierta de versos endecasílabos organizada sistemáticamente en pareados de rima consonante. Los versos sueltos o las consonancias aisladas no caracterizan el cuerpo de la serie.',
			'serie',
			true,
			false,
			'revisada',
			true,
			v_termino_pareado_endeca_id
		)
		returning forma_id into v_forma_pareados_id;
	else
		update public.formas_metricas
		set
			nombre = 'Pareados endecasílabos',
			definicion = 'Serie métrica abierta de versos endecasílabos organizada sistemáticamente en pareados de rima consonante. Los versos sueltos o las consonancias aisladas no caracterizan el cuerpo de la serie.',
			nivel_estructural = 'serie',
			seleccionable = true,
			residual = false,
			estado_revision = 'revisada',
			activo = true,
			origen_termino_id = v_termino_pareado_endeca_id
		where forma_id = v_forma_pareados_id;
	end if;

	select configuracion_id into v_config_pareados_id
	from public.configuraciones_forma
	where origen_termino_id = v_termino_pareado_endeca_id;

	if v_config_pareados_id is null then
		raise exception 'No se encontró la configuración importada de pareado_endecasilabo';
	end if;

	update public.configuraciones_forma
	set
		forma_id = v_forma_pareados_id,
		slug = 'endecasilabicos_consonantes',
		nombre = 'Serie de pareados endecasílabos consonantes',
		descripcion = 'Serie abierta de endecasílabos cuya organización normativa consiste en dísticos sucesivos de rima consonante.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_config_pareados_id;

	select patron_metrico_id into v_patron_pareados_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_config_pareados_id
	limit 1;

	if v_patron_pareados_metrico_id is null then
		insert into public.patrones_metricos (
			configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
		)
		values (
			v_config_pareados_id,
			'Endecasílabo repetido',
			'serie',
			'secuencia_repetible',
			'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_pareados_metrico_id;
	else
		update public.patrones_metricos
		set
			nombre = 'Endecasílabo repetido',
			ambito = 'serie',
			tipo = 'secuencia_repetible',
			descripcion = 'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
			estado_revision = 'revisada'
		where patron_metrico_id = v_patron_pareados_metrico_id;
	end if;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_pareados_metrico_id;
	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_pareados_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id, posicion, metro_id, opcional, alternativa, nota
	)
	values (
		v_patron_pareados_metrico_id,
		1,
		v_metro_11_id,
		false,
		1,
		'El endecasílabo se repite durante toda la serie.'
	);

	select patron_rima_id into v_patron_pareados_rima_id
	from public.patrones_rima
	where configuracion_id = v_config_pareados_id
	limit 1;

	if v_patron_pareados_rima_id is null then
		insert into public.patrones_rima (
			configuracion_id, nombre, esquema, tipo_rima_id, ambito,
			comportamiento, fijeza, descripcion, estado_revision
		)
		values (
			v_config_pareados_id,
			'Pareados consonantes sistemáticos',
			'AA | BB | CC | …',
			v_consonante_id,
			'serie',
			'secuencia_repetible',
			'fijo',
			'Cada bloque de dos endecasílabos comparte rima consonante y la clase de rima se renueva en el bloque siguiente.',
			'revisada'
		)
		returning patron_rima_id into v_patron_pareados_rima_id;
	else
		update public.patrones_rima
		set
			nombre = 'Pareados consonantes sistemáticos',
			esquema = 'AA | BB | CC | …',
			tipo_rima_id = v_consonante_id,
			ambito = 'serie',
			comportamiento = 'secuencia_repetible',
			fijeza = 'fijo',
			descripcion = 'Cada bloque de dos endecasílabos comparte rima consonante y la clase de rima se renueva en el bloque siguiente.',
			estado_revision = 'revisada'
		where patron_rima_id = v_patron_pareados_rima_id;
	end if;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_pareados_rima_id;
	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_pareados_rima_id;
	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_pareados_rima_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id, bloque, seccion, posicion, ubicacion,
		clase_rima, suelto, opcional, nota
	)
	values
		(v_patron_pareados_rima_id, 1, 'pareado', 1, 'final', 'A', false, false, 'Primer verso del pareado.'),
		(v_patron_pareados_rima_id, 1, 'pareado', 2, 'final', 'A', false, false, 'Segundo verso del pareado.');

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, descripcion, obligatoria
	)
	values
		(v_patron_pareados_rima_id, 'otra', 'predominio_versos_rimados', 'Predominan los versos rimados.', true),
		(v_patron_pareados_rima_id, 'otra', 'pareados_sistematicos', 'La serie está organizada sistemáticamente en pareados.', true),
		(v_patron_pareados_rima_id, 'versos_sueltos', 'no_caracteristicos', 'Los versos sueltos no caracterizan el cuerpo de la serie.', true);

	delete from public.estructuras_secciones
	where configuracion_id = v_config_pareados_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, patron_rima_id, nota
	)
	values (
		v_config_pareados_id,
		'pareado',
		'Serie de pareados',
		1,
		1,
		null,
		2,
		2,
		v_patron_pareados_metrico_id,
		v_patron_pareados_rima_id,
		'Cada unidad repetida está formada por dos endecasílabos con la misma rima consonante.'
	);

	insert into public.familias_metricas (
		slug, nombre, descripcion, estado_revision, activo
	)
	values (
		'pareados',
		'Pareados',
		'Familia que relaciona la unidad estrófica de dos versos con las series construidas mediante su repetición.',
		'revisada',
		true
	)
	on conflict (slug) do update
	set
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo
	returning familia_id into v_familia_pareados_id;

	insert into public.familias_formas (
		familia_id, forma_id, es_principal, orden, nota
	)
	values
		(v_familia_pareados_id, v_forma_pareado_id, true, 1, 'Unidad estrófica básica de dos versos.'),
		(v_familia_pareados_id, v_forma_pareados_id, false, 2, 'Serie abierta construida mediante pareados endecasílabos.')
	on conflict (familia_id, forma_id) do update
	set
		es_principal = excluded.es_principal,
		orden = excluded.orden,
		nota = excluded.nota;

	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
	)
	values (
		v_forma_pareados_id,
		v_forma_pareado_id,
		'relacionada_con',
		'La serie repite unidades de pareado, pero no es una configuración de la estrofa porque pertenece a otro nivel estructural.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set nota = excluded.nota, estado_revision = excluded.estado_revision;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma de serie abierta de pareados endecasílabos, distinta de la estrofa pareado.',
		certeza = 'alta',
		requiere_revision = true
	where termino_id = v_termino_pareado_endeca_id;

	update public.migracion_termino_destinos
	set
		tipo_operacion = 'conservar',
		forma_id = v_forma_pareados_id,
		familia_id = null,
		configuracion_id = null,
		patron_rima_id = null,
		rasgo_id = null,
		valor_rasgo_id = null,
		alias_id = null,
		nota = 'La entrada heredada pasa a una forma de nivel serie; la configuración única conserva además origen_termino_id.'
	where termino_id = v_termino_pareado_endeca_id;

	-- Endecasílabo suelto: la configuración general importada era redundante y
	-- se elimina. Sus cinco realizaciones heredadas quedan como configuraciones
	-- coordinadas.
	update public.formas_metricas
	set
		nombre = 'Endecasílabo suelto',
		definicion = 'Serie métrica abierta de versos endecasílabos en la que predominan los versos sueltos y las rimas son minoritarias. Puede presentar pareados intercalados y, según la configuración, un dístico final; una modalidad encadena la rima final de cada verso con el interior del siguiente.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_suelto_id;

	select configuracion_id into v_config_general_suelto_id
	from public.configuraciones_forma
	where forma_id = v_forma_suelto_id
		and origen_termino_id is null;

	if v_config_general_suelto_id is null then
		raise exception 'No se encontró la configuración general importada de endecasilabo_suelto';
	end if;

	delete from public.configuraciones_forma
	where configuracion_id = v_config_general_suelto_id;

	update public.configuraciones_forma configuracion
	set
		slug = case termino.termino
			when 'endecasilabo_suelto_con_pareados' then 'con_pareados_y_distico_final'
			when 'endecasilabo_suelto_con_pareados_y_sin_distico_final' then 'con_pareados_sin_distico_final'
			when 'endecasilabo_suelto_encadenado' then 'encadenado_interior'
			when 'endecasilabo_suelto_puro' then 'puro_con_distico_final'
			when 'endecasilabo_suelto_puro_sin_distico_final' then 'puro_sin_distico_final'
		end,
		nombre = case termino.termino
			when 'endecasilabo_suelto_con_pareados' then 'Con pareados y dístico final'
			when 'endecasilabo_suelto_con_pareados_y_sin_distico_final' then 'Con pareados y sin dístico final'
			when 'endecasilabo_suelto_encadenado' then 'Encadenado interior'
			when 'endecasilabo_suelto_puro' then 'Puro con dístico final'
			when 'endecasilabo_suelto_puro_sin_distico_final' then 'Puro sin dístico final'
		end,
		descripcion = case termino.termino
			when 'endecasilabo_suelto_con_pareados' then 'Serie de endecasílabos predominantemente sueltos con pareados intercalados de forma ocasional y un dístico final.'
			when 'endecasilabo_suelto_con_pareados_y_sin_distico_final' then 'Serie de endecasílabos predominantemente sueltos con pareados intercalados de forma ocasional y sin dístico final.'
			when 'endecasilabo_suelto_encadenado' then 'Serie de endecasílabos predominantemente sueltos en la que la rima final de un verso enlaza con una posición interior del verso siguiente.'
			when 'endecasilabo_suelto_puro' then 'Serie de endecasílabos sin pareados intercalados y con un dístico final.'
			when 'endecasilabo_suelto_puro_sin_distico_final' then 'Serie de endecasílabos sin pareados intercalados ni dístico final.'
		end,
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = null,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true
	from public.vocabularios termino
	where configuracion.origen_termino_id = termino.termino_id
		and configuracion.forma_id = v_forma_suelto_id
		and termino.termino in (
			'endecasilabo_suelto_con_pareados',
			'endecasilabo_suelto_con_pareados_y_sin_distico_final',
			'endecasilabo_suelto_encadenado',
			'endecasilabo_suelto_puro',
			'endecasilabo_suelto_puro_sin_distico_final'
		);

	select count(*) into v_total
	from public.configuraciones_forma configuracion
	join public.vocabularios termino
		on termino.termino_id = configuracion.origen_termino_id
	where configuracion.forma_id = v_forma_suelto_id
		and termino.termino in (
			'endecasilabo_suelto_con_pareados',
			'endecasilabo_suelto_con_pareados_y_sin_distico_final',
			'endecasilabo_suelto_encadenado',
			'endecasilabo_suelto_puro',
			'endecasilabo_suelto_puro_sin_distico_final'
		);

	if v_total <> 5 then
		raise exception 'Se esperaban cinco configuraciones específicas de endecasílabo suelto y se encontraron %', v_total;
	end if;

	for v_config in
		select configuracion.configuracion_id, termino.termino
		from public.configuraciones_forma configuracion
		join public.vocabularios termino
			on termino.termino_id = configuracion.origen_termino_id
		where configuracion.forma_id = v_forma_suelto_id
			and termino.termino in (
				'endecasilabo_suelto_con_pareados',
				'endecasilabo_suelto_con_pareados_y_sin_distico_final',
				'endecasilabo_suelto_encadenado',
				'endecasilabo_suelto_puro',
				'endecasilabo_suelto_puro_sin_distico_final'
			)
	loop
		select patron_metrico_id into v_patron_metrico_id
		from public.patrones_metricos
		where configuracion_id = v_config.configuracion_id
		limit 1;

		if v_patron_metrico_id is null then
			insert into public.patrones_metricos (
				configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
			)
			values (
				v_config.configuracion_id,
				'Endecasílabo repetido',
				'serie',
				'secuencia_repetible',
				'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
				'revisada'
			)
			returning patron_metrico_id into v_patron_metrico_id;
		else
			update public.patrones_metricos
			set
				nombre = 'Endecasílabo repetido',
				ambito = 'serie',
				tipo = 'secuencia_repetible',
				descripcion = 'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
				estado_revision = 'revisada'
			where patron_metrico_id = v_patron_metrico_id;
		end if;

		delete from public.patron_metrico_opciones
		where patron_metrico_id = v_patron_metrico_id;
		delete from public.patron_metrico_posiciones
		where patron_metrico_id = v_patron_metrico_id;

		insert into public.patron_metrico_posiciones (
			patron_metrico_id, posicion, metro_id, opcional, alternativa, nota
		)
		values (
			v_patron_metrico_id,
			1,
			v_metro_11_id,
			false,
			1,
			'El endecasílabo se repite durante toda la serie.'
		);

		select patron_rima_id into v_patron_rima_id
		from public.patrones_rima
		where configuracion_id = v_config.configuracion_id
		limit 1;

		if v_patron_rima_id is null then
			insert into public.patrones_rima (
				configuracion_id, nombre, esquema, tipo_rima_id, ambito,
				comportamiento, fijeza, descripcion, estado_revision
			)
			values (
				v_config.configuracion_id,
				'Predominio de versos sueltos',
				null,
				null,
				'serie',
				'restricciones',
				'preferente',
				'La ausencia de rima regular organiza la serie; las consonancias son minoritarias.',
				'revisada'
			)
			returning patron_rima_id into v_patron_rima_id;
		else
			update public.patrones_rima
			set
				nombre = case
					when v_config.termino = 'endecasilabo_suelto_encadenado'
						then 'Predominio de versos sueltos con encadenamiento interior'
					else 'Predominio de versos sueltos'
				end,
				esquema = null,
				tipo_rima_id = null,
				ambito = 'serie',
				comportamiento = 'restricciones',
				fijeza = 'preferente',
				descripcion = case
					when v_config.termino = 'endecasilabo_suelto_encadenado'
						then 'Predominan los versos sueltos y la rima final de cada verso puede enlazar con el interior del siguiente.'
					else 'La ausencia de rima regular organiza la serie; las consonancias son minoritarias.'
				end,
				estado_revision = 'revisada'
			where patron_rima_id = v_patron_rima_id;
		end if;

		delete from public.patron_rima_posiciones
		where patron_rima_id = v_patron_rima_id;
		delete from public.patron_rima_enlaces
		where patron_rima_id = v_patron_rima_id;
		delete from public.patron_rima_restricciones
		where patron_rima_id = v_patron_rima_id;

		insert into public.patron_rima_restricciones (
			patron_rima_id, tipo, valor_texto, descripcion, obligatoria
		)
		values
			(v_patron_rima_id, 'otra', 'predominio_versos_sueltos', 'Predominan los versos sueltos.', true),
			(v_patron_rima_id, 'otra', 'rima_minoritaria', 'Las rimas son minoritarias en el conjunto de la serie.', true),
			(v_patron_rima_id, 'otra', 'pareados_no_sistematicos', 'La serie no se organiza sistemáticamente en pareados.', true);

		if v_config.termino in (
			'endecasilabo_suelto_con_pareados',
			'endecasilabo_suelto_con_pareados_y_sin_distico_final'
		) then
			insert into public.patron_rima_restricciones (
				patron_rima_id, tipo, valor_texto, descripcion, obligatoria
			)
			values (
				v_patron_rima_id,
				'otra',
				'pareados_intercalados_ocasionales',
				'Puede presentar pareados intercalados, pero no organizan sistemáticamente la serie.',
				true
			);
		elsif v_config.termino in (
			'endecasilabo_suelto_puro',
			'endecasilabo_suelto_puro_sin_distico_final'
		) then
			insert into public.patron_rima_restricciones (
				patron_rima_id, tipo, valor_texto, descripcion, obligatoria
			)
			values (
				v_patron_rima_id,
				'otra',
				'sin_pareados_intercalados',
				'No presenta pareados intercalados.',
				true
			);
		else
			insert into public.patron_rima_restricciones (
				patron_rima_id, tipo, valor_texto, descripcion, obligatoria
			)
			values (
				v_patron_rima_id,
				'otra',
				'encadenamiento_final_interior',
				'La rima final de un verso enlaza con una posición interior del siguiente.',
				true
			);
		end if;

		if v_config.termino in (
			'endecasilabo_suelto_con_pareados',
			'endecasilabo_suelto_puro'
		) then
			insert into public.patron_rima_restricciones (
				patron_rima_id, tipo, valor_texto, descripcion, obligatoria
			)
			values (
				v_patron_rima_id,
				'otra',
				'distico_final',
				'La serie concluye con un dístico rimado.',
				true
			);
		elsif v_config.termino in (
			'endecasilabo_suelto_con_pareados_y_sin_distico_final',
			'endecasilabo_suelto_puro_sin_distico_final'
		) then
			insert into public.patron_rima_restricciones (
				patron_rima_id, tipo, valor_texto, descripcion, obligatoria
			)
			values (
				v_patron_rima_id,
				'otra',
				'sin_distico_final',
				'La serie no concluye con un dístico rimado.',
				true
			);
		end if;

		delete from public.estructuras_secciones
		where configuracion_id = v_config.configuracion_id;
	end loop;

	-- La silva endecasílaba ocupa la franja intermedia: predominan los versos
	-- rimados y los pareados son habituales, pero no sistemáticos.
	select configuracion.configuracion_id, patron.patron_rima_id
	into v_config_silva_endeca_id, v_patron_silva_endeca_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	join public.patrones_rima patron on patron.configuracion_id = configuracion.configuracion_id
	where forma.slug = 'silva'
		and configuracion.slug = 'endecasilabica'
	limit 1;

	if v_config_silva_endeca_id is null or v_patron_silva_endeca_id is null then
		raise exception 'No se encontró la configuración formalizada silva--endecasilabica';
	end if;

	update public.configuraciones_forma
	set descripcion = 'Serie abierta exclusivamente endecasilábica en la que predominan los versos con rima consonante. Los pareados son habituales, pero no organizan sistemáticamente toda la serie, que puede incluir versos sueltos.'
	where configuracion_id = v_config_silva_endeca_id;

	update public.patrones_rima
	set
		nombre = 'Predominio de rima consonante con pareados no sistemáticos',
		descripcion = 'Predominan los endecasílabos rimados y los pareados son habituales, pero no organizan sistemáticamente toda la serie; se admiten versos sueltos.'
	where patron_rima_id = v_patron_silva_endeca_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_silva_endeca_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, descripcion, obligatoria
	)
	values
		(v_patron_silva_endeca_id, 'otra', 'predominio_versos_rimados', 'Predominan los versos rimados.', true),
		(v_patron_silva_endeca_id, 'otra', 'pareados_no_sistematicos', 'La serie no se organiza sistemáticamente en pareados.', true),
		(v_patron_silva_endeca_id, 'otra', 'pareados_habituales', 'Los pareados son habituales, aunque no obligatorios.', true),
		(v_patron_silva_endeca_id, 'versos_sueltos', 'admitidos', 'Puede contener versos sueltos.', true);

	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
	)
	values
		(v_forma_suelto_id, v_forma_silva_id, 'contrasta_con', 'En el endecasílabo suelto predominan los versos sin rima; en la silva endecasílaba predominan los rimados.', 'revisada'),
		(v_forma_silva_id, v_forma_pareados_id, 'contrasta_con', 'La silva puede contener pareados habituales, pero la serie de pareados se organiza sistemáticamente mediante ellos.', 'revisada'),
		(v_forma_suelto_id, v_forma_pareados_id, 'contrasta_con', 'Contraste entre predominio de versos sueltos y organización sistemática en pareados.', 'revisada')
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set nota = excluded.nota, estado_revision = excluded.estado_revision;

	select fuente_id into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
		raise exception 'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id and forma_id = v_forma_pareado_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, forma_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_forma_pareado_id,
			'p. 184',
			'Define el pareado o dístico como combinación de dos versos, de igual o diferente medida, que riman en consonante o asonante.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id and forma_id = v_forma_suelto_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, forma_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_dominguez_id,
			v_forma_suelto_id,
			'pp. 232-233',
			'Describe el verso suelto, libre o blanco como una serie sin rima y señala como realización más frecuente la serie de endecasílabos solos o con algún heptasílabo. El catálogo conserva el alcance específico definido por el IP para el corpus.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 12,
	actualizado_en = now()
where id = true;

commit;
