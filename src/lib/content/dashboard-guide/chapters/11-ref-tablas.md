Referencias rápidas para consultar de un vistazo mientras editas.

## Estados de una obra y quién los cambia

- `borrador`: la obra está en edición. El editor asignado puede editar su contenido.
- `vista_previa`: permite revisar la ficha pública. El editor asignado puede pasar aquí desde `borrador` y volver.
- `listo_para_publicar`: la revisión está cerrada. El editor asignado puede llegar aquí desde `vista_previa`.
- `en revisión` → `revisado`: transición propia del revisor asignado.
- **Publicar** (hacer visible al público) y otras transiciones quedan reservadas a `admin` e `IP`.

## Público vs. interno

**Público** (puede aparecer en la ficha publicada):

- datos de la obra (título y variantes, género, datación, edición base, autoría);
- estructura y secuencias;
- observaciones y bibliografía;
- responsable de edición y/o revisión.

**Interno** (privado del equipo):

- comentarios internos (obra, jornadas, cuadros, secuencias, revisión);
- notas operativas de revisión;
- decisiones de asignación editorial.

**Excepción**: un comentario interno se publica en la ficha solo si es de tipo **"observación pública"** *y* tiene marcada la casilla **"Visible en ficha pública"**. Ver [Antes de empezar → Qué es público y qué es interno](/dashboard/guia/antes-de-empezar#que-es-publico-y-que-es-interno).

## Tipologías de autoría y número de autores

Por cada propuesta de autoría:

- `individual`: exactamente 1 autor.
- `colaborada`: 2 o más autores.
- `desconocida`: 0 autores (no crear un autor ficticio "desconocido").

Autoría **disputada** = varias propuestas en el mismo ámbito (alternativas entre sí). Varias **evidencias** dentro de una propuesta = varias fuentes que apoyan la misma atribución. Ver [Paso 5 · Autoría](/dashboard/guia/paso-autoria).

## Caracterizaciones por rango: regla de v_ini / v_fin

- `cantado`, `rima defectuosa`, `laguna`, `mayoria_agudas`, `mayoria_esdrujulas`: un solo verso o un rango.
- `hipométrico`, `hipermétrico`: `v_ini` y `v_fin` deben ser el **mismo verso** (una irregularidad por caracterización).
- `prosa`: `v_ini` y `v_fin` son el verso **anterior y posterior** a la prosa (la prosa no se numera).
- Tipos padre (`fenomenos_enunciativos`, `irregularidades_metricas`, `final_acentual`): agrupadores, **no se seleccionan directamente**.
- Toda caracterización debe quedar **dentro** del rango de versos de su secuencia.

## Roles y permisos (resumen)

El rol `editor` (incluye a quien actúa como `revisor`):

- edita obras asignadas y revisa las asignadas a revisión;
- ve el listado completo de obras, pero **solo puede abrir la ficha** de las que edita o revisa;
- consulta autores y vocabularios;
- **puede crear autores**, pero no editarlos ni eliminarlos;
- no crea obras, no gestiona vocabularios, no cambia su perfil ni su rol.

Los roles `admin` e `IP` tienen permisos ampliados (publicar, gestionar autores y vocabularios, asignar revisiones, etc.).
