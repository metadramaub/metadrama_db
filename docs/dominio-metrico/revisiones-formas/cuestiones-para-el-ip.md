# Cuestiones para el IP

Actualizado: 1 de agosto de 2026

Este archivo reúne solo decisiones pendientes. Las decisiones ya tomadas están en la
ficha de cada revisión.

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
- **Las fichas de `revisiones-formas/` sobran a medida que su contenido entra en el dato.**
  No se borran de golpe: llevan el *porqué* de muchas decisiones, y ese porqué tiene que
  mudarse antes a `definicion`, `descripcion`, `nota` o `afirmaciones_fuentes_metricas`.

**Cuidado con la duplicación.** Hay tres sitios donde puede vivir una explicación —definición
de la forma, descripción de la arquitectura y nota de una sección o un rasgo— y hoy nada
impide decir lo mismo en los tres. Está sin auditar a propósito: primero se mueve el
contenido y se suman las fuentes que faltan, y después se revisa qué debe vivir dónde.

Estado del contenido el 4 de agosto: 28 formas, todas con definición; 49 arquitecturas, todas
con descripción; 23 denominaciones; 39 afirmaciones sobre 11 fuentes.

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

## Quintilla

Véase [quintilla.md](./quintilla.md).

1. ¿Los ocho esquemas forman un repertorio cerrado o son los reconocidos hasta ahora?
2. ¿Por qué no se incluye `aabaa`?
3. ¿`abbaa` y `ababb`, con pareado final, son variedades ordinarias?
4. ¿La definición pública debe explicar la diferencia con la preceptiva general?

## Tercetos

Véase [tercetos.md](./tercetos.md).

1. ¿Un verso excepcional sin rima es variante admitida o desviación?
2. ¿La repetición de una rima cuatro veces es variante o desviación?
3. ¿Cuántas unidades mínimas exige una serie encadenada?
4. ¿Los cierres en pareado o cuarteto de las antiguas series sin encadenar son canónicos?

Resuelto en el modelo: el terceto octosílabo es una arquitectura del encadenado por medida
—adapta a octosílabos la misma norma y no cambia nada más—, y ya declara su encadenamiento y
su cierre, en minúsculas. `tercetos_sin_encadenar` no era una forma sino una tirada de
tercetos. Sus dos disposiciones —`A-A`, con el verso central suelto, y `-AA`, con el
primero— son los dos esquemas de rima del terceto, y el editor elige entre ellas. El
encadenado sigue siendo forma aparte porque su rima cruza el límite de la unidad y la
secuencia entera es una sola unidad abierta.

## Silva

Véase [silva.md](./silva.md).

1. ¿`silva libre` tiene el alcance específico del corpus —7 y 11, consonancia libre— o
   el alcance moderno más amplio?
2. La silva libre deja de ser una arquitectura y pasa a ser el valor `ninguna` del rasgo
   `organizacion_en_pareados`. **El modelo no permite hoy que una denominación apunte a un
   valor de rasgo**, así que ese nombre no queda registrado en ninguna parte. ¿Hace falta que
   lo esté?

3. **`Silva · Endecasilábica` ofrece hoy el valor `ninguna`**, que según el reparto acordado
   pertenece al endecasílabo suelto. Mientras siga ofreciéndolo, una serie endecasilábica sin
   pareados encaja en las dos formas y el demarcador no puede separarlas. Comprobado en el
   dato el 4 de agosto. ¿Se retira ese valor de la silva?
4. ¿Se recoge la **silva 4** de Morley y Bruerton —7 y 11 mezclados, todas las rimas en los
   pares—? No está en el catálogo ni aparece en el corpus.

Resuelto en el modelo: cuánto organizan los pareados la serie es un **rasgo transversal con
valores cerrados** —ninguna, ocasionales, habituales, predominantes, regulares—, no cuatro
arquitecturas ni cuatro frases en prosa. Su escala corre por el endecasílabo suelto, la silva
y el pareado, de modo que la respuesta del editor apunta a la misma fila del catálogo venga
de la forma que venga. Cada arquitectura **declara** su grado como rasgo definitorio en vez
de preguntarlo, y por eso «Silva libre» sigue siendo arquitectura pese a compartir esquemas
con la irregular: es el único sitio donde ese nombre de la tradición puede vivir mientras una
denominación no pueda apuntar al valor de un rasgo.

