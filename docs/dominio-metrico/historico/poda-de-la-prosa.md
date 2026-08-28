# Poda de la prosa del catálogo

Generado del catálogo el 13 de agosto de 2026. Repasa la prosa de **los niveles bajos**: la que
acompaña a cada esquema, posición, enlace, sección, rasgo, variedad, repetición y relación.

**Fuera de la poda**, y por decisión del IP: `formas_metricas.definicion` y
`arquitecturas_forma.descripcion`. Esas dos sitúan la forma y no repiten un dato menudo: son
la prosa que la ficha necesita para presentar aquello de lo que luego enseña las piezas.


> Este archivo enseña únicamente **decisiones pendientes**. Las entradas aprobadas ya están
> aplicadas mediante migraciones; cuando una prosa se conserva aunque la heurística la señale,
> la decisión expresa queda registrada en el generador para que no vuelva a abrirse.

Una frase se marca cuando lo que dice **ya está en un dato estructurado**: la figura, la
denominación del propio esquema, la modalidad, el régimen de rima declarado, la extensión o la
ficha de otra forma. Cada marca lleva su razón entre paréntesis para poder discutirla, porque
la razón es lo que se aprueba o se rechaza: si el dato no lo dice, la frase se queda.

Cada texto lleva una de estas dos propuestas:

- **Quitar entero** — todas sus frases repiten un dato. El campo quedaría vacío.
- **Acortar** — una parte dice algo que no está en ningún otro sitio, y esa se conserva.

Dentro de cada texto, `—` es la frase que sobra y `+` la que se queda.

| Campo | Quitar entero | Acortar | Sin tocar |
|---|---|---|---|
| `esquemas_metricos.nombre` | 0 | 0 | 19 |
| `esquemas_metricos.descripcion` | 0 | 0 | 3 |
| `esquema_metrico_posiciones.nota` | 0 | 0 | 4 |
| `esquemas_rima.descripcion` | 20 | 17 | 28 |
| `esquema_rima_posiciones.nota` | 2 | 0 | 13 |
| `esquema_rima_enlaces.nota` | 1 | 0 | 3 |
| `esquema_rima_restricciones.descripcion` | 0 | 0 | 1 |
| `estructuras_secciones.nota` | 2 | 11 | 16 |
| `variedades_arquitectura.descripcion` | 1 | 0 | 0 |
| `repeticiones_metricas.descripcion` | 0 | 0 | 5 |
| `arquitectura_rasgos.nota` | 5 | 10 | 29 |
| `forma_relaciones.nota` | 34 | 12 | 13 |

**143 frases de 356.** 65 textos se quitarían enteros, 50 se acortarían y 134 no se tocan.

## esquemas_rima.descripcion

37 de 65 textos, 40 de 99 frases.

**quintilla/heptasilabica** · `abbba` — **acortar**

Dice: «Ninguna otra disposición repite la misma rima en tres versos seguidos. Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.»

- Ninguna otra disposición repite la misma rima en tres versos seguidos.
- ~~Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.~~ _(lo dice la modalidad)_

**Quedaría:** «Ninguna otra disposición repite la misma rima en tres versos seguidos.»

**quintilla/hexasilabica** · `abbba` — **acortar**

Dice: «Ninguna otra disposición repite la misma rima en tres versos seguidos. Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.»

- Ninguna otra disposición repite la misma rima en tres versos seguidos.
- ~~Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.~~ _(lo dice la modalidad)_

**Quedaría:** «Ninguna otra disposición repite la misma rima en tres versos seguidos.»

**decima_lira/heterometrica_consonante** · `ababcdcdee` — **acortar**

Dice: «Dos parejas de rima cruzada y un pareado final. En el testimonio que la documenta los heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo testimonio y no basta para fijar esa alternancia como norma. Repite la cabeza como lo haría una fronte y no trae eslabón, que es lo que la deja del lado alirado.»

- ~~Dos parejas de rima cruzada y un pareado final.~~ _(lo dibuja la figura)_
- En el testimonio que la documenta los heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo testimonio y no basta para fijar esa alternancia como norma.
- Repite la cabeza como lo haría una fronte y no trae eslabón, que es lo que la deja del lado alirado.

**Quedaría:** «En el testimonio que la documenta los heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo testimonio y no basta para fijar esa alternancia como norma. Repite la cabeza como lo haría una fronte y no trae eslabón, que es lo que la deja del lado alirado.»

**septilla/octosilabica** · `abbacca` — **acortar**

Dice: «El terceto estrena una clase en sus dos primeros versos y cierra con la que abrió la redondilla. Es la que dan Villasandino y el *Planto de la reina doña Margarita* de Santillana, y la que las fuentes citan como esquema de la forma.»

- ~~El terceto estrena una clase en sus dos primeros versos y cierra con la que abrió la redondilla.~~ _(habla de otra forma («terceto»))_
- Es la que dan Villasandino y el *Planto de la reina doña Margarita* de Santillana, y la que las fuentes citan como esquema de la forma.

**Quedaría:** «Es la que dan Villasandino y el *Planto de la reina doña Margarita* de Santillana, y la que las fuentes citan como esquema de la forma.»

**septilla/octosilabica** · `abbaccb` — **quitar entero**

Dice: «El terceto cierra con la rima interior de la redondilla en vez de con la exterior.»

- ~~El terceto cierra con la rima interior de la redondilla en vez de con la exterior.~~ _(habla de otra forma («terceto»))_

**septilla/octosilabica** · `ababcbc` — **quitar entero**

Dice: «La redondilla va cruzada y el terceto alterna una clase nueva con la rima que trae.»

- ~~La redondilla va cruzada y el terceto alterna una clase nueva con la rima que trae.~~ _(habla de otra forma («terceto»))_

**septilla/octosilabica** · `abababb` — **quitar entero**

Dice: «La otra del Arcipreste: el terceto no estrena ninguna clase y se hace entero con las dos de la redondilla, de modo que la estrofa se sostiene sobre dos rimas.»

- ~~La otra del Arcipreste: el terceto no estrena ninguna clase y se hace entero con las dos de la redondilla, de modo que la estrofa se sostiene sobre dos rimas.~~ _(habla de otra forma («terceto»))_

**decima/endecasilabica** · `abbaaccddc` — **quitar entero**

Dice: «La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.»

- ~~La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.~~ _(habla de otra forma («redondilla»))_

**decima/heptasilabica** · `abbaaccddc` — **quitar entero**

Dice: «La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.»

- ~~La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.~~ _(habla de otra forma («redondilla»))_

**decima/hexasilabica** · `abbaaccddc` — **quitar entero**

Dice: «La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.»

- ~~La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.~~ _(habla de otra forma («redondilla»))_

**decima/pentasilabica** · `abbaaccddc` — **quitar entero**

Dice: «La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.»

- ~~La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.~~ _(habla de otra forma («redondilla»))_

**septeto/compuesta** · `distribucion-variable` — **acortar**

Dice: «Cada miembro trae la disposición de la forma que lo realiza. Lo que la norma deja abierto es si el terceto recoge alguna rima del cuarteto o estrena las suyas.»

- Cada miembro trae la disposición de la forma que lo realiza.
- ~~Lo que la norma deja abierto es si el terceto recoge alguna rima del cuarteto o estrena las suyas.~~ _(habla de otra forma («cuarteto»))_

**Quedaría:** «Cada miembro trae la disposición de la forma que lo realiza.»

**silva/arromanzada** · `asonancia-pares` — **acortar**

Dice: «Los pares comparten una misma asonancia de principio a fin de la serie; los impares quedan sueltos. Es lo único que la norma fija de su rima.»

- ~~Los pares comparten una misma asonancia de principio a fin de la serie; los impares quedan sueltos.~~ _(lo dibuja la figura)_
- Es lo único que la norma fija de su rima.

**Quedaría:** «Es lo único que la norma fija de su rima.»

**novena_lira/heterometrica_consonante** · `distribucion-variable` — **acortar**

