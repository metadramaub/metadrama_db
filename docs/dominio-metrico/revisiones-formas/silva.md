# Silva

Estado: revisada, pendiente de una precisión terminológica · 1 de agosto de 2026

## Decisión

Una forma de nivel serie y tres arquitecturas. No se crea una familia `silva`.

| Arquitectura | Metro | Rima |
| --- | --- | --- |
| `consonante_irregular` · principal | 7 y 11 sin orden fijo | consonante de orden libre |
| `consonante_regular` | ciclo `7 + 11` | `aA \| bB \| cC \| …` |
| `endecasilabica` | 11 | consonante, pareados no sistemáticos |

La forma es una serie abierta, no estrófica, con rima consonante y posibilidad de versos
sueltos. En la regular, un verso suelto es una desviación; en las demás puede formar parte
de la norma.

## Cuánto organizan los pareados es un rasgo, no una arquitectura

Antes había cuatro arquitecturas y dos de ellas —`libre` y `consonante_irregular`— no se
distinguían por nada computable: las separaba una frase en prosa colgada de su esquema de
rima. Hoy ambas son la misma arquitectura, y el grado se responde:

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

La arquitectura regular no pregunta: declara `regulares` como rasgo definitorio, porque su
alternancia `7 + 11` y su esquema `aA | bB | cC` ya lo fijan. Fue la única de las cuatro que
nunca dependió de un literal.

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
| `silva--consonantes-irregular` | Arquitectura `consonante_irregular`, valor `predominantes` |
| `silva--libre` | La misma arquitectura, valor `ninguna` |
| `silva--endecasilabica` | Arquitectura `endecasilabica`, valor `habituales` |

Las denominaciones del IP se conservan mediante `origen_termino_id`. En la comprobación del
28 de julio de 2026 no había secuencias asociadas.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 227-228: combinación asimétrica de
endecasílabos, o endecasílabos y heptasílabos, con consonancia libre y posibles versos
sueltos. Paraíso, «Arcadio Pardo y la Teoría Métrica», *Rhythmica* 20-21, documenta un uso
moderno más amplio de «silva libre».

## Dudas para el IP

1. ¿`silva libre` tiene deliberadamente el alcance específico del corpus —7 y 11,
   consonancia libre— o pretende coincidir con la categoría moderna más amplia?
2. La silva libre deja de ser una arquitectura y pasa a ser el valor `ninguna` del rasgo.
   **El modelo no permite hoy que una denominación apunte a un valor de rasgo**, solo a una
   forma, arquitectura, esquema, variedad o sección, así que ese nombre no queda registrado
   en ninguna parte. ¿Hace falta que lo esté?
