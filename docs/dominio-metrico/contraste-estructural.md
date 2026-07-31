# Contraste estructural del catálogo poblado

Estado: **para revisar con el IP** · 31 de julio de 2026

El catálogo se pobló forma por forma, y cada forma se decidió con su ficha delante. Este
documento hace la lectura contraria: compara las treinta formas **por sus rasgos, no por
sus nombres**, para ver dónde el nombre que instaló la tradición ha separado cosas que
estructuralmente son vecinas, y dónde algo puede estar en un nivel que no le toca.

No propone fusionar formas. La ontología ya resuelve la tensión sin perder nombres:

- el nombre tradicional vive como **denominación**, apuntando al nivel exacto que nombra;
- el parentesco vive como **relación tipada**, que no transmite propiedades;
- el género vive como forma de **grado general**, y el demarcador «ofrece la forma más
  específica que encaje; cuando ninguna corresponde, la general es la respuesta correcta,
  no un consuelo».

Lo que falta no son entidades: son **relaciones sin declarar y niveles sin confirmar**.

## 1 · Vecindarios estructurales

Formas del mismo nivel que declaran la misma extensión de unidad. Si dos formas coinciden
en extensión y régimen de rima y solo difieren en la medida, la pregunta es si hay un
género por encima o si la medida basta para separarlas.

### estrofa · unidad 10–10

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `copla_real` | especifica | {4, 8} | 2 | ← sucede_historicamente_a decima_espinela |
| `decima_espinela` | especifica | {8} | 1 | sucede_historicamente_a → copla_real |

### estrofa · unidad 12–12

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `copla_manriqueña` | especifica | {4, 8} | 1 | subtipo_de → doble_sextilla |
| `decima_aumentada` | especifica | {8} | 1 | **ninguna** |
| `doble_sextilla` | especifica | {4, 8} | 1 | ← subtipo_de copla_manriqueña |

### estrofa · unidad 5–5

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `lira` | especifica | {7, 11} | 1 | **ninguna** |
| `quintilla` | especifica | {8} | 1 | **ninguna** |

### estrofa · unidad 6–6

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `sexta_rima` | especifica | {11} | 1 | subtipo_de → sexteto |
| `sexteto` | general | {11, 12, 14} | 1 | ← subtipo_de sexta_rima |
| `sexteto_lira` | especifica | {7, 11} | 1 | **ninguna** |
| `sextilla` | especifica | {4, 6, 7, 8} | 2 | **ninguna** |

### estrofa · unidad 8–8

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `copla_de_arte_mayor` | especifica | {12} | 1 | **ninguna** |
| `octava_real` | especifica | {11} | 1 | **ninguna** |

**5 vecindarios**, y en ellos **7 formas sin ninguna relación declarada** con sus vecinas.

## 2 · Qué subió y qué bajó de nivel al migrar

En el vocabulario heredado, una raíz era de hecho una forma y un hijo era una variante.
Al migrar, algunas raíces pasaron a ser arquitecturas y algunos hijos pasaron a ser
formas. Cada uno de esos movimientos fue una decisión, y conviene volver a mirarlos
juntos.

### Raíces que hoy son arquitecturas

Eran entradas de primer nivel del vocabulario y hoy son una realización de otra forma.
La pregunta es si conservan identidad suficiente para ser forma.

| Término heredado | Definición | Hoy es |
| --- | --- | --- |
| `terceto_octosilabo` | Forma métrica que adapta los tercetos encadenados endecasílabos de raíz italiana a los octosílabos españoles | `terceto_encadenado · octosilabico` |
| `pareado_de_arte_menor` | Un dístico o una serie de dísticos de arte menor. | `pareado · arte_menor` |
| `pareado_endecasilabo` |  | `pareados_endecasilabos · endecasilabicos_consonantes` |
| `romance_heroico` | Serie indefinida de versos endecasílabos con rima asonante en los pares. | `romance · endecasilabico` |

### Subtipos que hoy son formas

Eran hijos de otra entrada y hoy son forma propia, asignable a una secuencia.

