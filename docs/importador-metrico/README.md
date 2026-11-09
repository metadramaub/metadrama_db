# Importador de esquemas métricos

Incorpora declaraciones métricas de ediciones críticas como fichas básicas privadas. La IA
transcribe las fotos; el importador normaliza, permite corregir y guarda una copia de lo confirmado.
Las fichas detalladas mantienen su anotación v2 y prevalecen al publicarse.

## Trabajo actual

El inventario terminológico incorpora las veinte respuestas 0.27, incluidas las obras
bloqueadas por discrepancias numéricas. El evaluador comparte la compleción mecánica
del dashboard. Las reglas v0.19 amplían las propuestas por nombre explícito del catálogo sin
inferir arquitecturas.
Quien importa puede [enseñar al importador un término nuevo](funcionamiento/importar.md#enseñar-al-importador-un-término-nuevo)
que llegó sin identificar.

**El prompt para las próximas pruebas es [0.27](../../prompts/importador-metrico/extraccion-v0.27.md).**
El botón del dashboard sigue copiando 0.15; la candidata no se ha activado.
Ya se han conservado las veinte respuestas de GPT-6 High, sin reintentos, y las cinco recibidas
de Gemini 3.6 Thinking. El [informe del lote](./evaluacion/informes/chatgpt-gpt6-high-v0.27.md)
recoge el cotejo de las 38 fotos, sus diferencias de literalidad y las correcciones del
importador (reglas v0.17; porcentajes también admitidos en Supabase) antes de activar la candidata. [Evaluación](./evaluacion/README.md) explica cómo conservar y cotejar las respuestas.

El guardado, consulta y eliminación de básicas ya tienen implementación y registros de despliegue.
Hay ensayos de datos comparables y precomputación con ambos orígenes; esto no acredita su
integración en los productores compartidos. No se han ejecutado los experimentos de sensibilidad
ni se habilitan comparaciones públicas con básicas. La prioridad es cerrar un flujo de importación
fiable para colaboradores. Los pendientes generales viven en [PENDIENTES](../PENDIENTES.md).

## Leer según la tarea

| Tarea | Referencia |
| --- | --- |
| Copiar el prompt adecuado | [Prompts: activo, en evaluación y archivo](../../prompts/importador-metrico/README.md) |
| Importar y revisar una obra | [Funcionamiento](./funcionamiento/importar.md) |
| Guardar y evaluar respuestas de modelos | [Evaluación](./evaluacion/README.md) |
| Saber qué obras faltan y por qué | [Seguimiento generado](./evaluacion/informes/seguimiento-lote.md) |
| Revisar correspondencias del catálogo | [Informe de equivalencias](./equivalencias/revision-equivalencias.md) |
| Regenerar los informes | [Seguimiento y generación](./funcionamiento/seguimiento-e-informe-equivalencias.md) |
| Comprobar un JSON desde archivos | [Validador](./funcionamiento/validador-local.md) |
| Consultar criterios científicos | [Metodología](./metodologia/metodologia.md) e [inventario general de medidas](../inventario-medidas-analiticas.md) |
| Consultar campos, modelo y permisos | [Campos mínimos](./arquitectura/campos-minimos.md) y [diseño de integración](./arquitectura/diseno-integracion.md) |
| Integrar cálculos y consumidores | [Consultas y precomputación](./arquitectura/consultas-y-precomputacion.md) |
| Localizar reglas consumidas por la aplicación | [Datos del importador](../../data/importador-metrico/README.md) |
| Recuperar el proceso seguido | [Histórico](./historico/README.md) |

## Mantener este espacio

Aplicar [la guía de documentación del repositorio](../guia-documentacion.md). Actualizar la
referencia que corresponda y este índice cuando cambie el estado del trabajo. No añadir un
documento de reanudación por sesión. El histórico no sustituye las instrucciones vigentes.
Las respuestas originales y los prompts utilizados en pruebas se conservan sin sobrescribirlos.
