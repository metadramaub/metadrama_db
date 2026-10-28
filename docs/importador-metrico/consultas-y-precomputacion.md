# Consultas y precomputación del corpus mínimo y completo

28 de octubre de 2026. Plan previo a conectar el guardado. Desarrolla el
[diseño acordado](./diseno-integracion.md), sin modificar todavía consultas, cálculos ni DB.
La implementación pendiente se mantiene en [PENDIENTES](../PENDIENTES.md).

## Condición de arquitectura

**El análisis sigue alimentándose de datos precomputados.** La combinación de fuentes se hace
en los productores de esos datos, nunca mediante nuevas consultas analíticas al abrir una página.
El laboratorio conserva sus interacciones sobre los datos preparados que recibe.
Guardar una importación no autoriza a ejecutar análisis al consultar su ficha.

La consulta individual de una importación puede recuperar su documento confirmado y procedencia.
Es lectura editorial, no una excepción para calcular perfiles o comparativas en cada visita.

## Lo observado en el sistema actual

- `public-artifacts.ts` centraliza las claves y la lectura de `artefactos_publicos`.
- El cargador del laboratorio lee el artefacto de comparativas, contrato `schema_version: 2`.
  Su criterio declara expresamente obras publicadas. No admite mínimas sin cambiar ese contrato.
- `corpus_comparativas_artefacto_json` parte del índice de obras y de sus análisis precomputados.
  Algunos agregados completan con cero valores ausentes: no puede recibir datos mínimos sin revisar
  esa semántica. La revisión también debe detectar datos desconocidos de fichas completas.
- `plan_recompute_datos_publicos` selecciona obras publicadas y autores;
  `finalizar_recompute_datos_publicos` elimina artefactos fuera de ese circuito. Los nuevos datos
  mixtos no pueden incorporarse a ese mantenimiento sin adaptar su selección y limpieza.
- `perfil_metrico_unidades` distingue atribuciones de obra y jornada. No se sustituye por una
  relación simplificada que adjudique toda obra completa a un único autor.
- Hay lectores y productores `SECURITY DEFINER`. La separación no puede descansar solo en RLS,
  en esconder enlaces ni en el nombre de una clave de JSON.

La [auditoría de consumidores](./piloto/auditoria-consumidores-2026-10-28.json) conserva firmas,
huellas de definiciones y permisos observados mediante SELECT. Su alcance son referencias directas;
no acredita todavía el cierre de las dependencias transitivas ni pruebas de ejecución.

## Qué debe consultar cada recorrido

| Recorrido | Fuentes admitidas | Salida y acceso |
| --- | --- | --- |
| Listados de trabajo, progreso, revisión y edición completa | Fichas del recorrido completo, en sus estados editoriales | Mantener separados sus contadores, checklist y obligaciones; no presentar una mínima como ficha completa pendiente |
| Fichas mínimas e importador | Importaciones confirmadas, incluida la propia y las de otros importadores | Consulta individual para admin/IP, importadores autorizados y referencia de la obra asignada; sin acceso añadido al laboratorio |
| Ficha completa y su análisis propio | Anotación completa de esa obra | Conservar su fuente y profundidad; una mínima anterior no rellena preguntas v2 |
| Laboratorio actual de completas | Universo actual de completas elegibles | Mantener resultados y permisos mientras se prepara el contrato mixto |
| Laboratorio con corpus ampliado | Una aportación seleccionada por obra; completas y mínimas elegibles para cada medida | Datos mixtos precomputados, privados para admin/IP, con filtros y cobertura explícitos |
| Contraste de una completa con su autor | Referente mixto seleccionado para esa comparación | Resultado agregado precomputado; su salida pública no contiene la matriz ni las fichas mínimas |
| Índices públicos de obras y fichas de autores existentes | Mantener su criterio actual de publicación | El referente estadístico ampliado no introduce fichas mínimas en el catálogo público |

