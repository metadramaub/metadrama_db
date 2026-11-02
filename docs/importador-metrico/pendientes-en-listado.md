# Pendientes y avisos en el listado de fichas básicas

Mejora solicitada por el responsable, pendiente de implementar. El objetivo es poder
localizar y retomar las importaciones que conservan datos por revisar, sin abrirlas todas.

## Columna Por revisar

- Formas sin identificar: denominación original y rangos de la copia confirmada.
  Ejemplo: «tercetos · 1–127, 1523–1667». La ambigüedad no implica error de extracción.
- Avisos detectados: texto y pasaje concretos, distinguiendo los de longitud métrica
  de las incidencias declaradas por la fuente o la extracción original.
- Si una incidencia del original ya fue corregida al preparar la ficha, no presentarla
  automáticamente como un error todavía vigente.
- Las fichas anteriores no guardan el resultado completo de los avisos al importar.
  No se reconstruirá un supuesto historial ni se mostrará «sin avisos al importar» por
  ausencia de ese registro. Los avisos recalculados hoy deben distinguirse de los históricos.

No llamar «errores» a todos los pendientes o avisos. Un aviso de compatibilidad de longitud
no demuestra por sí solo error de la edición. Las formas sin resolver deben seguir pendientes
hasta una decisión editorial, sin selección automática de candidatas ni remate por longitud.

## Implementación

### Fechas de importación y última modificación

Petición adicional del responsable: guardar y mostrar ambas fechas por ficha básica.
La importación es el alta original y no cambia. La última modificación representa el
último cambio efectivamente guardado en el contenido básico vigente (metadatos, estructura
o métrica), no una visita, una comprobación sin guardar ni una actualización de cálculos.
Al crear la ficha, ambas fechas pueden coincidir.

El esquema vivo ya conserva `importaciones_metricas.importado_en` y `updated_at` en obras,
jornadas y secuencias, pero no una fecha propia de modificación del registro de importación.
No usar sin más `obras.updated_at` como fecha de toda la ficha: no demuestra por sí solo
cuándo cambió la métrica o una secuencia. Los cambios del futuro borrador detallado tampoco
deben presentarse como modificaciones de la copia básica que sigue aportando al corpus.

La implementación debe conservar una fecha explícita del aporte básico y actualizarla en
la misma operación que guarda su corrección. La copia original y su fecha de importación
permanecen inmutables. Para registros existentes no se inventará una fecha histórica: usar
la importación si se acredita que no hubo cambios, o señalar que la modificación no consta.
Definirlo junto a la edición/reimportación de básicas y el resumen del listado; no introducir
una actualización ficticia de la copia solo para mostrar una fecha más reciente.

### Lectura del resumen

La consulta del listado debe devolver un resumen compacto por importación y mantener la
paginación y los permisos actuales. Evitar cargar todas las copias completas o hacer una
consulta por ficha. Las formas pendientes salen de la copia confirmada, no de la estructura
compartida que un editor pueda modificar después.

Antes de implementar: ampliar el contrato de lectura de la lista y concretar qué avisos
se conservarán al guardar las nuevas importaciones, usando el mismo comprobador del editor.
Mantener compatibilidad con las fichas existentes y sin modificar las copias inmutables.
La ampliación SQL deberá probarse en PostgreSQL aislado y seguir el procedimiento de backup
y despliegue del proyecto. No aplicar ahora una migración solo para el contador de avisos.

## Corrección inmediata ya implementada

Tras «Comprobar cambios» se muestran el contador y el texto de todos los avisos revisables.
El aviso de formas pendientes incluye denominaciones y rangos. Los recordatorios técnicos
del flujo siguen excluidos del contador. Esto permite entender la advertencia antes de guardar,
sin alterar la validación ni añadir requisitos a la ficha básica.
