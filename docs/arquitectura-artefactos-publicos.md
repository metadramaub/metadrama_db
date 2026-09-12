# Artefactos públicos JSON

Implementado y aplicado el 12 de septiembre de 2026 por las migraciones
`20260912100000_los_datos_publicos_son_artefactos_json.sql` y
`20260912150000_el_corpus_comparativo_es_un_laboratorio_privado.sql`.

## Decisión

Los datos derivados que consume la web pública se publican como documentos JSON con contrato y
clave estables. Por ahora viven en `public.artefactos_publicos` (`jsonb`); la ruta de cada clave es
también la futura clave de objeto si se trasladan a R2. La base relacional sigue siendo la fuente de
verdad y `obras_resumen` / `autores_resumen` quedan como cálculo intermedio, no como una API que
crece una columna por cada gráfico nuevo.

No se añade R2 todavía. Mientras el corpus cabe holgadamente en Postgres, introducir dos almacenes
obligaría a resolver credenciales, subidas parciales e invalidación sin reducir el coste actual. El
contrato ya queda desacoplado del soporte, de modo que el cambio posterior será un adaptador de
lectura/escritura y no otra remodelación de los datos.

## Contratos

| clave | contenido | consumidor principal |
|---|---|---|
| `obras/{id}/ficha/publico.json` | ficha pública completa | `/obras/[slug]` |
| `obras/{id}/analisis/publico.json` | hechos compactos por secuencia y agregados | comparativas y laboratorio |
| `indices/obras/{alcance}.json` | tarjetas, ordenación y facetas | `/obras` |
| `autores/{id}/ficha/{alcance}.json` | identidad, obras ligeras y perfil | `/autores/[slug]` |
| `indices/autores/{alcance}.json` | tarjetas y obras principales | `/autores` |
| `corpus/comparativas/{alcance}.json` | matriz compacta, prevalencias y distribuciones | laboratorio privado |

`alcance` es `publico` o `completo`. En los índices y fichas también determina quién puede leer; en
`corpus_comparativas` describe solo el universo estadístico y **ambas variantes son privadas**. Cada
payload declara `schema_version`; la fila conserva además
`generado_en` y `sucio`. Marcar un artefacto como sucio no borra la última versión coherente: la web
puede seguir sirviéndola mientras termina la actualización.

La lectura de SvelteKit está centralizada en `src/lib/server/public-artifacts.ts` y los contratos
de aplicación, en `src/lib/types/public-artifacts.types.ts`. Una página no debe construir claves a
mano ni leer directamente `payload`: eso permitiría cambiar el soporte de almacenamiento en un solo
lugar.

Las comparativas V2 guardan una fila compacta por obra, distribuciones escalares, perfiles por
forma, transiciones, fenómenos, enunciación y extremos de jornada. Conservan siempre el universo
analizable y la ausencia de respuesta. Los ceros entran cuando la ausencia es un valor —una forma o
una transición no aparecen—; una pregunta sin responder no se convierte en `No`.

La matriz no se entregará a la ficha. Cuando el laboratorio haya validado qué referencias ayudan a
leer una obra se generará una proyección pública pequeña por obra. El orden y las ideas de
presentación están en [plan-comparativas-corpus.md](plan-comparativas-corpus.md).

## Flujo de actualización

1. La interfaz pide a `plan_recompute_datos_publicos` la lista de obras y autores.
2. Cada paso de obra reconstruye `obras_resumen` y, en la misma petición, sus artefactos de ficha y
   análisis.
3. Cada paso de autor agrega sus perfiles desde los artefactos compactos de las obras y publica su
   ficha JSON. Solo durante el primer despliegue existe un fallback a las tablas de anotación si una
   obra todavía no tiene artefacto.
4. El paso final limpia entidades que hayan dejado de pertenecer al corpus y reemplaza los índices y
   las comparativas globales.

El botón individual de una obra sigue el mismo grafo: obra → autores afectados → índices y corpus.
La vista previa de una obra no publicada es la excepción deliberada y continúa construyéndose en
vivo, porque es temporal y todavía no debe formar parte del corpus.

Las páginas conservan un fallback a `obras_resumen`, `autores_resumen` y las RPC anteriores durante
el primer despliegue. Una vez materializadas las claves, anónimo y admin/IP leen los índices JSON.
El catálogo de un editor normal sigue siendo relacional porque mezcla el corpus público con su obra
no visible asignada: es un alcance personal, no un artefacto compartible.

La primera materialización dejó 36 artefactos coherentes: 29 legibles como anónimo y 7 variantes de
alcance `completo`. Estos números describen el corpus de prueba de esa fecha, no son invariantes ni
deben escribirse en código.

## Continuación

El siguiente trabajo de producto es hacer que el laboratorio privado consuma el contrato V2 y usarlo
para evaluar medidas. Solo después se seleccionarán comparaciones para la ficha y se creará su
proyección pública por obra. Las nuevas preguntas pueden ampliar los artefactos sin ensanchar
`obras_resumen`.

## Paso futuro a R2

El productor generará primero el nuevo payload con la misma clave y versión, lo subirá a una ruta
inmutable de revisión y, solo al terminar correctamente, moverá un manifiesto pequeño que señale la
revisión activa. La web leerá el manifiesto y seguirá usando la revisión anterior si una cola falla.
Postgres podrá conservar únicamente metadatos de publicación y, si conviene, una ventana de
artefactos recientes. No hará falta cambiar las rutas públicas ni los tipos de payload.
