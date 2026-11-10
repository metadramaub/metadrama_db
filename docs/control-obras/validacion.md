# Validación de la preparación del control de obras

Generado por `node scripts/control-obras/generar-validacion.mjs <carpeta de copia>` desde `validacion-local.json` y `validacion-acceso.json`. No editar a mano.

Ensayo: 2026-11-10T11:08:09.807Z. Acceso: 2026-11-10T11:11:54.138Z.

**Solo restauración aislada, sin red ni puertos; ninguna migración aplicada al Supabase compartido.**

## Datos conservados

| Tipo heredado | Obras | Asignadas |
| --- | ---: | ---: |
| Completa heredada | 145 | 107 |
| Básica (valor histórico minima) | 9 | 0 |

## Comprobaciones

- Correcta: Todas las tablas de aplicación e historial coinciden con la consulta remota (recuento y SHA-256).
- Correcta: 202 claves foráneas sin referencias huérfanas.
- Correcta: Huellas declaradas de importaciones confirmadas.
- Correcta: Expansión conserva todas las filas originales, Auth, Storage y artefactos.
- Correcta: Expansión idempotente sin cambiar fechas ni contenido.
- Correcta: Todas las completas heredadas conservadas.
- Correcta: Sin fechas de inicio inventadas.
- Correcta: Sin pertenencias inferidas ni carga automática del CSV.
- Correcta: Sin apertura anónima ni escritura directa de fichas.
- Correcta: Permisos y productor de ficha ejecutados sobre todas las obras.
- Correcta: recompute_all ejecutado y revertido sin alterar el origen.
- Correcta: Reversión aditiva conserva íntegramente la restauración.
- Correcta: Reaplicación tras revertir conserva el origen.
- Acceso real con rol authenticated y JWT para 24 perfiles restaurados: control global solo para gestores activos, completas de editores limitadas a sus encargos/revisiones.

## Funciones ejecutadas

- `public.auth_puede_ver_obra(o.obra_id)` sobre todas las obras.
- `public.auth_puede_editar_obra(o.obra_id)` sobre todas las obras.
- `public.auth_puede_consultar_importacion(o.obra_id)` sobre todas las obras.
- `public.can_view_obra_ficha_publica(o.obra_id,false)` sobre todas las obras.
- `public.get_obra_ficha_publica(o.obra_id,true)` sobre todas las obras.
- `recompute_all()` dentro de una transacción revertida; igualdad de huellas posterior.

## Diferencias entre instantes de copia y lectura remota

No se detectaron diferencias de recuento ni SHA-256 en las tablas comparadas.

## Alcance y límites

Se ha ensayado expansión, repetición, reversión y reaplicación sobre datos reales restaurados. No se ha adaptado la aplicación, no se ha cambiado la fuente autoritativa, no se han retirado columnas y no se ha renombrado el valor histórico persistido. Las políticas antiguas de producción no cambian. La futura migración coordinada necesita otra copia reciente y pruebas de sus lectores/escritores y roles.

Los originales, instantáneas, resultados completos y huellas de cada archivo permanecen en backups privado. El snapshot por obra complementa el volcado; no sustituye a las copias de importaciones ni Auth.
