# Informe de conformidad del catálogo métrico

Generado: 2026-08-01 10:56

Inventario: 27 formas y 2 tramos sin forma · 49 configuraciones · 52 patrones métricos · 69 patrones de rima · 57 secciones · 59 grupos de elección · 359 opciones · 6 rasgos.

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

### D10 · Coherencia del tipo de registro — 0

> Un tramo sin forma no tiene arquitectura; toda forma con norma declara al menos una.

**Cambiado el 5 de agosto de 2026.** Esta comprobación miraba antes el grado de
especificación, que se retiró del catálogo: su propósito —ordenar las hipótesis del
demarcador— nunca se implementó, y la regla que lo usaba, «una forma general no puede ser
subtipo de una específica», no podía dispararse porque no hay ninguna relación `subtipo_de`.
La clasificación que queda es `nivel_estructural`, y el criterio que excluye a «Verso aislado»
y «Versificación irregular» de tener arquitectura es `tipo_registro = 'sin_forma'`, que es su
razón verdadera.

Sin incidencias.

### D11 · Sección que solo existe para repetir la unidad — 0

> Una sección describe el interior de la unidad. Que el pasaje contenga varias unidades se deriva del rango, no se declara como sección. Se exceptúan las series, donde la sección repetible describe el ritmo interno de la propia serie.

Sin incidencias.

### D12 · Pregunta estructural con alcance de secuencia — 0

> Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad.

Sin incidencias.

## 2 · Homogeneidad de criterio

### 2.1 · Dónde vive cada dimensión, forma por forma

| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |
| --- | --- | ---: | :-: | --- | --- | ---: | --- |
| cancion_petrarquista | composicion | 3 | sí | conjunto, eleccion, posiciones | esquema libre, patrón único, varios patrones sin pregunta | 4 | secuencia, unidad |
| copla_de_arte_mayor | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| copla_de_pie_quebrado ·gral | estrofa | 1 | sí | conjunto, eleccion | patrón único | 1 | unidad |
| copla_real | estrofa | 1 | sí | eleccion | elección, sin patrón | 3 | unidad |
| cuarteto | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| decima_aumentada | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| decima_espinela | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| endecasilabo_suelto | serie | 1 | sí | posiciones | patrón único | 2 | secuencia |
| endecha_real | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| novena | estrofa | 2 | sí | posiciones | elección, sin patrón | 4 | unidad |
| octava_real | estrofa | 1 | sí | posiciones | patrón único | 1 | secuencia |
| pareado | estrofa | 1 | sí | conjunto, eleccion | elección | 2 | unidad |
| quintilla | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| redondilla | estrofa | 4 | sí | configuracion, posiciones | elección, patrón único | 3 | unidad |
| romance | serie | 4 | sí | configuracion, posiciones | patrón único | 4 | secuencia |
| seguidilla | estrofa | 2 | sí | posiciones | patrón único | 0 | — |
| sexteto ·gral | estrofa | 3 | sí | configuracion, posiciones | esquema libre | 3 | unidad |
| sexteto_lira | estrofa | 1 | sí | posiciones | variedad | 2 | secuencia, unidad |
| sextilla | estrofa | 5 | sí | configuracion, posiciones | elección, patrón único | 1 | unidad |
| sextina | composicion | 2 | sí | posiciones | sin patrón | 0 | — |
| silva | serie | 4 | sí | configuracion, conjunto, posiciones | patrón único | 1 | secuencia |
| soneto | composicion | 1 | sí | posiciones | elección | 3 | secuencia, unidad |
| terceto | estrofa | 1 | sí | posiciones | elección | 2 | secuencia, unidad |
| terceto_encadenado | serie | 2 | sí | configuracion, posiciones | patrón único | 0 | — |
| villancico | composicion | 2 | sí | conjunto, eleccion | elección | 15 | unidad |
| zejel | composicion | 1 | sí | conjunto, eleccion | patrón único | 5 | unidad |

### 2.2 · Reparto de la medida

