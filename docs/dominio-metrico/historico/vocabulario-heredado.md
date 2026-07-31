# El vocabulario métrico heredado

Estado: **registro histórico** · 31 de julio de 2026

Este documento conserva el vocabulario métrico anterior tal como estaba —sus términos,
definiciones, rasgos y jerarquía de subtipos— junto a dónde ha ido a parar cada uno en el
catálogo nuevo. Existe para poder responder dos preguntas sin volver a la base:

1. ¿Se ha perdido información al migrar?
2. ¿Hemos colocado como arquitectura algo que en realidad era una forma, o al revés?

No es una lista de tareas ni una matriz de revisión: es la fotografía del punto de
partida. La pestaña de trazabilidad de importación que lo mostraba en el panel se retira,
porque desde la importación las decisiones han cambiado tanto que sus pendientes ya no
describen nada actual.

> **`vocabularios` sigue vivo y no se toca.** Las secuencias métricas ya registradas en las
> obras siguen apuntando a estos términos. Lo que se retira es la matriz de importación,
> no el vocabulario.

## Inventario

119 términos de categoría `estrofa_tipo`: 31 raíces y 88 subtipos.

## Término por término

### Canción petrarquista

| | |
| --- | --- |
| Término | `cancion_petrarquista` |
| Etiqueta | Canción petrarquista |
| Tipo de forma | forma_italiana |
| Arte métrico | mixto |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 7, 11 sílabas |
| **Destino actual** | **forma** `cancion_petrarquista` |
| Propuesta de importación | F · certeza alta |

> La canción (canzone) es una estructura métrica de origen italiano compuesta por una serie de estrofas de extensión variable, generalmente entre los cinco y los veinte versos, que habitualmente combinan heptasílabos y endecasílabos. Excepto la "canción sin rima", el rasgo más distintivo de la canción petrarquista es el mantenimiento de un esquema de rima fijo y complejo que se repite idénticamente en cada una de las estrofas de un mismo pasaje, otorgando una arquitectura sonora muy estable a la composición. El modelo más frecuente consta de 13 versos organizados en dos secciones (la fronte, dividida en dos *piedi*, y la *sirima*), siguiendo habitualmente el patrón abCabC:cdeeDfF.

**Subtipos (7)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `cancion_de_15_versos` | — | 7, 11 | _según la matriz de importación_: retirado |
| `cancion_de_8_versos` | — | 7, 11 | _según la matriz de importación_: retirado |
| `cancion_de_9_versos` | — | 7, 11 | _según la matriz de importación_: retirado |
| `cancion_endecasilaba` | — | 11 | _según la matriz de importación_: esquema métrico |
| `cancion_regular_abCabCcdeeDfF` | abCabCcdeeDfF | 7, 11 | **arquitectura** `cancion_petrarquista · regular_13_versos` |
| `cancion_sin_rima` | — | 7, 11 | **arquitectura** `cancion_petrarquista · sin_rima_con_pareado_final` |
| `cancion_sin_rima_de_esdrujulos` | — | 7, 11 | _según la matriz de importación_: arquitectura `cancion_petrarquista · sin_rima_con_pareado_final`, rasgo |

- `cancion_de_15_versos`: Canción petrarquista (canzone) agrupada en estancias de 15 versos y que combina heptasílabos con endecasílabos.
- `cancion_de_8_versos`: Canción petrarquista (canzone) agrupada en estancias de 8 versos y que combina heptasílabos con endecasílabos.
- `cancion_de_9_versos`: Canción petrarquista (canzone) agrupada en estancias de 9 versos y que combina heptasílabos con endecasílabos.
- `cancion_endecasilaba`: Canción petrarquista formada exclusivamente por endecasílabos, por ejemplo, ABCABCDD.
- `cancion_regular_abCabCcdeeDfF`: Canción petrarquista (canzone) con el patrón regular de rimas abCabC:cdeeDfF.
- `cancion_sin_rima`: La canción sin rima (o canción libre) es una estructura métrica compuesta por series de estrofas que combinan heptasílabos y endecasílabos. A diferencia de la estancia de canción convencional, esta forma prescinde de la rima en el cuerpo de la estrofa, manteniendo únicamente un pareado final de rima consonante que sirve para cerrar cada unidad y marcar la transición rítmica.
- `cancion_sin_rima_de_esdrujulos`: Canción sin rima que usa total o mayoritariamente términos esdrújulos a final de verso.

### copla_de_arte_mayor

| | |
| --- | --- |
| Término | `copla_de_arte_mayor` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_mayor |
| Tamaño de unidad | 8 |
| Naturaleza estrófica | — |
| Tipo de rima | consonante |
| Metros declarados | 12 sílabas |
| **Destino actual** | **forma** `copla_de_arte_mayor` |
| Propuesta de importación | F · certeza alta |

> La copla de arte mayor es una estrofa de la métrica castellana en rima consonante, compuesta por versos dodecasílabos (con cesura entre los dos hexasílabos), con tres o cuatro rimas consonantes distribuidas en dos cuartetos.

**Subtipos (3)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `copla_de_arte_mayor_tipo_1_ABBAACCA` | ABBAACCA | 12 | _según la matriz de importación_: esquema de rima |
| `copla_de_arte_mayor_tipo_2_ABBACDCD` | ABBACDCD | 12 | _según la matriz de importación_: esquema de rima |
| `copla_de_arte_mayor_tipo_3_ABABCDCD` | ABABCDCD | 12 | _según la matriz de importación_: esquema de rima |

