# Dependencias del control de obras

Informe generado por `node scripts/control-obras/generar-dependencias.mjs <carpeta privada de copia>`.
Entradas: `inventario.json` de `inventariar.mjs` (Supabase enlazado, solo lectura) y los archivos actuales de `src/`, `scripts/` y `supabase/migrations/`. No editar a mano.

La búsqueda textual es conservadora: `estado` y `observaciones` pueden referirse a otras entidades. Las dependencias de catálogo no descubren todas las referencias dentro de PL/pgSQL ni SQL dinámico. Las migraciones aplicadas se inventarían, **no se editan**. No se incluyen valores de obras, cuentas, JWT ni definiciones privadas.

Auditoría de esquema: 2026-11-10T21:50:49.212Z. 207 archivos de código/pruebas/generadores candidatos, 48 funciones vivas candidatas y 58 políticas relacionadas.

## Campos afectados

| Campo trasladado o proyectado | Ubicación vigente | Archivos candidatos fuera del histórico SQL |
| --- | --- | ---: |
| `edicion` | fichas_completas.edicion_base | 31 |
| `editor_asignado` | fichas_completas.editor_asignado | 49 |
| `fecha_asignacion` | fichas_completas.fecha_asignacion | 1 |
| `estado` | fichas_completas.estado | 108 |
| `visible_publico` | fichas_completas.visible_publico | 37 |
| `fecha_cambio_estado` | fichas_completas.fecha_cambio_estado | 3 |
| `fecha_publicacion` | fichas_completas.fecha_publicacion | 3 |
| `autor_ficha_publico` | fichas_completas.autor_ficha_publico | 4 |
| `bibliografia` | fichas_completas.bibliografia | 30 |
| `observaciones` | fichas_completas.observaciones | 70 |
| `sin_figuras_donaire` | fichas_completas.sin_figuras_donaire | 12 |
| `sin_personajes_sobrenaturales` | fichas_completas.sin_personajes_sobrenaturales | 12 |
| `sin_eventos_sobrenaturales` | fichas_completas.sin_eventos_sobrenaturales | 12 |
| `tipo_ficha` | Proyección por existencia de importación y elaboración; basica en contratos nuevos | 29 |
| `fecha_inicio_trad` | obras_dataciones, clase referencia | 29 |
| `fecha_fin_trad` | obras_dataciones, clase referencia | 29 |
| `fuente_fecha` | obras_dataciones, clase referencia | 34 |
| `fecha_inicio_metadrama` | obras_dataciones, clase metrica | 9 |
| `fecha_fin_metadrama` | obras_dataciones, clase metrica | 9 |
| `dataciones` | Contrato tipado de obras_dataciones en proyecciones y artefactos | 24 |

## Código, pruebas y generadores

