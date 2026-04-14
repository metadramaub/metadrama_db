Este capítulo te acompaña en el trabajo principal dentro de una obra. La idea es que sepas qué información conviene incorporar, para qué sirve cada bloque y cómo priorizar cuando no tienes todos los datos desde el principio.

## Qué información incorporar y para qué

Al editar una obra estás construyendo una ficha útil para la investigación sobre su métrica, pero también una base que permitirá hacer análisis cuantitativos sobre el corpus en el futuro. Por eso registramos cada dato de forma tan específica.

En la práctica, trabajamos en tres capas de información, que se distribuyen en varias pestañas y múltiples campos:

1. Identificación y contexto de la obra (título, género, datación, edición base, autoría).
2. Estructura y análisis métrico (jornadas, cuadros, secuencias y caracterizaciones por rango dentro de estas secuencias).
3. Tu aporte más personal: observaciones en diferentes puntos, sinopsis de cada secuencia métrica, caracterización de estas (para establecer relaciones entre la métrica y el contenido del texto) y bibliografía específica sobre la obra.

> [!IMPORTANT]
> Muchos campos son opcionales a nivel técnico, pero casi todos son recomendables a nivel editorial. Si dudas, prioriza dejar información útil, aunque sea breve.

## Qué es público y qué es interno

> [!NOTE]
> Como regla general, toda la información introducida puede terminar en la ficha pública cuando la obra esté publicada y visible. La excepción es el conjunto de campos donde se indique “Comentarios internos” u “Observaciones internas”.

Será siempre contenido público:

- datos de la obra (título y variantes, género, datación, edición base, autoría);
- estructura y secuencias;
- observaciones y bibliografía;
- la persona responsable de la edición y/o revisión de cada obra.

Es contenido interno (no público):

- comentarios internos en cada obra (incluidos los de jornadas, cuadros, secuencias y revisión);
- notas operativas de revisión;
- decisiones de asignación editorial.

## Cómo tomar decisiones editoriales

Cuando haya varias opciones posibles, usa este criterio simple:

1. Prioriza coherencia con la obra completa.
2. Elige términos del vocabulario (si crees que falta alguno, indícalo o escríbenos un correo).
3. Si hay duda razonable, deja constancia breve de la decisión (pública o en comentario interno, según consideres).

Recuerda: una decisión documentada y coherente es mejor que una decisión perfecta pero opaca.

## Recorrido por pestañas de la obra

### Datos de la obra

Aquí defines la base descriptiva. Es la pestaña para fijar identidad y contexto de la obra.

Datos que puedes registrar:

- título principal;
- género;
- fecha tradicional;
- fuente bibliográfica de la que has extraído la fecha o el rango posible de fechas;
- edición base utilizada para leer la obra y realizar la ficha;
- variantes de título de la obra (si los hubiere).