- `copla_de_arte_mayor_tipo_1_ABBAACCA`: Ver definición de *Copla de arte mayor*
- `copla_de_arte_mayor_tipo_2_ABBACDCD`: Ver definición en *Copla de arte mayor*
- `copla_de_arte_mayor_tipo_3_ABABCDCD`: Ver definición en *Copla de arte mayor*

### copla_de_pie_quebrado

| | |
| --- | --- |
| Término | `copla_de_pie_quebrado` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | — |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 4, 5, 8 sílabas |
| Equivalencias | Sextilla de pie quebrado |
| **Destino actual** | **forma** `copla_de_pie_quebrado` |
| Propuesta de importación | E · certeza alta |

> Estrofa compuesta por la combinación de versos octosílabos con otros de menor medida, habitualmente tetrasílabos o pentasílabos, denominados "quebrados". Esta estructura métrica se organiza en estrofas que oscilan generalmente entre los cinco y los doce versos, donde la alternancia rítmica entre el verso largo y su mitad métrica genera una cadencia característica muy utilizada en la lírica castellana, especialmente en composiciones de tono elegíaco o narrativo. En esta categoría encajarían todas aquellas que no correspondan con las del campo *sextilla de pie quebrado*, *copla manriqueña* y *doble sextilla alternativa*.

### copla_real

| | |
| --- | --- |
| Término | `copla_real` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 10 |
| Naturaleza estrófica | — |
| Tipo de rima | consonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **forma** `copla_real` |
| Propuesta de importación | F · certeza alta |

> Tirada de estrofas de diez versos que combinan de un modo fijo dos quintillas normalmente de distinto tipo. Es característica la pausa tras el quinto verso, a diferencia de la décima espinela, que se da tras el cuarto. Puede incluir uno o dos versos de pie quebrado.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `copla_real_de_pie_quebrado` | — | 4, 8 | **arquitectura** `copla_real · con_pie_quebrado` |
| `copla_real_sin_quebrado` | — | 8 | **arquitectura** `copla_real · sin_pie_quebrado` |

- `copla_real_de_pie_quebrado`: Tirada de estrofas de diez versos que combinan de un modo fijo dos quintillas, normalmente de distinto tipo, pero no es obligatorio. Es característica la pausa tras el quinto verso, a diferencia de la décima espinela, que se da tras el cuarto. Incluyen uno o dos versos de pie quebrado.
- `copla_real_sin_quebrado`: Tirada de estrofas de diez versos que combinan de un modo fijo dos quintillas normalmente de distinto tipo. Es característica la pausa tras el quinto verso, a diferencia de la décima espinela, que se da tras el cuarto. Sin versos de pie quebrado.

### decima

| | |
| --- | --- |
| Término | `decima` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 10 |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 8 sílabas |
| Patrón específico | `abbaaccddc` |
| Equivalencias | décima espinela |
| **Destino actual** | _según la matriz de importación_: forma `decima_espinela` |
| Propuesta de importación | G · certeza alta |

> Diez octosílabos con rima abba:accddc. Es característica la pausa tras el cuarto verso (abba:accddc).

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `decima_aumentada` | abbaaccddeed | 8 | **forma** `decima_aumentada` |
| `decima_espinela` | abbaaccddc | 8 | **forma** `decima_espinela` |

- `decima_aumentada`: Estrofa de 12 versos con el patrón abbaaccddeed. Es característica la pausa tras el cuarto verso (abba:accddeed).
- `decima_espinela`: Diez octosílabos con rima abbaaccddc. Se trata de dos redondillas enlazadas por dos versos puente, uno sirve de vínculo con la primera redondilla y el otro con la segunda (4 + 2+ 4). Es característica la pausa tras el cuarto verso (abba:accddc), a diferencia de la copla real, que se da tras el quinto verso.

### doble_sextilla

| | |
| --- | --- |
| Término | `doble_sextilla` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 12 |
| Naturaleza estrófica | — |
| Tipo de rima | consonante |
| Metros declarados | 4, 8 sílabas |
| **Destino actual** | **forma** `doble_sextilla` |
| Propuesta de importación | F · certeza alta |

> Dos sextillas con un patrón de rima regular. El verso final de los cuatro tercetos es de pie quebrado.  Si se trata del patrón regular abcabcdefdef, ver la categoría *copla manriqueña*. Para el resto de casos, ver *doble sextilla alternativa*.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `copla_manriqueña` | abcabcdefdef | 4, 8 | **forma** `copla_manriqueña` |
| `doble_sextilla_alternativa` | — | 4, 8 | **arquitectura** `doble_sextilla · otro_esquema_regular` |

- `copla_manriqueña`: Dos sextillas con rima ab*c*ab*c*:de*f*de*f*. El verso final de los cuatro tercetos es de pie quebrado. Fue popularizado por Jorge Manrique en las *Coplas a la muerte de su padre*. Si se trata de una doble sextilla con otro patrón de rimas, ver la categoría *doble sextilla*.
- `doble_sextilla_alternativa`: Dos sextillas con un patrón de rima regular. El verso final de los cuatro tercetos es de pie quebrado.  Si se trata del patrón regular abcabcdefdef, ver la categoría *copla manriqueña*.

### Endecasílabo suelto

| | |
| --- | --- |
| Término | `endecasilabo_suelto` |
| Etiqueta | Endecasílabo suelto |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 11 sílabas |
| **Destino actual** | **forma** `endecasilabo_suelto` |
| Propuesta de importación | F · certeza alta |

