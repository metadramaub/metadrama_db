# Dashboard Guide Content

Este directorio contiene la guía interna del dashboard en formato Markdown.

## Estructura de la guía

La guía está organizada en capítulos cortos orientados a tarea, pensados para leerse
"siguiente → siguiente":

Los capítulos se agrupan por el campo `group` del manifiesto (`index.ts`):

- **Primeros pasos** (`intro`): `empieza-aqui`, `como-moverte`, `antes-de-empezar`.
- **Pasos de edición** (`edicion`): `paso-datos`, `paso-estructura`, `paso-secuencias`,
  `paso-caracterizaciones`, `paso-autoria`, `paso-observaciones`, `paso-revision`.
  Cada "paso" espeja una pestaña real del editor de obra.
- **Material de consulta** (`consulta`): `ref-markdown`, `ref-tablas`, `ref-vocabularios`.
- **Preguntas frecuentes** (`faq`): `faq`.

Las etiquetas visibles de cada grupo están en `DASHBOARD_GUIDE_GROUPS`
(`src/lib/types/dashboard-guide.types.ts`).

Los capítulos de la versión anterior (una sola página larga por módulo) se conservan en
`chapters/_old/*.bak`. No los carga la app: `import.meta.glob` solo lee `chapters/*.md`.

## Cómo editar

1. Abre `index.ts` y mantén el orden deseado de capítulos.
2. Crea o edita archivos en `chapters/`.
3. Cada entrada del manifiesto debe apuntar a un archivo existente con `file`.
4. Si un archivo falta, la app mostrará un mensaje de contenido pendiente (fallback).
5. Mantén los capítulos cortos (idealmente una pantalla). Si uno crece demasiado,
   plantéate dividirlo y enlazarlo.

## Cómo añadir un capítulo

1. Crea un nuevo `.md` en `chapters/`.
2. Agrega una entrada en `index.ts` con:
   - `slug`
   - `title`
   - `summary`
   - `file`
3. Verifica que el `slug` sea único.

## Sintaxis Markdown soportada

- Títulos `#` y `##`
- Listas con `- item`
- Listas numeradas con `1. item`
- Negrita con `**texto**`
- Cursiva con `*texto*`
- Código inline con `` `codigo` ``
- Enlaces externos `https://...`

Nota: el renderer interno es deliberadamente simple para mantener seguridad y consistencia visual.
