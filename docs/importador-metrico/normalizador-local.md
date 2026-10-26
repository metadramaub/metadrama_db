# Normalizador local del piloto

El normalizador convierte las cuatro transcripciones aceptadas en **borradores de normalización**
trazables. Conserva metadatos, fechas, jornadas, filas, notas y rangos; no crea obras en Supabase.
El primer resultado está en el [informe del lote](./piloto/informe-normalizacion.md).

```powershell
node scripts/importador-metrico/normalizar-piloto.mjs
node scripts/importador-metrico/normalizar-piloto.mjs --comprobar
```

El primer comando regenera los JSON y los informes de `piloto/normalizadas/`, el resumen del
lote y el MD de apoyo al prompt. El segundo contrasta sus contenidos sin escribir. La CLI
verifica antes de generar que los archivos de extracción coincidan con los SHA-256 aceptados
en `revision-humana.json`; no basta con conservar el nombre del archivo. Cada salida registra
también hashes de las reglas, catálogo, decisiones de desviación y revisión de transcripción.
La bibliografía consultada queda identificada en `piloto/bibliografia-contraste.json`; sus hallazgos
se enlazan desde las reglas y el normalizador rechaza referencias inexistentes. La biblioteca
se consulta en solo lectura; el normalizador trabaja con ese registro y no configura sincronización.

## Contrato provisional

La salida usa `versologia-normalizacion-local/0.1`. Es un ensayo del contrato de integración,
no el formato definitivo de la DB ni un cuerpo válido para la API del registrador completo.
La propuesta posterior de [campos mínimos y conexiones](./campos-minimos.md) define el destino
de estas interpretaciones: tabla mínima separada, fuentes conservadas y validación para el corpus.
El normalizador actual no escribe ese modelo ni acepta una obra para el corpus automáticamente.

- `identificacion_revisada` solo se rellena para una correspondencia única con aprobación
  explícita en la regla: responsable, fecha y fundamento. Puede identificar una forma sin
  seleccionar arquitectura. La aceptación de la transcripción no rellena este campo.
- `propuesta` guarda por separado el destino único pendiente de aprobación.
- `candidatas` conserva posibilidades orientativas sin convertirlas en formas identificadas.
  Ni su número ni su orden representan probabilidades. No se usan para cerrar límites de un
  cálculo cuando su exhaustividad no está justificada.
- `sin_resolver` no crea una forma del catálogo. El segmento permanece en su jornada, con su
  denominación de fuente y con todos sus versos.
- `detalles_fuente` conserva precisiones como «pareado final» sin dar por respondidas preguntas
  del editor ni afirmar ausencia de otros rasgos. No se infiere canto.
- `desviaciones` aplica las decisiones acordadas, enlazadas con fila y nota. En *Los locos*
  se conservan el heptasílabo de v. 2172 como desviación de metro y el v. 2666 como adición
  estructural. El tramo de redondillas mantiene 133 versos: solo la comprobación de su norma
  descuenta la posición añadida. No se reduce la extensión de la obra ni se parte el tramo.

Por ahora, cada fila fuente conserva un segmento provisional. No se pretende haber resuelto
con ello la segmentación definitiva de todas las fichas, ni se generan realizaciones completas
de sus estrofas a partir de divisiones aritméticas.

## Reglas y ámbito

Las reglas se conservan en [equivalencias.propuestas.json](./piloto/equivalencias.propuestas.json).
Se busca el literal explícito, sin resolver semejanzas ortográficas ni usar la longitud para
escoger una forma. Una regla puede limitarse a una lista de obras mediante `ambito.obras`;
la extensión futura a una edición o familia editorial requiere definir ese ámbito con evidencia.
Dos reglas aplicables al mismo literal son un conflicto que hay que resolver, no una prioridad
silenciosa. Todo destino debe existir en la referencia del catálogo y la arquitectura debe
pertenecer a su forma.

El MD [de apoyo al prompt](../../prompts/importador-metrico/referencia-equivalencias-v0.4.md)
se genera desde esas mismas reglas. No se mantiene un segundo repertorio manual. Es apoyo
para la normalización posterior a la extracción literal; no cambia el contrato del primer prompt.

La regla de estancias está aprobada al nivel de forma: Canción, sin arquitectura, con remate
declarado en pareado. No se exige consultar el texto para aplicarla. Las otras reglas generales
siguen pendientes. La lectura bibliográfica se documenta en
[el contraste de términos](./piloto/contraste-terminos.md). «Letrilla» tiene candidatas orientativas;
«tercetos» conserva su ambigüedad sin un cotejo textual obligatorio.

## Cobertura y límites

Se informa por separado de forma revisada, arquitectura revisada, forma solo propuesta,
arquitectura solo propuesta, candidatas y términos sin resolver. Las arquitecturas son un
subconjunto de sus formas: sus filas no se suman como categorías independientes. No se calcula
un porcentaje único de confianza ni un umbral de utilidad del corpus.

El denominador es la unión de los rangos conocidos. Un segmento sin rango sigue siendo
desconocido, no un tramo de cero versos. La herramienta rechaza discrepancias técnicas del
validador antes de generar perfiles: no usa intervalos solapados o recuentos discordantes para
producir porcentajes aparentemente correctos. Esto no desacredita la edición: obliga a resolver
su representación antes de continuar ese ensayo.

Los resultados conservan `apta_para_corpus: false`: aprobar algunas correspondencias no
equivale a aprobar automáticamente la futura elegibilidad de la obra para cada análisis.

## Código y pruebas

El [núcleo](../../scripts/lib/importador-metrico/normalizacion.mjs) no tiene acceso a archivos,
red ni DB. La [CLI del piloto](../../scripts/importador-metrico/normalizar-piloto.mjs) lee los
materiales locales y produce derivados reproducibles.

```powershell
npx vitest run scripts/lib/importador-metrico/normalizacion.test.mjs scripts/lib/importador-metrico/validacion.test.mjs
```

Las pruebas comprueban conservación de fuentes y versos, propuestas frente a identificaciones
revisadas, aprobación con ámbito, términos desconocidos, los tres casos ambiguos, referencias
inválidas y las dos desviaciones acordadas.
