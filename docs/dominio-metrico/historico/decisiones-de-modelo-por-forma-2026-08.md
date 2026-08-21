# Decisiones de modelo, forma por forma

> **Archivado el 21 de agosto de 2026.** Este archivo era andamiaje: se escribió para vaciarse, a
> medida que el porqué de cada forma se mudaba al catálogo —a su definición, a la descripción de su
> arquitectura o a una afirmación de fuente—. Con la revisión de la prosa terminada, **ese traslado
> está hecho** y lo que aquí queda es la versión anterior de esas explicaciones.
>
> Lo vigente se lee en `/formas`, que se genera del dato.

Por qué el catálogo está construido como está: qué se decidió tratar como forma, como
arquitectura, como esquema o como rasgo, y qué se descartó por el camino.

Estos textos vivían en [cuestiones para el IP](../cuestiones-para-el-ip.md),
que es un registro de **lo que sigue sin decidir**. No eran dudas sino decisiones ya aplicadas
en el dato, y hacían ruido allí. Se mudan aquí el 5 de agosto de 2026.

**Este archivo se vacía, no crece.** A medida que cada forma se revisa, su porqué se muda al
catálogo —a la definición, a la descripción de la arquitectura o a una afirmación de fuente— y
su apartado desaparece de aquí. Es andamiaje: si se deja estar, en unos meses no habrá manera
de saber qué sigue vigente y qué es residuo.

Cuando el trabajo termine, esto debería quedar en cero. La justificación de las decisiones
reales serán [la ontología](../ontologia-verso-espanol.md) y
[la implementación](../implementacion-metrica.md) contrastadas con el catálogo, que es el modelo
ya poblado: eso basta, y sobra el resto de documentos.

**Si se cambia el modelo**, hay que revisar esos dos. La lista vigente de cambios aplicados y
defectos aplazados vive únicamente en
[el estado de la revisión](./revision-del-catalogo-2026-07-a-08.md); no se duplica aquí porque esta
lista se vacía a medida que las formas quedan absorbidas en el catálogo.

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

## Sexteto

Resuelto en el modelo: la sexta rima no es una forma. **Desde el 9 de agosto de 2026 es una
denominación del esquema de rima `ABABCC`** de la arquitectura endecasilábica del sexteto, y
no una variedad como estuvo hasta entonces: una variedad restringe qué parejas de esquema
métrico y de rima se admiten, y esa arquitectura tiene un solo esquema métrico, de modo que no
hay parejas que restringir. Lo que hace es dar nombre a una disposición, que es el trabajo de
la denominación. Con ella viajaron «Sexteto clásico», «Sextina real» y «Sextina antigua».

El sexteto-lira, en cambio, no es ni arquitectura ni variedad suya: su heterometría es
principio constructivo y su genealogía va a la lira, declarada como
`sexteto_lira derivada_de lira`.

## Canción petrarquista

Resuelto en el modelo: 8, 9 y 15 son extensiones de estancia; una estancia solo
endecasílaba se obtiene eligiendo 11 sílabas en todas sus posiciones.

## Tramos sin forma

Resuelto en el modelo: `Versificación irregular` y `Verso aislado` son salidas
editoriales, no formas. La primera exige dos o más versos y la segunda exactamente uno.
Una forma reconocible con excepciones se registra mediante desviaciones y no mediante
estas salidas.
