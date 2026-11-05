# El verdadero amante: ensayo Gemini Automático con v0.12

Respuesta original conservada intacta en
`docs/importador-metrico/evaluacion/ensayos/anteriores/verdadero-amante-2026-11-02/respuesta-v0.12-gemini-original.json`.
Servicio declarado por el JSON: Gemini; modelo, modo, plan y parámetros null. El responsable
indica modo Automático; la condición gratuita procede de su declaración sobre la cuenta usada.
No se infiere la identidad del modelo. El formato valida, pero no la fidelidad de la lectura.

**Confirmación posterior:** el responsable abre Detalles de la respuesta y comunica
«Se ha usado 3.5 Flash-Lite». Se registra **3.5 Flash-Lite**, con servicio Gemini, modo
Automático y cuenta gratuita, en [el registro del ensayo](../../evaluacion/referencias/ensayos-verdadero-amante.json).
El JSON original conserva modelo null: la identificación procede del panel de la aplicación,
no de una afirmación generada por el modelo ni de una deducción sobre Automático.

Cotejo con la foto `12_verdadero_amante.HEIC` y con la referencia inicial aceptada:

- Las filas conservan los rangos y recuentos, 19 filas y 2878 versos, pero muchas formas
  están mal asociadas. La fila 1418–1460 corta «tercetos encadenados con serventesio final»
  tras «con» y pega «serventesio final» a la redondilla siguiente. Repite el fallo en
  1770–1896 y vuelve a desplazar las denominaciones. No son nuevos términos de la edición
  que deban añadirse al vocabulario de equivalencias.
- Desde 1641–1666 aparece «redondilla» donde la foto dice «romance en -io»; después siguen
  desplazados el romance, los sueltos y otras formas.
- La fila 2017–2064 pertenece al acto tercero, pero la respuesta la incluye en el segundo.
- El 51 de la última fila, 2828–2878, es el recuento impreso en su columna, no una marca
  de nota. La respuesta inventa una nota 51 ausente y una incidencia sobre su cuerpo.
- Introduce saltos de línea en denominaciones y pierde en la última fila la precisión de
  sueltos con pareado final, al etiquetarla como octava real.

**Resultado:** no guardar esta respuesta. Se conserva como ensayo fallido, sin sobrescribir
el gold ni incorporarla como fuente de nuevas equivalencias en el informe. La referencia
seleccionada del inventario sigue siendo la transcripción inicial aceptada.

## Registro del modelo en modo Automático

Consulta de documentación oficial de Google el 02-11-2026:
[About Gemini models](https://support.google.com/gemini/answer/18648722?hl=en).
La ayuda indica que en web se puede abrir Más → Mostrar pasos de razonamiento y consultar
el modelo al final del panel. Automático selecciona el modelo por petición, por lo que el
selector no identifica por sí solo el modelo efectivo. Si esa información no aparece en la
cuenta del responsable, registrar Gemini / Automático / gratuita y mantener modelo y
parámetros desconocidos. No se da por conocido un modelo a partir de lo que afirme la IA.

## ChatGPT GPT-6 Instant, prompt v0.12

El responsable aporta otra salida e identifica GPT-6 Instant. El JSON declara ChatGPT,
GPT-6 y Plus, pero deja modo null. Se registra Instant a partir de la declaración del
responsable, sin modificar la respuesta original. La copia queda en
`docs/importador-metrico/evaluacion/ensayos/anteriores/verdadero-amante-2026-11-02/respuesta-v0.12-chatgpt-gpt6-instant-original.json`.

La salida valida y coincide con la foto y la referencia aceptada en todas las jornadas,
rangos, recuentos y asociaciones de formas: 19 filas, 2878 versos y ninguna forma pendiente.
Conserva completos los dos «tercetos encadenados con serventesio final», los sueltos con
pareado final y el cambio de acto en 2017; no inventa una llamada de nota a partir de 51.
Solo difiere en t09: «romance en -ío» por «romance en -io». Se registra como diferencia de
literalidad, aunque ambas expresiones se normalizan al mismo valor de asonancia i-o.
No se modifica por ello la referencia aceptada ni se declara perfecta la transcripción literal.

En esta ejecución, ChatGPT corrige los errores estructurales presentes en la respuesta de
Gemini 3.5 Flash-Lite. No se generaliza este resultado a todos los casos o modelos.
Queda pendiente el guardado por el responsable; el cambio de estado del ensayo no acredita
una nueva importación en Supabase. La referencia del inventario sigue siendo la inicial aceptada.

## Guardado y prueba de regresión en Gemini gratuita

El responsable confirma el guardado. SELECT remoto confirma obra
`0a0af654-d8bc-4117-b4e1-c3c2f90a17e1`, importación
`7bfa86c6-639a-4637-88d6-3d67f8e5dffe`, guardada el 02-11-2026.
El seguimiento queda vinculado por obra_id; son cinco obras guardadas del lote.

El responsable fija Gemini gratuita como condición principal de los siguientes ensayos.
GPT-6 Instant queda como contraste en estos casos, sin atribuirle acierto universal.
El modelo efectivo de Gemini se registrará desde los detalles de cada respuesta si aparece.

Prompt v0.13: prioriza leer cada fila por su intervalo, unir las denominaciones de varias
líneas antes de pasar al siguiente rango, revisar en sentido inverso la asociación completa
y distinguir recuentos normales de llamadas tipográficas. Incluye un ejemplo ficticio de
dos filas, no los datos de esta obra. Conserva el formato y todas las reglas previas.

Pendiente probarlo en Gemini gratuita, preferiblemente en conversación nueva con las mismas
fotos y sin pegar la respuesta fallida, para evitar que la arrastre. Esta obra será una
prueba de regresión para el fallo conocido, no una evaluación independiente del prompt.
Después se comprobarán nuevas obras para observar si la mejora se mantiene. No hace falta
volver a guardar esta obra; se conservan por separado los originales de cada ensayo.

## Resultado de Gemini 3.5 Flash-Lite, prompt v0.13

El responsable aporta una nueva respuesta e indica «Se ha usado 3.5 Flash-Lite» desde
los detalles de la aplicación. El JSON declara Gemini pero deja modelo, modo y plan null;
las condiciones externas se conservan en el registro de ensayos. No se atribuye una
conversación nueva ni identidad binaria de adjuntos sin confirmación adicional.

Validación técnica correcta y **cero diferencias** respecto a la referencia inicial aceptada
en jornadas, rangos, denominaciones literales, recuentos, páginas y enlaces de notas de las
19 filas; 2878 versos. Conserva completas las denominaciones de tercetos con serventesio
y sueltos con pareado final, sitúa el acto tercero desde 2017, conserva «romance en -io»
y no inventa la nota 51. No hay formas pendientes con las reglas actuales.

Este resultado resuelve el fallo conocido en esta ejecución; no estima una tasa de acierto
ni acredita todavía mejora generalizable. Es una prueba de regresión tras adaptar el prompt
a los errores observados, no una obra nueva reservada para evaluación independiente.

Original intacto: `docs/importador-metrico/evaluacion/ensayos/anteriores/verdadero-amante-2026-11-02/respuesta-v0.13-gemini-flash-lite-original.json`.
La obra ya está guardada con la respuesta de ChatGPT v0.12: no se reimporta ni se cambia su
copia confirmada. La referencia inicial permanece intacta y sigue alimentando el inventario.
Mantener v0.13 y continuar con otra obra del lote para observar el comportamiento fuera
de este caso conocido.
