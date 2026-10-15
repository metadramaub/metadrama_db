# Propuesta de destino de las observaciones de caracterizaciones

Estado: **aplicación parcial realizada el 15 de octubre de 2026**. Se han trasladado las seis notas de prueba y la de Adonis y Venus a comentarios públicos de sus secuencias, con el rango al principio y el editor asignado como autor. La columna y los 73 textos originales permanecen intactos en la base. Las otras 66 notas reales se tratarán obra por obra al procesar sus Excel; la laguna de El mágico prodigioso se resolverá entonces.

El formulario ya no permite escribir observaciones en las caracterizaciones. La descripción de desviaciones muestra la ayuda aprobada para distinguir datos y comentarios críticos. La guía y el generador de obras de prueba siguen ese criterio.

Los traslados aplicados quedan registrados en `traslados_observaciones_caracterizacion`, tabla privada que conserva el origen completo y el ID del comentario. La ficha omite la nota junto a la caracterización solo cuando existe ese registro. Repetir el traslado no duplica ni sobrescribe el comentario, aunque se haya editado o borrado después. Si cambia el origen, el proceso se detiene para revisarlo.

Aplicado mediante `20261015120000_traslada_las_notas_de_prueba_a_comentarios.sql` y `20261015121000_traslada_la_nota_de_adonis_y_venus.sql`, con copia completa, snapshot y ensayos con rollback. Las guardas ejecutan los lectores de ficha y comentarios y comprueban la conservación de las caracterizaciones originales.

## Criterio de revisión

- **E — Dato estructurado:** información que puede registrarse íntegramente en los selectores de la desviación. Elegir el valor y dejar la descripción vacía; no crear un comentario público que lo repita.
- **D — Descripción de la desviación:** cita del verso, rima observada, diferencia de patrón o condición técnica local de escansión que no quede recogida en los selectores. Una explicación técnica puede ocupar varias frases y seguir siendo dato.
- **C — Comentario público:** interpretación, relación con la acción, discusión de ediciones o bibliografía y explicaciones de canto/prosa/evocación que no describen una desviación.
- **M — Mixta:** separar el dato de la explicación crítica. Los textos propuestos se muestran para aprobarlos antes de escribirlos.
- **R — Rectificación:** la respuesta recibida invalida la nota anterior. No publicar la nota descartada ni crear una desviación a partir de ella.

Las lecturas técnicas para completar el cómputo o la rima —acentuación de «Vayasé» o «cíclope», diéresis en «suave», «descuido» o «ruinas»— se proponen como D mientras solo expliquen la escansión local. Esto no autoriza a corregir el texto base ni a dar esas lecturas por documentadas en una edición. Una explicación mínima de la lectura utilizada, como la del v. 800 de El caballero de Olmedo, queda íntegra en la desviación. Las hipótesis sobre pronunciación histórica, la discusión crítica de ediciones o el efecto dramático se separan como comentario.

La descripción de una desviación sirve para completar lo que no cubran sus selectores. Las citas del texto de los versos que ya dejaron los editores se conservarán en esa descripción, aunque sean más extensas de lo necesario. No se pide transcribir los versos a quienes anoten en adelante. Las notas que solo repiten un metro exacto se resuelven con su selector, según el criterio E.

## Recuento por obra

| Obra | Editor | E | D | C | M | R | Total |
|---|---|---:|---:|---:|---:|---:|---:|
| Adonis y Venus | Gaston Gilabert | 0 | 0 | 1 | 0 | 0 | 1 |
| Dido y Eneas | Gaston Gilabert | 0 | 2 | 0 | 0 | 0 | 2 |
| El amor al uso | Ana Vicente | 4 | 2 | 0 | 0 | 1 | 7 |
| El caballero de Olmedo | María Isabel Cuena | 0 | 30 | 2 | 0 | 0 | 32 |
| El esclavo del demonio | Blanca Ballester Morell | 0 | 0 | 1 | 0 | 0 | 1 |
| El mágico prodigioso | Emma González Mesas | 0 | 0 | 2 | 1 | 0 | 3 |
| La gran Semíramis | Blanca Ballester Morell | 0 | 0 | 3 | 0 | 0 | 3 |
| Valor, agravio y mujer | María Isabel Cuena | 0 | 16 | 0 | 2 | 0 | 18 |
| **Total real** | | **4** | **50** | **9** | **3** | **1** | **67** |

