# ChatGPT GPT-6 High · extracción 0.27

## Condiciones de la repetición

5 de noviembre de 2026. Repetición autorizada por David de las cinco obras recibidas de Gemini
3.6 Thinking: mismo archivo de prompt 0.27 y las mismas diez fotografías HEIC originales del lote.
Cinco chats nuevos, una ejecución por obra y ningún reintento ni corrección de las respuestas.
No se facilitaron las respuestas de Gemini, sus errores ni ejemplos corregidos.

En la cuenta Plus abierta por David, el selector muestra GPT-6 seleccionado y esfuerzo High.
Se conservan la [captura del selector](../ensayos/v0.27/ChatGPT%20GPT-6%20High/modelo-final.png),
las respuestas, sus hashes y [las referencias de las conversaciones](../ensayos/v0.27/ChatGPT%20GPT-6%20High/conversaciones.json).
El selector también presenta «Límite de uso alcanzado», aunque las cinco solicitudes generan
respuestas completas. La identidad registrada es la selección visible en la interfaz; no se
ha verificado el modelo del backend por otra vía.

La interfaz convierte automáticamente los HEIC a JPG y el prompt pegado íntegro a un adjunto
de texto. Esto forma parte de la prueba del servicio web; no se presume idéntico procesamiento
interno de imágenes en los dos proveedores. Tampoco se controlaron las instrucciones de cuenta,
la memoria o la personalización. Los nombres locales foto-01/foto-02 y los nombres JPG que
aparecen en las respuestas quedan conservados, sin normalizarlos manualmente.

## Resultado

| Obra | Filas / resumen | Cotejo frente a los problemas observados en Gemini |
| --- | --- | --- |
| El caballero del milagro | 23 / 5 | Mantiene los rangos, denominaciones y recuentos correctos; nota 66 sin inventar su cuerpo |
| El favor agradecido | 26 / 0 | No completa los bordes recortados de notas 18, 19 y 22; conserva fragmentos y marca ilegibilidad |
| Laura perseguida | 27 / 7 | Conserva cdcdc y ccddc en nota 32; separa las llamadas 32–34 de las denominaciones |
| El leal criado | 28 / 6 | Nota 5 y localizador 930–934 correctos; conserva 130 en el resumen de octavas y explica la discrepancia con 136 |
| El maestro de danzar | 20 / 8 | Conserva AabBCC y separa la llamada 110 del literal endecasílabos sueltos |

124 filas métricas, 26 filas de resumen y 17 notas conservadas. En los puntos cotejados no se
han detectado los errores de extracción señalados en Gemini. No se declara una tasa del 100 %
de literalidad carácter por carácter ni se convierten estas respuestas en nuevos golds.

La nota 19 de Favor queda como fragmento `aabba (12[ilegible]`, sin inventar el final de la cifra
ni la unión con la segunda línea. La nota 22 conserva AaBbCC y «singularidad», marcando el
fragmento ausente. Los localizadores 888–889, 1056–1109, 1412–1413 y 2175–2176 se mantienen;
las llamadas sin cuerpo no reciben texto reconstruido.

En Laura, las siete referencias de la nota 32 expresan su alcance general y los pasajes
mencionados; no son siete llamadas impresas. La respuesta conserva esta interpretación ya
observada en Gemini y las mismas posiciones, sin inventar un intervalo único para toda la nota.

La revisión de la copia de lectura de Leal a resolución original permite leer **1250–1289**:
coincide con ambas respuestas. Queda resuelta la duda 1280/1289 del primer informe de Gemini;
no se considera una errata ni una corrección silenciosa. Los otros problemas de la edición
(coplas reales y resumen) permanecen separados de los errores de extracción.

## Preparación con el importador

Las cinco respuestas pasan la validación técnica después de la compleción mecánica habitual.
Se ejecutó `analizarEntrada` de la versión `0491f295` con los originales, sin inventar los
metadatos que faltan y sin escribir en Supabase: las cinco preparan sin errores técnicos.

| Obra | Extensión | Forma pendiente en la preparación actual |
| --- | --- | --- |
| El caballero del milagro | 3001 | Tres versos del estrambote, según criterio acordado |
| El favor agradecido | 3126 | 91 versos de primeros tercetos y 43 de los últimos |
| Laura perseguida | 3203 | Ninguna fila pendiente por el problema de superíndices |
| El leal criado | 3387 | Ninguna forma pendiente; persisten avisos de longitud en 475 y 445 versos de coplas reales |
| El maestro de danzar | 3042 | 153 versos del pasaje mixto; los 111 de sueltos ya se reconocen |

**Pendiente del normalizador, no de la transcripción:** en los primeros tercetos de Favor,
la nota dice expresamente «serie de tercetos encadenados», pero termina con «serven[ilegible]».
La regla actual exige una expresión más completa del cierre y deja esos 91 versos sin identificar.
Hay evidencia para identificar la forma independientemente de cuánto pueda saberse del remate.
La extracción de Gemini lograba identificar esa fila a costa de completar el texto recortado;
una mayor cobertura automática en ese caso no significaba una mejor transcripción.

Corrección posterior aprobada el 5 de noviembre: las reglas v0.16 identifican esos 91 versos
como Terceto encadenado, sin arquitectura ni remate. Si la nota sí declara el cierre completo,
se mantiene la regla más específica que registra el remate. La tabla anterior conserva el
resultado del ensayo con v0.15 para no reescribir la comparación original. Cambio probado
localmente; esta comprobación no acredita su despliegue en la web.

## Conclusión y continuación

La misma versión del prompt obtiene aquí lecturas mejores en los errores concretos de notas,
esquemas y llamadas. Es evidencia práctica a favor de GPT-6 High para este flujo. No demuestra
que los fallos dependan exclusivamente del modelo: se comparan servicios/cuentas y una sola
ejecución por obra, con procesamiento de imágenes y configuración de cuenta no aislados.

Mantener el 0.27 para terminar la comparación. No hace falta reescribirlo a partir de esta tanda.
La elección de un modelo recomendado requiere las otras obras y repetir algunos casos difíciles.
Antes de cerrar el importador, separar el reconocimiento explícito de encadenados de la
identificación de su remate en notas recortadas, y tratar las llamadas añadidas al literal sin
alterar la evidencia original. El primer ajuste se implementó después con v0.16, como se indica
arriba; el tratamiento de llamadas añadidas al literal sigue pendiente.

No se han guardado fichas, modificado equivalencias ni cambiado el prompt del dashboard.
