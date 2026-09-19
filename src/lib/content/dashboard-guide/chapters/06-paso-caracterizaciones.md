A veces una secuencia métrica contiene un fenómeno que afecta a cómo se usa la voz dentro del pasaje —se canta, se habla en prosa, un personaje adopta la voz de otro— y que no requiere crear una nueva secuencia. Eso se declara con las **caracterizaciones por rango**, dentro de la pestaña Secuencias, una vez que la secuencia está guardada.

> [!IMPORTANT]
> Para poder añadir caracterizaciones por rango (tantas como necesites), debes guardar al menos una vez la secuencia en edición.

## Qué se anota aquí, y qué no

Hoy se pueden crear caracterizaciones de tres tipos:

- **Cantado**: versos cantados dentro de la secuencia.
- **Prosa**: un tramo en prosa dentro de una secuencia métrica.
- **Evocación métrica**: el cambio de metro se debe a que un personaje adopta, imita o reproduce la voz de otro personaje.

> [!IMPORTANT]
> Un verso hipométrico o hipermétrico, una rima defectuosa, un patrón alternativo o una laguna no se anotan aquí: se declaran como **desviación** dentro del editor de la forma, una vez elegida su arquitectura. Ver [Paso 3 · Secuencias](/dashboard/guia/paso-secuencias#desviaciones). Si ves alguna fila con un tipo distinto de estos tres, es de antes del cambio: puedes corregirla o borrarla, pero no crear una nueva igual.

## Qué incluye cada caracterización

- tipo de caracterización (cantado, prosa o evocación métrica);
- verso inicial y verso final (que puede ser el mismo, si se trata de un solo verso);
- observaciones específicas de esa caracterización (cualquier dato extra que quieras añadir; será público).

Las observaciones de caracterización admiten [Markdown](/dashboard/guia/ref-markdown).

## Reglas de cada tipo

- En **prosa**, `v_ini` y `v_fin` indican el verso **anterior y posterior** a la prosa, pues esta, en realidad, no está numerada; deben ser dos versos distintos.
- En **cantado**, puedes marcar un solo verso (`v_ini` = `v_fin`) o un rango.
- En **evocación métrica**, la caracterización nace por defecto abarcando el rango completo de la secuencia —la evocación suele afectarla entera—, pero puedes acotarla si empieza o acaba dentro de ella.
- Toda caracterización debe quedar **dentro del rango de versos** de su secuencia.
