# La precomputación y la ficha pública

> **Archivado el 16 de septiembre de 2026.** Es el diario de septiembre: las doce obras de prueba,
> el plan de cinco pasos que llevó la zona pública a artefactos JSON, y el inventario `FP-*` de la
> ficha pública, punto por punto, con lo que se decidió en cada uno.
>
> Se conserva porque **explica por qué la ficha enseña lo que enseña**: qué se probó en pantalla,
> qué se descartó y con qué razón. El contrato vigente de los artefactos está en
> [su arquitectura](../../arquitectura-artefactos-publicos.md), y lo que quedaba abierto al
> archivarlo pasó a [PENDIENTES](../../PENDIENTES.md).
>
> **Sus cifras y sus «pendiente» son del día en que se escribieron.**

[Informe automático de la precomputación](../../mapa-precomputacion.md).

## Doce obras de prueba, y por qué hicieron falta

**Hechas entre el 7 y el 8 de septiembre de 2026.** Rehecha la precomputación sobre el catálogo
nuevo, no quedaba una sola obra con perfil: las 92 del corpus hablan el vocabulario legado. Sin
datos no se podía ver si la ficha funcionaba, así que se sembraron obras.

El primer intento —un generador que escribía directamente en la base— tardaba **tres cuartos de
hora por vuelta** y producía obras que no se parecían a comedias: diez formas clavadas en todas,
más variedad en la jornada I que en la III por construcción, secuencias que pisaban los finales de
jornada. Lo que lo arregló fue **separar el plan de la escritura**:

- **`npm run guion:pruebas`** escribe `xml-lope/guiones/`, un JSON por obra que dice en claro qué se
  va a anotar —jornadas, cuadros y una línea por secuencia con su forma, su arquitectura y sus
  respuestas—, **sin tocar la base**. Tarda segundos, así que se puede revisar y corregir a mano.
- **`npm run aplicar:guiones`** lo ejecuta y no decide nada. Es idempotente.

El **esqueleto sale de comedias reales de ARTELOPE** —`xml-lope/esqueletos/`, doce elegidas al azar
entre las 365 del repositorio—, porque el reparto de formas, el largo de las tiradas y que ninguna
secuencia pise el final de una jornada es justo lo que no se puede inventar a ojo. De ellas se toma
solo la estructura: los títulos, los autores y las fechas son inventados y ningún verso del texto
llega a la base. Lo que ARTELOPE no tiene —arquitectura, esquema de rima, asonancia, rasgos— se
sortea del catálogo respetando lo que el catálogo declara.

**Dos cosas que se aprendieron y valen más que las obras:**

1. **El catálogo ya declara el alcance de cada pregunta.** `grupos_eleccion_metrica.alcance` vale
   `secuencia`, `unidad` o `realizacion`: la asonancia se responde una vez para todo el romance, el
   esquema de rima una vez por estrofa. Responder por unidad no era el error; el error era
   **rotar** por el repertorio y **contestar todas las preguntas opcionales**. Una tirada real tiene
   una disposición dominante y unas pocas unidades que se salen —las quintillas ya anotadas dicen
   `ababa` 32, `aabba` 17, `abaab` 3—, y una pregunta que admite cero respuestas normalmente se
   queda sin responder: había pie quebrado en las 1.751 redondillas de la primera siembra.
2. **Windows corta la línea de comandos en 32.767 caracteres y lo que sobra se pierde sin error.**
   El proceso arranca, no ejecuta nada y termina con éxito. Se midió: 34.258 caracteres
   desaparecían, 27.224 pasaban. `scripts/lib/consulta.mjs` manda por fichero lo que pase de 8.000,
   y eso protege a cualquier informe del proyecto.

**El villancico entró en la base por primera vez** al hacerlo. Es la única forma del catálogo que
nadie había guardado nunca, y lo que lo impedía era que sus partes tienen partes: la mudanza cuelga
de la copla, no del ciclo. Lo mismo con la canción, cuyo primer pie cuelga del fronte.

Resultado: **12 obras, 433 secuencias, todas anotadas**, con perfiles que se distinguen entre sí
—de 6 a 12 formas, número efectivo de 2,67 a 6,67, forma dominante del 31 % al 66 %— y con los casos
raros representados: una sextina, un villancico, versos cantados, un pasaje en prosa, dos lagunas,
un hipométrico, un hipermétrico, una rima fuera del repertorio y un rasgo que sobra.

**Advertencia para quien las use:** son datos inventados. Sirven para comprobar que la maquinaria
calcula y dibuja; **no sirven para validar un hallazgo**, porque los patrones que se encuentren
serán los del generador y no los de Lope.

## El plan pactado, completado en cinco pasos

Nace de una decisión del proyecto tomada el 8 de septiembre y completada el 12: **la ficha lee la
base en vivo solo para las obras en vista previa; si está publicada, todo lo que la hace visible
está precomputado.** El motivo es doble —velocidad y no depender de una cuenta gratuita de
Supabase—. La API estable ya no es una fila creciente de `obras_resumen`, sino un conjunto de
[artefactos JSON con contrato y clave propios](../../arquitectura-artefactos-publicos.md).

1. **Una sola función productora.** Una función construye el JSON de la ficha y el recompute
   **guarda ese mismo JSON** como artefacto. Así, la vista previa y el documento materializado son
   idénticos por construcción. Dentro del JSON entran también los
   comentarios públicos y la identidad del editor de la ficha: se regeneran al pulsar «Actualizar
   datos públicos», como todo lo demás. Fuera queda solo el **permiso** —quién mira—, porque no es
   contenido: la tabla guarda lo que ve un anónimo.
