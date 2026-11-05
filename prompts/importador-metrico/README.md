# Prompts del importador

| Uso | Archivo | Estado |
| --- | --- | --- |
| Próxima comparación con las veinte obras | [Extracción 0.27](./extraccion-v0.27.md) | En evaluación; usar este para las nuevas pruebas |
| Botón «Copiar prompt» del dashboard | [Extracción 0.15](./extraccion-v0.15.md) | Versión activa; no se ha sustituido por la candidata |

Copiar el contenido completo del archivo de extracción y adjuntar las fotos de una obra.
No hay que adjuntar referencias de equivalencias: la transcripción conserva los términos
de la edición y el importador los interpreta después.

- `archivo/`: versiones anteriores y alternativas experimentales. Su número no acredita calidad.
- `auxiliares/`: ensayos de revisión parcial; no forman parte del flujo habitual.
- [Evaluación](../../docs/importador-metrico/evaluacion/README.md): dónde guardar respuestas y cotejos.
- [Proceso histórico](../../docs/importador-metrico/historico/README.md): resultados de los cambios anteriores.

Cada versión es inmutable una vez utilizada en un ensayo. Un cambio de instrucciones recibe
otra versión. Para activarla en el dashboard hay que cambiar explícitamente su import y superar
el panel de regresión; mover archivos no cambia el prompt activo.
