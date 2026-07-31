# Contraste estructural del catálogo poblado

Estado: **para revisar con el IP** · 31 de julio de 2026

El catálogo se pobló forma por forma, y cada forma se decidió con su ficha delante. Este
documento hace la lectura contraria: compara las veinticinco formas **por sus rasgos, no
por sus nombres**, para ver dónde el nombre que instaló la tradición ha separado cosas que
estructuralmente son vecinas, y dónde algo puede estar en un nivel que no le toca.

No propone fusionar formas. La ontología ya resuelve la tensión sin perder nombres:

- el nombre tradicional vive como **denominación**, apuntando al nivel exacto que nombra;
- el parentesco vive como **relación tipada**, que no transmite propiedades;
- el género vive como forma de **grado general**, y el demarcador «ofrece la forma más
  específica que encaje; cuando ninguna corresponde, la general es la respuesta correcta,
  no un consuelo».

Lo que falta no son entidades: son **relaciones sin declarar y niveles sin confirmar**.

## 1 · Vecindarios estructurales

Formas de nivel estrofa cuyas arquitecturas declaran la misma extensión de unidad. Si dos
coinciden en extensión y régimen de rima y solo difieren en la medida, la pregunta es si hay
un género por encima o si la medida basta para separarlas. Una forma aparece en tantos
vecindarios como extensiones declaran sus arquitecturas.

### unidad 4–4

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `redondilla` | especifica | {6, 7, 8} | 4 | **ninguna** |
| `seguidilla` | especifica | {5, 7} | 2 | **ninguna** |

### unidad 5–5

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `quintilla` | especifica | {8} | 1 | ← copla_real compuesta_por |
| `lira` | especifica | {7, 11} | 1 | ← sexteto_lira derivada_de |

### unidad 6–6

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `sexteto` | general | {11, 12, 14} | 3 | **ninguna** |
| `sextilla` | especifica | {4, 6, 7, 8} | 5 | **ninguna** |
| `sexteto_lira` | especifica | {7, 11} | 1 | derivada_de → lira |

### unidad 8–8

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `copla_de_arte_mayor` | especifica | {12} | 1 | **ninguna** |
| `octava_real` | especifica | {11} | 1 | **ninguna** |
| `redondilla` · doble enlazada | especifica | {6, 7, 8} | 4 | **ninguna** |

### unidad 10–10

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `copla_real` | especifica | {4, 8} | 1 | compuesta_por → quintilla · ← decima_espinela sucede_historicamente_a |
| `decima_espinela` | especifica | {8} | 1 | sucede_historicamente_a → copla_real · ← decima_aumentada derivada_de |

### unidad 12–12

| Forma | Grado | Medidas | Arquitecturas | Relación declarada |
| --- | --- | --- | ---: | --- |
| `decima_aumentada` | especifica | {8} | 1 | derivada_de → decima_espinela |
| `sextilla` · doble de pie quebrado | especifica | {4, 6, 7, 8} | 5 | **ninguna** |

**6 vecindarios**, y en ellos **6 formas sin ninguna relación declarada** con sus vecinas.

## 2 · Qué subió y qué bajó de nivel

En el vocabulario heredado, una raíz era de hecho una forma y un hijo era una variante. Al
migrar, algunas raíces pasaron a ser arquitecturas y algunos hijos pasaron a ser formas.
Cada uno de esos movimientos fue una decisión.

### Raíces que hoy son arquitecturas

| Término heredado | Definición | Hoy es |
| --- | --- | --- |
| `terceto_octosilabo` | Adapta a octosílabos los tercetos encadenados endecasílabos de raíz italiana | `terceto_encadenado · octosilabico` |
| `pareado_de_arte_menor` | Un dístico o una serie de dísticos de arte menor | `pareado · cualquier_medida` |
| `pareado_endecasilabo` | — | Respuesta de medida en `pareado · cualquier_medida` |
| `romance_heroico` | Serie indefinida de endecasílabos con rima asonante en los pares | `romance · endecasilabico` |
| `doble_sextilla` | Doce versos en dos sextillas de pie quebrado | `sextilla · doble_pie_quebrado` |
| `sexta_rima` | Sexteto de seis endecasílabos con esquema `ABABCC` | Variedad de `sexteto · endecasilabica` |
| `tercetos_sin_encadenar` | Serie de tercetos sin enlace entre unidades | Los dos esquemas de rima del `terceto` |

