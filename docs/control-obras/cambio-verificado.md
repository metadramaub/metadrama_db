# Cambio editorial: validación y despliegue

Generado por `node scripts/control-obras/generar-resumen-cambio.mjs` desde los resultados privados de SQL, API, Vitest e integridad. No editar a mano.

**Modelo y dataciones activos en Supabase y en la aplicación publicada.** Migración `20261110200000`; activación `b9a80151`, Vercel correcto. Verificación de integridad: 2026-11-10T21:47:51.244Z.

## Comprobación en producción

- 154 obras, 145 completas heredadas y 9 importaciones conservadas.
- Ocho tablas de métrica, estructura y procedencia con SHA-256 idéntico al respaldo; las 7 funciones de la corrección del timeout permanecen idénticas.
- Creación, encargo, inicio, edición, estructura, límites de fecha y acceso por rol ejecutados en una transacción revertida.
- Carga CSV confirmada con guardas transaccionales: no cambia métrica, importaciones, dataciones presentes ni encargos. Corpus: C60: 62; LOPE: 0; TAD: 10.
- Recomputación completa confirmada; 4 comprobaciones HTTP correctas sobre el dominio publicado. Son comprobaciones de servidor, no revisión visual.

## Contracción aplicada

Migración `20261110220000`, SHA-256 `aeec38f0b69639b2c76d3a995a9c808b2d1bd9f8319bb50be1d0f80e89061c2f`. Retiradas las 19 columnas congeladas; el núcleo conserva 9 columnas. Se retiraron el escritor y los permisos antiguos; los revisores requieren una completa mediante FK.

- Restauración de 103 tablas idénticas, recuperación con edición y fecha añadidas después, y reaplicación conservando todos los datos de la vista editorial (2026-11-10T21:44:14.029Z).
- 193 pruebas focalizadas y 37 comprobaciones de aplicación correctas con el esquema contraído. Tipos regenerados del esquema definitivo, cero errores y avisos, compilación correcta.
- Extractor analítico ejecutado con 21 registros; límites y propuestas de fecha presentes. SQL y acceso web comprobados también después de la contracción en producción.

## Ensayo inicial

- 97 tablas originales sin diferencias de SHA-256 después de los ensayos (2026-11-10T11:46:16.611Z).
- 54 pruebas focalizadas correctas; 0 fallidas.
- SQL real en transacción revertida: registro sin ficha, encargo separado del inicio, autosave en completa y conservación del núcleo; denegación de escritura directa y publicación por editor; importación nueva y sobre identidad existente; conservación de metadatos y corpus; rechazo de transición básica → completa; encargo por lotes sin inicio; lectura pública limitada.
- 12 comprobaciones HTTP correctas (2026-11-10T11:50:21.219Z):
  - PostgREST disponible solo dentro del contenedor.
  - Lectura pública limitada por estado y visibilidad.
  - Relación anidada de resumen desde la proyección pública.
  - Vista editorial inaccesible al anónimo.
  - Gestor consulta inventario completo: recuento 154.
  - Editor no consulta el inventario ajeno.
  - Creación por API mediante trigger de la proyección.
  - Identidad conservada tras crear por API.
  - Asignación de corpus por RPC autorizada.
  - Editor no modifica corpus.
  - Actualización por API sobre identidad existente.
  - Escritura efectiva en el núcleo de metadatos.

La recomputación completa se ejecutó y revirtió con los lectores adaptados.

## Control y dataciones: ensayo ampliado

Generadores reproducibles: `ensayar-dataciones-desde-copia.mjs`, `probar-aplicacion-local.mjs`, `pruebas-dataciones.sql` y las pruebas junto al código. Los datos privados y copias se mantienen en `backups/`.