## Series endecasilábicas y pareado

Véase [series-endecasilabicas.md](./series-endecasilabicas.md).

Sin decisiones imprescindibles pendientes.

Resuelto en el modelo: el pareado es **cualquier dístico** —dos versos que riman entre sí,
sea cual sea su medida— y una forma general que puede formar series, como el terceto o el
sexteto. Tiene una sola arquitectura: el arte no se modela, se deriva del metro elegido, y
además no separa regímenes de rima, porque el pareado admite consonancia y asonancia en
cualquier medida. Ni la medida ni el tipo de rima son arquitectura, porque el pareado no
tiene repertorio cerrado de ninguno de los dos: los declara el pasaje y se preguntan. La
medida se pregunta por posición, lo que además permite registrar el dístico heterométrico.
`pareados_endecasilabos` era una tirada de pareados, y `pareado_hexasilabo`,
`pareado_octosilabo` y `pareado_endecasilabo` eran medidas, no arquitecturas.

## Soneto

Véase [soneto.md](./soneto.md).

1. ¿`CDCDCD` debe seguir siendo el patrón preferente?
2. ~~¿`ABBA ABBA` es obligatorio o se admite `ABAB ABAB`?~~ **Resuelto: se admite.**
3. ¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?
4. ¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?

## Villancico

Véase [villancico.md](./villancico.md).

1. ¿La mudanza se presenta como una sección de cuatro versos o como dos mudanzas
   simétricas?
2. ¿El enlace o vuelta puede tener cualquier extensión desde un verso?
3. ¿`abba` y `abab` son esquemas cerrados o solo habituales?

Resuelto en el modelo: la medida se pregunta por sección, no por secuencia, porque un
villancico puede combinar medidas aunque lo habitual sea que no lo haga.

Resuelto en el modelo: la ausencia de cabeza no se trata como omisión. Si el estribillo
aparece por primera vez después de la primera copla, se selecciona una arquitectura
propia; las apariciones posteriores se registran como represas y la implícita no crea
versos ficticios. Una sección final aislada solo se considera estribillo si existe
evidencia funcional.

## Zéjel

Véase [zejel.md](./zejel.md).

1. ¿Se admiten estribillos de uno y de dos versos o el zéjel estricto exige dístico?
2. ¿Una represa parcial es posibilidad admitida o desviación?

Resuelto en el modelo: 6 y 8 no son un repertorio cerrado sino las medidas típicas, y se
preguntan por sección. Cualquier otra se registra como desviación.

## Copla real

Véase [coplas-y-sextillas.md](./coplas-y-sextillas.md).

1. ¿Los quebrados pueden ocupar cualquiera de las diez posiciones?
2. ¿Se admiten únicamente tetrasílabos o también pentasílabos?
3. ~~¿Las dos quintillas reutilizan el repertorio de ocho esquemas ya reconocido?~~
   **Resuelto: sí.** Cada sección declara la arquitectura de la quintilla con
   `arquitectura_referenciada_id` y sus opciones señalan los ocho esquemas de la quintilla.
4. ~~¿La arquitectura quebrada es admitida o canónica?~~ **Resuelto: es un rasgo, no una
   arquitectura.** Llevar quebrados no cambia la norma —diez octosílabos en dos
   quintillas—, así que las dos arquitecturas se han fundido en una y `pie_quebrado` queda
   como rasgo admitido.

## Coplas y sextillas

Véase [coplas-y-sextillas.md](./coplas-y-sextillas.md).

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