| Archivo | Campos mencionados |
| --- | --- |
| [scripts/analitica/extraer-aportaciones-local.sql](../../scripts/analitica/extraer-aportaciones-local.sql) | `dataciones`, `edicion`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `tipo_ficha` |
| [scripts/analitica/ensayar-precomputacion.mjs](../../scripts/analitica/ensayar-precomputacion.mjs) | `estado`, `tipo_ficha` |
| [src/routes/api/vocabularios/[id]/+server.ts](../../src/routes/api/vocabularios/[id]/+server.ts) | `bibliografia` |
| [scripts/test-editor-management.mjs](../../scripts/test-editor-management.mjs) | `editor_asignado`, `estado` |
| [scripts/test-editor-management-http.mjs](../../scripts/test-editor-management-http.mjs) | `editor_asignado` |
| [scripts/snapshot-obras.mjs](../../scripts/snapshot-obras.mjs) | `editor_asignado`, `estado` |
| [scripts/probar-prosa-local.mjs](../../scripts/probar-prosa-local.mjs) | `estado` |
| [scripts/migrar-berganza.mjs](../../scripts/migrar-berganza.mjs) | `editor_asignado`, `observaciones` |
| [src/routes/api/vocabularios/reordenar/+server.ts](../../src/routes/api/vocabularios/reordenar/+server.ts) | `bibliografia` |
| [src/routes/api/vocabularios/+server.ts](../../src/routes/api/vocabularios/+server.ts) | `bibliografia` |
| [scripts/auditoria-fuentes/lotes-pasada-c.mjs](../../scripts/auditoria-fuentes/lotes-pasada-c.mjs) | `estado` |
| [scripts/auditoria-fuentes/lotes-pasada-b.mjs](../../scripts/auditoria-fuentes/lotes-pasada-b.mjs) | `estado` |
| [scripts/auditoria-fuentes/hoja-correcciones.mjs](../../scripts/auditoria-fuentes/hoja-correcciones.mjs) | `estado`, `observaciones` |
| [scripts/auditoria-fuentes/estado-auditoria-fuentes.mjs](../../scripts/auditoria-fuentes/estado-auditoria-fuentes.mjs) | `estado` |
| [scripts/audit-anotaciones.mjs](../../scripts/audit-anotaciones.mjs) | `editor_asignado` |
| [scripts/aplicar-migracion.mjs](../../scripts/aplicar-migracion.mjs) | `editor_asignado`, `observaciones`, `visible_publico` |
| [scripts/aplicar-guiones.mjs](../../scripts/aplicar-guiones.mjs) | `bibliografia`, `edicion`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `visible_publico` |
| [scripts/importador-metrico/auditar-flujo-minimo.sql](../../scripts/importador-metrico/auditar-flujo-minimo.sql) | `editor_asignado`, `estado`, `fuente_fecha` |
| [scripts/guion-obras-de-prueba.mjs](../../scripts/guion-obras-de-prueba.mjs) | `estado`, `observaciones` |
| [scripts/importador-metrico/verificar-despliegue.mjs](../../scripts/importador-metrico/verificar-despliegue.mjs) | `estado`, `tipo_ficha`, `visible_publico` |
| [scripts/informe-equivalencias.mjs](../../scripts/informe-equivalencias.mjs) | `estado` |
| [scripts/informe-precomputacion.mjs](../../scripts/informe-precomputacion.mjs) | `estado` |
| [scripts/importador-metrico/generar-informes.mjs](../../scripts/importador-metrico/generar-informes.mjs) | `bibliografia`, `observaciones` |
| [scripts/importador-metrico/ensayar-promocion.mjs](../../scripts/importador-metrico/ensayar-promocion.mjs) | `tipo_ficha` |
| [scripts/importador-metrico/catalogo-piloto.sql](../../scripts/importador-metrico/catalogo-piloto.sql) | `estado` |
| [scripts/importador-metrico/probar-persistencia-local.mjs](../../scripts/importador-metrico/probar-persistencia-local.mjs) | `editor_asignado`, `estado`, `fuente_fecha`, `tipo_ficha`, `visible_publico` |
| [scripts/importador-metrico/revisar-piloto.mjs](../../scripts/importador-metrico/revisar-piloto.mjs) | `estado`, `fuente_fecha`, `observaciones` |
| [scripts/importador-metrico/preparar-piloto.mjs](../../scripts/importador-metrico/preparar-piloto.mjs) | `fuente_fecha` |
| [scripts/importador-metrico/normalizar-piloto.mjs](../../scripts/importador-metrico/normalizar-piloto.mjs) | `bibliografia`, `estado`, `observaciones` |
| [scripts/importador-metrico/sql/06-gestion.sql](../../scripts/importador-metrico/sql/06-gestion.sql) | `editor_asignado`, `tipo_ficha` |
| [scripts/importador-metrico/sql/05-aislamiento.sql](../../scripts/importador-metrico/sql/05-aislamiento.sql) | `editor_asignado`, `tipo_ficha` |
| [scripts/importador-metrico/sql/04-consulta.sql](../../scripts/importador-metrico/sql/04-consulta.sql) | `tipo_ficha` |
| [scripts/importador-metrico/sql/03-guardar.sql](../../scripts/importador-metrico/sql/03-guardar.sql) | `edicion`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `tipo_ficha`, `visible_publico` |
| [scripts/importador-metrico/sql/02-esquema-documento.sql](../../scripts/importador-metrico/sql/02-esquema-documento.sql) | `fuente_fecha`, `observaciones` |
| [scripts/importador-metrico/sql/01-almacenamiento.sql](../../scripts/importador-metrico/sql/01-almacenamiento.sql) | `editor_asignado`, `estado`, `tipo_ficha`, `visible_publico` |
| [scripts/importador-metrico/promocion/importador-basico.sql](../../scripts/importador-metrico/promocion/importador-basico.sql) | `edicion`, `editor_asignado`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `tipo_ficha`, `visible_publico` |
| [src/lib/autores/perfil-autor.ts](../../src/lib/autores/perfil-autor.ts) | `dataciones`, `fecha_fin_trad`, `fecha_inicio_trad`, `visible_publico` |
| [scripts/catalogo/pie-quebrado-pruebas.sql](../../scripts/catalogo/pie-quebrado-pruebas.sql) | `observaciones` |
| [scripts/lib/migracion/resoluciones.test.mjs](../../scripts/lib/migracion/resoluciones.test.mjs) | `observaciones` |
| [scripts/lib/migracion/modelo.mjs](../../scripts/lib/migracion/modelo.mjs) | `observaciones` |
| [scripts/lib/migracion/markdown.mjs](../../scripts/lib/migracion/markdown.mjs) | `estado` |
| [scripts/lib/migracion/excel.mjs](../../scripts/lib/migracion/excel.mjs) | `estado` |
| [scripts/lib/migracion/datos.mjs](../../scripts/lib/migracion/datos.mjs) | `editor_asignado`, `estado` |
| [scripts/lib/migracion/aplicador.mjs](../../scripts/lib/migracion/aplicador.mjs) | `observaciones` |
| [scripts/lib/importador-metrico/validacion.test.mjs](../../scripts/lib/importador-metrico/validacion.test.mjs) | `fuente_fecha`, `observaciones` |
| [scripts/lib/importador-metrico/validacion.mjs](../../scripts/lib/importador-metrico/validacion.mjs) | `fuente_fecha`, `observaciones` |
| [scripts/lib/importador-metrico/rutas.mjs](../../scripts/lib/importador-metrico/rutas.mjs) | `bibliografia` |
| [scripts/lib/importador-metrico/normalizacion.test.mjs](../../scripts/lib/importador-metrico/normalizacion.test.mjs) | `bibliografia`, `estado` |
| [scripts/lib/importador-metrico/normalizacion.mjs](../../scripts/lib/importador-metrico/normalizacion.mjs) | `bibliografia`, `estado`, `fuente_fecha` |
| [scripts/lib/importador-metrico/informes.test.mjs](../../scripts/lib/importador-metrico/informes.test.mjs) | `observaciones` |
| [scripts/lib/importador-metrico/informes.mjs](../../scripts/lib/importador-metrico/informes.mjs) | `estado`, `observaciones` |
| [scripts/lib/importador-metrico/ficha-minima.test.mjs](../../scripts/lib/importador-metrico/ficha-minima.test.mjs) | `editor_asignado`, `estado`, `fuente_fecha`, `visible_publico` |
| [scripts/lib/importador-metrico/ficha-minima.mjs](../../scripts/lib/importador-metrico/ficha-minima.mjs) | `estado`, `fuente_fecha`, `observaciones` |
| [scripts/lib/importador-metrico/evaluacion-modelos.mjs](../../scripts/lib/importador-metrico/evaluacion-modelos.mjs) | `fuente_fecha`, `observaciones` |
| [scripts/lib/importador-metrico/completar-extraccion.mjs](../../scripts/lib/importador-metrico/completar-extraccion.mjs) | `fuente_fecha`, `observaciones` |
| [src/lib/utils/editor-management.ts](../../src/lib/utils/editor-management.ts) | `editor_asignado` |
| [src/lib/utils/editor-management.test.ts](../../src/lib/utils/editor-management.test.ts) | `editor_asignado` |
| [src/lib/utils/comment-links.test.ts](../../src/lib/utils/comment-links.test.ts) | `observaciones` |
| [src/lib/utils/validators.ts](../../src/lib/utils/validators.ts) | `bibliografia`, `dataciones`, `edicion`, `editor_asignado`, `estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `visible_publico` |
| [src/lib/utils/validators.test.ts](../../src/lib/utils/validators.test.ts) | `bibliografia`, `dataciones`, `edicion`, `editor_asignado`, `estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `visible_publico` |
| [src/lib/utils/revision-checklist.ts](../../src/lib/utils/revision-checklist.ts) | `bibliografia`, `edicion`, `editor_asignado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones` |
| [src/lib/utils/revision-checklist.test.ts](../../src/lib/utils/revision-checklist.test.ts) | `bibliografia`, `edicion`, `editor_asignado`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones` |
| [src/lib/utils/permissions.ts](../../src/lib/utils/permissions.ts) | `estado` |
| [src/lib/utils/permissions.test.ts](../../src/lib/utils/permissions.test.ts) | `estado` |
| [src/lib/utils/generos-intervinientes.ts](../../src/lib/utils/generos-intervinientes.ts) | `estado` |
| [src/lib/utils/generos-intervinientes.test.ts](../../src/lib/utils/generos-intervinientes.test.ts) | `estado` |
| [scripts/lib/analitica/aportaciones.test.mjs](../../scripts/lib/analitica/aportaciones.test.mjs) | `dataciones` |
| [scripts/lib/analitica/aportaciones.mjs](../../scripts/lib/analitica/aportaciones.mjs) | `dataciones`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha` |
| [src/lib/importador-metrico/types.ts](../../src/lib/importador-metrico/types.ts) | `estado`, `fuente_fecha`, `observaciones` |
| [src/lib/importador-metrico/tipo-ficha.ts](../../src/lib/importador-metrico/tipo-ficha.ts) | `tipo_ficha` |
| [src/lib/importador-metrico/prosa.test.ts](../../src/lib/importador-metrico/prosa.test.ts) | `edicion` |
| [src/lib/importador-metrico/longitud.ts](../../src/lib/importador-metrico/longitud.ts) | `estado` |
| [src/lib/importador-metrico/longitud.test.ts](../../src/lib/importador-metrico/longitud.test.ts) | `estado` |
| [src/lib/importador-metrico/edicion.test.ts](../../src/lib/importador-metrico/edicion.test.ts) | `edicion` |
| [src/lib/importador-metrico/division-nota.test.ts](../../src/lib/importador-metrico/division-nota.test.ts) | `estado` |
| [src/routes/api/datos-publicos/recompute-all/+server.ts](../../src/routes/api/datos-publicos/recompute-all/+server.ts) | `estado` |
| [src/lib/types/public-ficha.types.ts](../../src/lib/types/public-ficha.types.ts) | `autor_ficha_publico`, `bibliografia`, `dataciones`, `edicion`, `fecha_fin_trad`, `fecha_inicio_trad`, `fecha_publicacion`, `fuente_fecha`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `visible_publico` |
| [src/lib/types/public-artifacts.types.ts](../../src/lib/types/public-artifacts.types.ts) | `dataciones`, `estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `visible_publico` |
| [src/lib/types/obra.types.ts](../../src/lib/types/obra.types.ts) | `bibliografia`, `edicion`, `editor_asignado`, `estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `visible_publico` |
| [src/lib/types/obra-editorial.types.ts](../../src/lib/types/obra-editorial.types.ts) | `dataciones`, `estado`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `tipo_ficha`, `visible_publico` |
| [src/lib/types/editor-management.types.ts](../../src/lib/types/editor-management.types.ts) | `editor_asignado` |
| [src/lib/types/database.types.ts](../../src/lib/types/database.types.ts) | `autor_ficha_publico`, `bibliografia`, `dataciones`, `edicion`, `editor_asignado`, `estado`, `fecha_asignacion`, `fecha_cambio_estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fecha_publicacion`, `fuente_fecha`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `tipo_ficha`, `visible_publico` |
| [src/lib/types/dashboard-guide.types.ts](../../src/lib/types/dashboard-guide.types.ts) | `edicion` |
| [src/lib/types/control-obras.types.ts](../../src/lib/types/control-obras.types.ts) | `dataciones`, `editor_asignado`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `tipo_ficha`, `visible_publico` |
| [src/routes/api/obras/[id]/visibilidad/+server.ts](../../src/routes/api/obras/[id]/visibilidad/+server.ts) | `estado`, `visible_publico` |
| [src/lib/stores/currentObra.ts](../../src/lib/stores/currentObra.ts) | `observaciones` |
| [src/lib/metrica/phenomena-index.ts](../../src/lib/metrica/phenomena-index.ts) | `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales` |
| [src/lib/metrica/phenomena-index.test.ts](../../src/lib/metrica/phenomena-index.test.ts) | `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales` |
| [src/lib/metrica/esquema-rima-escrito.ts](../../src/lib/metrica/esquema-rima-escrito.ts) | `estado`, `observaciones` |
| [src/lib/metrica/esquema-rima-escrito.test.ts](../../src/lib/metrica/esquema-rima-escrito.test.ts) | `estado` |
| [src/lib/demarcador-metrico/recorridos.test.ts](../../src/lib/demarcador-metrico/recorridos.test.ts) | `estado`, `observaciones` |
| [src/lib/demarcador-metrico/motor.ts](../../src/lib/demarcador-metrico/motor.ts) | `estado` |
| [src/lib/demarcador-metrico/modelo.ts](../../src/lib/demarcador-metrico/modelo.ts) | `estado` |
| [src/routes/(dashboard)/dashboard/vocabularios/[categoria]/+page.svelte](../../src/routes/(dashboard)/dashboard/vocabularios/[categoria]/+page.svelte) | `bibliografia` |
| [src/routes/(dashboard)/dashboard/vocabularios/[categoria]/+page.server.ts](../../src/routes/(dashboard)/dashboard/vocabularios/[categoria]/+page.server.ts) | `bibliografia` |
| [src/routes/(public)/laboratorio/+page.svelte](../../src/routes/(public)/laboratorio/+page.svelte) | `dataciones` |
| [src/lib/secciones-publicas.ts](../../src/lib/secciones-publicas.ts) | `bibliografia`, `estado`, `observaciones`, `visible_publico` |
| [src/routes/(public)/autores/[slug]/+page.svelte](../../src/routes/(public)/autores/[slug]/+page.svelte) | `dataciones` |
| [src/routes/(public)/recursos/demarcador/+page.svelte](../../src/routes/(public)/recursos/demarcador/+page.svelte) | `estado`, `observaciones` |
| [src/lib/server/public-obras.ts](../../src/lib/server/public-obras.ts) | `editor_asignado`, `estado`, `visible_publico` |
| [src/lib/server/public-obras.test.ts](../../src/lib/server/public-obras.test.ts) | `editor_asignado`, `visible_publico` |
| [src/lib/server/obras.ts](../../src/lib/server/obras.ts) | `bibliografia`, `edicion`, `estado`, `observaciones` |
| [src/lib/server/modelo-obras.ts](../../src/lib/server/modelo-obras.ts) | `estado` |
| [src/lib/server/migracion-informes.ts](../../src/lib/server/migracion-informes.ts) | `editor_asignado` |
| [src/lib/server/dashboard-basicas.test.ts](../../src/lib/server/dashboard-basicas.test.ts) | `editor_asignado`, `estado`, `tipo_ficha` |
| [src/lib/server/create-obras.ts](../../src/lib/server/create-obras.ts) | `editor_asignado`, `estado`, `tipo_ficha` |
| [src/lib/server/comentarios.ts](../../src/lib/server/comentarios.ts) | `estado`, `observaciones` |
| [src/lib/server/comentarios.test.ts](../../src/lib/server/comentarios.test.ts) | `estado` |
| [src/lib/server/caracterizaciones-rango-api.test.ts](../../src/lib/server/caracterizaciones-rango-api.test.ts) | `observaciones` |
| [src/lib/server/auth.ts](../../src/lib/server/auth.ts) | `editor_asignado`, `estado`, `tipo_ficha` |
| [src/lib/server/auth.test.ts](../../src/lib/server/auth.test.ts) | `editor_asignado`, `estado`, `tipo_ficha` |
| [src/lib/server/editor-management.test.ts](../../src/lib/server/editor-management.test.ts) | `editor_asignado`, `estado` |
| [src/lib/server/dashboard.ts](../../src/lib/server/dashboard.ts) | `editor_asignado`, `estado`, `fecha_cambio_estado`, `observaciones`, `tipo_ficha` |
| [src/lib/server/ficha-secciones.ts](../../src/lib/server/ficha-secciones.ts) | `bibliografia`, `observaciones` |
| [src/lib/server/ficha-secciones.test.ts](../../src/lib/server/ficha-secciones.test.ts) | `autor_ficha_publico`, `bibliografia`, `edicion`, `fecha_fin_trad`, `fecha_inicio_trad`, `fuente_fecha`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `visible_publico` |
| [src/lib/server/editor-management.ts](../../src/lib/server/editor-management.ts) | `editor_asignado`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `tipo_ficha`, `visible_publico` |
| [src/routes/api/dashboard/activity/mark-seen/+server.ts](../../src/routes/api/dashboard/activity/mark-seen/+server.ts) | `estado` |
| [src/routes/(dashboard)/dashboard/publicacion/+page.server.ts](../../src/routes/(dashboard)/dashboard/publicacion/+page.server.ts) | `estado` |
| [src/lib/server/importador-metrico/vista-previa.ts](../../src/lib/server/importador-metrico/vista-previa.ts) | `bibliografia`, `edicion`, `estado`, `fuente_fecha`, `observaciones` |
| [src/lib/server/importador-metrico/vista-previa.test.ts](../../src/lib/server/importador-metrico/vista-previa.test.ts) | `edicion`, `estado`, `fuente_fecha` |
| [src/lib/server/importador-metrico/persistencia.ts](../../src/lib/server/importador-metrico/persistencia.ts) | `tipo_ficha` |
| [src/lib/server/importador-metrico/persistencia.test.ts](../../src/lib/server/importador-metrico/persistencia.test.ts) | `tipo_ficha` |
| [scripts/lib/metrica/realizaciones.mjs](../../scripts/lib/metrica/realizaciones.mjs) | `observaciones` |
| [src/routes/api/obras/+server.ts](../../src/routes/api/obras/+server.ts) | `editor_asignado`, `estado` |
| [src/routes/(public)/obras/[slug]/+page.svelte](../../src/routes/(public)/obras/[slug]/+page.svelte) | `autor_ficha_publico`, `bibliografia`, `dataciones`, `edicion`, `estado`, `fecha_publicacion`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales`, `visible_publico` |
| [src/routes/(public)/obras/[slug]/+page.server.ts](../../src/routes/(public)/obras/[slug]/+page.server.ts) | `editor_asignado`, `estado`, `visible_publico` |
| [src/routes/api/obras/[id]/datos/+server.ts](../../src/routes/api/obras/[id]/datos/+server.ts) | `dataciones`, `edicion`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha` |
| [src/routes/api/obras/lote/+server.ts](../../src/routes/api/obras/lote/+server.ts) | `editor_asignado` |
| [src/lib/dataciones.ts](../../src/lib/dataciones.ts) | `dataciones`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha` |
| [src/lib/dataciones.test.ts](../../src/lib/dataciones.test.ts) | `dataciones`, `fecha_fin_trad`, `fecha_inicio_trad` |
| [src/routes/api/metrica/anotacion/server.test.ts](../../src/routes/api/metrica/anotacion/server.test.ts) | `observaciones` |
| [src/routes/api/importador/correspondencias/server.test.ts](../../src/routes/api/importador/correspondencias/server.test.ts) | `edicion` |
| [src/routes/api/metrica/anotacion/+server.ts](../../src/routes/api/metrica/anotacion/+server.ts) | `observaciones` |
| [src/routes/api/importador/correspondencias/+server.ts](../../src/routes/api/importador/correspondencias/+server.ts) | `edicion` |
| [src/routes/(public)/obras/listado/+page.svelte](../../src/routes/(public)/obras/listado/+page.svelte) | `fecha_fin_trad`, `fecha_inicio_trad`, `visible_publico` |
| [src/routes/(public)/obras/listado/+page.server.ts](../../src/routes/(public)/obras/listado/+page.server.ts) | `editor_asignado`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `visible_publico` |
| [src/routes/(public)/obras/+page.server.ts](../../src/routes/(public)/obras/+page.server.ts) | `editor_asignado`, `estado`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `visible_publico` |
| [src/routes/api/obras/[id]/publicar-datos/+server.ts](../../src/routes/api/obras/[id]/publicar-datos/+server.ts) | `estado` |
| [src/routes/api/obras/[id]/comentarios/+server.ts](../../src/routes/api/obras/[id]/comentarios/+server.ts) | `estado`, `visible_publico` |
| [src/routes/api/obras/[id]/secuencias/[secuenciaId]/caracterizaciones/+server.ts](../../src/routes/api/obras/[id]/secuencias/[secuenciaId]/caracterizaciones/+server.ts) | `observaciones` |
| [src/routes/(dashboard)/dashboard/obras/[id]/+page.svelte](../../src/routes/(dashboard)/dashboard/obras/[id]/+page.svelte) | `bibliografia`, `editor_asignado`, `estado`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales` |
| [src/routes/(dashboard)/dashboard/obras/[id]/+page.server.ts](../../src/routes/(dashboard)/dashboard/obras/[id]/+page.server.ts) | `editor_asignado`, `estado` |
| [src/routes/(dashboard)/dashboard/obras/+page.svelte](../../src/routes/(dashboard)/dashboard/obras/+page.svelte) | `dataciones`, `editor_asignado`, `estado`, `tipo_ficha` |
| [src/routes/(dashboard)/dashboard/obras/+page.server.ts](../../src/routes/(dashboard)/dashboard/obras/+page.server.ts) | `dataciones`, `editor_asignado`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `tipo_ficha`, `visible_publico` |
| [src/routes/api/obras/[id]/observaciones/+server.ts](../../src/routes/api/obras/[id]/observaciones/+server.ts) | `bibliografia`, `observaciones` |
| [src/routes/api/obras/[id]/secuencias/[secuenciaId]/caracterizaciones/[caracterizacionId]/+server.ts](../../src/routes/api/obras/[id]/secuencias/[secuenciaId]/caracterizaciones/[caracterizacionId]/+server.ts) | `observaciones` |
| [src/lib/components/vocabularios/VocabularyDetailPanel.svelte](../../src/lib/components/vocabularios/VocabularyDetailPanel.svelte) | `bibliografia` |
| [src/lib/components/vocabularios/useVocabularyTree.ts](../../src/lib/components/vocabularios/useVocabularyTree.ts) | `bibliografia` |
| [src/lib/components/vocabularios/useVocabularyTree.test.ts](../../src/lib/components/vocabularios/useVocabularyTree.test.ts) | `bibliografia` |
| [src/lib/config/vocabulary-fields.ts](../../src/lib/config/vocabulary-fields.ts) | `estado` |
| [src/routes/(dashboard)/dashboard/notificaciones/+page.svelte](../../src/routes/(dashboard)/dashboard/notificaciones/+page.svelte) | `estado` |
| [src/routes/api/obras/[id]/comentarios/[comentarioId]/+server.ts](../../src/routes/api/obras/[id]/comentarios/[comentarioId]/+server.ts) | `estado`, `visible_publico` |
| [src/routes/api/obras/[id]/estado/+server.ts](../../src/routes/api/obras/[id]/estado/+server.ts) | `estado`, `fecha_cambio_estado` |
| [src/lib/content/dashboard-guide/index.ts](../../src/lib/content/dashboard-guide/index.ts) | `edicion`, `estado`, `observaciones` |
| [src/routes/api/obras/[id]/revisores/+server.ts](../../src/routes/api/obras/[id]/revisores/+server.ts) | `editor_asignado` |
| [src/routes/api/obras/[id]/declaraciones/+server.ts](../../src/routes/api/obras/[id]/declaraciones/+server.ts) | `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales` |
| [src/routes/api/obras/[id]/comentarios/[comentarioId]/publicacion/+server.ts](../../src/routes/api/obras/[id]/comentarios/[comentarioId]/publicacion/+server.ts) | `estado`, `visible_publico` |
| [src/lib/components/public/PublicPageHeader.svelte](../../src/lib/components/public/PublicPageHeader.svelte) | `estado` |
| [src/routes/(dashboard)/dashboard/importador/server.test.ts](../../src/routes/(dashboard)/dashboard/importador/server.test.ts) | `edicion`, `fuente_fecha` |
| [src/routes/(dashboard)/dashboard/importador/page.server.test.ts](../../src/routes/(dashboard)/dashboard/importador/page.server.test.ts) | `tipo_ficha` |
| [src/lib/components/metrica/metric-distribution.test.ts](../../src/lib/components/metrica/metric-distribution.test.ts) | `observaciones` |
| [src/routes/(dashboard)/dashboard/importador/+page.server.ts](../../src/routes/(dashboard)/dashboard/importador/+page.server.ts) | `fuente_fecha`, `tipo_ficha` |
| [src/routes/(dashboard)/dashboard/importador/+page.svelte](../../src/routes/(dashboard)/dashboard/importador/+page.svelte) | `edicion`, `fuente_fecha`, `tipo_ficha` |
| [src/routes/(dashboard)/dashboard/editores/[id]/+page.svelte](../../src/routes/(dashboard)/dashboard/editores/[id]/+page.svelte) | `editor_asignado`, `estado` |
| [src/routes/(dashboard)/dashboard/editores/[id]/+page.server.ts](../../src/routes/(dashboard)/dashboard/editores/[id]/+page.server.ts) | `editor_asignado`, `estado` |
| [src/lib/components/metrica/editor-v2/structure-coverage.test.ts](../../src/lib/components/metrica/editor-v2/structure-coverage.test.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/structural-additions.test.ts](../../src/lib/components/metrica/editor-v2/structural-additions.test.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/sequence-draft.ts](../../src/lib/components/metrica/editor-v2/sequence-draft.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/reparto-estancia.ts](../../src/lib/components/metrica/editor-v2/reparto-estancia.ts) | `estado`, `observaciones` |
| [src/lib/components/metrica/editor-v2/reparto-estancia.test.ts](../../src/lib/components/metrica/editor-v2/reparto-estancia.test.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/proposed-unit-answers.test.ts](../../src/lib/components/metrica/editor-v2/proposed-unit-answers.test.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/norm-summary.ts](../../src/lib/components/metrica/editor-v2/norm-summary.ts) | `estado` |
| [src/lib/components/metrica/editor-v2/norm-summary.test.ts](../../src/lib/components/metrica/editor-v2/norm-summary.test.ts) | `estado` |
| [src/lib/components/metrica/editor-v2/MetricStructureEditor.svelte](../../src/lib/components/metrica/editor-v2/MetricStructureEditor.svelte) | `estado`, `observaciones` |
| [src/lib/components/metrica/editor-v2/MetricSequenceEditor.svelte](../../src/lib/components/metrica/editor-v2/MetricSequenceEditor.svelte) | `estado`, `observaciones` |
| [src/lib/components/metrica/editor-v2/MetricPanelSection.svelte](../../src/lib/components/metrica/editor-v2/MetricPanelSection.svelte) | `estado` |
| [src/lib/components/metrica/editor-v2/MetricNormSummary.svelte](../../src/lib/components/metrica/editor-v2/MetricNormSummary.svelte) | `estado` |
| [src/lib/components/metrica/editor-v2/MetricFamilyControl.svelte](../../src/lib/components/metrica/editor-v2/MetricFamilyControl.svelte) | `estado` |
| [src/lib/components/metrica/editor-v2/MetricChoiceField.svelte](../../src/lib/components/metrica/editor-v2/MetricChoiceField.svelte) | `estado` |
| [src/lib/components/metrica/editor-v2/grid-rows.test.ts](../../src/lib/components/metrica/editor-v2/grid-rows.test.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/editor-model.ts](../../src/lib/components/metrica/editor-v2/editor-model.ts) | `observaciones` |
| [src/lib/components/metrica/editor-v2/editor-model.test.ts](../../src/lib/components/metrica/editor-v2/editor-model.test.ts) | `observaciones` |
| [src/routes/(dashboard)/dashboard/metrica/maqueta/Norma.svelte](../../src/routes/(dashboard)/dashboard/metrica/maqueta/Norma.svelte) | `estado` |
| [src/routes/(dashboard)/dashboard/metrica/maqueta/escenarios.ts](../../src/routes/(dashboard)/dashboard/metrica/maqueta/escenarios.ts) | `estado` |
| [src/lib/catalogo/catalog-filters.ts](../../src/lib/catalogo/catalog-filters.ts) | `dataciones`, `fecha_fin_trad`, `fecha_inicio_trad` |
| [src/lib/catalogo/catalog-filters.test.ts](../../src/lib/catalogo/catalog-filters.test.ts) | `fecha_fin_trad`, `fecha_inicio_trad` |
| [src/lib/components/demarcador/DemarcadorResultCard.svelte](../../src/lib/components/demarcador/DemarcadorResultCard.svelte) | `estado` |
| [src/lib/components/editor/SecuenciasTab.svelte](../../src/lib/components/editor/SecuenciasTab.svelte) | `estado`, `observaciones`, `sin_eventos_sobrenaturales`, `sin_figuras_donaire`, `sin_personajes_sobrenaturales` |
| [src/lib/components/editor/InternalCommentsPanel.svelte](../../src/lib/components/editor/InternalCommentsPanel.svelte) | `visible_publico` |
| [src/lib/components/editor/InternalCommentsFeed.svelte](../../src/lib/components/editor/InternalCommentsFeed.svelte) | `estado`, `visible_publico` |
| [src/lib/components/editor/DatosObraTab.svelte](../../src/lib/components/editor/DatosObraTab.svelte) | `dataciones`, `edicion`, `fecha_fin_metadrama`, `fecha_fin_trad`, `fecha_inicio_metadrama`, `fecha_inicio_trad`, `fuente_fecha` |
| [src/lib/components/editor/DatacionEditor.svelte](../../src/lib/components/editor/DatacionEditor.svelte) | `dataciones` |
| [src/lib/components/editor/ObservacionesTab.svelte](../../src/lib/components/editor/ObservacionesTab.svelte) | `bibliografia`, `observaciones` |
| [src/lib/components/editor/RevisionTab.svelte](../../src/lib/components/editor/RevisionTab.svelte) | `editor_asignado`, `estado`, `visible_publico` |
| [src/lib/components/catalogo/CatalogResultRow.svelte](../../src/lib/components/catalogo/CatalogResultRow.svelte) | `dataciones`, `fecha_fin_trad`, `fecha_inicio_trad`, `visible_publico` |
| [src/lib/components/ficha/SequenceDetailModal.svelte](../../src/lib/components/ficha/SequenceDetailModal.svelte) | `observaciones` |
| [src/lib/components/ficha/observaciones-publicas.test.ts](../../src/lib/components/ficha/observaciones-publicas.test.ts) | `observaciones` |
| [src/lib/components/ficha/FichaObservaciones.svelte](../../src/lib/components/ficha/FichaObservaciones.svelte) | `observaciones` |
| [src/lib/components/importador-metrico/CorrespondenciaEditorial.svelte](../../src/lib/components/importador-metrico/CorrespondenciaEditorial.svelte) | `edicion` |
| [src/lib/components/importador-metrico/EditorSecuencia.svelte](../../src/lib/components/importador-metrico/EditorSecuencia.svelte) | `edicion`, `estado` |
| [src/lib/components/importador-metrico/DatosSecuencia.svelte](../../src/lib/components/importador-metrico/DatosSecuencia.svelte) | `edicion` |
| [src/lib/components/importador-metrico/VistaPrevia.svelte](../../src/lib/components/importador-metrico/VistaPrevia.svelte) | `edicion`, `estado` |
| [src/lib/components/importador-metrico/EstadoComprobacion.test.ts](../../src/lib/components/importador-metrico/EstadoComprobacion.test.ts) | `edicion` |
| [src/lib/components/editor/secuencias/CaracterizacionesPorRango.svelte](../../src/lib/components/editor/secuencias/CaracterizacionesPorRango.svelte) | `observaciones` |
| [src/lib/components/dashboard/ObrasTable.svelte](../../src/lib/components/dashboard/ObrasTable.svelte) | `dataciones`, `estado`, `fecha_fin_trad`, `fecha_inicio_trad`, `tipo_ficha`, `visible_publico` |
| [src/lib/components/dashboard/CreateWorksForm.svelte](../../src/lib/components/dashboard/CreateWorksForm.svelte) | `editor_asignado` |
| [src/lib/components/dashboard/BulkAssignments.svelte](../../src/lib/components/dashboard/BulkAssignments.svelte) | `editor_asignado` |

