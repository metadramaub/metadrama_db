# Ontología del verso español

Estado: vigente · 1 de agosto de 2026

Este documento describe **qué es el verso español y de qué está hecho**: sus unidades, sus
fenómenos y las estructuras en que se combinan. Describe posibilidades, no un corpus.

No conoce editores, ni catálogos, ni formularios. Tampoco restringe: si una posibilidad
existe en la métrica española, aquí figura aunque ningún proyecto la registre. Lo que
METADRAMA implementa de todo esto, y lo que restringe por su corpus, está en
[la implementación de METADRAMA](./implementacion-metrica.md).

> **Para qué sirve.** Formalizar el verso en estructuras permite descomponer un texto en
> hechos comparables y, por tanto, analizarlo cuantitativamente. Quien adopte esta ontología
> construirá con ella un catálogo —de la época, del autor o del género que le interese— y las
> cifras que obtenga serán comparables con las de otro catálogo construido igual. Esa
> comparabilidad es el objetivo; todo lo demás son medios.

## 1 · Qué es una norma métrica

Una norma métrica es un **análisis hacia el pasado**. Nadie escribió una redondilla
consultando su definición: la definición es una abstracción que la tradición crítica destiló
de muchas realizaciones y a la que después dio nombre.

De ahí se siguen tres consecuencias que gobiernan todo el modelo.

**La norma no es una prescripción, y la realización no es su cumplimiento.** Un pasaje no
obedece a una forma: se parece a ella lo bastante como para que llamarla así sea informativo.
Por eso la diferencia entre lo previsto y lo observado no es un error del texto sino un dato
del análisis.

**Las normas son de grano variable.** Algunas fijan casi todo —catorce endecasílabos con un
esquema de rima determinado—; otras fijan un mínimo —dos versos que riman entre sí—. Las
segundas no son normas defectuosas: son normas generales, y describen tanto como las
primeras.

**Las escuelas no coinciden.** La misma realización recibe nombres distintos según la
tradición crítica, y categorías que parecen equivalentes solo lo son en parte. Una ontología
que fuerce una sola nomenclatura pierde información; lo que hay que modelar es el concepto,
y registrar las denominaciones con su procedencia.

## 2 · Las cuatro familias de entidades

Todo lo que sigue pertenece a una de estas cuatro familias, y confundirlas es el error que
hace incomparables los recuentos.

| Familia | Qué contiene | Ejemplo |
| --- | --- | --- |
| **Formas abstractas** | Lo que una norma fija o admite | el esquema `abba`, el metro octosílabo |
| **Realizaciones observadas** | Lo que un pasaje concreto hace | la escansión de un verso, el timbre de su rima |
| **Fenómenos relacionales** | Lo que ocurre entre dos unidades o entre planos | la cesura, el encabalgamiento, el enlace de rima |
| **Clasificación** | Lo que agrupa y nombra | la forma, la tradición, la denominación |

La distinción entre las dos primeras es la que TEI codifica con `@met` —la forma
convencional— y `@real` —la realización prosódica—, y la que la teoría contemporánea del
verso formula como la relación entre un patrón abstracto y su instanciación lingüística.

## 3 · El verso

### La sílaba métrica

La unidad de cómputo del verso español no es la sílaba gramatical sino la **sílaba métrica**,
que resulta de aplicar a la cadena fónica un conjunto de operaciones. No son licencias en el
sentido de excepciones: son las reglas ordinarias del cómputo.

| Operación | Qué hace | Alcance |
| --- | --- | --- |
| **Sinalefa** | Une en una sílaba la vocal final de una palabra con la inicial de la siguiente | Entre palabras. Es lo normal; no hacerla es lo marcado |
| **Dialefa** o **hiato** | Mantiene separadas esas dos vocales | Entre palabras |
| **Sinéresis** | Cuenta como una las dos vocales que dentro de una palabra formarían hiato | Dentro de palabra |
| **Diéresis** | Deshace un diptongo y cuenta dos sílabas | Dentro de palabra; suele marcarse gráficamente |

