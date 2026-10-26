# Integración del corpus mínimo: base compartida, métrica separada

Diseño iniciado el 22 y revisado el 26 de octubre de 2026. Recoge las decisiones de la conversación y el
contraste con el esquema vivo. **No es una migración ni describe funciones ya implementadas.**
Los nombres nuevos de tablas y campos son orientativos; el piloto sigue en archivos locales.
La propuesta de [campos mínimos y conexiones](./campos-minimos.md) concreta este diseño:
obligatoriedad, referencias, detalles opcionales y revisión editorial con estructura reutilizable.

## Decisiones que delimitan el diseño

Se reutilizan `obras`, `jornadas` y `secuencias_metricas`. La **anotación métrica mínima se guarda
en una tabla aparte**: no se fuerza dentro de `anotaciones_metricas` ni se rebajan las exigencias
del registrador v2. Comparte el catálogo de formas y, cuando se conoce, de arquitecturas, pero no
la obligación de responder una anotación detallada. Esta separación es una decisión del proyecto,
no una alternativa pendiente de volver a escoger.

Las fichas mínimas no se publican individualmente. Sus datos sí pueden alimentar el perfil de un
autor, el laboratorio y **resultados agregados seleccionados para contrastar una ficha completa**
con ese corpus. La separación de acceso no implica excluirlas del referente público agregado.
Se declara qué corpus interviene, su cobertura y sus limitaciones, sin entregar sus fichas ni la
matriz por obra. La selección concreta de comparaciones publicables requiere evaluación posterior.

Cuatro obras permiten iniciar las correspondencias, no cerrar todo el vocabulario. El repertorio
se amplía con las veinte del piloto y después con cada lote. Un término nuevo o ambiguo se conserva
como pendiente; no bloquea por sí mismo la importación ni se identifica por conjetura. La cobertura
por dimensión determina los usos posibles. No se exige resolver todos los términos antes de diseñar
el almacenamiento.

## Qué se comprobó en la base

La [evidencia del esquema](./piloto/auditoria-esquema-2026-10-22.json) procede de un
[SELECT reproducible](../../scripts/importador-metrico/auditar-encaje.sql). Incluye columnas,
restricciones, disparadores, políticas y cuerpos de funciones. No ejecuta guardados ni
recomputaciones; inspeccionar su definición no constituye una prueba de ejecución.

| Comprobación | Consecuencia para el importador |
| --- | --- |
| `secuencias_metricas` exige identidad de obra y rango/extensión; sus caracterizaciones y sinopsis admiten `null` | Se puede reutilizar la estructura sin inventar personajes, sinopsis ni cuadros. Las exigencias del formulario completo se mantienen en su recorrido |
| `anotaciones_metricas.forma_id` es obligatorio; `validar_anotacion_metrica` exige arquitectura para las formas ordinarias, aunque la columna admita `null` | No permite guardar Canción solo al nivel de forma ni una identificación pendiente. Se mantiene v2 y se crea la representación mínima aparte |
| Las secciones de `anotacion_realizaciones` dependen de arquitectura, unidad padre y rangos | Saber que existe un remate no autoriza a fabricar una realización detallada |
| `guardar_anotacion_metrica` valida respuestas y sustituye sus datos hijos | El importador mínimo necesita un guardado propio, sin pasar por esta función |
| `formas_de_la_obra` lee las anotaciones v2; el corpus comparativo se construye desde índices de obras publicadas | Hace falta una lectura analítica común y un universo explícito que incluya mínimas confirmadas |
| El agregado actual rellena con cero perfiles de formas y transiciones ausentes | No se le pueden añadir fichas mínimas sin adaptar antes el tratamiento de lo desconocido |
| Hay una política permisiva `obras_authenticated_select` con condición `true` | Ocultar filas en el dashboard no basta para establecer nuevos permisos de consulta |
| `artefactos_publicos` limita tipos y alcances; sus políticas distinguen el banco privado de las salidas públicas | Los nuevos análisis y agregados necesitan contratos y permisos explícitos; no basta con inventar una clave de JSON |

