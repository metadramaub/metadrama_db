# Revisión del vocabulario legado

*Contrastada con la base en vivo el 24 de agosto de 2026. Sustituye a la lectura parcial que
sostenía el [informe de equivalencias](./informe-equivalencias.md): aquella miraba solo el nombre
del término y se dejaba fuera tres depósitos de información que el vocabulario viejo sí guardaba.*

## Lo que el vocabulario legado guarda de verdad

`vocabularios` no es una lista de nombres. Cada término de categoría `estrofa_tipo` —hay **123**—
lleva campos descriptivos que son ya datos de migración:

| Campo | Poblado | Qué aporta |
|---|---|---|
| `definicion` | 117 | prosa; no migra |
| `arte_metrico` | 96 | arte mayor / menor / mixto |
| `tipo_rima_id` | 86 | consonante, asonante, otras |
| `naturaleza_estrofica_id` | 76 | estrofa cerrada / tirada abierta |
| `tamanio_unidad_estrofica` | 67 | versos de la unidad |
| `patron_especifico` | **42** | **el esquema de rima, literal** |
| `equivalencias` | 13 | notas sueltas |
| `numero_silabas` | 0 | nunca se usó |

Y **el árbol**: 89 de los 123 términos cuelgan de un padre. La jerarquía distingue la forma de sus
realizaciones, y ahí es donde está lo fino —los cuatro sonetos por cómo cierran sus tercetos, los
seis endecasílabos sueltos por su grado de rima, las ocho quintillas por su disposición—.

Además, dos depósitos fuera de `vocabularios`:

- **`secuencias_subtipos_estrofa`** — un subtipo **por rango de versos dentro de la secuencia**, es
  decir estrofa a estrofa. Hoy guarda **336 filas** en **11 secuencias**, todas de quintilla.
- **`equivalencias_respuestas_legadas`** — tabla ya construida que permite que **un término legado
  declare varias respuestas** del editor nuevo, sorteando el `UNIQUE` de `origen_termino_id`. Hoy
  tiene **26 filas**, y desde C20 cada una **describe la respuesta** —arquitectura, dimensión,
  parte y entidad— en vez de apuntar a una pregunta, así que alcanza también a las heredadas.

## El estado real de la migración

Contando **solo las preguntas obligatorias** —`selecciones_min >= 1`—, que es lo que de verdad
impide guardar:

| | |
|---|---|
| Secuencias anotadas | **263** |
| Con propuesta completa hoy | **128** |
| Incompletas | **135** |

*El recuento anterior daba 139 incompletas porque exigía también las preguntas opcionales. «Final
acentual», «Dístico final» y «Encadenamiento interior» son opcionales: no responderlas no deja
ningún hueco. Eso solo ya reconcilia la octava real y siete de los ocho sonetos.*

Y las 135 se concentran en **una lista corta de términos**:

| Término legado | Sec. | Qué falta | ¿Recuperable? |
|---|---|---|---|
| `redondilla` | 37 | esquema de rima, por estrofa | **no** — el término es genérico |
| `redondilla_regular` | 26 | esquema de rima | **sí** — `patron_especifico` = `abba` |
| `endecasilabo_suelto_puro` | 26 | organización en pareados, densidad | **sí** — lo dice el nombre |
| `quintilla` | 18 | esquema, por estrofa | **11 sí** — subtipos anotados; 7 no |
| `silva_de_consonantes_irregular` | 11 | densidad de rima | a decidir |
| `copla_real_sin_quebrado` / `_de_pie_quebrado` | 3 | quebrados + dos esquemas | **parcial** |
| `soneto_regular_ABBAABBACDCDCD` | 1 | esquema de los cuartetos | **sí** — `ABBA`, en el patrón |
| `romancillo_heptasilabo` | 1 | vocales de la asonancia | **no** |
| `sexteto_lira_a4_aBaBCC` | 1 | variedad A4 | pendiente de las aliradas |
| `octava_lira` | 1 | forma entera | pendiente de las aliradas |

*Las nueve secuencias de versificación irregular ya salen completas: no tienen nada que preguntar.*

## Lo que cada término puede declarar

### Se declara moviendo la reclamación al esquema

La vista deriva forma y arquitectura **desde el esquema**, de modo que reclamar el esquema lleva las
tres cosas y reclamar la arquitectura solo lleva dos. Hoy hay reclamaciones puestas en el sitio
pobre:

- `redondilla_regular` reclama la arquitectura Octosilábica → debe reclamar su esquema **`abba`**.
- `redondilla_cruzada` no reclama nada → esquema **`abab`**.

### Se declara con varias respuestas a la vez

`equivalencias_respuestas_legadas`, un término y varias filas. Los seis endecasílabos sueltos son el
caso claro, porque el nombre legado **es** la respuesta:

| Término | Organización en pareados | Densidad de rima |
|---|---|---|
| `endecasilabo_suelto_puro` | Ninguna | Ninguna |
| `endecasilabo_suelto_puro_sin_distico_final` | Ninguna | Ninguna |
| `endecasilabo_suelto_con_pareados` | Ocasionales | Esporádica |
| `..._con_pareados_y_sin_distico_final` | Ocasionales | Esporádica |

El sufijo `_sin_distico_final` responde además la pregunta opcional «Dístico final», y
`endecasilabo_suelto_encadenado`, la de «Encadenamiento interior».

Igualmente, los cinco sonetos comparten `ABBA` en los cuartetos, y los tres que ya lo declaran lo
hacen por esta vía; falta `soneto_regular_ABBAABBACDCDCD`, que es el más usado.

### Se traslada desde la anotación, sin proponer nada

Las **336 tipologías de quintilla** de `secuencias_subtipos_estrofa` van a
`anotacion_elecciones.posicion_unidad`. La granularidad coincide: la pregunta «Esquema de
rima» de la quintilla tiene `alcance = 'unidad'`. **No es una propuesta, es la anotación misma.**

### Los esdrújulos

Seis términos —canción, endecasílabo suelto, octava real, sexteto-lira, soneto, terceto— llevan el
sufijo `_de_esdrujulos`. Es **un solo rasgo** dicho seis veces, y por el `UNIQUE` de
`origen_termino_id` un valor de rasgo solo puede reclamar un término. Se resuelven por
`equivalencias_respuestas_legadas`, que no tiene esa restricción. Ninguno se ha usado nunca.

## Tres clases de dato, que el informe debe distinguir

1. **Anotado** — las 336 tipologías. Alguien las miró verso a verso. Se trasladan.
2. **Derivado** — «esta secuencia se catalogó `redondilla_regular`, luego sus veinte estrofas serían
   todas `abba`». Es una inferencia sobre el término, no una observación, y **puede ser falsa
   estrofa a estrofa**. Es lo que hay que revisar.
3. **Hueco** — la pregunta que nadie respondió porque el vocabulario viejo no la hacía.

Si el informe no las separa, la revisión se vuelve ciega o inútilmente lenta.

## Errores del vocabulario legado, anotados sin corregir

- `quintilla_5_aabba` y `quintilla_7_ababb` declaran `tamanio_unidad_estrofica = 6`. Son de cinco.
- Una secuencia de quintilla tiene 52 subtipos para 51 estrofas.

*No se tocan: el vocabulario legado es el registro de lo que se anotó, y corregirlo borraría la
prueba. Se arreglan al trasladar.*
