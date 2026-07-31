# Informe de conformidad del catálogo métrico

Generado: 2026-07-31 07:04

Inventario: 30 formas y 2 tramos sin forma · 53 configuraciones · 58 patrones métricos · 81 patrones de rima · 61 secciones · 42 grupos de elección · 294 opciones · 3 rasgos.

Criterios aplicados: [criterios-de-nivel.md](./criterios-de-nivel.md). El bloque 1 recoge incumplimientos que no dependen de una decisión editorial. El bloque 2 describe dónde vive cada dimensión para que las divergencias de criterio sean visibles.

## 1 · Defectos

### D1 · Configuración sin contenido normativo — 1

> Una configuración debe declarar al menos un patrón, una sección o una variedad.

| Sujeto | Detalle |
| --- | --- |
| pareado · principal | principal=true · demarcable=true |

### D2 · Patrón de rima sin contenido alguno — 8

> Un patrón debe aportar algo computable: esquema, posiciones o restricciones. Un patrón vacío no declara norma y solo ocupa un hueco en la interfaz. Se exceptúa fijeza=no_aplica, que afirma la ausencia de rima.

| Sujeto | Detalle |
| --- | --- |
| cancion_petrarquista · estancias_consonantes_variables | Esquema consonante repetido entre estancias · fijeza=libre |
| sexteto · arte_mayor_consonante_variable | Distribución consonante variable · fijeza=libre |
| sextilla · isometrica | Distribución variable · fijeza=libre |
| sextilla · pie_quebrado_884884 | Distribución variable · fijeza=libre |
| pareado · pareado_de_arte_menor | Patrón principal · fijeza=admitido |
| pareado · pareado_hexasilabo | Patrón principal · fijeza=admitido |
| pareado · pareado_octosilabo | Patrón principal · fijeza=admitido |
| copla_de_pie_quebrado · variable_5_12 | Distribución variable · fijeza=libre |

### D2b · Configuración sin ninguna declaración de rima ni de repetición — 3

> Toda configuración debe declarar cómo se comporta la rima: un patrón propio, una sección que lo aporte o lo reutilice, o un patrón de repetición que ocupe su lugar.

| Sujeto | Detalle |
| --- | --- |
| terceto · endecasilabico_consonante | 0 sección(es), sin patrón de rima accesible |
| pareado · principal | 0 sección(es), sin patrón de rima accesible |
| terceto_encadenado · octosilabico | 0 sección(es), sin patrón de rima accesible |

### D3 · Patrón métrico sin posiciones ni opciones — 0

> Un patrón métrico debe declarar posiciones ordenadas o un conjunto permitido.

Sin incidencias.

### D4 · La unidad declarada contradice la extensión que producen las secciones — 0

> La arquitectura declara cuántos versos tiene su unidad; sus secciones describen el interior de esa unidad y no pueden sumar otra cosa.

Sin incidencias.

### D5 · La opción distingue menos posiciones que el patrón al que apunta — 4

> El patrón debe modelar el nivel que la pregunta distingue; si la opción nombra un esquema más corto, la alternativa vive en un nivel inferior.

| Sujeto | Detalle |
| --- | --- |
| soneto · endecasilabo_consonante | esquema_tercetos · opción «CDEDCE» (6) apunta a «ABBAABBACDEDCE» (14), ámbito composicion |
| soneto · endecasilabo_consonante | esquema_tercetos · opción «CDCEDE» (6) apunta a «ABBAABBACDCEDE» (14), ámbito composicion |
| soneto · endecasilabo_consonante | esquema_tercetos · opción «CDECDE» (6) apunta a «ABBAABBACDECDE» (14), ámbito composicion |
| soneto · endecasilabo_consonante | esquema_tercetos · opción «CDCDCD» (6) apunta a «ABBAABBACDCDCD» (14), ámbito composicion |

### D6 · Slug de opción con UUID incrustado — 0

> Los slugs son identificadores estables y legibles; serán clave de comparación.

Sin incidencias.

### D7 · Rasgo booleano usado como vector de posiciones — 1

> Un rasgo describe una propiedad, no una posición. Una alternativa posicional pertenece al patrón métrico o a una opción de metro con posicion_unidad.

| Sujeto | Detalle |
| --- | --- |
| copla_de_pie_quebrado · variable_5_12 | posiciones_pies_quebrados repite el rasgo «pie_quebrado» (booleano) en 12 posiciones |

### D8 · Componente copiado en lugar de reutilizado — 1

> Cuando una forma declara `compuesta_por` o `subtipo_de` otra, sus secciones reutilizan la configuración del componente mediante arquitectura_referenciada_id. Copiar sus patrones obliga a mantener el repertorio en varios sitios y rompe la comparación.

| Sujeto | Detalle |
| --- | --- |
| quintilla / copla_real | 8 esquema(s) copiados: ababa, abbab, ababb, abbaa, aabba, aabab, abaab, abbba |

### D9 · Rasgo cualitativo almacenado como restricción de rima sin catalogar — 16