El código también requiere adaptación: creación de obras, checklist, editor de secuencias,
perfiles, distancias y carga del laboratorio. Por ejemplo, el checklist actual comprueba la
existencia de anotación v2; una mínima no debe satisfacer esa revisión. La creación habitual
exige editor asignado, mientras que importar y asignar después son operaciones diferentes.

La [consulta del 26 de octubre](../../scripts/importador-metrico/auditar-flujo-minimo.sql) y su
[evidencia](./piloto/auditoria-flujo-2026-10-26.json) confirman que fuentes de datación y autoría
pueden quedar vacías. La revisión del diseño descarta añadir un estado Mínima validada: Mínima
será un tipo de ficha y la confirmación de la importación habilitará su aporte al corpus.

## Persistencia propuesta

La separación es entre **dos representaciones métricas con distinta profundidad**, dentro de una
misma identidad de obra. No se crea otra tabla de obras ni otra colección paralela de secuencias.

| Componente | Función propuesta |
| --- | --- |
| `obras` | Añadir una distinción mínima/completa independiente de `estado`, asignación y visibilidad. Completa significa recorrido editorial detallado, no que un borrador esté terminado |
| `jornadas`, `secuencias_metricas` | Rangos comunes. Cambio de forma A → B → A produce tres secuencias. Sinopsis y caracterizaciones no estudiadas permanecen desconocidas |
| Nueva `secuencias_metrica_minima` | Una anotación mínima vigente por secuencia, con forma identificada opcional, arquitectura opcional, estado de identificación, revisión y procedencia. Arquitectura conocida debe pertenecer a la forma; pendiente no es una nueva forma del catálogo |
| Candidatas y detalles mínimos | Información dependiente de la anotación mínima: alternativas con alcance exhaustivo u orientativo; metros, rima, remates o desviaciones solo cuando la fuente los sostenga. No son filas de `anotacion_elecciones` ni de `anotacion_realizaciones` |
| Registro de importación y evidencia | Original, fuente, versiones y transformaciones. Incluye una copia fija de los datos mínimos confirmados, con su estructura, para que la edición posterior no altere el referente |
| Confirmación de la importación | La persona autorizada comprueba y confirma la entrada, sin una segunda aprobación editorial. Solo una importación confirmada por obra aporta al corpus hasta que la sustituya la completa publicada |

El SQL concreto debe fijar los campos y los detalles que merecen tablas hijas tipadas. No se plantea
resolverlo con texto libre usado como hechos ni replicando las preguntas obligatorias de v2.
Las referencias al catálogo tendrán integridad; una lista de candidatas no se copiará como forma
confirmada. No se necesitan probabilidades inventadas para almacenar ambigüedad.

Los datos de fuente aceptados se conservan aunque cambie una correspondencia. Una regla nueva
produce una nueva interpretación revisable; no cambia silenciosamente todas las obras ya aceptadas.
La procedencia debe admitir una fila editorial dividida en tres secuencias y también filas que
terminen representando una misma secuencia, sin perder la declaración original.

Las fechas son obligatorias para el corpus cronológico; su fuente es opcional y puede ser la
edición base si así se registra. El género es obligatorio, con Comedia preseleccionada para este
lote. Se registra autor, sin exigir fundamentos de autoría en la mínima: se priorizan obras no
discutidas. No se revisan ahora las atribuciones existentes. La edición base es obligatoria y se
registra quién confirma la importación, independientemente de su futura asignación editorial.
Una obra no se duplica por reimportarla o por trabajar después con otra edición.

## Casos que debe expresar la tabla mínima

| Declaración revisada | Qué se guarda y qué permite |
| --- | --- |
| Estancias con pareado final | Forma Canción, sin arquitectura, con remate en pareado declarado. No se inventan patrón de estancias, respuestas internas ni unidades v2. Puede aportar al perfil de formas |
| Tercetos sin otra precisión | Literal y candidatas conservados; no se decide terceto/terceto encadenado mirando un pasaje aislado. Sus versos permanecen en el denominador |
| Letrilla | Denominación y posibilidades orientativas. No se afirma una forma concreta, canto ni una lista cerrada de alternativas |
| Redondillas de Los locos con verso añadido | Rango real de 133 versos y desviación estructural `sobra` en v. 2666. Se conservan los 133 versos del pasaje; la comprobación normativa considera 132. No se crea laguna ni nueva secuencia por ese verso |
| Heptasílabo dentro de los sueltos de Los locos | Desviación de metro en v. 2172, sin cambio de forma ni partición automática. La opinión editorial de posible descuido se conserva como tal |