> Los endecasílabos sueltos consisten en series de versos de once sílabas que carecen de rima regular, aunque mantienen la cohesión rítmica a través de la identidad métrica. Suelen concluir estas secuencias con un pareado final y a veces intercalan dísticos rimados con una frecuencia creciente a lo largo de un mismo pasaje. Técnicamente, una composición se categoriza bajo esta modalidad cuando la presencia de rimas es minoritaria, situándose por debajo del 50 % del total de los versos, lo que la diferencia de formas más densamente rimadas como la silva de consonantes o los pareados endecasílabos.

**Subtipos (6)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `endecasilabo_suelto_con_pareados` | — | 11 | **arquitectura** `endecasilabo_suelto · con_pareados_con_distico_final` |
| `endecasilabo_suelto_con_pareados_y_sin_distico_final` | — | 11 | **arquitectura** `endecasilabo_suelto · con_pareados_sin_distico_final` |
| `endecasilabo_suelto_de_esdrujulos` | — | 11 | _según la matriz de importación_: rasgo |
| `endecasilabo_suelto_encadenado` | — | 11 | **arquitectura** `endecasilabo_suelto · encadenado_interior` |
| `endecasilabo_suelto_puro` | — | 11 | **arquitectura** `endecasilabo_suelto · puro_con_distico_final` |
| `endecasilabo_suelto_puro_sin_distico_final` | — | 11 | **arquitectura** `endecasilabo_suelto · puro_sin_distico_final` |

- `endecasilabo_suelto_con_pareados`: En una tirada de endecasílabos sueltos se mezclan algunos pareados intercalados además del dístico conclusivo. Si los pareados suponen entre el 50 y el 98%, estamos ante una **silva de endecasílabos**; si suponen entre el 99-100%, estamos ante **pareados endecasílabos**.
- `endecasilabo_suelto_con_pareados_y_sin_distico_final`: Tirada de endecasílabos sueltos con intercalación de pareados, pero sin el dístico final. Si los pareados suponen entre el 50 y el 98%, estamos ante una **silva de endecasílabos**; si suponen entre el 99-100%, estamos ante **pareados endecasílabos**.
- `endecasilabo_suelto_de_esdrujulos`: Tirada de endecasílabos sueltos con terminaciones total o mayoritariamente en palabras esdrújulas.
- `endecasilabo_suelto_encadenado`: Tirada de endecasílabos sueltos en que riman las sílabas finales de un verso con un grupo silábico situado en el interior del verso siguiente (generalmente la sexta y séptima sílaba, y, con menor frecuencia, la cuarta y quinta).
- `endecasilabo_suelto_puro`: Los endecasílabos sueltos consisten en series de versos de once sílabas que carecen de rima regular, aunque mantienen la cohesión rítmica a través de la identidad métrica. Incluyen un pareado final, pero jamás intercalan dísticos rimados.
- `endecasilabo_suelto_puro_sin_distico_final`: Tirada de endecasílabos sueltos sin pareados intercalados ni dístico final.

### Irregular

| | |
| --- | --- |
| Término | `irregular` |
| Etiqueta | Irregular |
| Tipo de forma | — |
| Arte métrico | — |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | — |
| **Destino actual** | **forma** `irregular` |
| Propuesta de importación | E · certeza alta |

> Formas métricas irregulares.

**Subtipos (3)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `irregular_arte_mayor` · Irregular de arte mayor | — | — | _según la matriz de importación_: forma `irregular` |
| `irregular_arte_menor` · Irregular de arte menor | — | — | _según la matriz de importación_: forma `irregular` |
| `irregular_mixto` · Irregular mixto | — | — | _según la matriz de importación_: forma `irregular` |

- `irregular_arte_mayor`: Estrofa irregular compuesta exclusivamente por versos de arte mayor.
- `irregular_arte_menor`: Estrofa irregular compuesta exclusivamente por versos de arte menor.
- `irregular_mixto`: Estrofa irregular compuesta por una mixtura de versos de arte menor y mayor.

### lira

| | |
| --- | --- |
| Término | `lira` |
| Tipo de forma | forma_italiana |
| Arte métrico | mixto |
| Tamaño de unidad | 5 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 7, 11 sílabas |
| Patrón específico | `aBabB` |
| **Destino actual** | **forma** `lira` |
| Propuesta de importación | F · certeza alta |

> La lira es una estrofa de cinco versos que combina heptasílabos y endecasílabos bajo un esquema fijo de rima consonante 7a\11B\7a\7b\11B. Su estructura rítmica la convirtió en una de las formas predilectas de la lírica renacentista para expresar contenidos de gran elevación espiritual o emotiva.

### novena

| | |
| --- | --- |
| Término | `novena` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 9 |
| Naturaleza estrófica | — |
| Tipo de rima | consonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **forma** `novena` |
| Propuesta de importación | F · certeza alta |

> Nueve versos octosílabos generalmente compuestos por una redondilla y una quintilla o viceversa.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `novena_canonica` | — | 8 | **arquitectura** `novena · redondilla_quintilla` |
| `novena_invertida` | — | 8 | **arquitectura** `novena · quintilla_redondilla` |

- `novena_canonica`: Nueve versos octosílabos compuestos por una redondilla y una quintilla, por este orden.
- `novena_invertida`: Nueve versos octosílabos generalmente compuestos por una quintilla y una redondilla, por este orden.

### Octava real

