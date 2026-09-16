-- Doce fichas dejan de decir en voz de la fuente lo que la fuente no dice
--
-- Tercera y última tanda de la pasada D. Quince cláusulas quedaron marcadas como no sostenidas por
-- el pasaje. Una ya se había arreglado esa misma mañana y otra no lo necesitaba —en una ficha de
-- silencio, marcar «no aparece» sobre su propio «No la registra» es la respuesta esperada—. Quedan
-- trece, en doce fichas. La decimotercera ficha la encontró una guarda.
--
-- ══ Lo que se retira, y por qué no se pierde nada
--
--   `76b5b6b9`  Cuatro fichas decían que **«su repertorio no es el de la métrica española sino el de
--   `19a5eb39`  las formas que Lope usa en sus comedias»**. El capítulo V **no declara su alcance en
--   `e6434e41`  ninguna parte**: eso lo sabemos por el título del libro, que no tenemos. Lo que sí
--   `aef2b12f`  está, y es comprobable, son sus veinte entradas repartidas en dos secciones y cuatro
--               anotaciones «en Lope» dentro de formas de nombre general. La razón del silencio se
--               mantiene; deja de apoyarse en lo que sabemos del libro por fuera.
--   `b55ae482`  Las dos enlazadas del *Diccionario* atribuían a esa obra la copla encadenada «de la
--   `da0d0e2d`  **gaya ciencia**». La expresión **no aparece ni una vez** en el *Diccionario*, que
--               vincula el artificio al «paralelismo tan frecuente de la poesía gallego-portuguesa».
--               Quien dice «gaya ciencia» es **Navarro, en el § 131**, hablando de estas mismas
--               estrofas. Es la frase de una fuente puesta en boca de otra, y **la cuarta vez que el
--               copiar-pegar aparece con el donante identificado**.
--   `423b6dca`  **y una tercera** que la pasada D no había mirado: la redondilla enlazada decía lo
--               mismo. La cogió la guarda que pregunta por el catálogo entero, al fallar el primer
--               intento de aplicar esta migración. **Quinta vez que una guarda encuentra una
--               hermana que nadie había buscado.**
--   `ff6f74f9`  el soneto de Caparrós añadía «una condición que no es métrica sino de composición». La
--               exigencia está; la contraposición la poníamos nosotros, para explicar por qué no cabe
--               en la arquitectura.
--   `49b4e370`  «experimentos que no son realizaciones de la forma»: Jauralde los presenta como usos y
--               ensayos sobre el molde de la décima, no como algo que quede fuera de ella.
--
-- ══ Dos que dicen más al corregirse
--
--   `b436934c`  «Cuenta los doce» no está en ninguna frase, y lo que sí está es más interesante:
--               **Jauralde clasifica la copla manriqueña dentro de las estrofas de ocho versos**, y
--               el desglose «3+3+3+3» solo aparece en nota y para el caso de Jorge Manrique.
--   `8e712f47`  «su única estrofa de ocho versos es la octavilla» era falso —el § 5.4.7 de Quilis
--               tiene cuatro—, y el matiz que faltaba es justo el que sostiene el silencio: la
--               octavilla es la única **de arte menor**.
--
-- ══ Y dos que eran mías, de esta misma semana
--
-- `a71991db` decía que M&B llaman «sexteto» a los seis versos que siguen a **los dos cuartetos** del
-- soneto. Ellos escriben «los primeros ocho», y la palabra «cuarteto» aparece una sola vez en todo
-- el capítulo, en otro epígrafe. Venía de la ficha vieja y se conservó al reescribirla el 21 de
-- septiembre: se arreglaron los cuatro esquemas y se dejó pasar el término.
--
-- `4b2baf4c` y `8dc1b345` decían que «el capítulo no menciona en ningún punto el encadenamiento
-- entre estrofas». Se escribió el 20 de septiembre **para sustituir una frase inventada**, y
-- generalizó de «este epígrafe no lo dice» a «el capítulo no lo dice» sin comprobar lo segundo: el
-- capítulo tiene dos epígrafes de tercetos que se distinguen justamente por eso. **Las dos veces el
-- defecto fue el mismo que se estaba corrigiendo.**
--
-- ══ Lo que David decidió mantener
--
-- La pasada señaló también que `90ca3952` llama «realización **áurea**» al ejemplo de Baltasar del
-- Alcázar sin que Jauralde ponga etiqueta de época. **Se queda**: Alcázar es áureo sin discusión
-- —1530-1606— y señalar que un ejemplo cae en el período que interesa al catálogo es orientación
-- útil. Queda dicho aquí que **la etiqueta es nuestra y no de la fuente**.
--
-- Textos aprobados por David el 21 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 14;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_noaparece (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_noaparece (id8, antes, despues)
	values
		('19a5eb39', 'No la registra. Su repertorio no es el de la métrica española sino el de las formas que Lope usa en sus comedias, y lo componen veinte entradas entre las que esta no figura.', 'No la registra. Sus veinte entradas, repartidas entre «Metros Españoles» y «Formas Métricas Italianas», describen cada forma con anotaciones sobre el uso de Lope —«en estrofas (en Lope) de cinco a doce versos», «el tipo más corriente en Lope», «en las últimas comedias de Lope»—, y esta no figura entre ellas.'),
		('423b6dca', 'No la registra. Sí tiene entradas para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)» con que este diccionario señala de quién es el término, y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», con «copla capfinida» y «canción de coleo» como otros términos. Ninguna de ellas es una redondilla enlazada.', 'No la registra. Sí tiene entradas para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)» con que este diccionario señala de quién es el término, y «terceto enlazado»— y para la copla encadenada, «estrofa en la que hay lexaprén», artificio que vincula al «paralelismo tan frecuente de la poesía gallego-portuguesa», con «copla capfinida» y «canción de coleo» como otros términos. Ninguna de ellas es una redondilla enlazada.'),
		('49b4e370', 'Recorre la historia de la estrofa: aparición tardía, «muy a finales del siglo XVI», porque «**se suele señalar** que la inventó Vicente Espinel en sus *Diversas rimas* (1591)», y el nombre de espinela desde *La Dorotea* de Lope; popularísima desde entonces «para todo tipo de circunstancias, incluyendo los parlamentos teatrales». **Le documenta cuatro medidas además de la octosílaba, cada una con ejemplo**: hexasilábica con estribillo en **Góngora**, endecasilábica en la *Elegía moral a la Virtud* de **Meléndez Valdés** y en las «baladas» de Rubén Darío, pentasilábica en Concha Méndez y heptasilábica en Luis García Montero. Registra también experimentos que no son realizaciones de la forma: la escala métrica de Darío «empezando por décima de bisílabo, luego trisílabo», las décimas en verso blanco y las asonantadas de Jorge Guillén en *Cántico*, que presenta como ensayo sobre la estrofa —«al rimarlas en asonante en vez de en consonante, que era lo tradicional»—.', 'Recorre la historia de la estrofa: aparición tardía, «muy a finales del siglo XVI», porque «**se suele señalar** que la inventó Vicente Espinel en sus *Diversas rimas* (1591)», y el nombre de espinela desde *La Dorotea* de Lope; popularísima desde entonces «para todo tipo de circunstancias, incluyendo los parlamentos teatrales». **Le documenta cuatro medidas además de la octosílaba, cada una con ejemplo**: hexasilábica con estribillo en **Góngora**, endecasilábica en la *Elegía moral a la Virtud* de **Meléndez Valdés** y en las «baladas» de Rubén Darío, pentasilábica en Concha Méndez y heptasilábica en Luis García Montero. Registra también **ensayos sobre el propio molde**: la escala métrica de Darío «empezando por décima de bisílabo, luego trisílabo», las décimas en verso blanco y las asonantadas de Jorge Guillén en *Cántico*, que presenta como ensayo sobre la estrofa —«al rimarlas en asonante en vez de en consonante, que era lo tradicional»—.'),
		('4b2baf4c', 'No la distinguen. Sus «coplas de pie quebrado» abarcan por extensión, de cinco a doce versos, sin atender a si la rima enlaza una estrofa con la siguiente: el capítulo no menciona en ningún punto el encadenamiento entre estrofas.', 'No la distinguen. Sus «coplas de pie quebrado» abarcan por extensión, de cinco a doce versos, sin atender a si la rima enlaza una estrofa con la siguiente: en el capítulo el encadenamiento solo aparece a propósito de los tercetos, que separan en «Terza rima» y «Tercetos (sin encadenar)».'),
		('76b5b6b9', 'No la registra. Su repertorio no es el de la métrica española sino el de las formas que Lope usa en sus comedias, y lo componen veinte entradas entre las que esta no figura.', 'No la registra. Sus veinte entradas, repartidas entre «Metros Españoles» y «Formas Métricas Italianas», describen cada forma con anotaciones sobre el uso de Lope —«en estrofas (en Lope) de cinco a doce versos», «el tipo más corriente en Lope», «en las últimas comedias de Lope»—, y esta no figura entre ellas.'),
		('8dc1b345', 'No la distinguen. Sus «coplas de pie quebrado» son octosílabos combinados con su quebrado «en estrofas (en Lope) de cinco a doce versos», sin atender a si la rima enlaza una estrofa con la siguiente: el capítulo no menciona en ningún punto el encadenamiento entre estrofas.', 'No la distinguen. Sus «coplas de pie quebrado» son octosílabos combinados con su quebrado «en estrofas (en Lope) de cinco a doce versos», sin atender a si la rima enlaza una estrofa con la siguiente: en el capítulo el encadenamiento solo aparece a propósito de los tercetos, que separan en «Terza rima» y «Tercetos (sin encadenar)».'),
		('8e712f47', 'No registra una estrofa de ocho versos con cuatro rimas independientes: su única estrofa de ocho versos es la octavilla, cuyas dos combinaciones de rima comparten rima entre las dos mitades.', 'No registra una estrofa de ocho versos con cuatro rimas independientes: su única estrofa de ocho versos **de arte menor** es la octavilla, cuyas dos combinaciones de rima comparten rima entre las dos mitades; **las otras tres del § 5.4.7 —copla de arte mayor, octava real y octava italiana— son de arte mayor**.'),
		('a71991db', '**«Sexteto»** no nombra en su repertorio una estrofa de seis versos: nombra los seis versos que siguen a los dos cuartetos del soneto, y es dentro del epígrafe «Soneto» donde describen sus rimas. No hay epígrafe «Sexteto» entre los veinte del capítulo, aunque sí registran estrofas de seis versos bajo otros nombres —«Liras» y «Sestina»—.', '**«Sexteto»** no nombra en su repertorio una estrofa de seis versos: nombra los seis versos que siguen a «**los primeros ocho**» del soneto, y es dentro del epígrafe «Soneto» donde describen sus rimas. No hay epígrafe «Sexteto» entre los veinte del capítulo, aunque sí registran estrofas de seis versos bajo otros nombres —«Liras» y «Sestina»—.'),
		('aef2b12f', 'No la registra. Su repertorio no es el de la métrica española sino el de las formas que Lope usa en sus comedias, y lo componen veinte entradas entre las que esta no figura.', 'No la registra. Sus veinte entradas, repartidas entre «Metros Españoles» y «Formas Métricas Italianas», describen cada forma con anotaciones sobre el uso de Lope —«en estrofas (en Lope) de cinco a doce versos», «el tipo más corriente en Lope», «en las últimas comedias de Lope»—, y esta no figura entre ellas.'),
		('b436934c', 'Cuenta los doce: dice que aunque «se presenta muchas veces como octavilla de pie quebrado, su forma más habitual es la de doble sextilla con seis rimas», y señala que el Romanticismo imitó después la sextilla simple.', '**La trata dentro de las estrofas de ocho versos** y dice que aunque «se presenta muchas veces como octavilla de pie quebrado, su forma más habitual es la de doble sextilla con seis rimas»; **solo en nota, y para el caso de Jorge Manrique, desglosa «3+3+3+3»**. Señala que el Romanticismo imitó después la sextilla simple.'),
		('b55ae482', 'No la registra: su entrada «séptima» no recoge ninguna variedad enlazada y no hay «septeto enlazado» ni equivalente. Sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén».', 'No la registra: su entrada «séptima» no recoge ninguna variedad enlazada y no hay «septeto enlazado» ni equivalente. Sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada, «estrofa en la que hay lexaprén», artificio que vincula al «paralelismo tan frecuente de la poesía gallego-portuguesa».'),
		('da0d0e2d', 'No la registra. Ninguna de sus variedades de sextilla —alterna, correlativa, paralela y de pie quebrado— contempla el enlace con la estrofa siguiente, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», ninguna de ellas es una sextilla enlazada.', 'No la registra. Ninguna de sus variedades de sextilla —alterna, correlativa, paralela y de pie quebrado— contempla el enlace con la estrofa siguiente, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada, «estrofa en la que hay lexaprén», artificio que vincula al «paralelismo tan frecuente de la poesía gallego-portuguesa», ninguna de ellas es una sextilla enlazada.'),
		('e6434e41', 'No la registra. Su repertorio no es el de la métrica española sino el de las formas que Lope usa en sus comedias, y lo componen veinte entradas entre las que esta no figura.', 'No la registra. Sus veinte entradas, repartidas entre «Metros Españoles» y «Formas Métricas Italianas», describen cada forma con anotaciones sobre el uso de Lope —«en estrofas (en Lope) de cinco a doce versos», «el tipo más corriente en Lope», «en las últimas comedias de Lope»—, y esta no figura entre ellas.'),
		('ff6f74f9', 'Define el soneto como poema de catorce versos de arte mayor formado por catorce endecasílabos en su forma clásica, y añade una condición que no es métrica sino de composición: debe tener unidad temática y un desarrollo completo.', 'Define el soneto como poema de catorce versos de arte mayor formado por catorce endecasílabos en su forma clásica, y añade que «**debe tener unidad temática y un desarrollo completo**».');

	select count(*) into v_n
	from cambios_noaparece c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_noaparece c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_noaparece c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna de las cuatro frases retiradas queda en ficha alguna del catálogo. Las guardas
	-- de estas tandas han encontrado ya dos hermanas que nadie había visto, así que se pregunta
	-- por todo el catálogo y no solo por las fichas que esta migración toca.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where resumen ilike '%no es el de la métrica española%'
		or resumen ilike '%no menciona en ningún punto el encadenamiento%'
		or resumen ilike '%copla encadenada de la gaya ciencia%'
		or resumen ilike '%los dos cuartetos del soneto%'
		or resumen ilike '%que no es métrica sino de composición%';
	if v_n <> 0 then
		raise exception '% fichas conservan alguna de las frases que esta migración retira.', v_n;
	end if;

	-- Y que «gaya ciencia» no vuelve a atribuirse al Diccionario, que no la usa nunca.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2016 and a.resumen ilike '%gaya ciencia%';
	if v_n <> 0 then
		raise exception '% fichas del Diccionario siguen diciendo «gaya ciencia».', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
