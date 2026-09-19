# Migración métrica · Cegar para ver mejor

Informe para Gabriel López, generado el 2026-09-19. Se
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

- 3 secuencias métricas. De ellas, 2 tienen equivalencia directa en el
  catálogo, 1 llevan además un rasgo (la asonancia de un romance, por ejemplo) y
  0 toman la forma del término padre porque el suyo no tiene equivalencia propia.
- 0 subtipos estróficos (las tipologías de quintilla, estrofa a estrofa), que se conservan sin cambios.
- 0 caracterizaciones por rango, que se convierten en desviaciones o se mantienen como están.

## Qué te pedimos

- 3 confirmaciones de respuestas que ya hemos rellenado nosotros.

## Respuestas ya rellenas

Estas respuestas se deducen del término que elegiste en su día, y las hemos rellenado
nosotros. Conviene echarles un vistazo por si en alguna estrofa las cosas eran de otra
manera. Están en la pestaña **Confirmar**.

| Versos | Forma | Pregunta | Respuesta | Vocabulario anterior |
| --- | --- | --- | --- | --- |
| 1–244 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 61 estrofas | redondilla_regular |
| 245–420 | Romance · Octosílabo | Vocales de la asonancia | a-e | romance_a-e |
| 421–484 | Redondilla · Octosílaba | Esquema de rima | Abrazada · abba en las 16 estrofas | redondilla_regular |

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
| 1 | 1–244 | 244 | `redondilla_regular` | Redondilla | Octosílaba | — | — | lista | 61 derivadas | directa |
| 2 | 245–420 | 176 | `romance_a-e` | Romance | Octosílabo | — | — | lista | 1 derivada | rasgo + forma del padre |
| 3 | 421–484 | 64 | `redondilla_regular` | Redondilla | Octosílaba | — | — | lista | 16 derivadas | directa |