El remate ya pertenece conceptualmente al modelo de Canción; no hay que crear otra forma.
La representación mínima conserva esa información sin exigir las coordenadas y estructura que
necesita una realización v2. Conocer una ocurrencia tampoco demuestra que se hayan anotado todas.
Para las faltas no se vuelve a sumar una laguna si sus posiciones ya están incluidas en el rango:
las reglas de cómputo deben distinguir numeración del pasaje y extensión normativa.

## Una capa común para calcular, sin mezclar las anotaciones

Se propone una proyección analítica que traduzca cada fuente a un contrato compartido: obra,
secuencia, rango, forma confirmada o desconocida, profundidad, evidencia y cobertura por dimensión.
Los adaptadores de mínima y v2 alimentan ese contrato; los cálculos comunes se definen una sola vez.
La proyección no completa datos ni transforma la mínima en anotación detallada.
En términos de funcionamiento, el código sabe leer formas y rangos desde una u otra tabla para
calcular medidas equivalentes. No implica validar la segmentación importada: el editor elige entre
conservarla para corregirla o vaciarla, y revisa en todos los casos las propuestas métricas.

No se cambia indiscriminadamente `formas_de_la_obra` para que cualquier lector público empiece
a recibir datos mínimos. Se inventarían permisos y semánticas que sus consumidores no contemplan.
Primero se establece el contrato y se adaptan deliberadamente sus lectores.

| Uso | Tratamiento de la mínima |
| --- | --- |
| Extensión y jornadas | Utilizables con rangos revisados y cobertura estructural declarada |
| Perfil de formas y cronologías | Formas confirmadas sobre el total de versos, con parte pendiente e incertidumbre de las fechas explícitas |
| Transiciones y segmentación | Solo límites interpretables. A–desconocido–B no se convierte en A–B. Si las etiquetas no permiten decidir cambios de forma, tampoco se da por exacto el número de secuencias métricas |
| Arquitecturas, metros, rima y remates | Solo dimensiones y ocurrencias documentadas, con su propia cobertura. Falta de detalle no equivale a conformidad o ausencia |
| Cuadros, personajes y caracterizaciones | No disponibles por defecto. No aportar ceros a comparaciones de estos fenómenos |
| Afinidad de una completa con el autor | Referente con mínimas y completas elegibles, misma definición de medida, incertidumbre visible y evaluación de estabilidad antes de redactar conclusiones |

No se renormalizan los versos identificados como si cubrieran el 100 % de la obra. Si se ofrece
una lectura condicionada a esa parte, se nombra así. La ausencia solo puede computarse como cero
cuando los datos permiten descartarla; lo pendiente puede exigir límites o escenarios. Una lista
orientativa de candidatas no restringe esos límites como una lista exhaustiva.

No se fija ahora una tolerancia universal ni se presenta cobertura como probabilidad de acierto.
Los experimentos del piloto medirán estabilidad por pregunta, incluyendo pérdidas concentradas
en una denominación o periodo. Cuatro obras permiten ensayar el procedimiento; no calibran por sí
solas la utilidad de todo el corpus de Lope.

## Acceso individual, laboratorio y resultados difundibles

Son tres salidas distintas del mismo flujo de datos:

1. **Datos y fichas individuales:** las mínimas siguen fuera de la publicación. Admin/IP y editores
   con permiso individual de importación podrán consultar todas las mínimas, indicando quién importó
   cada una. Se propone una pestaña Fichas mínimas en Obras. Consultarlas no abre el laboratorio ni
   concede por sí solo edición de fichas ajenas. El editor de la completa podrá consultar su origen.
   Los permisos se aplican en servidor y RLS; no basta con ocultar botones.