### Subtipos que hoy son formas

| Término heredado | Colgaba de | Hoy es |
| --- | --- | --- |
| `terceto_encadenado` | `terceto` | forma `terceto_encadenado` |
| `decima_espinela` | `decima` | forma `decima_espinela` |
| `decima_aumentada` | `decima` | forma `decima_aumentada` |

`copla_manriqueña`, que era hijo de `doble_sextilla` y llegó a ser forma, hoy no es ninguna
de las dos cosas: es la **denominación** del esquema `abcabc:defdef` de la sextilla doble.

## 3 · Señales de que algo puede estar en el nivel equivocado

### Formas con una sola arquitectura y ninguna pregunta

Si una forma no admite ninguna variación, su arquitectura no distingue nada: es la forma
misma. No es un error —una forma fija es legítima y el registrador no debe preguntar nada—
pero conviene confirmarlo, porque una forma sin variación admitida es también la señal de
una forma que se describió por su ejemplar más común.

| Forma | Arquitectura | Unidad | Esquemas |
| --- | --- | --- | ---: |
| `decima_espinela` | `octosilabica` | 10–10 | 2 |
| `decima_aumentada` | `octosilabica` | 12–12 | 2 |
| `lira` | `heptasilabica_endecasilabica` | 5–5 | 2 |

Eran siete y quedan tres. Las otras cuatro —copla manriqueña, doble sextilla, pareados
endecasílabos y sexta rima— no eran formas fijas sino hechos colocados un nivel por encima
del que les correspondía.

### Dónde vive la medida

La ontología dice que la medida es arquitectura cuando la forma es isosilábica: se pregunta
solo si la norma admite que varíe **de una unidad a otra dentro de la misma secuencia**.

| Forma | Arquitecturas | Medidas por arquitectura | ¿Pregunta por la medida? |
| --- | ---: | --- | --- |
| `cancion_petrarquista` | 3 | estancias_consonantes_variables: {7,11} · sin_rima_con_pareado_final: {7,11} · regular_13_versos: {7,11} | **sí** · las dos variables |
| `copla_de_arte_mayor` | 1 | dodecasilabica_compuesta: {12} | no |
| `copla_de_pie_quebrado` | 1 | octosilabica_con_quebrados: {4,5,6,7,8} | **sí** |
| `copla_real` | 1 | octosilabica_consonante: {4,8} | **sí** |
| `endecasilabo_suelto` | 1 | endecasilabica: {11} | no |
| `lira` | 1 | heptasilabica_endecasilabica: {7,11} | no |
| `novena` | 2 | redondilla_quintilla: {8} · quintilla_redondilla: {8} | no |
| `octava_real` | 1 | endecasilabica_consonante: {11} | no |
| `pareado` | 1 | cualquier_medida: {4,5,6,7,8,11,12,14} | **sí** |
| `quintilla` | 1 | octosilabica_consonante: {8} | no |
| `redondilla` | 4 | heptasilabica: {7} · hexasilabica: {6} · octosilabica: {8} · doble_enlazada: {8} | no |
| `romance` | 4 | heptasilabico: {7} · hexasilabico: {6} · octosilabico: {8} · endecasilabico: {11} | no |
| `seguidilla` | 2 | compuesta: {5,7} · simple: {5,7} | no |
| `sexteto` | 3 | endecasilabica: {11} · dodecasilabica: {12} · alejandrina: {14} | no |
| `sexteto_lira` | 1 | heterometrica_consonante: {7,11} | no |
| `sextilla` | 5 | heptasilabica: {7} · hexasilabica: {6} · octosilabica: {8} · pie_quebrado: {4,8} · doble_pie_quebrado: {4,8} | no |
| `sextina` | 2 | doble: {11} · clasica: {11} | no |
| `silva` | 3 | consonante_irregular: {7,11} · consonante_regular: {7,11} · endecasilabica: {11} | no |
| `soneto` | 1 | endecasilabico_consonante: {11} | no |
| `terceto` | 1 | endecasilabico_consonante: {11} | no |
| `terceto_encadenado` | 2 | octosilabico: {8} · endecasilabico_consonante: {11} | no |
| `villancico` | 2 | estribillo_inicial: {6,8} · estribillo_tras_primera_copla: {6,8} | **sí** |
| `zejel` | 1 | estribillo_y_coplas_monorrimas: {6,8} | **sí** |

