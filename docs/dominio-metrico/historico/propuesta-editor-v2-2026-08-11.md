# Un solo sitio para cada pregunta

> **Archivado el 21 de agosto de 2026.** El diagnóstico que motivó la pantalla nueva del editor
> V2. Se aplicó el 11 de agosto y la pantalla lleva desde entonces en `develop`; se conserva
> porque explica **por qué el formulario es como es**.
>
> Cómo quedó: [el primer corte](./editor-secuencias-v2-2026-08-11.md).

Estado: **aplicado** · 11 de agosto de 2026

> El IP eligió la **rejilla** entre las dos maneras que se maquetaron, y esa es la que está en
> `develop`. Cómo quedó se describe en
> [especificación histórica del primer corte](./editor-secuencias-v2-2026-08-11.md#la-estructura-es-una-rejilla-y-no-se-pliega);
> lo que sigue es el diagnóstico que lo motivó, que se conserva porque explica por qué la
> pantalla es como es. **Lo que cambió respecto de lo que aquí se propone está al final.**

Este documento existe porque las mejoras sueltas sobre el editor V2 dejaron de mejorarlo. El IP
probó el formulario de la quintilla y describió lo que veía: dos botones que parecen lo mismo,
tarjetas con cabecera y sin contenido, y un desplegable que aparece en un sitio o en otro según
qué hayas pulsado antes. Tenía razón, y la causa no es la redacción de los botones.

## Qué pasa hoy

**Hay seis interruptores independientes** repartidos por el editor:

| Dónde                   | Cuál                      | Qué pliega                                                  |
| ----------------------- | ------------------------- | ----------------------------------------------------------- |
| `MetricStructureEditor` | `expandedFamilyKeys`      | Una pregunta que se responde para todas las unidades        |
| `MetricStructureEditor` | `expandedRepeatKeys`      | Una sección que se repite y cuyas realizaciones son iguales |
| `MetricStructureEditor` | `expandedUnitIds`         | Una unidad ya respondida                                    |
| `MetricSequenceEditor`  | `showMeasuresBySection`   | La medida, preguntada de una vez o por partes               |
| `MetricSequenceEditor`  | `identificationGroupOpen` | El bloque de versos y forma                                 |
| `MetricChoiceField`     | `expanded`                | Las opciones de una pregunta larga                          |

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
respuesta, sin mantener un recuento manual que quede obsoleto al crecer el catálogo.

## En qué se apartó de esto lo que se hizo

Se maquetaron dos maneras de cumplir las tres reglas y el IP eligió la segunda:

- **Grupo y excepciones**, que es lo dibujado arriba: una tarjeta para las N iguales y una
  acción por unidad para separarla.
- **Rejilla**, la elegida: la estructura a la izquierda verso a verso, las respuestas a la
  derecha, y **ninguna unidad oculta**. No hay acción de separar —se cambia la fila que sea—
  ni interruptor que la haga aparecer. El coste aceptado es que quince quintillas son quince
  filas; el IP lo dio por bueno porque las tiradas largas no son lo corriente.

Seis cosas que la propuesta no preveía y que hicieron falta:

1. **La pregunta común solo sirve en repeticiones simples.** Se probó primero una medida para
   toda la composición además de las medidas de cada sección. En el villancico real mezclaba
   tres escalas —composición, sección y ciclo— y se retiró: las composiciones variables se
   responden por partes; el atajo queda para unidades simples repetidas como el pareado.
2. **Una sección que no pregunta nada no pinta contenedor.** La copla dejaba el esquema de la
   mudanza a tres niveles de anidamiento. El enunciado derivado ya nombra su sección, así que la
   pregunta sube sin perder sujeto.
3. **Una sección que materializa una respuesta no se quita a mano.** Salió al mirar la pantalla
   renderizada: quitarla dejaba «se repite entero» apuntando a una repetición inexistente. Era
   un defecto anterior que el plegado tapaba.
4. **El atajo admite respuestas posicionales completas.** El pareado necesita dos metros por
   dístico, de modo que filtrar el atajo a `selecciones_max = 1` dejaba arriba solo la rima. Los
   dos metros se responden ahora junto a ella y las filas coincidentes muestran un resumen;
   el control completo se abre únicamente para cambiar una excepción.
5. **El propietario de guardado no impone el orden visual.** La repetición del estribillo se
   guarda en el ciclo, pero sus opciones materializan una sección hermana de la copla. Se pregunta
   por eso después de mudanza y enlace o vuelta; si se sobreentiende, mantiene allí una fila sin
   versos en vez de subir a la cabecera del ciclo.
6. **La composición variable no se multiplica dentro de la secuencia.** El villancico, el zéjel
   y la canción conservan una sola unidad raíz; lo que se añade o quita son sus ciclos. Cada
   ciclo tiene cabecera propia y acciones individuales, no un contador separado de la estructura.

`npm run audit:editor` da lo mismo antes y después —0 defectos, salida idéntica—, que era la
prueba de que la reforma es de pantalla y no del catálogo.
