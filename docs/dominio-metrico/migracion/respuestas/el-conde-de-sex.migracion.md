# Migración de El conde de Sex

Aplicada el 15 de octubre de 2026 a partir del Excel de Rosa Bono y las resoluciones del IP.

- **28 de 28 secuencias**, sin fusiones ni divisiones; 166 realizaciones, 118 respuestas y
  ninguna desviación. Se conservan las 25 confirmaciones del Excel.
- **115–240:** silva consonante de orden libre, densidad Mayoritaria y pareados Predominantes.
  La organización en pareados procede de una indicación expresa de David, guardada aparte del
  Excel. La densidad es la que confirma Rosa.
- **1323–1326:** redondilla abrazada, abba.
- **1329–1368:** ocho quintillas ababa, sin excepciones.
- **2905–3092:** último romance corregido desde 2905–3093. El total de la obra y el final de la
  tercera jornada y su último cuadro quedan también en 3092. No se renumeran los versos previos.
- **1301–1304:** no se añade Cantado, por indicación del IP. Se conservan la sinopsis y el
  comentario interno que describen el canto. Rosa comprobará y añadirá la marca en el editor
  si corresponde. Tampoco se añade Cantado en la repetición del mote, 1323–1326.

## Verificación

Copia completa de esquema, datos y roles; snapshots anterior y posterior; ensayo íntegro con
rollback antes de aplicar. Comparados todos los datos originales, las 28 anotaciones y sus
respuestas con el plan guardado. Los 28 rastros conservan las fuentes y decisiones. Las otras
136 obras permanecen iguales. No se han añadido caracterizaciones ni cambiado comentarios.

Pruebas del aplicador: 36 correctas. El SQL del ajuste de cierre se ejecutó en el ensayo y
en la aplicación definitiva. Revisión de código con ESLint sin avisos.

La auditoría detectó un falso positivo en el pareado consonante 1887–1888: exigía las vocales
de asonancia sin atender a la condición de esa pregunta. El auditor se ajustó para consultar
la misma función de régimen de rima que utiliza el guardado; no se añade una respuesta de
asonancia a la anotación consonante.
La auditoría final mantiene los ocho avisos anteriores de otras obras, sin ninguno en
El conde de Sex.

## Revisión de Rosa

Comprobar la silva 115–240, la redondilla 1323–1326, las quintillas 1329–1368 y el cierre
2905–3092. Revisar la marca de canto pendiente en 1301–1304. Las anotaciones sobre género de
los personajes se revisan por separado, conforme al aviso general al equipo.
