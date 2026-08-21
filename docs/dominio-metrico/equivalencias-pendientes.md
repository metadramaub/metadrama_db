# Equivalencias pendientes entre el vocabulario legado y el catálogo

Estado: **abierto, a completar por el IP** · actualizado el 9 de agosto de 2026

> **Las cifras no están aquí.** Cuántos términos declaran destino, cuáles no, cuánto se usa
> cada uno y cómo resuelve cada secuencia se consultan en
> **[informe-equivalencias.md](./informe-equivalencias.md)**, que genera
> `npm run equivalencias:informe`. Este documento explica **por qué** faltan los que faltan y
> **qué decidió el IP**; eso no lo puede generar un script.

Desde el 4 de agosto de 2026 **no queda ninguna secuencia sin resolver**, y lo que sigue
abierto no bloquea la migración: son decisiones de modelado sobre términos que casi nadie usa,
más las [cuestiones para el IP](./historico/cuestiones-por-forma-2026-08.md).

> **Las cifras de uso cambiaron dos veces el 4 de agosto.** Primero al retirarse «Los
> ramilletes de Madrid (prueba)», la obra de pruebas del proyecto, cuyos datos eran
> inventados: se llevaba 44 secuencias y era la única que escogía raíces genéricas, así que
> `decima`, `romance`, `octava_real`, `pareado_octosilabo`, `terceto`, `soneto` y `silva` se
> quedaron sin uso real. Después al borrarse las cuatro secuencias de prueba de
> Fuenteovejuna, que se volverán a introducir con el modelo nuevo. El corpus queda en **212
> secuencias sobre 10 obras**, y el de verdad siempre elige una hija concreta.

## El problema no es solo que falten: es que el mapa no puede expresarlos

El mapa vigente es `origen_termino_id`, **una columna única en el destino**. Eso permite
decir «esta arquitectura viene de aquel término», pero **no permite que varios términos
legados apunten al mismo destino**, ni que un término apunte a un destino compuesto —una
arquitectura más un juego de respuestas—. Y la ontología hizo exactamente eso a propósito: disolvió la
medida en la arquitectura y los esdrújulos en un rasgo, de modo que varios términos viejos
colapsan en uno nuevo.

Los tres casos comprobados el 4 de agosto:

- **Endecasílabo suelto** tiene **una sola arquitectura**, «Endecasilábica», y la reclama
  `endecasilabo_suelto_puro_sin_distico_final`. Los otros cinco hijos se quedan fuera —
  incluido `endecasilabo_suelto_puro`, **que es el único que se usa, con 6 secuencias**.
- **Pareado** tiene una sola arquitectura, «De cualquier medida», y la reclama el padre
  `pareado_de_arte_menor`. Sus dos hijos no pueden reclamarla. *(Resuelto el 4 de agosto: la
  forma reclama `pareado_endecasilabo` y los hijos resuelven por ascendencia.)*
- Los valores de rasgo **«Agudo» y «Esdrújulo» no declaran origen ninguno**, y necesitan
  recibir seis términos `*_de_esdrujulos` a la vez.

Consecuencia: parte de los que faltan no son un olvido sino **un límite de forma del mapa**.
`migracion_termino_destinos` existía justamente para lo de varios a uno, pero **ya no
existe**: se retiró con la matriz de importación y no está en el esquema (comprobado el 4 de
agosto). Hoy no hay ningún sitio en la base donde escribir una correspondencia compuesta.
Hay que decidir si se recrea esa tabla, si se admite una lista en el destino, o si esas
correspondencias se resuelven solo en el script de backfill.

Añadido: `origen_termino_id` registra supervivencias y transformaciones, **nunca
disoluciones**. Un término que desapareció a propósito, porque su contenido se disolvió en otro
nivel, es en la base indistinguible de un olvido: las dos cosas se ven como una columna a nulo.

**El 9 de agosto se comprobó que ese razonamiento se había aplicado mal a tres términos.**
`redondilla_hexasilaba`, `redondilla_heptasilaba` y `silva_libre` se daban por disueltos, pero
sus destinos existían con el mismo alcance y el mismo nombre —`Redondilla · Hexasilábica`,
`Redondilla · Heptasilábica`, `Silva · Libre`—: no eran disoluciones sino supervivencias sin
declarar. Ya lo declaran. *Conviene la misma comprobación sobre el resto de columnas a nulo
antes de concluir que un término se disolvió.*

