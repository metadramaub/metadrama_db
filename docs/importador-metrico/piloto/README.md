# Piloto con fotografías de ediciones críticas

El piloto comienza con las declaraciones de las ediciones. No requiere veinte fichas anotadas
exhaustivamente en el editor de Versología ni una revisión de la métrica contra los textos.
Una extracción cotejada y corregida por una persona será el gold de transcripción. Su normalización
podrá quedar parcial. Las cuatro primeras transcripciones fueron aceptadas sin correcciones por
el responsable del proyecto el 22 de octubre de 2026: [registro de revisión](./revision-humana.json).

## Primer lote preparado el 22 de octubre de 2026

El [informe inicial](./informe-inicial.md) enlaza las cuatro tablas para cotejo y describe los
controles ejecutados. Son 78 filas de sinopsis, antes de aplicar cambios de segmentación. Las
extracciones se conservan en JSON, con metadatos del DOCX, notas, resúmenes y fuentes identificadas
por SHA-256. La salida original conserva el estado de borrador; el registro separado de revisión
identifica por hash cada versión aceptada. Las equivalencias generales siguen pendientes.

- [Formato provisional 0.1](./formato-v0.1.md) y [prompt de extracción](../../../prompts/importador-metrico/extraccion-v0.1.md).
- [Tablas de revisión](./informe-inicial.md), [inventario de términos](./inventario-terminos.md) y
  [propuestas de equivalencia](./equivalencias.propuestas.json).
- [Propuesta de segmentación](./segmentacion.propuestas.json), conservada aparte de las filas fuente.
- [Fuentes del lote](./fuentes.json) y [referencia acotada del catálogo](./catalogo-referencia.json).
- [Primer ensayo de normalización](./informe-normalizacion.md), [su contrato local](../normalizador-local.md)
  y [contraste de los términos ambiguos](./contraste-terminos.md). Las propuestas no cuentan como
  identificaciones revisadas; se conservan todos los versos, incluso los que siguen sin resolver.

La lectura inicial fue asistida en este chat; no se presenta como ensayo ciego del prompt ni como
comparación entre proveedores. La capa normalizada ya permite ensayar correspondencias y
mantener candidatas separadas. El repertorio se ampliará al procesar las veinte obras; estos cuatro
casos también permiten avanzar en el [diseño de integración](../diseno-integracion.md), con métrica
mínima separada de v2 y estructura compartida. En *Los locos de Valencia* ya se acordó tratar el v. 2172 como desviación de metro y
el v. 2666 como adición estructural, manteniendo ambas secuencias. Los 133 versos del tramo de
redondillas contienen 132 posiciones normativas y una añadida: 33 redondillas, sin declarar laguna.

Desde la raíz del repo, `node scripts/importador-metrico/revisar-piloto.mjs` regenera los derivados.
Con `--comprobar --verificar-fuentes` comprueba además que coincidan con los archivos conservados y
que los originales externos mantengan sus hashes, sin escribir ni consultar Supabase. El script
comprueba este lote inicial, no implementa el validador general de un futuro importador.

## Materiales iniciales

La carpeta facilitada por el responsable del proyecto es:

```text
C:\Users\david\OneDrive - UAB\Documents\METADRAMA\VERSOLOGIA\Importador\Importador
```

El inventario inicial de esta carpeta, realizado el 15 de octubre de 2026, localizó un DOCX con
metadatos y 38 fotografías HEIC correspondientes a 20 obras según sus nombres de archivo. Es el
inventario de los materiales de partida, no un recuento del corpus de la base de datos.

Se examinaron seis fotografías de cuatro obras para conversar sobre el diseño: *El verdadero
amante*, *Los donaires de Matico*, *El molino* y *Los locos de Valencia*. Esa lectura exploratoria
no equivale a transcripción validada ni a revisión completa de las obras.

Las fotografías y el DOCX permanecen en su ubicación externa; no se han copiado a esta carpeta.
Los identificadores de [fuentes.json](./fuentes.json) permiten referenciar las imágenes por rutas
relativas y hashes. Se conservan en el repo los JSON de extracción, los derivados de revisión,
las propuestas, el prompt y la referencia consultada del catálogo; los originales gráficos y el
DOCX permanecen externos. La raíz local puede cambiar sin cambiar los identificadores de fuente.

## Recorrido de cada obra

1. Identificar obra, variantes de título, autoría, edición base, fechas y fuente de datación;
   relacionar sus fotografías y páginas. Diferenciar obra de edición evita duplicar el referente.
2. Extraer todos los tramos y notas métricas manteniendo las denominaciones originales, jornadas,
   rangos, totales declarados y localizadores. Conservar la salida recibida y la versión del prompt.
3. Cotejar la extracción con las imágenes, corregir errores y registrar incidencias de la fuente.
   La revisión y su responsable identifican la versión aceptada como gold de transcripción.
4. Reunir el inventario de términos. Aplicar correspondencias revisadas hasta el nivel documentado
   y registrar candidatas o identificación pendiente donde corresponda.
5. Derivar las secuencias según el criterio interno, con trazabilidad desde las filas de la edición.
   No inventar límites cuando una nota no los aporta ni contar los resúmenes como nuevos tramos.
6. Calcular cobertura y primeras medidas. Conservar la versión de datos, catálogo y reglas empleada.
7. Ensayar perturbaciones de lo conocido y límites de las lagunas sistemáticas como experimentos
   separados, con sus parámetros y resultados reproducibles.

## Casos que el material ya permite ensayar

- Variación entre denominaciones generales y específicas, como «tercetos» y «tercetos encadenados».
- Declaraciones con detalles adicionales, como pareado o serventesio final, y asonancias indicadas.
- «Letrilla» en *El molino*: conservar la declaración y examinar sus correspondencias sin dar por
  establecida ninguna forma ni su carácter cantado.
- Notas sobre versos excepcionales dentro de una tirada en *Los locos de Valencia*.
- Totales y resúmenes porcentuales para contrastar la extracción sin duplicar los versos.
- Variantes de título y dataciones alternativas en el DOCX. El intervalo 1995–1995 de *El casamiento
  en la muerte* requiere revisión de metadatos; no se sustituye automáticamente por otra fecha.

Estos casos orientan las pruebas. No constituyen decisiones filológicas aprobadas sobre sus destinos.

## Evidencia que deberá acompañar a los resultados

Se conservarán el inventario, la extracción recibida, la transcripción corregida y su revisión,
las correspondencias aplicadas con su fundamento y versión, y el conjunto derivado para analizar.
Los ensayos del prompt identificarán el proveedor/modelo declarado y las obras empleadas para ajuste
o evaluación. Los experimentos identificarán datos de referencia, perturbaciones, semillas cuando
haya azar y medidas comparadas. No se registrará una autoevaluación de confianza de la IA como
probabilidad calibrada.

El primer informe distinguirá qué proporción se identifica en cada dimensión, qué términos
concentran lo pendiente y cuánto pueden cambiar las conclusiones por ello. Una identificación
que nunca se ha resuelto no sirve como verdad oculta para medir un error empírico: en ese caso
corresponden límites o escenarios.
