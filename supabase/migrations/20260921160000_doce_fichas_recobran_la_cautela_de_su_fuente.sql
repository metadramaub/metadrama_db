-- Trece fichas recobran la cautela con que su fuente lo dijo
--
-- Segunda tanda de la pasada D. Diecisiete cláusulas quedaron marcadas porque **la fuente matiza y
-- la ficha no**, y se reparten en doce fichas. La decimotercera la encontró una guarda.
--
-- **Nueve de las trece son de Jauralde Pou**, y no parece casualidad: es el más cauto de los seis
-- —matiza sin parar— y es también de quien más parafrasean nuestras fichas. Donde más reservas pone
-- un autor es donde más se pierden al resumirlo.
--
-- ══ La que afirma un silencio falso
--
-- `a5faa793` decía que la fuente recoge `abbba` entre las disposiciones de la quintilla octosilábica
-- **«sin marcarla como anómala»**. Unas páginas más abajo, bajo «Quintilla octosilábica», Jauralde
-- escribe que «es escasa la combinación abbba […] frente a la mayoritaria ababa». No es que la ficha
-- omitiera el matiz: **declaraba que no existía**. De las 54 cláusulas que la pasada marcó, es la
-- única que afirma un silencio que la fuente desmiente.
--
-- ══ La que pone dos fichas de acuerdo con el IP
--
-- `299adc4b` decía que Jauralde enumera la serie alirada hasta el octeto-lira **y se detiene ahí,
-- porque a partir de esa extensión la llama de otra manera**. El libro lo desmiente unas líneas
-- antes: «no es difícil encontrar […] extensiones de la lira que alcanzan y aun superan la octava».
-- Esa ficha era la que sostenía la fila de Jauralde en la tabla de las seis fuentes de
-- `cuestiones-para-el-ip.md`, rehecha ayer: **esto la pone de acuerdo con ella**.
--
-- **Y tenía una gemela que nadie había visto.** `ba3902d5`, la novena-lira, lleva **el mismo
-- resumen palabra por palabra** y el mismo localizador. La pasada D la leyó también —iba en otro
-- lote— y **aquel verificador no marcó la cláusula**, mientras el de la décima-lira sí: la pasada se
-- contradice a sí misma entre dos fichas idénticas. La cogió la guarda que exige que la frase no
-- quede en ninguna, al fallar la primera vez que se intentó aplicar esta migración.
--
-- ══ Lo que se recobra en las demás
--
--   `cf2dcb07`  las dos cosas que la ficha daba por fijas van matizadas, y las dos son
--               estructurales: la estancia es de «no menos de nueve ni más de veinte,
--               **normalmente**», y el esquema de fronte, eslabón y sirima va precedido de «**aunque
--               no es obligatorio**, es frecuente». La arquitectura del catálogo declara ese esquema
--               como estructura de la estancia, y la fuente dice que no obliga.
--   `a691813f`  Jauralde abre con «**con todo tipo de salvedades y reservas**» la frase que reparte
--   `de48e693`  los siglos entre las dos coplas, y **dos fichas publicaban ese reparto como
--               afirmación firme**. Cinco cláusulas entre las dos.
--   `e2cb5403`  «explica por qué» donde Navarro escribe «respondía **probablemente** al propósito
--               de». Entra además la primera mitad de ese propósito, que la ficha se saltaba.
--   `e20a8b27`  la novena es «abundante en los cancioneros del siglo XV» y, a pocas líneas,
--               «**minoritaria** frente a sus hermanas la copla de arte menor y la castellana».
--   `19fc8274`  las estrofas agudas decayeron en el Modernismo «**aunque todavía hay octavillas
--               agudas en Amado Nervo o Manuel Machado**».
--   `8b5581b0`  `abaab` se da como lo que la quintilla de la oncena «**puede ser**» en el ejemplo de
--               Costana, no como su esquema; y los otros dos autores son un «hay muchos más».
--   `bdac1b06`  de la vuelta riman con la cabeza los demás versos «**o al menos el último**».
--   `b2e4dfe5`  el repertorio juglaresco y la *Historia Troyana* llevan un «**como tal
--               probablemente**» que la ficha convertía en constancia.
--   `ac2eb17b`  «la que llama seguidilla real» dejaba sin sujeto un nombre que no es de Jauralde:
--               **«real» es de sor Juana Inés de la Cruz y «gitana» de Augusto Ferrán**, y la ficha
--               nombraba solo al segundo.
--
-- Textos aprobados por David uno a uno el 21 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 13;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_cautelas_d (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_cautelas_d (id8, antes, despues)
	values
		('19fc8274', 'La fecha con precisión: «durante el siglo XVIII se incorpora al repertorio la octavilla aguda, en variedades octosilábicas, heptasilábicas y pentasilábicas sobre todo: los finales de cada semiestrofa (versos 4.º y 8.º) riman en aguda entre sí». Añade que «la modalidad aguda se extendió a otras muchas variedades estróficas, como la sextilla y la décima», y también a estrofas de arte mayor. Ejemplifica la octosilábica con *El reo de muerte* de Espronceda, que llama «octavilla de octosílabos o copla castellana aguda», y la heptasilábica con *La orgía* de Zorrilla. Señala que las estrofas agudas decayeron en el Modernismo.', 'La fecha con precisión: «durante el siglo XVIII se incorpora al repertorio la octavilla aguda, en variedades octosilábicas, heptasilábicas y pentasilábicas sobre todo: los finales de cada semiestrofa (versos 4.º y 8.º) riman en aguda entre sí». Añade que «la modalidad aguda se extendió a otras muchas variedades estróficas, como la sextilla y la décima», y también a estrofas de arte mayor. Ejemplifica la octosilábica con *El reo de muerte* de Espronceda, que llama «octavilla de octosílabos o copla castellana aguda», y la heptasilábica con *La orgía* de Zorrilla. Señala que las estrofas agudas, «tan típicas del Romanticismo», decayeron en el periodo modernista, «**aunque todavía hay octavillas agudas en Amado Nervo o Manuel Machado**».'),
		('299adc4b', 'No la registra. Enumera la serie alirada desde el cuarteto hasta el octeto-lira y se detiene ahí, porque a partir de esa extensión la llama de otra manera: define la estancia como estrofa de siete y once sílabas dispuestos de modo aleatorio, «normalmente por encima de los ocho versos (para diferenciarla de las liras)».', 'No la registra. Enumera la serie alirada desde el cuarteto hasta el octeto-lira y define la estancia como estrofa de siete y once sílabas dispuestos de modo aleatorio, «normalmente por encima de los ocho versos (para diferenciarla de las liras)». **El corte no es neto ni para él**: unas líneas antes admite que «no es difícil encontrar, sobre todo durante el periodo romántico, extensiones de la lira que alcanzan y aun superan la octava».'),
		('8b5581b0', 'Explica su formación: «la copla empezó por estructurarse como quintilla más sextilla (5-6), pero casi siempre necesitó de las cuatro rimas, como mínimo, para conjuntar sus versos», y describe la realización con quiebros —quintilla `abaab` más sextilla de pie quebrado `cdecde`— en Francisco de Costana, Tapia y Garci Sánchez de Badajoz, donde «los versos quebrados se encargan del descenso climático del poema». La fecha para este catálogo: «se encuentra durante todo el periodo medieval y llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)», **y sigue documentándola, «más rara hoy», en el siglo XX y hasta 2000 —Concha Méndez, Muñoz Rojas, Jorge Guillén, Gamoneda, J. Benito de Lucas—**.', 'Explica su formación: «la copla empezó por estructurarse como quintilla más sextilla (5-6), pero casi siempre necesitó de las cuatro rimas, como mínimo, para conjuntar sus versos», y describe la realización con quiebros —una quintilla, que «**puede ser**» `abaab`, más sextilla de pie quebrado `cdecde`— en Francisco de Costana, y añade que «**hay muchos más**», de Tapia y Garci Sánchez de Badajoz, donde «los versos quebrados se encargan del descenso climático del poema». La fecha para este catálogo: «se encuentra durante todo el periodo medieval y llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)», **y sigue documentándola, «más rara hoy», en el siglo XX y hasta 2000 —Concha Méndez, Muñoz Rojas, Jorge Guillén, Gamoneda, J. Benito de Lucas—**.'),
		('a5faa793', 'Recoge abbba entre las disposiciones de la quintilla octosílaba sin marcarla como anómala, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca, **abcaa y otras**— que describe como transgresión de las viejas normas.', 'Recoge abbba entre las disposiciones de la quintilla octosílaba y, más abajo, bajo «Quintilla octosilábica», **la llama «escasa» frente a «la mayoritaria ababa»**, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca, **abcaa y otras**— que describe como transgresión de las viejas normas.'),
		('a691813f', 'La presenta como derivada de la copla de arte menor y «algo posterior»: «alcanza una cuarta rima, por lo que cada semiestrofa es una auténtica redondilla **(abba: cddc; abab: cdcd; etc.)**». Da el reparto histórico —la de arte menor domina el siglo XIV, la castellana es mayoritaria en el XV— y **la señala como la que permanece, forma popularísima a lo largo de los siglos XVI y XVII**. Al tratar el epigrama la nombra otra vez: optó por «la brevedad de dos redondillas (es decir: de una copla castellana) o dos quintillas, **una décima, etc.**».', 'La presenta como derivada de la copla de arte menor y «algo posterior»: «alcanza una cuarta rima, por lo que cada semiestrofa es una auténtica redondilla **(abba: cddc; abab: cdcd; etc.)**». Da el reparto histórico «**con todo tipo de salvedades y reservas**» —la de arte menor domina el siglo XIV, la castellana es mayoritaria en el XV— y, con la misma reserva, **la señala como la que permanece, forma popularísima a lo largo de los siglos XVI y XVII**. Al tratar el epigrama la nombra otra vez: optó por «la brevedad de dos redondillas (es decir: de una copla castellana) o dos quintillas, **una décima, etc.**».'),
		('ac2eb17b', 'Describe la cuarteta de versos largos y cortos, normalmente 7-5-7-5 con asonancia en los pares, y subraya su fluctuación histórica. Recoge la compuesta, la chamberga, la que llama seguidilla real —la misma que Augusto Ferrán denomina gitana— y la extensión en series arromanzadas.', 'Describe la cuarteta de versos largos y cortos, normalmente 7-5-7-5 con asonancia en los pares, y subraya su fluctuación histórica. Recoge la compuesta, la chamberga, la que **sor Juana Inés de la Cruz** denomina seguidilla real y **Augusto Ferrán** gitana y la extensión en series arromanzadas.'),
		('b2e4dfe5', 'Reserva el nombre de sextilla para las estrofas de seis versos de arte menor y las ordena por medida, describiendo sextillas tetrasilábicas, pentasilábicas, hexasilábicas, heptasilábicas y octosilábicas. Documenta la sextilla alterna ababab en el repertorio juglaresco y en el Libro de Buen Amor, y el tipo aabccb en la Historia Troyana. Llama a las coplas de pie quebrado sextillas simétricas cuyos versos tercero y sexto son menores, con disposición más usual abc:abc, y advierte que el orden de las rimas varía de una composición a otra; entre sus variaciones cita las sextillas de Ricardo Gil, donde el tetrasílabo quiebra el segundo verso y el quinto, y variantes modernas que llegan a dejar versos blancos.', 'Reserva el nombre de sextilla para las estrofas de seis versos de arte menor y las ordena por medida, describiendo sextillas tetrasilábicas, pentasilábicas, hexasilábicas, heptasilábicas y octosilábicas. Documenta la sextilla alterna ababab en el repertorio juglaresco y en el *Libro de Buen Amor*, y —«**como tal probablemente**»— el tipo aabccb en la *Historia Troyana*. Llama a las coplas de pie quebrado sextillas simétricas cuyos versos tercero y sexto son menores, con disposición más usual abc:abc, y advierte que el orden de las rimas varía de una composición a otra; entre sus variaciones cita las sextillas de Ricardo Gil, donde el tetrasílabo quiebra el segundo verso y el quinto, y variantes modernas que llegan a dejar versos blancos.'),
		('ba3902d5', 'No la registra. Enumera la serie alirada desde el cuarteto hasta el octeto-lira y se detiene ahí, porque a partir de esa extensión la llama de otra manera: define la estancia como estrofa de siete y once sílabas dispuestos de modo aleatorio, «normalmente por encima de los ocho versos (para diferenciarla de las liras)».', 'No la registra. Enumera la serie alirada desde el cuarteto hasta el octeto-lira y define la estancia como estrofa de siete y once sílabas dispuestos de modo aleatorio, «normalmente por encima de los ocho versos (para diferenciarla de las liras)». **El corte no es neto ni para él**: unas líneas antes admite que «no es difícil encontrar, sobre todo durante el periodo romántico, extensiones de la lira que alcanzan y aun superan la octava».'),
		('bdac1b06', 'Ofrece la misma estructura canónica de cabeza de dos a cuatro versos, dos mudanzas simétricas y vuelta de tres o cuatro versos que, según el segundo sentido de «vuelta», «**se corresponde en extensión con la cabeza**». Precisa la relación de rimas del enlace y de la vuelta con mudanza y cabeza, la repetición del estribillo cuando hay varias estrofas, la estabilidad de la redondilla o cuarteta central y la variabilidad del comienzo y el final.', 'Ofrece la misma estructura canónica de cabeza de dos a cuatro versos, dos mudanzas simétricas y vuelta de tres o cuatro versos que, según el segundo sentido de «vuelta», «**se corresponde en extensión con la cabeza**». Precisa la relación de rimas del enlace y de la vuelta con mudanza y cabeza —los demás versos, «**o al menos el último**», riman con la cabeza—, la repetición del estribillo cuando hay varias estrofas, la estabilidad de la redondilla o cuarteta central y la variabilidad del comienzo y el final.'),
		('cf2dcb07', 'Registra la composición bajo el nombre de canción a la italiana y la define como poema de un número indeterminado de estancias, tres como mínimo, acabado en un fragmento de estancia que normalmente tiene el primer verso suelto, llamado remate, envío o *commiato*, con la misma distribución de rimas y de versos de once y siete sílabas en todas las estancias. Define la estancia entre nueve y veinte versos con fronte, eslabón y sirima. Describe aparte la canción alirada como variante cuyas estrofas, cortas y simétricas, prescinden de la ordenación rigurosa de la estancia y cuya unidad estrófica oscila entre cuatro y ocho versos.', 'Registra la composición bajo el nombre de canción a la italiana y la define como poema de un número indeterminado de estancias, tres como mínimo, acabado en un fragmento de estancia que normalmente tiene el primer verso suelto, llamado remate, envío o *commiato*, con la misma distribución de rimas y de versos de once y siete sílabas en todas las estancias. Define la estancia «no menos de nueve ni más de veinte, **normalmente**», y añade que «**aunque no es obligatorio, es frecuente**» que se ajuste al esquema de fronte, eslabón y sirima. Describe aparte la canción alirada como variante cuyas estrofas, cortas y simétricas, prescinden de la ordenación rigurosa de la estancia y cuya unidad estrófica oscila entre cuatro y ocho versos.'),
		('de48e693', 'Da el criterio en su forma más nítida: «en rigor, la copla de arte menor es la estrofa de ocho versos octosílabos, divididos en dos semiestrofas (4-4) que se enlazan por una rima y no tienen más de tres». La sitúa dominando el siglo XIV y cediendo en el XV ante la copla castellana, que alcanza una cuarta rima y que es la que permanece en los siglos XVI y XVII. Advierte además que bajo «octavillas» se esconde «el ancho hueco de las coplas de arte menor, con sus muchas variedades».', 'Da el criterio en su forma más nítida: «en rigor, la copla de arte menor es la estrofa de ocho versos octosílabos, divididos en dos semiestrofas (4-4) que se enlazan por una rima y no tienen más de tres». «**Con todo tipo de salvedades y reservas**», la sitúa dominando el siglo XIV y cediendo en el XV ante la copla castellana, que alcanza una cuarta rima y que es la que permanece en los siglos XVI y XVII. Advierte además que bajo «octavillas» se esconde «el ancho hueco de las coplas de arte menor, con sus muchas variedades».'),
		('e20a8b27', 'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma abundante en los cancioneros del siglo XV, con `abba:cdccd` como realización destacada: así el *Diálogo entre el amor y un viejo* de Rodrigo Cota, y también Cervantes en *El Laberinto de amor* y Villamediana. Señala que el orden inicial fue redondilla más quintilla (4+5) y que la forma derivó a juegos de rima más complicados hasta aislar cada semiestrofa y ensayar variantes, incluida la de 5+4. Atribuye a Cristóbal de Castillejo cierta preferencia por la novena y da de él un ejemplo con quebrado que abre la quintilla final, «8a 8b 8b 8a 4c 8c 8d 8d 8c»; registra además las diez novenas de Avellaneda en *La Cruz*, de endecasílabos quebrados en cuarta posición por un heptasílabo y con rimas totales, `ABBa:CDCCD`.', 'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma «abundante en los cancioneros del siglo XV» **aunque «minoritaria frente a sus hermanas la copla de arte menor y la castellana»**, con `abba:cdccd` como realización destacada: así el *Diálogo entre el amor y un viejo* de Rodrigo Cota, y también Cervantes en *El Laberinto de amor* y Villamediana. Señala que el orden inicial fue redondilla más quintilla (4+5) y que la forma derivó a juegos de rima más complicados hasta aislar cada semiestrofa y ensayar variantes, incluida la de 5+4. Atribuye a Cristóbal de Castillejo cierta preferencia por la novena y da de él un ejemplo con quebrado que abre la quintilla final, «8a 8b 8b 8a 4c 8c 8d 8d 8c»; registra además las diez novenas de Avellaneda en *La Cruz*, de endecasílabos quebrados en cuarta posición por un heptasílabo y con rimas totales, `ABBa:CDCCD`.'),
		('e2cb5403', 'Bajo el rótulo «Doble sextilla» del § 67 dice que «la estrofa de doce versos fue concebida ordinariamente como una pareja de sextillas», y es en el § 68, el del pie quebrado, donde sigue su historia disposición a disposición: en el *Cancionero de Baena* las dos sextillas se ajustan a dos únicas rimas, con los quebrados en posición interior, `aab:aab-aab:aab`; en Villasandino el orden se invierte en la segunda, `aab:aab-bba:bba`; Juan de Mena aplica rimas distintas a cada sextilla sin mover el verso corto. Y hacia la mitad del siglo aparece la que se impuso —cada sextilla con tres rimas correlativas propias y los versos cortos al final de cada terceto, `abc:abc-def:def`—, registrada primero en Juan de Mena y que «alcanzó fama permanente con las coplas de Jorge Manrique a la muerte de su padre». Explica además por qué: al individualizar las rimas de cada mitad, esa forma «desligaba una sextilla de otra con separación semejante a la practicada entre las redondillas de la copla castellana y las quintillas de la copla real».', 'Bajo el rótulo «Doble sextilla» del § 67 dice que «la estrofa de doce versos fue concebida ordinariamente como una pareja de sextillas», y es en el § 68, el del pie quebrado, donde sigue su historia disposición a disposición: en el *Cancionero de Baena* las dos sextillas se ajustan a dos únicas rimas, con los quebrados en posición interior, `aab:aab-aab:aab`; en Villasandino el orden se invierte en la segunda, `aab:aab-bba:bba`; Juan de Mena aplica rimas distintas a cada sextilla sin mover el verso corto. Y hacia la mitad del siglo aparece la que se impuso —cada sextilla con tres rimas correlativas propias y los versos cortos al final de cada terceto, `abc:abc-def:def`—, registrada primero en Juan de Mena y que «alcanzó fama permanente con las coplas de Jorge Manrique a la muerte de su padre». Apunta además una conjetura sobre por qué: al apartarse de las formas anteriores, «**respondía probablemente al propósito de**» reforzar la diferenciación y simetría de las rimas de cada sextilla, «a la vez que desligaba una sextilla de otra con separación semejante a la practicada entre las redondillas de la copla castellana y las quintillas de la copla real».');

	select count(*) into v_n
	from cambios_cautelas_d c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_cautelas_d c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_cautelas_d c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna ficha vuelve a afirmar lo que la fuente desmiente, ni a dar por firme lo que
	-- la fuente pone con reservas.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where resumen like '%sin marcarla como anómala%'
		or resumen like '%se detiene ahí, porque a partir de esa extensión%';
	if v_n <> 0 then
		raise exception '% fichas conservan lo que esta migración retira.', v_n;
	end if;

	-- Y que las dos coplas de Jauralde llevan ya la reserva con que él reparte los siglos.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) in ('a691813f', 'de48e693')
		and resumen ilike '%con todo tipo de salvedades y reservas%';
	if v_n <> 2 then
		raise exception 'Solo % de las dos coplas de Jauralde recogen su reserva.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