La sinalefa no atraviesa la cesura de un verso compuesto: cada hemistiquio se computa por
separado.

### La ley del acento final

El verso español no se mide contando sílabas hasta el final, sino **hasta la última sílaba
tónica, más una**. De ahí la regla que altera la cuenta según la terminación:

| Terminación | Efecto sobre el cómputo |
| --- | --- |
| **Aguda** · oxítona | +1 sílaba |
| **Llana** · paroxítona | sin efecto |
| **Esdrújula** · proparoxítona | −1 sílaba |

Esta regla **pertenece a la medida, no al ritmo**. Un modelo que excluya el ritmo del análisis
sigue necesitándola, porque sin ella no puede decir cuántas sílabas tiene un verso.

### La medida y el arte

La **medida** es el número de sílabas métricas. De ella se deriva el **arte**: menor hasta
ocho sílabas, mayor de nueve en adelante. El arte no es un dato independiente y no debe
almacenarse.

Cada medida tiene un nombre tradicional —bisílabo, trisílabo, tetrasílabo, pentasílabo,
hexasílabo, heptasílabo, octosílabo, eneasílabo, decasílabo, endecasílabo, dodecasílabo,
tridecasílabo, alejandrino— y por encima del alejandrino la nomenclatura se vuelve
descriptiva.

### El ritmo

El verso español es **silábico-acentual**: cuenta sílabas y distribuye acentos, pero no
construye pies. El ritmo es la distribución de las prominencias dentro de esa cuenta.

- **Acento estrófico** o constitutivo: el que recae sobre la penúltima sílaba métrica. Es
  fijo en todo verso español y constituye el eje del ritmo; los demás se ordenan respecto de
  él.
- **Ictus**: cada posición prominente del verso.
- **Acentos rítmicos, extrarrítmicos y antirrítmicos**: los que coinciden con el patrón
  periódico, los que caen fuera sin contradecirlo y los que caen en la sílaba contigua a un
  ictus y lo perturban.
- **Cláusula rítmica**: el grupo que forma un ictus con las sílabas átonas que lo siguen.
  Trocaica cuando lleva una átona, dactílica cuando lleva dos. Un verso es de ritmo trocaico
  o dactílico según cuál predomine.

Los versos de una misma medida se clasifican por su perfil acentual. El endecasílabo es el
caso más elaborado de la tradición hispánica:

| Tipo | Acentos principales |
| --- | --- |
| **Enfático** | 1.ª · 6.ª · 10.ª |
| **Heroico** | 2.ª · 6.ª · 10.ª |
| **Melódico** | 3.ª · 6.ª · 10.ª |
| **Sáfico** | 4.ª · 8.ª · 10.ª |

Los tres primeros comparten el acento en sexta y la nomenclatura antigua los reúne como
*a maiore*, frente al sáfico o *a minore*. Las escuelas difieren en los límites de estas
clases y en si el sáfico exige además acento en sexta; el modelo registra el perfil observado
y la clasificación como interpretación, no al revés.

> **El ritmo es propiedad del verso, nunca de la forma.** «Soneto de versos sáficos» confunde
> una propiedad de cada verso con la norma de un poema. La norma puede prescribir un perfil
> —y algunas lo hacen—, pero entonces lo prescribe para posiciones concretas, no para la
> composición entera.

### La cesura y el verso compuesto

Un verso puede estar dividido por una **cesura** en dos o más **hemistiquios**. Cuando lo
está, cada hemistiquio se comporta como un verso a efectos de cómputo: tiene su propia ley de
acento final y la sinalefa no lo atraviesa.

Eso hace que un **verso compuesto** no equivalga a un verso simple de la misma medida. El
alejandrino son dos heptasílabos; el dodecasílabo de arte mayor son dos hexasílabos; ninguno
es intercambiable con un verso simple de catorce o de doce sílabas.

### Pie y mora

