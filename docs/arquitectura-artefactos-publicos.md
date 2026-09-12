# Artefactos públicos JSON

Implementado y aplicado el 12 de septiembre de 2026 por la migración
`20260912100000_los_datos_publicos_son_artefactos_json.sql`.

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
| `corpus/comparativas/{alcance}.json` | prevalencias y distribuciones | fichas y laboratorio |

`alcance` es `publico` o `completo`. Cada payload declara `schema_version`; la fila conserva además
`generado_en` y `sucio`. Marcar un artefacto como sucio no borra la última versión coherente: la web
puede seguir sirviéndola mientras termina la actualización.

La lectura de SvelteKit está centralizada en `src/lib/server/public-artifacts.ts` y los contratos
de aplicación, en `src/lib/types/public-artifacts.types.ts`. Una página no debe construir claves a
mano ni leer directamente `payload`: eso permitiría cambiar el soporte de almacenamiento en un solo
lugar.

Las comparativas guardan siempre el universo analizable y la ausencia de respuesta. Para una
transición conservan obras con el patrón, total de obras, ocurrencias y distribución incluyendo
ceros. Para fenómenos por secuencia conservan la distribución de proporciones por obra. Así se
puede distinguir «no ocurre» de «no está anotado» y presentar media, mediana, cuartiles o percentil
sin recalcular el corpus en cada ficha.

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

La infraestructura ya calcula comparativas de transiciones y de fenómenos por secuencia, pero las
fichas todavía no presentan «esta obra frente al corpus». El siguiente trabajo de producto es
decidir esa redacción y visualización, conectar el artefacto de comparativas con los componentes de
análisis y reutilizarlo en el laboratorio. Después podrán añadirse métricas al contrato con una
nueva `schema_version`, sin ensanchar `obras_resumen`.

## Paso futuro a R2

El productor generará primero el nuevo payload con la misma clave y versión, lo subirá a una ruta
inmutable de revisión y, solo al terminar correctamente, moverá un manifiesto pequeño que señale la
revisión activa. La web leerá el manifiesto y seguirá usando la revisión anterior si una cola falla.
Postgres podrá conservar únicamente metadatos de publicación y, si conviene, una ventana de
artefactos recientes. No hará falta cambiar las rutas públicas ni los tipos de payload.
