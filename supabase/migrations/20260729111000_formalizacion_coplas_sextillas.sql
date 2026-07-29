begin;

-- Las relaciones taxonómicas y las compositivas son distintas. La cantidad
-- permite expresar "compuesta por dos sextillas" sin convertir sextilla en
-- padre jerárquico.
alter table public.forma_relaciones
	drop constraint forma_relaciones_tipo_relacion_check;

alter table public.forma_relaciones
	add constraint forma_relaciones_tipo_relacion_check
		check (tipo_relacion in (
			'subtipo_de',
			'variante_historica_de',
			'derivada_de',
			'compuesta_por',
			'relacionada_con',
			'contrasta_con',
			'equivalente_de'
		)),
	add column cantidad_min integer null
		check (cantidad_min is null or cantidad_min > 0),
	add column cantidad_max integer null
		check (cantidad_max is null or cantidad_max > 0),
	add column orden_composicion integer null
		check (orden_composicion is null or orden_composicion > 0),
	add constraint forma_relaciones_cantidad_check
		check (
			(cantidad_min is null and cantidad_max is null)
			or (
				tipo_relacion = 'compuesta_por'
				and cantidad_min is not null
				and (cantidad_max is null or cantidad_min <= cantidad_max)
			)
		);

comment on column public.forma_relaciones.cantidad_min is
	'Número mínimo de realizaciones de la forma componente; solo se usa con compuesta_por.';
comment on column public.forma_relaciones.cantidad_max is
	'Número máximo de realizaciones de la forma componente; NULL puede indicar repetición abierta.';
comment on column public.forma_relaciones.orden_composicion is
	'Orden relativo del tipo de componente cuando una forma combina varios tipos de forma.';

do $$
declare
	v_arte_id uuid;
	v_sextilla_id uuid;
	v_doble_id uuid;
	v_manriquena_id uuid;
	v_copla_real_id uuid;
	v_quintilla_id uuid;
	v_config_arte_id uuid;
	v_config_sextilla_provisional_id uuid;
	v_config_sextilla_iso_id uuid;
	v_config_sextilla_quebrado_id uuid;
	v_config_doble_provisional_id uuid;
	v_config_doble_otro_id uuid;
	v_config_manriquena_id uuid;
	v_tipo_consonante_id uuid;
	v_metro_4_id uuid;
	v_metro_6_id uuid;
	v_metro_7_id uuid;
	v_metro_8_id uuid;
	v_metro_12_id uuid;
	v_modelo_dodecasilabo_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_grupo_id uuid;
	v_raiz_id uuid;
	v_rasgo_pie_id uuid;
	v_fuente_id uuid;
	v_esquema record;
	v_posicion integer;
	v_configuracion_id uuid;
	v_configuraciones_afectadas uuid[];
