# Equivalencias pendientes entre el vocabulario legado y el catálogo

Estado: **abierto, a completar por el IP** · 4 de agosto de 2026

De los 119 términos de `vocabularios.categoria = 'estrofa_tipo'`, **90 declaran hoy su
equivalencia en el catálogo nuevo y 29 no**. A nivel de secuencias reales: **242 de 260
(93,1 %)**; las 15 restantes —más 3 secuencias sin `estrofa_tipo_id`— dependen de los cinco
términos que sí están en uso.

## El problema no es solo que falten: es que el mapa no puede expresarlos

El mapa vigente es `origen_termino_id`, **una columna en el destino**. Eso permite decir
«esta arquitectura viene de aquel término», pero **no permite que varios términos legados
apunten al mismo destino**. Y la ontología hizo exactamente eso a propósito: disolvió la
medida en la arquitectura y los esdrújulos en un rasgo, de modo que varios términos viejos
colapsan en uno nuevo.

Los tres casos comprobados el 4 de agosto:

- **Endecasílabo suelto** tiene **una sola arquitectura**, «Endecasilábica», y la reclama
  `endecasilabo_suelto_puro_sin_distico_final`. Los otros cinco hijos se quedan fuera —
  incluido `endecasilabo_suelto_puro`, **que es el único que se usa, con 6 secuencias**.
- **Pareado** tiene una sola arquitectura, «De cualquier medida», y la reclama el padre
  `pareado_de_arte_menor`. Sus dos hijos no pueden reclamarla.
- Los valores de rasgo **«Agudo» y «Esdrújulo» no declaran origen ninguno**, y necesitan
  recibir seis términos `*_de_esdrujulos` a la vez.

Consecuencia: parte de los 29 no son un olvido sino **un límite de forma del mapa**.
`migracion_termino_destinos` existía justamente para lo de varios a uno, y está vacía. Hay
que decidir si se rellena esa tabla, si se admite una lista en el destino, o si la
correspondencia de varios a uno se resuelve solo en el script de backfill.

Añadido: `origen_termino_id` registra supervivencias y transformaciones, **nunca
disoluciones**. `redondilla_hexasilaba` desapareció a propósito y no dejó rastro; en la base
es indistinguible de un olvido.

La intención está escrita para los 29 en
[la matriz de reclasificación](./historico/matriz-reclasificacion-formas-metricas.md), del
28 de julio, declarada «propuesta para revisión del IP; no aplicada». Es dos días anterior a
la revisión de la ontología y **la contradice en cuatro casos**.

## Cómo leer las columnas de uso

- **Propias**: secuencias reales que declaran ese término exacto.
- **Familia**: secuencias que declaran la raíz o cualquiera de sus descendientes. Es la que
  mide el riesgo de la decisión: un término sin uso propio dentro de una familia muy usada
  toca una zona delicada del corpus.

Por familia, de más a menos: **redondilla 76** · décima 23 · silva 13 · soneto 9 · octava
real 7 · endecasílabo suelto 6 · terceto 4 · sexteto-lira 4 · irregular 3 · copla real 3 ·
pareado 2 · **canción petrarquista 0**.

## 1 · El destino no existe todavía: hay que decidirlo

| Término legado | Propias | Familia | La matriz decía | Estado real | Destino definitivo |
| --- | ---: | ---: | --- | --- | --- |
| `decima` | **5** | **23** | Familia no seleccionable `decimas` | **Choca: no existen familias.** Hay «Décima espinela» (18 secuencias) y «Décima aumentada», pero no una Décima general | |
| `copla_real_de_pie_quebrado` | **1** | 3 | Arquitectura con uno o dos tetrasílabos por unidad | Copla real tiene **una sola arquitectura**, «Octosilábica consonante», ya reclamada por `copla_real_sin_quebrado`. El rasgo «Pie quebrado» existe **sin ningún valor** | |
| `endecasilabo_suelto_encadenado` | 0 | 6 | Arquitectura con rima interna encadenada + rasgo. **Certeza media, revisión del IP** | No hay tal arquitectura | |
| `endecasilabo_suelto_con_pareados` | 0 | 6 | Arquitectura con pareados intercalados y dístico final | No hay tal arquitectura | |
| `endecasilabo_suelto_con_pareados_y_sin_distico_final` | 0 | 6 | Arquitectura con pareados y sin dístico final | No hay tal arquitectura | |

## 2 · El destino existe pero ya lo reclamó otro término

Aquí no falta modelar: falta poder decir «varios vienen a este».