No se aplica un filtro general «solo completas» a todos los lectores ni se amplía indiscriminadamente
`formas_de_la_obra`. Los filtros editoriales pertenecen a sus consultas; el productor analítico tiene
su selección explícita. Un permiso de lectura tampoco determina por sí solo la elegibilidad estadística.

## Una sola aportación por obra

La selección precede al cálculo y al reparto por autoría:

1. Si la completa está publicada, la fuente seleccionada es v2; la disponibilidad de cada medida
   se evalúa después, sin recuperar datos de la antigua mínima para rellenarla.
2. Mientras esa publicación no se produzca, puede aportar la copia mínima confirmada seleccionada.
3. Sin ninguna de las dos fuentes elegibles, la obra no aporta un perfil supuesto.

No se unen todas las filas mínimas y v2 para quitar duplicados al final. Se elige primero la fuente
de cada obra. Publicar la completa sustituye el aporte mínimo; no se suman ni se mezclan dimensiones
de ambas fuentes. Una arquitectura ausente en la completa no se rellena desde la antigua mínima.

La mínima procede de `importaciones_metricas.datos_confirmados`, con sus jornadas, secuencias,
edición, datación y autor de importación. **No** de las secuencias de trabajo que alguien esté
corrigiendo, ni de los metadatos de otra edición introducidos durante ese trabajo.
La selección de autoría utiliza los identificadores de su fuente y conserva, para completas, las
unidades de obra/jornada del modelo existente. No se duplica una obra por varias atribuciones.

La copia retirada se conserva como historia. Retirar de publicación una completa no debe reactivar
automáticamente una importación histórica: esa transición requiere una política explícita.
Esta última regla se propone para concretar el caso aún no acordado, no como flujo implementado.

## Lectura común dentro de los productores

Dos lectores preparan los datos que necesitan los cálculos: uno traduce v2 y otro la copia mínima.
Ambos conservan identidad de obra, fuente seleccionada y su versión, rangos, forma y arquitectura
conocidas, detalles documentados, intervalos de fechas y cobertura por dimensión.
Después se aplican las mismas definiciones de medida cuando sean comparables.

Esto no crea una tercera anotación editable ni modifica las exigencias de v2. Los resultados
derivados se almacenan como datos precomputados; no constituyen otra ficha mantenida a mano.

| Medida | Condición que debe conservar el productor |
| --- | --- |
| Perfil de formas | Parte identificada y pendiente sobre el total numerado; no convertir la parte conocida en un falso 100 % |
| Arquitecturas | Cobertura propia, distinta de la cobertura de formas; no excluir por ello una forma conocida |
| Rima, remates y otros rasgos | Presencias documentadas; ausencia de dato no significa ausencia del fenómeno ni anotación exhaustiva |
| Secuencias y transiciones | No certificar límites provisionales ni saltar un tramo desconocido creando una transición entre sus vecinos |
| Cuadros, personajes y caracterizaciones | No disponibles en una mínima por defecto; no generar ceros ni incluirla en esos denominadores |
| Cronología | Conservar intervalos; el criterio de inclusión en un periodo debe declararse, sin inventar una fecha puntual |

La elegibilidad se determina por medida y evidencia, también para las completas. La etiqueta mínima
no rebaja automáticamente su peso, ni la etiqueta completa demuestra que todos sus campos se conozcan.
Los recuentos de obras y versos elegibles, conocidos, pendientes y excluidos acompañan al resultado.
No basta con un único porcentaje de cobertura para todo el corpus.

## Artefactos, universos y permisos

Se mantienen separados tres conceptos: **fuente** (mínima/completa), **composición del corpus**
(solo completas/mixto) y **acceso** (interno/salida pública seleccionada).
En el sistema actual `alcance='completo'` significa todas las publicadas admitidas por ese ámbito,
no «completas más mínimas». Además el payload de comparativas declara `privado: true` incluso para
el universo llamado `publico`. Esos nombres no se reutilizan con otro significado.

