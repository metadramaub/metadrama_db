La pestaña **Autoría** registra quién escribió la obra, con sus propuestas y las evidencias que las sostienen. Este es el modelo definitivo.

## Cómo se organiza

La autoría se estructura en tres niveles:

1. **Ámbito**: eliges entre **Obra completa** o **Por jornadas** (los dos botones de arriba). Hay una única autoría global de la obra; además, si una jornada tiene una atribución propia, la añades en su jornada.
2. **Propuestas**: dentro de un ámbito, cada propuesta es una atribución posible. **Varias propuestas en el mismo ámbito significan que la autoría está disputada** (son alternativas entre sí: "X *o* Y").
3. **Evidencias**: dentro de una propuesta, cada evidencia es una fuente que sostiene **esa misma** atribución. Varias evidencias = varias fuentes que apoyan la misma autoría.

## Tipología de cada propuesta

Cada propuesta tiene una tipología que fija cuántos autores lleva:

- **individual**: exactamente **1** autor.
- **colaborada**: **2 o más** autores (escribieron la obra juntos).
- **desconocida**: **0** autores.

> [!IMPORTANT]
> No crees un autor ficticio como "desconocido". Si la autoría es desconocida, usa la tipología **desconocida** y deja la propuesta sin autores. Así distinguimos una obra sin revisar de una obra revisada cuya autoría es desconocida.

## Cuándo añadir evidencias

- **Autoría única, segura y no disputada** → no hace falta añadir evidencias. Una sola propuesta individual con su autor basta.
- **Autoría disputada** (varias propuestas), o **una única propuesta pero también discutida** → añade evidencias que respalden cada propuesta.

Cada evidencia tiene un **tipo** y una **fuente de autoría** (texto en [Markdown](/dashboard/guia/ref-markdown) donde citas o explicas la fuente). Los tipos son:

- **Tradicional**: la atribución que sostiene la crítica o la tradición editorial.
- **Estilometría léxica**: análisis estilométrico del léxico. La fuente puede ser, preferiblemente un informe del proyecto [etso.es](https://etso.es); búscalo y pega el enlace en la fuente de autoría. También puedes usar un artículo o estudio publicado.
- **Propuesta versológica**: atribución basada en el análisis de la métrica, cuando tengamos corpus suficiente.

Para decidir si algo va como **otra evidencia** o como **otra propuesta**, pregúntate si el autor propuesto es el mismo:

- **Mismo autor, otra fuente** → misma propuesta, nueva evidencia.
- **Autor distinto** → nueva propuesta.

> [!NOTE]
> Dentro de una propuesta no puedes repetir el mismo **tipo** de evidencia (p. ej. no dos "Tradicional"), pero sí registrar varias fuentes tradicionales en el mismo campo.

Por ejemplo: si la tradición y un análisis versológico coinciden en que el autor es Lope, es **una** propuesta (Lope) con **dos** evidencias (Tradicional y Propuesta versológica). Si en cambio una fuente dice Lope y otra dice Tirso, son **dos** propuestas de atribución distintas.

## Obra colaborada por jornadas

Cuando una obra es de autoría colaborada, procede así:

1. En **Obra completa**, declara una propuesta **colaborada** con todos los autores implicados.
2. Si se sabe **quién escribió cada jornada**, ve a **Por jornadas** y, en cada jornada, añade una propuesta **individual** con su autor.
3. Si no se sabe el reparto por jornadas, deja solo la autoría colaborada a nivel global y no añadas nada por jornada.

## Si falta un autor

Como `editor` **puedes crear un autor nuevo** si no existe (pero no editar ni eliminar fichas ya creadas).

1. Desde la edición de una obra, si falta un autor, sal de la obra y abre [Autores](/dashboard/autores).
2. Busca por nombre principal, nombre normalizado y variantes conocidas.
3. Revisa las fichas parecidas y confirma que ninguna corresponde al autor que necesitas.
4. Si no existe, pulsa **Crear nuevo autor** y rellena al menos el nombre completo y el nombre normalizado.
5. Si el sistema muestra autores parecidos, revísalos antes de confirmar la creación.
6. Vuelve a [Obras](/dashboard/obras?scope=mine) y aplica la atribución en la obra correspondiente.

> [!WARNING]
> Si detectas un error en una ficha de autor ya existente, no puedes corregirla, ¡pero sí avisarnos por correo!
