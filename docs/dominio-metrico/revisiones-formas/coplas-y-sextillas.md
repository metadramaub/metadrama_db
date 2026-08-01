# Coplas y sextillas

Estado: revisado, con decisiones del proyecto por confirmar · 1 de agosto de 2026

## Decisión general

«Copla» no nombra una familia. El catálogo reparte lo que el vocabulario anterior
amontonaba bajo esa palabra en cuatro formas, y coloca cada hecho en el nivel que le
corresponde: lo que la norma fija y no varía dentro de una secuencia es **arquitectura**;
lo que varía de una unidad a otra es una **pregunta** al editor; una propiedad transversal
es un **rasgo**; y un nombre que la tradición dio a una realización concreta es una
**denominación**, no una forma.

Las formas son:

- `copla_de_arte_mayor`;
- `copla_de_pie_quebrado`, general;
- `copla_real`;
- `sextilla`.

`pie_quebrado` es un rasgo transversal: lo declaran todas las arquitecturas que incorporan
versos más breves que su medida dominante, sin que eso las emparente entre sí.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `copla_de_arte_mayor` | Forma `copla_de_arte_mayor` |
| `copla_de_arte_mayor_tipo_1_ABBAACCA` | Esquema de rima `ABBAACCA` |
| `copla_de_arte_mayor_tipo_2_ABBACDCD` | Esquema de rima `ABBACDCD` |
| `copla_de_arte_mayor_tipo_3_ABABCDCD` | Esquema de rima `ABABCDCD` |
| `copla_de_pie_quebrado` | Forma general `copla_de_pie_quebrado` |
| `copla_real` | Forma `copla_real` |
| `copla_real_sin_quebrado` | Arquitectura `octosilabica_consonante` |
| `copla_real_de_pie_quebrado` | La misma arquitectura, con el rasgo `pie_quebrado` admitido |
| `sextilla` | Forma `sextilla` |
| `sextilla_sin_quebrado` | Arquitecturas `octosilabica`, `heptasilabica` y `hexasilabica` |
| `sextilla_de_pie_quebrado` | Arquitectura `pie_quebrado` + rasgo |
| `doble_sextilla` | Arquitectura `doble_pie_quebrado` de la sextilla |
| `doble_sextilla_alternativa` | Esquema `consonante-variable` de esa arquitectura |
| `copla_manriqueña` | Denominación del esquema `abcabc:defdef` de esa arquitectura |

Ni la doble sextilla ni la copla manriqueña son ya formas. Doce versos en dos sextillas de
pie quebrado son una arquitectura de la sextilla, igual que la doble enlazada lo es de la
redondilla; y «copla manriqueña» es el nombre que la tradición dio a esa arquitectura
cuando responde `abcabc:defdef`, que es exactamente lo que una denominación existe para
decir.

## Formas y arquitecturas

| Forma | Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | --- | ---: |
| Copla de arte mayor | `dodecasilabica_compuesta` | 8 × `6 + 6` | consonante; tres esquemas admitidos | 8 |
| Copla de pie quebrado | `octosilabica_con_quebrados` | octosílabos y quebrados de 4 a 7 | consonante, disposición abierta | 5–12 |
| Copla real | `octosilabica_consonante` | 10 × 8, con uno o dos quebrados posibles | esquema de cada quintilla | 10 |
| Sextilla | `octosilabica` | 6 × 8 | consonante, disposición abierta | 6 |
| Sextilla | `heptasilabica` | 6 × 7 | consonante, disposición abierta | 6 |
| Sextilla | `hexasilabica` | 6 × 6 | consonante, disposición abierta | 6 |
| Sextilla | `pie_quebrado` | `8-8-4-8-8-4` | consonante, disposición abierta | 6 |
| Sextilla | `doble_pie_quebrado` | `8-8-4` × 4 | consonante; `abcabc:defdef` es la manriqueña | 12 |

La sextilla es isosilábica, así que su medida no puede cambiar a mitad de una tirada: es
arquitectura y no pregunta, en paralelo exacto con la redondilla y el romance. Su rima es
consonante y su disposición abierta: es una estrofa general y no tiene repertorio cerrado
de esquemas, de modo que el esquema declara el tipo de rima y deja libre el orden.

La copla de arte mayor conserva sus tres esquemas y su modelo de verso `6 + 6` referencia
también el metro dodecasílabo: el demarcador puede encontrarla como dodecasílaba mientras
los segmentos conservan su estructura compuesta.

## La copla real es una sola arquitectura

Llevar o no llevar quebrados no cambia la norma: son diez octosílabos en dos quintillas, y
uno o dos de esos versos pueden ser más breves. Eso es un rasgo **admitido**, no una
arquitectura distinta, así que las dos que hubo se han fundido en una.

Sus dos secciones de cinco versos no copian el repertorio de la quintilla: lo reutilizan
mediante `arquitectura_referenciada_id`, y sus preguntas ofrecen los ocho esquemas desde su
origen. El repertorio se mantiene en un solo sitio.

Y **tampoco declara su propio metro**: la copla real es octosilábica precisamente por ser dos
quintillas, y sus dos secciones cubren sus diez versos. La copla real es además la única forma
del catálogo que declara `compuesta_por`, porque es la única que efectivamente se formó
sumando otra estrofa.

Dónde caen los quebrados no lo fija la norma: lo observa el editor. Se pregunta como
medida de una posición —«el verso 3 es tetrasílabo»— y no como diez casillas sueltas que no
se ligan con ninguna medida.

## Lo abierta que es la copla de pie quebrado

