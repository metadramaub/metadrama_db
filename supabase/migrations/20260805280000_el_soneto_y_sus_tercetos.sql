-- El soneto: definición, descripciones y las seis fuentes.
--
-- Quinta forma de la revisión, 7 secuencias, y la última de las cinco que más pesan.
--
-- Conviene empezar por lo que **no** hay que arreglar, porque a primera vista lo parecía. El
-- soneto declara sus dos secciones —Cuartetos y Tercetos, dos repeticiones cada una— y las
-- dos reutilizan el repertorio de otra forma: la del cuarteto endecasílabo y la del terceto
-- endecasílabo consonante. Y admite `ABAB ABAB` además de `ABBA ABBA`, en un grupo de
-- elección de dos opciones. Nada de eso se ve mirando `esquemas_rima`, porque las secciones
-- cuelgan de la arquitectura y no de `estructuras_forma`. El modelo está bien.
--
-- Lo que sí hay que arreglar:
--
-- 1 · **La definición contradice al modelo.** Dice «dos cuartetos de rima abrazada ABBA ABBA»
--     como si fuera lo único posible, cuando el catálogo registra también `ABAB ABAB` y lo
--     hace con razón: el Diccionario dice que son posibles otras distribuciones, «especialmente
--     la que obedece al esquema ABAB ABAB». La definición pasa a decir cuál es la esperable
--     sin negar la otra. Y termina en «El catálogo reconoce actualmente cuatro esquemas para
--     los tercetos», que habla del catálogo.
--
-- 2 · **«Configuración» sigue viva** en la descripción de la arquitectura, que además acaba
--     en «cuyo esquema se elige entre los patrones reconocidos»: eso describe el formulario.
--
-- 3 · **Las cuatro descripciones de rima repiten la definición y su propia notación.** Las
--     cuatro empiezan «Dos cuartetos ABBA ABBA y dos tercetos…» —que es la forma entera, no
--     lo que distingue a ese esquema— y una remata con «Se conserva como patrón preferente por
--     su denominación heredada «regular»», que cuenta la migración. Pasan a decir lo único
--     que las separa: cómo se entrelazan las rimas de un terceto con las del otro.
--
-- 4 · **Una nota de sección habla del formulario**: «El esquema de rima no se declara aquí
--     porque entrelaza los dos: se pregunta una vez por unidad». La primera mitad es la razón
--     buena y se queda; la segunda sobra.
--
-- Y una precisión de método que las fuentes obligan a registrar: **«cruzada», «nuclear»,
-- «paralela» y «conclusiva» no salen de la bibliografía**. Ninguna de las seis monografías
-- usa esos nombres para los tercetos; son acuñación del proyecto, y son útiles porque dicen
-- algo del entrelazado que `CDCEDE` no dice a simple vista. Pero quien venga de Morley y
-- Bruerton los busca como tipos A, B, C y D, así que la correspondencia se escribe como
-- afirmación en vez de dejarla implícita.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'soneto';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if v_forma is null or v_arq is null then
		raise exception 'Falta el soneto o su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- 1 · La definición dice lo esperable sin negar lo registrado.
	update public.formas_metricas
	set definicion = 'Composición fija de catorce versos endecasílabos con rima consonante, repartida en dos cuartetos y dos tercetos. Los ocho primeros versos llevan dos clases de rima, abrazadas —ABBA ABBA— en la disposición esperable, aunque también se documenta la cruzada. Los seis últimos llevan dos o tres clases distintas de las anteriores, y su disposición varía: es la única parte del soneto que no está fijada de antemano.'
	where forma_id = v_forma;

	-- 2 · La arquitectura dice qué es, no cómo se rellena un formulario.
	update public.arquitecturas_forma
	set descripcion = 'Catorce endecasílabos consonantes: dos cuartetos que reutilizan el repertorio del cuarteto endecasílabo y dos tercetos que reutilizan el del terceto endecasílabo consonante.'
	where arquitectura_id = v_arq;

	-- 3 · Cada esquema dice lo único que lo separa de sus hermanos.
	update public.esquemas_rima
	set descripcion = case notacion
		when 'CDCDCD' then
			'Los dos tercetos alternan las mismas dos clases de rima, sin tercera: leído en tercetos es CDC y DCD. Era la disposición favorita de Petrarca.'
		when 'CDECDE' then
			'El segundo terceto repite el orden del primero con las mismas tres clases: CDE y CDE. Es la disposición del soneto clásico de Garcilaso.'
		when 'CDEDCE' then
			'Tres clases de rima cuyo orden se invierte en el segundo terceto: CDE y DCE.'
		when 'CDCEDE' then
			'La primera clase enmarca el primer terceto y las otras dos se emparejan en el segundo: CDC y EDE.'
		else descripcion
	end
	where arquitectura_id = v_arq;

	-- 4 · La nota de la sección da la razón y se calla el formulario.
	update public.estructuras_secciones
	set nota = 'El esquema de rima no se declara en la sección porque entrelaza los dos tercetos: lo que distingue a las cuatro disposiciones es precisamente cómo se responden entre sí, y eso no cabe en tres versos.'
	where arquitectura_id = v_arq and slug = 'terceto';

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- La tipología sobre la que se data a Lope, y cómo leer sus nombres aquí.
		(v_mb, v_forma, 'Cap. V, «Soneto»',
			'Describen los ocho primeros versos como de **rígido orden** ABBAABBA y solo variable el sexteto, del que dan cuatro tipos que son los cuatro del catálogo: A es CDCDCD, B es CDECDE, C es CDEDCE y D es CDCEDE. Advierten que hay otros, y remiten al estudio de Dorothy C. Clarke sobre las rimas de los tercetos en el soneto áureo. Los nombres que aquí llevan —cruzada, paralela, conclusiva y nuclear— son del proyecto y no de la bibliografía.',
			'alta'),

		-- Hasta dónde llega la forma fuera de este corpus, y la regla que gobierna los tercetos.
		(v_dicc, v_forma, 'Entrada «soneto», p. 409',
			'Define el soneto como poema de catorce versos de arte mayor, endecasílabos **en su forma clásica**, de modo que la medida no es parte de la definición sino de la realización. Sobre los cuartetos precisa que ABBA ABBA es lo normal pero que son posibles otras distribuciones, «especialmente la que obedece al esquema ABAB ABAB». Y sobre los tercetos da la regla que genera las disposiciones posibles: dos o tres clases distintas de las de los cuartetos, repartidas como sea **con tal de que no haya más de dos versos seguidos con la misma rima**.',
			'alta'),

		-- Los nombres antiguos de las dos partes.
		(v_dicc, v_forma, 'Entrada «soneto», p. 409',
			'Recoge que Juan Díaz Rengifo dividía el soneto en **pies** —los versos de los dos cuartetos— y **vueltas** —los dos tercetos—.',
			'alta'),

		-- Cuántas partes son, y de dónde vino la forma.
		(v_quilis, v_forma, 'p. 132',
			'Lo describe como poema de catorce versos divididos en **cuatro estrofas**: dos cuartetos y dos tercetos sucesivamente. Da como esquema clásico ABBA-ABBA-CDC-DCD y señala que esa disposición de los tercetos era la favorita de Petrarca, aunque se usaron también CDE-CDE, CDE-DCE y otras. Añade que en el Barroco alcanza el soneto su mayor auge.',
			'alta'),

		-- Quién lo introdujo de verdad.
		(v_jauralde, v_forma, '«Estrofas» → «Soneto»',
			'Sitúa su entrada con el endecasílabo desde Italia en el primer Renacimiento, y precisa que Imperial y Santillana lo cultivaron en el siglo XV con un tono marcadamente medieval que los relegó a antiguallas cuando Boscán y Garcilaso compusieron los suyos. Da como forma clásica ABBA ABBA **CDE DCE**, donde Quilis da CDC-DCD: las dos son disposiciones del catálogo, y que dos manuales elijan distinta «clásica» mide lo poco fijado que está el sexteto.',
			'alta'),

		-- El primer intento, y por qué no cuajó.
		(v_navarro, v_forma, '§ 107',
			'Estudia los sonetos del Marqués de Santillana como primer intento de aclimatación, anterior en un siglo al éxito de la forma. Que ese intento no tuviera continuidad es lo que hace de Boscán y Garcilaso los introductores efectivos.',
			'alta'),

		-- Lo que el soneto exige además de su esquema.
		(v_cap14, v_forma, 'p. 218',
			'Repite la definición del Diccionario y añade una condición que no es métrica sino de composición: el soneto **debe tener unidad temática y un desarrollo completo**.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Soneto · definición, arquitectura, 4 esquemas de rima, 1 nota y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
