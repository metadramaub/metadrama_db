# Gemini 3.6 Thinking · extracción 0.27

## Primera recepción: cinco obras

Recibidas el 5 de noviembre de 2026 en `hastamaestro.txt`. Servicio/modelo comunicado por David:
Gemini 3.6 Thinking. Tipo de cuenta, fecha de ejecución y posibles reintentos previos no constan.
Las cinco respuestas declaran `extraccion/0.27`. No se ha observado directamente la interfaz del
servicio en esta tanda; no se atribuye el modelo a una autodeclaración del JSON.

Original, respuestas separadas y hashes: [registro de recepción](../ensayos/v0.27/Gemini%203.6%20Thinking/registro.json).
Se conservan los bytes del original y de cada objeto extraído, sin corregirlos. La numeración
`intento-01` significa primera respuesta recibida aquí, no primer intento acreditado en el servicio.

## Resultado provisional

| Obra | Filas / resumen | Lectura de la tabla | Incidencias principales |
| --- | --- | --- | --- |
| El caballero del milagro | 23 / 5 | Coincide con la extracción previa cotejada y las fotos | Ningún fallo detectado en este cotejo; nota 66 del resumen sin cuerpo, correctamente conservada |
| El favor agradecido | 26 / 0 | Rangos, nombres y recuentos coinciden | Completa texto recortado y altera cifras en notas; no es transcripción íntegramente fiel |
| Laura perseguida | 27 / 7 | Rangos y recuentos coinciden | Cambia esquemas en nota 32; incorpora superíndices a tres nombres de forma |
| El leal criado | 28 / 6 | Conserva la continuación de jornada y los problemas normativos de coplas reales | El resumen de octavas dice 130, como la foto, frente a 136 de los rangos; un extremo de rango requiere revisión puntual |
| El maestro de danzar | 20 / 8 | Rangos, recuentos y esquema AabBCC correctos | El superíndice 110 dentro de la denominación impide reconocer una tirada de sueltos |

Las cinco son JSON válidos y pasan la validación técnica tras la misma compleción mecánica
que realiza el importador. Se ensayó también `analizarEntrada` de la versión `0f08ccb6`, sin
red, metadatos inventados ni escritura en base de datos: todas preparan sin errores técnicos.
Esto no demuestra fidelidad ni disponibilidad para guardar una ficha completa de metadatos.
No se han guardado estas obras ni sustituido las importaciones existentes.

## Hallazgos para la revisión

### Notas recortadas de El favor agradecido

- Nota 18: escribe «serventesio final» aunque la fotografía se corta dentro de la palabra
  «serventesio». No declara esa reconstrucción. La nota permite reconocer encadenados,
  pero el final reconstruido no queda acreditado como lectura literal.
- Nota 19: pone `aabba (125)` donde el fragmento visible muestra `(120…`; 125 no queda
  respaldado por la foto. Conserva un marcador de ilegibilidad en otra parte de la nota,
  lo que no justifica completar el borde derecho sin aviso.
- Nota 22: mantiene AaBbCC, pero su final no conserva fielmente el fragmento «singularidad»
  visible. La incidencia de recorte no convierte en literal todo el texto restante.
- Notas 20, 21, 24 y 25: localizadores útiles recuperados; 26–28 se conservan con cuerpo null.
  No hay resumen fotografiado, por lo que `resumen_fuente: []` es correcto.

### Esquemas y enlaces de Laura perseguida

La nota 32 de la foto presenta al principio `ababa, cdcdc` y `ababa, ccddc`. La respuesta pone
`ababa, cdedc` y `ababa, cddcc`. Son alteraciones del esquema, no cuestiones del catálogo.
El esquema preferido mencionado después, `ababa, ccddc`, sí queda conservado.

Además incluye `³²`, `³³` y `³⁴` en `denominacion_literal`, aunque también crea las notas.
Con el normalizador actual quedan sin identificar t02 (260 versos), t19 (78) y t20 (232):
570 versos. Son fallos de separación de la llamada respecto al nombre, no ambigüedades reales
de esas tres formas. La nota 32 enlaza siete filas por su alcance general y pasajes citados;
ese alcance es interpretativo y no debe confundirse con siete llamadas impresas.

### El leal criado: edición y lectura

La nota 5 está correctamente enlazada a 870–999 y localizada en 930–934, sin extender el
localizador hasta 935. No se divide automáticamente el pasaje.
Las coplas reales de 1392–1866 (475 versos) y 2407–2851 (445) siguen generando avisos normativos:
esas cifras están impresas. Tampoco se resuelve la incompatibilidad de la quintilla insertada
en 870–999. Estos problemas no se atribuyen a la lectura de esta respuesta.

En el resumen figura **130** para octavas reales: coincide con la imagen, aunque los dos rangos
suman 136. La respuesta anterior conservada tenía 136 en el resumen; no debe usarse como gold
para penalizar el 130 fiel a la fuente.

Revisión puntual pendiente: el extremo de la fila que empieza en 1250 parece **1280** en la copia
de lectura, mientras ambas respuestas (la anterior y esta) ponen 1289, coherente con el recuento
40 y la fila siguiente. No dar por fiel ese extremo solo por coincidir con la respuesta previa;
verificar el original antes de afirmar una corrección silenciosa de la errata.

### El maestro de danzar

Conserva **AabBCC**, que había fallado repetidamente en las extracciones gratuitas anteriores.
Es un resultado favorable en este ensayo, sin demostrar estabilidad ni aislar el efecto del modelo
respecto al prompt. El pasaje mixto de 1517–1669 sigue sin cortes internos: es lo esperado.

La fila 1670–1780 incluye `endecasílabos sueltos¹¹⁰`. El normalizador no reconoce ese nombre:
añade 111 versos sin identificar a los 153 del pasaje mixto. La nota 110 sí está separada y
con cuerpo null; basta separar correctamente la llamada del literal para evitar ese fallo.

## Cómo continuar

Continuar con las quince obras restantes **sin cambiar el 0.27 a mitad de la comparación**.
Conservar los primeros resultados y anotar reintentos si los hay. No hace falta relanzar estas
cinco ahora ni adoptar otra versión del prompt por estos resultados parciales.

Antes de elegir una versión definitiva habrá que resolver la contaminación de los nombres por
superíndices (extracción y tratamiento seguro en el importador) y verificar que una mejora no
altere cifras o esquemas. No se han modificado el prompt, las equivalencias ni las validaciones
para acomodar esta tanda. No se calcula una tasa global de aciertos con este cotejo preliminar.

El cotejo empleó las diez fotografías JPG de lectura del lote, identificadas por los números
3–7 y los nombres de las fuentes en las respuestas. Los cotejos anteriores son apoyo, no golds
adicionales. Esta recepción no cambia el registro histórico de guardados ni aprueba sus metadatos.