No pertenecen al sistema español y se nombran aquí para dejar constancia de que se descartan,
no de que se ignoran. El **pie** es la unidad de las tradiciones cuantitativas —griega y
latina— y de las acentuales-silábicas —inglesa, alemana—; la **mora**, de las cuantitativas y
de la japonesa. Una ontología que quiera cubrir otras tradiciones las activará; el verso
español no las necesita.

## 4 · La rima

### Qué es

La correspondencia fónica entre dos versos **a partir de su última vocal tónica**. De ahí
salen dos tipos, y la distinción es cerrada:

- **Consonante** o total: coinciden todos los sonidos, vocales y consonantes.
- **Asonante** o parcial: coinciden solo las vocales.

En la rima asonante de versos esdrújulos y en los diptongos rigen convenciones de reducción
—la vocal átona intermedia no cuenta, la débil del diptongo tampoco—, que son parte del
cómputo del timbre y no excepciones.

Un verso puede no rimar. Se llama **suelto** cuando queda sin correspondencia dentro de una
composición rimada, y **blanco** cuando la composición entera prescinde de la rima. No son lo
mismo: el primero es una posición del esquema, el segundo una propiedad de la forma.

La rima hereda además la terminación del verso: **aguda, llana o esdrújula**.

### La clase y el esquema

Una **clase de rima** es el conjunto de versos que comparten timbre dentro de una unidad. El
**esquema de rima** es la distribución de esas clases sobre las posiciones: qué posición
pertenece a qué clase y cuáles quedan sueltas.

El esquema tiene dos planos que conviene no confundir. La **notación** —`abba`, `aBabB`,
`-a-a`— es documentación legible, y en la tradición hispánica sus mayúsculas y minúsculas
codifican el arte métrico. El **comportamiento computable** son las posiciones con su clase,
las que se esperan sueltas, los enlaces y las restricciones combinatorias.

**El timbre concreto no forma parte de la identidad de la forma.** Un romance en `e-a` y otro
en `a-o` son el mismo romance. El timbre es una realización observada.

**Y una norma puede fijar la rima sin fijar su disposición.** La quintilla exige consonancia, dos
clases y que ningún verso quede suelto, pero no dice en qué orden; la sextilla admite «distintas
distribuciones»; la canción deja libre el esquema de la estancia y solo exige que vuelva idéntico
en todas. Eso no es ausencia de norma: es una norma expresada como **restricciones** en vez de
como posiciones.

Las dos maneras dicen lo mismo por dos caminos, y conviene verlo: de las restricciones de la
quintilla se **deriva** que sus disposiciones posibles son ocho, exactamente las que la tradición
nombra. Por eso un esquema sin posiciones no está incompleto —está diciendo otra cosa— y por eso
las restricciones y la enumeración deben poder contrastarse: si una disposición declarada no
cumpliera el criterio, una de las dos estaría mal.

> **Prueba de que una restricción está bien puesta: que sirva para juzgar un pasaje que nadie
> haya enumerado.** «No más de dos versos seguidos con la misma rima» lo hace; «la rima es
> consonante y su orden varía» no, porque eso ya lo dicen el tipo de rima y la ausencia de
> posiciones.

### La posición y el enlace

Lo normal es que la rima ocupe el final del verso, pero no es lo único posible: hay **rima
interna**, **rima en eco** y otras disposiciones que corresponden con posiciones no finales.
El modelo localiza cada correspondencia, no la presupone final.

Un **enlace** es una correspondencia que **cruza el límite de la unidad**: la rima central de
un terceto que pasa a las exteriores del siguiente, la vuelta que recupera la clase del
estribillo. Es un fenómeno relacional y no cabe en la notación de una sola unidad; por eso se
declara aparte.

## 5 · La agrupación

### Los niveles

```text
sílaba métrica → verso → [hemistiquio] → unidad → secuencia → poema
```

La **unidad** es lo que se repite. Según la forma, puede ser:

