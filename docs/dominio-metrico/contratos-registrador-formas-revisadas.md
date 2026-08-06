# Contratos del registrador para formas revisadas

Estado: implementado en el editor V2 · 31 de julio de 2026

Este documento separa lo que el catálogo conoce, lo que el editor debe responder y lo
que se guarda como desviación. Una forma no se considera preparada para el registrador
solo por tener datos normalizados: debe cumplir también este contrato.

| Forma o arquitectura | Se deriva sin preguntar | El editor registra | Compatibilidad del rango |
| --- | --- | --- | --- |
| Romance | octosílabo, asonancia en pares, impares sueltos | vocales de la asonancia | múltiplo de 2 |
| Romancillo hexasílabo | 6 sílabas, asonancia en pares, impares sueltos | cambiar a la arquitectura hexasílaba y elegir las vocales de la asonancia | múltiplo de 2 |
| Romancillo heptasílabo | 7 sílabas, asonancia en pares, impares sueltos | cambiar a la arquitectura heptasílaba y elegir las vocales de la asonancia | múltiplo de 2 |
| Romance heroico | endecasílabo, asonancia en pares, impares sueltos | cambiar a la arquitectura heroica y elegir las vocales de la asonancia | múltiplo de 2 |
| Versificación irregular | no existe norma de forma | únicamente el rango y, si hace falta, una observación | mínimo 2 versos |
| Verso aislado | no existe norma de forma | únicamente la posición y, si hace falta, una observación | exactamente 1 verso |
| Quintilla | 5 octosílabos, consonancia | esquema de cada quintilla | múltiplo de 5 |
| Endecha real | ciclo `7-7-7-11`, asonancia sostenida en el endecasílabo y heptasílabos sueltos | la disposición del pasaje —asonantada, suelta, cruzada, abrazada o con redondilla— y las vocales de la asonancia | múltiplo de 4; múltiplo de 5 en la variedad con redondilla |
| Cuarteto | 4 endecasílabos consonantes con dos rimas | disposición `ABBA` o `ABAB` | múltiplo de 4 |
| Terceto | 3 endecasílabos, consonancia entre dos de los tres | qué verso queda suelto, `A-A` o `-AA`; final esdrújulo si caracteriza | múltiplo de 3 |
| Terceto encadenado | encadenamiento y cierre en serventesio | la medida: endecasílaba u octosílaba | bloques de 3 más el verso final |
| Silva · consonante de orden libre | 7 y 11 sin orden fijo, consonancia y versos sueltos admitidos | cuánto organizan los pareados la serie | abierta |
| Silva · consonante regular | ciclo `7 + 11` y pareados regulares | nada | múltiplo de 2 |
| Silva · endecasilábica | 11 y consonancia | cuánto organizan los pareados la serie | abierta |
| Endecasílabo suelto | 11 y predominio de versos sueltos | si hay pareados intercalados; dístico final y encadenamiento interior si caracterizan | abierta |
| Pareado | dos versos que riman entre sí, `aa` | la medida de cada uno de los dos versos y si la rima es consonante o asonante | múltiplo de 2 |
| Soneto | 14 endecasílabos, `ABBA ABBA`, estructura `4 + 4 + 3 + 3` | esquema de tercetos; final esdrújulo si caracteriza | múltiplo de 14 |
| Villancico | posición de la primera aparición del estribillo y secciones obligatorias | la medida de cada sección, el esquema de cada mudanza, el enlace o vuelta y el tipo de represa | calculada desde cabeza/estribillo, coplas y represas |
| Zéjel | cabeza, mudanza monorrima de 3 versos y vuelta de 1 a la rima del estribillo | la medida de cada sección y la presencia material de la represa | calculada desde cabeza, coplas fijas de 4 y represas |
| Copla real | 10 versos, estructura `5 + 5` y consonancia; el pie quebrado es rasgo admitido | esquema de cada quintilla, reutilizado del de la quintilla, y las posiciones quebradas si las hay | múltiplo de 10 |
| Copla de arte mayor | 8 dodecasílabos compuestos `6 + 6`, consonancia y estructura `4 + 4` | uno de los tres esquemas reconocidos, en cada copla | múltiplo de 8 |
| Copla de pie quebrado (general) | octosílabo dominante, consonancia y unidades de 5–12 versos | extensión de cada unidad, medida o medidas de los quebrados y sus posiciones | cada unidad entre 5 y 12 |
| Sextilla | 6 versos, consonancia y la medida de su arquitectura: 8, 7, 6 o `8-8-4-8-8-4` | nada | múltiplo de 6 |
| Sextilla · doble de pie quebrado | 12 versos en dos sextillas `8-8-4-8-8-4` con rimas independientes | marcar la disposición si es la manriqueña `abcabc:defdef` | múltiplo de 12 |
| Décima espinela | 10 octosílabos, consonancia, `abbaaccddc` y estructura `4 + 2 + 4` | nada | múltiplo de 10 |
| Décima aumentada | 12 octosílabos, consonancia, `abbaaccddeed` y pausa `4 + 8` | nada | múltiplo de 12 |
| Redondilla · octosilábica, heptasilábica o hexasilábica | unidades de 4 versos consonantes de la medida de su arquitectura | disposición `abba` o `abab` | múltiplo de 4; materializa una unidad por cada 4 versos |
| Redondilla · doble enlazada | unidades de 8 octosílabos, `abba:acca` | nada | múltiplo de 8; materializa una unidad por cada 8 versos |
| Octava real | 8 endecasílabos consonantes y `ABABABCC` | final esdrújulo, solo si caracteriza | múltiplo de 8 |
| Novena | 9 octosílabos consonantes y orden de secciones según arquitectura | esquema de la redondilla y de la quintilla en cada unidad | múltiplo de 9; materializa una novena y sus dos partes por cada 9 versos |
| Lira | 5 versos, esquema `7-11-7-7-11`, consonancia y `aBabB` | nada | múltiplo de 5 |
| Sexteto-lira | 6 versos, medidas y rima de cada variedad reconocida | variedad reconocida por estrofa; final esdrújulo si caracteriza | múltiplo de 6; materializa una unidad por cada 6 versos |
| Sexteto | 6 versos de arte mayor consonantes, de la medida de su arquitectura: 11, 12 o 14 | esquema de rima de cada unidad; `ABABCC` es la variedad llamada sexta rima | múltiplo de 6; materializa una unidad por cada 6 versos |
| Seguidilla simple | 4 versos, `7-5-7-5`, asonancia `-a-a` | nada | múltiplo de 4; materializa una unidad por cada 4 versos |
| Seguidilla compuesta | 7 versos, `7-5-7-5 + 5-7-5`, asonancia `-a-a + b-b` y secciones | nada | múltiplo de 7; materializa una unidad por cada 7 versos |
| Sextina clásica | 39 endecasílabos, 6 estrofas × 6 + remate de 3 y permutación fija de seis palabras | nada | múltiplo de 39; materializa estrofas y remate |
| Sextina doble | 75 endecasílabos, 12 estrofas × 6 + remate de 3 y dos ciclos de permutación | nada | múltiplo de 75; materializa estrofas y remate |
| Canción petrarquista · estancias variables | 3 o más estancias, consonancia y repetición de la norma entre estancias | extensión, medida por posición y esquema de la primera estancia | calculada desde estancias de 5–20 versos y remate opcional |
| Canción petrarquista · regular de 13 | 3 o más estancias, esquema `abCabC:cdeeDfF` | nada salvo número de estancias y remate | calculada desde estancias de 13 versos y remate opcional |
| Canción sin rima | cuerpo suelto y pareado consonante final en cada estancia | extensión del cuerpo, medida por posición y final esdrújulo si caracteriza | calculada desde cuerpos de 3–18 versos más pareado final |