La intención está escrita para los 28 en
[la matriz de reclasificación](./historico/matriz-reclasificacion-formas-metricas.md), del
28 de julio, declarada «propuesta para revisión del IP; no aplicada». Es dos días anterior a
la revisión de la ontología y **la contradice en cuatro casos**.

## Dónde vive el sistema de equivalencias

Lo resuelve la vista **`propuesta_metrica_secuencia`**, y de ahí lo leen sus dos consumidores:

- la **anotación en sombra** del dashboard;
- el comando **`npm run migracion:informe`**, que escribe [los informes por obra](./migracion/).

El reparto por vía, siempre al día, está en
[el informe generado](./informe-equivalencias.md#cómo-se-resuelve-cada-secuencia).

Y una vista hermana, **`propuesta_elecciones_secuencia`**, deduce además **las respuestas**
que el término legado ya contenía: **91 en total**, entre 71 asonancias de romance y 20 de
ámbito unidad —los cuartetos y los tercetos de siete sonetos, tres tipologías de sexteto-lira
y la medida y la rima del pareado endecasílabo—. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad:
si contiene varias, el término legado decía una sola cosa de todas ellas y darla por buena
afirmaría que son idénticas.

Esa vista bebe de dos sitios, porque `origen_termino_id` no llega a todo:

1. **Lo que se deduce siguiendo `origen_termino_id`** hasta la opción que selecciona esa
   entidad. Sirve mientras la correspondencia sea de uno a uno.
2. **`equivalencias_respuestas_legadas`**, una tabla que declara a mano lo que un término
   implica cuando varios términos comparten destino y la columna única no da de sí. El caso
   que la hizo necesaria: los cuatro términos específicos de soneto empiezan por `ABBAABBA`
   y por tanto implican cuartetos abrazados, pero el esquema «Abrazada» solo puede declarar
   un origen y esos términos ya están reclamados por sus esquemas de tercetos.

Es la respuesta, acotada a respuestas, a la limitación de varios a uno que aparece también
en el endecasílabo suelto, el pareado y los esdrújulos. Solo se rellena con lo que el término
dice sin lugar a duda, y cada fila lleva su justificación en `nota`.

Las dos clases se rellenan solas en el formulario. Las de unidad se aplican cuando el editor
materializa las unidades, que es cuando existen: una pregunta sin sección va a la unidad
entera y una anclada en una sección, a las realizaciones de esa sección, con el mismo
criterio que usa la función de guardado.

**Hay una sola fuente: la vista.** Desde el 4 de agosto el informe no calcula nada — consulta
`propuesta_metrica_secuencia` y se limita a redactar. Cambiar una regla es cambiar la vista, y
los dos sitios cambian a la vez. El procedimiento completo está en
[cómo se migra una obra](./como-se-migra-una-obra.md).

Las tres vías:

| Vía | Qué significa |
| --- | --- |
| `directa` | Algo del catálogo reclama el término y de ahí sale la forma |
| `rasgo` | Lo reclama un valor de rasgo o un metro, que no dicen forma: esa viene del padre y el término aporta precisión. Es el caso de los romances y su asonancia |
| `ascendencia` | No lo reclama nadie, pero sí un ascendiente. Da forma y arquitectura, **no las respuestas** |
| `sin_destino` | Nadie lo reclama en toda su línea |
| `sin_tipo` | La secuencia no declara forma |

## La jerarquía ya lleva la respuesta en casi todos

Medido el 4 de agosto sobre los 28 términos que entonces no declaraban destino. Si, cuando un
término no tiene reclamación directa, se sube por `termino_padre_id` hasta encontrar un
ascendiente que sí la tenga, **24 de aquellos 28 se resolvían solos**: redondillas, pareados,
canciones, sonetos de esdrújulos, irregulares, copla real de pie quebrado, silva libre y los
seis hijos del endecasílabo suelto.

**Desde el 9 de agosto son 27**, porque `redondilla_hexasilaba`, `redondilla_heptasilaba` y
`silva_libre` pasaron a declarar destino directo en vez de resolverse por ascendencia.

Sobre las secuencias reales, tras resolver la décima y el pareado endecasílabo y retirar los
datos de prueba, el resultado es **212 de 212**.

Dos advertencias:

- La ascendencia da **forma y arquitectura, no las respuestas**. Un `endecasilabo_suelto_puro`
  resuelve a «Endecasílabo suelto · Endecasilábica», pero «¿hay pareados intercalados?» y
  «¿dístico final?» las sigue contestando el editor. Rellenarlas automáticamente exige un
  mapa compuesto, que es otra cosa.
- La propuesta debe **declarar que viene por ascendencia** y no hacerla pasar por directa.
  Si no, el recuento de la fase 0 contaría como acierto algo menos preciso de lo que parece.

Subir al padre tiene un límite que conviene no confundir: una **raíz** sin reclamación
directa parece huérfana aunque todos sus hijos estén mapeados, porque no hay adónde subir.
Es el caso de `romancillo`, cuyos dos hijos reclaman ya las arquitecturas Hexasílabo y
Heptasílabo del romance. No es un hueco: es una raíz disuelta.

Huérfanos quedan **dos**, ninguno en uso: `doble_sextilla` (0) y `copla_manriqueña` (0).

`pareado_endecasilabo` se resolvió el 4 de agosto. Su única secuencia mide **dos versos** y
está aislada entre dos romances octosílabos —El conde de Sex, vv. 1887-1888—, así que no es
el extremo del continuo endecasilábico de Morley y Bruerton sino un dístico. Le corresponde
la forma Pareado, que el catálogo define más ancha que M&B a propósito, con la medida y la
rima declaradas como respuestas.

Con eso **toda secuencia resuelve**; el reparto por vía, en
[el informe](./informe-equivalencias.md#cómo-se-resuelve-cada-secuencia). Las tres que no
declaraban forma eran datos de prueba de Fuenteovejuna y se borraron el mismo día.

## Qué falta, término a término

**No se escribe aquí: se genera.** El estado —qué términos declaran destino, cuáles no, cuánto
se usa cada uno y cómo resuelve cada secuencia— está en
**[informe-equivalencias.md](./informe-equivalencias.md)**, que produce
`npm run equivalencias:informe` consultando la base.

Vivía en este documento en tres tablas, y sus cifras se repetían además en el plan de migración
y en el estado del catálogo: cuatro copias que había que corregir a mano y que caducaban por
separado cada vez que se aplicaba una migración. **Al generarlo por primera vez, el 9 de agosto
de 2026, apareció que la familia de la redondilla eran 62 secuencias y no 63**: el 63 venía de
antes de retirarse la obra de pruebas, y nadie lo había vuelto a contar.

Lo que sigue en este documento es lo que **no** puede generarse: por qué faltan los que faltan,
y qué decidió el IP sobre cada uno.

### Los que esperan decisión, y por qué

Agrupados por la razón de que falten, que es lo que determina cómo se resuelven:

**a) El destino no existe todavía: hay que decidirlo.** `copla_real_de_pie_quebrado`, y tres
hijos del endecasílabo suelto —`_encadenado`, `_con_pareados`,
`_con_pareados_y_sin_distico_final`—. La matriz de julio proponía crear una arquitectura para
cada uno; la ontología del 30 de julio los convirtió en rasgos del pasaje, de modo que la
arquitectura que la matriz daba por hecha no existe. El rasgo «Pie quebrado» de la copla real
existe **sin ningún valor**.

**b) El destino existe pero ya lo reclamó otro término.** Es el límite del mapa descrito arriba,
no un olvido. Lo sufren `endecasilabo_suelto_puro` —el único de los cuatro que se usa, con 6
secuencias—, los dos hijos del pareado y los **seis términos `*_de_esdrujulos`**, que necesitan
apuntar todos al mismo valor de rasgo.

