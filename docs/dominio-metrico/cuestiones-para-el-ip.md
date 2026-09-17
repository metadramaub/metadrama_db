# Cuestiones para el IP

Este archivo reúne **lo que sigue sin decidir y necesita criterio filológico**, forma por forma. No
describe el catálogo: eso se lee en `/formas`, que se genera del dato y no puede quedarse viejo.

**Solo entra aquí lo que las fuentes no resuelven**, en alguna de sus tres maneras: porque callan,
porque se contradicen entre sí, o porque documentan algo y lo que falta por decidir es si el
proyecto lo sigue. Lo que ya está en el catálogo, lo que es deuda técnica y lo que una fuente
contesta sin que quede nada que elegir **no se guarda aquí**.

## Lo urgente: dónde puede haber una forma mal modelada

_Puesto el 28 de agosto de 2026._ De todo lo abierto, estas son las que **no son un matiz sino
la sospecha de que una forma no está donde debe**: o fija lo que no fija, o reúne bajo una arquitectura
lo que quizá sean dos, o tiene un nivel que no se sostiene. Son las que conviene resolver antes de que
se anote mucho con ellas, porque cambiarlas después obliga a revisar lo anotado.

1. **El septeto-lira fija su medida y quizá no deba.** Es la única de las cinco aliradas que declara
   posiciones —`7 11 7 11 7 7 11`—; las otras cuatro declaran repertorio abierto. Y su propia
   definición llama a esa disposición «la realización que la documenta», que es lenguaje de una entre
   varias. ⇒ [Lira, sexteto-lira y septeto-lira](#lira-sexteto-lira-y-septeto-lira)
2. **La endecha real reúne tres regímenes en una sola arquitectura**: asonante, consonante y sin
   rima. ¿Es una forma con tres realizaciones o son formas distintas que comparten medida?
   ⇒ [Endecha real](#endecha-real) 4
3. **El sexteto-lira: si su repertorio no tiene cierre y sus dos ejes son libres, ¿qué queda del
   nivel?** Es la pregunta más antigua de la lista y la que más estructura mueve.
   ⇒ [Sexteto-lira](#sexteto-lira) 1
4. **La canción sin rima: ¿arquitectura o forma propia?** Morley y Bruerton la registran como
   categoría aparte. ⇒ [Canción petrarquista](#canción-petrarquista) 1
5. **Qué repertorios de esquema están cerrados y cuáles son recortes del corpus.** Afecta al sexteto,
   al soneto y a la copla de arte mayor a la vez. ⇒ [Las que cruzan formas](#las-que-cruzan-formas)

_Y una que no toca el nivel pero deja un hueco al anotar:_ **el remate y el eslabón de la canción no
declaran ni medida ni rima**, así que de un remate leído solo queda registrado cuántos versos tiene.
⇒ [Canción petrarquista](#canción-petrarquista) 5

## Cómo se lee, y qué relación tiene con los pendientes

Hay **dos inventarios y no dicen lo mismo**:

- **[PENDIENTES](../PENDIENTES.md)** es lo que el proyecto
  tiene que **hacer**, ordenado por lo que bloquea los dos hitos siguientes. Ahí van las deudas del
  modelo, los huecos de cobertura y lo que el editor no sabe registrar.
- **Este archivo** es lo que hay que **decidir**, y la decisión es filológica: qué admite una forma,
  hasta dónde llega su repertorio, si una realización documentada entra o se queda fuera.

Muchas preguntas tienen las dos caras. Cuando la tienen, **el apunte lleva su código** —`⇒ A3`,
`⇒ B3`— y ahí se lee el lado técnico. Ninguna pregunta de este archivo impide anotar hoy, y
`npm run audit:metrica` no señala ningún defecto.

Cada apunte cierra en cursiva con **qué cambiaría si se decide otra cosa**.

## Las que cruzan formas

Son las que no se ven leyendo una sola sección. Conviene decidirlas juntas, porque responderlas
forma a forma produce criterios distintos para el mismo caso.

| Cruce                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Dónde                                                                                                                       | Estado                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Qué es una variedad**, si el repertorio del sexteto-lira no tiene cierre y sus dos ejes resultan libres                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | [Sexteto-lira](#sexteto-lira) 1                                                                                             | **abierto**: decidir si el nivel se conserva                                                                                                                                                                                                                                                                                                                                              |
| **Qué repertorios de esquema están cerrados** y cuáles son recortes del corpus                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | [Sexteto](#sexteto) 3 · [Soneto](#soneto) 1 · [Copla de arte mayor](#copla-de-arte-mayor) 1 · [Octava real](#octava-real) 2 | **abierto, y menos urgente desde el 25 de agosto de 2026**: con la salida abierta, un repertorio incompleto ya no pierde el dato —el editor declara lo que ve y el catálogo lo reconoce si ya lo tenía—. _El de las medidas se cerró el 22 de agosto: la medida no compromete la norma y se declara cuando una fuente la documenta —[criterios de nivel § 3.6](./criterios-de-nivel.md)—_ |
| **Qué elecciones dependen de otras**, que el modelo hoy no sabe expresar                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | [Copla real](#copla-real) 4 · [Novena](#novena) 2 · [Sexteto-lira](#sexteto-lira) 1                                         | **abierto** · ⇒ **B3**                                                                                                                                                                                                                                                                                                                                                                    |
| Cómo se representa una **norma abierta** sin enumerar cada realización                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | [Silva](#silva) 1 · [Seguidilla](#seguidilla) 1 · [Novena](#novena) 1                                                       | **abierto en lo filológico; el aparato se cerró el 25 de agosto de 2026** con las reglas 2 y 3 de [criterios de nivel § 3.3](./criterios-de-nivel.md): donde hay unidad, lista y salida abierta, y lo escrito se normaliza y se casa con el catálogo. _Lo que sigue sin decidir es qué acota cada norma, no cómo se registra._                                                            |
| **Modelar lo que las fuentes describen aunque el corpus no lo traiga**, o no                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | [Sexteto](#sexteto) 5 · [Sextilla](#sextilla) 6 · [Copla real](#copla-real) 2 · [Endecha real](#endecha-real) 1             | **abierto** ·                                                                                                                                                                                                                                                                                                                                                                             |
| **Los finales esdrújulos y agudos**, ¿en todas las formas o solo donde se documenten?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | abajo                                                                                                                       | **abierto** · ⇒ **B2**                                                                                                                                                                                                                                                                                                                                                                    |
| **Cuántos versos admite quebrados la redondilla y la copla de arte menor.** Las dos documentan el quiebro **sin nombrar el verso**: Navarro Tomás registra la redondilla quebrada con ejemplos —«la cruzada `abab` en serie de siete unidades… y la abrazada `abba` entre las coplas sueltas»— y no dice dónde cae; Caparrós, de la copla de arte menor, «admite versos quebrados de cuatro sílabas» y tampoco. **Es silencio, no una regla enunciada**, así que ninguna da máximo. _La copla castellana salió de aquí el 29 de agosto de 2026: § 65 sí nombra el suyo, el sexto_ | [Redondilla](#redondilla) · [Quintilla](#quintilla)                                                                         | **abierto** · ⇒ regla 5 bis del [§ 3.6](./criterios-de-nivel.md)                                                                                                                                                                                                                                                                                                                          |

### Los finales esdrújulos y agudos

El rasgo `final_acentual` marca la terminación sostenida en los finales de verso —esdrújula o
aguda—, y **se declara sin un criterio que una a las arquitecturas que lo llevan**. Contrastado el
dato, hay un desajuste que se ve a simple vista:

Contrastado de nuevo el 25 de agosto de 2026, al cerrar B2. **Seis arquitecturas declaran
`esdrujulo` y las seis lo preguntan ya**; el desajuste que quedaba era el del endecasílabo suelto,
que lo declaraba y no lo preguntaba, y se cerró ese día.

| Declara `esdrujulo` el catálogo                   | Tiene subtipo en el vocabulario legado |
| ------------------------------------------------- | -------------------------------------- |
| canción petrarquista · sin rima con pareado final | ✔ `cancion_sin_rima_de_esdrujulos`     |
| octava real                                       | ✔ `octava_real_de_esdrujulos`          |
| sexteto-lira                                      | ✔ `sexteto_lira_de_esdrujulos`         |
| terceto                                           | ✔ `terceto_de_esdrujulos`              |
| endecasílabo suelto                               | ✔ `endecasilabo_suelto_de_esdrujulos`  |
| **soneto**                                        | **—**                                  |

**Lo que queda del desajuste es una sola fila**: el soneto lo declara sin término legado que lo
respalde. Las otras cinco se corresponden una a una con el vocabulario, y ninguno de los seis
términos de esdrújulos se queda ya sin destino.

Y el valor `agudo` lo llevan la octava aguda —donde es definitorio y no se pregunta, porque su
propio esquema dice dónde cae—, el septeto y el sexteto alejandrino, mientras Jauralde dice que «la
modalidad aguda se extendió a otras muchas variedades estróficas, **como la sextilla y la décima**».

_La pregunta es si esto se declara **en todas o casi todas las formas** —porque cualquier estrofa
puede rimar en esdrújulos o en agudos, y entonces lo que el rasgo aporta es poder anotarlo cuando
ocurre— o **solo donde una fuente o el corpus lo documenten**, y entonces hay que cerrar el
desajuste en los dos sentidos. Ninguna de las seis monografías respalda hoy el rasgo en la octava
real: lo que lo sostiene es el vocabulario legado._

## Demarcador

1. **Las formas generales no tienen prioridad residual.** El **sexteto** cumple una función
   residual frente a formas más específicas de seis versos de arte mayor, y desde el 21 de agosto
   la **septilla**, la **oncena** y las tres **enlazadas** conviven con estrofas de su misma
   extensión. El antiguo `grado_especificacion` pretendía que el demarcador ofreciera la forma más
   específica, pero se retiró porque el motor nunca lo usó: hoy todas las hipótesis se puntúan al
   mismo nivel. _Hace falta una regla explícita de prioridad o una salida final separada. No es una
   relación `subtipo_de` ni `compuesta_por`: esas describen la ontología de las formas, no el orden
   en que el motor propone una clasificación._

---

# Series y composiciones largas

## Silva y endecasílabo suelto

Van juntas porque comparten frontera, y **tres de los apuntes que tenían por separado eran la misma
pregunta**.

| arquitectura | medida | densidad de rima | pareados |
| --- | --- | --- | --- |
| silva · Consonante de orden libre | 7 y 11, sin orden | mayoritaria o total | **predominantes** · definitoria |
| silva · Libre | 7 y 11, sin orden | mayoritaria o total | **ninguna** · definitoria |
| silva · Consonante regular | ciclo 7 + 11 | **total** · definitoria | **regulares** · definitoria |
| silva · Endecasílaba | 11 | **mayoritaria** · definitoria | habituales o predominantes |
| silva · Arromanzada | 7 y 11, sin orden | _(vocales de la asonancia)_ | — |
| endecasílabo suelto · Endecasílabo | 11 | **ninguna** · habitual; esporádica admitida | ninguna u ocasionales |

**La frontera, en el dato:** la densidad. La silva endecasilábica exige `mayoritaria`; el suelto va
de `ninguna` a `esporádica`. Y la medida: el suelto es solo de once.

### 1 · ¿Dónde acaba la silva y empieza el verso suelto? · **chocan**

**Hoy** · la silva exige rima, y su definición lo dice: «un pasaje de siete y once enteramente
suelto no es una silva». El endecasílabo suelto es endecasilábico por definición.

**Las fuentes** borran esa frontera por los dos lados. Que un pasaje sin rima **sea silva**: el
_Diccionario_ «admite como silva también la combinación de endecasílabos y heptasílabos **sin
rima**»; Caparrós presenta el verso suelto «como **una clase de silva** en la que ninguno de los
versos de la serie lleva rima»; Jauralde, que la silva moderna «es normalmente de versos blancos».
Que el suelto **no sea solo de once**: Caparrós, «la serie de endecasílabos **solos o con algún
heptasílabo**»; el _Diccionario_, «series de endecasílabos, **heptasílabos y pentasílabos, solos o
combinados entre sí**»; Jauralde funda la serie en «la igualdad **o proporcionalidad** silábica».

**A favor del corte actual**, y es de peso: Navarro Tomás § 158 data la silva teatral justamente en
la rima —desde 1588 Lope intercala pareados en pasajes de siete y once **sueltos**—, así que en la
comedia lo que separa una cosa de la otra es que rime.

**Decidir** · tres cosas encadenadas: si el suelto admite otras medidas; si la silva exige rima; y,
según las dos anteriores, dónde cae un pasaje de siete y once sin rima.

**Lo que hoy no tiene sitio** · los endecasílabos y heptasílabos sueltos de las dos _Nise_ de
Jerónimo Bermúdez, 1577, que Navarro documenta **en el teatro**. No es silva porque la nuestra exige
rima, ni suelto porque el nuestro es de once. Para Caparrós es verso suelto sin más discusión.

**Si cambia** · el endecasílabo suelto gana una arquitectura heterométrica, o la silva admite
densidad `ninguna`, o las dos. Y la definición de la silva deja de poder decir lo que dice.

### 2 · ¿Entra la cuarta silva de Morley y Bruerton? · **seguir**

**Hoy** · no está. Las cuatro consonantes salen de los cuatro tipos de M&B; falta el cuarto.

**Las fuentes** · M&B: «un cuarto tipo de siete y once mezclados con **todas las rimas en los
pares**». Es consonante, como las otras tres.

**Por qué no cabe en ninguna** · no es la Consonante regular, que son pareados; ni las abiertas,
porque su esquema no tiene posiciones y no puede declarar que la rima caiga en los pares; ni la
Libre, porque con los impares sueltos la densidad no llega a `mayoritaria`.

**Decidir** · si entra como sexta arquitectura. **Sería la gemela consonante de la Arromanzada**,
que ya dibuja esa figura —`[-a]…`— en asonante, así que no es una estructura inédita.

**Si cambia** · una arquitectura más, sin tocar la cabecera de la forma. Comprobado dos veces que
tampoco estaba en el vocabulario legado: no se perdió al migrar, no se declaró nunca.

### 3 · ¿Se distinguen dos silvas solo por un valor de rasgo? · **callan**

**Hoy** · «Consonante de orden libre» y «Libre» comparten esquema de rima, medida y densidad
admitida. Lo único que las separa es `organizacion_en_pareados`, y en las dos ese valor está
declarado **definitoria**: `predominantes` en una, `ninguna` en la otra.

**Las fuentes** · ninguna dice que sean arquitecturas distintas; las cuatro consonantes salen de
los cuatro tipos que M&B enumeran, y el corpus todavía no ha hablado.

**Decidir** · si un valor de rasgo `definitoria` basta para separar dos arquitecturas. El modelo
dice que sí —esa modalidad existe para eso—; el argumento en contra es de uso: el editor tiene que
elegir entre dos que **no puede distinguir hasta haber contado los pareados**, que es justo lo que
el rasgo le pregunta después.

**Si cambia** · una de las dos deja de ser arquitectura. **Es la clase de caso que este modelo está
hecho para resolver con datos**: cuando haya silvas anotadas se mira si alguna cae en
`predominantes` sin ser también otra cosa.

## Canción petrarquista

| arquitectura | estancia | remate | eslabón |
| --- | --- | --- | --- |
| Regular de 13 versos _(principal)_ | 13 versos, mín. 3 | `0-1`, de 1 a 13 versos | 1 verso, `0-1` |
| Estancias consonantes variables | 5–20 versos, mín. 3 | `0-1`, de 1 a 20 versos | 1 verso, `0-1` |
| Sin rima, con pareado final | cuerpo 3–18 + pareado | — | — |

**Ni el remate ni el eslabón declaran medida ni rima.** De las once secciones opcionales del
catálogo, las del terceto encadenado declaran las dos y las del villancico y el zéjel la medida;
**las tres de la canción no declaran ninguna**.

### 1 · ¿La canción sin rima es arquitectura o forma propia? · **seguir**

**Hoy** · arquitectura de la canción petrarquista, no principal.

**Las fuentes** · solo Morley y Bruerton la registran, y la registran **aparte**: «Canción sin
rima», epígrafe propio, y **remiten a un estudio suyo sobre las estrofas sin rima en las comedias de
Lope**, Coimbra 1934. Las otras cinco no la mencionan.

**Decidir** · que la única fuente que la trata le dé entrada propia es argumento para las dos
respuestas. Lo que ya no cabe es decidirlo sin ella.

### 2 · El catálogo hace opcional el remate y cuatro fuentes lo meten en la definición · **seguir**

**Hoy** · `repeticiones_min = 0` en las dos arquitecturas consonantes; en la canción sin rima no
existe.

**Las fuentes** · ninguna lo presenta como prescindible; cuatro lo incluyen al definir la
composición.

| _Diccionario_ | «poema de un número indeterminado de estancias, tres como mínimo, **acabado en** un fragmento de estancia… llamado remate, envío o _commiato_» |
| Caparrós 2014 | «se compone de un número indeterminado de estancias… **y acaba en** un fragmento de estancia llamado remate, envío o _commiato_» |
| Jauralde | «un mínimo de tres estancias iguales **terminadas en** otra mucho más breve, el envío o _commiato_» |
| Quilis | «**sitúa al final** una estrofa más breve, la _tornata_ o envío» |

La quinta, Morley y Bruerton, no lo menciona.

**Decidir** · si se exige. **Si se exige, hay que decidir antes si la canción sin rima participa de
ese cierre**, porque hoy ni siquiera tiene la sección.

**Si cambia** · las canciones sin remate pasan a incumplir la norma.

### 3 · El catálogo siguió a la única fuente que baja el suelo a cinco versos · **chocan**

**Hoy** · la estancia variable declara **5–20 versos**, que es el intervalo de Morley y Bruerton:
«estrofas de cinco a veinte versos».

**Las fuentes** · las otras cuatro ponen el suelo donde empieza la lira, y una dice para qué.

| Caparrós 2014 | «no menos de **nueve** ni más de veinte» |
| _Diccionario_ | «no menos de **nueve** ni más de veinte, normalmente». Y describe aparte la canción alirada como la de unidad **entre cuatro y ocho** |
| Quilis | «en PETRARCA, **entre nueve y veinte**; en BOSCÁN, quince; en GARCILASO, trece» |
| Jauralde | «normalmente **por encima de los ocho** versos, **para diferenciarla de las liras**» |

**Decidir** · si el suelo se sube a nueve. Una estancia de cinco a ocho versos es hoy territorio
compartido con la lira, el sexteto-lira y el septeto-lira.

**Va con la 6**, que es esta misma frontera vista de cerca.

### 4 · ¿Las estancias de la canción sin rima repiten la distribución posicional? · **seguir**

**Hoy** · sí: `medida_estancia` lleva `define_norma`, de modo que lo que se lea en la primera fija
la norma para las demás.

**Las fuentes** · Morley y Bruerton, su única fuente, la describen como «versos de siete y once
sílabas en estrofas sin rima, excepto un pareado final», **sin añadir que el orden métrico se repita
entre estrofas**, como sí hacen al definir la canción con rima —«un tipo de rima fijo e idéntico en
cada estrofa»—.

**Decidir** · si el catálogo puede ser más estricto que su única fuente.

### 5 · Dos fuentes fijan la rima del eslabón y el catálogo no declara ninguna · **seguir**

**Hoy** · el eslabón no declara ni medida ni rima; el remate tampoco, y admite de uno a trece versos
en la regular.

**Las fuentes** · Caparrós, «un eslabón o llave **que rima con el último verso de la fronte** pero
pertenece sintácticamente a la sirima»; Quilis, «un verso de unión llamado _volta_ **que rima con el
último verso del segundo _piede_**». Del remate, el _Diccionario_ y Caparrós dicen que es «**un
fragmento de estancia**» —de donde tomaría medidas y rimas— y el primero añade que «normalmente
tiene el primer verso suelto».

**Decidir** · si se declara lo que las fuentes fijan. De un remate leído hoy solo queda registrado
cuántos versos tiene.

**La cara técnica** ya está apuntada: falta dónde registrar la disposición observada cuando la norma
no la fija ⇒ **A4**.

### 6 · ¿Dónde está la frontera entre estrofa alirada y canción? · **callan**

**Hoy** · la frontera es el **eslabón**, y se modela como sección propia: la estancia regular es
`abCabC:cdeeDfF`, repartida en fronte (6) + eslabón (1) + sirima (6). La definición de la canción
dice que «cuando una estrofa de siete y once no trae eslabón, **la tradición** y este catálogo la
llaman alirada y no canción».

**Las fuentes** · **ninguna de las seis usa el eslabón como criterio**, y las dos que lo describen
dicen expresamente que no lo es.

| Morley y Bruerton | Ningún criterio. Su «Canción (Canzone)» son «versos de siete y once sílabas, agrupados en estrofas **de 5 a 20 versos**, con un tipo de rima fijo». Su ejemplo `ABCABCDD` de _Barlaán y Josafat_ tiene **ocho versos, pareado final y ningún eslabón**, y lo llaman canción |
| Quilis | Ninguno, y lo dice: «**No había ninguna norma relativa a la naturaleza de la rima, ni a su disposición**». La extensión, «en PETRARCA, entre nueve y veinte» |
| Navarro Tomás § 161 | No enuncia ninguno. Su epígrafe «Estrofas aliradas» llega hasta las de **nueve versos**. Lo único que distingue es su notación: escribe la estancia con dos puntos —`abCabC: cdeeDfF`— y las aliradas sin ellos, la de nueve incluida |
| Caparrós 2014 | **La extensión**: «no menos de nueve ni más de veinte, normalmente». Del eslabón, que «**aunque no es obligatorio**, es frecuente» |
| _Diccionario_ | Lo mismo, palabra por palabra. Y define la **canción alirada** como «canción a la italiana cuyas estrofas, cortas y simétricas, **prescinden de la ordenación rigurosa de la estancia**»: para él la alirada **es una canción** |
| Jauralde | **La extensión**: «dispuestos de modo aleatorio, normalmente **por encima de los ocho versos** (para diferenciarla de las liras)» |

**Las cuatro que dan una extensión coinciden en el umbral: nueve versos.** La única que baja de ahí
es Morley y Bruerton, con su «de 5 a 20», que es justo el intervalo que el catálogo declara.

**El caso que lo destapó cae en ese umbral.** El § 161 de Navarro, dentro de su epígrafe de
aliradas, describe dos estrofas de **nueve** versos como «una nueva reelaboración de este modelo»,
siendo «este modelo» las dos aliradas de ocho que acaba de describir: `abCabCcdD` de Figueroa y
`AbCAbCcdD` de Góngora. **El mismo string admite dos lecturas**: canción —fronte `abCabC` + eslabón
`c` + sirima `dD`— o alirada —la octava-lira con un verso más antes de su pareado final—.

**Aplicar nuestra regla al pie de la letra no se sostiene**, por dos razones. Que una rima se repita
no informa de nada: la fronte repite `abC` por definición y la sirima `cdeeDfF` repite la `e`. Y lo
que sigue al verso 7 es `dD`, un pareado final de dos versos —la marca de las aliradas, que la
octava-lira declara como «una condición que no falla»—, no una sirima de seis.

**Decidir** · tres cosas. Si la regla del eslabón necesita además una **extensión mínima de sirima**
para separar canción de alirada, o basta el verso que repite. Si la frase «**la tradición** y este
catálogo la llaman alirada» puede sostenerse, cuando la tradición que se invoca clasifica al revés
el caso de nueve versos. Y si «petrarquista» nombra propiamente la estancia de trece, en cuyo caso
la forma debería llamarse «Canción» a secas.

**Se decida como se decida, hay algo que cambia igual**: la definición de la novena-lira dice hoy
que «ninguna de las fuentes del catálogo la describe **ni le da nombre**», y Navarro describe una
estrofa alirada de nueve versos bajo ese epígrafe.

### 7 · ¿«Petrarquista» nombra la forma o solo la estancia de trece? · **seguir**

**Hoy** · la forma se llama «Canción petrarquista». Están registradas como denominaciones suyas
«Canción», «Canción a la italiana» y «Canción extensa», las tres con fuente.

**Las fuentes** · ninguna reserva el término para una extensión; las tres que lo usan lo aplican a
la forma entera y lo glosan como sinónimo. Caparrós, «La canción **petrarquista o italiana** está
compuesta de estancias». El _Diccionario_ lo trae como **entrada de remisión** —«canción
petrarquista. canción a la italiana»—. Jauralde, «La canción petrarquista **o italiana o,
sencillamente, canción**», y antes, «con el término simple "canción" nos solemos referir a la
canción petrarquista».

**Decidir** · bajar el apellido a la arquitectura de trece versos sería invención nuestra. Lo que sí
tiene respaldo es al revés: «Canción» a secas es el epígrafe de Morley y Bruerton, el de Quilis y el
de Navarro, y Jauralde lo autoriza.

**Si cambia** · la forma pasa a «Canción» y «canción petrarquista», «canción italiana» y «canción a
la italiana» quedan como denominaciones suyas. La definición ya advierte de que el nombre corto no
designa aquí la canción medieval del siglo XV.

## Villancico y zéjel

Las fuentes las separan **por la forma de la mudanza y de la vuelta** —redondilla en el villancico,
trístico monorrimo en el zéjel—, y varias avisan de que los dos moldes se confunden con facilidad.

| | cabeza | mudanza | enlace | vuelta | repetición |
| --- | --- | --- | --- | --- | --- |
| villancico · Estribillo inicial | 1–4 | 4 versos | 0–1, de 1 a 3 | 0–1, de 1 a 3 | pregunta de represa |
| villancico · Estribillo tras la primera copla | 1–4 | 4 versos | 0–1 | 0–1 | pregunta de represa |
| zéjel · Estribillo y coplas monorrimas | 1–2 | 3 versos | — | 1 verso | represa `0-1` |

**Solo se pregunta la rima de la mudanza.** De las demás partes se pregunta la medida, no la rima.

### 1 · ¿La mudanza son dos miembros simétricos o una redondilla? · **chocan**

**Hoy** · una sola sección de cuatro versos, y la nota lo explica.

**Las fuentes** · las mismas dicen las dos cosas. El _Diccionario_ y Caparrós hablan de «dos
mudanzas simétricas» y, en la misma entrada, de «la estabilidad de la **redondilla o cuarteta**
central»; Navarro Tomás da «la mudanza **en redondilla**» y Quilis «identifica **la redondilla**
como mudanza característica».

**Decidir** · cuál de las dos es la unidad y cuál la descripción de su interior. No es a quién hacer
caso: es qué nivel tiene cada cosa.

**Si cambia** · dos secciones hermanas donde hoy hay una, y toca la ficha y el registrador.

### 2 · ¿Hasta dónde llega el estribillo? · **chocan**

**Hoy** · de uno a cuatro versos. _El IP decidió el 10 de agosto quedarse en 2–4, de modo que uno de
cinco o más entra como desviación._

**Las fuentes** · Caparrós fija la cabeza en «dos, tres o cuatro versos» y el _Diccionario_ igual.
**Navarro Tomás recoge estribillos «de muy diversa extensión entre dos y dieciséis versos»**, y
Quilis «advierte variación en la extensión del estribillo».

**Decidir** · si el corte sigue en cuatro sabiendo que la distancia con la fuente más amplia es de
doce versos, no de tres. _Es la misma disyuntiva que la vuelta, donde se optó por lo contrario,
dejarla abierta; conviene revisarlas juntas._

### 3 · ¿Entran las mudanzas de seis versos? · **seguir**

**Hoy** · la mudanza es de cuatro. Están formalizadas `abba`, `abab` y la asonantada `-a-a`.

**Las fuentes** · Navarro Tomás registra «mudanzas **excepcionales de seis**», y junto a `abba`
también `abab` y la forma asonantada `abcb`, que el catálogo ya tiene.

**Decidir** · si la de seis entra como excepcional o se queda como desviación, que es donde está.

### 4 · La arquitectura de estribillo posterior se quedó sin fuente · **callan**

**Hoy** · dos arquitecturas, y **lo único que las separa es dónde aparece el estribillo por primera
vez**.

**Lo que la sostenía era falso y se retiró** el 13 de septiembre de 2026 (`20260913120000`): la
ficha atribuía a Navarro Tomás, «como modalidad moderna general», una cuarteta octosilábica seguida
de un estribillo en cuarteta hexasílaba. No lo dice en ninguno de los seis §§ citados, y lo que sí
dice lo contradice —en la _Gacela_ de Lorca «el estribillo es una cuarteta **heptasílaba**» y **va
delante**, y el otro ejemplo moderno es «ejemplo aislado de esta antigua forma de canción en el
presente período»—.

**Las fuentes** · buscado en los seis libros: **las cinco que describen la forma ponen el estribillo
al principio**, y el _Diccionario_ usa esa palabra —«un estribillo **inicial** —llamado cabeza,
villancico, letra o tema—»—. Ni cabeza pospuesta ni villancico que empiece por la copla aparecen en
ninguno.

**Decidir** · si la arquitectura se queda. Es anterior a la afirmación falsa —nació el 29 de julio
de 2026—, así que no la creó aquella lectura, pero ninguna otra la sostiene. Si el corpus la trae,
es hallazgo nuestro y la ficha debería decirlo así; si no la trae nadie, sobra.

**Si se retira** · desaparece con ella la duda de si son una arquitectura o dos. _Si se conserva, la
razón de tenerlas separadas es que el demarcador distingue por arquitectura y perdería capacidad de
identificar._

### 5 · La rima del estribillo, el enlace y la vuelta no se registra · **callan**

**Hoy** · el editor responde la rima de la mudanza y la **medida** de las demás partes. Las rimas
concretas del estribillo, el enlace y la vuelta no se guardan.

**Las fuentes** · sí precisan cómo enlazan: el _Diccionario_, que los versos de la vuelta «**o al
menos el último**» riman con la cabeza; Caparrós, que el primero enlaza con la rima final de la
mudanza.

**Decidir** · si se pregunta. Sin ese dato **no podrá reconstruirse después cómo enlazan las
secciones en cada realización**, que es justamente lo que las fuentes usan para distinguir el
villancico del zéjel.

### 6 · ¿Una repetición parcial del estribillo es posibilidad admitida o desviación? · **callan**

**Hoy** · en el zéjel la represa es total o no aparece.

**Las fuentes** · **ninguna de las cinco que tratan el zéjel describe repetición parcial**. Para el
villancico la describen dos: Jauralde, «repetición total o parcial de la cabeza», y Navarro Tomás,
«ampliación o supresión del enlace y la vuelta, y **repeticiones parciales o totales**».

**Decidir** · si el silencio de las cinco basta para no ofrecerla en el zéjel.

### 7 · ¿Se admite la mudanza de dos versos? · **seguir**

**Hoy** · la mudanza del zéjel es de tres, y es lo definitorio de la forma.

**Las fuentes** · Navarro Tomás, § 211, el del Siglo de Oro: «además de la forma regular… aparece
también **entre las canciones de la Noche Buena, de Gómez de Tejada, la variante con las mudanzas
reducidas a dos versos**, ya registrada en los períodos anteriores, `aa:bba`». Y la nota de ese
mismo párrafo trae **una tercera reducción**: `a:bba`, «con mudanza de dos versos **y uno de
estribillo**», en una letrilla de Trillo y Figueroa.

**Decidir** · si entra `aa:bba`, y con ella si se relaja también el estribillo, que hoy es de uno o
dos versos y en `a:bba` queda en uno.

**Si cambia** · toca el núcleo de la definición.

### 8 · ¿Y el zéjel en arte mayor? · **seguir**

**Hoy** · el esquema métrico ofrece seis u ocho sílabas.

**Las fuentes** · Navarro Tomás «registra zéjeles en arte mayor y variantes que modifican estribillo
y vuelta, como `aba:cccba` y `abba:cccaca`».

**Decidir** · nada, por ahora: son medievales y cultas, no del corpus dramático. _Queda anotado a la
espera de que aparezcan._

### 9 · ¿El estribillo del zéjel vuelve siempre, como el del villancico? · **seguir**

**Hoy** · sección `0-1` y una respuesta que permite decir que no vuelve. _El 29 de agosto de 2026 se
decidió que en el villancico **no puede faltar** —cuando la fuente antigua no lo copia es por ahorro
de espacio— y su sección pasó a obligatoria en las dos arquitecturas._

**Las fuentes**, y aquí hay razones para no extender el criterio:

- **Ninguna de las seis afirmaciones del zéjel incluye la repetición en el esquema.** Las cuatro que
  lo describen dan `aa:bbba` y coinciden en cómo vuelve: Navarro Tomás, «un cuarto verso de vuelta
  que rima con el estribillo»; Quilis, «un verso de vuelta que rima con el estribillo». **Lo que
  vuelve es la rima**, y el esquema se cierra ahí. En el villancico la repetición es una parte
  declarada.
- Las fuentes separan las dos formas precisamente por eso: «por la forma de la mudanza **y de la
  vuelta**».
- Y las dos respuestas del zéjel son de **presencia** —«no vuelve a aparecer», «se repite entero»—,
  no de extensión. Con la sección obligatoria habría que retirar la negativa y quedaría una sola
  opción: dejaría de haber pregunta.

**Decidir** · si el criterio de ejecución y transmisión que gobierna el villancico alcanza al zéjel.
_En el villancico coincide con lo que el esquema declara; en el zéjel iría contra lo que las fuentes
escriben._

---

# Estrofas de arte menor

## Pareado, redondilla y quintilla

| forma | arquitecturas | medidas | esquemas |
| --- | --- | --- | --- |
| Pareado | Cualquier medida · Alirado | 4 a 14 · 7 y 11 | `aa` |
| Redondilla | Octosilábica · Heptasilábica · Hexasilábica | 8 _(admite 4 y 5 quebrados)_ · 7 · 6 | `abba` y `abab`, las dos admitidas |
| Quintilla | Octosilábica consonante · Heptasilábica · Hexasilábica | 8 _(4 y 5 quebrados)_ · 7 · 6 | ocho, con `ababa` habitual y cuatro excepcionales |

### 1 · Una tirada de pareados alirados, ¿es una silva? · **seguir**

**Hoy** · el pareado alirado es arquitectura del pareado, y la silva Consonante regular es un ciclo
de 7 + 11 con pareados regulares. Son dos formas.

**Las fuentes** · las dos que se pronuncian las acercan hasta casi juntarlas. Morley y Bruerton, de
la silva de consonantes `aAbBcCdD`: «**se podría llamar pareados de 7 y 11**». El _Diccionario_, del
pareado: «es la forma sobre la que se construyen otras: **la silva de consonantes**, el perqué, la
aleluya, las canciones de coro».

**Decidir** · si una tirada de pareados alirados se anota como pareado o como silva regular. Hoy lo
elige el editor sin criterio escrito, y las dos respuestas tienen fuente.

### 2 · ¿Es `abab` una redondilla, o es otra cosa? · **chocan**

**Hoy** · las tres arquitecturas admiten `abba` y `abab` por igual, y una tirada puede alternarlas.

**Las fuentes no se ponen de acuerdo en si son la misma estrofa**:

| Morley y Bruerton | La definen como «cuatro octosílabos `ABBA`». **Su definición no recoge la cruzada** |
| _Diccionario_ | **Reserva «cuarteta»** para la cruzada en octosílabos o menores, y la separa de la redondilla |
| Navarro Tomás | La cruzada es la antigua y la abrazada su modificación; y advierte que Rengifo aplicó «redondilla» **a la vez a las formas `abab` y `abba`** |
| Quilis | Trata la cuarteta «**como variante de la redondilla** y no como estrofa independiente» |
| Caparrós 2014 | Registra tres medidas sin separar disposiciones |

**Decidir** · si la cruzada es una disposición de la redondilla —como está— o una forma vecina con
nombre propio. Y, dentro de la respuesta actual, si una misma tirada puede alternar las dos.

**Si cambia** · afecta a la copla castellana y a la copla real, que reutilizan estas arquitecturas.

### 3 · Faltan quintillas con verso suelto, y aquí las fuentes se enfrentan · **chocan**

**Hoy** · `versos_sueltos: ninguno`. Las ocho disposiciones tienen las cinco rimas.

**Las fuentes** · Jauralde **las registra**: `abcab`, `abbca`, `abaca`, `abcaa` «y otras», que
describe como **transgresión de las viejas normas**. El _Diccionario_ **las excluye de la
definición**, entre sus cuatro condiciones: cinco octosílabos o menores, dos clases de rima
consonante, no más de dos versos seguidos con la misma y «ni pareado final **ni verso suelto**».

**Decidir** · si entran. No es solo alcance del corpus: recogerlas contradice al _Diccionario_ y no
contradice a Jauralde, que ya las llama transgresión.

### 4 · Las fuentes no dan una cuenta de disposiciones, sino tres · **chocan**

**Hoy** · ocho, con `ababa` habitual, tres admitidas y cuatro excepcionales. **La octava es
numeración nuestra.**

| Caparrós 2014 | **cinco.** Las deriva de las dos prohibiciones —ni tres seguidos con la misma rima ni pareado final— y concluye que las posibles son `ababa`, `abaab`, `abbab`, `aabab` y `aabba` |
| Navarro Tomás | **siete**, numeradas: 1 `ababa`, 2 `abbab`, 3 `abaab`, 4 `aabab`, 5 `aabba`, 6 `abbaa`, 7 `ababb` |
| Morley y Bruerton | **siete**, y añaden que Rengifo (1592) recoge solo las cinco primeras, omitiendo las dos que acaban en pareado. Del tipo `ABBBA` dicen que «**puede deberse** a un error de imprenta o a una adaptación especial» |
| Jauralde | recoge `abbba` **entre las disposiciones** de la quintilla octosilábica, y la llama «escasa» frente a «la mayoritaria `ababa`» |

**Decidir** · `abbba` no lo **numera** nadie, pero **Jauralde sí lo cuenta entre las disposiciones**,
que es más que la aparición suelta. _Decisión del IP el 19 de agosto: se conserva el número 8 a la
espera de que el corpus lo confirme. Si no aparece más, conviene renombrarlo para no atribuir a
Navarro Tomás un octavo tipo que no dio._

### 5 · Tres formas preguntan el quiebro en todos sus versos porque su fuente calla · **callan**

**Hoy** · la copla real, la redondilla y la copla de arte menor ofrecen el quiebro en cualquier
posición. Las demás lo declaran donde su fuente lo nombra: la quintilla en el primero —Navarro
Tomás, «la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo»—, la
septilla en el quinto, la novena en orden 4+5 en el quinto y la oncena en orden 5+6 en el octavo y
el undécimo.

**Las fuentes** · las tres primeras documentan el quiebro **sin nombrar el verso**. El
_Diccionario_, que las quintillas de la copla real «admiten algún verso quebrado tetrasílabo»;
Navarro Tomás registra la redondilla quebrada con dos ejemplos y no dice dónde cae; Caparrós, de la
copla de arte menor, «admite versos quebrados de cuatro sílabas» **sin nombrar ninguno**.

**Decidir** · si el silencio basta para ofrecer las diez posiciones, o si se restringe por otra vía.
_Es silencio, no una regla enunciada, y de una enumeración no se saca un mínimo._

**Cuidado con esto** · ninguna de esas tres fuentes dice «no fija en qué verso»: eso es nuestra
lectura de su silencio, y conviene que la ficha no lo escriba entre comillas.

## Sextilla y copla manriqueña

| forma · arquitectura | versos | medidas | esquemas |
| --- | --- | --- | --- |
| sextilla · Octosilábica | 6 | 8 | `aabaab` `aabccb` `ababab` `abcabc`, admitidas |
| sextilla · De pie quebrado | 6 | 8 con quebrado de 4 o 5 | `abcabc` habitual; `aabaab` y `aabccb` admitidas |
| sextilla · Hepta, hexa, penta y tetrasilábica | 6 | 7 · 6 · 5 · 4 | solo disposición variable |
| **copla manriqueña** · Doble pie quebrado | **12** | 8 con quebrado de 4 o 5 | `abcabc\|defdef` habitual |

### 1 · La copla manriqueña es de doce versos y ninguna fuente la llama así · **chocan**

**Hoy** · forma propia, una sola arquitectura, **doce versos**. La quebrada de seis vive en la
sextilla.

**Las fuentes no la parten ahí:**

| Caparrós 2014 | «la variante más conocida de **la sextilla**… estrofa de **seis versos**», que difiere de la común en que el tercero y el sexto son tetrasílabos |
| _Diccionario_ | «**Cuenta también los seis**: la manriqueña es para él la estrofa de pie quebrado». Solo su entrada aparte, «copla mixta», contempla la agrupación de doce, dividida «en dos semiestrofas de distinta extensión **o en dos sextillas**» |
| Quilis | «la estrofa manriqueña como **sextilla de pie quebrado**, **sin epígrafe para la pareja de doce versos**» |
| Navarro Tomás | § 67: «la estrofa de doce versos fue concebida ordinariamente como **una pareja de sextillas**» |
| Jauralde | **la trata dentro de las estrofas de ocho versos**, y dice que «su forma más habitual es la de **doble sextilla con seis rimas**» |
| Morley y Bruerton | «No la separan»: la agrupación de doce cae dentro de sus coplas de pie quebrado «**sin nombre propio**» |

**Tres cuentan seis, dos describen el grupo de doce como pareja o doble de sextillas, y una no lo
separa. Ninguna da nombre propio a una estrofa de doce.**

**Decidir** · si la forma de doce se sostiene, y con qué apoyo. Si se sostiene, es decisión del
proyecto y conviene que la definición lo diga, como se hizo con la frontera alirada. Si no, la
manriqueña vuelve a ser una arquitectura de la sextilla y la pareja de doce se deriva del rango, que
es lo que el modelo hace con todas las demás.

_Este contraste no se podía ver antes de la auditoría: la afirmación de Jauralde decía «cuenta los
doce» hasta que el 21 de septiembre se comprobó que su epígrafe está entre las estrofas de ocho._

### 2 · Nada distingue dos sextillas seguidas de una copla manriqueña · **callan**

**Hoy** · los versos, las medidas y el tipo de rima son idénticos; **lo único que cambia es si las
rimas de la segunda mitad dependen de la primera**, y eso lo decide el editor al elegir forma, no un
criterio observable.

**Las fuentes** · ninguna da un criterio para distinguirlas al leer, porque para cinco de ellas la
pareja de doce ni siquiera es una forma.

**Decidir** · qué observa el editor para elegir. _Es la misma pregunta que la copla castellana frente
a dos redondillas, y las dos definiciones ya la admiten en voz alta._

### 3 · ¿Es una arquitectura más la quebrada en segundo y quinto? · **seguir**

**Hoy** · la arquitectura de pie quebrado declara los suyos en el **tercero y el sexto**, la
disposición manriqueña, **y el rasgo es ahí definitorio**. Una quebrada en otras posiciones solo
cabe como desviación.

**Las fuentes** · son **tres** las que traen la variante: el _Diccionario_ ilustra su entrada con
una estrofa de Lucas Fernández quebrada en **segundo y quinto**; Jauralde documenta «las sextillas
de Ricardo Gil, donde el tetrasílabo quiebra el segundo verso y el quinto»; y Caparrós «documenta
también una variante con los quebrados en segundo y quinto lugar».

**Decidir** · si es otra arquitectura de la misma forma —como los dos órdenes de la oncena y la
novena— o una desviación. Y qué hacer cuando el corpus traiga una quebrada en posiciones distintas
de esas dos.

### 4 · ¿Se admiten las tres disposiciones hexasílabas de Navarro Tomás? · **seguir**

**Hoy** · la hexasilábica solo declara disposición variable.

**Las fuentes** · Navarro Tomás documenta tres concretas: **rimas alternas** en Juan Ruiz, § 30; la
**aguda `aaé:bbé`** en Eugenio Gerardo Lobo, § 245; y el **lay**, «breve canción amorosa de origen
francoprovenzal en sextillas hexasílabas con insistentes rimas agudas», con `ááá:ááé` de don Álvaro
de Luna.

**Y del lay las dos fuentes que lo definen no coinciden**: el esquema de Navarro es `ááá:ááé`, y el
_Diccionario_ lo describe con «dos rimas consonantes agudas, una en los versos primero, segundo,
cuarto y quinto y otra en el tercero y el sexto, **es decir `aabaab`**».

**Decidir** · si entran, sabiendo que **quedaron fuera por criterio cronológico** —Juan Ruiz es del
XIV, Álvaro de Luna del XV y Lobo del XVIII—. Y si entra el lay, cuál de los dos esquemas.

**Ojo con las agudas** · la rima aguda no es una clase de rima sino una cualidad del final, y el
catálogo la lleva en `final_acentual`. Declararlas obliga a decidir cómo se escribe `aaé:bbé` sin
confundir las dos cosas.

### 5 · ¿Puede una sextilla dejar un verso suelto? · **seguir**

**Hoy** · no.

**Las fuentes** · **tres de las seis documentan que sí**, y en el mismo poema: las sextillas del
_Martín Fierro_ dejan sin rima el primer verso, y Caparrós escribe su esquema `- a a b b a`.

**Decidir** · nada nuevo: _el IP lo dejó fuera el 18 de agosto por criterio cronológico —el_ Martín
Fierro _es de 1872—._ Es una decisión de **alcance del corpus**, no una norma.

**Lo que dejó escrito, y vale para todo el catálogo** · para la sextilla **ninguna de las seis
enuncia una regla** —Quilis cierra su lista con un «etc.»—, y **la enumeración de una fuente no es
una norma**: derivar de ella un mínimo convierte una muestra en ley. `numero_clases`,
`min_alternancias` y `max_consecutivos` solo se declaran cuando una fuente enuncia la regla.

### 6 · Las cuatro disposiciones históricas de la copla manriqueña no están · **seguir**

**Hoy** · el catálogo declara solo la última, `abcabc|defdef`.

**Las fuentes** · Navarro Tomás § 68 enumera la serie entera con ejemplo y localizador:
`aab:aab-aab:aab` en el _Cancionero de Baena_; `aab:aab-bba:bba` en Villasandino, donde el orden se
invierte en la segunda; `aab:aab-ccd:ccd`, con rimas distintas en cada semiestrofa por Juan de Mena;
y `abc:abc-def:def`, «que alcanzó fama permanente con las coplas de Jorge Manrique».

**Decidir** · **no se han creado a propósito**, por ser cancioneriles del siglo XV y no del corpus
dramático. Queda confirmar que ese criterio sigue valiendo, y si la respuesta depende de la 1: si la
forma de doce se retira, la pregunta cambia de sitio.

### 7 · ¿Debe registrarse el esquema de las manriqueñas no manriqueñas? · **callan**

**Hoy** · la forma de doce tiene dos esquemas: el manriqueño, que se marca si es el observado, y uno
de distribución variable para todo lo demás, que **no guarda cuál fue**.

**Las fuentes** · ninguna se pronuncia sobre qué registrar; es cuestión de qué queremos poder
comparar después.

**Decidir** · si interesa comparar unas con otras. Hoy esa información se pierde.

## Sextina

1. **Son las dos únicas formas del catálogo con tres tradiciones** —provenzal, italiana y española—.
   Es cierto en la historia: la inventó Arnaut Daniel, la fijaron Dante y Petrarca y entró en España
   en el XVI. Pero **ninguna otra forma declara más de una**, incluido el soneto, que llegó por el
   mismo camino. _La duda es si «tradición» quiere decir aquí el origen remoto o la vía por la que
   entra en la métrica española._

**Añadido el 18 de septiembre de 2026, al cerrar la fase 4 de la auditoría de fuentes.**

**La estrofa se apoya en una sola de las seis fuentes.** Al registrar los silencios quedó a la vista
que cinco definen la sextina **como composición** y no dan entidad propia a la estrofa de seis que la
forma:

| fuente                  | qué hace                                                                                                                                |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Quilis 1969, § 5.4.5.1  | **La aísla**: «llama sextina a la estrofa de seis endecasílabos que forma parte, junto con otras cinco y un terceto, de la composición» |
| Morley y Bruerton 1968  | define «Sestina» como «una forma de _canzone_ que consiste en seis estrofas de seis endecasílabos cada una»                             |
| Navarro Tomás 1972      | «composición formada por seis estrofas de seis endecasílabos sueltos cada una»                                                          |
| Domínguez Caparrós 2014 | «un poema de treinta y nueve endecasílabos, dividido en seis estrofas de seis versos y un remate de tres»                               |
| _Diccionario_ 2016      | igual, y **usa el nombre además para otra cosa**: su segundo sentido remite a «sexteto»                                                 |
| Jauralde Pou 2020       | usa «sextina real» para el sexteto `ABABCC`, que es otra estrofa                                                                        |

**La forma no se discute, y la razón es estructural antes que filológica**: la sextina se declara
`compuesta_por` esta estrofa, de modo que sin ella la composición no estaría formada por nada. Es
argumento de David, del día en que se cerraron los silencios.

_Lo que queda para el IP es con qué apoyo se publica. Es el mismo caso que la derivación de la
septilla desde la séptima endecasílaba, sostenida también por un solo testimonio, y allí la nota de
la relación lo dice con su nombre: «es el único de los seis manuales que ordena la pareja». La
pregunta es si la definición de la estrofa debe decir lo mismo —que solo Quilis la aísla— o si basta
con que la sección de fuentes lo enseñe al ponerlas juntas._

## Terceto

_Sin cuestiones abiertas. El tercetillo entró el 22 de agosto de 2026 con sus dos medidas, su
disposición monorrima y la asonancia que el_ Diccionario _le admite; la septilla, que lo esperaba,
ya lo referencia._

## La serie alirada

Seis formas —cuarteto, sexteto, septeto, octava, novena y décima-lira— más la lira, que es la
estrofa canónica de cinco. **No están declaradas con el mismo criterio**, y esa es la raíz de casi
todo lo que sigue:

| | medida | rima | qué pregunta |
| --- | --- | --- | --- |
| Lira | 5 posiciones fijas | `aBabB` definitoria | **nada**: todo se deriva |
| Cuarteto, octava, novena y décima-lira | repertorio 7/11 **abierto** | esquemas admitidos, o ninguno | metro y rima, verso a verso |
| **Sexteto-lira** | fija, pero **dentro de ocho variedades** | tres disposiciones | la variedad, y el metro |
| **Septeto-lira** | **7 11 7 11 7 7 11, fija y sin alternativa** | `ababbcc` **habitual** | una sola cosa |

_El IP decidió el 26 de agosto de 2026 dejar abiertas de metro y de rima las aliradas nuevas, porque
todavía no se sabe qué hay en el corpus y la base es donde se va a documentar._

### 1 · El septeto-lira no quedó abierto como sus hermanas · **seguir**

**Hoy** · fija la medida verso a verso y declara un único esquema de rima, `ababbcc`, marcado
**habitual** —es decir, «suele ser este», luego hay otros— y **no pregunta la rima**. Quien encuentre
uno distinto no puede registrarlo.

**Las fuentes** · su propia definición presenta esa disposición como «**la realización que la
documenta**», que es lenguaje de una realización entre varias, no de una norma.

**Decidir** · si se abre como sus cuatro hermanas. Si se abre, se le crea la misma pregunta y deja
de fijar posiciones; si se deja fija, **la definición no puede seguir diciendo «la realización que la
documenta»**, porque eso describe lo contrario de lo que el dato declara.

### 2 · El sexteto simétrico `abC:abC` de san Juan de la Cruz no está · **seguir**

**Hoy** · el sexteto-lira tiene ocho variedades y tres disposiciones de rima —`ababcc` habitual,
`abbacc` y `aabbcc` admitidas—, **todas con pareado final**.

**Las fuentes** · Navarro Tomás lo documenta en la _Llama de amor viva_: seis versos de siete y
once, pero **sin pareado final**. Ninguna de las ocho variedades lo acoge y no cabe en la definición
actual.

**Decidir** · si es otra forma, una variedad que obliga a ensanchar la definición, o queda fuera del
corpus. **Va con la 3**, porque el pareado final es justamente lo que las ocho comparten.

### 3 · ¿Por qué esas ocho combinaciones del sexteto-lira y no otras? · **callan**

**De dónde salen** · no de una restricción documentada, sino del vocabulario legado: eran siete
subtipos escritos uno a uno, y la matriz de importación los mandó a `variedad`. Que fueran siete de
quince era el resultado de tener siete filas — **y el 24 de agosto de 2026 entró una octava,
`A4 · aBaBCC`**, lo que confirma que la lista no cerraba nada: crecía al leer.

**Los dos ejes son libres.** Comprobado: las cinco secuencias de medidas y las tres disposiciones de
rima son independientes, y nada impide combinarlas.

| Medidas | `ababcc` | `abbacc` | `aabbcc` |
| --- | :-: | :-: | :-: |
| `7-11-7-11-7-11` | **A1** | — | — |
| `11-7-7-11-7-11` | **A2** | — | **C1** |
| `7-7-7-11-7-11` | **A3** | — | — |
| `7-7-7-7-7-11` | — | **B1** | — |
| `11-7-7-11-11-11` | — | **B2** | **C2** |

**Las fuentes** · **ninguna de las seis prohíbe combinación alguna**, y dos terminan la enumeración
en abierto: Morley y Bruerton citan tres «entre otras» y Navarro Tomás cuatro «y otras». **Tres que
las fuentes nombran y el catálogo no tiene**: `AbbAcC` cabría sin añadir nada —es una de las ocho
casillas vacías—; `AbAbcC` y `aBaBCC` exigen un esquema métrico nuevo.

**Decidir** · qué queda del nivel de variedad si los dos ejes son libres. Hoy es una pregunta con
ocho opciones; la alternativa son **dos preguntas cerradas** —¿qué secuencia de medidas? (5) y ¿qué
disposición de rima? (3)—, que cubren las quince. _Si los dos ejes son libres, la contraprueba de_
[criterios de nivel](./criterios-de-nivel.md) _dice que la variedad «no hace falta»._

**Es la pregunta más antigua de la lista y la que más estructura mueve.**

### 4 · Nada distingue un cuarteto-lira de siete dominante de otro de once · **callan**

**Hoy** · «Heterométrico consonante» declara proporción variable **sin posiciones**: dice que mezcla
siete y once, y no cuántos de cada uno ni en qué orden. Un editor que lea `7 7 7 11` y otro que lea
`11 11 11 7` **registran hoy lo mismo**.

**Las fuentes** · Jauralde separa el cuarteto-lira del cuarteto de endecha **por ahí**: «cuando sobre
la misma estructura de cuatro versos impares lo que domina es el heptasílabo sobre el endecasílabo
**se prefiere hablar de cuartetos de endecha**». La relación entre las dos formas quedó declarada el
18 de septiembre de 2026, sin fundirlas.

**Decidir** · si el criterio de la proporción se registra en alguna parte. Sin eso **no se puede
aplicar al anotar aunque se acepte**, y lo que Jauralde propone queda como lectura que el catálogo no
sabe guardar.

**Es el mismo hueco** que tienen la novena-lira, la décima-lira y la canción de estancias variables
con sus disposiciones ⇒ **B1**. _Si se resuelve ahí, este caso se resuelve con él._

**Y de paso**, la escala que Jauralde sugiere —cuartetos, quintetos «y así sucesivamente» de
endecha— toca esta misma serie.

## Sexteto, octava aguda y octava real

| forma · arquitectura | medida | rima |
| --- | --- | --- |
| sexteto · Endecasilábica | 11 | `ABABCC` habitual, más disposición abierta |
| sexteto · Alejandrina | 14 | `AABCCB` habitual, más disposición abierta |
| sexteto · Dodecasilábica | 12 | solo disposición abierta |
| octava aguda · seis arquitecturas | 11 · 10 · 8 · 7 · 6 · 5 | `---a---a` en todas |
| octava real · Endecasilábica consonante | 11 | `ABABABCC` habitual; «Distribución variable» **excepcional** |

### 1 · ¿Se admite el sexteto que combina arte mayor y menor? · **chocan**

**Hoy** · no: el catálogo exige isosilabismo de arte mayor.

**Las fuentes** · tres lo admiten. Caparrós 2014 lo mete en la definición —«de arte mayor, **o de
arte mayor y menor combinados entre sí**»—; el _Diccionario_ «advierte que a veces el término se
aplica también a la estrofa compuesta en versos de arte menor»; y Jauralde «aparta como grupo propio
los **sextetos mixtos**».

**Decidir** · _el catálogo lo separa a propósito: la heterometría regular con endecasílabo es del
sexteto-lira y el arte menor es de la sextilla._ La pregunta es si ese reparto se mantiene sabiendo
que tres fuentes no lo hacen.

### 2 · ¿Las medidas 11, 12 y 14 son un repertorio cerrado? · **seguir**

**Hoy** · tres arquitecturas: endecasílaba, dodecasílaba y alejandrina.

**Las fuentes** · Jauralde describe **con apartado y ejemplo propios** sextetos eneasilábicos,
decasilábicos, endecasilábicos, dodecasilábicos y de alejandrinos: **dos más que el catálogo, el
nueve y el diez**. Del pentadecasilábico, en cambio, «solo hay una mención de paso, en el capítulo
del verso, a propósito de un ejemplo de Salvador Rueda», así que no pesa lo mismo.

**Decidir** · si entran el nueve y el diez. _Las tres del catálogo son las del corpus, no las de la
bibliografía._

### 3 · ¿La consonancia es exigible? · **seguir**

**Hoy** · definitoria en las tres arquitecturas.

**Las fuentes** · Navarro Tomás documenta en el modernismo **la estrofa asonante** de heptasílabos y
endecasílabos `abcbDB` de Darío, y tipos simétricos que dejan sueltos varios versos, `AAB:CCB` y
`AaB:CcB`.

**Decidir** · si la asonante entra, sabiendo que es modernista y no del corpus dramático.

### 4 · Sigue sin sitio la variedad de los _Nocturnos de San Pedro_ · **seguir**

**Hoy** · no cabe en ninguna forma.

**Las fuentes** · Navarro Tomás describe una combinación de endecha real y sexteto con **un pie
quebrado que repite en eco la rima del segundo heptasílabo**. Se buscó expresamente al revisar el
sexteto y **ninguna de las seis la formaliza como sexteto autónomo**.

**Decidir** · o se le da forma propia, o se registra como desviación de la endecha real, que es la
forma con la que Navarro la combina.

### 5 · Se modeló para la alejandrina lo que en otras formas se dejó en las fuentes · **callan**

**Hoy** · la alejandrina declara `AABCCB` y el rasgo de finales agudos, **y el sexteto alejandrino
no está en el corpus**. Se declaró porque la descripción contaba en prosa una disposición que la
ficha no podía dibujar.

**Las fuentes** · Quilis «recoge el sexteto de alejandrinos que tiene agudos y rimados entre sí los
versos tercero y sexto».

**Decidir** · **la inconsistencia es real y es de criterio general**: o el catálogo modela lo que las
fuentes describen aunque el corpus no lo traiga —y entonces faltan cosas en otras formas—, o modela
solo lo anotable, y entonces esta declaración sobra. _Afecta también a la sextilla, a la copla real y
a la endecha real._

### 6 · Navarro documenta la octava aguda en dos medidas que no están · **seguir**

**Hoy** · seis arquitecturas, del endecasílabo al pentasílabo.

**Las fuentes** · Navarro Tomás es **la única de las seis que recorre la forma metro por metro**, y
da testimonio por encima y por debajo:

| **eneasílaba** | Su «Índice de estrofas» separa las dos ramas por ahí —«octava aguda» las **de nueve o más sílabas** y «octavilla aguda» las de ocho o menos—, y el § 342 documenta «la Avellaneda en cinco octavas agudas de _La cruz_», en eneasílabo dactílico. **El _Diccionario_ corta igual**: «Combinación estrófica de ocho versos de nueve o más sílabas» |
| **trisílaba** | § 272: Sánchez Barbero, en la cantata _Lucha entre la ley y el derecho_, «en cuatro octavillas agudas cuyas semiestrofas terminan alternativamente en las palabras _amor_, _honor_» |

**Decidir** · si entran. **La eneasílaba deja además un hueco lógico**: la ficha separa las dos ramas
por el arte del verso, y el corte cae hoy entre el decasílabo y el octosílabo, sin que ninguna
arquitectura recoja el nueve, que es donde las dos fuentes ponen la frontera.

### 7 · Faltan los esquemas que Navarro enumera · **seguir**

**Hoy** · las seis arquitecturas declaran `---a---a`: riman el cuarto y el octavo, los demás sueltos.

**Las fuentes** · Navarro Tomás **recoge las variedades una a una**. En la endecasílaba, las que
enlazan las semiestrofas por la rima, `ABBÉ:ACCÉ` y `ABBÉ:CBBÉ`, y la de heptasílabos agudos en
cuarto y octavo, `ABBé:CDDé`, «hecha famosa por Pastor Díaz en _La mariposa negra_». En la
octavilla, la de versos primero y quinto sueltos —«que había de convertirse en el **esquema más
corriente**»—, la de todos rimados `abbé:accé`, la alterna `abaé:cdcé` y **la de semiestrofas
monorrimas `aaaé:bbbé`**, que Nervo y Díaz Mirón documentan aparte.

**Decidir** · cuáles entran. _Entrarían como `admitida`, según la regla del 17 de septiembre._ Y una
cosa más: a la endecasílaba, «cultivada especialmente por Salvador Bermúdez de Castro, se le llamó
también **bermudina**», que no está entre sus denominaciones.

### 8 · El nombre de italiana, en discusión dentro de la ficha · **chocan**

**Hoy** · la ficha recoge las tres voces tal como cada una lo dice.

**Las fuentes** · **Quilis** la llama «octava italiana u octava aguda»; **Caparrós 2014** dice que
cuando va en arte menor «se llama octavilla aguda u octava italiana»; el _Diccionario_ «registra
octava italiana y octavilla italiana como otros nombres»; y **Navarro objeta**: «el calificativo de
italianas que suele darse a la octava y octavilla agudas **no las distingue de la octava real,
también de origen italiano**».

**Decidir** · nada del dato: las voces están recogidas, que es lo que la sección hace. _Si alguna vez
se decide que una disparidad así merezca un párrafo que la resuma antes de las seis fuentes, este es
el primer caso del catálogo que lo pediría. El segundo es el **verso aislado**, donde las cuatro
voces responden cosas distintas a si un verso solo es verso._

### 9 · La octava real, ¿una estrofa o dos? · **seguir**

**Hoy** · el catálogo ha tomado partido sin escribirlo: **al no declarar secciones afirma que es una
unidad de ocho**.

**Las fuentes** · Caparrós 2014 remite a la discusión de Lázaro Carreter sobre si es una estrofa o
la unión de dos, y el _Diccionario_ observa que «la estrofa **suele subdividirse en dos grupos de
cuatro versos** según su contenido».

**Decidir** · si se declaran secciones. Y si se declaran, **dónde corta**: 6 + 2, por el pareado
final, o 4 + 4, por el contenido.

### 10 · Un solo esquema catalogado, y la sospecha de que hay más · **chocan**

**Hoy** · `ABABABCC` habitual y, aparte, una «Distribución variable» **excepcional** sin notación,
que es la salida abierta.

**Las fuentes se parten en dos mitades.** Dos la definen sin variantes: Morley y Bruerton, «ocho
endecasílabos `ABABABCC`», y Caparrós 2014 igual. Dos dicen que varía: el _Diccionario_, «es
posible, **aunque no frecuente**, encontrar otra disposición de la rima de los seis primeros
versos», y Jauralde, que «recibió variaciones de todo tipo a lo largo del tiempo, conservando casi
siempre de manera fija el pareado final».

**Decidir** · **ninguna de las dos que admiten variación enumera las variantes**: dicen que las hay.
Así que no son esquemas que falten sino una norma abierta que el catálogo ya declara. Lo que queda
por decidir es si esa salida debe ser `excepcional`, como está, cuando dos fuentes la dan por
posible y otras dos ni la contemplan.

## Copla de arte mayor

1. **Faltan tres esquemas, y Navarro Tomás los nombra.** Los cuatro actuales —`ABBA:ACCA` habitual,
   `ABAB:BCCB` y `ABBA:ACAC` admitidas y `ABBA:CDDC` excepcional— enlazan los cuartetos, que es lo
   que la norma exige, y una guarda impide declarar uno con más de tres clases. La pregunta era si
   faltaban otros que las fuentes no destacaran; **su afirmación verificada los da con nombre**:
   además de `ABBA:ACCA` y `ABAB:BCCB`, «registra combinaciones de **solo dos rimas: `ABAB:ABAB`,
   `ABBA:ABBA` y `ABAB:BAAB`**».

   _Las tres tienen dos clases, así que pasan la guarda sin tocarla. Lo que hay que decidir es si
   entran —y con qué modalidad, que por la regla del 17 de septiembre sería `admitida`— o si quedan
   fuera por alcance, como cancioneriles que son. 2. **¿Se admite la copla de cuatro rimas como desviación?** Navarro Tomás registra una,
   `ABBA:CDDC`, en una carta de Tirso de Molina en _Quien calla otorga_ —y anota que los propios
   personajes aluden al carácter antiguo de la estrofa—. Es exactamente lo que el catálogo retiró
   como esquema normal. _Si el corpus trae una, habría que registrarla como desviación localizada._

3. **¿La arquitectura debe seguir llamándose dodecasilábica?** Hoy declara `12-repetido` en sus ocho
   posiciones. Jauralde advierte que, por la estructura rítmica del verso, **su número de sílabas
   varía entre diez y dieciséis**. _Si el corpus trae un verso de trece o catorce, hoy sería una
   desviación métrica y no una realización admitida._

## Soneto

1. **¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?** M&B dan los cuatro y
   añaden «y otros». **Es abierto, y la fuente da la regla, no una lista**: el _Diccionario_ dice
   que los tercetos toman dos o tres clases distintas de las de los cuartetos y las reparten como
   sea «con tal de que no haya más de dos versos seguidos con la misma rima». Desde el 19 de agosto
   esa regla está en la definición. _Codificarla son dos piezas: un esquema abierto de la sección
   `terceto` con `max_consecutivos: 2` junto a los cuatro concretos, y la evaluación de ese tipo en
   el auditor. El grupo pasaría de cuatro opciones a cinco, y esa quinta es justo la salida que esta
   duda pide._ ⇒ **B4**

2. **¿Qué disposición de tercetos merece ser la habitual, si cada fuente elige una distinta?** Hoy
   el catálogo asciende `CDC DCD` a **habitual** y deja `CDE CDE`, `CDE DCE` y `CDC EDE` en
   **admitida**. Y lo que pasa no es que nadie lo respalde, sino algo más incómodo: **cada fuente
   eleva una distinta, y el catálogo eligió la de Quilis sin decirlo**:

   | fuente                 | a cuál llama clásica o preferida                                                                                                                                                                                                                                                   |
   | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | Quilis 1969            | `ABBA-ABBA-CDC-DCD`, «esquema clásico», y la da por favorita de Petrarca                                                                                                                                                                                                           |
   | Jauralde 2020          | `ABBA ABBA CDE DCE`, «forma clásica»                                                                                                                                                                                                                                               |
   | Navarro 1972           | **Las dos, y lo dice dos veces.** Su glosario: «los tercetos han usado **preferentemente** las combinaciones `CDE:CDE` y `CDC:DCD`». Y al tratar los sonetos de Santillana: «las dos combinaciones que **en general han predominado**; en 27 casos, `CDC:DCD`, y en 14, `CDE:CDE`» |
   | Morley y Bruerton 1968 | las cuatro seguidas, sin jerarquía, advirtiendo que hay más                                                                                                                                                                                                                        |
   | _Diccionario_ 2016     | no lista ninguna: da la regla, que es el punto 1                                                                                                                                                                                                                                   |

   **Y Navarro reparte por autores**, comprobado en el libro el 16 de septiembre de 2026, § 107:
   Garcilaso usó «en primer lugar, `CDE:CDE`; en segundo, `CDE:DCE`; en tercero, `CDC:DCD`»;
   «Gutierre de Cetina mostró mayor predilección por `CDC:DCD`, y **Herrera, como Garcilaso, por
   `CDE:CDE`**»; y las más frecuentes en Boscán son «`CDC:DCD`, `CDE:CDE` y `CDE:DCE`».

   _Lo que las fuentes dibujan no es una preferida sino **dos que predominan**, `CDC:DCD` y
   `CDE:CDE`, con las otras dos por debajo. La modalidad del catálogo no recoge esa forma: hoy una
   está arriba y tres abajo._

   Tres salidas: dejar las cuatro en `admitida`; subirlas las cuatro a `habitual`; o mantener una y
   escribir en la ficha **a quién se sigue y por qué**, que es lo que hoy falta. _No es un arreglo de auditoría: la modalidad decide lo que el editor
   V2 ofrece al anotar y lo que el demarcador compila, así que cambiarla se nota en las dos puntas._

   **En los cuartetos no hay nada que decidir**, y conviene decirlo para que no se arrastre la duda:
   `ABBA ABBA` habitual y `ABAB ABAB` excepcional es exactamente lo que dicen las dos fuentes que se
   pronuncian —Navarro, «uniformemente con raras excepciones»; el _Diccionario_, «lo normal», pero
   «posibles otras distribuciones, especialmente la que obedece al esquema ABAB ABAB»—.

3. **¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?** Quilis describe el
   estrambote como uno o varios tercetos añadidos, con la condición de que el verso que sigue al
   decimocuarto sea un **heptasílabo que rime con él** —`ABBA ABBA CDE CDE eFF`—, y lo ejemplifica
   con el «Voto a Dios que me espanta esta grandeza» de Cervantes. _Es el más probable de los dos en
   un corpus áureo, y hoy no cabe: un soneto de diecisiete versos no encaja en la arquitectura._

---

# Estrofas compuestas de arte menor

## Copla real

1. **La frecuencia de una disposición reutilizada no es la de la posición que ocupa.** Las dos
   quintillas reutilizan la arquitectura de la quintilla, así que traen sus esquemas **con la
   frecuencia que tienen como quintilla suelta**: `aabba` sale «admitida» en la segunda mitad, donde
   M&B dicen que en Lope es _siempre_ esa. _El IP decidió el 20 de agosto decirlo en prosa y no
   tocar el modelo por ahora._ ⇒ **B3**

2. **La copla real de cuatro y seis versos.** Jauralde advierte que «la forma 4-6 precede a la 5-5,
   que solo se hace mayoritaria a finales del siglo XV»; Navarro Tomás describe el mismo proceso
   desde el modelo 4-4. El catálogo solo tiene 5+5.

3. **¿Los quebrados pueden ocupar cualquiera de las diez posiciones?** Hoy la pregunta las ofrece
   las diez. Ninguna fuente fija dónde caen. _Si se restringe, hay que decir a qué posiciones._

4. **¿Solo tetrasílabos, o también pentasílabos?** Las seis fuentes, al hablar de la copla real,
   **solo nombran el tetrasílabo**. La arquitectura declara los dos como `quebrado`. _Si se decide
   que solo vale el tetrasílabo, lo que se retira es esa fila y la pregunta se estrecha sola._

5. **¿Debe restringirse el par de quintillas?** Hoy las dos preguntas ofrecen los ocho esquemas con
   total independencia. M&B, que describen a Lope, la llaman «**combinación fija de dos quintillas de
   tipo diferente**»: la segunda siempre `AABBA` y la primera casi siempre `ABABA`, «**muy pocas
   veces `ABBAB` o `ABAAB`**». _Esa cola importa: la propia fuente documenta las excepciones de la
   primera, de modo que restringirla del todo iría más lejos que ella._ _No se ha restringido
   porque las otras cinco fuentes describen libertad y el catálogo cubre más que a Lope. Si se
   restringe, pasa a ser una restricción entre dos preguntas, que el modelo hoy no sabe expresar._
   ⇒ **B3**

6. **Pedir datos al editor de _El caballero de Olmedo_.** Es de las poquísimas formas con uso real
   —tres secuencias, todas en esa obra— y las anotaciones vienen del vocabulario legado, sin decir
   qué disposición tiene cada quintilla ni dónde caen los quiebros. _Al revisar la obra conviene
   pedírselo: es el único sitio donde el corpus puede contrastar lo que las fuentes dicen del
   emparejamiento._

## Novena

1. **Separar la Novena general de la Copla novena.** Las seis se reparten **dos, dos y dos**:
   Caparrós y el _Diccionario_ llaman novena a cualquier estrofa de nueve versos y niegan que
   comparta necesariamente otra norma —el _Diccionario_ llega a decir que «parecería dudosa la
   unidad de la novena como estrofa»—; Navarro Tomás y Jauralde caracterizan la copla novena
   histórica como redondilla y quintilla; y **Quilis y Morley y Bruerton no registran las estrofas de
   nueve versos**, el primero pasando «de las de ocho a las de diez sin epígrafe intermedio». _Las
   dos arquitecturas actuales pasarían a la Copla novena. Falta decidir cómo se registra la Novena
   general sin que el demarcador clasifique por defecto cualquier pasaje de nueve versos_, que es el
   mismo problema que hizo retirar la copla de pie quebrado.

2. **¿Cómo se representan las realizaciones tempranas en que redondilla y quintilla comparten una o
   dos clases de rima**, frente a las posteriores con rimas independientes? _Hoy las dos secciones
   reutilizan repertorios independientes y no hay manera de declarar que comparten timbre. El editor
   trata cada respuesta como notación local y, al componer la novena, renumera la segunda parte con
   letras nuevas. Esto evita aparentar enlaces inexistentes, pero si el texto sí enlaza ambas partes
   obliga a falsear la anotación: hace falta modelar equivalencias de rima entre secciones o una
   disposición global de la unidad._ **Es un bloqueo de registro, no solo de presentación.** ⇒ **B3**

3. **¿Las ocho variedades de quintilla valen todas para la Copla novena** o deben restringirse según
   la documentación histórica? _Hoy se ofrecen las ocho, por reutilización._

## Décima

1. **¿Entra la décima asonante?** Quedó fuera el 22 de agosto de 2026 al aplicar el criterio de qué
   compromete la norma: es un **régimen nuevo**, ninguna fuente lo registra con nombre ni
   definición, y Jauralde lo presenta como ensayo de Jorge Guillén «al rimarlas en asonante en vez
   de en consonante, **que era lo tradicional**». _Si el IP prefiere admitirla, la décima pasaría a
   declarar dos regímenes, como la silva desde ese mismo día._ Las cuatro medidas que faltaban
   —penta, hexa, hepta y endecasílaba— sí entraron: la hexasílaba la firma **Góngora**.

2. **¿Debe poder intercalarse alguna otra forma, además de la décima aumentada?** El editor ya sabe
   anotar una aumentada entre décimas normales: desde el 26 de agosto de 2026 una arquitectura puede
   declararse `intercalable` y una unidad suelta puede adoptarla, sin registrarla como desviación,
   porque no lo es. _Se abrió **solo para la décima**, por decisión del IP: si otras formas lo
   necesitan se abrirán cuando alguien lo pida, para no complicar el editor —ni exponer a error a
   los editores— en las cuarenta que no lo necesitan._ La duda queda anotada por si el IP conoce ya
   algún caso: **una realización de otra forma que aparezca dentro de una tirada sin romperla**.

   _Hay además un caso vecino que hoy no cabe y que el IP dejó explícitamente para el futuro:_ que
   lo intercalado sea de **otra forma**, como un pareado cerrando una tirada alirada. Hoy el
   disparador exige que la arquitectura declarada sea de la misma forma que la secuencia.

3. **¿El linaje debe limitarse a copla real, espinela y aumentada?** Es la única relación histórica
   declarada. _Ampliarlo obligaría a decidir qué otras formas de diez versos entran._

4. **¿«Décima aumentada» es el nombre adecuado para la arquitectura de doce versos?** _El nombre
   describe bien lo que es, pero llamar «décima» a una estrofa de doce puede leerse mal en la
   ficha._

5. **¿La definición debe seguir describiéndola como «dos redondillas abrazadas y dos versos de
   enlace»?** M&B la explican de otro modo: como combinación de **dos quintillas**, la 6.ª y la 5.ª,
   aunque advierten que lo característico es la pausa tras el cuarto verso. _Son dos lecturas de la
   misma estrofa y la definición ya elige una; la duda es si conviene que la otra conste, porque es
   la de la fuente del corpus dramático._

---

# Series estróficas breves

## Seguidilla

1. **La fluctuación histórica de la simple no tiene representación.** La documentan **cinco de las
   seis**, y solo Quilis calla: Navarro Tomás «documenta su antigua fluctuación», Jauralde
   «subraya su fluctuación histórica», Caparrós 2014 «recoge fluctuación métrica», el _Diccionario_
   la pone entre «las modificaciones más corrientes» y M&B advierten que «el ritmo pesa más que el
   cómputo silábico estricto y que las medidas pueden variar ligeramente». Pero el catálogo declara
   `7-5-7-5` fijo. _Hoy una seguidilla de medidas fluctuantes solo cabe como desviación métrica
   verso a verso._

2. **La seguidilla arromanzada comparte asonancia entre unidades y eso no se declara.** El
   _Diccionario_ y Jauralde documentan series en que una misma asonancia recorre varias estrofas.
   _Es el mismo mecanismo que el romance ya resuelve con su ciclo, y que desde el 22 de agosto usan
   las tres enlazadas._

3. **¿Las realizaciones consonantes recurrentes son opciones admitidas o desviaciones?** Caparrós
   2014 recoge consonancia y rima de los impares como variantes atestiguadas. _Hoy la asonancia es
   definitoria, así que una seguidilla consonante es desviación._

## Romance

_Sin cuestiones abiertas. Las dos medidas que faltaban —pentasílaba y tetrasílaba— entraron el 22
de agosto de 2026, con el criterio de que la medida no compromete la norma._

## Endecha real

1. **Las dos arquitecturas de sor Juana están fuera del teatro áureo.** La de cinco versos
   (`7-7-7-7-11`, `abbaA`) y la hexasílaba (`6-6-6-11`) se declaran porque Navarro Tomás y Jauralde
   las documentan, pero los dos las atribuyen a sor Juana y a la poesía culta del XVII-XVIII, no al
   teatro. **Ninguna fuente dice que no aparezcan en teatro**; simplemente no lo tratan.

2. **Faltan dos cosas que Navarro Tomás documenta y no tienen dónde ir.** Sor Juana hizo también el
   último verso **decasílabo de dos adónicos**, y en los _Nocturnos de San Pedro_ combina endecha
   real y sexteto con un pie quebrado en eco. _Las dos están registradas como afirmación; la segunda
   se buscó sitio en el sexteto y no lo tiene —ver [Sexteto](#sexteto) 4—._

3. **¿Es endecha real la que no rima?** Las fuentes se contradicen. Navarro Tomás § 207 dice que
   Bermúdez y Cervantes la emplearon **en versos sueltos**, `abcD`, y el _Diccionario_ lo admite.
   Jauralde § 3.6 dice lo contrario: el cuarteto se usó suelto, sí, pero «**se denominó endecha real
   cuando recibió rimas**», de modo que sin rima sería una cuarteta de heptasílabos. Es un
   desacuerdo entre fuentes autorizadas, no un descuido. _Hoy la `suelta` está como `admitida`.
   Según se resuelva, se queda, baja a `excepcional` o sale de la forma._ Su esquema es además un
   ciclo `[----]…` con cero posiciones ⇒ **B8**

4. **Una sola arquitectura reúne tres regímenes de rima.** La heptasilábica con endecasílabo final
   admite disposiciones **asonantes** —abrazada, cruzada y la sostenida en los cuartos—, una
   **consonante** —cruzada— y los **versos sueltos**. Es la única arquitectura activa del catálogo con
   tres. _¿Es una forma que se realiza de tres maneras, o hay ahí más de una forma? De la respuesta
   depende si la asonancia se puede preguntar siempre, como se pregunta hoy, o solo cuando la
   disposición elegida sea asonante._

---

# Los dos tramos sin forma

1. **El quebrado no es versificación irregular, y conviene vigilarlo al anotar.** El _Diccionario_
   lo advierte expresamente y Caparrós 2014 lo confirma al incluir la proporcionalidad en la
   definición de lo regular. Un pasaje 8-8-4 pertenece a la copla o a la sextilla de pie quebrado,
   no a este tramo. La definición ya lo dice. _Merece comprobarse contra las anotaciones existentes
   cuando se haga el informe de migración._

2. **Jauralde llama a esto de otra manera y no se ha seguido.** Prefiere «verso libre o liberado»
   para el conjunto que no busca ninguna proporción aparente, y reserva «irregular» para otro caso.
   _El catálogo conserva «Versificación irregular» por ser el término de las otras fuentes y del
   vocabulario legado; queda registrada la divergencia._

3. **Revisar las equivalencias de los tramos irregulares antes de migrarlos.** El vocabulario legado
   distingue tres —`irregular_arte_mayor`, `irregular_arte_menor` e `irregular_mixto`— y son de lo
   más anotado que hay: **nueve secuencias, 313 versos**. El catálogo nuevo tiene una sola entrada.
   _Es posible que alguna se anotara como irregular solo porque quien la anotó no encontró la forma
   precisa, y que con el catálogo nuevo y el demarcador sí aparezca._ ⇒ **A3**