## Recorridos mínimos

- Romance: forma, vocales de la asonancia y guardar.
- Romancillos: forma Romance, cambiar a la arquitectura hexasílaba o heptasílaba,
  vocales de la asonancia y guardar.
- Romance heroico: forma Romance, cambiar la arquitectura principal a Heroica,
  vocales de la asonancia y guardar.
- Tramos sin forma: elegir Versificación irregular o Verso aislado, delimitar el
  rango y guardar; no se solicita arquitectura ni desviaciones.
- Quintilla: forma, esquema de la primera unidad, aplicar a todas si coincide y corregir
  solo las excepciones.
- Terceto: forma, verso suelto de la primera unidad y aplicar a todas; el rasgo
  esdrújulo queda vacío por defecto.
- Terceto encadenado: forma, arquitectura si se solicita y guardar.
- Silva: forma, arquitectura y organización en pareados; la regular no pregunta nada.
- Endecasílabo suelto: forma, pareados intercalados y, si caracterizan, dístico final o
  encadenamiento interior.
- Pareado: forma, medida de los dos versos del primer dístico y tipo de rima; aplicar a
  toda la tirada y cambiar solo los que difieran.
- Soneto: forma, esquema de los tercetos y guardar.
- Villancico: forma, medida de cada sección y únicamente las unidades que realmente
  aparecen.
