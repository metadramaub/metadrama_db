# Informe de conformidad del catálogo métrico

Generado: 2026-08-25 20:58

Inventario: 41 formas y 2 tramos sin forma · 91 configuraciones · 96 patrones métricos · 164 patrones de rima · 85 secciones · 106 grupos de elección · 680 opciones · 7 rasgos.

Criterios aplicados: [criterios-de-nivel.md](./criterios-de-nivel.md). El bloque 1 recoge incumplimientos que no dependen de una decisión editorial. El bloque 2 describe dónde vive cada dimensión para que las divergencias de criterio sean visibles.

## 1 · Defectos

### D1 · Configuración sin contenido normativo — 0

> Una configuración debe declarar al menos un patrón, una sección o una variedad.

Sin incidencias.

### D2 · Patrón de rima sin contenido alguno — 0

> Un esquema debe aportar algo computable: notación, posiciones o restricciones. Un esquema vacío no declara norma y solo ocupa un hueco en la interfaz. Se exceptúa el de tipo abierta con un tipo de rima declarado: afirma que la norma exige ese tipo y deja libre la disposición, como corresponde a una forma general.

Sin incidencias.

### D2b · Configuración sin ninguna declaración de rima ni de repetición — 0

> Toda configuración debe declarar cómo se comporta la rima: un patrón propio, una sección que lo aporte o lo reutilice, o un patrón de repetición que ocupe su lugar.

Sin incidencias.

### D3 · Patrón métrico sin posiciones ni opciones — 0

> Un patrón métrico debe declarar posiciones ordenadas o un conjunto permitido.

Sin incidencias.

### D4 · La extensión de la unidad no se declara ni se puede derivar — 0

> Una arquitectura declara cuántos versos tiene su unidad, y entonces sus secciones no pueden sumar otra cosa; o la deja sin declarar, y entonces tiene que haber secciones de las que derivarla. Lo que no puede es no decirlo por ninguna de las dos vías.

Sin incidencias.

### D5 · La opción distingue menos posiciones que el patrón al que apunta — 0

> El patrón debe modelar el nivel que la pregunta distingue; si la opción nombra un esquema más corto, la alternativa vive en un nivel inferior.

Sin incidencias.

### D6 · Slug de opción con UUID incrustado — 0

> Los slugs son identificadores estables y legibles; serán clave de comparación.

Sin incidencias.

### D7 · Rasgo booleano usado como vector de posiciones — 0

> Un rasgo describe una propiedad, no una posición. Una alternativa posicional pertenece al patrón métrico o a una opción de metro con posicion_unidad.

Sin incidencias.

### D8 · Componente copiado en lugar de reutilizado — 0

> Cuando una forma declara `compuesta_por` o `subtipo_de` otra, sus secciones reutilizan la configuración del componente mediante arquitectura_referenciada_id. Copiar sus patrones obliga a mantener el repertorio en varios sitios y rompe la comparación.

Sin incidencias.

### D9 · Rasgo cualitativo almacenado como restricción de rima sin catalogar — 0

> Una propiedad transversal es un rasgo con modalidad declarada, no un literal libre colgado de un patrón.

Sin incidencias.

### D10 · Coherencia del tipo de registro y del grado de especificación — 0

> Un tramo sin forma no tiene arquitectura. Y la taxonomía va en una sola dirección: lo específico es subtipo de lo general, nunca al revés.

Sin incidencias.

### D11 · Sección que solo existe para repetir la unidad — 0

> Una sección describe el interior de la unidad. Que el pasaje contenga varias unidades se deriva del rango, no se declara como sección. Se exceptúan las series, donde la sección repetible describe el ritmo interno de la propia serie.

Sin incidencias.

### D12 · Pregunta estructural con alcance de secuencia — 0

> Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad.

Sin incidencias.

### D13 · Un esquema concreto contradice el criterio de su esquema abierto — 0

