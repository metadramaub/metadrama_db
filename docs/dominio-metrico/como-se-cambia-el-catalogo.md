# Cómo se cambia el catálogo

**El método en vigor para cualquier cambio futuro**, tal como quedó tras revisar las fichas forma
por forma en agosto de 2026 y auditarlas contra sus fuentes en septiembre. Aquí está el
procedimiento y las trampas que costaron un día cada una; **los recuentos y el estado no se
escriben**, se consultan con `npm run audit:metrica`.

Lo que gobierna la redacción está en [dónde vive la prosa](./donde-vive-la-prosa.md); las
monografías y cómo se citan, en [las fuentes del catálogo](./fuentes-del-catalogo.md); el nivel en
que se registra cada hecho, en [criterios de nivel](./criterios-de-nivel.md).

## El método

Se audita una forma entera contra
la base —definición, arquitecturas, esquemas, notas, denominaciones, relaciones y afirmaciones—,
se contrasta con la ficha real de `/formas`, se presentan **todas las decisiones juntas** para que
el IP las apruebe una a una, y se aplica **una sola migración por forma**, con guardas que
comprueben los valores vivos exactos y ejecuten lo que tocan, para poder verificar esa ficha antes
de pasar a la siguiente. La norma de redacción es
[dónde vive la prosa](./donde-vive-la-prosa.md); las fuentes y cómo se citan, en
[las fuentes del catálogo](./fuentes-del-catalogo.md).

Se intentó primero como barrido global —hubo un informe de «segunda poda» con su generador— y no
funcionó: un inventario de frases sueltas no deja ver la forma entera, y sus recuentos envejecían
en cuanto se tocaba algo. Los tres documentos se retiraron el 18 de agosto de 2026; sus decisiones
ya aplicadas están en las migraciones y en el historial de `git`.

**Hubo un generador de podas y se retiró el 16 de septiembre de 2026.** Recorría la prosa
señalando cada frase que repitiera un dato ya estructurado, y llegó a proponer 191 cortes: **se
aceptaron cero**. No estaba desfasado, es que su criterio no era el del proyecto, y mantenerlo solo
servía para volver a rechazar lo mismo. Si alguna vez hace falta otra vez, se escribe con el
criterio de abajo y limitado a las notas.

**Definiciones y descripciones no se podan: se mejoran, y a menudo alargándolas.** Pueden repetir
en prosa lo que la figura dibuja, porque su función es que una forma se lea de corrido; las de la
seguidilla son el modelo. La regla de no escribir lo derivado se aplica con severidad a las
**notas** —de posición, de sección, de rasgo, y las descripciones de esquema—, no a ellas. Y su
prosa no usa lenguaje de base de datos ni da por supuesto el Siglo de Oro: el catálogo aspira a
ser más general que el corpus.

**Cómo se retira algo del catálogo.** Fijado el 20 de agosto de 2026, al retirar la primera
forma. Una **forma** o una **arquitectura** se retiran con `activo = false`: es el interruptor
real —lo filtran nueve funciones SQL y el cargador del editor—, y saca la fila de la ficha, del
catálogo público y del demarcador de una vez, sin borrarla. Lo que **cuelga de una arquitectura**
—esquemas, secciones, rasgos, grupos— se retira con ella y no lleva flag propio. Y un **esquema,
una sección o una variedad sueltos se borran**: todas las claves ajenas de
`anotacion_elecciones` son `on delete restrict`, así que la base impide sola borrar lo que
una anotación use, que es una garantía más fuerte que un estado.

`estado_revision` **ya no existe** en el dominio métrico. Se retiró de sus doce tablas ese mismo
día: la escribían solo las pantallas del gestor mutable —retirado el 11 de agosto—, la leía un
único filtro que nunca excluyó nada, y lo que guardaba era el rastro de la última pantalla que
tocó cada fila, no un estado. **La revisión es la migración**, y queda en `git`. Cuidado al
buscarla: `permissions.ts` y `/dashboard/vocabularios` mencionan un `estado_revision` que es otra
cosa, una categoría del vocabulario legado.

**Una afirmación no se reutiliza entre formas.** Cada fuente dice lo que dice **de cada forma**, y
una misma afirmación servida a varias acaba hablando de otra estrofa en tres de ellas: pasó el 20
de agosto de 2026 al mover al rasgo `pie_quebrado` la bibliografía de la copla de pie quebrado, y
la ficha de la copla real amaneció con dos notas de fuente sobre la sextilla. Cuando una fuente
documenta algo que toca a varias formas, **se integra en la afirmación que cada una ya tiene**, con
lo que esa fuente dice de ella; si no dice nada de una forma, esa forma no lleva nota.

**Las seis monografías, dónde están y cómo se citan:**
[las fuentes del catálogo](./fuentes-del-catalogo.md). Ahí va también el aviso que costó dos
descuidos: el texto de Morley y Bruerton es `definiciones_Morley&Bruerton.md`, en `.md` y sin sus
apellidos al principio, así que una búsqueda filtrada por `.txt` lo deja fuera y hace creer que su
libro no está.

**Que el auditor calle no prueba que la norma esté declarada.** El aviso `patron_rima_sin_regla`
se apaga en cuanto la arquitectura tiene *o* una restricción, *o* una densidad, *o* un esquema
concreto — y un esquema concreto no dice nada de la disposición abierta, que es la que la norma
declara. Así se le pasó al sexteto la densidad de rima de su arquitectura principal, y así la
tiene todavía la sextilla en dos de las suyas. Al revisar una forma con disposición abierta,
comprobar la densidad **arquitectura por arquitectura**, no fiarse del recuento.

**Tras cada migración, `npm run audit:metrica` debe dar 0 defectos** —necesita Docker levantado,
porque vuelca la base—. Y conviene mirar la ficha servida, no solo el dato: en esta fase, leerlas
una a una ha descubierto defectos de presentación que no se veían ni en el catálogo ni en el
código.

## Un volcado no trae vistas

El criterio de nivel está escrito en [criterios-de-nivel.md](./criterios-de-nivel.md) y
su cumplimiento se comprueba con `npm run audit:metrica`, que vuelca la base enlazada y
contrasta los datos poblados. El resultado vigente está en
[informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md). El informe separa
los incumplimientos objetivos de las matrices que describen dónde vive cada dimensión;
estas últimas son el material de las decisiones pendientes del IP, no errores.

**Un volcado no trae vistas, y hay una que el informe necesita.** `opciones_eleccion_metrica` es
una vista derivada desde el 11 de agosto de 2026, así que durante un día el informe leyó cero
opciones y firmó «0 defectos» sin haber mirado las reglas que dependen de ellas. Ahora esa
relación se pide por consulta y el informe **se planta** si el modelo se queda sin opciones. Si
otra tabla del catálogo se convierte en vista, hay que hacer lo mismo: `--dump` sobre una copia
local no puede verla.
