# Revisión de nomenclatura del catálogo métrico

Estado: **aplicado** · 31 de julio de 2026

> **Archivado el 1 de agosto de 2026.** Los renombrados están aplicados. Se conserva como
> registro de los criterios de nombre y slug que sigue el catálogo.


Las arquitecturas y los esquemas se fueron creando forma por forma, cada uno con el
criterio del momento. Este documento miró los 193 de una vez, fijó unas convenciones y
listó qué cambiaba con ellas. Está **aplicado** en la migración
[20260731200000](../../../supabase/migrations/20260731200000_nomenclatura_catalogo.sql), y se
conserva como el registro de qué se cambió y por qué.

Dos precisiones sobre lo que finalmente se hizo:

- **Los rótulos M1–M5 y R1–R3 del sexteto-lira se conservan como nombre.** Sus siete
  variedades se nombran componiéndolos —A1 es M1 + R1— y la ficha de revisión los usa como
  referencia cruzada. El rótulo dice algo que la secuencia no dice, así que el literal vive
  en el slug y el rótulo en el nombre. Es el mismo trato que reciben las «Tipología N» de la
  quintilla.
- **Los dieciséis «Quintilla xxxxx» de la copla real ya no existen**: la copla real
  reutiliza el repertorio de la quintilla en vez de copiarlo, y con ello desaparece el
  defecto D8.
- **Algunas filas nombran entidades que después se reorganizaron.** Las de `sexta_rima`,
  `doble_sextilla`, `copla_manriqueña`, `tercetos_sin_encadenar` y `pareados_endecasilabos`
  se conservan tal como se aplicaron; esas formas se disolvieron más tarde en la
  arquitectura, la variedad o el esquema que les correspondía, sin que cambiaran los
  criterios de nombre y slug que este documento fijó. El estado vigente de cada una está en
  su ficha de revisión.

---

## 1 · Qué es cada identificador

| | Qué es | Quién lo lee | Puede cambiar |
| --- | --- | --- | --- |
| `uuid` | Identificador opaco, aleatorio, sin significado | Nadie: solo las claves ajenas | **Nunca**. Cambiarlo rompe cada referencia |
| `slug` | Identificador legible y estable | Las migraciones, la auditoría, la comparación entre corpus | Con cuidado y de una vez |
| `nombre` | Etiqueta para el editor | La interfaz | Libremente |

Los UUID no se tocan y no hay motivo para tocarlos: son aleatorios a propósito y ninguno
lleva información dentro. Lo que está disperso son los otros dos.

## 2 · Convenciones propuestas

### 2.1 · La regla que las gobierna a todas

> **Un nombre dice solo lo que su contexto no dice ya.**

La interfaz siempre muestra la arquitectura dentro de su forma y el esquema dentro de su
arquitectura. Repetirlos alarga sin distinguir: «Soneto endecasílabo consonante» dentro de
«Soneto» sobra en su mitad. Y la unidad declarada, la notación de rima y las posiciones del
esquema métrico ya dicen la extensión y la disposición, así que tampoco hacen falta en el
nombre: «Sextina · Clásica · 6 × 6 + 3» repite tres veces la misma cuenta.

### 2.2 · Arquitectura

- **slug**: minúsculas, sin tildes, `snake_case`. Solo lo que la distingue de las demás
  arquitecturas de su forma. Nunca el nombre de la forma. Cuando hay varios ejes, en este
  orden: medida → rima → estructura.
- **nombre**: lo mismo en prosa, con mayúscula inicial. Sin el nombre de la forma, sin la
  extensión y sin la notación.
- Cuando la forma tiene una sola arquitectura no hay nada que distinguir: el nombre
  describe su norma en corto.

### 2.3 · Esquema métrico

- **slug nuevo** (hoy no existe): la secuencia literal. `8-8-8-8-8`, `7-11-7-7-11`,
  `11-repetido`, `conjunto-7-11`.
- **nombre**: la medida cuando es única —«Cinco octosílabos»—, la secuencia cuando no lo
  es —«7-11-7-7-11»—, el ciclo cuando se repite —«Endecasílabo repetido»— y el conjunto
  cuando está abierto —«Heptasílabo o endecasílabo»—.

### 2.4 · Esquema de rima

- **slug nuevo** (hoy no existe): la notación en minúsculas. `abbab`, `cdcdcd`, `-a-a`.
  Los que no tienen notación llevan un slug descriptivo.
- **nombre**: **no repite la notación**, que ya está en su propia columna. Dice el nombre
  tradicional o analítico: «Cruzada», «Abrazada», «Tipología 1», «Asonancia en los pares».

### 2.5 · Vocabulario de la interfaz

