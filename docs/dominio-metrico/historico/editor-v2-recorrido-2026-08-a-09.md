# El editor V2 en producción · el recorrido del formulario

> **Archivado el 16 de septiembre de 2026.** Es el diario de la puesta en producción del editor V2
> —recorrido entre el 26 de agosto y el 7 de septiembre— y del repaso del formulario forma por
> forma, con los códigos `F1`…`F63`. Se conserva porque explica **por qué el formulario pregunta lo
> que pregunta**: cada entrada dice a cuántas formas alcanzaba el problema y en qué capa se
> arregló.
>
> **Sus cifras y sus «pendiente» son del día en que se escribieron.** Lo que seguía vivo al
> archivarlo pasó a [PENDIENTES](../../PENDIENTES.md). El método de trabajo que salió de aquí
> —arreglar según aparece, recoger lo demás, separar el hueco de modelo— está en
> [cómo se cambia el catálogo](../como-se-cambia-el-catalogo.md).

**Recorrido entre el 26 y el 28 de agosto de 2026, y fusionado a `main` el 7 de septiembre.** El
editor V2 es ya el que ven los editores al abrir cualquier obra: sustituyó al panel lateral, las
tablas de la anotación se renombraron, el catálogo se abrió a todos los roles y el guardado pide
permiso sobre la obra. **Los doce pasos están en `git`**; lo que quedó vivo de aquel plan es esto:

- **Todas las obras se anotan con el catálogo nuevo.** No hay interruptor por obra: el que había
  —`obras_anotacion_nueva`— dejó de gobernar nada y solo sobrevive hasta que se migre lo anotado.
- **El editor V2 escribe únicamente en tablas `anotacion_*`** y no toca
  `secuencias_metricas.estrofa_tipo_id`. Lo que sí cambió el 7 de septiembre es el otro lado: la
  ficha, el buscador y los resúmenes **leen ya solo esas tablas**.
- **Crear una secuencia la guarda ya**, con el rango y `estrofa_tipo_id` en nulo; a partir de ahí cada
  parte guarda por su lado.