> Una propiedad transversal es un rasgo con modalidad declarada, no un literal libre colgado de un patrón.

| Sujeto | Detalle |
| --- | --- |
| pareados_no_sistematicos | 2 forma(s): endecasilabo_suelto, silva |
| predominio_versos_rimados | 2 forma(s): pareados_endecasilabos, silva |
| distico_final | 1 forma(s): endecasilabo_suelto |
| distinto_de_abcabc_defdef | 1 forma(s): doble_sextilla |
| encadenamiento_final_interior | 1 forma(s): endecasilabo_suelto |
| enlace_vuelta | 1 forma(s): villancico |
| mudanza_monorrima_y_vuelta_al_estribillo | 1 forma(s): zejel |
| pareados_habituales | 1 forma(s): silva |
| pareados_intercalados_ocasionales | 1 forma(s): endecasilabo_suelto |
| pareados_predominantes | 1 forma(s): silva |
| pareados_sistematicos | 1 forma(s): pareados_endecasilabos |
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

### D12 · Pregunta estructural con alcance de secuencia — 5

> Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad.

| Sujeto | Detalle |
| --- | --- |
| sextilla · isometrica | medida_comun · dimensión metro · 3 opciones |
| villancico · estribillo_inicial | medidas_realizadas · dimensión metro · 2 opciones |
| villancico · estribillo_tras_primera_copla | medidas_realizadas · dimensión metro · 2 opciones |
| zejel · estribillo_y_coplas_monorrimas | medidas_realizadas · dimensión metro · 2 opciones |
| copla_de_arte_mayor · ocho_dodecasilabos_compuestos | esquema_rima · dimensión rima · 3 opciones |

## 2 · Homogeneidad de criterio

### 2.1 · Dónde vive cada dimensión, forma por forma

| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |
| --- | --- | ---: | :-: | --- | --- | ---: | --- |
| cancion_petrarquista | composicion | 3 | — | conjunto, eleccion, posiciones | esquema libre, patrón único, varios patrones sin pregunta | 4 | secuencia, unidad |
| copla_de_arte_mayor | estrofa | 1 | sí | posiciones | elección | 1 | secuencia |
| copla_de_pie_quebrado ·gral | estrofa | 1 | sí | conjunto, eleccion | patrón único | 2 | unidad |
| copla_manriqueña | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| copla_real | estrofa | 2 | sí | configuracion, conjunto, eleccion, posiciones | elección | 5 | unidad |
| decima_aumentada | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| decima_espinela | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| doble_sextilla | estrofa | 1 | sí | posiciones | cualitativa, patrón único | 0 | — |
| endecasilabo_suelto | serie | 5 | — | posiciones | cualitativa, patrón único | 0 | — |
| lira | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| novena | estrofa | 2 | sí | posiciones | elección, sin patrón | 4 | unidad |
| octava_real | estrofa | 1 | sí | posiciones | patrón único | 1 | secuencia |
| pareado | estrofa | 4 | sí | configuracion, conjunto | patrón único, sin patrón | 0 | — |
| pareados_endecasilabos | serie | 1 | sí | posiciones | cualitativa, patrón único | 0 | — |
| quintilla | estrofa | 1 | sí | posiciones | elección | 1 | unidad |
| redondilla | estrofa | 2 | sí | configuracion, eleccion, posiciones | elección, patrón único | 2 | unidad |
| romance | serie | 4 | sí | configuracion, posiciones | patrón único | 4 | secuencia |
| seguidilla | estrofa | 2 | sí | posiciones | patrón único | 0 | — |
| sexta_rima | estrofa | 1 | sí | posiciones | patrón único | 0 | — |
| sexteto ·gral | estrofa | 1 | sí | conjunto, eleccion | esquema libre | 2 | unidad |
| sexteto_lira | estrofa | 1 | sí | posiciones | variedad | 2 | secuencia, unidad |
| sextilla | estrofa | 2 | sí | configuracion, conjunto, eleccion, posiciones | patrón único | 1 | secuencia |
| sextina | composicion | 2 | sí | posiciones | sin patrón | 0 | — |
| silva | serie | 4 | — | configuracion, conjunto, posiciones | cualitativa, patrón único | 0 | — |
| soneto | composicion | 1 | sí | posiciones | elección | 2 | secuencia, unidad |
| terceto | estrofa | 1 | sí | posiciones | sin patrón | 1 | secuencia |
| terceto_encadenado | serie | 2 | sí | configuracion, posiciones | patrón único, sin patrón | 0 | — |
| tercetos_sin_encadenar | serie | 1 | sí | posiciones | elección | 1 | secuencia |
| villancico | composicion | 2 | sí | conjunto, eleccion | cualitativa, elección | 7 | secuencia, unidad |
| zejel | composicion | 1 | sí | conjunto, eleccion | cualitativa, patrón único | 2 | secuencia, unidad |

### 2.2 · Reparto de la medida

