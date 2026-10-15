# Respuestas devueltas

Aquí va el Excel que devuelve cada editor, con el mismo nombre con que se le envió
(`<obra>.xlsx`, el de [cuestionarios/](../cuestionarios/)). Se versiona: es el rastro de lo que
se decidió sobre cada obra antes de migrarla. No se edita; si el editor corrige algo, manda otro.

Lo lee `npm run migracion:aplicar -- --obra <obra>` por la columna «Clave» de cada pestaña.

Si se recibe con otro nombre, se normaliza a `<obra>.xlsx` sin alterar el contenido. Las
resoluciones aprobadas sobre notas o correcciones particulares se guardan aparte en
`<obra>.resoluciones.json`: origen esperado, respuesta recibida y destino acordado. También
admite respuestas complementarias del IP, con procedencia y motivo; no se atribuyen al Excel.
El aplicador comprueba los originales y registra ambas fuentes y sus huellas en la base.

Las resoluciones pueden interpretar correcciones en prosa, cambiar arquitectura o elecciones,
localizar una laguna y ajustar rangos y referencias textuales. Cada modificación comprueba el
origen esperado. Para trasladar notas a comentarios públicos se indica un responsable admin/IP;
la autoría sigue siendo del editor asignado y los IDs nuevos quedan en el rastro.

Si el IP autoriza trasladar lo ya anotado sin enviar un Excel, se documenta esa procedencia
en las resoluciones. Se utiliza el cuestionario original sin rellenar mediante `--respuestas`,
sin crear un supuesto Excel devuelto ni atribuir confirmaciones nuevas al editor.
