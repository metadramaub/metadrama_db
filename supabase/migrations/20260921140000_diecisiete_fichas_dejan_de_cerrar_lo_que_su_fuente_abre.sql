-- Diecisiete fichas dejan de cerrar lo que su fuente deja abierto
--
-- Primera tanda de la pasada D, la descomposición en cláusulas. De las 458 cláusulas en que se
-- partieron 89 afirmaciones, 22 quedaron marcadas porque **la fuente abarca más —o menos— que la
-- ficha**. Se reparten en diecisiete fichas y ninguna era falso positivo.
--
-- El gesto es siempre el mismo: la ficha coge el primer valor que encuentra —un número, una lista,
-- un nombre— y lo da por el que la fuente ofrece, cuando la fuente sigue unas líneas más allá.
-- Ninguna comprobación mecánica podía verlo, porque **el valor que la ficha da sí está en el
-- pasaje**: lo que falta viene después.
--
-- ══ Las cinco que cambian algo de fondo
--
--   `fcc4589c` y las otras tres aliradas de Quilis. Decían que la estrofa de su canción oscila
--   `1ed98315`   «normalmente entre seis y doce» versos. La cita es literal y el rango, falso por
--   `d183bf08`   partida doble: ese «seis y doce» es de la **canción provenzal**, y la misma frase
--   `7f1b3434`   declara que **el máximo es «ilimitado»**, con nueve a veinte en Petrarca, quince en
--                Boscán y trece en Garcilaso. **Esto obliga a rehacer la tabla de las seis fuentes
--                que está en `cuestiones-para-el-ip.md`**, donde el solapamiento de las dos series se
--                describió apoyándose en el rango corto.
--   `514e4cdd`   la novena del *Diccionario* se quedaba con la mitad amable de la frase. La otra
--                mitad dice que esas uniones se dan «incluso sin repetición de rimas en las
--                semiestrofas, con lo que **parecería dudosa la unidad de la novena como estrofa**».
--                La fuente pone en duda que la novena sea una estrofa, y no lo decíamos.
--   `008e03ef`   «cubre por igual el hexasílabo y el heptasílabo» era nuestro, y el *Diccionario* lo
--                desmiente dos veces: el sentido 2 de «romancillo» excluye el heptasílabo, y la
--                entrada «endecha» —que el localizador ya citaba y la ficha no usaba— le da nombre
--                propio. Sexto caso del patrón de los sentidos numerados.
--   `8b5581b0`   la oncena «llega hasta Cervantes», y el epígrafe sigue, sin cambio de sección, hasta
--                el *Álbum de familia* de 2000. **Segundo «final prestado»** tras el «hasta Andrés
--                Bello» de la octava real, corregido el 20 de septiembre.
--   `588025c8`   el § 57 de Navarro no se detiene en las combinaciones de tres rimas: sigue con tres
--                de **dos** rimas que la ficha ignoraba, y que son otra categoría.
--
-- ══ Y una que nos devuelve una frase nuestra
--
-- `3d5e92bb` decía, en voz de Caparrós, que «la estrofa llegó a dar nombre al verso». No está en el
-- pasaje, que enumera nombres y pasa a la acentuación. **Y se sabe de dónde salió**: la migración
-- `20260805230000`, del 5 de agosto, pone encima de la afirmación el comentario «El octosílabo,
-- nombrado por la estrofa». Era nuestra razón para citar el pasaje y se coló dentro de la cita. La
-- observación es buena y su sitio es la prosa de la ficha. Con ella entra el cuarto nombre que la
-- fuente da y la ficha no recogía, «pie».
--
-- ══ El localizador
--
-- `bdac1b06` cita ahora la página de la entrada «vuelta», que le faltaba y de la que ahora toma el
-- segundo sentido. **La página no es la que la pasada C propuso**: dijo 497 y es la **498**, leída en
-- la hoja 500 del PDF. Lo vio David al preguntar si no faltaba localizador.
--
-- Textos aprobados por David uno a uno el 21 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 20;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_extension (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_extension (id8, antes, despues)
	values
		('008e03ef', 'Cuando el romance se compone en versos distintos del octosílabo recibe denominaciones específicas: romancillo el de versos de menos de ocho sílabas —lo que cubre por igual el hexasílabo y el heptasílabo— y romance heroico el endecasílabo.', 'Cuando el romance se compone en versos distintos del octosílabo recibe denominaciones específicas: romancillo el de versos de menos de ocho sílabas —aunque **un segundo sentido, de Rafael Lapesa, lo restringe a «versos hexasílabos o menores»**—, **endecha el de siete sílabas según Lapesa y el de siete o seis según Tomás de Iriarte**, y romance heroico el endecasílabo.'),
		('1ed98315', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuyas estrofas «normalmente oscilaban entre seis y doce» versos.', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuya estrofa tiene un mínimo de seis versos y un máximo que declara «ilimitado»: «normalmente oscilaban entre seis y doce» en la provenzal, pero «en PETRARCA, entre nueve y veinte; en BOSCÁN, en la primera canción quince; en GARCILASO, trece, etc.».'),
		('2d0599a0', 'Distingue las sextillas, de arte menor, de los sextetos, de arte mayor, y aparta como grupo propio los sextetos mixtos, los sextetos-lira y los simétricos, compuestos por dos series de tres versos. Describe sextetos eneasilábicos, decasilábicos, endecasilábicos, dodecasilábicos, de alejandrinos y pentadecasilábicos. Llama sextina real al sexteto de endecasílabos rimado a la manera de la octava real con pareado final, ABABCC, y lo documenta en Herrera, Cervantes, Lope de Vega y Bocángel.', 'Distingue las sextillas, de arte menor, de los sextetos, de arte mayor, y aparta como grupo propio los sextetos mixtos, los sextetos-lira y los simétricos, compuestos por dos series de tres versos. Describe, **con apartado y ejemplo propios**, sextetos eneasilábicos, decasilábicos, endecasilábicos, dodecasilábicos y de alejandrinos; **del pentadecasilábico solo hay una mención de paso, en el capítulo del verso, a propósito de un ejemplo de Salvador Rueda**. Llama sextina real al sexteto de endecasílabos rimado a la manera de la octava real con pareado final, ABABCC, y lo documenta en Herrera, Cervantes, Lope de Vega y Bocángel.'),
		('387f50dd', 'Distingue la desaparición sistemática de la rima, que llama verso blanco, de la esporádica, que llama verso suelto, y advierte que ninguna de las dos configura por sí sola un verso libre, porque el verso puede mantener intacta su estructura silábica y tonal al margen de la rima. Explica que desde el siglo XVI se conoce el verso blanco como serie de versos que no riman, y que en ella la percepción de la serie descansa en la igualdad silábica: una sucesión indeterminada de endecasílabos forma poema porque todos comparten medida y periodo rítmico.', 'Distingue la desaparición sistemática de la rima, que llama verso blanco, de la esporádica, que llama verso suelto, y advierte que ninguna de las dos configura por sí sola un verso libre, porque el verso puede mantener intacta su estructura silábica y tonal al margen de la rima. Explica que desde el siglo XVI se conoce el verso blanco como serie de versos que no riman, y que en ella la percepción de la serie descansa en «la igualdad **o proporcionalidad** silábica»: una sucesión indeterminada de endecasílabos forma poema porque todos comparten medida y periodo rítmico.'),
		('3d5e92bb', 'Recoge «verso de redondilla mayor» entre los nombres tradicionales del octosílabo, junto a verso de arte menor y de arte real: la estrofa llegó a dar nombre al verso.', 'Recoge «verso de redondilla mayor» entre los nombres tradicionales del octosílabo, junto a **pie**, verso de arte menor y de arte real.'),
		('4848b0a0', 'Es quien fija el reparto entre las dos: «las septillas y septetos suelen organizarse como estrofas compuestas de dos simples, de 4+3 […] para ellas cabe también **la distinción según el tipo de verso que acojan**», y señala aparte las formas mixtas, como el septeto-lira. En los poetas del siglo XX las ve asomar «ocasionalmente, sin que la forma se reitere a lo largo de un poema», como semiestrofas de poemas poliestróficos.', 'Es quien fija el reparto entre las dos: «las septillas y septetos suelen organizarse como estrofas compuestas de dos simples, de 4+3 […] para ellas cabe también **la distinción según el tipo de verso que acojan**», y señala aparte las formas mixtas, como el septeto-lira. En **poetas actuales y del siglo XX** las ve asomar «ocasionalmente, sin que la forma se reitere a lo largo de un poema», como semiestrofas de poemas poliestróficos.'),
		('514e4cdd', 'Define la novena como estrofa de nueve versos sin más rasgo común necesario. Señala que puede formarse uniendo estrofas de cuatro y cinco versos, añadiendo un verso a una octava o suprimiéndolo de una décima, y que puede combinar octosílabos con tetrasílabos o endecasílabos con heptasílabos.', 'Define la novena como estrofa de nueve versos sin más rasgo común necesario. Señala que puede formarse uniendo estrofas de cuatro y cinco versos, «**incluso sin repetición de rimas en las semiestrofas, con lo que parecería dudosa la unidad de la novena como estrofa**», añadiendo un verso a una octava o suprimiéndolo de una décima, y que puede combinar octosílabos con tetrasílabos o endecasílabos con heptasílabos.'),
		('588025c8', 'La describe como dos cuartetos en versos de arte mayor con sólo tres rimas, generalmente en forma abrazada ABBA:ACCA, y otras veces con un cuarteto abrazado y otro cruzado. Registra aparte, como caso singular, una carta de Tirso de Molina en *Quien calla otorga* compuesta en una copla de cuatro rimas finales ABBA:CDDC y otras cuatro en los primeros hemistiquios; los personajes aluden al carácter antiguo de la estrofa, «aunque en realidad difiera bastante del modelo tradicional».', 'La describe como dos cuartetos en versos de arte mayor con sólo tres rimas, generalmente en forma abrazada ABBA:ACCA y, «en nivel inmediato», ABAB:BCCB; y registra además combinaciones de solo dos rimas: ABAB:ABAB, ABBA:ABBA y ABAB:BAAB. Registra aparte, como caso singular, una carta de Tirso de Molina en *Quien calla otorga* compuesta en una copla de cuatro rimas finales ABBA:CDDC y otras cuatro en los primeros hemistiquios; los personajes aluden al carácter antiguo de la estrofa, «aunque en realidad difiera bastante del modelo tradicional».'),
		('69a00fa1', 'Le da epígrafe propio. Plantea la objeción —«si definimos la estrofa como agrupación de versos, no podría existir la estrofa de un solo verso, como no podría denominarse verso a uno solo, si es que no se ha extraído de un conjunto»— y la resuelve: «el verso único puede funcionar como estrofa y como poema, en cada caso, porque se relaciona *in absentia* con versos semejantes». Sitúa su procedencia: «la mayoría de las veces, con todo, el verso único pertenece al género prepoético de los motes, emblemas, refranes, sentencias, pie de glosa, estribillo, etc.». Y distingue el verso suelto que ocupa el lugar de una estrofa dentro de un poema, «muy frecuente en poesía contemporánea», del poema de un solo verso, del que da repertorio por medidas, del bisílabo al endecasílabo y más allá.', 'Le da epígrafe propio. Plantea la objeción —«si definimos la estrofa como agrupación de versos, no podría existir la estrofa de un solo verso, como no podría denominarse verso a uno solo, si es que no se ha extraído de un conjunto»— y la resuelve: «el verso único puede funcionar como estrofa y como poema, en cada caso, porque se relaciona *in absentia* con versos semejantes». Sitúa su procedencia: «la mayoría de las veces, con todo, el verso único pertenece al género prepoético de los motes, emblemas, refranes, sentencias, pie de glosa, estribillo, etc.». Y distingue el verso suelto que ocupa el lugar de una estrofa dentro de un poema, «muy frecuente en poesía contemporánea», del poema de un solo verso, del que da repertorio por medidas, **del bisílabo al alejandrino, y un apartado final de «formas mayores y versiculares» con ejemplos de quince, diecinueve, veintiuna y veintitrés sílabas**.'),
		('7f1b3434', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuyas estrofas «normalmente oscilaban entre seis y doce» versos.', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuya estrofa tiene un mínimo de seis versos y un máximo que declara «ilimitado»: «normalmente oscilaban entre seis y doce» en la provenzal, pero «en PETRARCA, entre nueve y veinte; en BOSCÁN, en la primera canción quince; en GARCILASO, trece, etc.».'),
		('7fd372ca', 'Define la simple y sus modificaciones habituales, la compuesta, la chamberga, la gitana —cuyo tercer verso puede tener diez, once o doce sílabas—, la real 10-6-10-6 y la serie simple arromanzada que mantiene una misma asonancia entre estrofas.', 'Define la simple y sus modificaciones habituales, la compuesta, la chamberga, la gitana —cuyo tercer verso puede tener diez, once o doce sílabas—, la real 10-6-10-6 y la serie simple arromanzada, que tiene «igual asonancia **en los versos pares** de las distintas estrofas».'),
		('880f3d66', 'Lo sitúa entre las formas originarias y primitivas de la poesía, y recoge sus modalidades en la lírica tradicional: el cosante, el perqué, las canciones infantiles. Señala que aparece esporádicamente en la comedia del Siglo de Oro, donde resulta muy funcional para intervenciones breves y concisas, y que su función más importante ha sido servir de estribillo.', 'Lo sitúa entre las formas originarias y primitivas de la poesía, y recoge sus modalidades en la lírica tradicional: el cosante, el perqué, las canciones infantiles. Señala que aparece esporádicamente en la comedia del Siglo de Oro, donde resulta muy funcional para intervenciones breves y concisas, y que su función más importante «**ha sido y es**» la de servir de estribillo.'),
		('8b5581b0', 'Explica su formación: «la copla empezó por estructurarse como quintilla más sextilla (5-6), pero casi siempre necesitó de las cuatro rimas, como mínimo, para conjuntar sus versos», y describe la realización con quiebros —quintilla `abaab` más sextilla de pie quebrado `cdecde`— en Francisco de Costana, Tapia y Garci Sánchez de Badajoz, donde «los versos quebrados se encargan del descenso climático del poema». La fecha con precisión para este catálogo: «se encuentra durante todo el periodo medieval y llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)».', 'Explica su formación: «la copla empezó por estructurarse como quintilla más sextilla (5-6), pero casi siempre necesitó de las cuatro rimas, como mínimo, para conjuntar sus versos», y describe la realización con quiebros —quintilla `abaab` más sextilla de pie quebrado `cdecde`— en Francisco de Costana, Tapia y Garci Sánchez de Badajoz, donde «los versos quebrados se encargan del descenso climático del poema». La fecha para este catálogo: «se encuentra durante todo el periodo medieval y llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)», **y sigue documentándola, «más rara hoy», en el siglo XX y hasta 2000 —Concha Méndez, Muñoz Rojas, Jorge Guillén, Gamoneda, J. Benito de Lucas—**.'),
		('8d77881a', 'La cuenta entre las formas mixtas de siete versos y advierte que tiene «múltiples variedades», sin enumerarlas: «asimismo son importantes algunas de sus formas mixtas, como el septeto-lira con sus múltiples variedades». En los poetas del siglo XX la ve aparecer como semiestrofa de poemas poliestróficos.', 'La cuenta entre las formas mixtas de siete versos y advierte que tiene «múltiples variedades», sin enumerarlas: «asimismo son importantes algunas de sus formas mixtas, como el septeto-lira con sus múltiples variedades». De **septillas y septetos en general** dice que en poetas actuales y del siglo XX asoman ocasionalmente, sin que la forma se reitere a lo largo de un poema, como semiestrofas de poemas poliestróficos.'),
		('962207aa', 'Registra que Lope recomendaba las décimas para las quejas, y que fuera del teatro se emplean, por su concisión, en composiciones ingeniosas y de carácter epigramático.', 'Registra que Lope recomendaba las décimas para las quejas, y que fuera del teatro se emplean, por su concisión, en composiciones ingeniosas, **delicadas** y de carácter epigramático.'),
		('a5faa793', 'Recoge abbba entre las disposiciones de la quintilla octosílaba sin marcarla como anómala, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca— que describe como transgresión de las viejas normas.', 'Recoge abbba entre las disposiciones de la quintilla octosílaba sin marcarla como anómala, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca, **abcaa y otras**— que describe como transgresión de las viejas normas.'),
		('a691813f', 'La presenta como derivada de la copla de arte menor y «algo posterior»: «alcanza una cuarta rima, por lo que cada semiestrofa es una auténtica redondilla». Da el reparto histórico —la de arte menor domina el siglo XIV, la castellana es mayoritaria en el XV— y **la señala como la que permanece, forma popularísima a lo largo de los siglos XVI y XVII**. Al tratar el epigrama la nombra otra vez: optó por «la brevedad de dos redondillas (es decir: de una copla castellana) o dos quintillas».', 'La presenta como derivada de la copla de arte menor y «algo posterior»: «alcanza una cuarta rima, por lo que cada semiestrofa es una auténtica redondilla **(abba: cddc; abab: cdcd; etc.)**». Da el reparto histórico —la de arte menor domina el siglo XIV, la castellana es mayoritaria en el XV— y **la señala como la que permanece, forma popularísima a lo largo de los siglos XVI y XVII**. Al tratar el epigrama la nombra otra vez: optó por «la brevedad de dos redondillas (es decir: de una copla castellana) o dos quintillas, **una décima, etc.**».'),
		('bdac1b06', 'Ofrece la misma estructura canónica de cabeza de dos a cuatro versos, dos mudanzas simétricas y vuelta de tres o cuatro. Precisa la relación de rimas del enlace y de la vuelta con mudanza y cabeza, la repetición del estribillo cuando hay varias estrofas, la estabilidad de la redondilla o cuarteta central y la variabilidad del comienzo y el final.', 'Ofrece la misma estructura canónica de cabeza de dos a cuatro versos, dos mudanzas simétricas y vuelta de tres o cuatro versos que, según el segundo sentido de «vuelta», «**se corresponde en extensión con la cabeza**». Precisa la relación de rimas del enlace y de la vuelta con mudanza y cabeza, la repetición del estribillo cuando hay varias estrofas, la estabilidad de la redondilla o cuarteta central y la variabilidad del comienzo y el final.'),
		('d183bf08', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuyas estrofas «normalmente oscilaban entre seis y doce» versos.', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuya estrofa tiene un mínimo de seis versos y un máximo que declara «ilimitado»: «normalmente oscilaban entre seis y doce» en la provenzal, pero «en PETRARCA, entre nueve y veinte; en BOSCÁN, en la primera canción quince; en GARCILASO, trece, etc.».'),
		('fcc4589c', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuyas estrofas «normalmente oscilaban entre seis y doce» versos.', 'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en su canción, cuya estrofa tiene un mínimo de seis versos y un máximo que declara «ilimitado»: «normalmente oscilaban entre seis y doce» en la provenzal, pero «en PETRARCA, entre nueve y veinte; en BOSCÁN, en la primera canción quince; en GARCILASO, trece, etc.».');

	select count(*) into v_n
	from cambios_extension c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_extension c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_extension c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguno de los valores cerrados que se retiran queda en el catálogo.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where resumen like '%oscilaban entre seis y doce» versos%'
		or resumen like '%la estrofa llegó a dar nombre al verso%'
		or resumen like '%y llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)».'
		or resumen like '%cubre por igual el hexasílabo y el heptasílabo%'
		or resumen like '%al endecasílabo y más allá%';
	if v_n <> 0 then
		raise exception '% fichas conservan un valor que esta migración abre.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 1;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_extension_loc (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_extension_loc (id8, antes, despues)
	values
		('bdac1b06', 'Entrada «villancico», pp. 495-496, y «vuelta»', 'Entradas «villancico», pp. 495-496, y «vuelta», p. 498');

	select count(*) into v_n
	from cambios_extension_loc c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set localizador = c.despues
	from cambios_extension_loc c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_extension_loc c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