**c) Disoluciones deliberadas.** No hay destino porque no debe haberlo; el detalle, más abajo.

## Resueltos por el IP el 4 de agosto de 2026

| Término legado | Propias | Familia | Decisión |
| --- | ---: | ---: | --- |
| `redondilla_cruzada` | 0 | **63** | Esquema de rima `abab` de la redondilla. Es exactamente la misma cosa que la cuarteta: «redondilla cruzada» es el nombre preferente y «cuarteta» el que se usa hoy. En el catálogo va como denominación del esquema cruzado, porque en el Siglo de Oro ambas disposiciones eran redondillas. No confundir con la forma «Cuarteto», que es otra cosa |
| `decima` | 0 | 18 | **Aplicado** en `20260804110000`. Una sola forma **Décima** con dos arquitecturas: **Espinela** (10 versos, principal) y **Aumentada** (12). La raíz legada y `decima_espinela` eran el mismo texto con el mismo patrón, no una forma general. La aumentada vuelve dentro porque la extensión la declara la arquitectura, no la forma —igual que la redondilla, de cuatro versos, aloja «Doble enlazada», de ocho—. No se creó arquitectura genérica: en el corpus no hay ninguna décima de diez versos que no sea espinela. La definición lleva la articulación 4 + 2 + 4 y no solo la medida, porque la copla real es también diez octosílabos consonantes y se separa por la pausa (5 + 5) |
| `decima_espinela` | — | — | Arquitectura «Espinela» de Décima; conserva su nombre como denominación |
| `decima_aumentada` | — | — | Arquitectura «Aumentada» de Décima; conserva su nombre como denominación |

