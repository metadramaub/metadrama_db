# ChatGPT GPT-6 High · extracción 0.27

## Lote completo: veinte obras

Completado el 5 de noviembre de 2026: **20 respuestas JSON, sin rechazos ni reintentos**,
447 filas de sinopsis (incluidas las filas de prosa sin numerar), 108 filas de resumen y 37 notas.
Se mantuvo el prompt 0.27 y GPT-6 High seleccionado en veinte chats nuevos. Todos los originales,
enlaces de conversación y hashes están en el registro enlazado más abajo. Las quince respuestas
nuevas amplían la primera tanda; no la sustituyen ni se corrigen sus archivos.

**Compatibilidad:** 19 respuestas cumplen el esquema después de la compleción mecánica; una
es rechazada por un separador decimal fiel a la foto. De las 19, cuatro producen advertencias
por discrepancias impresas. Con las reglas v0.16 y `analizarEntrada` de `145adc0a`, **15 de 20
preparan sin errores técnicos**. Esto no acredita metadatos completos ni autoriza guardar sin
cotejo. No es una tasa de exactitud del modelo.

| Obra | Filas / resumen / notas | Resultado principal de la comprobación |
| --- | --- | --- |
| El caballero del milagro | 23 / 5 / 1 | Prepara; tres versos del estrambote sin identificar por criterio del catálogo |
| El favor agradecido | 26 / 0 / 11 | Prepara; notas recortadas sin reconstrucción y 43 versos de tercetos pendientes |
| Laura perseguida | 27 / 7 / 3 | Prepara; esquemas y llamadas de notas correctos en los puntos que fallaron en Gemini |
| El leal criado | 28 / 6 / 1 | Prepara con avisos normativos de coplas reales; no resuelve el problema de la edición |
| El maestro de danzar | 20 / 8 / 1 | Prepara; AabBCC correcto y 153 versos mixtos sin cortes inventados |
| El verdadero amante | 19 / 0 / 0 | Rangos y recuentos coinciden con la referencia; escribe -ío frente a -io, misma normalización de asonancia |
| Los donaires de Matico | 18 / 5 / 0 | Coincide en campos métricos cotejados con la referencia; tercetos generales sin forzar equivalencia |
| El molino | 21 / 7 / 0 | Coincide en campos métricos cotejados con la referencia; letrilla sin resolver |
| Las ferias de Madrid | 25 / 7 / 0 | Tabla y resumen conservados; el contrato rechaza los apóstrofos de porcentajes impresos |
| El hijo de Reduán | 21 / 6 / 2 | Coincide en tabla y resumen con el cotejo anterior; octavas sin calificativo siguen pendientes |
| El nacimiento de Ursón y Valentín | 25 / 9 / 0 | Conserva prosa sin rango y la numeración impresa; tres advertencias impiden preparar |
| Traición acertada | 18 / 6 / 2 | Prepara; nota 21 única enlazada a tres pasajes y nota 22 solo del resumen, sin prosa inventada |
| El dómine Lucas | 18 / 4 / 0 | Conserva 538 y 176 impresos, incompatibles con sus rangos; dos advertencias impiden preparar |
| La ingratitud vengada | 5 / 2 / 2 | Prepara; notas localizadas en 133 y 832, sin rangos artificiales |
| Los locos de Valencia | 20 / 0 / 2 | Coincide en campos métricos con la referencia; localizadores 2172 y 2666 conservados |
| El perseguido | 26 / 6 / 5 | Prepara; recuentos alineados, notas 34–38 recuperadas y alcance de notas generales por revisar |
| La serrana de Tormes | 19 / 7 / 4 | Conserva 1974–1075 impreso, sin corregirlo; varias denominaciones explícitas aún no tienen regla |
| Jorge Toledano | 26 / 7 / 0 | Coincide con el cotejo anterior correcto, sin desplazamiento de recuentos; sextinas pendientes |
| El casamiento en la muerte | 29 / 7 / 0 | Conserva prosa entre 524–525, hueco 974–977 y dos recuentos discrepantes; tres advertencias impiden preparar |
| El mármol de Felisardo | 33 / 9 / 3 | Recuentos impresos conservados, v. 655 localizado y nota de cierre enlazada a ambas series; tres advertencias impiden preparar |

### Qué ha mejorado y qué queda por revisar

