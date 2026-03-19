# Dashboard Guide Content

Este directorio contiene la guía interna del dashboard en formato Markdown.

## Cómo editar

1. Abre `index.ts` y mantiene el orden deseado de capítulos.
2. Crea o edita archivos en `chapters/`.
3. Cada entrada del manifiesto debe apuntar a un archivo existente con `file`.
4. Si un archivo falta, la app mostrará un mensaje de contenido pendiente (fallback).
5. Para esta guía de editores, cada capítulo debe incluir estas secciones:
- `Objetivo`
- `Qué puede hacer el editor en este módulo`
- `Qué no puede hacer el editor en este módulo`
- `Qué hacer si necesita una acción sin permiso`
- `Pasos operativos`
- `Errores frecuentes`
- `Checklist`
- `Capturas sugeridas`

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
