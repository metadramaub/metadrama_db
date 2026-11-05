# Control de regresiones del prompt de extracción

Acuerdo del 3 de noviembre de 2026: mejorar un caso no autoriza a empeorar obras que ya se
extraían bien. Las pruebas de código del importador no prueban la fidelidad de una respuesta
de Gemini. No activar una revisión solo porque cambia bien un ejemplo del prompt.

## Estado actual

- Activa en el dashboard: **0.15**.
- **0.16 descartada** por regresiones; **0.17–0.25** son candidatas experimentales.
- **0.26** es la candidata para repetir el panel y, si mantiene el resultado,
  probar el lote de veinte. Tiene una revisión opcional para los esquemas de notas.
- Las candidatas conservan el ejemplo de prosa desde la 0.17 y separan las incidencias
  de lectura de las comprobaciones numéricas que ya hace el importador.
- No se modifican las equivalencias ni la validación para hacer pasar una salida defectuosa.

## Panel que debe conservarse

| Caso | Qué vigilar |
| --- | --- |
| El verdadero amante | Asociaciones de columnas, denominaciones partidas y asonancias; éxito previo de 0.13 |
| El molino | Pareados finales, letrilla sin identificar y filas de ambas fotos |
| Los donaires de Matico | Jornadas, 18 filas, 2812 versos y tercetos sin inferir remate |
| Los locos de Valencia | Notas, esquemas y particularidades de la transcripción aceptada |
| Ursón y Valentín | Prosa real sin rango, jornada continuada, aBaBcC, errata conservada e incidencia verdadera |
| Traición acertada (rótulo del lote) | Ausencia de prosa inventada, 18 filas numeradas, nota 21 con tres intervalos y nota 22 sin cuerpo visible |

Las cuatro transcripciones iniciales son referencias aceptadas; los ensayos posteriores no
se convierten por ello en nuevos golds. Ursón conserva una errata de edición: que no pueda
guardarse no supone un error de extracción. Traición v0.15 es una respuesta fallida.

## Comparación antes de activar

Para cada revisión, elegir los casos difíciles afectados por el cambio y controles que
ya salieron bien. El panel reúne casos reutilizables. Cuando haya una versión finalista,
cotejar de nuevo las veinte obras del piloto antes de darla por definitiva.

1. Conservar las mismas fotos, orden, identificadores y metadatos facilitados para ambas
   versiones. Un chat nuevo para cada ejecución evita arrastrar datos de otra obra.
2. Usar el mismo servicio, modelo efectivo, modo y cuenta, registrando lo que realmente
   conste. «Automático» no garantiza que dos ejecuciones hayan usado el mismo modelo.
3. Guardar las respuestas originales completas de la versión activa y la candidata. Cotejar
   todas las filas, no solo el campo que motivó la revisión. Repetir los casos donde aparezca
   una regresión o un resultado inconsistente; una ejecución por versión no prueba estabilidad.
4. Para los cuatro golds, reutilizar `evaluar-respuesta-modelo.mjs`; los cambios de IDs de
   fotografía o los metadatos no facilitados requieren interpretar las diferencias, no editar
   la respuesta o cambiar la referencia para conseguir un resultado favorable. Las notas,
   sus enlaces y las incidencias también requieren cotejo: el texto libre no se valida por igualdad.
5. Registrar por caso: errores de lectura, omisiones/invenciones, formato, enlaces e incidencias
   verdaderas/falsas. No esconder una regresión nueva detrás de una mejora del total.
6. Activar cuando la candidata resuelva el problema y no queden regresiones observadas sin
   resolver en el panel. Si empeora un caso, revisar o descartar la candidata y mantener la
   activa. Conservar las versiones para poder volver atrás.

Este panel se usa para desarrollar el prompt. No es una estimación independiente de exactitud:
los casos y algunos ejemplos ya han intervenido en su redacción. Las obras nuevas permitirán
comprobar después si las mejoras se mantienen fuera de estos casos conocidos.

## Resultado del 4 de noviembre de 2026

Cuatro ejecuciones de la candidata 0.16. David comunica Gemini 3.5 Flash-Lite.
Las respuestas originales se conservan en `backups/importador-local/regresiones-v0.16-2026-11-04/`.