| | |
| --- | --- |
| Término | `octava_real` |
| Etiqueta | Octava real |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 11 sílabas |
| Patrón específico | `ABABABCC` |
| Equivalencias | octava rima,octava heroica |
| **Destino actual** | **forma** `octava_real` |
| Propuesta de importación | F · certeza alta |

> Estrofa formada por ocho endecasílabos con rima ABABABCC.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `octava_real_de_esdrujulos` | — | 11 | _según la matriz de importación_: rasgo |
| `octava_real_regular` | ABABABCC | 11 | **denominación** «Octava real regular» |

- `octava_real_de_esdrujulos`: Octava real rimada total o mayoritariamente con términos esdrújulos.
- `octava_real_regular`: Estrofa formada por ocho endecasílabos con rima ABABABCC.

### Pareado de arte menor

| | |
| --- | --- |
| Término | `pareado_de_arte_menor` |
| Etiqueta | Pareado de arte menor |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 2 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | otras |
| Metros declarados | 4, 5, 6, 7, 8 sílabas |
| **Destino actual** | **arquitectura** `pareado · arte_menor` |
| Propuesta de importación | C · certeza media |

> Un dístico o una serie de dísticos de arte menor.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `pareado_hexasilabo` · Pareado hexasílabo | — | 6 | **respuesta** de medida en `pareado · arte_menor` |
| `pareado_octosilabo` · Pareado octosílabo | — | 8 | **respuesta** de medida en `pareado · arte_menor` |

- `pareado_hexasilabo`: Dísticos de hexasílabos.
- `pareado_octosilabo`: Dísticos de octosílabos.

### pareado_endecasilabo

| | |
| --- | --- |
| Término | `pareado_endecasilabo` |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | 2 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 11 sílabas |
| Equivalencias | Dístico o tirada de dísticos endecasílabos en su práctica totalidad (99-100%). |
| **Destino actual** | **arquitectura** `pareado · arte_mayor` |
| Propuesta de importación | F · certeza alta |

### Quintilla

| | |
| --- | --- |
| Término | `quintilla` |
| Etiqueta | Quintilla |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 5 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **forma** `quintilla` |
| Propuesta de importación | F · certeza alta |

> Quintilla: estrofa formada por cinco versos octosílabos y dos rimas que se repiten seguidas un máximo de dos veces (excepto la tipología 8). La rima siempre es consonante. Hay siete modalidades:  1) ababa; 2) abbab; 3) abaab; 4) aabab; 5) aabba; 6) abbaa; 7) ababb; 8) abbba.

**Subtipos (8)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `quintilla_1_ababa` | ababa | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_2_abbab` | abbab | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_3_abaab` | abaab | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_4_aabab` | aabab | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_5_aabba` | aabba | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_6_abbaa` | abbaa | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_7_ababb` | ababb | 8 | _según la matriz de importación_: esquema de rima |
| `quintilla_8_abbba` | abbba | 8 | _según la matriz de importación_: esquema de rima |

- `quintilla_1_ababa`: Quintilla ababa (tipo 1)
- `quintilla_2_abbab`: Quintilla abbab (tipo 2)
- `quintilla_3_abaab`: Quintilla abaab (tipo 3)
- `quintilla_4_aabab`: Quintilla aabab (tipo 4)
- `quintilla_5_aabba`: Quintilla aabba (tipo 5)
- `quintilla_6_abbaa`: Quintilla abbaa (tipo 6)
- `quintilla_7_ababb`: Quintilla ababb (tipo 7)
- `quintilla_8_abbba`: Quintilla que contradice la norma general al repetir tres rimas seguidas: abbba.

### Redondilla

| | |
| --- | --- |
| Término | `redondilla` |
| Etiqueta | Redondilla |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 4 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **forma** `redondilla` |
| Propuesta de importación | F · certeza alta |

**Subtipos (5)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `redondilla_cruzada` | abab | 8 | _según la matriz de importación_: esquema de rima |
| `redondilla_doble_abbaacca` · Redondilla doble (abbaacca) | abbaacca | 8 | **arquitectura** `redondilla · doble_enlazada` |
| `redondilla_heptasilaba` · Redondilla heptasílaba | abba | 7 | _según la matriz de importación_: esquema métrico |
| `redondilla_hexasilaba` · Redondilla hexasílaba | abba | 6 | _según la matriz de importación_: esquema métrico |
| `redondilla_regular` | abba | 8 | **arquitectura** `redondilla · simple` |

- `redondilla_cruzada`: La redondilla de rima cruzada es la estrofa formada por cuatro versos octosílabos con rima consonante abab.
- `redondilla_doble_abbaacca`: Redondillas dobles con el patrón de rima abbaacca.
- `redondilla_heptasilaba`: Redondilla formada por cuatro versos heptasílabos con rima abba.
- `redondilla_hexasilaba`: Redondilla formada por cuatro versos hexasílabos con rima abba.
- `redondilla_regular`: La redondilla regular es la estrofa formada por cuatro versos octosílabos con rima abrazada consonante abba.

### Romance

| | |
| --- | --- |
| Término | `romance` |
| Etiqueta | Romance |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | — |
| Naturaleza estrófica | tirada_abierta |
| Tipo de rima | asonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **forma** `romance` |
| Propuesta de importación | F · certeza alta |

> Serie indefinida de versos octosílabos con rima asonante en los pares.