2. **La ficha lee el artefacto si la obra está publicada**, y llama a la función en vivo solo en vista
   previa, que es lo único que justifica el cálculo al vuelo.
3. **`/obras` no muestra las obras en vista previa** y lee solo el índice precomputado. Se llega a
   ellas desde el dashboard, así que el buscador se simplifica.
4. **Los agregados de una ficha se calculan en el navegador** a partir de su JSON: evolución de cada
   forma por jornadas, italianos contra españoles y transiciones entre formas. La comparación entre
   obras usa el artefacto compacto de análisis y no recalcula el corpus al abrir cada ficha.
5. **Se enseña lo que ya llega**: espacios inaugurados, versos cantados y prosa, y en
   qué secuencias intervienen personajes femeninos, figuras de donaire o sobrenaturales.

*Sobre «quién canta»: se mostrará lo que se sabe. Hoy la secuencia dice si interviene una mujer, un
donaire o un sobrenatural, no quién canta, y el modelo no se cambia por esto.*

**Los cinco pasos están hechos.** Los tres primeros se cerraron el 9 de septiembre sobre
`obras_resumen`; el 12 se sustituyó esa frontera por `artefactos_publicos`: la ficha publicada lee
`obra_ficha`, la vista previa sigue en vivo, `/obras` y `/autores` leen índices ligeros y el análisis
compacto por obra alimenta las comparativas del corpus. `obras_resumen` y `autores_resumen` quedan
como cálculo intermedio y fallback de primer despliegue, no como API pública que deba crecer.

### Paso 4 · Los agregados, en el navegador

En la ficha actual, estos agregados siguen saliendo del JSON que la página ya tiene cargado y se
calculan en cliente. Los mismos hechos normalizados se materializan además en `obra_analisis` para
comparar obras y alimentar el laboratorio sin descargar fichas completas ni bajar de nuevo a las
tablas de anotación.

El cálculo vive en **un módulo puro y probado**, `src/lib/metrica/analisis-ficha.ts` —**escrito el
9 de septiembre de 2026**, con catorce pruebas—, y los componentes solo pintan: la misma división
que `rejilla.ts`, que es la que ha aguantado bien. Consume un tipo mínimo propio y no
`PublicFichaSecuencia`, para servir también al perfil de autor cuando llegue; la ficha se adapta a
él en `ficha-metric-adapter`. De la ficha salen:

| medida | de dónde |
|---|---|
| perfil por jornada, y la evolución de cada forma | `jornada_num` × `forma_slug` × `n_versos` |
| españolas contra italianas, global y por jornada | `tipo_forma` |
| desglose forma → arquitectura → dimensiones observadas | `arquitectura_nombre`, `esquemas_rima`, `rasgos`, `metros` y `variedades` |
| transiciones entre formas y patrones repetidos | la serie de secuencias en orden |
| largo de las tiradas: media, máxima, cuántas por forma | `n_versos` |
| cuántos cambios de cuadro parten una tirada | `cuadro_continua` |
| cantado y prosa: cuántos versos, en qué formas | `caracterizaciones_rango` |

**Cómo se muestra**, en bloques nuevos de la ficha, cada uno con su sección para que respete
`scope_minimo`:

- **Esquema métrico de un vistazo** —`MetricScheme.svelte`, **hecho el 9 de septiembre de 2026**—:
  una línea por secuencia con su rango, su forma y lo que la distingue de otra tirada de la misma
  forma. Con él **las asonancias se ven por primera vez**. Los cuadros van en la banda de la
  izquierda, que se explica más abajo. Falta colgarle el PNG.
- **Esquema de estructura** —`StructureOutline.svelte`, hecho el mismo día—: jornadas y sus
  cuadros, el mismo índice que el dashboard enseña en la pestaña de secuencias. **No vive en el
  esquema métrico**: cómo está partida la obra es un dato de la obra, no del verso, así que se abre
  en ventana desde la cabecera, y el botón son los propios recuentos —«3 jornadas · 11 cuadros»—,
  sin enlace aparte ni cabecera que crezca.

**Dos reglas de pantalla que se sacaron de ahí** —9 de septiembre de 2026—: en la ficha **solo la
cabecera va sobre blanco**, lo demás sobre el fondo de la página; y **todo lo que se abre en
ventana se cierra con Escape**, porque dos ventanas que se cierran distinto se sienten como dos
aplicaciones.

**El cuadro que empieza dentro de una tirada se dibuja donde cae** —resuelto el 9 de septiembre de
2026—. Pasa en el 31 % de los cambios de cuadro, y se resolvía de dos maneras distintas que
mentían igual: la sinopsis elegía entre `cuadro_divider` y `cuadro_carryover` según dónde hubiera
acabado la tarjeta anterior, y el esquema ponía la etiqueta sobre la fila siguiente. **El corte no
cae en el límite de una fila.**

Ahora hay una **banda a la izquierda** en las dos superficies, calculada por
`src/lib/metrica/banda-de-cuadros.ts` —puro, nueve pruebas—. La objeción que llevó al diseño
bueno: como cada fila mide lo que mide —una sinopsis larga ocupa el triple que una vacía—, no se
puede mapear verso a píxel. Y no hace falta: **fuera de la fila partida la banda solo dice qué
filas cubre cada cuadro, sin escala ninguna**, y la proporción se usa dentro de la fila que el
corte parte, como porcentaje de su propia altura. Lo resuelve el navegador sin medir nada.

