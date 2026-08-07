# Cuestiones para el IP

Actualizado: 7 de agosto de 2026

Este archivo reúne solo decisiones pendientes. **Lo descriptivo ya no vive aquí ni en fichas
sueltas: vive en el catálogo, y se lee en `/formas`.** A medida que una forma se revisa, su
prosa se muda al dato, sus dudas resueltas se borran de aquí y su ficha `.md` se retira: el
catálogo es el documento vivo y un `.md` paralelo solo puede quedarse viejo.

Revisadas y con ficha ya retirada: romance, redondilla, décima, silva, soneto, quintilla, lira,
octava real, cuarteto, terceto, terceto encadenado, pareado, endecha real, seguidilla, sextina
—como estrofa y como composición— y villancico. La copla de pie quebrado está revisada; su
ficha es compartida con la sextilla y las otras coplas pendientes, por lo que se retirará
cuando se absorban también esas formas. Las fuentes de la novena están revisadas y su ficha se
retiró, pero su separación respecto de la copla novena depende del modelo abierto pendiente.

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


1. ¿Los quebrados pueden ocupar cualquiera de las diez posiciones?
2. ¿Se admiten únicamente tetrasílabos o también pentasílabos?

## Coplas y sextillas


1. **Nada en el modelo distingue dos sextillas consecutivas de una doble sextilla.** Los
   versos, las medidas y el tipo de rima son los mismos; solo cambia si las rimas de la
   segunda mitad dependen de la primera. Hoy lo afirma el editor al elegir arquitectura.
   ¿Debe seguir siendo así o hay un criterio observable que lo decida?
2. ¿La sextilla de pie quebrado es exactamente `8-8-4-8-8-4`? La bibliografía documenta
   también sextillas heterométricas con otra distribución; si el corpus las trae, serían una
   arquitectura más.
3. ¿Las medidas 6, 7 y 8 forman un repertorio cerrado para la sextilla isométrica?
4. ¿Debe registrarse el esquema exacto de las dobles sextillas no manriqueñas?
5. ¿Los tres esquemas de copla de arte mayor son un repertorio cerrado?
6. ¿Copla de arte menor y copla castellana se incorporarán solo si aparecen en el
   corpus?

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


1. ¿Las siete variedades son un repertorio cerrado, las reconocidas hasta ahora o
   medida y rima pueden combinarse libremente? Si aparecen otras parejas restringidas,
   se ampliarían las combinaciones; solo si ambos ejes son independientes se
   preguntarían por separado.
2. ¿A1 debe seguir presentándose como variedad habitual o preferente?
3. ¿Una tirada puede cambiar de variedad entre estrofas sin dejar de constituir una
   única secuencia?

## Sexteto


- No bloquea el registro actual: el proyecto lo delimita como seis versos de arte mayor
  consonantes, repartidos en tres arquitecturas por medida —11, 12 y 14—.
- Si el corpus documenta un sexteto que combine arte mayor y menor y no sea sexteto-lira,
  confirmar si debe ampliarse la forma o crearse otra.
- ¿Las medidas 11, 12 y 14 forman un repertorio cerrado?

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
