# La auditoría de las fuentes · septiembre de 2026

> **Archivado el 16 de septiembre de 2026, al terminar.** Este es el registro de qué se hizo, cómo
> y qué salió. No describe ningún estado: lo que la auditoría dejó por hacer está en
> [PENDIENTES](../../PENDIENTES.md), bloque E, y el método, por si hay que repetirlo, en
> [el plan](../plan-auditoria-fuentes.md) y en las cuatro instrucciones de verificador de
> [auditoria-fuentes/](../auditoria-fuentes/).

## Qué se auditó

Las **267 afirmaciones** de «Lo que dicen las fuentes» del catálogo métrico, una por cada cosa que
una de las seis monografías dice de una forma. La pregunta no era si la forma está bien descrita
—eso lo había mirado la revisión de agosto— sino otra, más estrecha y más comprobable: **si cada
afirmación dice lo que su libro dice, y si está donde declara estar.**

Terminó con **las 267 resueltas: 149 corregidas y 118 sin nada que corregir**, en **57 migraciones**.

## Cómo se miró

Cuatro pasadas de lectura, cada una ciega respecto de las anteriores, y cada una hecha para
descubrir un tipo de defecto distinto:

| | qué ve | qué encuentra |
| --- | --- | --- |
| **A** | la afirmación y su localizador, juntos | que la ficha endurezca o ablande lo que la fuente dice |
| **B** | el pasaje sin la ficha | lo que la fuente dice y la ficha calló |
| **C** | la afirmación sin el localizador | localizadores equivocados, epígrafes que no existen |
| **D** | la afirmación descompuesta en cláusulas | lo que se cuela dentro de una frase por lo demás cierta |

Y cuatro comprobaciones mecánicas sobre el catálogo entero: la resolución de los localizadores de
nivel 0 y 1, los esquemas huérfanos, las tiradas de seis palabras compartidas —que delatan el
copiar-pegar— y la señal de endurecimiento.

Aparte, la **fase 4** miró lo que las pasadas no pueden mirar: **lo que no está escrito**. Un
tablero de forma × fuente, 264 celdas, y cada celda vacía abierta en el libro. Terminó sin ninguna
vacía, y una guarda lo exige.

## Qué salió

**El defecto más repetido no es un error de lectura: es una frase nuestra puesta en boca del
libro.** «Su corpus es Lope, posterior al de los entremeses», «la silva dramática nace, por tanto,
de…», «Es la única fuente que la describe». No aparece por descuido sino por la forma del campo: el
sitio donde se explica qué dice una fuente es también el sitio más cómodo para explicar por qué el
catálogo decidió lo que decidió.

Lo demás, por familias: localizadores sin la página impresa o con la equivocada; epígrafes que no
existen en el libro; glosas que el libro no enuncia; y afirmaciones repartidas entre dos lugares de
la fuente sin decirlo.

**La fase 4 dejó además una forma nueva.** La **estrofa sáfica** no estaba en el catálogo y cinco de
las seis fuentes la documentan; Navarro Tomás le da sección propia en los seis períodos que recorre.
Entró con dos arquitecturas y sus cinco afirmaciones. Con ella, y con las dos liras que dejaron de
estar mudas, **ninguna forma activa se queda sin fuente**.

**Y una lección sobre el silencio.** Veintidós celdas vacías, en siete razones, y **seis de las
siete son citables**: lo que parecía ausencia era una frontera que cada libro declara. La primera
redacción decía de todas lo mismo —«no la registra»— y era falsa por omisión. La única razón
puramente negativa son las cuatro celdas de Morley y Bruerton en formas que le son ajenas, y ahí el
motivo también es del libro: su repertorio es el de las formas que Lope usa.

## Lo que enseñó el método, que vale para la próxima

**Una guarda encuentra lo que nadie pensó en buscar.** Pasó cinco veces. La escrita para exigir que
la sigla `AB-DE-CF` no quedara en ninguna ficha falló señalando una segunda —y ahí era correcta,
porque es notación de Quilis—: la sigla no se había inventado, **se había copiado de una ficha a
otra**, y es la primera vez que el copiar-pegar apareció con donante identificado. La escrita para
comprobar que «Es la única fuente que la describe» había salido de una ficha encontró otras dos,
fuera del cubo y dadas por corregidas, que ninguna pasada habría vuelto a mirar. Y así tres veces
más. **Por eso las guardas ejecutan lo que tocan en vez de comprobar el dato.**

**Un verificador puede citar mal nuestro catálogo, no la fuente.** Una afirmación quedó atascada con
dos dictámenes de la pasada A contradictorios: uno la acusaba de endurecimiento grave citándola como
«Establece como únicas distribuciones posibles», y la ficha decía «Da como distribuciones más
frecuentes» desde un mes antes de la auditoría. Es un modo de fallo que no estaba previsto: toda la
arquitectura contrasta la fuente contra la ficha **dando por supuesto que la ficha al menos se lee
bien**. Quedó acotado —solo 3 de las 267 recibieron dos dictámenes A, solo esa los tuvo discordes, y
ninguna de las 118 limpias tiene una cita de A que no case con su ficha—, y el procedimiento lo paró
solo, dejándola aparcada en vez de migrada. De ahí que **la pasada D exija un eco literal de la
ficha** antes de emitir nada.

**Los extractos envejecen sin avisar.** Se generaron el 11 de septiembre y no se regeneraron en
cinco días y cincuenta migraciones: durante ese tiempo **todas las comprobaciones mecánicas
estuvieron juzgando pasajes que el catálogo ya no declaraba**. Al regenerarlos volvieron diez
afirmaciones al alcance mecánico y aparecieron diez candidatos nuevos.

**El contador de menciones cuenta denominaciones, no formas.** Si una fuente llama a una forma por
un nombre que el catálogo no tiene registrado, el contador da cero y la celda pasa por silencio.
Ocurrió tres veces: el guion de «cuarteto lira», el nombre propio de «Novena-lira» —que es nuestro y
de nadie más— y los «octetos-lira» con que Jauralde nombra la octava-lira.

**Las entradas del *Diccionario* con sentidos numerados.** Cuando una entrada tiene varias
acepciones, la ficha se quedaba con la primera: «serventesio 2 → cuarteta», «sextilla 2 → sexteto»,
«verso libre, 2», y la sextina. Cuatro de cuatro. Es una regla, no una casualidad.

**El volcado de Navarro Tomás lee la `c` como `e` en las cadenas de esquema.** En la p. 133 imprime
«cuyo modelo, *abe:abe*», que es `abc:abc`. De ahí salen `abeabeddedde` o `abeabedefdef`. Cualquier
lista de esquemas sacada de ese volcado **no es una lista de trabajo**: hay que abrir el libro.

**Una comprobación que convendría escribir.** El epígrafe «Formas mixtas en cuartetos y septetos» no
existe en Jauralde, y no lo vio ninguna pasada: salió de cotejar sus cincuenta localizadores contra
los 214 encabezados reales del epub. Eso no está escrito como script.

## Un aviso sobre el repositorio

El informe de la fase 4 —[fase-4-exhaustividad.md](../auditoria-fuentes/fase-4-exhaustividad.md)—
**cita pasajes de los seis libros**, y está en la historia del repositorio. El resto del material de
trabajo —extractos, lotes, dictámenes— se dejó fuera precisamente por eso. Si ese informe tampoco
debe estar, hay que sacarlo y dejarlo local.
