# El favor agradecido: notas y prompt v0.7

La respuesta v0.6 aportada el 02-11-2026 presenta errores de transcripción de notas, cotejados
con las dos fotografías del lote. La nota 18 mezcla su comienzo sobre tercetos con contenido
de la 19; la 19 omite texto y transforma abaab en abaabb. Las notas 26–28, cuyo cuerpo no se
ve, repiten la denominación de la fila. Los rangos de notas se rellenan con los de sus filas,
incluso cuando el texto cita otros versos (por ejemplo, 1056–1109 o 888–889).

El prompt v0.7 conserva v0.6 como antecedente y añade instrucciones explícitas para:

- Delimitar cada nota por su llamada y la siguiente, sin mezclar notas contiguas.
- Conservar solo lo visible de un recorte con [ilegible] e incidencia; sin cuerpo, texto null.
- No sustituir el cuerpo de una nota por el nombre de la forma de la tabla.
- Respetar exactamente letras y mayúsculas de los esquemas de rima.
- Usar en los campos de versos solo las posiciones expresamente citadas en la nota;
  nunca copiar por defecto el rango de la fila ni tratar recuentos como posiciones.

No hay todavía una nueva ejecución de IA con v0.7; estas instrucciones no acreditan por sí
solas una mejora de fidelidad. La respuesta v0.6 sigue necesitando corrección o nueva extracción
antes de guardar. Una nota truncada no debe completarse con la frase esperada.

## Acuerdo y aplicación

El responsable confirma que la nota de tercetos permite identificar **Terceto encadenado con
remate de un verso (3+1)**, sin arquitectura. Las equivalencias v0.9 aplican esta precisión cuando
una misma nota, enlazada recíprocamente a la fila «tercetos», contiene expresamente «tercetos
encadenados» y «se cierra con un serventesio». No se buscan esas frases en notas de otras filas
ni se asigna esa equivalencia al término «tercetos» sin nota suficiente.

Los esquemas de quintillas y sus cantidades se conservan en el texto: no se crean elecciones
ni se localiza su distribución, pues no constan las posiciones. Tampoco se asignan datos a los
otros tercetos de la obra por analogía.

La transcripción de notas permanece separada de las equivalencias: no se pide a la IA traducir
la forma a nuestro catálogo. La regla nueva no valida ni repara notas contaminadas.

Comprobación: 204 pruebas dirigidas correctas, incluidos identificación y remate desde nota
enlazada, ausencia de propagación a otra fila y conservación de esquemas de quintillas en texto.
