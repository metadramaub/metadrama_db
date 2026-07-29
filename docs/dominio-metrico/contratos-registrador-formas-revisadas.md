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
| Villancico | configuración y secciones obligatorias | medidas, esquema de cada mudanza, enlace o vuelta y recuperación del estribillo | calculada desde sus secciones |

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
