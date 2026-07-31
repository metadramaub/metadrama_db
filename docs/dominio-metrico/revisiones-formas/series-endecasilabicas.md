# Series endecasilábicas y pareado

Estado: revisado · 31 de julio de 2026

## Las series

Dos series de endecasílabos se distinguen mediante dos rasgos observables, sin porcentajes.

| Forma | Predominan rimados | Pareados sistemáticos |
| --- | :---: | :---: |
| `endecasilabo_suelto` | No | No |
| `silva` · arquitectura endecasilábica | Sí | No |

Cuando los pareados son sistemáticos ya no hay una serie que nombrar: hay N pareados.
`pareados_endecasilabos` era una serie cuya única sección se repetía, así que pasa al
pareado y cuántos contiene el pasaje se deriva del rango.

El endecasílabo suelto mantiene cinco arquitecturas: con o sin pareados intercalados, con o
sin dístico final, y encadenamiento interior.

## El pareado

Un pareado es **cualquier dístico**: dos versos que riman entre sí, sea cual sea su medida.
Es una forma general, como el terceto o el sexteto, y como ellas puede formar series de las
que cada unidad se deriva del rango.

| Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | ---: |
| `arte_menor` · principal | de 4 a 8 sílabas | `aa`; el tipo no lo fija la norma | 2 |
| `arte_mayor` | de 11 a 14 sílabas | `AA` consonante | 2 |

**La medida no es arquitectura aquí, y es la única forma isosilábica del catálogo donde no
lo es.** En la redondilla, la sextilla, el sexteto o el romance el proyecto fija un
repertorio de medidas y cada una es una norma. El pareado no tiene repertorio: su norma dice
que dos versos riman y nada más, de modo que la medida la declara el pasaje y se pregunta.
Lo que sí es normativo es el **arte** —menor o mayor—, porque es el corte que la tradición
hace y el que se corresponde con el régimen de rima.

La pregunta es posicional, con una respuesta por verso, para que el dístico heterométrico
—un heptasílabo y un endecasílabo, por ejemplo— se pueda registrar sin inventar una
arquitectura. El editor responde en el primer pareado y aplica a toda la tirada.

La disposición, en cambio, no admite variación: dos versos que riman solo pueden rimar entre
sí, así que el esquema es `aa` y es fijo. Lo que queda abierto en el arte menor es el
**tipo** de rima, que la fuente heredada dejó marcado como «otras».

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `endecasilabo_suelto` | Forma `endecasilabo_suelto`, cinco arquitecturas |
| `silva--endecasilabica` | Arquitectura de `silva` |
| `pareado_de_arte_menor` | Arquitectura `arte_menor` |
| `pareado_hexasilabo` | Respuesta de medida dentro de `arte_menor` |
| `pareado_octosilabo` | Respuesta de medida dentro de `arte_menor` |
| `pareado_endecasilabo` | Arquitectura `arte_mayor` |
| `pareados_endecasilabos` | La misma arquitectura `arte_mayor` |

Las dos entradas hexasílaba y octosílaba eran subtipos del pareado de arte menor, es decir
dos medidas concretas dentro de un rango: hoy son dos respuestas posibles a la pregunta por
la medida, no dos arquitecturas.

## Registrador

- **Endecasílabo suelto**: elegir la arquitectura registra directamente la presencia de
  pareados, dístico final o encadenamiento interior; no se repiten esas preguntas.
- **Silva endecasílaba**: queda descrita por su arquitectura.
- **Pareado**: elegir arte menor o mayor y la medida de los dos versos del primer dístico;
  aplicar a la tirada y cambiar solo los que difieran. El rango debe ser par.

## Demarcador

1. ¿Predominan los versos rimados?
2. ¿La serie está organizada sistemáticamente en pareados?

Las preguntas se generan desde los rasgos almacenados en el catálogo. Los detalles del
endecasílabo suelto solo aparecen si aún hace falta distinguir sus arquitecturas. Si la
respuesta a la segunda es que sí, la salida es el pareado y la medida decide el arte.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), p. 184, define el pareado como unidad
de dos versos; pp. 232-233 describen el verso suelto. El criterio cualitativo que separa las
series procede del IP, igual que la delimitación del pareado como cualquier dístico.

## Dudas para el IP

1. ¿El pareado de arte menor admite rima asonante además de consonante? El vocabulario
   heredado dejó su tipo de rima como «otras» y el modelo lo conserva sin declarar; si la
   norma exige consonancia, basta con declararla.
2. ¿El arte mayor del pareado debe limitarse al endecasílabo o conviene mantener abierto el
   rango a dodecasílabos y alejandrinos, que hoy se ofrecen?
