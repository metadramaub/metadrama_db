# Decisiones de modelo, forma por forma

Por qué el catálogo está construido como está: qué se decidió tratar como forma, como
arquitectura, como esquema o como rasgo, y qué se descartó por el camino.

Estos textos vivían en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md),
que es un registro de **lo que sigue sin decidir**. No eran dudas sino decisiones ya aplicadas
en el dato, y hacían ruido allí. Se mudan aquí el 5 de agosto de 2026.

**Este archivo se vacía, no crece.** A medida que cada forma se revisa, su porqué se muda al
catálogo —a la definición, a la descripción de la arquitectura o a una afirmación de fuente— y
su apartado desaparece de aquí. Es andamiaje: si se deja estar, en unos meses no habrá manera
de saber qué sigue vigente y qué es residuo.

Cuando el trabajo termine, esto debería quedar en cero. La justificación de las decisiones
reales serán [la ontología](./ontologia-verso-espanol.md) y
[la implementación](./implementacion-metrica.md) contrastadas con el catálogo, que es el modelo
ya poblado: eso basta, y sobra el resto de documentos.

**Si se cambia el modelo**, hay que revisar esos dos. Hasta ahora la revisión de definiciones y
fuentes no lo ha tocado: se ha corregido prosa, se han declarado partes que ya estaban
implícitas y se ha retirado `tipo_alias`, que era una clasificación sin uso, no una pieza del
modelo.


## Series endecasilábicas y pareado

Resuelto en el modelo: el pareado es **cualquier dístico** —dos versos que riman entre sí,
sea cual sea su medida— y una forma general que puede formar series, como el terceto o el
sexteto. Tiene una sola arquitectura: el arte no se modela, se deriva del metro elegido, y
además no separa regímenes de rima, porque el pareado admite consonancia y asonancia en
cualquier medida. Ni la medida ni el tipo de rima son arquitectura, porque el pareado no
tiene repertorio cerrado de ninguno de los dos: los declara el pasaje y se preguntan. La
medida se pregunta por posición, lo que además permite registrar el dístico heterométrico.
`pareados_endecasilabos` era una tirada de pareados, y `pareado_hexasilabo`,
`pareado_octosilabo` y `pareado_endecasilabo` eran medidas, no arquitecturas.

## Villancico

Resuelto en el modelo: la medida se pregunta por sección, no por secuencia, porque un
villancico puede combinar medidas aunque lo habitual sea que no lo haga.

## Villancico

Resuelto en el modelo: la ausencia de cabeza no se trata como omisión. Si el estribillo
aparece por primera vez después de la primera copla, se selecciona una arquitectura
propia; las apariciones posteriores se registran como represas y la implícita no crea
versos ficticios. Una sección final aislada solo se considera estribillo si existe
evidencia funcional.

## Zéjel

Resuelto en el modelo: 6 y 8 no son un repertorio cerrado sino las medidas típicas, y se
preguntan por sección. Cualquier otra se registra como desviación.

## Coplas y sextillas

Resuelto en el modelo: la medida de la sextilla es arquitectura y no pregunta, porque es
isosilábica; la doble sextilla es su arquitectura de doce versos y no otra forma; y «copla
manriqueña» es la denominación del esquema `abcabc:defdef` de esa arquitectura, no una
forma. `copla_de_pie_quebrado` sigue siendo una forma general, registrable, de 5–12 versos,
para los casos que no encajan en una más específica, y sus quebrados se registran como
medida de una posición, no como doce casillas sueltas. El rasgo `pie_quebrado` permanece
separado y reutilizable.

## Novena

Resuelto en el modelo: `redondilla_quintilla` y `quintilla_redondilla` son arquitecturas de una
única forma; sus secciones reutilizan las arquitecturas de redondilla y quintilla sin
copiar sus esquemas.

## Sexteto

Resuelto en el modelo: la sexta rima no es una forma sino una **variedad** de la
arquitectura endecasilábica del sexteto, con «Sexta rima» y «Sexteto clásico» como
denominaciones. No añade ninguna norma que la arquitectura no tenga ya: concreta una de sus
realizaciones y le pone nombre. El sexteto-lira, en cambio, no es ni arquitectura ni
variedad suya: su heterometría es principio constructivo y su genealogía va a la lira,
declarada como `sexteto_lira derivada_de lira`.

## Canción petrarquista

Resuelto en el modelo: 8, 9 y 15 son extensiones de estancia; una estancia solo
endecasílaba se obtiene eligiendo 11 sílabas en todas sus posiciones.

## Tramos sin forma

Resuelto en el modelo: `Versificación irregular` y `Verso aislado` son salidas
editoriales, no formas. La primera exige dos o más versos y la segunda exactamente uno.
Una forma reconocible con excepciones se registra mediante desviaciones y no mediante
estas salidas.
