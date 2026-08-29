# Cuestiones para el IP

Estado: **vigente** · podado el 22 de agosto de 2026

Este archivo reúne **lo que sigue sin decidir y necesita criterio filológico**, forma por forma. No
describe el catálogo: eso se lee en `/formas`, que se genera del dato y no puede quedarse viejo.

> **Purga del 22 de agosto de 2026.** El archivo se había llenado de preguntas ya respondidas —unas
> por el IP, otras por las migraciones de la revisión de la prosa entre el 14 y el 22 de agosto— y
> costaba distinguir lo vivo de lo cerrado. Se recorrió entero contra la base y **se borró todo lo
> resuelto**: las dieciocho preguntas tachadas, las de la octavilla y la octava aguda, las del
> pareado, la de si la doble sextilla merecía nivel propio, la del criterio de cuándo la medida hace
> forma aparte, la de la densidad de la sextilla y la del grupo `tipologia` del sexteto-lira. Lo que
> queda está comprobado abierto.

## Lo urgente: dónde puede haber una forma mal modelada

*Puesto el 28 de agosto de 2026.* De todo lo abierto, estas cinco son las que **no son un matiz sino
la sospecha de que una forma no está donde debe**: o fija lo que no fija, o reúne bajo una arquitectura
lo que quizá sean dos, o tiene un nivel que no se sostiene. Son las que conviene resolver antes de que
se anote mucho con ellas, porque cambiarlas después obliga a revisar lo anotado.

