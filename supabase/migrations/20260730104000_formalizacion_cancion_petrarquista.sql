begin;

-- Las opciones posicionales ya no se limitan a marcar una posición: una misma
-- posición puede ofrecer varias medidas mutuamente excluyentes.
drop index if exists public.opciones_eleccion_posicion_unidad_idx;

create index if not exists opciones_eleccion_posicion_unidad_idx
	on public.opciones_eleccion_metrica (grupo_eleccion_id, posicion_unidad)
	where posicion_unidad is not null;

do $$
declare
	v_forma_id uuid := '10d7f0d4-9f73-4674-bd88-0bc9d4a51775'::uuid;
	v_regular_termino_id uuid := 'cca8de4d-25af-4840-bc36-0500b37eb60a'::uuid;
	v_endecasilaba_termino_id uuid := '0d7d464b-541b-4ecd-af02-bd6ea8503d6a'::uuid;
	v_sin_rima_termino_id uuid := '7c77b0f1-b224-4726-914a-70c6cce5089d'::uuid;
	v_esdrujulos_termino_id uuid := 'c8154c3a-1158-4ebf-bf9a-72e4fb8424dc'::uuid;
	v_ocho_termino_id uuid := '18742e01-b696-4998-a8c0-c3c877a7a668'::uuid;
	v_nueve_termino_id uuid := '9a751fd7-3fce-4725-9c14-5ef1bad2cc16'::uuid;
	v_quince_termino_id uuid := 'a4286d70-8b15-4640-8b70-4685a74217be'::uuid;
	v_config_general_id uuid;
	v_config_regular_id uuid;
	v_config_sin_rima_id uuid;
	v_patron_metrico_general_id uuid;
	v_patron_metrico_regular_id uuid;
	v_patron_metrico_sin_rima_id uuid;
	v_patron_rima_general_id uuid;
	v_patron_rima_regular_id uuid;
	v_patron_rima_cuerpo_id uuid;
	v_patron_rima_pareado_id uuid;
	v_raiz_general_id uuid;
	v_estancia_general_id uuid;
	v_raiz_regular_id uuid;
	v_estancia_regular_id uuid;
	v_raiz_sin_rima_id uuid;
	v_estancia_sin_rima_id uuid;
	v_cuerpo_sin_rima_id uuid;
	v_pareado_sin_rima_id uuid;
	v_grupo_id uuid;
	v_metro_7_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_sin_rima_id uuid;
	v_rasgo_final_id uuid;
	v_valor_esdrujulo_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	if not exists (
		select 1 from public.formas_metricas
		where forma_id = v_forma_id and slug = 'cancion_petrarquista'
	) then
		raise exception 'No se encontró la canción petrarquista con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 5 then
		raise exception
			'Se esperaban cinco configuraciones importadas para canción petrarquista y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_general_id
	from public.configuraciones_forma
	where forma_id = v_forma_id and principal;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro' and activo and numero_silabas = 7
	order by created_at
	limit 1;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro' and activo and numero_silabas = 11
	order by created_at
	limit 1;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima' and activo and termino = 'consonante'
	limit 1;

	select termino_id into v_sin_rima_id
	from public.vocabularios
	where categoria = 'tipo_rima' and activo and termino = 'sin_rima'
	limit 1;

	select rasgo_id into v_rasgo_final_id
	from public.rasgos_metricos
	where slug = 'final_acentual';

	select valor.valor_id into v_valor_esdrujulo_id
	from public.rasgo_valores valor
	join public.rasgos_metricos rasgo on rasgo.rasgo_id = valor.rasgo_id
	where rasgo.slug = 'final_acentual' and valor.slug = 'esdrujulo';

	if v_config_general_id is null
		or v_metro_7_id is null
		or v_metro_11_id is null
		or v_consonante_id is null
		or v_sin_rima_id is null
		or v_rasgo_final_id is null
		or v_valor_esdrujulo_id is null
	then
		raise exception
			'Falta una configuración, metro, tipo de rima o valor transversal necesario para formalizar la canción';
	end if;

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_forma_id,
		v_regular_termino_id,
		v_endecasilaba_termino_id,
		v_sin_rima_termino_id,
		v_esdrujulos_termino_id,
		v_ocho_termino_id,
		v_nueve_termino_id,
		v_quince_termino_id
	);

	delete from public.configuraciones_forma
	where forma_id = v_forma_id
		and configuracion_id <> v_config_general_id;

	delete from public.secuencias_editor_metrico
	where configuracion_id = v_config_general_id;
	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_config_general_id;
	delete from public.estructuras_secciones
	where configuracion_id = v_config_general_id;
	delete from public.patrones_repeticion
	where configuracion_id = v_config_general_id;
	delete from public.patrones_rima
	where configuracion_id = v_config_general_id;
	delete from public.patrones_metricos
	where configuracion_id = v_config_general_id;
	delete from public.configuracion_rasgos
	where configuracion_id = v_config_general_id;

	update public.formas_metricas
	set
		nombre = 'Canción petrarquista',
		definicion = 'Composición de estancias que combinan habitualmente heptasílabos y endecasílabos. En la canción rimada, todas las estancias repiten la misma distribución métrica y el mismo esquema consonante; el catálogo distingue además el modelo regular de trece versos y la modalidad de cuerpo sin rima con pareado final.',
		nivel_estructural = 'compuesta',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'estancias_consonantes_variables',
		nombre = 'Estancias consonantes variables',
		descripcion = 'Tres o más estancias de 5 a 20 versos. La primera estancia declara su distribución de heptasílabos y endecasílabos y su esquema consonante; ambos se repiten en las demás.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_consonante_id,
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_general_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_general_id,
		'Heptasílabos y endecasílabos en distribución repetida',
		'estrofa',
		'conjunto_permitido',
		'Cada posición de la primera estancia se registra como heptasílaba o endecasílaba; la distribución se repite en las demás estancias.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_general_id;

	insert into public.patron_metrico_opciones (patron_metrico_id, metro_id, orden)
	values
		(v_patron_metrico_general_id, v_metro_7_id, 1),
		(v_patron_metrico_general_id, v_metro_11_id, 2);

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito, fijeza,
		comportamiento, descripcion, estado_revision
	)
	values (
		v_config_general_id,
		'Esquema consonante repetido entre estancias',
		null,
		v_consonante_id,
		'estrofa',
		'libre',
		'libre',
		'El esquema concreto es libre dentro de la estancia, pero debe repetirse idénticamente en todas las estancias de la canción.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_general_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_general_id,
		'cancion',
		'Canción',
		1,
		1,
		1,
		'La extensión total se deriva de las estancias y, si aparece, del remate.'
	)
	returning seccion_id into v_raiz_general_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, patron_rima_id, nota
	)
	values (
		v_config_general_id,
		v_raiz_general_id,
		'estancia',
		'Estancia',
		1,
		3,
		null,
		5,
		20,
		v_patron_metrico_general_id,
		v_patron_rima_general_id,
		'Las estancias repiten exactamente la extensión, las medidas por posición y el esquema de rima.'
	)
	returning seccion_id into v_estancia_general_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_general_id,
		v_raiz_general_id,
		'remate',
		'Remate o envío',
		2,
		0,
		1,
		1,
		20,
		'Fragmento final de estancia. Se mantiene opcional hasta confirmar con el IP si debe exigirse en el corpus.'
	);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		seccion_id, selecciones_min, selecciones_max, permite_aplicar_global,
		tipo_control, estado_revision, activo, orden
	)
	values (
		v_config_general_id,
		'medida_por_posicion',
		'¿Qué medida tiene cada verso de la estancia?',
		'Elige 7 u 11 sílabas en cada posición. Después aplica la distribución a todas las estancias equivalentes.',
		'metro',
		'unidad',
		v_estancia_general_id,
		5,
		20,
		true,
		'opciones',
		'revisada',
		true,
		1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, descripcion, metro_id,
		posicion_unidad, orden
	)
	select
		v_grupo_id,
		format('verso_%s_%s_silabas', posicion, metro.silabas),
		format('%s sílabas', metro.silabas),
		format('El verso %s tiene %s sílabas.', posicion, metro.silabas),
		metro.metro_id,
		posicion,
		posicion * 10 + metro.orden
	from generate_series(1, 20) posicion
	cross join (
		values
			(v_metro_7_id, 7, 1),
			(v_metro_11_id, 11, 2)
	) as metro (metro_id, silabas, orden);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		seccion_id, selecciones_min, selecciones_max, permite_aplicar_global,
		tipo_control, estado_revision, activo, orden
	)
	values (
		v_config_general_id,
		'esquema_rima_estancia',
		'¿Qué esquema de rima presenta la estancia?',
		'Escribe una letra por verso. El esquema consonante debe repetirse en todas las estancias.',
		'rima',
		'unidad',
		v_estancia_general_id,
		1,
		1,
		true,
		'esquema_rima',
		'revisada',
		true,
		2
	);

	insert into public.configuraciones_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, grado,
		tipo_rima_id, estado_revision, activo, orden, origen_termino_id
	)
	select
		v_forma_id,
		'regular_13_abCabC_cdeeDfF',
		'Regular de 13 versos · abCabC:cdeeDfF',
		'Estancias de trece versos con patrón métrico y consonante fijo: abCabC:cdeeDfF.',
		false,
		true,
		'canonica',
		v_consonante_id,
		'revisada',
		true,
		2,
		v_regular_termino_id
	from public.configuraciones_forma
	where configuracion_id = v_config_general_id
	returning configuracion_id into v_config_regular_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_regular_id,
		'7-7-11 / 7-7-11 / 7-7-7-7-11-7-11',
		'estrofa',
		'secuencia_fija',
		'Dos pies de tres versos forman la fronte; el heptasílabo séptimo actúa como eslabón y abre la sirima.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_regular_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id, posicion, metro_id, opcional, alternativa, nota
	)
	select
		v_patron_metrico_regular_id,
		posicion,
		case when silabas = 7 then v_metro_7_id else v_metro_11_id end,
		false,
		1,
		case
			when posicion between 1 and 3 then 'Primer pie de la fronte.'
			when posicion between 4 and 6 then 'Segundo pie de la fronte.'
			when posicion = 7 then 'Eslabón o chiave; inicia sintácticamente la sirima.'
			else 'Sirima.'
		end
	from (
		values
			(1, 7), (2, 7), (3, 11), (4, 7), (5, 7), (6, 11), (7, 7),
			(8, 7), (9, 7), (10, 7), (11, 11), (12, 7), (13, 11)
	) as posicion_metrica (posicion, silabas);

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito, fijeza,
		comportamiento, descripcion, estado_revision, origen_termino_id
	)
	values (
		v_config_regular_id,
		'ABCABCCDEEDFF',
		'ABCABCCDEEDFF',
		v_consonante_id,
		'estrofa',
		'fijo',
		'secuencia_fija',
		'Equivale a la notación métrico-rimática abCabC:cdeeDfF; las mayúsculas y minúsculas de esa notación indican la medida, no clases de rima diferentes.',
		'revisada',
		v_regular_termino_id
	)
	returning patron_rima_id into v_patron_rima_regular_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_regular_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id, bloque, seccion, posicion, clase_rima,
		suelto, opcional, nota
	)
	select
		v_patron_rima_regular_id,
		1,
		case
			when posicion between 1 and 3 then 'pie_1'
			when posicion between 4 and 6 then 'pie_2'
			when posicion = 7 then 'eslabon'
			else 'sirima'
		end,
		posicion,
		clase,
		false,
		false,
		null
	from (
		values
			(1, 'A'), (2, 'B'), (3, 'C'), (4, 'A'), (5, 'B'), (6, 'C'),
			(7, 'C'), (8, 'D'), (9, 'E'), (10, 'E'), (11, 'D'), (12, 'F'), (13, 'F')
	) as posicion_rima (posicion, clase);

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_regular_id,
		'cancion',
		'Canción regular',
		1,
		1,
		1,
		'La extensión total se deriva de las estancias y, si aparece, del remate.'
	)
	returning seccion_id into v_raiz_regular_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, patron_rima_id, nota
	)
	values (
		v_config_regular_id,
		v_raiz_regular_id,
		'estancia',
		'Estancia regular',
		1,
		3,
		null,
		13,
		13,
		v_patron_metrico_regular_id,
		v_patron_rima_regular_id,
		'La fronte ocupa los versos 1–6 y la sirima los versos 7–13; el verso 7 es el eslabón.'
	)
	returning seccion_id into v_estancia_regular_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_regular_id,
		v_raiz_regular_id,
		'remate',
		'Remate o envío',
		2,
		0,
		1,
		1,
		13,
		'Fragmento final de estancia; la extensión concreta se registra cuando aparece.'
	);

	insert into public.configuraciones_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, grado,
		tipo_rima_id, estado_revision, activo, orden, origen_termino_id
	)
	select
		v_forma_id,
		'cuerpo_sin_rima_pareado_final',
		'Canción sin rima · cuerpo suelto y pareado final',
		'Series de estancias que combinan heptasílabos y endecasílabos, sin rima en el cuerpo y con un pareado consonante al final de cada estancia.',
		false,
		true,
		'admitida',
		null,
		'revisada',
		true,
		3,
		v_sin_rima_termino_id
	from public.configuraciones_forma
	where configuracion_id = v_config_general_id
	returning configuracion_id into v_config_sin_rima_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_sin_rima_id,
		'Heptasílabos y endecasílabos por posición',
		'estrofa',
		'conjunto_permitido',
		'Cada posición de la estancia se registra como heptasílaba o endecasílaba.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_sin_rima_id;

	insert into public.patron_metrico_opciones (patron_metrico_id, metro_id, orden)
	values
		(v_patron_metrico_sin_rima_id, v_metro_7_id, 1),
		(v_patron_metrico_sin_rima_id, v_metro_11_id, 2);

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito, fijeza,
		comportamiento, descripcion, estado_revision
	)
	values (
		v_config_sin_rima_id,
		'Cuerpo sin rima',
		null,
		v_sin_rima_id,
		'seccion',
		'no_aplica',
		'restricciones',
		'Todos los versos del cuerpo carecen normativamente de rima.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_cuerpo_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, descripcion, obligatoria
	)
	values (
		v_patron_rima_cuerpo_id,
		'versos_sueltos',
		'todos',
		'Todos los versos del cuerpo son sueltos.',
		true
	);

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito, fijeza,
		comportamiento, descripcion, estado_revision
	)
	values (
		v_config_sin_rima_id,
		'Pareado consonante final',
		'AA',
		v_consonante_id,
		'seccion',
		'fijo',
		'secuencia_fija',
		'Los dos versos finales de cada estancia forman un pareado consonante.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_pareado_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_pareado_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id, bloque, seccion, posicion, clase_rima, suelto, opcional
	)
	values
		(v_patron_rima_pareado_id, 1, 'pareado_final', 1, 'A', false, false),
		(v_patron_rima_pareado_id, 1, 'pareado_final', 2, 'A', false, false);

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_sin_rima_id,
		'cancion',
		'Canción sin rima',
		1,
		1,
		1,
		'La extensión total se deriva de sus estancias.'
	)
	returning seccion_id into v_raiz_sin_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_sin_rima_id,
		v_raiz_sin_rima_id,
		'estancia',
		'Estancia',
		1,
		3,
		null,
		'La extensión se deriva del cuerpo y del pareado final.'
	)
	returning seccion_id into v_estancia_sin_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_rima_id, nota
	)
	values (
		v_config_sin_rima_id,
		v_estancia_sin_rima_id,
		'cuerpo',
		'Cuerpo sin rima',
		1,
		1,
		1,
		3,
		18,
		v_patron_rima_cuerpo_id,
		'Extensión variable, sin contar los dos versos del pareado final.'
	)
	returning seccion_id into v_cuerpo_sin_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_rima_id, nota
	)
	values (
		v_config_sin_rima_id,
		v_estancia_sin_rima_id,
		'pareado_final',
		'Pareado final',
		2,
		1,
		1,
		2,
		2,
		v_patron_rima_pareado_id,
		'Dos versos de rima consonante.'
	)
	returning seccion_id into v_pareado_sin_rima_id;

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		seccion_id, selecciones_min, selecciones_max, permite_aplicar_global,
		tipo_control, estado_revision, activo, orden
	)
	values (
		v_config_sin_rima_id,
		'medida_por_posicion',
		'¿Qué medida tiene cada verso de la estancia?',
		'Elige 7 u 11 sílabas en cada posición y aplica la distribución a las demás estancias.',
		'metro',
		'unidad',
		v_estancia_sin_rima_id,
		5,
		20,
		true,
		'opciones',
		'revisada',
		true,
		1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, descripcion, metro_id,
		posicion_unidad, orden
	)
	select
		v_grupo_id,
		format('verso_%s_%s_silabas', posicion, metro.silabas),
		format('%s sílabas', metro.silabas),
		format('El verso %s tiene %s sílabas.', posicion, metro.silabas),
		metro.metro_id,
		posicion,
		posicion * 10 + metro.orden
	from generate_series(1, 20) posicion
	cross join (
		values
			(v_metro_7_id, 7, 1),
			(v_metro_11_id, 11, 2)
	) as metro (metro_id, silabas, orden);

	insert into public.configuracion_rasgos (
		configuracion_id, rasgo_id, valor_id, modalidad, nota
	)
	values (
		v_config_sin_rima_id,
		v_rasgo_final_id,
		v_valor_esdrujulo_id,
		'admitida',
		'Especialización transversal heredada de cancion_sin_rima_de_esdrujulos; solo se declara cuando caracteriza la secuencia.'
	);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, permite_aplicar_global,
		tipo_control, estado_revision, activo, orden
	)
	values (
		v_config_sin_rima_id,
		'final_acentual_destacado',
		'¿Predominan los finales esdrújulos?',
		'Déjalo vacío si no es una característica destacable de la secuencia.',
		'rasgo',
		'secuencia',
		0,
		1,
		false,
		'opciones',
		'revisada',
		true,
		2
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden
	)
	values (
		v_grupo_id,
		'esdrujulo',
		'Sí, predominan',
		'La secuencia usa total o mayoritariamente términos esdrújulos a final de verso.',
		v_valor_esdrujulo_id,
		1
	);

	insert into public.formas_tradiciones (
		forma_id, tradicion_id, tipo_relacion, es_principal, nota
	)
	select
		v_forma_id,
		tradicion_id,
		'origen',
		true,
		'La canción petrarquista procede de la canzone italiana y se organiza en estancias.'
	from public.tradiciones_metricas
	where slug = 'italiana'
	on conflict (forma_id, tradicion_id, tipo_relacion)
	do update set
		es_principal = excluded.es_principal,
		nota = excluded.nota,
		updated_at = now();

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_id is null then
		raise exception 'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	update public.afirmaciones_fuentes_metricas
	set
		localizador = 'pp. 214-216',
		resumen = 'Describe la canción petrarquista como composición de estancias consonantes de heptasílabos y endecasílabos; formaliza la fronte con dos pies, el eslabón, la sirima y el remate. Sitúa la estancia entre 9 y 20 versos, frente al intervalo 5-20 adoptado por el proyecto.',
		confianza = 'alta',
		estado_revision = 'revisada',
		updated_at = now()
	where fuente_id = v_fuente_id and forma_id = v_forma_id;

	if not found then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id, forma_id, localizador, resumen, confianza, estado_revision
		)
		values (
			v_fuente_id,
			v_forma_id,
			'pp. 214-216',
			'Describe la canción petrarquista como composición de estancias consonantes de heptasílabos y endecasílabos; formaliza la fronte con dos pies, el eslabón, la sirima y el remate. Sitúa la estancia entre 9 y 20 versos, frente al intervalo 5-20 adoptado por el proyecto.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case
			when termino_id = v_forma_id then 'F'
			when termino_id = v_regular_termino_id then 'P'
			when termino_id = v_sin_rima_termino_id then 'C'
			when termino_id = v_esdrujulos_termino_id then 'R'
			when termino_id = v_endecasilaba_termino_id then 'R'
			else 'D'
		end,
		propuesta = case
			when termino_id = v_forma_id
				then 'Conservar como forma compuesta con estancias, configuraciones y elecciones observadas.'
			when termino_id = v_regular_termino_id
				then 'Transformar en configuración regular que acopla un patrón métrico y uno de rima de trece posiciones.'
			when termino_id = v_sin_rima_termino_id
				then 'Transformar en configuración diferenciada de cuerpo sin rima y pareado consonante final.'
			when termino_id = v_esdrujulos_termino_id
				then 'Transformar en final_acentual = esdrujulo dentro de la configuración sin rima.'
			when termino_id = v_endecasilaba_termino_id
				then 'Transformar en realización métrica: endecasílabo elegido en todas las posiciones, no configuración independiente.'
			else 'Retirar como identidad: 8, 9 y 15 son extensiones observadas de la estancia.'
		end,
		certeza = case when termino_id = v_sin_rima_termino_id then 'media' else 'alta' end,
		requiere_revision = termino_id = v_sin_rima_termino_id,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id in (
		v_forma_id,
		v_regular_termino_id,
		v_endecasilaba_termino_id,
		v_sin_rima_termino_id,
		v_esdrujulos_termino_id,
		v_ocho_termino_id,
		v_nueve_termino_id,
		v_quince_termino_id
	);

	insert into public.migracion_termino_destinos (
		termino_id, tipo_operacion, forma_id, configuracion_id,
		patron_metrico_id, valor_rasgo_id, nota
	)
	values
		(
			v_forma_id, 'conservar', v_forma_id, null, null, null,
			'La raíz se conserva como forma compuesta.'
		),
		(
			v_regular_termino_id, 'transformar', null, v_config_regular_id, null, null,
			'El patrón legado se conserva con su acoplamiento métrico y rimático en la configuración regular.'
		),
		(
			v_endecasilaba_termino_id, 'transformar', null, null,
			v_patron_metrico_general_id, null,
			'Se migra el uso como elección de 11 sílabas en todas las posiciones de la estancia.'
		),
		(
			v_sin_rima_termino_id, 'transformar', null, v_config_sin_rima_id, null, null,
			'Se mantiene como configuración diferenciada, pendiente de confirmar su identidad con el IP.'
		),
		(
			v_esdrujulos_termino_id, 'transformar', null, v_config_sin_rima_id, null, null,
			'La futura migración aplicará esta configuración sin rima.'
		),
		(
			v_esdrujulos_termino_id, 'transformar', null, null, null,
			v_valor_esdrujulo_id,
			'La futura migración añadirá el rasgo final_acentual = esdrujulo.'
		),
		(
			v_ocho_termino_id, 'retirar', null, null, null, null,
			'La extensión de ocho versos se registra en la unidad estancia.'
		),
		(
			v_nueve_termino_id, 'retirar', null, null, null, null,
			'La extensión de nueve versos se registra en la unidad estancia.'
		),
		(
			v_quince_termino_id, 'retirar', null, null, null, null,
			'La extensión de quince versos se registra en la unidad estancia.'
		);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 39,
	actualizado_en = now()
where id = true;

commit;
