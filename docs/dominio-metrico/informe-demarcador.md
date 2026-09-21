# Con qué trabaja el demarcador

Generado el 2026-09-21 desde la base enlazada con `npm run demarcador:informe`. **No se edita a mano.**

Este documento dice **qué material tiene** el demarcador. El **porqué** de cada decisión —las dos
escalas del catálogo, cómo se puntúa la compatibilidad, cómo se elige la pregunta siguiente y
cuándo se detiene el recorrido— está en [demarcador-metrico.md](./demarcador-metrico.md), escrito a
mano porque cambia cuando alguien cambia de idea, no cuando alguien toca el catálogo.

## 1 · Qué entra y qué queda fuera

El demarcador compila una **hipótesis por arquitectura**: la forma es la identidad del resultado y
la arquitectura, la precisión de su realización.

|  | cuántas |
|---|---|
| Formas que el demarcador puede proponer | 47 |
| Registros que no son forma (tramos sin forma) | 2 |
| **Arquitecturas que compila** | **92** |
| Arquitecturas activas pero no demarcables | 5 |
| Arquitecturas inactivas | 3 |

> **Sextina no tiene ninguna arquitectura demarcable**, así que el demarcador no puede proponerla nunca.

## 2 · Qué puede preguntar

Cada dimensión sale de una parte distinta del catálogo. La **cobertura** dice cuántas de las
arquitecturas compiladas la declaran: una dimensión que casi nadie declara separa poco, por muy
fácil de responder que sea.

| familia | de dónde sale | cobertura |
|---|---|---|
| Metro | esquemas métricos: posiciones y opciones | 92 de 92 |
| Extensión | reglas de longitud derivadas de la unidad | 82 de 92 |
| Rima | esquemas de rima y su tipo | 84 de 92 |
| Estructura | secciones internas y su orden | 29 de 92 |
| Rasgo | rasgos marcados como demarcables | 30 de 92 |

## 3 · Los rasgos, y por qué algunos no se preguntan

Un rasgo solo se pregunta si el catálogo lo marca `demarcable`. La regla que hay detrás es que la
interfaz solo debe preguntar **hechos que el usuario pueda observar**: lo demás se calcula o se
calla.

| rasgo | se pregunta | observabilidad | valores | lo declaran |
|---|---|---|---|---|
| Densidad de rima | sí | directa | 4 | 20 |
| Dístico final | sí | directa | 1 · es de presencia | 2 |
| Organización en pareados | sí | directa | 5 | 8 |
| Pie quebrado | sí | directa | booleano | 15 |
| Encadenamiento interior | **no** | especializada | 1 · es de presencia | 1 |
| Final acentual | **no** | directa | 2 | 16 |
| Vocales de la asonancia | **no** | especializada | 20 | 28 |

*Un rasgo de **un solo valor** es de presencia: su contenido entero es estar presente, así que se
pregunta como booleano —«¿se observa…?», sí o no— y no como una lista de un elemento. Sin eso, un
pasaje que **no** lo lleva no se podría decir, y el rasgo no podría contradecir a ninguna forma.*

## 4 · Contra quién se contrasta una hipótesis

El recorrido de comprobación no compara la forma propuesta contra el catálogo entero, sino contra
**sus rivales**: los que el catálogo declara en `forma_relaciones`, más los que las respuestas
hayan puesto arriba, más los estructuralmente próximos cuando no hay contraste declarado. Estas
son las declaraciones de hoy, y su nota es lo que la pantalla enseña al terminar.