begin
	select forma_id into v_arte_id
	from public.formas_metricas where slug = 'copla_de_arte_mayor';
	select forma_id into v_sextilla_id
	from public.formas_metricas where slug = 'sextilla';
	select forma_id into v_doble_id
	from public.formas_metricas where slug = 'doble_sextilla';
	select forma_id into v_manriquena_id
	from public.formas_metricas where slug = 'copla_manriqueña';
	select forma_id into v_copla_real_id
	from public.formas_metricas where slug = 'copla_real';
	select forma_id into v_quintilla_id
	from public.formas_metricas where slug = 'quintilla';

	select configuracion_id into v_config_arte_id
	from public.configuraciones_forma
	where forma_id = v_arte_id and origen_termino_id is null
	order by principal desc, created_at limit 1;

	select configuracion_id into v_config_sextilla_iso_id
	from public.configuraciones_forma
	where origen_termino_id = 'b7426463-66e8-41af-bbd7-6106053e9b34'::uuid;
	select configuracion_id into v_config_sextilla_quebrado_id
	from public.configuraciones_forma
	where origen_termino_id = 'e0e17a64-23d8-4bfb-9b74-3fd8ea9d9938'::uuid;
	select configuracion_id into v_config_sextilla_provisional_id
	from public.configuraciones_forma
	where forma_id = v_sextilla_id and origen_termino_id is null
	order by principal desc, created_at limit 1;

	select configuracion_id into v_config_doble_otro_id
	from public.configuraciones_forma
	where origen_termino_id = 'adae111d-3883-49f7-84b0-8c52c118ca93'::uuid;
	select configuracion_id into v_config_doble_provisional_id
	from public.configuraciones_forma
	where forma_id = v_doble_id and origen_termino_id is null
	order by principal desc, created_at limit 1;

	select configuracion_id into v_config_manriquena_id
	from public.configuraciones_forma
	where forma_id = v_manriquena_id
	order by principal desc, created_at limit 1;

	select termino_id into v_tipo_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and termino_id = coalesce(
			(select tipo_rima_id from public.configuraciones_forma
			 where configuracion_id = v_config_sextilla_iso_id),
			(select tipo_rima_id from public.configuraciones_forma
			 where configuracion_id = v_config_manriquena_id)
		);

	select termino_id into v_metro_4_id
	from public.vocabularios where categoria = 'metro' and numero_silabas = 4 limit 1;
	select termino_id into v_metro_6_id
	from public.vocabularios where categoria = 'metro' and numero_silabas = 6 limit 1;
	select termino_id into v_metro_7_id
	from public.vocabularios where categoria = 'metro' and numero_silabas = 7 limit 1;
	select termino_id into v_metro_8_id
	from public.vocabularios where categoria = 'metro' and numero_silabas = 8 limit 1;
	select termino_id into v_metro_12_id
	from public.vocabularios where categoria = 'metro' and numero_silabas = 12 limit 1;

	if num_nonnulls(
		v_arte_id, v_sextilla_id, v_doble_id, v_manriquena_id,
		v_config_arte_id, v_config_sextilla_iso_id,
		v_config_sextilla_quebrado_id, v_config_doble_otro_id,
		v_config_manriquena_id, v_tipo_consonante_id,
		v_metro_4_id, v_metro_6_id, v_metro_7_id, v_metro_8_id, v_metro_12_id
	) <> 15 then
		raise exception 'La importación de coplas y sextillas está incompleta';
	end if;

	v_configuraciones_afectadas := array[
		v_config_arte_id,
		v_config_sextilla_provisional_id,
		v_config_sextilla_iso_id,
		v_config_sextilla_quebrado_id,
		v_config_doble_provisional_id,
		v_config_doble_otro_id,
		v_config_manriquena_id
	];

	delete from public.secuencias_editor_metrico
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.grupos_eleccion_metrica
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.estructuras_secciones
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.patrones_repeticion
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.patrones_rima
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.patrones_metricos
	where configuracion_id = any(v_configuraciones_afectadas);
	delete from public.configuracion_rasgos
	where configuracion_id = any(v_configuraciones_afectadas);

	if v_config_sextilla_provisional_id is not null then
		delete from public.configuraciones_forma
		where configuracion_id = v_config_sextilla_provisional_id;
	end if;
	if v_config_doble_provisional_id is not null then
		delete from public.configuraciones_forma
		where configuracion_id = v_config_doble_provisional_id;
	end if;

	update public.formas_metricas
	set nombre = 'Copla de arte mayor',
		definicion = 'Estrofa de ocho versos dodecasílabos compuestos por dos hemistiquios hexasílabos, con rima consonante distribuida en dos semiestrofas de cuatro versos. El proyecto reconoce tres esquemas de rima.',
		nivel_estructural = 'estrofa',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_arte_id;

	update public.configuraciones_forma
	set slug = 'ocho_dodecasilabos_compuestos',
		nombre = 'Ocho dodecasílabos compuestos',
		descripcion = 'Ocho versos de arte mayor, cada uno formado por dos hemistiquios de seis sílabas separados por cesura.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 8,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_arte_id;

	insert into public.modelos_verso (
		slug, nombre, metro_id, tipo, silabas_totales, tipo_cesura,
		descripcion, estado_revision, activo
	)
	values (
		'dodecasilabo_compuesto_6_6',
		'Dodecasílabo compuesto 6 + 6',
		v_metro_12_id,
		'compuesto',
		12,
		'central',
		'Verso de doce sílabas organizado en dos hemistiquios hexasílabos.',
		'revisada',
		true
	)
	on conflict (slug) do update set
		nombre = excluded.nombre,
		metro_id = excluded.metro_id,
		tipo = excluded.tipo,
		silabas_totales = excluded.silabas_totales,
		tipo_cesura = excluded.tipo_cesura,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		updated_at = now()
	returning modelo_verso_id into v_modelo_dodecasilabo_id;

	delete from public.modelo_verso_segmentos
	where modelo_verso_id = v_modelo_dodecasilabo_id;
	insert into public.modelo_verso_segmentos (
		modelo_verso_id, posicion, silabas, funcion, pausa_posterior, alternativa
	)
	values
		(v_modelo_dodecasilabo_id, 1, 6, 'primer_hemistiquio', 'cesura', 1),
		(v_modelo_dodecasilabo_id, 2, 6, 'segundo_hemistiquio', null, 1);

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_arte_id, 'Ocho dodecasílabos compuestos 6 + 6',
		'estrofa', 'secuencia_fija',
		'El modelo compuesto 6 + 6 ocupa las ocho posiciones de la estrofa.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id, posicion, modelo_verso_id
	)
	select v_patron_metrico_id, posicion, v_modelo_dodecasilabo_id
	from generate_series(1, 8) posicion;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_arte_id, 'copla_arte_mayor', 'Copla de arte mayor', 1,
		1, 1, 8, 8, 'Se divide en dos semiestrofas de cuatro versos.'
	)
	returning seccion_id into v_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max
	)
	values
		(v_config_arte_id, v_raiz_id, 'primera_semiestrofa', 'Primera semiestrofa', 1, 1, 1, 4, 4),
		(v_config_arte_id, v_raiz_id, 'segunda_semiestrofa', 'Segunda semiestrofa', 2, 1, 1, 4, 4);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, estado_revision, activo, orden
	)
	values (
		v_config_arte_id, 'esquema_rima', '¿Qué esquema de rima presenta?',
		'Elige uno de los tres esquemas reconocidos por el proyecto.',
		'rima', 'secuencia', 1, 1, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo_id;

	for v_esquema in
		select *
		from (values
			('ABBAACCA', 1, '3deb22e4-471e-49e5-a836-42818596e5f1'::uuid),
			('ABBACDCD', 2, '623a5dda-9c34-456c-b3e2-154af9373c9a'::uuid),
			('ABABCDCD', 3, '28d0874e-c851-46d3-aaca-f81b8f0f1cb2'::uuid)
		) as esquemas(esquema, orden, origen_id)
	loop
		insert into public.patrones_rima (
			configuracion_id, nombre, esquema, tipo_rima_id, ambito,
			comportamiento, fijeza, descripcion, estado_revision, origen_termino_id
		)
		values (
			v_config_arte_id, v_esquema.esquema, v_esquema.esquema,
			v_tipo_consonante_id, 'estrofa', 'secuencia_fija', 'admitido',
			'Esquema reconocido por el proyecto para la copla de arte mayor.',
			'revisada', v_esquema.origen_id
		)
		returning patron_rima_id into v_patron_rima_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, patron_rima_id, orden
		)
		values (
			v_grupo_id, lower(v_esquema.esquema), v_esquema.esquema,
			v_patron_rima_id, v_esquema.orden
		);

		insert into public.migracion_termino_destinos (
			termino_id, tipo_operacion, patron_rima_id
		)
		values (v_esquema.origen_id, 'transformar', v_patron_rima_id);
	end loop;

	update public.formas_metricas
	set nombre = 'Sextilla',
		definicion = 'Estrofa de seis versos de arte menor con rima consonante. El catálogo del proyecto distingue una configuración isométrica, en versos hexasílabos, heptasílabos u octosílabos, y una configuración de pie quebrado con patrón 8-8-4-8-8-4.',
		nivel_estructural = 'estrofa',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_sextilla_id;

	update public.configuraciones_forma
	set slug = 'isometrica',
		nombre = 'Isométrica',
		descripcion = 'Seis versos con una misma medida de seis, siete u ocho sílabas.',
		principal = true,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 6,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_sextilla_iso_id;

	update public.configuraciones_forma
	set slug = 'pie_quebrado_884884',
		nombre = 'Pie quebrado 8-8-4-8-8-4',
		descripcion = 'Dos grupos de tres versos con pie quebrado en las posiciones tercera y sexta.',
		principal = false,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 6,
		estado_revision = 'revisada',
		activo = true,
		orden = 2,
		updated_at = now()
	where configuracion_id = v_config_sextilla_quebrado_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_sextilla_iso_id, 'Una medida de arte menor',
		'estrofa', 'conjunto_permitido',
		'La misma medida ocupa las seis posiciones; el proyecto admite 6, 7 u 8 sílabas.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id, metro_id, orden
	)
	values
		(v_patron_metrico_id, v_metro_6_id, 1),
		(v_patron_metrico_id, v_metro_7_id, 2),
		(v_patron_metrico_id, v_metro_8_id, 3);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, estado_revision, activo, orden
	)
	values (
		v_config_sextilla_iso_id, 'medida_comun', '¿Qué medida tienen los versos?',
		'La respuesta se aplica a los seis versos.',
		'metro', 'secuencia', 1, 1, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, orden
	)
	values
		(v_grupo_id, 'hexasilabos', '6 sílabas', v_metro_6_id, 1),
		(v_grupo_id, 'heptasilabos', '7 sílabas', v_metro_7_id, 2),
		(v_grupo_id, 'octosilabos', '8 sílabas', v_metro_8_id, 3);

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_sextilla_quebrado_id, '8-8-4-8-8-4',
		'estrofa', 'secuencia_fija',
		'Los pies quebrados ocupan las posiciones tercera y sexta.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	for v_posicion in 1..6 loop
		insert into public.patron_metrico_posiciones (
			patron_metrico_id, posicion, metro_id
		)
		values (
			v_patron_metrico_id,
			v_posicion,
			case when v_posicion in (3, 6) then v_metro_4_id else v_metro_8_id end
		);
	end loop;

	foreach v_configuracion_id in array array[
		v_config_sextilla_iso_id,
		v_config_sextilla_quebrado_id
	] loop
		insert into public.patrones_rima (
			configuracion_id, nombre, esquema, tipo_rima_id, ambito,
			comportamiento, fijeza, descripcion, estado_revision
		)
		values (
			v_configuracion_id, 'Distribución variable', null,
			v_tipo_consonante_id, 'estrofa', 'libre', 'libre',
			'La sextilla admite distintas distribuciones de rima consonante.',
			'revisada'
		);

		insert into public.estructuras_secciones (
			configuracion_id, tipo_seccion, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max
		)
		values (
			v_configuracion_id, 'sextilla', 'Sextilla', 1,
			1, 1, 6, 6
		);
	end loop;

	insert into public.rasgos_metricos (
		slug, nombre, descripcion, tipo_valor, observabilidad,
		demarcable, estado_revision, activo
	)
	values (
		'pie_quebrado',
		'Pie quebrado',
		'Presencia normativa de versos más breves que la medida dominante en posiciones estructuralmente declaradas.',
		'booleano',
		'directa',
		true,
		'revisada',
		true
	)
	on conflict (slug) do update set
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		tipo_valor = excluded.tipo_valor,
		observabilidad = excluded.observabilidad,
		demarcable = excluded.demarcable,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		updated_at = now()
	returning rasgo_id into v_rasgo_pie_id;
	if v_rasgo_pie_id is not null then
		insert into public.configuracion_rasgos (
			configuracion_id, rasgo_id, modalidad, nota
		)
		values (
			v_config_sextilla_quebrado_id, v_rasgo_pie_id, 'definitoria',
			'Se deriva del patrón métrico 8-8-4-8-8-4.'
		)
		on conflict (configuracion_id, rasgo_id, modalidad) do update
		set nota = excluded.nota;
	end if;

	update public.formas_metricas
	set nombre = 'Doble sextilla',
		definicion = 'Estrofa de doce versos formada por dos sextillas de pie quebrado. En esta entrada se registran los esquemas regulares distintos del patrón manriqueño, que conserva identidad como forma propia.',
		nivel_estructural = 'estrofa',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_doble_id;

	update public.configuraciones_forma
	set slug = 'otro_esquema_regular',
		nombre = 'Otro esquema regular',
		descripcion = 'Dos sextillas 8-8-4-8-8-4 con un esquema regular distinto de abcabc:defdef.',
		principal = true,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 12,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_doble_otro_id;

	update public.formas_metricas
	set nombre = 'Copla manriqueña',
		definicion = 'Estrofa de doce versos formada por dos sextillas de pie quebrado. Cada sextilla sigue el patrón métrico 8-8-4-8-8-4; las rimas consonantes se distribuyen como abcabc:defdef, con clases distintas en cada sextilla.',
		nivel_estructural = 'estrofa',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_manriquena_id;

	update public.configuraciones_forma
	set slug = 'dos_sextillas_abcabc_defdef',
		nombre = 'Dos sextillas abcabc:defdef',
		descripcion = 'Dos sextillas de pie quebrado con rimas independientes.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_tipo_consonante_id,
		numero_versos = 12,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_manriquena_id;

	foreach v_configuracion_id in array array[
		v_config_doble_otro_id,
		v_config_manriquena_id
	] loop
		insert into public.patrones_metricos (
			configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
		)
		values (
			v_configuracion_id, '8-8-4-8-8-4 / 8-8-4-8-8-4',
			'estrofa', 'secuencia_fija',
			'Dos sextillas con pies quebrados en las posiciones 3, 6, 9 y 12.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;

		for v_posicion in 1..12 loop
			insert into public.patron_metrico_posiciones (
				patron_metrico_id, posicion, metro_id
			)
			values (
				v_patron_metrico_id,
				v_posicion,
				case when v_posicion in (3, 6, 9, 12) then v_metro_4_id else v_metro_8_id end
			);
		end loop;

		insert into public.estructuras_secciones (
			configuracion_id, tipo_seccion, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max, nota
		)
		values (
			v_configuracion_id, 'doble_sextilla', 'Doble sextilla', 1,
			1, 1, 12, 12, 'Unidad formada por dos sextillas sucesivas.'
		)
		returning seccion_id into v_raiz_id;

		insert into public.estructuras_secciones (
			configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max
		)
		values
			(v_configuracion_id, v_raiz_id, 'primera_sextilla', 'Primera sextilla', 1, 1, 1, 6, 6),
			(v_configuracion_id, v_raiz_id, 'segunda_sextilla', 'Segunda sextilla', 2, 1, 1, 6, 6);

		if v_rasgo_pie_id is not null then
			insert into public.configuracion_rasgos (
				configuracion_id, rasgo_id, modalidad, nota
			)
			values (
				v_configuracion_id, v_rasgo_pie_id, 'definitoria',
				'Se deriva de las posiciones métricas 3, 6, 9 y 12.'
			)
			on conflict (configuracion_id, rasgo_id, modalidad) do update
			set nota = excluded.nota;
		end if;
	end loop;

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito,
		comportamiento, fijeza, descripcion, estado_revision
	)
	values (
		v_config_doble_otro_id, 'Otro esquema regular',
		'Esquema regular distinto de abcabc:defdef',
		v_tipo_consonante_id, 'estrofa', 'restricciones', 'admitido',
		'El patrón debe ser regular y no coincidir con el patrón manriqueño.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, descripcion, obligatoria
	)
	values (
		v_patron_rima_id, 'otra', 'distinto_de_abcabc_defdef',
		'Esquema regular distinto de abcabc:defdef.', true
	);

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito,
		comportamiento, fijeza, descripcion, estado_revision
	)
	values (
		v_config_manriquena_id, 'abcabc:defdef', 'abcabc:defdef',
		v_tipo_consonante_id, 'estrofa', 'secuencia_fija', 'fijo',
		'Cada sextilla emplea tres clases de rima distintas de las de la otra.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	for v_posicion in 1..12 loop
		insert into public.patron_rima_posiciones (
			patron_rima_id, bloque, seccion, posicion, clase_rima
		)
		values (
			v_patron_rima_id,
			case when v_posicion <= 6 then 1 else 2 end,
			case when v_posicion <= 6 then 'primera_sextilla' else 'segunda_sextilla' end,
			case when v_posicion <= 6 then v_posicion else v_posicion - 6 end,
			substring('abcabcdefdef' from v_posicion for 1)
		);
	end loop;

	-- La entrada antigua no representa una forma ni una genealogía: es una
	-- caracterización transversal. Se conserva la trazabilidad hacia el rasgo.
	delete from public.migracion_termino_destinos
	where termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid;

	delete from public.familias_metricas
	where origen_termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid;

	insert into public.migracion_termino_destinos (
		termino_id, tipo_operacion, rasgo_id, nota
	)
	values (
		'352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid,
		'transformar',
		v_rasgo_pie_id,
		'La entrada agrupaba formas de longitudes y arquitecturas distintas; se normaliza como rasgo y las declaraciones antiguas requerirán revisión de forma.'
	);

	-- Relaciones taxonómicas y compositivas.
	delete from public.forma_relaciones
	where forma_origen_id in (v_doble_id, v_manriquena_id, v_copla_real_id)
		and tipo_relacion in ('subtipo_de', 'compuesta_por')
		and forma_destino_id in (v_doble_id, v_sextilla_id, v_quintilla_id);

	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion,
		cantidad_min, cantidad_max, orden_composicion, nota, estado_revision
	)
	values
		(v_manriquena_id, v_doble_id, 'subtipo_de',
		 null, null, null,
		 'La copla manriqueña es el subtipo lexicalizado de doble sextilla con esquema abcabc:defdef.',
		 'revisada'),
		(v_doble_id, v_sextilla_id, 'compuesta_por',
		 2, 2, 1,
		 'La forma se organiza en dos sextillas sucesivas de pie quebrado.',
		 'revisada'),
		(v_manriquena_id, v_sextilla_id, 'compuesta_por',
		 2, 2, 1,
		 'La forma se organiza en dos sextillas 8-8-4-8-8-4 con rimas independientes.',
		 'revisada')
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set cantidad_min = excluded.cantidad_min,
		cantidad_max = excluded.cantidad_max,
		orden_composicion = excluded.orden_composicion,
		nota = excluded.nota,
		estado_revision = excluded.estado_revision,
		updated_at = now();

	if v_copla_real_id is not null and v_quintilla_id is not null then
		insert into public.forma_relaciones (
			forma_origen_id, forma_destino_id, tipo_relacion,
			cantidad_min, cantidad_max, orden_composicion, nota, estado_revision
		)
		values (
			v_copla_real_id, v_quintilla_id, 'compuesta_por',
			2, 2, 1,
			'La copla real se organiza como dos quintillas separadas por la pausa 5 + 5.',
			'revisada'
		)
		on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
		set cantidad_min = excluded.cantidad_min,
			cantidad_max = excluded.cantidad_max,
			orden_composicion = excluded.orden_composicion,
			nota = excluded.nota,
			estado_revision = excluded.estado_revision,
			updated_at = now();
	end if;

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where titulo = 'Métrica española'
		and autoria = 'José Domínguez Caparrós'
	order by created_at
	limit 1;

	if v_fuente_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, cita, nota
		)
		values (
			'monografia',
			'José Domínguez Caparrós',
			'Métrica española',
			2014,
			'UNED',
			'Domínguez Caparrós, José. Métrica española. Madrid: UNED, 2014.',
			'Fuente bibliográfica local del proyecto.'
		)
		returning fuente_id into v_fuente_id;
	end if;

	delete from public.afirmaciones_fuentes_metricas
	where fuente_id = v_fuente_id
		and (
			forma_id in (v_arte_id, v_sextilla_id, v_doble_id, v_manriquena_id)
			or rasgo_id = v_rasgo_pie_id
		);

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_fuente_id, v_sextilla_id, 'pp. 196-198',
		 'Define la sextilla como estrofa de seis versos de arte menor con rima consonante y documenta distintas distribuciones.',
		 'alta', 'revisada'),
		(v_fuente_id, v_manriquena_id, 'pp. 196-197',
		 'Describe la estrofa manriqueña 8a 8b 4c 8a 8b 4c y señala que puede considerarse unidad de doce versos cuando el sentido enlaza dos sextillas, cuyas rimas siguen siendo distintas.',
		 'alta', 'revisada'),
		(v_fuente_id, v_arte_id, 'pp. 200-201',
		 'Caracteriza la copla de arte mayor como ocho versos de Juan de Mena distribuidos en dos cuartetos enlazados.',
		 'alta', 'revisada');

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, rasgo_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_id, v_rasgo_pie_id, 'pp. 196-197',
		'Documenta la combinación de octosílabos y tetrasílabos y su organización posicional en la estrofa manriqueña.',
		'alta', 'revisada'
	);

	update public.migracion_terminos_metricos
	set clasificacion_decidida = case
			when termino_id in (
				'15105265-5a6a-41ea-afbc-2d4f32d2014b'::uuid,
				'b2de4d5a-1174-4d0c-9d13-a2a4206a0e09'::uuid,
				'd221e829-07ed-48b4-aabe-33a5278e0a7c'::uuid,
				'33220456-8402-41b3-9789-da2417690f52'::uuid
			) then 'F'
			when termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid then 'R'
			when termino_id in (
				'e0e17a64-23d8-4bfb-9b74-3fd8ea9d9938'::uuid,
				'b7426463-66e8-41af-bbd7-6106053e9b34'::uuid,
				'adae111d-3883-49f7-84b0-8c52c118ca93'::uuid
			) then 'C'
			else 'P'
		end,
		certeza = 'alta',
		updated_at = now()
	where termino_id in (
		'15105265-5a6a-41ea-afbc-2d4f32d2014b'::uuid,
		'3deb22e4-471e-49e5-a836-42818596e5f1'::uuid,
		'623a5dda-9c34-456c-b3e2-154af9373c9a'::uuid,
		'28d0874e-c851-46d3-aaca-f81b8f0f1cb2'::uuid,
		'352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid,
		'b2de4d5a-1174-4d0c-9d13-a2a4206a0e09'::uuid,
		'e0e17a64-23d8-4bfb-9b74-3fd8ea9d9938'::uuid,
		'b7426463-66e8-41af-bbd7-6106053e9b34'::uuid,
		'd221e829-07ed-48b4-aabe-33a5278e0a7c'::uuid,
		'33220456-8402-41b3-9789-da2417690f52'::uuid,
		'adae111d-3883-49f7-84b0-8c52c118ca93'::uuid
	);
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 22,
	actualizado_en = now()
where id = true;

commit;