Los dos avisos de la sinopsis se retiran, y con ellos el tipo `cuadro_divider`/`cuadro_carryover`:
solo quedan tarjetas. **Cómo se dibuja**, después de tres pasadas mirando la pantalla: el cuadro se
nombra con palabras —«Cuadro 3 · desde el v. 420»— porque un número diminuto pegado a la banda de
color no se leía; la etiqueta va **a la altura del corte** y no arriba de la fila, que la dejaba
dentro del cuadro anterior; la línea es **la misma en todo el recorrido del cuadro**, y lo que marca
el corte es un travesaño, no el tono; y salta el hueco entre tarjetas, o se leía partida.

**Y una regla de redacción**: nada de rótulos que expliquen lo que se está viendo. La frase «verso a
verso, como en una edición crítica…» sobraba encima del esquema.

**La pestaña Análisis está hecha** —9 de septiembre de 2026— con **tres gráficos que contestan tres
preguntas distintas**, que es la lección de la tarde: un solo gráfico de «evolución» acababa
diciendo lo mismo que los donuts de «De un vistazo», o sea composición.

- **`MetricFormStrips`** — *dónde cae cada forma*: una fila por forma con sus tiradas donde caen de
  verdad. Se llegó descartando un área apilada por ventanas, que parecía lo obvio: **dentro de una
  obra no hay ventana buena**. Ancha —150 versos, lo que hace falta para suavizar una tirada media
  de cien— esconde un soneto de catorce; estrecha, cada ventana contiene una secuencia y el área
  converge al código de barras. *El área por ventanas es el gráfico del **corpus por años**, donde
  cada punto es una obra entera y diluir un soneto es lo que se quiere medir: queda pendiente para
  el laboratorio, cuando haya obras reales datadas.*
- **`MetricSlopeChart`** — *cómo cambia una forma*: lo único que un apilado no puede, porque ahí el
  tramo se mueve arriba y abajo empujado por los de debajo. Guías finas cada cinco puntos —casi
  todas las formas quedan por debajo del veinte—, el cero dibujado **hueco** porque «no aparece» no
  es «aparece poquísimo», y el nombre resaltando al pasar por encima.
- **`MetricTraditionSplit`** — *de qué tradición es cada jornada*: columnas de dos partes. Una sola
  línea con la proporción italiana obligaba a rellenar mentalmente que el resto era español, y
  repetía el lenguaje de las pendientes. **Con dos categorías el apilado se lee perfectamente**: lo
  que no se puede seguir en un apilado es una banda intermedia entre muchas.

Y el reparto entre donut y apilado: **el donut para una sola composición** —la obra entera—, porque
tres donuts uno al lado de otro es lo que nadie sabe comparar.

El lenguaje gráfico fija además:

- **Lo horizontal se reserva para lo secuencial.** El código de barras recorre la obra verso a
  verso, así que una barra apilada en horizontal se lee como si también fuera un recorrido. La
  evolución es una acumulación de formas, sin orden que seguir: va **en columnas**.
- **Apiladas al cien por cien**, porque lo que se compara es de qué está hecha cada jornada y sus
  totales no son iguales: comparar alturas absolutas engañaría.
- **El mismo orden de formas en todas las barras**, el del reparto global. Si cada jornada ordenara
  por su propio peso, los tramos bailarían y no se podría seguir ninguno.
- **Un espacio de coordenadas ancho con escalado uniforme.** Dibujar en porcentaje obligaría a
  `preserveAspectRatio="none"`, que estira el texto junto con las barras. Y las etiquetas van dentro
  del SVG a propósito, para que viajen con él al exportarlo a PNG.

**Dos cosas más que salieron de mirarlo en pantalla, y que valen para cualquier gráfico que venga:**

- **Colocar etiquetas sin que se pisen tiene tres versiones y solo la tercera funciona.** Separarlas
  hacia abajo evita el solape pero la pila se sale por el suelo; subir la pila entera saca la de
  arriba por el techo —así desapareció la etiqueta de la redondilla, la que más pesa—. Lo que
  funciona son **dos pasadas**, una hacia abajo separando y otra hacia arriba desde la última, con
  tope en cada extremo.
- **Cada gráfico lleva una línea que dice qué pregunta contesta, no cómo está dibujado.** Describir
  el dibujo sobra cuando el dibujo está delante —esa es la regla de redacción de antes—, pero saber
  qué se está mirando no sobra para quien no viene del oficio. Ahí se explican también las
  convenciones propias: el círculo hueco, las líneas de jornada.

**Del paso 4 quedan dos cosas**, en este orden:

1. **La exportación en PNG**, con sus dos versiones —color con leyenda, y grises con trama y los
   nombres fuera en diagonal— y su pie con marca. Los dos avisos técnicos, arriba en este mismo
   plan: las variables CSS y la tipografía no sobreviven a `XMLSerializer`. Las etiquetas de los
   gráficos se pusieron **dentro del SVG** precisamente para esto.
2. **El detalle de una secuencia**, que **se rehace entero** y no se parchea: hoy es un cajón donde
   las cosas se fueron poniendo según llegaban. Lo que tiene que caber está unas líneas más abajo.

Y después, el **paso 5**: enseñar lo que ya llega y nadie pinta.
- **Evolución por jornadas**: barras apiladas con los colores de las formas, y encima la línea de
  españolas contra italianas.
