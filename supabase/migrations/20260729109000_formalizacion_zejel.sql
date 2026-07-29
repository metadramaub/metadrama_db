begin;

-- El zéjel reutiliza las mismas funciones estructurales generales que el
-- villancico (cabeza, copla, mudanza, vuelta y represa), pero las combina con
-- una norma propia: mudanza monorrima de tres versos, sin enlace independiente.
do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_forma_villancico_id uuid;
	v_tipo_rima_id uuid;
	v_patron_metrico_id uuid;
	v_metro_6_id uuid;
	v_metro_8_id uuid;
	v_patron_rima_id uuid;
	v_repeticion_total_id uuid;
	v_repeticion_no_material_id uuid;
	v_cabeza_id uuid;
	v_ciclo_id uuid;
	v_copla_id uuid;
	v_mudanza_id uuid;
	v_vuelta_id uuid;
	v_represa_id uuid;
	v_grupo_id uuid;
	v_fuente_dominguez_id uuid;
	v_fuente_carrasco_id uuid;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'zejel';

	if v_forma_id is null then
		raise exception 'No se encontró la forma zejel';
	end if;

	select configuracion_id, tipo_rima_id
	into v_configuracion_id, v_tipo_rima_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
	order by principal desc, orden nulls last, created_at
	limit 1;

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración heredada del zéjel';
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id
		and tipo = 'conjunto_permitido'
	order by created_at
	limit 1;

	select opcion.metro_id into v_metro_6_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_id
		and metro.numero_silabas = 6;

	select opcion.metro_id into v_metro_8_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_id
		and metro.numero_silabas = 8;

	if num_nonnulls(
		v_tipo_rima_id,
		v_patron_metrico_id,
		v_metro_6_id,
		v_metro_8_id
	) <> 4 then
		raise exception 'Los datos heredados de metro o rima del zéjel están incompletos';
	end if;

	-- Solo se descartan realizaciones del editor V2. Las obras y las secuencias
	-- reales siguen vinculadas al vocabulario anterior y no se modifican.
	delete from public.secuencias_editor_metrico
	where configuracion_id = v_configuracion_id;

	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id;

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

	delete from public.patrones_repeticion
	where configuracion_id = v_configuracion_id;

	delete from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	update public.formas_metricas
	set
		nombre = 'Zéjel',
		definicion = 'Forma compuesta de arte menor, normalmente octosílaba o hexasílaba, que comienza con un estribillo de uno o dos versos y continúa con una o más coplas. Cada copla consta de una mudanza de tres versos monorrimos y un verso de vuelta que recupera la rima del estribillo; después puede reaparecer materialmente el estribillo.',
		nivel_estructural = 'compuesta',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'estribillo_y_coplas_monorrimas',
		nombre = 'Estribillo y coplas monorrimas',
		descripcion = 'Estribillo inicial de uno o dos versos seguido de ciclos formados por una copla y la posible represa del estribillo. La copla contiene tres versos monorrimos de mudanza y un verso de vuelta.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_configuracion_id;

	update public.patrones_metricos
	set
		nombre = 'Hexasílabos u octosílabos',
		ambito = 'composicion',
		tipo = 'conjunto_permitido',
		descripcion = 'Los versos son normalmente hexasílabos u octosílabos. El catálogo registra qué medidas aparecen en cada secuencia sin imponer un orden fijo.',
		estado_revision = 'revisada',
		updated_at = now()
	where patron_metrico_id = v_patron_metrico_id;

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
		'Estribillo, mudanza monorrima y vuelta',
		'A(A) | BBBA',
		v_tipo_rima_id,
		'composicion',
		'restricciones',
		'fijo',
		'El estribillo comparte una clase de rima; cada mudanza introduce una clase nueva en sus tres versos y la vuelta recupera la del estribillo.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id, bloque, seccion, posicion, clase_rima, opcional, nota
	)
	values
		(v_patron_rima_id, 1, 'cabeza', 1, 'A', false, 'Primer verso del estribillo inicial.'),
		(v_patron_rima_id, 1, 'cabeza', 2, 'A', true, 'Segundo verso cuando el estribillo es un dístico.'),
		(v_patron_rima_id, 2, 'mudanza', 1, 'B', false, 'Primera posición monorrima de la mudanza.'),
		(v_patron_rima_id, 2, 'mudanza', 2, 'B', false, 'Segunda posición monorrima de la mudanza.'),
		(v_patron_rima_id, 2, 'mudanza', 3, 'B', false, 'Tercera posición monorrima de la mudanza.'),
		(v_patron_rima_id, 2, 'vuelta', 4, 'A', false, 'Verso de vuelta: recupera la rima del estribillo.');

	insert into public.patron_rima_enlaces (
		patron_rima_id,
		bloque_origen,
		posicion_origen,
		desplazamiento_bloque,
		bloque_destino,
		posicion_destino,
		tipo_enlace,
		obligatorio,
		nota
	)
	values (
		v_patron_rima_id,
		2,
		4,
		-1,
		1,
		1,
		'misma_rima',
		true,
		'La vuelta enlaza directamente con la rima del estribillo; el zéjel no añade un verso de enlace independiente.'
	);

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, descripcion, obligatoria
	)
	values (
		v_patron_rima_id,
		'otra',
		'mudanza_monorrima_y_vuelta_al_estribillo',
		'Cada copla introduce una rima propia en los tres versos de mudanza y recupera en la vuelta la clase del estribillo.',
		true
	);

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, nota
	)
	values (
		v_configuracion_id,
		'cabeza',
		'Cabeza (primera aparición del estribillo)',
		1,
		1,
		1,
		1,
		2,
		v_patron_metrico_id,
		'La función es estribillo; «cabeza» indica que su primera aparición abre la composición.'
	)
	returning seccion_id into v_cabeza_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_configuracion_id,
		'ciclo_copla',
		'Copla y posible represa',
		2,
		1,
		null,
		'Contenedor repetible. La copla y la posible represa son secciones hermanas.'
	)
	returning seccion_id into v_ciclo_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_configuracion_id,
		v_ciclo_id,
		'copla',
		'Copla',
		1,
		1,
		1,
		'Unidad fija de cuatro versos: tres de mudanza y uno de vuelta.'
	)
	returning seccion_id into v_copla_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, nota
	)
	values
		(
			v_configuracion_id,
			v_copla_id,
			'mudanza',
			'Mudanza monorrima',
			1,
			1,
			1,
			3,
			3,
			v_patron_metrico_id,
			'Tres versos con una nueva rima común.'
		),
		(
			v_configuracion_id,
			v_copla_id,
			'vuelta',
			'Verso de vuelta',
			2,
			1,
			1,
			1,
			1,
			v_patron_metrico_id,
			'Recupera la rima del estribillo sin verso de enlace independiente.'
		);

	select seccion_id into v_mudanza_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_copla_id
		and tipo_seccion = 'mudanza';

	select seccion_id into v_vuelta_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_copla_id
		and tipo_seccion = 'vuelta';

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, nota
	)
	values (
		v_configuracion_id,
		v_ciclo_id,
		'represa',
		'Represa del estribillo',
		2,
		0,
		1,
		1,
		2,
		v_patron_metrico_id,
		'Reaparición material completa del estribillo después de la copla.'
	)
	returning seccion_id into v_represa_id;

	insert into public.patrones_repeticion (
		configuracion_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	)
	values
		(
			v_configuracion_id,
			'estribillo',
			'seccion',
			'La represa reproduce íntegramente el estribillo inicial después de la copla.',
			'habitual',
			'Reaparición material completa; su extensión se deriva de la cabeza.',
			'revisada'
		),
		(
			v_configuracion_id,
			'estribillo',
			'seccion',
			'El estribillo no reaparece materialmente después de la copla.',
			'admitida',
			'Registra solo la ausencia observable de represa material, sin afirmar una repetición implícita.',
			'revisada'
		);

	select patron_repeticion_id into v_repeticion_total_id
	from public.patrones_repeticion
	where configuracion_id = v_configuracion_id
		and regla like 'La represa reproduce íntegramente%';

	select patron_repeticion_id into v_repeticion_no_material_id
	from public.patrones_repeticion
	where configuracion_id = v_configuracion_id
		and regla like 'El estribillo no reaparece materialmente%';

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, estado_revision, orden
	)
	values (
		v_configuracion_id,
		'medidas_realizadas',
		'¿Qué medidas aparecen?',
		'Marca 6, 8 o ambas si la secuencia combina las dos medidas admitidas.',
		'metro',
		'secuencia',
		1,
		2,
		'revisada',
		1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, orden
	)
	values
		(v_grupo_id, 'hexasilabo', '6 sílabas', v_metro_6_id, 1),
		(v_grupo_id, 'octosilabo', '8 sílabas', v_metro_8_id, 2);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
	)
	values (
		v_configuracion_id,
		'represa_estribillo',
		'¿Reaparece materialmente el estribillo?',
		'Elige la opción observada después de esta copla. Puedes aplicarla a todas y corregir solo las excepciones.',
		'repeticion',
		'unidad',
		v_ciclo_id,
		1,
		1,
		true,
		'revisada',
		2
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_repeticion_id,
		materializa_seccion_id, extension_desde_seccion_id, orden
	)
	values
		(
			v_grupo_id,
			'total',
			'Sí, represa total',
			v_repeticion_total_id,
			v_represa_id,
			v_cabeza_id,
			1
		),
		(
			v_grupo_id,
			'sin_represa_material',
			'No aparece materialmente',
			v_repeticion_no_material_id,
			null,
			null,
			2
		);

	select forma_id into v_forma_villancico_id
	from public.formas_metricas
	where slug = 'villancico';

	if v_forma_villancico_id is not null then
		update public.forma_relaciones
		set
			nota = 'Ambas formas articulan estribillo y coplas. El zéjel fija una mudanza monorrima de tres versos seguida directamente por la vuelta; el villancico admite otras mudanzas y puede incorporar enlace o vuelta.',
			estado_revision = 'revisada',
			updated_at = now()
		where forma_origen_id = v_forma_villancico_id
			and forma_destino_id = v_forma_id
			and tipo_relacion = 'contrasta_con';
	end if;

	select fuente_id into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
		raise exception 'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, configuracion_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_dominguez_id,
		v_configuracion_id,
		'pp. 210-211',
		'Describe el zéjel como forma fija con estribillo de uno o dos versos, mudanza de tres versos monorrimos y verso de vuelta que rima con el estribillo; señala el octosílabo como medida más usada.',
		'alta',
		'revisada'
	);

	select fuente_id into v_fuente_carrasco_id
	from public.fuentes_metricas
	where autoria = 'María Soledad Carrasco Urgoiti'
		and titulo = '«Allega, morico, allega». Notas sobre un villancico del siglo XVI y sus glosas'
		and anio = 1980
	limit 1;

	if v_fuente_carrasco_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, url, cita, nota
		)
		values (
			'artículo',
			'María Soledad Carrasco Urgoiti',
			'«Allega, morico, allega». Notas sobre un villancico del siglo XVI y sus glosas',
			1980,
			'Revista de Dialectología y Tradiciones Populares, 35 (1979-1980), pp. 101-112',
			'https://www.cervantesvirtual.com/obra/allega-morico-allega-notas-sobre-un-villancico-del-siglo-xvi-y-sus-glosas/',
			'Carrasco Urgoiti, María Soledad. «Allega, morico, allega». Notas sobre un villancico del siglo XVI y sus glosas. Revista de Dialectología y Tradiciones Populares, 35 (1979-1980), pp. 101-112.',
			'Publicación académica especializada. La URL remite a su reproducción digital en la Biblioteca Virtual Miguel de Cervantes.'
		)
		returning fuente_id into v_fuente_carrasco_id;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, configuracion_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_carrasco_id,
		v_configuracion_id,
		'pp. 104-105 de la edición original; apartado II en la reproducción digital',
		'Caracteriza el zéjel estricto por un dístico inicial, tres versos monorrimos de mudanza y un verso de vuelta que recoge la rima del dístico, y documenta realizaciones consonantes del siglo XVI.',
		'alta',
		'revisada'
	);

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma compuesta con estribillo inicial, copla de tres versos monorrimos más vuelta y posible represa material.',
		certeza = 'alta',
		requiere_revision = true,
		updated_at = now()
	where termino_id = v_forma_id;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 20,
	actualizado_en = now()
where id = true;

commit;
