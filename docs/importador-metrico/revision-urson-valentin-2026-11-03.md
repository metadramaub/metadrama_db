# El nacimiento de Ursón y Valentín — aplazada el 3 de noviembre de 2026

El responsable decide no importar esta obra. Respuesta original conservada sin modificaciones
en `backups/importador-local/urson-valentin-2026-11-03/respuesta-v0.13-original.json`.
Servicio declarado: Gemini; modelo, modo y cuenta no comunicados. Prompt v0.13.

## Errores de extracción comprobados en las fotografías

La foto `23_nacimiento_Urson_y_valentin_2.HEIC`, p. 996, continúa la jornada segunda.
La tercera comienza en 2252, no en 1931 como indica el JSON. Al inicio de la foto aparece
una carta en prosa sin rango ni recuento: no tiene 24 versos. La IA le ha asignado el rango
y el recuento de la siguiente fila, desplazando varias denominaciones posteriores.

| Rango | Denominación de la foto | Denominación del JSON |
| --- | --- | --- |
| 1931–1954 | octavas reales (24) | carta en prosa (24) |
| 1955–1970 | endecasílabos sueltos (16) | octavas reales (16) |
| 1971–2042 | liras aBaBcC (72) | endecasílabos sueltos (72) |
| 2043–2082 | redondillas (40) | liras aBabCC (40) |
| 2083–2119 | endecasílabos sueltos (37) | redondillas (37) |
| 2120–2251 | redondillas (132) | endecasílabos sueltos (132) |

Por tanto, la supuesta redondilla de 37 versos que activa el aviso no es una redondilla
irregular declarada por la edición: es una asociación incorrecta de columnas en la extracción.
También se altera la caja del esquema aBaBcC y se traduce parcialmente la etiqueta de
2686–2723 a «endecasílabos sueltos with pareado final»; la foto dice «(con pareado final)».
Estas alteraciones no justifican nuevas equivalencias para aceptar texto ajeno al original.

## Posible errata independiente en la edición

Tras el soneto 2534–2547, la foto imprime redondillas **2458–2575**, con recuento **28**.
Ese rango abarca 118 posiciones y se solapa con lo anterior. 2548–2575 sería compatible con
la continuidad y con 28, pero es una hipótesis, no una corrección comprobada. El JSON ya ha
escrito 2548 sin declarar la discrepancia. Conservar ambos testimonios, sin corregir la edición
ni declarar una laguna o una adición por conjetura.

El responsable solicita mejorar el prompt y relanzar, en vez de dar por cerrado el caso como
error de edición. Prompt v0.14 incorpora un ejemplo de prosa sin rango seguida de tres filas
numeradas y un título de jornada a media página. Exige comprobar las anclas de continuación,
no desplazar nombres, no traducir literales y no reparar un dígito impreso por continuidad.
También aclara los enlaces recíprocos de notas de alcance explícitamente general.

Pendiente ejecutar v0.14 con las mismas fotos y comprobar esas asociaciones contra las imágenes.
Las instrucciones nuevas no demuestran aún mejor rendimiento de Gemini. Se conserva la respuesta
v0.13 como ensayo fallido, fuera de las entradas seleccionadas para inventariar equivalencias:
«with pareado final» y las formas desplazadas no deben contaminar ese documento de revisión.
No se ha guardado la obra ni modificado producción durante este cotejo.

## Resultado recibido con v0.14

Original conservado en `backups/importador-local/urson-valentin-2026-11-03/respuesta-v0.14-original.json`.
Esta ejecución corrige el desplazamiento de formas, la carta en prosa sin rango, la jornada
segunda continuada hasta 2251, el inicio de la tercera en 2252 y el literal del pareado final.

La fila t17 reproduce ahora fielmente **2458–2575, redondillas, 28** de la foto. La validación
genera tres avisos del mismo origen: 118 posiciones frente a 28 declaradas, retroceso después
de 2534–2547 y solapamiento de 90 posiciones. No son tres fallos independientes ni un nuevo
error de transcripción. 2548–2575 sigue siendo una corrección probable sin cotejo textual.

Persisten dos limitaciones de la IA: transcribe `liras aBabCc` donde la foto muestra
`liras aBaBcC`, y devuelve `incidencias: []` sin declarar el descuadre conservado. El formato
es válido, pero la extracción no se considera completamente fiel ni lista para guardar.
Se mantiene fuera de las entradas seleccionadas para inventariar equivalencias.