El recuento refleja la revisión inicial. La nota de Adonis y Venus y las seis de prueba, revisadas al final como C, ya están trasladadas. Quedan 66 notas reales en siete obras.

## Cómo encajarlo con la migración de obras

1. Mantener intacta la columna observaciones y los textos originales durante la migración. El campo está retirado del formulario; los datos históricos siguen disponibles para el aplicador.
2. Registrar cada destino por caracterizacion_rango_id y huella del texto. Si el texto cambia después de la revisión, detener ese traslado y volver a revisarlo. No clasificar por palabras o por longitud durante la aplicación.
3. Conservar los Excel enviados y recibidos. El lector identifica las filas por Clave, incluida D|<caracterizacion_rango_id>; no es necesario volver a enviarlos para esta clasificación. Las correcciones que haya escrito el editor prevalecen sobre la propuesta inicial y se resuelven explícitamente.
4. Al migrar cada obra, resolver primero sus respuestas, correcciones, renumeraciones y fusiones. E se guarda en el selector correspondiente, sin repetirlo en la descripción; D va al texto de la desviación; C crea un comentario de tipo observacion_publica, visible en ficha pública; M separa dato y comentario; R aplica la rectificación aprobada. En una enunciativa, el traslado del comentario no elimina la caracterización.
5. Los comentarios llevan como autor al editor asignado, según la indicación del IP. Se vinculan a la secuencia y comienzan con el verso o rango definitivo escrito en el propio texto, por ejemplo «**V. 22.** …» o «**Vv. 354–355.** …». Conservar el ID y el texto originales en el rastro y evitar duplicados al repetir el proceso.

   Si una renumeración afecta a referencias de versos dentro del texto de la nota, revisarlas antes de trasladarlo. No sustituir cifras automáticamente: también hay páginas bibliográficas y otros números. Conservar la redacción original y su numeración en el rastro.
6. Corregir la fusión de secuencias para trasladar también los comentarios ya existentes antes de borrar las filas absorbidas: actualmente solo se trasladan subtipos y caracterizaciones y la FK de comentarios tiene borrado en cascada.
7. Antes de aplicar: copia, snapshot y ensayo íntegro con rollback. Las notas que dependan de la migración métrica se trasladan al migrar su obra; no completar respuestas métricas no recibidas. Las secuencias que ya tienen anotación V2 se tratan sin esperar un Excel.

La base tiene vacía migracion_secuencias. Entre estas obras reales, Adonis y Venus ya tiene anotaciones V2; las demás no. Su nota de canto se ha trasladado sin migrar de nuevo su métrica.

### Orden de aplicación

- **Ya anotadas con V2:** traslado realizado para Adonis y Venus, canto de vv. 1229–1287 dentro de la secuencia 1229–1306. Comentario público firmado por Gaston Gilabert, con el rango al principio y sin alterar el canto.
- **Pendientes de migración métrica:** trasladar sus notas en la misma operación que la obra, cuando se procese su Excel. Son las otras 66 notas reales, en siete obras. Así se respetan las rectificaciones del editor, las renumeraciones y las fusiones y no se crean descripciones de desviaciones que aún no existen.
- **Nuevas anotaciones:** aplicar el formulario sin Observaciones en las caracterizaciones por rango y la ayuda aprobada en desviaciones. La columna y los textos históricos pendientes permanecen en la base para el aplicador, aunque el formulario no permita crear nuevas notas en ella.
- **Pruebas:** las seis notas ya están trasladadas. Cinco pertenecen a secuencias con anotación V2 y una a una secuencia sin ella; ninguna requiere crear una desviación.

Las tres notas mixtas quedan aprobadas para separar dato y comentario. La pausa de El caballero de Olmedo (vv. 478–480) se conservará como desviación con la nota íntegra, por indicación del IP. El encaje de su dimensión se revisará al migrar esa obra; no se asignará rima automáticamente solo por el nombre legado patron_alternativo.

## Prueba con El amor al uso

Excel recibido: docs/dominio-metrico/migracion/respuestas/migracion_amor al uso_completado AV.xlsx. Se ha leído sin modificarlo. El lector reconoce 30 claves y no informa duplicados ni errores de lectura.

La simulación del aplicador actual prepara 24 de 28 secuencias, sin correcciones estructurales, y deja cuatro pendientes: la rectificación del v. 1082 y Organización en pareados en vv. 1348–1407, 2545–2612 y 2621–2644. El cuestionario es anterior a la nueva pregunta: falta recoger esas tres respuestas, no regenerar todo el Excel.

