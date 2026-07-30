# Versificación irregular y verso aislado

Estado: revisado con los datos del proyecto y bibliografía · 30 de julio de 2026

## Decisión

No son formas métricas. Son tramos sin forma que comparten el
selector con las formas por razones operativas, pero se distinguen mediante
`formas_metricas.tipo_registro = salida_editorial`.

| Salida | Uso | Extensión |
| --- | --- | ---: |
| `irregular` · Versificación irregular | El pasaje no conserva una identidad del catálogo reconocible | 2 o más versos |
| `verso_aislado` · Verso aislado | El verso no pertenece a la forma anterior ni a la siguiente | exactamente 1 verso |

Ninguna tiene configuración, patrones, norma, unidades ni desviaciones. Una observación
general es opcional.

## Límite con las desviaciones

```text
¿Se reconoce todavía una forma?
├── Sí → forma + configuración + desviaciones localizadas
└── No
    ├── un solo verso no agrupable → Verso aislado
    └── dos o más versos → Versificación irregular
```

Una redondilla con un verso hipométrico sigue siendo redondilla. Una tirada que solo
recuerda vagamente una redondilla y exige convertir casi todos sus versos en excepciones
se registra como Versificación irregular. Las desviaciones explican diferencias respecto
de una norma reconocible; un tramo sin forma declara que no existe tal norma para ese
tramo.

## Terminología

`Verso suelto` no es un buen nombre para la salida de un único verso. En la descripción
métrica puede significar:

- una posición sin correspondencia de rima dentro de un patrón;
- una serie de versos sin rima, también llamada verso blanco.

El catálogo ya representa el primer sentido mediante `patron_rima_posiciones.suelto` y
el segundo mediante las series endecasilábicas sin rima. La salida heredada pasa por ello
a llamarse `Verso aislado`; `Verso suelto` se conserva solo como denominación histórica
para migrar los datos existentes.

## Arte mayor, menor o mixto

Los antiguos hijos `irregular_arte_mayor`, `irregular_arte_menor` e
`irregular_mixto` no son formas ni configuraciones. Todos migrarán a Versificación
irregular. La clase de arte se conservará como observación si solo existe el dato legado
o se derivará de las medidas observadas cuando estén disponibles. El editor no responde
una pregunta adicional si el sistema ya puede calcularlo.

## Registrador

Recorridos mínimos:

```text
Versificación irregular → delimitar al menos dos versos → guardar
Verso aislado            → indicar el verso → guardar
```

El selector separa visualmente las formas de las salidas «Solo si no encaja en una
forma». En Verso aislado, el verso final se mantiene igual al inicial.

## Demarcador y análisis

Los tramos sin forma no intervienen en las preguntas ni en las distancias entre
formas. Solo aparecen cuando ya no queda una candidata ordinaria y no se incluyen en los
recuentos de diversidad de formas. Sí pueden contabilizarse por separado como cobertura
residual del corpus.

La copla de pie quebrado sigue siendo una forma, general pero plena: conserva una estructura
positiva formalizable. La distinción `tipo_registro` evita confundir ese caso con estas
dos salidas sin norma.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014:

- p. 159: distingue la versificación irregular o anisosilábica de la regular;
- p. 232: usa verso suelto, libre o blanco para una serie de versos sin rima.

La bibliografía justifica la distinción terminológica. Los dos tramos sin forma y su
límite de uso son una decisión metodológica del proyecto.

## Duda para el IP

Confirmar si `Verso aislado` debe ser la etiqueta pública definitiva. El cambio no altera
la migración: el término legado `verso suelto` conserva toda su trazabilidad.
