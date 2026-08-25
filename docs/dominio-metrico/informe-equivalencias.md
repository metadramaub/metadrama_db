# Estado de las equivalencias con el vocabulario legado

> **Documento generado.** No se edita a mano: lo produce
> `npm run equivalencias:informe` consultando la base enlazada. El razonamiento sobre
> por qué faltan y las decisiones del IP viven en
> [equivalencias-pendientes.md](./equivalencias-pendientes.md), que sí es prosa propia.

Generado el 2026-08-25.

## Resumen

- **123 términos** en `vocabularios.categoria = 'estrofa_tipo'`.
- **96 declaran su destino** en el catálogo nuevo; **27 no**.
- **263 secuencias reales**, todas con forma propuesta.
- 9 no proponen arquitectura: son tramos sin forma, que no la tienen por diseño.
- **21 tienen la longitud incompatible** con la arquitectura propuesta. No es un fallo de la equivalencia: es la anotación de la obra, y se revisa en [migracion/](./migracion/).

### Cómo se resuelve cada secuencia

| Vía | Secuencias | Qué significa |
| --- | ---: | --- |
| `directa` | 145 | El término declara su destino, o lo declara algo que cuelga de él |
| `rasgo` | 71 | El término se disolvió en un rasgo y la forma la da su ascendiente |
| `ascendencia` | 47 | El término no declara destino; lo hereda de un ascendiente |

## Términos sin destino declarado

Ordenados por uso propio. **Propias** son las secuencias que declaran ese término
exacto; **familia**, las que declaran su raíz o cualquier descendiente de ella.
Un término sin uso propio dentro de una familia muy usada toca una zona delicada.

| Término legado | Padre | Propias | Familia |
| --- | --- | ---: | ---: |
| `endecasilabo_suelto_puro` | `endecasilabo_suelto` | **26** | 26 |
| `octava_real_regular` | `octava_real` | **12** | 12 |
| `irregular_mixto` | `irregular` | **6** | 9 |
| `copla_real_de_pie_quebrado` | `copla_real` | **1** | 3 |
| `irregular_arte_mayor` | `irregular` | **1** | 9 |
| `irregular_arte_menor` | `irregular` | **1** | 9 |
| `cancion_de_15_versos` | `cancion_petrarquista` | 0 | 3 |
| `cancion_de_8_versos` | `cancion_petrarquista` | 0 | 3 |
| `cancion_de_9_versos` | `cancion_petrarquista` | 0 | 3 |
| `cancion_endecasilaba` | `cancion_petrarquista` | 0 | 3 |
| `cancion_sin_rima_de_esdrujulos` | `cancion_petrarquista` | 0 | 3 |
| `copla_de_arte_mayor_tipo_2_ABBACDCD` | `copla_de_arte_mayor` | 0 | 0 |
| `copla_de_arte_mayor_tipo_3_ABABCDCD` | `copla_de_arte_mayor` | 0 | 0 |
| `copla_manriqueña` | `doble_sextilla` | 0 | 0 |
| `doble_sextilla` | — | 0 | 0 |
| `endecasilabo_suelto_con_pareados` | `endecasilabo_suelto` | 0 | 26 |
| `endecasilabo_suelto_con_pareados_y_sin_distico_final` | `endecasilabo_suelto` | 0 | 26 |
| `endecasilabo_suelto_de_esdrujulos` | `endecasilabo_suelto` | 0 | 26 |
| `endecasilabo_suelto_encadenado` | `endecasilabo_suelto` | 0 | 26 |
| `octava_real_de_esdrujulos` | `octava_real` | 0 | 12 |
| `pareado_hexasilabo` | `pareado_de_arte_menor` | 0 | 0 |
| `pareado_octosilabo` | `pareado_de_arte_menor` | 0 | 0 |
| `redondilla_cruzada` | `redondilla` | 0 | 63 |
| `romancillo` | — | 0 | 1 |
| `sexteto_lira_de_esdrujulos` | `sexteto_lira` | 0 | 5 |
| `soneto_de_esdrújulos` | `soneto` | 0 | 9 |
| `terceto_de_esdrujulos` | `terceto` | 0 | 7 |

## Términos con destino declarado