| Obra | Resultado |
| --- | --- |
| Traición acertada | Conserva las 18 filas numeradas, omite la prosa inventada y recupera la llamada 22. Las falsas discrepancias bajan de 18 a 4. La nota 21 todavía abarca un intervalo artificial, carece de dos enlaces recíprocos y altera los esquemas. El validador bloquea la preparación. |
| Ursón y Valentín | Regresión frente a 0.15. Numera la prosa, desplaza denominaciones y el inicio de la jornada tercera, altera el esquema y duplica el tramo final. La incidencia confunde el recuento impreso 28 con 38. |
| El verdadero amante | Las 19 filas coinciden en rangos, formas y recuentos, incluida la asonancia. Cambia la página visible 225 por 226 y toma el 51 de la última fila por una llamada de nota 5. |
| Los locos de Valencia | Las 20 filas y las dos notas coinciden con la referencia tras identificar la misma foto. Añade 10 falsas discrepancias aritméticas. |

La candidata queda descartada para activación. La regresión más grave es la pérdida de
alineación en Ursón tras quitar el ejemplo de continuación. El ensayo documenta el cambio
observado y no aísla su causa, ya que hay una sola ejecución de la candidata por obra.

## Ensayo de la candidata 0.17 del 4 de noviembre de 2026

Dos chats nuevos de Gemini Automático con los HEIC originales. El detalle de ambas
respuestas identifica 3.5 Flash-Lite. Se parte de la 0.15 y se retira la instrucción
general de producir incidencias aritméticas. El borrador conserva una mención puntual
al descuadre en las reglas de transcripción. Las respuestas nombran los adjuntos como JPG.
Se archivan en backups/importador-local/regresiones-v0.17-2026-11-04/.

- Traición acertada conserva las 18 filas, el resumen y los esquemas de la nota 21.
  Cero discrepancias falsas. Duplica la nota 21, conserva su intervalo artificial
  y omite la llamada 22. El validador detecta el problema del localizador.
- Ursón y Valentín conserva las 25 filas, la prosa sin numerar y el esquema aBaBcC.
  Introduce PARTE I como segunda jornada repetida. El validador detecta esa referencia
  duplicada y el descuadre impreso de 28 frente a 118 aunque incidencias esté vacío.

La candidata sigue en ensayo. Estos dos resultados justifican conservar el enfoque
para otra revisión y separar el trabajo de las notas y de las cabeceras.

## Ensayos de las candidatas 0.18–0.20

Fotos HEIC originales en chats nuevos de Gemini Automático. Las respuestas se guardan
en `backups/importador-local/regresiones-v0.18-2026-11-04/` y los directorios
equivalentes para las versiones siguientes. Los archivos de respuesta no se corrigen.

| Candidata | Obra | Resultado |
| --- | --- | --- |
| 0.18 | Ursón y Valentín | 25 pasajes iguales en jornada, rango, literal y recuento a la respuesta de referencia. Solo tres jornadas. Sin errores del validador; conserva la errata impresa y sus tres avisos. |
| 0.18 | Traición acertada | 18 filas y 6 totales. La nota 21 ya tiene los tres enlaces y no fabrica un intervalo, pero la llamada crea una copia vacía («21» frente a «21.» en el pie). Omite la llamada 22. El validador no detecta estos fallos. |
| 0.19 | Traición acertada | Una sola nota 21 con los tres enlaces correctos, esquemas intactos y llamada 22 sin cuerpo. Sin errores del validador. Faltan los avisos de los dos recortes. |
| 0.19 | El verdadero amante | Página 225 correcta y sin nota espuria. Las 19 filas mantienen sus intervalos y formas, pero el primer total queda vacío y toda la columna se desplaza: el validador señala 18 descuadres. |
| 0.20 | El verdadero amante | Las 19 filas coinciden con el gold en jornada, intervalos, formas, recuentos y página. El último recuento es 51; no hay notas espurias ni incidencias de validación. |
| 0.20 | Ursón y Valentín | Conserva los 25 pasajes, las tres jornadas, la prosa sin rango, el esquema aBaBcC y la errata impresa. Sin errores de validación; tres avisos de la errata. |
| 0.20 | Traición acertada | Conserva las 18 filas, los 6 totales, las dos notas y los dos avisos de lectura. La nota 22 no enlaza tramos, pero t18 la cita indebidamente: el validador rechaza el enlace no recíproco. |