1. **El septeto-lira fija su medida y quizá no deba.** Es la única de las cinco aliradas que declara
   posiciones —`7 11 7 11 7 7 11`—; las otras cuatro declaran repertorio abierto. Y su propia
   definición llama a esa disposición «la realización que la documenta», que es lenguaje de una entre
   varias. ⇒ [Lira, sexteto-lira y septeto-lira](#lira-sexteto-lira-y-septeto-lira)
2. **La endecha real reúne tres regímenes en una sola arquitectura**: asonante, consonante y sin
   rima. ¿Es una forma con tres realizaciones o son formas distintas que comparten medida?
   ⇒ [Endecha real](#endecha-real) 3
3. **El sexteto-lira: si su repertorio no tiene cierre y sus dos ejes son libres, ¿qué queda del
   nivel?** Es la pregunta más antigua de la lista y la que más estructura mueve.
   ⇒ [Sexteto-lira](#sexteto-lira) 1
4. **La canción sin rima: ¿arquitectura o forma propia?** Morley y Bruerton la registran como
   categoría aparte. ⇒ [Canción petrarquista](#canción-petrarquista) 1
5. **Qué repertorios de esquema están cerrados y cuáles son recortes del corpus.** Afecta al sexteto,
   al soneto y a la copla de arte mayor a la vez. ⇒ [Las que cruzan formas](#las-que-cruzan-formas)

*Y una que no toca el nivel pero deja un hueco al anotar:* **el remate y el eslabón de la canción no
declaran ni medida ni rima**, así que de un remate leído solo queda registrado cuántos versos tiene.
⇒ [Canción petrarquista](#canción-petrarquista) 5

## Cómo se lee, y qué relación tiene con los pendientes

Hay **dos inventarios y no dicen lo mismo**:

- **[Qué queda pendiente](./CONTEXTO-PARA-CONTINUAR.md#qué-queda-pendiente)** es lo que el proyecto
  tiene que **hacer**, ordenado por lo que bloquea los dos hitos siguientes. Ahí van las deudas del
  modelo, los huecos de cobertura y lo que el editor no sabe registrar.
- **Este archivo** es lo que hay que **decidir**, y la decisión es filológica: qué admite una forma,
  hasta dónde llega su repertorio, si una realización documentada entra o se queda fuera.

Muchas preguntas tienen las dos caras. Cuando la tienen, **el apunte lleva su código** —`⇒ A3`,
`⇒ C1`— y ahí se lee el lado técnico. Ninguna pregunta de este archivo impide anotar hoy, y
`npm run audit:metrica` no señala ningún defecto.

Cada apunte cierra en cursiva con **qué cambiaría si se decide otra cosa**.

## Las que cruzan formas

Son las que no se ven leyendo una sola sección. Conviene decidirlas juntas, porque responderlas
forma a forma produce criterios distintos para el mismo caso.

| Cruce | Dónde | Estado |
| --- | --- | --- |
| **Qué es una variedad**, si el repertorio del sexteto-lira no tiene cierre y sus dos ejes resultan libres | [Sexteto-lira](#sexteto-lira) 1 | **abierto**: decidir si el nivel se conserva |
| **Qué repertorios de esquema están cerrados** y cuáles son recortes del corpus | [Sexteto](#sexteto) 3 · [Soneto](#soneto) 1 · [Copla de arte mayor](#copla-de-arte-mayor) 1 · [Octava real](#octava-real) 2 | **abierto, y menos urgente desde el 25 de agosto de 2026**: con la salida abierta, un repertorio incompleto ya no pierde el dato —el editor declara lo que ve y el catálogo lo reconoce si ya lo tenía—. *El de las medidas se cerró el 22 de agosto: la medida no compromete la norma y se declara cuando una fuente la documenta —[criterios de nivel § 3.6](./criterios-de-nivel.md)—* |
| **Qué elecciones dependen de otras**, que el modelo hoy no sabe expresar | [Copla real](#copla-real) 4 · [Novena](#novena) 2 · [Sexteto-lira](#sexteto-lira) 1 | **abierto** · ⇒ **C1** |
| Cómo se representa una **norma abierta** sin enumerar cada realización | [Silva](#silva) 1 · [Seguidilla](#seguidilla) 1 · [Novena](#novena) 1 | **abierto en lo filológico; el aparato se cerró el 25 de agosto de 2026** con las reglas 2 y 3 de [criterios de nivel § 3.3](./criterios-de-nivel.md): donde hay unidad, lista y salida abierta, y lo escrito se normaliza y se casa con el catálogo. *Lo que sigue sin decidir es qué acota cada norma, no cómo se registra.* |
| **Modelar lo que las fuentes describen aunque el corpus no lo traiga**, o no | [Sexteto](#sexteto) 5 · [Sextilla](#sextilla) 7 · [Copla real](#copla-real) 2 · [Endecha real](#endecha-real) 2 | **abierto** · ⇒ **C11** |
| **Los finales esdrújulos y agudos**, ¿en todas las formas o solo donde se documenten? | abajo | **abierto** · ⇒ **C16** |
| **Cuántos versos admite quebrados la redondilla, la copla castellana y la copla de arte menor.** Las tres documentan el quiebro **sin fijar el verso** —«sin fijar en qué versos cae», «alternando versos plenos y quebrados»—, así que ninguna da máximo. Las otras siete sí lo declaran desde el 25 de agosto de 2026: una posición nombrada es un quiebro contado | [Redondilla](#redondilla) · [Quintilla](#quintilla) | **abierto** · ⇒ regla 5 bis del [§ 3.6](./criterios-de-nivel.md) |

### Los finales esdrújulos y agudos

El rasgo `final_acentual` marca la terminación sostenida en los finales de verso —esdrújula o
aguda—, y **se declara sin un criterio que una a las arquitecturas que lo llevan**. Contrastado el
dato, hay un desajuste que se ve a simple vista:

Contrastado de nuevo el 25 de agosto de 2026, al cerrar B2. **Seis arquitecturas declaran
`esdrujulo` y las seis lo preguntan ya**; el desajuste que quedaba era el del endecasílabo suelto,
que lo declaraba y no lo preguntaba, y se cerró ese día.

| Declara `esdrujulo` el catálogo | Tiene subtipo en el vocabulario legado |
| --- | --- |
| canción petrarquista · sin rima con pareado final | ✔ `cancion_sin_rima_de_esdrujulos` |
| octava real | ✔ `octava_real_de_esdrujulos` |
| sexteto-lira | ✔ `sexteto_lira_de_esdrujulos` |
| terceto | ✔ `terceto_de_esdrujulos` |
| endecasílabo suelto | ✔ `endecasilabo_suelto_de_esdrujulos` |
| **soneto** | **—** |

**Lo que queda del desajuste es una sola fila**: el soneto lo declara sin término legado que lo
respalde. Las otras cinco se corresponden una a una con el vocabulario, y ninguno de los seis
términos de esdrújulos se queda ya sin destino.

Y el valor `agudo` lo llevan la octava aguda —donde es definitorio y no se pregunta, porque su
propio esquema dice dónde cae—, el septeto y el sexteto alejandrino, mientras Jauralde dice que «la
modalidad aguda se extendió a otras muchas variedades estróficas, **como la sextilla y la décima**».

*La pregunta es si esto se declara **en todas o casi todas las formas** —porque cualquier estrofa
puede rimar en esdrújulos o en agudos, y entonces lo que el rasgo aporta es poder anotarlo cuando
ocurre— o **solo donde una fuente o el corpus lo documenten**, y entonces hay que cerrar el
desajuste en los dos sentidos. Ninguna de las seis monografías respalda hoy el rasgo en la octava
real: lo que lo sostiene es el vocabulario legado.*

## Demarcador

1. **Las formas generales no tienen prioridad residual.** El **sexteto** cumple una función
   residual frente a formas más específicas de seis versos de arte mayor, y desde el 21 de agosto
   la **septilla**, la **oncena** y las tres **enlazadas** conviven con estrofas de su misma
   extensión. El antiguo `grado_especificacion` pretendía que el demarcador ofreciera la forma más
   específica, pero se retiró porque el motor nunca lo usó: hoy todas las hipótesis se puntúan al
   mismo nivel. *Hace falta una regla explícita de prioridad o una salida final separada. No es una
   relación `subtipo_de` ni `compuesta_por`: esas describen la ontología de las formas, no el orden
   en que el motor propone una clasificación.*

---

# Series y composiciones largas

## Silva

**Qué tiene hoy:** cinco arquitecturas —cuatro consonantes y la arromanzada, que entró el 22 de
agosto de 2026— situadas en dos ejes. `densidad_de_rima` dice
cuántos versos riman —*ninguna · esporádica · mayoritaria · total*— y `organizacion_en_pareados` qué
figura dibujan los que riman —*ninguna · ocasionales · habituales · predominantes · regulares*—.

1. **¿Dos de las cuatro silvas se diferencian solo por un valor de rasgo?**

   | | esquema de rima | densidad | pareados |
   | --- | --- | --- | --- |
   | Consonante de orden libre | `consonante-orden-libre` | mayoritaria · total | **predominantes** |
   | Libre | `consonante-orden-libre` | mayoritaria · total | **ninguna** |

   Comparten esquema, medida y densidad admitida: **lo único que las separa es el valor de un
   rasgo**. Y un rasgo es una respuesta *dentro* de una norma, no una norma: si dos arquitecturas no
   se distinguen más que por él, una de las dos es un nombre y no una realización estructural.

   *A favor de dejarlas:* las cuatro salen de los cuatro tipos de Morley y Bruerton, y el corpus
   todavía no ha hablado. *A favor de fundirlas:* el editor tiene que elegir entre dos arquitecturas
   cuya diferencia no puede observar antes de haber contado los pareados, que es lo que el rasgo
   pregunta después. **Es la clase de caso que este modelo está hecho para resolver con datos**:
   cuando haya silvas anotadas, se mira si alguna cae en `predominantes` sin ser también otra cosa.

2. **¿Se recoge la silva 4.ª de Morley y Bruerton** —7 y 11 mezclados, **todas las rimas en los
   pares**—? **Es consonante**, como las otras tres, y cabría como quinta arquitectura sin tocar la
   cabecera. **No es ninguna de las cuatro que ya hay**: no es la `Consonante regular`, que son
   pareados; y no cabe en las abiertas porque `consonante-orden-libre` **no tiene posiciones**, de
   modo que no puede declarar que la rima caiga en los pares, ni en `Libre`, porque con los impares
   sueltos la densidad no llega a `mayoritaria`. *Estructuralmente es la figura del romance —`[-a]…`—
   pero consonante y heterométrica, y por eso la pregunta de si la acerca al romance heroico no es
   retórica: requeriría un esquema cíclico con posiciones, que ninguna silva tiene hoy.* Comprobado
   dos veces que **tampoco estaba en el vocabulario legado**: no se perdió al migrar, no se declaró
   nunca.

3. **¿La silva exige rima?** El *Diccionario* admite como silva la combinación de 7 y 11 sin rima.
   El catálogo no, y la definición lo dice: «un pasaje de siete y once enteramente suelto no es una
   silva». La razón es de corpus y la respalda Navarro Tomás § 158: desde 1588 Lope intercalaba
   pareados en pasajes de 7 y 11 sueltos, así que en la comedia lo que separa la silva del pasaje
   suelto es que rime. *Por decisión del IP la lectura del* Diccionario *se conserva en las
   afirmaciones y no se codifica; conviene confirmar que el corte vale también en la heterométrica.*

4. **Tres arquitecturas declaran una sección cuyo único contenido es el periodo.** La regla es que
   las secciones describen el **interior** de una unidad, así que una parte se justifica cuando el
   periodo existe por algo más que la rima:

   | Arquitectura | Sección | ¿El periodo es también métrico? |
   | --- | --- | --- |
   | Silva · Consonante regular | «Serie de pareados regulares» · 2 versos | **Sí**: `7-11-repetido` alterna las dos medidas |
   | Terceto encadenado ×2 | «Cadena de tercetos» · 3 versos | No: `11-repetido` y `8-repetido` |
   | Romance | *(ninguna, y es lo correcto)* | No: `8-repetido` |

   *La de la silva se sostiene sola. La del terceto encadenado se parece más al romance, pero su
   ciclo `[ABA]…` con dos enlaces es bastante particular como para mirarlo aparte.*

## Endecasílabo suelto

2. **¿Se admiten series sueltas de otras medidas?** Esta forma es endecasilábica por definición.
   Caparrós documenta el heptasílabo sin rima de Francisco de la Torre y ocho octosílabos sueltos de
   Hurtado de Mendoza; el *Diccionario* añade series de pentasílabos.

3. **La esquina de las *Nise*: heptasílabos mezclados y sin rima.** No es silva, porque la silva
   exige rima, y no es endecasílabo suelto, porque este es solo de once. Navarro Tomás lo documenta
   **en el teatro**: Jerónimo Bermúdez compuso *Nise lastimosa* y *Nise laureada*, de 1577, en
   endecasílabos sueltos, «donde además mezcló endecasílabos y heptasílabos sueltos». *Se anota por
   si alguna de las dos entra en el corpus: entonces habrá que decidir si el endecasílabo suelto
   gana una arquitectura heterométrica o si la frontera con la silva se redibuja.* ⇒ **C15**

4. **¿Es «una clase de silva», como dice Caparrós 2014?** El catálogo las tiene como formas
   distintas unidas por `contrasta_con`. Ninguna otra fuente las identifica. *No se han fusionado;
   queda registrado que una de las seis las clasifica juntas.*

## Canción petrarquista

1. **¿La canción sin rima debe seguir siendo arquitectura o tiene identidad de forma?** No es una
   aportación sin fuente: **Morley y Bruerton la registran como categoría propia** —«Canción sin
   rima»— y la describen igual que el catálogo. *Que la fuente la liste aparte, junto a la canción,
   es argumento para cualquiera de las dos respuestas; lo que ya no cabe es decidirlo sin ella.*

2. **¿Debe exigirse siempre remate o envío?** Hoy la sección `remate` es opcional en las dos
   arquitecturas consonantes y no existe en la canción sin rima. Las cinco fuentes que describen la
   composición lo dan como lo normal pero ninguna lo declara imprescindible. *Si se exige, las
   canciones sin remate pasarían a incumplir la norma; antes habría que decidir si la canción sin
   rima participa de ese cierre.*

3. **El tramo bajo del intervalo solapa con la lira.** Jauralde sitúa la estancia «normalmente por
   encima de los ocho versos (para diferenciarla de las liras)», y el *Diccionario* describe la
   canción alirada como la variante cuya unidad oscila entre cuatro y ocho. Es decir, una estancia
   de 5 a 8 versos es territorio de la lira, del sexteto-lira y, desde el 21 de agosto, del
   septeto-lira. *No se ha tocado el intervalo, que es el de M&B, pero ahí las formas se rozan.*

4. **¿Las estancias de la canción sin rima repiten también la distribución posicional de 7 y 11?**
   El catálogo lo exige con `define_norma`. M&B la describen como «versos de siete y once sílabas,
   agrupados en estrofas sin rima, excepto un pareado final», pero no añaden que el orden métrico
   sea idéntico entre estrofas, como sí hacen al definir la canción consonante.

5. **¿Qué documentan las fuentes sobre la medida y la rima del remate y del eslabón?** El catálogo no
   les atribuye ninguna de las dos. Contado sobre las **once secciones opcionales** que hay en cuatro
   formas, las del terceto encadenado declaran medida y rima y las del villancico y el zéjel declaran
   la medida; **las tres de la canción —dos remates y el eslabón— no declaran ninguna**, y el remate
   de la regular admite de uno a trece versos. *Si las fuentes fijan algo, se declara y deja de estar
   abierto; si no lo fijan, queda abierto de veras y habrá que registrarlo al anotar, como todo lo
   que la norma no fija.*

## Villancico

1. **¿Se segmenta la mudanza de cuatro versos en dos miembros simétricos?** Las fuentes la describen
   como **dos mudanzas simétricas**; el catálogo conserva una sola sección de cuatro y lo explica en
   su nota. *Segmentarla daría dos secciones hermanas donde hoy hay una, y afectaría a la ficha y al
   registrador.*

2. **¿Entran las mudanzas de seis versos?** Están formalizadas `abba`, `abab` y la asonantada
   `-a-a`; Navarro Tomás documenta además mudanzas excepcionales de seis. *Hoy solo caben como
   desviación.*

3. **¿Hasta dónde llega el estribillo: cuatro versos o siete?** Caparrós fija la cabeza en **dos a
   cuatro**; Navarro Tomás recoge estribillos de **dos a siete**. *El IP decidió el 10 de agosto
   quedarse en 2-4, de modo que uno de cinco a siete entra como desviación. Queda anotado porque es
   la misma disyuntiva que la vuelta —donde se optó por lo contrario, dejarla abierta— y conviene
   revisarlas juntas si algún día se unifica el criterio.*

4. **¿Se restringe la arquitectura de estribillo posterior?** Representa una familia funcional
   abierta, pero la fuente que la sustenta describe algo concreto: una cuarteta octosilábica seguida
   de un estribillo en cuarteta hexasílaba. *Restringirla la haría verificable; dejarla abierta
   permite registrar realizaciones que la fuente no describe.*

5. **¿Debe el editor registrar por separado la rima del estribillo y la del enlace y la vuelta?**
   Hoy pregunta por la rima de la mudanza, pero no conserva las rimas concretas de las otras partes;
   sin esos datos no podrá reconstruirse después cómo enlazan las secciones en cada realización.

6. **¿Son una sola arquitectura las dos del villancico?** Lo único que las separa es **dónde aparece
   el estribillo por primera vez**. Podría resolverse con una pregunta dentro de una sola
   arquitectura. *No se hizo porque el demarcador distingue por arquitectura y perdería capacidad de
   identificar, y porque las fuentes presentan la cabeza inicial como el modelo y la otra como una
   modalidad.* ⇒ **C10**

## Zéjel

1. **¿Una repetición parcial del estribillo es posibilidad admitida o desviación?** Hoy la represa
   es total o no aparece. Ninguna de las cinco fuentes que tratan el zéjel describe repetición
   parcial —sí lo hace Jauralde para el villancico—.

2. **¿Se admite la mudanza de dos versos?** Hoy es de tres, y es lo definitorio de la forma. Navarro
   Tomás documenta la variante `aa:bba` **también en el Siglo de Oro**. *Relajar la mudanza toca el
   núcleo de la definición.*

3. **¿Y el zéjel en arte mayor?** Hoy el esquema métrico ofrece 6 u 8 sílabas. Navarro Tomás
   registra dos zéjeles en arte mayor en el *Cancionero de Baena*, y variantes que modifican
   estribillo y vuelta —`aba:cccba`, `abba:cccaca`—. *Son medievales y cultas, no del corpus
   dramático; se dejan fuera a la espera de que aparezcan.*

---

# Estrofas de arte menor

## Pareado

1. **Una tirada de pareados alirados, ¿es una silva?** El pareado alirado combina heptasílabo y
   endecasílabo y rima en consonante. Repetido, es exactamente lo que describe la silva consonante.
   *Si son la misma cosa, el alirado no debería poder abarcar más de dos versos y hay que decirlo en
   el catálogo; si no lo son, hay que saber qué los distingue, porque el editor hoy deja registrar
   una tirada de veinte versos como diez pareados alirados.* La pregunta general —**qué formas no
   admiten repetirse dentro de una secuencia**— el modelo no la sabe expresar: la regla de longitud
   dice cuántos versos mide cada unidad y nada limita cuántas caben. ⇒ **F42**

## Redondilla

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Hoy sí: el esquema se elige por
   unidad. *Si no pudiera, serían dos arquitecturas más por medida y la redondilla se registraría
   sin ninguna pregunta.* Se mantiene así porque es **la opción reversible**: corregirlo después es
   reclasificar filas, mientras que haberlo tratado como arquitectura habría partido secuencias que
   no debían partirse.

## Quintilla

1. **Faltan quintillas con verso suelto, y quedan fuera por alcance.** Jauralde registra `abcab`,
   `abbca` y `abaca`, que él mismo describe como transgresión de las viejas normas. El catálogo
   declara `versos_sueltos: ninguno`. *Es una decisión de alcance del corpus, no una norma: si el
   corpus las trae, se recogen y se relaja la restricción, sin que eso desmienta nada.*

2. ~~**`min_alternancias: 2` no es la regla de las fuentes.**~~ **Resuelto el 25 de agosto de 2026**
   (`20260825380000`). Las tres medidas declaran ya `max_consecutivos: 2`, que es la regla que
   enuncian las fuentes —«no más de dos versos seguidos con la misma rima»—. El sucedáneo se mantuvo
   dos meses por dos motivos que ese día desaparecieron los dos: el auditor no evaluaba ese tipo, y
   declararlo habría hecho que protestara por `abbba`, que ahora salta por excepcional.

   *Y no filtraba nada:* medidas las ocho disposiciones, las ocho pasaban `min_alternancias: 2`,
   `abbba` incluida. Con la regla buena, la única que se separa es `abbba`, que es justo lo que la
   tradición trata como aparición suelta.

   **Cambia lo que la forma afirma, y conviene saberlo:** antes el criterio admitía las ocho
   disposiciones y ahora admite siete. `abbba` sigue en el catálogo como excepcional, que es donde
   le toca. La descripción del patrón se reescribió en consecuencia. *Con esto ninguna arquitectura
   declara ya `min_alternancias`: era la única que lo usaba.*

4. **Dónde cae el quiebro: lo documentado ya se declara; queda lo inferido.** El 29 de agosto de
   2026 se declararon las posiciones de las cuatro arquitecturas cuya nota nombra un verso **y tiene
   detrás una realización leída**: la quintilla en el primero —Navarro Tomás § 154, «la quintilla con
   verso inicial quebrado fue la estrofa más usada por Castillejo»—, la septilla en el quinto, la
   novena en orden 4+5 en el quinto —«el único caso que las fuentes documentan»— y la oncena en orden
   5+6 en el octavo y el undécimo, por el *Claro escuro* de Juan de Mena.

   **La oncena en orden 6-5 entró después, el mismo día**, en el tercer verso y el sexto. El reparo
   que la había dejado fuera —que la afirmación de fuente para ese orden recoge `ababba:babba` y
   `abaaab:cdccd` *sin quebrados*— no valía: **un esquema de rima no declara medidas**, así que de
   una notación de rima no se concluye que los versos fueran plenos. Y la misma fuente afirma que
   «la estrofa de once con quebrados fue más corriente que la de octosílabos plenos». Lo que sitúa
   los quiebros es la estructura: **son los que cierran cada terceto de la sextilla**, y con este
   orden la sextilla va delante.

   **Y la novena en orden 5+4 dejó de admitir quiebro**, el mismo día. Su nota decía que ninguna
   fuente documenta un ejemplo, y la posición salía de trasladar a este orden lo que sí se lee en el
   otro. Se le retiraron la declaración del rasgo, la pregunta y los dos roles de quiebro: la
   arquitectura afirma ahora nueve octosílabos, que es lo documentado. *El orden 4+5 conserva el
   suyo, porque allí hay una realización leída.* Si aparece un ejemplo, se repone: el razonamiento y
   los dos textos que se retiraron están en el comentario de la migración.

   *Y tres preguntan en todos los versos con razón*, porque su nota lo dice: la copla real —«la
   tradición no fija en qué verso»—, la redondilla —«sin fijar en qué versos cae»— y la copla de arte
   menor. La copla castellana queda aparte: nombra un verso **y** un patrón alterno, y no da máximo.
   ⇒ **F44**

5. **Tipología 8 es numeración nuestra.** Navarro Tomás numera **siete** y M&B dan las mismas siete.
   `abbba` no lo numera nadie: lo registran como aparición suelta, que M&B atribuyen a errata o a
   adaptación expresiva. *Decisión del IP el 19 de agosto: se conserva el número 8, a la espera de
   ver si el corpus lo confirma. Si no aparece más, conviene renombrarlo para no atribuir a Navarro
   Tomás un octavo tipo que no dio.*

## Sextilla

1. **¿Es una arquitectura más la sextilla quebrada en segundo y quinto, o una desviación?** El
   *Diccionario* ilustra su entrada con una estrofa de Lucas Fernández quebrada en **segundo y
   quinto**, y Jauralde documenta las sextillas de Ricardo Gil en esas mismas posiciones. Desde el
   18 de agosto lo dice la descripción de la arquitectura, y el esquema declara además que el
   quebrado puede medir cuatro **o cinco** sílabas. *Falta decidir qué hacer cuando el corpus traiga
   una quebrada en otras posiciones.*

3. **¿Nada distingue dos sextillas consecutivas de una copla manriqueña?** Los versos, las medidas y
   el tipo de rima son idénticos; lo único que cambia es si las rimas de la segunda mitad dependen
   de la primera. Hoy **lo decide el editor al elegir forma**, no un criterio observable. *Es la
   misma pregunta que la copla castellana frente a dos redondillas, y las dos definiciones ya la
   admiten en voz alta.*

4. **¿Debe registrarse el esquema exacto de las coplas manriqueñas no manriqueñas?** La forma de
   doce tiene dos esquemas: el manriqueño `abcabc|defdef`, que se marca si es el observado, y uno de
   distribución variable para todo lo demás, que **no guarda cuál fue**. *Si interesa compararlas
   entre sí, esa información hoy se pierde.*

5. **¿Se admiten las tres disposiciones que Navarro Tomás documenta para la hexasílaba?** Le
   documenta **rimas alternas** en Juan Ruiz (§ 30); la **aguda `aaé:bbé`** en Eugenio Gerardo Lobo
   (§ 245); y el **lay**, «breve canción amorosa de origen francoprovenzal en sextillas hexasílabas
   con insistentes rimas agudas», con `ááá:ááé` de don Álvaro de Luna. **No se registraron por
   criterio cronológico**: Juan Ruiz es del XIV, Álvaro de Luna del XV y Lobo del XVIII. *Ojo a las
   agudas: la rima aguda no es una clase de rima sino una cualidad del final, y el catálogo la lleva
   en `final_acentual`, así que declararlas obligaría a decidir cómo se escribe `aaé:bbé` sin
   confundir las dos cosas.*

6. **¿Puede una sextilla dejar un verso suelto?** **Tres de las seis documentan que sí**, y en el
   mismo poema: las sextillas del *Martín Fierro* dejan sin rima el primer verso. *Decisión del IP
   el 18 de agosto: fuera por criterio cronológico —el* Martín Fierro *es de 1872—.* Es una decisión
   de **alcance del corpus**, no una norma. La distinción costó una rectificación: el primer intento
   lo escribió como `versos_sueltos: ninguno`, que es afirmar lo contrario de lo que dicen tres
   fuentes, y se retiró el mismo día.

   **Lo que dejó escrito, y vale para todo el catálogo:** para la sextilla **ninguna de las seis
   enuncia una regla** —Quilis cierra su lista con un «etc.»—, y **la enumeración de una fuente no
   es una norma**: derivar de ella un mínimo convierte una muestra en ley. *`numero_clases`,
   `min_alternancias` y `max_consecutivos` solo se declaran cuando una fuente enuncia la regla.*

7. **Las cuatro disposiciones históricas de la copla manriqueña no se han creado.** Navarro Tomás
   § 68 enumera con ejemplo y localizador la serie entera: `aab:aab-aab:aab`, `aab:aab-bba:bba`,
   `aab:aab-ccd:ccd` y `abc:abc-def:def`, «que alcanzó fama permanente con las coplas de Jorge
   Manrique». Hoy el catálogo declara solo la última. **No se han creado a propósito**: son
   cancioneriles del siglo XV y no del corpus dramático. ⇒ **C11**

---

# Estrofas de arte mayor e italianas

## Sextina

1. **Son las dos únicas formas del catálogo con tres tradiciones** —provenzal, italiana y española—.
   Es cierto en la historia: la inventó Arnaut Daniel, la fijaron Dante y Petrarca y entró en España
   en el XVI. Pero **ninguna otra forma declara más de una**, incluido el soneto, que llegó por el
   mismo camino. *La duda es si «tradición» quiere decir aquí el origen remoto o la vía por la que
   entra en la métrica española.* ⇒ **C13**

## Terceto

*Sin cuestiones abiertas. El tercetillo entró el 22 de agosto de 2026 con sus dos medidas, su
disposición monorrima y la asonancia que el* Diccionario *le admite; la septilla, que lo esperaba,
ya lo referencia.*

## Lira, sexteto-lira y septeto-lira

1. ~~**Las formas aliradas se deciden aparte y en conjunto.**~~ **Resuelto en parte el 24 de agosto
   de 2026.** Entraron el **cuarteto-lira** y la **octava-lira**, que son las que documenta el
   *Diccionario* —la serie que acota «entre los cuatro y ocho versos»—, más la octava variedad del
   sexteto-lira y el pareado alirado. La **novena-lira** y la **décima-lira** quedan para después de
   B1: no las registra ninguna fuente, así que entrarán con la disposición abierta y será el editor
   quien declare la que vea. *No es falta de apoyo: es que son el caso de rima abierta, y el sitio
   donde se documentarán es esta base.*

1bis. **Cuando la cabeza se repite pero no hay eslabón, ¿es canción o es alirada?** Es la única
   pregunta que queda de la serie, y se la hizo el IP antes que nadie. Lo que separa una estancia de
   canción de una estrofa alirada es **la ordenación**: fronte partida en dos piedi idénticos,
   eslabón —el verso que abre la sirima repitiendo la rima que cerró la fronte— y sirima con rimas
   nuevas. Pero **el eslabón no sirve de prueba**, porque el propio IP escribe que la sirima «suele»
   empezar con chiave: es habitual, no constitutivo. Y **la prueba de los dos piedi sola no basta**:
   aplicada al patrón `aBaBcDcDeE` que la edición de *Elisa Dido* llama «décima-estancia», da
   `aB` + `aB` de fronte y `cDcDeE` de sirima, es decir, **la declara canción** — que es lo que el
   IP consideraba forzado.

   | Cabeza repetida | Eslabón | Veredicto |
   |---|---|---|
   | sí | sí | canción, sin discusión |
   | no | no | alirada, sin discusión |
   | sí | no | **zona gris** |

   No hay un tercer rasgo formal que rompa el empate; lo que queda son criterios de grado —el
   *Diccionario* llama a las aliradas «cortas y simétricas» y las acota en cuatro a ocho versos—.
   *La propuesta técnica es que la base registre los tres rasgos —esquema observado, si la cabeza se
   repite, si hay eslabón— y que la asignación quede como lectura declarada y revisable. Pero dónde
   cae la zona gris lo decide el IP.* De ello dependen también las **canciones de 8, 9 y 15 versos**,
   que hoy no se distinguen de una octava-lira o una décima-lira porque su arquitectura no tiene
   modelada ninguna ordenación.

1ter. **¿El septeto-lira debe quedar abierto como sus hermanas nuevas?** El IP decidió el 26 de
   agosto de 2026 dejar **abiertas de metro y de rima** las formas aliradas nuevas —cuarteto,
   septeto, octava, novena y décima-lira—, porque todavía no se sabe qué hay en el corpus y la base
   es donde se va a documentar. Pero contado contra la base, **el septeto no está así**: tiene el
   metro fijo en `7 11 7 11 7 7 11` y un único esquema de rima, `ababbcc`, marcado `habitual` —es
   decir, «suele ser este», luego hay otros— y **no pregunta nada**, de modo que quien encuentre uno
   distinto no puede registrarlo. *Sus cuatro hermanas sí están abiertas.* ⇒ **B8**

2. **El sexteto simétrico `abC:abC` de san Juan de la Cruz no está.** Lo documenta Navarro Tomás en
   la *Llama de amor viva*: seis versos de siete y once, pero **sin pareado final**, de modo que
   ninguna de las siete variedades lo acoge y no cabe en la definición actual. *¿Es otra forma, una
   variedad que obliga a ensanchar la definición, o queda fuera del corpus?* Va con el punto 1.

**¿El septeto-lira es de medida fija o abierta?** *Salió el 27 de agosto de 2026.* Las otras cuatro
aliradas —cuarteto, octava, novena y décima— declaran repertorio `7/11` **sin posiciones**, y desde
ese día registran verso a verso lo que se lee. El septeto-lira, en cambio, **fija la medida**: `7 11 7
11 7 7 11`. Pero su definición presenta esa disposición como «la realización que la documenta», que es
lenguaje de una realización entre varias. *Si es abierta como sus hermanas, se le crea la misma
pregunta y deja de fijar posiciones; si es fija, conviene que la definición no diga «la realización
que la documenta».*

## Sexteto-lira

1. **¿Por qué esas ocho combinaciones y no otras?**

   **De dónde salen.** No de una restricción documentada, sino del vocabulario legado: eran siete
   subtipos escritos uno a uno y la matriz de importación los mandó a `variedad`. Que fueran siete de
   quince era el resultado de tener siete filas —**y el 24 de agosto de 2026 entró una octava,
   `A4 · aBaBCC`**, lo que confirma que la lista no cerraba nada: crecía al leer—.

   **Los dos ejes son libres.** Comprobado: las cinco secuencias de medidas y las tres disposiciones
   de rima son independientes, y nada impide combinarlas.

   | Medidas | `ababcc` | `abbacc` | `aabbcc` |
   | --- | :---: | :---: | :---: |
   | `7-11-7-11-7-11` | **A1** | — | — |
   | `11-7-7-11-7-11` | **A2** | — | **C1** |
   | `7-7-7-11-7-11` | **A3** | — | — |
   | `7-7-7-7-7-11` | — | **B1** | — |
   | `11-7-7-11-11-11` | — | **B2** | **C2** |

   **Ninguna de las seis prohíbe combinación alguna**, y dos terminan la enumeración en abierto: M&B
   citan tres «entre otras» y Navarro Tomás cuatro «y otras». **Tres que las fuentes nombran y el
   catálogo no tiene:** `AbbAcC` cabría sin añadir nada —es una de las ocho casillas vacías—;
   `AbAbcC` y `aBaBCC` exigen un esquema métrico nuevo.

   **Lo que está en juego.** Hoy es una pregunta con siete opciones. La alternativa son **dos
   preguntas cerradas** —¿qué secuencia de medidas? (5) y ¿qué disposición de rima? (3)—, que cubren
   las quince. *Si los dos ejes son libres, la contraprueba de
   [criterios de nivel](./criterios-de-nivel.md) dice que la variedad «no hace falta».*

## Sexteto

1. **¿Se admite el sexteto que combina arte mayor y menor?** Hoy no: el catálogo exige isosilabismo
   de arte mayor. Pero Caparrós 2014 lo incluye en la definición —«de arte mayor, o de arte mayor y
   menor combinados entre sí»—, el *Diccionario* añade que a veces el término cubre el arte menor, y
   Jauralde reserva un grupo a los «sextetos mixtos». *El catálogo lo separa a propósito: la
   heterometría regular con endecasílabo es del sexteto-lira y el arte menor es de la sextilla.*

2. **¿Las medidas 11, 12 y 14 son un repertorio cerrado?** Jauralde describe además sextetos
   eneasilábicos, decasilábicos y pentadecasilábicos. *Las tres del catálogo son las del corpus, no
   las de la bibliografía.*

3. **¿La consonancia es exigible?** Hoy es definitoria en las tres arquitecturas. Navarro Tomás
   documenta en el modernismo el sexteto asonante `abcbDB` de Darío y tipos que dejan sueltos varios
   versos. *En el corpus áureo la consonancia es la norma; conviene confirmar que ninguna secuencia
   obligue a relajarla.*

4. **Sigue sin sitio la variedad de los *Nocturnos de San Pedro*.** Navarro Tomás describe una
   combinación de endecha real y sexteto con un pie quebrado que repite en eco la rima del segundo
   heptasílabo. Se buscó expresamente al revisar el sexteto y **ninguna de las seis la formaliza como
   sexteto autónomo**. *Queda como realización documentada sin hueco: o se le da forma propia, o se
   registra como desviación de la endecha real, que es la forma con la que Navarro la combina.*

5. **Se modeló para la alejandrina algo que en otras formas se dejó en las fuentes.** Se declaró el
   esquema `AABCCB` y el rasgo de finales agudos porque la descripción contaba en prosa una
   disposición que la ficha no podía dibujar. Pero el sexteto alejandrino **no está en el corpus**, y
   en otras formas lo documentado y no anotado se quedó en la afirmación. *La inconsistencia es real:
   o el catálogo modela lo que las fuentes describen aunque el corpus no lo traiga —y entonces faltan
   cosas en otras formas—, o modela solo lo anotable, y entonces esta declaración sobra.* ⇒ **C11**

## Octava real

1. **¿Una estrofa o dos?** Caparrós 2014 remite a la discusión de Lázaro Carreter sobre si la octava
   real es una estrofa o la unión de dos, y el *Diccionario* observa que suele subdividirse en dos
   grupos de cuatro versos según el contenido. *El catálogo ha tomado partido sin escribirlo: al no
   declarar secciones afirma que es una unidad de ocho. Si se declararan, habría que decidir si el
   corte es 6 + 2 —el pareado final— o 4 + 4.*

2. **Un solo esquema catalogado, y la sospecha de que hay más.** La arquitectura declara
   `ABABABCC` como **habitual** y, aparte, una «Distribución variable» **excepcional** sin notación,
   que es la salida abierta. *Las fuentes describen «tres clases de rima en ocho versos, con pareado
   final» y dicen que el orden de los seis primeros varía: si esas variantes están documentadas una
   a una, son esquemas que faltan; si no, el repertorio está bien y lo que hay es una norma abierta.*
   ⇒ [Las que cruzan formas](#las-que-cruzan-formas)

## Copla de arte mayor

1. **¿Los cuatro esquemas son ahora un repertorio cerrado?** Los cuatro actuales —`ABBA:ACCA`
   habitual, `ABAB:BCCB` y `ABBA:ACAC` admitidas y `ABBA:CDDC` excepcional— enlazan los cuartetos,
   que es lo que la norma exige, y una guarda impide declarar uno con más de tres clases. *La
   pregunta es si faltan otros enlazados que las fuentes no destaquen.*

2. **¿Se admite la copla de cuatro rimas como desviación?** Navarro Tomás registra una,
   `ABBA:CDDC`, en una carta de Tirso de Molina en *Quien calla otorga* —y anota que los propios
   personajes aluden al carácter antiguo de la estrofa—. Es exactamente lo que el catálogo retiró
   como esquema normal. *Si el corpus trae una, habría que registrarla como desviación localizada.*

3. **¿La arquitectura debe seguir llamándose dodecasilábica?** Hoy declara `12-repetido` en sus ocho
   posiciones. Jauralde advierte que, por la estructura rítmica del verso, **su número de sílabas
   varía entre diez y dieciséis**. *Si el corpus trae un verso de trece o catorce, hoy sería una
   desviación métrica y no una realización admitida.*

## Soneto

1. **¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?** M&B dan los cuatro y
   añaden «y otros». **Es abierto, y la fuente da la regla, no una lista**: el *Diccionario* dice
   que los tercetos toman dos o tres clases distintas de las de los cuartetos y las reparten como
   sea «con tal de que no haya más de dos versos seguidos con la misma rima». Desde el 19 de agosto
   esa regla está en la definición. *Codificarla son dos piezas: un esquema abierto de la sección
   `terceto` con `max_consecutivos: 2` junto a los cuatro concretos, y la evaluación de ese tipo en
   el auditor. El grupo pasaría de cuatro opciones a cinco, y esa quinta es justo la salida que esta
   duda pide.* ⇒ **C3**

2. **¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?** Quilis describe el
   estrambote como uno o varios tercetos añadidos, con la condición de que el verso que sigue al
   decimocuarto sea un **heptasílabo que rime con él** —`ABBA ABBA CDE CDE eFF`—, y lo ejemplifica
   con el «Voto a Dios que me espanta esta grandeza» de Cervantes. *Es el más probable de los dos en
   un corpus áureo, y hoy no cabe: un soneto de diecisiete versos no encaja en la arquitectura.*

---

# Estrofas compuestas de arte menor

## Copla real

1. **La frecuencia de una disposición reutilizada no es la de la posición que ocupa.** Las dos
   quintillas reutilizan la arquitectura de la quintilla, así que traen sus esquemas **con la
   frecuencia que tienen como quintilla suelta**: `aabba` sale «admitida» en la segunda mitad, donde
   M&B dicen que en Lope es *siempre* esa. *El IP decidió el 20 de agosto decirlo en prosa y no
   tocar el modelo por ahora.* ⇒ **C1**

2. **La copla real de cuatro y seis versos.** Jauralde advierte que «la forma 4-6 precede a la 5-5,
   que solo se hace mayoritaria a finales del siglo XV»; Navarro Tomás describe el mismo proceso
   desde el modelo 4-4. El catálogo solo tiene 5+5. ⇒ **C11**

3. **¿Los quebrados pueden ocupar cualquiera de las diez posiciones?** Hoy la pregunta las ofrece
   las diez. Ninguna fuente fija dónde caen. *Si se restringe, hay que decir a qué posiciones.*

4. **¿Solo tetrasílabos, o también pentasílabos?** Las seis fuentes, al hablar de la copla real,
   **solo nombran el tetrasílabo**. La arquitectura declara los dos como `quebrado`. *Si se decide
   que solo vale el tetrasílabo, lo que se retira es esa fila y la pregunta se estrecha sola.*

5. **¿Debe restringirse el par de quintillas?** Hoy las dos preguntas ofrecen los ocho esquemas con
   total independencia. M&B, que describen a Lope, afirman que **las dos quintillas son de tipo
   diferente**: la segunda siempre `AABBA` y la primera casi siempre `ABABA`. *No se ha restringido
   porque las otras cinco fuentes describen libertad y el catálogo cubre más que a Lope. Si se
   restringe, pasa a ser una restricción entre dos preguntas, que el modelo hoy no sabe expresar.*
   ⇒ **C1**

6. **Pedir datos al editor de *El caballero de Olmedo*.** Es de las poquísimas formas con uso real
   —tres secuencias, todas en esa obra— y las anotaciones vienen del vocabulario legado, sin decir
   qué disposición tiene cada quintilla ni dónde caen los quiebros. *Al revisar la obra conviene
   pedírselo: es el único sitio donde el corpus puede contrastar lo que las fuentes dicen del
   emparejamiento.*

## Novena

1. **Separar la Novena general de la Copla novena.** Caparrós y el *Diccionario* llaman novena a
   cualquier estrofa de nueve versos y niegan que comparta necesariamente otra norma, mientras
   Navarro Tomás y Jauralde caracterizan la copla novena histórica como redondilla y quintilla. *Las
   dos arquitecturas actuales pasarían a la Copla novena. Falta decidir cómo se registra la Novena
   general sin que el demarcador clasifique por defecto cualquier pasaje de nueve versos*, que es el
   mismo problema que hizo retirar la copla de pie quebrado.

2. **¿Cómo se representan las realizaciones tempranas en que redondilla y quintilla comparten una o
   dos clases de rima**, frente a las posteriores con rimas independientes? *Hoy las dos secciones
   reutilizan repertorios independientes y no hay manera de declarar que comparten timbre.* ⇒ **C1**

3. **¿Las ocho variedades de quintilla valen todas para la Copla novena** o deben restringirse según
   la documentación histórica? *Hoy se ofrecen las ocho, por reutilización.*

## Décima

1. **¿Entra la décima asonante?** Quedó fuera el 22 de agosto de 2026 al aplicar el criterio de qué
   compromete la norma: es un **régimen nuevo**, ninguna fuente lo registra con nombre ni
   definición, y Jauralde lo presenta como ensayo de Jorge Guillén «al rimarlas en asonante en vez
   de en consonante, **que era lo tradicional**». *Si el IP prefiere admitirla, la décima pasaría a
   declarar dos regímenes, como la silva desde ese mismo día.* Las cuatro medidas que faltaban
   —penta, hexa, hepta y endecasílaba— sí entraron: la hexasílaba la firma **Góngora**.

2. **¿Debe poder intercalarse alguna otra forma, además de la décima aumentada?** El editor ya sabe
   anotar una aumentada entre décimas normales: desde el 26 de agosto de 2026 una arquitectura puede
   declararse `intercalable` y una unidad suelta puede adoptarla, sin registrarla como desviación,
   porque no lo es. *Se abrió **solo para la décima**, por decisión del IP: si otras formas lo
   necesitan se abrirán cuando alguien lo pida, para no complicar el editor —ni exponer a error a
   los editores— en las cuarenta que no lo necesitan.* La duda queda anotada por si el IP conoce ya
   algún caso: **una realización de otra forma que aparezca dentro de una tirada sin romperla**.

   *Hay además un caso vecino que hoy no cabe y que el IP dejó explícitamente para el futuro:* que
   lo intercalado sea de **otra forma**, como un pareado cerrando una tirada alirada. Hoy el
   disparador exige que la arquitectura declarada sea de la misma forma que la secuencia.

3. **¿El linaje debe limitarse a copla real, espinela y aumentada?** Es la única relación histórica
   declarada. *Ampliarlo obligaría a decidir qué otras formas de diez versos entran.*

4. **¿«Décima aumentada» es el nombre adecuado para la arquitectura de doce versos?** *El nombre
   describe bien lo que es, pero llamar «décima» a una estrofa de doce puede leerse mal en la
   ficha.*

5. **¿La definición debe seguir describiéndola como «dos redondillas abrazadas y dos versos de
   enlace»?** M&B la explican de otro modo: como combinación de **dos quintillas**, la 6.ª y la 5.ª,
   aunque advierten que lo característico es la pausa tras el cuarto verso. *Son dos lecturas de la
   misma estrofa y la definición ya elige una; la duda es si conviene que la otra conste, porque es
   la de la fuente del corpus dramático.*

---

# Series estróficas breves

## Seguidilla

1. **La fluctuación histórica de la simple no tiene representación.** Cuatro de las seis fuentes la
   documentan —M&B advierten que «el ritmo pesa más que el cómputo»—, pero el catálogo declara
   `7-5-7-5` fijo. *Hoy una seguidilla de medidas fluctuantes solo cabe como desviación métrica
   verso a verso.*

2. **La seguidilla arromanzada comparte asonancia entre unidades y eso no se declara.** El
   *Diccionario* y Jauralde documentan series en que una misma asonancia recorre varias estrofas.
   *Es el mismo mecanismo que el romance ya resuelve con su ciclo, y que desde el 22 de agosto usan
   las tres enlazadas.*

3. **¿Las realizaciones consonantes recurrentes son opciones admitidas o desviaciones?** Caparrós
   2014 recoge consonancia y rima de los impares como variantes atestiguadas. *Hoy la asonancia es
   definitoria, así que una seguidilla consonante es desviación.*

## Romance

*Sin cuestiones abiertas. Las dos medidas que faltaban —pentasílaba y tetrasílaba— entraron el 22
de agosto de 2026, con el criterio de que la medida no compromete la norma.*

## Endecha real

1. **El disparador de posiciones toma la caja por clase de rima.**
   `sincronizar_posiciones_esquema_rima_fijo` deriva las posiciones letra a letra, y de `-a-A` saca
   las clases `a` y `A` como si fueran dos rimas distintas. Pero **la caja dice el arte del verso**,
   no con quién rima: la lira escribe `aBabB` y son dos rimas, no cuatro. En la endecha real hubo
   que corregir la clase a mano. **No es un problema de esta forma**: cualquier rima futura entre un
   verso de arte menor y otro de arte mayor caerá en lo mismo. *Arreglarlo es comparar en minúsculas
   dentro del disparador, pero antes hay que comprobar si alguna forma poblada depende de la
   conducta actual.*

2. **Las dos arquitecturas de sor Juana están fuera del teatro áureo.** La de cinco versos
   (`7-7-7-7-11`, `abbaA`) y la hexasílaba (`6-6-6-11`) se declaran porque Navarro Tomás y Jauralde
   las documentan, pero los dos las atribuyen a sor Juana y a la poesía culta del XVII-XVIII, no al
   teatro. **Ninguna fuente dice que no aparezcan en teatro**; simplemente no lo tratan. ⇒ **C11**

3. **Faltan dos cosas que Navarro Tomás documenta y no tienen dónde ir.** Sor Juana hizo también el
   último verso **decasílabo de dos adónicos**, y en los *Nocturnos de San Pedro* combina endecha
   real y sexteto con un pie quebrado en eco. *Las dos están registradas como afirmación; la segunda
   se buscó sitio en el sexteto y no lo tiene —ver [Sexteto](#sexteto) 4—.*

4. **¿Es endecha real la que no rima?** Las fuentes se contradicen. Navarro Tomás § 207 dice que
   Bermúdez y Cervantes la emplearon **en versos sueltos**, `abcD`, y el *Diccionario* lo admite.
   Jauralde § 3.6 dice lo contrario: el cuarteto se usó suelto, sí, pero «**se denominó endecha real
   cuando recibió rimas**», de modo que sin rima sería una cuarteta de heptasílabos. Es un
   desacuerdo entre fuentes autorizadas, no un descuido. *Hoy la `suelta` está como `admitida`.
   Según se resuelva, se queda, baja a `excepcional` o sale de la forma.* Su esquema es además un
   ciclo `[----]…` con cero posiciones ⇒ **C2**

---

# Los dos tramos sin forma

1. **El quebrado no es versificación irregular, y conviene vigilarlo al anotar.** El *Diccionario*
   lo advierte expresamente y Caparrós 2014 lo confirma al incluir la proporcionalidad en la
   definición de lo regular. Un pasaje 8-8-4 pertenece a la copla o a la sextilla de pie quebrado,
   no a este tramo. La definición ya lo dice. *Merece comprobarse contra las anotaciones existentes
   cuando se haga el informe de migración.*

2. **Jauralde llama a esto de otra manera y no se ha seguido.** Prefiere «verso libre o liberado»
   para el conjunto que no busca ninguna proporción aparente, y reserva «irregular» para otro caso.
   *El catálogo conserva «Versificación irregular» por ser el término de las otras fuentes y del
   vocabulario legado; queda registrada la divergencia.*

3. **Revisar las equivalencias de los tramos irregulares antes de migrarlos.** El vocabulario legado
   distingue tres —`irregular_arte_mayor`, `irregular_arte_menor` e `irregular_mixto`— y son de lo
   más anotado que hay: **nueve secuencias, 313 versos**. El catálogo nuevo tiene una sola entrada.
   *Es posible que alguna se anotara como irregular solo porque quien la anotó no encontró la forma
   precisa, y que con el catálogo nuevo y el demarcador sí aparezca.* ⇒ **A4**

3. **Una sola arquitectura reúne tres regímenes de rima.** La heptasilábica con endecasílabo final
   admite disposiciones **asonantes** —abrazada, cruzada y la sostenida en los cuartos—, una
   **consonante** —cruzada— y los **versos sueltos**. Es la única arquitectura activa del catálogo con
   tres. *¿Es una forma que se realiza de tres maneras, o hay ahí más de una forma? De la respuesta
   depende si la asonancia se puede preguntar siempre, como se pregunta hoy, o solo cuando la
   disposición elegida sea asonante.*