| Vía | Formas |
| --- | --- |
| configuracion (6) | redondilla, romance, sexteto, sextilla, silva, terceto_encadenado |
| conjunto (6) | cancion_petrarquista, copla_de_pie_quebrado, pareado, silva, villancico, zejel |
| eleccion (6) | cancion_petrarquista, copla_de_pie_quebrado, copla_real, pareado, villancico, zejel |
| posiciones (22) | cancion_petrarquista, copla_de_arte_mayor, cuarteto, decima_aumentada, decima_espinela, endecasilabo_suelto, endecha_real, lira, novena, octava_real, quintilla, redondilla, romance, seguidilla, sexteto, sexteto_lira, sextilla, sextina, silva, soneto, terceto, terceto_encadenado |

### 2.3 · Alcance de las preguntas por dimensión

| Dimensión · alcance | Formas |
| --- | --- |
| combinacion · unidad | sexteto_lira |
| metro · unidad | cancion_petrarquista, copla_de_pie_quebrado, copla_real, pareado, villancico, zejel |
| rasgo · secuencia | cancion_petrarquista, endecasilabo_suelto, octava_real, romance, sexteto_lira, silva, soneto, terceto |
| repeticion · unidad | villancico, zejel |
| rima · unidad | cancion_petrarquista, copla_de_arte_mayor, copla_real, cuarteto, novena, pareado, quintilla, redondilla, sexteto, sextilla, soneto, terceto, villancico |

### 2.4 · Ámbito declarado en los patrones de rima

| Ámbito | Total | Formas |
| --- | ---: | --- |
| seccion | 12 | cancion_petrarquista×4, soneto×4, villancico×4 |
| unidad | 57 | copla_de_arte_mayor×3, copla_de_pie_quebrado×1, cuarteto×2, decima_aumentada×1, decima_espinela×1, endecasilabo_suelto×1, endecha_real×1, lira×1, octava_real×1, pareado×2, quintilla×8, redondilla×7, romance×4, seguidilla×2, sexteto×4, sexteto_lira×3, sextilla×6, silva×4, terceto×2, terceto_encadenado×2, zejel×1 |

### 2.5 · Cómo se resuelve la rima que la norma no fija

| Configuración | Patrones abiertos | Estrategia |
| --- | ---: | --- |
| cancion_petrarquista · estancias_consonantes_variables | 1 | control abierto de esquema |
| sexteto · alejandrina | 1 | control abierto de esquema |
| sexteto · dodecasilabica | 1 | control abierto de esquema |
| sexteto · endecasilabica | 1 | control abierto de esquema |
| copla_de_pie_quebrado · octosilabica_con_quebrados | 1 | patrón vacío, sin sustituto |
| sextilla · doble_pie_quebrado | 1 | patrón vacío, sin sustituto |
| sextilla · heptasilabica | 1 | patrón vacío, sin sustituto |
| sextilla · hexasilabica | 1 | patrón vacío, sin sustituto |
| sextilla · octosilabica | 1 | patrón vacío, sin sustituto |
| sextilla · pie_quebrado | 1 | patrón vacío, sin sustituto |
| cancion_petrarquista · sin_rima_con_pareado_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · endecasilabica | 1 | restricciones cualitativas (1) |
| silva · consonante_irregular | 1 | restricciones cualitativas (1) |
| silva · endecasilabica | 1 | restricciones cualitativas (1) |
| silva · libre | 1 | restricciones cualitativas (1) |

### 2.6 · Esquemas que coinciden literalmente en varias formas

Coincidencia literal no implica error: puede tratarse de la misma disposición sobre metros distintos. Solo debe reutilizarse cuando una forma es componente de la otra (véase D8).

| Esquema | Formas |
| --- | --- |
| -a-a | endecha_real, seguidilla |
| abab | redondilla×3, villancico×2 |
| abba | redondilla×3, villancico×2 |

## 3 · Cobertura del contrato del registrador

Formas sin contrato editorial declarado (2): cuarteto, endecha_real.

---

Total de defectos detectados: 0.

