# El favor agradecido: notas y prompt v0.7

## Aclaración del piloto y equivalencias v0.10

El responsable aclara que varias fotografías están mal hechas deliberadamente para probar el
prompt en condiciones adversas. En el trabajo ordinario se fotografiará todo el contenido.
Los recortes de este lote son casos de evaluación: interesa medir si la IA marca lo ausente
sin reconstruirlo. No se pide reemplazar estas fuentes de ensayo ni se borra su evidencia;
los fallos de literalidad de v0.7 siguen registrados como resultados de la prueba.

Se solicita reconocer cualquier asonancia explícita. La regla general de romance reconoce
una o dos vocales, con tildes, guion inicial y separación por guion, raya o espacios. Comprueba
el valor y contexto contra el catálogo: las 20 asonancias admitidas se guardan como rasgo;
una combinación reconocible no catalogada se conserva como texto, sin inventar un valor.
No se generaliza automáticamente a otras formas ni a expresiones ambiguas.

«Endecasílabos sueltos con pareado» identifica forma y arquitectura. La posición final se
registra si una nota enlazada declara que la serie está rematada o cerrada por un pareado;
sin esa precisión se conserva el literal y no se afirma un dístico final.

El responsable admite orientar la revisión de tercetos por longitudes 3n+1. Se muestra la
compatibilidad con encadenados y remate de un verso tanto en la tabla sin guardar como en su
editor, manteniendo la forma sin resolver y las candidatas. Se exige longitud mínima de siete
versos para sugerir una serie de al menos dos tercetos más cierre. No es una probabilidad,
una demostración ni un remate anotado: el importador decide expresamente en el editor.
Si ya se ha elegido una forma, la sugerencia desaparece. No se muestra como dato de una copia
guardada ni se conserva en la nota o en los rasgos.

Con la respuesta v0.7: 26 secuencias y 3126 versos; solo quedan pendientes los tercetos
2593–2635 (43 versos). Se registran e-a e i-a y tres dísticos finales explícitos en notas.
Las otras dos filas de sueltos con pareado quedan identificadas, sin afirmar el cierre que
sus notas ausentes no permiten comprobar. Ningún dato remoto se modifica.

## Respuesta v0.7 recibida

Se conserva como `respuesta-v0.7-original.json` en la carpeta privada del caso. La respuesta
mantiene 26 filas y 3126 versos sin huecos ni solapamientos; los rangos y recuentos coinciden
con las fotos. Mejora las notas: separa 18 y 19, conserva abaab, recoge los versos explícitos
888–889, 1056–1109, 1412–1413 y 2175–2176, y deja null las notas 26–28 con incidencias.

Persisten reconstrucciones no señaladas en bordes recortados: la nota 18 termina en la foto
antes de verse completo «serventesio»; la 19 completa la unión de sus líneas a través del borde
derecho y la 22 completa el final de su primera línea. No se certifica literalidad de esos
fragmentos ni se transforma esta respuesta en gold. Solicitar foto completa o conservar solo
lo visible con marca de incompleto; otra ejecución sobre el mismo recorte no recupera el texto.

El validador técnico no da errores ni advertencias. Con equivalencias v0.9 quedan sin resolver
cinco filas «endecasílabos sueltos con pareado», dos romances (e-a e i-a) y los tercetos de la
tercera jornada, cuya nota 27 no está fotografiada. Los primeros tercetos se resuelven por
la nota 18 transcrita; esto no valida el final reconstruido de esa nota.
Los alias y rasgos todavía pendientes pertenecen al normalizador, no requieren modificar
los nombres literales en el JSON. El título se puede precargar desde la cabecera de la foto 2.

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
