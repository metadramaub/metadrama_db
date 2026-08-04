# Cómo se migra una obra

Estado: vigente · 4 de agosto de 2026

Este documento explica el procedimiento de la migración métrica obra por obra: qué se hace,
en qué orden, quién decide qué y qué garantías hay de que no se pierde nada. Está escrito
para poder explicárselo a quien anotó cada obra.

El plan completo, con sus fases y criterios de aceptación, está en
[plan de migración](./plan-migracion-anotaciones.md). Aquí solo está el procedimiento.

## Lo primero: qué NO va a pasar

Conviene decirlo antes que nada, porque es lo que preocupa:

- **Nadie va a reanotar su obra desde cero.** El modelo nuevo llega con la propuesta ya
  hecha a partir de lo que se anotó; lo que se pide es revisarla.
- **Nada se toca sin hablarlo.** Las secuencias reales no cambian hasta que la revisión de
  esa obra esté cerrada.
- **El editor de siempre sigue funcionando igual** mientras dure todo esto. Quien no esté en
  una revisión no nota nada.
- **No se inventa precisión.** Si el dato viejo no dice cuántas sílabas tenía un verso
  hipométrico, el nuevo tampoco se lo inventa: se conserva que era menor que la norma y
  se marca para revisar.

## Por qué hay que revisar, si la correspondencia es automática

Porque automática no quiere decir completa. De las 216 secuencias del corpus, el sistema
resuelve 212, pero **por tres vías que no valen lo mismo**:

| Vía | Qué significa | Cuántas |
| --- | --- | ---: |
| **directa** | El término viejo tiene su equivalente exacto en el catálogo. No hay nada que decidir | 134 |
| **rasgo** | El término codificaba un rasgo, no una forma: `romance_a-o` dice «romance» *y* «asonancia a-o». La forma viene de su padre, y **la asonancia llega ya contestada en el formulario** | 71 |
| **ascendencia** | Nadie reclama el término, pero sí su padre. **Da la forma, no las respuestas** | 7 |
| **sin resolver** | Hay que decidirlo | 4 |

Las de **ascendencia** son las que necesitan al editor. Ejemplo real: seis secuencias de
*El esclavo del demonio* están anotadas como `endecasilabo_suelto_puro`. El catálogo sabe
que son endecasílabos sueltos, pero el modelo nuevo pregunta además si hay pareados
intercalados y si hay dístico final —cosas que el término viejo daba por supuestas y que no
se pueden deducir del dato—. Eso lo contesta quien leyó el texto.

## El procedimiento, paso a paso

### 1 · Se genera el informe de la obra

```sh
npm run migracion:informe
```

Escribe un documento por obra en [migracion/](./migracion/). Cada uno empieza diciendo si
hay algo que consultar o no, y lleva:

- las **dudas** una por una, con su rango de versos;
- las secuencias que **se funden** en una sola;
- la tabla completa de secuencias, con su forma y arquitectura propuestas y **por qué vía**;
- los subtipos y las caracterizaciones agrupados.

Los informes **se regeneran**: no se editan a mano, porque cada decisión que se aplica al
catálogo los cambia. Lo que se decide se anota en
[equivalencias pendientes](./equivalencias-pendientes.md), que es el documento vivo.

### 2 · Se revisa con quien anotó la obra

Una videollamada por obra, con el informe delante. Se repasa:

1. **Las dudas.** Son pocas y concretas: un rango de versos y una pregunta.
2. **Las secuencias heredadas.** Qué contestaría hoy a las preguntas nuevas.
3. **Los tramos que se funden**, si los hay, para confirmar que son un mismo pasaje.
4. **Las caracterizaciones de medida**, si las hay, porque son las que perdieron el dato
   exacto y hay que recuperarlo del texto.

Lo que no aparece en el informe no hace falta mirarlo: está resuelto.

### 3 · Las decisiones se aplican al catálogo

Cada decisión se convierte en una migración de base de datos —nunca en una edición a mano—
y se anota en [equivalencias pendientes](./equivalencias-pendientes.md) con su fecha. Al
regenerar el informe, esa duda desaparece.

### 4 · Se anota en sombra y se contrasta

Con la obra ya sin dudas, se abre a la **anotación en sombra**: `/dashboard/metrica` →
pestaña «Anotación en sombra» → «Abrir una obra».

Ahí se anota con el modelo nuevo **sobre las secuencias reales**, sin que producción se
entere: la secuencia real no cambia ni una columna y todo lo anotado cuelga aparte.

El formulario llega con **la forma, la arquitectura y las respuestas que el término legado
ya permitía deducir**: la asonancia de un romance, el esquema de los tercetos de un soneto,
la tipología de un sexteto-lira, el esquema de sus cuartetos. Son 88 respuestas, y **se
rellenan solas,
tanto las de la secuencia entera como las de cada unidad**. En esos casos el trabajo es leer
y guardar. Lo que no se deduce se pregunta, y en la tabla se ve en verde qué llega
contestado antes de abrir.

Lo ya contestado por el editor nunca se pisa: la propuesta solo rellena huecos.

La pantalla lleva el recuento que decide cuándo termina la fase: de lo anotado en los dos
modelos, cuántas secuencias **coinciden**, cuántas **difieren** y cuántas no tienen
correspondencia. Para ver la obra en los dos modelos a la vez se abre el editor de siempre
en otra pestaña.

### 5 · Solo entonces se migra de verdad

Cuando el contraste dice que el modelo nuevo recoge sin pérdida lo que decía el viejo, y las
diferencias que quedan son correcciones deliberadas y no defectos del modelo, se ejecuta el
backfill sobre esa obra. Antes hay copia de seguridad.

## Quién tiene trabajo, hoy

| Obra | Editor | Qué hay que mirar |
| --- | --- | --- |
| Fuenteovejuna | David Merino Recalde | 3 secuencias que no declaran forma |
| El conde de Sex | Rosa Bono | 1 secuencia: `pareado_endecasilabo` |
| El esclavo del demonio | Blanca Ballester Morell | 6 secuencias heredadas + 225 subtipos |
| Dido y Eneas | Gaston Gilabert | 4 sextetos-lira que se funden; el tramo no cuadra en múltiplos de 6 |
| Valor, agravio y mujer | María Isabel Cuena | 160 caracterizaciones por rango |
| El caballero de Olmedo | María Isabel Cuena | 50 caracterizaciones por rango |
| El amor al uso | Ana Vicente | 28 subtipos |
| El mágico prodigioso | Emma González Mesas | 52 subtipos |
| Cegar para ver mejor · El ganso de oro · La tragedia del duque de Berganza | | nada |

Las cifras se actualizan solas al regenerar; el reparto de nombres, no.

## Dónde vive cada cosa

| | |
| --- | --- |
| Las reglas de equivalencia | La vista `propuesta_metrica_secuencia`. **Fuente única**: la usan igual el dashboard y el informe |
| Los informes por obra | [migracion/](./migracion/), generados |
| Las decisiones tomadas y pendientes | [equivalencias pendientes](./equivalencias-pendientes.md), a mano |
| El plan y sus fases | [plan de migración](./plan-migracion-anotaciones.md) |
