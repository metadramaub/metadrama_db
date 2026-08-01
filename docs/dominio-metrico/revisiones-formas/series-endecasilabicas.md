# Series endecasilábicas y pareado

Estado: revisado · 1 de agosto de 2026

## Las series

Las tres series de endecasílabos se ordenan sobre un mismo eje: **cuánto organizan los
pareados la serie**. Es un rasgo con valores cerrados, no un porcentaje.

| Forma | Organización en pareados |
| --- | --- |
| `endecasilabo_suelto` | ninguna u ocasionales |
| `silva` · arquitectura endecasilábica | habituales |
| `pareado` | regulares |

Cuando los pareados son sistemáticos ya no hay una serie que nombrar: hay N pareados.
`pareados_endecasilabos` era una serie cuya única sección se repetía, así que pasa al pareado
y cuántos contiene el pasaje se deriva del rango.

El endecasílabo suelto tiene **una sola arquitectura**. Antes tenía cinco, y lo único que las
separaba era una frase en prosa colgada de un esquema de rima vacío: eran el producto
cartesiano de dos booleanos —¿pareados intercalados? ¿dístico final?— más el encadenamiento
interior. Hoy los tres son rasgos catalogados y el editor los responde.

| Rasgo | Valores |
| --- | --- |
| `organizacion_en_pareados` | ninguna · ocasionales |
| `distico_final` | presente o no |
| `encadenamiento_interior` | presente o no |

Que sean rasgos catalogados y no frases significa que la respuesta del editor apunta a la
misma fila del catálogo que la norma de otra forma, y por tanto se puede comparar entre
secuencias. Su definición —predominan los versos sueltos y las rimas son minoritarias— pasa a
una restricción tipada `versos_sueltos = predominantes`, que decía lo mismo que dos literales
distintos y ahora es un solo hecho computable.

## El pareado

Un pareado es **cualquier dístico**: dos versos que riman entre sí, sea cual sea su medida.
Es una forma general, como el terceto o el sexteto, y como ellas puede formar series de las
que cada unidad se deriva del rango.

| Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | ---: |
| `cualquier_medida` | de 4 a 14 sílabas | `aa`, consonante o asonante | 2 |

Una sola arquitectura, porque no hay nada que distinguir: el pareado admite cualquier medida
y cualquiera de los dos tipos de rima. **El arte no se modela, se deriva del metro elegido**,
como en el resto del catálogo; separar arte menor de arte mayor habría aplicado aquí un
criterio que no se usa en ninguna otra forma, y además no separa regímenes de rima, porque el
endecasílabo suele ser consonante pero no lo exige.

**La medida no es arquitectura aquí, y es la única forma isosilábica del catálogo donde no lo
es.** En la redondilla, la sextilla, el sexteto o el romance el proyecto fija un repertorio
de medidas y cada una es una norma. El pareado no tiene repertorio: su norma dice que dos
versos riman y nada más, de modo que la medida la declara el pasaje y se pregunta.

La pregunta es posicional, con una respuesta por verso, para que el dístico heterométrico
—un heptasílabo y un endecasílabo, por ejemplo— se pueda registrar sin inventar una
arquitectura. El editor responde en el primer pareado y aplica a toda la tirada.

La disposición, en cambio, no admite variación: dos versos que riman solo pueden rimar entre
sí, así que el esquema es `aa`. Lo que se pregunta es el **tipo**, entre los dos esquemas
que la arquitectura declara.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `endecasilabo_suelto` | Forma `endecasilabo_suelto`, cinco arquitecturas |
| `silva--endecasilabica` | Arquitectura de `silva` |
| `pareado_de_arte_menor` | Arquitectura `cualquier_medida` |
| `pareado_hexasilabo` | Respuesta de medida |
| `pareado_octosilabo` | Respuesta de medida |
| `pareado_endecasilabo` | Respuesta de medida |
| `pareados_endecasilabos` | La misma arquitectura, con el rango como tirada |

Las cuatro entradas de medida —hexasílaba, octosílaba, endecasílaba y el arte menor
genérico— eran la misma dimensión repartida en niveles distintos: unas colgaban como
subtipos y otra como raíz. Hoy todas son respuestas posibles a la pregunta por la medida.

## Registrador

- **Endecasílabo suelto**: responder si hay pareados intercalados y marcar el dístico final
  o el encadenamiento interior si caracterizan la serie.
- **Silva endecasílaba**: responder cuánto organizan los pareados la serie.
- **Pareado**: elegir la medida de los dos versos del primer dístico y si riman en
  consonante o en asonante; aplicar a la tirada y cambiar solo los que difieran. El rango
  debe ser par.

## Demarcador

1. ¿Predominan los versos rimados o los sueltos?
2. ¿Cuánto organizan los pareados la serie?

Las preguntas se generan desde los rasgos almacenados en el catálogo, que ahora tienen
valores ordenados: basta con situar la serie en la escala. Si la organización es regular, la
salida es el pareado, cualquiera que sea su medida.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), p. 184, define el pareado como unidad
de dos versos; pp. 232-233 describen el verso suelto. El criterio cualitativo que separa las
series procede del IP, igual que la delimitación del pareado como cualquier dístico.

## Dudas para el IP

Ninguna imprescindible. El pareado se registra hoy con dos respuestas —medida y tipo de
rima— y no hay ningún repertorio cerrado que confirmar, porque la forma no lo tiene.