2. **Exploración y cálculo del referente:** el laboratorio autorizado puede seleccionar el corpus
   ampliado de mínimas confirmadas y completas elegibles, por autoría, fechas y cobertura. Se mantiene
   la opción de estudiar solo completas; incorporar mínimas no impone usarlas en todas las medidas.
3. **Comparación en una ficha completa:** una proyección seleccionada puede usar ese referente
   ampliado y mostrar resultados globales con número de obras, composición mínima/completa,
   cobertura, fechas y versión del cálculo. No descarga títulos, secuencias ni fichas mínimas.

Por tanto, el universo estadístico puede ser más amplio que el catálogo de fichas públicas.
La ficha debe poder decir que se compara con un corpus métrico que incluye fichas mínimas de
ediciones críticas. No debe llamarlo simplemente «corpus publicado» si no lo es.

La propuesta metodológica de excluir la propia obra y sus versiones del referente sigue pendiente
de concretar junto con la ponderación por obras o versos, las fechas amplias y los requisitos de
muestra/estabilidad. Son decisiones del cálculo; no cuestionan la posibilidad acordada de utilizar
el corpus mínimo en resultados agregados difundibles.

Los artefactos internos y la proyección pública necesitan contratos separados y versionados.
Se puede estudiar reutilizar el almacén materializado existente, pero sus restricciones y políticas
deben adaptarse antes: añadir un tipo nuevo sin revisar las políticas actuales no garantiza que
sea privado. Las mínimas no se marcan como publicadas para entrar en un cálculo.

## Asignación y nuevo análisis completo

La obra conserva su identidad al asignarse. El editor puede mantener jornadas y secuencias para
corregirlas o vaciar la estructura y empezar de nuevo. Puede cambiar la edición y sus metadatos.
Al abrir una secuencia se presenta la propuesta del importador como referencia, sin convertirla
en respuestas v2 ni darla por correcta. Los cambios de rango o edición no autorizan correspondencias
automáticas con el tramo anterior.

Está confirmado que el corpus conserva el aporte mínimo hasta publicar la completa.
Para ello se propone `importaciones_metricas.datos_confirmados` (JSONB), una copia fija de la estructura, métrica y
metadatos aceptados. Es independiente de las secuencias editables y permite vaciarlas sin alterar
el referente. Solo una importación confirmada por obra puede estar marcada `usada_en_corpus`.
No se necesita un selector de versiones métricas generales en `obras`.

Al publicarse la completa, v2 sustituye ese aporte y se actualizan los agregados, contando una vez
la obra. La copia mínima puede conservarse como documento histórico sin seguir aportando al corpus.
No se sobrescribe trabajo completo mediante una reimportación; tampoco se mezclan la métrica de
la edición importada y los metadatos del nuevo borrador.

## Orden de integración y verificación

La secuencia de trabajo se desarrolla en la [hoja de ruta](./hoja-de-ruta.md), sin otra lista de
pendientes. El diseño de almacenamiento y del contrato analítico puede avanzar con los cuatro
casos actuales, mientras se amplían las equivalencias y se prepara la evaluación de sensibilidad.

Antes de migrar se debe concretar el esquema mínimo con estos casos, el guardado transaccional,
la reimportación, la conservación del aporte mínimo y la elección editorial de estructura. Después se incorporan almacenamiento y
permisos compatibles; a continuación, lectores y cálculos con cobertura; finalmente, el recorrido
de importación, ampliación editorial y selección de agregados para fichas. El referente ampliado
no se publica como una matriz por obra.

La implementación tendrá que verificar guardados reales, rechazo de referencias incoherentes,
idempotencia, concurrencia, permisos por rol, no publicación individual y no duplicación del corpus.
Se probarán específicamente Canción sin arquitectura con remate, identificación pendiente,
desviaciones, promoción incompleta y transiciones con huecos. Las anotaciones completas existentes
deben seguir pasando sus validaciones. Antes de tocar datos se aplican las copias y snapshots
exigidos por el repositorio; ninguna de esas operaciones forma parte de este documento.