En el v. 1082, la editora indica que el defecto procedía de otra edición y lo descarta para el texto base utilizado. El aplicador actual deja la secuencia pendiente por no interpretar correcciones libres; debe recibir una resolución explícita para ese ID, no una regla que acepte cualquier «No es así». Su explicación del Excel se conserva como evidencia editorial y no se publica automáticamente.

En el v. 1948, el aplicador actual conserva Cantado pero no crea una desviación de rima, pese al contenido de la nota. La propuesta D de esta revisión requiere añadir ese destino de forma explícita manteniendo el canto.

Las notas «Verso heptasílabo» de los vv. 2917 y 2983 se registrarán como metro observado heptasílabo. Las notas «Verso endecasílabo» de los vv. 2918 y 2984, como metro observado endecasílabo. Las cuatro descripciones quedarán vacías: el texto no añade nada al valor del selector. El Excel deja las sílabas sin rellenar, pero estos valores constan expresamente en la anotación original y no requieren inferirlos.

## Localización de los comentarios públicos

Actualmente los comentarios pueden vincularse a una secuencia, pero no tienen un rango de versos propio. En la ficha pública aparecen dentro del detalle de esa secuencia, bajo «Aclaraciones públicas» o «Notas públicas».

**Criterio acordado:** mantener el mismo modelo de comentario público para toda la secuencia. No añadir selectores ni campos de versos a los comentarios. Si una nota se refiere a uno o pocos versos, indicarlos al principio de su texto. En el traslado se añadirá ese prefijo utilizando el rango que ya tiene la caracterización, después de resolver las renumeraciones.

Quien anote en adelante puede escribir también el verso al principio de su comentario, tanto para cuestiones métricas como para observaciones sobre personajes o cualquier otro aspecto. El comentario sigue vinculado a la secuencia. No se necesita filtrado por verso ni un tratamiento específico para las notas procedentes de caracterizaciones.

## Ayuda aprobada para la desviación

«Describe el dato métrico que no quede recogido en los campos anteriores. La interpretación y el comentario crítico deben ir en “Comentarios” de esta secuencia, con el tipo “Observación pública”.»

## Lectura individual

### Adonis y Venus — Gaston Gilabert

#### 1. vv. 1229–1287 · cantado

Origen: `d73527b8-210f-4e16-a7ed-600fa817b796`. Secuencia actual: vv. 1229–1306.

> Véase la justificación de estos versos cantados en la bibliografía (Gilabert, 2021: 65-87).

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

### Dido y Eneas — Gaston Gilabert

#### 2. v. 1626 · rima_defectuosa

Origen: `53aecedd-6f06-41e0-87b1-c8dc02b906ad`. Secuencia actual: vv. 1575–1798.

> "Vayasé" para que rime con "sé"

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 3. v. 1792 · rima_defectuosa

Origen: `5aae2325-54c3-4a09-9bce-cdd3219587ff`. Secuencia actual: vv. 1575–1798.

> "Consuelaté" para que rime con "disculparé"

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

### El amor al uso — Ana Vicente

#### 4. v. 1082 · rima_defectuosa

Origen: `732f37e1-235f-4ab9-9a26-9defa3763bf0`. Secuencia actual: vv. 1043–1117.

> La rima es "-asa", pero en este verso se usa "-oso" ("enfadoso").

**Propuesta: Rectificación del editor.** La editora retira la anomalía en el Excel recibido. No crear desviación ni publicar la observación antigua como si siguiera vigente. Conservar ambas versiones en el rastro y registrar una decisión explícita para esta caracterización.

**Rectificación recibida de la editora:**

> La rima no es defectuosa. Mi comentario venía de una edición que al final no es la que he usado como texto base, en la que pone "enfadoso", pero es en realidad "enfadado", por lo que cuadra con la rima de la quintilla, que es "ababa".

#### 5. v. 1202 · rima_defectuosa

Origen: `ace1b329-4aa4-40d0-ade6-436a70823995`. Secuencia actual: vv. 1174–1347.

> La rima del romance es e-e, pero este verso acaba con "voy".

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 6. v. 1948 · cantado

Origen: `e67efe83-d102-4099-a702-2fa0037cb642`. Secuencia actual: vv. 1730–2037.

