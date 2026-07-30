# Romance

Estado: revisado · 29 de julio de 2026

## Decisión

Una sola forma con cuatro configuraciones exactas de metro. Todas comparten la serie
abierta, la asonancia en los versos pares y los impares sueltos. Las vocales concretas
de la asonancia son valores de un rasgo registrable, no subformas.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `romance` · serie |
| Configuración principal | `octosilabico_asonante` · 8 sílabas |
| Configuración menor | `hexasilabico_romancillo` · 6 sílabas |
| Configuración menor | `heptasilabico_romancillo` · 7 sílabas |
| Configuración heroica | `endecasilabico_heroico` · 11 sílabas |
| Rima | asonante en los versos pares |
| Versos impares | sueltos |
| Ciclo | `-A` repetido |
| Rasgo | `vocales_asonancia` |

## Registrador

La configuración octosilábica se selecciona por defecto. El editor solo cambia la
configuración si observa 6, 7 u 11 sílabas; después elige las vocales de la asonancia y
guarda. El rango debe contener un número par de versos. Una ruptura puntual de la
alternancia se registra como desviación de rima.

## Demarcador

Identifica la forma mediante la alternancia entre impares sueltos y pares asonantados;
la medida distingue las configuraciones hexasílaba, heptasílaba, octosilábica y
heroica. Las vocales concretas describen la realización, pero no son necesarias para
identificarla.

## Trazabilidad

Los antiguos hijos `romance_*` conservan su origen en los valores normalizados de
`vocales_asonancia`. Las antiguas formas `romance_heroico` y `romancillo` dejan de
duplicar la arquitectura de romance. Los hijos exactos conservan sus UUID como origen
de las configuraciones; la raíz ambigua `romancillo` queda pendiente de revisión solo
para la futura migración de secuencias.
