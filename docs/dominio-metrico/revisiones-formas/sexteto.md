# Sexteto

Estado: revisado con los datos del proyecto y bibliografía · 1 de agosto de 2026

## Decisión

Una forma general de seis versos de arte mayor con rima consonante, repartida por medidas.
La sexta rima no es otra forma: es una variedad reconocida de su arquitectura
endecasilábica.

| Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | ---: |
| `endecasilabica` · principal | 6 × 11 | consonante, disposición abierta | 6 |
| `dodecasilabica` | 6 × 12 | consonante, disposición abierta | 6 |
| `alejandrina` | 6 × 14 | consonante, disposición abierta | 6 |

La medida es arquitectura y no pregunta: el sexteto es una unidad estrófica isosilábica y
no cambia de metro a mitad de tirada. Si cambia, o empieza otra secuencia o hay un
anisosilabismo que se registra como desviación.

La disposición, en cambio, sí queda abierta. El sexteto es una estrofa **general**: la
norma exige consonancia y no fija el orden de las rimas, de modo que el esquema declara el
tipo de rima y deja libre la distribución. No se registra un repertorio de posibilidades
cerradas porque la bibliografía no lo reconoce.

## La sexta rima es una variedad

| Elemento | Valor |
| --- | --- |
| Arquitectura | `sexteto · endecasilabica` |
| Esquema métrico | `11-11-11-11-11-11` |
| Esquema de rima | `ABABCC` |
| Denominaciones | «Sexta rima», «Sexteto clásico» |

Los cuatro primeros versos alternan dos clases de rima y los dos últimos forman un pareado.
Como no añade ninguna norma que la arquitectura no tenga ya —seis endecasílabos
consonantes—, sino que **concreta** una de sus realizaciones y le pone nombre, vive donde
viven las realizaciones con nombre: en `variedades_arquitectura`, con sus dos
denominaciones. El vocabulario anterior la registraba como forma `sexta_rima`, subtipo del
sexteto.

## Registrador

```text
Sexteto → medida (arquitectura) → esquema observado → guardar
```

El rango debe ser múltiplo de seis. Se anota un esquema de seis posiciones, por ejemplo
`AABCCB`: una respuesta abierta controlada donde se eliminan los espacios, las letras se
normalizan y se exige exactamente una posición por verso. No se crea un esquema nuevo en el
catálogo por cada observación.

El editor responde en la primera unidad y puede aplicar la respuesta a todas; solo cambia
las que difieran. Cuando lo observado es `ABABCC`, la interfaz puede mostrar que esa
realización se llama sexta rima.

## Demarcador

El sexteto se ofrece cuando quedan unidades de seis versos de arte mayor con rima
consonante y ninguna forma más precisa las explica. La medida distingue entre sus tres
arquitecturas. El esquema concreto se registra después de identificar la categoría: no hace
competir entre sí una cantidad indeterminada de disposiciones.

## Relación con el sexteto-lira

El [sexteto-lira](./sexteto-lira.md) no es una arquitectura del sexteto ni una variedad
suya. Combina heptasílabos y endecasílabos, de modo que su heterometría no es una medida
más sino su principio constructivo; y desciende de la lira garcilasiana, no del sexteto.
Esa genealogía está declarada en el modelo como `sexteto_lira derivada_de lira`.

No se crea una familia de «estrofas de seis versos»: la extensión ya puede consultarse como
dato y no justifica por sí sola una agrupación ontológica.

## Fuentes

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 198: llama sexteto a la
estrofa de seis versos de arte mayor o de arte mayor y menor combinados; p. 199 define la
sexta rima como sexteto de seis endecasílabos con esquema `ABABCC`.

El proyecto aplica una delimitación más estricta que la primera, fijada por el IP para el
corpus: seis versos de arte mayor con rima consonante y disposición variable. La fuente se
conserva como contraste general y no sobrescribe ese criterio.

## Dudas para el IP

1. Si el corpus documenta un sexteto que combine arte mayor y menor y no sea sexteto-lira,
   ¿se amplía la forma o se crea otra?
2. ¿Las medidas 11, 12 y 14 forman un repertorio cerrado?