> Cuando una arquitectura declara un esquema abierto con restricciones y además esquemas concretos sobre el mismo tramo, el abierto es la norma y los concretos son sus realizaciones documentadas: tienen que cumplirla. Se exceptúan tres. El concreto que el propio criterio excluye —ahí el abierto no es la norma sino la alternativa que queda—; los que ocupan otra sección, que no compiten con él sino que completan la estrofa; y **los declarados `excepcional`**, que están en el catálogo precisamente porque se apartan de la norma y se registran igual.

Sin incidencias.

### D14 · La notación de un esquema y sus clases de rima no cuadran — 0

> La notación es lo que se publica y las posiciones son lo que se dibuja: tienen que decir lo mismo. Las letras de la notación, en orden de lectura, son las clases guardadas, con su caja —la mayúscula marca el arte mayor y no una clase distinta— y sin contar los versos sueltos, que la notación escribe con guion y las posiciones dejan sin clase. Ocho esquemas incumplían esto hasta el 12 de agosto de 2026, y se veía al dibujar la rejilla: las letras contradecían la notación impresa debajo.

Sin incidencias.

### D15 · Arquitectura sin régimen de rima declarado en ningún nivel — 0

> El régimen —consonante, asonante, sin rima— se declara siempre, en el nivel que le corresponde: en la arquitectura cuando es uno solo, y en cada disposición cuando dentro de ella varía. El villancico lo declara abajo porque admite `abba` consonante junto a la asonantada `-a-a`, y la canción sin rima porque su cuerpo no rima y su pareado final sí. Lo que no vale es que no esté en ninguno de los dos: es lo primero que hay que saber de una rima, y ocho arquitecturas lo callaban hasta el 12 de agosto de 2026.

Sin incidencias.

### D16 · Reutilización entre formas sin relación ontológica — 0

> Cuando una sección reutiliza una arquitectura de otra forma, la precisión estructural vive en arquitectura_referenciada_id y el vínculo navegable vive en forma_relaciones. Tiene que existir al menos una relación entre ambas formas, declarada una sola vez en cualquiera de las dos direcciones.

Sin incidencias.

### D17 · Una unidad cuya rima no está fija y nadie pregunta — 0

> Regla 1 de criterios de nivel § 3.3: donde hay unidad y la norma no fija una sola disposición, el editor tiene que poder decir cuál leyó. Se cumple de cuatro maneras y basta una: la arquitectura pregunta su rima; la resuelve una variedad, que empareja esquema métrico y de rima; toda su rima vive en secciones que reutilizan otras arquitecturas y la heredan; o la norma la fija con un único esquema concreto. Las series quedan fuera porque no tienen unidad: su rima se describe por rasgos del pasaje.

Sin incidencias.

## 2 · Homogeneidad de criterio

### 2.1 · Dónde vive cada dimensión, forma por forma

| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |
| --- | --- | ---: | :-: | --- | --- | ---: | --- |
| cancion_petrarquista | composicion | 3 | sí | conjunto, eleccion, posiciones | esquema libre, patrón único, varios patrones sin pregunta | 4 | secuencia, unidad |
| copla_castellana | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| copla_de_arte_mayor | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| copla_de_arte_menor | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| copla_manriquena | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| copla_real | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección, sin patrón | 3 | unidad |
| cuarteto | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| cuarteto_lira | estrofa | 1 | sí | conjunto | elección | 1 | unidad |
| decima | estrofa | 6 | sí | configuracion, posiciones | patrón único | 0 | — |
| decima_lira | estrofa | 1 | sí | conjunto | elección | 1 | unidad |
| endecasilabo_suelto | serie | 1 | sí | posiciones | patrón único | 5 | secuencia |
| endecha_real | serie | 3 | sí | configuracion, posiciones | elección, patrón único | 4 | secuencia |
| lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| novena | estrofa | 2 | sí | conjunto, eleccion, posiciones | elección, sin patrón | 6 | unidad |
| novena_lira | estrofa | 1 | sí | conjunto | esquema libre | 1 | unidad |
| octava_aguda | estrofa | 6 | sí | configuracion, posiciones | elección | 6 | unidad |
| octava_lira | estrofa | 1 | sí | conjunto | elección | 1 | unidad |
| octava_real | estrofa | 1 | sí | posiciones | elección | 3 | secuencia, unidad |
| oncena | estrofa | 2 | sí | conjunto, eleccion, posiciones | sin patrón | 2 | unidad |
| pareado | estrofa | 2 | sí | configuracion, conjunto, eleccion | elección, patrón único | 3 | unidad |
| quintilla | estrofa | 3 | sí | configuracion, conjunto, eleccion, posiciones | elección | 4 | unidad |
| redondilla | estrofa | 3 | sí | configuracion, conjunto, eleccion, posiciones | elección | 4 | unidad |
| redondilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| romance | serie | 6 | sí | configuracion, posiciones | patrón único | 6 | secuencia |
| seguidilla | estrofa | 7 | sí | configuracion, eleccion, posiciones | patrón único | 1 | unidad |
| septeto | estrofa | 2 | sí | posiciones | esquema libre, patrón único | 3 | secuencia, unidad |
| septeto_lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| septilla | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| septilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| sexteto | estrofa | 3 | sí | configuracion, posiciones | elección, esquema libre | 4 | secuencia, unidad |
| sexteto_lira | estrofa | 1 | sí | posiciones | variedad | 2 | secuencia, unidad |
| sextilla | estrofa | 6 | sí | configuracion, posiciones | elección, esquema libre | 6 | unidad |
| sextilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| sextina | composicion | 3 | sí | posiciones | sin patrón | 0 | — |
| sextina_estrofa | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| silva | serie | 5 | sí | configuracion, conjunto, posiciones | patrón único | 4 | secuencia |
| soneto | composicion | 1 | sí | posiciones | elección | 3 | secuencia, unidad |
| terceto | estrofa | 3 | sí | configuracion, posiciones | elección | 4 | secuencia, unidad |
| terceto_encadenado | serie | 2 | sí | configuracion, posiciones | patrón único | 0 | — |
| villancico | composicion | 2 | sí | conjunto, eleccion | elección | 12 | realizacion, unidad |
| zejel | composicion | 1 | sí | conjunto, eleccion | patrón único | 4 | realizacion, unidad |

### 2.2 · Reparto de la medida

| Vía | Formas |
| --- | --- |
| configuracion (13) | decima, endecha_real, octava_aguda, pareado, quintilla, redondilla, romance, seguidilla, sexteto, sextilla, silva, terceto, terceto_encadenado |
| conjunto (17) | cancion_petrarquista, copla_castellana, copla_de_arte_menor, copla_real, cuarteto_lira, decima_lira, novena, novena_lira, octava_lira, oncena, pareado, quintilla, redondilla, septilla, silva, villancico, zejel |
| eleccion (13) | cancion_petrarquista, copla_castellana, copla_de_arte_menor, copla_real, novena, oncena, pareado, quintilla, redondilla, seguidilla, septilla, villancico, zejel |
| posiciones (34) | cancion_petrarquista, copla_castellana, copla_de_arte_mayor, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto, decima, endecasilabo_suelto, endecha_real, lira, novena, octava_aguda, octava_real, oncena, quintilla, redondilla, redondilla_enlazada, romance, seguidilla, septeto, septeto_lira, septilla, septilla_enlazada, sexteto, sexteto_lira, sextilla, sextilla_enlazada, sextina, sextina_estrofa, silva, soneto, terceto, terceto_encadenado |

### 2.3 · Alcance de las preguntas por dimensión

| Dimensión · alcance | Formas |
| --- | --- |
| combinacion · unidad | sexteto_lira |
| metro · unidad | cancion_petrarquista, copla_castellana, copla_de_arte_menor, copla_real, novena, oncena, pareado, quintilla, redondilla, seguidilla, septilla, villancico, zejel |
| rasgo · secuencia | cancion_petrarquista, endecasilabo_suelto, endecha_real, octava_real, romance, septeto, sexteto, sexteto_lira, silva, soneto, terceto |
| repeticion · realizacion | villancico, zejel |
| rima · secuencia | endecha_real |
| rima · unidad | cancion_petrarquista, copla_castellana, copla_de_arte_mayor, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto, cuarteto_lira, decima_lira, novena, novena_lira, octava_aguda, octava_lira, octava_real, pareado, quintilla, redondilla, septeto, septilla, sexteto, sextilla, soneto, terceto, villancico |