## Funciones de la base viva

| Firma | Campos mencionados | Security definer |
| --- | --- | --- |
| `sync_obra_autor_ficha_publico()` | autor_ficha_publico, editor_asignado | Sí |
| `recompute_autor_resumen(uuid)` | estado, visible_publico | Sí |
| `obras_enforce_public_visibility()` | estado, visible_publico | Sí |
| `obra_declara_por_sus_secuencias()` | sin_eventos_sobrenaturales, sin_figuras_donaire, sin_personajes_sobrenaturales | No |
| `recompute_all()` | estado | Sí |
| `corpus_comparativas_artefacto_json(text)` | dataciones, estado, fecha_fin_metadrama, fecha_fin_trad, fecha_inicio_metadrama, fecha_inicio_trad, visible_publico | Sí |
| `esquema_extraccion_minima()` | fuente_fecha, observaciones | No |
| `esquema_documento_minimo()` | fuente_fecha, observaciones | No |
| `eliminar_ficha_basica(uuid,text)` | editor_asignado, tipo_ficha | Sí |
| `ficha_publica_dominio_json(uuid,boolean)` | observaciones, tipo_ficha | Sí |
| `get_portada_publica(uuid)` | fecha_fin_trad, fecha_inicio_trad | No |
| `get_equipo_publico()` | editor_asignado, visible_publico | Sí |
| `recompute_obra_resumen_metricas(uuid)` | tipo_ficha | Sí |
| `mark_autores_resumen_dirty_on_obra()` | estado, visible_publico | Sí |
| `get_autor_publico(text)` | dataciones, estado, fecha_fin_trad, fecha_inicio_trad, visible_publico | Sí |
| `get_obra_comentarios_publicos(uuid,boolean)` | visible_publico | Sí |
| `auth_puede_editar_obra(uuid)` | editor_asignado | Sí |
| `auth_puede_ver_obra(uuid)` | editor_asignado | Sí |
| `mark_obra_resumen_dirty_by_editor_asignado()` | editor_asignado | Sí |
| `obra_recuerda_su_publicacion()` | estado, fecha_publicacion | No |
| `sync_editor_identity_in_public_summaries()` | autor_ficha_publico, editor_asignado | Sí |
| `ficha_publica_json(uuid,boolean)` | fecha_publicacion, sin_eventos_sobrenaturales, sin_figuras_donaire, sin_personajes_sobrenaturales | Sí |
| `auth_puede_consultar_importacion(uuid)` | editor_asignado | Sí |
| `auth_respeta_limite_minima(uuid)` | tipo_ficha | Sí |
| `coincidencias_importacion_metrica(text)` | tipo_ficha | Sí |
| `listar_fichas_basicas(integer)` | tipo_ficha | Sí |
| `gestionar_asignaciones_lote(text,uuid,jsonb)` | editor_asignado, tipo_ficha | Sí |
| `get_autores_listado_publico()` | estado, visible_publico | Sí |
| `can_view_obra_ficha_publica(uuid,boolean)` | editor_asignado, estado, visible_publico | Sí |
| `plan_recompute_datos_publicos()` | estado | Sí |
| `guardar_anotacion_metrica(jsonb)` | observaciones | Sí |
| `analisis_obra_publico_json(uuid)` | tipo_ficha | Sí |
| `secuencia_respeta_lo_declarado_en_la_obra()` | sin_eventos_sobrenaturales, sin_figuras_donaire, sin_personajes_sobrenaturales | No |
| `obra_publica_visible(uuid)` | estado, visible_publico | Sí |
| `obra_publicada_asignada(uuid,uuid)` | editor_asignado, estado | Sí |
| `recompute_obra_resumen_estructura(uuid)` | tipo_ficha | Sí |
| `finalizar_recompute_datos_publicos()` | estado | Sí |
| `recompute_artefactos_obra(uuid)` | tipo_ficha | Sí |
| `trasladar_observaciones_a_comentarios(uuid[],uuid)` | editor_asignado, observaciones, visible_publico | No |
| `impedir_v2_en_basica()` | tipo_ficha | No |
| `perfil_artefacto_obra_rango(uuid,integer,integer,text)` | tipo_ficha | Sí |
| `escribir_obra_editorial()` | autor_ficha_publico, bibliografia, dataciones, edicion, editor_asignado, estado, fecha_asignacion, fecha_cambio_estado, fecha_fin_metadrama, fecha_fin_trad, fecha_inicio_metadrama, fecha_inicio_trad, fuente_fecha, observaciones, sin_eventos_sobrenaturales, sin_figuras_donaire, sin_personajes_sobrenaturales, tipo_ficha, visible_publico | Sí |
| `guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid)` | edicion, estado, fecha_fin_trad, fecha_inicio_trad, fuente_fecha, observaciones, tipo_ficha, visible_publico | Sí |
| `iniciar_ficha_completa(uuid,uuid,boolean)` | editor_asignado, estado, fecha_asignacion | Sí |
| `destino_importacion_metrica(uuid)` | tipo_ficha | Sí |
| `autor_ficha_artefacto_json(uuid,text)` | dataciones, estado, fecha_fin_trad, fecha_inicio_trad, visible_publico | Sí |
| `ficha_publica_base_json(uuid,boolean)` | autor_ficha_publico, bibliografia, dataciones, edicion, editor_asignado, fecha_fin_trad, fecha_inicio_trad, fuente_fecha, observaciones, tipo_ficha, visible_publico | Sí |
| `recompute_artefactos_globales()` | dataciones, estado, fecha_fin_metadrama, fecha_fin_trad, fecha_inicio_metadrama, fecha_inicio_trad, visible_publico | Sí |

