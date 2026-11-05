# Evaluación del importador y de los modelos

Completadas veinte extracciones con GPT-6 High usando el [prompt 0.27](../../../prompts/importador-metrico/extraccion-v0.27.md),
sin reintentos. El [informe del lote](./informes/chatgpt-gpt6-high-v0.27.md) separa lectura,
errores de las ediciones y tareas del importador. El dashboard conserva 0.15; la candidata no está activada.

## Guardar una respuesta

Usar `ensayos/v0.27/<modelo-y-modo>/<obra>/intento-01.json`, una obra por archivo y sin corregir
el original. Si hay rechazo o respuesta que no sea JSON, conservarla como `.txt`. Un reintento
se guarda aparte. No hace falta añadir carpetas vacías para las obras que aún no se han probado.

La carpeta creada por David está en
[`ensayos/v0.27/Gemini 3.6 Thinking/`](./ensayos/v0.27/Gemini%203.6%20Thinking/).
`las20.json` se conserva tal como estaba (vacío al reorganizar). La primera entrega recibida,
`hastamaestro.txt`, está conservada en `recepciones/` dentro de esa carpeta de modelo, con las
cinco respuestas separadas por obra y un `registro.json` con sus hashes.

Registrar en la evaluación el servicio, modelo efectivo mostrado, modo, tipo de cuenta, fecha,
fotos y versión del prompt. Si no constan, indicar «No consta». La respuesta puede autodeclarar
datos erróneos del modelo: no sustituye lo observado en la interfaz.

## Evaluar

Separar siempre:

1. **Fidelidad a las fotos:** filas, columnas, numeración, denominaciones, notas, esquemas y resumen.
2. **Compatibilidad con el importador:** preparación, equivalencias, avisos y guardado.
3. **Problemas de la edición:** una errata bien transcrita es un acierto de lectura, aunque impida guardar.

Mismas fotos y chat nuevo por obra; conservar el primer resultado y los reintentos. Una salida
que carga no demuestra fidelidad. Una respuesta evaluada no se convierte automáticamente en gold.
Durante el ajuste, repetir casos difíciles y controles; antes de adoptar la versión definitiva,
repetir el lote de veinte. No cambiar validaciones para hacer pasar una lectura defectuosa.

## Dónde consultar

- [Lote de veinte con GPT-6 High y 0.27](./informes/chatgpt-gpt6-high-v0.27.md): resultados, cotejos y preparación real del importador; incluye el detalle de las primeras cinco.

- [Gemini 3.6 Thinking con 0.27](./informes/gemini-3.6-thinking-v0.27.md): primera valoración de cinco obras y cuestiones a vigilar antes de completar las veinte.

- [Seguimiento de las veinte obras](./informes/seguimiento-lote.md): informe generado de guardados y pendientes.
- [Revisión de equivalencias](../equivalencias/revision-equivalencias.md): documento generado para revisión.
- `referencias/extracciones/`: cuatro transcripciones aceptadas, con hashes en `referencias/revision-humana.json`.
- `referencias/normalizadas/` y `referencias/preparadas/`: derivados reproducibles de esas referencias.
- [Ensayos anteriores del prompt](../historico/desarrollo/control-regresiones-prompt.md): proceso y resultados anteriores a esta comparación.
- `ensayos/anteriores/`: respuestas de las pruebas anteriores, copiadas literalmente desde
  los archivos locales. `manifest.json` conserva sus hashes; no son nuevos golds.

Los archivos JSON de seguimiento y decisiones son editables; los informes y derivados se
regeneran con los comandos de [seguimiento](../funcionamiento/seguimiento-e-informe-equivalencias.md).
Los manifiestos de fuentes y las auditorías fechadas en `referencias/` son evidencias del piloto,
no un catálogo vivo ni instrucciones para el modelo.
