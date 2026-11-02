# Datos de ejecución de la extracción

El prompt v0.12 intenta declarar servicio (`generador`), modelo, modo, cuenta (`plan`) y
parámetros conocidos. No infiere el modelo a partir de Instant ni inventa valores de
temperatura u otros parámetros. Lo desconocido queda en null. Son datos declarados por
la IA, no una certificación independiente de su identidad.

Después de «Preparar importación», el bloque opcional **Extracción con IA**, dentro de
los metadatos, permite corregir o borrar esos cinco datos. Se comprueban y guardan con
el mismo flujo de la obra. Ninguno se exige para importar. `parametros` es texto con
los valores explícitos, no un objeto de configuración que la plataforma ejecute.

## Conservación

- `entrada_original.procedencia`: declaración original, conservada sin cambios.
- `datos_confirmados.procedencia.ejecucion`: valores confirmados en el formulario y versión
  del prompt de la entrada. Borrar un campo produce null; no recupera la afirmación original.
- La ficha básica guardada muestra los valores confirmados en modo de consulta. La copia
  es inmutable; esta edición se hace antes de guardar, no modifica importaciones históricas.
- Una copia antigua sin `ejecucion` puede leer los datos disponibles de la procedencia
  original. No se modifica para completar lo que falta.

Se añaden tres campos opcionales a la procedencia de extracción 0.1 (`modo`, `plan`,
`parametros`) y un objeto opcional a la procedencia del documento mínimo 0.2. No cambia
la métrica, los datos bibliográficos, los permisos ni las tablas. Los formatos anteriores
siguen siendo válidos. La migración actualiza solo las dos funciones de esquema JSON;
no recalcula ni reescribe las fichas.

## Verificación

Backup completo previo en `backups/supabase/20261102-ia-ejecucion`: esquema, datos y roles.
El esquema público se exporta además para restaurarlo en PostgreSQL aislado; el esquema
completo contiene pg_cron, que requiere su base configurada y no se restaura como parte
de este ensayo. Las pruebas de PostgreSQL usan datos sintéticos, nunca nuevas obras reales.

Pruebas del formulario, correcciones/borrado, lectura posterior y compatibilidad incluidas
en las suites del importador. El ensayo PostgreSQL guarda una ejecución corregida, mantiene
el modelo declarado originalmente y admite las copias anteriores sin el objeto nuevo.

Resultado: 269 pruebas Vitest, comprobación de tipos sin errores ni advertencias y build
de producción correctos. La migración exacta pasa 91 comprobaciones en PostgreSQL aislado.
El dry-run remoto lista únicamente `20261102170000_importador_ejecucion_ia.sql`.

**Estado de despliegue, 02-11-2026:** migración aplicada a Supabase compartido tras la
autorización explícita del responsable («aplica la migración»). La revisión automática había
bloqueado el primer intento por no identificar aprobación para este cambio concreto;
ese intento no ejecutó SQL. Tras la autorización, el dry-run confirmó que solo estaba
pendiente esta migración y `db push` la aplicó correctamente.

Verificación remota posterior mediante SELECT: las cuatro importaciones anteriores conservan
las mismas huellas de `entrada_original` y `datos_confirmados`; cero documentos incompatibles.
Las nuevas propiedades opcionales están en los dos contratos y la migración figura registrada.
Evidencia local: `backups/supabase/20261102-ia-ejecucion/verificacion-despues.json`.