Dice: «La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las rimas. No es que el catálogo no lo sepa todavía: es que de esta forma no hay ninguna disposición documentada, y declarar una sería inventarla.»

- La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las rimas.
- ~~No es que el catálogo no lo sepa todavía: es que de esta forma no hay ninguna disposición documentada, y declarar una sería inventarla.~~ _(lo dice la modalidad)_

**Quedaría:** «La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las rimas.»

**septeto_lira/heterometrica_consonante** · `ababbcc` — **acortar**

Dice: «Los cuatro primeros versos alternan dos clases, el quinto recoge la segunda y los dos últimos forman un pareado. Es la que documenta el ejemplo de fray Luis; la tradición reconoce otras que no enumera.»

- ~~Los cuatro primeros versos alternan dos clases, el quinto recoge la segunda y los dos últimos forman un pareado.~~ _(lo dibuja la figura)_
- Es la que documenta el ejemplo de fray Luis; la tradición reconoce otras que no enumera.

**Quedaría:** «Es la que documenta el ejemplo de fray Luis; la tradición reconoce otras que no enumera.»

**redondilla_enlazada/octosilabica_con_quebrado** · `enlazada` — **acortar**

Dice: «Dentro de la estrofa solo riman entre sí el segundo verso y el tercero. La primera clase y la cuarta no quedan sueltas: la primera recoge la que abrió el quebrado de la estrofa anterior, y la cuarta la pasa a la siguiente.»

- ~~Dentro de la estrofa solo riman entre sí el segundo verso y el tercero.~~ _(lo dibuja la figura)_
- La primera clase y la cuarta no quedan sueltas: la primera recoge la que abrió el quebrado de la estrofa anterior, y la cuarta la pasa a la siguiente.

**Quedaría:** «La primera clase y la cuarta no quedan sueltas: la primera recoge la que abrió el quebrado de la estrofa anterior, y la cuarta la pasa a la siguiente.»

**pareado/alirado** · `aa` — **acortar**

Dice: «Los dos versos riman entre sí en consonante. Es lo que hace pareado al pareado.»

- ~~Los dos versos riman entre sí en consonante.~~ _(lo dibuja la figura)_
- Es lo que hace pareado al pareado.

**Quedaría:** «Es lo que hace pareado al pareado.»

**quintilla/octosilabica_consonante** · `distribucion-variable` — **quitar entero**

Dice: «El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite. Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.»

- ~~El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite.~~ _(habla de otra forma («verso suelto»))_
- ~~Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.~~ _(lo dice la modalidad)_

**quintilla/heptasilabica** · `distribucion-variable` — **quitar entero**

Dice: «El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite. Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.»

- ~~El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite.~~ _(habla de otra forma («verso suelto»))_
- ~~Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.~~ _(lo dice la modalidad)_

**quintilla/hexasilabica** · `distribucion-variable` — **quitar entero**

Dice: «El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite. Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.»

- ~~El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la enumeración clásica: la recoge entera y admite además las disposiciones que acaban en pareado, que Díaz Rengifo omite.~~ _(habla de otra forma («verso suelto»))_
- ~~Deja fuera `abbba`, que ninguna fuente numera y que el catálogo registra como excepcional.~~ _(lo dice la modalidad)_

**octava_real/endecasilabica_consonante** · `distribucion-variable` — **quitar entero**

Dice: «La rima admite otro orden, sobre todo en los seis primeros versos, aunque es poco frecuente.»

- ~~La rima admite otro orden, sobre todo en los seis primeros versos, aunque es poco frecuente.~~ _(lo dice la modalidad)_

**quintilla/octosilabica_consonante** · `abbba` — **acortar**

Dice: «Ninguna otra disposición repite la misma rima en tres versos seguidos. Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.»

- Ninguna otra disposición repite la misma rima en tres versos seguidos.
- ~~Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.~~ _(lo dice la modalidad)_

**Quedaría:** «Ninguna otra disposición repite la misma rima en tres versos seguidos.»

**decima/espinela** · `abbaaccddc` — **quitar entero**

Dice: «La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.»

- ~~La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.~~ _(habla de otra forma («redondilla»))_

**terceto/endecasilabica_consonante** · `primer-verso-suelto` — **quitar entero**

Dice: «El verso suelto es el primero.»

- ~~El verso suelto es el primero.~~ _(lo dibuja la figura)_

**terceto/endecasilabica_consonante** · `verso-central-suelto` — **quitar entero**

Dice: «El verso suelto es el central.»

- ~~El verso suelto es el central.~~ _(habla de otra forma («verso suelto»))_

**copla_de_arte_mayor/dodecasilabica_compuesta** · `abbacddc` — **quitar entero**

Dice: «La única documentada en el teatro: cuatro rimas en vez de tres, en una carta de *Quien calla otorga*, de Tirso de Molina.»

- ~~La única documentada en el teatro: cuatro rimas en vez de tres, en una carta de *Quien calla otorga*, de Tirso de Molina.~~ _(lo dice la modalidad)_

**septilla_enlazada/octosilabica_con_quebrado** · `enlazada` — **acortar**

Dice: «La primera clase aparece una sola vez y no queda suelta: es la rima con que terminó la estrofa anterior. La segunda vuelve cuatro veces —el quebrado y tres versos de la quintilla— y es la que sostiene la estrofa; la tercera cierra, y es la que se pasa a la siguiente.»

- La primera clase aparece una sola vez y no queda suelta: es la rima con que terminó la estrofa anterior.
- ~~La segunda vuelve cuatro veces —el quebrado y tres versos de la quintilla— y es la que sostiene la estrofa; la tercera cierra, y es la que se pasa a la siguiente.~~ _(habla de otra forma («quintilla»))_

**Quedaría:** «La primera clase aparece una sola vez y no queda suelta: es la rima con que terminó la estrofa anterior.»

**cuarteto_lira/heterometrica_consonante** · `abab` — **quitar entero**

Dice: «Rima el primero con el tercero y el segundo con el cuarto.»

- ~~Rima el primero con el tercero y el segundo con el cuarto.~~ _(lo dibuja la figura)_

**cuarteto_lira/heterometrica_consonante** · `abba` — **quitar entero**

Dice: «Rima el primero con el cuarto y el segundo con el tercero.»

- ~~Rima el primero con el cuarto y el segundo con el tercero.~~ _(lo dibuja la figura)_

**terceto/octosilabica** · `monorrimo` — **acortar**

Dice: «Los tres versos riman entre sí. Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.»

- ~~Los tres versos riman entre sí.~~ _(lo dibuja la figura)_
- Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.

**Quedaría:** «Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.»

**copla_de_arte_menor/octosilabica** · `abbaacca` — **quitar entero**

Dice: «La que el Marqués de Santillana emplea en la *Coronación de Mosén Jordi*: la segunda redondilla no estrena sus dos clases, sino solo una.»

- ~~La que el Marqués de Santillana emplea en la *Coronación de Mosén Jordi*: la segunda redondilla no estrena sus dos clases, sino solo una.~~ _(habla de otra forma («redondilla»))_

**terceto/hexasilabica** · `monorrimo` — **acortar**

Dice: «Los tres versos riman entre sí. Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.»

- ~~Los tres versos riman entre sí.~~ _(lo dibuja la figura)_
- Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.

**Quedaría:** «Es la disposición que las fuentes destacan en arte menor, y la del trístico medieval.»

**copla_castellana/octosilabica** · `abbacddc` — **acortar**

Dice: «Las dos mitades abrazadas. Es la que Castillejo emplea en la «Canción a Nuestra Señora, viniendo en la mar» y la que Santillana quiebra en el sexto verso.»

- Las dos mitades abrazadas.
- ~~Es la que Castillejo emplea en la «Canción a Nuestra Señora, viniendo en la mar» y la que Santillana quiebra en el sexto verso.~~ _(habla de otra forma («cancion»))_

**Quedaría:** «Las dos mitades abrazadas.»

⚠ **El resto queda cojo**: decidir el texto entero, no el corte.