- Los gráficos se dibujan con **`d3-scale` y SVG a mano, en componentes reutilizables**, como el
  código de barras: consumen tipos de presentación propios y no la ficha, para poder servir después
  al perfil de autor. `echarts` se queda donde ya está —el reparto de formas y el laboratorio— y no
  se extiende.
- **Desglose del perfil**: el reparto de formas se abre y enseña dentro sus arquitecturas y sus
  esquemas de rima con su porcentaje.
- **Patrones**: dicho en prosa —«el romance sigue a la redondilla siete de cada nueve veces»— con la
  matriz de transiciones al lado. Va **marcado como calculado**, y con las obras de prueba delante
  no significa nada: sirve para diseñar la pantalla, no para afirmar.

### Exportar los diagramas en PNG

Un utilitario compartido, porque lo van a usar todos los diagramas. Serializa el SVG, lo pinta en
un lienzo al doble o al triple de tamaño y lo descarga. Dos avisos que son la causa de que esto
salga mal casi siempre:

- **Las variables CSS y las clases de Tailwind no sobreviven a `XMLSerializer`.** Hay que resolver
  cada `fill` y cada `stroke` con `getComputedStyle` **antes** de serializar, o el PNG sale negro.
- **La tipografía tampoco viaja.** O se empotra en base64 o el texto del PNG se dibuja con una pila
  del sistema, que para un pie de imagen basta.

Cada exportación lleva **pie y marca**: título de la obra, «Versología · versologia.metadrama.org»,
el enlace permanente y la fecha de consulta, para que un diagrama suelto no pierda de dónde salió.

Y sale en **dos versiones**:

- **En color**, como en pantalla, con la leyenda de formas.
- **En escala de grises, para imprimir.** Doce formas no se distinguen por tono: llevan además
  **trama** —rayado, punteado—, y **los nombres van fuera, en diagonal ascendente**, unidos a su
  tramo por una línea de guía.

*El espacio del cuadro no se registra ni se va a pedir a los editores* —decidido el 9 de septiembre
de 2026—, así que el esquema de estructura es el de jornadas y cuadros, como el índice que ya
enseña la pestaña de secuencias del dashboard.

### Paso 5 · Enseñar lo que ya llega

Nada de esto necesita cálculo ni consulta: **el dato ya viaja en la ficha y no lo pinta nadie**.

- **Rasgos**: la asonancia de cada romance, la densidad de rima de la silva, el dístico final de una
  tirada de sueltos. Son 182 respuestas que no se ven en ninguna pantalla.
- **Desviaciones**: las lagunas, el verso hipométrico, la rima fuera del repertorio.
- **Metros** y **esquemas de rima con su reparto** —«abrazada 46, cruzada 8»—, que ya llegan
  contados por estrofa.
- **Las partes de la unidad**: 826 realizaciones —estancia, fronte, pie, sirima, mudanza,
  estribillo— que se escriben al anotar una canción o un villancico y no salen a ningún sitio.
- **Versos cantados y prosa**, hoy solo visibles al abrir una secuencia.
- **Espacios inaugurados**, **versos partidos** y en qué secuencias intervienen personajes
  femeninos, figuras de donaire o sobrenaturales.

*De «quién canta» se enseña lo que se sabe: la secuencia dice si interviene una mujer, un donaire o
un sobrenatural, no quién canta, y el modelo no se cambia por esto.*

### Dónde va cada cosa

La ficha tiene hoy cuatro pestañas —**Estructura métrica**, **Sinopsis**, **Observaciones**,
**Bibliografía métrica**— y la primera lleva el código de barras y el reparto de formas. Meterle
ahí diez bloques más la convierte en un rollo.

**Lo que se propone** es que las pestañas nombren *preguntas del lector* y no *tipos de dato*:

| pestaña | qué responde | qué lleva |
|---|---|---|
| **De un vistazo** | ¿qué obra es esta? | código de barras, reparto de formas, estructura de jornadas y cuadros, ficha técnica |
| **Esquema métrico** | ¿qué hay en cada verso? | la lista verso a verso como en una edición crítica, con su exportación |
| **Análisis** | ¿qué se puede decir de ella? | evolución por jornadas, españolas contra italianas, transiciones y patrones |
| **Sinopsis** | ¿de qué va? | lo que ya hay |
| **Observaciones** · **Bibliografía** | | lo que ya hay |

Las dos alternativas, por si se prefieren: **dejar cuatro pestañas** y apilar los bloques nuevos
dentro de «Estructura métrica», plegados; o **añadir solo «Análisis»** y meter los dos esquemas
—métrico y de estructura— donde hoy está el código de barras.

**Las pestañas van así** —decidido el 9 de septiembre de 2026—, con las preguntas por nombre.

**El detalle de una secuencia se rehace entero**, no se le añaden bloques: hoy es un cajón donde
las cosas se fueron poniendo según llegaban, y con los rasgos, las desviaciones, el reparto de
esquemas y las partes de la unidad encima no hay dónde meterlas. Lo que tiene que caber:

- *Datos base*, con el **metro** y el **reparto de esquemas de rima**.
- **Lo observado**: los rasgos y las desviaciones. Es lo que el editor anotó mirando el texto y no
  lo que la forma prescribe, y por eso va junto y aparte.
- **Las partes**, solo cuando la secuencia las tiene —canción, villancico, sextina, terceto
  encadenado—: una lista anidada con sus rangos.
