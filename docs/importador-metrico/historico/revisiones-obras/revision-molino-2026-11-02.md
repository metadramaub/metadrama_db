# El molino: nueva extracción frente a la copia real guardada

El responsable aporta una respuesta del prompt v0.13 e identifica su ejecución como
Gemini 3.5 Flash-Lite, modo Automático y cuenta gratuita. El JSON declara Gemini, pero
deja modelo, modo y plan null. Las condiciones se registran externamente en
[ensayos-molino.json](../../evaluacion/referencias/ensayos-molino.json), sin modificar la respuesta recibida.

Original nuevo: `docs/importador-metrico/evaluacion/ensayos/anteriores/molino-2026-11-02/respuesta-v0.13-gemini-flash-lite-original.json`.
Consulta de solo lectura a Supabase: importación `3f6a8587-7761-4f26-851f-ec38a71f49eb`,
obra `55db5a13-38c7-4574-b8fb-3ad874b65909`, guardada el 29-10-2026.

## Resultado

- Valida técnicamente: 21 filas y 2992 versos.
- Cero diferencias frente a la extracción original guardada en jornadas, rangos,
  denominaciones, recuentos, páginas, notas y resumen. Cambian la procedencia de ejecución,
  los metadatos disponibles y los identificadores locales de fuente; no son otra obra.
- Al normalizar la nueva respuesta con las reglas actuales, coinciden campo a campo con
  la copia confirmada los rangos, identificaciones de forma y arquitectura, detalles,
  candidatas y desviaciones de sus 21 secuencias. La comparación es semántica de objetos,
  independiente del orden de claves JSON.
- Dístico final presente en 1794–1831 y 1964–1988, igual que en la importación existente.
- «Letrilla», 2880–2888, conserva la forma sin identificar. No se resuelve por el nuevo ensayo.

Evidencia de la comparación: `docs/importador-metrico/evaluacion/ensayos/anteriores/molino-2026-11-02/comparacion-v0.13.json`.
No se crea otra obra ni se modifica la copia confirmada o su fecha de importación.

## Procedencia de la importación original

La extracción guardada declara «Codex en este chat», procedimiento lectura_visual_asistida,
prompt extraccion/0.1 y modelo null. La copia confirmada es anterior al nuevo bloque de
ejecución IA. Se conserva ese desconocimiento; el modelo Flash-Lite corresponde únicamente
a la nueva respuesta. No se rellena retroactivamente la identidad de un modelo desconocido
porque dos extracciones produzcan los mismos datos.

El ensayo respalda mantener v0.13 para las pruebas siguientes, sin estimar una tasa general
de acierto a partir de este caso. La fuente de referencia inicial permanece intacta y la nueva
respuesta pasa a ser la entrada seleccionada del inventario, conservando ambas.
