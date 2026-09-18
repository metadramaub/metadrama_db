-- El romance son tres formas: romance, romance heroico y romancillo
--
-- «Romance» era una forma con seis arquitecturas por medida —octosílabo, endecasílabo y cuatro
-- de arte menor— y una definición que decía que el octosílabo es la realización no marcada y que
-- «las demás medidas reciben nombre propio». Ese nombre propio es lo que las fuentes tratan como
-- forma: las seis distinguen romance, romance heroico y romancillo, cada uno con su historia, y el
-- vocabulario legado también los separaba (`romance`, `romance_heroico`, `romancillo`). Decidido
-- con David el 18 de septiembre de 2026, a la manera de la canción:
--
--   · **Romance** (`romance`, conserva slug, URL y término legado) se queda con el octosílabo.
--   · **Romance heroico** (`romance_heroico`, nuevo) recibe el endecasílabo. El más tardío de los
--     romances —segunda mitad del XVII— y el único de arte mayor; la tragedia neoclásica lo hizo
--     suyo. Sus denominaciones «Romance endecasílabo», «Romance real» y «Romance mayor» suben de
--     la arquitectura a la forma.
--   · **Romancillo** (`romancillo`, nuevo) recibe las cuatro medidas menores, el tetrasílabo
--     incluido: el *Diccionario* dice «menos de ocho sílabas» y Jauralde lo nombra. Principal y
--     habitual el **hexasílabo**, que Navarro Tomás da por «mucho más corriente» y con «papel
--     importante en el teatro»; el heptasílabo deja de ser «el romancillo por antonomasia».
--   · Las tres se emparentan con `derivada_de`, no con `subtipo_de`: comparten el esquema `[-a]…`
--     y el auditor (D8) tomaría por copia lo que es la misma figura en tres medidas.
--
-- Viajan con su arquitectura, sin tocar nada más, las anotaciones: 83 octosílabas se quedan, y
-- pasan al romancillo las cinco de arte menor, **dos de ellas reales** —*Adonis y Venus* y *El
-- burlador de Sevilla*, heptasílabas—. Se comprueban antes y después.
--
-- El razonamiento con las fuentes: docs/dominio-metrico/historico/cancion-y-liras-2026-09-17.md
-- (apartado del romance).

begin;

