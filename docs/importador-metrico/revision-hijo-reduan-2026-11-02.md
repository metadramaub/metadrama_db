# El hijo de Reduán — revisión del 2 de noviembre de 2026

Respuesta del prompt v0.13 conservada sin cambios en
`backups/importador-local/hijo-reduan-2026-11-02/respuesta-v0.13-original.json`.
No se ha guardado ni modificado ninguna obra en esta revisión.

Las 21 filas coinciden con las dos fotografías del lote: 3015 versos consecutivos, tres
jornadas, sin huecos ni solapamientos. Los recuentos del resumen coinciden con los rangos,
agrupando las etiquetas singulares/plurales y las denominaciones abreviadas que usa la fuente.

## Equivalencias incorporadas (reglas v0.15)

- `romance aa` (1258–1297): Romance, arquitectura octosilábica, vocales de asonancia a-a.
  El patrón acepta ahora vocales con o sin la preposición «en», manteniendo el literal.
  Se comprueban todas las asonancias del catálogo con ambas notaciones, sin inventar valores
  para combinaciones fuera del catálogo.
- Endecasílabos sueltos con nota enlazada «concluyen con un pareado»: Dístico final presente.
  En el JSON recibido solo se aplica a 616–667.
- Tercetos encadenados con nota enlazada «se remata con un serventesio» (2285–2522):
  Terceto encadenado con remate final de un verso (3+1). Arquitectura sin determinar.
  Se usa la declaración explícita de la nota, no la divisibilidad del rango.

## Decisiones y límites

El responsable decide dejar `octavas` (1386–1465) sin identificar, aunque el resumen agrupe
96 versos bajo «Octavas reales». No se añade una equivalencia general ni contextual automática.

La primera nota declara «Las series de endecasílabos sueltos concluyen con un pareado»,
pero el JSON solo enlaza t02, donde está el asterisco. La extracción no expresa sus enlaces
con 896–953 y 2687–2773. Las reglas no amplían automáticamente el ámbito de las notas:
para esta preparación, marcar Dístico final en esos dos pasajes desde la interfaz.
Queda como caso para mejorar el enlace de notas de alcance plural en el prompt.

No se deducen canto, esquemas de rima ni arquitecturas adicionales. El modelo efectivo,
modo y cuenta siguen nulos en el original; solo declara Gemini como servicio.