Las salidas registran los nombres de los adjuntos como JPG; no es prueba de que se
haya entregado a Gemini una foto distinta. El resultado de cada ensayo describe
esa ejecución, no aísla el efecto del cambio de redacción.

## Ensayos de enlaces desde la 0.21

- **0.21, Traición acertada:** añade una cita al final del bloque, que hace fallar
  el análisis del JSON. Aislando el objeto solo para diagnosticarlo, persiste el
  enlace indebido de la nota 22 a la última fila.
- **0.22, Traición acertada:** al escribir las notas primero, deja la nota 22
  sin enlaces como corresponde. Cambia, sin embargo, una referencia de la nota 21
  de t11 a t12, aunque la fila t11 sí cita esa nota. También altera el cierre
  de un esquema de rima y omite el aviso del recorte de la nota 21.
- **0.23, Traición acertada:** recupera el orden anterior e ilustra juntos los dos
  sentidos de los enlaces. Conserva las filas, el resumen, las dos notas y los dos
  avisos; mantiene el enlace indebido de la nota 22 a t18.
- **0.23 + revisión de enlaces 0.1, Traición acertada:** en el mismo chat, Gemini
  3.5 Flash-Lite vuelve a emitir el JSON y elimina solo el enlace indebido. La
  comparación de todos los campos confirma que no hay ningún otro cambio. El
  validador acepta la respuesta sin errores ni avisos estructurales; se conservan
  en el JSON los avisos de lectura de las fotos. Es una prueba de una segunda
  pasada puntual, no un resultado satisfactorio del prompt principal por sí solo.
- **0.23, controles:** El verdadero amante coincide con el gold en las 19 filas
  y la página. Los locos de Valencia conserva las 20 filas, el texto de las dos
  notas y sus enlaces, pero omite los localizadores 2172 y 2666 en campos propios.
- **0.24, controles:** El verdadero amante conserva las 19 filas y la página
  225. Los locos de Valencia conserva las 20 filas y ambas notas con sus
  localizadores. En ambos se cotejaron todos los campos de filas y notas salvo
  el identificador de fotografía. Ursón y Valentín conserva los 25 pasajes con
  su jornada, rango, literal y recuento; quedan solo los tres avisos de la
  discrepancia impresa. El detalle de Gemini identifica 3.5 Flash-Lite.
- **0.24 + revisión de notas 0.2, Traición acertada:** la primera pasada duplica
  la nota 21. La segunda la unifica, corrige el enlace de t18 y renumera el id de
  la nota 22; no altera ningún otro valor. El validador acepta el JSON. El
  cotejo con las fotos revela que falta una comilla de apertura en la nota 21 y
  que el aviso de la 22 localiza la llamada sin indicar que no se ve su cuerpo.
- **0.25:** Traición conserva la comilla y avisa del cuerpo no visible, pero
  aún requiere corregir el enlace de t18. La revisión de enlaces cambia solo
  ese campo. El verdadero amante vuelve a desplazar la columna de recuentos,
  con 18 avisos del validador. Se descarta esta candidata.

## Panel de la 0.26 con Gemini 3.5 Flash-Lite

La 0.26 añade un ejemplo de detección de una columna de recuentos desplazada.
Se ensayó en Gemini Automático, con las fotos originales y chats nuevos.
Las respuestas sin editar están en `backups/importador-local/regresiones-v0.26-2026-11-04/`.

| Obra | Resultado observado |
| --- | --- |
| El verdadero amante | 19 filas iguales al gold, página 225, último recuento 51, sin notas espurias. Validador limpio. |
| Los locos de Valencia | 20 filas y dos notas iguales al gold, con localizadores 2172 y 2666. Validador limpio. |
| Ursón y Valentín | 25 pasajes iguales en jornada, rango, denominación y recuento a la referencia. Tres jornadas, prosa sin rango y esquema aBaBcC. El validador solo avisa de la errata impresa: 2458–2575 con recuento 28. |
| Traición acertada | 18 filas, 6 totales, las notas 21 y 22 con los enlaces correctos y dos avisos de lectura. Primera ejecución: confunde el corchete con una letra en el primer esquema, pese a pasar el validador. Con `revision-esquemas-v0.1.md`, recupera `[ababa]` y conserva `[aabba]`; la comparación completa confirma que solo cambia ese esquema. |