- Lo que ya está: caracterizaciones por rango, personajes, sinopsis y aclaraciones públicas.

### Inventario vivo de la ficha pública

Este inventario se mantiene **aquí**, no en una nota de sesión separada. Al cerrar, aplazar o
reordenar un punto hay que actualizar su estado y el punto de continuación, para que el contexto
vuelva a ser suficiente por sí solo. Se usa el prefijo `FP-` para no confundirlo con las incidencias
`F1`, `F2`… del formulario métrico que aparecen antes en este documento.

**Estado consolidado el 9 de septiembre de 2026.** **FP-F1, FP-F3, FP-S1–FP-S6, FP-D1, FP-D3,
FP-G1, FP-G2, FP-G4–FP-G10, FP-U2 y FP-U3 están corregidos**. El núcleo del detalle de secuencia y
el bloque de análisis de obra están terminados. **FP-S7 no se implementa mientras no haya un caso real de
inaplicabilidad**: los atajos de obra `sin_figuras_donaire`, `sin_personajes_sobrenaturales` y
`sin_eventos_sobrenaturales` escriben «No» en todas sus secuencias, no convierten la pregunta en
«No se aplica»; y las dimensiones métricas ajenas a una forma sencillamente no se muestran. **FP-F2**
se mantiene para el final porque los comentarios fuera de secuencia no son urgentes. **FP-G3 queda
aplazado** hasta acordar qué constituye un patrón repetido y poder contrastarlo con un corpus
publicado suficiente. El siguiente punto de decisión es el orden entre **FP-U1, FP-U4 y FP-U5**.
Las descargas siguen aparcadas.

**Correcciones de datos ya recibidos**

| código | pendiente | estado |
|---|---|---|
| **FP-F1** | El contrato entregaba los esquemas con nombres heredados y el detalle de secuencia esperaba un id y rangos antiguos. Debe decir «Esquemas de rima» y mostrar qué realización concreta se está contando. | **hecho**: contrato tipado con el dominio actual; cada respuesta conserva realización y sección, y el detalle recompone y nombra sonetos, estancias, mudanzas, tiradas u otras unidades reales |
| **FP-F2** | La página solo pinta comentarios con `secuencia_id`; quedan fuera los generales y los ligados a jornada o cuadro. | **para el final** |
| **FP-F3** | El perfil no es forma → «tipos de estrofa». Debe respetar forma → arquitectura → comportamiento observado de esa arquitectura: tipologías, esquemas, variedades, metros, rasgos u otras dimensiones solo cuando correspondan. En romance, «Octosilábica» es la arquitectura y las vocales de la asonancia son un rasgo suyo. En soneto, la base y el JSON deben conservar por separado las respuestas de Cuartetos y Tercetos, enlazadas con su realización y orden, para que la ficha pueda reconstruir al mostrar `ABBA ABBA CDC DCD` o `ABBA ABBA CDE CDE`. | **hecho**: el JSON conserva las respuestas descompuestas con realización, sección y orden; el perfil y el detalle las recomponen solo para presentarlas. La agrupación sigue el alcance del catálogo: una estancia repetida se cuenta como estancia; las secciones que referencian otra arquitectura se recomponen en su unidad raíz, como las dos quintillas de la copla real |

**Dentro del detalle de cada secuencia**

| código | pendiente |
|---|---|
| **FP-S1** | **Hecho**: muestra el metro o los metros y los versos que cubre realmente cada uno. |
| **FP-S2** | **Hecho**: muestra el reparto de esquemas reconstruido en la escala real de la forma. |
| **FP-S3** | **Hecho**: muestra los rasgos observados agrupados por dimensión. |
| **FP-S4** | **Hecho**: muestra las desviaciones con dimensión, relación con la norma, rango y observaciones. |
| **FP-S5** | **Hecho**: el detalle se ha sustituido entero por una lectura vertical con cabecera identificativa, construcción métrica, lo observado, contexto dramático, sinopsis y aclaraciones; los bloques sin contenido no se crean y el pie permite navegar entre secuencias. La pasada responsive del 9 de septiembre porta el modal al `body`, cubre todo el viewport, limita la lectura de escritorio a 56 rem y jerarquiza la forma como título principal con la arquitectura subordinada en tamaño y tono. El contexto no repite jornada/cuadro: separa `Intervenciones` —donde exclusiva/compartida califican la intervención de cada tipo de personaje— de `Otras caracterizaciones`, con rótulos explicativos para versos partidos, cambio de espacio y evento sobrenatural. |
| **FP-S6** | **Hecho**: canto, prosa y evocación métrica se separan bajo `Enunciación`, con nombres legibles, rango y observaciones. La auditoría inicial era falsa porque buscó los slugs `cantado` y `prosa`, pero la ficha pública entrega las etiquetas `Cantado` y `Prosa`. El 9 de septiembre se contrastaron tabla viva, `ficha_publica_json(...)` y `obras_resumen.ficha`: coinciden los seis rangos de las cuatro obras de prueba publicadas. Se revisaron manualmente los dos casos de *Lo fingido y lo cierto* y los de *El marqués desdichado*, *La monja de Ávila* y *Las batuecas del duque*. |
| **FP-S7** | **No se implementa por ahora**: el modal distingue `Sin dato` de `No`, pero no hay un caso demostrado que signifique `No se aplica`. Los atajos negativos de la obra rellenan respuestas negativas y no expresan inaplicabilidad. Reabrir solo si aparece un dato cuyo dominio distinga realmente esos tres estados. |