| Dice hoy | Debe decir |
| --- | --- |
| Configuración | Arquitectura |
| Patrón métrico | Esquema métrico |
| Patrón de rima | Esquema de rima |
| Patrón de repetición | Repetición |
| Combinación de patrones | Variedad |

Aparece en once componentes del panel y en dos nombres de archivo
(`MetricConfigurationEditor`, `MetricConfigurationNormEditor`). La base ya no lo dice en
ninguna parte desde el bloque D.

## 3 · Arquitecturas · 53

| Forma | slug actual | slug propuesto | nombre actual | nombre propuesto | Por qué |
| --- | --- | --- | --- | --- | --- |
| cancion_petrarquista | cuerpo_sin_rima_pareado_final | **sin_rima_con_pareado_final** | Canción sin rima · cuerpo suelto y pareado final | **Sin rima, con pareado final** |  |
| cancion_petrarquista | estancias_consonantes_variables | · | Estancias consonantes variables | · |  |
| cancion_petrarquista | regular_13_abCabC_cdeeDfF | **regular_13_versos** | Regular de 13 versos · abCabC:cdeeDfF | **Regular de 13 versos** | El slug lleva mayúsculas; el esquema ya vive en la notación del esquema de rima |
| copla_de_arte_mayor | ocho_dodecasilabos_compuestos | **dodecasilabica_compuesta** | Ocho dodecasílabos compuestos | **Dodecasilábica compuesta** | La extensión la declara la unidad |
| copla_de_pie_quebrado | variable_5_12 | **octosilabica_con_quebrados** | Realización no tipificada de 5 a 12 versos | **Octosilábica con quebrados** | La extensión 5–12 la declara la unidad |
| copla_manriqueña | dos_sextillas_abcabc_defdef | **dos_sextillas** | Dos sextillas abcabc:defdef | **Dos sextillas** | El esquema ya vive en la notación |
| copla_real | con_pie_quebrado | · | Sí: uno o dos versos tetrasílabos | **Con pie quebrado** | El nombre era la respuesta a una pregunta |
| copla_real | sin_pie_quebrado | · | No: diez octosílabos | **Sin pie quebrado** | El nombre era la respuesta a una pregunta |
| decima_aumentada | octosilabica_abbaaccddeed | **octosilabica** | Octosilábica abbaaccddeed | **Octosilábica** | El esquema ya vive en la notación |
| decima_espinela | octosilabica_abbaaccddc | **octosilabica** | Octosilábica abbaaccddc | **Octosilábica** | El esquema ya vive en la notación |
| doble_sextilla | otro_esquema_regular | · | Otro esquema regular | · | Se conserva: el IP tiene abierto qué reúne exactamente |
| endecasilabo_suelto | con_pareados_sin_distico_final | · | Con pareados y sin dístico final | **Con pareados, sin dístico final** |  |
| endecasilabo_suelto | con_pareados_y_distico_final | **con_pareados_con_distico_final** | Con pareados y dístico final | · | Simetría con la anterior: con/sin |
| endecasilabo_suelto | encadenado_interior | · | Encadenado interior | · |  |
| endecasilabo_suelto | puro_con_distico_final | · | Puro con dístico final | **Puro, con dístico final** |  |
| endecasilabo_suelto | puro_sin_distico_final | · | Puro sin dístico final | **Puro, sin dístico final** |  |
| lira | heptasilabica_endecasilabica_consonante | **heptasilabica_endecasilabica** | Heptasilábica y endecasilábica consonante | **Heptasilábica y endecasilábica** | La consonancia no distingue: es la única arquitectura |
| novena | quintilla_redondilla | · | Quintilla + redondilla | · |  |
| novena | redondilla_quintilla | · | Redondilla + quintilla | · |  |
| octava_real | endecasilabica_consonante | · | Octava real endecasílaba consonante | **Endecasilábica consonante** | El nombre repetía la forma |
| pareado | pareado_de_arte_menor | **arte_menor** | Pareado de arte menor | **De arte menor** | El slug y el nombre repetían la forma |
| pareado | pareado_hexasilabo | **hexasilabico** | Pareado hexasílabo | **Hexasilábico** | El slug y el nombre repetían la forma |
| pareado | pareado_octosilabo | **octosilabico** | Pareado octosílabo | **Octosilábico** | El slug y el nombre repetían la forma |
| pareado | principal | **—** | Configuración principal | **—** | Sin propuesta: es el defecto D1 y su destino lo decide el IP |
| pareados_endecasilabos | endecasilabicos_consonantes | · | Serie de pareados endecasílabos consonantes | **Endecasílabos consonantes** | El nombre repetía la forma |
| quintilla | octosilabica_consonante | · | Quintilla octosilábica consonante | **Octosilábica consonante** | El nombre repetía la forma |
| redondilla | doble_enlazada | · | Doble enlazada | · |  |
| redondilla | simple | · | De cuatro versos | **Simple** | El nombre «De cuatro versos» decía la extensión, que ya declara la unidad |
| romance | endecasilabico_heroico | **endecasilabico** | Romance heroico | **Endecasílabo** | «Romance heroico» debería pasar a denominación, como ya lo son «Romance real» y «Endecha» |
| romance | heptasilabico_romancillo | **heptasilabico** | Romancillo heptasílabo | **Heptasílabo** | «Romancillo» debería pasar a denominación |
| romance | hexasilabico_romancillo | **hexasilabico** | Romancillo hexasílabo | **Hexasílabo** | «Romancillo» debería pasar a denominación |
| romance | octosilabico_asonante | **octosilabico** | Octosilábico | **Octosílabo** | La asonancia no distingue: la tienen las cuatro |
| seguidilla | compuesta_7575575_asonante | **compuesta** | Compuesta · 7-5-7-5 + 5-7-5 | **Compuesta** | La secuencia ya vive en el esquema métrico |
| seguidilla | simple_7575_asonante | **simple** | Simple · 7-5-7-5 | **Simple** | La secuencia ya vive en el esquema métrico |
| sexta_rima | endecasilabica_consonante | · | Endecasilábica consonante | · |  |
| sexteto | arte_mayor_consonante_variable | · | Arte mayor consonante variable | **De arte mayor, consonante variable** |  |
| sexteto_lira | heterometrica_consonante | · | Heterométrica consonante | · |  |
| sextilla | isometrica | · | Isométrica | · |  |
| sextilla | pie_quebrado_884884 | **pie_quebrado** | Pie quebrado 8-8-4-8-8-4 | **De pie quebrado** | La secuencia ya vive en el esquema métrico |
| sextina | clasica_6x6_mas_3 | **clasica** | Clásica · 6 × 6 + 3 | **Clásica** | La extensión 39 la declara la unidad |
| sextina | doble_12x6_mas_3 | **doble** | Doble · 12 × 6 + 3 | **Doble** | La extensión 75 la declara la unidad |
| silva | consonantes_irregular | **consonante_irregular** | Silva de consonantes irregular | **Consonante irregular** | El nombre repetía la forma |
| silva | consonantes_regular | **consonante_regular** | Silva de consonantes regular | **Consonante regular** | El nombre repetía la forma |
| silva | endecasilabica | · | Silva de endecasílabos | **Endecasilábica** | El nombre repetía la forma |
| silva | libre | · | Silva libre | **Libre** | El nombre repetía la forma |
| soneto | endecasilabo_consonante | **endecasilabico_consonante** | Soneto endecasílabo consonante | **Endecasilábico consonante** | El nombre repetía la forma; se normaliza a la forma adjetiva -ico |
| terceto | endecasilabico_consonante | · | Terceto endecasilábico consonante | **Endecasilábico consonante** | El nombre repetía la forma |
| terceto_encadenado | endecasilabico_consonante | · | Terceto encadenado endecasilábico consonante | **Endecasilábico consonante** | El nombre repetía la forma |
| terceto_encadenado | octosilabico | · | Terceto encadenado octosilábico | **Octosilábico** | El nombre repetía la forma |
| tercetos_sin_encadenar | endecasilabico_consonante | **endecasilabicos_consonantes** | Tercetos sin encadenar endecasilábicos consonantes | **Endecasílabos consonantes** | El nombre repetía la forma |
| villancico | estribillo_inicial | · | El estribillo aparece al comienzo | **Estribillo inicial** | El nombre era una frase |
| villancico | estribillo_tras_primera_copla | · | El estribillo aparece después de la primera copla | **Estribillo tras la primera copla** | El nombre era una frase |
| zejel | estribillo_y_coplas_monorrimas | · | Estribillo y coplas monorrimas | · |  |

