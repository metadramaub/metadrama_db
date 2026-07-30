begin;

do $$
declare
	v_termino_heroico_id uuid := '8bcba9bd-996c-4e52-8b92-0316a083ef91'::uuid;
	v_forma_romance_id uuid;
	v_config_octosilabica_id uuid;
	v_config_heroica_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_11_id uuid;
	v_asonante_id uuid;
	v_rasgo_asonancia_id uuid;
	v_grupo_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_romance_id
	from public.formas_metricas
	where slug = 'romance';

	if v_forma_romance_id is null then
		raise exception 'No se encontró la forma romance';
	end if;

	if not exists (
		select 1
		from public.formas_metricas
		where forma_id = v_termino_heroico_id
			and slug = 'romance_heroico'
	) then
		raise exception 'No se encontró la forma importada romance_heroico';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_romance_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración revisada de romance y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_octosilabica_id
	from public.configuraciones_forma
	where forma_id = v_forma_romance_id;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and numero_silabas = 11
	order by created_at
	limit 1;

	select termino_id into v_asonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'asonante'
	limit 1;

	select rasgo_id into v_rasgo_asonancia_id
	from public.rasgos_metricos
	where slug = 'vocales_asonancia';

	if v_config_octosilabica_id is null
		or v_metro_11_id is null
		or v_asonante_id is null
		or v_rasgo_asonancia_id is null
	then
		raise exception
			'Falta la configuración octosilábica, el endecasílabo, la rima asonante o el rasgo vocales_asonancia';
	end if;

	delete from public.migracion_termino_destinos
	where termino_id = v_termino_heroico_id;

	-- El catálogo nuevo todavía no alimenta secuencias de producción. La falsa
	-- forma importada puede retirarse y su UUID queda conservado como origen de
	-- la configuración que expresa exactamente la misma especialización.
	delete from public.formas_metricas
	where forma_id = v_termino_heroico_id;

	update public.formas_metricas
	set
		definicion = 'Serie indefinida de versos isométricos en la que los versos pares comparten una misma rima asonante y los impares quedan sueltos. Su configuración prototípica es octosilábica; la realización endecasílaba recibe el nombre de romance heroico.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_romance_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabico_asonante',
		nombre = 'Octosilábico',
		descripcion = 'Configuración prototípica: serie abierta de octosílabos, con una misma asonancia en los versos pares y versos impares sueltos.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_asonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_octosilabica_id;

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
		orden,
		origen_termino_id
	)
	values (
		v_forma_romance_id,
		'endecasilabico_heroico',
		'Romance heroico',
		'Serie abierta de endecasílabos, con una misma asonancia en los versos pares y versos impares sueltos.',
		false,
		true,
		'canonica',
		v_asonante_id,
		null,
		'revisada',
		true,
		2,
		v_termino_heroico_id
	)
	returning configuracion_id into v_config_heroica_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_heroica_id,
		'Endecasílabo repetido',
		'serie',
		'secuencia_repetible',
		'Un endecasílabo por cada posición del ciclo, repetido durante toda la serie.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		grupo_repeticion,
		alternativa,
		nota
	)
	values (
		v_patron_metrico_id,
		1,
		v_metro_11_id,
		false,
		'todos_los_versos',
		1,
		'El ciclo métrico de un solo verso se repite durante toda la serie.'
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
		v_config_heroica_id,
		'Asonancia en los versos pares',
		'-a-a-a…',
		v_asonante_id,
		'serie',
		'secuencia_repetible',
		'fijo',
		'Ciclo de dos versos: el impar queda suelto y el par mantiene la misma clase de asonancia durante toda la serie.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id,
		bloque,
		posicion,
		ubicacion,
		clase_rima,
		suelto,
		opcional,
		nota
	)
	values
		(
			v_patron_rima_id,
			1,
			1,
			'final',
			null,
			true,
			false,
			'Verso impar suelto.'
		),
		(
			v_patron_rima_id,
			1,
			2,
			'final',
			'a',
			false,
			false,
			'Verso par con la misma asonancia en cada repetición del ciclo.'
		);

	insert into public.configuracion_rasgos (
		configuracion_id,
		rasgo_id,
		modalidad,
		nota
	)
	values (
		v_config_heroica_id,
		v_rasgo_asonancia_id,
		'admitida',
		'La realización concreta declara las vocales de la asonancia sin crear una forma distinta.'
	);

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		selecciones_min,
		selecciones_max,
		permite_aplicar_global,
		tipo_control,
		estado_revision,
		activo,
		orden
	)
	values (
		v_config_heroica_id,
		'vocales_asonancia',
		'¿Qué vocales caracterizan la asonancia?',
		'Selecciona las vocales que comparten los versos pares.',
		'rasgo',
		'secuencia',
		1,
		1,
		false,
		'opciones',
		'revisada',
		true,
		1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		valor_rasgo_id,
		orden
	)
	select
		v_grupo_id,
		valor.slug,
		valor.nombre,
		valor.descripcion,
		valor.valor_id,
		valor.orden
	from public.rasgo_valores valor
	where valor.rasgo_id = v_rasgo_asonancia_id
		and valor.activo
	order by valor.orden, valor.nombre;

	insert into public.denominaciones_metricas (
		configuracion_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		idioma,
		preferente
	)
	values (
		v_config_heroica_id,
		'Romance real',
		'romance_real',
		'equivalente',
		'es',
		false
	);

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_id is null then
		raise exception 'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id,
		configuracion_id,
		localizador,
		resumen,
		confianza,
		estado_revision
	)
	values (
		v_fuente_id,
		v_config_heroica_id,
		'p. 226',
		'Define el romance heroico como el romance compuesto por versos de once sílabas.',
		'alta',
		'revisada'
	);

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'C',
		propuesta = 'Transformar en la configuración endecasílaba y lexicalizada de romance.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_termino_heroico_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		configuracion_id,
		nota
	)
	values (
		v_termino_heroico_id,
		'transformar',
		v_config_heroica_id,
		'La futura migración conserva la clasificación mediante Romance + configuración Romance heroico.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 40,
	actualizado_en = now()
where id = true;

commit;