**Fuera de las secuencias: datos disponibles o calculables**

| código | pendiente |
|---|---|
| **FP-G1** | **Hecho**: `De un vistazo` muestra formas distintas, longitud media, secuencia más larga con rango y las formas de apertura y cierre. No repite versos, jornadas, cuadros ni secuencias, que ya están en la cabecera; los índices de versos partidos, espacios y desviaciones pasan a FP-G8/U2. |
| **FP-G2** | **Hecho**: `Análisis` presenta las transiciones entre secuencias consecutivas como pares legibles y ordenados por frecuencia. Las seis principales quedan a la vista, el resto se despliega y se aclara que el cálculo incluye los pasos entre jornadas. No se usa una red que dificulte la lectura. |
| **FP-G3** | **Aplazado**: no se detectan patrones hasta decidir una definición y un umbral defendibles. Conviene abordarlo con la futura comparación de corpus, no producir ahora una lista arbitraria a partir de una sola obra. |
| **FP-G4** | **Hecho**: `Análisis` incluye una tabla por forma con secuencias, versos, longitud media y extremos mínimo–máximo, usando la misma clave de color que los gráficos. |
| **FP-G5** | **Hecho**: `Análisis` cuenta los límites reales entre cuadros dentro de cada jornada y los divide en dos agregados comparables: los que coinciden con un cambio de secuencia y los que parten una secuencia. Al desplegarlos permite localizar las secuencias, agrupa por forma y ordena por número de cortes, y señala únicamente la excepción en que cambia la secuencia pero continúa la misma forma. Los cortes de jornada quedan fuera. El listado por formas reutiliza el componente de `Localizar en la obra`; ninguno muestra sumas de versos, porque la extensión no es la variable contada. |
| **FP-G6** | **Hecho**: `Análisis` resume canto, prosa y evocación métrica con versos, porcentaje de la obra y formas en que aparecen. Las etiquetas públicas se normalizan y los rangos solapados no duplican versos; el bloque no se crea cuando la obra no contiene ninguno. |
| **FP-G7** | **Hecho**: el bloque de articulación muestra con qué forma abre y cierra cada jornada, junto a la lectura de los cambios de cuadro. |
| **FP-G8** | **Hecho junto con FP-U2**: `Análisis` incorpora un único índice `Localizar en la obra`. Ocho fenómenos —canto, prosa, evocación, desviaciones, versos partidos, cambios de espacio, intervención de personajes y eventos sobrenaturales—, con los tres tipos de personaje reunidos en un solo grupo, como en el editor. **Cada fenómeno se agrupa por forma**, ordenadas por número de secuencias, y las secuencias concretas quedan replegadas dentro de cada forma: la pregunta que contesta el índice es en qué formas aparece más, no cuáles son las secuencias. Al elegir un fenómeno aparecen todas sus respuestas como acordeones cerrados, mostrando solo etiqueta y contador. Un icono de confirmación identifica las positivas (`Sí`, `Exclusiva`, `Compartida`) y uno de ausencia las negativas (`No`, `Sin intervención`), sin usar claro/oscuro como código semántico. El chip resume las respuestas cuando hay una sola pregunta; los tres tipos de intervención se anuncian como tales. También se declara cuántas secuencias siguen sin anotar. Canto, prosa y evocación conservan el rango específico. Cuando la obra declara que no tiene figuras de donaire, personajes sobrenaturales o eventos sobrenaturales, la rama lo dice una vez en lugar de listar las secuencias que el disparador respondió por ella: las tres marcas viajan en la ficha desde el 10 de septiembre de 2026. |
| **FP-G9** | **Hecho**: la fuente se ofrece bajo la datación mediante un control discreto y accesible. Al abrirlo conserva cursivas, listas y referencias separadas; no vuelca en la cabecera campos que en las obras reales pueden contener varias citas bibliográficas extensas. La auditoría del 9 de septiembre comprobó el formato contra la tabla viva antes de diseñarlo. |
| **FP-G10** | **Hecho**: el correo de la cuenta del editor no se muestra y se retira también del JSON público y de las fichas precomputadas. Nombre público y ORCID bastan para firmar la ficha; un futuro contacto directo requerirá un campo propio y consentimiento expreso. |

**Comparación futura con el corpus.** Transiciones, patrones y las demás medidas analíticas pueden
poder añadir, cuando haya un corpus publicado suficiente, una referencia del tipo «en esta obra
ocurre X; ocurre también en el Y % del corpus analizado». La ficha comparará la obra con el corpus
sin convertirse en el laboratorio: mostrará una referencia breve, nombrará el universo y la fecha
del cálculo, y dejará la exploración transversal para la herramienta específica. El banco de
trabajo V2 ya se calcula y es privado; la proyección pública por obra todavía no existe. Las obras de
prueba validan la maquinaria, no se usan como si fueran un corpus histórico.

**Revisión de organización y lenguaje solicitada el 10 de septiembre de 2026.** Se hará en cambios
pequeños y reversibles, uno por uno; esta nota no implica que estén implementados:

- **hecho**: mover `Localizar en la obra` de `Esquema métrico` a `Análisis` —cierra esa pestaña, por
  ser lo único que no contesta una pregunta sino que lleva a un sitio—, de modo que el esquema
  contiene solo el esquema;
