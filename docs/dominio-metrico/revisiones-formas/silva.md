# Silva

Estado: revisada, pendiente de una precisión terminológica · 1 de agosto de 2026

## Decisión

Una forma de nivel serie y tres arquitecturas. No se crea una familia `silva`.

| Arquitectura | Metro | Rima | Pareados |
| --- | --- | --- | --- |
| `consonante_irregular` · principal | 7 y 11 sin orden fijo | consonante de orden libre | predominantes |
| `libre` | 7 y 11 sin orden fijo | consonante de orden libre | **ninguno** |
| `consonante_regular` | ciclo `7 + 11` | `aA \| bB \| cC \| …` | regulares |
| `endecasilabica` | 11 | consonante, pareados no sistemáticos | habituales |

La forma es una serie abierta, no estrófica, con rima consonante y posibilidad de versos
sueltos. En la regular, un verso suelto es una desviación; en las demás puede formar parte
de la norma.

## Cuánto organizan los pareados es un rasgo, no una arquitectura

La **silva libre** es la más irregular: no se organiza en pareados y, si aparece alguno, es un
caso aislado. Es la que el editor elige cuando lo que encuentra no encaja con ninguna de las
otras.

Y por eso vuelve a ser arquitectura propia. Se había fundido con la irregular porque solo las
separaba una frase en prosa; hoy el grado de organización en pareados es un rasgo con valores
catalogados, así que la distinción es computable. Además hacía falta que viviera ahí: «Silva
libre» es un nombre de la tradición, y una denominación **no puede apuntar al valor de un
rasgo**, solo a una forma, una arquitectura, un esquema o una variedad.

Cada arquitectura declara su grado como rasgo definitorio en lugar de preguntarlo:

| Valor | Qué dice |
| --- | --- |
| `ninguna` | La serie no se organiza normativamente mediante pareados |
| `habituales` | Los pareados son frecuentes, aunque no obligatorios |
| `predominantes` | Los pareados organizan predominantemente la serie |
| `regulares` | La serie se organiza sistemáticamente en pareados |

`organizacion_en_pareados` es un rasgo transversal con valores cerrados, y su escala corre
por tres formas: el endecasílabo suelto ocupa el extremo bajo —ninguna u ocasionales—, la
silva el centro, y la tirada de pareados el extremo alto. Que sea un rasgo catalogado y no
una frase significa que la respuesta del editor apunta a la misma fila que la norma de otra
forma, y por tanto se puede comparar entre secuencias.

La regular lo tenía ya declarado así: su alternancia `7 + 11` y su esquema `aA | bB | cC` lo
fijan, y fue la única de las cuatro que nunca dependió de un literal.

## Registrador

El editor elige la arquitectura y responde cuánto organizan los pareados la serie, salvo en
la regular, donde no se pregunta nada. Solo la regular exige un número par de versos por su
ciclo `7 + 11`; en ella un verso suelto o una ruptura del orden se registra como desviación.

## Demarcador

Pregunta por las medidas, por la organización en pareados y, si corresponde, por el orden
`7 + 11`. No pide porcentajes: el rasgo tiene valores nombrados y ordenados, que es lo que
sustituye a los umbrales del vocabulario heredado.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `silva` | Forma `silva` |
| `silva--consonantes-regular` | Arquitectura `consonante_regular` |
| `silva--consonantes-irregular` | Arquitectura `consonante_irregular` |
| `silva--libre` | Arquitectura `libre`, con «Silva libre» como denominación |
| `silva--endecasilabica` | Arquitectura `endecasilabica` |

Las denominaciones del IP se conservan mediante `origen_termino_id`. En la comprobación del
28 de julio de 2026 no había secuencias asociadas.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 227-228: combinación asimétrica de
endecasílabos, o endecasílabos y heptasílabos, con consonancia libre y posibles versos
sueltos. Paraíso, «Arcadio Pardo y la Teoría Métrica», *Rhythmica* 20-21, documenta un uso
moderno más amplio de «silva libre».

## Dudas para el IP

Ninguna pendiente. **Resuelto:** la silva libre tiene el alcance específico del corpus —siete
y once, consonancia al arbitrio del poeta, versos sueltos admitidos y sin organización en
pareados—, y es la arquitectura que el editor elige cuando lo observado no encaja con las
demás.
