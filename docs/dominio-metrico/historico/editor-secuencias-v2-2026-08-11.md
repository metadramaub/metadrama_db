# Editor de secuencias métricas V2 — fotografía del 11 de agosto de 2026

> **Documento histórico.** Sirvió para construir la primera versión del editor y conserva las
> decisiones de ese corte, pero no se mantiene sincronizado con la interfaz. El comportamiento
> vigente se deriva del catálogo y vive en `src/lib/components/metrica/editor-v2/`, con sus
> pruebas junto al código. La persistencia y las garantías del modelo se documentan en
> `implementacion-metrica.md`.

Estado: primera versión de prueba en `develop`, aislada del editor de obras.

## Cómo está repartido el código

El formulario y el laboratorio son piezas distintas, para que la aprobación no obligue a
reescribir nada:

- `MetricSequenceEditor.svelte` es **el editor**. Recibe el catálogo —en el tipo estrecho
  `MetricCatalogForEditor`, sin escenarios ni estadísticas— y un borrador de partida; se
  queda con ese borrador, lo normaliza contra la arquitectura y devuelve su estado
  (resumen, progreso y el motivo por el que aún no se puede guardar). No conoce la ventana
  que lo abre ni la API que lo guarda, así que pasa al editor de obras sin tocarlo.
- `MetricStructureEditor`, `MetricChoiceField`, `MetricFamilyControl`, `MetricGridRow`,
  `MetricLengthAlert`, `editor-model.ts`, `grid-rows.ts` y `sequence-draft.ts` son suyos y
  viajan con él. `grid-rows.ts` decide qué filas pinta la rejilla y no toca la pantalla:
  está aparte para poder probarlo.
- `MetricEditorSandbox.svelte` es **el laboratorio**, y es desechable: escenarios, tabla,
  réplica del panel de producción y llamadas a `/api/metrica/editor-pruebas`.
- El editor deja dos huecos al contenedor: `bodyExtra`, para el resto del formulario de la
  secuencia, y `extraRailItems`, para que esas secciones aparezcan en el mapa. En el
  laboratorio los rellena la réplica; en producción los rellenarán las caracterizaciones,
  la intervención de personajes y la sinopsis reales. El editor no las conoce.
- El control segmentado vive en `ui/segmented-choice.svelte`, fuera del dominio métrico,
  porque no tiene nada de métrico.

## Objetivo

Comprobar con casos reales si el catálogo genera un formulario breve, comprensible y
analíticamente útil antes de migrar las secuencias que están registrando los editores.

La prueba usa el mismo Supabase que producción, pero solo tablas nuevas. No crea obras, no
escribe en `secuencias_metricas`, no modifica `estrofa_tipo_id` y no alimenta fichas,
buscadores, resúmenes ni el checklist editorial.

## Fórmula de registro

```text
realización efectiva =
    forma
    + configuración
    + elecciones entre alternativas admitidas
    + realizaciones de la unidad y de sus secciones
    + desviaciones respecto de lo admitido

o, cuando no existe una forma reconocible:

    tramo sin forma
    + rango
    + observación opcional
```

Una elección ordinaria no es una desviación. En el villancico, `abba`, `abab` y la realización
asonantada `abcb` son respuestas
posibles a la pregunta por la rima de la mudanza; una ruptura que no encaje en ninguna de
ellas sí se registra como desviación.

`Versificación irregular` y `Verso aislado` siguen la segunda vía: no tienen
configuración, norma, unidades ni desviaciones. La primera abarca dos o más versos; la
segunda, exactamente uno.

## Tablas del catálogo

### `grupos_eleccion_metrica`

Define una pregunta que interesa responder:

- configuración;
- ayuda para el editor;
- dimensión;
- alcance en toda la secuencia o en cada unidad;
- sección a la que se aplica;
- cardinalidad mínima y máxima;
- posibilidad de aplicar la respuesta a todas las unidades equivalentes.

No se crea un grupo para un resultado único que pueda derivarse automáticamente.

**El enunciado no está entre sus columnas: se deriva.** Desde el 10 de agosto de 2026 se lee de
`grupos_eleccion_metrica_resueltos`, que lo compone con la dimensión y el nombre de la sección
—«Mudanza · Esquema de rima», «Medida de los quebrados»—, y en las elecciones de rasgo usa
`rasgos_metricos.nombre`. No hay columnas de preguntas redactadas a mano.