- **hecho**: mover el número de secuencias métricas desde `Estructura` en la cabecera hasta
  `Resumen métrico`. La estructura son jornadas y cuadros —cómo está partida la obra—; en cuántas
  secuencias está versificada es un dato del verso, y junto a la longitud media y los extremos se
  lee;
- **hecho**: auditar `tirada` en toda la ficha. La entidad general es **secuencia métrica**; `tirada` se reserva
  para series estróficas o formas repetidas cuando el término describe de verdad su realización.
  Un soneto puede ocupar una secuencia, pero no es una tirada;
- **hecho**: completar el resumen con la **secuencia más corta**, además de media y máxima. Dice
  tanto como la más larga: un verso suelto o un soneto entre tiradas de cien versos es justo lo que
  la media esconde. De paso, una secuencia de un solo verso se nombra en singular —«v. 234 · 1 v.»—;
- **hecho**: retirar los rótulos auxiliares `Calculado` y `Calculado a partir de las secuencias`;
- añadir una lectura de la evolución por cuadros y jornadas: si las secuencias tienden a hacerse más
  largas o cortas y si aumenta o disminuye la concentración/diversidad de formas. Antes de crear
  otro cálculo, reutilizar y contrastar `numero_efectivo_formas` y `densidad_transiciones`, que ya
  alimentan `/obras`, y decidir qué significa cada medida dentro de una sola obra.

**Punto de continuación inmediato:** de esa revisión queda **solo la lectura de la evolución** por
cuadros y jornadas, y no es un cambio de sitio sino una decisión: antes de crear otro cálculo hay
que acordar qué significan `numero_efectivo_formas` y `densidad_transiciones` **dentro de una sola
obra** —hoy alimentan `/obras`, donde comparan obras entre sí— y si «se concentra» o «se
diversifica» a lo largo de una obra es afirmable con lo que se mide.

**Corrección de `tirada` —implementada el 10 de septiembre.** La ficha usaba el término como
sinónimo general de la fila `secuencias_metricas`, y por eso alcanzaba indebidamente a sonetos y
otras formas no seriadas. La corrección aplicada es:

- cambiar a **secuencia** el resumen —media, máxima y futura mínima—, la tabla por forma y sus
  recuentos, y la articulación con los cuadros (`cortan una secuencia`, `entre secuencias de la misma
  forma`);
- acompañar ese cambio en nombres internos hoy genéricos: `tiradaMasLarga`, `tiradasPorForma`, los
  recuentos `tiradas`, las franjas de posición y `partenTirada`/`entreTiradasMismaForma`;
- en el desglose de rasgos y esquemas, dejar de usar `tirada` como unidad de reserva cuando no llega
  una realización: la reserva segura es `secuencia`;
- **mantener tirada** cuando el texto nombra expresamente una serie métrica real —por ejemplo, una
  tirada de romance, redondillas, quintillas o versos sueltos— y cuando el catálogo/realización
  garantiza que esa es la unidad contada. No se sustituye mecánicamente en la documentación
  histórica ni en explicaciones donde tiene ese sentido específico;
- `cuadro_continua` puede conservar su nombre de contrato, que ya es neutral; deben corregirse los
  comentarios y rótulos que interpretan automáticamente la secuencia como tirada.

Las pruebas dirigidas del análisis de ficha y de la distribución métrica cubren el vocabulario y
los recuentos resultantes. Los usos específicos —por ejemplo, `tirada de redondillas`, `tirada de
quintillas` o `tirada de décimas`— se conservan.

**Recálculo público por elementos —implementado el 10 de septiembre de 2026.** El antiguo botón de
`/dashboard/publicacion` llamaba una sola vez a `recompute_all()`. Bajo el límite de ocho segundos
del rol `authenticated`, la función recorría las doce obras y los autores en una única transacción:
el timeout cancelaba todo y no quedaba ninguna actualización parcial. Ahora el navegador prepara un
plan y llama secuencialmente a `obra`, `autor` y `finalize`; cada llamada confirma una obra o un
autor por separado. Muestra `Obras x/y · Autores x/y`, continúa tras los fallos y permite
**Reintentar fallidos** sin repetir los elementos correctos. Recargar o cerrar detiene la cola, pero
lo ya confirmado permanece guardado; una ejecución nueva construye otro plan completo.

- `plan_recompute_datos_publicos()` devuelve solo las obras que siguen publicadas y los autores con
  unidades métricas; `finalizar_recompute_datos_publicos()` limpia lo que ha salido del corpus y
  reconstruye índices y comparativas. Las funciones y el endpoint comprueban admin/IP en cada paso
  y que una obra no haya dejado de estar publicada antes de recalcularla.
- La cola usa `recompute_obra_artefactos_global` y `recompute_autor_artefactos_global`: primero
  actualiza el resumen intermedio y los JSON de cada obra, después agrega los autores desde esos
  JSON compactos y al final publica los artefactos globales. Así no reconstruye al mismo autor
  varias veces ni vuelve desde su ficha a todas las tablas de anotación. `recompute_all()` conserva
  el mismo grafo para SQL y migraciones, con el permiso revocado a `authenticated` y retenido por
  `service_role`.
- Cambiar datos fuente marca `metrica_sucia` y los artefactos afectados como `sucio = true`, pero no
  borra su payload: la web sirve la última versión coherente mientras la cola construye la nueva.
  El endpoint de asignaciones devuelve `datosPublicosPendientes` y el dashboard muestra
  inmediatamente «Hay cambios sin publicar». Un cambio del nombre público o del ORCID de un editor
  sigue invalidando sus fichas. El botón individual «Actualizar datos públicos» es la publicación
  explícita de la nueva versión.