## Triggers de obras

- `trg_set_obras_slug`: `CREATE TRIGGER trg_set_obras_slug BEFORE INSERT OR UPDATE OF titulo, slug ON public.obras FOR EACH ROW EXECUTE FUNCTION set_obras_slug()`
- `trigger_obras_updated_at`: `CREATE TRIGGER trigger_obras_updated_at BEFORE UPDATE ON public.obras FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at()`

## Referencias a obras

- `jornadas.jornadas_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `secuencias_metricas.secuencias_metricas_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `grupos_atribucion.grupos_atribucion_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `comentarios_internos.comentarios_internos_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `obras_resumen.obras_resumen_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `atribuciones.atribuciones_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `importaciones_metricas.importaciones_metricas_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `migracion_secuencias.migracion_secuencias_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON UPDATE CASCADE ON DELETE CASCADE`
- `traslados_observaciones_caracterizacion.traslados_observaciones_caracterizacion_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `fichas_completas.fichas_completas_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `obras_corpus.obras_corpus_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `obras_dataciones.obras_dataciones_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`
- `asignaciones_historial.asignaciones_historial_obra_id_fkey`: `FOREIGN KEY (obra_id) REFERENCES obras(obra_id) ON DELETE CASCADE`

## Políticas relacionadas

| Tabla | Política | Operación |
| --- | --- | --- |
| obras_revisores | obras_revisores_delete | DELETE |
| obras_revisores | obras_revisores_insert | INSERT |
| obras_revisores | obras_revisores_select | SELECT |
| obras_revisores | obras_revisores_update | UPDATE |
| grupos_atribucion | grupos_atribucion_delete_authenticated | DELETE |
| grupos_atribucion | grupos_atribucion_insert_authenticated | INSERT |
| grupos_atribucion | grupos_atribucion_select_authenticated | SELECT |
| grupos_atribucion | grupos_atribucion_update_authenticated | UPDATE |
| atribucion_evidencias | atribucion_evidencias_delete_authenticated | DELETE |
| atribucion_evidencias | atribucion_evidencias_insert_authenticated | INSERT |
| atribucion_evidencias | atribucion_evidencias_select_authenticated | SELECT |
| atribucion_evidencias | atribucion_evidencias_update_authenticated | UPDATE |
| secuencias_caracterizaciones_rango | secuencias_caracterizaciones_rango_delete_authenticated | DELETE |
| secuencias_caracterizaciones_rango | secuencias_caracterizaciones_rango_insert_authenticated | INSERT |
| secuencias_caracterizaciones_rango | secuencias_caracterizaciones_rango_select_assigned_reviewer | SELECT |
| secuencias_caracterizaciones_rango | secuencias_caracterizaciones_rango_select_authenticated | SELECT |
| secuencias_caracterizaciones_rango | secuencias_caracterizaciones_rango_update_authenticated | UPDATE |
| obras_resumen | obras_resumen_anon_select | SELECT |
| obras_resumen | obras_resumen_auth_select | SELECT |
| secuencias_metricas | secuencias_delete_authenticated | DELETE |
| secuencias_metricas | secuencias_importadas_consulta | SELECT |
| secuencias_metricas | secuencias_insert_authenticated | INSERT |
| secuencias_metricas | secuencias_metricas_basicas_delete | DELETE |
| secuencias_metricas | secuencias_metricas_basicas_insert | INSERT |
| secuencias_metricas | secuencias_metricas_basicas_update | UPDATE |
| secuencias_metricas | secuencias_minimas_limite | SELECT |
| secuencias_metricas | secuencias_select_assigned_reviewer | SELECT |
| secuencias_metricas | secuencias_select_authenticated | SELECT |
| secuencias_metricas | secuencias_update_authenticated | UPDATE |
| cuadros | cuadros_delete_authenticated | DELETE |
| cuadros | cuadros_insert_authenticated | INSERT |
| cuadros | cuadros_select_authenticated | SELECT |
| cuadros | cuadros_update_authenticated | UPDATE |
| jornadas | jornadas_delete_authenticated | DELETE |
| jornadas | jornadas_insert_authenticated | INSERT |
| jornadas | jornadas_select_authenticated | SELECT |
| jornadas | jornadas_update_authenticated | UPDATE |
| secuencias_subtipos_estrofa | secuencias_subtipos_delete_authenticated | DELETE |
| secuencias_subtipos_estrofa | secuencias_subtipos_insert_authenticated | INSERT |
| secuencias_subtipos_estrofa | secuencias_subtipos_select_assigned_reviewer | SELECT |
| secuencias_subtipos_estrofa | secuencias_subtipos_select_authenticated | SELECT |
| secuencias_subtipos_estrofa | secuencias_subtipos_update_authenticated | UPDATE |
| migracion_secuencias | migracion_secuencias_escritura | ALL |
| migracion_secuencias | migracion_secuencias_lectura | SELECT |
| obras | obras_consulta_editorial | SELECT |
| atribuciones | atribuciones_delete_authenticated | DELETE |
| atribuciones | atribuciones_insert_authenticated | INSERT |
| atribuciones | atribuciones_select_authenticated | SELECT |
| atribuciones | atribuciones_update_authenticated | UPDATE |
| atribucion_autores | atribucion_autores_delete_authenticated | DELETE |
| atribucion_autores | atribucion_autores_insert_authenticated | INSERT |
| atribucion_autores | atribucion_autores_select_authenticated | SELECT |
| atribucion_autores | atribucion_autores_update_authenticated | UPDATE |
| importaciones_metricas | importaciones_consulta | SELECT |
| metrica_minima_secuencias | metrica_minima_consulta | SELECT |
| asignaciones_historial | asignaciones_historial_gestores | SELECT |
| obras_corpus | obras_corpus_gestores_consulta | SELECT |
| obras_dataciones | dataciones_consulta | SELECT |

