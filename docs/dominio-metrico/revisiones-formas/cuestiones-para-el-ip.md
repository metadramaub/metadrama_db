# Cuestiones para el IP

Actualizado: 9 de agosto de 2026

Este archivo reúne solo decisiones pendientes. **Lo descriptivo ya no vive aquí ni en fichas
sueltas: vive en el catálogo, y se lee en `/formas`.** El catálogo es el documento vivo; un
`.md` paralelo solo puede quedarse viejo.

**La revisión filológica está terminada.** Las 27 formas activas y los dos tramos sin forma se
han contrastado con las seis monografías, y **este archivo es lo único que queda en
`revisiones-formas/`**: todas las fichas `.md` se han retirado porque su contenido descriptivo
vive ya en el catálogo.

## Cómo se lee este archivo

Cada forma abre con **qué tiene hoy el catálogo** —lo que hace falta saber para decidir sin
abrir la base— y cada duda cierra en cursiva con **qué cambiaría si se decide otra cosa**. Las
resueltas se dejan tachadas con su respuesta cuando la respuesta es en sí un dato que conviene
no volver a buscar.

**Tres bloques que conviene no confundir:**

1. **Lo que bloquea de verdad** — nada. Ninguna duda de este archivo impide anotar hoy. El
   [informe de conformidad](../informe-conformidad-catalogo.md) no señala ningún defecto.
