-- Sextina nombra una estrofa y la composición que se construye con ella.
--
-- Quilis las distingue expresamente: llama sextina a cada estrofa de seis endecasílabos y
-- también al poema de seis estrofas más contera. Se crea por eso una forma estrófica propia y
-- las secciones de la composición pasan a reutilizarla, como ya ocurre con las estrofas de
-- otras composiciones del catálogo.
--
-- La composición recibe las dos sextinas dobles que ha decidido conservar el IP:
--
--   clásica                 6 × 6 + 3      39 versos
--   doble petrarquista     12 × 6 + 3      75 versos
--   doble de Montemayor    12 × 6 + 2 × 3  78 versos
--
-- La última está documentada por Navarro Tomás, pero la fuente no enumera sus doce
-- combinaciones. Se declara la extensión y la exigencia de combinaciones distintas sin
-- inventar posiciones. La ausencia de posiciones significa aquí «orden no documentado», no
-- «orden libre».
--
-- Tampoco se convierte en norma universal el orden del remate. Quilis y el ejemplo de Herrera
-- recogido por Domínguez Caparrós muestran AB-DE-CF; Morley y Bruerton registran BA-DF-EC.
-- El invariante común es que comparezcan las seis palabras, una interior y otra final en cada
-- verso del terceto. Los dos órdenes quedan en las afirmaciones de fuente, no como posiciones
-- obligatorias de la forma.

begin;

do $$
declare
	v_forma_composicion uuid;
	v_forma_estrofa uuid;
	v_arq_clasica uuid;
	v_arq_petrarquista uuid;
	v_arq_montemayor uuid;
	v_arq_estrofa uuid;
	v_esquema_clasica uuid;
	v_esquema_petrarquista uuid;
	v_esquema_montemayor uuid;
	v_esquema_estrofa uuid;
	v_seccion uuid;
	v_repeticion_clasica uuid;
	v_repeticion_petrarquista uuid;
	v_repeticion_montemayor uuid;
	v_endecasilabo uuid;
	v_sin_rima uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_provenzal uuid;
	v_italiana uuid;
	v_espanola uuid;
	v_n integer;
