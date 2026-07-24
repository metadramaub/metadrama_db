La pestaña **Secuencias** es donde haces el análisis métrico más detallado. Es la más compleja de la obra.

> [!TIP]
> Conviene trabajarla en dos pasadas: primero declara las secuencias base (rango de versos y tipología) y luego completa su análisis (caracterización, sinopsis y caracterizaciones por rango).

Puedes declarar las secuencias antes que jornadas y cuadros.

> [!IMPORTANT]
> Si al corregir la numeración una secuencia se solapa temporalmente con otra, puedes guardar el borrador. Después de guardar, el sistema mostrará automáticamente un aviso y resaltará en rojo las secuencias afectadas hasta que ajustes sus rangos. Una obra con solapamientos no puede avanzar a revisión ni publicarse.
>
> Los huecos entre secuencias no se consideran errores: pueden corresponder, por ejemplo, a prosa o lagunas. Solo se señalan los rangos que se solapan.

Al abrir una secuencia (con **Nueva secuencia** o **Editar**) se despliega un panel lateral con estos bloques, en este orden. Los explicamos en el mismo orden en que los ves.

## Métrica base

Lo primero que rellenas:

- **Verso inicial** y **Verso final** de la secuencia;
- **Estrofa**: el tipo de estrofa, obligatorio.

El selector de estrofa es **jerárquico**: algunas formas tienen subformas anidadas. Elige siempre la **opción más específica** (la hija) que corresponda; las formas raíz que agrupan a otras no son seleccionables. Si dudas, empieza por la familia general y ve bajando.

> [!IMPORTANT]
> ¿Qué hacer si una forma métrica (o una variación o patrón distinto de la misma) presente en la obra no aparece entre las opciones seleccionables de la base de datos? **Avísanos para que demos de alta la opción o resolvamos la duda.** No sigas adelante con ese punto sin resolver: es mejor parar y aclararlo que arrastrar el problema al resto de la ficha.

## Subtipos internos y caracterizaciones por rango

Justo debajo de la métrica base aparecen dos bloques que **solo se activan cuando la secuencia ya está guardada** (necesitan un identificador para colgar de ella):

- **Subtipos internos**: solo se muestran cuando la estrofa es una que los admite (por ejemplo, quintilla).
- **Caracterizaciones por rango**: fenómenos internos de la secuencia (versos cantados, irregularidades, prosa, lagunas…).

Ambos se explican en detalle en [Paso 4 · Caracterizaciones por rango](/dashboard/guia/paso-caracterizaciones).

## Intervención de personajes

Indicas si en la secuencia interviene cada tipo de personaje, con tres valores: **sin intervención**, **intervención exclusiva** o **intervención compartida**.

Los tres selectores comienzan en blanco. Si guardas la secuencia sin completarlos, quedan marcados como **pendientes**; el sistema no los interpreta como "sin intervención".

- personajes femeninos;
- figuras de donaire;
- personajes sobrenaturales.

> [!IMPORTANT]
> "Intervención" se refiere a que el personaje **habla dentro de la secuencia**, no a su mera presencia escénica. Un personaje puede estar en escena sin intervenir métricamente en esa secuencia.

> [!NOTE]
> Por **figura de donaire** entendemos el personaje subalterno (típicamente el criado o gracioso) que contrasta con los amos y funciona como contrapunto de la acción principal. Es un criterio de tipo de personaje, lo relevante es su papel subalterno y no es necesario juzgar su comicidad.

## Otras caracterizaciones

Tres marcas más sobre la secuencia:

- **Versos partidos** (`pendiente/no/sí`): selecciona "sí" si hay versos repartidos entre intervenciones de distintos personajes.
- **Inaugura espacio** (`pendiente/no/sí`): selecciona "sí" si el inicio de la secuencia coincide, de forma evidente, con un cambio de espacio escénico.
- **Evocación métrica** (`pendiente/no/sí`): selecciona "sí" cuando el cambio de metro se deba a que un personaje **adopta, imita o reproduce la voz de otro personaje**. Al hacerlo, se abre un campo **"Explicación de la evocación métrica"** (admite [Markdown](/dashboard/guia/ref-markdown)) para que expliques brevemente el caso.

Las secuencias nuevas empiezan con estas caracterizaciones en **Pendiente**. Este estado permite guardar la secuencia y deja visible que el dato todavía debe revisarse.

## Sinopsis argumental

La sinopsis argumental admite [Markdown](/dashboard/guia/ref-markdown).

Da la información general de lo que ocurre y también los detalles importantes. Sé sistemático en la redacción: en el futuro trataremos de formalizar funciones dramáticas a partir de estos resúmenes y de relacionarlas con la métrica de cada secuencia, así que un resumen ordenado y consistente nos será mucho más útil. Puedes incorporar números de verso y citar versos o acotaciones si te ayuda.

Un modelo puede ser este de Antonucci para *La vida es sueño*. Fíjate en el resumen que hace para las dos primeras secuencias (silva de pareados y décimas):

> [*Secuencia 1*]
> En lo alto de un monte, sale Rosaura, vestida de hombre, increpando a su cabalgadura que acaba de desarzonarla. Su llegada a Polonia no parece haberse realizado bajo los mejores auspicios: ya es casi de noche y ni ella ni su criado Clarín saben adónde encontrar refugio. De lejos ven una torre que casi se confunde con las peñas y deciden acercarse (espacio itinerante). Al llegar allí escuchan ruido de cadenas y un quejido; un paso más y ven una habitación oscura en la que yace un prisionero vestido de pieles.

> [*Secuencia 2*]
> Quedándose a los umbrales, y habiendo salido ya al tablado Segismundo, escuchan un largo monólogo en el que este se pregunta por qué está preso, por qué, único entre las criaturas vivientes, se le ha privado de su libertad. Al manifestar Rosaura la conmoción que siente, el prisionero se da cuenta de que alguien ha escuchado sus palabras y se abalanza sobre los intrusos para matarlos, porque han escuchado sus "flaquezas" (v. 182). Rosaura se arrodilla delante de él confiando en su piedad y enseguida la actitud del prisionero cambia: declara sentir algo nuevo, algo que lo empuja a mirar al desconocido una y otra vez como si sus ojos fueran "hidrópicos" (v. 227). Rosaura reconoce que, ante las penas del prisionero, las suyas le parecen menores.