> El verso acaba en "veo", lo cual no sigue la rima en i-o del romance.

**Propuesta: Dato de desviación.** Aunque está asociada a Cantado, la nota describe una diferencia de rima. Proponer desviación de rima en el v. 1948 y conservar por separado el canto. El Excel confirma la caracterización; esta ampliación del destino debe aprobarse expresamente.

#### 7. v. 2917 · hipometrico

Origen: `f64ecbc8-351b-48fb-9fbd-f1d3e5a08360`. Secuencia actual: vv. 2801–2924.

> Verso heptasílabo

**Propuesta: Dato estructurado.** Seleccionar metro observado **heptasílabo (7)** y dejar la descripción vacía. No crear comentario público. Conservar el texto original en el rastro.

#### 8. v. 2918 · hipermetrico

Origen: `be231df4-c5ae-4ccf-9678-c4405332a620`. Secuencia actual: vv. 2801–2924.

> Verso endecasílabo

**Propuesta: Dato estructurado.** Seleccionar metro observado **endecasílabo (11)** y dejar la descripción vacía. No crear comentario público. Conservar el texto original en el rastro.

#### 9. v. 2983 · hipometrico

Origen: `7d2d13c4-969e-4714-a0a3-0128405b12f3`. Secuencia actual: vv. 2975–3056.

> Verso heptasílabo

**Propuesta: Dato estructurado.** Seleccionar metro observado **heptasílabo (7)** y dejar la descripción vacía. No crear comentario público. Conservar el texto original en el rastro.

#### 10. v. 2984 · hipermetrico

Origen: `9285fc5a-0196-42da-abb1-dead86452129`. Secuencia actual: vv. 2975–3056.

> Verso endecasílabo

**Propuesta: Dato estructurado.** Seleccionar metro observado **endecasílabo (11)** y dejar la descripción vacía. No crear comentario público. Conservar el texto original en el rastro.

### El caballero de Olmedo — María Isabel Cuena

#### 11. v. 215 · hipermetrico

Origen: `c2158c38-4ed4-4de7-835f-b67ba721ed37`. Secuencia actual: vv. 183–407.

> «Y todos dicen, Leonor»

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 12. v. 252 · hipermetrico

Origen: `bb5fc8c0-8eb5-4f7f-a0e8-d8fdc961fdb7`. Secuencia actual: vv. 183–407.

> «¿Quieres tú que entre, Leonor?»

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 13. v. 272 · hipermetrico

Origen: `0e8be6ba-196a-456f-ab81-d944c240ded5`. Secuencia actual: vv. 183–407.

> «fue el ejemplo de lealtad»

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 14. v. 276 · hipometrico

Origen: `81483886-061b-4612-8b8b-436884319c7b`. Secuencia actual: vv. 183–407.

> «¿A quién no hizo mil bienes?»

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 15. vv. 478–480 · patron_alternativo

Origen: `a6332da3-dfd9-43b0-b85f-8def48d6dba5`. Secuencia actual: vv. 461–490.

> Esta décima espinela incorpora una pausa sintáctica justo antes de este grupo de versos, que es el final de la misma.

**Propuesta: Dato de desviación.** El IP considera la pausa un patrón alternativo y decide conservarla como desviación con esta explicación íntegra. Revisar la dimensión concreta al migrar la obra; el nombre legado patron_alternativo no obliga a clasificarla automáticamente como diferencia de rima.

#### 16. vv. 503–516 · evocacion_metrica

Origen: `7c2901c5-96e6-44fd-b4a6-53ade9b5e280`. Secuencia actual: vv. 503–516.

> Doña Inés lee el memorial que don Alonso le escribió, donde se le declara.

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 17. v. 645 · hipermetrico

Origen: `eb9e46b1-2e32-4a59-aa25-7cecd273cd49`. Secuencia actual: vv. 623–706.

> "Favor fue de mi Leonor"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 18. v. 646 · hipometrico

Origen: `4cebfb31-1b59-4f77-905f-3b64f4096055`. Secuencia actual: vv. 623–706.

> "tal vez por aquí me habla"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 19. v. 708 · hipermetrico

Origen: `84b2ba81-294d-45bc-a09d-3324a6efd64a`. Secuencia actual: vv. 707–786.

> "Leonor, el pie de marfil"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 20. v. 743 · hipermetrico

Origen: `3747b7dc-b5b6-40ad-9175-f5fac42153e5`. Secuencia actual: vv. 707–786.