| La unidad es | La secuencia contiene | Nombre tradicional |
| --- | --- | --- |
| la **estrofa** | N estrofas iguales | tirada, serie estrófica |
| la **serie abierta** | exactamente una, de extensión libre | serie no estrófica |
| la **composición** de estructura fija | N composiciones | — |

Una sucesión de estrofas iguales **no es otra forma**: es una secuencia con N unidades. La
distinción importa porque el vocabulario tradicional a veces nombra la tirada y a veces la
estrofa con la misma palabra.

### Secciones y repetición

Una **sección** es una parte del interior de la unidad, con extensión y repetición propias:
los cuartetos y tercetos de un soneto, la cabeza y las mudanzas de un villancico. Puede
anidarse.

Hay dos repeticiones distintas y solo una pertenece a la norma:

- **repetición interna** — cuántas veces se repite una parte dentro de la unidad;
- **repetición del pasaje** — cuántas unidades hay, que es una propiedad del pasaje y no de la
  forma.

Además de la rima, una forma puede repetir **material léxico** en posiciones determinadas: las
seis palabras finales de la sextina, el estribillo que reaparece. Es un mecanismo distinto de
la rima y necesita expresarse aparte.

### La pausa y el encabalgamiento

La **pausa versal** cierra el verso, la **estrófica** la unidad, y la cesura es una pausa
interior. Cuando una unidad sintáctica atraviesa una pausa versal se produce
**encabalgamiento**.

Es un fenómeno relacional entre la sintaxis y el verso, **no una propiedad de la forma**: un
soneto no es «un soneto encabalgado». Se localiza entre dos versos y se clasifica por su
extensión —abrupto o suave, según dónde caiga la pausa sintáctica— y por lo que separa:
sirremático cuando parte un sintagma trabado, oracional cuando parte una oración, léxico
cuando parte una palabra.

## 6 · La forma

### Qué la constituye

Una **forma** es una combinación de todo lo anterior que una tradición reconoce y nombra, y
que puede asignarse a un pasaje. Fija algunas cosas, admite variación en otras y deja el resto
abierto.

Lo que una forma fija puede ser: la extensión de su unidad, su división en secciones, la
medida o la sucesión de medidas, el tipo de rima, el esquema o el repertorio de esquemas
admitidos, los enlaces, las repeticiones léxicas y las propiedades que la caracterizan.

Una forma **no hereda de otra**. Dos formas pueden estar emparentadas y ese parentesco se
declara, pero no transmite propiedades: heredar convierte la taxonomía en comportamiento y
hace que reordenar nombres cambie cálculos.

### General y específica

Una **forma general** fija un mínimo que no llega a cerrar una identidad. Una **forma
específica** cierra esa norma. La segunda no es más forma que la primera: está más
especificada.

La consecuencia práctica es de identificación: ante un pasaje se ofrece la forma más
específica que encaje, y cuando ninguna especialización corresponde, **la general es la
respuesta correcta y no un consuelo**.

### Realización estructural y variedad

Una forma puede admitir varias **realizaciones estructurales**: distintas extensiones de
unidad, distintas divisiones internas, distintas medidas cuando es isosilábica. Cada una es
constante dentro de una secuencia; si cambia, empieza otra.

Y puede reconocer **variedades**: parejas concretas de esquema métrico y esquema de rima que
la tradición documenta, cuando no todas las parejas posibles se dan. Sin esa entidad, dos
listas independientes ofrecerían el producto cartesiano completo, la mayoría inexistente.

### Propiedades transversales

Además de lo que fija su norma, un pasaje puede presentar **propiedades sin posición fija que
aparecen en más de una forma**: la terminación esdrújula de sus versos, la presencia de versos
más breves que la medida dominante, el timbre concreto de una asonancia, el grado en que los
pareados organizan una serie.

No son parte del esquema, porque no ocupan una posición determinada, y no son formas, porque
no identifican nada por sí solas. Son propiedades predicables del tramo, y su valor está en
que **atraviesan formas distintas**: solo así se puede preguntar cuánto se parecen dos pasajes
que no comparten forma.