**copla_castellana/octosilabica** · `abbacdcd` — **quitar entero**

Dice: «Abrazada la primera, cruzada la segunda.»

- ~~Abrazada la primera, cruzada la segunda.~~ _(lo dibuja la figura)_

**copla_castellana/octosilabica** · `ababcddc` — **quitar entero**

Dice: «Cruzada la primera, abrazada la segunda.»

- ~~Cruzada la primera, abrazada la segunda.~~ _(lo dibuja la figura)_

**octava_lira/heterometrica_consonante** · `ababccdd` — **acortar**

Dice: «Cruza las dos primeras rimas y cierra con dos pareados. Es la que Navarro Tomás documenta en Fray Diego Tadeo González y en Arriaza.»

- ~~Cruza las dos primeras rimas y cierra con dos pareados.~~ _(lo dibuja la figura)_
- Es la que Navarro Tomás documenta en Fray Diego Tadeo González y en Arriaza.

**Quedaría:** «Es la que Navarro Tomás documenta en Fray Diego Tadeo González y en Arriaza.»

**octava_lira/heterometrica_consonante** · `abcabcdd` — **acortar**

Dice: «Tres rimas que se enlazan a lo largo de los seis primeros versos, y el pareado que cierra. Es la de la oda de Lista.»

- ~~Tres rimas que se enlazan a lo largo de los seis primeros versos, y el pareado que cierra.~~ _(lo dibuja la figura)_
- Es la de la oda de Lista.

**Quedaría:** «Es la de la oda de Lista.»

## esquema_rima_posiciones.nota

2 de 15 textos, 2 de 15 frases.

**septilla_enlazada/octosilabica_con_quebrado** · `enlazada pos.2` — **quitar entero**

Dice: «Quebrado: estrena la clase con que abre la quintilla.»

- ~~Quebrado: estrena la clase con que abre la quintilla.~~ _(habla de otra forma («quintilla»))_

**septilla_enlazada/octosilabica_con_quebrado** · `enlazada pos.7` — **quitar entero**

Dice: «Cierra la quintilla, y su rima abrirá la estrofa siguiente.»

- ~~Cierra la quintilla, y su rima abrirá la estrofa siguiente.~~ _(habla de otra forma («quintilla»))_

## esquema_rima_enlaces.nota

1 de 4 textos, 1 de 4 frases.

**septilla_enlazada/octosilabica_con_quebrado** · `enlazada` — **quitar entero**

Dice: «El séptimo verso cierra la quintilla, y su rima es la que recoge el primer verso de la estrofa siguiente.»

- ~~El séptimo verso cierra la quintilla, y su rima es la que recoge el primer verso de la estrofa siguiente.~~ _(habla de otra forma («quintilla»))_

## estructuras_secciones.nota

13 de 29 textos, 14 de 53 frases.

**villancico/estribillo_tras_primera_copla** · `mudanza` — **acortar**

Dice: «Es la parte más estable de la forma: una redondilla o una cuarteta. La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera. Se documentan también, excepcionalmente, mudanzas de seis versos.»

- ~~Es la parte más estable de la forma: una redondilla o una cuarteta.~~ _(habla de otra forma («redondilla»))_
- La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera.
- Se documentan también, excepcionalmente, mudanzas de seis versos.

**Quedaría:** «La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera. Se documentan también, excepcionalmente, mudanzas de seis versos.»

**septilla_enlazada/octosilabica_con_quebrado** · `enlace` — **acortar**

Dice: «Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior. En la primera estrofa de la composición, la que le da la rima es una quintilla suelta que sirve de arranque.»

- Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior.
- ~~En la primera estrofa de la composición, la que le da la rima es una quintilla suelta que sirve de arranque.~~ _(habla de otra forma («quintilla»))_

**Quedaría:** «Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior.»

**septilla_enlazada/octosilabica_con_quebrado** · `quebrado` — **quitar entero**

Dice: «El segundo verso de enlace, más breve, que estrena la clase de rima con la que abre la quintilla. Es análogo al de la sextilla enlazada.»

- ~~El segundo verso de enlace, más breve, que estrena la clase de rima con la que abre la quintilla.~~ _(habla de otra forma («quintilla»))_
- ~~Es análogo al de la sextilla enlazada.~~ _(habla de otra forma («sextilla enlazada»))_

**septilla_enlazada/octosilabica_con_quebrado** · `quintilla` — **acortar**

Dice: «La base de la estrofa, donde la sextilla enlazada tiene una redondilla. Abre con la clase del quebrado y cierra con la que pasará a la estrofa siguiente.»

- ~~La base de la estrofa, donde la sextilla enlazada tiene una redondilla.~~ _(habla de otra forma («sextilla enlazada»))_
- Abre con la clase del quebrado y cierra con la que pasará a la estrofa siguiente.

**Quedaría:** «Abre con la clase del quebrado y cierra con la que pasará a la estrofa siguiente.»

**septilla/octosilabica** · `terceto` — **acortar**

Dice: «No es un terceto independiente: al menos uno de sus tres versos recoge una rima de la redondilla, y ese enlace es lo que cierra la estrofa. Va en octosílabos, de modo que es un tercetillo.»

- ~~No es un terceto independiente: al menos uno de sus tres versos recoge una rima de la redondilla, y ese enlace es lo que cierra la estrofa.~~ _(habla de otra forma («terceto»))_
- Va en octosílabos, de modo que es un tercetillo.

**Quedaría:** «Va en octosílabos, de modo que es un tercetillo.»

**oncena/quintilla_sextilla** · `sextilla` — **acortar**

Dice: «Es el miembro que más varía. Lo corriente es que sus seis versos formen una quintilla con uno añadido; cuando se organizan en tercetos correlativos, la estrofa llega a cinco clases de rima.»

- Es el miembro que más varía.
- ~~Lo corriente es que sus seis versos formen una quintilla con uno añadido; cuando se organizan en tercetos correlativos, la estrofa llega a cinco clases de rima.~~ _(habla de otra forma («quintilla»))_

**Quedaría:** «Es el miembro que más varía.»

**oncena/sextilla_quintilla** · `sextilla` — **acortar**

Dice: «Es el miembro que más varía. Lo corriente es que sus seis versos formen una quintilla con uno añadido; cuando se organizan en tercetos correlativos, la estrofa llega a cinco clases de rima.»

- Es el miembro que más varía.
- ~~Lo corriente es que sus seis versos formen una quintilla con uno añadido; cuando se organizan en tercetos correlativos, la estrofa llega a cinco clases de rima.~~ _(habla de otra forma («quintilla»))_

**Quedaría:** «Es el miembro que más varía.»

**villancico/estribillo_inicial** · `mudanza` — **acortar**

Dice: «Es la parte más estable de la forma: una redondilla o una cuarteta. La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera. Se documentan también, excepcionalmente, mudanzas de seis versos.»

- ~~Es la parte más estable de la forma: una redondilla o una cuarteta.~~ _(habla de otra forma («redondilla»))_
- La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera.
- Se documentan también, excepcionalmente, mudanzas de seis versos.

**Quedaría:** «La tradición cuenta aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una sola parte de cuatro porque lo que se mantiene es la estrofa entera. Se documentan también, excepcionalmente, mudanzas de seis versos.»

**cancion_petrarquista/estancias_consonantes_variables** · `segundo_pie` — **acortar**

Dice: «Repite la medida y la disposición del primero. Es lo que hace estancia a la estancia.»

- ~~Repite la medida y la disposición del primero.~~ _(lo dibuja la figura)_
- Es lo que hace estancia a la estancia.

**Quedaría:** «Es lo que hace estancia a la estancia.»

**cancion_petrarquista/estancias_consonantes_variables** · `eslabon` — **acortar**

Dice: «Verso que abre la sirima retomando la rima con que se cerró la fronte —la chiave—. Es lo que separa una estancia de una estrofa alirada, y en la tradición italiana es habitual pero no obligatorio: una canción sin él no deja de serlo, aunque este catálogo llame alirado por defecto a lo que no lo trae.»