begin
	select forma_id into v_forma_composicion
	from public.formas_metricas where slug = 'sextina';

	select arquitectura_id into v_arq_clasica
	from public.arquitecturas_forma
	where forma_id = v_forma_composicion and slug = 'clasica';

	select arquitectura_id into v_arq_petrarquista
	from public.arquitecturas_forma
	where forma_id = v_forma_composicion and slug = 'doble';

	select esquema_metrico_id into v_esquema_clasica
	from public.esquemas_metricos
	where arquitectura_id = v_arq_clasica and slug = '11-repetido';

	select esquema_metrico_id into v_esquema_petrarquista
	from public.esquemas_metricos
	where arquitectura_id = v_arq_petrarquista and slug = '11-repetido';

	select repeticion_id into v_repeticion_clasica
	from public.repeticiones_metricas
	where arquitectura_id = v_arq_clasica and slug = 'palabra_final';

	select repeticion_id into v_repeticion_petrarquista
	from public.repeticiones_metricas
	where arquitectura_id = v_arq_petrarquista and slug = 'palabra_final';

	select metro_id into v_endecasilabo from public.metros where slug = 'endecasilabo';
	select termino_id into v_sin_rima
	from public.vocabularios where categoria = 'tipo_rima' and termino = 'sin_rima';

	if num_nonnulls(
		v_forma_composicion, v_arq_clasica, v_arq_petrarquista,
		v_esquema_clasica, v_esquema_petrarquista,
		v_repeticion_clasica, v_repeticion_petrarquista,
		v_endecasilabo, v_sin_rima,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 15 then
		raise exception 'Falta la sextina vigente, alguno de sus datos o una fuente autorizada';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- ------------------------------------------------------------------
	-- 1 · La forma estrófica que las composiciones reutilizan
	-- ------------------------------------------------------------------

	insert into public.formas_metricas (
		slug, nombre, definicion, nivel_estructural, tipo_registro,
		seleccionable, estado_revision, activo, orden
	)
	values (
		'sextina_estrofa',
		'Sextina',
		'Estrofa de seis endecasílabos sin rima convencional. Cada verso termina en una palabra distinta que funciona como palabra-rima; en la composición homónima, esas seis palabras se permutan de una estrofa a otra.',
		'estrofa',
		'forma',
		true,
		'aprobada',
		true,
		279
	)
	returning forma_id into v_forma_estrofa;

	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max,
		estado_revision, activo, orden
	)
	values (
		v_forma_estrofa,
		'endecasilabica_sin_rima',
		'Endecasilábica sin rima',
		'Los seis versos establecen las seis palabras finales que la composición permuta entre sus estrofas.',
		true,
		false,
		'preferente',
		v_sin_rima,
		6,
		6,
		'revisada',
		true,
		1
	)
	returning arquitectura_id into v_arq_estrofa;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (
		v_arq_estrofa,
		'11-repetido',
		'Endecasílabo repetido',
		'unidad',
		'ciclo',
		'La misma medida endecasilábica ocupa los seis versos.',
		'revisada'
	)
	returning esquema_metrico_id into v_esquema_estrofa;

	insert into public.esquema_metrico_posiciones (
		esquema_metrico_id, posicion, metro_id, opcional, alternativa, nota
	)
	values (
		v_esquema_estrofa, 1, v_endecasilabo, false, 1,
		'Esta posición se repite en los seis versos de la estrofa.'
	);

	-- ------------------------------------------------------------------
	-- 2 · La composición y sus dos arquitecturas dobles
	-- ------------------------------------------------------------------

	update public.formas_metricas
	set definicion = 'Composición endecasilábica formada por seis o doce sextinas y cerrada por uno o dos tercetos. Seis palabras finales aparecen en cada estrofa, permutadas en órdenes sucesivos, y vuelven en el cierre en posición interior y final.',
		nivel_estructural = 'composicion',
		seleccionable = true,
		estado_revision = 'aprobada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_composicion;

	update public.arquitecturas_forma
	set nombre = 'Clásica',
		descripcion = 'Seis sextinas y un terceto final. Las seis palabras siguen el ciclo canónico completo.',
		unidad_versos_min = 39,
		unidad_versos_max = 39,
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq_clasica;

	update public.arquitecturas_forma
	set slug = 'doble_petrarquista',
		nombre = 'Doble petrarquista',
		descripcion = 'Doce sextinas que recorren dos veces el ciclo canónico y un terceto final.',
		unidad_versos_min = 75,
		unidad_versos_max = 75,
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq_petrarquista;

	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max,
		estado_revision, activo, orden
	)
	values (
		v_forma_composicion,
		'doble_montemayor',
		'Doble de Montemayor',
		'Doce sextinas con combinaciones distintas de las seis palabras y dos tercetos finales.',
		false,
		true,
		'admitida',
		v_sin_rima,
		78,
		78,
		'revisada',
		true,
		3
	)
	returning arquitectura_id into v_arq_montemayor;

	-- Las estrofas toman su medida de la forma estrófica. Los esquemas propios de la
	-- composición quedan limitados a los tercetos finales, que no reutilizan esa arquitectura.
	update public.esquemas_metricos
	set ambito = 'seccion',
		tipo_secuencia = 'ciclo',
		descripcion = 'La misma medida endecasilábica ocupa los tres versos del remate.',
		updated_at = now()
	where esquema_metrico_id in (v_esquema_clasica, v_esquema_petrarquista);

	update public.esquema_metrico_posiciones
	set nota = 'Esta posición se repite en los tres versos del remate.',
		updated_at = now()
	where esquema_metrico_id in (v_esquema_clasica, v_esquema_petrarquista);

	update public.estructuras_secciones
	set arquitectura_referenciada_id = v_arq_estrofa,
		esquema_metrico_id = null,
		nota = 'Cada sección realiza la forma estrófica Sextina.',
		updated_at = now()
	where arquitectura_id in (v_arq_clasica, v_arq_petrarquista)
		and slug = 'estrofa';

	update public.estructuras_secciones
	set esquema_metrico_id = case arquitectura_id
			when v_arq_clasica then v_esquema_clasica
			else v_esquema_petrarquista
		end,
		nota = 'Las seis palabras comparecen una vez: cada verso contiene una en el interior y otra al final, sin un orden universal por parejas.',
		updated_at = now()
	where arquitectura_id in (v_arq_clasica, v_arq_petrarquista)
		and slug = 'remate';

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (
		v_arq_montemayor,
		'11-repetido',
		'Endecasílabo repetido',
		'seccion',
		'ciclo',
		'La misma medida endecasilábica ocupa los versos de los dos tercetos finales.',
		'revisada'
	)
	returning esquema_metrico_id into v_esquema_montemayor;

	insert into public.esquema_metrico_posiciones (
		esquema_metrico_id, posicion, metro_id, opcional, alternativa, nota
	)
	values (
		v_esquema_montemayor, 1, v_endecasilabo, false, 1,
		'Esta posición se repite en los seis versos de los dos tercetos finales.'
	);

	insert into public.estructuras_secciones (
		arquitectura_id, slug, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		arquitectura_referenciada_id, nota
	)
	values (
		v_arq_montemayor, 'estrofa', 'estrofa', 'Estrofa', 1,
		12, 12, 6, 6, v_arq_estrofa,
		'Cada sección realiza la forma estrófica Sextina.'
	);

	insert into public.estructuras_secciones (
		arquitectura_id, slug, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		esquema_metrico_id, nota
	)
	values (
		v_arq_montemayor, 'terceto_final', 'remate', 'Terceto final', 2,
		2, 2, 3, 3, v_esquema_montemayor,
		'Los seis vocablos vuelven en los dos tercetos; la fuente no precisa su distribución por parejas.'
	);

	-- ------------------------------------------------------------------
	-- 3 · La repetición léxica: posiciones solo donde están documentadas
	-- ------------------------------------------------------------------

	update public.repeticiones_metricas
	set regla = 'Las seis palabras finales siguen el ciclo ABCDEF → FAEBDC → CFDABE → ECBFAD → DEACFB → BDFECA. En el terceto aparecen las seis, una interior y otra final en cada verso; la forma no impone una única asociación por parejas.',
		descripcion = 'Seis palabras finales permutadas en seis estrofas y recuperadas en el terceto.',
		updated_at = now()
	where repeticion_id = v_repeticion_clasica;

	update public.repeticiones_metricas
	set regla = 'El ciclo ABCDEF → FAEBDC → CFDABE → ECBFAD → DEACFB → BDFECA se completa dos veces con las mismas seis palabras finales. En el terceto aparecen las seis, una interior y otra final en cada verso; la forma no impone una única asociación por parejas.',
		descripcion = 'Seis palabras finales permutadas durante dos ciclos estróficos y recuperadas en el terceto.',
		updated_at = now()
	where repeticion_id = v_repeticion_petrarquista;

	insert into public.repeticiones_metricas (
		arquitectura_id, slug, tipo, ambito, regla, modalidad, descripcion, estado_revision
	)
	values (
		v_arq_montemayor,
		'palabra_final',
		'palabra_final',
		'unidad',
		'Las mismas seis palabras finales aparecen en doce estrofas con combinaciones distintas y vuelven en dos tercetos finales. No se fija una secuencia de doce permutaciones ni una distribución por parejas que la fuente no proporciona.',
		'definitoria',
		'Seis palabras finales distribuidas en doce combinaciones estróficas distintas y dos tercetos finales.',
		'revisada'
	)
	returning repeticion_id into v_repeticion_montemayor;

	-- La relación dice de qué forma se compone; cada sección declara cuántas realizaciones hay
	-- en su arquitectura concreta.
	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion,
		cantidad_min, cantidad_max, orden_composicion, nota, estado_revision
	)
	values (
		v_forma_composicion, v_forma_estrofa, 'compuesta_por',
		6, 12, 1,
		'La composición consta de seis sextinas en la arquitectura clásica y de doce en las dos arquitecturas dobles.',
		'revisada'
	);

	-- ------------------------------------------------------------------
	-- 4 · Tradiciones y fuentes
	-- ------------------------------------------------------------------

	insert into public.tradiciones_metricas (
		slug, nombre, descripcion, estado_revision, activo, orden
	)
	values (
		'provenzal', 'Provenzal',
		'Tradición trovadoresca en lengua de oc.',
		'revisada', true, 10
	)
	on conflict (slug) do update
	set nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		activo = true,
		updated_at = now()
	returning tradicion_id into v_provenzal;

	select tradicion_id into v_italiana from public.tradiciones_metricas where slug = 'italiana';
	select tradicion_id into v_espanola from public.tradiciones_metricas where slug = 'espanola';

	if num_nonnulls(v_provenzal, v_italiana, v_espanola) <> 3 then
		raise exception 'Falta alguna de las tradiciones provenzal, italiana o española';
	end if;

	delete from public.formas_tradiciones
	where forma_id in (v_forma_composicion, v_forma_estrofa);

	insert into public.formas_tradiciones (forma_id, tradicion_id, cronologia, nota)
	select forma.forma_id, tradicion.tradicion_id, tradicion.cronologia, tradicion.nota
	from (values (v_forma_composicion), (v_forma_estrofa)) forma (forma_id)
	cross join (values
		(v_provenzal, 'Finales del siglo XII', 'Arnaut Daniel creó el modelo en la tradición trovadoresca provenzal.'),
		(v_italiana, 'Desde Dante y Petrarca', 'Dante le dio forma en italiano y Petrarca contribuyó decisivamente a su difusión.'),
		(v_espanola, 'Desde el siglo XVI', 'Se introdujo en España en el siglo XVI y tuvo un cultivo escaso, aunque documentado, durante los siglos XVI y XVII.')
	) tradicion (tradicion_id, cronologia, nota);

	delete from public.afirmaciones_fuentes_metricas
	where forma_id in (v_forma_composicion, v_forma_estrofa)
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma
			where forma_id in (v_forma_composicion, v_forma_estrofa)
		);

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza, estado_revision)
	values
		(v_mb, v_forma_composicion, 'Entrada «Sestina»',
		 'Define la forma petrarquista como seis estrofas de seis endecasílabos y un envío de tres versos, siempre 39 en total. Da la permutación 123456 → 615243 → 364125 → 532614 → 451362 → 246531 y realiza el envío como 21-46-53, es decir, BA-DF-EC. Registra además una sextina incompleta de Lope de 21 versos.',
		 'alta', 'revisada'),
		(v_quilis, v_forma_estrofa, '§ 5.4.5.1, p. 100',
		 'Llama sextina a la estrofa de seis endecasílabos que forma parte, junto con otras cinco y un terceto, de la composición homónima.',
		 'alta', 'revisada'),
		(v_quilis, v_forma_composicion, '§ 6.3.4, pp. 167-168',
		 'Atribuye la invención a Arnaut Daniel, la forma italiana a Dante y su difusión a Petrarca; señala su entrada en España en el siglo XVI y su escaso arraigo. Da el ciclo canónico completo y ejemplifica la contera como AB-DE-CF.',
		 'alta', 'revisada'),
		(v_navarro, v_forma_composicion, '§§ 115 y 167',
		 'Documenta sextinas endecasílabas en Montemayor, Gil Polo, Herrera y Bermúdez, y su uso raro en Cervantes, Rioja y tres comedias de Lope anteriores a 1604. En el libro V de la *Diana* registra una doble de doce estrofas con combinaciones distintas y dos tercetos finales, es decir, 78 versos.',
		 'alta', 'revisada'),
		(v_cap14, v_forma_composicion, 'pp. 216-218',
		 'Define la forma clásica como 39 endecasílabos en seis estrofas y un remate, explica la permutación canónica y exige en el remate una palabra interior y otra final por verso. El ejemplo de Herrera realiza ese cierre como AB-DE-CF; la definición no lo impone como pareja universal.',
		 'alta', 'revisada'),
		(v_dicc, v_forma_estrofa, 'Entradas «sextina» y «sextina real», pp. 391-392',
		 'Distingue tres sentidos de «sextina»: la composición clásica de 39 versos, el sexteto y la sexta rima. Remite además «sextina real» a sexta rima, por lo que ese nombre no designa la estrofa sin rima que integra la composición.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma_estrofa, 'Apartado «Sextina real»',
		 'Usa «sextina real» para un sexteto endecasilábico ABABCC con pareado final. Es otra estrofa —la sexta rima— y no la sextina sin rima que sirve de unidad a la composición de palabras finales.',
		 'alta', 'revisada');

	-- ------------------------------------------------------------------
	-- 5 · Guardas de la decisión
	-- ------------------------------------------------------------------

	select count(*) into v_n
	from public.formas_metricas
	where slug in ('sextina', 'sextina_estrofa')
		and nombre = 'Sextina'
		and nivel_estructural in ('estrofa', 'composicion');
	if v_n <> 2 then
		raise exception 'Deben existir la Sextina estrófica y la composición homónima';
	end if;

	select count(*) into v_n
	from public.arquitecturas_forma
	where forma_id = v_forma_composicion
		and (slug, unidad_versos_min, unidad_versos_max) in (
			('clasica', 39, 39),
			('doble_petrarquista', 75, 75),
			('doble_montemayor', 78, 78)
		);
	if v_n <> 3 then
		raise exception 'La composición debe tener arquitecturas de 39, 75 y 78 versos';
	end if;

	select count(*) into v_n
	from public.estructuras_secciones
	where arquitectura_id in (v_arq_clasica, v_arq_petrarquista, v_arq_montemayor)
		and slug = 'estrofa'
		and arquitectura_referenciada_id = v_arq_estrofa;
	if v_n <> 3 then
		raise exception 'Las tres composiciones deben reutilizar la sextina estrófica';
	end if;

	select count(*) into v_n
	from public.repeticion_posiciones
	where repeticion_id = v_repeticion_clasica;
	if v_n <> 36 then
		raise exception 'El ciclo clásico debe conservar sus 36 posiciones';
	end if;

	select count(*) into v_n
	from public.repeticion_posiciones
	where repeticion_id = v_repeticion_petrarquista;
	if v_n <> 72 then
		raise exception 'La doble petrarquista debe conservar sus 72 posiciones';
	end if;

	select count(*) into v_n
	from public.repeticion_posiciones
	where repeticion_id = v_repeticion_montemayor;
	if v_n <> 0 then
		raise exception 'No se deben inventar posiciones para la doble de Montemayor';
	end if;

end;
$$;

-- La comprobación de fuentes se deja fuera del bloque anterior para mantener separados los
-- dos recuentos y producir errores legibles.
do $$
declare
	v_fuentes integer;
	v_afirmaciones integer;
begin
	select count(distinct afirmacion.fuente_id), count(*)
	into v_fuentes, v_afirmaciones
	from public.afirmaciones_fuentes_metricas afirmacion
	join public.formas_metricas forma on forma.forma_id = afirmacion.forma_id
	where forma.slug in ('sextina', 'sextina_estrofa');

	if v_fuentes <> 6 or v_afirmaciones <> 7 then
		raise exception 'La revisión debe dejar 6 fuentes y 7 afirmaciones, no % y %',
			v_fuentes, v_afirmaciones;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