2. **Lo que se decide junto, no forma por forma.** Varias dudas son la misma pregunta vista
   desde formas distintas y se responden en las
   [lecturas transversales](../revision-del-catalogo-estado.md#defectos-del-modelo-aplazados).
   Están marcadas **⇒ transversal** con el nombre de la lectura que las absorbe.
3. **Lo que es filología de una forma sola** y se puede decidir cuando se quiera.

### Las dudas que cruzan formas

Son las que no se ven leyendo una sola sección, y por eso van aquí arriba:

| Cruce | Dónde | Estado |
| --- | --- | --- |
| **Silva endecasilábica y endecasílabo suelto ofrecían los dos el valor `ninguna`** de organización en pareados, así que una serie de once sin pareados encajaba en las dos formas | [Silva](#silva) 2 · [Endecasílabo suelto](#endecasílabo-suelto) 3 | **resuelto el 9 de agosto**: se retiró de la silva, siguiendo el corte cuantitativo de Morley y Bruerton. Era el único solape del catálogo |
| **El umbral del 50 % que separa sueltos de silva vive solo en las afirmaciones**: los grados del rasgo son cualitativos y nada declara la correspondencia | [Silva](#silva) 3 · [Endecasílabo suelto](#endecasílabo-suelto) 1 | abierto ⇒ transversal de las preguntas |
| Qué es una **variedad**, si el repertorio del sexteto-lira no tiene cierre | [Sexteto-lira](#sexteto-lira) 1 · [Sexteto](#sexteto) · [Quintilla](#quintilla) | ⇒ transversal de la variedad |
| Qué **repertorios están cerrados** —medidas, esquemas— y cuáles son recortes del corpus | [Sexteto](#sexteto) 2 · [Sextilla](#sextilla) 2 · [Quintilla](#quintilla) 1 · [Soneto](#soneto) 1 · [Copla de arte mayor](#copla-de-arte-mayor) 1 | ⇒ transversal de la modalidad |
| Qué **elecciones dependen de otras**, que el modelo hoy no sabe expresar | [Copla real](#copla-real) 4 · [Sexteto-lira](#sexteto-lira) 1 | ⇒ transversal de las preguntas |
| Cómo se representa una **norma abierta** sin enumerar cada realización | [Silva](#silva) 3 · [Seguidilla](#seguidilla) · [Novena](#novena) 1 · [Copla de pie quebrado](#copla-de-pie-quebrado) | ⇒ transversal de los esquemas abiertos |

**Cerrados por la revisión de las últimas formas**, y anotados aquí porque estuvieron abiertos
meses: la relación entre **Lira y sexteto-lira** —Morley y Bruerton llaman «lira» a la estrofa
de seis, y el catálogo lo registra como denominación— y el sitio de la **variedad de los
*Nocturnos de San Pedro***, que se buscó en el sexteto y no lo tiene en ninguna de las seis
fuentes.

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

Estado consultado en Supabase el **9 de agosto**: 27 formas y 2 tramos sin forma; 57
arquitecturas; 8 variedades; **65 denominaciones**; **179 afirmaciones** sobre 6 fuentes; 10
relaciones entre formas. Todas las formas y los dos tramos tienen ya afirmaciones: no queda
ninguna en cero.

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

---

# Series y composiciones largas

## Silva

**Qué tiene hoy el catálogo:** cuatro arquitecturas, todas consonantes, y el rasgo
`organizacion_en_pareados`, que es el eje que separa la silva del endecasílabo suelto y de la
tirada de pareados. El rasgo tiene **cinco grados ordenados y cualitativos**: `ninguna` (1),
`ocasionales` (2), `habituales` (3), `predominantes` (4), `regulares` (5).

**Cada arquitectura se sitúa en ese eje**, y tres de las cuatro lo hacen sin preguntar nada: lo
declaran como rasgo `definitorio` con un valor fijo. La tabla del apartado siguiente cruza cada
una con su término legado y con la fuente de la que sale.

### El vocabulario: quién llama cómo a qué

Es el punto que más se enreda, porque **la misma palabra significa cosas distintas en cada
capa**. El reparto exacto:

| Concepto | Morley y Bruerton | Vocabulario legado del IP | Catálogo nuevo | Grado de pareados |
| --- | --- | --- | --- | --- |
| Pareados de 7 y 11 **siempre igual** (`aAbBcC`) | silva **1.ª**, «se podría llamar pareados de 7 y 11» | `silva_de_consonantes_regular` | `Silva · Consonante regular` | `regulares`, fijo |
| Pareados **mayoritarios pero sin patrón fijo** (`AABbcCDDEe`) | — *(partición propia del IP)* | `silva_de_consonantes_irregular` | `Silva · Consonante de orden libre` | `predominantes`, fijo |
| 7 y 11 sin orden fijo, **sin pareados**, con algunos sueltos | silva **2.ª** | `silva_libre` | `Silva · Libre` | `ninguna`, fijo |
| Solo endecasílabos, **50-98 % rimados** | silva **3.ª** | `silva_de_endecasilabos` | `Silva · Endecasilábica` | se **pregunta**: `habituales` o `predominantes` |
| 7 y 11, todas las rimas en los pares | silva **4.ª** | — | — *(véase la duda 4)* | — |
| Endecasílabos con **menos del 50 %** rimado | **sueltos** | `endecasilabo_suelto` | forma `Endecasílabo suelto` | se pregunta: `ninguna` u `ocasionales` |

**Tres de las cuatro arquitecturas no preguntan nada**: declaran su grado como rasgo
`definitorio` y fijo. Solo la endecasilábica pregunta, porque es la única cuya fuente le da un
intervalo —del 50 al 98 %— en vez de un valor.

**De dónde sale cada cosa.** Que el vocabulario legado se hizo sobre Morley y Bruerton no es
conjetura: `silva_de_endecasilabos` copia su cifra literalmente —«del 50 al 98 % son
rimados»— y `silva_libre` traduce casi palabra por palabra su tipo 2. Lo que el IP añadió por
su cuenta es **partir la silva 1.ª en dos**: la de pareados sistemáticos, que conserva el
nombre `silva_de_consonantes_regular`, y la de pareados mayoritarios pero de disposición
variable, `silva_de_consonantes_irregular` —de ahí que las dos se llamen «de consonantes»—.

**Y el eje de los pareados ya estaba en el vocabulario legado, con porcentajes.** La definición
de `silva_de_endecasilabos` lo dice entera: «la mayoría son rimados (del 50 al 98 %)… Si los
pareados suponen un porcentaje **menor**, estamos ante **endecasílabo suelto**; si suponen entre
el **99-100 %**, estamos ante **pareado endecasílabo**». El rasgo `organizacion_en_pareados` del
catálogo nuevo **no inventa esa escala: la formaliza**, y la
[matriz de reclasificación](../historico/matriz-reclasificacion-formas-metricas.md) dejó dicho
que la conversión a grados cualitativos era deliberada —«no se conservarán porcentajes exactos…
las configuraciones utilizarán modalidades cualitativas»—. Es el origen del hueco que describe
la duda 3.

**Cuidado con «libre», que nombra tres cosas distintas.** En M&B, su silva 2.ª. En el catálogo,
la arquitectura `Silva · Libre`, **que es esa misma silva 2.ª** y declara el valor `ninguna`. Y
en la crítica moderna, la *silva libre* de medidas mezcladas y por lo común sin rima, que no es
ninguna de las dos y no está en el catálogo; la descripción de la arquitectura ya lo advierte.

1. **El término legado `silva_libre` no lo reclama nada, y la equivalencia se queda coja.**
   La arquitectura `Silva · Libre` existe y lleva su nombre, pero **no declara
   `origen_termino_id`**, de modo que ninguna cadena de equivalencia lleva el término legado
   hasta ella: comprobado el 9 de agosto, `silva_libre` no aparece en
   `propuesta_metrica_secuencia` y no lo reclama ninguna arquitectura, esquema, variedad ni
   denominación. *Hoy ninguna obra lo usa, así que no rompe nada; pero si apareciera, resolvería
   a la forma Silva sin arquitectura, cuando existe una que le corresponde exactamente.*

2. ~~**`Silva · Endecasilábica` ofrecía el valor `ninguna`**, que según el reparto acordado
   pertenece al endecasílabo suelto, de modo que una serie de once sin pareados encajaba en las
   dos formas.~~ **Resuelto el 9 de agosto de 2026: se retiró de la silva.** Era el único
   solape declarado del catálogo.

   **Lo que dice cada fuente**, que es lo que sostiene la decisión:

   | Fuente | Qué dice de una serie de once sin rima |
   | --- | --- |
   | **Morley y Bruerton** | Su silva 3.ª son versos «todos de 11 sílabas, la mayoría (**del 50 al 98 %**) rimados»; clasifican como **sueltos** aquellos pasajes en que «el porcentaje de los versos rimados es **menos de 50**». Advierten expresamente que la silva 3.ª «se puede parecer a los sueltos o pareados de 11» |
   | **Navarro Tomás** (§ 158) | En la silva los versos «podían estar rimados en su totalidad o bien **algunos** de ellos… podían quedar sueltos» |
   | **Caparrós 2014** (pp. 232-233) | Llama **verso suelto** al caso en que «ninguno lleva rima», aunque lo clasifique como «una clase de silva» |
   | **Quilis** (§ 6.4.3) | Lleva los poemas sin rima a un epígrafe aparte, «poemas de versos sueltos» |
   | **Jauralde** | Trata el **verso blanco** como fenómeno de ausencia de rima, no como silva; y es categoría moderna, no descripción de la silva áurea |
   | **Diccionario** | **La excepción**: «también se considera silva la combinación de endecasílabos y heptasílabos sin rima» |

   El argumento decisivo es que **el valor contradecía a la fuente de la que sale la propia
   arquitectura**: `Silva · Endecasilábica` viene de `silva_de_endecasilabos`, que es la silva
   3.ª de M&B, definida por tener entre el 50 y el 98 % de versos rimados. Ofrecer `ninguna`
   era admitir el 0 % en una arquitectura definida por no tenerlo. M&B ya habían visto el
   parecido entre su silva 3.ª y los sueltos y lo cortaron por la proporción de rima, de modo
   que las dos definiciones encajan sin hueco ni solape.

   La excepción del *Diccionario* se conserva **solo en las afirmaciones de fuente y no se
   codifica como opción**, por decisión del IP: habla de **siete y once**, no de la serie solo
   endecasilábica que producía el conflicto, y es la misma lectura de la que el catálogo ya se
   aparta en la duda 4.

   *Qué cambió exactamente: la pregunta de la silva endecasilábica pasó de tres opciones a dos
   —`habituales` y `predominantes`—, y `ninguna` queda solo en el endecasílabo suelto, que es la
   otra arquitectura que pregunta. **No se tocó nada más**: ni la arquitectura `Silva · Libre`,
   que sigue declarando `ninguna` como rasgo definitorio y fijo —eso es la silva 2.ª de M&B, no
   una serie sin rima—, ni la escala de cinco grados del rasgo, que la usan también el pareado
   y el endecasílabo suelto. Ninguna anotación resultó afectada.*

3. **Los porcentajes de Morley y Bruerton no están en el dato, y esto es un hueco.** Los cinco
   grados del rasgo son **cualitativos**: «Los pareados son frecuentes, aunque no obligatorios»,
   «Los pareados organizan predominantemente la serie». Las cifras —menos del 50 %, del 50 al
   98 %— viven **únicamente en las afirmaciones de fuente**, como prosa, y **nada declara la
   correspondencia entre una y otra escala**. *Un editor que observe un pasaje con el 40 % de
   versos rimados no tiene en el catálogo con qué decidir si eso es `ocasionales` o
   `habituales`. Si el proyecto quiere el criterio cuantificador de M&B, hay que decidir si esa
   correspondencia se declara —y dónde— o si se acepta que el grado lo estime el editor.*
   **⇒ transversal de las preguntas**, junto con lo que se derive del dato.
4. **¿Se recoge la silva 4.ª de Morley y Bruerton** —7 y 11 mezclados, **todas las rimas en los
   pares**—? **Sigue abierta por decisión del IP.** El 5 de agosto se comprobó una cosa que la
   enmarca: **tampoco estaba en el vocabulario legado**. En los 119 términos de `estrofa_tipo`
   solo la familia del romance menciona los versos pares, de modo que no se perdió en la
   migración: no se declaró nunca. *Si entra, es una arquitectura más, y hay que decidir si su
   rima en los pares la acerca al romance heroico.*

   Junto a ella conviene decidir la **silva arromanzada** o silva-romance, que el *Diccionario*
   recoge (p. 395) y tampoco está: todos los versos pares con una misma rima **asonante**. Las
   cuatro arquitecturas del catálogo son consonantes, así que ninguna la acoge.

5. **¿La silva exige rima?** El *Diccionario* admite como silva la combinación de 7 y 11 sin
   rima. El catálogo no, y la definición lo dice expresamente: «un pasaje de siete y once
   enteramente suelto no es una silva». La razón es de corpus y la respalda Navarro Tomás
   (§ 158): desde 1588 Lope intercalaba pareados en pasajes de 7 y 11 **sueltos**, así que en
   la comedia lo que separa la silva del pasaje suelto es precisamente que rime. *Es el mismo
   corte que la duda 2 resolvió para la serie endecasilábica, visto ahora en la heterométrica.
   Por decisión del IP la lectura del Diccionario se conserva en las afirmaciones de fuente y
   no se codifica como opción; conviene confirmar que el corte vale también aquí.*

## Endecasílabo suelto

*Revisado el 8 de agosto de 2026, el último de las 27 por decisión del IP. Su ficha, compartida
con el pareado y la silva, ya se retiró.*

**Qué tiene hoy el catálogo:** una arquitectura, `endecasilabica`, con la restricción
`versos_sueltos = predominantes` y tres rasgos que el editor observa —`organizacion_en_pareados`
(`ninguna` u `ocasionales`), `distico_final` y `encadenamiento_interior`—. Seis secuencias
reales lo usan hoy a través del término legado `endecasilabo_suelto_puro`.

**El vocabulario, capa por capa.** Conviene tenerlo delante porque las tres capas usan palabras
distintas para lo mismo, y una de ellas —«verso blanco»— pertenece además a otra época:

| Concepto | Morley y Bruerton | Vocabulario legado del IP | Catálogo nuevo | Otras fuentes |
| --- | --- | --- | --- | --- |
| Serie de once con menos del 50 % rimado | **sueltos** (`su.`) | `endecasilabo_suelto`, `endecasilabo_suelto_puro` | forma `Endecasílabo suelto` | **verso suelto** (*Diccionario*, Quilis, Caparrós) |
| Serie de once con 50-98 % rimado | silva **3.ª** | `silva_de_endecasilabos` | `Silva · Endecasilábica` | — |
| Ausencia **sistemática** de rima | — | — | — *(no se distingue)* | **verso blanco** (Jauralde, *Diccionario* como sinónimo) |

**«Verso blanco» es categoría moderna y no describe la práctica áurea.** Jauralde la separa
expresamente del verso suelto —sistemática frente a esporádica— y la sitúa como fenómeno del
siglo XX; el *Diccionario* la da como sinónimo de verso suelto. El catálogo **no la distingue**,
y por decisión del IP se queda así: la registra como denominación de esta forma, sin crear un
nivel que el corpus dramático no necesita.

1. **La restricción «predominan los sueltos» tiene umbral en la fuente y no está formalizado.**
   Morley y Bruerton clasifican un pasaje como sueltos «cuando el porcentaje de los versos
   rimados es **menos de 50**», y su silva 3.ª entre el **50 y el 98 %**: las dos definiciones
   encajan sin hueco, y **son el criterio cuantificador que el proyecto quiere seguir**. Pero el
   catálogo lo dice solo en palabras: la restricción declara `versos_sueltos = predominantes` y
   los grados del rasgo son cualitativos, sin ninguna cifra. *El umbral vive hoy únicamente en
   la afirmación de fuente. Si ha de ser operativo —que el editor o el demarcador puedan aplicar
   el 50 %—, hay que decidir dónde se declara la correspondencia entre porcentaje y grado.* Es
   la misma pregunta que la duda 3 de la [Silva](#silva). **⇒ transversal de las preguntas.**
2. **¿Se admiten series sueltas de otras medidas?** Esta forma es endecasilábica por definición.
   Caparrós documenta el heptasílabo sin rima de Francisco de la Torre y ocho octosílabos
   sueltos de Hurtado de Mendoza; el *Diccionario* añade series de pentasílabos. **Y Navarro
   Tomás documenta en el teatro áureo la mezcla de endecasílabos y heptasílabos sueltos**, en
   las tragedias *Nise* de Jerónimo Bermúdez. *Ese último caso es el que más probablemente
   aparezca en el corpus y hoy no cabe: sería una desviación métrica sobre cada heptasílabo.*
3. ~~**Comparte con la silva endecasilábica el valor `ninguna`**, de modo que una serie de once
   sin pareados encaja en las dos formas y el demarcador no puede separarlas.~~ **Resuelto el 9
   de agosto de 2026**: el valor se retiró de la silva, no de aquí. El reparto queda
   `ninguna` y `ocasionales` en el endecasílabo suelto; `habituales` y `predominantes` en la
   silva endecasilábica. El razonamiento con las seis fuentes está en [Silva](#silva) 2, donde
   vivía el problema: era la silva la que ofrecía un valor que su propia fuente —la silva 3.ª
   de Morley y Bruerton, «del 50 al 98 % rimados»— excluye.
4. **¿Es «una clase de silva», como dice Caparrós 2014?** El catálogo las tiene como formas
   distintas unidas por `contrasta_con`, y la nota de esa relación ya explica el eje —predominio
   de sueltos frente a predominio de rimados—. Ninguna otra fuente las identifica. *No se han
   fusionado; queda registrado que una de las seis las clasifica juntas.*

## Canción petrarquista

*Revisada el 8 de agosto de 2026. Su ficha ya se retiró.*

**Qué tiene hoy el catálogo:** tres arquitecturas —`regular_13_versos` (principal, esquema
`abCabC:cdeeDfF`), `estancias_consonantes_variables` (estancias de 5 a 20 versos) y
`sin_rima_con_pareado_final`—. Todas exigen un mínimo de tres estancias y admiten un remate
opcional. La distribución métrica y el esquema de rima llevan `define_norma`: se responden en
cada estancia, pero todas las de una misma canción deben coincidir, y la base lo comprueba.

1. **¿La canción sin rima debe seguir siendo arquitectura o tiene identidad de forma?** Sigue
   abierta, pero la revisión aporta un dato que la ficha no tenía: **no es una aportación sin
   fuente**. La ficha decía que procedía del criterio del IP y que no se atribuía a ninguna
   fuente; Morley y Bruerton la registran como categoría propia —«Canción sin rima»— y la
   describen igual que el catálogo. *Que la fuente la liste aparte, junto a la canción, es
   argumento para cualquiera de las dos respuestas; lo que ya no cabe es decidirlo sin ella.*
2. **¿Debe exigirse siempre remate o envío?** Hoy la sección `remate` es opcional
   (`repeticiones_min = 0`). Las cinco fuentes que describen la composición lo dan como lo
   normal —Caparrós: «acaba en un fragmento de estancia»; Jauralde: «termina con otra mucho
   más breve»— pero ninguna lo declara imprescindible. *Si se exige, las canciones sin remate
   registradas pasarían a incumplir la norma.*
3. ~~¿Se mantiene el mínimo de 5 versos por estancia, pese al mínimo de 9 de Caparrós?~~
   **Resuelto: sí, y con fuente.** El 5 no lo fijó el proyecto: **Morley y Bruerton dicen
   literalmente «estrofas de 5 a 20 versos»** al describir la canción de Lope. Caparrós 2014 y
   el *Diccionario* dan 9-20 para la estancia italiana; el catálogo sigue a la fuente
   especializada en el corpus dramático, que es lo que corresponde.
4. **Nuevo: el tramo bajo del intervalo solapa con la lira.** Jauralde sitúa la estancia
   «normalmente por encima de los ocho versos (para diferenciarla de las liras)», y el
   *Diccionario* describe la canción alirada como la variante cuya unidad estrófica oscila
   entre cuatro y ocho versos. Es decir, una estancia de 5 a 8 versos es territorio de la lira
   y del sexteto-lira. *No se ha tocado el intervalo, que es el de Morley y Bruerton, pero
   conviene saber que ahí las formas se rozan.*

## Villancico

**Qué tiene hoy el catálogo:** dos arquitecturas —la de estribillo inicial y la de estribillo
posterior—, con secciones de estribillo, ciclo de copla, mudanza, enlace y vuelta, y repetición
del estribillo. La jerarquía padre-hijo de esas secciones se corrigió el 7 de agosto para que
la ficha pública la conserve. Contrasta con el zéjel por la forma de la mudanza.

1. **¿Se segmenta la mudanza de cuatro versos en dos miembros simétricos?** Las fuentes la
   describen como dos mudanzas simétricas; el catálogo conserva **una sola sección de cuatro**.
   *Segmentarla daría dos secciones hermanas donde hoy hay una, y afectaría a la ficha pública
   y al registrador.*
2. **¿La vuelta se separa en arquitecturas o se deja abierta y opcional?** Caparrós fija una
   vuelta canónica de tres o cuatro versos; Navarro Tomás documenta ampliaciones y también la
   supresión del enlace o de la vuelta. *Hoy es abierta y opcional, que es lo que absorbe las
   dos descripciones sin multiplicar arquitecturas.*
3. **¿Entran las mudanzas de seis versos?** Están formalizadas `abba`, `abab` y la asonantada
   `abcb`; Navarro Tomás documenta además mudanzas excepcionales de seis. *Hoy solo caben como
   desviación.*
4. **¿Se restringe la arquitectura de estribillo posterior?** Representa una familia funcional
   abierta, pero la fuente que la sustenta describe algo concreto: una cuarteta octosilábica
   seguida de un estribillo en cuarteta hexasílaba. *Restringirla la haría verificable; dejarla
   abierta permite registrar realizaciones que la fuente no describe.*

## Zéjel

*Revisado el 8 de agosto de 2026, partiendo de cero afirmaciones: era la última de las tres
formas que se quedaron sin respaldo al retirarse las cinco fuentes no autorizadas. Su ficha ya
se retiró.*

**Qué tiene hoy el catálogo:** una arquitectura, `estribillo_y_coplas_monorrimas`, con cabeza
de uno o dos versos y un ciclo repetible de copla —mudanza de tres versos monorrimos más un
verso de vuelta— y posible reaparición del estribillo. El editor responde la medida de cada
sección, entre 6 y 8 sílabas, y si el estribillo reaparece materialmente. La mudanza, su
monorrimia y la vuelta se derivan y no se preguntan.

1. ~~¿Se admiten estribillos de uno y de dos versos o el zéjel estricto exige dístico?~~
   **Resuelto: uno o dos, como está.** Caparrós 2014 y el *Diccionario* dicen «un estribillo de
   uno o dos versos»; Quilis precisa que en el zéjel «de ordinario, son dos», frente al
   villancico, donde suelen ser tres o cuatro. El dístico es lo ordinario, no lo exigido.
2. **¿Una repetición parcial del estribillo es posibilidad admitida o desviación?** Hoy la
   sección `represa` es total o no aparece: el editor responde sí o no. Ninguna de las cinco
   fuentes que tratan el zéjel describe repetición parcial —sí lo hace Jauralde para el
   villancico—. *Si el corpus la trae, hoy no cabe más que como desviación.*
3. **¿Se admite la mudanza de dos versos?** Hoy la mudanza es de tres, y es lo definitorio de
   la forma. Navarro Tomás documenta la variante `aa:bba`, con la mudanza reducida a dos
   versos, **también en el Siglo de Oro**. No se ha añadido: relajar la mudanza toca el núcleo
   de la definición y es decisión del IP.
4. **¿Y el zéjel en arte mayor?** Hoy el esquema métrico ofrece 6 u 8 sílabas. Navarro Tomás
   registra dos zéjeles en arte mayor en el *Cancionero de Baena*, y variantes que modifican
   estribillo y vuelta —`aba:cccba`, `abba:cccaca`—. Son medievales y cultas, no del corpus
   dramático; se dejan fuera a la espera de que aparezcan.

---

# Estrofas de arte menor

## Redondilla

**Qué tiene hoy el catálogo:** cuatro arquitecturas —`octosilabica`, `heptasilabica`,
`hexasilabica` y `doble_enlazada` (`abba|acca`, la antigua «redondilla doble»)—. Las tres
isométricas ofrecen los dos esquemas, `abba` y `abab`, y el editor elige uno **por unidad**.

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Hoy sí: el esquema se elige
   por unidad. *Si no pudiera, serían dos arquitecturas más por medida y la redondilla se
   registraría sin ninguna pregunta.* Se mantiene así porque es **la opción reversible**:
   corregirlo después es reclasificar filas, mientras que haberlo tratado como arquitectura
   habría partido secuencias que no debían partirse.
2. **¿Debe incorporarse «octavilla» como denominación relacionada o resultaría demasiado
   amplia?** Hoy no está. Jauralde documenta la octavilla aguda como estrofa muy usada en el
   XVIII y el Romanticismo, y Navarro Tomás la describe como la más usada de las octosílabas en
   la lírica romántica. *Es forma de otro periodo; la duda es si el catálogo la nombra como
   pariente de la redondilla doble o la deja fuera.*

## Quintilla

**Qué tiene hoy el catálogo:** una sola arquitectura, `octosilabica_consonante`, y ocho
esquemas de rima entre los que el editor elige uno por estrofa. Ese repertorio de ocho lo
reutilizan la copla real y la novena mediante `arquitectura_referenciada_id`, de modo que vive
en un solo sitio.

1. **¿La quintilla es solo octosílaba?** Hoy sí: es su única arquitectura. El *Diccionario*
   dice «octosílabos **o menores**» y Jauralde documenta quintillas hexasilábicas y
   heptasilábicas. **Es exactamente la decisión que se tomó al revés en la redondilla**, que sí
   tiene las tres medidas —6, 7 y 8—, y en la sextilla, que también. *Si se añaden, la quintilla
   pasa de una arquitectura a tres y hay que decidir si el repertorio de ocho esquemas vale
   para las tres.* **⇒ transversal de la modalidad**, con el resto de los repertorios de medida.

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

## Novena

**Qué tiene hoy el catálogo:** dos arquitecturas, `redondilla_quintilla` (4+5) y
`quintilla_redondilla` (5+4), que reutilizan los repertorios de la redondilla y de la
quintilla. Sus fuentes están revisadas y su ficha retirada, pero **la separación acordada no se
ha aplicado**: sigue siendo una sola forma.

1. **Separar la Novena general de la Copla novena.** Está acordado y pendiente: Caparrós y el
   *Diccionario* llaman novena a cualquier estrofa de nueve versos y niegan que comparta
   necesariamente otra norma, mientras Navarro Tomás y Jauralde caracterizan la copla novena
   histórica como redondilla y quintilla. Las dos arquitecturas actuales pasarían a la Copla
   novena. *Falta decidir cómo se registra la Novena general sin que el demarcador clasifique
   por defecto cualquier pasaje de nueve versos.* **⇒ transversal de los esquemas abiertos**,
   porque es el mismo problema que la copla de pie quebrado: una forma general sin norma
   positiva que la acote.
2. **¿Cómo se representan las realizaciones tempranas en que redondilla y quintilla comparten
   una o dos clases de rima**, frente a las posteriores con rimas independientes? *Hoy las dos
   secciones reutilizan repertorios independientes y no hay manera de declarar que comparten
   timbre.* Es el mismo hueco que la copla real: una restricción entre dos elecciones.
   **⇒ transversal de las preguntas.**
3. **¿Las ocho variedades de quintilla valen todas para la Copla novena** o deben restringirse
   según la documentación histórica? *Hoy se ofrecen las ocho, por reutilización.*

## Décima

**Qué tiene hoy el catálogo:** dos arquitecturas, `espinela` (principal) y `aumentada`, y una
relación `sucede_historicamente_a` hacia la copla real. **No declara ninguna denominación**, de
modo que «Décima aumentada» es hoy el nombre de una arquitectura, no un alias.

1. **¿El linaje debe limitarse a copla real, espinela y aumentada?** Es la única relación
   histórica declarada, y su nota ya evita afirmar invención individual o derivación exclusiva.
   *Ampliarlo obligaría a decidir qué otras formas de diez versos entran.*
2. **¿«Décima aumentada» es el nombre adecuado para la arquitectura de doce versos?** Morley y
   Bruerton la describen como `ABBA:ACCDDEED`, «demasiado frecuente como para considerarla
   defectuosa», y aparece en medio de pasajes de décimas normales. *El nombre describe bien lo
   que es, pero llamar «décima» a una estrofa de doce versos puede leerse mal en la ficha
   pública.*
3. **¿La definición debe seguir describiéndola como «dos redondillas abrazadas y dos versos de
   enlace»?** Es lo que dice hoy, con el esquema `abba, ac, cddc`. Morley y Bruerton la
   explican de otro modo: como combinación de **dos quintillas**, la 6.ª y la 5.ª, aunque
   advierten que la 6.ª es muy poco frecuente sola y que lo característico es la pausa tras el
   cuarto verso —que es justo lo que la definición actual usa para separarla de la copla real—.
   *Son dos lecturas de la misma estrofa y la definición ya elige una; la duda es si conviene
   que la otra conste, porque es la de la fuente del corpus dramático.*

## Seguidilla

**Qué tiene hoy el catálogo:** seis arquitecturas —simple `7-5-7-5`, compuesta, de tres versos
`5-7-5`, chamberga, gitana `6-6-(10/11/12)-6` y real `10-6-10-6`—, todas con asonancia en los
pares. Ninguna duda bloquea el registro.

1. **La fluctuación histórica de la simple no tiene representación.** Cuatro de las seis
   fuentes la documentan —Morley y Bruerton advierten que «el ritmo pesa más que el cómputo» y
   que las medidas «pueden variar ligeramente»—, pero el catálogo declara `7-5-7-5` fijo. *Hoy
   una seguidilla de medidas fluctuantes solo cabe como desviación métrica verso a verso.*
   **⇒ transversal de los esquemas abiertos**: es el caso típico de norma que no se puede
   enumerar sin listar cada realización.
2. **La seguidilla arromanzada comparte asonancia entre unidades y eso no se declara.** El
   *Diccionario* y Jauralde documentan series en que una misma asonancia recorre varias
   estrofas. *El catálogo declara la asonancia dentro de la unidad; que se conserve entre
   unidades es un hecho de la serie, no de la estrofa.* Es el mismo mecanismo que el romance ya
   resuelve con su ciclo.
3. **¿Las realizaciones consonantes recurrentes son opciones admitidas o desviaciones?**
   Caparrós 2014 recoge consonancia y rima de los impares como variantes atestiguadas. *Hoy la
   asonancia es definitoria, así que una seguidilla consonante es desviación.*

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
   «Variedad de la endecha real». Las dos están registradas como afirmación de fuente.

   **Comprobado el 8 de agosto al revisar el sexteto: tampoco tiene sitio ahí.** Se buscó
   expresamente, y ninguna de las seis fuentes formaliza esa combinación como sexteto autónomo
   —el sexteto del catálogo exige isosilabismo de arte mayor, y esta mezcla heptasílabos con un
   quebrado—. La revisión no la creó como forma. *Sigue siendo una realización documentada sin
   hueco en el catálogo: o se le da forma propia, o se registra como desviación de la endecha
   real, que es la forma con la que Navarro Tomás la combina.*

---

# Estrofas de arte mayor e italianas

## Lira

**Qué tiene hoy el catálogo:** una arquitectura de cinco versos, `7-11-7-7-11` con rima
`aBabB`. El editor no responde nada: toda la norma se deriva. El sexteto-lira es forma aparte,
con relación `derivada_de` hacia esta.

1. ~~**¿Qué relación tiene con el sexteto-lira?**~~ **Cerrado el 8 de agosto de 2026 al revisar
   el sexteto-lira.** Las seis fuentes lo subordinan a la lira —el *Diccionario* lo define
   literalmente como «Lira de seis versos» y Jauralde como «la variedad más usada de la lira»—,
   y **Morley y Bruerton lo llaman simplemente *Lira***, reservando «quintilla de Fray Luis de
   León» para la de cinco. El catálogo conserva las dos formas separadas, mantiene la relación
   `derivada_de` que ya existía y registra «Lira» como denominación del sexteto-lira, con su
   fuente. La equivalencia legada no las cruza: son términos distintos, cada uno con su forma.
   *Queda una pregunta de presentación, no de modelo, en
   [Sexteto-lira](#sexteto-lira) 4: cuál de los dos nombres debe ser el preferente.*

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

## Octava real

**Qué tiene hoy el catálogo:** una arquitectura endecasilábica con esquema `ABABABCC` y unidad
de ocho versos. **No declara secciones**: la estrofa es una unidad indivisa. El catálogo
mantiene el alcance endecasilábico del proyecto y no incorpora la octavilla real excepcional
que documenta la bibliografía.

1. **¿Una estrofa o dos?** Caparrós 2014 remite en nota a la discusión de Lázaro Carreter
   (1983) sobre si la octava real es una estrofa o la unión de dos, y el *Diccionario* observa
   que suele subdividirse en dos grupos de cuatro versos según el contenido. *El catálogo ha
   tomado partido sin escribirlo: al no declarar secciones afirma que es una unidad de ocho.
   Si se declararan, habría que decidir si el corte es 6 + 2 —el pareado final— o 4 + 4.*

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

## Soneto

**Qué tiene hoy el catálogo:** una arquitectura endecasilábica consonante de catorce versos,
con los cuartetos fijos en `ABBA ABBA` y una pregunta para los tercetos con **cuatro opciones**
—`CDCDCD` cruzada, `CDECDE` paralela, `CDEDCE` conclusiva, `CDCEDE` nuclear—. Sus secciones
reutilizan el cuarteto y el terceto.

1. **¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?** Morley y Bruerton
   dan los cuatro y añaden «y otros», remitiendo al estudio de Dorothy C. Clarke sobre las
   rimas de los tercetos del soneto áureo. *Si es abierto, hace falta una salida para el
   esquema no listado; hoy el editor solo puede elegir entre los cuatro.* **⇒ transversal de la
   modalidad.**
2. **¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?** No están en el
   catálogo. Quilis describe el estrambote como uno o varios tercetos añadidos cuando la idea
   excede los catorce versos, con la condición de que el verso que sigue al decimocuarto sea un
   **heptasílabo que rime con él** —`ABBA ABBA CDE CDE eFF`—, y lo ejemplifica con el «Voto a
   Dios que me espanta esta grandeza» de Cervantes. *Es el más probable de los dos en un corpus
   áureo, y hoy no cabe: un soneto de diecisiete versos no encaja en la arquitectura.*

---

# Los dos tramos sin forma

## Tramos sin forma

*Revisados el 8 de agosto de 2026. Su ficha ya se retiró. No son formas: no tienen arquitectura,
norma, unidades ni desviaciones, y una guarda en migración lo comprueba.*

1. ~~Confirmar si `Verso aislado` debe ser la etiqueta pública definitiva de la antigua entrada
   `verso suelto`.~~ **Resuelto: sí.** El *Diccionario* registra la entrada «verso único», que
   atribuye a Navarro Tomás y define como el verso que no se integra en la estructura de una
   estrofa, y al explicarla usa literalmente la expresión **«un verso aislado»**. El nombre no
   es una invención del catálogo, y «Verso único» queda declarado como denominación.
2. **Nuevo: el quebrado no es versificación irregular, y conviene vigilarlo al anotar.** El
   *Diccionario* lo advierte expresamente —la combinación de versos largos con sus quebrados no
   se considera irregular— y Caparrós 2014 lo confirma al incluir la proporcionalidad en la
   definición de lo regular. Un pasaje 8-8-4 pertenece a la copla o a la sextilla de pie
   quebrado, no a este tramo. La definición ya lo dice. *Merece comprobarse contra las
   anotaciones existentes cuando se haga el informe de migración.*
3. **Jauralde llama a esto de otra manera y no se ha seguido.** Prefiere «verso libre o
   liberado» para el conjunto que no busca ninguna proporción aparente, y reserva «irregular»
   para otro caso. El catálogo conserva «Versificación irregular» por ser el término de las
   otras fuentes y del vocabulario legado. *Queda registrada la divergencia.*