El identificador JPG asignado por Gemini al adjunto no se compara literalmente
con la referencia interna. No se modifica la versión del dashboard, no se guardan
obras y no se confunde el resultado del validador con fidelidad a la fotografía.

Una segunda ejecución independiente de Traición con la misma 0.26 y el mismo
modelo leyó bien los dos esquemas, pero volvió a duplicar la nota 21 y enlazó
la copia vacía a t18. Además, calificó como no visible un cuerpo que sí se
ve parcialmente. La versión todavía no pasa de forma estable en una sola
pasada. Se conserva la 0.15 activa y se mantiene pendiente el ensayo final de
las veinte obras.

## Primer panel de la candidata 1.0

La 1.0 reúne la lectura de tablas, el tratamiento de notas y la emisión del
JSON en tres pasos con una sola plantilla. Tiene unas 900 palabras frente a
las 4600 de la 0.26. Se conservaron las primeras respuestas de seis chats
nuevos con las mismas fotografías. Gemini identificó 3.5 Flash-Lite en los
seis. Evidencias en `backups/importador-local/piloto-v1.0/`.

| Obra | Resultado de la primera respuesta |
| --- | --- |
| El verdadero amante | Gemini declinó la tarea. La 0.26 había extraído las 19 filas. |
| Ursón y Valentín | Los 25 pasajes y los 9 totales coinciden en contenido con la 0.26 al comparar los números por su valor. Conserva la prosa y la discrepancia impresa. El validador da 38 errores por páginas y recuentos entre comillas. |
| La ingratitud vengada | Validador limpio. Conserva 5 tramos y 2 totales y añade correctamente los localizadores 133 y 832 que faltaban en la 0.26, cotejados con el pie impreso. |
| El mármol de Felisardo | Gemini declinó la tarea. No se pudo comprobar si mejora los enlaces de las notas. |
| La serrana de Tormes | Validador limpio. Escribe `genero_literal` correctamente. Coinciden los 19 rangos, sus recuentos y los 7 totales con la 0.26. Hay diferencias textuales en cinco denominaciones, varias de ellas por saltos de línea. Queda por cotejar el literal y las notas. |
| Jorge Toledano | Los 26 tramos y los 7 totales reproducen los valores de la 0.26. El validador da 19 errores por páginas y recuentos entre comillas. |

Dos respuestas pasan el validador, frente a cinco de las seis con 0.26. El
panel no justifica ampliar el ensayo a veinte. Conviene probar tipos numéricos
con valores de ejemplo en la plantilla y repetir los dos casos sin JSON
antes de atribuir las negativas a la redacción.

## Panel de la candidata 1.01

La 1.01 mantiene los tres pasos de la 1.0 e introduce valores numéricos de
ejemplo en la plantilla. Se enviaron las mismas fotos en chats nuevos.
Se guardaron las primeras respuestas y los reintentos por separado en
`backups/importador-local/piloto-v1.01/`.

| Obra | Primera respuesta |
| --- | --- |
| El verdadero amante | Vuelve a devolver JSON. Las 19 filas coinciden en jornada, rango, denominación y recuento con la 0.26. Página 225. Validador limpio. |
| El mármol de Felisardo | Devuelve JSON con 33 tramos y localiza el v. 655. Añade una décima fila al resumen y desplaza los valores de varias formas. Cambia el singular impreso «redondilla» y sigue omitiendo el segundo enlace al remate. El validador acepta el esquema y avisa de los tres recuentos discrepantes que constan en la edición. |
| La ingratitud vengada | Mantiene 5 tramos, 2 totales y los localizadores 133 y 832. Validador limpio. |
| Ursón y Valentín | Gemini declina la tarea. |
| Jorge Toledano | Gemini declina la tarea. |
| La serrana de Tormes | Gemini declina la tarea. |

Los seis primeros intentos usaron 3.5 Flash-Lite. Tres producen JSON conforme
al esquema, pero el resumen de El mármol impide considerar fiel una de esas
tres respuestas. Sigue pendiente comprobar si los ejemplos numéricos resuelven
los casos que fallaron por tipos en la 1.0. El panel no se amplía al lote de veinte.

