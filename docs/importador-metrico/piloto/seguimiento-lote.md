# Seguimiento de las veinte obras del piloto

Guardados contrastados por SELECT en Supabase: 2026-11-02T18:48:26.265Z. No se escribe en la base.

**5 guardadas de 20.** El resto no tiene guardado confirmado en este registro.

El guardado se acredita por obra_id, no por semejanza de títulos. Sin guardado confirmado no significa extracción incorrecta. La revisión y el motivo son anotaciones humanas, separadas del estado de persistencia.

| N.º de foto | Obra | Guardado | Revisión y motivo |
| --- | --- | --- | --- |
| 3 | El caballero del milagro | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/4822994f-5836-44a1-8cce-d821df1af228) | Guardada y cotejada. Estrambote conservado como tres versos sin identificar; criterio pendiente. [Detalle](../revision-caballero-milagro-2026-11-02.md) |
| 4 | El favor agradecido | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/d1ec59f7-4526-42f6-b0a3-b99fbe71745b) | Guardada. Elección manual de encadenados con remate en el pasaje de 43 versos; no se generaliza su arquitectura. [Detalle](../revision-favor-agradecido-2026-11-02.md) |
| 5 | Laura perseguida | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/736ef3b5-c87a-46dc-9085-5b27be7851c1) | Guardada. 617–876 se mantiene como Quintilla; caso complejo pendiente. [Detalle](../revision-laura-perseguida-2026-11-02.md) |
| 6 | El leal criado | Sin guardado confirmado | Aplazada por decisión del responsable. No guardar: pendiente resolver 870–999 y la nota 5 (división 60 + 5 + 65); también 1392–1866 y 2407–2851 tienen longitudes incompatibles con coplas reales regulares. Texto no cotejado. [Detalle](../revision-leal-criado-2026-11-02.md) |
| 7 | El maestro de danzar | Sin guardado confirmado | Respuesta ChatGPT Plus Instant v0.11 cotejada: AabBCC correcto; validación técnica correcta. La respuesta Gemini gratuita v0.11 produce AaBbCC; ChatGPT Plus Instant v0.11 conserva AabBCC. El editor debe consultar el texto y dividir manualmente 1517–1669 (redondillas y quintillas); nota 110 fuera de la foto. [Detalle](../revision-maestro-danzar-2026-11-02.md) |
| 12 | El verdadero amante | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/7bfa86c6-639a-4637-88d6-3d67f8e5dffe) | Guardada con la respuesta ChatGPT GPT-6 Instant v0.12. Guardada con ChatGPT v0.12 (-ío por -io). Nueva respuesta Gemini 3.5 Flash-Lite v0.13: 19 filas y 2878 versos, sin diferencias métricas respecto a la referencia; no se reimporta. [Detalle](../revision-verdadero-amante-2026-11-02.md) |
| 13 | Los donaires de Matico | Sin guardado confirmado | Respuesta Gemini v0.13 cotejada; pendiente guardado. 18 filas y 2812 versos correctos, incluido el resumen. Tercetos 1–127 y 1523–1667 sin identificar: la edición no precisa si son encadenados. Modelo efectivo no comunicado para esta ejecución. [Detalle](../revision-donaires-matico-2026-11-02.md) |
| 14 | El molino | Sin guardado confirmado | Guardada; nueva extracción Gemini v0.13 coincide con la copia real. 21 secuencias y 2992 versos; dos dísticos finales conservados y letrilla 2880–2888 pendiente. El modelo original sigue sin identificar; el nuevo ensayo usa 3.5 Flash-Lite, Automático, cuenta gratuita. [Detalle](../revision-molino-2026-11-02.md) |
| 15 | Las ferias de Madrid | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/7d5f1d40-2e9e-49fa-8d9a-f0e53f98705e) | Guardada y cotejada. 25 secuencias y 3236 versos correctos. Tres tercetos y cuatro letrillas pendientes (576 versos). El resumen impreso duplica redondillas: 1780 y 2240; los rangos suman 2240. Gemini 3.5 Flash-Lite, Automático, Gratuita; prompt v0.13. [Detalle](../revision-ferias-madrid-2026-11-02.md) |
| 20 | El hijo de Reduán | Sin guardado confirmado | Extracción cotejada; pendientes antes de guardar. 21 filas y 3015 versos correctos. Reglas v0.15 reconocen romance aa, dístico por nota y tercetos con remate. Octavas 1386–1465 queda sin identificar por decisión del responsable. Revisar dístico final en 896–953 y 2687–2773: nota plural enlazada solo a t02. [Detalle](../revision-hijo-reduan-2026-11-02.md) |
| 23 | El nacimiento de Ursón y Valentín | Sin guardado confirmado | Pendiente de ensayo |
| 25 | Traición acertada (rótulo del lote) | Sin guardado confirmado | Pendiente de ensayo |
| 28 | El dómine Lucas | Sin guardado confirmado | Pendiente de ensayo |
| 29 | La ingratitud vengada | Sin guardado confirmado | Pendiente de ensayo |
| 30 | Los locos de Valencia | Sin guardado confirmado | Transcripción inicial aceptada y ensayos externos; pendiente de guardado |
| 31 | El perseguido | Sin guardado confirmado | Pendiente de ensayo |
| 32 | La serrana de Tormes | Sin guardado confirmado | Pendiente de ensayo |
| 33 | Jorge Toledano | Sin guardado confirmado | Pendiente de ensayo |
| 34 | El casamiento en la muerte | Sin guardado confirmado | Pendiente de ensayo |
| 36 | El mármol de Felisardo | Sin guardado confirmado | Pendiente de ensayo |

Los títulos pendientes se identifican por el número de las fotografías; el rótulo del lote no sustituye a los metadatos bibliográficos. Los ensayos antiguos se conservan: la nueva pasada con el prompt vigente sigue pendiente donde se indica.

Fuente editable: `seguimiento-lote.json`. Guardados: `registro-guardados.json`. Regenerar: `npm run importador:informes`. Actualizar primero la consulta remota: `npm run importador:informes -- --actualizar-guardados`.

## Importaciones sin vincular al seguimiento

- Los donaires de Matico: obra_id c94b1ef4-be32-4c04-b38b-6986338014b8. Revisar identidad antes de vincular.
- El molino: obra_id 8b3110a5-9633-4692-a9b6-e545c917c801. Revisar identidad antes de vincular.