| Término heredado | Colgaba de | Hoy es |
| --- | --- | --- |
| `terceto_encadenado` | `terceto` | forma `terceto_encadenado` |
| `copla_manriqueña` | `doble_sextilla` | forma `copla_manriqueña` |
| `decima_espinela` | `decima` | forma `decima_espinela` |
| `decima_aumentada` | `decima` | forma `decima_aumentada` |

## 3 · Señales de que algo puede estar en el nivel equivocado

### Formas con una sola arquitectura y ninguna pregunta

Si una forma no admite ninguna variación, su arquitectura no distingue nada: es la forma
misma. No es un error —una forma fija es legítima— pero conviene confirmarlo.

| Forma | Arquitectura | Unidad | Esquemas |
| --- | --- | --- | ---: |
| `copla_manriqueña` | `dos_sextillas` | 12–12 | 2 |
| `decima_aumentada` | `octosilabica` | 12–12 | 2 |
| `decima_espinela` | `octosilabica` | 10–10 | 2 |
| `doble_sextilla` | `otro_esquema_regular` | 12–12 | 2 |
| `lira` | `heptasilabica_endecasilabica` | 5–5 | 2 |
| `pareados_endecasilabos` | `endecasilabicos_consonantes` | — | 2 |
| `sexta_rima` | `endecasilabica_consonante` | 6–6 | 2 |

### Arquitecturas que se distinguen solo por la medida

La ontología dice que la medida es arquitectura cuando la forma es isosilábica. Cuando
varias arquitecturas de una forma solo difieren en eso, el reparto es correcto; cuando la
medida convive con una **pregunta** por la medida dentro de la misma arquitectura, hay
dos criterios aplicados al mismo fenómeno.

| Forma | Arquitecturas | Medidas por arquitectura | ¿Pregunta por la medida? |
| --- | ---: | --- | --- |
| `cancion_petrarquista` | 3 | estancias_consonantes_variables: {7,11} · sin_rima_con_pareado_final: {7,11} · regular_13_versos: {7,11} | **sí** · estancias_consonantes_variables, sin_rima_con_pareado_final |
| `copla_de_pie_quebrado` | 1 | octosilabica_con_quebrados: {4,5,6,7,8} | **sí** · octosilabica_con_quebrados |
| `copla_real` | 2 | con_pie_quebrado: {4,8} · sin_pie_quebrado: {8} | **sí** · con_pie_quebrado |
| `endecasilabo_suelto` | 5 | con_pareados_sin_distico_final: {11} · con_pareados_con_distico_final: {11} · encadenado_interior: {11} · puro_con_distico_final: {11} · puro_sin_distico_final: {11} | no |
| `novena` | 2 | redondilla_quintilla: {8} · quintilla_redondilla: {8} | no |
| `pareado` | 4 | principal: {} · arte_menor: {4,5,6,7,8} · hexasilabico: {6} · octosilabico: {8} | no |
| `redondilla` | 2 | simple: {6,7,8} · doble_enlazada: {8} | **sí** · simple |
| `romance` | 4 | heptasilabico: {7} · hexasilabico: {6} · octosilabico: {8} · endecasilabico: {11} | no |
| `seguidilla` | 2 | compuesta: {5,7} · simple: {5,7} | no |
| `sexteto` | 1 | arte_mayor_consonante_variable: {11,12,14} | **sí** · arte_mayor_consonante_variable |
| `sextilla` | 2 | isometrica: {6,7,8} · pie_quebrado: {4,8} | **sí** · isometrica |
| `sextina` | 2 | doble: {11} · clasica: {11} | no |
| `silva` | 4 | consonante_irregular: {7,11} · consonante_regular: {7,11} · endecasilabica: {11} · libre: {7,11} | no |
| `terceto_encadenado` | 2 | octosilabico: {8} · endecasilabico_consonante: {11} | no |
| `villancico` | 2 | estribillo_inicial: {6,8} · estribillo_tras_primera_copla: {6,8} | **sí** · estribillo_inicial, estribillo_tras_primera_copla |
| `zejel` | 1 | estribillo_y_coplas_monorrimas: {6,8} | **sí** · estribillo_y_coplas_monorrimas |

## 4 · Lo que este contraste deja ver