### 2.4 · Ámbito declarado en los patrones de rima

| Ámbito | Total | Formas |
| --- | ---: | --- |
| undefined | 164 | cancion_petrarquista×4, copla_castellana×4, copla_de_arte_mayor×4, copla_de_arte_menor×3, copla_manriquena×2, cuarteto×2, cuarteto_lira×2, decima×6, decima_lira×1, endecasilabo_suelto×1, endecha_real×7, lira×1, novena_lira×1, octava_aguda×12, octava_lira×2, octava_real×2, pareado×3, quintilla×27, redondilla×6, redondilla_enlazada×1, romance×6, seguidilla×7, septeto×2, septeto_lira×1, septilla×5, septilla_enlazada×1, sexteto×5, sexteto_lira×3, sextilla×11, sextilla_enlazada×1, sextina_estrofa×1, silva×5, soneto×6, terceto×10, terceto_encadenado×2, villancico×6, zejel×1 |

### 2.5 · Cómo se resuelve la rima que la norma no fija

| Configuración | Patrones abiertos | Estrategia |
| --- | ---: | --- |
| novena_lira · heterometrica_consonante | 1 | control abierto de esquema |
| sexteto · dodecasilabica | 1 | control abierto de esquema |
| sextilla · heptasilabica | 1 | control abierto de esquema |
| sextilla · hexasilabica | 1 | control abierto de esquema |
| sextilla · pentasilabica | 1 | control abierto de esquema |
| sextilla · tetrasilabica | 1 | control abierto de esquema |
| cancion_petrarquista · estancias_consonantes_variables | 1 | control abierto de esquema + restricciones cualitativas (1) |
| septeto · endecasilabica | 1 | control abierto de esquema + restricciones cualitativas (1) |
| octava_real · endecasilabica_consonante | 1 | patrón vacío, sin sustituto |
| septeto · compuesta | 1 | patrón vacío, sin sustituto |
| sexteto · alejandrina | 1 | patrón vacío, sin sustituto |
| sexteto · endecasilabica | 1 | patrón vacío, sin sustituto |
| sextilla · octosilabica | 1 | patrón vacío, sin sustituto |
| sextilla · pie_quebrado | 1 | patrón vacío, sin sustituto |
| cancion_petrarquista · sin_rima_con_pareado_final | 1 | restricciones cualitativas (1) |
| copla_manriquena · doble_pie_quebrado | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · endecasilabica | 1 | restricciones cualitativas (1) |
| quintilla · heptasilabica | 1 | restricciones cualitativas (1) |
| quintilla · hexasilabica | 1 | restricciones cualitativas (1) |
| quintilla · octosilabica_consonante | 1 | restricciones cualitativas (1) |
| silva · consonante_irregular | 1 | restricciones cualitativas (1) |
| silva · endecasilabica | 1 | restricciones cualitativas (1) |
| silva · libre | 1 | restricciones cualitativas (1) |

### 2.6 · Esquemas que coinciden literalmente en varias formas

Coincidencia literal no implica error: puede tratarse de la misma disposición sobre metros distintos. Solo debe reutilizarse cuando una forma es componente de la otra (véase D8).

| Esquema | Formas |
| --- | --- |
| abab | cuarteto_lira, redondilla×3, villancico×2 |
| abba | cuarteto_lira, redondilla×3, villancico×2 |
| -a-a | seguidilla×3, villancico×2 |
| [-a]… | romance×5, silva |
| a-a | seguidilla, terceto×2 |
| aa | cancion_petrarquista, pareado×3 |

## 3 · Cobertura del contrato del registrador

Formas sin contrato editorial declarado (15): copla_castellana, copla_de_arte_menor, copla_manriquena, cuarteto_lira, decima_lira, novena_lira, octava_aguda, octava_lira, oncena, redondilla_enlazada, septeto, septeto_lira, septilla, septilla_enlazada, sextilla_enlazada.

---

Total de defectos detectados: 0.

