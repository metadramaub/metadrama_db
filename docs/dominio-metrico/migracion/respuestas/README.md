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