Resuelto en el modelo: la medida de la sextilla es arquitectura y no pregunta, porque es
isosilábica; la doble sextilla es su arquitectura de doce versos y no otra forma; y «copla
manriqueña» es la denominación del esquema `abcabc:defdef` de esa arquitectura, no una
forma. `copla_de_pie_quebrado` sigue siendo una forma general, registrable, de 5–12 versos,
para los casos que no encajan en una más específica, y sus quebrados se registran como
medida de una posición, no como doce casillas sueltas. El rasgo `pie_quebrado` permanece
separado y reutilizable.

## Décimas

Véase [decimas.md](./decimas.md).

1. ¿El linaje debe limitarse por ahora a copla real, décima espinela y décima
   aumentada?
2. ¿Se mantiene «Décima aumentada» como nombre público preferente?
3. ¿La definición pública de la espinela debe conservar la expresión «dos redondillas
   enlazadas por dos versos puente»?

Resuelto el 4 de agosto de 2026 y **aplicado**, revisando la decisión anterior: existe una
forma **Décima** con dos arquitecturas, **Espinela** (10 versos) y **Aumentada** (12), y los
nombres tradicionales se conservan como denominaciones de cada una.

Antes se había retirado `decima` porque su definición y su patrón duplicaban los de la
espinela —lo cual es cierto: son el mismo texto y el mismo `abbaaccddc`, y cada término
declara al otro en `equivalencias`—. Pero de ahí no se sigue que la décima no sea forma, sino
que la raíz vieja **era** la espinela. Y la aumentada había quedado fuera porque doce versos
no cabían en una forma de diez, obstáculo que desapareció cuando la extensión pasó a
declararla la arquitectura: la redondilla, de cuatro versos, aloja «Doble enlazada», de ocho.

No se creó arquitectura genérica: en el corpus no hay ninguna décima de diez versos que no
sea espinela. La definición lleva la articulación 4 + 2 + 4 y no solo la medida, porque la
copla real es también diez octosílabos consonantes y lo que las separa es dónde cae la pausa.

Lo que **no** cambia: la copla real sigue siendo forma aparte, y lo que la une a la décima son
relaciones tipadas, no pertenencia. No hay familia.

## Redondilla

Véase [redondilla.md](./redondilla.md).

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Si no puede, son dos
   arquitecturas más y la redondilla se registra sin ninguna pregunta. Mientras la duda
   siga abierta se mantiene como esquema elegido por unidad, que es la opción reversible:
   corregirlo después es reclasificar filas, mientras que haberlo tratado como
   arquitectura habría partido secuencias que no debían partirse.
2. ¿Debe incorporarse «octavilla» como denominación relacionada o resultaría
   demasiado amplia?

Resuelto en el modelo y aplicado en el dato: existe una única forma `redondilla`. Por su
isosilabismo, las medidas 6, 7 y 8 son tres arquitecturas y no una elección; la doble
enlazada es una cuarta, de ocho versos; «Cuarteta» es denominación **posterior** del esquema
cruzado, no equivalente, porque en el Siglo de Oro ambas disposiciones eran redondillas; la
hexasílaba se corrige a seis sílabas.

## Octava real

Véase [octava-real.md](./octava-real.md).

Sin decisiones imprescindibles pendientes. El catálogo mantiene el alcance
endecasilábico del proyecto y no incorpora automáticamente la octavilla real
excepcional documentada en la bibliografía.

## Novena

Véase [novena.md](./novena.md).

1. ¿Las rimas de redondilla y quintilla son siempre independientes o debe registrarse
   una clase compartida entre ambas secciones?
2. ¿Las ocho variedades actuales de quintilla se ofrecen dentro de toda novena?
3. ¿Las demás estrofas de nueve versos quedan fuera salvo que aparezcan en el corpus?

Resuelto en el modelo: `redondilla_quintilla` y `quintilla_redondilla` son arquitecturas de una
única forma; sus secciones reutilizan las arquitecturas de redondilla y quintilla sin
copiar sus esquemas.

## Sexteto-lira

Véase [sexteto-lira.md](./sexteto-lira.md).

1. ¿Las siete variedades son un repertorio cerrado, las reconocidas hasta ahora o
   medida y rima pueden combinarse libremente? Si aparecen otras parejas restringidas,
   se ampliarían las combinaciones; solo si ambos ejes son independientes se
   preguntarían por separado.
