# Informe de conformidad del catálogo métrico

Generado: 2026-09-21 08:55

Inventario: 47 formas y 2 tramos sin forma · 97 configuraciones · 99 patrones métricos · 167 patrones de rima · 80 secciones · 136 grupos de elección · 1040 opciones · 7 rasgos.

Criterios aplicados: [criterios-de-nivel.md](./criterios-de-nivel.md). El bloque 1 recoge incumplimientos que no dependen de una decisión editorial. El bloque 2 describe dónde vive cada dimensión para que las divergencias de criterio sean visibles.

## 1 · Defectos

### D1 · Configuración sin contenido normativo — 0

> Una configuración debe declarar al menos un patrón, una sección o una variedad. No alcanza a los tramos sin forma, cuya arquitectura existe para colgar preguntas y no para declarar norma: lo suyo lo miran D10 y D19.

Sin incidencias.

### D2 · Patrón de rima sin contenido alguno — 0

> Un esquema debe aportar algo computable: notación, posiciones o restricciones. Un esquema vacío no declara norma y solo ocupa un hueco en la interfaz. Se exceptúa el de tipo abierta con un tipo de rima declarado: afirma que la norma exige ese tipo y deja libre la disposición, como corresponde a una forma general.

Sin incidencias.

### D2b · Configuración sin ninguna declaración de rima ni de repetición — 0

> Toda configuración debe declarar cómo se comporta la rima: un patrón propio, una sección que lo aporte o lo reutilice, o un patrón de repetición que ocupe su lugar. Salvo los tramos sin forma, que no declaran ninguna: la rima que se vea en ellos se escribe al anotar.

Sin incidencias.

### D3 · Patrón métrico sin posiciones ni opciones — 0

> Un patrón métrico debe declarar posiciones ordenadas o un conjunto permitido.

Sin incidencias.

### D4 · La extensión de la unidad no se declara ni se puede derivar — 0

> Una arquitectura declara cuántos versos tiene su unidad, y entonces sus secciones no pueden sumar otra cosa; o la deja sin declarar, y entonces tiene que haber secciones de las que derivarla. Lo que no puede es no decirlo por ninguna de las dos vías. Quedan fuera las series y los tramos sin forma, que no tienen unidad.

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

> Un tramo sin forma puede tener arquitecturas, porque de ellas cuelgan sus preguntas, pero ninguna declara norma. Y la taxonomía va en una sola dirección: lo específico es subtipo de lo general, nunca al revés.

Sin incidencias.

### D11 · Sección que solo existe para repetir la unidad — 0

> Una sección describe el interior de la unidad. Que el pasaje contenga varias unidades se deriva del rango, no se declara como sección. Se exceptúan las series, donde la sección repetible describe el ritmo interno de la propia serie.

Sin incidencias.

### D12 · Pregunta estructural con alcance de secuencia — 0

> Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad. Tampoco en los tramos sin forma, donde no hay unidad ninguna y el alcance de secuencia es el único que cabe.

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

> Regla 1 de criterios de nivel § 3.3: donde hay unidad y la norma no fija una sola disposición, el editor tiene que poder decir cuál leyó. Se cumple de cuatro maneras y basta una: la arquitectura pregunta su rima; la resuelve una variedad, que empareja esquema métrico y de rima; toda su rima vive en secciones que reutilizan otras arquitecturas y la heredan; o la norma la fija con un único esquema **definitorio**. Un único esquema marcado «habitual» o «admitida» no exime: decir que suele ser ese es decir que hay otros. Las series y los tramos sin forma quedan fuera porque no tienen unidad: su rima se describe por rasgos del pasaje o se escribe al anotar.

Sin incidencias.

### D18 · Una unidad cuya medida no está fija y nadie pregunta — 0

> El mismo principio que D17, en la otra dimensión: donde la norma admite varias medidas y no dice cuál va en cada verso, el editor tiene que poder decir cuál leyó. Exime que la arquitectura pregunte su metro, que lo resuelva una variedad —que empareja esquema métrico y de rima—, o que su estructura reutilice otras arquitecturas. Las series y los tramos sin forma quedan fuera porque no tienen unidad. Una arquitectura cuyo esquema métrico fija cada posición no entra: ahí la medida no varía, y lo que se salga de ella es una desviación.

Sin incidencias.

### D19 · Un tramo sin forma que no registra lo que se ve — 0

> El envés de D10. Un tramo sin forma no declara norma —eso lo comprueba D10— pero **tiene que registrar la observación**: cada una de sus arquitecturas pregunta al menos una cosa, y la pregunta es de respuesta escrita. Una lista cerrada de opciones sería declarar norma por la puerta de atrás, ofreciendo un repertorio donde se dijo que no se reconoce ninguno. Sin este criterio, eximir a los tramos de D1, D2b, D4, D12, D17 y D18 los dejaría sin auditar por ningún lado.

Sin incidencias.

## 2 · Homogeneidad de criterio

### 2.1 · Dónde vive cada dimensión, forma por forma

| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |
| --- | --- | ---: | :-: | --- | --- | ---: | --- |
| cancion | composicion | 1 | sí | conjunto, eleccion | esquema libre | 4 | unidad |
| cancion_petrarquista | composicion | 1 | sí | conjunto, eleccion, posiciones | esquema libre | 2 | unidad |
| cancion_sin_rima | composicion | 1 | sí | conjunto, eleccion | varios patrones sin pregunta | 3 | secuencia, unidad |
| copla_castellana | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| copla_de_arte_mayor | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| copla_de_arte_menor | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| copla_manriquena | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| copla_real | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección, sin patrón | 3 | unidad |
| cuarteto | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| cuarteto_lira | estrofa | 1 | sí | conjunto, eleccion | elección | 2 | unidad |
| decima | estrofa | 6 | sí | configuracion, posiciones | patrón único | 0 | — |
| decima_lira | estrofa | 1 | sí | conjunto, eleccion | elección | 2 | unidad |
| endecasilabo_encadenado | serie | 1 | sí | posiciones | cualitativa, patrón único | 2 | secuencia |
| endecasilabo_suelto | serie | 1 | sí | posiciones | patrón único | 4 | secuencia |
| endecha_real | serie | 3 | sí | configuracion, posiciones | elección, patrón único | 4 | secuencia |
| estrofa_safica | estrofa | 2 | sí | configuracion, posiciones | elección, patrón único | 1 | unidad |
| lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| novena | estrofa | 2 | sí | configuracion, conjunto, eleccion, posiciones | elección, sin patrón | 5 | unidad |
| novena_lira | estrofa | 1 | sí | conjunto, eleccion | elección | 2 | unidad |
| octava_aguda | estrofa | 6 | sí | configuracion, posiciones | elección | 12 | secuencia, unidad |
| octava_lira | estrofa | 1 | sí | conjunto, eleccion | elección | 2 | unidad |
| octava_real | estrofa | 1 | sí | posiciones | elección | 2 | secuencia, unidad |
| oncena | estrofa | 2 | sí | conjunto, eleccion, posiciones | sin patrón | 2 | unidad |
| pareado | estrofa | 2 | sí | configuracion, conjunto, eleccion | elección, patrón único | 4 | secuencia, unidad |
| quintilla | estrofa | 3 | sí | configuracion, conjunto, eleccion, posiciones | elección | 4 | unidad |
| redondilla | estrofa | 3 | sí | configuracion, conjunto, eleccion, posiciones | elección | 4 | unidad |
| redondilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| romance | serie | 1 | sí | posiciones | patrón único | 1 | secuencia |
| romance_heroico | serie | 1 | sí | posiciones | patrón único | 1 | secuencia |
| romancillo | serie | 4 | sí | configuracion, posiciones | patrón único | 4 | secuencia |
| seguidilla | estrofa | 7 | sí | configuracion, eleccion, posiciones | patrón único | 8 | secuencia, unidad |
| septeto | estrofa | 2 | sí | posiciones | esquema libre, patrón único | 3 | secuencia, unidad |
| septeto_lira | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| septilla | estrofa | 1 | sí | conjunto, eleccion, posiciones | elección | 2 | unidad |
| septilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| sexteto | estrofa | 3 | sí | configuracion, posiciones | elección, esquema libre | 4 | secuencia, unidad |
| sexteto_lira | estrofa | 1 | sí | posiciones | variedad | 2 | secuencia, unidad |
| sextilla | estrofa | 6 | sí | configuracion, conjunto, eleccion, posiciones | elección, esquema libre | 7 | unidad |
| sextilla_enlazada | serie | 1 | sí | posiciones | patrón único | 0 | — |
| sextina | composicion | 3 | sí | posiciones | sin patrón | 0 | — |
| sextina_estrofa | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| silva | serie | 5 | sí | configuracion, conjunto, posiciones | patrón único | 4 | secuencia |
| soneto | composicion | 1 | sí | posiciones | elección | 3 | secuencia, unidad |
| terceto | estrofa | 3 | sí | configuracion, posiciones | elección | 6 | secuencia, unidad |
| terceto_encadenado | serie | 2 | sí | configuracion, posiciones | patrón único | 0 | — |
| villancico | composicion | 1 | sí | conjunto, eleccion | elección | 7 | realizacion, secuencia, unidad |
| zejel | composicion | 1 | sí | conjunto, eleccion | patrón único | 4 | realizacion, unidad |

### 2.2 · Reparto de la medida

