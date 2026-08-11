# Un solo sitio para cada pregunta

Estado: **propuesta** · 11 de agosto de 2026 · sin implementar

Este documento existe porque las mejoras sueltas sobre el editor V2 dejaron de mejorarlo. El IP
probó el formulario de la quintilla y describió lo que veía: dos botones que parecen lo mismo,
tarjetas con cabecera y sin contenido, y un desplegable que aparece en un sitio o en otro según
qué hayas pulsado antes. Tenía razón, y la causa no es la redacción de los botones.

## Qué pasa hoy

**Hay seis interruptores independientes** repartidos por el editor:

| Dónde | Cuál | Qué pliega |
| --- | --- | --- |
| `MetricStructureEditor` | `expandedFamilyKeys` | Una pregunta que se responde para todas las unidades |
| `MetricStructureEditor` | `expandedRepeatKeys` | Una sección que se repite y cuyas realizaciones son iguales |
| `MetricStructureEditor` | `expandedUnitIds` | Una unidad ya respondida |
| `MetricSequenceEditor` | `showMeasuresBySection` | La medida, preguntada de una vez o por partes |
| `MetricSequenceEditor` | `identificationGroupOpen` | El bloque de versos y forma |
| `MetricChoiceField` | `expanded` | Las opciones de una pregunta larga |

Son ortogonales, así que **una misma pregunta puede aparecer en tres lugares distintos** según qué
combinación esté abierta: en «así es toda la composición», dentro de la tarjeta de la repetición
plegada, o dentro de la tarjeta de una unidad concreta.

De ahí sale todo lo que el IP describe. Una quintilla de dos unidades ofrece «corregir alguna de
las 2» y «corregir una concreta»: la primera abre un desplegable **dentro** de «Cada quintilla»,
que es donde ya estaba; la segunda parte «Cada quintilla» en dos tarjetas **sin contenido**, hasta
que se pulsa la primera. Dos acciones para llegar al mismo sitio por caminos distintos, y estados
intermedios en que la pantalla no enseña nada.

## Las tres reglas de la propuesta

**1 · Una pregunta vive siempre en su unidad.** El bloque «así es toda la composición» desaparece
como lugar alternativo. No hay dos sitios donde pueda estar la misma pregunta.

**2 · Una tarjeta nunca se enseña sin su contenido.** Si hay algo que responder, está dentro. Si no
hay nada, es una línea de texto y no una tarjeta. Se acabaron las cabeceras vacías.

**3 · Una sola acción para divergir.** Cuando N unidades son iguales se enseña **una** tarjeta con
sus preguntas dentro, respondidas a la vez. Junto a ella, una acción por unidad: «vv. 121–125 es
distinta». Al pulsarla, esa unidad se separa y aparece con sus propias preguntas. No hay un plegado
de pregunta y otro de repetición: hay unidades iguales y unidades separadas.

## Cómo quedaría la quintilla de la captura

```
Quintilla · Octosilábica consonante
vv. 116–125 · 2 quintillas de 5 versos

┌ Las 2 quintillas ──────────────────────────────────┐
│ Esquema de rima   [ Tipología 3 · abaab      ▾ ]   │
│                                                    │
│ ¿Alguna es distinta?  vv. 116–120 · vv. 121–125    │
└────────────────────────────────────────────────────┘
```

Una tarjeta, una pregunta, una acción. Al separar la segunda:

```
┌ Quintilla 1 · vv. 116–120 ─────────────────────────┐
│ Esquema de rima   [ Tipología 3 · abaab      ▾ ]   │
└────────────────────────────────────────────────────┘
┌ Quintilla 2 · vv. 121–125 ─────────────────────────┐
│ Esquema de rima   [ Tipología 5 · ababa      ▾ ]   │
│                              · volver a unirla     │
└────────────────────────────────────────────────────┘
```

## Qué se conserva

Nada de esto toca el modelo ni lo que se guarda: **cada unidad sigue teniendo su propia
respuesta**, como hoy. Cambia dónde se pregunta, no qué se registra. Y el patrón que el IP pidió
—responder una vez para todas y corregir después las que varían— es exactamente el que queda,
solo que con una acción en vez de tres.

Se conservan también los dos aciertos del editor actual: que las repeticiones sin nada que
responder se resuman en una línea, y que el catálogo diga cuándo una forma no necesita ninguna
respuesta, que son veintiuna de las treinta y siete arquitecturas.

## Por dónde empezar

1. Quitar `expandedFamilyKeys` y su bloque, moviendo esas preguntas a la tarjeta de la unidad.
2. Sustituir `expandedRepeatKeys` y `expandedUnitIds` por un solo conjunto: qué unidades se han
   separado del grupo.
3. Rehacer `renderSection` con la regla 2 delante: si hay contenido, tarjeta; si no, línea.
4. Medir antes y después con `npm run audit:editor`, que ya cuenta cuántas respuestas exige cada
   forma y no debería cambiar: esto es una reforma de la pantalla, no del catálogo.

*El paso 3 es el grueso y conviene hacerlo con la pantalla delante, no a ciegas.*
