# Romance heroico

Estado: revisado con los datos del proyecto y bibliografía · 30 de julio de 2026

## Decisión

El romance heroico no se conserva como forma independiente. Es la configuración
endecasílaba, canónica y lexicalizada de `romance`.

Comparte con el romance octosilábico toda su arquitectura:

| Elemento | Valor |
| --- | --- |
| Forma | `romance` · serie |
| Configuración | `endecasilabico_heroico` |
| Metro | 11 sílabas |
| Rima | asonante en los versos pares |
| Versos impares | sueltos |
| Ciclo | `-A` repetido |
| Denominación equivalente del proyecto | Romance real |
| Elección observada | `vocales_asonancia` |

La única diferencia definitoria respecto de la configuración prototípica del romance
es el metro. Una denominación asentada no obliga a duplicar la forma, sus patrones ni
la pregunta editorial.

## Registrador

El recorrido mínimo es:

```text
Romance → Romance heroico → vocales de la asonancia → guardar
```

Al elegir `Romance`, el registrador selecciona por defecto la configuración principal
octosilábica. El editor solo cambia el desplegable a `Romance heroico` cuando observa
endecasílabos. La rima en pares, los impares sueltos y el metro se derivan.

El rango debe contener un número par de versos. Una medida distinta o una ruptura
puntual de la alternancia se registra como desviación.

## Demarcador

El demarcador compila las configuraciones métricas de una misma forma:

```text
Romance
├── Romancillo hexasílabo: 6 sílabas + -A repetido
├── Romancillo heptasílabo: 7 sílabas + -A repetido
├── Octosilábico:          8 sílabas + -A repetido
└── Heroico:              11 sílabas + -A repetido
```

La medida separa ambas realizaciones. Las vocales concretas de la asonancia se guardan
para búsqueda y análisis, pero no son necesarias para identificar la configuración.

## Trazabilidad

```text
romance_heroico → FORMA Romance
                  └── CONFIGURACIÓN Romance heroico
                      └── DENOMINACIÓN Romance real
```

El UUID anterior deja de identificar una forma duplicada y se conserva como origen de
la configuración. La futura migración de secuencias podrá reconstruir exactamente
`forma = romance` y `configuración = endecasilabico_heroico`.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 226:
«El romance en versos de once sílabas se llama romance heroico».

La denominación `romance real` se conserva por el criterio ya incorporado por el IP;
no se atribuye a esta fuente.

## Dudas para el IP

Ninguna. `Romance real` se conserva como denominación equivalente según el criterio ya
incorporado por el IP.