- **Traición:** resuelve el caso que había resistido los ajustes en Flash-Lite. Nota 21:
  t07/t11/t18, localizadores estructurados null porque cita tres intervalos distintos. Nota 22:
  cuerpo null y sin vínculo artificial al último tramo. Los 18 rangos y seis totales se conservan.
- **Serrana:** conserva literalmente `1974-1075` y explica la incongruencia. La respuesta anterior
  de Flash-Lite 0.27 lo cambiaba a `1074-1075`. No se penaliza al modelo por copiar una errata.
- **Mármol:** conserva las nueve filas del resumen, las marcas *, ** y ***, el localizador 655,
  el intervalo 2378–2381 y las dos referencias de la nota **. No repite los problemas de omisión
  y desplazamiento del resumen observados en la respuesta gratuita anterior.
- **Perseguido:** la comparación posterior detecta que el archivo de Flash-Lite 0.27 tenía
  desplazados los recuentos desde t09. GPT los asocia correctamente en el cotejo con las fotos.
  El informe antiguo había dado por buena esa alineación: se anota la rectificación en el histórico.
  La nota 35 se limita a los tercetos; la 36 habla de las cinco tiradas de sueltos, incluyendo
  dos excepciones explícitas sin pareado. Ese alcance documental no autoriza a marcar Dístico
  final presente en todas. El normalizador actual no lo hace, pero tampoco recupera aún los
  cierres positivos de esa nota. La nota 37 se conserva como fragmento recortado.
- **Comparación con las cuatro referencias aceptadas:** rangos, jornadas y recuentos coinciden.
  Hay una diferencia literal en Amante, `-ío` frente a `-io`; no cambia la asonancia normalizada
  pero impide afirmar identidad literal absoluta. Los metadatos procedentes del DOCX inicial
  no se exigen a estas ejecuciones con fotos solas. Los nombres internos de foto pueden variar.

El cotejo combina referencias aceptadas, comparación de campos con ensayos anteriores y revisión
dirigida de las fotografías, especialmente en notas, recortes y discrepancias. Las respuestas
anteriores que no son gold no se utilizan como verdad automática; las diferencias se contrastan.
No se ha realizado una segunda revisión humana exhaustiva de las veinte, carácter por carácter.
No se calcula una tasa global de transcripción correcta ni se certifica el modelo como infalible.

### Pendientes del importador descubiertos por la tanda

1. **Porcentajes literales:** `porcentaje_literal` acepta solo coma, pero el propio prompt exige
   conservar coma, punto o apóstrofo. Ferias imprime `54,6`, `69’2`, `17’4`, etc.; el modelo los
   conserva correctamente y el contrato rechaza seis valores. Hay que adaptar la lectura del
   contrato, manteniendo el original, antes de repetir esa preparación. No hay JSON corregido.
2. **Forma y detalles en una denominación:** en Serrana, cinco filas nombran expresamente
   endecasílabos sueltos y añaden entre paréntesis posiciones de pareados. La forma debería
   reconocerse independientemente de los detalles; un localizador imposible como 1974–1075
   debe conservarse y revisarse sin convertir toda la forma en desconocida. Hoy estas filas
   aportan 430 de sus 719 versos pendientes; los demás corresponden a octavas y tercetos generales.
3. **Notas de alcance plural con excepciones:** documentar por separado dónde se afirma un
   rasgo y dónde se niega, antes de ampliar las equivalencias de Perseguido. No basta encontrar
   la palabra «pareado» en una nota enlazada. Las notas que describen versos aislados siguen
   requiriendo aplicar o revisar las desviaciones, no tratarlas como información ausente.

Son tareas de integración que no se han implementado durante la comparación. El prompt y las
validaciones quedaron congelados en esta tanda; las cuatro obras con erratas de numeración
no se han corregido ni guardado. Las formas «octavas», «tercetos», «letrilla» o «sextinas» no
se fuerzan a otra forma por divisibilidad. La incertidumbre del catálogo es distinta de la lectura.

**Conclusión práctica:** mantener el 0.27 y usar un modelo de esta capacidad resulta más prometedor
que seguir añadiendo instrucciones para cada fallo de Flash-Lite. Falta repetir algunos casos
difíciles para medir estabilidad y resolver las incompatibilidades anteriores antes de activar
la candidata en el dashboard. Estas veinte ejecuciones no sustituyen esa comprobación.

## Detalle de la primera tanda

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