- Ensayo desde la restauración de producción, sin la carga CSV anterior (2026-11-10T21:02:26.915Z): 154 obras conservadas, 63 dataciones incorporadas donde faltaban; fuentes anteriores conservadas literalmente y fechas conservadas salvo la corrección expresamente autorizada de *El esclavo del demonio* (≤1612).
- 159 pruebas focalizadas correctas; 0 fallidas. Svelte/TypeScript: cero errores y cero avisos.
- Compilación de producción completada. Se instaló la fuente ya fijada en las dependencias; package-lock permanece idéntico.
- 37 comprobaciones reales de las API de aplicación correctas (2026-11-10T21:43:20.999Z), con Auth y PostgREST locales. Incluyen dos propuestas independientes, límites estrictos, fuentes literales, rechazo de intervalos vacíos y guardado de otros metadatos sin borrar las fechas.
- SQL ejecutado: permisos, escritura única, borrado sin reaparición de datos antiguos, invalidación de resúmenes y recomputación completa. Ficha, índices, autor y comparativas conservan los calificadores. Las pruebas funcionales usan transacciones revertidas; la simulación de reversión conserva su fixture solo en la base desechable de ensayo.
- Migración definitiva transaccional ejecutada y reversión probada, conservando una edición y datación añadidas después del cambio. SQL validado: SHA-256 `e818c39abb6bed3acc960cd3728d57598453bfef852dd913868e04d7be736873`. Las tablas nuevas se conservan al revertir; el modelo anterior no representa sus calificadores y debe reactivarse junto con la aplicación compatible.
- Dos conexiones reales: una reasignación concurrente no queda sobrescrita por el guardado anterior; este recibe 40001 y conserva el nuevo responsable. La escritura de servicio funciona con claims JSON de PostgREST.
- Carga del CSV repetida sin cambios; asignaciones conservadas. 8 tablas de métrica/estructura/procedencia conservan sus huellas. Las siete funciones de la corrección del timeout permanecen idénticas.
- Pertenencias del CSV: C60: 62; LOPE: 0; TAD: 10. Lope se crea sin deducir miembros por autor.

## Diferencias conservadas frente al CSV

8 diferencias en extremos y 3 casos donde el CSV añade aproximación. No se sustituyeron fechas existentes ni se registró un estado de revisión.

| Obra | Inicio / fin vigentes | CSV | Diferencia |
| --- | --- | --- | --- |
| Tragedia de los amores de Eneas y de la reina Dido | 1530 / 1560 | c. 1540 | Extremos |
| La gran Semíramis | 1580 / 1585 | c. 1579 | Extremos |
| Elisa Dido | 1570 / 1580 | c. 1581 | Extremos |
| El prado de Valencia | 1589 / 1589 | c. 1589–1590 | Extremos |
| El esclavo del demonio | — / 1612 | 1605–1610 | Extremos |
| Dido y Eneas | 1613 / 1625 | c. 1613 | Extremos |
| El caballero de Olmedo | 1620 / 1625 | c. 1620–1625 | Aproximación |
| El conde de Sex | 1633 / 1633 | c. 1633 | Aproximación |
| Valor, agravio y mujer | 1630 / 1640 | c. 1630–1640 | Aproximación |
| El amor al uso | 1636 / 1640 | c. 1640 | Extremos |
| Cegar para ver mejor | 1653 / 1660 | ≤1660 | Extremos |

El IP confirmó que el 1612 de *El esclavo del demonio* es un límite superior por su edición: se migra a ≤1612, con la fuente intacta. La candidata comprueba el dato de origen y se detiene si ha cambiado antes del despliegue. El CSV no sustituye las demás dataciones existentes.

## Límites de la comprobación

La interacción visual inicial cubrió corpus y encargos; el navegador integrado dejó de responder y no permitió revisar visualmente el formulario nuevo. La carga SSR y las API sí se comprobaron. El despliegue coordinado está comprobado en producción. Las columnas antiguas están retiradas; copias y recuperación comprobadas. Los formatos y JSON históricos permanecen intactos.
