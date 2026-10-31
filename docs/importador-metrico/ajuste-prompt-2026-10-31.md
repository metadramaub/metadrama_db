# Ajuste del prompt · 31 de octubre de 2026

Objetivo autorizado: mejorar la conservación de la información métrica y contrastar las salidas
sin sustituirlas por el gold. Se ha conservado el estado del proyecto en `estado-2026-10-31.md`.
Los casos siguientes son de **ajuste**, no una muestra independiente ni una comparación científica
de proveedores. No se han aplicado migraciones ni guardado nuevas obras en Supabase real.

## Captura y cotejo

Se detectó una limitación en el ensayo anterior: Gemini renderiza el JSON sin cercas como Markdown.
Se ha observado un elemento de cursiva que abarca campos entre asteriscos, por lo que el texto
renderizado no acredita la respuesta literal en las marcas de nota. Se rectificó la atribución
en el informe del 30 de octubre, conservando los archivos. El botón Copiar se pudo pulsar, pero
la API de portapapeles devolvió contenido vacío; no se ha inventado una copia original a partir
del gold ni reconstruido los asteriscos por conjetura.

Desde v0.3 se solicita un bloque de código JSON. La captura se hace desde su `pre code` visible,
comprobando que no contiene formato de cursiva/negrita. El importador ya admite este formato.
El evaluador usa el contenido del bloque para su validación técnica y conserva su formato de salida.

El cotejo ahora presenta además las incidencias de fuente para revisión. No equipara dos redacciones
libres ni considera que todo texto diferente sea un error semántico; una discrepancia impide declarar
automáticamente integridad total. También contrasta observaciones y fuente de los metadatos.

## Versiones ensayadas

| Versión | Cambio | Resultado observado |
| --- | --- | --- |
| v0.2 | Tipos explícitos, estructuras de objetos y cotejo final de filas, recuentos, notas y bordes | Locos mantiene textos, pero su captura renderizada no permite evaluar fielmente marcas. Amante traslada las 19 filas a resumen: versión descartada para uso operativo |
| v0.3 | Bloque de código; distinción de pasajes con intervalo frente a totales; IDs de notas y rangos explícitos | Locos conserva 20 filas, ambas marcas y sus versos; duplica la marca dentro del cuerpo de nota, cambia un singular y omite la incidencia del resumen recortado. Amante conserva 19 pasajes, pero desplaza la columna de recuentos una fila; el validador detecta los descuadres |
| v0.4 | Seguir la inclinación de las filas al asociar columnas; releer ante un posible desplazamiento sin calcular cifras de sustitución; marca separada del cuerpo de nota | Cuatro casos cerrados; resultados desglosados a continuación |

## Resultado de v0.4

| Obra | Filas métricas | Notas y resúmenes | Datos que no conserva |
| --- | --- | --- | --- |
| Los locos de Valencia | 20/20, rangos, recuentos y denominaciones correctos tras corregir el gold | Las dos notas completas, marcas, versos y enlaces correctos | `autoria_procedencia`, `bloque_docx_literal` y aviso de resumen recortado |
| El verdadero amante | 19/19, incluidos todos los recuentos correctamente asociados | No inventa notas ni resumen; conserva los metadatos auxiliares | No declara expresamente que no se aportó un resumen global |
| Los donaires de Matico | 18/18 correctas | 5 filas de resumen correctas | `autoria_procedencia` y `bloque_docx_literal` |
| El molino | 21/21 correctas | 7 filas de resumen correctas | Los dos campos auxiliares y el aviso de que la primera foto no muestra página; conserva la página desconocida como null |

En estas cuatro respuestas no hay errores de formato numérico y no se pierden rangos, denominaciones,
recuentos ni notas métricas. Esto describe estos ensayos, no una garantía de futuras extracciones.
La integridad de todos los campos todavía no está acreditada: el evaluador mantiene visibles
las omisiones auxiliares y el cotejo de incidencias. Por eso v0.4 sigue siendo candidata.

También se detectó un error de la referencia: la foto de Los locos dice «quintillas» en
vv. 2755–2804 y el gold decía «quintilla». David autorizó el 31 de octubre corregirlo.
Se corrigió el literal y su huella, conservando aceptación y hash anteriores en el historial
de `revision-humana.json`; se regeneraron los derivados locales. No se modificó una importación
guardada ni sus equivalencias. La diferencia de plural no era un fallo del modelo.

Se facilitaron el mismo material fotográfico y metadatos, en conversación nueva por caso, con
Gemini gratuito según lo declarado por David, modo visible Automático y modelo exacto desconocido.
No se enviaron las tablas de referencia. Las entradas registran la versión concreta del prompt.
Originales y evaluaciones: `backups/importador-modelos/prompt-v02-20261031/`,
`prompt-v03-20261031/` y `prompt-v04-20261031/`, fuera de Git.

Las diferencias por campo no son errores independientes: desplazar una columna genera muchos
desacuerdos desde una sola asociación equivocada. No se publican tasas ni un ganador de modelo.
La ausencia del resumen recortado es una limitación no registrada, distinta de perder una fila
métrica legible. No se da por alcanzada una extracción sin pérdidas por lograr JSON válido.

## ChatGPT sin sesión

Se abrió ChatGPT sin iniciar sesión. La interfaz ofrece Añadir fotos; la subida de archivos
genéricos pide iniciar sesión. No se concluye de ello que las fotos estén prohibidas.
La carga de la foto mediante WebMCP fue rechazada por la revisión automática porque los bytes
excedían el presupuesto del revisor. No se envió la imagen y no se intentó eludir el bloqueo.
La prueba puede continuar si David adjunta manualmente la foto; no exige iniciar sesión por ahora.

David autorizó expresamente el envío del prompt y los metadatos de Los locos y su foto.
Tras esa confirmación, el borrador se preparó correctamente en ChatGPT sin enviarlo; el rechazo
inicial de autorización del borrador quedó resuelto. La carga de imagen por la herramienta sigue
pendiente del límite de revisión por tamaño, y se pidió adjuntarla manualmente. No hay resultados
de extracción de ChatGPT que comparar todavía.

## Estado de publicación

Los nuevos prompts son candidatos de ensayo. El botón del dashboard sigue utilizando v0.1 hasta
cerrar la comprobación de la versión que lo sustituya. No se cambia el formato de intercambio 0.1
ni se rebaja su validación. El nuevo prompt por sí solo no acredita fidelidad completa.

Comprobaciones de este bloque: las pruebas del importador y de la vista previa pasan (145),
y el ensayo de extracción, normalización y preparación se regenera localmente tras la corrección
autorizada. Antes de cerrar v0.4 falta asegurar los campos auxiliares, los avisos de fuente y
contrastar casos nuevos reservados. No es necesario volver a revisar campos mínimos ni criterios
filológicos ya aprobados.
