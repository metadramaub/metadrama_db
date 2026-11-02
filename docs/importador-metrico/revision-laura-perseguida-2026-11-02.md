# Laura perseguida: enlaces de notas y prompt v0.8

La respuesta v0.7 aportada por el responsable duplica la nota impresa 32: `n01` tiene solo
la llamada y `n04` contiene el cuerpo. La fila t02 enlaza n01, pero n04 afirma enlazar t02
sin reciprocidad. Además, el texto enumera intervalos separados y la IA los convierte en
un único localizador 747–3203, que atraviesa otras formas y no está cubierto por t02.
Ambos avisos del comprobador son correctos; no se relajan para aceptar la extracción.

La foto muestra otros errores de literalidad: se transcribe cddcc en lugar de ccddc en dos
apariciones y aabba en lugar de ababa para las quintillas independientes 3154–3158 y 3199–3203.
Las notas 33 y 34 siguen parcialmente fuera de las fotografías del ensayo. Las fuentes adversas
se conservan como parte deliberada de la evaluación.

El prompt v0.8 añade reglas para actualizar una nota ya creada al encontrar su cuerpo, mantener
la identidad por llamada/fuente/página/continuidad y verificar enlaces recíprocos antes de emitir
el JSON. Para varios versos o intervalos separados mantiene todos los localizadores en el texto,
pero deja v_ini y v_fin null y declara la limitación en incidencias. No usa extremos mínimos y
máximos como si todo el intervalo intermedio estuviera citado. No amplía el formato de intercambio.

El responsable precisa el método del piloto: mejorar el prompt y relanzarlo hasta obtener una
extracción correcta; no sustituir esas ejecuciones por una versión corregida manualmente. Se
conserva `respuesta-v0.7-original.json` en la carpeta privada del caso y queda pendiente la nueva
ejecución v0.8. Ninguna corrección asistida se considera gold ni nuevo resultado de modelo.

Separadamente se corrige la comparación de nombres del importador para ignorar mayúsculas,
manteniendo el literal de origen. Mediante consulta de solo lectura se confirma en el catálogo
la denominación Sexteto alirado → Sexteto-lira y se incluyen singular y plural en equivalencias
v0.11. Esto no debe pedirse a la IA ni mezclarse con el cotejo de la transcripción.

Comprobaciones: 208 pruebas dirigidas correctas. Se regenera el piloto local, sin guardar obras
ni modificar datos remotos. La actualización del prompt todavía requiere su ensayo real.
