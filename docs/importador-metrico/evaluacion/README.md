# Evaluación del importador y de los modelos

Completadas veinte extracciones con GPT-6 High usando el [prompt 0.27](../../../prompts/importador-metrico/extraccion-v0.27.md),
sin reintentos. El [informe del lote](./informes/chatgpt-gpt6-high-v0.27.md) separa lectura,
errores de las ediciones y tareas del importador. Incluye el cotejo de las 38 fotos y un
[registro separado](./ensayos/v0.27/ChatGPT%20GPT-6%20High/revision-transcripcion.json) de las diferencias,
sin corregir los originales ni declararlos gold. El 0.27 es el prompt activo del dashboard.

## Piloto 2: lote independiente

Trece obras de nueve libros que no se usaron para escribir el prompt (Castalia, Cátedra, Crítica
y la Parte XXII de Gredos; incluye a Calderón y Tirso). Las fotos son buenas, como las de uso
real, y la dificultad está en construir el JSON y en decidir a partir de las notas. Su
[manifiesto](./referencias/fuentes-piloto-2.json) da edición, páginas, hash de cada foto y qué
pone a prueba cada obra. *Los locos de Valencia* es un control: mismo texto que en el piloto 1,
ahora con foto buena.

**Con este lote se mide, no se ajusta.** Primero se pasa el 0.27 tal cual. Si después se cambia
el prompt, el cambio se valida en otro lote nuevo, no en este. Las respuestas se guardan en
`ensayos/piloto-2/<modelo-y-modo>/<obra_ref>/intento-01.json`.

Las trece primeras respuestas de Gemini 3.5 Flash-Lite High pasan la validación de estructura
tras la compleción mecánica. Seis tienen avisos de recuento, orden o solapamiento. El cotejo
de la p. 71 de Castalia confirma que *El perro del hortelano* termina en el verso 3383. La
respuesta le añade la redondilla de los vv. 1–196 y la silva de los vv. 197–205, que pertenecen
a *El castigo sin venganza*. La primera respuesta de *El castigo* empieza en el verso 206 y
también pasa la validación de estructura. En ese intento faltaba la foto de la p. 71. Al
adjuntarla, el reintento recupera ambas filas. Para medir cobertura hay que contrastar las
páginas y los extremos con el manifiesto y las fotos. Los originales se conservan en el
[registro del ensayo](./ensayos/piloto-2/Gemini%203.5%20Flash-Lite%20High/registro.json).

### Contraste con GPT-5.6 Instant

Hay un JSON original por cada una de las trece obras (451 filas y 13 notas). Once llegaron en el
primer intento. Los primeros intentos de *Las bizarrías de Belisa* y *Don Gil de las calzas verdes*
produjeron imágenes y no quedó confirmado el modelo efectivo de esas dos respuestas. Se repitieron
en chats nuevos con 5.6 Instant visible antes y después de enviar, pidiendo el bloque JSON en el
chat. El prompt 0.27 se mantuvo íntegro. En *Alcalde* y *Olmedo* se verificó el selector durante
la preparación. Los originales, hashes y condiciones se conservan en el
[registro de GPT-5.6 Instant](./ensayos/piloto-2/ChatGPT%20GPT-5.6%20Instant/registro.json).

Tras la compleción mecánica, los trece JSON pasan el validador de estructura y seis tienen avisos.
Antes de ampliar la revisión de la fuente se preparaban siete vistas previas de GPT y ocho de
Gemini. Al repetir la comprobación local con los mismos originales y el reintento de *El castigo*
con las cuatro fotos, se preparan diez de GPT y nueve de Gemini. En ambos recuentos nuevos se
incluye *Don Gil*, que aún necesita los límites de jornada. Se cotejaron con las fotos las
divergencias que siguen, sin certificar la literalidad completa ni medir el tiempo de revisión.

- **El perro del hortelano, pp. 70–71.** Conserva 48 filas métricas, vv. 1–3383, y la carta en
  prosa entre los vv. 2025 y 2026 como fila sin intervalo. Deja cuatro precisiones de rima en
  incidencias enlazadas a sus filas. La vista previa registra la carta dentro del romance de los
  vv. 1988–2071. El primer
  intento de Gemini falla por orden y solapamiento al añadir dos filas de la obra siguiente.
- **El castigo sin venganza, pp. 71–74.** Conserva las 34 filas, vv. 1–3021, y enlaza las tres
  notas. Trata los superíndices como llamadas, incluido el de «Octava», que Gemini había dejado
  pegado al nombre. Hay diferencias de literalidad en la nota 1, como «Gasparetti» por el impreso
  «Gasparretti». La precisión del v. 2473 sin rima se conserva como incidencia. La vista previa
  prepara las 34 filas y deja seis formas sin resolver, las mismas que en el reintento de Gemini
  con las cuatro fotos. Falta completar la edición base para guardar. La primera respuesta de
  Gemini carecía de la p. 71, por lo que la comparación de cobertura se hace con su reintento.
- **Don Gil de las calzas verdes, p. 69.** La tabla continua contiene los vv. 1–3272 sin encabezados
  de acto. Ambos modelos dejan la jornada sin asignar en las 27 filas y conservan la décima
  intercalada en los vv. 2270–2279. La vista previa de ambos prepara las filas y deja las
  jornadas pendientes de cotejo.