Va corto y sin artículo porque el catálogo no declara el género de nada. Y lleva la sección
dentro, no aparte, porque **el enunciado es además la clave con la que el editor pliega
preguntas**: las que comparten dimensión y enunciado se responden juntas, y así las dos mudanzas
del villancico —dos secciones distintas con el mismo nombre— siguen siendo una sola pregunta.

**`seccion_id` dice dónde se responde, no de qué trata.** El editor plantea la pregunta en cada
realización de esa sección, así que un grupo que la declare se pregunta tantas veces como veces
aparezca. Cuando la respuesta es una sola pero habla de una sección concreta —los cuatro esquemas
de tercetos del soneto describen sus dos realizaciones a la vez—, el grupo la deja sin declarar y
el sujeto lo ponen los esquemas, con `esquemas_rima.seccion_id`.

### `opciones_eleccion_metrica` — ya no es una tabla

Desde el 9 de agosto de 2026 es una **vista** que calcula las respuestas al leer, desde el
catálogo. No se escriben en ninguna parte: el gestor las muestra y el endpoint de entidades
las rechaza. Para cambiar una respuesta se cambia el esquema, el rasgo, la repetición o la
variedad de la que sale.

La derivación vive en `opciones_eleccion_derivadas()` y es la única definición de qué se
admite y cómo se rotula. Cada respuesta sigue apuntando a un dato normalizado —metro, patrón
métrico, patrón de rima, sección, patrón de repetición, valor de rasgo o variedad—, con la
diferencia de que ahora ese vínculo no se declara: es de donde la respuesta nace.

Su etiqueta es el nombre de la entidad, compuesto con la posición cuando la pregunta es
posicional, y su explicación es la `descripcion` de la entidad. Nada de eso se escribe dos
veces, que era justo lo que se estaba separando: la quintilla llegó a describir su `aabab`
como «cruzada, también llamada Cuarteta», copiado de la redondilla.

La tabla anterior se conservó apartada mientras se comprobaba la derivación, y **se retiró el 10
de agosto de 2026** junto con la función que las contrastaba: el guardado se había ejercitado
contra la vista con una inserción real y la derivación había sostenido cuatro migraciones más sin
que las 405 opciones se movieran. Lo que hubo está en el historial.

La excepción son los esquemas observados de formas abiertas. Un grupo con
`tipo_control = esquema_rima` no enumera previamente todas las particiones posibles:
guarda una cadena validada con una posición por verso, letras normalizadas y guiones
para versos sueltos. La respuesta sigue vinculada a la pregunta, la configuración y la
unidad; no se convierte en observación libre ni en desviación.

Una opción puede llevar además un efecto de formulario:

- materializar una sección cuando la respuesta implica versos presentes;
- derivar su extensión de otra sección ya registrada.
- aplicar el valor a una `posicion_unidad` concreta, cuando la alternativa es posicional.

Los dos primeros los declara la propia repetición, en `repeticiones_metricas`, y la opción los
arrastra; el tercero sale de la posición que la derivación recorre. El efecto no sustituye al
valor normalizado. «Repetición total del estribillo», por ejemplo, sigue apuntando a su patrón
de repetición y hace aparecer una sección cuyo número de versos se calcula desde la primera
aparición del estribillo.

En una copla real con pie quebrado, las opciones posicionales apuntan todas al metro de
4 sílabas y distinguen las posiciones 1-10. El editor las presenta como una única fila
compacta y guarda una o dos respuestas, no diez preguntas.

Una posición también puede admitir alternativas. En una estancia de canción
petrarquista, cada posición ofrece 7 u 11 sílabas mediante un selector propio. La
respuesta completa y la extensión de la estancia se pueden aplicar a todas las
unidades equivalentes; el editor cambia únicamente las excepciones.

## Tablas exclusivas de prueba

- `anotacion_escenarios_prueba`: sustituye temporalmente a una obra ficticia.
- `anotaciones_metricas`: rango, forma y configuración de cada prueba.
- `anotacion_realizaciones`: las unidades del pasaje y, dentro de ellas, coplas,
  cabezas, estribillos, repeticiones del estribillo u otras secciones enlazadas
  jerárquicamente mediante
  `realizacion_padre_id`. Una realización sin `seccion_id` es la unidad que define la
  forma: no es parte de nada y no cuelga de ninguna otra. La equivalencia es estricta y la
  base la impone: una realización no realiza ninguna sección exactamente cuando no tiene
  realización superior.
- `anotacion_elecciones`: respuesta general o por unidad.
- `anotacion_desviaciones`: diferencias localizadas respecto de lo admitido.