- Verso que abre la sirima retomando la rima con que se cerró la fronte —la chiave—.
- ~~Es lo que separa una estancia de una estrofa alirada, y en la tradición italiana es habitual pero no obligatorio: una canción sin él no deja de serlo, aunque este catálogo llame alirado por defecto a lo que no lo trae.~~ _(lo dice la modalidad)_

**Quedaría:** «Verso que abre la sirima retomando la rima con que se cerró la fronte —la chiave—.»

**sextilla_enlazada/octosilabica_con_quebrado** · `enlace` — **acortar**

Dice: «Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior. En la primera estrofa de la composición, la que le da la rima es una redondilla suelta que sirve de arranque.»

- Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior.
- ~~En la primera estrofa de la composición, la que le da la rima es una redondilla suelta que sirve de arranque.~~ _(habla de otra forma («redondilla»))_

**Quedaría:** «Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior.»

**sextilla_enlazada/octosilabica_con_quebrado** · `quintilla` — **quitar entero**

Dice: «Es la quintilla con quebrado inicial que la tradición atribuye a Castillejo, aquí con el octosílabo de enlace antepuesto.»

- ~~Es la quintilla con quebrado inicial que la tradición atribuye a Castillejo, aquí con el octosílabo de enlace antepuesto.~~ _(habla de otra forma («quintilla»))_

**zejel/estribillo_y_coplas_monorrimas** · `mudanza` — **acortar**

Dice: «Tres versos monorrimos con una rima nueva en cada copla. El terceto monorrimo fue la forma primitiva del cuerpo del zéjel y siguió siendo la mayoritaria; se documenta también reducido a dos versos, aa:bba, junto a variantes que alteran el estribillo y la vuelta, como aba:cccba y abba:cccaca, y a zéjeles en arte mayor.»

- Tres versos monorrimos con una rima nueva en cada copla.
- ~~El terceto monorrimo fue la forma primitiva del cuerpo del zéjel y siguió siendo la mayoritaria; se documenta también reducido a dos versos, aa:bba, junto a variantes que alteran el estribillo y la vuelta, como aba:cccba y abba:cccaca, y a zéjeles en arte mayor.~~ _(habla de otra forma («terceto»))_

**Quedaría:** «Tres versos monorrimos con una rima nueva en cada copla.»

## variedades_arquitectura.descripcion

1 de 1 textos, 1 de 1 frases.

**sexteto_lira/heterometrica_consonante** · `a4_aBaBCC` — **quitar entero**

Dice: «Cierra con un pareado enteramente endecasílabo, sobre la misma alternancia de siete y once de las demás de su familia.»

- ~~Cierra con un pareado enteramente endecasílabo, sobre la misma alternancia de siete y once de las demás de su familia.~~ _(habla de otra forma («pareado»))_

## arquitectura_rasgos.nota

15 de 44 textos, 15 de 58 frases.

**redondilla/octosilabica** · `pie_quebrado` — **quitar entero**

Dice: «Navarro Tomás documenta la redondilla quebrada en los cancioneros del siglo XV, cruzada y abrazada, sin fijar en qué versos cae el quiebro.»

- ~~Navarro Tomás documenta la redondilla quebrada en los cancioneros del siglo XV, cruzada y abrazada, sin fijar en qué versos cae el quiebro.~~ _(habla de otra forma («cancion»))_

**septilla/octosilabica** · `pie_quebrado` — **acortar**

Dice: «El quiebro que documentan las fuentes es tetrasílabo y se documenta en el quinto verso, el primero del terceto. El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».»

- ~~El quiebro que documentan las fuentes es tetrasílabo y se documenta en el quinto verso, el primero del terceto.~~ _(habla de otra forma («terceto»))_
- El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».

**Quedaría:** «El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».»

**novena/redondilla_quintilla** · `pie_quebrado` — **acortar**

Dice: «En el orden 4+5 el quiebro abre la quintilla, que con ese orden es el quinto verso de la estrofa. Es el único caso que las fuentes documentan: Jauralde recoge de Castillejo «8a 8b 8b 8a 4c 8c 8d 8d 8c», con un solo quebrado tetrasílabo.»

- ~~En el orden 4+5 el quiebro abre la quintilla, que con ese orden es el quinto verso de la estrofa.~~ _(habla de otra forma («quintilla»))_
- Es el único caso que las fuentes documentan: Jauralde recoge de Castillejo «8a 8b 8b 8a 4c 8c 8d 8d 8c», con un solo quebrado tetrasílabo.

**Quedaría:** «Es el único caso que las fuentes documentan: Jauralde recoge de Castillejo «8a 8b 8b 8a 4c 8c 8d 8d 8c», con un solo quebrado tetrasílabo.»

**novena/quintilla_redondilla** · `pie_quebrado` — **acortar**

Dice: «En el orden 5+4 ninguna fuente documenta un ejemplo con quebrado. Por el patrón que sí se documenta —el quebrado abre la quintilla—, caería en el primer verso de la estrofa, que es donde la quintilla empieza con este orden. Sigue siendo uno solo.»

- En el orden 5+4 ninguna fuente documenta un ejemplo con quebrado.
- ~~Por el patrón que sí se documenta —el quebrado abre la quintilla—, caería en el primer verso de la estrofa, que es donde la quintilla empieza con este orden.~~ _(habla de otra forma («quintilla»))_
- Sigue siendo uno solo.

**Quedaría:** «En el orden 5+4 ninguna fuente documenta un ejemplo con quebrado. Sigue siendo uno solo.»

**sextilla_enlazada/octosilabica_con_quebrado** · `pie_quebrado` — **quitar entero**

Dice: «El segundo verso es quebrado, y es el primero de la quintilla: es la disposición que la tradición atribuye a Castillejo.»

- ~~El segundo verso es quebrado, y es el primero de la quintilla: es la disposición que la tradición atribuye a Castillejo.~~ _(habla de otra forma («quintilla»))_

**sexteto/alejandrina** · `final_acentual` — **quitar entero**

Dice: «Riman en agudo los versos tercero y sexto, que son los que cierran cada semiestrofa.»

- ~~Riman en agudo los versos tercero y sexto, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_

**octava_real/endecasilabica_consonante** · `distico_final` — **quitar entero**

Dice: «Las variantes documentadas alteran el orden de los seis primeros versos y conservan el pareado.»

- ~~Las variantes documentadas alteran el orden de los seis primeros versos y conservan el pareado.~~ _(habla de otra forma («pareado»))_

**oncena/quintilla_sextilla** · `pie_quebrado` — **acortar**

Dice: «La estrofa de once con quebrados fue más corriente que la de octosílabos plenos. En el modelo que fijó la forma caen en el octavo verso y en el undécimo, los que cierran cada terceto del miembro de seis.»

- La estrofa de once con quebrados fue más corriente que la de octosílabos plenos.
- ~~En el modelo que fijó la forma caen en el octavo verso y en el undécimo, los que cierran cada terceto del miembro de seis.~~ _(habla de otra forma («terceto»))_

**Quedaría:** «La estrofa de once con quebrados fue más corriente que la de octosílabos plenos.»

**octava_aguda/endecasilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**octava_aguda/decasilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**octava_aguda/octosilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**octava_aguda/heptasilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**octava_aguda/hexasilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**octava_aguda/pentasilabica** · `final_acentual` — **acortar**

Dice: «Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. Es lo que da nombre a la estrofa y lo único que su norma fija.»

- ~~Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa.~~ _(lo dibuja la figura)_
- Es lo que da nombre a la estrofa y lo único que su norma fija.

**Quedaría:** «Es lo que da nombre a la estrofa y lo único que su norma fija.»

**septilla_enlazada/octosilabica_con_quebrado** · `pie_quebrado` — **quitar entero**

Dice: «El segundo verso es quebrado, y es el segundo de los dos versos de enlace: los mismos que la sextilla enlazada antepone a su base.»

- ~~El segundo verso es quebrado, y es el segundo de los dos versos de enlace: los mismos que la sextilla enlazada antepone a su base.~~ _(habla de otra forma («sextilla enlazada»))_