En los reintentos, también con Flash-Lite, Jorge volvió a declinar. Ursón
devolvió dos comienzos de objeto anidados, de modo que la respuesta original
falla como JSON. Al aislar el objeto completo solo para diagnóstico, el
validador acepta sus tipos, pero la carta en prosa ocupa los números de la
fila siguiente. Quedan 24 filas en vez de 25. Por tanto, aún no hay una salida
utilizable de la 1.01 para ninguno de los dos controles de tipos.

## Prueba puntual de la candidata 1.02

La 1.02 conserva la 1.01 y añade un ejemplo de una carta en prosa sin números
entre dos filas numeradas. Se prueba con las fotos originales de Ursón y
Valentín y La ingratitud vengada en chats nuevos. Evidencias en
`backups/importador-local/piloto-v1.02/`.

- Ursón y Valentín recupera 25 pasajes. La carta en prosa conserva los tres
  campos numéricos en null y la fila siguiente conserva 1931–1954 y 24 versos.
  El validador acepta el JSON y solo avisa de la errata impresa. El cotejo con
  la 0.26 revela una diferencia en el esquema de liras: aBaBCc frente a aBaBcC.
- La ingratitud vengada recibe una negativa de Flash-Lite en el primer intento.
  En el reintento recupera 5 tramos y 2 totales con los mismos valores de
  la 1.01. Conserva los localizadores 133 y 832 y el validador no emite avisos.

Las tres ejecuciones usaron Gemini 3.5 Flash-Lite. El resultado de Ursón
resuelve el caso de prosa en esta ejecución. La diferencia en el esquema
de liras y la necesidad de repetir La ingratitud impiden dar por estable
la candidata.

En dos chats nuevos con la misma 1.02 y Gemini 3.5 Flash-Lite, la primera
repetición de Ursón devolvió una negativa. El reintento recuperó los 25
pasajes, la carta sin numeración, el esquema literal aBaBcC y los nueve
totales. Los campos cotejados de tramos y resumen coinciden con la 0.26
salvo los identificadores de foto, excluidos de la comparación. El JSON
original fue rechazado porque devolvió obra_ref null. Las dos respuestas
se archivaron como urson-valentin.repeticion.txt y urson-valentin.reintento.txt.

## Panel de la candidata 1.03

Cuatro primeras respuestas en chats nuevos de Gemini 3.5 Flash-Lite, con las
fotos originales. La prueba pasó el texto recibido por la vista previa real
del importador local. Las respuestas y el diagnóstico están en
`backups/importador-local/piloto-v1.03/`.

| Obra | Cotejo y resultado en el importador |
| --- | --- |
| Ursón y Valentín | Recupera los 25 pasajes y nueve totales, la prosa sin números y aBaBcC. Asigna a la jornada tercera siete filas de la segunda. La vista previa bloquea por el descuadre y solapamiento ya presentes en la edición. |
| La ingratitud vengada | Los cinco tramos, dos totales y dos notas coinciden con la referencia, salvo los identificadores de foto excluidos del cotejo. Conserva los localizadores 133 y 832. La vista previa rechaza los cinco segmentos porque sus filas llevan fuente_id null. |
| El verdadero amante | Conserva rangos y recuentos de las 19 filas. Convierte el recuento 220 en una nota que no existe y coloca dos campos bibliográficos dentro de procedencia. La vista previa rechaza esas claves. |
| El mármol de Felisardo | Gemini declina la tarea y no devuelve JSON. |

Las tres extracciones omiten la referencia interna y el importador la completa.
Ninguna de las cuatro llega a una vista previa utilizable por los motivos de
la tabla. El identificador de foto requiere conservar la procedencia real
de cada fila, especialmente cuando se adjuntan varias imágenes.

## Comparación puntual de la candidata 0.27

La 0.27 parte de la 0.26 y delega al importador la referencia interna ausente,
los campos administrativos de procedencia y revisión y los enlaces inversos
de las notas. Se probó una primera respuesta por obra en chats nuevos de
Gemini 3.5 Flash-Lite con las mismas fotos. Respuestas originales en
`backups/importador-local/piloto-v0.27/`.

