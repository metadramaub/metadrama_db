# Seguimiento del lote e informe de equivalencias

Dos documentos de trabajo, generados con el mismo comando:

- [Seguimiento de las veinte obras](./piloto/seguimiento-lote.md): guardadas, revisión,
  motivo de aplazamiento y enlace a la importación o al detalle del caso.
- [Documento de revisión de equivalencias](./piloto/revision-equivalencias.md): para enviar
  al IP. Incluye todos los términos de las entradas seleccionadas, las reglas y sus fundamentos,
  todas las formas y arquitecturas del catálogo, los datos adicionales y los casos complejos.
  Puede enviarse solo: reproduce el contenido de los casos complejos antes del anexo.

El documento de revisión se ordena en cinco partes: decisiones pendientes, tabla resumen,
procedencia con uno o dos ejemplos por término, casos complejos y anexo exhaustivo.
Las formas aún no encontradas en las entradas disponibles se listan aparte: no son errores
ni equivalencias que haya que inventar. Cada término enlaza con su procedencia; las candidatas
se señalan expresamente. Las reglas completas, todas las apariciones y arquitecturas y las
huellas de archivos se conservan en el anexo.

Las cuestiones de la primera tabla se mantienen en `piloto/decisiones-equivalencias.json`:
criterio actual, propuesta y pregunta por resolver. Son propuestas para revisión, no cambios
aplicados al normalizador. Se actualizan cuando se toma una decisión para no perpetuar preguntas
ya resueltas. Los casos concretos proceden del documento de casos complejos.

```powershell
npm run importador:informes
npm run importador:informes -- --actualizar-guardados
npm run importador:informes -- --comprobar
```

El primer comando regenera desde archivos. El segundo consulta Supabase con **SELECT** y
actualiza `piloto/registro-guardados.json` antes de regenerar; no cambia datos de la plataforma.
El tercero comprueba que los documentos están al día respecto a sus fuentes locales, sin
escribir ni consultar la red. La fecha de la última consulta remota siempre queda visible.
No hay una tarea programada: se regenera al avanzar con cada obra o cambiar las reglas.

## Qué se mantiene a mano

`piloto/seguimiento-lote.json` es el registro editable: número de fotografías, título,
obra_id cuando se haya confirmado la identidad, revisión, motivo, documento del caso y
entrada original seleccionada. Al guardar una nueva obra se añade su obra_id. Una consulta
remota que encuentra una importación sin vincular la lista al final para revisarla; no la
vincula por parecido de título. El estado de guardado se deriva del registro remoto, no de
la existencia de un archivo de ensayo.

Se conserva una entrada seleccionada por obra para inventariar los términos; si hay varias,
se utiliza la última de la lista `entradas`, sin borrar las anteriores. Las respuestas que
David ha relanzado permanecen intactas. Registrar un ensayo no lo convierte en gold.
La versión del prompt que conste en el nombre del archivo no implica que la obra guardada
se haya recalculado con esa versión. Los cuatro golds iniciales no son las veinte revisadas.

## Qué se calcula

El informe normaliza las entradas seleccionadas con el motor real y las reglas actuales,
conservando el literal y la fila de origen. Inventaría separadamente el catálogo completo:
tener una regla para la forma no completa sus arquitecturas; ser candidata no es disponer
de una equivalencia directa. Las condiciones de nota y las restricciones de ámbito se muestran.

Los casos de versos insertos, agrupación de quintillas o estrambote se deciden en los
documentos de casos y en las reglas, no editando el informe generado. Que una obra se haya
guardado no aprueba sus reglas generales ni identifica todos sus versos.

El catálogo utilizado es una referencia fechada del catálogo activo. Tras cambiar el catálogo
se actualiza esa referencia con el procedimiento del piloto y se regenera el informe.
Las fotos y respuestas de los casos ampliados están fuera de Git: si faltan en otro equipo,
se declara expresamente qué entrada no se ha podido evaluar; no se trata como una obra sin
términos desconocidos. Cada entrada leída queda identificada por su archivo y SHA-256.
