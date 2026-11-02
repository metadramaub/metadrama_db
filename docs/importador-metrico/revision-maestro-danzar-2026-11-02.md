# El maestro de danzar: nuevas denominaciones y esquema mal transcrito

Respuesta original v0.9 conservada en
`backups/importador-local/maestro-danzar-2026-11-02/respuesta-v0.9-original.json`.
Cotejadas las dos fotografías del lote; no se ha consultado el texto dramático ni guardado la obra.
Veinte filas continuas, 3042 versos; jornadas 1–1120, 1121–2192 y 2193–3042.
Los rangos y recuentos coinciden con las fotos, también los del resumen.

- 93–208, «romance»: se identifica Romance octosílabo, sin inventar asonancia.
- 1517–1669, «redondillas y quintillas»: ambas formas están declaradas, pero no sus
  localizaciones internas. No son alternativas entre las que elegir una para todo el pasaje.
  Se conserva sin identificar y se documenta como caso complejo de segmentación.
- 2863–2970: la foto dice **lira (AabBCC)**; la respuesta pone **lira (aAbbCC)**.
  Seis posiciones, 108 versos (18 unidades de seis), compatibles con Sexteto-lira.
  Consulta SELECT al catálogo real: arquitectura heterométrica consonante, rima aabbcc y
  metro 11-7-7-11-11-11. Se añade la correspondencia de forma y arquitectura. No se añade
  una equivalencia indiscriminada de «lira» a Sexteto-lira: nuestra Lira tiene cinco versos.
  El contrato mínimo no incluye todavía esquemas estructurados: la notación queda en el
  literal, sin presentarla como esquema métrico o de rima registrado.
- La llamada 110 está en 1670–1780 y el cuerpo de la nota no aparece en la fotografía.
  El JSON lo declara con null e incidencia: no se reconstruye su contenido ni se supone remate.

El prompt v0.10 insiste en copiar cada letra y su caja exactas; pide relanzar la extracción,
no reparar el JSON manualmente. No se da por corregida la respuesta ni por aprobado un
esquema hasta comprobar el nuevo resultado. El cotejo es una revisión de esta respuesta,
no un nuevo gold ni una validación del texto de la edición.

La coincidencia terminológica del motor ignora caja en nombres de forma. Por ello la nueva
regla identifica la forma de seis versos también en la respuesta errónea, pero **no valida**
la distribución de medidas que esta habría alterado. El esquema literal debe corregirse
en la extracción, mediante nueva ejecución del prompt.