Cambian **42** de 53. El punto significa que se queda como está.

## 4 · Esquemas métricos · 58

Ninguno tiene slug hoy. Tres no tienen ni nombre.

| Forma · arquitectura | Tipo | Medidas | nombre actual | slug propuesto | nombre propuesto |
| --- | --- | --- | --- | --- | --- |
| cancion_petrarquista · cuerpo_sin_rima_pareado_final | conjunto_permitido | {7, 11} | Heptasílabos y endecasílabos por posición | **conjunto-7-11** | **Heptasílabo o endecasílabo** |
| cancion_petrarquista · estancias_consonantes_variables | conjunto_permitido | {7, 11} | Heptasílabos y endecasílabos en distribución repetida | **conjunto-7-11** | **Heptasílabo o endecasílabo** |
| cancion_petrarquista · regular_13_abCabC_cdeeDfF | secuencia_fija | 7-7-11-7-7-11-7-7-7-7-11-7-11 | 7-7-11 / 7-7-11 / 7-7-7-7-11-7-11 | **7-7-11-7-7-11-7-7-7-7-11-7-11** | **7-7-11-7-7-11-7-7-7-7-11-7-11** |
| copla_de_arte_mayor · ocho_dodecasilabos_compuestos | secuencia_fija | 12-12-12-12-12-12-12-12 | Ocho dodecasílabos compuestos 6 + 6 | **12-12-12-12-12-12-12-12** | **Ocho dodecasílabos** |
| copla_de_pie_quebrado · variable_5_12 | conjunto_permitido | {4, 5, 6, 7, 8} | Octosílabos con pies quebrados | **conjunto-4-5-6-7-8** | **De 4 a 8 sílabas** |
| copla_manriqueña · dos_sextillas_abcabc_defdef | secuencia_fija | 8-8-4-8-8-4-8-8-4-8-8-4 | 8-8-4-8-8-4 / 8-8-4-8-8-4 | **8-8-4-8-8-4-8-8-4-8-8-4** | **8-8-4-8-8-4-8-8-4-8-8-4** |
| copla_real · con_pie_quebrado | conjunto_permitido | {4, 8} | Octosílabos con uno o dos pies quebrados | **conjunto-4-8** | **Tetrasílabo u octosílabo** |
| copla_real · sin_pie_quebrado | secuencia_fija | 8-8-8-8-8-8-8-8-8-8 | Diez octosílabos | **8-8-8-8-8-8-8-8-8-8** | · |
| decima_aumentada · octosilabica_abbaaccddeed | secuencia_fija | 8-8-8-8-8-8-8-8-8-8-8-8 | Doce octosílabos | **8-8-8-8-8-8-8-8-8-8-8-8** | · |
| decima_espinela · octosilabica_abbaaccddc | secuencia_fija | 8-8-8-8-8-8-8-8-8-8 | Diez octosílabos | **8-8-8-8-8-8-8-8-8-8** | · |
| doble_sextilla · otro_esquema_regular | secuencia_fija | 8-8-4-8-8-4-8-8-4-8-8-4 | 8-8-4-8-8-4 / 8-8-4-8-8-4 | **8-8-4-8-8-4-8-8-4-8-8-4** | **8-8-4-8-8-4-8-8-4-8-8-4** |
| endecasilabo_suelto · con_pareados_sin_distico_final | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| endecasilabo_suelto · con_pareados_y_distico_final | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| endecasilabo_suelto · encadenado_interior | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| endecasilabo_suelto · puro_con_distico_final | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| endecasilabo_suelto · puro_sin_distico_final | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| lira · heptasilabica_endecasilabica_consonante | secuencia_fija | 7-11-7-7-11 | Esquema fijo 7-11-7-7-11 | **7-11-7-7-11** | **7-11-7-7-11** |
| novena · quintilla_redondilla | secuencia_fija | 8-8-8-8-8-8-8-8-8 | Nueve octosílabos | **8-8-8-8-8-8-8-8-8** | · |
| novena · redondilla_quintilla | secuencia_fija | 8-8-8-8-8-8-8-8-8 | Nueve octosílabos | **8-8-8-8-8-8-8-8-8** | · |
| octava_real · endecasilabica_consonante | secuencia_fija | 11-11-11-11-11-11-11-11 | Ocho endecasílabos | **11-11-11-11-11-11-11-11** | · |
| pareado · pareado_de_arte_menor | conjunto_permitido | {4, 5, 6, 7, 8} | (sin nombre) | **conjunto-4-5-6-7-8** | **De 4 a 8 sílabas** |
| pareado · pareado_hexasilabo | secuencia_repetible | {6} | (sin nombre) | **-repetido** | ** repetido** |
| pareado · pareado_octosilabo | secuencia_repetible | {8} | (sin nombre) | **-repetido** | ** repetido** |
| pareados_endecasilabos · endecasilabicos_consonantes | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| quintilla · octosilabica_consonante | secuencia_fija | 8-8-8-8-8 | Cinco octosílabos | **8-8-8-8-8** | · |
| redondilla · doble_enlazada | secuencia_fija | 8-8-8-8-8-8-8-8 | Ocho octosílabos | **8-8-8-8-8-8-8-8** | · |
| redondilla · simple | secuencia_fija | 8-8-8-8 | Cuatro octosílabos | **8-8-8-8** | · |
| redondilla · simple | secuencia_fija | 7-7-7-7 | Cuatro heptasílabos | **7-7-7-7** | · |
| redondilla · simple | secuencia_fija | 6-6-6-6 | Cuatro hexasílabos | **6-6-6-6** | · |
| romance · endecasilabico_heroico | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| romance · heptasilabico_romancillo | secuencia_repetible | 7 | Romancillo Heptasílabo repetido | **7-repetido** | **Heptasílabo repetido** |
| romance · hexasilabico_romancillo | secuencia_repetible | 6 | Romancillo Hexasílabo repetido | **6-repetido** | **Hexasílabo repetido** |
| romance · octosilabico_asonante | secuencia_repetible | 8 | Octosílabo repetido | **8-repetido** | · |
| seguidilla · compuesta_7575575_asonante | secuencia_fija | 7-5-7-5-5-7-5 | Esquema fijo 7-5-7-5-5-7-5 | **7-5-7-5-5-7-5** | **7-5-7-5-5-7-5** |
| seguidilla · simple_7575_asonante | secuencia_fija | 7-5-7-5 | Esquema fijo 7-5-7-5 | **7-5-7-5** | **7-5-7-5** |
| sexta_rima · endecasilabica_consonante | secuencia_fija | 11-11-11-11-11-11 | Seis endecasílabos | **11-11-11-11-11-11** | · |
| sexteto · arte_mayor_consonante_variable | conjunto_permitido | {11, 12, 14} | Conjunto de medidas de arte mayor | **conjunto-11-12-14** | **Endecasílabo, dodecasílabo o alejandrino** |
| sexteto_lira · heterometrica_consonante | secuencia_fija | 7-11-7-11-7-11 | M1 · 7-11-7-11-7-11 | **7-11-7-11-7-11** | **7-11-7-11-7-11** |
| sexteto_lira · heterometrica_consonante | secuencia_fija | 11-7-7-11-7-11 | M2 · 11-7-7-11-7-11 | **11-7-7-11-7-11** | **11-7-7-11-7-11** |
| sexteto_lira · heterometrica_consonante | secuencia_fija | 7-7-7-11-7-11 | M3 · 7-7-7-11-7-11 | **7-7-7-11-7-11** | **7-7-7-11-7-11** |
| sexteto_lira · heterometrica_consonante | secuencia_fija | 7-7-7-7-7-11 | M4 · 7-7-7-7-7-11 | **7-7-7-7-7-11** | **7-7-7-7-7-11** |
| sexteto_lira · heterometrica_consonante | secuencia_fija | 11-7-7-11-11-11 | M5 · 11-7-7-11-11-11 | **11-7-7-11-11-11** | **11-7-7-11-11-11** |
| sextilla · isometrica | conjunto_permitido | {6, 7, 8} | Una medida de arte menor | **conjunto-6-7-8** | **Hexasílabo, heptasílabo u octosílabo** |
| sextilla · pie_quebrado_884884 | secuencia_fija | 8-8-4-8-8-4 | 8-8-4-8-8-4 | **8-8-4-8-8-4** | · |
| sextina · clasica_6x6_mas_3 | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| sextina · doble_12x6_mas_3 | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| silva · consonantes_irregular | conjunto_permitido | {7, 11} | Heptasílabo o endecasílabo en orden libre | **conjunto-7-11** | **Heptasílabo o endecasílabo** |
| silva · consonantes_regular | secuencia_repetible | 7-11 | Pareado 7 + 11 repetido | **7-11-repetido** | **7-11 repetido** |
| silva · endecasilabica | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| silva · libre | conjunto_permitido | {7, 11} | Heptasílabo o endecasílabo en orden libre | **conjunto-7-11** | **Heptasílabo o endecasílabo** |
| soneto · endecasilabo_consonante | secuencia_repetible | 11 | Endecasílabo en las catorce posiciones | **11-repetido** | **Endecasílabo repetido** |
| terceto · endecasilabico_consonante | secuencia_fija | 11-11-11 | Tres endecasílabos | **11-11-11** | · |
| terceto_encadenado · endecasilabico_consonante | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| terceto_encadenado · octosilabico | secuencia_repetible | 8 | Octosílabo repetido | **8-repetido** | · |
| tercetos_sin_encadenar · endecasilabico_consonante | secuencia_repetible | 11 | Endecasílabo repetido | **11-repetido** | · |
| villancico · estribillo_inicial | conjunto_permitido | {6, 8} | Hexasílabo u octosílabo | **conjunto-6-8** | · |
| villancico · estribillo_tras_primera_copla | conjunto_permitido | {6, 8} | Hexasílabo u octosílabo | **conjunto-6-8** | · |
| zejel · estribillo_y_coplas_monorrimas | conjunto_permitido | {6, 8} | Hexasílabos u octosílabos | **conjunto-6-8** | **Hexasílabo u octosílabo** |

