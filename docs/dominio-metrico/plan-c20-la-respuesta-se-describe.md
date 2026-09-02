# C20 · La respuesta se describe a sí misma

**Escrito el 29 de agosto de 2026, sin aplicar.** Cambia **a qué apunta una respuesta guardada**. Hoy
dice «soy la respuesta a *esta pregunta*»; pasará a decir «**esta realización, en la dimensión rima,
es este esquema**».

Las preguntas **no desaparecen**: siguen siendo la declaración del catálogo de qué se pregunta, con
qué control y cuántas respuestas caben. Lo único que cambia es la clave de la respuesta.

## Por qué ahora

| | |
|---|---|
| anotaciones con el sistema nuevo | **3** |
| respuestas guardadas | **7** |
| desviaciones | **0** |
| obras migradas del vocabulario legado | **0** |

Y la edición está pausada, así que no crecerá mientras dure. **No hay migración de datos**: las siete
respuestas son de prueba y se borran.

## Lo que ya está hecho a medias

Dos piezas del propio esquema van ya por este camino, y son la prueba de que el diseño encaja:

- **`anotacion_desviaciones` no tiene `grupo_eleccion_id`.** Tiene `dimension` con un `CHECK` sobre
  las cinco dimensiones, columnas de entidad observada, y otro `CHECK` que obliga a que la entidad
  case con la dimensión. Es exactamente la forma que se propone aquí, ya en producción.
- **`anotacion_elecciones_resueltas` deriva la opción desde la entidad**, casando `metro_id`,
  `esquema_rima_id`, `valor_rasgo_id`… contra las opciones de la pregunta. El código **ya sabe** que
  la respuesta es la entidad y que la opción es derivable.

## Qué significa que algo «se derive»

**Derivar es no guardarlo y calcularlo cuando hace falta**, a partir de lo guardado más el catálogo.

Hoy se guarda **el puntero a la pregunta**. Eso tiene tres consecuencias que conviene ver:

1. **El catálogo queda congelado por las anotaciones.** La clave ajena es `RESTRICT`: en cuanto una
   obra esté anotada, **no se podrá borrar ni reorganizar una pregunta** sin tocar sus respuestas.
   Todo lo que hemos hecho esta semana —retirar la pregunta del dístico, crear la del septeto-lira,
   renombrar rótulos— habría sido imposible con obras anotadas.
2. **La reutilización no cabe.** Una pregunta prestada no tiene fila, así que no tiene identidad, así
   que no se puede guardar. Es **F39**: la oncena y el septeto compuesto no pueden anotar su rima.
3. **Los tramos sin forma no pueden preguntar nada**, porque toda pregunta cuelga de una arquitectura
   y ellos no tienen. Es **F63**.

Al derivar la pregunta, las tres desaparecen. **Lo que se pierde** es poder decir «esta respuesta
contestaba a la pregunta tal como estaba redactada entonces». *No es una pérdida real: lo que la
respuesta afirma —que esos versos riman `abba`— sigue siendo verdad aunque la pregunta se renombre,
se mueva o se retire.*

## Cómo se verán los datos

**Hoy**, una redondilla anotada:

| realización | grupo_eleccion_id | esquema_rima_id |
|---|---|---|
| vv. 300-303 | `a4f2…` *(«Esquema de rima» de Redondilla · Octosilábica)* | `9c1b…` *(`abba`)* |

Para saber qué dice hay que ir al grupo, del grupo a la arquitectura, y de ahí a la forma.

**Después**, la misma:

| realización | dimensión | esquema_rima_id |
|---|---|---|
| vv. 300-303 | `rima` | `9c1b…` *(`abba`)* |

Se lee sola: **estos cuatro versos riman `abba`**. Y una copla real de dos coplas:

| realización | parte | dimensión | entidad |
|---|---|---|---|
| vv. 1-10 | — | `metro` | tetrasílabo, posición 6 |
| vv. 1-5 | Primera quintilla | `rima` | `ababa` |
| vv. 6-10 | Segunda quintilla | `rima` | `abbab` |
| vv. 11-20 | — | `metro` | … |

*La parte no se guarda en la respuesta: la lleva la realización, que ya tiene `seccion_id`.*

## Si todas las formas guardan lo mismo

**No, y eso no lo cambia C20** —conviene saberlo antes de contar nada—. Lo que se guarda es **solo
lo que se pregunta**, y lo que se pregunta es **lo que la norma no fija**:

- una **décima espinela** no guarda nada: su rima y su medida son definitorias, así que su anotación
  es «décima espinela, vv. X–Y» y punto;
- una **copla real** guarda la rima de cada quintilla y dónde caen sus quiebros;
- un **sexteto-lira** guarda una variedad por estrofa, que vale por rima y medida a la vez.

Las tres están igual de bien descritas, pero **la tabla de respuestas las enseña muy desiguales**.
Cualquier análisis que lea solo las respuestas subestimará sistemáticamente a las formas cuya norma
lo fija todo.

