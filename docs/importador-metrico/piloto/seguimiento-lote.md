# Seguimiento de las veinte obras del piloto

Guardados contrastados por SELECT en Supabase: 2026-11-02T13:39:00.323Z. No se escribe en la base.

**4 guardadas de 20.** El resto no tiene guardado confirmado en este registro.

El guardado se acredita por obra_id, no por semejanza de títulos. Sin guardado confirmado no significa extracción incorrecta. La revisión y el motivo son anotaciones humanas, separadas del estado de persistencia.

| N.º de foto | Obra | Guardado | Revisión y motivo |
| --- | --- | --- | --- |
| 3 | El caballero del milagro | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/4822994f-5836-44a1-8cce-d821df1af228) | Guardada y cotejada. Estrambote conservado como tres versos sin identificar; criterio pendiente. [Detalle](../revision-caballero-milagro-2026-11-02.md) |
| 4 | El favor agradecido | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/d1ec59f7-4526-42f6-b0a3-b99fbe71745b) | Guardada. Elección manual de encadenados con remate en el pasaje de 43 versos; no se generaliza su arquitectura. [Detalle](../revision-favor-agradecido-2026-11-02.md) |
| 5 | Laura perseguida | [Guardada 2026-11-02](https://versologia.metadrama.org/dashboard/importador/fichas/736ef3b5-c87a-46dc-9085-5b27be7851c1) | Guardada. 617–876 se mantiene como Quintilla; caso complejo pendiente. [Detalle](../revision-laura-perseguida-2026-11-02.md) |
| 6 | El leal criado | Sin guardado confirmado | Aplazada por decisión del responsable. No guardar: pendiente resolver 870–999 y la nota 5 (división 60 + 5 + 65); también 1392–1866 y 2407–2851 tienen longitudes incompatibles con coplas reales regulares. Texto no cotejado. [Detalle](../revision-leal-criado-2026-11-02.md) |
| 7 | El maestro de danzar | Sin guardado confirmado | Respuesta v0.10 validada técnicamente; persiste error de caja en el esquema. La foto dice AabBCC; v0.10 produce AaBbCC. Pendiente resolver la alternancia de redondillas y quintillas en 1517–1669; nota 110 fuera de la foto. [Detalle](../revision-maestro-danzar-2026-11-02.md) |
| 12 | El verdadero amante | Sin guardado confirmado | Transcripción inicial aceptada; pendiente de nueva pasada |
| 13 | Los donaires de Matico | Sin guardado confirmado | Transcripción inicial aceptada; pendiente de nueva pasada |
| 14 | El molino | [Guardada 2026-10-29](https://versologia.metadrama.org/dashboard/importador/fichas/3f6a8587-7761-4f26-851f-ec38a71f49eb) | Guardada y reabierta en producción. Primera importación real, 29-10-2026 |
| 15 | Las ferias de Madrid | Sin guardado confirmado | Pendiente de ensayo |
| 20 | El hijo de Reduán | Sin guardado confirmado | Pendiente de ensayo |
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
