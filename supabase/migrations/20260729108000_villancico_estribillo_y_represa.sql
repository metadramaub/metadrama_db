begin;

-- El estribillo es una función recurrente, no una parte de la copla.
-- «Cabeza» nombra únicamente su primera aparición cuando abre la composición;
-- las apariciones posteriores se registran como represas. Cuando el estribillo
-- aparece por primera vez tras la primera copla, esa realización no es cabeza.
do $$
declare
	v_forma_id uuid;
	v_config_inicial_id uuid;
	v_config_posterior_id uuid;
	v_metro_6_id uuid;
	v_metro_8_id uuid;
	v_patron_metrico_inicial_id uuid;
	v_patron_metrico_posterior_id uuid;
	v_rima_relaciones_inicial_id uuid;
	v_rima_abba_inicial_id uuid;
	v_rima_abab_inicial_id uuid;
	v_rima_relaciones_posterior_id uuid;
	v_rima_abba_posterior_id uuid;
	v_rima_abab_posterior_id uuid;
	v_repeticion_total_inicial_id uuid;
	v_repeticion_parcial_inicial_id uuid;
	v_repeticion_implicita_inicial_id uuid;
	v_repeticion_total_posterior_id uuid;
	v_repeticion_parcial_posterior_id uuid;
	v_repeticion_implicita_posterior_id uuid;
	v_cabeza_id uuid;
	v_ciclo_inicial_id uuid;
	v_copla_inicial_id uuid;
	v_mudanza_inicial_id uuid;
	v_represa_inicial_id uuid;
	v_primer_ciclo_id uuid;
	v_primera_copla_id uuid;
	v_primera_mudanza_id uuid;
	v_estribillo_id uuid;
	v_ciclo_posterior_id uuid;
	v_copla_posterior_id uuid;
	v_mudanza_posterior_id uuid;
	v_represa_posterior_id uuid;
	v_grupo_id uuid;
	v_fuente_rodado_id uuid;
	v_fuente_sorjuana_id uuid;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'villancico';

	if v_forma_id is null then
		raise exception 'No se encontró la forma villancico';
	end if;

	select configuracion_id into v_config_inicial_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'estructura_habitual';

	if v_config_inicial_id is null then
		raise exception 'No se encontró la configuración heredada del villancico';
	end if;

	-- Las secuencias de estas tablas son únicamente pruebas del editor V2. Su
	-- árbol anterior afirma una jerarquía que deja de ser válida y no debe
	-- sobrevivir disfrazado como si ya hubiera sido revisado.
	delete from public.secuencias_editor_metrico
	where configuracion_id = v_config_inicial_id;

	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_config_inicial_id;

	delete from public.estructuras_secciones
	where configuracion_id = v_config_inicial_id;

	delete from public.patrones_repeticion
	where configuracion_id = v_config_inicial_id;

	update public.configuraciones_forma
	set
		slug = 'estribillo_inicial',
		nombre = 'El estribillo aparece al comienzo',
		descripcion = 'La primera aparición del estribillo abre la composición y recibe la denominación posicional de cabeza. Después se suceden coplas y represas totales, parciales o implícitas.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		numero_versos = null,
		estado_revision = 'revisada',
		activo = true,
		orden = 1
	where configuracion_id = v_config_inicial_id;

	insert into public.configuraciones_forma (
		forma_id,
		slug,
		nombre,
		descripcion,
		principal,
		demarcable,
		grado,
		numero_versos,
		estado_revision,
		activo,
		orden
	)
	values (
		v_forma_id,
		'estribillo_tras_primera_copla',
		'El estribillo aparece después de la primera copla',
		'La composición comienza con una copla y presenta después la primera aparición del estribillo. Las apariciones siguientes son represas totales, parciales o implícitas.',
		false,
		true,
		'admitida',
		null,
		'revisada',
		true,
		2
	)
	returning configuracion_id into v_config_posterior_id;

	update public.formas_metricas
	set
		definicion = 'Forma compuesta de arte menor, normalmente hexasílaba u octosílaba, articulada por un estribillo y una o más coplas. Si la primera aparición del estribillo abre la composición, funciona como cabeza; si aparece después de la primera copla, no recibe ese nombre. Cada copla contiene una mudanza, generalmente de cuatro versos con esquema abba o abab, y puede incluir un enlace o vuelta. Las apariciones posteriores del estribillo son represas totales, parciales o implícitas.',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_forma_id;

	select patron_metrico_id into v_patron_metrico_inicial_id
	from public.patrones_metricos
	where configuracion_id = v_config_inicial_id
		and tipo = 'conjunto_permitido'
	limit 1;

	select opcion.metro_id into v_metro_6_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_inicial_id
		and metro.numero_silabas = 6;

	select opcion.metro_id into v_metro_8_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_inicial_id
		and metro.numero_silabas = 8;

	select patron_rima_id into v_rima_relaciones_inicial_id
	from public.patrones_rima
	where configuracion_id = v_config_inicial_id
		and comportamiento = 'restricciones'
	limit 1;

	select patron_rima_id into v_rima_abba_inicial_id
	from public.patrones_rima
	where configuracion_id = v_config_inicial_id
		and esquema = 'abba'
	limit 1;

	select patron_rima_id into v_rima_abab_inicial_id
	from public.patrones_rima
	where configuracion_id = v_config_inicial_id
		and esquema = 'abab'
	limit 1;

	if num_nonnulls(
		v_patron_metrico_inicial_id,
		v_metro_6_id,
		v_metro_8_id,
		v_rima_relaciones_inicial_id,
		v_rima_abba_inicial_id,
		v_rima_abab_inicial_id
	) <> 6 then
		raise exception 'La norma heredada del villancico está incompleta';
	end if;

	update public.patrones_rima
	set
		nombre = 'Relación entre mudanza, enlace o vuelta y estribillo',
		descripcion = 'Cuando aparece, el enlace o vuelta articula el paso desde la mudanza hacia la rima del estribillo, con independencia de la posición de su primera aparición.',
		estado_revision = 'revisada'
	where patron_rima_id = v_rima_relaciones_inicial_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	select
		v_config_posterior_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	from public.patrones_metricos
	where patron_metrico_id = v_patron_metrico_inicial_id
	returning patron_metrico_id into v_patron_metrico_posterior_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id, metro_id, orden, nota
	)
	select v_patron_metrico_posterior_id, metro_id, orden, nota
	from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_inicial_id;

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
	select
		v_config_posterior_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	from public.patrones_rima
	where patron_rima_id = v_rima_relaciones_inicial_id
	returning patron_rima_id into v_rima_relaciones_posterior_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id, tipo, valor_texto, valor_numero, descripcion, obligatoria
	)
	select
		v_rima_relaciones_posterior_id,
		tipo,
		valor_texto,
		valor_numero,
		descripcion,
		obligatoria
	from public.patron_rima_restricciones
	where patron_rima_id = v_rima_relaciones_inicial_id;

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
	select
		v_config_posterior_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	from public.patrones_rima
	where patron_rima_id = v_rima_abba_inicial_id
	returning patron_rima_id into v_rima_abba_posterior_id;

	update public.patron_rima_posiciones
	set seccion = 'mudanza'
	where patron_rima_id = v_rima_abba_posterior_id;

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
	select
		v_config_posterior_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	from public.patrones_rima
	where patron_rima_id = v_rima_abab_inicial_id
	returning patron_rima_id into v_rima_abab_posterior_id;

	update public.patron_rima_posiciones
	set seccion = 'mudanza'
	where patron_rima_id = v_rima_abab_posterior_id;

	-- Configuración con estribillo inicial: cabeza y ciclos de copla/represa
	-- son secciones hermanas en la composición.
	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_inicial_id, 'cabeza', 'Cabeza (primera aparición del estribillo)', 1,
		1, 1, 2, 4,
		'«Cabeza» expresa aquí posición inicial y función de estribillo; no es una unidad distinta del estribillo.'
	)
	returning seccion_id into v_cabeza_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_inicial_id, 'ciclo_copla', 'Copla y posible represa', 2,
		1, null,
		'Contenedor estructural repetible. La copla y la represa son partes hermanas.'
	)
	returning seccion_id into v_ciclo_inicial_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_inicial_id, v_ciclo_inicial_id, 'copla', 'Copla', 1,
		1, 1,
		'La copla contiene la mudanza y, cuando aparece, el enlace o vuelta.'
	)
	returning seccion_id into v_copla_inicial_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values
		(
			v_config_inicial_id, v_copla_inicial_id, 'mudanza', 'Mudanza', 1,
			1, 1, 4, 4,
			'Cuatro versos con esquema abba o abab entre las posibilidades reconocidas por el proyecto.'
		),
		(
			v_config_inicial_id, v_copla_inicial_id, 'enlace_vuelta', 'Enlace o vuelta', 2,
			0, 1, 1, null,
			'Sección opcional que articula la mudanza con el estribillo.'
		);

	select seccion_id into v_mudanza_inicial_id
	from public.estructuras_secciones
	where configuracion_id = v_config_inicial_id
		and seccion_padre_id = v_copla_inicial_id
		and tipo_seccion = 'mudanza';

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_inicial_id, v_ciclo_inicial_id, 'represa', 'Represa del estribillo', 2,
		0, 1, 1, 4,
		'Aparición posterior del estribillo. Puede ser total, parcial o quedar implícita.'
	)
	returning seccion_id into v_represa_inicial_id;

	-- Configuración sin cabeza: la primera aparición del estribillo pertenece
	-- al primer ciclo; los ciclos posteriores contienen represas.
	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_posterior_id, 'primer_ciclo', 'Primera copla y estribillo', 1,
		1, 1,
		'Contiene la primera copla y la primera aparición del estribillo, que no es cabeza porque no abre la composición.'
	)
	returning seccion_id into v_primer_ciclo_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_posterior_id, v_primer_ciclo_id, 'copla', 'Primera copla', 1,
		1, 1,
		'Primera copla de la composición.'
	)
	returning seccion_id into v_primera_copla_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values
		(
			v_config_posterior_id, v_primera_copla_id, 'mudanza', 'Mudanza', 1,
			1, 1, 4, 4,
			'Cuatro versos con esquema abba o abab entre las posibilidades reconocidas por el proyecto.'
		),
		(
			v_config_posterior_id, v_primera_copla_id, 'enlace_vuelta', 'Enlace o vuelta', 2,
			0, 1, 1, null,
			'Sección opcional que articula la mudanza con el estribillo.'
		);

	select seccion_id into v_primera_mudanza_id
	from public.estructuras_secciones
	where configuracion_id = v_config_posterior_id
		and seccion_padre_id = v_primera_copla_id
		and tipo_seccion = 'mudanza';

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_posterior_id, v_primer_ciclo_id, 'estribillo', 'Primera aparición del estribillo', 2,
		1, 1, 1, null,
		'No se denomina cabeza porque su primera aparición no ocupa la posición inicial.'
	)
	returning seccion_id into v_estribillo_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_posterior_id, 'ciclo_copla', 'Copla y posible represa', 2,
		0, null,
		'Contenedor estructural de las coplas posteriores y sus posibles represas.'
	)
	returning seccion_id into v_ciclo_posterior_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_posterior_id, v_ciclo_posterior_id, 'copla', 'Copla', 1,
		1, 1,
		'Copla posterior a la primera aparición del estribillo.'
	)
	returning seccion_id into v_copla_posterior_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values
		(
			v_config_posterior_id, v_copla_posterior_id, 'mudanza', 'Mudanza', 1,
			1, 1, 4, 4,
			'Cuatro versos con esquema abba o abab entre las posibilidades reconocidas por el proyecto.'
		),
		(
			v_config_posterior_id, v_copla_posterior_id, 'enlace_vuelta', 'Enlace o vuelta', 2,
			0, 1, 1, null,
			'Sección opcional que articula la mudanza con el estribillo.'
		);

	select seccion_id into v_mudanza_posterior_id
	from public.estructuras_secciones
	where configuracion_id = v_config_posterior_id
		and seccion_padre_id = v_copla_posterior_id
		and tipo_seccion = 'mudanza';

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values (
		v_config_posterior_id, v_ciclo_posterior_id, 'represa', 'Represa del estribillo', 2,
		0, 1, 1, null,
		'Aparición posterior, total o parcial, del estribillo; también puede quedar implícita.'
	)
	returning seccion_id into v_represa_posterior_id;

	-- Las tres realizaciones de la recurrencia pertenecen al catálogo. Solo
	-- total y parcial materializan una represa; la implícita no inventa versos.
	insert into public.patrones_repeticion (
		configuracion_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	)
	values
		(
			v_config_inicial_id, 'estribillo', 'seccion',
			'La represa reproduce íntegramente la primera aparición del estribillo.',
			'admitida', 'Reaparición material completa.', 'revisada'
		),
		(
			v_config_inicial_id, 'estribillo', 'seccion',
			'La represa reproduce solo una parte de la primera aparición del estribillo.',
			'admitida', 'Reaparición material parcial.', 'revisada'
		),
		(
			v_config_inicial_id, 'estribillo', 'seccion',
			'La represa queda sobreentendida y no se realiza materialmente.',
			'admitida', 'Recurrencia funcional sin versos añadidos.', 'revisada'
		);

	select patron_repeticion_id into v_repeticion_total_inicial_id
	from public.patrones_repeticion
	where configuracion_id = v_config_inicial_id
		and regla like 'La represa reproduce íntegramente%';

	select patron_repeticion_id into v_repeticion_parcial_inicial_id
	from public.patrones_repeticion
	where configuracion_id = v_config_inicial_id
		and regla like 'La represa reproduce solo%';

	select patron_repeticion_id into v_repeticion_implicita_inicial_id
	from public.patrones_repeticion
	where configuracion_id = v_config_inicial_id
		and regla like 'La represa queda%';

	insert into public.patrones_repeticion (
		configuracion_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	)
	select
		v_config_posterior_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	from public.patrones_repeticion
	where patron_repeticion_id = v_repeticion_total_inicial_id
	returning patron_repeticion_id into v_repeticion_total_posterior_id;

	insert into public.patrones_repeticion (
		configuracion_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	)
	select
		v_config_posterior_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	from public.patrones_repeticion
	where patron_repeticion_id = v_repeticion_parcial_inicial_id
	returning patron_repeticion_id into v_repeticion_parcial_posterior_id;

	insert into public.patrones_repeticion (
		configuracion_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	)
	select
		v_config_posterior_id, tipo, ambito, regla, fijeza, descripcion, estado_revision
	from public.patrones_repeticion
	where patron_repeticion_id = v_repeticion_implicita_inicial_id
	returning patron_repeticion_id into v_repeticion_implicita_posterior_id;

	-- Preguntas de la configuración con cabeza.
	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, estado_revision, orden
	)
	values (
		v_config_inicial_id, 'medidas_realizadas', '¿Qué medidas aparecen?',
		'Marca 6, 8 o ambas si la secuencia combina las dos medidas admitidas.',
		'metro', 'secuencia', 1, 2, 'revisada', 1
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
		v_config_inicial_id, 'rima_mudanza', '¿Qué patrón tiene la mudanza?',
		'Puede aplicar la misma respuesta a todas y corregir solo las excepciones.',
		'rima', 'unidad', v_mudanza_inicial_id, 1, 1, true, 'revisada', 2
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_rima_id, orden
	)
	values
		(v_grupo_id, 'abba', 'abba — redondilla', v_rima_abba_inicial_id, 1),
		(v_grupo_id, 'abab', 'abab — cuarteta', v_rima_abab_inicial_id, 2);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
	)
	values (
		v_config_inicial_id, 'represa_estribillo', '¿Cómo reaparece el estribillo?',
		'Elige la realización observada después de esta copla.',
		'repeticion', 'unidad', v_ciclo_inicial_id, 1, 1, true, 'revisada', 3
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_repeticion_id,
		materializa_seccion_id, extension_desde_seccion_id, orden
	)
	values
		(v_grupo_id, 'total', 'Represa total', v_repeticion_total_inicial_id, v_represa_inicial_id, v_cabeza_id, 1),
		(v_grupo_id, 'parcial', 'Represa parcial', v_repeticion_parcial_inicial_id, v_represa_inicial_id, null, 2),
		(v_grupo_id, 'implicita', 'Represa implícita', v_repeticion_implicita_inicial_id, null, null, 3);

	-- Preguntas de la configuración con primera aparición posterior.
	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		selecciones_min, selecciones_max, estado_revision, orden
	)
	values (
		v_config_posterior_id, 'medidas_realizadas', '¿Qué medidas aparecen?',
		'Marca 6, 8 o ambas si la secuencia combina las dos medidas admitidas.',
		'metro', 'secuencia', 1, 2, 'revisada', 1
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
		v_config_posterior_id, 'rima_primera_mudanza', '¿Qué patrón tiene la mudanza?',
		'Se refiere a la mudanza de la primera copla.',
		'rima', 'unidad', v_primera_mudanza_id, 1, 1, false, 'revisada', 2
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_rima_id, orden
	)
	values
		(v_grupo_id, 'abba', 'abba — redondilla', v_rima_abba_posterior_id, 1),
		(v_grupo_id, 'abab', 'abab — cuarteta', v_rima_abab_posterior_id, 2);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
	)
	values (
		v_config_posterior_id, 'rima_mudanzas_posteriores', '¿Qué patrón tiene la mudanza?',
		'Puede aplicar la misma respuesta a todas las coplas posteriores y corregir solo las excepciones.',
		'rima', 'unidad', v_mudanza_posterior_id, 1, 1, true, 'revisada', 3
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_rima_id, orden
	)
	values
		(v_grupo_id, 'abba', 'abba — redondilla', v_rima_abba_posterior_id, 1),
		(v_grupo_id, 'abab', 'abab — cuarteta', v_rima_abab_posterior_id, 2);

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
	)
	values (
		v_config_posterior_id, 'represa_estribillo', '¿Cómo reaparece el estribillo?',
		'Elige la realización observada después de esta copla.',
		'repeticion', 'unidad', v_ciclo_posterior_id, 1, 1, true, 'revisada', 4
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_repeticion_id,
		materializa_seccion_id, extension_desde_seccion_id, orden
	)
	values
		(v_grupo_id, 'total', 'Represa total', v_repeticion_total_posterior_id, v_represa_posterior_id, v_estribillo_id, 1),
		(v_grupo_id, 'parcial', 'Represa parcial', v_repeticion_parcial_posterior_id, v_represa_posterior_id, null, 2),
		(v_grupo_id, 'implicita', 'Represa implícita', v_repeticion_implicita_posterior_id, null, null, 3);

	select fuente_id into v_fuente_rodado_id
	from public.fuentes_metricas
	where autoria = 'Ana M. Rodado Ruiz'
		and titulo = 'La métrica cancioneril en la época de los Reyes Católicos: la poesía de Pedro de Cartagena'
		and anio = 2012
	limit 1;

	if v_fuente_rodado_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, url, cita, nota
		)
		values (
			'artículo',
			'Ana M. Rodado Ruiz',
			'La métrica cancioneril en la época de los Reyes Católicos: la poesía de Pedro de Cartagena',
			2012,
			'Ars Metrica, 2012/05',
			'https://f-book.com/arsmetrica/wp-content/uploads/2012/12/Rodado-Ruiz_2012_La-metrica-cancioneril-en-la-epoca-de-los-Reyes-Catolicos.pdf',
			'Rodado Ruiz, Ana M. «La métrica cancioneril en la época de los Reyes Católicos: la poesía de Pedro de Cartagena». Ars Metrica, 2012/05.',
			'Fuente bibliográfica para la terminología y la estructura cancioneril; no sustituye el criterio del IP para el corpus.'
		)
		returning fuente_id into v_fuente_rodado_id;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, configuracion_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_rodado_id,
		v_config_inicial_id,
		'Apartado dedicado al villancico',
		'Describe la unidad inicial recurrente como estribillo o cabeza y la continuación mediante coplas, lo que respalda reservar «cabeza» para la primera aparición inicial.',
		'alta',
		'revisada'
	);

	select fuente_id into v_fuente_sorjuana_id
	from public.fuentes_metricas
	where autoria = 'Juana Inés de la Cruz'
		and titulo = 'Inundación castálida'
		and anio = 1689
	limit 1;

	if v_fuente_sorjuana_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, url, cita, nota
		)
		values (
			'fuente primaria',
			'Juana Inés de la Cruz',
			'Inundación castálida',
			1689,
			'Madrid: Juan García Infanzón',
			'https://www.cervantesvirtual.com/obra-visor/inundacion-castalida--0/html/e59d0e1e-7e62-4169-9386-247b6678ec06_7.html',
			'Juana Inés de la Cruz. Inundación castálida. Madrid: Juan García Infanzón, 1689.',
			'Testimonio primario. La edición digital permite comprobar rúbricas y orden de las secciones; no funciona como tratado normativo.'
		)
		returning fuente_id into v_fuente_sorjuana_id;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, configuracion_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_sorjuana_id,
		v_config_posterior_id,
		'Rúbricas «Coplas» y «Estribillo»',
		'Documenta composiciones en las que unas coplas preceden a la sección rotulada como estribillo. El testimonio justifica poder registrar una primera aparición posterior sin denominarla cabeza.',
		'alta',
		'revisada'
	);

	update public.migracion_terminos_metricos
	set
		propuesta = 'Conservar como forma compuesta con dos configuraciones según la posición de la primera aparición del estribillo; formalizar copla, mudanza, enlace o vuelta y represas.',
		requiere_revision = true,
		updated_at = now()
	where termino_id = v_forma_id;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 19,
	actualizado_en = now()
where id = true;

commit;
