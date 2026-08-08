# Cuestiones para el IP

Actualizado: 8 de agosto de 2026

Este archivo reúne solo decisiones pendientes. **Lo descriptivo ya no vive aquí ni en fichas
sueltas: vive en el catálogo, y se lee en `/formas`.** A medida que una forma se revisa, su
prosa se muda al dato, sus dudas resueltas se borran de aquí y su ficha `.md` se retira: el
catálogo es el documento vivo y un `.md` paralelo solo puede quedarse viejo.

Revisadas y con ficha ya retirada: romance, redondilla, décima, silva, soneto, quintilla, lira,
octava real, cuarteto, terceto, terceto encadenado, pareado, endecha real, seguidilla, sextina
—como estrofa y como composición—, villancico, sexteto, sextilla, sexteto-lira y las cuatro
coplas: de pie quebrado, real, de arte mayor y la sextilla que compartía ficha con ellas. La
ficha de las coplas se retiró al quedar revisadas las cuatro. Las fuentes de la novena están
revisadas y su ficha se retiró, pero su separación respecto de la copla novena depende del
modelo abierto pendiente.

Quedan por revisar: **zéjel y canción petrarquista**, y al final el **endecasílabo suelto** con
los dos tramos sin forma.

**Muchas de estas dudas no se responden una a una.** Varias son la misma pregunta vista desde
formas distintas —qué repertorios están cerrados, qué elecciones dependen de otras, qué se
pregunta y qué se deriva— y se resolverán juntas al cerrar la revisión, en las lecturas
transversales que recoge
[el estado del catálogo](../revision-del-catalogo-estado.md#defectos-del-modelo-aplazados): la
del concepto de **variedad**, la de la **modalidad y la primacía**, y la de **si las preguntas
del editor pueden derivarse del dato en vez de mantenerse a mano**. Cada duda de abajo dice qué
hace hoy el catálogo y qué cambiaría si se decide otra cosa, para que la decisión se pueda tomar
sin releer las fuentes.

## Dónde vive la información de cada forma

Desde el 4 de agosto de 2026 existe un **catálogo público de formas** en `/formas`, generado
del dato: cada forma con sus arquitecturas, esquemas, secciones, variedades, rasgos,
denominaciones y lo que dicen las fuentes. Se apaga y se abre desde
`/dashboard/publicacion`, sección `formas`, y nace en `admin_ip` para poder revisarlo antes
de enseñarlo.

El reparto al que se va:

- **El catálogo público describe.** Qué es cada forma y cómo está codificada. Sale del dato,
  así que no puede quedarse viejo.
- **Este archivo pregunta.** Solo lo que sigue sin decidir.
- **Las fichas de `revisiones-formas/` se retiran** cuando su contenido está en el dato. Antes
  de borrar una, su *porqué* se muda a `definicion`, `descripcion`, `nota`,
  `afirmaciones_fuentes_metricas` o a la `nota` de una relación entre formas.

**Dónde va cada cosa** está resuelto en [dónde vive la prosa](../donde-vive-la-prosa.md), que
recoge los ocho criterios que gobiernan el barrido.

Estado consultado en Supabase el 7 de agosto: 27 formas y 2 tramos sin forma; 57
arquitecturas; 39 denominaciones; 134 afirmaciones sobre 6 fuentes; 9 relaciones entre formas.

## Los defectos del informe que esperan una decisión

El [informe de conformidad](../informe-conformidad-catalogo.md) **no señala ningún
defecto**. Todos los que dependían de una decisión de modelado están resueltos y aplicados;
lo que queda en este archivo son precisiones filológicas que el catálogo puede esperar sin
quedar mal formado.

Las últimas en cerrarse fueron las cuatro preguntas con alcance de secuencia. Eran el mismo
malentendido de nivel visto cuatro veces: una pregunta con alcance de secuencia se responde
una vez para todo el pasaje, es decir, afirma que el hecho **no varía**; y lo que no varía y
además es estructural —metro o rima— no se pregunta, lo declara la arquitectura. El alcance
de secuencia queda para los rasgos, que describen el pasaje sin cambiar su estructura.

- El villancico y el zéjel preguntan ahora la medida **de cada sección**, porque pueden
  combinarlas; 6 y 8 son las registradas por típicas y otra se anota como desviación.
- La copla de arte mayor elige su esquema **en cada copla**, como la quintilla o el soneto:
  los tres alternan de estrofa en estrofa.

## Demarcador

1. **Las formas generales positivas no tienen prioridad residual.** La copla de pie quebrado
   recibe, por criterio del IP, las unidades de cinco a doce versos que combinan octosílabos y
   quebrados pero no corresponden a las arquitecturas simple o doble de la sextilla. El
   sexteto cumple una función semejante frente a formas más específicas de seis versos de arte
   mayor. El antiguo `grado_especificacion` pretendía que el demarcador ofreciera la forma más
   específica, pero se retiró porque el motor nunca lo usó; hoy todas las hipótesis se puntúan
   al mismo nivel. Hace falta una regla explícita de prioridad o una salida final separada. No
   es una relación `subtipo_de` ni `compuesta_por`: esas relaciones describen la ontología de
   las formas, no el orden en que el motor propone una clasificación.

## Endecha real

1. **El trigger de posiciones toma la caja por clase de rima.**
   `sincronizar_posiciones_esquema_rima_fijo` deriva las posiciones letra a letra de la
   notación, y de `-a-A` saca las clases `a` y `A` como si fueran dos rimas distintas. Pero la
   caja dice el **arte del verso**, no con quién rima: la lira escribe `aBabB` y son dos rimas,
   no cuatro. En la endecha real hubo que corregir la clase a mano después de insertar. **No es
   un problema de esta forma**: cualquier rima futura entre un verso de arte menor y otro de
   arte mayor caerá en lo mismo. Arreglarlo es cambiar una línea del trigger —comparar en
   minúsculas—, pero antes hay que comprobar si alguna forma ya poblada depende de la conducta
   actual.

2. **Las dos arquitecturas de sor Juana están fuera del teatro áureo, y habría que comprobar
   si eso importa.** La de cinco versos (`7-7-7-7-11`, `abbaA`) y la hexasílaba (`6-6-6-11`)
   se declaran porque Navarro Tomás y Jauralde las documentan, pero los dos las atribuyen a
   sor Juana y a la poesía culta del XVII-XVIII —Trillo y Figueroa, Vaca de Guzmán, Iriarte,
   Bello—, no al teatro. **Ninguna fuente dice que no aparezcan en teatro**; simplemente no lo
   tratan. Queda por decidir si el catálogo recoge todo lo que la teoría documenta o solo lo
   que el corpus dramático puede dar, y esa decisión afecta a más formas que a esta.

3. **Faltan dos cosas que Navarro Tomás documenta y no tienen dónde ir.** Sor Juana hizo
   también el último verso **decasílabo de dos adónicos**, y en los *Nocturnos de San Pedro*
   combina endecha real y sexteto con un pie quebrado que repite en eco la rima del segundo
   heptasílabo. Jauralde trata esa segunda entre las **estrofas de seis versos**, con el título
   «Variedad de la endecha real». Están registradas como afirmación de fuente; su sitio como
   forma, si lo tienen, está en el sexteto, y conviene mirarlo al revisarlo.

## Quintilla

1. **Nueva: ¿la quintilla es solo octosílaba?** El Diccionario dice «octosílabos **o menores**»
   y Jauralde documenta quintillas hexasilábicas y heptasilábicas. La única arquitectura del
   catálogo es octosilábica. Es el mismo tipo de decisión que se tomó en la redondilla, que sí
   tiene las tres medidas.

## Lira

1. **¿Qué relación tiene con el sexteto-lira?** No se ha creado familia ni relación automática
   entre las dos: se decidirá al revisar el sexteto-lira, y no se infiere del nombre. Lo que sí
   consta ya es que **Morley y Bruerton llaman «lira» a la estrofa de seis versos** `aBaBcC`
   —el sexteto-lira del catálogo— y a la de cinco «quintilla de Fray Luis de León». Comprobado
   que la equivalencia no las cruza: son términos legados distintos, cada uno con su forma.

## Silva

1. La silva libre deja de ser una arquitectura y pasa a ser el valor `ninguna` del rasgo
   `organizacion_en_pareados`. **El modelo no permite hoy que una denominación apunte a un
   valor de rasgo**, así que ese nombre no queda registrado en ninguna parte. ¿Hace falta que
   lo esté?

2. **`Silva · Endecasilábica` ofrece hoy el valor `ninguna`**, que según el reparto acordado
   pertenece al endecasílabo suelto. Mientras siga ofreciéndolo, una serie endecasilábica sin
   pareados encaja en las dos formas y el demarcador no puede separarlas. Comprobado en el
   dato el 4 de agosto. ¿Se retira ese valor de la silva?
3. ¿Se recoge la **silva 4** de Morley y Bruerton —7 y 11 mezclados, todas las rimas en los
   pares—? Sigue abierta, pero el 5 de agosto se comprobó una cosa que la enmarca: **tampoco
   estaba en el vocabulario viejo**. En los 119 términos de `estrofa_tipo` solo la familia del
   romance menciona los versos pares. No se perdió en la migración; no se declaró nunca.

   El cotejo aclara además de dónde salen las cuatro silvas del vocabulario:

   | Morley y Bruerton | Vocabulario del IP | Catálogo nuevo |
   | --- | --- | --- |
   | 1 · silva de consonantes `aAbBcC` | `silva_de_consonantes_regular` | Regular · Regulares |
   | 2 · 7 y 11 sin orden fijo de extensión ni rima | `silva_libre` | Libre · Ninguna |
   | — | `silva_de_consonantes_irregular` | Orden libre · Predominantes |
   | 3 · solo de once, 50-98 % rimados | `silva_de_endecasilabos` | Endecasilábica |
   | 4 · rimas en los pares | — | — |

   Que el vocabulario se hizo sobre Morley y Bruerton no es conjetura: `silva_de_endecasilabos`
   copia su cifra literalmente, «del 50 al 98% son rimados», y `silva_libre` traduce casi
   palabra por palabra su tipo 2. Lo que el IP añadió por su cuenta es
   `silva_de_consonantes_irregular`, partiendo el tipo 2 según si los pareados predominan — y
   el rasgo `Organización en pareados` del catálogo nuevo es la sistematización de esa
   distinción suya, llevada a cinco grados y extendida al endecasílabo suelto y al pareado.

   Junto a la silva 4 conviene decidir la **silva arromanzada** o silva-romance, que el
   Diccionario recoge (p. 395) y tampoco está: todos los versos pares con una misma rima
   **asonante**. Las cuatro arquitecturas del catálogo son consonantes, así que ninguna la
   acoge.
4. **¿La silva exige rima?** El Diccionario admite como silva la combinación de 7 y 11 sin
   rima. El catálogo no, y la definición ahora lo dice expresamente: «un pasaje de siete y
   once enteramente suelto no es una silva». La razón es de corpus y la respalda Navarro
   Tomás, § 158: desde 1588 Lope intercalaba pareados en pasajes de 7 y 11 **sueltos**, así
   que en la comedia lo que separa la silva del pasaje suelto es precisamente que rime.
   Conviene que el IP confirme ese corte, porque es el mismo que separa la silva del
   endecasílabo suelto en la pregunta 2.

## Soneto

1. ¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?
2. ¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?

## Villancico

1. Las fuentes describen la mudanza estable de cuatro versos como dos mudanzas simétricas.
   ¿Conviene segmentar esos dos miembros o conservar una sola sección de cuatro versos que
   registre internamente su simetría?
2. Domínguez Caparrós fija una vuelta canónica de tres o cuatro versos, mientras Navarro
   Tomás documenta ampliaciones y también la supresión del enlace o la vuelta. ¿Separamos
   esas realizaciones en configuraciones o mantenemos una vuelta abierta y opcional?
3. Se han formalizado `abba`, `abab` y la asonantada `abcb`. Navarro Tomás documenta además
   mudanzas excepcionales de seis versos: ¿deben entrar en el catálogo o quedar como
   desviación?
4. La configuración con estribillo posterior representa hoy una familia funcional abierta.
   La fuente autorizada que la sustenta describe de manera concreta una cuarteta octosilábica
   seguida por un estribillo en cuarteta hexasílaba. ¿La restringimos a esa modalidad moderna
   o conservamos el alcance general actual?

## Zéjel


1. ¿Se admiten estribillos de uno y de dos versos o el zéjel estricto exige dístico?
2. ¿Una repetición parcial del estribillo es posibilidad admitida o desviación?

## Copla real

*Revisada el 8 de agosto de 2026, partiendo de cero afirmaciones: era una de las tres formas
que se quedaron sin respaldo al retirarse las cinco fuentes no autorizadas.*

**Qué tiene hoy el catálogo:** una sola arquitectura, `octosilabica_consonante`, de diez
octosílabos en dos quintillas de cinco. El editor elige el esquema de cada quintilla entre los
ocho de la quintilla, por separado, y marca las posiciones quebradas si las hay. El pie
quebrado es rasgo admitido, no definitorio.

1. **¿Los quebrados pueden ocupar cualquiera de las diez posiciones?** Hoy la pregunta las
   ofrece las diez. Ninguna fuente fija dónde caen: el *Diccionario* solo dice que la estrofa
   «admite algún verso quebrado (tetrasílabo)» y Jauralde que con el tiempo llegó a quebrar
   alguno de sus versos. *Si se restringe, hay que decir a qué posiciones.*
2. **¿Solo tetrasílabos, o también pentasílabos?** Hoy la pregunta ofrece las dos medidas, como
   en la copla de pie quebrado. Pero las seis fuentes, al hablar de la copla real, **solo
   nombran el tetrasílabo**; el pentasílabo aparece en la otra forma. *Si vale solo el
   tetrasílabo, la pregunta pasa de 20 opciones a 10.*
3. **¿Admite la estructura 4-6, o solo 5+5?** Hoy el catálogo fija 5+5 y lo declara con dos
   secciones de cinco versos que reutilizan el repertorio de la quintilla. Jauralde advierte que
   las semiestrofas «no son necesariamente iguales» y que **la forma 4-6 precede a la 5-5**,
   mayoritaria solo a finales del siglo XV; Navarro Tomás describe el mismo proceso desde el
   modelo 4-4. *Si el corpus áureo solo da 5+5, lo actual basta y esto se cierra; si aparece una
   4-6, no cabe hoy en ninguna arquitectura.*
4. **¿Debe restringirse el par de quintillas?** Hoy las dos preguntas ofrecen los ocho esquemas
   con total independencia, así que el editor puede responder el mismo en las dos mitades.
   Morley y Bruerton, que describen a Lope, afirman que **las dos quintillas son de tipo
   diferente**: la segunda siempre `AABBA` y la primera casi siempre `ABABA`. No se ha
   restringido porque las otras cinco fuentes describen libertad de disposición y el catálogo
   cubre más que a Lope. *Si se restringe, deja de ser una elección libre y pasa a ser una
   restricción entre dos preguntas, que el modelo hoy no sabe expresar; va con la
   [auditoría de las preguntas](../revision-del-catalogo-estado.md#defectos-del-modelo-aplazados).*

## Copla de arte mayor

*Revisada el 8 de agosto de 2026. **Es la única forma de esta tanda en la que hubo que corregir
el dato, no solo la prosa.***

**Qué cambió, en concreto.** Tenía tres esquemas de rima: `ABBAACCA`, `ABBACDCD` y `ABABCDCD`.
Los dos últimos **estrenan dos rimas nuevas en el segundo cuarteto**, de modo que la estrofa
lleva cuatro rimas y los versos cuarto y quinto no riman entre sí. Eso contradice a cuatro
fuentes: Caparrós 2014 lo declara *necesario* —«una rima debe ser común a los dos cuartetos, y
el cuarto y quinto versos deben rimar entre sí»—, el *Diccionario* lo llama característico,
Navarro Tomás dice «con sólo tres rimas» y Jauralde describe el mismo enlace. Se retiraron y se
sustituyeron por `ABABBCCB` y `ABBAACAC`, que son los que Caparrós 2014 y el *Diccionario* dan
como más frecuentes junto al primero.

**Sobre nombres y slugs.** Estos esquemas nunca han tenido `nombre` —es `null` en los tres— y se
identifican por su `notacion`, que **sí conserva la caja** (`ABBAACCA`), porque en arte mayor la
mayúscula es dato. El slug va en minúsculas siguiendo
[la norma de nomenclatura](../historico/revision-nomenclatura.md), que lo fija así para todos
los esquemas de rima del catálogo: la octava real es `abababcc` y la lira, `ababb`. De modo que
no se renombró nada ni se cambió ninguna convención: se borraron dos filas y se insertaron dos
nuevas con el mismo criterio. Lo que sí se actualizó fue el slug y el nombre de las **opciones**
de la pregunta del editor, porque una opción rotulada `ABBACDCD` no puede apuntar a un esquema
`ABABBCCB`. Y los dos esquemas nuevos **no heredan el `origen_termino_id`** de los retirados, a
propósito: un término legado llamado `copla_de_arte_mayor_tipo_2_ABBACDCD` no puede reclamar un
esquema `ABABBCCB` sin afirmar una equivalencia falsa. Ninguna obra usa hoy esos términos.

1. **¿Los tres esquemas son ahora un repertorio cerrado?** Siguen siendo tres, pero ya no son
   los mismos. Los tres actuales enlazan los cuartetos, que es lo que la norma exige; una
   guarda en migración impide que se declare uno con más de tres clases de rima. *La pregunta es
   si faltan otros enlazados que las fuentes no destaquen.*
2. **¿Se admite la copla de cuatro rimas como desviación?** Navarro Tomás registra una,
   `ABBA:CDDC`, en una carta de Tirso de Molina en *Quien calla otorga* —y anota que los propios
   personajes aluden al carácter antiguo de la estrofa—. Es exactamente lo que el catálogo
   acaba de retirar como esquema normal. *Si el corpus trae una, hoy no cabe: habría que
   registrarla como desviación localizada, no como esquema de la forma.*
3. **¿La arquitectura debe seguir llamándose dodecasilábica?** Hoy declara `12-repetido` en sus
   ocho posiciones. Jauralde advierte que, por la estructura rítmica del verso, **su número de
   sílabas varía entre diez y dieciséis**. La descripción ya no presenta la medida como
   invariable, pero el esquema métrico sigue fijando doce. *Si el corpus trae un verso de trece
   o catorce, hoy sería una desviación métrica y no una realización admitida.*
4. **¿Se incorporan la copla de arte menor y la copla castellana?** No están en el catálogo, y
   las seis fuentes las tratan como formas aparte: la de arte menor son ocho octosílabos en dos
   redondillas con el mismo enlace que la de arte mayor, y la castellana es la combinación
   `abba:cddc` que Navarro Tomás documenta **con lugar importante en la versificación del teatro
   del siglo XVI**. Esa última nota la hace más probable en el corpus de lo que parece.

## Copla de pie quebrado

*Revisada el 7 de agosto de 2026. Su ficha, compartida con las otras coplas y la sextilla, se
retiró el 8 de agosto al quedar revisadas las cuatro; estas dudas venían de ahí.*

**Qué tiene hoy el catálogo:** una arquitectura, `octosilabica_con_quebrados`, y es la forma
**general** del quebrado —la salida para las coplas que combinan octosílabos con versos más
breves y no encajan en ninguna forma más específica—. Su unidad es un **rango de 5 a 12
versos**, no una cifra fija, y su disposición de rima es abierta. De ahí que su pregunta tenga
**24 opciones**: doce posiciones por dos medidas, generadas para el caso máximo porque el
catálogo no puede saber cuántos versos tendrá cada copla.

1. **Es la única forma del catálogo que puede desbordar, y conviene no olvidarlo.** Como la
   unidad es un rango y las opciones cubren el máximo, el catálogo por sí solo no impide que se
   responda sobre un verso que no existe —«el verso 11 es tetrasílabo» en una copla de cinco— ni
   que se den dos medidas para la misma posición. La comprobación no cabe en el catálogo, donde
   la unidad es un rango: está en **un disparador sobre las elecciones**, que solo puede
   validarlo al guardar, cuando ya se sabe cuántos versos tiene esa realización. *No es una duda
   abierta, es una fragilidad conocida que hay que recordar si se toca el modelo de elecciones.*

## Sextilla

*Revisada el 8 de agosto de 2026. Su ficha, compartida con las coplas, ya se retiró.*

**Qué tiene hoy el catálogo:** cinco arquitecturas —`octosilabica`, `heptasilabica`,
`hexasilabica`, `pie_quebrado` (`8-8-4-8-8-4`) y `doble_pie_quebrado` (12 versos)—. La
disposición de la rima es abierta y no se pregunta, salvo en la doble. La revisión añadió las
tres disposiciones que la tradición nombra —alterna `ababab`, correlativa `abcabc`, simétrica
`aabccb`— como esquemas **admitidos y descriptivos**: no generan pregunta al editor.

1. **¿La sextilla de pie quebrado es exactamente `8-8-4-8-8-4`?** El catálogo lo afirmaba como
   invariable y la revisión **lo desmiente**: el *Diccionario* ilustra su entrada con una
   estrofa de Lucas Fernández quebrada en **segundo y quinto**, y Jauralde documenta las
   sextillas de Ricardo Gil con el tetrasílabo en esas mismas posiciones. La nota del rasgo ya
   no dice que la posición sea fija. *Si el corpus trae una así, ¿es una arquitectura más o una
   desviación de la existente?*
2. **¿Las medidas 6, 7 y 8 son un repertorio cerrado?** Jauralde ordena las sextillas por medida
   y describe también **tetrasilábicas y pentasilábicas**. Las tres del catálogo son las del
   corpus, no las de la bibliografía.
3. **¿Nada distingue dos sextillas consecutivas de una doble sextilla?** Los versos, las medidas
   y el tipo de rima son idénticos; lo único que cambia es si las rimas de la segunda mitad
   dependen de la primera. Hoy **lo decide el editor al elegir arquitectura**, no un criterio
   observable. *¿Debe seguir siendo así?*
4. **¿Debe registrarse el esquema exacto de las dobles sextillas no manriqueñas?** Hoy la doble
   tiene dos esquemas: el manriqueño `abcabc|defdef`, que se marca si es el observado, y uno de
   distribución variable para todo lo demás, que **no guarda cuál fue**. *Si interesa comparar
   dobles sextillas entre sí, esa información hoy se pierde.*

## Décimas

1. ¿El linaje debe limitarse por ahora a copla real, décima espinela y décima
   aumentada?
2. ¿Se mantiene «Décima aumentada» como nombre público preferente?
3. ¿La definición pública de la espinela debe conservar la expresión «dos redondillas
   enlazadas por dos versos puente»?

## Redondilla

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Si no puede, son dos
   arquitecturas más y la redondilla se registra sin ninguna pregunta. Mientras la duda
   siga abierta se mantiene como esquema elegido por unidad, que es la opción reversible:
   corregirlo después es reclasificar filas, mientras que haberlo tratado como
   arquitectura habría partido secuencias que no debían partirse.
2. ¿Debe incorporarse «octavilla» como denominación relacionada o resultaría
   demasiado amplia?

## Octava real

El catálogo mantiene el alcance endecasilábico del proyecto y no incorpora automáticamente la
octavilla real excepcional documentada en la bibliografía.

Revisada el 5 de agosto, **aparece una decisión que sí conviene tomar**:

1. **¿Una estrofa o dos?** Caparrós 2014 remite en nota a la discusión de Lázaro Carreter
   (1983) sobre si la octava real es una estrofa o la unión de dos, y el Diccionario observa
   que suele subdividirse en dos grupos de cuatro versos según el contenido. El catálogo la
   trata como una unidad de ocho y no declara secciones: es una posición, y está sin escribir.

## Novena

1. Al resolver el modelo de formas abiertas, aplicar la separación acordada entre **Novena**
   general y **Copla novena** como forma subordinada. Las arquitecturas 4+5 y 5+4 pasarán a la
   Copla novena; queda por decidir cómo se registra la Novena general sin demarcar por defecto
   cualquier pasaje de nueve versos.
2. ¿Cómo se representan las realizaciones tempranas en las que redondilla y quintilla comparten
   una o dos clases de rima, frente a las posteriores con rimas independientes?
3. ¿Las ocho variedades actuales de quintilla pertenecen al repertorio de la Copla novena o
   deben restringirse según la documentación histórica?

## Sexteto-lira

*Revisado el 8 de agosto de 2026. Su ficha ya se retiró.*

**Qué tiene hoy el catálogo:** una sola arquitectura, `heterometrica_consonante`, de seis versos
de 7 y 11 sílabas, y **siete tipologías** que acoplan cada patrón métrico con uno de rima —A1
`aBaBcC` (preferente), A2, A3, B1, B2, C1, C2—. El editor elige una tipología por estrofa. Es la
forma que concentra **7 de las 8 variedades de todo el catálogo**.

1. **El repertorio no está cerrado, y ya no es una duda: está demostrado.** Navarro Tomás
   enumera `aBaBCC`, `AbAbcC`, `AbbAcC`, `AabBCC` «etc.»; Morley y Bruerton, `aBaBcC`, `abbacC`,
   `AabBcC`, `AabBCC` «etc.». De ellas, **`AbAbcC` y `AbbAcC` no están en el catálogo**. No se
   añadieron a propósito: el problema no es que falten dos, sino que la variedad acopla medida y
   rima en un solo registro y las parejas documentadas no tienen cierre. *Va a la
   [lectura transversal de la variedad](../revision-del-catalogo-estado.md#defectos-del-modelo-aplazados):
   ¿son variedades, dos elecciones independientes, o una restricción entre ambas?*
2. **¿A1 debe seguir marcada como preferente?** Hoy lo está. Navarro Tomás y Morley y Bruerton
   coinciden en que `aBaBcC` es la forma regular, así que la preferencia tiene respaldo. *Queda
   decidir si el editor debe verla destacada en la interfaz.*
3. **¿Una tirada puede cambiar de tipología entre estrofas y seguir siendo una secuencia?** Hoy
   el editor puede responder una distinta en cada unidad. Morley y Bruerton observan que el tipo
   adoptado al comienzo de un pasaje **suele conservarse a lo largo de él**, lo que apoya tratar
   el cambio como excepción y no como norma. *Si se decide que no puede cambiar, un cambio pasa
   a ser una desviación o el corte entre dos secuencias.*
4. **¿Debe llamarse sexteto-lira o lira?** Las seis fuentes la subordinan a la lira, y **Morley
   y Bruerton —la fuente del verso dramático de Lope— la llaman simplemente *Lira***, que es el
   nombre con el que está descrita la métrica de las comedias. El catálogo conserva
   «Sexteto-lira» porque lo distingue de la lira de cinco versos, y «Lira» quedó registrada como
   denominación con su fuente. *Conviene confirmar que ese es el orden de preferencia y no al
   revés.*
5. **¿Dónde va el `abC:abC` de san Juan de la Cruz?** Navarro Tomás lo documenta en la *Llama de
   amor viva*: seis versos de siete y once sílabas, pero **sin pareado final**, de modo que no
   cabe en la definición actual, que exige el pareado de tercera rima. *¿Es otra forma, una
   tipología que obliga a ensanchar la definición, o queda fuera del corpus?*

## Sexteto

*Revisado el 8 de agosto de 2026. Su ficha ya se retiró.*

**Qué tiene hoy el catálogo:** tres arquitecturas por medida —`endecasilabica` (principal),
`dodecasilabica`, `alejandrina`—, seis versos isosilábicos de arte mayor con rima consonante y
disposición abierta. El editor elige la medida y anota el esquema observado. La disposición
`ABABCC` es la variedad **sexta rima**, que Jauralde llama en cambio *sextina real*.

**El hilo común de las tres primeras dudas:** las fuentes definen el sexteto **más ancho que el
catálogo**, y el recorte es una decisión del proyecto, no un descuido. Ninguna bloquea el
registro actual.

1. **¿Se admite el sexteto que combina arte mayor y menor?** Hoy no: el catálogo exige
   isosilabismo de arte mayor. Pero Caparrós 2014 lo incluye en la propia definición —«de arte
   mayor, o de arte mayor y menor combinados entre sí»—, el *Diccionario* añade que a veces el
   término cubre también el arte menor, y Jauralde reserva un grupo a los «sextetos mixtos». El
   catálogo lo separa a propósito: la heterometría regular con endecasílabo es del sexteto-lira
   y el arte menor es de la sextilla. *Si el corpus trae uno que no sea ninguna de las dos, hay
   que decidir si se amplía esta forma o se crea otra.*
2. **¿Las medidas 11, 12 y 14 son un repertorio cerrado?** Jauralde describe además sextetos
   eneasilábicos, decasilábicos y pentadecasilábicos. Las tres del catálogo son las del corpus,
   no las de la bibliografía.
3. **¿La consonancia es exigible?** Hoy es definitoria en las tres arquitecturas. Navarro Tomás
   documenta en el modernismo el sexteto asonante `abcbDB` de Darío y tipos que dejan sueltos
   varios versos. En el corpus áureo la consonancia es la norma. *Conviene confirmar que ninguna
   secuencia obligue a relajarla.*
4. **Sigue sin sitio la variedad de los *Nocturnos de San Pedro*.** Navarro Tomás describe una
   combinación de endecha real y sexteto con un pie quebrado que repite en eco la rima del
   segundo heptasílabo; se anotó al revisar la endecha real. Ninguna de las seis fuentes la
   formaliza como sexteto autónomo, así que la revisión **no la ha creado**. *Queda como forma
   sin hueco.*

## Seguidilla


- No bloquea el registro actual: se distinguen las arquitecturas simple, compuesta, de tres
  versos, chamberga, gitana y real.
- Al revisar conjuntamente las formas abiertas, decidir cómo se representa la fluctuación
  histórica de la simple sin enumerar todas las combinaciones ni reducirla a prosa.
- Revisar también cómo se declara la asonancia compartida entre unidades en la seguidilla
  simple arromanzada, y si las realizaciones consonantes recurrentes deben ser opciones
  admitidas o desviaciones.

## Canción petrarquista


1. ¿La canción sin rima o canción libre debe seguir siendo arquitectura de la canción
   petrarquista o tiene identidad suficiente para ser forma?
2. ¿Debe exigirse siempre remate o envío en las canciones registradas?
3. ¿Se mantiene el mínimo de 5 versos por estancia fijado por el proyecto, pese al
   mínimo de 9 indicado por Domínguez Caparrós?

## Tramos sin forma


1. Confirmar si `Verso aislado` debe ser la etiqueta pública definitiva de la antigua
   entrada `verso suelto`.