**Subtipos (19)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `romance_a` · Romance (-a) | — | 8 | _según la matriz de importación_: rasgo |
| `romance_a-a` · Romance (a-a) | a-a | 8 | _según la matriz de importación_: rasgo |
| `romance_a-e` · Romance (a-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_a-o` · Romance (a-o) | — | — | _según la matriz de importación_: rasgo |
| `romance_e` · Romance (-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_e-a` · Romance (e-a) | e-a | 8 | _según la matriz de importación_: rasgo |
| `romance_e-e` · Romance (e-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_e-o` · Romance (e-o) | e-o | — | _según la matriz de importación_: rasgo |
| `romance_i` · Romance (-i) | — | — | _según la matriz de importación_: rasgo |
| `romance_i-a` · Romance (i-a) | i-a | — | _según la matriz de importación_: rasgo |
| `romance_i-e` · Romance (i-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_i-o` · Romance (i-o) | i-o | — | _según la matriz de importación_: rasgo |
| `romance_o` · Romance (-o) | — | — | _según la matriz de importación_: rasgo |
| `romance_o-a` · Romance (o-a) | o-a | — | _según la matriz de importación_: rasgo |
| `romance_o-e` · Romance (o-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_o-o` · Romance (o-o) | — | — | _según la matriz de importación_: rasgo |
| `romance_u-a` · Romance (u-a) | — | — | _según la matriz de importación_: rasgo |
| `romance_u-e` · Romance (u-e) | — | — | _según la matriz de importación_: rasgo |
| `romance_u-o` · Romance (u-o) | — | — | _según la matriz de importación_: rasgo |

- `romance_a`: Romance con asonancia -á
- `romance_a-a`: Romance con asonancia a-a
- `romance_a-e`: Romance con asonancia a-e
- `romance_a-o`: Romance con asonancia a-o
- `romance_e`: Romance con asonancia -e
- `romance_e-a`: Romance con asonancia e-a
- `romance_e-e`: Romance con asonancia e-e
- `romance_e-o`: Romance con asonancia e-o
- `romance_i`: Romance con asonancia -í
- `romance_i-a`: Romance con asonancia i-a
- `romance_i-e`: Romance con asonancia i-e
- `romance_i-o`: Romance con asonancia i-o
- `romance_o`: Romance con asonancia -ó
- `romance_o-a`: Romance con asonancia o-a
- `romance_o-e`: Romance con asonancia o-e
- `romance_o-o`: Romance con asonancia o-o
- `romance_u-a`: Romance con asonancia u-a
- `romance_u-e`: Romance con asonancia u-e
- `romance_u-o`: Romance con asonancia u-o

### Romance heroico

| | |
| --- | --- |
| Término | `romance_heroico` |
| Etiqueta | Romance heroico |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_mayor |
| Tamaño de unidad | — |
| Naturaleza estrófica | tirada_abierta |
| Tipo de rima | asonante |
| Metros declarados | 11 sílabas |
| Equivalencias | romance real |
| **Destino actual** | **arquitectura** `romance · endecasilabico` |
| Propuesta de importación | C · certeza alta |

> Serie indefinida de versos endecasílabos con rima asonante en los pares.

### Romancillo

| | |
| --- | --- |
| Término | `romancillo` |
| Etiqueta | Romancillo |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | — |
| Naturaleza estrófica | tirada_abierta |
| Tipo de rima | asonante |
| Metros declarados | 6, 7 sílabas |
| Equivalencias | endecha,romance endecha |
| **Destino actual** | _según la matriz de importación_: arquitectura `romance · hexasilabico`, arquitectura `romance · heptasilabico` |
| Propuesta de importación | D · certeza alta |

> Serie indefinida de versos hexasílabos o heptasílabos con rima asonante en los pares.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `romancillo_heptasilabo` | — | 7 | **arquitectura** `romance · heptasilabico` |
| `romancillo_hexasilabo` | — | 6 | **arquitectura** `romance · hexasilabico` |

- `romancillo_heptasilabo`: Serie indefinida de versos heptasílabos con rima asonante en los pares.
- `romancillo_hexasilabo`: Serie indefinida de versos hexasílabos con rima asonante en los pares.

### seguidilla

| | |
| --- | --- |
| Término | `seguidilla` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 4 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | asonante |
| Metros declarados | 5, 7 sílabas |
| **Destino actual** | **forma** `seguidilla` |
| Propuesta de importación | F · certeza alta |

> La seguidilla es una forma métrica que se estructura en estrofas de cuatro o siete versos, caracterizada por la alternancia de versos de siete y cinco sílabas con rima asonante (por ejemplo, 7-5a-7-5a). En este tipo de composición, el cómputo silábico puede presentar ligeras variaciones debido a que su construcción prioriza la cadencia musical sobre el rigor numérico literario.

### sexta_rima

| | |
| --- | --- |
| Término | `sexta_rima` |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | 6 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 11 sílabas |
| Patrón específico | `ABABCC` |
| **Destino actual** | **forma** `sexta_rima` |
| Propuesta de importación | F · certeza alta |

> En el Diccionario de métrica española, la define como un sexteto de endecasílabos con rima consonante, en el que riman el primero con el tercero, el segundo con el cuarto, y el quinto con el sexto: 11A 11B 11A 11B 11C 11C.

Bibliografía: ****

### sexteto

| | |
| --- | --- |
| Término | `sexteto` |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | 6 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 11 sílabas |
| **Destino actual** | **forma** `sexteto` |
| Propuesta de importación | E · certeza alta |

> El sexteto es una estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante y con disposición variable. Domínguez Caparrós lo formula de manera muy clara: después de definir la sextilla como estrofa de seis versos de arte menor, añade que, si los versos son de arte mayor, se llama sexteto. Además, en su esquema de estrofas de seis versos separa: sextilla = arte menor, consonante; sexteto = arte mayor, consonante; sexta rima = 11 ABABCC; sexteto lira = endecasílabos y heptasílabos, consonante. En el Diccionario de métrica española, Domínguez lo define como estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante que puede adoptar variadas disposiciones.

### Sexteto-lira

| | |
| --- | --- |
| Término | `sexteto_lira` |
| Etiqueta | Sexteto-lira |
| Tipo de forma | forma_italiana |
| Arte métrico | mixto |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 7, 11 sílabas |
| **Destino actual** | **forma** `sexteto_lira` |
| Propuesta de importación | F · certeza alta |

> El sexteto-lira es una estrofa de seis versos que combina heptasílabos y endecasílabos mediante el empleo de tres rimas diferenciadas. Su estructura se organiza en dos bloques: los cuatro primeros versos alternan o abrazan las dos primeras rimas, mientras que los dos finales cierran la composición mediante un pareado que introduce la tercera rima. Aunque admite diversas variantes en la disposición de los metros y las rimas (como abbacC o AabBCC), la forma considerada regular sigue el esquema aBaBcC. Por lo general, el patrón métrico elegido al inicio de un pasaje se mantiene de forma constante a lo largo de toda la serie, garantizando la cohesión rítmica de la unidad.

**Subtipos (8)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `sexteto_lira_a1_aBaBcC` | aBaBcC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_a2_AbaBcC` | AbaBcC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_a3_abaBcC` | abaBcC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_b1_abbacC` | abbacC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_b2_AbbACC` | AbbACC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_c1_AabBcC` | AabBcC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_c2_AabBCC` | AabBCC | 7, 11 | _según la matriz de importación_: variedad |
| `sexteto_lira_de_esdrujulos` | — | 7, 11 | _según la matriz de importación_: rasgo |

- `sexteto_lira_a1_aBaBcC`: El sexteto-lira regular es el más habitual y sigue el esquema aBaBcC.
- `sexteto_lira_a2_AbaBcC`: Sexteto-lira con el patrón de rima AbaBcC.
- `sexteto_lira_b1_abbacC`: Sexteto-lira con rimas en esquema abbacC.
- `sexteto_lira_b2_AbbACC`: Sexteto-lira con patrón de rimas AbbACC
- `sexteto_lira_c1_AabBcC`: Sexteto-lira con patrón de rimas AabBcC.
- `sexteto_lira_c2_AabBCC`: Sexteto-lira con patrón de rimas AabBCC.
- `sexteto_lira_de_esdrujulos`: Sexteto-lira rimado total o mayoritariamente con términos esdrújulos.

### sextilla

| | |
| --- | --- |
| Término | `sextilla` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 6 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 6, 7, 8 sílabas |
| **Destino actual** | **forma** `sextilla` |
| Propuesta de importación | F · certeza alta |

> Una sextilla es una estrofa de seis versos de arte menor, normalmente con rima consonante y con disposición variable de las rimas. Domínguez Caparrós la define de forma muy directa: “se llama sextilla a toda estrofa de seis versos de arte menor con rima consonante”. Y añade inmediatamente la distinción importante: si los versos son de arte mayor, ya no se llama sextilla, sino sexteto. Quilis coincide en lo esencial: la define como “estrofa de versos de arte menor” y señala que admite varias combinaciones de rima, como aabaab, abcabc, ababab, etc. Varela, Moíño y Jauralde también la colocan dentro de las estrofas de seis versos y distinguen claramente entre sextillas, de arte menor, y sextetos, de arte mayor. Además, recuerdan que dentro de las estrofas de seis versos hay variantes históricas importantes, como las sextillas simétricas y las coplas de pie quebrado. Para la *copla manriqueña*, compuesta por dos sextillas, véase esa categoría.

**Subtipos (2)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `sextilla_de_pie_quebrado` | — | — | **arquitectura** `sextilla · pie_quebrado` |
| `sextilla_sin_quebrado` | — | — | **arquitectura** `sextilla · isometrica` |

- `sextilla_de_pie_quebrado`: Ver definición en *Sextilla* y su diferencia en *Doble sextilla*.
- `sextilla_sin_quebrado`: Ver *Sextilla*.

### sextina

| | |
| --- | --- |
| Término | `sextina` |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | 39 |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 11 sílabas |
| **Destino actual** | **forma** `sextina` |
| Propuesta de importación | F · certeza alta |

> La sextina es una estructura métrica culta compuesta por treinta y nueve versos endecasílabos, organizados en seis estrofas de seis versos y un remate final de tres. Su rasgo distintivo es la ausencia de rima convencional, sustituida por la repetición de seis palabras fijas al final de los versos; estas palabras rotan en cada estrofa siguiendo un orden de alternancia hasta completar todas las combinaciones posibles. El poema concluye con un remate de tres versos que integra las seis palabras clave —tres en el interior del verso y tres al final—, cerrando así este complejo ejercicio de arquitectura léxica y rítmica. Puede darse el caso de la sextina doble, consistente en repetir el esquema de las seis estrofas de seis versos y acabar con el remate simple de tres versos.

### silva

| | |
| --- | --- |
| Término | `silva` |
| Tipo de forma | forma_italiana |
| Arte métrico | mixto |
| Tamaño de unidad | — |
| Naturaleza estrófica | tirada_abierta |
| Tipo de rima | otras |
| Metros declarados | 7, 11 sílabas |
| **Destino actual** | **forma** `silva` |
| Propuesta de importación | F · certeza alta |

> La silva es una serie métrica abierta que generalmente combina versos heptasílabos y endecasílabos con rima consonante distribuida al arbitrio del poeta, permitiendo incluso la aparición de versos sueltos sin rima. Podemos categorizar esta forma en cuatro variantes según la disposición de sus elementos:  1.- Silva de consonantes regular, que alterna siempre del mismo modo los pareados (aAbBcCdDeE, etc.). 2.- Silva de consonantes irregular, que alterna de manera libre  los pareados (por ejemplo, AABbcCDDEE, etc.). 3.- Silva libre, donde la extensión y la rima no siguen un orden fijo y pueden quedar versos sin rimar. Es la silva más irregular. 4.- Silva de endecasílabos, compuesta exclusivamente por versos de once sílabas con una alta densidad de rimas (del 50 al 98% son rimados), a menudo en dísticos.

**Subtipos (4)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `silva_de_consonantes_irregular` | — | 7, 11 | **arquitectura** `silva · consonante_irregular` |
| `silva_de_consonantes_regular` | — | 7, 11 | **arquitectura** `silva · consonante_regular` |
| `silva_de_endecasilabos` | — | 11 | **arquitectura** `silva · endecasilabica` |
| `silva_libre` | — | 7, 11 | **arquitectura** `silva · libre` |

- `silva_de_consonantes_irregular`: La silva de consonantes irregular es una serie métrica abierta que combina versos heptasílabos y endecasílabos con rima consonante agrupados en pareados, pero sin una estructura fija (por ejemplo, AABbcCDDEe, etc.). Aunque la mayoría son pareados, puede dejar algunos versos sueltos sin rimar.
- `silva_de_consonantes_regular`: La silva de consonantes regular es una serie métrica abierta que combina versos heptasílabos y endecasílabos con rima consonante en forma de pareados estructurados siempre del mismo modo (aAbBcCdDeE, etc.).
- `silva_de_endecasilabos`: La silva de endecasílabos es una serie métrica abierta exclusivamente de versos de 11 sílabas, que permite la aparición de versos sueltos sin rima, aunque la mayoría son rimados (del 50 al 98%), a menudo en dísticos. Si los pareados suponen un porcentaje menor, estamos ante **endecasílabo suelto**; si suponen entre el 99-100%, estamos ante **pareado endecasílabo**.
- `silva_libre`: La silva libre es una serie métrica abierta que combina versos heptasílabos y endecasílabos con rima consonante distribuida al arbitrio del poeta, sin un orden fijo, permitiendo incluso la aparición de versos sueltos sin rima. Es la silva más irregular. No contiene pareados y, si los hubiera, serían una minoría de casos aislados.

### Soneto

| | |
| --- | --- |
| Término | `soneto` |
| Etiqueta | Soneto |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 11 sílabas |
| **Destino actual** | **forma** `soneto` |
| Propuesta de importación | F · certeza alta |

> El soneto es una composición poética de catorce versos endecasílabos organizada en dos cuartetos iniciales, que mantienen un orden rígido de rima abrazada (ABBAABBA), seguidos de dos tercetos finales cuya disposición es variable. Esta última sección permite diversas combinaciones rítmicas que definen el carácter de la resolución del poema, destacando entre las más comunes los tercetos de rima cruzada (CDCDCD) y los de la rima paralela (CDECDE), la de rima conclusiva (CDEDCE) o la rima nuclear (CDCEDE), entre otras variantes que otorgan al poeta flexibilidad para modular el cierre conceptual y sonoro de la pieza.

**Subtipos (5)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE` | ABBAABBACDEDCE | 11 | _según la matriz de importación_: esquema de rima |
| `soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE` | ABBAABBACDCEDE | 11 | _según la matriz de importación_: esquema de rima |
| `soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE` | ABBAABBACDECDE | 11 | _según la matriz de importación_: esquema de rima |
| `soneto_de_esdrújulos` | — | 11 | _según la matriz de importación_: rasgo |
| `soneto_regular_ABBAABBACDCDCD` | ABBAABBACDCDCD | 11 | _según la matriz de importación_: esquema de rima |

- `soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE`: Composición poética de catorce versos endecasílabos organizada en dos cuartetos iniciales, que mantienen un orden rígido de rima abrazada (ABBAABBA), seguidos de dos tercetos finales de rima conclusiva (CDEDCE).
- `soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE`: Composición poética de catorce versos endecasílabos organizada en dos cuartetos iniciales, que mantienen un orden rígido de rima abrazada (ABBAABBA), seguidos de dos tercetos finales de rima nuclear (CDCEDE).
- `soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE`: Composición poética de catorce versos endecasílabos organizada en dos cuartetos iniciales, que mantienen un orden rígido de rima abrazada (ABBAABBA), seguidos de dos tercetos finales de rima paralela (CDECDE).
- `soneto_de_esdrújulos`: Soneto rimado total o mayoritariamente con términos esdrújulos.
- `soneto_regular_ABBAABBACDCDCD`: Composición poética de catorce versos endecasílabos organizada en dos cuartetos iniciales, que mantienen un orden rígido de rima abrazada (ABBAABBA), seguidos de dos tercetos finales de rima cruzada (CDCDCD).

### Terceto

| | |
| --- | --- |
| Término | `terceto` |
| Etiqueta | Terceto |
| Tipo de forma | forma_italiana |
| Arte métrico | arte_mayor |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | 11 sílabas |
| **Destino actual** | **forma** `terceto` |
| Propuesta de importación | F · certeza media |

> Unidad métrica fundamental de tres versos endecasílabos en los que riman, al menos, el primero con el tercero, el cuarto con el sexto, etc. Su flexibilidad permite su integración en series más extensas, basando su eficacia rítmica en la combinación de una rima compartida con un verso que puede quedar libre (tercetos sin encadenar) o anticipar el sonido de la siguiente unidad (tercetos encadenados).

**Subtipos (4)**

| Subtipo | Patrón | Metros | Destino actual |
| --- | --- | --- | --- |
| `terceto_de_esdrujulos` | — | 11 | _según la matriz de importación_: rasgo |
| `terceto_encadenado` | — | 11 | **forma** `terceto_encadenado` |
| `terceto_sin_encadenar_1_AXABYB` | — | 11 | _según la matriz de importación_: esquema de rima |
| `terceto_sin_encadenar_2_XAAYBB` | — | 11 | _según la matriz de importación_: esquema de rima |

- `terceto_de_esdrujulos`: Terceto rimado total o mayoritariamente con términos esdrújulos.
- `terceto_encadenado`: Estructura métrica continua de endecasílabos donde la rima del segundo verso de cada terceto se retoma en el primero y tercero del siguiente (ABABCBCDC, etc.), creando una secuencia entrelazada que se cierra habitualmente con un serventesio (YZYZ) o un verso suelto. Aunque su forma es regular, admite variaciones excepcionales como la presencia de un verso sin rima o la repetición de un mismo sonido en cuatro ocasiones para enfatizar un pasaje.
- `terceto_sin_encadenar_1_AXABYB`: Serie de endecasílabos organizados en grupos de tres donde no existe una trabazón sonora continua entre las estrofas, optando por esquemas de rima interna o versos sueltos (AXABYB, etc.). Estas composiciones pueden finalizar en un pareado o en un cuarteto.
- `terceto_sin_encadenar_2_XAAYBB`: Serie de endecasílabos organizados en grupos de tres donde no existe una trabazón sonora continua entre las estrofas, optando por esquemas de rima interna o versos sueltos (XAAYBB, etc.). Estas composiciones pueden finalizar en un pareado o en un cuarteto.

### Terceto octosílabo

| | |
| --- | --- |
| Término | `terceto_octosilabo` |
| Etiqueta | Terceto octosílabo |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | 3 |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 8 sílabas |
| **Destino actual** | **arquitectura** `terceto_encadenado · octosilabico` |
| Propuesta de importación | C · certeza media |

> Forma métrica que adapta los tercetos encadenados endecasílabos de raíz italiana a los octosílabos españoles

### verso suelto

| | |
| --- | --- |
| Término | `verso suelto` |
| Tipo de forma | — |
| Arte métrico | — |
| Tamaño de unidad | — |
| Naturaleza estrófica | — |
| Tipo de rima | — |
| Metros declarados | — |
| **Destino actual** | **forma** `verso_aislado` |
| Propuesta de importación | E · certeza alta |

> Un verso suelto que no se encuentre en medio de un segmento métrico (en este caso, tendría que marcarse como irregularidad dentro de ese segmento).  Si ese verso suelto corresponde a una tirada o forma específica (como las habituales tiradas de endecasílabos sueltos), hay que marcarlo como tal.

### Villancico

| | |
| --- | --- |
| Término | `villancico` |
| Etiqueta | Villancico |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | — |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | otras |
| Metros declarados | 6, 8 sílabas |
| **Destino actual** | **forma** `villancico` |
| Propuesta de importación | F · certeza alta |

> El villancico es una forma poética y musical española de arte menor (generalmente octosílabos o hexasílabos) caracterizada por la siguiente estructura métrica: cabeza (que puede coincidir total o parcialmente con el estribillo), una copla (que contiene mudanza y, menudo, versos de enlace y de vuelta) y la repetición del estribillo. La mudanza suele ser una redondilla o cuarteta (abba o abab).  Así es la estructura más habitual: - Estribillo o cabeza: De dos a cuatro versos iniciales que contienen el estribillo que se repiten más tarde. En algunos textos no existe esta sección. - Mudanza: una estrofa, frecuentemente redondilla (cuatro versos octosílabos, rima abba). - Verso de enlace: uno o más versos que conectan con la mudanza mediante la rima. - Verso de vuelta: uno o más versos que conectan con el estribillo mediante la rima. - Estribillo: unas veces se repite parte del estribillo y luego el estribillo entero; otras veces, tan solo una parte del estribillo y puede sobreentenderse que luego se repite el estribillo entero. Existen villancicos que omiten los versos de vuelta y de enlace.

### zejel

| | |
| --- | --- |
| Término | `zejel` |
| Tipo de forma | forma_espanola |
| Arte métrico | arte_menor |
| Tamaño de unidad | — |
| Naturaleza estrófica | estrofa_cerrada |
| Tipo de rima | consonante |
| Metros declarados | 6, 8 sílabas |
| **Destino actual** | **forma** `zejel` |
| Propuesta de importación | F · certeza alta |

> El zéjel es una forma poética y musical española de arte menor (generalmente octosílabos o hexasílabos) caracterizada por la siguiente estructura métrica: estribillo, una copla o estrofa compuesta por tres versos monorrimos, un verso de vuelta que rima con el estribillo y, habitualmente, la repetición del estribillo.

## Términos sin rastro en el catálogo nuevo

Ninguno: todos los términos tienen destino directo o registrado en la matriz de importación.