El contrato nuevo debe versionar composición, criterio de selección, definiciones de las medidas,
fecha/generación, fuentes utilizadas y sus huellas, cobertura y políticas de datación/autoría.
El laboratorio recibe su conjunto de datos privado precomputado. Una comparación difundible recibe
un payload distinto, construido expresamente con los agregados permitidos, nunca el conjunto privado
con una etiqueta pública ni su matriz por obra.

Se estudiará reutilizar `artefactos_publicos` y su mecanismo de recálculo, adaptando sus tipos,
restricciones, RLS y limpieza. No se crea otro almacén o planificador por defecto, pero tampoco se
da por segura la reutilización hasta comprobar los permisos del tipo y sus lectores.

## Invalidación y actualización coherente

| Cambio | Qué debe quedar pendiente de recalcular |
| --- | --- |
| Confirmar una mínima | Su análisis preparado y los referentes de los autores/universos a los que aporta; no su publicación individual |
| Editar el borrador completo mientras aporta la copia mínima | La edición y sus controles; el referente mínimo no cambia por esos datos de trabajo |
| Publicar la completa | Su análisis completo, la sustitución de fuente y los agregados/comparaciones dependientes |
| Corregir una fuente aceptada mediante una operación prevista | Los resultados que dependan de esa fuente, sin sobrescribir silenciosamente la copia histórica |
| Cambiar definiciones de cálculo o políticas de selección | Los artefactos de la versión afectada; no todas las fichas por una mera variación visual |
| Cambiar catálogo o equivalencias | Evaluar las referencias afectadas; no reinterpretar automáticamente las importaciones confirmadas |

El recálculo prepara las dependencias antes de activar el agregado. Si falta una dependencia o sigue
pendiente de generar, no se elimina esa obra silenciosamente del universo ni se usa una mínima
histórica como sustituto. Una generación identifica qué fuentes y versiones reunió.

Una generación completa y validada sustituye a la anterior de forma atómica para ese conjunto de
resultados. Ante fallo se conserva la última generación coherente, marcada como pendiente/desactualizada,
o se indica que aún no existe resultado. **Nunca se recalcula al leer ni se sirve un corpus a medias.**
Conservar una generación anterior identificada no significa volver a seleccionar la antigua mínima
para calcular un resultado nuevo después de publicar la completa.
Si cambia el análisis propio de una ficha, una conclusión comparativa anterior debe identificarse como
pendiente de actualizar; no presentarse como calculada sobre los datos nuevos.
Las vistas editoriales de una importación guardada no dependen de que haya terminado este recálculo.

## Orden de implementación y pruebas de aceptación

Primero se documenta el mapa de lectores/productores, se fija la selección de fuente y el contrato
precomputado y se protege la separación editorial. Después se conectan guardado y consulta de mínimas.
Su aportación analítica se habilita al disponer del productor, invalidación y permisos correspondientes.
Una mínima guardada no se presentará como ya incorporada a los análisis si aún no lo está.

Casos de aceptación: una mínima confirmada; su completa en elaboración sin alterar el referente;
publicación con sustitución y una sola aportación; cambios de edición y rangos; forma conocida sin
arquitectura; forma pendiente; ausencia real frente a dato desconocido; atribución de obra/jornada;
fallo y reintento de generación; aislamiento entre payload privado y comparación pública.
Las pruebas de los cargadores comprobarán que las consultas analíticas solo leen artefactos:
no disparan productores ni usan las tablas de anotaciones como cálculo alternativo si falta uno.

Las métricas conocidas de las completas deben conservar sus valores. Las diferencias debidas a
corregir ceros que representaban datos desconocidos se documentan y versionan, no se introducen
como un efecto lateral del importador. Se comparan los resultados anteriores con casos de control.

Quedan decisiones metodológicas antes de publicar afinidades: ponderación por obra o versos,
exclusión de la obra comparada y sus versiones, tratamiento operativo de intervalos cronológicos
y requisitos de muestra/estabilidad. Se formularán con ejemplos; no se inventan umbrales con cuatro obras.
