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
`generado_en`, `contenido_cambiado_en` y `sucio`. Marcar un artefacto como sucio no borra la última
versión coherente: la web puede seguir sirviéndola mientras termina la actualización.

`generado_en` se mueve en cada recálculo, y la cola recalcula todas las obras publicadas cada vez.
`contenido_cambiado_en` solo se mueve cuando el payload guardado es distinto del anterior: es la
fecha que la ficha enseña como «actualizada» y la del «datos a…» de sus gráficos. Cambiar el
contrato —añadir un campo a todas las fichas— la mueve en todas.

La lectura de SvelteKit está centralizada en `src/lib/server/public-artifacts.ts` y los contratos
de aplicación, en `src/lib/types/public-artifacts.types.ts`. Una página no debe construir claves a
mano ni leer directamente `payload`: eso permitiría cambiar el soporte de almacenamiento en un solo
lugar.

Las comparativas V2 guardan una fila compacta por obra, distribuciones escalares, perfiles por
forma, transiciones, fenómenos, enunciación y extremos de jornada. Conservan siempre el universo
analizable y la ausencia de respuesta. Los ceros entran cuando la ausencia es un valor —una forma o
una transición no aparecen—; una pregunta sin responder no se convierte en `No`.

Desde la migración de géneros, la ficha añade `generos_intervinientes` (array o `null`) a cada
secuencia; los hechos de análisis añaden el mismo array cuando está respondido. Se conservan
las claves anteriores de compatibilidad, de modo que es una ampliación aditiva de los contratos
de ficha V1 y análisis/comparativas V2. El análisis añade los indicadores de intervención masculina
e indeterminada y calcula los tres géneros con el mismo denominador de secuencias respondidas.
La regeneración de fichas, análisis, índices y comparativas se ejecuta en la transacción de la
migración. Los consumidores activos usan el conjunto; no reconstruyen géneros desde el indicador
femenino heredado.

La matriz no se entregará a la ficha. Cuando el laboratorio haya validado qué referencias ayudan a
leer una obra se generará una proyección pública pequeña por obra. El orden y las ideas de
presentación están en [plan-comparativas-corpus.md](plan-comparativas-corpus.md).

### Corrección de prosa: contrato V3 preparado el 29 de octubre

La migración `20261029120000_la_prosa_se_localiza_entre_versos.sql` separa prosa de las medidas de
extensión en `obra_analisis` y `corpus_comparativas`, que pasan a V3. La ficha y los índices
mantienen V1. No cambia la anotación editorial ni las políticas de acceso.

Cuando hay prosa, `enunciacion.prosa` del análisis contiene `presente: true`, `localizaciones`
con `v_anterior`/`v_posterior`, y las formas de sus secuencias. No contiene `versos` ni
`proporcion_versos`. Las localizaciones repetidas se deduplican, sin fusionar inserciones próximas.
El agregado del corpus conserva obras con presencia y su proporción entre obras analizadas;
esa proporción no mide extensión de prosa. Canto y evocación conservan su cálculo por versos.

Despliegue: publicar primero los lectores compatibles y después aplicar la migración, que llama
al recorrido completo `recompute_all()`. El laboratorio admite temporalmente V2 mediante
`corpus-compat.ts`: conserva sus medidas válidas y omite los datos inválidos de extensión de prosa,
sin convertir su omisión en una ausencia analizada. V3 se sirve directamente. Esta adaptación
solo transforma JSON ya precomputado; no consulta anotaciones ni recalcula análisis en una visita.

La migración se ha ejecutado dos veces en una copia aislada del esquema y datos de aplicación,
con 16 comprobaciones de contenido, persistencia, privacidad e integridad de las anotaciones.
Ensayo reproducible, con el contenedor aislado `versologia-prosa-pruebas` iniciado según el mismo
procedimiento de [persistencia local](./importador-metrico/persistencia-local.md), cambiando su nombre:

```sh
node scripts/probar-prosa-local.mjs backups/prosa-correccion/public-schema.sql backups/prosa-correccion/public-data.sql
```

Los dos volcados se obtienen con `supabase db dump --linked --schema public` y su variante
`--data-only`, sin sustituir la copia completa previa exigida para aplicar en remoto. El ensayo
no se conecta a Supabase ni expone puertos. El estado del despliegue se mantiene en PENDIENTES.

## Flujo de actualización

Las notas históricas trasladadas a comentarios se registran en la tabla privada
`traslados_observaciones_caracterizacion`. `ficha_publica_base_json` conserva la caracterización,
pero devuelve su `observaciones` como `null` cuando existe ese rastro, para mostrar la nota solo en
`comentarios_publicos`. Las notas pendientes de traslado conservan su representación anterior.
No cambia el contrato de ficha. Los textos originales permanecen en la tabla de rangos y en el
rastro; si se elimina el comentario, la nota antigua no reaparece. La primera migración de
traslado regenera los artefactos publicados con `recompute_all()`.

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