Todas tienen RLS para `admin` e `IP`. La función
`guardar_anotacion_metrica` guarda cada secuencia con sus unidades, elecciones
y desviaciones en una transacción.

## Presentación

El formulario se reparte en dos zonas dentro de la caja que lo contenga: un raíl estrecho
que es el **mapa** de la secuencia —identificación resuelta, contenido con lo que falta,
acciones para añadir— y un cuerpo ancho donde se responde una cosa cada vez. En pantalla
estrecha el raíl pasa arriba y el formulario queda en una columna.

El cuerpo lleva la secuencia entera, no solo lo métrico: las caracterizaciones, la
intervención de personajes y la sinopsis van a continuación, en el mismo flujo, porque el
editor las rellena en la misma pasada. En el laboratorio son una réplica que no guarda
nada, pero se muestran siempre y con su sitio real: la prueba consiste en juzgar cuánto
ocupa lo métrico dentro del panel completo, y eso no se puede ver si el resto está oculto.

### La estructura es una rejilla, y no se pliega

Desde el 11 de agosto de 2026. Antes había **seis interruptores de plegado independientes**,
de modo que una misma pregunta podía aparecer en tres sitios según qué combinación estuviera
abierta; de ahí salían tarjetas con cabecera y sin contenido y dos botones que llevaban al
mismo sitio por caminos distintos. El diagnóstico y las dos alternativas que se estudiaron
están en [propuesta-editor-v2.md](./propuesta-editor-v2-2026-08-11.md).

**A la izquierda la secuencia dibujada verso a verso, a la derecha lo que hay que responder
de cada parte.** Tres reglas la gobiernan:

1. **Una pregunta tiene un solo lugar estructural.** Conserva la realización donde se guarda,
   pero puede mostrarse en la sección de la que trata; no hay dos sitios donde responderla.
2. **Nada se enseña sin contenido.** Un bloque cuyas realizaciones no preguntan nada, no se
   pueden alargar ni quitar, se resume en una línea. No hay cabeceras vacías.
3. **Una sección que no pregunta nada no pinta contenedor.** La copla del villancico solo
   contiene la mudanza; sin esta regla, llegar a su esquema de rima costaba tres niveles de
   anidamiento para un desplegable. El enunciado que el catálogo deriva ya dice de qué
   sección habla —«Mudanza · Esquema de rima»—, así que la pregunta sube sin perder sujeto.

Arriba, en «Se responde una vez para todas», está el atajo: una línea por cada pregunta que
apunte a **dos o más** realizaciones y admita `permite_aplicar_global`. **No es un segundo
domicilio de la pregunta**: las filas de abajo siguen enseñando qué guarda cada realización.
Cuando todas coinciden, la fila recoge el control en un resumen con «Cambiar»; si alguna
diverge, vuelve a enseñar el control completo. Con una sola realización el atajo no aparece,
porque diría lo mismo que su fila.

**Las composiciones variables formadas por ciclos no usan esta zona.** En el villancico, el
zéjel o la canción, juntar «toda la composición», «todas las mudanzas» y «cada ciclo» vuelve
menos legible la estructura. Se responde directamente en cada parte, en orden de aparición.

El atajo no se limita a preguntas de una respuesta. Una serie posicional completa también se
puede copiar: en el pareado aparecen juntos «Medida de cada verso» —dos selectores, uno por
posición— y «Esquema de rima». Elegirlos arriba sigue escribiendo tres elecciones en cada
dístico; únicamente evita repetir los controles mientras todos dicen lo mismo.

Qué filas existen se decide en `grid-rows.ts`, aparte del componente, que es donde se puede
probar: las cuatro formas de referencia —quintilla, villancico, soneto y romance— están en
`grid-rows.test.ts` con los datos del catálogo.

- **La identificación se pliega.** Elegidas forma y arquitectura, versos y forma se
  resumen en una línea con «Cambiar versos o forma». El sitio es para las preguntas. No
  lleva encima un segundo plegado que diga lo mismo.
- **Las respuestas de dos a cuatro alternativas se enseñan enteras**, en un control
  segmentado, cuando el campo ocupa el ancho del formulario. **Dentro de la rejilla van
  siempre en desplegable**, aunque sean pocas, porque una lista de tres con sus
  explicaciones ocuparía más que la composición entera; a cambio, la explicación que el
  catálogo deriva de la respuesta elegida se lee debajo del control, y allí donde aporta:
  en el atajo y en la realización que diverge.