- **Lo que sigue abierto** está abajo, en [los campos propios de la secuencia](#los-campos-propios-de-la-secuencia)
  y en [la precomputación y la ficha](./ficha-publica-2026-09.md).

## El replanteo de la migración, 27 de agosto de 2026

La anotación en sombra se retiró. El instrumento es **el informe por obra**
—`npm run migracion:informe`—, que vuelca cada secuencia con todos sus datos, y la migración se hace
**a mano con los editores**, obra por obra. Todas las obras abren ya con el editor nuevo, y al abrir
una secuencia heredada se ve en una línea de dónde viene: *sistema antiguo: tal · propuesta nueva:
tal*, que no rellena nada.


## Lo que sale de recorrer el formulario

*Se abre el 26 de agosto de 2026.* Cada entrada dice a cuántas formas alcanza y en qué capa está el
arreglo, comprobado contra la base antes de proponer nada.

**Cómo se recorre, acordado el 27 de agosto.** El editor pinta desde reglas genéricas, así que casi
nada de lo que se vea es «de esta forma»: lo que parece que a una le sobra suele ser que la regla
está mal planteada, y eso **solo se distingue después de tres o cuatro formas**. Así que:

- **Los fallos se arreglan según aparecen** —un número mal, algo que no guarda—, porque dejarlos
  ensucia el resto del recorrido.
- **Lo demás se recoge y no se toca**, y se decide cuando el mismo asunto aparezca por segunda o
  tercera vez. Arreglarlo con una sola forma delante acierta para esa y desajusta las otras cuarenta.
- Y se separa aparte **lo que es hueco del modelo**, que necesita decisión del IP.

**El registro va en tabla**, no en prosa, para poder cruzarlo: lo que interesa al final no es la queja
de una forma, sino **qué formas se comportan igual de cara al editor**. `Capa` dice dónde está el
arreglo; `alcance` está contado contra la base, no estimado.

| # | forma · arquitectura | síntoma | capa | causa | alcance | estado |
|---|---|---|---|---|---|---|
| F1 | todas | el rango admitía final anterior al inicial, y la pantalla razonaba sobre él | UI | sin `min` ni acotado | 41 formas | **arreglado** |
| F2 | canción · regular y variables | el remate no declara metro ni rima, y no pregunta nada | catálogo | sección opcional sin esquemas ni grupo de elección | 3 secciones (las 3 de la canción, de 11 opcionales del catálogo) | **IP** |
| F3 | canción · regular | «39 de 2 versos» se lee como número al revés | UI · redacción | la fórmula «X de Y» | 41 formas | **arreglado** |
| F7 | canción · variables | cinco renglones «Estructura» seguidos y «1 Primeros pies» | UI | `variableSectionFacts` recorría las hijas en plano | 9 arquitecturas de 5 formas; 14 secciones hijas; plural roto en 8 casos | **arreglado** |
| F8 | canción · sin rima | el pareado final no pinta su `aa` | UI · rejilla | `metricNormGrid` toma solo secciones madre; aquí los esquemas cuelgan de las hijas y la estancia no lleva ninguno | **1 caso en todo el catálogo**: es la única sección hija con posiciones de rima | pendiente |
| F9 | canción · sin rima | el `aa` del pareado no se guarda en la anotación | modelo | no hay grupo de elección de rima: el `aa` es norma del catálogo, no respuesta | 5 arquitecturas activas sin grupo de rima | con **B8** |
| F10 | canción · sin rima | la medida verso a verso y el nº de versos del cuerpo son el mismo control, y los versos se van sumando | catálogo | grupo `medida_estancia`, `alcance: unidad`, 5–20 selecciones; la estancia tiene extensión abierta y no hay pregunta de longitud | 1 arquitectura | recogido |
| F11 | copla castellana · octosilábica | «Medida: base de 8, quebrados 4 y 5» y debajo «Medida fija: 8» | UI | **un solo esquema leído dos veces**: `roleBasedMetreSummary` por roles y `fixedMetreSummary` por posiciones | 10 arquitecturas de 8 formas, todas iguales: base 8, quebrados 4 y 5, 1 posición | **arreglado** |
| F12 | copla castellana | con 2 coplas, responder «en conjunto» deja las dos abiertas y editables a la vez | UI | **era una copia, no un modo**: el panel escribía la misma respuesta en cada unidad y se cerraba | 77 preguntas en 51 arquitecturas, **28 de 41 formas** | **arreglado** |
| F21 | copla manriqueña · de pie quebrado | hay que poder decir si los quebrados son de 4 o de 5, y no se pregunta | **catálogo** | el esquema **ya declaraba la alternativa** —posiciones 3, 6, 9 y 12— pero la arquitectura no tenía grupo de metro | 2 arquitecturas: copla manriqueña (4 posiciones) y sextilla de pie quebrado (2) | **arreglado** |
| F22 | copla manriqueña · de pie quebrado | pregunta el esquema de rima, que estaba marcado **definitorio** | **catálogo** | la marca era la equivocada, no la pregunta | 1 arquitectura | **arreglado** |
| F26 | endecha real · heptasilábica de cinco versos | pregunta las **vocales de la asonancia** en una arquitectura cuya rima es **solo consonante**, y además es obligatoria | **catálogo** | el grupo `vocales_asonancia` está puesto donde no hay asonancia que describir | 1 arquitectura (de 10 que lo preguntan; las otras 9 son correctas) | **migración, sin aprobar** |
| F27 | endecha real · heptasilábica con endecasílabo final | pregunta la asonancia **elijas la rima que elijas**, incluidas «cruzada consonante» y «versos sueltos» | **modelo** | **no hay preguntas condicionales**: `grupos_eleccion_metrica` no tiene ninguna columna que haga depender una pregunta de otra respuesta | 1 arquitectura lo sufre hoy, pero **12 mezclan disposiciones asonantes y no asonantes**, y son las mismas que impiden dar la pregunta a las 18 arquitecturas con rima asonante que hoy no anotan en qué vocales asuena | **IP** |
| F24 | endecasílabo suelto | los textos de ayuda son de fuente, no de uso: «Morley y Bruerton cuentan un pasaje como suelto por debajo de ese umbral» | catálogo · prosa | las descripciones dicen de dónde sale el criterio, no qué mirar en el pasaje | los grupos con `ayuda_editor` y las opciones con `descripcion` | recogido, **2.ª vez** (octava real) |
| F25 | endecasílabo suelto | la norma decía «Densidad de rima: Ninguna; obligatorio» y la pregunta ofrecía **Ninguna y Esporádica** | catálogo | el valor «Ninguna» estaba marcado `definitoria`, y lo obligatorio es **el rasgo**, no el valor | 1 arquitectura, y la garantía se extiende a todos los rasgos | **arreglado** |
| F14 | copla castellana | marcar quebrado pinta lo que ocupa el pie antes de saber cuánto mide | UI | se dibuja la extensión sin esperar a la medida elegida | las 10 de F11 | **ya no existe**: el paso de «marcar» desapareció el 5 de septiembre de 2026 al retirarse la medida de base. Elegir la medida **es** marcar el quiebro, así que no hay nada que se pinte antes de saber cuánto mide |
| F15 | copla castellana | el resumen de «aplicar a todas» —«coincide con las demás unidades»— se entiende fatal | UI | consecuencia de F12: lo que coincidía seguía pintando campo, con esa nota repetida por unidad | los mismos 77 grupos | **arreglado con F12** |
| — | copla castellana | «rango calculado desde sus partes» | — | *es F6, segunda repetición del mismo mensaje* | — | ya en F6 |
| F16 | copla castellana, copla real, novena, oncena, quintilla, redondilla **y septilla** | el quebrado es **rasgo opcional**, no medida esperada: ponerlo bajo «Medida» hace creer que hay que encontrarlo; la definición de la copla real lo dice, «el quiebro, cuando lo hay» | **catálogo** | el rasgo `pie_quebrado` **ya está declarado** en las 10 arquitecturas —`admitida` en 8, `habitual` en las dos oncenas— pero **no tiene ningún valor** en `rasgo_valores`, así que no puede preguntarse ni salir en la norma; lo que se pregunta es `posiciones_pie_quebrado`, de dimensión `metro` | 9 arquitecturas lo preguntan, de 15 que lo declaran | **arreglado** el 4 de septiembre de 2026: la pregunta se llama «Pie quebrado» y su rejilla de versos ya no viene desplegada, ni suelta ni en el control común de varias unidades. Se lee en una línea —«Ningún verso quebrado · todos, 8 síl. · Marcar»— y al responder, «Quebrados: v. 1 (4 síl.)». **No se le dio valor al rasgo**: preguntarlo aparte sería preguntar lo que la respuesta de posiciones ya contiene |
| F17 | todas las de rima | «¿Rima de otra manera?» se muestra siempre. Debe ser **una opción más del desplegable**; y donde el repertorio esté cerrado, **no salir en absoluto** | UI | `tipo_control: opciones_y_esquema` pintaba las opciones **y** el campo libre a la vez | 49 preguntas en 42 arquitecturas de 26 formas | **arreglado**: es una opción más —«Rima de otra manera…»— y el campo aparece detrás. Y **no habrá repertorios cerrados**: se ofrece en todas, en vez de obligar a una desviación, porque el dato escrito es el mismo y saber si se aparta de la norma se deriva del repertorio |
| F68 | novena · las dos arquitecturas, y cualquier forma compuesta con rima por partes | una rima que pasa de una parte a otra **no se puede registrar** | **modelo** | cada sección responde con notación local y el resumen renumera la siguiente con letras libres. Es correcto para miembros independientes y evita falsos enlaces, pero borra uno verdadero: las fuentes documentan novenas tempranas en que redondilla y quintilla comparten una o dos clases | hoy afecta de forma documentada a la novena; el mecanismo debe diseñarse para cualquier forma compuesta | **pendiente y bloqueante si aparece en el corpus**: la UI avisa de la renumeración, pero hace falta modelar equivalencias entre secciones o un esquema global de la unidad; cuestión Novena 2 · **C1** |
| F19 | copla de arte mayor | no hay «añadir otra copla»: las unidades aparecen al alargar el rango | — | **no es fallo**: `countFromRange` se activa cuando la unidad tiene extensión fija, y eso es la mayoría del catálogo | **65 arquitecturas de 30 formas** derivan del rango; solo 3 formas se añaden a mano (canción, villancico, zéjel) | **cerrado** |
| F18 | todas las de rima | esquema predefinido **con desviación** y esquema escrito a mano se ofrecen como si fueran lo mismo | modelo · UI | no hay nada que distinga los dos caminos ni que avise de que lo escrito se parece a un esquema ya existente | los mismos 37 | recogido, va con **F17** |
| F36 | las cuatro liras abiertas | **preguntan su rima de tres maneras distintas**, habiéndose creado el mismo día como una sola serie | **catálogo** | cuarteto-lira y octava-lira: repertorio de 2 y salida abierta, **obligatoria**. Décima-lira: repertorio de 1 y salida abierta, **opcional**. Novena-lira: **sin repertorio**, solo campo escrito —y esa sí está justificada, porque su único esquema es «Distribución variable», de secuencia `abierta`, y la función de opciones no ofrece las abiertas— | 4 arquitecturas de 4 formas | **arreglado**: las cuatro con repertorio —el que haya—, salida abierta y respuesta obligatoria |
| F67 | canción petrarquista · las 2 con `define_norma` | **guardar reventaba** con «column eleccion.opcion_eleccion_id does not exist» | **SQL** | `guardar_anotacion_metrica` construye la firma de las preguntas que declaran la norma con una columna que **no existe** en `anotacion_elecciones`: la añade la vista `anotacion_elecciones_resueltas`. El cuerpo entrecomillado no se revalida, así que compilaba, `db push` pasaba y las pruebas también; solo falla al ejecutarse, y solo donde hay `define_norma` | 3 preguntas en 2 arquitecturas de 1 forma | **arreglado** |
| F66 | villancico · estribillo inicial | la medida se pregunta **parte por parte** —cabeza, mudanza, y enlace y vuelta si se añaden—, todas con el mismo hexasílabo/octosílabo, y en un villancico de cuatro ciclos son muchas veces la misma pregunta | UI | la zona común de medida excluye a propósito las composiciones que crecen por ciclos: «mezclar composición, sección y ciclo confundía más de lo que ahorraba». *La decisión se quedó corta* | villancico ×2 y zéjel | a medias: la revisión del 7 de septiembre quitó la repetición **por ciclo** —la medida se pregunta una vez, «en todas»— y queda que sigan siendo cuatro preguntas distintas con el mismo hexasílabo/octosílabo, que es del catálogo |
| F65 | villancico y zéjel | **se abren en error**: una secuencia nueva de 2 versos monta ya una estructura de 6 y avisa «estructura 6 · rango 2 — sobran 4», antes de tocar nada | UI | la arquitectura materializa su ciclo mínimo al elegirla, y el rango recién creado no le llega | las 3 que crecen por ciclos | **arreglado** el 7 de septiembre de 2026: al elegir arquitectura el rango se estira hasta lo que la estructura ocupa. Solo al elegir y solo hacia arriba: el rango de una secuencia recién abierta no dice nada todavía, pero uno ya escrito no se toca |
| F64 | villancico · estribillo inicial | la repetición del estribillo se declaraba **opcional** y la pregunta que la materializa es **obligatoria y sin respuesta negativa** —«se repite entero» o «solo en parte»—: un ciclo sin repetición no se podía ni declarar ni guardar | **catálogo** | **las dos arquitecturas de la forma se contradecían**: en «Estribillo tras la primera copla» la sección homóloga ya era `1-1`. El estribillo no puede faltar —es lo que define un villancico— y lo que varía es cuánto vuelve | 1 arquitectura; el zéjel declara lo mismo y queda aparte | **arreglado** |
| F63 | versificación irregular y verso aislado | **no se les puede preguntar nada**, y lo único que se registra de ellas es una observación en texto libre | **modelo** | `grupos_eleccion_metrica.arquitectura_id` es **NOT NULL** y las dos son `sin_forma`: no tienen arquitectura, así que no hay dónde colgar una pregunta. No es que falten, es que el modelo no las sostiene | 2 tramos sin forma, y **9 secuencias ya anotadas con 197 versos** que hoy no tienen ningún destino al migrar | **hecho** el 3 de septiembre de 2026, según [su plan](../plan-f63-los-tramos-registran-lo-que-se-ve.md): tres arquitecturas por arte y una para el verso aislado, ninguna normativa, con dos preguntas escritas de una vez. Ocho de las nueve secuencias legadas ya tienen destino. Queda una consulta: por qué la de *El mágico prodigioso* vv. 2191–2201 se anotó con el término madre y no con uno de los tres específicos |
| F62 | terceto encadenado · las dos | **no se puede decir si lleva remate final**, que el catálogo declara opcional —`repeticiones 0-1`, 1 verso— | UI · modelo | `metricUnitPlan` devuelve `null` cuando el nivel es `serie`, así que `hasStructuredEditor` es falso y **el editor de estructura no se pinta**, aunque la arquitectura declare secciones. La regla de longitud sí lo sabe —`desplazamientos [0, 1]`, «bloques completos de 3 versos, con un cierre opcional de 1 verso»— de modo que el rango valida con o sin él y nada registra cuál | **2 arquitecturas** con sección opcional sin respuesta; y **4 series** declaran secciones que no se ven: las dos del terceto encadenado, la septilla y la sextilla enlazadas y la silva consonante regular | **arreglado sin preguntarlo**: `3n ≡ 0` y `3n+1 ≡ 1` en módulo 3 son excluyentes, así que el rango ya decide si el remate está y solo faltaba ponerle nombre. Lo de ver la estructura de una serie **sigue abierto y hoy sin sitio**: la rejilla salió del recuadro al rehacer la norma (**F46**), así que ya no hay dónde mirarla en el editor |
| F59 | silva · endecasilábica | **la única pregunta de pareados del catálogo obliga a elegir entre dos grados que su prosa no separa**: «Habituales — los pareados son frecuentes, aunque no obligatorios» y «Predominantes — los pareados organizan predominantemente la serie» | catálogo · prosa | *no es una duda abierta*: el 28 de agosto de 2026 se decidió **no cuantificar los grados**, y la cuestión se retiró del documento del IP. Lo que queda es que la descripción es el único criterio que el editor tiene, y con estas dos no basta | 1 arquitectura, y la pregunta es obligatoria | pendiente, va con **F24** |
| F57 | sextina · estrofa | **se puede elegir suelta**, y su definición dice que no se usa así: «fuera de ella la estrofa no se usa sola» | catálogo · modelo | nada impide elegir en el selector una forma que solo existe dentro de otra. Es **la única** del catálogo cuya definición lo dice, pero el modelo no sabe expresarlo | 1 forma hoy | **pendiente de decidir** |
| F55 | sextilla · de pie quebrado | ofrecía **una sola disposición de rima**, `abcabc`, y las fuentes nombran tres | **catálogo** | el *Diccionario* la describe «con disposiciones `aabaab`, `aabccb` o `abcabc`», y Navarro Tomás llama a `abc:abc` «la más usual» y advierte que «el orden de las rimas varía de una composición a otra». No entra `ababab`, que las fuentes dan para la sextilla de octosílabos plenos | 1 arquitectura | **arreglado**: `abcabc` sigue habitual y entran las otras dos como admitidas |
| F53 | sexteto-lira · heterométrica consonante | la rejilla dibuja **las tres disposiciones de rima y un solo esquema métrico**, teniendo seis, cuando las variedades son combinaciones de ambos | UI · rejilla | `construirRejilla` toma el métrico con `find(esquema => !esquema.seccion)`: **el primero que encuentre**, en silencio. Es la única arquitectura del catálogo con más de un esquema métrico de unidad, así que hasta ahora no se notaba | 1 arquitectura | recogido; **la revisión del formulario del 4 de septiembre de 2026 no lo alcanzó** |
| F52 | sexteto-lira · heterométrica consonante | elegir una variedad **no cambiaba nada** en la anotación de la unidad | UI | el resumen solo leía preguntas de `metro` y de `rima`, y esta es de `combinacion`. Una variedad **reúne un esquema de rima y uno métrico**, así que responderla dice las dos cosas | 1 arquitectura hoy; toda pregunta de variedad | **arreglado** |
| F51 | septeto-lira · heterométrica consonante | declara `ababbcc` como **habitual** y **no lo preguntaba**: se daba por hecho que el pasaje rima así, sin confirmarlo ni poder decir otra cosa | **catálogo** | de las arquitecturas activas sin pregunta de rima era la única en ese caso: el endecasílabo suelto y las dos silvas declaran esquemas `abierta` sin posiciones —no hay disposición que ofrecer— y el sexteto-lira elige su rima por la variedad | 1 arquitectura | **arreglado**: repertorio y salida abierta, como la décima-lira |
| F50 | septeto · endecasilábica, y los 8 grupos de esquema abierto | **lo escrito se guarda tal cual**, y la convención de caja solo se aplica al pintar el resumen: escribir `abab` en una forma de endecasílabos guarda `abab` y enseña `ABAB` | modelo · UI | `compactRhymeNotation` solo quita espacios, y su comentario lo dice a propósito —«la caja de las letras también codifica la medida»—. Donde hay repertorio no importa, porque `canonizar` compara **sin distinguir caja** y lo guarda como la disposición catalogada; donde no lo hay, dos anotaciones de lo mismo quedan escritas distinto | los 8 grupos sin repertorio, en 5 formas | **arreglado**: se normaliza al guardar con la medida de cada verso, la misma que usa el resumen |
| F49 | septeto · endecasilábica y compuesta, **y soneto** | el marcador del campo abierto dice `aBaBcC` en una forma **de endecasílabos**, donde la convención pide todo mayúsculas; y en la redondilla, de cuatro versos, dice `abcabc`, que son seis | UI | es un literal fijo del componente, igual para todas las formas; la medida de la unidad ya se conoce y podría escribirlo bien | los 8 grupos de esquema abierto y los 39 mixtos | **arreglado** el 7 de septiembre de 2026: el marcador se arma con los versos que abarca el esquema y la caja que le toca a cada uno. Y esa cuenta es la que comprueba lo escrito, así que en el soneto «ABBA ABBA» dejó de leerse como si le faltaran seis letras |
| F48 | seguidilla · compuesta, chamberga y gitana | la anotación verso a verso **se saltaba los versos sueltos**: la compuesta salía «a a b b» en vez de «- a - a b - b» | UI | el resumen solo escribía las posiciones con clase de rima, y las sueltas —que el catálogo marca con `suelto` y escribe con raya en `-a-ab-b`— se caían | toda forma con versos sueltos en su esquema | **arreglado** |
| F47 | seguidilla · gitana, y las 6 de F44 | dos rótulos que decían lo que no es: «Medida de cada verso» cuando **solo se pregunta uno**, y «Medida de cada verso» donde antes decía «Medida de los quebrados» | catálogo · SQL | la vista decidía el rótulo con `bool_and(rol = 'quebrado')`, que dejó de cumplirse al declarar las posiciones —ahora ofrecen también el octosílabo, que es la respuesta de que ahí no hay quiebro—; y no distinguía una pregunta de una sola posición | 12 preguntas de quiebro y 1 de verso único | **arreglado** |
| F45 | redondilla, y las 15 que declaran el rasgo | el quiebro se afirmaba **bajo «Medida»** —«base de 8; los pies quebrados pueden medir 4 y 5»—, y ahí se lee como parte de cómo mide la estrofa. En una redondilla es raro: teóricamente es base de 8 con admitidos de menos, y en la práctica es de 8 y ya | UI | la medida decía cuánto miden y callaba el grado; y el rasgo no subía a la norma, porque uno `admitida` sin límite de posiciones se considera dato de la realización. Ahora la medida dice la base, y el quiebro va a su renglón con su grado y sus medidas | las 15 arquitecturas que declaran `pie_quebrado`, en sus tres grados | **arreglado** |
| F44 | quintilla, septilla, las dos novenas y las dos oncenas | la nota **nombra el verso del quiebro** y el editor lo pregunta en todos | **catálogo** | hay dos mecanismos y estas están en el que no restringe: con `medida_uniforme = false` la derivación enumera `generate_series(1, unidad_versos_max)` y ofrece el quebrado en cada verso; con `medida_uniforme = null` y posiciones declaradas —manriqueña, sextilla de pie quebrado y las tres enlazadas— solo se ofrece donde se declara | **6 arquitecturas declaran ahora dónde cae el quiebro** —quintilla, septilla, novena 4+5, las dos oncenas y la copla castellana— y **1 dejó de admitirlo**, la novena 5+4, cuyo quiebro no lo documenta ninguna fuente. Quedan 3 preguntando en todos los versos, y su fuente lo justifica: copla real, redondilla y copla de arte menor | **arreglado** |
| F43 | quintilla · octosilábica consonante | las ocho tipologías salían en el desplegable **desordenadas**: 4, 5, 3, 1, 7, 6, 2, 8 | catálogo · SQL | `opciones_eleccion_derivadas()` las ordenaba por notación —`aabab`, `aabba`, `abaab`…— y el número de la tipología, que es como se nombran y como las cita la bibliografía, no contaba | toda forma cuyas disposiciones llevan nombre; las que no lo llevan no se mueven | **arreglado** |
| F42 | pareado · alirado | **más de dos versos lo convierte en serie**, y una tirada de pareados alirados es en realidad una silva. Habría que avisarlo o impedirlo | **modelo** | la regla de longitud dice `unidades completas de 2 versos` y nada limita **cuántas** unidades caben en una secuencia; el modelo no sabe decir «esta arquitectura no se repite» | 1 arquitectura hoy; la pregunta —qué formas no admiten repetirse— alcanza a las 41 | **IP** |
| F41 | pareado · de cualquier medida | la elección de medida **se salía de pantalla** | UI | ofrece **nueve alternativas por verso**, 18 opciones en 2 posiciones, y la fila de botones no envolvía. Las formas vistas hasta aquí ofrecían dos | toda pregunta de medida posicional con repertorio ancho | **arreglado** |
| F40 | las 12 que admiten más de un régimen de rima | **el régimen no se podía preguntar nunca**, y la norma tampoco lo decía: el alirado solo enseñaba «Rima fija: aa», y el de cualquier medida, dos disposiciones llamadas «aa» sin distinguir la asonante | UI | dos huecos con la misma raíz: `rhymeRegimes` leía `domain.vocabularies`, **que no existe** —ni está entre los recursos del dominio ni lo rellena nadie—, y `metricNormGrid` no rellenaba el campo `tipoRima` que `MetricPositionGrid` **ya sabe pintar** y que la ficha pública sí rellena | 12 arquitecturas para el selector; el rótulo, todas las que declaran régimen | **arreglado** |
| F39 | oncena · las dos, y septeto compuesto | **la rima heredada no se puede guardar**: el servidor la rechaza | **modelo** | la herencia por reutilización vive **solo en el cliente**. El grupo que inventa conserva el `grupo_eleccion_id` del prestamista, y `validar_anotacion_eleccion` lo busca con `and arquitectura_id = <la de la secuencia>`: no lo encuentra y da «El grupo de elección no pertenece a la arquitectura seleccionada». `guardar_anotacion_metrica` no lo remapea —no menciona la reutilización en ninguna línea— | **3 arquitecturas de 2 formas**, las mismas de F38 | **arreglado con C20**: la respuesta dejó de apuntar a la pregunta, y las heredadas pasaron a ser filas del catálogo |
| F38 | oncena · las dos, **y septeto compuesto** | **solo preguntaba la rima de la primera parte**: la quintilla si la arquitectura es quintilla + sextilla, y la sextilla si es al revés | UI | las preguntas que una parte hereda de la arquitectura que reutiliza se traían **con el nombre pelado del prestamista**, «Esquema de rima», así que las dos partes se llamaban igual y todo lo que agrupa por nombre las tomaba por una sola. Las copiadas a mano de la copla real y la novena no lo sufrían porque alguien las llamó «Primera quintilla · Esquema de rima» | **3 arquitecturas de 2 formas** —las 2 oncenas y el septeto compuesto—, que son las que heredan en más de una parte, de 9 secciones que heredan en total | **arreglado** |
| F37 | las 21 formas de rima con repertorio y salida | escribir el esquema a mano **no marcaba la pregunta como respondida**: la rejilla la seguía enseñando pendiente | UI | `preguntaRespondida` miraba el texto solo en el control abierto puro | los 39 grupos de `opciones_y_esquema`, en 36 arquitecturas de 21 formas | **arreglado** |
| F35 | octava real · endecasilábica consonante | con más de una unidad, en conjunto **solo dejaba elegir del repertorio**, mientras la ayuda decía «si no, escribe el que veas» | UI | F31 abrió el camino escrito solo al esquema abierto puro; el de repertorio con salida seguía pintándose únicamente con sus opciones | **39 grupos en 36 arquitecturas de 21 formas**, que son todas las de `opciones_y_esquema` | **arreglado** |
| F34 | octava real · endecasilábica consonante | preguntaba el **dístico final** siempre, y no aportaba por ninguno de los dos caminos: el esquema `ABABABCC` ya lo lleva, y si se escribe el esquema a mano la notación lo enseña | **catálogo** | se retira **la pregunta, no la declaración**: `arquitectura_rasgos` conserva «Presente · habitual», que es de donde salen la norma y la ficha pública. El endecasílabo suelto conserva la suya, porque allí no hay notación de la que deducirlo | 1 arquitectura | **arreglado** |
| F33 | octava aguda, seguidilla, terceto, pareado, villancico | tienen disposición asonante y **no preguntan en qué vocales asuena** | catálogo | **9 de 27 arquitecturas con esquema asonante** lo preguntan; las 18 restantes, no. El final agudo, que sí es obligatorio, va marcado y no se pregunta: eso está bien | 18 arquitecturas de 5 formas | **arreglado** el 4 de septiembre de 2026: preguntan las 28 arquitecturas con esquema asonante. Obligatoria en las 17 que siempre asuenan y **opcional en las 11 que mezclan regímenes**, porque el mismo pasaje puede rimar en consonante y el esquema elegido ya dice cuál es. Entró la `u` aguda, que faltaba, y **donde el final agudo es definitorio solo se ofrecen las agudas** —las seis octavas agudas— |
| F31 | novena-lira · heterométrica consonante | con más de una unidad, el esquema de rima se preguntaba **por novena** y no en conjunto | UI | `preguntasCompartidas` excluía `tipo_control = 'esquema_rima'` sin decir por qué: el control común hablaba en slugs y el esquema abierto es texto | **8 arquitecturas de 5 formas**: novena-lira, septeto, sexteto dodecasilábico, las 4 sextillas y las estancias variables de la canción | **arreglado** |
| F30 | novena-lira · heterométrica consonante | con más de una unidad, la medida se preguntaba con **un desplegable por verso** en vez de con las barras | UI | `MetricFamilyControl` y `MetricChoiceField` habían divergido justo en lo que el primero existe para evitar: la misma pregunta, dos dibujos | las 34 preguntas de metro que admiten respuesta común, en 26 arquitecturas de 21 formas | **arreglado** |
| F29 | novena, seguidilla gitana, septilla y las 6 de F44 | la medida se pedía con un **desplegable con una unidad** y con las barras con dos, **la misma pregunta con dos controles** | UI | `MetricChoiceField` miraba `maximum === 1` **antes** que las ramas posicionales, y el control común no: con una unidad la pregunta no entra en el atajo y caía en el desplegable. Es la divergencia que estos dos componentes existen para evitar | 7 arquitecturas | **arreglado**: las ramas posicionales van primero, y el campo recibe además **lo que la norma fija en cada verso**, que antes solo sabía deducir del rol `dominante` —la gitana no lo tiene y sus tres versos fijos decían «sin medidas disponibles»— |
| F28 | lira · heptasilábica y endecasilábica | la cabecera decía «2 unidades de 5 versos» y el cuerpo, «2 ciclos de 5 versos» | UI · redacción | la caja del pasaje escribía «ciclos» a secas, cuando `arquitecturas_reglas_longitud.origen` distingue cinco casos y su propia `explicacion` los nombra distinto —«unidades», «ciclos de rima», «ciclos métricos», «estructuras», «bloques»— | **81 reglas de 37 formas**: 65 cuentan unidades, 10 ciclos de rima, 3 bloques, 2 estructuras y 1 ciclo métrico. La palabra estaba mal en las **71 que no son ciclos de rima** | **arreglado** |

**Lo arreglado no se cuenta aquí.** La tabla dice qué era y a cuánto alcanzaba; el porqué de cada
arreglo está en su commit, que es donde no se queda viejo. Lo que sigue es **solo lo que aún no se ha
tocado** y necesita algo más que una fila.

**F33 · La asonancia se anota siempre que la haya.** Decidido el 29 de agosto de 2026, y **no se
migra suelto**: se hace de una vez cuando se resuelva el bloque de la rima, porque la mitad de los
casos depende de que una pregunta pueda condicionarse a otra (**C1 · F27**).

*Lo que ya está comprobado y no hay que volver a averiguar:*

- **No hay que duplicar nada.** `vocales_asonancia` es **un solo rasgo** con sus 19 valores, y las 10
  arquitecturas que hoy preguntan apuntan todas al mismo `rasgo_id`. Añadirlo en otra son dos filas:
  una en `grupos_eleccion_metrica` y otra en `arquitectura_rasgos`.
- **El modelo ya sabe ofrecer un subconjunto.** La rama de rasgo de `opciones_eleccion_derivadas()`
  filtra `and (ar.valor_id is null or ar.valor_id = rv.valor_id)`: con `valor_id` en nulo ofrece los
  19 —así lo declara el romance, modalidad `admitida`—, y con una fila por valor admitido, solo esos.
- **Las nuevas filas van `admitida`**, nunca `definitoria`: el disparador
  `definitoria_no_se_ofrece()` rechaza una definitoria que se ofrezca como opción.

*Y lo que hay que hacer, en dos bloques:*

| bloque | arquitecturas | qué |
|---|---|---|
| **se puede sin nada más** | **7**: las siete seguidillas —simple, compuesta, real, gitana, chamberga, de tres versos y simple arromanzada— | todos sus esquemas son asonantes, como el romance: pregunta obligatoria y los 19 valores |
| **espera a C1** | **11**: octava aguda (6), villancico (2), terceto (2), pareado (1) | admiten asonante **y** consonante, así que la pregunta saldría también a quien eligió la consonante. Es el fallo de la endecha real |

*Dos precisiones del contenido:*

- **En la octava aguda solo van cuatro valores.** Es la única forma del catálogo que fija
  `final_acentual = Agudo`, y **definitorio** en sus seis arquitecturas. Una asonancia aguda es de
  **una sola vocal**, así que de los 19 solo aplican `a`, `e`, `i` y `o`; los otros quince son pares
  y describen asonancias llanas.
- **Falta el valor `u`.** *Virtud*, *salud*, *alud* asuenan en **ú** y no hay dónde decirlo. En el
  romance casi no se nota porque su asonancia suele ser llana; en la octava aguda, donde toda
  asonancia es aguda, falta una de las cinco vocales posibles. **Decidido añadirlo**, en la misma
  migración.

**F39 · La herencia por reutilización no llega al servidor.** Salió el 29 de agosto de 2026 al
preguntarse por qué la copla real y la novena **copian a mano** una pregunta que podrían heredar.

*La respuesta a eso es histórica y está bien:* el 31 de julio, el defecto D8 retiró los dieciséis
esquemas duplicados y ancló las preguntas a su sección, porque **entonces ese anclaje era el
mecanismo** —«es lo que autoriza a la opción a señalar un esquema de otra arquitectura»—. La
herencia automática, que se inventa el grupo sin que exista fila, llegó el **25 de agosto**, casi un
mes después, cuando la oncena y el septeto compuesto la necesitaron por no tener ninguna.

*Y al comprobar si las seis copias se podían borrar apareció lo otro:* **nadie enseñó al servidor
qué es heredar.** Ejecutada contra la base la primera comprobación del disparador —buscar el grupo
en la arquitectura de la secuencia— **las seis preguntas heredadas dan cero**. Así que la oncena y
el septeto compuesto no pueden guardar su rima, y **borrar las seis copias las dejaría igual**.

*Lo comprobado, para no repetirlo:*

- Las copias son idénticas a lo que se heredaría —repertorio, control y selecciones—, y **el
  repertorio no puede separarse**: la rama de rima de `opciones_eleccion_derivadas()` resuelve los
  esquemas con `coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)`, así que un grupo
  anclado a una parte que reutiliza la quintilla ya deriva los esquemas de la quintilla. Lo que sí
  puede separarse es lo que vive en la fila: control, selecciones y ayuda.
- **La ficha pública no lee esas filas.** `formas-publicas.ts` tiene su propia `rimaHeredada`, que
  solo mira esquemas; como la copla real y la novena no declaran ninguno, **la ficha ya las trata
  como heredadas**. Las dos superficies llevan tiempo diciendo cosas distintas, y la regla que
  `reutilizacion.ts` dice guardar «una sola vez» está en realidad escrita dos veces, con condiciones
  que no coinciden: la del editor mira además las preguntas, la de la ficha no.
- Cero respuestas guardadas y cero equivalencias legadas en las seis.

*Los dos caminos:* enseñar al servidor a resolver la herencia —`validar_anotacion_eleccion` acepta
el grupo de la arquitectura que la parte reutiliza, y `seccion_id` se resuelve a la parte que lo
toma prestado—, o **darle filas propias a la oncena y al septeto**, seis en total, como las tiene la
copla real. Lo segundo funciona hoy y no toca ninguna función; lo primero es el mecanismo único.

**F46 · La norma de la arquitectura. Hecha el 4 de septiembre de 2026.** Se decidió con una
maqueta sobre datos medidos, en `/dashboard/metrica/maqueta`, porque rehacer el formulario sobre
una forma concreta acierta para esa y desajusta las otras noventa.

El recuadro dice ahora tres cosas y en este orden: **qué está fijado** —en una línea gris, porque
no se consulta renglón a renglón—, **qué declara el pasaje que se anota**, y **qué admite la forma**
sin exigirlo. Y cierra con lo que faltaba: qué hacer con lo que no cabe en ninguna de las tres.

Dos cosas se fueron de ahí, y las dos por la misma razón —el recuadro competía con el formulario
en vez de ayudarlo—:

- **La rejilla verso a verso.** Es buena en la ficha pública y en el demarcador, donde se compara
  una forma con otra; aquí duplicaba la estructura que el editor tiene delante en el texto.
- **La enumeración de lo que el desplegable ya ofrece.** Si la rima se elige, lo que hace falta
  saber es que se elige y con qué criterio, no cuáles son las ocho disposiciones: están tres
  centímetros más abajo. En la quintilla eso quitó un párrafo entero del catálogo, que sigue
  donde sirve, en la ficha enlazada al pie.

Con el recuadro se cierran **F4, F5, F6, F13, F20, F32 y F60**, que pedían todos lo mismo por
sitios distintos.

**La otra mitad, el formulario. Hecha el 4 de septiembre de 2026**, en cuatro pasos —`4ac8479`,
`b0ced58`, `981c9b1`, `e882491`—, sobre la misma maqueta y por la misma razón. Lo pedido era una
tercera zona:

> «Yo lo que quiero es que haya una zona de **qué se va a registrar**. Eso es para mí el resumen:
> tenemos la norma, luego las elecciones, y al final qué se va a registrar sumando la norma más las
> elecciones.»

**Y esa zona no se hizo, por lo mismo que la abría.** Con la norma diciendo lo fijo y las respuestas
lo elegido —con sus excepciones y sus rangos—, «qué se va a registrar» ya estaba dicho dos veces, y
una tercera sería repetir en tres sitios la misma cosa, que es lo que se venía a quitar. Lo que
faltaba no era una zona sino **contenido donde ya había hueco**: el listado enseña ahora la notación
—`8a 8b 8a 4b | 8c 8d 8c 8d`— también cuando no tiene preguntas que mostrar. Es la única lectura en
versos que da el editor, frente al vocabulario del catálogo de las otras dos zonas, y es donde se
caza una respuesta equivocada: si se eligió `abbab` y el pasaje lee `abab`, ahí se ve.

| paso | qué |
|---|---|
| 1 | las excepciones, nombradas y situadas: qué responde, cuántas unidades y dónde |
| 2 | el modo «en conjunto / una a una» desaparece; la lista es un detalle que se abre |
| 3 | los rasgos que la forma admite no ocupan sitio hasta que los hay, cada uno con su botón |
| 4 | el listado enseña la notación, o no se pinta |

El tercero cierra **F23** —los seleccionables presentados como cinco preguntas seguidas, cada una
con su caja, sus radios y su descripción larga: era exactamente esta pantalla— y el cuarto, **F58**.

**La manera de responder venía decidida en la maqueta**: una respuesta para todas las
unidades y las excepciones agrupadas debajo —«en todas: ababa · salvo 7 de 52»—, con la lista
unidad por unidad a un clic. Se eligió sobre lo medido: de las 134 secuencias con unidad, las de
más de diez son el 86 % de los versos, y **nunca son todas distintas**: el máximo del corpus son
cuatro esquemas en 43 unidades.

**Dos cosas salieron distintas de lo previsto:**

- **La sextina no es que le falte la notación: no la tiene.** Su rima es la repetición de seis
  palabras, no un esquema de letras, así que no hay `8a 8b…` que escribir y el bloque solo repetía
  la cabecera. Ahora no se pinta. Eso es F58, que se había recogido como un listado que no dice
  nada y era en realidad un listado que no tiene nada que decir.
- **Las unidades idénticas no se agrupan**, aunque estaba en el plan del cuarto paso: choca con lo
  decidido en la maqueta —una fila por unidad, con su número, sus versos y su respuesta—, así que
  tres quintillas iguales se leen en tres renglones iguales.

**Revisado en pantalla el 5 y el 7 de septiembre de 2026**, y con esa revisión se cierran los tres
que quedaban de esta zona:

- **F56** —la disposición en columnas de una unidad con varias preguntas— se fue con el bloque
  apilado: `MetricGridRow` dejó de pintar el rótulo a la izquierda y la respuesta a la derecha, así
  que ya no hay tabla que leer mal.
- **F54** —el plegado unidad por unidad— **ya no existe**: ese plegado era del modo «una a una», que
  desapareció con el segundo paso de A′.
- **F61** —dónde leer la descripción de la arquitectura— **se retira**: decidido el 7 de septiembre
  que no hace falta. El desplegable la lleva en el `title` de cada opción y con eso basta.

**Y lo que se ha ido arreglando por el camino ya dice por dónde va**: la medida se cuenta una sola
vez (**F11**), el régimen de rima se dice una vez arriba o en cada disposición (**F40**), y el pie
quebrado se afirma donde es un rasgo y no donde se mide (**F45**).

**F63 · Qué habría que preguntar en los dos tramos sin forma.** Revisado el 29 de agosto de 2026 a
petición de David. Hoy no se pregunta nada, y no por descuido: **toda pregunta cuelga de una
arquitectura** —`arquitectura_id` es `NOT NULL`— y estos dos no tienen ninguna, por definición. Lo
único que queda de un pasaje irregular es una observación en texto libre, que no se puede contar.

**Y hay una pérdida medida, no hipotética.** El vocabulario legado distinguía cuatro clases de
irregular, y el corpus las usa:

| término legado | secuencias | versos | ¿tiene equivalencia? |
|---|---|---|---|
| `irregular_mixto` | 6 | 147 | **no** |
| `irregular_arte_menor` | 1 | 37 | **no** |
| `irregular_arte_mayor` | 1 | 2 | **no** |
| `irregular` | 1 | 11 | **no** |
| `verso suelto` | 0 | 0 | **no** |

De las 26 filas de `equivalencias_respuestas_legadas`, **ninguna es de estas**: todas son del
endecasílabo suelto y una de la silva. Así que migrar esas nueve secuencias hoy **aplanaría las
cuatro clases en una** y la distinción se perdería sin que nadie lo notara.

**Lo que habría que preguntar, y de dónde sale:**

- **Versificación irregular — de qué arte son sus versos**: menor, mayor o mixto. No es una taxonomía
  inventada: es la que el corpus ya tiene anotada, y es el criterio que usa la propia definición
  —«ni el número de sílabas obedece a igualdad o proporción»—. Una sola respuesta, y hace contable
  una categoría cuyo valor es precisamente **poder volver a ella**: es la lista de lo que no se supo
  clasificar.
- **Verso aislado — cuánto mide**, que su definición da por observable —«con medida reconocible»— y
  sin lo cual el dato no sirve para nada; y **de qué clase es**, que la definición enumera: el mote
  con su glosa, y los proverbios, refranes y sentencias que el diálogo intercala.

*Lo que no propongo:* una pregunta de «por qué no se reconoce la forma». Esa taxonomía no está en
ninguna fuente ni en el vocabulario legado, y habría que inventarla.

**Lo que costaría.** Es la decisión de fondo: o `arquitectura_id` deja de ser obligatorio en las
preguntas, o los dos tramos sin forma reciben una arquitectura, que contradice su nombre. *La segunda
es más pequeña y menos honesta; la primera toca la tabla de la que cuelga todo.* Va con **C20**, que
replantea a qué apunta una respuesta.

**F2 · El remate, y las secciones opcionales que no declaran nada.** Contado contra la base, de las
**once secciones opcionales** del catálogo:

| forma | secciones | declaran | preguntan |
|---|---|---|---|
| Terceto encadenado | los dos remates finales | metro; la rima, en la nota | no hace falta ⇒ **F62** |
| Villancico y zéjel | enlace, vuelta y repetición (6) | metro sí, rima no | 4 de 6 |
| **Canción petrarquista** | **remate ×2 y eslabón** | **ninguno** | **no** |

El remate de la regular admite **de 1 a 13 versos** y no dice nada de cómo son, así que anotarlo no
registra más que su extensión. *Decisión del IP: si debe declarar lo que las fuentes documenten, o
preguntar como las demás.*

**Por qué el terceto encadenado no necesita preguntarlo.** Sus dos secciones opcionales son remates
de un verso, y de ellas el catálogo declara el metro —lo cubre el ciclo de una posición de la
arquitectura— pero no la rima, que solo vive en su nota. Aun así no hace falta preguntar si el
remate está: `3n ≡ 0` y `3n+1 ≡ 1` en módulo 3 son **excluyentes**, de modo que ninguna longitud
admite las dos lecturas y **el rango decide solo** —cuarenta versos llevan remate, treinta y nueve
no—. Lo único que faltaba era decirlo, y la caja del pasaje lo dice: «y el remate». ⇒ **F62**

**F8 y F9 · Lo comprobado, para no repetirlo.** El catálogo **sí** declara el pareado de la canción
sin rima —esquema «Pareado consonante final», posiciones 1 y 2, ambas clase `a`—, y «Cuerpo sin rima»
es un esquema con cero posiciones, que es como se dice «no rima». Ninguna de las dos se pinta, y
ninguna se guarda: no hay grupo de rima, así que el `aa` es norma y no respuesta. Toda esa
arquitectura va **sin esquema métrico**, y por eso la medida se pregunta verso a verso.

**F16 · El quebrado es un rasgo, y el rasgo está vacío.** Las diez arquitecturas con quebrados **ya
declaran** `pie_quebrado` —`admitida` en ocho, `habitual` en las dos oncenas—, pero el rasgo **no
tiene ningún valor** en `rasgo_valores`, así que no puede preguntarse ni salir en la norma; lo único
visible es `posiciones_pie_quebrado`, de dimensión `metro`, y de ahí que todo acabe bajo «Medida».
Preguntar primero «¿hay quebrados?» es lo que el rasgo permitiría en cuanto tenga sus dos valores.
**No se le dieron.** El 4 de septiembre de 2026 se decidió al revés: preguntar el rasgo aparte sería
preguntar lo que la respuesta de posiciones ya contiene. Lo que se arregló es dónde se lee —«Pie
quebrado», en una línea y con su rejilla de versos plegada—, no de qué tabla sale.

**F17 y F18 · La misma pantalla.** Escribir un esquema a mano y elegir uno predefinido marcando una
desviación son cosas distintas, y hoy se ofrecen juntas y sin jerarquía. El IP añade que la frontera
la decide el editor, que no pasa nada porque luego se revisen, y que **el comprobador en vivo podría
avisar de que lo escrito se parece mucho a un esquema existente**. Va con **B8** cerrado y con **F9**.

**F26 y F27 · Los dos huecos de la endecha real.** El primero es de dato: la **heptasilábica de cinco
versos** rima solo en consonante y pregunta obligatoriamente las vocales de la asonancia; de las diez
arquitecturas que hacen esa pregunta, las otras nueve son correctas. El segundo es de modelo: la
**heptasilábica con endecasílabo final** admite **tres regímenes** y pregunta la asonancia se elija lo
que se elija. Para callarla haría falta que **una pregunta dependiera de otra respuesta**, y eso no
está en el modelo —`grupos_eleccion_metrica` no declara ninguna dependencia—. Hoy muerde ahí, pero
**12 arquitecturas admiten más de un régimen**. *Es la cara técnica de una pregunta ya abierta en
cuestiones para el IP: «qué elecciones dependen de otras» ⇒ **C1**.*


## Los campos propios de la secuencia

Los que no son métricos —caracterizaciones, personajes, sinopsis—. Se abren con la edición pausada,
que es cuando se puede mover un campo sin que nadie guarde a mitad.

**Hecho el 7 de septiembre de 2026:**

- **La evocación métrica es un fenómeno enunciativo.** Vivía en dos columnas propias de la secuencia
  y se preguntaba en su panel; es lo mismo que el canto y la prosa, y se anota por rango con ellos.
  Sus seis filas se trasladaron con el rango completo de su secuencia, las columnas se borraron y la
  ficha dejó de publicarlas. Se pierde a propósito la distinción entre «no» y «pendiente»: una
  caracterización no se declara negativa.
- **Lo que será desviación dejó de ofrecerse.** Las cinco irregularidades métricas y los dos finales
  acentuales salieron del selector —`activo = false`—. **No se borró ninguna
  fila**: las 209 que hay se siguen leyendo, corrigiendo y borrando; solo no se pueden volver a
  elegir. A qué se traduce cada una cuando se migre está en
  [el plan de migración](../plan-migracion-anotaciones.md#2bis--el-reparto-de-las-caracterizaciones-por-rango). El endpoint conserva el término retirado cuando la fila ya lo tenía, y el desplegable lo
  ofrece marcado «del sistema anterior», para que corregir un rango no responda «no está activo».
- **El bloque dice lo que guarda.** «Caracterizaciones por rango» era un botón y una tabla vacía, y
  nadie sabía que los versos cantados se registran ahí. Ahora nombra lo que admite, armado del
  vocabulario y no de una lista escrita.

- **Lo que no hay en la obra no se pregunta en cada secuencia.** Tres casillas —`sin_figuras_donaire`,
  `sin_personajes_sobrenaturales`, `sin_eventos_sobrenaturales`— abren la pestaña de secuencias, en
  un bloque plegable llamado «Antes de anotar»: se marca lo que la obra no tiene y deja de
  preguntarse en cada secuencia, que quedan respondidas y bloqueadas con la nota «declarado para
  toda la obra». Se sembraron de lo anotado, así que nadie vuelve sobre una obra terminada.
  **Son casillas y no preguntas de tres estados, y eso es una decisión**: la pregunta no es
  simétrica —marcar que no hay cierra la pregunta en todas; un «sí» no marcaría un sí en ninguna, y
  puesto al lado del «no» parecía que lo haría—. Lo que afirma que las hay son las secuencias, y por
  eso la casilla se bloquea, diciendo cuántas, cuando alguna lo declara. Los personajes femeninos se
  dan por presentes en toda obra y siguen preguntándose por secuencia. El **evento sobrenatural** es
  nuevo, no es el personaje, y se responde sí/no por secuencia: ocurre o no ocurre, y la escala de
  intervención es de quien habla. **La coherencia la sostienen dos disparadores**, no la pantalla.
  `evento_sobrenatural` sigue sin agregarse al resumen —comprobado el 8 de septiembre de 2026—: su
  medida entra con el paso 1 del [plan de la precomputación](./ficha-publica-2026-09.md#el-plan-pactado-completado-en-cinco-pasos), para
  no escribir dos veces la misma función.

**Sin abrir:** la **revisión de los vocabularios generales**, inventariada en
[revisión de vocabularios](../revision-de-vocabularios.md).
