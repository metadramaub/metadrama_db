-- Nueve glosas del catálogo salen de la voz de la fuente, y una singular se hace plural
--
-- **Segunda vez que el cubo de una hoja de correcciones no era lo que la hoja decía.** El de
-- «observación» reunía cincuenta afirmaciones descritas como «conformes, pero con algo anotado», y
-- de las tres pasadas habían tenido A y B las cincuenta, **C ninguna** — igual que el de
-- confirmación la semana pasada.
--
-- Al leer las cincuenta notas, la familia más numerosa resultó ser **la misma que dio seis de los
-- ocho defectos del cubo anterior**: una frase del catálogo puesta en boca del libro. No es
-- casualidad. La heurística que reparte los cubos busca las palabras con que un verificador dice
-- una divergencia —«es una glosa», «es una inferencia», «no aparece»—, y esas son justo las que usa
-- cuando ve que la ficha ha añadido algo suyo.
--
-- ══ Lo que se retira, y lo que no
--
-- **Ninguna pierde un dato de la fuente.** Pierden una frase nuestra:
--
--   `f749bd50`  el envío de la sextina traducido a letras, «BA-DF-EC». Morley y Bruerton solo dan
--               números —«envío: 21, 46, 53»—, y A-F es notación de rima: usarla dice lo contrario
--               de lo que el epígrafe insiste, que **ninguna de las palabras finales rima**. Eso
--               último, que la ficha callaba, entra en su lugar.
--   `4b2baf4c`  «su corpus es Lope, posterior al de los entremeses donde esta serie se documenta»,
--   `8dc1b345`  la misma frase repetida en la ficha vecina. «entremés», «paso» y «corpus» no
--               aparecen **ni una vez** en el capítulo V.
--   `a1e0457a`  «la silva dramática nace, **por tanto**, de rimar un pasaje que antes iba suelto».
--   `8ef78bc8`  «la agrupación existe, **pues**, aunque no sea regular ni se pueda declarar de
--               antemano». En las dos, el conector delata que se está razonando y no citando.
--   `51476304`  la escansión `7a 11B 7a 11B 7b 7c 11C` del ejemplo de fray Luis. Es correcta —está
--               comprobada verso a verso— pero **ya está en el catálogo**: es la arquitectura del
--               septeto-lira, con su esquema métrico `7-11-7-11-7-7-11` y su rima `ababbcc`. La
--               ficha repetía la arquitectura con la firma del *Diccionario* debajo.
--   `c5992665`  «Es la única fuente que la describe». Es cierta —las otras cinco son silencios—
--               pero es una afirmación sobre el corpus entero dicha dentro de una sola fuente, y la
--               sección ya lo enseña sola.
--   `3fd5381e`  «el proyecto formaliza el cierre como…». El catálogo no habla dentro de una fuente.
--               En su lugar entra el esquema tal como Caparrós lo imprime, **con la variante de
--               cierre VYVYZZ** que la ficha no recogía.
--
-- ══ La que no era glosa
--
-- `ce47ab90` decía que las estrofas enlazadas de seis y siete versos «llevan esa misma quintilla
-- dentro», y parecía una inferencia del catalogador. Al ir al § 131 a ver si podía anclarse resultó
-- que **lo dice Navarro con esas palabras**: «se trata, como se ve, de la quintilla con quebrado
-- inicial de Castillejo a la cual se antepone un octosílabo». No se corta: se cita y se localiza.
--
-- ══ Y una concordancia
--
-- `2cb2f293` empezaba «Nombra las variedades». De las 45 fichas de Morley y Bruerton, 42 hablan en
-- plural, que es lo que son: dos autores. Con `f749bd50` —que arreglaba otra cosa— quedan dos
-- menos; la tercera está fuera de este cubo y se anota.
--
-- Textos aprobados por David uno a uno el 20 de septiembre de 2026.

begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 10;
	v_antes bigint;
	v_despues bigint;
	v_otro_antes text;
	v_otro_despues text;
begin
	create temporary table cambios_glosas (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_glosas (id8, antes, despues)
	values
		('2cb2f293', 'Nombra las variedades por su medida: romancillo o endechas en seis y siete sílabas, romance heroico o romance real en once.', 'Nombran las variedades por su medida: romancillo o endechas en seis y siete sílabas, romance heroico o romance real en once.'),
		('3fd5381e', 'La rima central de cada terceto se convierte en la rima exterior del siguiente; el proyecto formaliza el cierre como último terceto YZY más un verso Z, que completa YZYZ.', 'La rima central de cada terceto se convierte en la rima exterior del siguiente, según el esquema ABA BCB CDC… YZYZ, y da como variante de cierre VYVYZZ.'),
		('4b2baf4c', 'No la distinguen. Sus «coplas de pie quebrado» abarcan por extensión, de cinco a doce versos, sin atender a si la rima enlaza una estrofa con la siguiente, y su corpus es Lope, posterior al de los entremeses donde esta serie se documenta.', 'No la distinguen. Sus «coplas de pie quebrado» abarcan por extensión, de cinco a doce versos, sin atender a si la rima enlaza una estrofa con la siguiente: el capítulo no menciona en ningún punto el encadenamiento entre estrofas.'),
		('51476304', 'Es la fuente que le da entrada propia: «septeto alirado. Lira de siete versos», y precisa que «es una clase de lira que sirve de estrofa en la canción alirada». Registra lira heptástica y septeto-estancia como otros términos, y ejemplifica con fray Luis de León —«El ánimo constante / armado de verdad, mil aceradas…»—, cuya disposición es `7a 11B 7a 11B 7b 7c 11C`.', 'Es la fuente que le da entrada propia: «septeto alirado. Lira de siete versos», y precisa que «es una clase de lira que sirve de estrofa en la canción alirada». Registra lira heptástica y septeto-estancia como otros términos, y ejemplifica con fray Luis de León —«El ánimo constante / armado de verdad, mil aceradas…»—.'),
		('8dc1b345', 'No la distinguen. Sus «coplas de pie quebrado» son octosílabos combinados con su quebrado «en estrofas (en Lope) de cinco a doce versos», sin atender a si la rima enlaza una estrofa con la siguiente. Su corpus es Lope, posterior al de los pasos y entremeses donde esta serie se documenta.', 'No la distinguen. Sus «coplas de pie quebrado» son octosílabos combinados con su quebrado «en estrofas (en Lope) de cinco a doce versos», sin atender a si la rima enlaza una estrofa con la siguiente: el capítulo no menciona en ningún punto el encadenamiento entre estrofas.'),
		('8ef78bc8', 'Matiza que, siendo la silva un poema no estrófico, los poetas suelen dividirla en formas **paraestróficas** desiguales que recuerdan las estancias de la canción. La agrupación existe, pues, aunque no sea regular ni se pueda declarar de antemano.', 'Matiza que, siendo la silva un poema no estrófico, los poetas suelen dividirla en formas **paraestróficas** desiguales que recuerdan las estancias de la canción.'),
		('a1e0457a', 'Data la silva teatral con precisión: desde 1588 Lope intercaló pareados en los pasajes de sus comedias escritos en endecasílabos y heptasílabos **sueltos**; la silva de endecasílabos solos aparece desde 1604, en *Don Juan de Austria en Flandes*; y la silva ordinaria de siete y once es la de las *Soledades* de Góngora, compuesta la primera en 1613. La silva dramática nace, por tanto, de rimar un pasaje que antes iba suelto.', 'Data la silva teatral con precisión: desde 1588 Lope intercaló pareados en los pasajes de sus comedias escritos en endecasílabos y heptasílabos **sueltos**; la silva de endecasílabos solos aparece desde 1604, en *Don Juan de Austria en Flandes*; y la silva ordinaria de siete y once es la de las *Soledades* de Góngora, compuesta la primera en 1613.'),
		('c5992665', 'Es la única fuente que la describe. La sitúa entre las estrofas enlazadas, cuyo propósito explica: «se hizo de varios modos el enlace de las estrofas, no como mera gala métrica a la manera del encadenado de la gaya ciencia, sino como recurso para dar a la versificación movimiento flexible y corrido». De esta dice que una poesía del *Cancionero de Pedro del Pozo* «se sirve de una especie de redondilla cuyo último verso es un pie quebrado que introduce un nuevo consonante con el cual rima el principio de la redondilla siguiente: `abbc-cdde-effg`», y encuentra el mismo procedimiento en otra composición del *Cancionero de Évora*. En su recorrido del período añade lo que justifica estas formas en un catálogo de verso dramático: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».', 'La sitúa entre las estrofas enlazadas, cuyo propósito explica: «se hizo de varios modos el enlace de las estrofas, no como mera gala métrica a la manera del encadenado de la gaya ciencia, sino como recurso para dar a la versificación movimiento flexible y corrido». De esta dice que una poesía del *Cancionero de Pedro del Pozo* «se sirve de una especie de redondilla cuyo último verso es un pie quebrado que introduce un nuevo consonante con el cual rima el principio de la redondilla siguiente: `abbc-cdde-effg`», y encuentra el mismo procedimiento en otra composición del *Cancionero de Évora*. En su recorrido del período añade lo que justifica estas formas en un catálogo de verso dramático: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».'),
		('ce47ab90', 'Al resumir el período renacentista registra el uso suelto de la quintilla quebrada: mientras decaen las coplas reales y castellanas y aumentan «las redondillas y quintillas emancipadas», **«la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo»**. En el mismo pasaje anota que el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos, que llevan esa misma quintilla dentro.', 'Al resumir el período renacentista registra el uso suelto de la quintilla quebrada: mientras decaen las coplas reales y castellanas y aumentan «las redondillas y quintillas emancipadas», **«la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo»**. En el mismo pasaje anota que el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos, que en el § 131 describe como «la quintilla con quebrado inicial de Castillejo a la cual se antepone un octosílabo».'),
		('f749bd50', 'Define la forma petrarquista como seis estrofas de seis endecasílabos y un envío de tres versos, siempre 39 en total. Da la permutación 123456 → 615243 → 364125 → 532614 → 451362 → 246531 y realiza el envío como 21-46-53, es decir, BA-DF-EC. Registra además una sextina incompleta de Lope de 21 versos.', 'Definen la forma petrarquista como seis estrofas de seis endecasílabos y un envío de tres versos, siempre 39 en total, y advierten que ninguna de las palabras finales rima en ninguna estrofa. Dan la permutación 123456 → 615243 → 364125 → 532614 → 451362 → 246531 y el envío como 21, 46, 53. Registran además una sextina incompleta de Lope de 21 versos.');

	-- Que cada afirmación existe y tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_glosas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % afirmaciones tienen el texto que esta migración espera; no toco ninguna.',
			v_n, v_esperadas;
	end if;

	-- Y que ninguna tiene ya el texto nuevo, que significaría que esto se aplicó por otra vía.
	select count(*) into v_n
	from cambios_glosas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> 0 then
		raise exception '% afirmaciones tienen ya el texto nuevo.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	select string_agg(a.localizador, '|' order by a.afirmacion_id) into v_otro_antes
	from cambios_glosas c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_glosas c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las 10 quedaron con el texto nuevo, releído de la tabla.
	select count(*) into v_n
	from cambios_glosas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna conserva el viejo.
	select count(*) into v_n
	from cambios_glosas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> 0 then
		raise exception '% se quedaron con el texto viejo.', v_n;
	end if;

	select string_agg(a.localizador, '|' order by a.afirmacion_id) into v_otro_despues
	from cambios_glosas c
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
