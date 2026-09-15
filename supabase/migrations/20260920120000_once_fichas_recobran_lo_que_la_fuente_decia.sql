-- Once fichas recobran lo que la fuente decía y ellas callaban
--
-- Segunda tanda del cubo de observación. Aquí no sobra nada: **falta**. Son dos familias.
--
-- ══ La fuente matiza y la ficha no
--
--   `588025c8`  Navarro cuenta que los personajes de Tirso aluden al carácter antiguo de la
--               estrofa, y añade en la misma frase «**aunque en realidad difiera bastante del
--               modelo tradicional**». La ficha se quedaba con la alusión y tiraba la reserva. Es
--               la definición exacta del endurecimiento: lo que queda sigue siendo verdad a medias.
--   `ec3f5532`  «sigue su uso… **hasta Andrés Bello**». El § 226 enumera **cuatro** terrenos y Bello
--               es el segundo ejemplo del segundo; la frase continúa en la página siguiente con
--               poemas mitológicos y poesías festivas. «Hasta» convertía un nombre de en medio de
--               la lista en un final que Navarro no pone.
--   `63e2a80d`  el *Diccionario* dice que la quintilla es muy usada en el teatro del Siglo de Oro y
--               acto seguido, con un «Con todo», que «**no se limita a la poesía dramática**». En un
--               catálogo de verso dramático, omitir esa salvedad es quedarse con la mitad que nos
--               favorece.
--   `d3241dd6`  dos cosas. «Boscán compuso canciones de hasta veintisiete estrofas» repartía entre
--               once canciones lo que Navarro dice de **una**. Y las excepciones de Garcilaso
--               estaban borradas: la cuarta, de ocho estancias de veinte versos, y **la quinta,
--               compuesta en liras** — dicho por Navarro dentro del epígrafe de la estancia, que es
--               justo la frontera alirada/canción abierta para el IP.
--   `22c63f36`  la ficha daba la seguidilla gitana como `6-6-(10/11)-6` citando el § 450 y el
--               repertorio final. **Los dos no dicen lo mismo**: el § 450 admite «diez o doce» y el
--               repertorio «once y a veces diez», y el repertorio remite a ese mismo § 450, o sea
--               que lo resume perdiendo el doce. La contradicción es de Navarro y se dice como suya.
--   `b4c150a8`  la ficha decía que el *Diccionario* «**reserva**» serventesio para el cuarteto de
--               arte mayor. El sentido 2 de esa misma entrada lo da a la «cuarteta», de arte menor.
--
-- ══ Material
--
--   `9c4dd052`  «**Reservan** el nombre de lira para la de seis versos» invierte lo que hacen:
--               «El nombre de lira **también** se aplica a una estrofa de 5 versos, aBabB, que aquí
--               se ha llamado quintilla de Fray Luis de León». Registran el uso corriente y se
--               inventan un nombre para distinguir. De paso entra el epígrafe entero, que la ficha
--               daba a medias.
--   `0432c49f`  el 50-98 % de versos rimados del tercer tipo de silva iba con una condición,
--               «**sin contar el pareado final**», que se había caído; y el esquema del primero
--               estaba cortado sin el «etc.» de la fuente.
--   `f3015660`  cita literal a la que le faltaba una palabra: «de la misma rima **total**».
--   `9df9b891`  «**con rima consonante**» es lo único que el *Diccionario* fija sobre la rima de la
--               sextilla de pie quebrado, y estaba fuera. Y la entrada tiene un segundo sentido que
--               remite a «sexteto» — lo que el catálogo separa a propósito.
--   `b32dd1f7`  el bloque OTROS TÉRMINOS de «verso suelto» tiene cuatro nombres y la ficha daba
--               tres. El descartado, «verso libre, 2», parecía otra forma; **el sentido 2 de la
--               entrada «verso libre» es, literalmente, «verso suelto»**.
--
-- ══ Lo que enseña esta tanda
--
-- **Tres de las cinco fichas del *Diccionario* perdían lo mismo: lo que llevaba número de sentido.**
-- Serventesio 2, sextilla 2, «verso libre, 2» — más la sextina de hace dos días. Es una regla, no
-- tres casualidades, y queda apuntada como quinta comprobación mecánica: recorrer las entradas con
-- sentidos numerados y cotejar qué recoge la ficha.
--
-- Textos aprobados por David uno a uno el 20 de septiembre de 2026.

begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 11;
	v_antes bigint;
	v_despues bigint;
	v_otro_antes text;
	v_otro_despues text;