La fuente bibliográfica y la edición base admiten [Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

En `edición base utilizada`, puedes añadir al final de cada referencia una indicación entre corchetes para señalar su uso, por ejemplo `[Texto base]` o `[Sinopsis argumental]`. Si no se especifica nada, se asume `[Texto base]`.

> [!IMPORTANT]
> Aunque algunas fechas no se sepan con seguridad, deja la mejor aproximación disponible y cita siempre la fuente. Si la fecha está segura y no hay un rango, introduce el mismo año en ambos campos.

### Estructura

Aquí organizas la arquitectura del texto por jornadas y cuadros, con sus rangos de versos. 

> [!DANGER]
> Introduce al menos la división de jornadas antes de declarar las secuencias métricas en la siguiente.

En esta pestaña puedes registrar:

- en cada jornada: número de jornada, verso inicial y verso final;
- en cada cuadro: jornada a la que pertenece, número de cuadro (numeración reiniciada en cada jornada), verso inicial, verso final y certeza de la delimitación.

Recomendaciones para la delimitación de los cuadros: 
* aunque la bibliografía no sea unánime, desde METADRAMA entendemos por cambio de cuadro un vacío total de personajes en escena. 
* La única excepción es el cambio de jornada: una jornada nueva implica siempre un cuadro nuevo con independencia de los personajes que la inauguren. El cambio de jornada es un muro inquebrantable.
* ¡Cuidado con los cambios de cuadro sutiles! A veces, un personaje ve a alguien que se acerca y decide retirarse. El recién llegado habla con la misma métrica, están en el mismo espacio y tiempo, pero ha habido un vacío escénico de pocos segundos. Estamos ante dos cuadros distintos aunque están articulados o encadenados, es decir, el dramaturgo está mostrando que hay una continuidad de bloque escénico en ambos cuadros.
* ¡Cuidado con los falsos cambios de cuadro! A veces un personaje parece que se va, pero permanece escondido para espiar la escena y luego reaparece. Esto es un único cuadro. 

> [!TIP] 
> Incluye siempre la certeza con la que has definido cada cuadro. Si el cambio de cuadro es claro selecciona “certeza alta”, pero, si fuese dudoso, selecciona “media” o “baja”. Esta información no se hará pública, pero ayuda mucho en revisión interna.

> [!DANGER]
> Antes de pasar a secuencias, confirma que no hay solapamientos evidentes de rangos de versos entre jornadas o cuadros.

### Secuencias

Aquí haces el análisis métrico más detallado. 

> [!TIP]
> Es la pestaña más compleja, y conviene trabajarla en dos pasadas: primero declarar secuencias base y luego completar su análisis.

En cada secuencia registras:

- verso inicial y verso final;
- tipo de estrofa;
- si hay caracterizaciones por rango (por ejemplo, si esa estrofa es cantada, si falta un verso en una redondilla o si hay defectos o variaciones métricas especiales);
- caracterización de la secuencia a través de varios ítems (por ejemplo, si interviene el gracioso en ella o si hay un cambio de espacio);
- sinopsis argumental;
- certeza de las decisiones tomadas (por ejemplo, si no estás seguro de la estrofa métrica seleccionada).

> [!IMPORTANT]
> ¿Qué hacer si una forma métrica (o una variación o patrón distinto de la misma) presente en la obra no aparece entre las opciones seleccionables de la base de datos? En ese caso, descríbela en los comentarios internos. Una vez la ficha se haya revisado, se dará de alta la nueva forma métrica para que el editor responsable pueda editar su ficha y seleccionar la opción adecuada.

La sinopsis argumental también admite Markdown. Puedes ver pautas al final, en [Sobre los campos de texto largos y Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

Dentro de la caracterización, marcas:

- personaje femenino (`ausente`, `solo`, `con_otros`);
- donaire (`ausente`, `solo`, `con_otros`);
- sobrenatural (`ausente`, `solo`, `con_otros`);
- versos partidos (`sí/no`);
- inaugura espacio (`sí/no`);

Para la sinopsis argumental, ten en cuenta dar toda la información general de lo que ocurre y también algunos detalles importantes, porque pueden ser útiles para, en el futuro de nuestro proyecto, poder determinar las funciones de la métrica según lo que pasa en cada secuencia. 
Un modelo puede ser este de Antonucci para *La vida es sueño*. Fíjate en el resumen que hace para las dos primeras secuencias (silva de pareados y décimas):

> [*Secuencia 1*]
> En lo alto de un monte, sale Rosaura, vestida de hombre, increpando a su cabalgadura que acaba de desarzonarla. Su llegada a Polonia no parece haberse realizado bajo los mejores auspicios: ya es casi de noche y ni ella ni su criado Clarín saben adónde encontrar refugio. De lejos ven una torre que casi se confunde con las peñas y deciden acercarse (espacio itinerante). Al llegar allí escuchan ruido de cadenas y un quejido; un paso más y ven una habitación oscura en la que yace un prisionero vestido de pieles.

> [*Secuencia 2*]
> Quedándose a los umbrales, y habiendo salido ya al tablado Segismundo, escuchan un largo monólogo en el que este se pregunta por qué está preso, por qué, único entre las criaturas vivientes, se le ha privado de su libertad. Al manifestar Rosaura la conmoción que siente, el prisionero se da cuenta de que alguien ha escuchado sus palabras y se abalanza sobre los intrusos para matarlos, porque han escuchado sus “flaquezas” (v. 182). Rosaura se arrodilla delante de él confiando en su piedad y enseguida la actitud del prisionero cambia: declara sentir algo nuevo, algo que lo empuja a mirar al desconocido una y otra vez como si sus ojos fueran “hidrópicos” (v. 227). Rosaura reconoce que, ante las penas del prisionero, las suyas le parecen menores.


#### Caracterizaciones por rango (dentro de una secuencia)

A veces una secuencia métrica puede contener fenómenos internos que no requieren la creación de una nueva secuencia, pero sí conviene declarar por rango.

Para poder añadir caracterizaciones por rango (tantas como necesites), debes guardar al menos una vez la secuencia en edición.

Por ejemplo, contemplamos:
- versos cantados;
- versos de medida irregular (hipométricos o hipermétricos);
- rimas defectuosas o diferentes a lo esperado según la tipología estrófica;
- patrones alternativos a lo esperado según la tipología estrófica;
- lagunas textuales;
- prosa dentro de una secuencia métrica;
- tramos con mayoría de agudas o mayoría de esdrújulas.

Cada caracterización por rango incluye:

- tipo de caracterización;
- verso inicial y verso final (que puede ser el mismo, si se trata de solo un verso);
- observaciones específicas de esa caracterización (cualquier dato extra que quieras añadir, será público).

Las observaciones de caracterización admiten [Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

Consideraciones importantes:

- la caracterización debe quedar dentro del rango de versos de su secuencia;
- los tipos padre (`fenomenos_enunciativos`, `irregularidades_metricas`, `final_acentual`) funcionan como agrupadores y no se seleccionan directamente;
- si existe una secuencia cantada con versificación muy irregular, puedes combinar varias caracterizaciones por rango dentro de la misma secuencia;
- si existe una secuencia cantada que parece una estrofa concreta (por ejemplo, redondilla), pero tiene una versificación muy irregular, no debes elegir “redondilla” como tipo de estrofa, sino “irregular” y, dentro de las caracterizaciones, marcar “cantado”;
- en `prosa`, `v_ini` y `v_fin` indican el verso anterior y posterior a la prosa, pues esta, en realidad, no está numerada;
- en `hipométrico` e `hipermétrico`, `v_ini` y `v_fin` deben ser el mismo verso, declarando cada irregularidad de forma individual;
- en tipos como `cantado`, `rima defectuosa`, `laguna`, `mayoria_agudas` o `mayoria_esdrujulas`, puedes marcar un solo verso o un rango.

#### Subtipos internos de quintilla

De momento, los subtipos extraordinarios solo se habilitan cuando la estrofa de la secuencia es `quintilla`, y también requieren que la secuencia esté guardada.

En cada subtipo registras:

- subtipo de quintilla (por ejemplo, ababa);
- verso inicial y verso final del subtipo dentro de la secuencia.

> [!IMPORTANT]
> El rango del subtipo debe quedar dentro del rango de su secuencia.

### Autoría

Esta pestaña está pendiente de adaptarse al nuevo modelo de autoría, pero en el estado actual permite:

- registrar una `fuente_autoria` en Markdown (opcional) dentro de cada atribución;
- asignar autoría en modo `obra completa` o `por jornadas`.

Reglas de trabajo recomendadas:

- no crees un autor ficticio como “desconocido”;
- si la autoría es desconocida, usa la modalidad `desconocida` y deja la atribución sin autores seleccionados;
- en `única`, debes seleccionar exactamente 1 autor;
- en `alternativa` y `colaborativa`, debes seleccionar 2 o más autores;
- en `desconocida`, debes dejar 0 autores.

Esto ayuda a distinguir, de cara al análisis posterior, entre una obra sin revisión de autoría y una obra con autoría revisada pero desconocida.

### Observaciones

Aquí incorporas todo aquello que no hayas podido reflejar en el resto de campos, o todo lo que pueda ser útil para los usuarios finales de la base de datos de cara a la interpretación de los datos. Se trata de observaciones públicas.

En esta pestaña registras:

- observaciones sobre la obra;
- bibliografía específica (no estudios generales sobre una obra, sino estudios específicos que traten sobre la métrica de la obra).

Como en otros campos de texto largos, ambos admiten [Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

### Revisión

Esta pestaña te sirve para cerrar el ciclo:

- revisar el checklist de información (datos, estructura, secuencias, autoría, observaciones y bibliografía);
- dejar o responder comentarios internos;
- actualizar estado de `borrador` a `pendiente` (de revisión), cuando tu rol lo permita.

## Orden recomendado de trabajo

Todo el contenido de la obra debe quedar completo antes de pasarla a revisión. Para hacerlo con más facilidad, te recomendamos este orden:

1. Completa primero los datos base: título y variantes, género, datación, fuente, edición base y autoría. El título y la autoría, generalmente, ya vendrán declarados.
2. Define la estructura de la obra (jornadas y cuadros), para poder trabajar después con estos rangos.
3. Declara todas las secuencias métricas en una primera pasada (rango de versos y tipología).
4. Haz una segunda pasada de secuencias para completar su análisis (caracterización, sinopsis y caracterizaciones por rango).
5. Revisa todo y deja tus observaciones generales y bibliografía específica que hayas encontrado.
6. Cambia el estado de `borrador` a `pendiente` cuando termines.

> [!TIP]
> Deja clara la certeza de tus decisiones (alta, media o baja) y usa comentarios internos cuando haya dudas o casos discutibles.

## Sobre los campos de texto largos y Markdown

En los campos de texto largos del editor puedes escribir en Markdown (por ejemplo: fuente bibliográfica, edición base, sinopsis, observaciones o bibliografía).

Markdown es un formato de marcado simple que permite dar estructura al texto (negrita, cursiva, listas, enlaces, etc.) sin complicar la edición.

Lo usamos para mantener un formato consistente y facilitar que el contenido se renderice bien en la interfaz de consulta pública sin necesidad de aprender HTML.

#### Ejemplo rápido: Markdown -> vista previa

Escribes esto:

```md
### Ejemplo lorem ipsum
Lorem ipsum dolor sit amet, **consectetur adipiscing elit**, sed do *eiusmod tempor* incididunt ut labore. Consulta [este enlace](https://url.com).

- Primer punto de lista
- Segundo punto de lista

1. Paso uno
2. Paso dos
```

Y se verá así:

> ### Ejemplo lorem ipsum
>
> Lorem ipsum dolor sit amet, **consectetur adipiscing elit**, sed do *eiusmod tempor* incididunt ut labore. Consulta [este enlace](https://url.com).
>
> - Primer punto de lista
> - Segundo punto de lista
>
> 1. Paso uno
> 2. Paso dos

Para facilitar tu tarea, tienes una barra mínima de herramientas que te ayuda a aplicar este formato de forma rápida, pero también puedes introducir tú mismo las marcas. Si quieres ver cómo se va renderizar después, haz clic en `vista previa`.

Si quieres una aprender más, puedes consultar la sintaxis básica aquí: [Guía Markdown en español](https://github.com/WordPress/spain-handbook/blob/main/manuales/markdown/index.md). No contemplamos todos los estilos, así que, si necesites alguno nuevo, puedes escribir a `david.merino@uab.cat`.