> "¡Ay, Leonor! No sin razón"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 21. vv. 789–791 · patron_alternativo

Origen: `ddcf855d-724f-421a-acc8-069cd75fc64a`. Secuencia actual: vv. 787–885.

> Además de la rima asonante propia del romance, riman el v. 789 y el v. 791, que son el tercero y el quinto del romance, respectivamente.

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 22. v. 800 · hipermetrico

Origen: `89a1371d-07e6-4c3d-86c4-449a1d77d9f0`. Secuencia actual: vv. 787–885.

> «a las rejas de tu güerto»; en la edición que manejo está marcado con diéresis, pero si no se rompe el diptongo, es octosílabo y, por tanto, regular.

**Propuesta: Dato de desviación.** Conservar la nota íntegra como explicación técnica mínima de la escansión. No separar ni crear un comentario público. No modificar automáticamente la lectura del verso.

#### 23. v. 842 · hipometrico

Origen: `e722eefe-716f-40e8-860d-63e8f8e3caa6`. Secuencia actual: vv. 787–885.

> "para él tienen sus padres"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 24. v. 878 · hipermetrico

Origen: `b9ac4fbc-fec0-41a8-b5d4-fd9863ec4e4d`. Secuencia actual: vv. 787–885.

> "Leonor, ¿no me das consejo?"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 25. v. 961 · hipometrico

Origen: `cb68bb25-9278-4f56-9d5a-bf533c8bcbbf`. Secuencia actual: vv. 888–1035.

> "a sacar de un ahorcado"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 26. v. 965 · hipermetrico

Origen: `fc569342-4f8d-4b88-af0d-a64628279528`. Secuencia actual: vv. 888–1035.

> "y díjome el salteador"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 27. v. 1041 · hipermetrico

Origen: `1eb35e69-90b5-427e-850d-c80f41b3fa3c`. Secuencia actual: vv. 1036–1095.

> "me voy de Leonor guardando"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 28. v. 1098 · hipometrico

Origen: `9a5f9e42-201f-42df-8b97-3b43749a013b`. Secuencia actual: vv. 1096–1103.

> "que a él le has hecho discreto"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 29. vv. 1104–1108 · evocacion_metrica

Origen: `0259027d-8633-4d77-a1d1-0a65f33f2d28`. Secuencia actual: vv. 1104–1108.

> Tello recita el estribo que don Alonso compuso: «En el valle a Inés / la dejé riendo: / si la ves, Andrés, / dile cuál me ves / por ella muriendo».

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 30. v. 1170 · hipermetrico

Origen: `8664537a-ef75-4421-b5bb-ebb46855b30d`. Secuencia actual: vv. 1163–1250.

> "INÉS: Escondeos. ALONSO: ¿Dónde? [*Ellos se entran, y sale DON PEDRO*.] PEDRO: Inés mía".

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 31. v. 1201 · hipermetrico

Origen: `f440e87c-7d1f-4ee5-ab02-4aa7a0470c2b`. Secuencia actual: vv. 1163–1250.

> "Leonor te queda, que al fin"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 32. v. 1202 · hipermetrico

Origen: `b7fae4ef-8989-4be6-98ca-44cf1631bd89`. Secuencia actual: vv. 1163–1250.

> "te dará nietos Leonor"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 33. v. 1327 · hipometrico

Origen: `76117fc0-8c02-491d-b962-169e73be28a5`. Secuencia actual: vv. 1251–1332.

> «ALONSO: ¿Cómo? TELLO: Porque es de día»

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 34. v. 1352 · hipermetrico

Origen: `2ddf79ba-2c90-46ff-ad6d-1c081781cf3d`. Secuencia actual: vv. 1333–1393.

> "alanceador galán y cortesano"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 35. v. 1371 · hipometrico

Origen: `797ceb13-5288-4e02-b7b1-b9f72ff82feb`. Secuencia actual: vv. 1333–1393.

> "yo hago diferente mi conceto"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 36. v. 1530 · hipermetrico

Origen: `eb2527c3-ec80-4872-a009-f88a792d2ad4`. Secuencia actual: vv. 1466–1553.

> "que has de verlas con Leonor"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 37. v. 1550 · hipermetrico

Origen: `ff10ddc9-e821-408b-9935-ef9e15458309`. Secuencia actual: vv. 1466–1553.