| Término legado | Propias | Familia | Destino | Quién lo reclama ya | Destino definitivo |
| --- | ---: | ---: | --- | --- | --- |
| `endecasilabo_suelto_puro` | **6** | 6 | Endecasílabo suelto · Endecasilábica | `endecasilabo_suelto_puro_sin_distico_final` | |
| `pareado_octosilabo` | **2** | 2 | Pareado · De cualquier medida | `pareado_de_arte_menor` (el padre) | |
| `pareado_hexasilabo` | 0 | 2 | Pareado · De cualquier medida | Ídem | |
| `soneto_de_esdrújulos` | 0 | **9** | Soneto + rasgo `final_acentual = esdrujulo` | «Esdrújulo» no declara origen; lo necesitan seis términos | |
| `octava_real_de_esdrujulos` | 0 | 7 | Octava real + mismo rasgo | Ídem | |
| `terceto_de_esdrujulos` | 0 | 4 | Terceto + mismo rasgo (corregir tamaño 1 → 3) | Ídem | |
| `sexteto_lira_de_esdrujulos` | 0 | 4 | Sexteto-lira + mismo rasgo; extensión derivada como 6 | Ídem | |
| `endecasilabo_suelto_de_esdrujulos` | 0 | 6 | Endecasílabo suelto + mismo rasgo | Ídem | |
| `cancion_sin_rima_de_esdrujulos` | 0 | 0 | Arquitectura sin rima + mismo rasgo | La arquitectura «Sin rima, con pareado final» la reclama `cancion_sin_rima` | |

## 3 · El destino existe y está libre: solo falta declararlo

| Término legado | Propias | Familia | Destino disponible en el catálogo | Destino definitivo |
| --- | ---: | ---: | --- | --- |
| `redondilla_heptasilaba` | 0 | **76** | Redondilla · Heptasilábica (sin origen declarado) | |
| `redondilla_hexasilaba` | 0 | **76** | Redondilla · Hexasilábica (sin origen declarado) | |
| `silva_libre` | 0 | 13 | Silva · Libre (sin origen declarado) | |

## 4 · Resueltos por el IP el 4 de agosto de 2026

| Término legado | Propias | Familia | Decisión |
| --- | ---: | ---: | --- |
| `redondilla_cruzada` | 0 | **76** | Esquema de rima `abab` de la redondilla. **«Redondilla cruzada» es el nombre preferente y «cuarteta» su denominación equivalente en uso actual: son exactamente lo mismo.** No confundir con la forma «Cuarteto» del catálogo, que es otra cosa |

## 5 · Disoluciones deliberadas: no hay destino porque no debe haberlo

| Término legado | Propias | Familia | Decisión de la matriz |
| --- | ---: | ---: | --- |
| `irregular_arte_mayor` | 0 | 3 | Fundir con Versificación irregular; el arte se conserva o se deriva como observación |
| `irregular_arte_menor` | 0 | 3 | Ídem |
| `irregular_mixto` | 0 | 3 | Ídem |
| `cancion_de_8_versos` | 0 | 0 | Extensión observada de la estancia; no identidad propia |
| `cancion_de_9_versos` | 0 | 0 | Ídem |
| `cancion_de_15_versos` | 0 | 0 | Ídem |
| `cancion_endecasilaba` | 0 | 0 | Realización con 11 sílabas en todas las posiciones |
| `romancillo` | 0 | 1 | Retirar como entidad ambigua: exige saber si es hexasílabo o heptasílabo. Las arquitecturas Hexasílabo y Heptasílabo del romance ya reclaman `romancillo_hexasilabo` y `romancillo_heptasilabo` |

Queda por decidir si una disolución deliberada debe dejar constancia en algún sitio. Hoy no
la deja, y por eso aparecen en esta lista.

## 6 · Superadas por la ontología del 30 de julio

| Término legado | Propias | Familia | La matriz decía | Por qué ya no vale | Destino definitivo |
| --- | ---: | ---: | --- | --- | --- |
| `pareado_endecasilabo` | **1** | 1 | Conservar como forma, serie abierta de pareados endecasílabos | Lo que decía «N unidades de esta otra» dejó de ser forma | |
| `doble_sextilla` | 0 | 0 | Conservar como forma de doce versos | Ídem. Sextilla tiene ya la arquitectura «Doble, de pie quebrado», que reclama `doble_sextilla_alternativa` | |
| `copla_manriqueña` | 0 | 0 | Conservar como forma lexicalizada, subtipo de doble sextilla | Ídem, y no existe la relación padre/hijo | |

## 7 · Además

- Tres secuencias reales tienen `estrofa_tipo_id` **nulo**: no declaran forma ninguna.
- El rasgo **«Pie quebrado» no tiene valores**, y hace falta para
  `copla_real_de_pie_quebrado`.
- **Cuarteto** y **Endecha real** son formas nuevas sin equivalente legado: no hay nada que
  migrar y no son un problema. Muchas otras formas del catálogo tampoco se han usado aún, y
  ahí la migración será trivial —**canción petrarquista, con 0 secuencias**, es el caso
  claro.
- `vocabulario-heredado.md` documenta solo **31 de los 119** términos —las raíces—, así que
  no sirve para resolver subtipos: para eso está la matriz.