| Término legado | Destino en el catálogo | Propias | Familia |
| --- | --- | ---: | ---: |
| `redondilla` | forma · Redondilla | **37** | 63 |
| `redondilla_regular` | arquitectura · Redondilla · Octosilábica | **26** | 63 |
| `romance_e-o` | valor de rasgo · e-o | **20** | 71 |
| `decima_espinela` | arquitectura · Décima · Espinela | **18** | 18 |
| `quintilla` | forma · Quintilla | **18** | 18 |
| `silva_de_consonantes_irregular` | arquitectura · Silva · Consonante de orden libre | **11** | 12 |
| `romance_a-e` | valor de rasgo · a-e | **9** | 71 |
| `romance_e-a` | valor de rasgo · e-a | **8** | 71 |
| `romance_a-o` | valor de rasgo · a-o | **7** | 71 |
| `soneto_regular_ABBAABBACDCDCD` | esquema de rima · Tercetos de rima cruzada | **7** | 9 |
| `terceto_encadenado` | forma · Terceto encadenado | **7** | 7 |
| `romance_a-a` | valor de rasgo · a-a | **6** | 71 |
| `romance_e-e` | valor de rasgo · e-e | **5** | 71 |
| `cancion_regular_abCabCcdeeDfF` | arquitectura · Canción petrarquista · Regular de 13 versos | **3** | 3 |
| `romance_i-o` | valor de rasgo · i-o | **3** | 71 |
| `romance_o-o` | valor de rasgo · o-o | **3** | 71 |
| `seguidilla` | forma · Seguidilla | **3** | 3 |
| `copla_real_sin_quebrado` | arquitectura · Copla real · Octosilábica consonante | **2** | 3 |
| `pareado_endecasilabo` | forma · Pareado | **2** | 2 |
| `romance_o-a` | valor de rasgo · o-a | **2** | 71 |
| `romance_o-e` | valor de rasgo · o-e | **2** | 71 |
| `sexteto_lira_a1_aBaBcC` | variedad · A1 · aBaBcC | **2** | 5 |
| `irregular` | forma · Versificación irregular | **1** | 9 |
| `octava_lira` | forma · Octava-lira | **1** | 1 |
| `romance_a` | valor de rasgo · a | **1** | 71 |
| `romance_i-a` | valor de rasgo · i-a | **1** | 71 |
| `romance_i-e` | valor de rasgo · i-e | **1** | 71 |
| `romance_o` | valor de rasgo · o | **1** | 71 |
| `romance_u-e` | valor de rasgo · u-e | **1** | 71 |
| `romance_u-o` | valor de rasgo · u-o | **1** | 71 |
| `romancillo_heptasilabo` | arquitectura · Romance · Heptasilábica | **1** | 1 |
| `sexteto_lira_a2_AbaBcC` | variedad · A2 · AbaBcC | **1** | 5 |
| `sexteto_lira_a3_abaBcC` | variedad · A3 · abaBcC | **1** | 5 |
| `sexteto_lira_a4_aBaBCC` | variedad · A4 · aBaBCC | **1** | 5 |
| `silva_de_consonantes_regular` | arquitectura · Silva · Consonante regular | **1** | 12 |
| `soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE` | esquema de rima · Tercetos de rima conclusiva | **1** | 9 |
| `soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE` | esquema de rima · Tercetos de rima paralela | **1** | 9 |
| `cancion_petrarquista` | forma · Canción petrarquista | 0 | 3 |
| `cancion_sin_rima` | arquitectura · Canción petrarquista · Sin rima, con pareado final | 0 | 3 |
| `copla_de_arte_mayor` | forma · Copla de arte mayor | 0 | 0 |
| `copla_de_arte_mayor_tipo_1_ABBAACCA` | esquema de rima · ABBA:ACCA | 0 | 0 |
| `copla_de_pie_quebrado` | forma · Copla de pie quebrado | 0 | 0 |
| `copla_real` | forma · Copla real | 0 | 3 |
| `decima` | forma · Décima | 0 | 18 |
| `decima_aumentada` | arquitectura · Décima · Aumentada | 0 | 18 |
| `decima_lira` | forma · Décima-lira | 0 | 0 |
| `doble_sextilla_alternativa` | arquitectura · Copla manriqueña · De pie quebrado | 0 | 0 |
| `endecasilabo_suelto` | forma · Endecasílabo suelto | 0 | 26 |
| `endecasilabo_suelto_puro_sin_distico_final` | arquitectura · Endecasílabo suelto · Endecasilábica | 0 | 26 |
| `lira` | forma · Lira | 0 | 0 |
| `novena` | forma · Novena | 0 | 0 |
| `novena_canonica` | arquitectura · Novena · Redondilla + quintilla | 0 | 0 |
| `novena_invertida` | arquitectura · Novena · Quintilla + redondilla | 0 | 0 |
| `octava_real` | forma · Octava real | 0 | 12 |
| `pareado_alirado` | arquitectura · Pareado · Alirado | 0 | 0 |
| `pareado_de_arte_menor` | arquitectura · Pareado · De cualquier medida | 0 | 0 |
| `quintilla_1_ababa` | esquema de rima · Tipología 1 | 0 | 18 |
| `quintilla_2_abbab` | esquema de rima · Tipología 2 | 0 | 18 |
| `quintilla_3_abaab` | esquema de rima · Tipología 3 | 0 | 18 |
| `quintilla_4_aabab` | esquema de rima · Tipología 4 | 0 | 18 |
| `quintilla_5_aabba` | esquema de rima · Tipología 5 | 0 | 18 |
| `quintilla_6_abbaa` | esquema de rima · Tipología 6 | 0 | 18 |
| `quintilla_7_ababb` | esquema de rima · Tipología 7 | 0 | 18 |
| `quintilla_8_abbba` | esquema de rima · Tipología 8 | 0 | 18 |
| `redondilla_doble_abbaacca` | arquitectura · Redondilla · Doble enlazada | 0 | 63 |
| `redondilla_heptasilaba` | arquitectura · Redondilla · Heptasilábica | 0 | 63 |
| `redondilla_hexasilaba` | arquitectura · Redondilla · Hexasilábica | 0 | 63 |
| `romance` | forma · Romance | 0 | 71 |
| `romance_e` | valor de rasgo · e | 0 | 71 |
| `romance_heroico` | arquitectura · Romance · Endecasilábica | 0 | 0 |
| `romance_i` | valor de rasgo · i | 0 | 71 |
| `romance_u-a` | valor de rasgo · u-a | 0 | 71 |
| `romancillo_hexasilabo` | arquitectura · Romance · Hexasilábica | 0 | 1 |
| `sexta_rima` | denominación · Sexta rima | 0 | 0 |
| `sexteto` | forma · Sexteto | 0 | 0 |
| `sexteto_lira` | forma · Sexteto-lira | 0 | 5 |
| `sexteto_lira_b1_abbacC` | variedad · B1 · abbacC | 0 | 5 |
| `sexteto_lira_b2_AbbACC` | variedad · B2 · AbbACC | 0 | 5 |
| `sexteto_lira_c1_AabBcC` | variedad · C1 · AabBcC | 0 | 5 |
| `sexteto_lira_c2_AabBCC` | variedad · C2 · AabBCC | 0 | 5 |
| `sextilla` | forma · Sextilla | 0 | 0 |
| `sextilla_de_pie_quebrado` | arquitectura · Sextilla · De pie quebrado | 0 | 0 |
| `sextilla_sin_quebrado` | arquitectura · Sextilla · Octosilábica | 0 | 0 |
| `sextina` | forma · Sextina | 0 | 0 |
| `silva` | forma · Silva | 0 | 12 |
| `silva_de_endecasilabos` | arquitectura · Silva · Endecasilábica | 0 | 12 |
| `silva_libre` | arquitectura · Silva · Libre | 0 | 12 |
| `soneto` | forma · Soneto | 0 | 9 |
| `soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE` | esquema de rima · Tercetos de rima nuclear | 0 | 9 |
| `terceto` | forma · Terceto | 0 | 7 |
| `terceto_octosilabo` | arquitectura · Terceto encadenado · Octosilábica consonante | 0 | 0 |
| `terceto_sin_encadenar_1_AXABYB` | esquema de rima · Verso central suelto | 0 | 7 |
| `terceto_sin_encadenar_2_XAAYBB` | esquema de rima · Primer verso suelto | 0 | 7 |
| `verso suelto` | forma · Verso aislado | 0 | 0 |
| `villancico` | forma · Villancico | 0 | 0 |
| `zejel` | forma · Zéjel | 0 | 0 |