## Disoluciones deliberadas: no hay destino porque no debe haberlo

| Término legado | Propias | Familia | Decisión de la matriz |
| --- | ---: | ---: | --- |
| `irregular_arte_mayor` | 0 | 1 | Fundir con Versificación irregular; el arte se conserva o se deriva como observación |
| `irregular_arte_menor` | 0 | 1 | Ídem |
| `irregular_mixto` | 0 | 1 | Ídem |
| `cancion_de_8_versos` | 0 | 0 | Extensión observada de la estancia; no identidad propia |
| `cancion_de_9_versos` | 0 | 0 | Ídem |
| `cancion_de_15_versos` | 0 | 0 | Ídem |
| `cancion_endecasilaba` | 0 | 0 | Realización con 11 sílabas en todas las posiciones |
| `romancillo` | 0 | 1 | Retirar como entidad ambigua: exige saber si es hexasílabo o heptasílabo. Las arquitecturas Hexasílabo y Heptasílabo del romance ya reclaman `romancillo_hexasilabo` y `romancillo_heptasilabo` |

Queda por decidir si una disolución deliberada debe dejar constancia en algún sitio. Hoy no
la deja, y por eso aparecen en esta lista.

## Superadas por la ontología del 30 de julio

| Término legado | Propias | Familia | La matriz decía | Por qué ya no vale | Destino definitivo |
| --- | ---: | ---: | --- | --- | --- |
| `pareado_endecasilabo` | **1** | 1 | Conservar como forma, serie abierta de pareados endecasílabos | Lo que decía «N unidades de esta otra» dejó de ser forma | |
| `doble_sextilla` | 0 | 0 | Conservar como forma de doce versos | Ídem. Sextilla tiene ya la arquitectura «Doble, de pie quebrado», que reclama `doble_sextilla_alternativa` | |
| `copla_manriqueña` | 0 | 0 | Conservar como forma lexicalizada, subtipo de doble sextilla | Ídem, y no existe la relación padre/hijo | |

## Además

- Tres secuencias reales tienen `estrofa_tipo_id` **nulo**: no declaran forma ninguna.
- El rasgo **«Pie quebrado» sigue sin valores**, y hace falta para
  `copla_real_de_pie_quebrado`: el término legado necesita un valor al que apuntar. Lo que sí
  quedó declarado el 9 de agosto de 2026 son **las medidas** del quebrado, que hasta entonces
  solo existían en las opciones de la pregunta: `esquema_metrico_opciones` dice ahora, con su
  columna `rol`, que el octosílabo es el metro dominante de la copla real y que el tetrasílabo y
  el pentasílabo son sus quebrados.
- **Cuarteto** y **Endecha real** son formas nuevas sin equivalente legado: no hay nada que
  migrar y no son un problema. Muchas otras formas del catálogo tampoco se han usado aún, y
  ahí la migración será trivial —**canción petrarquista, con 0 secuencias**, es el caso
  claro.
- `vocabulario-heredado.md` documenta solo **31 de los 119** términos —las raíces—, así que
  no sirve para resolver subtipos: para eso está la matriz.
