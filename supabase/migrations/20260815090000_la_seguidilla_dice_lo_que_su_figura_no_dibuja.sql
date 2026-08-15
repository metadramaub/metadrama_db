-- La seguidilla dice lo que su figura no dibuja
--
-- Segunda poda de la prosa, forma a forma. Las seis descripciones de arquitectura transcribían
-- letra por letra las dos filas de la rejilla —medida y clase de rima— y la definición abría
-- llamando «de arte menor» a una forma cuya gitana alarga el tercer verso hasta doce sílabas y
-- cuya real usa decasílabos. Aquí cada descripción pasa a decir lo que la figura no puede: cuándo
-- se regularizó, quién la inventó, para qué se usaba y qué se le añade por el final.
--
-- Se retiran además diecisiete textos que no llegan a la ficha o que la repiten:
--   * ocho `esquema_metrico_posiciones.nota`: el camino público no lee esa columna en ningún
--     punto —`metricoEntrada` mapea posición, sílabas, alternativa y opcional, nada más—, así
--     que eran texto muerto. Lo único que sostenían, que el endecasílabo es la medida normal
--     del tercer verso de la gitana, pasa a su descripción y a la afirmación del Diccionario.
--   * tres `esquemas_metricos.descripcion`: solo se pintan cuando el esquema tiene repertorio
--     abierto (`esquema_metrico_opciones`), y la seguidilla no tiene ninguno.
--   * la glosa de `-a-ab-b`, que leía en voz alta la notación impresa justo debajo.
--   * tres notas de sección que repetían la línea «Se estructura como Simple» o las columnas
--     de la rejilla. La cuarta se reescribe para dar el nombre tradicional de la parte.
--
-- Entra lo que faltaba: la arquitectura de la serie arromanzada, modelada como el romance
-- —ciclo, notación `[-a-a]…` y enlaces sin nota, para que la ficha derive sola que la asonancia
-- de los pares se conserva—, seis denominaciones, la relación con la endecha real y diez
-- afirmaciones que traen el testimonio localizado que las descripciones ya no llevan.
--
-- Criterio nuevo que gobierna el reparto (regla 9 de `donde-vive-la-prosa`): la descripción no
-- cita y la afirmación no generaliza. Un nombre entra en una descripción solo si es parte del
-- hecho —Sor Juana inventó la real y por eso se llama así—, no si es quien lo atestigua: que
-- Correas la diera por regular a principios del XVII se escribe «ya era regular a principios del
-- XVII», y Correas se va a su afirmación con su localizador.
--
-- Las guardas ejecutan lo que comprueban: cada UPDATE exige encontrar el valor vivo exacto —o el
-- valor nuevo, para que volver a pasarla no falle— y se planta si no cambia el número de filas
-- esperado.

do $$
declare
	v_forma uuid;
	v_endecha uuid;
	v_asonante uuid;
	v_simple uuid;
	v_compuesta uuid;
	v_tres uuid;
	v_chamberga uuid;
	v_gitana uuid;
	v_real uuid;
	v_arromanzada uuid;
	v_em_arromanzada uuid;
	v_er_arromanzada uuid;
	v_heptasilabo uuid;
	v_pentasilabo uuid;
	v_navarro uuid;
	v_diccionario uuid;
	v_jauralde uuid;
	n integer;