> "Y vos, Leonor, ¿no seréis"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 38. v. 1659 · hipermetrico

Origen: `1b7848ce-4a8e-496b-afc8-1fdae214958f`. Secuencia actual: vv. 1610–1659.

> "partir el alma y dividir y la vida"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 39. v. 1673 · hipometrico

Origen: `8ad020bd-ced8-4775-8a73-f4e25cc99af3`. Secuencia actual: vv. 1660–1727.

> "porque manjar tan süave", hipométrico sin diéresis

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 40. v. 1717 · hipometrico

Origen: `a277e9a8-c984-4065-92aa-424d8b9823b6`. Secuencia actual: vv. 1660–1727.

> "que de ser amado eres"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 41. vv. 1728–1730 · patron_alternativo

Origen: `514ffd8a-b1b2-44fb-a769-f2fbbd2bbd8a`. Secuencia actual: vv. 1728–1813.

> Al inicio del romance, riman el primer verso y el tercero.

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 42. v. 1734 · hipermetrico

Origen: `00a4d225-e943-4d12-a29b-4bf872981278`. Secuencia actual: vv. 1728–1813.

> "poneos esa banda al cuello"

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

### El esclavo del demonio — Blanca Ballester Morell

#### 43. vv. 1649–1760 · evocacion_metrica

Origen: `271ca2e4-3152-4058-9987-1a00bfcc57a3`. Secuencia actual: vv. 1649–1760.

> Al cierre del pasaje, Leonor le pide al músico que siga cantando el romance que estaba cantando.

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

### El mágico prodigioso — Emma González Mesas

#### 44. v. 2211 · cantado

Origen: `9707d571-d786-4d13-88f5-2c840a3ea552`. Secuencia actual: vv. 2202–2459.

> La parte cantada se corresponde con la segunda mitad del verso partido ("Amor, amor.")

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 45. v. 2246 · cantado

Origen: `bf587b79-09bb-4356-a3c3-67d28bdba672`. Secuencia actual: vv. 2202–2459.

> La parte cantada se corresponde con la segunda mitad del verso partido ("Amor, amor.")

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 46. vv. 2277–2279 · laguna

Origen: `9918dbff-5d7f-447f-8737-618be80c6c39`. Secuencia actual: vv. 2202–2459.

> Wardropper (p. 140) señala que la falta de los dos versos de esta quintilla se da en todas las versiones del siglo XVII.

**Propuesta: Separar dato y comentario.** La laguna es el dato estructural; la comparación de testimonios y la referencia bibliográfica van al comentario público. El rango guardado abarca tres posiciones y la nota habla de dos versos: resolver con el Excel antes de trasladar.

**Texto para la desviación, propuesto:**

> Faltan dos versos en esta quintilla. Propuesta pendiente de conciliar con el rango 2277–2279.

**Texto para el comentario público, propuesto:**

> Wardropper (p. 140) señala que la falta de los dos versos de esta quintilla se da en todas las versiones del siglo XVII.

### La gran Semíramis — Blanca Ballester Morell

#### 47. vv. 1226–1312 · evocacion_metrica

Origen: `8709f5e5-2417-4c5e-9e3c-e22344ae9df5`. Secuencia actual: vv. 1226–1312.

> Janto lee en voz alta una carta escrita por Semíramis.

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 48. vv. 1979–2017 · evocacion_metrica

Origen: `b8a60fc2-a318-4f95-b63d-5d8d2c28da52`. Secuencia actual: vv. 1979–2017.

> Diarco, al contarle a Celabo, la muerte de Semíramis a manos de su hijo, reproduce las últimas palabras que fueron dichas por la reina.

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

#### 49. vv. 2022–2047 · evocacion_metrica

Origen: `545f86fb-7f24-466e-9499-6bf66456bcfb`. Secuencia actual: vv. 2022–2047.

> Diarco, tras una breve pausa, sigue reproduciendo las últimas palabras de Semíramis.

**Propuesta: Comentario público.** Explica la enunciación, su contexto o su bibliografía. Mantener la caracterización y trasladar el texto a un comentario público de la secuencia; no crear una desviación por ese motivo.

### Valor, agravio y mujer — María Isabel Cuena

#### 50. v. 22 · rima_defectuosa

Origen: `5aef9cae-259b-47dd-99cf-3fc6e3bd8c8b`. Secuencia actual: vv. 1–236.