| par | relación | qué las separa, según el catálogo |
|---|---|---|
| Canción ↔ Novena-lira | contrasta_con | A partir de los nueve versos las dos formas coinciden en materia y en extensión —heptasílabos y endecasílabos consonantes, repetidos sin cambio de una… |
| Canción ↔ Septeto-lira | contrasta_con | Por debajo de los nueve versos una estrofa de heptasílabos y endecasílabos consonantes, repetida sin cambio, pertenece a la serie alirada. Morley y Br… |
| Canción ↔ Octava-lira | contrasta_con | Las dos formas comparten la materia, y la extensión es el criterio que las separa: el catálogo sitúa el límite inferior de la estancia en nueve versos… |
| Canción ↔ Silva | contrasta_con | Las dos combinan heptasílabos y endecasílabos sin medida fija por posición. La canción repite en cada estancia el patrón que fijó la primera; la silva… |
| Canción ↔ Lira | contrasta_con | Por debajo de los nueve versos una estrofa de heptasílabos y endecasílabos consonantes, repetida sin cambio, es alirada, y la lira es la menor de esas… |
| Canción sin rima ↔ Canción | contrasta_con | Misma materia, misma repetición del patrón que fijó la primera estancia y mismo cierre en pareado; lo que las separa es el régimen. La canción es siem… |
| Canción sin rima ↔ Silva | contrasta_con | Las dos combinan heptasílabos y endecasílabos y las dos pueden no rimar. La diferencia es que aquí hay estancia: una estrofa de medida fijada por la p… |
| Copla real ↔ Novena | contrasta_con | Las dos reparten octosílabos consonantes en dos miembros con rimas independientes, y se separan por cómo los reparten: la copla real junta dos quintil… |
| Endecasílabo encadenado ↔ Endecasílabo suelto | contrasta_con | Comparten la serie sin estrofa y sin rima entre los finales de verso; los separa que en el encadenado todos los versos riman, cada uno con el interior… |
| Endecasílabo suelto ↔ Silva | contrasta_con | En el endecasílabo suelto predominan los versos sin rima; en la silva endecasílaba predominan los rimados. |
| Octava aguda ↔ Copla castellana | contrasta_con | Las dos reparten ocho versos en dos semiestrofas de cuatro, y se separan por lo que su norma fija: la castellana fija las cuatro rimas y no dice nada … |
| Octava real ↔ Copla de arte mayor | contrasta_con | Las dos reparten ocho versos de arte mayor en dos mitades, y se separan por cómo las atan. La copla de arte mayor las enlaza —una rima común a los dos… |
| Oncena ↔ Novena | contrasta_con | Las dos reparten octosílabos consonantes en dos miembros de distinta extensión, y se separan por cuáles: la novena junta una redondilla con una quinti… |
| Redondilla enlazada ↔ Copla de arte menor | contrasta_con | Las dos enlazan redondillas por la rima, y se separan por dónde: la copla de arte menor es una estrofa de ocho versos que se cose por dentro —una rima… |
| Romance heroico ↔ Endecasílabo suelto | contrasta_con | Las dos son series de endecasílabos, y lo único que las separa es la asonancia de los pares: sostenida en el romance heroico, ausente en el suelto. Cu… |
| Septeto ↔ Septilla | contrasta_con | Son la misma estrofa de siete versos en las dos artes: septilla en arte menor, septeto en arte mayor, y séptima como nombre común. Es el mismo reparto… |
| Septeto-lira ↔ Septeto | contrasta_con | Las dos miden siete versos de arte mayor, y se separan por la medida: el septeto es isosilábico y el septeto-lira mezcla heptasílabos y endecasílabos,… |
| Septilla enlazada ↔ Septilla | contrasta_con | Las dos miden siete octosílabos, y se separan por si la estrofa se cierra: la septilla reparte sus versos en redondilla y terceto y agota sus rimas de… |
| Sexteto ↔ Sextina | contrasta_con | «Sextina» designa la composición de palabras finales repetidas, mientras que «sexta rima» —también llamada «sextina real» por parte de la bibliografía… |
| Sexteto ↔ Sexteto-lira | contrasta_con | Las dos son estrofas de seis versos con rima consonante y las dos suelen cerrar en pareado; lo que las separa es la medida. El sexteto la mantiene igu… |
| Sextilla ↔ Sexteto | contrasta_con | La misma estrofa de seis versos, separada por el arte de sus versos: se llama sextilla cuando son de arte menor y sexteto cuando son de arte mayor. Es… |
| Silva ↔ Pareado | contrasta_con | La silva de consonantes son pareados de siete y once, y lo único que la mantiene silva es que alterna las dos medidas. Sin esa heterometría no queda n… |
| Verso aislado ↔ Versificación irregular | contrasta_con | Son las dos salidas del catálogo cuando un pasaje no deja reconocer ninguna forma, y se reparten por extensión: el verso aislado es uno solo; desde do… |
| Villancico ↔ Zéjel | contrasta_con | Ambas formas articulan estribillo y coplas. El zéjel fija una mudanza monorrima de tres versos seguida directamente por la vuelta. El villancico emple… |
| Copla castellana ↔ Copla de arte menor | derivada_de | Las dos son ocho octosílabos en dos grupos de cuatro, y se separan por una sola cosa: la de arte menor comparte una rima entre las semiestrofas y no p… |
| Endecha real ↔ Romancillo | derivada_de | Deriva del romance heptasílabo, pero alarga a endecasílabo el cuarto verso de cada cuarteto. Conserva la asonancia única sostenida durante toda la com… |
| Quintilla ↔ Redondilla | derivada_de | Se formó añadiendo un quinto verso a la redondilla, y de ahí que comparta con ella sus dos clases de rima. El origen no alcanza, sin embargo, a todas … |
| Romance heroico ↔ Romance | derivada_de | El romance en endecasílabos: la misma serie de pares asonantados e impares sueltos, en el verso de arte mayor. Es el más tardío de los romances y el ú… |
| Romancillo ↔ Romance | derivada_de | El romance en versos de menos de ocho sílabas. Es la misma serie —impares sueltos, una sola asonancia en los pares— y todo lo que vale para el romance… |
| Septeto-lira ↔ Sexteto-lira | derivada_de | Es el sexteto-lira con un verso más: la misma combinación de heptasílabos y endecasílabos y el mismo pareado final, con una clase recogida antes del r… |
| Septilla ↔ Septeto | derivada_de | La octosílaba se hizo sobre la endecasílaba. Navarro Tomás describe la séptima como «una estrofa endecasílaba de antigua tradición provenzal, compuest… |
| Sexteto-lira ↔ Lira | derivada_de | Es una variedad de la lira garcilasiana ampliada a seis versos, no una modificación del sexteto isosilábico: conserva la combinación de heptasílabos y… |