- Zéjel: forma, medida de cada sección, extensión de la cabeza y presencia material de la
  represa; la
  estructura `BBB + A` no se pregunta.
- Copla real: forma y los dos esquemas de quintilla; marcar una o dos posiciones
  quebradas solo si la copla las tiene.
- Décima espinela y décima aumentada: forma y guardar; todas sus propiedades
  normativas se derivan.
- Redondilla: forma, arquitectura de la medida y distribución de la primera unidad;
  aplicar la respuesta a toda la tirada y cambiar solo las unidades distintas.
- Redondilla doble enlazada: forma, arquitectura y guardar; el registrador deriva las
  unidades de ocho versos.
- Sextilla: forma, arquitectura de la medida y guardar; en la doble de pie quebrado se
  marca además si la disposición es la manriqueña.
- Octava real: forma y guardar; el rasgo esdrújulo queda vacío por defecto.
- Novena: forma, orden de secciones y los dos esquemas de la primera unidad; aplicar a
  toda la tirada y cambiar solo las unidades distintas.
- Lira: forma y guardar; toda la norma se deriva.
- Sexteto-lira: forma, variedad reconocida de la primera unidad y aplicar a todas; cambiar solo
  las estrofas diferentes y dejar vacío el rasgo esdrújulo por defecto.
- Sexteto: forma, arquitectura de la medida y esquema de la primera unidad; aplicar a
  todas y cambiar solo los sextetos diferentes.
- Seguidilla: forma, arquitectura simple o compuesta y guardar; toda la norma se
  deriva.
- Sextina: forma, arquitectura clásica o doble y guardar; toda la estructura y la
  repetición léxica se derivan.
- Canción petrarquista: forma y arquitectura; en la regular solo se añaden las
  estancias. En las variables se caracteriza la primera estancia y se aplican su
  extensión, medidas y rima a las demás.

## Criterio de las desviaciones

Una opción admitida nunca se registra como desviación. Se usa una desviación cuando un
tramo incumple la arquitectura o la elección realizada: medida distinta, ruptura de
rima, ausencia o adición estructural, repetición anómala o rasgo observado no previsto.
La ausencia de desviaciones significa conformidad con la norma seleccionada.

La laguna de una fuente no autoriza un rango incompatible. El cómputo incorpora la
posición del verso ausente y la laguna se localiza en el registro correspondiente.

## Límite de esta revisión

Estos contratos cubren únicamente las formas revisadas en profundidad. Las demás formas
del catálogo pueden verse en el editor V2, pero no deben considerarse editorialmente
validadas hasta pasar por la misma matriz.