> «cristalino móvil» es el final del verso. El cierre en el timbre vocálico (en este caso, e> i) sucede más de una vez a lo largo de la obra, lo cual me hace pensar en una variación en la pronunciación original.

**Propuesta: Separar dato y comentario.** Separar la diferencia fonética localizada de la hipótesis histórica de pronunciación.

**Texto para la desviación, propuesto:**

> «cristalino móvil», al final del verso: cierre del timbre vocálico e > i.

**Texto para el comentario público, propuesto:**

> El cierre en el timbre vocálico (en este caso, e> i) sucede más de una vez a lo largo de la obra, lo cual me hace pensar en una variación en la pronunciación original.

#### 51. v. 58 · rima_defectuosa

Origen: `4c09c52b-07df-4e29-aa07-ee446fb4e09b`. Secuencia actual: vv. 1–236.

> «Piedra inmóvil», es el mismo cierre en el timbre vocálico que el indicado en el v. 22.

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 52. v. 110 · rima_defectuosa

Origen: `e7099cbe-1b53-4a4c-b6e6-6ec5e3635703`. Secuencia actual: vv. 1–236.

> «un Polifemo cíclope»: la terminación en esdrújula rompe la pauta del romance; para que siga la rima hay que desplazar el acento y leer *cíclope* como llana.

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 53. v. 228 · rima_defectuosa

Origen: `bfa58dd4-cb90-40c9-aca3-9d2e79e7a626`. Secuencia actual: vv. 1–236.

> «más de doscientos Néstores»: de nuevo (cf. v. 110), la terminación esdrújula rompe la pauta del romance; para preservar la rima habría que leer la palabra como llana (lo cual también completaría la hipometría del verso).

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 54. v. 246 · rima_defectuosa

Origen: `04ca848d-644e-4285-954f-f08505bb3924`. Secuencia actual: vv. 237–463.

> «dio al mundo a Lucano y Séneca», la forma esdrújula rompe el romance

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 55. vv. 354–355 · patron_alternativo

Origen: `7ce02b84-99c4-4b12-ba0b-68b3f61e9c73`. Secuencia actual: vv. 237–463.

> cambio en el patrón de rima en los vv. 354-355: la rima esperada en el v. 354 se salta un verso y se retoma en el 355. Justo el cambio de patrón coincide con el aparte en que don Juan expresa su atracción por Estela.

**Propuesta: Separar dato y comentario.** El desplazamiento de la rima es el dato; su relación con el aparte es comentario crítico.

**Texto para la desviación, propuesto:**

> La rima esperada en el v. 354 se salta un verso y se retoma en el 355.

**Texto para el comentario público, propuesto:**

> Justo el cambio de patrón coincide con el aparte en que don Juan expresa su atracción por Estela.

#### 56. v. 829 · rima_defectuosa

Origen: `d7bed083-b5c5-4d89-bdc6-5e84f685b970`. Secuencia actual: vv. 820–887.

> El verso 829 no tiene rima («¿Ya vive ocioso e inútil»)

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 57. v. 928 · patron_alternativo

Origen: `4ff566fd-6acf-4fe1-a13d-4203026b9d9f`. Secuencia actual: vv. 928–1182.

> La rima empieza en verso impar (el inicial), no en los pares de la estrofa

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 58. vv. 1107–1109 · rima_defectuosa

Origen: `d7db9018-4133-4612-92ca-f561ddfc060c`. Secuencia actual: vv. 928–1182.

> La rima esperada en el v. 1108 pasa al v. 1109; en el v. 1108, el príncipe Ludovico repite la pregunta hecha por Doña Leonor en el v. inmediatamente anterior: así, se escucha «¿Qué hay de Estela?» en los versos 1107 y 1108, por boca de ella y de él respectivamente

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 59. vv. 1162–1164 · rima_defectuosa

Origen: `2eb8a4a1-46ce-4889-b117-9fc5ad839f33`. Secuencia actual: vv. 928–1182.

> La rima esperada en el v. 1163 pasa al v. 1164: «TOMILLO: ¿Cuándo vinisteis de allá? / RIBETE: ¡Bravo chasco! Habrá seis meses. TOMILLO: ¿Qué hay en el lugar de nuevo? / RIBETE: Ya todo es muy viejo allá» (vv. 1161-1164).

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 60. vv. 1311–1314 · patron_alternativo

Origen: `e98eb871-d281-44f1-bb05-eacaeef182ac`. Secuencia actual: vv. 1302–1595.