- Migraciones aplicadas: `20260910100000_invalidar_ficha_por_identidad_editorial.sql`,
  `20260910110000_cola_recompute_datos_publicos.sql` y
  `20260912100000_los_datos_publicos_son_artefactos_json.sql`. Commits anteriores: `fd786c1`,
  `3c6638c` y `d1fef26`.
  Falta solo la verificación manual autenticada:
  cambiar un editor en una obra publicada, confirmar el aviso pendiente, pulsar la actualización
  individual y comprobar en la ficha pública el nuevo nombre y ORCID.

**Edición inline de estructura —implementada el 10 de septiembre de 2026.** En el dashboard de una
obra, jornadas y cuadros se editan y se crean en el propio listado: una sola fila activa a la vez,
con `Guardar` y `Cancelar`; `Escape` cancela y `Enter` guarda los campos numéricos. Se reutilizan
sin cambios las validaciones y las mutaciones de estructura ya existentes. Los comentarios internos
de un cuadro guardado se abren en una segunda línea amplia bajo su fila. El panel lateral se retiró
por completo de esta pantalla. Se comprobó en *Demo obra* la edición consecutiva de jornadas y
cuadros, las cancelaciones, las altas inline y la persistencia tras recargar; los valores de prueba
se guardaron sin modificarlos.

**Datos que aún no llegan al JSON público**

| código | pendiente |
|---|---|
| **FP-D1** | **Hecho**: la precomputación y los tipos conservan realización, sección, orden y rangos; el detalle reconstruye y presenta las partes materiales disponibles —por ejemplo, estancias, mudanzas y otras secciones— sin inventar rangos para divisiones tratadas solo por el catálogo. |
| **FP-D2** | «Quién canta» no está modelado. No se considera un fallo actual: solo se abrirá si se decide un proyecto de datos específico. |
| **FP-D3** | **Hecho**: se retiraron del contrato público los nombres heredados del modelo anterior y ahora el JSON, los tipos, el informe y la interfaz usan forma, arquitectura y esquemas de rima. La migración está aplicada, las fichas publicadas están regeneradas y el almacenamiento interno legado queda fuera de este cambio. |

**Normalización pendiente del catálogo**

| código | pendiente |
|---|---|
| **FP-C1** | **Los nombres, hechos el 10 de septiembre de 2026** (`20260910120000`). Se auditaron las 95 arquitecturas activas contra la base viva y se corrigieron **58**. El nombre no se lee nunca solo —la ficha, el catálogo y el editor lo pintan junto al de su forma—, y estaba escrito para concordar con la palabra «arquitectura», que no sale en ninguna pantalla. Se arreglan dos cosas de una vez: **la denominación tradicional**, `-sílabo`/`-sílaba` en lugar de `-silábico` («romance octosílabo», «redondilla octosílaba»), y **la concordancia** con la forma, que alcanza también a `Heterométrico consonante` bajo las tres liras masculinas, a `Alejandrino` del sexteto y a `Compuesto` del septeto. `endecasilabo_suelto/endecasilabica` solo se concuerda: «Sin rima» sería falso, porque un pasaje de sueltos admite rimas esporádicas y puede organizarse en pareados, y cómo nombrar la única arquitectura de una forma que ya lo dice todo queda por decidir. **Los slugs siguen pendientes**: viajan en `obras_resumen.perfil_formas_hijos`, en el JSON de la ficha y en las URLs del catálogo, así que renombrarlos pide un día tranquilo, con recompute y repaso de enlaces. Ese día hay dos desajustes que arreglar, que esta migración deja a la vista: `terceto/endecasilabica_consonante` se llama «Endecasílabo», y los slugs dicen `octosilabica` mientras el nombre dice «Octosílabo». |

**Mejoras de interacción y lectura**

| código | pendiente |
|---|---|
| **FP-U1** | Conectar los gráficos de análisis con el filtro o la apertura de las secuencias correspondientes. |
| **FP-U2** | **Hecho con FP-G8**: el índice navegable de fenómenos vive una sola vez, encima del esquema métrico, y no despliega de entrada listas potencialmente largas. |
| **FP-U3** | **Hecho**: cada cifra explica qué cuenta. Formas y arquitecturas usan versos; los rasgos dicen, por ejemplo, `340 vv. en 4 secuencias`; los esquemas y variedades nombran su alcance real (`sonetos`, `estancias`, `mudanzas`, `tiradas`…); los metros cuentan solo los versos efectivamente cubiertos por sus respuestas, no el total de la secuencia. |
| **FP-U4** | Revisar los estados vacíos y la cobertura parcial de métrica, jornadas, sinopsis y anotaciones. |
| **FP-U5** | **Parcial**: ya tiene foco inicial, cierre con `Escape`, restauración del foco, navegación con botones y flechas, cierre de 40 × 40 px con la X centrada y estados perceptibles de hover/activo/foco, disposición de pantalla completa en móvil y revisión visual de escritorio del overlay y los márgenes. Falta la comprobación visual final en móvil y decidir si se añade confinamiento completo del foco. |

**Aparcado:** **FP-P1**, descarga PNG en color, está empezada pero no validada; **FP-P2**, versión
en blanco y negro para impresión, queda para otro día. Ninguna de las dos forma parte del siguiente
punto de continuación.
