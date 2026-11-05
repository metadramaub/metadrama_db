# Gestión de fichas básicas — 2 de noviembre de 2026

Migración `20261102190000_gestion_listado_fichas_basicas.sql` aplicada al Supabase enlazado.
La migración añade `modificado_en`, amplía el resumen paginado del listado y habilita la función
de eliminación explícita para admin/IP. No ejecuta eliminaciones ni reescribe copias existentes.

- Backup previo de esquema, datos y roles: `backups/supabase/20261102-listado-basicas/`.
- Ensayo de la migración exacta en PostgreSQL aislado: 107 comprobaciones satisfactorias.
- Pruebas de servidor, componente y vista previa satisfactorias; tipos y compilación correctos.
- Registro de migración verificado en `supabase_migrations.schema_migrations`.
- Antes y después: 151 obras, 107 jornadas y 921 secuencias. Las seis importaciones mantienen
  la misma huella conjunta de `entrada_original` y `datos_confirmados`.
- Las seis fechas históricas nuevas permanecen nulas. Las importaciones futuras usan `now()`.
- `anon` no puede ejecutar la función de eliminación. Los filtros de sesión, rol, confirmación
  y protección de obras asignadas/detalladas se verificaron en el ensayo aislado.
- El molino sigue existiendo. Su eliminación queda a cargo del responsable desde la interfaz.

[Contrato del listado y gestión](../importador-metrico/historico/desarrollo/pendientes-en-listado.md).