### La medida se trata de dos maneras distintas

Es el hallazgo más claro, y afecta a ocho formas. Ante el mismo fenómeno —una forma que
admite varias medidas— el catálogo aplica dos criterios opuestos:

| Criterio | Formas |
| --- | --- |
| La medida es **arquitectura**: una por medida, sin pregunta | romance (6, 7, 8, 11), terceto encadenado (8, 11), pareado (6, 8) |
| La medida es **pregunta** dentro de una sola arquitectura | redondilla (6, 7, 8), sextilla (6, 7, 8), sexteto (11, 12, 14), villancico (6, 8), zéjel (6, 8) |

La ontología tiene la regla escrita: se pregunta si la norma admite que eso varíe **de una
unidad a otra dentro de la misma secuencia**. En una forma isosilábica no puede: una tirada
de redondillas no cambia de medida a mitad de camino, y si cambia, empieza otra secuencia.

La ficha de la redondilla ya lo resolvió —«por su isosilabismo, las medidas 6, 7 y 8 son
tres arquitecturas y no una elección»— pero **el dato no lo refleja**: sigue habiendo una
sola arquitectura `simple` con tres esquemas métricos y una pregunta. Es una decisión
tomada y sin aplicar.

Si el IP confirma que el mismo criterio vale para la sextilla isométrica, se cierra de una
vez:

- el defecto **D12** de la sextilla;
- la pregunta 2 de «coplas y sextillas» sobre si 6, 7 y 8 son repertorio cerrado, que pasa a
  ser «tres arquitecturas» en vez de «tres opciones»;
- y la divergencia pendiente de la redondilla.

El villancico y el zéjel son distintos: ahí la medida no es de la unidad entera sino de sus
secciones, y la pregunta 3 de cada ficha sigue abierta con razón.

### Los vecindarios piden una decisión de género, no una fusión

Los cinco vecindarios comparten extensión y régimen de rima y se separan por la medida. Eso
es un criterio real —el sexteto es de arte mayor, la sextilla de arte menor, el sexteto-lira
heterométrico— y no hay nada que fusionar. Lo que falta es decir si hay un género por
encima y declararlo:

- **Seis versos consonantes** es el caso más poblado: cuatro formas, y solo una —la sexta
  rima— declara ser subtipo del sexteto. El sexteto-lira no declara nada, aunque comparta
  extensión y rima. Un pasaje de seis versos consonantes que mezclara 8 y 11 hoy no
  encajaría en ninguna.
- **Cinco versos** —quintilla y lira— y **ocho versos** —octava real y copla de arte mayor—
  no tienen ninguna relación declarada entre sí.
- **Diez y doce versos** sí las tienen, y son las únicas.

La pregunta para el IP no es «¿son la misma forma?» sino **«¿hay un género que el corpus
necesite nombrar, o basta con declarar el parentesco?»**. Declarar el parentesco es barato y
reversible; crear un género general solo se justifica si aparecen pasajes que no encajan en
ninguna especialización.

### Qué mirar de los cambios de nivel

De los ocho movimientos, dos merecen una segunda mirada:

- **`pareado_endecasilabo` y `pareado_de_arte_menor` eran ambos raíces** y hoy uno es
  arquitectura de una forma de nivel serie —`pareados_endecasilabos`— y el otro de una
  estrofa —`pareado`—. Dos entradas paralelas acabaron en niveles distintos.
- **`romance_heroico` es hoy una arquitectura** cuyo nombre tradicional no está registrado
  como denominación, a diferencia de «Romance real» y «Endecha», que sí lo están. Si el
  nombre no vive en ninguna parte, deja de ser recuperable, y eso incumple el principio de
  asignabilidad.

### Las siete formas fijas

Siete formas tienen una sola arquitectura y ninguna pregunta: copla manriqueña, décima
aumentada, décima espinela, doble sextilla, lira, pareados endecasílabos y sexta rima. No es
un error —una forma fija es legítima y el registrador no debe preguntar nada— pero conviene
confirmarlo caso por caso, porque una forma sin ninguna variación admitida es también la
señal de una forma que se describió por su ejemplar más común.