Cambian de nombre **28** de 58, y los 58 reciben slug.

## 5 · Esquemas de rima · 82

| Forma · arquitectura | Notación | nombre actual | slug propuesto | nombre propuesto |
| --- | --- | --- | --- | --- |
| cancion_petrarquista · cuerpo_sin_rima_pareado_final | — | Cuerpo sin rima | **cuerpo-sin-rima** | · |
| cancion_petrarquista · cuerpo_sin_rima_pareado_final | AA | Pareado consonante final | **aa** | · |
| cancion_petrarquista · estancias_consonantes_variables | — | Esquema consonante repetido entre estancias | **consonante-repetido** | · |
| cancion_petrarquista · regular_13_abCabC_cdeeDfF | ABCABCCDEEDFF | ABCABCCDEEDFF | **abcabccdeedff** | **(vacío: habla la notación)** |
| copla_de_arte_mayor · ocho_dodecasilabos_compuestos | ABABCDCD | ABABCDCD | **ababcdcd** | **(vacío: habla la notación)** |
| copla_de_arte_mayor · ocho_dodecasilabos_compuestos | ABBAACCA | ABBAACCA | **abbaacca** | **(vacío: habla la notación)** |
| copla_de_arte_mayor · ocho_dodecasilabos_compuestos | ABBACDCD | ABBACDCD | **abbacdcd** | **(vacío: habla la notación)** |
| copla_de_pie_quebrado · variable_5_12 | — | Distribución variable | **distribucion-variable** | · |
| copla_manriqueña · dos_sextillas_abcabc_defdef | abcabc:defdef | abcabc:defdef | **abcabc-defdef** | **(vacío: habla la notación)** |
| copla_real · con_pie_quebrado | aabab | Quintilla aabab | **aabab** | · |
| copla_real · con_pie_quebrado | aabba | Quintilla aabba | **aabba** | · |
| copla_real · con_pie_quebrado | abaab | Quintilla abaab | **abaab** | · |
| copla_real · con_pie_quebrado | ababa | Quintilla ababa | **ababa** | · |
| copla_real · con_pie_quebrado | ababb | Quintilla ababb | **ababb** | · |
| copla_real · con_pie_quebrado | abbaa | Quintilla abbaa | **abbaa** | · |
| copla_real · con_pie_quebrado | abbab | Quintilla abbab | **abbab** | · |
| copla_real · con_pie_quebrado | abbba | Quintilla abbba | **abbba** | · |
| copla_real · sin_pie_quebrado | aabab | Quintilla aabab | **aabab** | · |
| copla_real · sin_pie_quebrado | aabba | Quintilla aabba | **aabba** | · |
| copla_real · sin_pie_quebrado | abaab | Quintilla abaab | **abaab** | · |
| copla_real · sin_pie_quebrado | ababa | Quintilla ababa | **ababa** | · |
| copla_real · sin_pie_quebrado | ababb | Quintilla ababb | **ababb** | · |
| copla_real · sin_pie_quebrado | abbaa | Quintilla abbaa | **abbaa** | · |
| copla_real · sin_pie_quebrado | abbab | Quintilla abbab | **abbab** | · |
| copla_real · sin_pie_quebrado | abbba | Quintilla abbba | **abbba** | · |
| decima_aumentada · octosilabica_abbaaccddeed | abbaaccddeed | Esquema fijo abbaaccddeed | **abbaaccddeed** | **(vacío: habla la notación)** |
| decima_espinela · octosilabica_abbaaccddc | abbaaccddc | Esquema fijo abbaaccddc | **abbaaccddc** | **(vacío: habla la notación)** |
| doble_sextilla · otro_esquema_regular | Esquema regular distinto de abcabc:defdef | Otro esquema regular | **regular-distinto-de-abcabc-defdef** | · |
| endecasilabo_suelto · con_pareados_sin_distico_final | — | Predominio de versos sueltos | **versos-sueltos** | · |
| endecasilabo_suelto · con_pareados_y_distico_final | — | Predominio de versos sueltos | **versos-sueltos** | · |
| endecasilabo_suelto · encadenado_interior | — | Predominio de versos sueltos con encadenamiento interior | **versos-sueltos-encadenados** | · |
| endecasilabo_suelto · puro_con_distico_final | — | Predominio de versos sueltos | **versos-sueltos** | · |
| endecasilabo_suelto · puro_sin_distico_final | — | Predominio de versos sueltos | **versos-sueltos** | · |
| lira · heptasilabica_endecasilabica_consonante | aBabB | Esquema fijo aBabB | **ababb** | **(vacío: habla la notación)** |
| octava_real · endecasilabica_consonante | ABABABCC | Esquema fijo ABABABCC | **abababcc** | **(vacío: habla la notación)** |
| pareado · pareado_de_arte_menor | — | Patrón principal | ⚠ pendiente | **(vacío: habla la notación)** |
| pareado · pareado_hexasilabo | — | Patrón principal | ⚠ pendiente | **(vacío: habla la notación)** |
| pareado · pareado_octosilabo | — | Patrón principal | ⚠ pendiente | **(vacío: habla la notación)** |
| pareados_endecasilabos · endecasilabicos_consonantes | AA \| BB \| CC \| … | Pareados consonantes sistemáticos | **pareados-sistematicos** | · |
| quintilla · octosilabica_consonante | aabab | Tipología 4 (aabab) | **aabab** | **Tipología 4** |
| quintilla · octosilabica_consonante | aabba | Tipología 5 (aabba) | **aabba** | **Tipología 5** |
| quintilla · octosilabica_consonante | abaab | Tipología 3 (abaab) | **abaab** | **Tipología 3** |
| quintilla · octosilabica_consonante | ababa | Tipología 1 (ababa) | **ababa** | **Tipología 1** |
| quintilla · octosilabica_consonante | ababb | Tipología 7 (ababb) | **ababb** | **Tipología 7** |
| quintilla · octosilabica_consonante | abbaa | Tipología 6 (abbaa) | **abbaa** | **Tipología 6** |
| quintilla · octosilabica_consonante | abbab | Tipología 2 (abbab) | **abbab** | **Tipología 2** |
| quintilla · octosilabica_consonante | abbba | Tipología 8 excepcional (abbba) | **abbba** | **Tipología 8 excepcional** |
| redondilla · doble_enlazada | abbaacca | Doble enlazada | **abbaacca** | · |
| redondilla · simple | abab | Cruzada | **abab** | · |
| redondilla · simple | abba | Abrazada | **abba** | · |
| romance · endecasilabico_heroico | -a-a-a… | Asonancia en los versos pares | **asonancia-pares** | · |
| romance · heptasilabico_romancillo | -a-a-a… | Asonancia en los versos pares | **asonancia-pares** | · |
| romance · hexasilabico_romancillo | -a-a-a… | Asonancia en los versos pares | **asonancia-pares** | · |
| romance · octosilabico_asonante | -a-a-a… | Asonancia en los versos pares | **asonancia-pares** | · |
| seguidilla · compuesta_7575575_asonante | -a-ab-b | Esquema fijo -a-ab-b | **-a-ab-b** | **(vacío: habla la notación)** |
| seguidilla · simple_7575_asonante | -a-a | Esquema fijo -a-a | **-a-a** | **(vacío: habla la notación)** |
| sexta_rima · endecasilabica_consonante | ABABCC | Esquema fijo ABABCC | **ababcc** | **(vacío: habla la notación)** |
| sexteto · arte_mayor_consonante_variable | — | Distribución consonante variable | **consonante-variable** | · |
| sexteto_lira · heterometrica_consonante | aabbcc | R3 · aabbcc | **aabbcc** | · |
| sexteto_lira · heterometrica_consonante | ababcc | R1 · ababcc | **ababcc** | · |
| sexteto_lira · heterometrica_consonante | abbacc | R2 · abbacc | **abbacc** | · |
| sextilla · isometrica | — | Distribución variable | **distribucion-variable** | · |
| sextilla · pie_quebrado_884884 | — | Distribución variable | **distribucion-variable** | · |
| silva · consonantes_irregular | — | Pareados consonantes predominantes | **pareados-predominantes** | · |
| silva · consonantes_regular | aA \| bB \| cC \| … | Pareados consonantes regulares | **pareados-regulares** | · |
| silva · endecasilabica | — | Predominio de rima consonante con pareados no sistemáticos | **consonante-con-pareados-no-sistematicos** | · |
| silva · libre | — | Rima libre sin organización en pareados | **libre-sin-pareados** | · |
| soneto · endecasilabo_consonante | ABBA | Cuartetos abrazados | **abba** | · |
| soneto · endecasilabo_consonante | CDCDCD | Tercetos de rima cruzada (CDCDCD) | **cdcdcd** | **Tercetos de rima cruzada** |
| soneto · endecasilabo_consonante | CDCEDE | Tercetos de rima nuclear (CDCEDE) | **cdcede** | **Tercetos de rima nuclear** |
| soneto · endecasilabo_consonante | CDECDE | Tercetos de rima paralela (CDECDE) | **cdecde** | **Tercetos de rima paralela** |
| soneto · endecasilabo_consonante | CDEDCE | Tercetos de rima conclusiva (CDEDCE) | **cdedce** | **Tercetos de rima conclusiva** |
| terceto_encadenado · endecasilabico_consonante | ABA \| BCB \| CDC \| … \| YZYZ | Encadenamiento consonante con cierre en serventesio | **encadenado-con-serventesio** | · |
| tercetos_sin_encadenar · endecasilabico_consonante | -AA \| -BB \| -CC \| … | Primer verso suelto | **primer-verso-suelto** | · |
| tercetos_sin_encadenar · endecasilabico_consonante | A-A \| B-B \| C-C \| … | Verso central suelto | **verso-central-suelto** | · |
| villancico · estribillo_inicial | — | Relación entre mudanza, enlace o vuelta y estribillo | **relacion-mudanza-estribillo** | · |
| villancico · estribillo_inicial | abab | Mudanza en cuarteta (abab) | **abab** | **Mudanza en cuarteta** |
| villancico · estribillo_inicial | abba | Mudanza en redondilla (abba) | **abba** | **Mudanza en redondilla** |
| villancico · estribillo_tras_primera_copla | — | Relación entre mudanza, enlace o vuelta y estribillo | **relacion-mudanza-estribillo** | · |
| villancico · estribillo_tras_primera_copla | abab | Mudanza en cuarteta (abab) | **abab** | **Mudanza en cuarteta** |
| villancico · estribillo_tras_primera_copla | abba | Mudanza en redondilla (abba) | **abba** | **Mudanza en redondilla** |
| zejel · estribillo_y_coplas_monorrimas | A(A) \| BBBA | Estribillo, mudanza monorrima y vuelta | **estribillo-mudanza-vuelta** | · |