2. ¿A1 debe seguir presentándose como variedad habitual o preferente?
3. ¿Una tirada puede cambiar de variedad entre estrofas sin dejar de constituir una
   única secuencia?

## Sexteto

Véase [sexteto.md](./sexteto.md).

- No bloquea el registro actual: el proyecto lo delimita como seis versos de arte mayor
  consonantes, repartidos en tres arquitecturas por medida —11, 12 y 14—.
- Si el corpus documenta un sexteto que combine arte mayor y menor y no sea sexteto-lira,
  confirmar si debe ampliarse la forma o crearse otra.
- ¿Las medidas 11, 12 y 14 forman un repertorio cerrado?

Resuelto en el modelo: la sexta rima no es una forma sino una **variedad** de la
arquitectura endecasilábica del sexteto, con «Sexta rima» y «Sexteto clásico» como
denominaciones. No añade ninguna norma que la arquitectura no tenga ya: concreta una de sus
realizaciones y le pone nombre. El sexteto-lira, en cambio, no es ni arquitectura ni
variedad suya: su heterometría es principio constructivo y su genealogía va a la lira,
declarada como `sexteto_lira derivada_de lira`.

## Seguidilla

Véase [seguidilla.md](./seguidilla.md).

- No bloquea el registro actual: se distinguen las arquitecturas simple y compuesta
  con la norma asonante fijada por el proyecto.
- Si las oscilaciones métricas o las realizaciones consonantes fueran recurrentes en el
  corpus, confirmar si deben seguir siendo desviaciones o convertirse en opciones
  admitidas.

## Sextina

Véase [sextina.md](./sextina.md).

- No bloquea el registro: la definición del proyecto permite distinguir la clásica de
  la doble y ambas conservan la misma regla de permutación.
- Confirmar únicamente si debe fijarse el orden de las seis palabras dentro del remate.
  Por ahora se exige su presencia —tres interiores y tres finales— sin imponer parejas.

## Canción petrarquista

Véase [cancion-petrarquista.md](./cancion-petrarquista.md).

1. ¿La canción sin rima o canción libre debe seguir siendo arquitectura de la canción
   petrarquista o tiene identidad suficiente para ser forma?
2. ¿Debe exigirse siempre remate o envío en las canciones registradas?
3. ¿Se mantiene el mínimo de 5 versos por estancia fijado por el proyecto, pese al
   mínimo de 9 indicado por Domínguez Caparrós?

Resuelto en el modelo: 8, 9 y 15 son extensiones de estancia; una estancia solo
endecasílaba se obtiene eligiendo 11 sílabas en todas sus posiciones.

## Romance

Véase [romance.md](./romance.md).

1. ¿`Endecha` y `Romance endecha` deben mantenerse como denominaciones equivalentes tanto
   de la arquitectura hexasílaba como de la heptasílaba, o reservarse para la heptasílaba?
2. ¿Debe registrarse «Romance heroico» como denominación de la arquitectura endecasílaba?
   Hoy solo está «Romance real», y un nombre que no vive en ninguna parte deja de ser
   recuperable.

Resuelto en el modelo: ni el romancillo ni el romance heroico son formas. Las cuatro
medidas —6, 7, 8 y 11— son arquitecturas de `romance` y solo se distinguen por ese dato;
sus nombres tradicionales viven como denominaciones. La antigua raíz ambigua `romancillo`
mezclaba dos medidas y no tiene destino: obliga a revisar las secuencias heredadas que no
permitan determinar cuál era.

## Tramos sin forma

Véase [tramos-sin-forma.md](./tramos-sin-forma.md).

1. Confirmar si `Verso aislado` debe ser la etiqueta pública definitiva de la antigua
   entrada `verso suelto`.

Resuelto en el modelo: `Versificación irregular` y `Verso aislado` son salidas
editoriales, no formas. La primera exige dos o más versos y la segunda exactamente uno.
Una forma reconocible con excepciones se registra mediante desviaciones y no mediante
estas salidas.