do $$
declare
	v_romance uuid;
	v_heroico uuid;
	v_romancillo uuid;
	v_suelto uuid;
	v_endecha_real uuid;
	v_arq_octo uuid;
	v_arq_endeca uuid;
	v_arq_hexa uuid;
	v_arq_hepta uuid;
	v_termino_heroico uuid;
	v_termino_romancillo uuid;
	v_espanola constant uuid := 'bf56b9c7-1261-41db-8a0c-d82529f88dd3';
	v_mb constant uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis constant uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro constant uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_capar constant uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dicc constant uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jaur constant uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_menores_reales integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- ══════════════════════════════════════════════════════════ Lo que tiene que estar
	select forma_id into v_romance from public.formas_metricas where slug = 'romance' and activo;
	select forma_id into v_suelto from public.formas_metricas where slug = 'endecasilabo_suelto' and activo;
	select forma_id into v_endecha_real from public.formas_metricas where slug = 'endecha_real' and activo;
	if v_romance is null or v_suelto is null or v_endecha_real is null then
		raise exception 'Falta el romance, el endecasílabo suelto o la endecha real.';
	end if;
	if exists (select 1 from public.formas_metricas where slug in ('romance_heroico', 'romancillo')) then
		raise exception 'Ya existe «romance_heroico» o «romancillo».';
	end if;
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_romance and activo;
	if v_n <> 6 then
		raise exception 'El romance debía tener seis arquitecturas activas y tiene %.', v_n;
	end if;
	select arquitectura_id into v_arq_octo from public.arquitecturas_forma where forma_id = v_romance and slug = 'octosilabica' and principal;
	select arquitectura_id, origen_termino_id into v_arq_endeca, v_termino_heroico from public.arquitecturas_forma where forma_id = v_romance and slug = 'endecasilabica';
	select arquitectura_id into v_arq_hexa from public.arquitecturas_forma where forma_id = v_romance and slug = 'hexasilabica';
	select arquitectura_id into v_arq_hepta from public.arquitecturas_forma where forma_id = v_romance and slug = 'heptasilabica';
	if v_arq_octo is null or v_arq_endeca is null or v_arq_hexa is null or v_arq_hepta is null then
		raise exception 'Faltan arquitecturas del romance por su slug.';
	end if;
	select termino_id into v_termino_romancillo from public.vocabularios where termino = 'romancillo';
	if v_termino_heroico is null or v_termino_romancillo is null
		or (select termino from public.vocabularios where termino_id = v_termino_heroico) <> 'romance_heroico' then
		raise exception 'Los términos legados «romance_heroico» y «romancillo» no están donde se esperaba.';
	end if;
	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_romance) <> 7 then
		raise exception 'El romance debía tener siete afirmaciones.';
	end if;
	-- Las anotaciones reales de arte menor: dos, heptasílabas.
	select count(*) into v_menores_reales
	from public.anotaciones_metricas am
	join public.arquitecturas_forma a on a.arquitectura_id = am.arquitectura_id
	join public.secuencias_metricas s on s.secuencia_id = am.secuencia_id
	join public.obras o on o.obra_id = s.obra_id
	where a.forma_id = v_romance and a.slug in ('heptasilabica', 'hexasilabica', 'pentasilabica', 'tetrasilabica')
		and o.titulo not ilike '%(prueba)%';
	if v_menores_reales <> 2 then
		raise exception 'Se esperaban 2 anotaciones reales de romancillo y hay %: mirarlas antes de mover nada.', v_menores_reales;
	end if;
	if exists (select 1 from public.anotaciones_metricas where arquitectura_id = v_arq_endeca) then
		raise exception 'El endecasílabo tiene anotaciones y esta migración lo daba por vacío.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ══════════════════════════════════════════════════════════ Las formas nuevas
	insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
	values (
		'romance_heroico', 'Romance heroico',
		$p$Serie de endecasílabos en la que los pares comparten una misma asonancia y los impares quedan sueltos: el romance llevado al verso de arte mayor. Es el más tardío de los romances —sus primeras muestras son de la segunda mitad del siglo XVII, en sor Juana Inés de la Cruz y en los poetas satíricos— y el teatro neoclásico lo adoptó para la tragedia, de donde pasó a la épica y al canto grave del siglo XIX. Se distingue del endecasílabo suelto solo por la asonancia sostenida de los pares: sin ella, la serie es suelta y no romance.$p$,
		'serie', 'forma', true
	) returning forma_id into v_heroico;

	insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
	values (
		'romancillo', 'Romancillo',
		$p$Romance en versos de menos de ocho sílabas: la misma serie de impares sueltos y una sola asonancia en los pares, en heptasílabos, hexasílabos, pentasílabos o tetrasílabos. El hexasílabo y el heptasílabo son los del Siglo de Oro: el hexasílabo, en romancillos líricos y satíricos, letrillas y villancicos, y con papel propio en el teatro; el heptasílabo, en las anacreónticas y en las barquillas de Lope. El pentasílabo llega con las fábulas del siglo XVIII y el tetrasílabo con el Modernismo. Cuando el asunto es luctuoso recibe el nombre de endecha, que apunta al tema antes que a la medida, aunque algunos tratados reservan «endecha» al heptasílabo y limitan «romancillo» al hexasílabo y a los menores.$p$,
		'serie', 'forma', true
	) returning forma_id into v_romancillo;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_heroico, v_espanola), (v_romancillo, v_espanola);

	update public.formas_metricas
	set definicion = $p$Serie de octosílabos en la que los pares comparten una misma asonancia y los impares quedan sueltos. Esa asonancia es única y no cambia: es lo que mantiene unida la serie, y un romance acaba justamente donde empieza otra. Nació como verso largo de dieciséis sílabas partido en dos hemistiquios, que los cancioneros del siglo XV empezaron a copiar como octosílabos; en esa figura se regularizó en el XVI, pasó a la poesía culta y se hizo, con la redondilla y la décima, uno de los moldes del diálogo de la comedia. El sentido suele partirlo en grupos de cuatro versos, y admite estribillos o canciones intercalados. Es la medida no marcada del romance: «romance» a secas es el octosílabo, y la misma serie en versos más cortos o en endecasílabos recibe nombre propio.$p$
	where forma_id = v_romance;

	-- ══════════════════════════════════════════════════════════ Las arquitecturas se reparten
	-- El término legado del heroico sube de la arquitectura a la forma (es único en las dos).
	update public.arquitecturas_forma set origen_termino_id = null where arquitectura_id = v_arq_endeca;
	update public.formas_metricas set origen_termino_id = v_termino_heroico where forma_id = v_heroico;
	update public.formas_metricas set origen_termino_id = v_termino_romancillo where forma_id = v_romancillo;

	update public.arquitecturas_forma
	set forma_id = v_heroico, principal = true, modalidad = 'habitual', orden = 1,
		descripcion = $p$Endecasílabos en serie con asonancia en los pares; solo se elige la asonancia.$p$
	where arquitectura_id = v_arq_endeca;

	update public.arquitecturas_forma
	set forma_id = v_romancillo, principal = true, modalidad = 'habitual', orden = 1,
		descripcion = $p$El romancillo del teatro y de la poesía tradicional: villancicos, letrillas, endechas y romances de tema sentimental.$p$
	where arquitectura_id = v_arq_hexa;
	update public.arquitecturas_forma
	set forma_id = v_romancillo, principal = false, orden = 2,
		descripcion = $p$El de las endechas y anacreónticas del Siglo de Oro. Cuando el asunto es luctuoso recibe el nombre de endecha, que apunta al tema antes que a la medida.$p$
	where arquitectura_id = v_arq_hepta;
	update public.arquitecturas_forma set forma_id = v_romancillo, orden = 3
	where forma_id = v_romance and slug = 'pentasilabica';
	update public.arquitecturas_forma set forma_id = v_romancillo, orden = 4
	where forma_id = v_romance and slug = 'tetrasilabica';

	update public.arquitecturas_forma
	set descripcion = $p$Octosílabos en serie con asonancia en los pares. La medida es fija y la asonancia se elige: es lo único que la norma deja abierto.$p$
	where arquitectura_id = v_arq_octo;

	-- Las anotaciones, después de las arquitecturas: el disparador exige que casen.
	update public.anotaciones_metricas am
	set forma_id = a.forma_id
	from public.arquitecturas_forma a
	where a.arquitectura_id = am.arquitectura_id and am.forma_id = v_romance and a.forma_id <> v_romance;

	-- ══════════════════════════════════════════════════════════ Denominaciones
	delete from public.denominaciones_metricas
	where arquitectura_id = v_arq_endeca and slug_normalizado = 'romance_heroico';
	update public.denominaciones_metricas
	set arquitectura_id = null, forma_id = v_heroico, fuente_id = v_dicc
	where arquitectura_id = v_arq_endeca and slug_normalizado in ('romance_real', 'romance_mayor');
	insert into public.denominaciones_metricas (forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values
		(v_heroico, 'Romance endecasílabo', 'romance_endecasilabo', false, v_dicc),
		(v_romancillo, 'Romance corto', 'romance_corto', false, v_dicc),
		(v_romancillo, 'Romance menor', 'romance_menor', false, v_dicc);

	-- ══════════════════════════════════════════════════════════ Relaciones
	update public.forma_relaciones set forma_destino_id = v_romancillo
	where forma_origen_id = v_endecha_real and forma_destino_id = v_romance and tipo_relacion = 'derivada_de';

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values
	(v_heroico, v_romance, 'derivada_de',
		$p$El romance en endecasílabos: la misma serie de pares asonantados e impares sueltos, en el verso de arte mayor. Es el más tardío de los romances y el único de arte mayor, y donde el octosílabo se lee de corrido, el endecasílabo asonantado tiende a la gravedad, por lo que la tragedia neoclásica lo hizo suyo.$p$),
	(v_romancillo, v_romance, 'derivada_de',
		$p$El romance en versos de menos de ocho sílabas. Es la misma serie —impares sueltos, una sola asonancia en los pares— y todo lo que vale para el romance vale para el romancillo: la partición en cuartetas, el estribillo intercalado. Solo cambia la medida, y con ella el nombre.$p$),
	(v_heroico, v_suelto, 'contrasta_con',
		$p$Las dos son series de endecasílabos, y lo único que las separa es la asonancia de los pares: sostenida en el romance heroico, ausente en el suelto. Cuando el suelto admite rimas ocasionales, el límite lo pone que la asonancia no sea sistemática ni la misma en toda la serie.$p$);

	-- ══════════════════════════════════════════════════════════ Afirmaciones
	update public.afirmaciones_fuentes_metricas
	set resumen = $p$Definen el romance como «octosílabos en tiradas de duración indeterminada, con la misma asonancia en los versos pares», y anotan que la misma forma en otras medidas cambia de nombre: romancillo o endechas en seis o siete sílabas, romance heroico o romance real en once.$p$
	where forma_id = v_romance and fuente_id = v_mb;
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_romance and fuente_id = v_jaur;

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	values
	(v_dicc, v_heroico, 'Entradas «romance heroico», p. 369, y «romance mayor», p. 369',
		$p$Lo define como «romance en versos endecasílabos», con «romance endecasílabo» y «romance real» como otros términos, y llama «romance mayor» a todo romance «en versos de más de ocho sílabas». Recoge la opinión desfavorable de Menéndez Pelayo sobre esta combinación —«peligro de prosaísmo, verbosidad y facilidad desaliñada»— y la de Díez Echarri, que la juzga apropiada para obras dramáticas de cierta índole, «especialmente la tragedia de corte clásico».$p$, 'alta'),
	(v_navarro, v_heroico, '§§ 169 y 298',
		$p$Sitúa en la segunda mitad del siglo XVII «las primeras manifestaciones del romance endecasílabo», que significaba «el paso más definitivo del metro italiano para compenetrarse con la tradición castellana»: una composición de Fernando de Valenzuela en elogio de san Juan de Dios y varias poesías de sor Juana Inés de la Cruz. En el Romanticismo «mantuvo en las tragedias el papel que el teatro neoclásico le había asignado»; lo adoptó el duque de Rivas en *El moro expósito*, Espronceda en *Despedida del patriota griego* y Zorrilla en numerosas poesías.$p$, 'alta'),
	(v_jaur, v_heroico, 'Apartado «El romance y el romancillo»',
		$p$«Se denomina romance heroico al que se desarrolla con endecasílabos: no aparece más que tardíamente en nuestra historia literaria (segunda mitad del siglo XVII, con ejemplos sueltos anteriores, como los de Pellicer en el *Argenis*; lo cultivaron los poetas satíricos del siglo XVII y sor Juana Inés de la Cruz)», y los neoclásicos lo acogen «como forma apropiada para el teatro, la épica, el canto grave». Bécquer lo quiebra con heptasílabos, acercándolo a la silva, y en versos blancos «se ha convertido en la más socorrida de la poesía contemporánea».$p$, 'alta'),
	(v_quilis, v_heroico, '§ 6.4.1, pp. 162-163',
		$p$«Cuando el romance se construye con versos de once sílabas recibe el nombre de romance heroico, que no ha sido muy frecuente en nuestra métrica»; lo ejemplifica con el duque de Rivas.$p$, 'alta'),
	(v_capar, v_heroico, 'p. 226',
		$p$«El romance en versos de once sílabas se llama romance heroico», y lo ejemplifica con «Vésper», de *El canto errante* de Rubén Darío.$p$, 'alta'),
	(v_mb, v_heroico, 'Cap. V, «Romance», p. 39',
		$p$Al definir el romance anotan que el verso asonantado «con once sílabas» se llama «romance heroico o romance real».$p$, 'alta'),
	(v_dicc, v_romancillo, 'Entradas «romancillo», p. 370, y «endecha», p. 148',
		$p$Define el romancillo como «romance en versos de menos de ocho sílabas», con «romance corto» y «romance menor» como otros términos, y recoge un segundo sentido, de Rafael Lapesa, que lo restringe a «versos hexasílabos o menores». Lo ejemplifica con un romancillo pentasílabo de Tomás de Iriarte y añade que «es romancillo también la endecha», forma «empleada en endechas y anacreónticas». La endecha es «poema de asunto triste cuya forma métrica es la de un romancillo de versos de siete sílabas generalmente, pero que admite también los versos de cinco o de seis sílabas», y como el nombre se refiere al asunto, «es posible encontrar endechas en otras formas métricas».$p$, 'alta'),
	(v_quilis, v_romancillo, '§ 6.4.1, p. 162, y § 3.5.1.4, p. 52',
		$p$«Cuando el romance tiene menos de ocho sílabas recibe los nombres de: a) endecha, si los versos constan de siete sílabas, y b) romancillo, si tienen menos de siete»; ejemplifica el heptasílabo con García Lorca y el hexasílabo con la «Hermana Marica» de Góngora. Del hexasílabo dice que «es muy frecuente en los romancillos, villancicos y endechas», y que los poetas del Barroco «lo adoptan en la composición de sus romancillos».$p$, 'alta'),
	(v_capar, v_romancillo, 'p. 226',
		$p$«Si el romance está en versos de menos de siete sílabas, se llama romancillo», y lo ejemplifica con el tetrasílabo de las *Rimas* de Rubén Darío.$p$, 'alta'),
	(v_jaur, v_romancillo, 'Apartado «El romance y el romancillo»',
		$p$«Se denominan romancillos las composiciones semejantes que utilizan versos menores, esto es, heptasílabos, hexasílabos, pentasílabos, tetrasílabos... Todo lo que diremos para el romance se acomoda fácilmente a los romancillos (en semiestrofas, con estribillo, etc.)». Entre las variantes del romance que trajeron los cancioneros y los poetas cultos, «el romancillo hexasilábico es la primera y más importante». La endecha es para él un romancillo heptasílabo, a veces hexasílabo o pentasílabo, «al que se añade su tema triste».$p$, 'alta'),
	(v_navarro, v_romancillo, '§§ 205 y 208',
		$p$Del heptasílabo: Góngora lo adoptó en un romancillo aconsonantado sobre la muerte de doña Luisa de Cardona (1594) y en dos romancillos asonantes con estribillo, y el metro alcanzó su mayor prestigio lírico con las anacreónticas de Villegas y «los delicados romancillos de Lope que recibieron el nombre de barquillas». Del hexasílabo: se empleó «en villancicos, letrillas, endechas y romances»; «mucho más corriente fue el uso del hexasílabo en romancillos líricos y satíricos, profanos y sagrados. Con este carácter desempeñó papel importante en el teatro», y «el romance hexasílabo de tema sentimental y melancólico continuó siendo la forma más frecuente de la endecha».$p$, 'alta'),
	(v_mb, v_romancillo, 'Cap. V, «Romance», p. 39',
		$p$Al definir el romance anotan que el verso asonantado «de seis o siete sílabas» se llama «romancillo o endechas».$p$, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones, ejecutando lo que se toca
	if (select count(*) from public.arquitecturas_forma where forma_id = v_romance and activo) <> 1
		or (select count(*) from public.arquitecturas_forma where forma_id = v_heroico and activo and principal) <> 1
		or (select count(*) from public.arquitecturas_forma where forma_id = v_romancillo and activo) <> 4
		or (select count(*) from public.arquitecturas_forma where forma_id = v_romancillo and principal) <> 1 then
		raise exception 'El reparto de arquitecturas no quedó como se esperaba.';
	end if;
	if exists (
		select 1 from public.anotaciones_metricas am
		join public.arquitecturas_forma a on a.arquitectura_id = am.arquitectura_id
		where am.forma_id <> a.forma_id and a.forma_id in (v_romance, v_heroico, v_romancillo)
	) then
		raise exception 'Alguna anotación no cambió de forma con su arquitectura.';
	end if;
	select count(*) into v_n
	from public.anotaciones_metricas am
	join public.secuencias_metricas s on s.secuencia_id = am.secuencia_id
	join public.obras o on o.obra_id = s.obra_id
	where am.forma_id = v_romancillo and o.titulo not ilike '%(prueba)%';
	if v_n <> 2 then
		raise exception 'El romancillo debía quedarse con las 2 anotaciones reales y tiene %.', v_n;
	end if;
	-- Cada anotación movida se reescribe a sí misma: pasa por su disparador.
	update public.anotaciones_metricas set forma_id = forma_id where forma_id in (v_heroico, v_romancillo);

	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_romance) <> 6
		or (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_heroico) <> 6
		or (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_romancillo) <> 6 then
		raise exception 'Las afirmaciones no quedaron 6 / 6 / 6.';
	end if;
	if (select forma_destino_id from public.forma_relaciones where forma_origen_id = v_endecha_real and tipo_relacion = 'derivada_de') <> v_romancillo then
		raise exception 'La endecha real no deriva ya del romancillo.';
	end if;
	if exists (select 1 from public.denominaciones_metricas where arquitectura_id = v_arq_endeca) then
		raise exception 'El endecasílabo conserva denominaciones que debían subir a la forma.';
	end if;

	perform public.get_forma_metrica_publica_jerarquica('romance');
	perform public.get_forma_metrica_publica_jerarquica('romance_heroico');
	perform public.get_forma_metrica_publica_jerarquica('romancillo');
	perform public.get_forma_metrica_publica_jerarquica('endecha_real');
	perform public.get_forma_metrica_publica_jerarquica('endecasilabo_suelto');
	perform public.obtener_catalogo_demarcador();

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % -> %', v_antes, v_despues;
	end if;

	raise notice 'Romance (%), Romance heroico (%) y Romancillo (%): revisión % -> %.',
		v_romance, v_heroico, v_romancillo, v_antes, v_despues;
end $$;

commit;