Ninguna forma isosilábica pregunta ya por su medida. Las cinco que preguntan lo hacen por
otra cosa:

- la **canción**, la **copla real** y la **copla de pie quebrado** preguntan por la medida
  de una **posición** dentro de la unidad, no por la de la unidad entera: dónde cae el
  quebrado y cuánto mide es un hecho que solo el pasaje declara;
- el **pareado** pregunta porque su medida no es normativa en absoluto: la norma dice que
  dos versos riman entre sí y nada más, así que la medida de cada uno la declara el pasaje.
  Es la única forma isosilábica sin repertorio de medidas, y por eso la única donde la
  medida no es arquitectura;
- el **villancico** y el **zéjel** preguntan por la medida de sus **secciones**, y si esos
  repertorios son cerrados sigue siendo cuestión abierta en sus fichas.

## 4 · Lo que este contraste deja ver

### La medida ya se trata de una sola manera

Era el hallazgo más claro del primer contraste: ante el mismo fenómeno —una forma que
admite varias medidas— el catálogo aplicaba dos criterios opuestos. El romance y el terceto
encadenado la trataban como arquitectura; la redondilla, la sextilla y el sexteto, como
pregunta.

Hoy los cinco la tratan igual. La redondilla tiene tres arquitecturas por medida más la
doble enlazada; la sextilla, tres más las dos de pie quebrado; el sexteto, tres de arte
mayor. La regla queda escrita en la ontología y aplicada en el dato.

### Los vecindarios piden una decisión de género, no una fusión

Los seis vecindarios comparten extensión y régimen de rima y se separan por la medida. Eso
es un criterio real —el sexteto es de arte mayor, la sextilla de arte menor, el sexteto-lira
heterométrico— y no hay nada que fusionar. Lo que falta es decir si hay un género por encima
y declararlo:

- **Seis versos consonantes** es el caso más poblado: tres formas y ninguna relación
  declarada entre ellas. El sexteto es la forma **general** del vecindario, pero el
  sexteto-lira no cuelga de él y no debe hacerlo: su heterometría es principio constructivo
  y su genealogía va a la lira, que es lo que el modelo declara. La sextilla se separa por
  el arte menor. Un pasaje de seis versos consonantes que mezclara 8 y 11 sin ser
  sexteto-lira hoy no encajaría en ninguna.
- **Cuatro versos** —redondilla y seguidilla—, **cinco** —quintilla y lira— y **ocho**
  —octava real, copla de arte mayor y redondilla doble— no tienen ninguna relación declarada
  entre sí.
- **Diez y doce versos** sí las tienen, y son las únicas.

La pregunta para el IP no es «¿son la misma forma?» sino **«¿hay un género que el corpus
necesite nombrar, o basta con declarar el parentesco?»**. Declarar el parentesco es barato y
reversible; crear un género general solo se justifica si aparecen pasajes que no encajan en
ninguna especialización.

### Lo que queda en el nivel dudoso

- **`romance_heroico` es hoy una arquitectura** cuyo nombre tradicional no está registrado
  como denominación, a diferencia de «Romance real» y «Endecha», que sí lo están. Si el
  nombre no vive en ninguna parte, deja de ser recuperable, y eso incumple el principio de
  asignabilidad. Lo mismo le ocurre ahora a **«silva libre»**, que pasa a ser un valor de
  rasgo, y una denominación no puede apuntar a un valor de rasgo.
- **Nada distingue dos sextillas consecutivas de una doble sextilla.** Los versos, las
  medidas y el tipo de rima son idénticos; solo cambia si las rimas de la segunda mitad
  dependen de la primera. Hoy lo afirma el editor al elegir arquitectura.