**13 formas no declaran ningún contraste.** Para ellas el recorrido de comprobación
cae en la afinidad estructural —las que predicen lo mismo en más dimensiones—, que cubre el hueco
pero no sabe lo que sabe un filólogo:

> Canción petrarquista · Copla manriqueña · Cuarteto · Cuarteto-lira · Décima · Décima-lira · Estrofa sáfica · Seguidilla · Sextilla enlazada · Sextina · Soneto · Terceto · Terceto encadenado

## 5 · Conjuntos de medidas: admitir no es mezclar

Un esquema de `tipo_secuencia = conjunto` enumera las medidas admitidas. **`medida_uniforme`**
decide qué significa esa lista: si es `true`, la arquitectura admite *cualquiera* de ellas pero una
sola cada vez —el pareado isométrico mide igual sus dos versos—; si es `false`, las **combina** dentro
de la unidad, como la silva alterna siete y once. Declararlo mal hace que el demarcador resuma el
repertorio en «mixto» y **contradiga** a la forma en la primera pregunta.

| forma · arquitectura | medidas admitidas | qué declara |
|---|---|---|
| Pareado · Isométrico | 8 | una cualquiera de ellas |
| Villancico · Estribillo inicial | 2 | una cualquiera de ellas |
| Zéjel · Estribillo y coplas monorrimas | 2 | una cualquiera de ellas |
| Canción · Estancias consonantes variables | 2 | las combina |
| Canción petrarquista · Regular de 13 versos | 2 | las combina |
| Canción sin rima · Sin rima, con pareado final | 2 | las combina |
| Cuarteto-lira · Heterométrico consonante | 2 | las combina |
| Décima-lira · Heterométrica consonante | 2 | las combina |
| Novena-lira · Heterométrica consonante | 2 | las combina |
| Octava-lira · Heterométrica consonante | 2 | las combina |
| Pareado · Alirado | 2 | las combina |
| Silva · Consonante de orden libre | 2 | las combina |
| Silva · Libre | 2 | las combina |
| Silva · Arromanzada | 2 | las combina |

## 6 · Avisos

- **Hay contrastes declarados contra formas que el demarcador no puede proponer**: Versificación irregular, Verso aislado. El contraste no llega a usarse.
- **1 rasgo de presencia se pregunta como booleano**: Dístico final. Si ganara un segundo valor dejaría de ser una presencia, y la pregunta cambiaría sola.

