# Contratos del registrador para formas revisadas

Estado: implementado en el editor V2 · 29 de julio de 2026

Este documento separa lo que el catálogo conoce, lo que el editor debe responder y lo
que se guarda como desviación. Una forma no se considera preparada para el registrador
solo por tener datos normalizados: debe cumplir también este contrato.

| Forma o configuración | Se deriva sin preguntar | El editor registra | Compatibilidad del rango |
| --- | --- | --- | --- |
| Romance | octosílabo, asonancia en pares, impares sueltos | vocales de la asonancia | múltiplo de 2 |
| Quintilla | 5 octosílabos, consonancia | esquema de cada quintilla | múltiplo de 5 |
| Terceto | 3 endecasílabos, consonancia 1-3 | final esdrújulo, solo si caracteriza la secuencia | múltiplo de 3 |
| Terceto encadenado | encadenamiento y cierre `YZYZ` | configuración métrica, si hay más de una | bloques de 3 más el verso final |
| Tercetos sin encadenar | endecasílabo y ausencia de enlace entre unidades | `A-A` o `-AA` | múltiplo de 3, mínimo 6 |
| Silva libre | norma completa de la configuración | nada más | abierta |
| Silva de consonantes regular | pareados `7 + 11` | nada más | múltiplo de 2 |
| Silva de consonantes irregular | 7 y 11, pareados predominantes | nada más | abierta |
| Silva endecasílaba | 11, predominio de rimados, pareados no sistemáticos | nada más | abierta |
| Endecasílabo suelto | norma de la configuración elegida | nada más | abierta |
| Pareados endecasílabos | dísticos consonantes de 11 | nada más | múltiplo de 2 |
| Soneto | 14 endecasílabos, `ABBA ABBA`, estructura `4 + 4 + 3 + 3` | esquema de tercetos; final esdrújulo si caracteriza | múltiplo de 14 |
| Villancico | posición de la primera aparición del estribillo y secciones obligatorias | medidas, esquema de cada mudanza, enlace o vuelta y tipo de represa | calculada desde cabeza/estribillo, coplas y represas |
| Zéjel | cabeza, mudanza monorrima de 3 versos y vuelta de 1 a la rima del estribillo | medidas y presencia material de la represa | calculada desde cabeza, coplas fijas de 4 y represas |
| Copla real | 10 versos, estructura `5 + 5`, consonancia y presencia de pie quebrado según configuración | esquema de cada quintilla y posiciones quebradas cuando corresponda | múltiplo de 10 |
| Copla de arte mayor | 8 dodecasílabos compuestos `6 + 6`, consonancia y estructura `4 + 4` | uno de los tres esquemas reconocidos | múltiplo de 8 |
| Copla de pie quebrado (residual) | octosílabo dominante, consonancia y unidades de 5–12 versos | extensión de cada unidad, medida o medidas de los quebrados y sus posiciones | cada unidad entre 5 y 12 |
| Sextilla | 6 versos, consonancia y configuración isométrica o `8-8-4-8-8-4` | medida común solo en la isométrica | múltiplo de 6 |
| Doble sextilla | dos sextillas de pie quebrado y esquema regular no manriqueño | ninguna elección cerrada adicional | múltiplo de 12 |
| Copla manriqueña | dos sextillas `8-8-4-8-8-4` y `abcabc:defdef` | ninguna | múltiplo de 12 |
| Décima espinela | 10 octosílabos, consonancia, `abbaaccddc` y estructura `4 + 2 + 4` | nada | múltiplo de 10 |
| Décima aumentada | 12 octosílabos, consonancia, `abbaaccddeed` y pausa `4 + 8` | nada | múltiplo de 12 |
| Redondilla · configuración simple | unidades de 4 versos consonantes | medida 8, 7 o 6 y disposición `abba` o `abab` | múltiplo de 4; materializa una unidad por cada 4 versos |
| Redondilla · configuración doble enlazada | unidades de 8 octosílabos, `abba:acca` | nada | múltiplo de 8; materializa una unidad por cada 8 versos |
| Octava real | 8 endecasílabos consonantes y `ABABABCC` | final esdrújulo, solo si caracteriza | múltiplo de 8 |
| Novena | 9 octosílabos consonantes y orden de secciones según configuración | esquema de la redondilla y de la quintilla en cada unidad | múltiplo de 9; materializa una novena y sus dos partes por cada 9 versos |
| Lira | 5 versos, patrón `7-11-7-7-11`, consonancia y `aBabB` | nada | múltiplo de 5 |
| Sexteto-lira | 6 versos, medidas y rima de cada tipología admitida | tipología combinada por estrofa; final esdrújulo si caracteriza | múltiplo de 6; materializa una unidad por cada 6 versos |

## Recorridos mínimos

- Romance: forma, vocales de la asonancia y guardar.
- Quintilla: forma, esquema de la primera unidad, aplicar a todas si coincide y corregir
  solo las excepciones.
- Terceto: forma y guardar; el rasgo esdrújulo queda vacío por defecto.
- Terceto encadenado: forma, configuración si se solicita y guardar.
- Tercetos sin encadenar: forma, disposición de la rima y guardar.
- Silva: forma, configuración y guardar.
- Endecasílabo suelto: forma, configuración y guardar.
- Pareados endecasílabos: forma y guardar.
- Soneto: forma, esquema de los tercetos y guardar.
- Villancico: forma, medidas y únicamente las unidades que realmente aparecen.
- Zéjel: forma, medidas, extensión de la cabeza y presencia material de la represa; la
  estructura `BBB + A` no se pregunta.
- Copla real: forma, configuración con o sin quebrado y los dos esquemas de quintilla;
  solo la configuración quebrada pide marcar una o dos posiciones.
- Décima espinela y décima aumentada: forma y guardar; todas sus propiedades
  normativas se derivan.
- Redondilla simple: forma, configuración, medida y distribución de la primera unidad;
  aplicar ambas respuestas a toda la tirada y cambiar solo las unidades distintas.
- Redondilla doble: forma, configuración y guardar; el registrador deriva las unidades
  de ocho versos.
- Octava real: forma y guardar; el rasgo esdrújulo queda vacío por defecto.
- Novena: forma, orden de secciones y los dos esquemas de la primera unidad; aplicar a
  toda la tirada y cambiar solo las unidades distintas.
- Lira: forma y guardar; toda la norma se deriva.
- Sexteto-lira: forma, tipología de la primera unidad y aplicar a todas; cambiar solo
  las estrofas diferentes y dejar vacío el rasgo esdrújulo por defecto.

## Criterio de las desviaciones

Una opción admitida nunca se registra como desviación. Se usa una desviación cuando un
tramo incumple la configuración o la elección realizada: medida distinta, ruptura de
rima, ausencia o adición estructural, repetición anómala o rasgo observado no previsto.
La ausencia de desviaciones significa conformidad con la norma seleccionada.

La laguna de una fuente no autoriza un rango incompatible. El cómputo incorpora la
posición del verso ausente y la laguna se localiza en el registro correspondiente.

## Límite de esta revisión

Estos contratos cubren únicamente las formas revisadas en profundidad. Las demás formas
del catálogo pueden verse en el editor V2, pero no deben considerarse editorialmente
validadas hasta pasar por la misma matriz.
