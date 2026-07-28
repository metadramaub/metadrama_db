begin;

do $$
declare
	v_forma_terceto_id uuid;
	v_forma_sin_encadenar_id uuid;
	v_configuracion_sin_encadenar_id uuid;
	v_patron_metrico_id uuid;
	v_patron_central_suelto_id uuid;
	v_patron_inicial_suelto_id uuid;
	v_patron_romance_id uuid;
	v_familia_id uuid;
	v_metro_endecasilabo_id uuid;
	v_tipo_consonante_id uuid;
	v_total integer;
begin
	select forma_id
	into v_forma_terceto_id
	from public.formas_metricas
	where slug = 'terceto';

	if v_forma_terceto_id is null then
		raise exception 'No se encontró la forma terceto en el catálogo métrico';
	end if;

	insert into public.formas_metricas (
		slug,
		nombre,
		definicion,
		nivel_estructural,
		seleccionable,
		residual,
		estado_revision,
		activo
	)
	values (
		'tercetos_sin_encadenar',
		'Tercetos sin encadenar',
		'Serie métrica abierta de versos endecasílabos con rima consonante, organizada en tercetos cuyas rimas no enlazan con las unidades siguientes. El catálogo reconoce tanto la disposición con verso central suelto como la disposición con primer verso suelto.',
		'serie',
		true,
		false,
		'revisada',
		true
	)
	on conflict (slug) do update
	set
		nombre = excluded.nombre,
		definicion = excluded.definicion,
		nivel_estructural = excluded.nivel_estructural,
		seleccionable = excluded.seleccionable,
		residual = excluded.residual,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo;

	select forma_id
	into v_forma_sin_encadenar_id
	from public.formas_metricas
	where slug = 'tercetos_sin_encadenar';

	update public.formas_metricas
	set definicion = 'Estrofa de tres versos endecasílabos con rima consonante en la que, al menos, el primero rima con el tercero. Puede emplearse como unidad autónoma. Las sucesiones de estas unidades se catalogan como terceto encadenado o tercetos sin encadenar según exista o no enlace de rima entre ellas.'
	where forma_id = v_forma_terceto_id;

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

	select configuracion_id
	into v_configuracion_sin_encadenar_id
	from public.configuraciones_forma
	where forma_id = v_forma_sin_encadenar_id
		and slug = 'endecasilabico_consonante';

	if v_configuracion_sin_encadenar_id is null then
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
			activo
		)
		values (
			v_forma_sin_encadenar_id,
			'endecasilabico_consonante',
			'Tercetos sin encadenar endecasilábicos consonantes',
			'Serie abierta formada por unidades de tres endecasílabos. Cada unidad mantiene su propia rima consonante y no la transmite a la siguiente.',
			true,
			true,
			'canonica',
			v_tipo_consonante_id,
			null,
			'revisada',
			true
		)
		returning configuracion_id into v_configuracion_sin_encadenar_id;
	else
		update public.configuraciones_forma
		set
			nombre = 'Tercetos sin encadenar endecasilábicos consonantes',
			descripcion = 'Serie abierta formada por unidades de tres endecasílabos. Cada unidad mantiene su propia rima consonante y no la transmite a la siguiente.',
			principal = true,
			demarcable = true,
			grado = 'canonica',
			tipo_rima_id = v_tipo_consonante_id,
			numero_versos = null,
			estado_revision = 'revisada',
			activo = true
		where configuracion_id = v_configuracion_sin_encadenar_id;
	end if;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_sin_encadenar_id;

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
			v_configuracion_sin_encadenar_id,
			'Endecasílabo repetido',
			'serie',
			'secuencia_repetible',
			'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;
	elsif v_total = 1 then
		select patron_metrico_id
		into v_patron_metrico_id
		from public.patrones_metricos
		where configuracion_id = v_configuracion_sin_encadenar_id;

		update public.patrones_metricos
		set
			nombre = 'Endecasílabo repetido',
			ambito = 'serie',
			tipo = 'secuencia_repetible',
			descripcion = 'Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.',
			estado_revision = 'revisada'
		where patron_metrico_id = v_patron_metrico_id;
	else
		raise exception
			'La configuración de tercetos sin encadenar tiene % patrones métricos',
			v_total;
	end if;

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
	values (
		v_patron_metrico_id,
		1,
		v_metro_endecasilabo_id,
		false,
		1,
		'El ciclo métrico de un solo verso se repite durante toda la serie.'
	);

	select patron.patron_rima_id
	into v_patron_central_suelto_id
	from public.patrones_rima patron
	join public.vocabularios termino
		on termino.termino_id = patron.origen_termino_id
	where termino.termino = 'terceto_sin_encadenar_1_AXABYB';

	select patron.patron_rima_id
	into v_patron_inicial_suelto_id
	from public.patrones_rima patron
	join public.vocabularios termino
		on termino.termino_id = patron.origen_termino_id
	where termino.termino = 'terceto_sin_encadenar_2_XAAYBB';

	if v_patron_central_suelto_id is null or v_patron_inicial_suelto_id is null then
		raise exception
			'No se encontraron los dos patrones heredados de tercetos sin encadenar';
	end if;

	update public.patrones_rima
	set
		configuracion_id = v_configuracion_sin_encadenar_id,
		nombre = 'Verso central suelto',
		esquema = 'A-A | B-B | C-C | …',
		tipo_rima_id = v_tipo_consonante_id,
		ambito = 'serie',
		comportamiento = 'secuencia_repetible',
		fijeza = 'admitido',
		descripcion = 'Cada terceto hace rimar sus versos primero y tercero y deja suelto el verso central. La clase de rima se renueva en cada unidad porque no existe enlace entre bloques.',
		estado_revision = 'revisada'
	where patron_rima_id = v_patron_central_suelto_id;

	update public.patrones_rima
	set
		configuracion_id = v_configuracion_sin_encadenar_id,
		nombre = 'Primer verso suelto',
		esquema = '-AA | -BB | -CC | …',
		tipo_rima_id = v_tipo_consonante_id,
		ambito = 'serie',
		comportamiento = 'secuencia_repetible',
		fijeza = 'admitido',
		descripcion = 'Cada terceto deja suelto el primer verso y hace rimar entre sí el segundo y el tercero. La clase de rima se renueva en cada unidad porque no existe enlace entre bloques.',
		estado_revision = 'revisada'
	where patron_rima_id = v_patron_inicial_suelto_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id in (v_patron_central_suelto_id, v_patron_inicial_suelto_id);

	delete from public.patron_rima_enlaces
	where patron_rima_id in (v_patron_central_suelto_id, v_patron_inicial_suelto_id);

	delete from public.patron_rima_posiciones
	where patron_rima_id in (v_patron_central_suelto_id, v_patron_inicial_suelto_id);

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
			v_patron_central_suelto_id,
			1,
			'terceto',
			1,
			'final',
			'A',
			false,
			false,
			'Primera aparición de la rima propia de la unidad.'
		),
		(
			v_patron_central_suelto_id,
			1,
			'terceto',
			2,
			'final',
			null,
			true,
			false,
			'Verso central suelto.'
		),
		(
			v_patron_central_suelto_id,
			1,
			'terceto',
			3,
			'final',
			'A',
			false,
			false,
			'Segunda aparición de la rima propia de la unidad.'
		),
		(
			v_patron_inicial_suelto_id,
			1,
			'terceto',
			1,
			'final',
			null,
			true,
			false,
			'Primer verso suelto.'
		),
		(
			v_patron_inicial_suelto_id,
			1,
			'terceto',
			2,
			'final',
			'A',
			false,
			false,
			'Primera aparición de la rima propia de la unidad.'
		),
		(
			v_patron_inicial_suelto_id,
			1,
			'terceto',
			3,
			'final',
			'A',
			false,
			false,
			'Segunda aparición de la rima propia de la unidad.'
		);

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_sin_encadenar_id;

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
		nota
	)
	values (
		v_configuracion_sin_encadenar_id,
		'terceto',
		'Serie de tercetos independientes',
		1,
		2,
		null,
		3,
		3,
		v_patron_metrico_id,
		'La unidad de tres versos se repite al menos dos veces. Cada patrón de rima renueva su clase en cada unidad.'
	);

	select familia_id
	into v_familia_id
	from public.familias_metricas
	where slug = 'tercetos';

	if v_familia_id is null then
		raise exception 'No se encontró la familia tercetos en el catálogo métrico';
	end if;

	insert into public.familias_formas (
		familia_id,
		forma_id,
		es_principal,
		orden,
		nota
	)
	values (
		v_familia_id,
		v_forma_sin_encadenar_id,
		false,
		3,
		'Serie de unidades de terceto que no comparten rimas entre sí.'
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
		v_forma_sin_encadenar_id,
		v_forma_terceto_id,
		'relacionada_con',
		'La serie se construye mediante unidades de terceto independientes; no es un subtipo porque cambia el nivel estructural.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set
		nota = excluded.nota,
		estado_revision = excluded.estado_revision;

	-- Una clase repetida conserva su identidad entre bloques solo cuando existe
	-- un enlace explícito. El romance necesita por ello declarar que la
	-- asonancia de los versos pares continúa durante toda la serie.
	select patron.patron_rima_id
	into v_patron_romance_id
	from public.patrones_rima patron
	join public.configuraciones_forma configuracion
		on configuracion.configuracion_id = patron.configuracion_id
	join public.formas_metricas forma
		on forma.forma_id = configuracion.forma_id
	where forma.slug = 'romance'
		and patron.comportamiento = 'secuencia_repetible'
	order by patron.updated_at desc
	limit 1;

	if v_patron_romance_id is not null
		and not exists (
			select 1
			from public.patron_rima_enlaces
			where patron_rima_id = v_patron_romance_id
				and bloque_origen = 1
				and posicion_origen = 2
				and desplazamiento_bloque = 1
				and bloque_destino = 1
				and posicion_destino = 2
		)
	then
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
		values (
			v_patron_romance_id,
			1,
			2,
			'final',
			1,
			1,
			2,
			'final',
			'misma_rima',
			true,
			'La misma asonancia de los versos pares se conserva al repetir el ciclo.'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 10,
	actualizado_en = now()
where id = true;

commit;