Solo **3** quedan sin slug propuesto: los tres del pareado, que no declaran nada y son el defecto D2.

«Vacío» significa que el nombre no decía nada que la notación no dijera ya. La columna
`nombre` admite nulo y la interfaz cae en la notación, así que dejarlos vacíos quita
repetición sin perder nada.

## 6 · Dos decisiones menores dentro de la propuesta

- **El slug de rima va en minúsculas aunque la notación distinga mayúsculas.** En `aBabB`
  las mayúsculas dicen arte mayor, y el slug `ababb` lo pierde. No se pierde en el catálogo:
  la columna `notacion` lo conserva, y el slug solo tiene que ser único dentro de su
  arquitectura. La alternativa —slugs con mayúsculas— rompe la convención de todos los demás.
- **Los dieciséis «Quintilla xxxxx» de la copla real se dejan como están.** Repiten la
  notación, pero son las filas del defecto D8: si el IP decide que la copla real reutiliza el
  repertorio de la quintilla en vez de copiarlo, desaparecen. Renombrarlas ahora sería
  trabajo que se tira.

## 7 · Lo que la revisión ha destapado y no es nomenclatura

- **La redondilla tiene una sola arquitectura `simple` con tres esquemas métricos** —de 8,
  7 y 6 sílabas— y una pregunta `medida_redondilla`. Su ficha de revisión dice lo
  contrario: «por su isosilabismo, las medidas 6, 7 y 8 son tres arquitecturas y no una
  elección». El dato y la decisión no coinciden.