## forma_relaciones.nota

46 de 59 textos, 70 de 97 frases.

**seguidilla** · `relacionada_con` — **acortar**

Dice: «Sor Juana Inés de la Cruz llamó real a su cuarteta de decasílabos dactílicos y hexasílabos por imitación de la endecha real, que combina versos breves con un verso largo final. El parentesco es de nombre y de procedimiento —dos medidas alternadas y una asonancia sostenida en posiciones fijas—, no de estructura: ni las medidas ni el lugar de la asonancia coinciden.»

- ~~Sor Juana Inés de la Cruz llamó real a su cuarteta de decasílabos dactílicos y hexasílabos por imitación de la endecha real, que combina versos breves con un verso largo final.~~ _(habla de otra forma («endecha real»))_
- El parentesco es de nombre y de procedimiento —dos medidas alternadas y una asonancia sostenida en posiciones fijas—, no de estructura: ni las medidas ni el lugar de la asonancia coinciden.

**Quedaría:** «El parentesco es de nombre y de procedimiento —dos medidas alternadas y una asonancia sostenida en posiciones fijas—, no de estructura: ni las medidas ni el lugar de la asonancia coinciden.»

**cancion_petrarquista** · `contrasta_con` — **acortar**

Dice: «Las dos combinan heptasílabos y endecasílabos sin medida fija por posición. La canción repite en cada estancia el patrón que fijó la primera; la silva no repite ninguno.»

- ~~Las dos combinan heptasílabos y endecasílabos sin medida fija por posición.~~ _(lo dibuja la figura)_
- La canción repite en cada estancia el patrón que fijó la primera; la silva no repite ninguno.

**Quedaría:** «La canción repite en cada estancia el patrón que fijó la primera; la silva no repite ninguno.»

**copla_real** · `compuesta_por` — **quitar entero**

Dice: «Las dos quintillas se separan por una pausa estructural y conservan rimas independientes. El pie quebrado de la quintilla no nace aquí —Navarro Tomás la documenta suelta y quebrada, la más usada por Castillejo—, pero es en la copla real donde el catálogo pregunta en qué versos cae.»

- ~~Las dos quintillas se separan por una pausa estructural y conservan rimas independientes.~~ _(habla de otra forma («quintilla»))_
- ~~El pie quebrado de la quintilla no nace aquí —Navarro Tomás la documenta suelta y quebrada, la más usada por Castillejo—, pero es en la copla real donde el catálogo pregunta en qué versos cae.~~ _(habla de otra forma («quintilla»))_

**quintilla** · `derivada_de` — **quitar entero**

Dice: «Se formó añadiendo un quinto verso a la redondilla, y de ahí que comparta con ella sus dos clases de rima. El origen no alcanza, sin embargo, a todas sus disposiciones: solo la mitad conserva una redondilla en los cuatro primeros versos, y las demás reparten las dos clases de un modo que la redondilla no admite.»

- ~~Se formó añadiendo un quinto verso a la redondilla, y de ahí que comparta con ella sus dos clases de rima.~~ _(habla de otra forma («redondilla»))_
- ~~El origen no alcanza, sin embargo, a todas sus disposiciones: solo la mitad conserva una redondilla en los cuatro primeros versos, y las demás reparten las dos clases de un modo que la redondilla no admite.~~ _(habla de otra forma («redondilla»))_

**soneto** · `compuesta_por` — **quitar entero**

Dice: «El soneto no hereda del cuarteto su rima, solo su medida y su extensión: las dos clases las declara él, y son las mismas en los dos cuartetos.»

- ~~El soneto no hereda del cuarteto su rima, solo su medida y su extensión: las dos clases las declara él, y son las mismas en los dos cuartetos.~~ _(habla de otra forma («cuarteto»))_

**soneto** · `compuesta_por` — **quitar entero**

Dice: «El soneto no hereda del terceto su rima, solo su medida y su extensión: las dos o tres clases las declara él, y son las mismas en los dos tercetos.»

- ~~El soneto no hereda del terceto su rima, solo su medida y su extensión: las dos o tres clases las declara él, y son las mismas en los dos tercetos.~~ _(habla de otra forma («terceto»))_

**decima** · `compuesta_por` — **quitar entero**

Dice: «La espinela articula dos redondillas abrazadas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.»

- ~~La espinela articula dos redondillas abrazadas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.~~ _(habla de otra forma («redondilla»))_

**cuarteto** · `relacionada_con` — **quitar entero**

Dice: «Comparten la organización de cuatro versos consonantes en dos clases de rima, abrazadas o cruzadas, y solo las separa el arte del verso: mayor en el cuarteto, menor en la redondilla. Por eso el nombre de una disposición sirve para las dos, y «serventesio» se ha usado alguna vez para la redondilla cruzada aunque corresponda más propiamente al cuarteto.»

- ~~Comparten la organización de cuatro versos consonantes en dos clases de rima, abrazadas o cruzadas, y solo las separa el arte del verso: mayor en el cuarteto, menor en la redondilla.~~ _(habla de otra forma («redondilla»))_
- ~~Por eso el nombre de una disposición sirve para las dos, y «serventesio» se ha usado alguna vez para la redondilla cruzada aunque corresponda más propiamente al cuarteto.~~ _(habla de otra forma («redondilla»))_

**silva** · `contrasta_con` — **quitar entero**

Dice: «La silva de consonantes son pareados de siete y once, y lo único que la mantiene silva es que alterna las dos medidas. Sin esa heterometría no queda nada que las distinga: por eso una serie de solo endecasílabos con pareados sistemáticos se registra como tirada de pareados.»

- ~~La silva de consonantes son pareados de siete y once, y lo único que la mantiene silva es que alterna las dos medidas.~~ _(habla de otra forma («pareado»))_
- ~~Sin esa heterometría no queda nada que las distinga: por eso una serie de solo endecasílabos con pareados sistemáticos se registra como tirada de pareados.~~ _(habla de otra forma («pareado»))_

**terceto_encadenado** · `relacionada_con` — **quitar entero**

Dice: «Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente, de modo que la serie no se deja cortar en estrofas contables: es una sola unidad abierta. Por eso figuran como formas distintas y no como dos realizaciones de una sola: el terceto es una estrofa y el encadenado, una serie.»

- ~~Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente, de modo que la serie no se deja cortar en estrofas contables: es una sola unidad abierta.~~ _(habla de otra forma («terceto»))_
- ~~Por eso figuran como formas distintas y no como dos realizaciones de una sola: el terceto es una estrofa y el encadenado, una serie.~~ _(habla de otra forma («terceto»))_

**sextilla** · `contrasta_con` — **quitar entero**

Dice: «La misma estrofa de seis versos, separada por el arte de sus versos: se llama sextilla cuando son de arte menor y sexteto cuando son de arte mayor. Es el mismo reparto que separa la redondilla del cuarteto en las estrofas de cuatro, y viene de la tradición, que define a cada una por exclusión de la otra. Cuando la estrofa mezcla endecasílabos y heptasílabos con regularidad no es ninguna de las dos, sino sexteto-lira.»

- ~~La misma estrofa de seis versos, separada por el arte de sus versos: se llama sextilla cuando son de arte menor y sexteto cuando son de arte mayor.~~ _(habla de otra forma («sexteto»))_
- ~~Es el mismo reparto que separa la redondilla del cuarteto en las estrofas de cuatro, y viene de la tradición, que define a cada una por exclusión de la otra.~~ _(habla de otra forma («cuarteto»))_
- ~~Cuando la estrofa mezcla endecasílabos y heptasílabos con regularidad no es ninguna de las dos, sino sexteto-lira.~~ _(habla de otra forma («sexteto-lira»))_

**sexteto** · `contrasta_con` — **quitar entero**