| Vía | Formas |
| --- | --- |
| configuracion (7) | copla_real, pareado, redondilla, romance, sextilla, silva, terceto_encadenado |
| conjunto (9) | cancion_petrarquista, copla_de_pie_quebrado, copla_real, pareado, sexteto, sextilla, silva, villancico, zejel |
| eleccion (8) | cancion_petrarquista, copla_de_pie_quebrado, copla_real, redondilla, sexteto, sextilla, villancico, zejel |
| posiciones (25) | cancion_petrarquista, copla_de_arte_mayor, copla_manriqueña, copla_real, decima_aumentada, decima_espinela, doble_sextilla, endecasilabo_suelto, lira, novena, octava_real, pareados_endecasilabos, quintilla, redondilla, romance, seguidilla, sexta_rima, sexteto_lira, sextilla, sextina, silva, soneto, terceto, terceto_encadenado, tercetos_sin_encadenar |

### 2.3 · Alcance de las preguntas por dimensión

| Dimensión · alcance | Formas |
| --- | --- |
| combinacion · unidad | sexteto_lira |
| metro · secuencia | sextilla, villancico, zejel |
| metro · unidad | cancion_petrarquista, copla_de_pie_quebrado, copla_real, redondilla, sexteto |
| rasgo · secuencia | cancion_petrarquista, octava_real, romance, sexteto_lira, soneto, terceto |
| rasgo · unidad | copla_de_pie_quebrado |
| repeticion · unidad | villancico, zejel |
| rima · secuencia | copla_de_arte_mayor, tercetos_sin_encadenar |
| rima · unidad | cancion_petrarquista, copla_real, novena, quintilla, redondilla, sexteto, soneto, villancico |

### 2.4 · Ámbito declarado en los patrones de rima

| Ámbito | Total | Formas |
| --- | ---: | --- |
| composicion | 7 | soneto×4, villancico×2, zejel×1 |
| estrofa | 32 | cancion_petrarquista×2, copla_de_arte_mayor×3, copla_de_pie_quebrado×1, copla_manriqueña×1, decima_aumentada×1, decima_espinela×1, doble_sextilla×1, lira×1, octava_real×1, quintilla×8, redondilla×3, seguidilla×2, sexta_rima×1, sexteto×1, sexteto_lira×3, sextilla×2 |
| seccion | 22 | cancion_petrarquista×2, copla_real×16, villancico×4 |
| serie | 17 | endecasilabo_suelto×5, pareados_endecasilabos×1, romance×4, silva×4, terceto_encadenado×1, tercetos_sin_encadenar×2 |
| unidad | 3 | pareado×3 |

### 2.5 · Cómo se resuelve la rima que la norma no fija

| Configuración | Patrones abiertos | Estrategia |
| --- | ---: | --- |
| cancion_petrarquista · estancias_consonantes_variables | 1 | control abierto de esquema |
| sexteto · arte_mayor_consonante_variable | 1 | control abierto de esquema |
| copla_de_pie_quebrado · variable_5_12 | 1 | patrón vacío, sin sustituto |
| pareado · pareado_de_arte_menor | 1 | patrón vacío, sin sustituto |
| pareado · pareado_hexasilabo | 1 | patrón vacío, sin sustituto |
| pareado · pareado_octosilabo | 1 | patrón vacío, sin sustituto |
| sextilla · isometrica | 1 | patrón vacío, sin sustituto |
| sextilla · pie_quebrado_884884 | 1 | patrón vacío, sin sustituto |
| endecasilabo_suelto · con_pareados_sin_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · con_pareados_y_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · encadenado_interior | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · puro_con_distico_final | 1 | restricciones cualitativas (1) |
| endecasilabo_suelto · puro_sin_distico_final | 1 | restricciones cualitativas (1) |
| silva · consonantes_irregular | 1 | restricciones cualitativas (1) |
| silva · endecasilabica | 1 | restricciones cualitativas (1) |
| silva · libre | 1 | restricciones cualitativas (1) |
| villancico · estribillo_inicial | 1 | restricciones cualitativas (1) |
| villancico · estribillo_tras_primera_copla | 1 | restricciones cualitativas (1) |

### 2.6 · Esquemas que coinciden literalmente en varias formas

Coincidencia literal no implica error: puede tratarse de la misma disposición sobre metros distintos. Solo debe reutilizarse cuando una forma es componente de la otra (véase D8).

| Esquema | Formas |
| --- | --- |
| aabab | copla_real×2, quintilla |
| aabba | copla_real×2, quintilla |
| abaab | copla_real×2, quintilla |
| abab | redondilla, villancico×2 |
| ababa | copla_real×2, quintilla |
| ababb | copla_real×2, quintilla |
| abba | redondilla, villancico×2 |
| abbaa | copla_real×2, quintilla |
| abbab | copla_real×2, quintilla |
| abbba | copla_real×2, quintilla |

## 3 · Cobertura del contrato del registrador

Todas las formas aparecen en el contrato del registrador.

---

Total de defectos detectados: 39.