Una forma declara con qué **modalidad** interviene cada una: si la define, si es lo esperable,
si simplemente la admite o si es excepcional. Ahí vive el matiz cualitativo, y por eso no hace
falta traducir «mayoría» a umbrales inventados.

Cuando el matiz tiene grados, la propiedad declara **valores cerrados y ordenados** en vez de
una frase. Escribirla como texto libre la haría incomparable, porque cada forma inventaría su
manera de decirlo.

> **Prueba de que una propiedad está bien puesta: que dos formas distintas puedan nombrar el
> mismo valor.** Y prueba de contraste: si necesita una posición, no es una propiedad
> transversal sino parte del esquema. Una propiedad booleana repetida N veces para señalar qué
> posiciones cumplen algo es un esquema disfrazado.

### Verso libre y verso fluctuante

Son **formas**, no ausencia de forma.

- **Verso fluctuante**: la medida oscila alrededor de una norma sin fijarse, como en buena
  parte del verso medieval. Lo que la define es la oscilación misma, no su irregularidad.
- **Verso libre**: prescinde de medida fija y de rima, y organiza la unidad por otros medios
  —sintácticos, tipográficos, de repetición—.

Un proyecto puede decidir que un pasaje suyo no encaja en ninguna forma y registrarlo como
tramo sin norma reconocible. Eso es una categoría **operativa de ese proyecto**, no de la
métrica: dice que el análisis no llegó, no que el verso carezca de organización.

### Nombres y parentesco

Una **denominación** es otro nombre de algo ya formalizado, apuntando al nivel exacto que
nombra: una forma, una realización estructural, un esquema, una variedad. Declara además su
relación temporal con el objeto —un nombre aplicado retrospectivamente no equivale a uno
coetáneo— y su procedencia crítica, porque las escuelas no coinciden.

Una **tradición** es el ámbito histórico del que procede una forma. Es pertenencia, no
herencia, y una forma puede pertenecer a más de una: eso ya dice que nació en un ámbito y se
aclimató en otro.

Una **relación** es un vínculo tipado entre dos formas —taxonomía, composición, derivación,
sucesión histórica, contraste—. Ninguna convierte a una forma en padre de otra.

> **Dos criterios opuestos, y hacen falta los dos.** Un nombre tradicional no crea una forma:
> cuando la tradición nombra una realización concreta dentro de una forma que ya existe, eso
> es una variedad o una denominación. Pero la genealogía separa lo que la estructura acerca:
> dos formas pueden coincidir en extensión y rima y no ser la misma cosa si nacen de
> principios constructivos distintos. **El nombre no basta para separar, y la estructura no
> basta para unir.**

## 7 · Norma y realización

### Qué registra cada plano

| Plano | Contiene | TEI |
| --- | --- | --- |
| **Norma** | Lo que la forma fija y lo que admite | `@met` |
| **Realización** | Lo que el pasaje hace | `@real` |

Entre ambos hay tres relaciones posibles, y son distintas:

- **Variación admitida** — la norma prevé alternativas y el pasaje instancia una. Elegir
  `abba` en lugar de `abab` no es apartarse de nada.
- **Licencia** — una operación permitida sobre el cómputo o la pronunciación: sinéresis,
  diéresis, dialefa. Modifica la realización sin contradecir la norma.
- **Desviación** — lo que la norma no prevé y aun así ocurre. Se localiza por su rango y su
  dimensión, y la diferencia se deriva de la comparación: no hace falta una etiqueta que
  nombre cada tipo de discrepancia.

Hay además formas cuya norma **la fija su primera realización**: el esquema no está enumerado
de antemano, lo establece la primera unidad y las demás lo repiten. Reconocer la forma
consiste precisamente en comprobar esa repetición. No es variación admitida ni desviación: es
una norma declarada por el pasaje.

### Comparabilidad

> Un hecho de la realización debe quedar registrado **de la misma manera venga de donde
> venga**: de lo que la norma fija, de una variación instanciada o de una desviación
> observada. El origen es un dato más, no el camino que hay que recorrer para saber qué dice
> el pasaje.