Dice: «Las dos son estrofas de seis versos con rima consonante y las dos suelen cerrar en pareado; lo que las separa es la medida. El sexteto la mantiene igual en los seis versos, y el sexteto-lira alterna endecasílabos con heptasílabos. Entre el aBaBcC del sexteto-lira y la sexta rima ABABCC no hay más diferencia que el heptasílabo en los impares.»

- ~~Las dos son estrofas de seis versos con rima consonante y las dos suelen cerrar en pareado; lo que las separa es la medida.~~ _(habla de otra forma («pareado»))_
- ~~El sexteto la mantiene igual en los seis versos, y el sexteto-lira alterna endecasílabos con heptasílabos.~~ _(habla de otra forma («sexteto-lira»))_
- ~~Entre el aBaBcC del sexteto-lira y la sexta rima ABABCC no hay más diferencia que el heptasílabo en los impares.~~ _(habla de otra forma («sexteto-lira»))_

**copla_real** · `contrasta_con` — **acortar**

Dice: «Las dos reparten octosílabos consonantes en dos miembros con rimas independientes, y se separan por cómo los reparten: la copla real junta dos quintillas, cinco y cinco, y la novena una redondilla con una quintilla, cuatro y cinco o cinco y cuatro. Las dos admiten que algún verso se quiebre.»

- ~~Las dos reparten octosílabos consonantes en dos miembros con rimas independientes, y se separan por cómo los reparten: la copla real junta dos quintillas, cinco y cinco, y la novena una redondilla con una quintilla, cuatro y cinco o cinco y cuatro.~~ _(habla de otra forma («quintilla»))_
- Las dos admiten que algún verso se quiebre.

**Quedaría:** «Las dos admiten que algún verso se quiebre.»

**octava_real** · `contrasta_con` — **acortar**

Dice: «Las dos reparten ocho versos de arte mayor en dos mitades, y se separan por cómo las atan. La copla de arte mayor las enlaza —una rima común a los dos cuartetos, y el cuarto verso rimando con el quinto—, mientras que la octava real corre sobre dos rimas alternas hasta cerrar con un pareado que estrena la tercera. Y la medida las separa también: dodecasílabos partidos por cesura frente a endecasílabos.»

- Las dos reparten ocho versos de arte mayor en dos mitades, y se separan por cómo las atan.
- ~~La copla de arte mayor las enlaza —una rima común a los dos cuartetos, y el cuarto verso rimando con el quinto—, mientras que la octava real corre sobre dos rimas alternas hasta cerrar con un pareado que estrena la tercera.~~ _(habla de otra forma («copla de arte mayor»))_
- Y la medida las separa también: dodecasílabos partidos por cesura frente a endecasílabos.

**Quedaría:** «Las dos reparten ocho versos de arte mayor en dos mitades, y se separan por cómo las atan. Y la medida las separa también: dodecasílabos partidos por cesura frente a endecasílabos.»

**octava_real** · `relacionada_con` — **quitar entero**

Dice: «`ABABCC` y `ABABABCC` son la misma manera de rimar con dos versos de diferencia: alternancia de dos clases y un pareado final que estrena la tercera. Por eso Jauralde describe la sexta rima como un sexteto rimado a la manera de la octava real.»

- ~~`ABABCC` y `ABABABCC` son la misma manera de rimar con dos versos de diferencia: alternancia de dos clases y un pareado final que estrena la tercera.~~ _(habla de otra forma («pareado»))_
- ~~Por eso Jauralde describe la sexta rima como un sexteto rimado a la manera de la octava real.~~ _(habla de otra forma («sexteto»))_

**novena** · `compuesta_por` — **quitar entero**

Dice: «La quintilla es el miembro mayor de la copla novena: va detrás en el orden habitual, 4+5, y delante en el 5+4. Es también donde suele caer el quiebro cuando la estrofa lo lleva y la redondilla abre.»

- ~~La quintilla es el miembro mayor de la copla novena: va detrás en el orden habitual, 4+5, y delante en el 5+4.~~ _(lo dice la modalidad)_
- ~~Es también donde suele caer el quiebro cuando la estrofa lo lleva y la redondilla abre.~~ _(habla de otra forma («redondilla»))_

**novena** · `compuesta_por` — **quitar entero**

Dice: «La redondilla abre la copla novena en su orden habitual, 4+5, y la cierra en el 5+4, que es cuando el quiebro se traslada a ella.»

- ~~La redondilla abre la copla novena en su orden habitual, 4+5, y la cierra en el 5+4, que es cuando el quiebro se traslada a ella.~~ _(lo dice la modalidad)_

**verso_aislado** · `contrasta_con` — **acortar**

Dice: «Son las dos salidas del catálogo cuando un pasaje no deja reconocer ninguna forma, y se reparten por extensión: el verso aislado es uno solo; desde dos versos, el tramo es versificación irregular. Ninguna de las dos es una forma métrica, y por eso no declaran medida, rima ni partes.»

- ~~Son las dos salidas del catálogo cuando un pasaje no deja reconocer ninguna forma, y se reparten por extensión: el verso aislado es uno solo; desde dos versos, el tramo es versificación irregular.~~ _(habla de otra forma («versificacion irregular»))_
- Ninguna de las dos es una forma métrica, y por eso no declaran medida, rima ni partes.

**Quedaría:** «Ninguna de las dos es una forma métrica, y por eso no declaran medida, rima ni partes.»

**villancico** · `relacionada_con` — **quitar entero**

Dice: «La mudanza del villancico es una redondilla —o una cuarteta, cuando la disposición es cruzada o asonantada— y es la parte que menos varía de la forma: el estribillo y el final de la copla admiten bastantes cambios de extensión y de rima, y la estrofa central se mantiene.»

- ~~La mudanza del villancico es una redondilla —o una cuarteta, cuando la disposición es cruzada o asonantada— y es la parte que menos varía de la forma: el estribillo y el final de la copla admiten bastantes cambios de extensión y de rima, y la estrofa central se mantiene.~~ _(habla de otra forma («redondilla»))_

**copla_de_arte_menor** · `compuesta_por` — **quitar entero**

Dice: «Cada semiestrofa se dispone como una redondilla, abrazada o cruzada. Lo que la copla añade es una rima que vuelve de la primera a la segunda, y es lo que impide leerla como dos redondillas seguidas.»

- ~~Cada semiestrofa se dispone como una redondilla, abrazada o cruzada.~~ _(habla de otra forma («redondilla»))_
- ~~Lo que la copla añade es una rima que vuelve de la primera a la segunda, y es lo que impide leerla como dos redondillas seguidas.~~ _(habla de otra forma («redondilla»))_

**copla_castellana** · `compuesta_por` — **quitar entero**

Dice: «Cada semiestrofa es una redondilla entera, con sus dos clases propias. Que ninguna rima pase de una a otra es lo que hace de esta forma la suma de dos redondillas y no una estrofa con enlace interior.»

- ~~Cada semiestrofa es una redondilla entera, con sus dos clases propias.~~ _(habla de otra forma («redondilla»))_
- ~~Que ninguna rima pase de una a otra es lo que hace de esta forma la suma de dos redondillas y no una estrofa con enlace interior.~~ _(habla de otra forma («redondilla»))_

**octava_aguda** · `contrasta_con` — **acortar**

Dice: «Las dos reparten ocho versos en dos semiestrofas de cuatro, y se separan por lo que su norma fija: la castellana fija las cuatro rimas y no dice nada del acento; la aguda fija solo los versos de cierre —que riman entre sí y en agudo— y deja libres los demás. Cuando una octavilla aguda va en octosílabos, la tradición llega a llamarla copla castellana aguda.»

- Las dos reparten ocho versos en dos semiestrofas de cuatro, y se separan por lo que su norma fija: la castellana fija las cuatro rimas y no dice nada del acento; la aguda fija solo los versos de cierre —que riman entre sí y en agudo— y deja libres los demás.
- ~~Cuando una octavilla aguda va en octosílabos, la tradición llega a llamarla copla castellana aguda.~~ _(habla de otra forma («octavilla»))_

