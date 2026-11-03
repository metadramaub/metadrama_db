# Control de regresiones del prompt de extracción

Acuerdo del 3 de noviembre de 2026: mejorar un caso no autoriza a empeorar obras que ya se
extraían bien. Las pruebas de código del importador no prueban la fidelidad de una respuesta
de Gemini. No activar una revisión solo porque cambia bien un ejemplo del prompt.

## Estado actual

- Activa en el dashboard: **0.15**.
- **0.16 candidata**, sin activar: `prompts/importador-metrico/candidatas/extraccion-v0.16.md`.
- Cambios limitados: quitar el ejemplo de prosa que puede copiarse como dato; distinguir
  comprobaciones correctas de incidencias; precisar enlaces de notas con intervalos separados.
- No se modifican las equivalencias ni la validación para hacer pasar una salida defectuosa.

## Panel que debe conservarse

| Caso | Qué vigilar |
| --- | --- |
| El verdadero amante | Asociaciones de columnas, denominaciones partidas y asonancias; éxito previo de 0.13 |
| El molino | Pareados finales, letrilla sin identificar y filas de ambas fotos |
| Los donaires de Matico | Jornadas, 18 filas, 2812 versos y tercetos sin inferir remate |
| Los locos de Valencia | Notas, esquemas y particularidades de la transcripción aceptada |
| Ursón y Valentín | Prosa real sin rango, jornada continuada, aBaBcC, errata conservada e incidencia verdadera |
| Traición acertada (rótulo del lote) | Ausencia de prosa inventada, 18 filas numeradas, nota 21 con tres intervalos y nota 22 sin cuerpo visible |

Las cuatro transcripciones iniciales son referencias aceptadas; los ensayos posteriores no
se convierten por ello en nuevos golds. Ursón conserva una errata de edición: que no pueda
guardarse no supone un error de extracción. Traición v0.15 es una respuesta fallida.

## Comparación antes de activar

1. Conservar las mismas fotos, orden, identificadores y metadatos facilitados para ambas
   versiones. Un chat nuevo para cada ejecución evita arrastrar datos de otra obra.
2. Usar el mismo servicio, modelo efectivo, modo y cuenta, registrando lo que realmente
   conste. «Automático» no garantiza que dos ejecuciones hayan usado el mismo modelo.
3. Guardar las respuestas originales completas de la versión activa y la candidata. Cotejar
   todas las filas, no solo el campo que motivó la revisión. Repetir los casos donde aparezca
   una regresión o un resultado inconsistente; una ejecución por versión no prueba estabilidad.
4. Para los cuatro golds, reutilizar `evaluar-respuesta-modelo.mjs`; los cambios de IDs de
   fotografía o los metadatos no facilitados requieren interpretar las diferencias, no editar
   la respuesta o cambiar la referencia para conseguir un resultado favorable. Las notas,
   sus enlaces y las incidencias también requieren cotejo: el texto libre no se valida por igualdad.
5. Registrar por caso: errores de lectura, omisiones/invenciones, formato, enlaces e incidencias
   verdaderas/falsas. No esconder una regresión nueva detrás de una mejora del total.
6. Activar cuando la candidata resuelva el problema y no queden regresiones observadas sin
   resolver en el panel. Si empeora un caso, revisar o descartar la candidata y mantener la
   activa. Conservar las versiones para poder volver atrás.

Este panel se usa para desarrollar el prompt. No es una estimación independiente de exactitud:
los casos y algunos ejemplos ya han intervenido en su redacción. Las obras nuevas permitirán
comprobar después si las mejoras se mantienen fuera de estos casos conocidos.
