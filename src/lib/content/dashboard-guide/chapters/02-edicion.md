Este capítulo te acompaña en el trabajo principal dentro de una obra. La idea es que sepas qué información conviene incorporar, para qué sirve cada bloque y cómo priorizar cuando no tienes todos los datos desde el principio.

## Qué información incorporar y para qué

Al editar una obra estás construyendo una ficha útil para la investigación sobre su métrica, pero también una base que permitirá hacer análisis cuantitativos sobre el corpus en el futuro. Por eso registramos cada dato de forma tan específica.

En la práctica, trabajamos en tres capas de información, que se distribuyen en varias pestañas y múltiples campos:

1. Identificación y contexto de la obra (título, género, datación, edición base, autoría).
2. Estructura y análisis métrico (jornadas, cuadros, secuencias y variaciones métricas dentro de estas secuencias).
3. Tu aporte más personal: observaciones en diferentes puntos, sinopsis de cada secuencia métrica, caracterización de estas (para establecer relaciones entre la métrica y el contenido del texto) y bibliografía específica sobre la obra.

> [!IMPORTANT]
> Muchos campos son opcionales a nivel técnico, pero casi todos son recomendables a nivel editorial. Si dudas, prioriza dejar información útil, aunque sea breve.

## Qué es público y qué es interno

> [!NOTE]
> Como regla general, la información de contenido de la obra puede terminar en la ficha pública cuando la obra esté publicada y visible.

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

1. Prioriza consistencia con la obra completa.
2. Elige términos del vocabulario (si crees que falta alguno, indícalo o escríbenos un correo).
3. Si hay duda razonable, deja constancia breve de la decisión (pública o en comentario, según consideres).

Recuerda: una decisión documentada y consistente es mejor que una decisión perfecta pero opaca.

## Recorrido por pestañas de la obra

### Datos de la obra

Aquí defines la base descriptiva. Es la pestaña para fijar identidad y contexto de la obra.

Datos que puedes registrar:

- título principal y variantes;
- género;
- fecha tradicional (inicio/fin) y su fuente;
- edición base utilizada.