**Quedaría:** «Las dos reparten ocho versos en dos semiestrofas de cuatro, y se separan por lo que su norma fija: la castellana fija las cuatro rimas y no dice nada del acento; la aguda fija solo los versos de cierre —que riman entre sí y en agudo— y deja libres los demás.»

**septilla** · `compuesta_por` — **quitar entero**

Dice: «La redondilla abre la estrofa y le presta al terceto la rima con que se cierra. Es la misma base sobre la que se levantan la copla de arte menor y la copla castellana, aquí con un miembro más corto detrás.»

- ~~La redondilla abre la estrofa y le presta al terceto la rima con que se cierra.~~ _(habla de otra forma («terceto»))_
- ~~Es la misma base sobre la que se levantan la copla de arte menor y la copla castellana, aquí con un miembro más corto detrás.~~ _(habla de otra forma («copla de arte menor»))_

**oncena** · `compuesta_por` — **quitar entero**

Dice: «La quintilla es el miembro menor de la oncena y el que menos varía: va de ordinario en `abaab`, abriendo la estrofa en el orden corriente y cerrándola en el inverso.»

- ~~La quintilla es el miembro menor de la oncena y el que menos varía: va de ordinario en `abaab`, abriendo la estrofa en el orden corriente y cerrándola en el inverso.~~ _(habla de otra forma («quintilla»))_

**oncena** · `compuesta_por` — **quitar entero**

Dice: «Los seis versos del miembro mayor se combinan de manera variable, y es donde la oncena admite más soluciones: una quintilla con un verso añadido, lo más frecuente, o dos tercetos correlativos, que llevan la estrofa a cinco rimas.»

- ~~Los seis versos del miembro mayor se combinan de manera variable, y es donde la oncena admite más soluciones: una quintilla con un verso añadido, lo más frecuente, o dos tercetos correlativos, que llevan la estrofa a cinco rimas.~~ _(lo dice la modalidad)_

**oncena** · `contrasta_con` — **acortar**

Dice: «Las dos reparten octosílabos consonantes en dos miembros de distinta extensión, y se separan por cuáles: la novena junta una redondilla con una quintilla, y la oncena una quintilla con una sextilla. Las dos admiten los dos órdenes y las dos admiten quiebro, que en la oncena es además lo corriente.»

- ~~Las dos reparten octosílabos consonantes en dos miembros de distinta extensión, y se separan por cuáles: la novena junta una redondilla con una quintilla, y la oncena una quintilla con una sextilla.~~ _(habla de otra forma («sextilla»))_
- Las dos admiten los dos órdenes y las dos admiten quiebro, que en la oncena es además lo corriente.

**Quedaría:** «Las dos admiten los dos órdenes y las dos admiten quiebro, que en la oncena es además lo corriente.»

**copla_manriquena** · `compuesta_por` — **quitar entero**

Dice: «Cada mitad es una sextilla de pie quebrado entera, con sus consonancias propias. Que ninguna rima pase de una a otra es lo que las individualiza, y lo que hace de la agrupación una estrofa de doce y no una serie de sextillas: lo que corre entre ellas es el sentido del texto.»

- ~~Cada mitad es una sextilla de pie quebrado entera, con sus consonancias propias.~~ _(habla de otra forma («sextilla»))_
- ~~Que ninguna rima pase de una a otra es lo que las individualiza, y lo que hace de la agrupación una estrofa de doce y no una serie de sextillas: lo que corre entre ellas es el sentido del texto.~~ _(habla de otra forma («sextilla»))_

**septeto** · `contrasta_con` — **acortar**

Dice: «Son la misma estrofa de siete versos en las dos artes: septilla en arte menor, septeto en arte mayor, y séptima como nombre común. Es el mismo reparto que separa la sextilla del sexteto y la redondilla del cuarteto. Las dos admiten organizarse en cuatro y tres.»

- ~~Son la misma estrofa de siete versos en las dos artes: septilla en arte menor, septeto en arte mayor, y séptima como nombre común.~~ _(habla de otra forma («septilla»))_
- ~~Es el mismo reparto que separa la sextilla del sexteto y la redondilla del cuarteto.~~ _(habla de otra forma («cuarteto»))_
- Las dos admiten organizarse en cuatro y tres.

**Quedaría:** «Las dos admiten organizarse en cuatro y tres.»

**septeto** · `compuesta_por` — **quitar entero**

Dice: «El cuarteto abre el septeto compuesto y aporta cuatro de sus siete versos.»

- ~~El cuarteto abre el septeto compuesto y aporta cuatro de sus siete versos.~~ _(habla de otra forma («cuarteto»))_

**septeto** · `compuesta_por` — **quitar entero**

Dice: «El terceto cierra el septeto compuesto, recogiendo alguna rima del cuarteto o estrenando las suyas.»

- ~~El terceto cierra el septeto compuesto, recogiendo alguna rima del cuarteto o estrenando las suyas.~~ _(habla de otra forma («cuarteto»))_

**septeto_lira** · `derivada_de` — **acortar**

Dice: «Es el sexteto-lira con un verso más: la misma combinación de heptasílabos y endecasílabos y el mismo pareado final, con una clase recogida antes del remate. Las dos salen de la lira de cinco versos.»

- ~~Es el sexteto-lira con un verso más: la misma combinación de heptasílabos y endecasílabos y el mismo pareado final, con una clase recogida antes del remate.~~ _(habla de otra forma («sexteto-lira»))_
- Las dos salen de la lira de cinco versos.

**Quedaría:** «Las dos salen de la lira de cinco versos.»

**septeto_lira** · `contrasta_con` — **quitar entero**

Dice: «Las dos miden siete versos de arte mayor, y se separan por la medida: el septeto es isosilábico y el septeto-lira mezcla heptasílabos y endecasílabos, que es lo que lo hace alirado.»

- ~~Las dos miden siete versos de arte mayor, y se separan por la medida: el septeto es isosilábico y el septeto-lira mezcla heptasílabos y endecasílabos, que es lo que lo hace alirado.~~ _(habla de otra forma («septeto»))_

**redondilla_enlazada** · `relacionada_con` — **quitar entero**

Dice: «Navarro la llama «una especie de redondilla», y de la redondilla tiene la extensión y el par de versos centrales rimados. Pero no es una redondilla: la redondilla cierra sus dos clases dentro de sí, y esta deja abiertas la primera y la última, que son las que la atan a las estrofas vecinas.»

- ~~Navarro la llama «una especie de redondilla», y de la redondilla tiene la extensión y el par de versos centrales rimados.~~ _(habla de otra forma («redondilla»))_
- ~~Pero no es una redondilla: la redondilla cierra sus dos clases dentro de sí, y esta deja abiertas la primera y la última, que son las que la atan a las estrofas vecinas.~~ _(habla de otra forma («redondilla»))_

**redondilla_enlazada** · `relacionada_con` — **acortar**

Dice: «Son las dos maneras que el catálogo registra de encadenar una serie por la rima. En el terceto encadenado el enlace es la rima central, que vuelve como exterior de la unidad siguiente; aquí es el verso quebrado del final, que abre la clase con que empieza la estrofa que viene.»

- Son las dos maneras que el catálogo registra de encadenar una serie por la rima.
- ~~En el terceto encadenado el enlace es la rima central, que vuelve como exterior de la unidad siguiente; aquí es el verso quebrado del final, que abre la clase con que empieza la estrofa que viene.~~ _(habla de otra forma («terceto encadenado»))_

**Quedaría:** «Son las dos maneras que el catálogo registra de encadenar una serie por la rima.»

**sextilla_enlazada** · `compuesta_por` — **quitar entero**

Dice: «Cinco de sus seis versos son una quintilla, la de quebrado inicial que la tradición atribuye a Castillejo. Lo que la sextilla enlazada añade es el octosílabo de delante, que no rima dentro de la estrofa sino con la anterior.»

- ~~Cinco de sus seis versos son una quintilla, la de quebrado inicial que la tradición atribuye a Castillejo.~~ _(habla de otra forma («quintilla»))_
- ~~Lo que la sextilla enlazada añade es el octosílabo de delante, que no rima dentro de la estrofa sino con la anterior.~~ _(habla de otra forma («sextilla»))_

