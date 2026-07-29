begin;

do $$
declare
	v_termino_raiz_id uuid := 'd07d21de-bef3-40f3-9573-ce5ac4639651'::uuid;
	v_termino_regular_id uuid := 'e51c9fea-b5e1-4942-9407-230a559a31bf'::uuid;
	v_termino_esdrujulos_id uuid := '12a4847e-01f0-4dfb-a13a-b6a92f8c96d5'::uuid;
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_rasgo_final_id uuid;
	v_valor_esdrujulo_id uuid;
	v_grupo_id uuid;
	v_alias_regular_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'octava_real';

	if v_forma_id is null or v_forma_id <> v_termino_raiz_id then
		raise exception 'No se encontró la forma importada octava_real con su UUID legado';
	end if;

	select count(*)
	into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para octava real y se encontraron %',
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
		nombre = 'Octava real',
		definicion = 'Estrofa de ocho versos endecasílabos con rima consonante ABABABCC: los seis primeros alternan dos rimas y los dos últimos forman un pareado. También recibe los nombres de octava rima y octava heroica.',
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
		descripcion = 'Unidad fija de ocho endecasílabos consonantes con esquema ABABABCC.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 8,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_configuracion_id;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un patrón métrico importado para octava real y se encontraron %',
			v_total;
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	update public.patrones_metricos
	set
		nombre = 'Ocho endecasílabos',
		ambito = 'estrofa',
		tipo = 'secuencia_fija',
		descripcion = 'Un verso endecasílabo en cada una de las ocho posiciones.',
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
		'Posición endecasilábica fija de la octava real.'
	from generate_series(1, 8) as posiciones(posicion);

	select count(*)
	into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba un patrón de rima importado para octava real y se encontraron %',
			v_total;
	end if;

	select patron_rima_id into v_patron_rima_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	update public.patrones_rima
	set
		nombre = 'Esquema fijo ABABABCC',
		esquema = 'ABABABCC',
		tipo_rima_id = v_consonante_id,
		ambito = 'estrofa',
		comportamiento = 'secuencia_fija',
		fijeza = 'fijo',
		descripcion = 'Tres pares alternos AB y un pareado final CC.',
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
		case when posicion <= 6 then 1 else 2 end,
		case when posicion <= 6 then 'alternancia' else 'pareado_final' end,
		posicion,
		'final',
		substring('ABABABCC' from posicion for 1),
		false,
		false,
		case
			when posicion <= 6 then 'Posición de la alternancia AB.'
			else 'Posición del pareado final CC.'
		end
	from generate_series(1, 8) as posiciones(posicion);

	select rasgo_id into v_rasgo_final_id
	from public.rasgos_metricos
	where slug = 'final_acentual';

	select valor_id into v_valor_esdrujulo_id
	from public.rasgo_valores
	where rasgo_id = v_rasgo_final_id
		and slug = 'esdrujulo';

	if v_rasgo_final_id is null or v_valor_esdrujulo_id is null then
		raise exception 'No se encontró el rasgo final_acentual = esdrujulo';
	end if;

	insert into public.configuracion_rasgos (
		configuracion_id,
		rasgo_id,
		valor_id,
		modalidad,
		nota
	)
	values (
		v_configuracion_id,
		v_rasgo_final_id,
		v_valor_esdrujulo_id,
		'admitida',
		'Especialización transversal heredada de octava_real_de_esdrujulos. Solo se declara cuando caracteriza la secuencia.'
	)
	on conflict (configuracion_id, rasgo_id, modalidad) do update
	set
		valor_id = excluded.valor_id,
		valor_numero = null,
		valor_texto = null,
		nota = excluded.nota,
		updated_at = now();

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		selecciones_min,
		selecciones_max,
		estado_revision,
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'final_acentual_destacado',
		'¿Presenta un final acentual destacado?',
		'Déjalo sin marcar cuando no sea una característica de la secuencia.',
		'rasgo',
		'secuencia',
		0,
		1,
		'revisada',
		1,
		true
	)
	on conflict (configuracion_id, slug) do update
	set
		nombre = excluded.nombre,
		ayuda_editor = excluded.ayuda_editor,
		dimension = excluded.dimension,
		alcance = excluded.alcance,
		seccion_id = null,
		selecciones_min = excluded.selecciones_min,
		selecciones_max = excluded.selecciones_max,
		estado_revision = excluded.estado_revision,
		orden = excluded.orden,
		activo = excluded.activo,
		updated_at = now()
	returning grupo_eleccion_id into v_grupo_id;

	delete from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo_id;

	delete from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		valor_rasgo_id,
		orden
	)
	values (
		v_grupo_id,
		'esdrujulo',
		'Mayoría de finales esdrújulos',
		'Los finales esdrújulos caracterizan mayoritariamente la secuencia.',
		v_valor_esdrujulo_id,
		1
	);

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

	select alias_id into v_alias_regular_id
	from public.denominaciones_metricas
	where origen_termino_id = v_termino_regular_id;

	if v_alias_regular_id is null then
		insert into public.denominaciones_metricas (
			forma_id,
			nombre,
			slug_normalizado,
			tipo_alias,
			origen_termino_id
		)
		values (
			v_forma_id,
			'Octava real regular',
			'octava_real_regular',
			'historico',
			v_termino_regular_id
		)
		returning alias_id into v_alias_regular_id;
	else
		update public.denominaciones_metricas
		set
			forma_id = v_forma_id,
			configuracion_id = null,
			patron_metrico_id = null,
			patron_rima_id = null,
			seccion_id = null,
			patron_repeticion_id = null,
			nombre = 'Octava real regular',
			slug_normalizado = 'octava_real_regular',
			tipo_alias = 'historico',
			fuente_id = null,
			updated_at = now()
		where alias_id = v_alias_regular_id;
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
			'Octava rima',
			'octava_rima',
			'equivalente',
			v_fuente_id
		),
		(
			v_forma_id,
			'Octava heroica',
			'octava_heroica',
			'equivalente',
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
		localizador = 'p. 202',
		resumen = 'Define la octava real, octava rima u octava heroica como ocho endecasílabos de rima consonante ABABABCC.',
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
			'p. 202',
			'Define la octava real, octava rima u octava heroica como ocho endecasílabos de rima consonante ABABABCC.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case migracion.termino_id
			when v_termino_raiz_id then 'F'
			when v_termino_regular_id then 'A'
			else 'R'
		end,
		propuesta = case migracion.termino_id
			when v_termino_raiz_id
				then 'Conservar como forma fija de ocho endecasílabos consonantes ABABABCC.'
			when v_termino_regular_id
				then 'Fusionar con octava_real; no aporta una configuración distinta.'
			else
				'Transformar en el rasgo transversal final_acentual = esdrujulo.'
		end,
		certeza = 'alta',
		requiere_revision = false
	where migracion.termino_id in (
		v_termino_raiz_id,
		v_termino_regular_id,
		v_termino_esdrujulos_id
	);

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_raiz_id,
		v_termino_regular_id,
		v_termino_esdrujulos_id
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
		'La raíz anterior ya contenía la definición completa de la octava real.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		alias_id,
		nota
	)
	values (
		v_termino_regular_id,
		'fusionar',
		v_alias_regular_id,
		'La etiqueta redundante se conserva únicamente como denominación histórica de migración.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		valor_rasgo_id,
		nota
	)
	values (
		v_termino_esdrujulos_id,
		'transformar',
		v_valor_esdrujulo_id,
		'La antigua subforma pasa al rasgo transversal de final acentual.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 31,
	actualizado_en = now()
where id = true;

commit;
