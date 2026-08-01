# El dominio métrico de METADRAMA

Estado: vigente · 1 de agosto de 2026

Este documento explica en pocas páginas y sin tecnicismos **qué se ha construido y para
qué**. Es la lectura de acompañamiento de los dos documentos que lo detallan: la
[ontología del verso español](./ontologia-verso-espanol.md), que describe el objeto, y
[la implementación de METADRAMA](./implementacion-metrica.md), que describe qué se ha hecho
con él aquí.

## El problema que lo motivó

El vocabulario anterior era una jerarquía de padres e hijos, y bajo el mismo tipo de arista
convivían cosas de naturaleza distinta: formas métricas, variantes de una forma, esquemas de
rima, nombres históricos, tradiciones y propiedades que pueden darse en muchas formas a la
vez. `romance` era padre de `romance_e-a`; `redondilla`, de `redondilla_cruzada` y de
`redondilla_hexasilaba`. Pero `e-a` es un timbre observado, `cruzada` una disposición de rima
y `hexasílaba` una medida.

Eso tenía tres consecuencias prácticas. Reordenar el vocabulario cambiaba cálculos aunque
solo se pretendiera ordenar nombres. El editor tenía que elegir entre decenas de hijos que no
eran alternativas comparables. Y cualquier recuento —cuántas formas usa un autor, cuánto se
parecen dos obras— mezclaba órdenes distintos y producía cifras que no significaban lo mismo
en cada forma.

## Qué se ha hecho

Se ha separado **lo que el verso español es** de **lo que este proyecto registra de él**.

La ontología describe el objeto: la sílaba métrica y su cómputo, la ley del acento final, el
ritmo, la rima, cómo se agrupan los versos en unidades y las unidades en pasajes, qué
convierte a una combinación en una forma con nombre. Describe posibilidades, no un corpus, y
por eso incluye cosas que aquí no se analizan —el ritmo acentual, el encabalgamiento— pero
que otro proyecto podría necesitar.

La implementación dice qué parte de eso se realiza y qué se restringe. La frontera principal
es que **el proyecto no almacena el texto de las obras**: sin texto no hay sílabas que contar
ni acentos que situar, y eso decide qué mitad de la ontología es implementable aquí.

## Cómo funciona el catálogo

Una forma —el romance, el soneto, la copla real— declara una **arquitectura**: cuántos versos
tiene su unidad, cómo se divide en secciones, qué medidas admite, cómo se comporta la rima.
Junto a esa norma se registran arquitecturas alternativas, variedades reconocidas, nombres
equivalentes con su época, tradiciones y fuentes. Cada dato ocupa un lugar preciso y deja de
hacer falta inventar una «subforma» cada vez que cambia un rasgo.

Tres decisiones ordenan todo lo demás.

**La medida de una forma isosilábica es arquitectura, no pregunta.** Una tirada de
redondillas no cambia de medida a mitad de camino: si cambia, empieza otra secuencia. Por eso
el romance tiene cuatro arquitecturas y no una pregunta por la medida.

**Las estrofas básicas existen una vez y las formas complejas las reutilizan.** Los cuartetos
del soneto son cuartetos, las dos mitades de la copla real son quintillas, la cadena del
terceto encadenado cierra con un serventesio. Ninguna de esas formas copia el repertorio de
la otra: lo referencia. Reutilizar es mecánico y no afirma parentesco; para eso están las
relaciones tipadas, que se declaran aparte y solo cuando son ciertas.

**Se registran las combinaciones típicas y se nombra a las que han recibido nombre.** Lo
demás es posible aunque no esté registrado. La escala que acompaña a cada realización
—definitoria, preferente, admitida, excepcional— no dice qué está permitido, porque nada está
prohibido: dice cuánto ha fijado la norma o la crítica esa combinación, que es lo que después
se puede analizar.

## Qué hace el editor

La complejidad se concentra en el catálogo, que se prepara y revisa antes. Cuando el editor
elige una forma, el sistema ya conoce su norma, y solo se le pregunta lo que no puede
derivarse: qué disposición de rima presenta esta redondilla, qué medida tiene esta sección,
qué esquema traen los tercetos de este soneto.

Esas respuestas no son irregularidades: describen la realización y se guardan porque sirven
para comparar. Lo que sí es una irregularidad se registra como **desviación**, localizada por
su rango: si una copla de octosílabos trae un verso de siete, se anota esa diferencia y dónde
está, sin inventar una forma nueva.

Rige una convención de mundo cerrado: **una secuencia guardada sin desviaciones se considera
conforme**. No se piden campos de certeza ni de revisión.

## Qué se gana

**Comparabilidad.** Un hecho registrado significa lo mismo venga de la forma que venga,
porque todos apuntan a los mismos catálogos: el mismo octosílabo, la misma clase de rima, el
mismo valor de rasgo. Sin eso, contar cuántas redondillas hay en un corpus produce una cifra
que solo su autor sabe leer.

**Un demarcador que razona con datos.** En lugar de recorrer una jerarquía rígida, trabaja
con las propiedades efectivas de cada arquitectura y pregunta solo lo que separa candidatas.
«No sé» sigue siendo una respuesta válida y no equivale a negar nada.

**Un modelo publicable.** La ontología del verso español no depende de este corpus y puede
reutilizarla quien quiera construir su propio catálogo. Esa separación es deliberada: lo que
aquí se decidió para el teatro del Siglo de Oro está marcado como decisión y no como hecho de
la métrica.

## Dónde está ahora

El catálogo tiene veintiséis formas y dos tramos sin forma, y el informe de conformidad no
señala ningún defecto. Las anotaciones existentes en las obras siguen usando el vocabulario
anterior: su migración se hará cuando el IP haya validado el catálogo y el editor se haya
probado con casos reales, conservando la referencia de procedencia y sin asignar por
conjetura lo que un registro antiguo no permita determinar.