La fuente bibliográfica y la edición base admiten [Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

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
[PENDIENTE]

> [!TIP] 
> Incluye la certeza con la que has definido cada cuadro. Esta información no se hará pública, pero ayuda mucho en revisión interna.

> [!DANGER]
> Antes de pasar a secuencias, confirma que no hay solapes evidentes de rangos de versos entre jornadas o cuadros.

### Secuencias

Aquí haces el análisis métrico más detallado. Es la pestaña más densa, y conviene trabajarla en dos pasadas: primero declarar secuencias base y luego completar su análisis.

> [!TIP]
> uedes usar filtros por estrofa y certeza para localizar y revisar mejor lo ya cargado.

En cada secuencia registras:

- verso inicial y verso final;
- tipo de estrofa;
- caracterización de la secuencia;
- sinopsis argumental;
- certeza editorial.

La sinopsis argumental también admite Markdown. Puedes ver pautas al final, en [Sobre los campos de texto largos y Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

Dentro de la caracterización, marcas:

- personaje femenino (`ausente`, `solo`, `con_otros`);
- donaire (`ausente`, `solo`, `con_otros`);
- sobrenatural (`ausente`, `solo`, `con_otros`);
- versos partidos (`sí/no`);
- inaugura espacio (`sí/no`);

Para la sinopsis argumental, ten en cuenta:
[PENDIENTE]


#### Variaciones o irregularidades (dentro de una secuencia)

A veces una secuencia métrica puede contener alguna variación que no necesariamente requiere la creación de una nueva secuencia, o alguna irregularidad métrica relevante. 

Para poder añadir variaciones (tantas como necesites), debes guardar al menos una vez la secuencia en edición.

Por ejemplo, contemplamos:
- versos cantados;
- versos de medida irregular (hipométricos o hipermétricos);
- rimas defectuosas o diferentes a lo esperado según la tipología estrófica;
- lagunas textuales;
- prosa dentro de una secuencia métrica.

Cada variación incluye:

- tipo de variación;
- verso inicial y verso final (que puede ser el mismo, si se trata de solo un verso);
- observaciones específicas de esa variación (cualquier dato extra que quieras añadir, será público).

Las observaciones de variación admiten [Markdown](#sobre-los-campos-de-texto-largos-y-markdown).

Consideraciones importantes:

- la variación debe quedar dentro del rango de versos de su secuencia;
- el tipo `irregular` funciona como agrupador y no se selecciona directamente;
- si existe una secuencia cantada con versificación muy irregular, elegir la tipología estrófica `irregular` después la variación `cantado`;
- en `prosa`, `v_ini` y `v_fin` indican el verso anterior y posterio a la prosa, pues esta, en realidad, no está numerada;
- en `hipométrico` e `hipermétrico`, `v_ini` y `v_fin` deben ser el mismo verso, declarando cara irregularidad de forma individual;
- en tipos como `cantado`, `rima defectuosa` o `laguna`, puedes marcar un solo verso o un rango.

#### Subtipos internos de quintilla

Los subtipos solo se habilitan cuando la estrofa de la secuencia es `quintilla`, y también requieren que la secuencia esté guardada.

En cada subtipo registras:

- subtipo de quintilla;
- verso inicial y verso final del subtipo dentro de la secuencia.

> [!IMPORTANTE]
> el rango del subtipo debe quedar dentro del rango de su secuencia.

### Autoría

Esta pestaña está pendiente de adaptarse al nuevo modelo de autoría, pero en el estado actual permite:

- registrar la URL del informe ETSO;
- asignar autoría en modo `obra completa`.

### Observaciones

Aquí incorporas todo aquello que no hayas podido reflejar en el resto de campos, o todo lo que pueda ser útil para los usuarios finales de la base de datos de cara a la interpretación de los datos.

En esta pestaña registras:

- observaciones sobre la obra;
- bibliografía específica (otros estudios sobre la métrica de la obra).

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
4. Haz una segunda pasada de secuencias para completar su análisis (caracterización, sinopsis y variaciones).
5. Revisa todo y deja tus observaciones generales y bibliografía específica.
6. Cambia el estado de `borrador` a `pendiente` cuando termines.

> [!TIP]
> Deja clara la certeza de tus decisiones y usa comentarios internos cuando haya dudas o casos discutibles.

## Sobre los campos de texto largos y Markdown

En los campos de texto largos del editor puedes escribir en Markdown (por ejemplo: fuente bibliográfica, edición base, sinopsis, observaciones o bibliografía).

Markdown es un formato de marcado simple que permite dar estructura al texto (negrita, cursiva, listas, enlaces, etc.) sin complicar la edición.

Lo usamos para mantener un formato consistente y facilitar que el contenido se renderice bien en la interfaz de consulta pública sin necesidad de aprender HTML.

#### Ejemplo rápido: Markdown -> vista previa

<div class="markdown-fake-preview">
  <div class="markdown-fake-preview__head">
    <div class="markdown-fake-preview__title">Markdown</div>
    <div class="markdown-fake-preview__title">Vista previa</div>
  </div>
  <div class="markdown-fake-preview__split">
    <div class="markdown-fake-preview__pane markdown-fake-preview__pane--code">
      <pre class="markdown-fake-preview__pre">### Ejemplo lorem ipsum

Lorem ipsum dolor sit amet, **consectetur adipiscing elit**, sed do *eiusmod tempor* incididunt ut labore. Consulta [este enlace](https://url.com).

- Primer punto de lista
- Segundo punto de lista

1. Paso uno
2. Paso dos</pre>
    </div>
    <div class="markdown-fake-preview__pane markdown-fake-preview__pane--render">
      <h4 class="!mt-0 text-base font-semibold">Ejemplo lorem ipsum</h4>
      <p>Lorem ipsum dolor sit amet, <strong>consectetur adipiscing elit</strong>, sed do <em>eiusmod tempor</em> incididunt ut labore. Consulta <a href="https://url.com" target="_blank" rel="noreferrer">este enlace</a>.</p>
      <ul class="mt-2 list-disc space-y-1 pl-6">
        <li>Primer punto de lista</li>
        <li>Segundo punto de lista</li>
      </ul>
      <ol class="mt-2 list-decimal space-y-1 pl-6">
        <li>Paso uno</li>
        <li>Paso dos</li>
      </ol>
    </div>
  </div>
</div>

Para facilitar tu tarea, tienes una barra mínima de herramientas que te ayuda a aplicar este formato de forma rápida, pero también puedes introducir tú mismo las marcas. Si quieres ver cómo se va renderizar después, haz clic en `vista previa`.

Si quieres una aprender más, puedes consultar la sintaxis básica aquí: [Guía Markdown en español](https://github.com/WordPress/spain-handbook/blob/main/manuales/markdown/index.md). No contemplamos todos los estilos, así que, si necesites alguno nuevo, puedes escribir a `david.merino@uab.cat`.
