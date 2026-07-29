begin;

-- Los nombres tradicionales no siempre designan formas. La tabla anterior solo
-- permitía alias de forma y obligaba a elevar realizaciones como «Cuarteta» al
-- nivel equivocado. Se conserva su contenido y se amplían los destinos posibles.
alter table public.forma_aliases
	rename to denominaciones_metricas;

alter table public.denominaciones_metricas
	alter column forma_id drop not null,
	add column configuracion_id uuid null
		references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	add column patron_metrico_id uuid null
		references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete cascade,
	add column patron_rima_id uuid null
		references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	add column seccion_id uuid null
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete cascade,
	add column patron_repeticion_id uuid null
		references public.patrones_repeticion (patron_repeticion_id)
		on update cascade on delete cascade,
	add column fuente_id uuid null
		references public.fuentes_metricas (fuente_id)
		on update cascade on delete set null,
	add constraint denominaciones_metricas_destino_check
		check (
			num_nonnulls(
				forma_id,
				configuracion_id,
				patron_metrico_id,
				patron_rima_id,
				seccion_id,
				patron_repeticion_id
			) = 1
		);

create unique index denominaciones_metricas_configuracion_slug_idx
	on public.denominaciones_metricas (configuracion_id, slug_normalizado)
	where configuracion_id is not null;

create unique index denominaciones_metricas_patron_metrico_slug_idx
	on public.denominaciones_metricas (patron_metrico_id, slug_normalizado)
	where patron_metrico_id is not null;

create unique index denominaciones_metricas_patron_rima_slug_idx
	on public.denominaciones_metricas (patron_rima_id, slug_normalizado)
	where patron_rima_id is not null;

create unique index denominaciones_metricas_seccion_slug_idx
	on public.denominaciones_metricas (seccion_id, slug_normalizado)
	where seccion_id is not null;

create unique index denominaciones_metricas_repeticion_slug_idx
	on public.denominaciones_metricas (patron_repeticion_id, slug_normalizado)
	where patron_repeticion_id is not null;

comment on table public.denominaciones_metricas is
	'Nombres equivalentes, históricos, gráficos o abreviados asociados exactamente a una forma, configuración, patrón o sección. No crean entidades seleccionables nuevas.';

comment on column public.denominaciones_metricas.forma_id is
	'Forma designada, solo cuando el nombre alternativo corresponde a la identidad completa.';

comment on column public.denominaciones_metricas.patron_rima_id is
	'Patrón designado, por ejemplo «Cuarteta» para la realización cruzada abab de redondilla.';

-- La trazabilidad inicial ya admitía patrones de rima, pero no patrones
-- métricos. Se añade el destino para no convertir las variantes de 6 y 7
-- sílabas en configuraciones artificiales.
alter table public.migracion_termino_destinos
	add column patron_metrico_id uuid null
		references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete cascade;

do $$
declare
	v_constraint text;
begin
	for v_constraint in
		select constraint_record.conname
		from pg_constraint constraint_record
		where constraint_record.conrelid = 'public.migracion_termino_destinos'::regclass
			and constraint_record.contype = 'c'
			and pg_get_constraintdef(constraint_record.oid) like '%num_nonnulls%'
	loop
		execute format(
			'alter table public.migracion_termino_destinos drop constraint %I',
			v_constraint
		);
	end loop;
end;
$$;

alter table public.migracion_termino_destinos
	add constraint migracion_termino_destinos_un_destino_check
	check (
		tipo_operacion = 'retirar'
		or num_nonnulls(
			forma_id,
			familia_id,
			configuracion_id,
			patron_metrico_id,
			patron_rima_id,
			rasgo_id,
			valor_rasgo_id,
			alias_id
		) = 1
	);