- Ursón y Valentín reproduce las tres jornadas, los 25 pasajes y los nueve
  totales de la 0.26, incluida la procedencia de cada fila, la carta en prosa
  sin numeración y aBaBcC. La validación solo señala la errata impresa.
- El verdadero amante reproduce las tres jornadas y las 19 filas de la
  0.26, incluida la página 225. No genera notas espurias ni avisos técnicos.

En las dos respuestas falta obra_ref y el importador la completa antes de
validar. Ninguna obra aporta notas en estas fotos, por lo que la prueba no
mide la lectura de enlaces en Gemini. Una ejecución por obra tampoco mide
la estabilidad de la candidata.

### Tres controles de notas con la 0.27

Se repitió el procedimiento con Gemini 3.5 Flash-Lite y las fotos originales.

- La ingratitud vengada conserva los cinco tramos, los dos totales y las dos
  notas. Identifica ambas fotos y localiza los versos 133 y 832. El importador
  reconstruye los enlaces inversos de t01 y t02 y el validador queda limpio.
- Los locos de Valencia conserva los 20 tramos y las notas con localizadores
  2172 y 2666. Se reconstruyen los enlaces de t13 y t16 sin avisos técnicos.
- El mármol de Felisardo recibe una negativa inicial. En un chat nuevo
  reproduce los 33 tramos, pero el resumen desplaza cifras y añade una
  décima fila sin denominación, que el validador rechaza. Cambia dos marcas
  de nota, omite el localizador 655 y mantiene ausente el segundo enlace al
  remate de tercetos de 2826–2931. Se guardan ambos intentos por separado.

Un ensayo adicional con un subagente GPT-6.1 Sol y la misma 0.27 reproduce
las tres jornadas, los 33 tramos y los nueve totales. Conserva las tres
marcas, localiza el verso 655 y enlaza las dos llamadas a la nota del
remate, en t20 y t32. El validador solo señala tres recuentos discordantes
impresos. La respuesta se conserva en
`docs/importador-metrico/evaluacion/ensayos/anteriores/piloto-v0.27/el-marmol-de-felisardo.sol.json`.
Sol leyó las copias JPG locales y heredó contexto sobre los fallos previos,
aunque no consultó las extracciones de referencia. Es un control
diagnóstico, con diferencias de formato y contexto frente a Gemini.

### Ampliación de la 0.27 en Flash-Lite

Se enviaron las fotos HEIC originales por pares en chats nuevos. Gemini
identificó 3.5 Flash-Lite en los cinco primeros intentos y en el reintento.
Los JSON y las identificaciones del modelo se conservan por separado en
`backups/importador-local/piloto-v0.27/ampliacion/`.

| Obra | Fotos | Resultado |
| --- | --- | --- |
| Jorge Toledano | 33, ambas | Primer intento con 25 recuentos distintos del cotejo anterior, desplazados una fila. La repetición recuperó los 26 tramos y los siete totales y pasó el validador sin avisos. |
| La serrana de Tormes | 32, ambas | 19 tramos, siete totales y cuatro notas. Pasa el validador. Corrige por su cuenta 1974–1075 a 1074–1075 dentro de una denominación. La foto confirma que la edición imprime 1974–1075. |
| El dómine Lucas | 28, ambas | Coincide con la lectura anterior en 18 tramos y cuatro totales. Los dos avisos corresponden a recuentos impresos discordantes. |
| El perseguido | 31, ambas | Coincide en 26 tramos y seis totales. Pasa el validador y recupera las llamadas 35–38. El cotejo confirma que la nota 35 se enlazó además a t08, una fila de endecasílabos que esa nota no identifica. |
| El casamiento en la muerte | 34, ambas | 29 tramos y siete totales. Conserva la prosa sin numerar y los avisos por dos recuentos impresos discordantes y el hueco de la edición. La diferencia con la extracción anterior son los paréntesis que conserva en la denominación de la prosa. |

Las cinco respuestas iniciales contienen JSON conforme al esquema después
de completar los campos internos. La comparación cotejó los campos de
transcripción con las respuestas anteriores y las fotos en las diferencias
señaladas, sin considerar equivalentes los identificadores de archivo.
Para comparar Gemini institucional y ChatGPT, usar el mismo prompt 0.27 y
las mismas fotos, un chat nuevo por obra y registrar el modelo efectivo, la
primera respuesta y los reintentos por separado.