Es la condición para que los recuentos signifiquen lo mismo entre corpus. Un registro que
guarde solo referencias a la norma obliga a resolverla en cada consulta, y esa resolución
acaba viviendo en el código de análisis, distinta cada vez.

De ahí que el grano natural de la realización sea el **verso**: es la unidad mínima común a
la medida, al ritmo, a la rima y a la posición estructural.

### Procedencia y certeza

Toda anotación métrica es interpretación, y algunas más que otras. La escansión de un verso
ambiguo, la clasificación de un perfil acentual o la decisión de dónde empieza una secuencia
admiten desacuerdo entre analistas competentes; los corpus anotados que publican su acuerdo
interanotador no llegan al cien por cien ni siquiera en tareas bien definidas.

La ontología prevé por tanto que cada hecho registrado pueda declarar **de dónde viene**
—norma, análisis humano, análisis automático— y **con qué certeza**. Que un proyecto decida
no preguntarlo es una decisión suya, no una propiedad del dominio.

## 8 · Correspondencias

### Con los estándares digitales

| Concepto de esta ontología | TEI | POSTDATA / OntoPoetry |
| --- | --- | --- |
| Norma de la forma | `@met`, `metDecl` | esquema métrico abstracto |
| Realización observada | `@real` | escansión, línea anotada |
| Esquema de rima | `@rhyme` | `Rhyme`, esquema de rima |
| Verso | `<l>` | `Line` |
| Unidad estrófica | `<lg>` | `Stanza` |
| Sílaba métrica | — | `Syllable` |
| Sinalefa | — | `Synaloepha` |
| Encabalgamiento | — | `Enjambment` |
| Denominación y sus variantes | — | capa terminológica SKOS |

TEI y RDF no son formatos rivales: la práctica establecida es conservar la codificación TEI
del corpus y transponerla o enriquecerla hacia RDF para la capa semántica.

### Con la tradición crítica hispánica

Los conceptos anteriores no son invención de este documento. Su formulación procede de una
tradición estratificada en la que conviene señalar quién fija qué:

| Obra | Qué aporta al modelo |
| --- | --- |
| Bello, *Principios de ortología y métrica* (1835) | La matriz de acento, cantidad y cláusula; la nomenclatura del endecasílabo |
| Benot, *Prosodia castellana y versificación* (1892) | El tratamiento sistemático del cómputo y de las licencias |
| Navarro Tomás, *Métrica española* (1956) | La síntesis histórico-descriptiva y la terminología del acento estrófico y los períodos rítmicos |
| Balbín, *Sistema de rítmica castellana* (1962) | El desplazamiento del foco hacia la rítmica y la cláusula |
| Quilis, *Métrica española* (1969) | La sistematización moderna del verso, la pausa y el encabalgamiento |
| Devoto (1995) | La microlexicografía de la rima |
| Domínguez Caparrós, *Métrica española* (2014) y *Métrica y poética* (2010) | El léxico actualizado y la reflexión metodológica explícita |

### Dónde no coinciden

Estas no equivalencias son parte del objeto y deben registrarse, no resolverse por decreto:

- **«Combinación»** designa en la tradición hispánica la estrofa misma; en otros usos, una
  operación sobre esquemas.
- **«Patrón métrico»** designa en la métrica computacional el patrón acentual del verso; en
  la tradición filológica, la sucesión de medidas.
- **«Cuarteta»** frente a **«redondilla»** distingue hoy dos disposiciones de rima que en el
  Siglo de Oro no se distinguían por el nombre.
- **Los límites de los perfiles acentuales** del endecasílabo varían entre escuelas.
- **«Verso libre»** tiene un alcance en la crítica del Siglo de Oro y otro, más amplio, en la
  contemporánea.

Por eso una denominación registra su procedencia crítica y su relación temporal con el
objeto, en vez de imponer una nomenclatura única.
