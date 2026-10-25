# Formato de extracción del piloto 0.1

El intercambio provisional es un JSON por obra. Se genera además una tabla Markdown para el cotejo
humano. JSON conserva notas, resúmenes y metadatos sin convertirlos en filas métricas ni exigir
escapar separadores de tabla. Todavía no es un contrato definitivo del dashboard.

La extracción reproduce la edición. No contiene identificaciones del catálogo. Las propuestas se
guardan aparte en `equivalencias.propuestas.json`; un término sin resolver sigue siendo transcribible.

## Contenido

| Campo | Significado |
| --- | --- |
| `esquema` | `versologia-extraccion/0.1` |
| `obra_ref` | Identificador local estable del ensayo; no es un UUID de Supabase |
| `estado_revision` | Inicialmente `borrador_ia` |
| `revision_humana` | Responsable y fecha nulos, resultado `pendiente`; solo una revisión humana podrá validarlo |
| `procedencia` | Fecha, procedimiento, generador, modelo si se conoce y versión del prompt. Distinguir lectura asistida de ensayo controlado del prompt |
| `metadatos` | Título, autoría del lote, género, fechas, fuente de datación, edición, observaciones y referencia al documento aportado |
| `jornadas` | Número de jornada y rótulo literal del encabezamiento; los límites se derivan aparte |
| `tramos` | Filas métricas en orden de lectura, antes de transformarlas en secuencias del sistema |
| `notas` | Notas de la fuente, con marca, texto, localizador, filas vinculadas y versos expresamente señalados |
| `resumen_fuente` | Totales y porcentajes impresos, separados de los tramos |
| `incidencias` | Ilegibilidad, información ausente o contradicciones conservadas, sin repararlas por conjetura |

Cada tramo contiene `id`, `jornada`, `v_ini`, `v_fin`, `denominacion_literal`,
`n_versos_fuente`, `fuente_id`, `pagina` y `notas_ref`. Una cifra ilegible es `null` y produce
una incidencia. Un valor ausente no se representa como cero. El intervalo es inclusivo.

Cada entrada del resumen contiene denominación literal, total declarado, porcentaje literal,
fuente y página. Se conserva la coma decimal. Se puede pasar `2.060` a entero `2060` cuando
es claramente separador de millares; el total calculado se presenta aparte del declarado.

Se permiten unir palabras partidas por salto de línea, normalizar espacios tipográficos y expresar
los dígitos como enteros. Se conservan singular/plural, paréntesis, tildes, calificativos y marcas
de nota. No se corrige una etiqueta para que coincida con otra ni para que cuadre con el resumen.

Los encabezamientos ACTO/JORNADA se numeran para ordenar el dato, conservando su texto. La página
se rellena solo si se ve; que la foto siguiente sea la 1562 no prueba la página de una foto recortada.
Se fotografía o aporta lo que falte, o se conserva `null` y el nombre de archivo como localizador.

## Fuentes, derivados y revisión

`fuentes.json` relaciona identificadores con nombres relativos y SHA-256 de los originales externos.
No se copian fotografías al repositorio. Las cuatro extracciones iniciales proceden de lectura
visual asistida en este chat: no son cuatro ejecuciones ciegas de un proveedor ni una evaluación
independiente de este prompt. Su modelo exacto no se inventa.

Las notas son evidencia y no nuevas filas automáticas. Una nota que localiza otra forma puede
proponer una partición A → B → A, manteniendo la fila original. Un cambio de medida no se interpreta
por sí solo como cambio de forma. Las propuestas deben revisarse antes de alterar secuencias.

Los metadatos del lote incluyen además el bloque literal del DOCX y una explicación de la autoría
tomada del lote. Son trazabilidad de lo aportado, no decisiones sobre atribuciones de Supabase.

El comprobador local exige los datos transcritos de este primer lote y verifica estructura,
referencias, rangos, continuidad y sumas. No es aún un parser general para salidas incompletas del
prompt. **No certifica el cotejo visual ni promueve un borrador a gold.** Un resumen ausente no
significa que la edición no lo tenga, solo que no se dispone de él en las fotografías del ensayo.

Además del comprobador específico del lote, existe un [validador general local](../validador-local.md)
para entradas del formato 0.1, incluidas extracciones con campos ilegibles a `null`. Distingue errores
de formato, discrepancias y pendientes sin corregir datos. También exporta JSON Schema del intercambio.
No admite identificaciones del catálogo ni aprobación humana dentro de la extracción inicial.