**sextilla_enlazada** · `relacionada_con` — **quitar entero**

Dice: «Mide seis versos octosílabos con quebrado, como la sextilla de pie quebrado, y no es una sextilla: la sextilla cierra sus clases dentro de sí, y esta deja la primera y la última atadas a las estrofas vecinas.»

- ~~Mide seis versos octosílabos con quebrado, como la sextilla de pie quebrado, y no es una sextilla: la sextilla cierra sus clases dentro de sí, y esta deja la primera y la última atadas a las estrofas vecinas.~~ _(habla de otra forma («sextilla»))_

**sextilla_enlazada** · `relacionada_con` — **quitar entero**

Dice: «Son dos de las tres estrofas enlazadas, y se separan por dónde cae el quebrado y qué papel hace: en la redondilla enlazada es el último verso y pasa la rima hacia delante; aquí es el segundo, y lo que enlaza con la estrofa anterior es el primero.»

- ~~Son dos de las tres estrofas enlazadas, y se separan por dónde cae el quebrado y qué papel hace: en la redondilla enlazada es el último verso y pasa la rima hacia delante; aquí es el segundo, y lo que enlaza con la estrofa anterior es el primero.~~ _(habla de otra forma («redondilla enlazada»))_

**septilla_enlazada** · `compuesta_por` — **quitar entero**

Dice: «Cinco de sus siete versos son una quintilla regular, que abre con la clase del quebrado y cierra con la que pasa a la estrofa siguiente. Es la base de la estrofa, donde la sextilla enlazada tiene una redondilla.»

- ~~Cinco de sus siete versos son una quintilla regular, que abre con la clase del quebrado y cierra con la que pasa a la estrofa siguiente.~~ _(habla de otra forma («quintilla»))_
- ~~Es la base de la estrofa, donde la sextilla enlazada tiene una redondilla.~~ _(habla de otra forma («sextilla enlazada»))_

**septilla_enlazada** · `relacionada_con` — **quitar entero**

Dice: «Son la misma técnica en dos extensiones: los dos versos de enlace son idénticos —un octosílabo que recoge la rima anterior y un quebrado que estrena la suya— y lo que cambia es la base, redondilla en la de seis y quintilla en la de siete.»

- ~~Son la misma técnica en dos extensiones: los dos versos de enlace son idénticos —un octosílabo que recoge la rima anterior y un quebrado que estrena la suya— y lo que cambia es la base, redondilla en la de seis y quintilla en la de siete.~~ _(habla de otra forma («quintilla»))_

**septilla_enlazada** · `contrasta_con` — **quitar entero**

Dice: «Las dos miden siete octosílabos, y se separan por si la estrofa se cierra: la septilla reparte sus versos en redondilla y terceto y agota sus rimas dentro de sí; la enlazada deja abiertas la primera y la última, que la atan a las estrofas vecinas.»

- ~~Las dos miden siete octosílabos, y se separan por si la estrofa se cierra: la septilla reparte sus versos en redondilla y terceto y agota sus rimas dentro de sí; la enlazada deja abiertas la primera y la última, que la atan a las estrofas vecinas.~~ _(habla de otra forma («terceto»))_

**redondilla_enlazada** · `contrasta_con` — **quitar entero**

Dice: «Las dos enlazan redondillas por la rima, y se separan por dónde: la copla de arte menor es una estrofa de ocho versos que se cose por dentro —una rima vuelve de la primera semiestrofa a la segunda y ahí se cierra, sin pasar de tres clases—, y la redondilla enlazada es una serie abierta que se cose por fuera, con un verso quebrado que estrena la clase con que abre la estrofa siguiente. Dos vueltas de la enlazada dan ocho versos con cinco clases y una abierta; la copla de arte menor nunca llega ahí.»

- ~~Las dos enlazan redondillas por la rima, y se separan por dónde: la copla de arte menor es una estrofa de ocho versos que se cose por dentro —una rima vuelve de la primera semiestrofa a la segunda y ahí se cierra, sin pasar de tres clases—, y la redondilla enlazada es una serie abierta que se cose por fuera, con un verso quebrado que estrena la clase con que abre la estrofa siguiente.~~ _(habla de otra forma («copla de arte menor»))_
- ~~Dos vueltas de la enlazada dan ocho versos con cinco clases y una abierta; la copla de arte menor nunca llega ahí.~~ _(habla de otra forma («copla de arte menor»))_

**septilla** · `compuesta_por` — **quitar entero**

Dice: «Los tres versos que cierran la septilla son un tercetillo, el terceto en arte menor. Lo que la septilla añade es que no rima solo: al menos uno de sus versos recoge una clase de la redondilla que lo precede.»

- ~~Los tres versos que cierran la septilla son un tercetillo, el terceto en arte menor.~~ _(habla de otra forma («terceto»))_
- ~~Lo que la septilla añade es que no rima solo: al menos uno de sus versos recoge una clase de la redondilla que lo precede.~~ _(habla de otra forma («redondilla»))_

**silva** · `relacionada_con` — **quitar entero**

Dice: «La silva arromanzada toma del romance su figura de rima: una misma asonancia en todos los versos pares, con los impares sueltos. Lo que la separa es la medida —el romance es isosilábico y la silva mezcla siete y once— y que aquí esa figura es una realización entre otras, no la norma de la forma.»

- ~~La silva arromanzada toma del romance su figura de rima: una misma asonancia en todos los versos pares, con los impares sueltos.~~ _(habla de otra forma («romance»))_
- ~~Lo que la separa es la medida —el romance es isosilábico y la silva mezcla siete y once— y que aquí esa figura es una realización entre otras, no la norma de la forma.~~ _(habla de otra forma («romance»))_

**octava_lira** · `relacionada_con` — **acortar**

Dice: «Las dos son estrofas aliradas: misma mezcla de siete y once, misma rima consonante y misma repetición sin cambio. Lo único que las separa es la extensión, ocho versos frente a cinco. Y las dos comparten el cierre en pareado, que Jauralde da por seña de identidad de la lira y el Diccionario por invariante de la octava.»

- Las dos son estrofas aliradas: misma mezcla de siete y once, misma rima consonante y misma repetición sin cambio.
- Lo único que las separa es la extensión, ocho versos frente a cinco.
- ~~Y las dos comparten el cierre en pareado, que Jauralde da por seña de identidad de la lira y el Diccionario por invariante de la octava.~~ _(habla de otra forma («pareado»))_

**Quedaría:** «Las dos son estrofas aliradas: misma mezcla de siete y once, misma rima consonante y misma repetición sin cambio. Lo único que las separa es la extensión, ocho versos frente a cinco.»

**novena_lira** · `relacionada_con` — **acortar**

Dice: «Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho. La octava tiene disposiciones documentadas y una invariante —cierra en pareado—; de la novena no se conoce ninguna.»

- Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho.
- ~~La octava tiene disposiciones documentadas y una invariante —cierra en pareado—; de la novena no se conoce ninguna.~~ _(habla de otra forma («pareado»))_

**Quedaría:** «Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho.»

**decima_lira** · `relacionada_con` — **quitar entero**

Dice: «Es la estrofa alirada que más se acerca a una estancia de canción: misma materia, y una disposición que repite la cabeza como lo haría una fronte partida en dos piedi. Lo único que las separa es el eslabón, que la canción trae y esta no. De ahí que la tradición crítica la llame «décima-estancia».»

- ~~Es la estrofa alirada que más se acerca a una estancia de canción: misma materia, y una disposición que repite la cabeza como lo haría una fronte partida en dos piedi.~~ _(habla de otra forma («cancion»))_
- ~~Lo único que las separa es el eslabón, que la canción trae y esta no.~~ _(habla de otra forma («cancion»))_
- ~~De ahí que la tradición crítica la llame «décima-estancia».~~ _(habla de otra forma («decima»))_
