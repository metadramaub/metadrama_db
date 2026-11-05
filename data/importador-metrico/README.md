# Referencias que usa el importador

Estos JSON son entradas de la aplicación y de sus herramientas de evaluación. No son informes.

| Archivo | Función |
| --- | --- |
| `catalogo-referencia.json` | Referencia fechada del catálogo |
| `equivalencias.propuestas.json` | Reglas de normalización y su ámbito; el nombre histórico no implica que todas sigan pendientes |
| `bibliografia-contraste.json` | Fundamentos de las correspondencias |
| `reglas-longitud.json` | Comprobación normativa de rangos |
| `segmentacion.propuestas.json` | Decisiones de segmentación y desviaciones del lote |
| `auditoria-flujo-2026-10-26.json` | Vocabularios empleados por la preparación |
| `auditoria-campos-2026-10-22.json` | Metros y referencias del contrato de preparación |

Los nombres fechados conservan la identidad de los datos ya utilizados. No actualizarlos por
el mero traslado. Sus consumidores están en `src/lib/importador-metrico`, el servidor del
importador y los scripts. Un cambio semántico exige las pruebas correspondientes.

Las herramientas locales resuelven estas entradas y las del piloto mediante
`scripts/lib/importador-metrico/rutas.mjs`. El código de aplicación importa los JSON directamente.
Las respuestas de modelos y los derivados del lote están en
[evaluación](../../docs/importador-metrico/evaluacion/README.md).