## Migraciones históricas con referencias

- [supabase/migrations/20260210190000_obras_select_dashboard_fix.sql](../../supabase/migrations/20260210190000_obras_select_dashboard_fix.sql)
- [supabase/migrations/20260210180000_iter2_reviewers_and_rls.sql](../../supabase/migrations/20260210180000_iter2_reviewers_and_rls.sql)
- [supabase/migrations/20260210162000_comentarios_tipologia_y_relaciones.sql](../../supabase/migrations/20260210162000_comentarios_tipologia_y_relaciones.sql)
- [supabase/migrations/20260209181500_rls_dashboard_core_policy_fix.sql](../../supabase/migrations/20260209181500_rls_dashboard_core_policy_fix.sql)
- [supabase/migrations/20260209173000_rls_secuencias_policy_fix.sql](../../supabase/migrations/20260209173000_rls_secuencias_policy_fix.sql)
- [supabase/migrations/20260209121803_remote_schema.sql](../../supabase/migrations/20260209121803_remote_schema.sql)
- [supabase/migrations/20260210213000_obras_update_remove_reviewer_write.sql](../../supabase/migrations/20260210213000_obras_update_remove_reviewer_write.sql)
- [supabase/migrations/20260216120000_unify_estado_visibility.sql](../../supabase/migrations/20260216120000_unify_estado_visibility.sql)
- [supabase/migrations/20260213093000_comentarios_update_delete_rls.sql](../../supabase/migrations/20260213093000_comentarios_update_delete_rls.sql)
- [supabase/migrations/20260319103000_rename_personajes_genero_personaje_femenino.sql](../../supabase/migrations/20260319103000_rename_personajes_genero_personaje_femenino.sql)
- [supabase/migrations/20260318193000_secuencias_subtipos_estrofa.sql](../../supabase/migrations/20260318193000_secuencias_subtipos_estrofa.sql)
- [supabase/migrations/20260318170000_drop_cuadros_descripcion.sql](../../supabase/migrations/20260318170000_drop_cuadros_descripcion.sql)
- [supabase/migrations/20260318123000_rename_observaciones_sinopsis.sql](../../supabase/migrations/20260318123000_rename_observaciones_sinopsis.sql)
- [supabase/migrations/20260222221500_public_obras_ficha_editor_contact.sql](../../supabase/migrations/20260222221500_public_obras_ficha_editor_contact.sql)
- [supabase/migrations/20260222193000_public_obras_ficha_rpc.sql](../../supabase/migrations/20260222193000_public_obras_ficha_rpc.sql)
- [supabase/migrations/20260405193000_autoria_atribuciones_cutover.sql](../../supabase/migrations/20260405193000_autoria_atribuciones_cutover.sql)
- [supabase/migrations/20260402120000_caracterizacion_rango_refactor.sql](../../supabase/migrations/20260402120000_caracterizacion_rango_refactor.sql)
- [supabase/migrations/20260327113000_comentarios_internos_seccion.sql](../../supabase/migrations/20260327113000_comentarios_internos_seccion.sql)
- [supabase/migrations/20260414120000_autoria_fuente_markdown.sql](../../supabase/migrations/20260414120000_autoria_fuente_markdown.sql)
- [supabase/migrations/20260517130000_comentarios_publicos_tipologia.sql](../../supabase/migrations/20260517130000_comentarios_publicos_tipologia.sql)
- [supabase/migrations/20260517152000_autoria_grupos_composicion.sql](../../supabase/migrations/20260517152000_autoria_grupos_composicion.sql)
- [supabase/migrations/20260618120000_secciones_publicas.sql](../../supabase/migrations/20260618120000_secciones_publicas.sql)
- [supabase/migrations/20260617120000_autoria_perfil_metrico_only.sql](../../supabase/migrations/20260617120000_autoria_perfil_metrico_only.sql)
- [supabase/migrations/20260518001500_rename_secuencia_intervenciones.sql](../../supabase/migrations/20260518001500_rename_secuencia_intervenciones.sql)
- [supabase/migrations/20260517193000_secuencias_evocacion_metrica.sql](../../supabase/migrations/20260517193000_secuencias_evocacion_metrica.sql)
- [supabase/migrations/20260517184500_drop_grupo_atribucion_metadata.sql](../../supabase/migrations/20260517184500_drop_grupo_atribucion_metadata.sql)
- [supabase/migrations/20260517170000_atribucion_evidencias.sql](../../supabase/migrations/20260517170000_atribucion_evidencias.sql)
- [supabase/migrations/20260618180000_vocabularios_etiqueta.sql](../../supabase/migrations/20260618180000_vocabularios_etiqueta.sql)
- [supabase/migrations/20260618170000_ficha_publica_sinopsis_metrica.sql](../../supabase/migrations/20260618170000_ficha_publica_sinopsis_metrica.sql)
- [supabase/migrations/20260618160000_ficha_publica_subtipos_estrofa.sql](../../supabase/migrations/20260618160000_ficha_publica_subtipos_estrofa.sql)
- [supabase/migrations/20260618190000_ficha_forma_color_slug.sql](../../supabase/migrations/20260618190000_ficha_forma_color_slug.sql)
- [supabase/migrations/20260618200000_ficha_sinopsis_forma_slug.sql](../../supabase/migrations/20260618200000_ficha_sinopsis_forma_slug.sql)
- [supabase/migrations/20260623130000_remove_certeza_editor.sql](../../supabase/migrations/20260623130000_remove_certeza_editor.sql)
- [supabase/migrations/20260621140000_autores_listado_top_obras.sql](../../supabase/migrations/20260621140000_autores_listado_top_obras.sql)
- [supabase/migrations/20260621120000_autores_mejoras_perfil_hijos.sql](../../supabase/migrations/20260621120000_autores_mejoras_perfil_hijos.sql)
- [supabase/migrations/20260619170000_autores_publico_rpc.sql](../../supabase/migrations/20260619170000_autores_publico_rpc.sql)
- [supabase/migrations/20260619160000_autores_resumen.sql](../../supabase/migrations/20260619160000_autores_resumen.sql)
- [supabase/migrations/20260619143000_obras_resumen_estructura_barcode.sql](../../supabase/migrations/20260619143000_obras_resumen_estructura_barcode.sql)
- [supabase/migrations/20260619120000_obras_resumen_rls_publico.sql](../../supabase/migrations/20260619120000_obras_resumen_rls_publico.sql)
- [supabase/migrations/20260618220000_obras_resumen_nucleo.sql](../../supabase/migrations/20260618220000_obras_resumen_nucleo.sql)
- [supabase/migrations/20260624120000_editorial_preview_workflow.sql](../../supabase/migrations/20260624120000_editorial_preview_workflow.sql)
- [supabase/migrations/20260728103000_demarcador_versiones.sql](../../supabase/migrations/20260728103000_demarcador_versiones.sql)
- [supabase/migrations/20260729102000_elecciones_editor_metrico_v2.sql](../../supabase/migrations/20260729102000_elecciones_editor_metrico_v2.sql)
- [supabase/migrations/20260729105000_guardado_editor_metrico_jerarquico.sql](../../supabase/migrations/20260729105000_guardado_editor_metrico_jerarquico.sql)
- [supabase/migrations/20260730101000_formalizacion_sexteto_y_esquemas_observados.sql](../../supabase/migrations/20260730101000_formalizacion_sexteto_y_esquemas_observados.sql)
- [supabase/migrations/20260730200000_unidad_explicita.sql](../../supabase/migrations/20260730200000_unidad_explicita.sql)
- [supabase/migrations/20260730180000_renombrado_ontologia_metrica.sql](../../supabase/migrations/20260730180000_renombrado_ontologia_metrica.sql)
- [supabase/migrations/20260731160000_respuesta_que_define_la_norma.sql](../../supabase/migrations/20260731160000_respuesta_que_define_la_norma.sql)
- [supabase/migrations/20260801120000_alias_contenedor.sql](../../supabase/migrations/20260801120000_alias_contenedor.sql)
- [supabase/migrations/20260801110000_vocabulario_unico.sql](../../supabase/migrations/20260801110000_vocabulario_unico.sql)
- [supabase/migrations/20260804100000_guardado_de_la_anotacion_en_sombra.sql](../../supabase/migrations/20260804100000_guardado_de_la_anotacion_en_sombra.sql)
- [supabase/migrations/20260802100000_zejel_secuencia_y_formas_aprobadas.sql](../../supabase/migrations/20260802100000_zejel_secuencia_y_formas_aprobadas.sql)
- [supabase/migrations/20260809190000_la_respuesta_guarda_el_dato_elegido.sql](../../supabase/migrations/20260809190000_la_respuesta_guarda_el_dato_elegido.sql)
- [supabase/migrations/20260810140000_el_guardado_nombra_la_pregunta_por_su_enunciado.sql](../../supabase/migrations/20260810140000_el_guardado_nombra_la_pregunta_por_su_enunciado.sql)
- [supabase/migrations/20260810150000_los_tercetos_del_soneto_son_dos_bloques.sql](../../supabase/migrations/20260810150000_los_tercetos_del_soneto_son_dos_bloques.sql)
- [supabase/migrations/20260818140000_la_sextilla_no_convierte_su_muestra_en_norma.sql](../../supabase/migrations/20260818140000_la_sextilla_no_convierte_su_muestra_en_norma.sql)
- [supabase/migrations/20260815100000_el_catalogo_de_formas_se_lee_sin_sesion.sql](../../supabase/migrations/20260815100000_el_catalogo_de_formas_se_lee_sin_sesion.sql)
- [supabase/migrations/20260825430000_el_guardado_recuerda_la_arquitectura_de_la_realizacion.sql](../../supabase/migrations/20260825430000_el_guardado_recuerda_la_arquitectura_de_la_realizacion.sql)
- [supabase/migrations/20260826090000_la_unidad_excepcional_se_valida_por_su_arquitectura.sql](../../supabase/migrations/20260826090000_la_unidad_excepcional_se_valida_por_su_arquitectura.sql)
- [supabase/migrations/20260826100000_las_fuentes_tambien_suben_la_revision.sql](../../supabase/migrations/20260826100000_las_fuentes_tambien_suben_la_revision.sql)
- [supabase/migrations/20260820140000_el_catalogo_no_lleva_su_propio_estado_de_revision.sql](../../supabase/migrations/20260820140000_el_catalogo_no_lleva_su_propio_estado_de_revision.sql)
- [supabase/migrations/20260826130000_las_tablas_de_la_anotacion_se_llaman_anotacion.sql](../../supabase/migrations/20260826130000_las_tablas_de_la_anotacion_se_llaman_anotacion.sql)
- [supabase/migrations/20260824170000_la_decima_lira_trae_su_unica_disposicion.sql](../../supabase/migrations/20260824170000_la_decima_lira_trae_su_unica_disposicion.sql)
- [supabase/migrations/20260910100000_invalidar_ficha_por_identidad_editorial.sql](../../supabase/migrations/20260910100000_invalidar_ficha_por_identidad_editorial.sql)
- [supabase/migrations/20260829220000_la_respuesta_se_describe_a_si_misma.sql](../../supabase/migrations/20260829220000_la_respuesta_se_describe_a_si_misma.sql)
- [supabase/migrations/20260829210000_la_cancion_petrarquista_no_se_podia_guardar.sql](../../supabase/migrations/20260829210000_la_cancion_petrarquista_no_se_podia_guardar.sql)
- [supabase/migrations/20260909170000_la_ficha_habla_el_dominio_actual.sql](../../supabase/migrations/20260909170000_la_ficha_habla_el_dominio_actual.sql)
- [supabase/migrations/20260909130000_la_sinopsis_recibe_el_nombre_de_la_forma.sql](../../supabase/migrations/20260909130000_la_sinopsis_recibe_el_nombre_de_la_forma.sql)
- [supabase/migrations/20260909110000_el_equipo_muestra_sus_fichas_publicadas.sql](../../supabase/migrations/20260909110000_el_equipo_muestra_sus_fichas_publicadas.sql)
- [supabase/migrations/20260827110000_el_guardado_pide_permiso_sobre_la_obra.sql](../../supabase/migrations/20260827110000_el_guardado_pide_permiso_sobre_la_obra.sql)
- [supabase/migrations/20260827100000_los_editores_anotan_y_el_catalogo_es_publico.sql](../../supabase/migrations/20260827100000_los_editores_anotan_y_el_catalogo_es_publico.sql)
- [supabase/migrations/20260827090000_todas_las_obras_se_anotan_con_el_catalogo_nuevo.sql](../../supabase/migrations/20260827090000_todas_las_obras_se_anotan_con_el_catalogo_nuevo.sql)
- [supabase/migrations/20260907140000_lo_que_no_hay_se_marca_una_vez.sql](../../supabase/migrations/20260907140000_lo_que_no_hay_se_marca_una_vez.sql)
- [supabase/migrations/20260907130000_lo_que_no_hay_en_la_obra_no_se_pregunta_en_cada_secuencia.sql](../../supabase/migrations/20260907130000_lo_que_no_hay_en_la_obra_no_se_pregunta_en_cada_secuencia.sql)
- [supabase/migrations/20260907110000_la_evocacion_metrica_es_un_fenomeno_enunciativo.sql](../../supabase/migrations/20260907110000_la_evocacion_metrica_es_un_fenomeno_enunciativo.sql)
- [supabase/migrations/20260908100000_la_ficha_dice_tambien_lo_que_se_anoto.sql](../../supabase/migrations/20260908100000_la_ficha_dice_tambien_lo_que_se_anoto.sql)
- [supabase/migrations/20260907180000_la_ficha_no_lee_ya_el_vocabulario_legado.sql](../../supabase/migrations/20260907180000_la_ficha_no_lee_ya_el_vocabulario_legado.sql)
- [supabase/migrations/20260907170000_la_ficha_lee_el_catalogo_nuevo.sql](../../supabase/migrations/20260907170000_la_ficha_lee_el_catalogo_nuevo.sql)
- [supabase/migrations/20260908120000_una_sola_funcion_construye_la_ficha.sql](../../supabase/migrations/20260908120000_una_sola_funcion_construye_la_ficha.sql)
- [supabase/migrations/20260914140000_los_localizadores_de_caparros_2014_llevan_al_pasaje.sql](../../supabase/migrations/20260914140000_los_localizadores_de_caparros_2014_llevan_al_pasaje.sql)
- [supabase/migrations/20260912150000_el_corpus_comparativo_es_un_laboratorio_privado.sql](../../supabase/migrations/20260912150000_el_corpus_comparativo_es_un_laboratorio_privado.sql)
- [supabase/migrations/20260912100000_los_datos_publicos_son_artefactos_json.sql](../../supabase/migrations/20260912100000_los_datos_publicos_son_artefactos_json.sql)
- [supabase/migrations/20260910150000_la_ficha_dice_lo_que_la_obra_declara_que_no_hay.sql](../../supabase/migrations/20260910150000_la_ficha_dice_lo_que_la_obra_declara_que_no_hay.sql)
- [supabase/migrations/20260910120000_el_nombre_de_la_arquitectura_concuerda_con_su_forma.sql](../../supabase/migrations/20260910120000_el_nombre_de_la_arquitectura_concuerda_con_su_forma.sql)
- [supabase/migrations/20260910110000_cola_recompute_datos_publicos.sql](../../supabase/migrations/20260910110000_cola_recompute_datos_publicos.sql)
- [supabase/migrations/20260909090000_la_portada_lee_los_resumenes.sql](../../supabase/migrations/20260909090000_la_portada_lee_los_resumenes.sql)
- [supabase/migrations/20260916220000_el_repertorio_de_enlaces_del_diccionario_no_es_solo_la_gaya_ciencia.sql](../../supabase/migrations/20260916220000_el_repertorio_de_enlaces_del_diccionario_no_es_solo_la_gaya_ciencia.sql)
- [supabase/migrations/20261110220000_contraer_modelo_de_obras.sql](../../supabase/migrations/20261110220000_contraer_modelo_de_obras.sql)
- [supabase/migrations/20261110200000_control_de_obras_y_dataciones.sql](../../supabase/migrations/20261110200000_control_de_obras_y_dataciones.sql)
- [supabase/migrations/20261110130000_el_guardado_metrico_no_recalcula_el_catalogo_por_respuesta.sql](../../supabase/migrations/20261110130000_el_guardado_metrico_no_recalcula_el_catalogo_por_respuesta.sql)
- [supabase/migrations/20261110100000_importador_numeracion_y_canto.sql](../../supabase/migrations/20261110100000_importador_numeracion_y_canto.sql)
- [supabase/migrations/20261105120000_importador_separadores_porcentajes.sql](../../supabase/migrations/20261105120000_importador_separadores_porcentajes.sql)
- [supabase/migrations/20261103110000_importador_prosa_en_secuencia.sql](../../supabase/migrations/20261103110000_importador_prosa_en_secuencia.sql)
- [supabase/migrations/20261102190000_gestion_listado_fichas_basicas.sql](../../supabase/migrations/20261102190000_gestion_listado_fichas_basicas.sql)
- [supabase/migrations/20261102170000_importador_ejecucion_ia.sql](../../supabase/migrations/20261102170000_importador_ejecucion_ia.sql)
- [supabase/migrations/20261029180000_importador_fichas_basicas.sql](../../supabase/migrations/20261029180000_importador_fichas_basicas.sql)
- [supabase/migrations/20261029120000_la_prosa_se_localiza_entre_versos.sql](../../supabase/migrations/20261029120000_la_prosa_se_localiza_entre_versos.sql)
- [supabase/migrations/20261026090000_el_quebrado_conserva_su_disposicion.sql](../../supabase/migrations/20261026090000_el_quebrado_conserva_su_disposicion.sql)
- [supabase/migrations/20261019130000_los_conflictos_de_reparto_no_se_reintentan.sql](../../supabase/migrations/20261019130000_los_conflictos_de_reparto_no_se_reintentan.sql)
- [supabase/migrations/20261019120000_gestion_de_asignaciones_en_lote.sql](../../supabase/migrations/20261019120000_gestion_de_asignaciones_en_lote.sql)
- [supabase/migrations/20261015121000_traslada_la_nota_de_adonis_y_venus.sql](../../supabase/migrations/20261015121000_traslada_la_nota_de_adonis_y_venus.sql)
- [supabase/migrations/20261015120000_traslada_las_notas_de_prueba_a_comentarios.sql](../../supabase/migrations/20261015120000_traslada_las_notas_de_prueba_a_comentarios.sql)
- [supabase/migrations/20261015093000_generos_de_quienes_intervienen.sql](../../supabase/migrations/20261015093000_generos_de_quienes_intervienen.sql)
- [supabase/migrations/20261014200000_la_silva_de_orden_libre_admite_pareados_sistematicos.sql](../../supabase/migrations/20261014200000_la_silva_de_orden_libre_admite_pareados_sistematicos.sql)
- [supabase/migrations/20260924160000_el_final_acentual_es_una_capa.sql](../../supabase/migrations/20260924160000_el_final_acentual_es_una_capa.sql)
- [supabase/migrations/20260924140000_cada_rasgo_dice_en_que_se_cuenta.sql](../../supabase/migrations/20260924140000_cada_rasgo_dice_en_que_se_cuenta.sql)
- [supabase/migrations/20260924100000_una_obra_recuerda_cuando_se_publico.sql](../../supabase/migrations/20260924100000_una_obra_recuerda_cuando_se_publico.sql)
- [supabase/migrations/20260923140000_las_vocales_de_la_asonancia_se_exigen_si_la_rima_asuena.sql](../../supabase/migrations/20260923140000_las_vocales_de_la_asonancia_se_exigen_si_la_rima_asuena.sql)
- [supabase/migrations/20260922190000_la_norma_de_la_estancia_no_se_compara_con_el_remate.sql](../../supabase/migrations/20260922190000_la_norma_de_la_estancia_no_se_compara_con_el_remate.sql)
- [supabase/migrations/20260921200000_el_villancico_sin_cabeza_no_existe.sql](../../supabase/migrations/20260921200000_el_villancico_sin_cabeza_no_existe.sql)