- **«Romance heroico» y «Romancillo» son nombres de arquitectura**, no denominaciones,
  mientras que «Romance real» y «Endecha» sí lo son. Si las arquitecturas pasan a llamarse
  por su medida, esos dos nombres deberían registrarse como denominaciones para no
  perderlos.
- **Dos esquemas métricos del pareado se declaran `secuencia_repetible` pero guardan su
  medida como conjunto de opciones, sin ninguna posición.** El tipo y el dato se
  contradicen; la migración dedujo el tipo efectivo de dónde estaban realmente las medidas.
- **La numeración de las tipologías de quintilla no sigue el orden de sus notaciones**
  (1=ababa, 2=abbab, 3=abaab, 4=aabab…). Si viene de una fuente, conviene decir de cuál en
  la descripción; si no, renumerarla.
- **La notación de `doble_sextilla` guarda una frase**, «Esquema regular distinto de
  abcabc:defdef», en una columna que debería llevar una notación computable. Es prosa en el
  sitio equivocado y por eso su slug hay que escribirlo a mano.
- **Tres esquemas métricos del pareado no tienen nombre** y sus tres esquemas de rima se
  llaman «Patrón principal», sin notación ni posiciones. Es la forma peor descrita del
  catálogo y ya aparece en los defectos D1, D2 y D2b.