Es la forma **general** del quebrado: la salida para las coplas que combinan octosílabos con
versos más breves y no encajan en ninguna forma más específica. El vocabulario heredado lo
decía literalmente —«en esta categoría encajarían todas aquellas que no correspondan con la
sextilla de pie quebrado, la copla manriqueña y la doble sextilla»— y por eso su grado de
especificación es **general**.

Su norma fija muy poco, y conviene tener presente cuánto:

| Dimensión | Qué fija |
| --- | --- |
| Unidad | **de 5 a 12 versos**, y lo dice el pasaje |
| Metro | conjunto de 4 a 8 sílabas; el octosílabo domina y los quebrados son su mitad |
| Rima | consonante, disposición **abierta** |
| Secciones | ninguna |

De ahí sale su pregunta: **48 opciones**, doce posiciones por cuatro medidas, generadas para
el caso máximo porque el catálogo no puede saber cuántos versos tendrá cada copla.

**Esa apertura tiene un precio y hay que conocerlo.** Como la unidad es un rango y las
opciones cubren el máximo, el catálogo por sí solo no puede impedir que se responda sobre un
verso que no existe —«el verso 11 es tetrasílabo» en una copla de cinco— ni que se den dos
medidas distintas para la misma posición. Es la única forma del catálogo con unidad variable
y opciones posicionales, así que es la única que puede desbordar.

La comprobación no cabe en el catálogo, donde la unidad es un rango: solo es posible **al
guardar**, cuando ya se sabe cuántos versos tiene esa realización concreta. Ahí es donde
está, en un disparador sobre las elecciones.

## El rasgo `pie_quebrado`

| Arquitectura | Modalidad |
| --- | --- |
| Copla de pie quebrado · `octosilabica_con_quebrados` | definitoria |
| Copla real · `octosilabica_consonante` | admitida |
| Sextilla · `pie_quebrado` | definitoria |
| Sextilla · `doble_pie_quebrado` | definitoria |

El editor no lo activa a mano: se deriva de la arquitectura, y solo se le piden los datos
que concretan la realización observada.

## Registrador

- **Copla de arte mayor**: elegir uno de los tres esquemas **en cada copla**. Los tres
  alternan de estrofa en estrofa; si toda la tirada usa el mismo, la respuesta se aplica a
  todas.
- **Copla de pie quebrado**: indicar la extensión de cada unidad, entre 5 y 12 versos, y
  señalar qué versos son quebrados y con qué medida, entre 4 y 7 sílabas. El resto son
  octosílabos y debe quedar al menos uno.
- **Copla real**: escoger de manera independiente el esquema de cada quintilla y, si los
  hay, marcar una o dos posiciones tetrasílabas. Elegir el mismo esquema en las dos mitades
  no afirma que compartan timbres.
- **Sextilla**: elegir la arquitectura; nada más se pregunta, salvo en la doble, donde se
  marca la disposición manriqueña si es la observada y se deja vacío si es otra regular.

La extensión se valida por unidades: 8 versos la copla de arte mayor, 10 la copla real, 6
la sextilla, 12 la doble y de 5 a 12 cada copla de pie quebrado.

## Demarcador

Distingue seis, ocho, diez y doce versos; isometría frente a combinaciones de octosílabos y
quebrados; la copla real por su estructura `5 + 5`; en doce versos, `abcabc:defdef` frente
a otra disposición regular; y la copla de arte mayor por sus ocho dodecasílabos compuestos.

Las posiciones exactas de los quebrados y los esquemas internos de una copla real son datos
analíticos del registrador, no las primeras preguntas del demarcador. La copla de pie
quebrado no interviene en el cálculo ordinario: solo se ofrece cuando las respuestas
descartan las formas más específicas compatibles.

## Fuentes

José Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 196–201. Define la sextilla
como estrofa de seis versos de arte menor con rima consonante; caracteriza la estrofa
manriqueña como `8a 8b 4c 8a 8b 4c`; admite su consideración como unidad de doce versos
cuando el sentido enlaza dos sextillas, manteniendo distintas sus rimas; y describe la
copla de arte mayor como ocho versos distribuidos en dos cuartetos.

Maximiano Trapero, «La primera copla real en la poesía castellana», *Analecta Malacitana*,
39.1-2 (2016-2017), pp. 27–61. Caracteriza la copla real por la doble quintilla, la pausa
`5 + 5`, la variabilidad de las rimas y la independencia estructural de sus dos mitades.

María Victoria Utrera Torremocha, «Métrica y poética en “Nocturno yanqui”, de Luis
Cernuda», *Rhythmica*, 3-4 (2006), pp. 283–303. Documenta la relevancia de la posición de
los versos cortos en las formas de pie quebrado.

## Dudas para el IP

1. ¿La sextilla de pie quebrado es exactamente `8-8-4-8-8-4`? La bibliografía documenta
   también sextillas heterométricas con otra distribución.
2. ¿Las medidas 6, 7 y 8 forman un repertorio cerrado para la sextilla isométrica?
3. **Nada en el modelo distingue dos sextillas consecutivas de una doble sextilla.** Los
   versos, las medidas y el tipo de rima son los mismos; solo cambia si las rimas de la
   segunda mitad dependen de la primera. Hoy lo afirma el editor al elegir arquitectura.
   ¿Debe seguir siendo así o hay un criterio observable que lo decida?
4. ¿Debe registrarse el esquema exacto de las dobles sextillas no manriqueñas?
5. ¿Los tres esquemas de copla de arte mayor son un repertorio cerrado? Que alternen entre
   coplas de una misma tirada ya está resuelto: la pregunta es por unidad.
6. ¿Los quebrados de la copla real pueden ocupar cualquiera de sus diez posiciones, y solo
   tetrasílabos o también pentasílabos?
7. ¿Copla de arte menor y copla castellana se incorporarán solo si aparecen en el corpus?