begin
	-- 1 · Lo que la migración necesita encontrar tal cual está.

	select forma_id into v_forma from formas_metricas where slug = 'seguidilla';
	if v_forma is null then
		raise exception 'No existe la forma «seguidilla».';
	end if;

	select forma_id into v_endecha from formas_metricas where slug = 'endecha_real';
	if v_endecha is null then
		raise exception 'No existe la forma «endecha_real», destino de la relación.';
	end if;

	select termino_id into v_asonante
	from vocabularios where categoria = 'tipo_rima' and termino = 'asonante';
	if v_asonante is null then
		raise exception 'No existe el término de rima «asonante».';
	end if;

	select metro_id into v_heptasilabo from metros where nombre = 'Heptasílabo';
	select metro_id into v_pentasilabo from metros where nombre = 'Pentasílabo';
	if v_heptasilabo is null or v_pentasilabo is null then
		raise exception 'Faltan los metros heptasílabo o pentasílabo.';
	end if;

	select fuente_id into v_navarro from fuentes_metricas where anio = 1972 and autoria like 'Tomás Navarro%';
	select fuente_id into v_diccionario from fuentes_metricas where anio = 2016;
	select fuente_id into v_jauralde from fuentes_metricas where anio = 2020;
	if v_navarro is null or v_diccionario is null or v_jauralde is null then
		raise exception 'Falta alguna de las tres fuentes citadas (Navarro 1972, Diccionario 2016, Jauralde 2020).';
	end if;

	select arquitectura_id into v_simple from arquitecturas_forma where forma_id = v_forma and slug = 'simple';
	select arquitectura_id into v_compuesta from arquitecturas_forma where forma_id = v_forma and slug = 'compuesta';
	select arquitectura_id into v_tres from arquitecturas_forma where forma_id = v_forma and slug = 'tres_versos';
	select arquitectura_id into v_chamberga from arquitecturas_forma where forma_id = v_forma and slug = 'chamberga';
	select arquitectura_id into v_gitana from arquitecturas_forma where forma_id = v_forma and slug = 'gitana';
	select arquitectura_id into v_real from arquitecturas_forma where forma_id = v_forma and slug = 'real';
	if v_simple is null or v_compuesta is null or v_tres is null
		or v_chamberga is null or v_gitana is null or v_real is null then
		raise exception 'Falta alguna de las seis arquitecturas de la seguidilla.';
	end if;

	-- 2 · La definición. Fuera «de arte menor», que su propia gitana y su propia real desmienten,
	-- fuera «terceto», que en el catálogo es otra forma, y fuera la enumeración de lo que la
	-- ficha lista dos líneas más abajo.

	update formas_metricas set
		definicion = 'De origen popular y uso abundante en el teatro, sobre todo en los entremeses, se construye sobre la alternancia de un verso largo y uno breve: su forma canónica es la cuarteta 7-5-7-5, con los impares sueltos y asonancia en los pares. La medida fluctuó hasta bien entrado el siglo XVII, porque en ella pesa más el ritmo que el cómputo silábico. Puede repetirse como estrofa dentro de una composición, formar ella sola una composición entera o cerrar como estribillo otra escrita en estrofas distintas; sus demás realizaciones prolongan la cuarteta por el final o sustituyen su pareja de medidas.',
		updated_at = now()
	where forma_id = v_forma
		and definicion in (
			'Forma estrófica de arte menor basada en la combinación de versos largos y cortos. La seguidilla simple consta de cuatro versos 7-5-7-5 con asonancia en los pares; la compuesta añade un terceto 5-7-5 con asonancia propia. Se documentan también las variedades de tres versos, chamberga, gitana y real, con distribuciones métricas estables. Históricamente admite fluctuaciones de medida y puede organizarse en series.',
			'De origen popular y uso abundante en el teatro, sobre todo en los entremeses, se construye sobre la alternancia de un verso largo y uno breve: su forma canónica es la cuarteta 7-5-7-5, con los impares sueltos y asonancia en los pares. La medida fluctuó hasta bien entrado el siglo XVII, porque en ella pesa más el ritmo que el cómputo silábico. Puede repetirse como estrofa dentro de una composición, formar ella sola una composición entera o cerrar como estribillo otra escrita en estrofas distintas; sus demás realizaciones prolongan la cuarteta por el final o sustituyen su pareja de medidas.'
		);
	get diagnostics n = row_count;
	if n <> 1 then
		raise exception 'La definición de la seguidilla no tiene el valor esperado (filas afectadas: %).', n;
	end if;

	-- 3 · Las seis descripciones de arquitectura.

	update arquitecturas_forma set
		descripcion = 'La forma canónica, ya regular a principios del siglo XVII y la que el teatro usó con más abundancia, sobre todo en los entremeses. Admite modificaciones que no alteran su arquitectura: la medida fluctúa, la rima puede ser consonante y los impares pueden asonar entre sí.',
		updated_at = now()
	where arquitectura_id = v_simple
		and descripcion in (
			'Cuatro versos 7-5-7-5; los impares quedan sueltos y los pares comparten asonancia.',
			'La forma canónica, ya regular a principios del siglo XVII y la que el teatro usó con más abundancia, sobre todo en los entremeses. Admite modificaciones que no alteran su arquitectura: la medida fluctúa, la rima puede ser consonante y los impares pueden asonar entre sí.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «Simple» no tiene el valor esperado (%).', n; end if;

	update arquitecturas_forma set
		descripcion = 'La cuarteta prolongada con un bordón, que es la variedad de tres versos añadida por el final. Las dos partes quedan separadas por la rima y por el sentido, y el bordón no recoge la asonancia del cuerpo. Se documenta ya en el teatro áureo, aunque su difusión mayor llega a partir del siglo XVIII.',
		updated_at = now()
	where arquitectura_id = v_compuesta
		and descripcion in (
			'Una seguidilla simple seguida de un terceto 5-7-5; cada parte tiene su propia asonancia.',
			'La cuarteta prolongada con un bordón, que es la variedad de tres versos añadida por el final. Las dos partes quedan separadas por la rima y por el sentido, y el bordón no recoge la asonancia del cuerpo. Se documenta ya en el teatro áureo, aunque su difusión mayor llega a partir del siglo XVIII.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «Compuesta» no tiene el valor esperado (%).', n; end if;

	update arquitecturas_forma set
		descripcion = 'La misma pareja de medidas invertida y reducida a tres versos. Fue bastante corriente a principios del siglo XVII, antes que la compuesta, que la incorpora como bordón por el final.',
		updated_at = now()
	where arquitectura_id = v_tres
		and descripcion in (
			'Tres versos 5-7-5 con asonancia entre los pentasílabos extremos.',
			'La misma pareja de medidas invertida y reducida a tres versos. Fue bastante corriente a principios del siglo XVII, antes que la compuesta, que la incorpora como bordón por el final.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «De tres versos» no tiene el valor esperado (%).', n; end if;

	-- El árbol agrupa los tres pareados en una sola banda «×3», así que el dibujo puede dejar
	-- entender que comparten rima. Que cada uno estrene la suya se dice, entonces, en palabras.
	update arquitecturas_forma set
		descripcion = 'La cuarteta alargada con tres pareados de trisílabo y heptasílabo. Cada pareado estrena asonancia, de modo que la estrofa acumula cuatro rimas distintas y ninguna vuelve. Es forma de poesía popular y trata con frecuencia asuntos religiosos.',
		updated_at = now()
	where arquitectura_id = v_chamberga
		and descripcion in (
			'Una seguidilla simple seguida de tres pareados 3-7, cada uno con una asonancia distinta.',
			'La cuarteta alargada con tres pareados de trisílabo y heptasílabo. Cada pareado estrena asonancia, de modo que la estrofa acumula cuatro rimas distintas y ninguna vuelve. Es forma de poesía popular y trata con frecuencia asuntos religiosos.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «Chamberga» no tiene el valor esperado (%).', n; end if;

	-- La casilla de la rejilla imprime «11/10/12» sin jerarquía: cuál es la normal solo cabe
	-- decirlo aquí.
	update arquitecturas_forma set
		descripcion = 'Sustituye la pareja 7-5 por el hexasílabo y alarga el tercer verso, que normalmente es endecasílabo, con cesura tras la quinta sílaba. Es composición popular destinada al canto, ligada al cante flamenco y muy posterior al teatro del Siglo de Oro.',
		updated_at = now()
	where arquitectura_id = v_gitana
		and descripcion in (
			'Cuatro versos 6-6-(10/11/12)-6 con asonancia en el segundo y el cuarto.',
			'Sustituye la pareja 7-5 por el hexasílabo y alarga el tercer verso, que normalmente es endecasílabo, con cesura tras la quinta sílaba. Es composición popular destinada al canto, ligada al cante flamenco y muy posterior al teatro del Siglo de Oro.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «Gitana» no tiene el valor esperado (%).', n; end if;

	update arquitecturas_forma set
		descripcion = 'Combina el decasílabo dactílico —acentuado en tercera, sexta y novena— con el hexasílabo. Es invención de Sor Juana Inés de la Cruz, que le dio el nombre por imitación de la endecha real.',
		updated_at = now()
	where arquitectura_id = v_real
		and descripcion in (
			'Cuatro versos 10-6-10-6 con asonancia en el segundo y el cuarto.',
			'Combina el decasílabo dactílico —acentuado en tercera, sexta y novena— con el hexasílabo. Es invención de Sor Juana Inés de la Cruz, que le dio el nombre por imitación de la endecha real.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La descripción de «Real» no tiene el valor esperado (%).', n; end if;

	-- 4 · Las ocho notas de posición métrica, que ninguna superficie pública lee.

	update esquema_metrico_posiciones p set nota = null, updated_at = now()
	from esquemas_metricos em
	where p.esquema_metrico_id = em.esquema_metrico_id
		and em.arquitectura_id in (v_simple, v_gitana)
		and p.nota in (
			'Primer heptasílabo.',
			'Primer pentasílabo.',
			'Primer hexasílabo.',
			'Medida general del tercer verso.',
			'Alternativa decasílaba del tercer verso.',
			'Alternativa dodecasílaba del tercer verso.'
		);
	get diagnostics n = row_count;
	if n not in (0, 8) then
		raise exception 'Se esperaban 8 notas de posición métrica en la simple y la gitana, y se encontraron %.', n;
	end if;

	-- 5 · Las tres descripciones de esquema métrico, invisibles por no haber repertorio abierto.

	update esquemas_metricos set descripcion = null, updated_at = now()
	where arquitectura_id in (v_compuesta, v_tres, v_chamberga)
		and descripcion in (
			'La seguidilla simple ocupa las posiciones 1-4 y el estribillo 5-7-5 las posiciones 5-7.',
			'Pentasílabos en los extremos y heptasílabo en el centro.',
			'Cuarteta simple seguida de tres pares de trisílabo y heptasílabo.'
		);
	get diagnostics n = row_count;
	if n not in (0, 3) then
		raise exception 'Se esperaban 3 descripciones de esquema métrico, y se encontraron %.', n;
	end if;

	-- 6 · La glosa de `-a-ab-b`, que leía la notación impresa debajo.

	update esquemas_rima set descripcion = null, updated_at = now()
	where arquitectura_id = v_compuesta
		and slug = '-a-ab-b'
		and descripcion = 'El cuerpo presenta -a-a; el estribillo presenta b-b con una asonancia independiente.';
	get diagnostics n = row_count;
	if n not in (0, 1) then
		raise exception 'La glosa de «-a-ab-b» no tiene el valor esperado (%).', n;
	end if;

	-- 7 · Las notas de sección. Tres repetían la línea «Se estructura como Simple» o las columnas
	-- de la rejilla; la del estribillo pasa a dar el nombre que la tradición le da a esa parte.

	update estructuras_secciones set nota = null, updated_at = now()
	where arquitectura_id in (v_compuesta, v_chamberga)
		and nota in (
			'Los cuatro versos de la seguidilla simple, sobre los que se añade el estribillo.',
			'La cuarteta inicial realiza la seguidilla simple.',
			'Cada repetición consta de trisílabo y heptasílabo con una asonancia propia.'
		);
	get diagnostics n = row_count;
	if n not in (0, 3) then
		raise exception 'Se esperaban 3 notas de sección que retirar, y se encontraron %.', n;
	end if;

	update estructuras_secciones set
		nota = 'También llamado **bordón**.',
		updated_at = now()
	where arquitectura_id = v_compuesta
		and slug = 'estribillo'
		and nota in (
			'Tres versos 5-7-5; los pentasílabos extremos comparten una asonancia distinta de la del cuerpo.',
			'También llamado **bordón**.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La nota del estribillo de la compuesta no tiene el valor esperado (%).', n; end if;

	-- 8 · La ayuda del editor de la gitana. Se conserva porque el criterio no está en las
	-- opciones —tres metros sin jerarquía— y gana la cesura, que es el apoyo para contar.

	update grupos_eleccion_metrica set
		ayuda_editor = 'El endecasílabo es la medida normal, con cesura tras la quinta sílaba; el decasílabo y el dodecasílabo, solo cuando esa sea la medida observada.',
		updated_at = now()
	where arquitectura_id = v_gitana
		and slug = 'medida_tercer_verso'
		and ayuda_editor in (
			'El tercer verso suele ser endecasílabo; registra diez o doce sílabas solo cuando esa sea la medida observada.',
			'El endecasílabo es la medida normal, con cesura tras la quinta sílaba; el decasílabo y el dodecasílabo, solo cuando esa sea la medida observada.'
		);
	get diagnostics n = row_count;
	if n <> 1 then raise exception 'La ayuda de «medida_tercer_verso» no tiene el valor esperado (%).', n; end if;

	-- 9 · La serie arromanzada, que tres fuentes registran y el catálogo no tenía. Se modela como
	-- el romance: la unidad es la serie —extensión abierta—, el ciclo son los cuatro versos de la
	-- cuarteta y los enlaces van sin nota para que la ficha derive sola que la asonancia de los
	-- pares vuelve en cada repetición.

	insert into arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, estado_revision, activo, orden, unidad_versos_min, unidad_versos_max
	)
	values (
		v_forma, 'simple_arromanzada', 'Simple arromanzada',
		'Una serie de seguidillas simples que mantiene una misma asonancia en los versos pares de todas las estrofas, en lugar de estrenarla en cada una.',
		false, true, 'admitida', v_asonante, 'revisada', true, 7, null, null
	)
	on conflict (forma_id, slug) do update set
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		modalidad = excluded.modalidad,
		tipo_rima_id = excluded.tipo_rima_id,
		estado_revision = excluded.estado_revision,
		activo = true,
		unidad_versos_min = null,
		unidad_versos_max = null,
		updated_at = now()
	returning arquitectura_id into v_arromanzada;

	insert into esquemas_metricos (arquitectura_id, slug, nombre, tipo_secuencia, estado_revision)
	values (v_arromanzada, '7-5-7-5', '7-5-7-5', 'ciclo', 'revisada')
	on conflict (arquitectura_id, slug) do update set
		nombre = excluded.nombre,
		tipo_secuencia = excluded.tipo_secuencia,
		estado_revision = excluded.estado_revision,
		updated_at = now()
	returning esquema_metrico_id into v_em_arromanzada;

	insert into esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values
		(v_em_arromanzada, 1, v_heptasilabo, 1),
		(v_em_arromanzada, 2, v_pentasilabo, 1),
		(v_em_arromanzada, 3, v_heptasilabo, 1),
		(v_em_arromanzada, 4, v_pentasilabo, 1)
	on conflict (esquema_metrico_id, alternativa, posicion) do update set
		metro_id = excluded.metro_id,
		nota = null,
		updated_at = now();

	insert into esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, estado_revision
	)
	values (
		v_arromanzada, 'asonancia-pares-continua', 'Asonancia continua en los versos pares',
		'[-a-a]…', v_asonante, 'definitoria', 'ciclo', 'revisada'
	)
	on conflict (arquitectura_id, slug) do update set
		nombre = excluded.nombre,
		notacion = excluded.notacion,
		tipo_rima_id = excluded.tipo_rima_id,
		modalidad = excluded.modalidad,
		tipo_secuencia = excluded.tipo_secuencia,
		estado_revision = excluded.estado_revision,
		updated_at = now()
	returning esquema_rima_id into v_er_arromanzada;

	insert into esquema_rima_posiciones (esquema_rima_id, bloque, posicion, ubicacion, clase_rima, suelto)
	values
		(v_er_arromanzada, 1, 1, 'final', null, true),
		(v_er_arromanzada, 1, 2, 'final', 'a', false),
		(v_er_arromanzada, 1, 3, 'final', null, true),
		(v_er_arromanzada, 1, 4, 'final', 'a', false)
	on conflict (esquema_rima_id, bloque, posicion, ubicacion) do update set
		clase_rima = excluded.clase_rima,
		suelto = excluded.suelto,
		nota = null,
		updated_at = now();

	-- Sin nota: la ficha imprime «El verso 2 conserva su rima en cada repetición», y lo mismo del
	-- cuarto. Escribirlo a mano es el caso con el que abre `donde-vive-la-prosa`.
	insert into esquema_rima_enlaces (
		esquema_rima_id, bloque_origen, posicion_origen, desplazamiento_bloque, bloque_destino, posicion_destino
	)
	select v_er_arromanzada, 1, p, 1, 1, p
	from (values (2), (4)) as pares(p)
	where not exists (
		select 1 from esquema_rima_enlaces l
		where l.esquema_rima_id = v_er_arromanzada
			and l.posicion_origen = pares.p
			and l.posicion_destino = pares.p
			and l.desplazamiento_bloque = 1
	);

	select count(*) into n from esquema_rima_enlaces where esquema_rima_id = v_er_arromanzada;
	if n <> 2 then
		raise exception 'La arromanzada debe tener 2 enlaces de ciclo, y tiene %.', n;
	end if;

	-- 10 · Denominaciones. La forma no tenía ninguna y las fuentes dan varias.

	insert into denominaciones_metricas (forma_id, nombre, slug_normalizado, idioma, preferente)
	values
		(v_forma, 'Seguiriya', 'seguiriya', 'es', false),
		(v_forma, 'Bolero', 'bolero', 'es', false)
	on conflict do nothing;

	insert into denominaciones_metricas (arquitectura_id, nombre, slug_normalizado, idioma, preferente)
	values
		(v_gitana, 'Playera', 'playera', 'es', false),
		(v_gitana, 'Flamenca', 'flamenca', 'es', false),
		(v_gitana, 'Seguiriya de plañir', 'seguiriya_de_planir', 'es', false),
		(v_chamberga, 'Chamberga', 'chamberga', 'es', false)
	on conflict do nothing;

	select count(*) into n
	from denominaciones_metricas d
	where d.forma_id = v_forma or d.arquitectura_id in (v_gitana, v_chamberga);
	if n <> 6 then
		raise exception 'Se esperaban 6 denominaciones de la seguidilla, y hay %.', n;
	end if;

	-- 11 · La relación con la endecha real, que explica de dónde viene el nombre de la real.

	insert into forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
	values (
		v_forma, v_endecha, 'relacionada_con',
		'Sor Juana Inés de la Cruz llamó real a su cuarteta de decasílabos dactílicos y hexasílabos por imitación de la endecha real, que combina versos breves con un verso largo final. El parentesco es de nombre y de procedimiento —dos medidas alternadas y una asonancia sostenida en posiciones fijas—, no de estructura: ni las medidas ni el lugar de la asonancia coinciden.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update set
		nota = excluded.nota,
		estado_revision = excluded.estado_revision,
		updated_at = now();

	-- 12 · Las afirmaciones. Traen el testimonio localizado que las descripciones ya no llevan:
	-- el ejemplo de Lope, la advertencia de Correas, el pasaje de Sor Juana, el desacuerdo de
	-- Jauralde con el Diccionario sobre a qué combinación llamar gitana.

	insert into afirmaciones_fuentes_metricas (
		fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza, estado_revision
	)
	select v.fuente_id, v.forma_id, v.arquitectura_id, v.localizador, v.resumen, 'alta', 'revisada'
	from (values
		(v_navarro, v_forma, null::uuid, '§ 216',
			'El teatro hizo abundante uso de la seguidilla, sobre todo en los entremeses. Recoge la definición de Rengifo —dos heptasílabos libres alternando con dos pentasílabos asonantes— y la advertencia de Correas de que esa forma era ya regular desde principios del siglo XVII, aunque los ejemplos fluctuantes siguieron apareciendo: Góngora dio siete sílabas al cuarto verso de «Las flores del romero», y la que canta el mancebito del Quijote consta de 7-6-7-6.'),
		(v_navarro, null::uuid, v_tres, '§ 216',
			'La variedad de tres versos, 5-7-5, fue bastante corriente a principios del siglo XVII, con ejemplo de Lope en Los pastores de Belén: «Callad un poco, que me matan llorando tan dulces ojos». La seguidilla compuesta, que suma la variedad de cuatro versos y la de tres, empezó a divulgarse más tarde.'),
		(v_navarro, null::uuid, v_real, '§ 216',
			'Las coplas de dos villancicos de Sor Juana Inés de la Cruz y de uno de su coetáneo José Pérez de Montoro son cuartetos de decasílabos dactílicos y hexasílabos, 10-6-10-6; Sor Juana les dio el nombre de seguidillas reales.'),
		(v_diccionario, v_forma, null::uuid, 'Entrada «seguidilla»',
			'La seguidilla puede ser la combinación estrófica que en número plural constituye una composición, constituir ella sola una composición, o aparecer como estribillo al final de una escrita en otra clase de estrofas. Junto a la forma canónica recoge como modificaciones más corrientes la fluctuación de la medida, la rima consonante y la rima de los heptasílabos entre sí.'),
		(v_diccionario, null::uuid, v_compuesta, 'Entradas «bordón» y «seguidilla compuesta»',
			'Llama bordón, siguiendo a Rafael Lapesa, al apéndice de tres versos —pentasílabos el primero y el tercero, asonantes entre sí, y heptasílabo suelto el segundo— que se añade a veces a la seguidilla, y registra que la seguidilla con bordón se llama compuesta. Las dos partes quedan separadas por la rima y por el sentido, y la forma se extiende a partir del siglo XVIII.'),
		(v_diccionario, null::uuid, v_gitana, 'Entrada «seguidilla gitana»',
			'El tercer verso es normalmente endecasílabo, con cesura tras la quinta sílaba, aunque también puede tener diez o doce. A veces la estrofa se presenta sin su primer verso. Es composición popular destinada al canto y puede adoptar formas lingüísticas dialectales.'),
		(v_diccionario, null::uuid, v_chamberga, 'Entrada «seguidilla chamberga»',
			'Es forma de poesía popular y trata frecuentemente de asuntos religiosos.'),
		(v_diccionario, null::uuid, v_arromanzada, 'Entrada «seguidilla simple arromanzada»',
			'Recoge de Rudolf Baehr la serie de seguidillas simples que mantienen igual asonancia en los versos pares de las distintas estrofas.'),
		(v_jauralde, null::uuid, v_arromanzada, 'Apartado «Seguidillas»',
			'Sitúa la constitución de la serie arromanzada al menos desde el modernismo, después de las variantes que alargan la cuarteta.'),
		(v_jauralde, null::uuid, v_real, 'Apartado «Seguidillas»',
			'Llama a la combinación 10-6-10-6 seguidilla real, nombre que Sor Juana Inés de la Cruz le dio por imitación de la endecha real, o gitana, en la terminología de Augusto Ferrán. El Diccionario y Navarro Tomás reservan el nombre de gitana para la combinación 6-6-(10/11/12)-6.')
	) as v(fuente_id, forma_id, arquitectura_id, localizador, resumen)
	where not exists (
		select 1 from afirmaciones_fuentes_metricas a
		where a.fuente_id = v.fuente_id
			and a.forma_id is not distinct from v.forma_id
			and a.arquitectura_id is not distinct from v.arquitectura_id
			and a.localizador = v.localizador
	);

	select count(*) into n
	from afirmaciones_fuentes_metricas a
	where a.forma_id = v_forma
		or a.arquitectura_id in (v_simple, v_compuesta, v_tres, v_chamberga, v_gitana, v_real, v_arromanzada);
	if n <> 16 then
		raise exception 'Se esperaban 16 afirmaciones sobre la seguidilla (6 previas + 10 nuevas), y hay %.', n;
	end if;

	-- 13 · La comprobación final: la arquitectura nueva se dibuja como el romance y ninguna de
	-- las siete se queda sin declarar su régimen de rima.

	select count(*) into n
	from arquitecturas_forma a
	where a.forma_id = v_forma and a.activo and a.tipo_rima_id is null
		and not exists (
			select 1 from esquemas_rima er
			where er.arquitectura_id = a.arquitectura_id and er.tipo_rima_id is not null
		);
	if n <> 0 then
		raise exception '% arquitectura(s) de la seguidilla no declaran su régimen de rima.', n;
	end if;

	select count(*) into n from arquitecturas_forma where forma_id = v_forma and activo;
	if n <> 7 then
		raise exception 'La seguidilla debe quedar con 7 arquitecturas activas, y tiene %.', n;
	end if;
end;
$$;
