begin;

do $$
declare
	v_termino_id uuid := '187be9a5-f24c-4fde-a4dd-591e9e742c39'::uuid;
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_7_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'lira';

	if v_forma_id is null or v_forma_id <> v_termino_id then
		raise exception 'No se encontró la forma lira con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para lira y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'heptasilabo'
		and numero_silabas = 7;

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

	if v_metro_7_id is null
		or v_metro_11_id is null
		or v_consonante_id is null
	then
		raise exception
			'Falta el metro heptasílabo, el endecasílabo o el tipo de rima consonante';
	end if;

	update public.formas_metricas
	set
		nombre = 'Lira',
		definicion = 'Estrofa de cinco versos, tres heptasílabos y dos endecasílabos, con rima consonante aBabB y patrón métrico 7-11-7-7-11. También recibe los nombres de lira garcilasiana y estrofa de fray Luis de León.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'heptasilabica_endecasilabica_consonante',
		nombre = 'Heptasilábica y endecasilábica consonante',
		descripcion = 'Configuración fija de cinco versos: 7a 11B 7a 7b 11B.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 5,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_configuracion_id;

	select count(*) into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un patrón métrico importado para lira y se encontraron %',
			v_total;
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	update public.patrones_metricos
	set
		nombre = 'Esquema fijo 7-11-7-7-11',
		ambito = 'estrofa',
		tipo = 'secuencia_fija',
		descripcion = 'Heptasílabos en las posiciones 1, 3 y 4; endecasílabos en las posiciones 2 y 5.',
		estado_revision = 'revisada',
		updated_at = now()
	where patron_metrico_id = v_patron_metrico_id;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_id;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_id;

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
		(v_patron_metrico_id, 2, v_metro_11_id, false, 1, 'Primer endecasílabo.'),
		(v_patron_metrico_id, 3, v_metro_7_id, false, 1, 'Segundo heptasílabo.'),
		(v_patron_metrico_id, 4, v_metro_7_id, false, 1, 'Tercer heptasílabo.'),
		(v_patron_metrico_id, 5, v_metro_11_id, false, 1, 'Segundo endecasílabo.');

	select count(*) into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un patrón de rima importado para lira y se encontraron %',
			v_total;
	end if;

	select patron_rima_id into v_patron_rima_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	update public.patrones_rima
	set
		nombre = 'Esquema fijo aBabB',
		esquema = 'aBabB',
		tipo_rima_id = v_consonante_id,
		ambito = 'estrofa',
		comportamiento = 'secuencia_fija',
		fijeza = 'fijo',
		descripcion = 'Dos clases de rima consonante: a en los versos 1 y 3; b en los versos 2, 4 y 5.',
		estado_revision = 'revisada',
		updated_at = now()
	where patron_rima_id = v_patron_rima_id;

	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_rima_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_rima_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_id;

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
		(v_patron_rima_id, 1, null, 1, 'final', 'a', false, false, 'Rima a.'),
		(v_patron_rima_id, 1, null, 2, 'final', 'b', false, false, 'Rima b; el verso es endecasílabo.'),
		(v_patron_rima_id, 1, null, 3, 'final', 'a', false, false, 'Rima a.'),
		(v_patron_rima_id, 1, null, 4, 'final', 'b', false, false, 'Rima b.'),
		(v_patron_rima_id, 1, null, 5, 'final', 'b', false, false, 'Rima b; el verso es endecasílabo.');

	select count(*) into v_total
	from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'La lira tiene % grupos editoriales no previstos; deben revisarse antes de formalizarla',
			v_total;
	end if;

	select count(*) into v_total
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'La lira tiene % secciones no previstas; deben revisarse antes de formalizarla',
			v_total;
	end if;

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

	insert into public.denominaciones_metricas (
		forma_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		fuente_id
	)
	values
		(
			v_forma_id,
			'Lira garcilasiana',
			'lira_garcilasiana',
			'equivalente',
			v_fuente_id
		),
		(
			v_forma_id,
			'Estrofa de fray Luis de León',
			'estrofa_de_fray_luis_de_leon',
			'historico',
			v_fuente_id
		)
	on conflict (forma_id, slug_normalizado) do update
	set
		nombre = excluded.nombre,
		tipo_alias = excluded.tipo_alias,
		fuente_id = excluded.fuente_id,
		updated_at = now();

	update public.afirmaciones_fuentes_metricas
	set
		localizador = 'p. 195',
		resumen = 'Define la lira, lira garcilasiana o estrofa de fray Luis de León como cinco versos heptasílabos y endecasílabos con rima consonante 7A 11B 7A 7B 11B.',
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
			'p. 195',
			'Define la lira, lira garcilasiana o estrofa de fray Luis de León como cinco versos heptasílabos y endecasílabos con rima consonante 7A 11B 7A 7B 11B.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma fija de cinco versos con patrón 7a 11B 7a 7b 11B.',
		certeza = 'alta',
		requiere_revision = false
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
		'La entrada anterior ya correspondía a la forma; sus patrones pasan a posiciones normalizadas.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 33,
	actualizado_en = now()
where id = true;

commit;
