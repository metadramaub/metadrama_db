# Gestión y pendientes en el listado de fichas básicas

Implementación del 2 de noviembre de 2026. El listado permite localizar importaciones por
revisar y eliminar explícitamente una básica desde una cuenta admin/IP.

## Columna Por revisar

- Formas sin identificar: denominación original y rangos de la copia confirmada, agrupados.
- Avisos de longitud guardados: pasaje y explicación del comprobador compartido con el editor.
  Las nuevas importaciones guardan `comprobacion.avisos_longitud` en `datos_confirmados`.
  Se recalcula al comprobar cambios; corregir una secuencia retira su aviso antes de guardar.
- Incidencias del JSON original: separadas, con su texto accesible. Pueden haberse corregido
  durante la preparación y no se afirman como errores vigentes.
- Las copias anteriores no conservan la comprobación de longitud: muestran «sin registro al
  importar». Su ausencia no certifica que se importaran sin avisos. No se reescriben estas copias.

Las formas pendientes no implican error de extracción. La longitud tampoco autoriza por sí
sola una equivalencia ni un remate: se mantiene la decisión editorial.

## Fechas

`importado_en` conserva el alta original. La nueva columna `modificado_en` registra la fecha
propia de la copia básica; al crearla coincide con el alta. Los registros anteriores quedan
sin fecha acreditada y muestran «No consta», sin inventar historia ni usar `obras.updated_at`.

Las copias siguen siendo inmutables. Aún no existe edición/reimportación general de básicas:
cuando se implemente, deberá definir la sustitución de la copia y guardar la fecha del cambio
en esa misma operación. Visitar, comprobar sin guardar, recalcular análisis o modificar el
borrador detallado no cambia la fecha de la copia básica.

## Consulta

`listar_fichas_basicas` devuelve metadatos y resúmenes compactos, con paginación de 50 fichas
y un registro adicional para detectar la siguiente página. No descarga documentos completos,
no realiza una consulta por ficha ni recalcula métricas. Usa la copia confirmada, no secuencias
compartidas que un editor pueda modificar al preparar una detallada.

## Eliminación

La papelera aparece al final de la fila para admin/IP. El diálogo exige escribir el título y
explica el alcance. El servidor y `eliminar_ficha_basica` comprueban permisos de sesión activa,
título, tipo básico vigente, ausencia de editor asignado y ausencia de anotaciones detalladas.
La operación elimina la obra y, por las claves foráneas, jornadas, secuencias e importaciones.
No hay recuperación desde la interfaz. La implementación no elimina ninguna obra real.

Migración: `20261102190000_gestion_listado_fichas_basicas.sql`. Copia de seguridad completa en
`backups/supabase/20261102-listado-basicas/`. Probada en PostgreSQL aislado con 107 comprobaciones,
incluidos permisos, confirmación, cascadas y conservación de las otras obras. Pruebas de servidor
y componente, comprobación de tipos y compilación completadas.
