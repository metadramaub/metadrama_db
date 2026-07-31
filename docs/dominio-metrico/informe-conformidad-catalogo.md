# Informe de conformidad del catálogo métrico

Generado: 2026-07-31 17:22

Inventario: 25 formas y 2 tramos sin forma · 52 configuraciones · 56 patrones métricos · 72 patrones de rima · 55 secciones · 43 grupos de elección · 324 opciones · 3 rasgos.

Criterios aplicados: [criterios-de-nivel.md](./criterios-de-nivel.md). El bloque 1 recoge incumplimientos que no dependen de una decisión editorial. El bloque 2 describe dónde vive cada dimensión para que las divergencias de criterio sean visibles.

## 1 · Defectos

### D1 · Configuración sin contenido normativo — 0

> Una configuración debe declarar al menos un patrón, una sección o una variedad.

Sin incidencias.

### D2 · Patrón de rima sin contenido alguno — 0

> Un patrón debe aportar algo computable: esquema, posiciones o restricciones. Un patrón vacío no declara norma y solo ocupa un hueco en la interfaz. Se exceptúan dos casos que sí la declaran: fijeza=no_aplica, que afirma la ausencia de rima, y fijeza=libre con un tipo de rima declarado, que afirma que la norma exige ese tipo y deja abierta la disposición, como corresponde a una forma general.

Sin incidencias.

### D2b · Configuración sin ninguna declaración de rima ni de repetición — 1

> Toda configuración debe declarar cómo se comporta la rima: un patrón propio, una sección que lo aporte o lo reutilice, o un patrón de repetición que ocupe su lugar.

| Sujeto | Detalle |
| --- | --- |
| terceto_encadenado · octosilabico | 0 sección(es), sin patrón de rima accesible |

### D3 · Patrón métrico sin posiciones ni opciones — 0

> Un patrón métrico debe declarar posiciones ordenadas o un conjunto permitido.

Sin incidencias.

### D4 · La unidad declarada contradice la extensión que producen las secciones — 0

> La arquitectura declara cuántos versos tiene su unidad; sus secciones describen el interior de esa unidad y no pueden sumar otra cosa.

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

### D9 · Rasgo cualitativo almacenado como restricción de rima sin catalogar — 15

> Una propiedad transversal es un rasgo con modalidad declarada, no un literal libre colgado de un patrón.

| Sujeto | Detalle |
| --- | --- |
| pareados_no_sistematicos | 2 forma(s): endecasilabo_suelto, silva |
| predominio_versos_rimados | 2 forma(s): pareado, silva |
| distico_final | 1 forma(s): endecasilabo_suelto |
| encadenamiento_final_interior | 1 forma(s): endecasilabo_suelto |
| enlace_vuelta | 1 forma(s): villancico |
| mudanza_monorrima_y_vuelta_al_estribillo | 1 forma(s): zejel |
| pareados_habituales | 1 forma(s): silva |
| pareados_intercalados_ocasionales | 1 forma(s): endecasilabo_suelto |
| pareados_predominantes | 1 forma(s): silva |
| pareados_sistematicos | 1 forma(s): pareado |
| predominio_versos_sueltos | 1 forma(s): endecasilabo_suelto |
| rima_minoritaria | 1 forma(s): endecasilabo_suelto |
| sin_distico_final | 1 forma(s): endecasilabo_suelto |
| sin_organizacion_normativa_en_pareados | 1 forma(s): silva |
| sin_pareados_intercalados | 1 forma(s): endecasilabo_suelto |

### D10 · Coherencia del tipo de registro y del grado de especificación — 0

> Un tramo sin forma no tiene arquitectura. Y la taxonomía va en una sola dirección: lo específico es subtipo de lo general, nunca al revés.

Sin incidencias.

### D11 · Sección que solo existe para repetir la unidad — 0

> Una sección describe el interior de la unidad. Que el pasaje contenga varias unidades se deriva del rango, no se declara como sección. Se exceptúan las series, donde la sección repetible describe el ritmo interno de la propia serie.

Sin incidencias.

### D12 · Pregunta estructural con alcance de secuencia — 4

> Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad.

| Sujeto | Detalle |
| --- | --- |
| villancico · estribillo_inicial | medidas_realizadas · dimensión metro · 2 opciones |
| villancico · estribillo_tras_primera_copla | medidas_realizadas · dimensión metro · 2 opciones |
| zejel · estribillo_y_coplas_monorrimas | medidas_realizadas · dimensión metro · 2 opciones |
| copla_de_arte_mayor · dodecasilabica_compuesta | esquema_rima · dimensión rima · 3 opciones |

## 2 · Homogeneidad de criterio

### 2.1 · Dónde vive cada dimensión, forma por forma

| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |
| --- | --- | ---: | :-: | --- | --- | ---: | --- |
| cancion_petrarquista | composicion | 3 | — | conjunto, eleccion, posiciones | esquema libre, patrón único, varios patrones sin pregunta | 4 | secuencia, unidad |
| copla_de_arte_mayor | estrofa | 1 | sí | posiciones | elección | 1 | secuencia |
| copla_de_pie_quebrado ·gral | estrofa | 1 | sí | conjunto, eleccion | patrón único | 1 | unidad |
| copla_real | estrofa | 1 | sí | eleccion, posiciones | elección, sin patrón | 3 | unidad |
| decima_aumentada | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| decima_espinela | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| endecasilabo_suelto | serie | 5 | — | posiciones | cualitativa, patrón único | 0 | — |
| lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| novena | estrofa | 2 | sí | posiciones | elección, sin patrón | 4 | unidad |
| octava_real | estrofa | 1 | sí | posiciones | patrón único | 1 | secuencia |
| pareado | estrofa | 2 | sí | configuracion, conjunto, eleccion | cualitativa, patrón único | 2 | unidad |
| quintilla | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| redondilla | estrofa | 4 | sí | configuracion, posiciones | elección, patrón único | 3 | unidad |
| romance | serie | 4 | sí | configuracion, posiciones | patrón único | 4 | secuencia |
| seguidilla | estrofa | 2 | sí | posiciones | patrón único | 0 | — |
| sexteto ·gral | estrofa | 3 | sí | configuracion, posiciones | esquema libre | 3 | unidad |
| sexteto_lira | estrofa | 1 | sí | posiciones | variedad | 2 | secuencia, unidad |
| sextilla | estrofa | 5 | sí | configuracion, posiciones | elección, patrón único | 1 | unidad |
| sextina | composicion | 2 | sí | posiciones | sin patrón | 0 | — |
| silva | serie | 4 | — | configuracion, conjunto, posiciones | cualitativa, patrón único | 0 | — |
| soneto | composicion | 1 | sí | posiciones | elección | 2 | secuencia, unidad |
| terceto | estrofa | 1 | sí | posiciones | elección | 2 | secuencia, unidad |
| terceto_encadenado | serie | 2 | sí | configuracion, posiciones | patrón único, sin patrón | 0 | — |
| villancico | composicion | 2 | sí | conjunto, eleccion | cualitativa, elección | 7 | secuencia, unidad |
| zejel | composicion | 1 | sí | conjunto, eleccion | cualitativa, patrón único | 2 | secuencia, unidad |

### 2.2 · Reparto de la medida

| Vía | Formas |
| --- | --- |
| configuracion (7) | pareado, redondilla, romance, sexteto, sextilla, silva, terceto_encadenado |
| conjunto (6) | cancion_petrarquista, copla_de_pie_quebrado, pareado, silva, villancico, zejel |
| eleccion (6) | cancion_petrarquista, copla_de_pie_quebrado, copla_real, pareado, villancico, zejel |
| posiciones (21) | cancion_petrarquista, copla_de_arte_mayor, copla_real, decima_aumentada, decima_espinela, endecasilabo_suelto, lira, novena, octava_real, quintilla, redondilla, romance, seguidilla, sexteto, sexteto_lira, sextilla, sextina, silva, soneto, terceto, terceto_encadenado |

### 2.3 · Alcance de las preguntas por dimensión

| Dimensión · alcance | Formas |
| --- | --- |
| combinacion · unidad | sexteto_lira |
| metro · secuencia | villancico, zejel |
| metro · unidad | cancion_petrarquista, copla_de_pie_quebrado, copla_real, pareado |
| rasgo · secuencia | cancion_petrarquista, octava_real, romance, sexteto_lira, soneto, terceto |
| repeticion · unidad | villancico, zejel |
| rima · secuencia | copla_de_arte_mayor |
| rima · unidad | cancion_petrarquista, copla_real, novena, quintilla, redondilla, sexteto, sextilla, soneto, terceto, villancico |

### 2.4 · Ámbito declarado en los patrones de rima

| Ámbito | Total | Formas |
| --- | ---: | --- |
| composicion | 3 | villancico×2, zejel×1 |
| estrofa | 44 | cancion_petrarquista×2, copla_de_arte_mayor×3, copla_de_pie_quebrado×1, decima_aumentada×1, decima_espinela×1, lira×1, octava_real×1, pareado×2, quintilla×8, redondilla×7, seguidilla×2, sexteto×4, sexteto_lira×3, sextilla×6, terceto×2 |
| seccion | 11 | cancion_petrarquista×2, soneto×5, villancico×4 |
| serie | 14 | endecasilabo_suelto×5, romance×4, silva×4, terceto_encadenado×1 |

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
| endecasilabo_suelto · con_pareados_con_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · con_pareados_sin_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · encadenado_interior | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · puro_con_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · puro_sin_distico_final | 1 | restricciones cualitativas (1) |
| silva · consonante_irregular | 1 | restricciones cualitativas (1) |
| silva · endecasilabica | 1 | restricciones cualitativas (1) |
| silva · libre | 1 | restricciones cualitativas (1) |
| villancico · estribillo_inicial | 1 | restricciones cualitativas (1) |
| villancico · estribillo_tras_primera_copla | 1 | restricciones cualitativas (1) |

### 2.6 · Esquemas que coinciden literalmente en varias formas

Coincidencia literal no implica error: puede tratarse de la misma disposición sobre metros distintos. Solo debe reutilizarse cuando una forma es componente de la otra (véase D8).

| Esquema | Formas |
| --- | --- |
| AA | cancion_petrarquista, pareado |
| abab | redondilla×3, villancico×2 |
| abba | redondilla×3, villancico×2 |

## 3 · Cobertura del contrato del registrador

Todas las formas aparecen en el contrato del registrador.

---

Total de defectos detectados: 20.