begin
	create temporary table cambios_cautelas (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_cautelas (id8, antes, despues)
	values
		('0432c49f', 'Distinguen cuatro tipos: la silva de consonantes aAbBcC, de la que dicen que «se podría llamar pareados de 7 y 11»; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**.', 'Distinguen cuatro tipos: la silva de consonantes aAbBcCdD, etc., de la que dicen que «se podría llamar pareados de 7 y 11»; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados sin contar el pareado final y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**.'),
		('22c63f36', 'Define la simple 7-5-7-5 con impares sueltos y pares asonantes, y documenta su antigua fluctuación. Registra además la estrofa 5-7-5, la compuesta, la chamberga, la gitana 6-6-(10/11)-6 y la real 10-6-10-6, junto con series arromanzadas, formas con eco y otras prolongaciones.', 'Define la simple 7-5-7-5 con impares sueltos y pares asonantes, y documenta su antigua fluctuación. Registra además la estrofa 5-7-5, la compuesta, la chamberga, la gitana de hexasílabos con el tercer verso generalmente endecasílabo —el § 450 lo rebaja en algunos casos a diez o doce sílabas y el repertorio final a diez, sin coincidir— y la real 10-6-10-6, junto con series arromanzadas, formas con eco y otras prolongaciones.'),
		('588025c8', 'La describe como dos cuartetos en versos de arte mayor con sólo tres rimas, generalmente en forma abrazada ABBA:ACCA, y otras veces con un cuarteto abrazado y otro cruzado. Registra aparte, como caso singular, una carta de Tirso de Molina en *Quien calla otorga* compuesta en una copla de cuatro rimas finales ABBA:CDDC y otras cuatro en los primeros hemistiquios, cuyos personajes aluden al carácter antiguo de la estrofa.', 'La describe como dos cuartetos en versos de arte mayor con sólo tres rimas, generalmente en forma abrazada ABBA:ACCA, y otras veces con un cuarteto abrazado y otro cruzado. Registra aparte, como caso singular, una carta de Tirso de Molina en *Quien calla otorga* compuesta en una copla de cuatro rimas finales ABBA:CDDC y otras cuatro en los primeros hemistiquios; los personajes aluden al carácter antiguo de la estrofa, «aunque en realidad difiera bastante del modelo tradicional».'),
		('63e2a80d', 'Fija cuatro condiciones: cinco versos octosílabos **o menores**, dos clases de rima consonante, no más de dos versos seguidos con la misma rima, y ni pareado final ni verso suelto. Añade que es estrofa muy usada en el teatro del Siglo de Oro, sobre todo en las partes narrativas y líricas, y que dentro de un mismo poema puede variar la disposición de unas quintillas a otras.', 'Fija cuatro condiciones: cinco versos octosílabos **o menores**, dos clases de rima consonante, no más de dos versos seguidos con la misma rima, y ni pareado final ni verso suelto. Añade que es estrofa muy usada en el teatro del Siglo de Oro, sobre todo en las partes narrativas y líricas, aunque «no se limita a la poesía dramática, sino que es forma empleada también en la poesía lírica y en la narrativa», y que dentro de un mismo poema puede variar la disposición de unas quintillas a otras.'),
		('9c4dd052', 'Reservan el nombre de lira para la estrofa de **seis** versos aBaBcC, y llaman a esta de cinco «quintilla de Fray Luis de León». Añaden que todas las liras no son más que formas especializadas de la canzone italiana.', 'Llaman lira a la estrofa de seis versos de siete y once sílabas con tres rimas, donde los cuatro primeros llevan dos rimas y los dos últimos forman un pareado con la tercera; en Lope el último verso es endecasílabo. Su forma más corriente, la que ellos llaman «regular», es aBaBcC, y registran también abbacC, AabBcC, AabBCC y otras; el tipo que se adopta al comienzo de un pasaje es el que generalmente se conserva a lo largo de todo él. Advierten que el nombre de lira se aplica **también** a una estrofa de cinco versos, aBabB, que en su libro llaman «quintilla de Fray Luis de León». Añaden que «todas las liras no son más que formas especializadas de la *canzone*».'),
		('9df9b891', 'Define la sextilla como estrofa de seis versos de arte menor cuya rima puede adoptar variadas disposiciones, y recoge «redondilla de seis versos» como otro nombre. Tipifica la alterna, con dos rimas alternadas; la correlativa, en que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto; y la paralela, dividida en dos partes de tres versos ordenadas simétricamente. La sextilla de pie quebrado la describe como copla de pie quebrado en dos semiestrofas de tres versos, con disposiciones aabaab, aabccb o abcabc.', 'Define la sextilla como estrofa de seis versos de arte menor cuya rima puede adoptar variadas disposiciones, y recoge «redondilla de seis versos» como otro nombre. Tipifica la alterna, con dos rimas alternadas; la correlativa, en que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto; y la paralela, dividida en dos partes de tres versos ordenadas simétricamente. La sextilla de pie quebrado la describe como copla de pie quebrado en dos semiestrofas de tres versos con rima consonante, con disposiciones aabaab, aabccb o abcabc. La entrada «sextilla» tiene además un segundo sentido, que recoge de Vicente Salvá y remite a «sexteto».'),
		('b32dd1f7', 'Lo define como clase de verso regular que no lleva rima y señala que sus formas más frecuentes son las series de endecasílabos, heptasílabos y pentasílabos, solos o combinados entre sí, sobre modelo italiano. Explica que al renunciar a uno de los elementos rítmicos exige estar más trabajado, porque cualquier prosaísmo se nota enseguida, y que por eso se tuvo por más difícil que el verso rimado. Recoge poema de verso suelto, poesía suelta y verso blanco como otros términos.', 'Lo define como clase de verso regular que no lleva rima y señala que sus formas más frecuentes son las series de endecasílabos, heptasílabos y pentasílabos, solos o combinados entre sí, sobre modelo italiano. Explica que al renunciar a uno de los elementos rítmicos exige estar más trabajado, porque cualquier prosaísmo se nota enseguida, y que por eso se tuvo por más difícil que el verso rimado. Recoge como otros términos poema de verso suelto, poesía suelta, verso blanco y «verso libre», que en el segundo de sus dos sentidos nombra esta misma forma.'),
		('b4c150a8', 'Reserva «serventesio» para la disposición cruzada del cuarteto de arte mayor, y recoge «cuarteto de rima cruzada» y «faleucio» como otros nombres suyos.', 'Da «serventesio» en dos sentidos: la disposición cruzada del cuarteto de arte mayor —con «cuarteto de rima cruzada», «faleucio» y «sermontesio» como otros nombres— y un segundo que remite a «cuarteta».'),
		('d3241dd6', 'Describe la estancia como la estrofa de las canciones y églogas renacentistas y, en contraste con la regularidad del soneto, como la más variable de la métrica italiana, cuya extensión y combinación de rimas dejaban amplio margen a la libertad del poeta. Explica que constaba de dos partes, la primera más breve y generalmente en endecasílabos, con los heptasílabos intercalados sobre todo en la segunda o marcando la transición entre ambas. Documenta que Boscán compuso canciones de hasta veintisiete estrofas de quince versos y Garcilaso composiciones de cuatro o cinco estancias de trece, y que la estancia abCabC:cdeeDfF de su segunda égloga, tomada de la canción undécima de Petrarca, fue usada por Herrera e imitada después en numerosas ocasiones.', 'Describe la estancia como la estrofa de las canciones y églogas renacentistas y, en contraste con la regularidad del soneto, como la más variable de la métrica italiana, cuya extensión y combinación de rimas dejaban amplio margen a la libertad del poeta. Explica que constaba de dos partes, la primera más breve y generalmente en endecasílabos, con los heptasílabos intercalados sobre todo en la segunda o marcando la transición entre ambas. Documenta que Boscán compuso once largas canciones, la primera de las cuales llega a veintisiete estrofas de quince versos, y que las de Garcilaso son en su mayor parte de no más de cuatro o cinco estancias de trece, con excepción de la cuarta, de ocho estancias de veinte versos, y de la quinta, compuesta en liras; y que la estancia abCabC:cdeeDfF de su segunda égloga, tomada de la canción undécima de Petrarca, fue usada por Herrera e imitada después en numerosas ocasiones.'),
		('ec3f5532', 'La señala como la estrofa endecasílaba de forma orgánica que se mantuvo con más firmeza en su antiguo nivel, y sigue su uso en cantos heroicos y en composiciones de carácter filosófico o novelesco hasta Andrés Bello.', 'La señala como la estrofa endecasílaba de forma orgánica que se mantuvo con más firmeza en su antiguo nivel, y recorre su uso en cuatro terrenos: cantos heroicos, composiciones de carácter filosófico o novelesco —donde cita *El proscrito*, de Andrés Bello—, poemas mitológicos y poesías festivas o humorísticas.'),
		('f3015660', 'No registra esta estrofa. Bajo «estrofas de siete versos» describe una **séptima de arte mayor**, que dice poco usada en la métrica española y cuya rima «queda a gusto del poeta, con la sola condición de que tres versos no vayan seguidos de la misma rima», y ejemplifica con Rubén Darío: es otra estructura, no la de cuatro y tres.', 'No registra esta estrofa. Bajo «estrofas de siete versos» describe una **séptima de arte mayor**, que dice poco usada en la métrica española y cuya rima «queda a gusto del poeta, con la sola condición de que tres versos no vayan seguidos de la misma rima total», y ejemplifica con Rubén Darío: es otra estructura, no la de cuatro y tres.');

	-- Que cada afirmación existe y tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % afirmaciones tienen el texto que esta migración espera; no toco ninguna.',
			v_n, v_esperadas;
	end if;

	-- Y que ninguna tiene ya el texto nuevo, que significaría que esto se aplicó por otra vía.
	select count(*) into v_n
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> 0 then
		raise exception '% afirmaciones tienen ya el texto nuevo.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	select string_agg(a.localizador, '|' order by a.afirmacion_id) into v_otro_antes
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_cautelas c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las 11 quedaron con el texto nuevo, releído de la tabla.
	select count(*) into v_n
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna conserva el viejo.
	select count(*) into v_n
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> 0 then
		raise exception '% se quedaron con el texto viejo.', v_n;
	end if;

	select string_agg(a.localizador, '|' order by a.afirmacion_id) into v_otro_despues
	from cambios_cautelas c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8;
	if v_otro_despues is distinct from v_otro_antes then
		raise exception 'Se movió algún localizador y esta migración solo escribe prosa.';
	end if;


	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