- **Una respuesta común contestada se resume en cada realización.** El valor sigue visible y
  «Cambiar» abre solo esa realización para registrar una excepción; no se vuelve a dibujar el
  mismo desplegable en todas las filas.
- **La jerarquía se marca con un filete a la izquierda**, no solo con sangría.
- **El dorado del proyecto queda reservado** a la respuesta activa y a lo que falta por
  contestar. Las acciones secundarias van en gris subrayado (`.link-action`).
- **La cabecera dice cuántas respuestas obligatorias faltan** antes de pulsar Guardar, y
  cuenta una por realización: lo mismo que hay en pantalla.
- **El raíl queda fijo** mientras el cuerpo se desplaza, y cada destino del mapa se
  corresponde con una sección del cuerpo, con su mismo título.
- **Una sección que aparece porque una respuesta la materializa no se quita a mano.** Se
  quita cambiando la respuesta. Quitarla dejaba «se repite entero» apuntando a una
  repetición que ya no existía.
- **La pregunta que materializa una sección se coloca en esa sección.** En el villancico, la
  repetición se guarda en el ciclo pero se pregunta después de mudanza y enlace o vuelta,
  donde aparece el estribillo. Si se sobreentiende y no materializa versos, conserva una fila
  funcional en ese mismo lugar; no se inventa rango ni realización.
- **Cada ciclo repetible abre un bloque visual.** Se añade con una acción al final y, cuando
  sobra alguno, se quita desde su propia cabecera. La composición raíz no tiene contador:
  una secuencia contiene un villancico y este crece mediante sus ciclos.

### La observación libre de una forma no existe

Una secuencia con forma reconocida **no** tiene campo de observaciones. Lo que el editor
quiera anotar sobre ella va a los comentarios internos, que ya se anclan a la secuencia
(`comentarios_internos.secuencia_id`), se tipifican —general, revisión, técnico, estado—,
guardan autoría y fecha, y pueden hacerse públicos. Un campo libre paralelo no aportaba
ninguna de esas cuatro cosas y partía en dos el mismo trabajo.

Se conservan dos usos que no son comentarios:

- la **observación del tramo sin forma**, que el modelo declara como parte del registro
  (`tramo sin forma + rango + observación opcional`);
- la **descripción de cada desviación**, que va pegada a la desviación y es dato
  estructurado.

## Comportamiento del formulario

1. El editor elige forma.
2. Si solo existe una configuración, puede resolverse automáticamente; si hay varias, debe
   seleccionar una.
3. Se muestran únicamente los grupos activos de esa configuración.
4. Las preguntas generales se responden una vez.
5. Si la configuración no tiene ni unidad declarada ni estructura interna editable, no
   aparece ningún constructor de unidades.
6. En una forma compuesta, las secciones obligatorias y sus rangos se derivan; el editor solo
   añade secciones opcionales e indica longitudes variables.
7. Las preguntas con alcance por unidad aparecen en su sección exacta, no en el contenedor.
   Una pregunta sin sección se refiere a la unidad entera y aparece en ella.
8. Una respuesta puede copiarse a todas las unidades equivalentes y después corregirse donde
   cambie.
9. El bloque de desviaciones permanece vacío por defecto.
10. Una pregunta obligatoria sin respuesta impide guardar.
11. La ausencia de desviaciones significa cumplimiento, no falta de revisión.
12. El rango inclusivo debe ser compatible con la extensión o el ciclo de la
    configuración. La comprobación se deriva del catálogo y se repite en la base de datos.
13. En una tirada de unidades fijas, el editor materializa silenciosamente una unidad por
    cada tramo: 48 versos de redondillas producen 12 filas de 4 versos en
    `anotacion_realizaciones`. El formulario muestra el recuento, pero no obliga a
    editar cada unidad si todas cumplen la misma norma. Cuántas unidades hay se deriva del
    rango y de la extensión declarada por la arquitectura, así que no se añaden ni se
    quitan a mano; con una unidad de extensión variable —la copla de pie quebrado— ocurre
    al revés y es el rango el que se calcula.
14. Una composición fija se registra igual que una estrofa: tres sonetos seguidos son tres
    unidades de catorce versos, cada una con sus dos cuartetos y sus dos tercetos. Cuando
    la composición no declara su extensión —el villancico, el zéjel, la canción— hay una sola
    unidad raíz y el editor añade o quita sus ciclos y secciones; el rango se calcula desde
    esas partes.

## Compatibilidad de longitud

