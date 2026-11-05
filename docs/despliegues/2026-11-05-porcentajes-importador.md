# Porcentajes literales del importador — 5 de noviembre de 2026

Migración `20261105120000_importador_separadores_porcentajes.sql` aplicada al Supabase
enlazado. Amplía únicamente la constante JSON Schema de extracción para admitir coma,
punto y apóstrofo decimal. Conserva el literal: no modifica importaciones existentes.

- Backup completo de esquema, datos y roles, más esquema público para restauración local:
  `backups/supabase/20261105-importador-cotejo/`; los cuatro archivos tienen contenido.
- Ensayo del mismo archivo dos veces sobre el esquema público recién descargado, en
  `versologia-importador-pruebas`, sin red ni puertos publicados: **117 comprobaciones
  PostgreSQL satisfactorias**, incluido guardar y recuperar `69’2` sin cambiar el separador.
- La guarda SQL ejecuta la validación con seis ejemplos válidos y cinco inválidos.
- Simulación previa: solo esta migración pendiente. Aplicación posterior correcta.
- SELECT posterior: migración registrada una vez y `69’2` admitido por la función real.
- No se guardaron obras sintéticas en Supabase. No cambia ninguna función de precomputación.

El primer ensayo con el volcado del 3 de noviembre no superó el contrato de guardado;
se repitió sobre el esquema actual, que sí supera las comprobaciones. El esquema completo
incluye `pg_cron`, que no se restaura en bases temporales; el ensayo usa el volcado público.

Este registro acredita la migración de Supabase. Los cambios de aplicación y de equivalencias
se comprueban y versionan en main; este registro no acredita su despliegue web.

[Evaluación del lote y correcciones](../importador-metrico/evaluacion/informes/chatgpt-gpt6-high-v0.27.md).
