# Prosa en secuencias básicas — 3 de noviembre de 2026

Migración `20261103110000_importador_prosa_en_secuencia.sql` aplicada al Supabase enlazado tras
ensayar ese mismo archivo en PostgreSQL sin red ni puertos publicados. Amplía el contrato JSON
de forma compatible y la validación de procedencia del guardado. No reescribe copias anteriores.

- Backup de esquema completo, esquema público, datos y roles:
  `backups/supabase/20261103-prosa-importador/`.
- 116 comprobaciones PostgreSQL satisfactorias con datos y sesiones sintéticos: permisos,
  conservación de originales, guardado y consulta de prosa localizada, rechazos de procedencia
  inventada, caracterización ausente o duplicada y ausencia de versos adicionales por prosa.
- 285 pruebas de aplicación satisfactorias, tipos sin errores ni avisos y compilación correcta.
- Migración registrada y verificada mediante SELECT.
- Antes/después: 153 obras, 113 jornadas y 967 secuencias. Misma huella conjunta de originales
  y copias confirmadas; misma huella de anotaciones métricas. Informes en `estado-antes.json`
  y `estado-despues.json` de la carpeta del backup.
- No se guardó ninguna obra sintética en producción ni se alteró una importación existente.

[Contrato y comportamiento](../importador-metrico/prosa-en-secuencias.md).