La regla no se mantiene como una lista de nombres de formas. Se deriva, por este orden, del
número de versos de la configuración, de sus secciones exactas y de sus ciclos repetibles
de rima o medida.

| Caso               | Regla derivada                           |
| ------------------ | ---------------------------------------- |
| Quintilla          | múltiplo de 5                            |
| Romance            | múltiplo de 2                            |
| Soneto             | múltiplo de 14                           |
| Terceto encadenado | grupos de 3 más el verso final de cierre |

El formulario calcula siempre `v_fin - v_ini + 1`. Un rango incompatible impide guardar y
pide revisar la anotación o la fuente. Si falta un verso en el testimonio, se incorpora la
posición necesaria al cómputo y se registra la laguna como desviación; la norma no se
desactiva para ese caso.

## Primer caso completo: villancico

La forma ofrece dos configuraciones legibles:

- `estribillo_inicial`: el estribillo abre la composición y esa primera aparición es la
  cabeza;
- `estribillo_tras_primera_copla`: la primera aparición sigue a la primera copla y no se
  denomina cabeza.

Ambas generan:

| Alcance                      | Dato                                                                             |
| ---------------------------- | -------------------------------------------------------------------------------- |
| Cada sección que pone versos | Medida: 6 u 8 sílabas.                                                           |
| Cada mudanza                 | Patrón: `abba`, `abab` o la realización asonantada `abcb`.                       |
| Cada copla                   | Enlace o vuelta como sección opcional, sin una pregunta redundante de presencia. |
| Cada ciclo posterior         | El estribillo se repite entero o en parte.                                       |

La repetición del estribillo no declara medida: sus versos son los del estribillo, así que su
medida se deriva y no se pregunta. La regla no nombra formas: ninguna sección cuyos versos los
pone otra sección declara medida propia.

En `estribillo_tras_primera_copla`, la referencia de extensión apunta a la misma sección porque
la primera aparición y las reapariciones son realizaciones de un único `estribillo`. El editor la
resuelve por orden: la primera aparición permite declarar sus 1–4 versos y una aparición posterior
marcada como repetición total toma esa extensión. La primera nunca se toma a sí misma como fuente.

En el formulario, cada medida se responde en la sección a la que pertenece. El villancico
heterométrico que documenta Navarro Tomás —cuarteta octosilábica seguida de estribillo en
cuarteta hexasílaba— se registra sin pasar por una respuesta global ambigua: cabeza, mudanza,
enlace o vuelta y repetición se leen en su orden. Cada ciclo tiene una cabecera propia y la
composición crece con «Añadir ciclo», no con un contador de villancicos.

Los slugs técnicos heredados conservan `represa` para no romper referencias estables, pero no
se muestran como terminología del catálogo ni del editor: en ambos se lee siempre «Repetición
del estribillo». El uso bibliográfico de _represa_ queda en las afirmaciones de las fuentes que
emplean ese término.

La configuración inicial crea la cabeza y el primer ciclo; la posterior crea una primera
copla seguida del primer estribillo. Cada copla contiene su mudanza y posible enlace o
vuelta. La repetición del estribillo es hermana de la copla, no hija suya. La primera aparición
posterior declara sus versos y no pregunta modalidad; desde el segundo ciclo, cada repetición
es total o parcial y materializa únicamente los versos que ofrece la edición crítica.

Tras elegir forma y arquitectura, el Editor V2 muestra solo la norma estructurada que ya fija el
catálogo —extensión, partes, medidas y rimas fijas— y un enlace a la ficha pública completa. No
repite allí las definiciones: las decisiones variables aparecen justo después, en sus controles,
y la teoría general queda en la guía del dashboard.

## Segundo caso: soneto

La única configuración se selecciona automáticamente. El editor responde una sola
pregunta, «¿Qué esquema presentan los tercetos?», con los cuatro patrones reconocidos por
el catálogo. La elección se guarda como referencia normalizada; la estructura fija y la
compatibilidad con catorce versos se derivan.

En formas simples se mantiene el camino corto: forma, las pocas elecciones realmente
registrables y guardado. La complejidad del catálogo no se traslada al formulario.

## Paso futuro

Cuando el catálogo y la interfaz estén validados:

1. se auditarán las anotaciones reales;
2. se crearán las tablas definitivas enlazadas con `secuencias_metricas`;
3. se migrará `estrofa_tipo_id`, los subtipos y las irregularidades existentes;
4. el componente V2 sustituirá al selector legado;
5. las tablas de escenarios de prueba podrán retirarse sin afectar a las obras.