do $$
declare
	v_termino_raiz_id uuid := '1affe499-c92d-4cf0-a0f6-46c76a26f88f'::uuid;
	v_termino_regular_id uuid := '1525ae6c-8052-446c-af93-3042341cf610'::uuid;
	v_termino_cruzada_id uuid := 'e42244af-caae-416e-9d5e-49e6c8b7af21'::uuid;
	v_termino_hexasilaba_id uuid := '7f1bcbaf-834e-4c6f-8190-2547a066a6df'::uuid;
	v_termino_heptasilaba_id uuid := '105e6394-6d90-481a-8f49-9b1b214cb35b'::uuid;
	v_termino_doble_id uuid := 'e8e11481-6af2-4830-a9cf-a13a0e2221b2'::uuid;
	v_forma_id uuid;
	v_forma_cruzada_id uuid;
	v_forma_doble_id uuid;
	v_config_simple_id uuid;
	v_config_heptasilaba_id uuid;
	v_config_hexasilaba_id uuid;
	v_config_cruzada_id uuid;
	v_config_doble_id uuid;
	v_patron_metrico_8_id uuid;
	v_patron_metrico_7_id uuid;
	v_patron_metrico_6_id uuid;
	v_patron_metrico_doble_id uuid;
	v_patron_abrazado_id uuid;
	v_patron_cruzado_id uuid;
	v_patron_doble_id uuid;
	v_metro_6_id uuid;
	v_metro_7_id uuid;
	v_metro_8_id uuid;
	v_consonante_id uuid;
	v_seccion_simple_id uuid;
	v_seccion_doble_id uuid;
	v_grupo_metro_id uuid;
	v_grupo_rima_id uuid;
	v_fuente_diccionario_id uuid;
	v_fuente_devoto_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_metro_id uuid;
	v_extension integer;
	v_nombre text;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'redondilla';

	select forma_id into v_forma_cruzada_id
	from public.formas_metricas
	where slug = 'redondilla_cruzada';

	select forma_id into v_forma_doble_id
	from public.formas_metricas
	where slug = 'redondilla_doble';

	if num_nonnulls(v_forma_id, v_forma_cruzada_id, v_forma_doble_id) <> 3 then
		raise exception
			'No se encontraron las tres formas provisionales del bloque de redondilla';
	end if;

	select configuracion_id into v_config_simple_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'octosilabica_abba';

	select configuracion_id into v_config_heptasilaba_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'heptasilabica_abba';

	select configuracion_id into v_config_hexasilaba_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'hexasilabica_abba';

	select configuracion_id into v_config_cruzada_id
	from public.configuraciones_forma
	where forma_id = v_forma_cruzada_id
	limit 1;

	select configuracion_id into v_config_doble_id
	from public.configuraciones_forma
	where forma_id = v_forma_doble_id
	limit 1;

	if num_nonnulls(
		v_config_simple_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cruzada_id,
		v_config_doble_id
	) <> 5 then
		raise exception
			'No se encontraron las configuraciones provisionales de redondilla';
	end if;

	select patron_metrico_id into v_patron_metrico_8_id
	from public.patrones_metricos
	where configuracion_id = v_config_simple_id
	limit 1;

	select patron_metrico_id into v_patron_metrico_7_id
	from public.patrones_metricos
	where configuracion_id = v_config_heptasilaba_id
	limit 1;

	select patron_metrico_id into v_patron_metrico_6_id
	from public.patrones_metricos
	where configuracion_id = v_config_hexasilaba_id
	limit 1;

	select patron_metrico_id into v_patron_metrico_doble_id
	from public.patrones_metricos
	where configuracion_id = v_config_doble_id
	limit 1;

	select patron_rima_id into v_patron_abrazado_id
	from public.patrones_rima
	where configuracion_id = v_config_simple_id
	limit 1;

	select patron_rima_id into v_patron_cruzado_id
	from public.patrones_rima
	where configuracion_id = v_config_cruzada_id
	limit 1;

	select patron_rima_id into v_patron_doble_id
	from public.patrones_rima
	where configuracion_id = v_config_doble_id
	limit 1;

	if num_nonnulls(
		v_patron_metrico_8_id,
		v_patron_metrico_7_id,
		v_patron_metrico_6_id,
		v_patron_metrico_doble_id,
		v_patron_abrazado_id,
		v_patron_cruzado_id,
		v_patron_doble_id
	) <> 7 then
		raise exception
			'Faltan patrones provisionales necesarios para consolidar la redondilla';
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

	if num_nonnulls(v_metro_6_id, v_metro_7_id, v_metro_8_id, v_consonante_id) <> 4 then
		raise exception 'Faltan los metros de 6, 7 u 8 sílabas o la rima consonante';
	end if;

	-- Las pruebas del editor V2 no son anotaciones de obras. Se eliminan antes
	-- de sustituir sus configuraciones y secciones.
	delete from public.secuencias_editor_metrico
	where configuracion_id in (
		v_config_simple_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cruzada_id,
		v_config_doble_id
	);

	-- Las opciones referencian patrones y secciones con borrado restringido.
	delete from public.grupos_eleccion_metrica
	where configuracion_id in (
		v_config_simple_id,
		v_config_heptasilaba_id,
		v_config_hexasilaba_id,
		v_config_cruzada_id,
		v_config_doble_id
	);

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_raiz_id,
		v_termino_regular_id,
		v_termino_cruzada_id,
		v_termino_hexasilaba_id,
		v_termino_heptasilaba_id,
		v_termino_doble_id
	);

	delete from public.afirmaciones_fuentes_metricas
	where forma_id in (v_forma_cruzada_id, v_forma_doble_id);

	delete from public.familias_metricas
	where slug = 'redondillas';

	-- Estas dos filas eran una separación provisional. Sus UUID de
	-- configuración y patrón se reutilizan más abajo bajo la forma correcta.
	delete from public.formas_metricas
	where forma_id in (v_forma_cruzada_id, v_forma_doble_id);

	delete from public.configuraciones_forma
	where configuracion_id in (v_config_heptasilaba_id, v_config_hexasilaba_id);

	delete from public.estructuras_secciones
	where configuracion_id = v_config_simple_id;

	delete from public.patrones_repeticion
	where configuracion_id = v_config_simple_id;

	delete from public.patrones_rima
	where configuracion_id = v_config_simple_id;

	delete from public.patrones_metricos
	where configuracion_id = v_config_simple_id;

	update public.formas_metricas
	set
		nombre = 'Redondilla',
		definicion = 'Estrofa de cuatro versos de arte menor con rima consonante distribuida en dos clases. La disposición puede ser abrazada (abba) o cruzada (abab), también denominada cuarteta. El catálogo reconoce realizaciones de seis, siete y ocho sílabas y la configuración doble enlazada.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		origen_termino_id = v_termino_raiz_id,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'simple',
		nombre = 'De cuatro versos',
		descripcion = 'Unidad de cuatro versos consonantes. El editor registra la medida y si la disposición de las dos rimas es abrazada (abba) o cruzada (abab).',
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
	where configuracion_id = v_config_simple_id;

	insert into public.configuraciones_forma (
		configuracion_id,
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
		orden,
		origen_termino_id
	)
	values (
		v_config_doble_id,
		v_forma_id,
		'doble_enlazada',
		'Doble enlazada',
		'Ocho versos organizados como dos redondillas abrazadas que comparten la rima exterior: abba:acca.',
		false,
		true,
		'fija',
		v_consonante_id,
		8,
		'revisada',
		true,
		2,
		v_termino_doble_id
	);

	for
		v_configuracion_id,
		v_patron_metrico_id,
		v_metro_id,
		v_extension,
		v_nombre
	in
		select *
		from (
			values
				(v_config_simple_id, v_patron_metrico_8_id, v_metro_8_id, 4, 'Cuatro octosílabos'),
				(v_config_simple_id, v_patron_metrico_7_id, v_metro_7_id, 4, 'Cuatro heptasílabos'),
				(v_config_simple_id, v_patron_metrico_6_id, v_metro_6_id, 4, 'Cuatro hexasílabos'),
				(v_config_doble_id, v_patron_metrico_doble_id, v_metro_8_id, 8, 'Ocho octosílabos')
		) as patrones(
			configuracion_id,
			patron_metrico_id,
			metro_id,
			extension,
			nombre
		)
	loop
		insert into public.patrones_metricos (
			patron_metrico_id,
			configuracion_id,
			nombre,
			ambito,
			tipo,
			descripcion,
			estado_revision
		)
		values (
			v_patron_metrico_id,
			v_configuracion_id,
			v_nombre,
			'estrofa',
			'secuencia_fija',
			format('La misma medida se aplica a las %s posiciones de la unidad.', v_extension),
			'revisada'
		);

		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id
		)
		select v_patron_metrico_id, posicion, v_metro_id
		from generate_series(1, v_extension) posicion;
	end loop;

	insert into public.patrones_rima (
		patron_rima_id,
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
	values
		(
			v_patron_abrazado_id,
			v_config_simple_id,
			'Abrazada',
			'abba',
			v_consonante_id,
			'estrofa',
			'secuencia_fija',
			'admitido',
			'Dos rimas consonantes dispuestas de forma abrazada.',
			'revisada'
		),
		(
			v_patron_cruzado_id,
			v_config_simple_id,
			'Cruzada',
			'abab',
			v_consonante_id,
			'estrofa',
			'secuencia_fija',
			'admitido',
			'Dos rimas consonantes dispuestas de forma cruzada. Esta realización recibe también la denominación «Cuarteta».',
			'revisada'
		),
		(
			v_patron_doble_id,
			v_config_doble_id,
			'Doble enlazada',
			'abbaacca',
			v_consonante_id,
			'estrofa',
			'secuencia_fija',
			'fijo',
			'Dos redondillas abrazadas enlazadas mediante la clase exterior a.',
			'revisada'
		);

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
	where patron_rima_id = v_patron_doble_id;

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
			v_patron_doble_id,
			1,
			1,
			'final',
			1,
			2,
			4,
			'final',
			'misma_rima',
			true,
			'La rima exterior de la primera redondilla reaparece al final de la segunda.'
		),
		(
			v_patron_doble_id,
			1,
			4,
			'final',
			1,
			2,
			1,
			'final',
			'misma_rima',
			true,
			'El cierre de la primera redondilla enlaza con el inicio de la segunda.'
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
		v_config_simple_id,
		'redondilla',
		'Redondilla',
		1,
		1,
		null,
		4,
		4,
		'Unidad repetible de cuatro versos; una tirada se descompone automáticamente en redondillas.'
	)
	returning seccion_id into v_seccion_simple_id;

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
		v_config_doble_id,
		'redondilla_doble',
		'Redondilla doble',
		1,
		1,
		null,
		8,
		8,
		v_patron_metrico_doble_id,
		v_patron_doble_id,
		'Unidad repetible de ocho versos. Sus dos bloques internos de cuatro se derivan de las posiciones del patrón abba:acca.'
	)
	returning seccion_id into v_seccion_doble_id;

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		seccion_id,
		selecciones_min,
		selecciones_max,
		permite_aplicar_global,
		estado_revision,
		activo,
		orden
	)
	values (
		v_config_simple_id,
		'medida_redondilla',
		'¿Qué medida tienen los versos?',
		'Elige la medida de esta redondilla. Puedes aplicarla al resto de la tirada y cambiar solo las excepciones.',
		'metro',
		'unidad',
		v_seccion_simple_id,
		1,
		1,
		true,
		'revisada',
		true,
		1
	)
	returning grupo_eleccion_id into v_grupo_metro_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		patron_metrico_id,
		activo,
		orden
	)
	values
		(v_grupo_metro_id, 'octosilaba', '8 sílabas', v_patron_metrico_8_id, true, 1),
		(v_grupo_metro_id, 'heptasilaba', '7 sílabas', v_patron_metrico_7_id, true, 2),
		(v_grupo_metro_id, 'hexasilaba', '6 sílabas', v_patron_metrico_6_id, true, 3);

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		seccion_id,
		selecciones_min,
		selecciones_max,
		permite_aplicar_global,
		estado_revision,
		activo,
		orden
	)
	values (
		v_config_simple_id,
		'disposicion_rima',
		'¿Cómo se distribuyen las dos rimas?',
		'Elige la disposición de esta redondilla. «Cuarteta» es la denominación equivalente de la cruzada.',
		'rima',
		'unidad',
		v_seccion_simple_id,
		1,
		1,
		true,
		'revisada',
		true,
		2
	)
	returning grupo_eleccion_id into v_grupo_rima_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		patron_rima_id,
		activo,
		orden
	)
	values
		(v_grupo_rima_id, 'abrazada', 'Abrazada · abba', v_patron_abrazado_id, true, 1),
		(v_grupo_rima_id, 'cruzada', 'Cruzada · abab (cuarteta)', v_patron_cruzado_id, true, 2);

	insert into public.denominaciones_metricas (
		patron_rima_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		idioma,
		preferente
	)
	values (
		v_patron_cruzado_id,
		'Cuarteta',
		'cuarteta',
		'equivalente',
		'es',
		false
	);

	select fuente_id into v_fuente_diccionario_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Diccionario de métrica española'
	limit 1;

	select fuente_id into v_fuente_devoto_id
	from public.fuentes_metricas
	where autoria = 'Daniel Devoto'
		and titulo = 'De la redondilla y su familia'
	limit 1;

	if v_fuente_diccionario_id is not null then
		update public.denominaciones_metricas
		set fuente_id = v_fuente_diccionario_id
		where patron_rima_id = v_patron_cruzado_id
			and slug_normalizado = 'cuarteta';

		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			patron_rima_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_diccionario_id,
			v_patron_cruzado_id,
			'Voz «cuarteta»',
			'Documenta la denominación cuarteta para la disposición cruzada abab; el proyecto la registra como nombre equivalente de esta realización de redondilla.',
			'alta',
			'revisada'
		);
	end if;

	if v_fuente_devoto_id is not null then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			configuracion_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_devoto_id,
			v_config_doble_id,
			'pp. 478-479',
			'Documenta la fórmula ABBAACCA de ocho octosílabos; el proyecto la formaliza como configuración doble de redondilla.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case migracion.termino_id
			when v_termino_raiz_id then 'F'
			when v_termino_regular_id then 'C'
			when v_termino_cruzada_id then 'P'
			when v_termino_doble_id then 'C'
			else 'P'
		end,
		propuesta = case migracion.termino_id
			when v_termino_raiz_id
				then 'Conservar como forma redondilla con configuraciones simple y doble enlazada.'
			when v_termino_regular_id
				then 'Transformar en la configuración simple de cuatro versos.'
			when v_termino_cruzada_id
				then 'Transformar en el patrón de rima cruzada abab; cuarteta queda como denominación equivalente.'
			when v_termino_doble_id
				then 'Transformar en la configuración doble enlazada abba:acca.'
			when v_termino_heptasilaba_id
				then 'Transformar en el patrón métrico admitido de cuatro heptasílabos.'
			else
				'Transformar en el patrón métrico admitido de cuatro hexasílabos y conservar la corrección del metro legado.'
		end,
		certeza = 'alta',
		requiere_revision = false
	where migracion.termino_id in (
		v_termino_raiz_id,
		v_termino_regular_id,
		v_termino_cruzada_id,
		v_termino_hexasilaba_id,
		v_termino_heptasilaba_id,
		v_termino_doble_id
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values (
		v_termino_raiz_id,
		'conservar',
		v_forma_id,
		'La antigua raíz jerárquica aporta la identidad de la forma única Redondilla.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		configuracion_id,
		nota
	)
	values
		(
			v_termino_regular_id,
			'transformar',
			v_config_simple_id,
			'La antigua redondilla regular pasa a ser la configuración simple.'
		),
		(
			v_termino_doble_id,
			'transformar',
			v_config_doble_id,
			'La antigua forma doble pasa a ser una configuración estructural de redondilla.'
		);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		patron_rima_id,
		nota
	)
	values (
		v_termino_cruzada_id,
		'transformar',
		v_patron_cruzado_id,
		'La antigua redondilla cruzada pasa a ser el patrón abab; Cuarteta es su denominación equivalente.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		patron_metrico_id,
		nota
	)
	values
		(
			v_termino_heptasilaba_id,
			'transformar',
			v_patron_metrico_7_id,
			'La antigua subforma heptasílaba pasa a ser un patrón métrico admitido.'
		),
		(
			v_termino_hexasilaba_id,
			'transformar',
			v_patron_metrico_6_id,
			'La antigua subforma hexasílaba pasa a ser un patrón métrico admitido.'
		);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 30,
	actualizado_en = now()
where id = true;

commit;
