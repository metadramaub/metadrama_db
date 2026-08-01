# Romance

Estado: revisado · 1 de agosto de 2026

## Decisión

Una sola forma con **cuatro arquitecturas que solo se distinguen por la medida**. Todas
comparten la serie abierta, la asonancia en los versos pares y los impares sueltos. Las
vocales concretas de la asonancia son un rasgo observado, no subformas.

| Arquitectura | Metro | Nombre tradicional |
| --- | ---: | --- |
| `octosilabico` · principal | 8 | Romance |
| `hexasilabico` | 6 | Romancillo hexasílabo |
| `heptasilabico` | 7 | Romancillo heptasílabo · Endecha |
| `endecasilabico` | 11 | Romance heroico · Romance real · Romance mayor |

El romance es isosilábico, así que la medida es arquitectura y no pregunta. Y como ninguna
de las cuatro cambia nada más —el ciclo de rima es el mismo `-a-a-a…` en las cuatro—, lo que
las separa es exactamente un dato.

**Ni el romancillo ni el romance heroico son formas.** Un nombre tradicional asentado no
obliga a duplicar la forma, sus esquemas ni la pregunta editorial: vive como denominación de
la arquitectura que nombra.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `romance` | Forma `romance`, arquitectura `octosilabico` |
| `romance_e-a`, `romance_a-o`… | Valores del rasgo `vocales_asonancia` |
| `romance_heroico` | Arquitectura `endecasilabico` |
| `romancillo` | Raíz ambigua: se retira |
| `romancillo_hexasilabo` | Arquitectura `hexasilabico` |
| `romancillo_heptasilabo` | Arquitectura `heptasilabico` |

La raíz `romancillo` mezclaba las dos medidas y por eso no tiene destino: queda marcada para
la futura migración de secuencias, donde un registro que no permita conocer la medida **no se
asignará por conjetura**.

## Denominaciones

| Arquitectura | Denominaciones |
| --- | --- |
| `hexasilabico` | Romancillo hexasílabo |
| `heptasilabico` | Romancillo heptasílabo · Endecha · Romance endecha |
| `endecasilabico` | Romance heroico · Romance real · Romance mayor |

**«Endecha» y «Romance endecha» nombran el heptasílabo, no el hexasílabo.** Estaban en las dos
medidas menores y era un error: el romance de seis o menos sílabas es el romancillo, y el de
siete admite los dos nombres.

Todas están registradas, incluidas las tres del endecasílabo: un nombre que no vive en ninguna
parte deja de ser recuperable, y eso incumpliría el principio de asignabilidad.

De la endecha heptasílaba deriva además una forma aparte, la
[endecha real](./endecha-real.md), que rompe la serie introduciendo un endecasílabo al cerrar
cada estrofa de cuatro versos.

## Registrador

```text
Romance → medida → vocales de la asonancia → guardar
```

La octosilábica se ofrece por defecto. El editor solo cambia la arquitectura si observa 6, 7
u 11 sílabas. El metro, la asonancia en los pares y los impares sueltos se derivan; el rango
debe contener un número par de versos, y una ruptura puntual de la alternancia se registra
como desviación de rima.

## Demarcador

Identifica la forma por la alternancia entre impares sueltos y pares asonantados; la medida
distingue las cuatro arquitecturas.

```text
Romance
├── hexasilábico   6 sílabas + -a repetido
├── heptasilábico  7 sílabas + -a repetido
├── octosilábico   8 sílabas + -a repetido
└── endecasilábico 11 sílabas + -a repetido
```

Las vocales concretas describen la realización pero no hacen falta para identificarla. Esto
permite agrupar por forma para estudiar todos los romances, y por arquitectura para
distinguir sus realizaciones.

## Fuentes

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 226: «El romance en
versos de once sílabas se llama romance heroico»; pp. 226–227 denomina `endecha` al romance
heptasílabo y `romancillo` al romance de menos de siete sílabas.

El proyecto conserva el criterio incorporado por el IP, que usa «Romancillo» para las dos
medidas menores y «Romance real» junto a «Romance heroico». La divergencia queda documentada
sin sobrescribir el criterio del corpus.

## Dudas para el IP

Ninguna pendiente. **Resuelto:** «Endecha» y «Romance endecha» corresponden al heptasílabo;
el hexasílabo es el romancillo; y el endecasílabo lleva «Romance heroico», «Romance real» y
«Romance mayor».
