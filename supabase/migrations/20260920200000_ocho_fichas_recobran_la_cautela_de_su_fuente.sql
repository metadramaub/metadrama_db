-- Ocho fichas recobran la cautela con que su fuente lo dijo
--
-- **Salieron al regenerar los extractos.** Llevaban desde el 11 de septiembre sin rehacerse, con
-- cincuenta migraciones de por medio; sobre los pasajes frescos, la cuarta comprobación mecánica
-- levantó diez fichas que antes no señalaba. Ocho eran de verdad. De las otras dos, una es un
-- marcador de discurso —«como puede observarse»— y la otra un inciso que va a favor de la duda que
-- la ficha registra, no en contra.
--
-- ══ La que más importa
--
-- `d3328f68` decía que ciertas combinaciones de ocho versos «con aspecto de estancias» **deben**
-- considerarse octavas aliradas. El § 229 dice que **pueden**. Y no es un endurecimiento cualquiera:
-- es exactamente la frase que el catálogo usa como criterio para separar la estrofa alirada de la
-- estancia de canción, que es la cuestión abierta con el IP. Navarro no manda ahí: sugiere.
--
-- Con ella sale también la coletilla «Es el criterio que separa la estrofa alirada de la estancia de
-- canción», que es el catálogo hablando dentro de Navarro —la pasada C ya avisó de que esa fórmula
-- no está en el libro— y entra en su lugar la filiación que la ficha había perdido: el esquema de
-- Lista «reproduce con poca diferencia» el ABcABcDD de *La entretenida*, que ya es otra de nuestras
-- octavas-lira.
--
-- ══ Las otras siete
--
--   `14578fe2`  Quilis dice que los *versi sciolti* **pueden deberse** a la imitación latina o a
--               exigencias de la música; la ficha daba las dos causas por ciertas.
--   `3ac1b32a`  M&B dicen «**se puede considerar** esta forma como una combinación de dos
--               quintillas» y la ficha lo daba como su lectura. Y se había comido la reserva que
--               sigue, «pero la 6 es muy poco frecuente sola». Sale además la comparación con
--               Domínguez Caparrós: es nuestra, y no de las que caben dentro de una fuente.
--   `77da08e6`  **un «pero» convertido en «porque»**. Quilis dice que la redondilla no tuvo vida
--               independiente **pero** que duplicarla dio origen a la octavilla; la ficha hacía de
--               lo primero la causa de lo segundo. Es la misma familia que el «es lo que hace» del
--               soneto. Entra de paso el «uso frecuente en los cancioneros del siglo XV».
--   `71d1e7df`  el zéjel procede de una forma arábigo-española «aunque modificado y adecuado a la
--               métrica románica», y ese inciso califica justo la derivación que la ficha afirma.
--   `e69543b4`  la «copla mixta» del *Diccionario* «puede tener desde siete hasta doce versos
--               octosílabos —rara vez versos de arte mayor—», y el rango era lo que sostenía la
--               afirmación.
--   `5b191115`  «lo atribuyen a» por «dicen que **puede deberse** a», que es como M&B lo escriben.
--   `e7df73d9`  «Registra» por «dice que **es frecuente**», que es como empieza el § 58.
--
-- Textos aprobados por David el 20 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 8;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_cautelas2 (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_cautelas2 (id8, antes, despues)
	values
		('3ac1b32a', 'Leen la estrofa como combinación de dos quintillas, la n.º 6 y la n.º 5, y consideran la pausa tras el cuarto verso característica «aunque no obligatoria», donde Domínguez Caparrós la exige en las dos obras suyas que aquí se citan.', 'Dicen que «se puede considerar esta forma como una combinación de dos quintillas, la n.º 6 y la n.º 5», pero advierten que «la 6 es muy poco frecuente sola», y tienen la pausa después del verso 4 por característica «aunque no es obligatoria».'),
		('14578fe2', 'Explica que en la Italia del siglo XVI aparecen composiciones caracterizadas por la ausencia de rima entre sus versos, los *versi sciolti*, por imitación de la poesía latina clásica o por exigencias de la música, y que Boscán introduce esta forma en España empleando el endecasílabo. Señala que el poema de versos sueltos se usó para epístolas y sátiras, y a veces en poemas líricos o narrativos, y que resulta muy útil para las traducciones, donde la búsqueda de la rima puede resultar forzada.', 'Explica que en la Italia del siglo XVI aparecen composiciones caracterizadas por la ausencia de rima entre sus versos, los *versi sciolti*, que **pueden deberse** a la imitación de la poesía latina clásica o a exigencias de la música, y que Boscán introduce esta forma en España empleando el endecasílabo. Señala que el poema de versos sueltos se usó para epístolas y sátiras, y a veces en poemas líricos o narrativos, y que resulta muy útil para las traducciones, donde la búsqueda de la rima puede resultar forzada.'),
		('5b191115', 'Dan siete combinaciones y precisan que Rengifo, en su *Arte poética* de 1592, recoge solo las cinco primeras y en ese orden, omitiendo las dos que acaban en pareado, que se hallan alguna vez pero con muy poca frecuencia. Sobre su uso: la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara. Registran además que alguna vez aparece el tipo ABBBA, y lo atribuyen a un error de imprenta o a una adaptación especial para expresar un pensamiento.', 'Dan siete combinaciones y precisan que Rengifo, en su *Arte poética* de 1592, recoge solo las cinco primeras y en ese orden, omitiendo las dos que acaban en pareado, que se hallan alguna vez pero con muy poca frecuencia. Sobre su uso: la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara. Registran además que alguna vez aparece el tipo ABBBA, que dicen que «**puede deberse** a un error de imprenta o a una adaptación especial para expresar un pensamiento».'),
		('71d1e7df', 'Explica que procede de una forma popular de la poesía arábigo-española y aparece en la lírica castellana en el siglo XIV. Lo describe normalmente en octosílabos, con estribillo de uno o dos versos, mudanza de tres versos monorrimos y un cuarto verso de vuelta que rima con el estribillo, según el esquema aa-bbba. Precisa que se diferencia del villancico sobre todo por la mudanza —redondilla en el villancico, trístico monorrimo en el zéjel— y, de manera menos constante, por el estribillo: en el villancico suele tener tres o cuatro versos y en el zéjel, de ordinario, dos.', 'Explica que procede de una forma popular de la poesía arábigo-española, «**aunque modificado y adecuado a la métrica románica**», y que aparece en la lírica castellana en el siglo XIV. Lo describe normalmente en octosílabos, con estribillo de uno o dos versos, mudanza de tres versos monorrimos y un cuarto verso de vuelta que rima con el estribillo, según el esquema aa-bbba. Precisa que se diferencia del villancico sobre todo por la mudanza —redondilla en el villancico, trístico monorrimo en el zéjel— y, de manera menos constante, por el estribillo: en el villancico suele tener tres o cuatro versos y en el zéjel, de ordinario, dos.'),
		('77da08e6', 'Su estrofa de ocho versos es la octavilla, que hace derivar de la duplicación de una redondilla o de la combinación de dos, porque durante la Edad Media la redondilla «no tuvo vida independiente». De su rima dice que «suele ser» `abbecdde` o `ababbccb`, y la ejemplifica con una estrofa del Marqués de Santillana. Añade que cuando los octosílabos alternan con versos de cuatro sílabas se originan las coplas de pie quebrado, muy difundidas en el siglo XV y principios del XVI, y cita el *Diálogo de Bías contra Fortuna* y los *Proverbios morales* de Santillana.', 'Su estrofa de ocho versos es la octavilla: durante la Edad Media la redondilla «no tuvo vida independiente», **pero** la duplicación de una o la combinación de dos «dio origen a estrofas de uso frecuente en los cancioneros del siglo XV». De su rima dice que «suele ser» `abbecdde` o `ababbccb`, y la ejemplifica con una estrofa del Marqués de Santillana. Añade que cuando los octosílabos alternan con versos de cuatro sílabas se originan las coplas de pie quebrado, muy difundidas en el siglo XV y principios del XVI, y cita el *Diálogo de Bías contra Fortuna* y los *Proverbios morales* de Santillana.'),
		('d3328f68', 'Sostiene que ciertas combinaciones de ocho versos «con aspecto de estancias» deben considerarse más bien octavas aliradas, y documenta dos: ABAbCcDD, en Fray Diego Tadeo González y en Arriaza, y ABcaBCdD, en la oda de Lista. Es el criterio que separa la estrofa alirada de la estancia de canción, enunciado sobre la forma que más se presta a confundirlas.', 'Sostiene que ciertas combinaciones de ocho versos «con aspecto de estancias» **pueden más bien considerarse** octavas aliradas, y documenta dos: ABAbCcDD, en Fray Diego Tadeo González y en Arriaza, y ABcaBCdD, en la oda de Lista, que «reproduce con poca diferencia» el ABcABcDD que se halla en *La entretenida*, de Cervantes.'),
		('e69543b4', 'Cuenta también los seis: la manriqueña es para él la estrofa de pie quebrado. Su entrada «copla mixta» sí contempla la agrupación de doce, al definirla como combinación «dividida en dos semiestrofas de distinta extensión **o en dos sextillas**».', 'Cuenta también los seis: la manriqueña es para él la estrofa de pie quebrado. Su entrada «copla mixta» sí contempla la agrupación de doce, al definirla como combinación que «**puede tener desde siete hasta doce versos octosílabos —rara vez versos de arte mayor—** y que está dividida en dos semiestrofas de distinta extensión **o en dos sextillas**».'),
		('e7df73d9', 'Registra el pareado octosílabo en estribillos de canciones, en máximas o proverbios intercalados en algunos decires, y en motes y divisas. Del pareado narrativo de la poesía juglaresca, restringido entre los poetas de clerecía, dice que «**parece** casi enteramente desterrado de la métrica del siglo XV», y anota que se halla por excepción en el *Razonamiento que fizo don Alfonso Enríquez fablando con él mesmo*.', 'Dice que «**es frecuente** el pareado octosílabo en estribillos de canciones, en máximas o proverbios intercalados en algunos decires y en motes y divisas». Del pareado narrativo de la poesía juglaresca, restringido entre los poetas de clerecía, dice que «**parece** casi enteramente desterrado de la métrica del siglo XV», y anota que se halla por excepción en el *Razonamiento que fizo don Alfonso Enríquez fablando con él mesmo*.');

	-- Que cada una tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_cautelas2 c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_cautelas2 c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_cautelas2 c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna de las ocho conserva la forma dura que se retira.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where resumen like '%deben considerarse más bien octavas aliradas%'
		or resumen like '%Es el criterio que separa la estrofa alirada%';
	if v_n <> 0 then
		raise exception '% fichas siguen endureciendo el § 229.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