> En el v. 1312 se repite la rima que se había producido en el v. 1311, de manera que cambia el patrón de rima y el romance empieza a rimar en los pares, en vez de en los impares, como hasta ese verso: «en qué me pones de ultrajes! / ¡Oh, si Ribete acabase / de venir, para saber / si tuvo dicha de darle» (vv. 1311-1314)

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 61. v. 1457 · rima_defectuosa

Origen: `33117a8a-e224-46d3-8cd3-0938d0634d3d`. Secuencia actual: vv. 1302–1595.

> Cambia el timbre vocálico, que se hace cerrado («perjuro, bárbaro, fácil»)

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 62. v. 1523 · rima_defectuosa

Origen: `686b4799-513d-4bfd-9faa-686c8673502d`. Secuencia actual: vv. 1302–1595.

> Por cambio el timbre vocálico: se hace cerrado («No os habrá de ser muy fácil»).

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 63. v. 1686 · rima_defectuosa

Origen: `ad5d1e84-7028-4bf0-9be9-c470e9526a56`. Secuencia actual: vv. 1596–1690.

> Verso suelto

**Propuesta: Dato de desviación.** Descripción localizada de la rima o su patrón. Conservar como dato de la desviación de rima.

#### 64. v. 1723 · hipometrico

Origen: `1af37344-c497-46f0-8e1f-457f4b773327`. Secuencia actual: vv. 1715–1734.

> Verso hipométrico, salvo que se añada diéresis en «suave» («que es el jazmín más suave»).

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 65. v. 1772 · hipometrico

Origen: `ed2f5df2-43bc-4592-87dc-c0db8af2fa6a`. Secuencia actual: vv. 1763–1782.

> Igual que ocurre con el v. 1723, verso hipométrico a menos que se indique con diéresis la partición del diptongo en la última palabra: «y el jazmín menos suave».

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 66. v. 2101 · hipometrico

Origen: `ce88217f-2c8b-40e9-a501-3148f8ec3b56`. Secuencia actual: vv. 2076–2417.

> Podría regularizarse el cómputo métrico de incluir diéresis en la última palabra («porque el común descuido»)

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

#### 67. v. 2370 · hipometrico

Origen: `3053550d-1d90-498c-b28d-310f1ebc1982`. Secuencia actual: vv. 2076–2417.

> El patrón métrico podría regularizarse de incluir una diéresis en la última palabra del verso («ostenta sucias ruinas»).

**Propuesta: Dato de desviación.** Cita del verso, medida o condición local de escansión. Conservar como dato de la desviación de metro, sin inventar sílabas no declaradas.

### El marqués desdichado (prueba) — David Merino Recalde

#### 68. vv. 1383–1398 · cantado

Origen: `065646f3-07d4-4513-a53c-34193b10ae8d`. Secuencia actual: vv. 1383–1430.

> Romance cantado por músicos dentro.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.

### La monja de Ávila (prueba) — David Merino Recalde

#### 69. vv. 2665–2666 · cantado

Origen: `36603ccf-f13a-40fb-9181-8385f8229523`. Secuencia actual: vv. 2665–2666.

> Pasaje cantado.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.

#### 70. vv. 2667–2682 · cantado

Origen: `7bfff83c-1d18-46ca-bfc5-0e940d934865`. Secuencia actual: vv. 2667–2682.

> Pasaje cantado.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.

### Las batuecas del duque (prueba) — David Merino Recalde

#### 71. vv. 1854–1875 · cantado

Origen: `ece5224f-89d2-442c-b696-b2af3452be05`. Secuencia actual: vv. 1854–1875.

> Pasaje cantado.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.

### Lo fingido y lo cierto (prueba) — David Merino Recalde

#### 72. vv. 1471–1504 · cantado

Origen: `51abe19e-9914-4621-89bf-075e9b7e0ad9`. Secuencia actual: vv. 1471–1504.

> El villancico lo cantan los músicos.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.

#### 73. vv. 1591–1596 · prosa

Origen: `4503f1a2-11d7-458e-8767-8f787a7ba984`. Secuencia actual: vv. 1591–1602.

> Pasaje en prosa dentro de la escena.

**Propuesta: Comentario público.** Describe el pasaje cantado o en prosa. Si se conserva la obra de prueba, trasladar como observación pública de la secuencia; no crear una desviación.
