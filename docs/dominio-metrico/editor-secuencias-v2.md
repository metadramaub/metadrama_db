# Editor de secuencias métricas V2

Estado: primera versión de prueba en `develop`, aislada del editor de obras.

## Cómo está repartido el código

El formulario y el laboratorio son piezas distintas, para que la aprobación no obligue a
reescribir nada:

- `MetricSequenceEditor.svelte` es **el editor**. Recibe el catálogo —en el tipo estrecho
  `MetricCatalogForEditor`, sin escenarios ni estadísticas— y un borrador de partida; se
  queda con ese borrador, lo normaliza contra la arquitectura y devuelve su estado
  (resumen, progreso y el motivo por el que aún no se puede guardar). No conoce la ventana
  que lo abre ni la API que lo guarda, así que pasa al editor de obras sin tocarlo.
- `MetricStructureEditor`, `MetricChoiceField`, `MetricLengthAlert`, `editor-model.ts` y
  `sequence-draft.ts` son suyos y viajan con él.
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
- texto y ayuda para el editor;
- dimensión;
- alcance en toda la secuencia o en cada unidad;
- sección a la que se aplica;
- cardinalidad mínima y máxima;
- posibilidad de aplicar la respuesta a todas las unidades equivalentes.

No se crea un grupo para un resultado único que pueda derivarse automáticamente.

### `opciones_eleccion_metrica`

Cada respuesta apunta mediante FK a un dato normalizado:

- metro;
- patrón métrico;
- patrón de rima;
- sección;
- patrón de repetición;
- rasgo o valor de rasgo.

Así se controla lo que puede elegir el editor sin duplicar la ontología ni guardar respuestas
textuales difíciles de analizar.

La excepción son los esquemas observados de formas abiertas. Un grupo con
`tipo_control = esquema_rima` no enumera previamente todas las particiones posibles:
guarda una cadena validada con una posición por verso, letras normalizadas y guiones
para versos sueltos. La respuesta sigue vinculada a la pregunta, la configuración y la
unidad; no se convierte en observación libre ni en desviación.

Una opción puede declarar además un efecto de formulario:

- materializar una sección cuando la respuesta implica versos presentes;
- derivar su extensión de otra sección ya registrada.
- aplicar el valor a una `posicion_unidad` concreta, cuando la alternativa es posicional.

El efecto no sustituye el valor normalizado. «Repetición total del estribillo», por ejemplo,
sigue apuntando a su patrón de repetición y hace aparecer una sección cuyo número de versos se
calcula desde la primera aparición del estribillo.

En una copla real con pie quebrado, las opciones posicionales apuntan todas al metro de
4 sílabas y distinguen las posiciones 1-10. El editor las presenta como una única fila
compacta y guarda una o dos respuestas, no diez preguntas.

Una posición también puede admitir alternativas. En una estancia de canción
petrarquista, cada posición ofrece 7 u 11 sílabas mediante un selector propio. La
respuesta completa y la extensión de la estancia se pueden aplicar a todas las
unidades equivalentes; el editor cambia únicamente las excepciones.

## Tablas exclusivas de prueba

- `escenarios_editor_metrico`: sustituye temporalmente a una obra ficticia.
- `secuencias_editor_metrico`: rango, forma y configuración de cada prueba.
- `realizaciones_editor_metrico`: las unidades del pasaje y, dentro de ellas, coplas,
  cabezas, estribillos, repeticiones del estribillo u otras secciones enlazadas
  jerárquicamente mediante
  `realizacion_padre_id`. Una realización sin `seccion_id` es la unidad que define la
  forma: no es parte de nada y no cuelga de ninguna otra. La equivalencia es estricta y la
  base la impone: una realización no realiza ninguna sección exactamente cuando no tiene
  realización superior.
- `elecciones_editor_metrico`: respuesta general o por unidad.
- `desviaciones_editor_metrico`: diferencias localizadas respecto de lo admitido.

Todas tienen RLS para `admin` e `IP`. La función
`guardar_secuencia_editor_metrico_prueba` guarda cada secuencia con sus unidades, elecciones
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

