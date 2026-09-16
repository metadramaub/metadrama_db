# Divergencias del catálogo con sus fuentes

Generado por `node scripts/divergencias-con-las-fuentes.mjs`. **No se edita a mano.**

**Esto no es una lista de errores.** La definición y el uso de cada forma son del proyecto:
se apoyan en las fuentes y pueden apartarse de ellas. Lo que este informe busca es que ningún
desacuerdo quede **sin saberse**. Cada caso lo decide el IP: desviación deliberada o descuido.

Mira **los datos** —esquemas, modalidades, denominaciones—, no la prosa: la definición y la
descripción no repiten lo que los datos enseñan, sino lo que no cabe en ellos.

| | cuántos |
| --- | --- |
| Esquemas de rima que ninguna fuente enuncia | **16** de 147 |
| — de ellos, `definitoria` | **10** |
| Denominaciones sin eco en sus fuentes | 10 de 65 |
| Denominaciones sin fuente declarada | 9 |
| Afirmaciones que matizan en formas con esquema definitorio | 23 |

---

## 1 · Esquemas que el catálogo declara y ninguna de sus seis voces enuncia

El orden es por modalidad: primero lo que **define** una forma, que es donde un desacuerdo
pesa más. Una ausencia aquí puede ser tres cosas: que la notación se escriba distinto —nuestros
corchetes, las mayúsculas—, que el esquema venga de la práctica del corpus y no de un libro, o
que nadie lo sostenga. Solo lo tercero es un problema, y distinguirlo exige abrir la fuente.

| forma | arquitectura | notación | modalidad |
| --- | --- | --- | --- |
| Décima | Endecasílaba | `abba:accddc` | **definitoria** |
| Décima | Espinela | `abba:accddc` | **definitoria** |
| Décima | Pentasílaba | `abba:accddc` | **definitoria** |
| Décima | Hexasílaba | `abba:accddc` | **definitoria** |
| Décima | Heptasílaba | `abba:accddc` | **definitoria** |
| Redondilla | Doble enlazada | `abba|acca` | **definitoria** |
| Seguidilla | Compuesta | `-a-ab-b` | **definitoria** |
| Seguidilla | Chamberga | `-a-abbccdd` | **definitoria** |
| Septilla enlazada | Octosílaba con quebrado | `[abbcbbc]…` | **definitoria** |
| Sextilla enlazada | Octosílaba con quebrado | `[abbccb]…` | **definitoria** |
| Septeto-lira | Heterométrico consonante | `ababbcc` | **habitual** |
| Terceto | Hexasílabo | `aaa` | **habitual** |
| Terceto | Octosílabo | `aaa` | **habitual** |
| Décima-lira | Heterométrica consonante | `ababcdcdee` | **admitida** |
| Terceto | Octosílabo | `aaa` | **admitida** |
| Terceto | Hexasílabo | `aaa` | **admitida** |

## 2 · Esquemas que las fuentes dan y el catálogo no tiene

Los cuenta la comprobación mecánica nº 2, en
[senales-mecanicas.md](./auditoria-fuentes/senales-mecanicas.md). **Su lista no es una lista de
trabajo**: el volcado de Navarro Tomás lee la `c` como `e` —imprime `abe:abe` donde el libro dice
`abc:abc`— y algunas cadenas son varias estrofas seguidas leídas de corrido. Cada candidato pasa
dos filtros que solo aplica quien abra el libro: que la cadena esté bien leída, y que el esquema
sea de esa forma y no de otra.

Queda fuera de esta vuelta, y sigue pendiente.

## 3 · Denominaciones

### Sin eco: el catálogo las atribuye a una fuente cuya ficha no las menciona

| forma | denominación | fuente que se le atribuye |
| --- | --- | --- |
| Canción petrarquista | Canción extensa | 2016 |
| Cuarteto-lira | Cuarteto alirado | 1972 |
| Décima-lira | Décima-lira | — |
| Novena | Novena de pie quebrado | 1972 |
| Octava-lira | Octava alirada | 1972 |
| Octava-lira | Octava-lira | — |
| Octava-lira | Octeto-lira | 2020 |
| Seguidilla | Bolero | — |
| Seguidilla | Seguiriya | — |
| Versificación irregular | Versificación anisosilábica | 2016 |

### Sin fuente declarada

| forma | denominación |
| --- | --- |
| Décima-lira | Décima-estancia |
| Décima-lira | Décima-lira |
| Lira | Quinteto-lira |
| Lira | Quintilla de Fray Luis de León |
| Octava-lira | Octava-lira |
| Seguidilla | Bolero |
| Seguidilla | Seguiriya |
| Silva | Canción libre |
| Silva | Silva imperfecta |

## 4 · Lo que el catálogo declara fijo y su fuente deja abierto

Afirmaciones que llevan una marca de cautela en formas cuyo esquema de rima es `definitoria`.
**La mayoría no serán nada**: una fuente puede matizar sobre algo que no es lo que el esquema
fija. Pero por aquí salieron, sin buscarlas, el «aunque no es obligatorio» del esquema de la
estancia y el «parecería dudosa la unidad de la novena como estrofa».

| forma | fuente | afirmación | marcas |
| --- | --- | --- | --- |
| Lira | 2020 | `4d50e967` | «suele» |
| Décima | 1969 | `0c07cb3f` | «generalmente» |
| Redondilla | 1972 | `a4c5f781` | «a veces» |
| Redondilla | 2016 | `7535361c` | «normalmente» |
| Romance | 2016 | `755cf2c2` | «suele» |
| Silva | 2016 | `b85a2577` | «generalmente» |
| Silva | 2020 | `5d3cd719` | «normalmente» |
| Décima | 2020 | `49b4e370` | «suele» |
| Endecha real | 2016 | `e5868e5e` | «generalmente» |
| Seguidilla | 2020 | `ac2eb17b` | «normalmente» |
| Seguidilla | 1972 | `22c63f36` | «generalmente» |
| Canción petrarquista | 1972 | `d3241dd6` | «generalmente» |
| Canción petrarquista | 2016 | `cf2dcb07` | «normalmente», «no es obligatorio» |
| Estrofa sáfica | 1972 | `b8d4deb6` | «generalmente» |
| Seguidilla | 2016 | `708ebd3f` | «normalmente», «a veces» |
| Estrofa sáfica | 2014 | `5a352ac6` | «generalmente», «a veces» |
| Lira | 1968 | `9c4dd052` | «generalmente» |
| Canción petrarquista | 2020 | `4c90a1f0` | «suele», «normalmente» |
| Terceto encadenado | 1968 | `80001779` | «generalmente» |
| Seguidilla | 2016 | `bf1583ba` | «a veces» |
| Canción petrarquista | 2014 | `e66e30cc` | «normalmente», «suele» |
| Canción petrarquista | 1968 | `96a4a4bd` | «rara vez» |
| Zéjel | 1969 | `71d1e7df` | «normalmente», «suele» |