- **Fuenteovejuna, pp. 40–41.** GPT conserva el esquema `bccbbaa;a` en los vv. 2037–2044 y el total
  impreso de `100,01` %. Gemini omite una `a` antes del separador y no recoge la fila del total.
  La vista previa prepara ambos JSON y avisa del total transcrito por GPT.
- **La vida de san Pedro Nolasco, p. 524.** GPT mantiene en el acto segundo las filas de los
  vv. 1390–1587 que continúan la página anterior. Gemini las adelanta al tercero. GPT copia la
  caja de `aBaBCC` en los vv. 1669–1722 y lee `-o` donde la foto dice `-eo` en los vv. 2265–2330.
- **El caballero de Olmedo, Quien todo lo quiere y Los locos de Valencia.** Ambos modelos conservan
  los números impresos que bloquean la vista previa. Se verificaron el recuento de 109 para los
  vv. 787–887 y el inicio 1066 tras 1465 en *Olmedo* (pp. 88–89), el solapamiento del v. 1914
  en *Quien todo lo quiere* (p. 87) y el recuento de 80 para los vv. 1021–1050 en *Los locos* (p. 40).
  Las pruebas con correcciones simuladas preparan *Quien todo lo quiere* y *Los locos* conservando
  las cifras impresas. *Olmedo* trae además localizadores de prosa abreviados como «570 +»,
  algunos entre filas de distinta forma.

## Guardar una respuesta

Usar `ensayos/v0.27/<modelo-y-modo>/<obra>/intento-01.json`, una obra por archivo y sin corregir
el original. Si hay rechazo o respuesta que no sea JSON, conservarla como `.txt`. Un reintento
se guarda aparte. No hace falta añadir carpetas vacías para las obras que aún no se han probado.

La carpeta creada por David está en
[`ensayos/v0.27/Gemini 3.6 Thinking/`](./ensayos/v0.27/Gemini%203.6%20Thinking/).
`las20.json` se conserva tal como estaba (vacío al reorganizar). La primera entrega recibida,
`hastamaestro.txt`, está conservada en `recepciones/` dentro de esa carpeta de modelo, con las
cinco respuestas separadas por obra y un `registro.json` con sus hashes.

Registrar en la evaluación el servicio, modelo efectivo mostrado, modo, tipo de cuenta, fecha,
fotos y versión del prompt. Si no constan, indicar «No consta». La respuesta puede autodeclarar
datos erróneos del modelo: no sustituye lo observado en la interfaz.

## Evaluar

Separar siempre:

1. **Fidelidad a las fotos:** filas, columnas, numeración, denominaciones, notas, esquemas y resumen.
2. **Compatibilidad con el importador:** preparación, equivalencias, avisos y guardado.
3. **Problemas de la edición:** una errata bien transcrita es un acierto de lectura, aunque impida guardar.

Mismas fotos y chat nuevo por obra; conservar el primer resultado y los reintentos. Una salida
que carga no demuestra fidelidad. Una respuesta evaluada no se convierte automáticamente en gold.
Durante el ajuste, repetir casos difíciles y controles; antes de adoptar la versión definitiva,
repetir el lote de veinte. No cambiar validaciones para hacer pasar una lectura defectuosa.

## Dónde consultar

- [Lote de veinte con GPT-6 High y 0.27](./informes/chatgpt-gpt6-high-v0.27.md): resultados, cotejos y preparación real del importador; incluye el detalle de las primeras cinco.

- [Gemini 3.6 Thinking con 0.27](./informes/gemini-3.6-thinking-v0.27.md): primera valoración de cinco obras y cuestiones a vigilar antes de completar las veinte.

- [Seguimiento de las veinte obras](./informes/seguimiento-lote.md): informe generado de guardados y pendientes.
- [Revisión de equivalencias](../equivalencias/revision-equivalencias.md): documento generado para revisión.
- `referencias/extracciones/`: cuatro transcripciones aceptadas, con hashes en `referencias/revision-humana.json`.
- `referencias/normalizadas/` y `referencias/preparadas/`: derivados reproducibles de esas referencias.
- [Ensayos anteriores del prompt](../historico/desarrollo/control-regresiones-prompt.md): proceso y resultados anteriores a esta comparación.
- `ensayos/anteriores/`: respuestas de las pruebas anteriores, copiadas literalmente desde
  los archivos locales. `manifest.json` conserva sus hashes; no son nuevos golds.

Los archivos JSON de seguimiento y decisiones son editables; los informes y derivados se
regeneran con los comandos de [seguimiento](../funcionamiento/seguimiento-e-informe-equivalencias.md).
Los manifiestos de fuentes y las auditorías fechadas en `referencias/` son evidencias del piloto,
no un catálogo vivo ni instrucciones para el modelo.

## Preparación común y condiciones del siguiente ensayo

El evaluador y el dashboard comparten `completarExtraccion`: los campos internos y
los enlaces inversos se completan en una copia. El informe distingue la estructura
original de la estructura tras esa compleción; esta operación no corrige cifras,
esquemas ni decisiones sobre notas y no modifica las respuestas conservadas.

Las fotografías difíciles del piloto son pruebas de resistencia deliberadas. El uso
previsto empleará fotografías completas y legibles. La próxima comparación debe
centrarse en construir el JSON y proponer interpretaciones trazables de las notas,
siempre modificables por quien importa. No se mezcla la prueba de resistencia con
una estimación de rendimiento en condiciones habituales. Las nuevas fotografías se
solicitarán al investigador cuando se prepare el lote independiente.
