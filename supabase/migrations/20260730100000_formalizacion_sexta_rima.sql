begin;

do $$
declare
	v_termino_id uuid := 'df645af0-0ab3-43f1-b357-b58793d39c2b'::uuid;
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'sexta_rima';

	if v_forma_id is null or v_forma_id <> v_termino_id then
		raise exception 'No se encontró la forma sexta_rima con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para sexta rima y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

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

	if v_metro_11_id is null or v_consonante_id is null then
		raise exception 'Falta el metro endecasílabo o el tipo de rima consonante';
	end if;

	update public.formas_metricas
	set
		nombre = 'Sexta rima',
		definicion = 'Estrofa de seis versos endecasílabos con rima consonante ABABCC: los cuatro primeros alternan dos rimas y los dos últimos forman un pareado.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'endecasilabica_consonante',
		nombre = 'Endecasilábica consonante',
		descripcion = 'Unidad fija de seis endecasílabos consonantes con esquema ABABCC.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 6,
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
			'Se esperaba un patrón métrico importado para sexta rima y se encontraron %',
			v_total;
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	update public.patrones_metricos
	set
		nombre = 'Seis endecasílabos',
		ambito = 'estrofa',
		tipo = 'secuencia_fija',
		descripcion = 'Un verso endecasílabo en cada una de las seis posiciones.',
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
	select
		v_patron_metrico_id,
		posicion,
		v_metro_11_id,
		false,
		1,
		'Posición endecasilábica fija de la sexta rima.'
	from generate_series(1, 6) as posiciones(posicion);

	select count(*) into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un patrón de rima importado para sexta rima y se encontraron %',
			v_total;
	end if;

	select patron_rima_id into v_patron_rima_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	update public.patrones_rima
	set
		nombre = 'Esquema fijo ABABCC',
		esquema = 'ABABCC',
		tipo_rima_id = v_consonante_id,
		ambito = 'estrofa',
		comportamiento = 'secuencia_fija',
		fijeza = 'fijo',
		descripcion = 'Alternancia ABAB seguida de un pareado final CC.',
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
	select
		v_patron_rima_id,
		case when posicion <= 4 then 1 else 2 end,
		case when posicion <= 4 then 'alternancia' else 'pareado_final' end,
		posicion,
		'final',
		substring('ABABCC' from posicion for 1),
		false,
		false,
		case
			when posicion <= 4 then 'Posición de la alternancia ABAB.'
			else 'Posición del pareado final CC.'
		end
	from generate_series(1, 6) as posiciones(posicion);

	select count(*) into v_total
	from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'La sexta rima tiene % grupos editoriales no previstos; deben revisarse antes de formalizarla',
			v_total;
	end if;

	select count(*) into v_total
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'La sexta rima tiene % secciones no previstas; deben revisarse antes de formalizarla',
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

	update public.afirmaciones_fuentes_metricas
	set
		localizador = 'p. 199',
		resumen = 'Define la sexta rima como un sexteto de seis endecasílabos con esquema consonante ABABCC.',
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
			'p. 199',
			'Define la sexta rima como un sexteto de seis endecasílabos con esquema consonante ABABCC.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma fija de seis endecasílabos consonantes ABABCC.',
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
	modelo_version = 35,
	actualizado_en = now()
where id = true;

commit;
