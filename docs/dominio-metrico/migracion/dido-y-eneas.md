# Migración métrica · Dido y Eneas

Informe para Gaston Gilabert, generado el 2026-09-19. Se
regenera con `npm run migracion:informe`, así que no conviene editarlo a mano. Va acompañado
de un Excel con el mismo nombre, que es lo que hay que devolver rellenado.

## De qué va esto

Estamos trasladando la anotación métrica de las obras al catálogo nuevo, el que se publica en
[recursos/catalogo-metrico](https://versologia.metadrama.org/recursos/catalogo-metrico). La mayor parte del trabajo la hace un programa:
cada término del vocabulario anterior tiene su forma y su arquitectura en el catálogo, y las
tipologías de quintilla, las asonancias de los romances o los esquemas de los sonetos que
anotaste en su día se conservan tal cual. Hay, sin embargo, algunas cosas que el catálogo nuevo
registra y que el vocabulario anterior no recogía, y eso es lo que te pedimos en el Excel. Con
esas respuestas hacemos la migración de una vez y no hace falta que vuelvas a anotar nada.

Mientras tanto tu obra no cambia: en el dashboard sigue tal como está hasta que devuelvas el
Excel. Cuando la migración esté hecha, podrás ver cada secuencia con el editor nuevo y corregir
allí lo que haga falta.

## Tu obra en cifras

- 24 secuencias métricas. De ellas, 16 tienen equivalencia directa en el
  catálogo, 8 llevan además un rasgo (la asonancia de un romance, por ejemplo) y
  0 toman la forma del término padre porque el suyo no tiene equivalencia propia.
- 0 subtipos estróficos (las tipologías de quintilla, estrofa a estrofa), que se conservan sin cambios.
- 7 caracterizaciones por rango, que se convierten en desviaciones o se mantienen como están.

## Qué te pedimos

- 1 decisión sobre pasajes cuyo número de versos no encaja, o sobre tramos que van a unirse en una sola secuencia.
- 30 respuestas, en 6 secuencias, a preguntas que el vocabulario anterior no recogía.
- 17 confirmaciones de respuestas que ya hemos rellenado nosotros.
- 1 verso hipométrico o hipermétrico en los que puedes indicar el número de sílabas si lo tienes a mano. Es opcional.

## Pasajes que no encajan

Son secuencias cuyo número de versos no se corresponde con la forma que tienen asignada, y
tramos que el vocabulario anterior obligaba a dividir. Aparecen en la pestaña **Responder**
del Excel, marcadas como *Decidir*.

- **vv. 169–378** · Sexteto-lira · Heterométrico consonante. En tu obra este pasaje está dividido en 4 secuencias (169–174, 175–180, 181–186, 187–378). En el modelo nuevo pasa a ser una sola, con 35 estrofas de 6 versos, y lo que distinguía a cada parte se conserva en sus estrofas. ¿Es realmente un mismo pasaje?

Cuando un tramo se une en una sola secuencia, los indicadores de escena de las partes se
combinan: basta con que una tenga versos partidos para que la secuencia entera los tenga, y
si las intervenciones de personajes no coinciden quedan como «compartida». La sinopsis del
pasaje la escribes tú; en el Excel van las actuales, una detrás de otra, para partir de ellas.

## Preguntas pendientes

Estas son las preguntas que hace el catálogo nuevo y que no se pueden responder con lo que
había anotado; hace falta mirar el texto. Están en la pestaña **Responder**.

| Versos | Forma | Pregunta | Cómo contestar |
| --- | --- | --- | --- |
| 543–622 | Redondilla · Octosílaba | Esquema de rima · 20 estrofas | Elige en el desplegable. La respuesta vale para todas las estrofas; las que sean distintas, en «Excepciones» (versos: respuesta) |
| 771–942 | Redondilla · Octosílaba | Esquema de rima · 43 estrofas | Elige en el desplegable. La respuesta vale para todas las estrofas; las que sean distintas, en «Excepciones» (versos: respuesta) |
| 1045–1094 | Quintilla · Octosílaba consonante | Esquema de rima, en 10 estrofas (una fila por estrofa) | Elige en el desplegable |
| 1223–1302 | Quintilla · Octosílaba consonante | Esquema de rima, en 16 estrofas (una fila por estrofa) | Elige en el desplegable |
| 2053–2227 | Quintilla · Octosílaba consonante | Esquema de rima · 35 estrofas | Elige en el desplegable. La respuesta vale para todas las estrofas; las que sean distintas, en «Excepciones» (versos: respuesta) |
| 169–378 | Sexteto-lira · Heterométrico consonante | Escribe la sinopsis de la secuencia completa | En «Propuesta» tienes las 4 sinopsis actuales, una detrás de otra, para partir de ellas |

## Respuestas ya rellenas

Estas respuestas se deducen del término que elegiste en su día, y las hemos rellenado
nosotros. Conviene echarles un vistazo por si en alguna estrofa las cosas eran de otra
manera. Están en la pestaña **Confirmar**.

| Versos | Forma | Pregunta | Respuesta | Vocabulario anterior |
| --- | --- | --- | --- | --- |
| 1–168 | Octava real · Endecasílaba consonante | Esquema de rima | ABABABCC en las 21 estrofas | octava_real_regular |
| 169–174 | Sexteto-lira · Heterométrico consonante | Variedad | A2 · AbaBcC | sexteto_lira_a2_AbaBcC |
| 175–180 | Sexteto-lira · Heterométrico consonante | Variedad | A1 · aBaBcC | sexteto_lira_a1_aBaBcC |
| 181–186 | Sexteto-lira · Heterométrico consonante | Variedad | A3 · abaBcC | sexteto_lira_a3_abaBcC |
| 187–378 | Sexteto-lira · Heterométrico consonante | Variedad | A1 · aBaBcC en las 32 estrofas | sexteto_lira_a1_aBaBcC |
| 379–542 | Romance · Octosílabo | Vocales de la asonancia | o-e | romance_o-e |
| 623–770 | Romance · Octosílabo | Vocales de la asonancia | o-a | romance_o-a |
| 943–1044 | Romance · Octosílabo | Vocales de la asonancia | e-a | romance_e-a |
| 1095–1222 | Romance · Octosílabo | Vocales de la asonancia | a-o | romance_a-o |
| 1303–1494 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 48 estrofas | redondilla_regular |
| 1575–1798 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 56 estrofas | redondilla_regular |
| 1877–2052 | Romance · Octosílabo | Vocales de la asonancia | e-e | romance_e-e |
| 2228–2381 | Romance · Octosílabo | Vocales de la asonancia | e-o | romance_e-o |
| 2382–2853 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 118 estrofas | redondilla_regular |
| 2854–2971 | Romance · Octosílabo | Vocales de la asonancia | a-a | romance_a-a |
| 2972–3015 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 11 estrofas | redondilla_regular |
| 3016–3073 | Romance · Octosílabo | Vocales de la asonancia | e-a | romance_e-a |

## Desviaciones

Las caracterizaciones por rango que anotaste, y cómo quedan en el modelo nuevo. Los versos
hipométricos e hipermétricos pasan a ser desviaciones de medida; si tienes a mano el número
de sílabas puedes indicarlo, y si no se registra que el verso tiene menos o más sílabas de
las que le tocan, sin dar una cifra. Están en la pestaña **Desviaciones**.

| Tipo | Rangos | Cómo queda |
| --- | ---: | --- |
| `cantado` | 4 | Se mantiene como está: describe el pasaje, no su métrica |
| `rima_defectuosa` | 2 | Pasa a ser una desviación de rima, y se conserva tu nota |
| `hipometrico` | 1 | Pasa a ser una desviación de medida: el verso tiene menos sílabas de las que le tocan |

## Cómo rellenar el Excel

El Excel tiene cinco pestañas. En tres de ellas hay que escribir —**Responder**, **Confirmar** y **Desviaciones**— y las otras dos son de consulta: **Secuencias**, con todo lo que tiene anotado tu obra, e **Instrucciones**, con este mismo texto. Solo hace falta escribir en las columnas de fondo amarillo, que son «Respuesta», «Excepciones / detalle» y «Comentario». El resto de columnas las genera el programa y las necesita tal cual para poder leer las respuestas, así que conviene no tocarlas.

En **Responder** están las preguntas que no hemos podido contestar con lo que ya tenías anotado. Cada fila corresponde a un pasaje y a una pregunta. Cuando la celda tiene desplegable, basta con elegir; cuando no, la columna «Cómo contestar» explica el formato. Las preguntas que se refieren a cada estrofa aparecen de dos maneras: si son pocas estrofas, hay una fila por estrofa; si son muchas, hay una sola fila cuya respuesta vale para todas, y las estrofas que se aparten de ella se anotan en «Excepciones / detalle» indicando los versos y la respuesta, por ejemplo «191–194: Cruzada · abab; 203–206: Cruzada · abab».

Las filas marcadas como **Decidir** señalan pasajes cuyo número de versos no encaja con la forma que tienen asignada. En ellas hay que elegir en el desplegable qué ocurre y explicarlo al lado. Si se trata de una laguna que no se contó, indica en qué verso está y cuántos versos faltan, porque los añadiremos a la numeración y todo lo que viene después se desplazará. Si lo que falla es el rango, escribe el rango correcto.

En **Confirmar** aparecen las respuestas que hemos rellenado nosotros a partir del término que elegiste en su día: la asonancia de un romance, el esquema de una octava real «regular», o que un endecasílabo suelto «puro» no lleva pareados. Solo hay que revisarlas. Si alguna no es así, elige «No es así» y escribe al lado lo que corresponde.

En **Desviaciones** están los versos hipométricos e hipermétricos, las rimas defectuosas y las lagunas que anotaste, con tus notas, y cómo quedan en el modelo nuevo. Se trasladan tal cual. Si tienes a mano el número de sílabas de algún verso hipométrico o hipermétrico, ponlo en la columna «Sílabas»; si no, se registra simplemente que el verso tiene menos o más sílabas de las que le tocan, sin dar una cifra.

Si algo no está claro o no sabes cómo contestarlo, pregúntaselo a David antes de dejarlo a medias. Una vez hecha la migración podrás ver cada secuencia de tu obra con el editor nuevo en el dashboard y corregir allí lo que haga falta.

Cuando no hay desplegable, los formatos son estos:

- Medidas: el número de sílabas de cada verso, en orden y separados por espacios. Por ejemplo, «7 11 7 7 11 7 11 11».
- Posiciones: en qué versos de la estrofa cae el quebrado y cuántas sílabas tiene cada uno, separados por comas. Por ejemplo, «3: 4, 8: 5» quiere decir que el verso 3 tiene cuatro sílabas y el 8 tiene cinco.
- Esquema de rima: una letra por verso, en mayúscula si el verso es de arte mayor y un guion si queda suelto. Por ejemplo, «aBab-B».
- Excepciones: los versos de la estrofa y la respuesta que le corresponde, separando cada estrofa con punto y coma. Por ejemplo, «191–194: Cruzada · abab; 203–206: Cruzada · abab».

## Todas las secuencias

Para terminar, la lista completa de secuencias con todo lo que la obra tiene anotado de cada
una, salvo la sinopsis y los comentarios internos, de modo que se pueda seguir la migración
sin consultar la base. Cuando un subtipo o una caracterización no ocupa la secuencia entera,
lleva su rango entre paréntesis. La columna «Propuesta» indica cuántas respuestas trae ya la
secuencia: las anotadas son las que se miraron verso a verso en su día y se conservan; las
derivadas se deducen del término y aparecen en la pestaña Confirmar.

| # | Versos | v | Vocabulario anterior | Forma | Arquitectura | Subtipos | Caracterizaciones | Estado | Propuesta | Vía |
| ---: | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1–168 | 168 | `octava_real_regular` | Octava real | Endecasílaba consonante | — | — | lista | 21 derivadas | directa |
| 2 | 169–174 | 6 | `sexteto_lira_a2_AbaBcC` | Sexteto-lira | Heterométrico consonante | — | — | lista | 1 derivada | directa |
| 3 | 175–180 | 6 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrico consonante | — | — | lista | 1 derivada | directa |
| 4 | 181–186 | 6 | `sexteto_lira_a3_abaBcC` | Sexteto-lira | Heterométrico consonante | — | — | lista | 1 derivada | directa |
| 5 | 187–378 | 192 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrico consonante | — | `hipometrico` (190) | lista | 32 derivadas | directa |
| 6 | 379–542 | 164 | `romance_o-e` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 7 | 543–622 | 80 | `redondilla` | Redondilla | Octosílaba | — | — | **Falta:** Esquema de rima | — | directa |
| 8 | 623–770 | 148 | `romance_o-a` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 9 | 771–942 | 172 | `redondilla` | Redondilla | Octosílaba | — | — | **Falta:** Esquema de rima | — | directa |
| 10 | 943–1044 | 102 | `romance_e-a` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 11 | 1045–1094 | 50 | `quintilla` | Quintilla | Octosílaba consonante | — | — | **Falta:** Esquema de rima | — | directa |
| 12 | 1095–1222 | 128 | `romance_a-o` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 13 | 1223–1302 | 80 | `quintilla` | Quintilla | Octosílaba consonante | — | — | **Falta:** Esquema de rima | — | directa |
| 14 | 1303–1494 | 192 | `redondilla_regular` | Redondilla | Octosílaba | — | — | lista | 48 derivadas | directa |
| 15 | 1495–1574 | 80 | `decima_espinela` | Décima | Espinela | — | — | lista | — | directa |
| 16 | 1575–1798 | 224 | `redondilla_regular` | Redondilla | Octosílaba | — | `rima_defectuosa` (1626)<br>`rima_defectuosa` (1792) | lista | 56 derivadas | directa |
| 17 | 1799–1876 | 78 | `terceto_encadenado` | Terceto encadenado | Endecasílabo consonante | — | — | lista | — | directa |
| 18 | 1877–2052 | 176 | `romance_e-e` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 19 | 2053–2227 | 175 | `quintilla` | Quintilla | Octosílaba consonante | — | — | **Falta:** Esquema de rima | — | directa |
| 20 | 2228–2381 | 154 | `romance_e-o` | Romance | Octosílabo | — | `cantado` (2240–2243)<br>`cantado` (2248–2251)<br>`cantado` (2257–2260)<br>`cantado` (2264–2267) | lista | 1 derivada | rasgo + forma del padre |
| 21 | 2382–2853 | 472 | `redondilla_regular` | Redondilla | Octosílaba | — | — | lista | 118 derivadas | directa |
| 22 | 2854–2971 | 118 | `romance_a-a` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 23 | 2972–3015 | 44 | `redondilla_regular` | Redondilla | Octosílaba | — | — | lista | 11 derivadas | directa |
| 24 | 3016–3073 | 58 | `romance_e-a` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |

