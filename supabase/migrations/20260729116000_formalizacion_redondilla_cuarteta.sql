begin;

do $$
declare
	v_termino_redondilla_id uuid := '1affe499-c92d-4cf0-a0f6-46c76a26f88f'::uuid;
	v_termino_regular_id uuid := '1525ae6c-8052-446c-af93-3042341cf610'::uuid;
	v_termino_cruzada_id uuid := 'e42244af-caae-416e-9d5e-49e6c8b7af21'::uuid;
	v_termino_hexasilaba_id uuid := '7f1bcbaf-834e-4c6f-8190-2547a066a6df'::uuid;
	v_termino_heptasilaba_id uuid := '105e6394-6d90-481a-8f49-9b1b214cb35b'::uuid;
	v_termino_doble_id uuid := 'e8e11481-6af2-4830-a9cf-a13a0e2221b2'::uuid;
	v_forma_redondilla_id uuid;
	v_forma_cuarteta_id uuid;
	v_forma_doble_id uuid;
	v_config_octosilaba_id uuid;
	v_config_hexasilaba_id uuid;
	v_config_heptasilaba_id uuid;
	v_config_cuarteta_id uuid;
	v_config_doble_id uuid;
	v_metro_6_id uuid;
	v_metro_7_id uuid;
	v_metro_8_id uuid;
	v_consonante_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_configuracion_id uuid;
	v_metro_id uuid;
	v_numero_versos integer;
	v_esquema text;
	v_nombre_metro text;
	v_fuente_diccionario_id uuid;
	v_fuente_devoto_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_redondilla_id
	from public.formas_metricas
	where slug = 'redondilla';

	select forma_id into v_forma_doble_id
	from public.formas_metricas
	where slug = 'redondilla_doble_abbaacca';

	if v_forma_redondilla_id is null or v_forma_doble_id is null then
		raise exception
			'No se encontraron la redondilla y la redondilla doble importadas';
	end if;

	select termino_id into v_metro_6_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 6
		and activo
	limit 1;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 7
		and activo
	limit 1;

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 8
		and activo
	limit 1;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and termino = 'consonante'
		and activo
	limit 1;

	if num_nonnulls(
		v_metro_6_id,
		v_metro_7_id,
		v_metro_8_id,
		v_consonante_id
	) <> 4 then
		raise exception
			'Falta algún metro de 6, 7 u 8 sílabas o la rima consonante';
	end if;

	-- La relación métrica legada contradice el nombre y la definición del IP.
	delete from public.estrofa_tipo_metros
	where estrofa_tipo_id = v_termino_hexasilaba_id;

	insert into public.estrofa_tipo_metros (estrofa_tipo_id, metro_id)
	values (v_termino_hexasilaba_id, v_metro_6_id)
	on conflict do nothing;

	select configuracion_id into v_config_octosilaba_id
	from public.configuraciones_forma
	where forma_id = v_forma_redondilla_id
		and origen_termino_id is null
	order by principal desc, created_at
	limit 1;

	select configuracion_id into v_config_hexasilaba_id
	from public.configuraciones_forma
	where forma_id = v_forma_redondilla_id
		and origen_termino_id = v_termino_hexasilaba_id;

	select configuracion_id into v_config_heptasilaba_id
	from public.configuraciones_forma
	where forma_id = v_forma_redondilla_id
		and origen_termino_id = v_termino_heptasilaba_id;

	select configuracion_id into v_config_doble_id
	from public.configuraciones_forma
	where forma_id = v_forma_doble_id
	order by principal desc, created_at
	limit 1;

	if num_nonnulls(
		v_config_octosilaba_id,
		v_config_hexasilaba_id,
		v_config_heptasilaba_id,
		v_config_doble_id
	) <> 4 then
		raise exception
			'La importación de las configuraciones de redondilla está incompleta';
	end if;

	delete from public.migracion_termino_destinos
	where termino_id = v_termino_regular_id;

	delete from public.forma_aliases
	where origen_termino_id = v_termino_regular_id;

	update public.configuraciones_forma
	set principal = false
	where forma_id = v_forma_redondilla_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabica_abba',
		nombre = 'Octosilábica abba',
		descripcion = 'Cuatro versos octosílabos con rima consonante abrazada abba.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_consonante_id,
		numero_versos = 4,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		origen_termino_id = v_termino_regular_id,
		updated_at = now()
	where configuracion_id = v_config_octosilaba_id;

	update public.configuraciones_forma
	set
		slug = 'heptasilabica_abba',
		nombre = 'Heptasilábica abba',
		descripcion = 'Cuatro versos heptasílabos con rima consonante abrazada abba.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = 4,
		estado_revision = 'revisada',
		activo = true,
		orden = 2,
		updated_at = now()
	where configuracion_id = v_config_heptasilaba_id;

	update public.configuraciones_forma
	set
		slug = 'hexasilabica_abba',
		nombre = 'Hexasílaba abba',
		descripcion = 'Cuatro versos hexasílabos con rima consonante abrazada abba.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = 4,
		estado_revision = 'revisada',
		activo = true,
		orden = 3,
		updated_at = now()
	where configuracion_id = v_config_hexasilaba_id;

	update public.formas_metricas
	set
		nombre = 'Redondilla',
		definicion = 'Estrofa de cuatro versos de arte menor con dos rimas consonantes abrazadas según el esquema abba. El catálogo del proyecto reconoce configuraciones octosilábica, heptasilábica y hexasilábica.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_redondilla_id;

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
		orden,
		origen_termino_id
	)
	values (
		v_termino_cruzada_id,
		'cuarteta',
		'Cuarteta',
		'Estrofa de cuatro versos octosílabos con dos rimas consonantes alternas según el esquema abab. El catálogo usa esta denominación para distinguirla con claridad de la redondilla abba, aunque la terminología histórica no siempre mantuvo esa separación.',
		'estrofa',
		true,
		false,
		'revisada',
		true,
		21,
		v_termino_cruzada_id
	)
	on conflict (forma_id) do update
	set
		slug = excluded.slug,
		nombre = excluded.nombre,
		definicion = excluded.definicion,
		nivel_estructural = excluded.nivel_estructural,
		seleccionable = excluded.seleccionable,
		residual = excluded.residual,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		orden = excluded.orden,
		origen_termino_id = excluded.origen_termino_id,
		updated_at = now()
	returning forma_id into v_forma_cuarteta_id;

	insert into public.forma_aliases (
		forma_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		preferente
	)
	values (
		v_forma_cuarteta_id,
		'Redondilla cruzada',
		'redondilla_cruzada',
		'historico',
		false
	)
	on conflict (forma_id, slug_normalizado) do update
	set
		nombre = excluded.nombre,
		tipo_alias = excluded.tipo_alias,
		preferente = excluded.preferente,
		updated_at = now();

	select configuracion_id into v_config_cuarteta_id
	from public.configuraciones_forma
	where forma_id = v_forma_cuarteta_id
	limit 1;

	if v_config_cuarteta_id is null then
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
			v_forma_cuarteta_id,
			'octosilabica_abab',
			'Octosilábica abab',
			'Cuatro versos octosílabos con rima consonante alterna abab.',
			true,
			true,
			'fija',
			v_consonante_id,
			4,
			'revisada',
			true,
			1
		)
		returning configuracion_id into v_config_cuarteta_id;
	else
		update public.configuraciones_forma
		set
			slug = 'octosilabica_abab',
			nombre = 'Octosilábica abab',
			descripcion = 'Cuatro versos octosílabos con rima consonante alterna abab.',
			principal = true,
			demarcable = true,
			grado = 'fija',
			tipo_rima_id = v_consonante_id,
			numero_versos = 4,
			estado_revision = 'revisada',
			activo = true,
			orden = 1,
			updated_at = now()
		where configuracion_id = v_config_cuarteta_id;
	end if;

	update public.formas_metricas
	set
		slug = 'redondilla_doble',
		nombre = 'Redondilla doble',
		definicion = 'Estrofa de ocho versos octosílabos con rima consonante abbaacca, organizada como dos redondillas que comparten la rima exterior a.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_doble_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabica_abbaacca',
		nombre = 'Octosilábica abbaacca',
		descripcion = 'Ocho octosílabos consonantes organizados como abba:acca.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 8,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_doble_id;

	delete from public.secuencias_editor_metrico
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	delete from public.grupos_eleccion_metrica
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	delete from public.estructuras_secciones
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	delete from public.patrones_repeticion
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	delete from public.patrones_rima
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	delete from public.patrones_metricos
	where configuracion_id in (
		v_config_octosilaba_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cuarteta_id,
		v_config_doble_id
	);

	for
		v_configuracion_id,
		v_metro_id,
		v_numero_versos,
		v_esquema,
		v_nombre_metro
	in
		select *
		from (
			values
				(v_config_octosilaba_id, v_metro_8_id, 4, 'abba', 'Cuatro octosílabos'),
				(v_config_heptasilaba_id, v_metro_7_id, 4, 'abba', 'Cuatro heptasílabos'),
				(v_config_hexasilaba_id, v_metro_6_id, 4, 'abba', 'Cuatro hexasílabos'),
				(v_config_cuarteta_id, v_metro_8_id, 4, 'abab', 'Cuatro octosílabos'),
				(v_config_doble_id, v_metro_8_id, 8, 'abbaacca', 'Ocho octosílabos')
		) as configuraciones(
			configuracion_id,
			metro_id,
			numero_versos,
			esquema,
			nombre_metro
		)
	loop
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
			v_nombre_metro,
			'estrofa',
			'secuencia_fija',
			format(
				'La misma medida se aplica a las %s posiciones de la estrofa.',
				v_numero_versos
			),
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;

		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id
		)
		select v_patron_metrico_id, posicion, v_metro_id
		from generate_series(1, v_numero_versos) posicion;

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
			'Esquema fijo ' || v_esquema,
			v_esquema,
			v_consonante_id,
			'estrofa',
			'secuencia_fija',
			'fijo',
			case
				when v_esquema = 'abba' then 'Dos rimas consonantes abrazadas.'
				when v_esquema = 'abab' then 'Dos rimas consonantes alternas.'
				else 'Dos redondillas enlazadas por la rima exterior a: abba:acca.'
			end,
			'revisada'
		)
		returning patron_rima_id into v_patron_rima_id;

		if v_esquema = 'abbaacca' then
			update public.patron_rima_posiciones
			set
				bloque = case when posicion <= 4 then 1 else 2 end,
				seccion = case
					when posicion <= 4 then 'primera_redondilla'
					else 'segunda_redondilla'
				end,
				posicion = case
					when posicion <= 4 then posicion
					else posicion - 4
				end
			where patron_rima_id = v_patron_rima_id;
		end if;
	end loop;

	delete from public.forma_relaciones
	where forma_origen_id = v_forma_doble_id
		and forma_destino_id = v_forma_redondilla_id
		and tipo_relacion = 'subtipo_de';

	insert into public.forma_relaciones (
		forma_origen_id,
		forma_destino_id,
		tipo_relacion,
		cantidad_min,
		cantidad_max,
		orden_composicion,
		nota,
		estado_revision
	)
	values (
		v_forma_doble_id,
		v_forma_redondilla_id,
		'compuesta_por',
		2,
		2,
		1,
		'Dos redondillas octosilábicas sucesivas enlazadas por la rima exterior compartida a; la relación es compositiva, no taxonómica.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set
		cantidad_min = excluded.cantidad_min,
		cantidad_max = excluded.cantidad_max,
		orden_composicion = excluded.orden_composicion,
		nota = excluded.nota,
		estado_revision = excluded.estado_revision;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case termino.termino
			when 'redondilla' then 'F'
			when 'redondilla_regular' then 'C'
			when 'redondilla_cruzada' then 'F'
			when 'redondilla_doble_abbaacca' then 'F'
			else 'C'
		end,
		propuesta = case termino.termino
			when 'redondilla'
				then 'Conservar como forma abba con configuraciones de 8, 7 y 6 sílabas.'
			when 'redondilla_regular'
				then 'Transformar en la configuración octosilábica principal de redondilla.'
			when 'redondilla_cruzada'
				then 'Transformar en la forma canónica cuarteta, con alias histórico redondilla cruzada.'
			when 'redondilla_doble_abbaacca'
				then 'Conservar como forma redondilla doble, compuesta por dos redondillas octosilábicas.'
			when 'redondilla_heptasilaba'
				then 'Transformar en configuración heptasilábica de redondilla.'
			else
				'Transformar en configuración hexasilábica de redondilla y corregir su metro legado de 7 a 6.'
		end,
		certeza = 'alta',
		requiere_revision = termino.termino in (
			'redondilla',
			'redondilla_cruzada',
			'redondilla_doble_abbaacca'
		)
	from public.vocabularios termino
	where migracion.termino_id = termino.termino_id
		and termino.termino in (
			'redondilla',
			'redondilla_regular',
			'redondilla_cruzada',
			'redondilla_doble_abbaacca',
			'redondilla_heptasilaba',
			'redondilla_hexasilaba'
		);

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_regular_id,
		v_termino_cruzada_id
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		configuracion_id,
		nota
	)
	values (
		v_termino_regular_id,
		'transformar',
		v_config_octosilaba_id,
		'La antigua subforma regular pasa a ser la configuración octosilábica principal.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values (
		v_termino_cruzada_id,
		'transformar',
		v_forma_cuarteta_id,
		'La antigua redondilla cruzada se conserva trazada como la forma cuarteta.'
	);

	select fuente_id into v_fuente_diccionario_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Diccionario de métrica española'
	limit 1;

	if v_fuente_diccionario_id is null then
		insert into public.fuentes_metricas (
			tipo,
			autoria,
			titulo,
			anio,
			publicacion,
			url,
			cita,
			nota
		)
		values (
			'diccionario especializado',
			'José Domínguez Caparrós',
			'Diccionario de métrica española',
			2016,
			'Madrid, Alianza Editorial, 3.ª ed.',
			'https://www.alianzaeditorial.es/primer_capitulo/diccionario-de-metrica-espanola.pdf',
			'Domínguez Caparrós, José. Diccionario de métrica española. 3.ª ed. Madrid: Alianza Editorial, 2016.',
			'Obra terminológica especializada; primera edición de 1999.'
		)
		returning fuente_id into v_fuente_diccionario_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_diccionario_id
			and forma_id = v_forma_redondilla_id
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
			v_fuente_diccionario_id,
			v_forma_redondilla_id,
			'Voz «redondilla»',
			'Sustenta la identificación terminológica moderna de la redondilla como estrofa de arte menor y rima abrazada abba, sin borrar la amplitud de los usos históricos del término.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_diccionario_id
			and forma_id = v_forma_cuarteta_id
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
			v_fuente_diccionario_id,
			v_forma_cuarteta_id,
			'Voz «cuarteta»',
			'Sustenta el uso de cuarteta para la estrofa de cuatro versos de arte menor con disposición alterna abab.',
			'alta',
			'revisada'
		);
	end if;

	select fuente_id into v_fuente_devoto_id
	from public.fuentes_metricas
	where autoria = 'Daniel Devoto'
		and titulo = 'De la redondilla y su familia'
	limit 1;

	if v_fuente_devoto_id is null then
		insert into public.fuentes_metricas (
			tipo,
			autoria,
			titulo,
			anio,
			publicacion,
			url,
			cita,
			nota
		)
		values (
			'artículo',
			'Daniel Devoto',
			'De la redondilla y su familia',
			1983,
			'Boletín de la Real Academia Española, 63, pp. 475-482',
			'https://webfrl.rae.es/BRAE_DB_PDF/TOMO_LXIII/CCXXX/Devoto_475_482.pdf',
			'Devoto, Daniel. «De la redondilla y su familia». Boletín de la Real Academia Española, 63 (1983), pp. 475-482.',
			'Estudio histórico de la amplitud terminológica y formal de la redondilla.'
		)
		returning fuente_id into v_fuente_devoto_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_devoto_id
			and forma_id = v_forma_doble_id
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
			v_fuente_devoto_id,
			v_forma_doble_id,
			'pp. 478-479',
			'Documenta como redondilla de ocho octosílabos la fórmula ABBAACCA y advierte que Navarro Tomás la cataloga entre las octavas; confirma el patrón, pero deja abierta su delimitación terminológica.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 27,
	actualizado_en = now()
where id = true;

commit;