| Vía | Formas |
| --- | --- |
| configuracion (15) | decima, endecha_real, estrofa_safica, novena, octava_aguda, pareado, quintilla, redondilla, romancillo, seguidilla, sexteto, sextilla, silva, terceto, terceto_encadenado |
| conjunto (21) | cancion, cancion_petrarquista, cancion_sin_rima, copla_castellana, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto_lira, decima_lira, novena, novena_lira, octava_lira, oncena, pareado, quintilla, redondilla, septilla, sextilla, silva, villancico, zejel |
| eleccion (21) | cancion, cancion_petrarquista, cancion_sin_rima, copla_castellana, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto_lira, decima_lira, novena, novena_lira, octava_lira, oncena, pareado, quintilla, redondilla, seguidilla, septilla, sextilla, villancico, zejel |
| posiciones (38) | cancion_petrarquista, copla_castellana, copla_de_arte_mayor, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto, decima, endecasilabo_encadenado, endecasilabo_suelto, endecha_real, estrofa_safica, lira, novena, octava_aguda, octava_real, oncena, quintilla, redondilla, redondilla_enlazada, romance, romance_heroico, romancillo, seguidilla, septeto, septeto_lira, septilla, septilla_enlazada, sexteto, sexteto_lira, sextilla, sextilla_enlazada, sextina, sextina_estrofa, silva, soneto, terceto, terceto_encadenado |

### 2.3 · Alcance de las preguntas por dimensión

| Dimensión · alcance | Formas |
| --- | --- |
| combinacion · unidad | sexteto_lira |
| metro · secuencia | irregular, verso_aislado |
| metro · unidad | cancion, cancion_petrarquista, cancion_sin_rima, copla_castellana, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto_lira, decima_lira, novena, novena_lira, octava_lira, oncena, pareado, quintilla, redondilla, seguidilla, septilla, sextilla, villancico, zejel |
| rasgo · secuencia | cancion_sin_rima, endecasilabo_encadenado, endecasilabo_suelto, endecha_real, octava_aguda, octava_real, pareado, romance, romance_heroico, romancillo, seguidilla, septeto, sexteto, sexteto_lira, silva, soneto, terceto, villancico |
| repeticion · realizacion | villancico, zejel |
| rima · secuencia | endecha_real, irregular |
| rima · unidad | cancion, cancion_petrarquista, copla_castellana, copla_de_arte_mayor, copla_de_arte_menor, copla_manriquena, copla_real, cuarteto, cuarteto_lira, decima_lira, estrofa_safica, novena, novena_lira, octava_aguda, octava_lira, octava_real, pareado, quintilla, redondilla, septeto, septeto_lira, septilla, sexteto, sextilla, soneto, terceto, villancico |

### 2.4 · Ámbito declarado en los patrones de rima

| Ámbito | Total | Formas |
| --- | ---: | --- |
| undefined | 167 | cancion×1, cancion_petrarquista×1, cancion_sin_rima×2, copla_castellana×4, copla_de_arte_mayor×4, copla_de_arte_menor×3, copla_manriquena×2, cuarteto×2, cuarteto_lira×2, decima×6, decima_lira×1, endecasilabo_encadenado×1, endecasilabo_suelto×1, endecha_real×7, estrofa_safica×3, lira×1, novena_lira×1, octava_aguda×12, octava_lira×2, octava_real×2, pareado×3, quintilla×27, redondilla×6, redondilla_enlazada×1, romance×1, romance_heroico×1, romancillo×4, seguidilla×7, septeto×2, septeto_lira×1, septilla×5, septilla_enlazada×1, sexteto×5, sexteto_lira×3, sextilla×13, sextilla_enlazada×1, sextina_estrofa×1, silva×5, soneto×6, terceto×10, terceto_encadenado×2, villancico×3, zejel×1 |

### 2.5 · Cómo se resuelve la rima que la norma no fija

| Configuración | Patrones abiertos | Estrategia |
| --- | ---: | --- |
| sexteto · dodecasilabica | 1 | control abierto de esquema |
| sextilla · heptasilabica | 1 | control abierto de esquema |
| sextilla · hexasilabica | 1 | control abierto de esquema |
| sextilla · pentasilabica | 1 | control abierto de esquema |
| sextilla · tetrasilabica | 1 | control abierto de esquema |
| cancion · estancias_consonantes_variables | 1 | control abierto de esquema + restricciones cualitativas (1) |
| septeto · endecasilabica | 1 | control abierto de esquema + restricciones cualitativas (1) |
| novena_lira · heterometrica_consonante | 1 | patrón vacío, sin sustituto |
| octava_real · endecasilabica_consonante | 1 | patrón vacío, sin sustituto |
| septeto · compuesta | 1 | patrón vacío, sin sustituto |
| sexteto · alejandrina | 1 | patrón vacío, sin sustituto |
| sexteto · endecasilabica | 1 | patrón vacío, sin sustituto |
| sextilla · octosilabica | 1 | patrón vacío, sin sustituto |
| sextilla · pie_quebrado | 1 | patrón vacío, sin sustituto |
| cancion_sin_rima · sin_rima_con_pareado_final | 1 | restricciones cualitativas (1) |
| copla_manriquena · doble_pie_quebrado | 1 | restricciones cualitativas (1) |
| endecasilabo_encadenado · endecasilabica | 1 | restricciones cualitativas (1) |
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
| [-a]… | romance, romancillo×4, silva |
| abab | cuarteto_lira, redondilla×3, villancico |
| abba | cuarteto_lira, redondilla×3, villancico |
| -a-a | seguidilla×3, villancico |
| a-a | seguidilla, terceto×2 |
| aa | cancion_sin_rima, pareado×3 |

---

Total de defectos detectados: 0.

