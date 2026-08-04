# Equivalencias pendientes entre el vocabulario legado y el catálogo

Estado: **abierto, a completar por el IP** · 4 de agosto de 2026

De los 119 términos de `vocabularios.categoria = 'estrofa_tipo'`, **90 declaran hoy su
equivalencia en el catálogo nuevo y 29 no**. Este documento lista esos 29 para que se
decida y se aplique cada uno.

A nivel de secuencias reales: **242 de 260 (93,1 %)** tienen equivalencia declarada. Las
15 restantes —más 3 secuencias sin `estrofa_tipo_id`— dependen de los cinco términos de la
primera tabla.

## Qué significa exactamente «sin equivalencia»

El mapa vigente es `origen_termino_id`: cada entidad del catálogo declara de qué término
legado salió. Las tablas `migracion_terminos_metricos` y `migracion_termino_destinos`
están **vacías** desde que se retiró la matriz de importación.

Ese mecanismo tiene un límite que conviene tener presente: **registra supervivencias y
transformaciones, nunca disoluciones.** Cuando `redondilla_hexasilaba` desapareció a
propósito —porque la medida de una forma isosilábica es hoy arquitectura y ya no se
pregunta—, no quedó ninguna fila que lo dijera. En la base es indistinguible de un término
olvidado.

Por eso «29 sin equivalencia» **no son 29 huecos**: son 29 sin resolver *en la base*. La
intención está escrita para los 29 en
[la matriz de reclasificación](./historico/matriz-reclasificacion-formas-metricas.md), que
es del 28 de julio de 2026 y se declara «propuesta para revisión del IP; no aplicada». Es
dos días anterior a la revisión de la ontología del 30 de julio, y **la contradice en
cuatro casos**, señalados abajo.

## 1 · En uso: bloquean la migración

Quince secuencias reales dependen de estos cinco términos.

| Término legado | Padre | Sec. | Qué dijo la matriz (28 jul) | Estado | Destino definitivo |
| --- | --- | ---: | --- | --- | --- |
| `endecasilabo_suelto_puro` | `endecasilabo_suelto` | 6 | Arquitectura sin pareados intercalados, «con la política de cierre que se apruebe» | La forma existe; la arquitectura no está declarada. La matriz ya lo marcaba como revisión del IP | |
| `decima` | — (raíz) | 5 | Familia no seleccionable `decimas` | **Choca con la ontología: no existen familias.** El catálogo tiene «Décima espinela» y «Décima aumentada», pero no una Décima general | |
| `pareado_octosilabo` | `pareado_de_arte_menor` | 2 | Arquitectura octosílaba de `pareado` | La forma «Pareado» existe pero **no declara ningún origen ni reutiliza UUID legado** | |
| `copla_real_de_pie_quebrado` | `copla_real` | 1 | Arquitectura con uno o dos tetrasílabos en posiciones registradas por unidad | El rasgo «Pie quebrado» existe **sin ningún valor**. Revisión del IP pendiente desde julio | |
| `pareado_endecasilabo` | — (raíz) | 1 | Conservar como forma, serie abierta de pareados endecasílabos | **Choca con la ontología:** lo que decía «N unidades de esta otra» ya no es forma | |

## 2 · Sin uso, y la matriz sigue siendo coherente con la ontología

Ninguna secuencia real los usa. Aquí no falta decidir, falta **declararlo en la base** para
que el mapa deje de callar.

| Término legado | Padre | Destino según la matriz | Destino definitivo |
| --- | --- | --- | --- |
| `soneto_de_esdrújulos` | `soneto` | Forma `soneto` + rasgo «mayoría de finales esdrújulos» | |
| `octava_real_de_esdrujulos` | `octava_real` | Rasgo `final_acentual = esdrujulo` | |
| `terceto_de_esdrujulos` | `terceto` | Terceto + rasgo esdrújulo (corregir tamaño 1 → 3) | |
| `sexteto_lira_de_esdrujulos` | `sexteto_lira` | `final_acentual = esdrujulo`; la extensión se deriva como 6 | |
| `endecasilabo_suelto_de_esdrujulos` | `endecasilabo_suelto` | Endecasílabo suelto + rasgo esdrújulo | |
| `cancion_sin_rima_de_esdrujulos` | `cancion_petrarquista` | Arquitectura sin rima + `final_acentual = esdrujulo` | |
| `cancion_de_8_versos` | `cancion_petrarquista` | Extensión observada de la estancia; no identidad propia | |
| `cancion_de_9_versos` | `cancion_petrarquista` | Ídem | |
| `cancion_de_15_versos` | `cancion_petrarquista` | Ídem | |
| `cancion_endecasilaba` | `cancion_petrarquista` | Realización con 11 sílabas en todas las posiciones | |
| `endecasilabo_suelto_con_pareados` | `endecasilabo_suelto` | Arquitectura con pareados intercalados y dístico final | |
| `endecasilabo_suelto_con_pareados_y_sin_distico_final` | `endecasilabo_suelto` | Arquitectura con pareados y sin dístico final | |
| `endecasilabo_suelto_encadenado` | `endecasilabo_suelto` | Arquitectura con rima interna encadenada + rasgo. **Certeza media, revisión del IP** | |
| `redondilla_cruzada` | `redondilla` | Esquema de rima `abab`; «Cuarteta» como denominación | |
| `redondilla_heptasilaba` | `redondilla` | Arquitectura de cuatro heptasílabos | |
| `redondilla_hexasilaba` | `redondilla` | Arquitectura de cuatro hexasílabos (corregir la relación legada de 7 a 6) | |
| `pareado_hexasilabo` | `pareado_de_arte_menor` | Arquitectura hexasílaba de `pareado` | |
| `silva_libre` | `silva` | Arquitectura de silva, con el alcance que fije el IP frente al uso moderno | |
| `irregular_arte_mayor` | `irregular` | Fundir con Versificación irregular; el arte se conserva o se deriva como observación | |
| `irregular_arte_menor` | `irregular` | Ídem | |
| `irregular_mixto` | `irregular` | Ídem | |
| `romancillo` | — (raíz) | Retirar como entidad ambigua: exige saber si es hexasílabo o heptasílabo | |

## 3 · Sin uso, y la matriz quedó superada por la ontología

| Término legado | Padre | Qué dijo la matriz | Por qué ya no vale | Destino definitivo |
| --- | --- | --- | --- | --- |
| `doble_sextilla` | — (raíz) | Conservar como forma de doce versos compuesta por dos sextillas de pie quebrado | Lo que decía «N unidades de esta otra» dejó de ser forma el 30 de julio | |
| `copla_manriqueña` | `doble_sextilla` | Conservar como forma lexicalizada, subtipo de doble sextilla | Ídem, y además no existe la relación padre/hijo | |

## 4 · Formas del catálogo sin vínculo hacia atrás

Tres formas nuevas no declaran origen **ni reutilizan el UUID legado**, así que no se puede
saber de qué término salieron:

- **Pareado** — importa, porque `pareado_octosilabo` y `pareado_endecasilabo` están en uso
- **Cuarteto**
- **Endecha real**

## 5 · Además

- Tres secuencias reales tienen `estrofa_tipo_id` **nulo**: no dicen forma ninguna.
- El rasgo **«Pie quebrado» no tiene valores**, y hace falta para
  `copla_real_de_pie_quebrado`.
- `vocabulario-heredado.md` documenta solo **31 de los 119** términos —las raíces—, así que
  no sirve para resolver los subtipos: para eso está la matriz.