- **La identificación se pliega.** Elegidas forma y arquitectura, versos y forma se
  resumen en una línea con «Cambiar versos o forma». El sitio es para las preguntas.
- **Las respuestas de dos a cuatro alternativas se enseñan enteras**, en un control
  segmentado, en lugar de esconderse tras un desplegable. Por encima de cuatro opciones, o
  con etiquetas largas, se vuelve al desplegable.
- **Las repeticiones idénticas son una tarjeta.** Doce redondillas que responden lo mismo
  se muestran como «Cada redondilla» y un recuento; contestar ahí contesta las doce. Se
  puede desplegar para hacer una excepción, y si alguna deja de coincidir la lista se abre
  sola, porque ya no dicen lo mismo.
- **La jerarquía se marca con un filete a la izquierda**, no solo con sangría.
- **El dorado del proyecto queda reservado** a la respuesta activa y a lo que falta por
  contestar. Las acciones secundarias van en gris subrayado (`.link-action`).
- **La cabecera dice cuántas respuestas obligatorias faltan** antes de pulsar Guardar.
- **El raíl queda fijo** mientras el cuerpo se desplaza, y cada grupo del mapa se
  corresponde con un grupo plegable del cuerpo, con su mismo título.

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
    `realizaciones_editor_metrico`. El formulario muestra el recuento, pero no obliga a
    editar cada unidad si todas cumplen la misma norma. Cuántas unidades hay se deriva del
    rango y de la extensión declarada por la arquitectura, así que no se añaden ni se
    quitan a mano; con una unidad de extensión variable —la copla de pie quebrado— ocurre
    al revés y es el rango el que se calcula.
14. Una composición se registra igual que una estrofa: tres sonetos seguidos son tres
    unidades de catorce versos, cada una con sus dos cuartetos y sus dos tercetos. Cuando
    la composición no declara su extensión —el villancico, el zéjel, la canción— el editor
    añade y quita unidades a mano y el rango se calcula desde ellas.

## Compatibilidad de longitud

La regla no se mantiene como una lista de nombres de formas. Se deriva, por este orden, del
número de versos de la configuración, de sus secciones exactas y de sus ciclos repetibles
de rima o medida.

| Caso | Regla derivada |
| --- | --- |
| Quintilla | múltiplo de 5 |
| Romance | múltiplo de 2 |
| Soneto | múltiplo de 14 |
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

| Alcance | Dato |
| --- | --- |
| Cada sección que pone versos | Medida: 6 u 8 sílabas. |
| Cada mudanza | Patrón: `abba`, `abab` o la realización asonantada `abcb`. |
| Cada copla | Enlace o vuelta como sección opcional, sin una pregunta redundante de presencia. |
| Cada ciclo posterior | El estribillo se repite entero, en parte o se sobreentiende. |

La repetición del estribillo no declara medida: sus versos son los del estribillo, así que su
medida se deriva y no se pregunta. La regla no nombra formas: ninguna sección cuyos versos los
pone otra sección declara medida propia.

En el formulario, la medida se pregunta una sola vez para toda la composición y las secciones
solo se abren de una en una cuando alguna difiere. El atajo es de interfaz: lo que se guarda
sigue siendo la medida de cada sección.

Los slugs técnicos heredados conservan `represa` para no romper referencias estables, pero no
se muestran como terminología del catálogo ni del editor: en ambos se lee siempre «Repetición
del estribillo». El uso bibliográfico de *represa* queda en las afirmaciones de las fuentes que
emplean ese término.

La configuración inicial crea la cabeza y el primer ciclo; la posterior crea una primera
copla seguida del primer estribillo. Cada copla contiene su mudanza y posible enlace o
vuelta. La repetición del estribillo es hermana de la copla, no hija suya. Una repetición total
o parcial
materializa versos; la implícita no inventa un rango. El formulario no infiere que una
sección final aislada sea estribillo: elegir esa función exige evidencia editorial.

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