**Lo que C20 aporta aquí** es que la suma se puede hacer: como la respuesta se describe sola, una
proyección puede juntar **norma + respuestas** y emitir un registro uniforme —verso a verso o estrofa
a estrofa— igual para las cuarenta y una formas. Eso es **C18**, y hoy no se puede escribir porque la
respuesta no dice de qué habla sin ir a buscar la pregunta.

## Y la proyección a estático

*No se hace ahora, pero el diseño tiene que permitirla.* Dos condiciones, y las dos las cumple:

1. **La fila debe poder exportarse sin consultar las tablas de preguntas.** Después de C20 una
   respuesta ya dice versos, dimensión y entidad. Las entidades que quedan —un esquema de rima, un
   metro, un valor de rasgo— son **entidades del dominio**, estables, no filas de configuración.
2. **La exportación no debe romperse cuando el catálogo cambie.** Hoy sí se rompe: si una pregunta se
   retira, un volcado histórico apunta a una fila que ya no existe. Después no, porque no apunta a
   ninguna pregunta.

## El plan

### A · Limpiar y preparar

1. **Borrar las 3 anotaciones de prueba.** Son de pruebas y se rehacen en un minuto; sin ellas el
   cambio de esquema no arrastra ningún dato.

### B · El esquema

2. **`anotacion_elecciones` se describe sola**: añadir `dimension` con el mismo `CHECK` de cinco
   valores que ya usa `anotacion_desviaciones`; añadir `seccion_tratada_id`, para el único caso en
   que la respuesta se guarda en la unidad pero habla de una parte —los cuartetos y los tercetos del
   soneto, **2 preguntas en todo el catálogo**—; y retirar `grupo_eleccion_id`.
3. **Un `CHECK` que ate la entidad a la dimensión**, copiado del de las desviaciones: un
   `esquema_rima_id` solo con `dimension = 'rima'`, un `metro_id` solo con `'metro'`, y así.

### C · El servidor

4. **`validar_anotacion_eleccion` resuelve la pregunta** desde (arquitectura de la anotación, sección
   de la realización, dimensión, sección tratada) en vez de por id. *Y ahí la reutilización sale
   gratis*: la realización ya lleva `seccion_id`, y la sección ya declara qué arquitectura reutiliza,
   así que las opciones admitidas salen sin que exista fila de pregunta. **Cierra F39.**
5. **`guardar_anotacion_metrica`**: escribe la dimensión y cuenta la cardinalidad agrupando por
   (dimensión, sección) en vez de por grupo. Sus tres pasadas se conservan.

### D · El cliente

6. **`MetricChoiceDraft` pasa a llevar dimensión y parte** en vez del identificador de pregunta.
   Trece ficheros, y el grueso es mecánico: donde hoy se dice `grupo_eleccion_id` se dirá dimensión y
   sección. Ocho ficheros más son pruebas.
7. **`reutilizacion.ts` desaparece**, y con él el prefijo que se le puso el 29 de agosto: ya no hace
   falta inventarse preguntas, porque la respuesta no necesita una.

### E · El puente con lo viejo

8. **`equivalencias_respuestas_legadas`** —26 filas, y de ellas dependía migrar lo ya anotado— pasa a
   apuntar a (arquitectura, dimensión, sección) en vez de a un grupo. **Es la pieza delicada**, y por
   eso va la última y con su propia comprobación: cada una de las 26 debe seguir resolviendo a la
   misma respuesta que resuelve hoy, y eso se comprueba fila a fila.

### F · Lo que se arregla de paso

9. **F63**: con la respuesta describiéndose sola, la versificación irregular y el verso aislado pueden
   registrar de qué arte son sus versos y cuánto mide un verso suelto, sin necesitar una arquitectura
   que contradiga su nombre.

## Comprobación

**No basta con que compile.** Después de aplicarlo, en la obra «Prueba»:

1. Anotar **una forma de cada clase** y comprobar que guarda y se relee entera: una que no pregunte
   nada (décima espinela), una de rima simple (redondilla), una con partes (copla real), una con
   ciclos (villancico), una de variedad (sexteto-lira) y **una de las que hoy no pueden guardar**
   (oncena), que es la prueba de que F39 se cerró.
2. Comprobar en la base que cada respuesta dice de qué habla **sin consultar ninguna pregunta**.
3. `npm run check`, `npm run test` y `npm run lint`.
4. Y recompilar el artefacto del demarcador, que indexa por pregunta y pasará a indexar por dimensión.

## Lo que este plan no toca

- **La proyección a notación verso a verso (C18)**, que es lo que hace comparables las formas. C20 es
  su condición previa, no su sustituto.
- **El precomputado a estático**, que viene después y sobre la proyección.
- **F46**, la revisión de la norma: se hace luego, ya sabiendo qué forma tiene un registro.
