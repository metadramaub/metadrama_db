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
| `endecasilabico` | 11 | Romance heroico · Romance real |

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

```text
Romance real     → arquitectura endecasilabico
Endecha          → arquitecturas hexasilabico y heptasilabico
Romance endecha  → arquitecturas hexasilabico y heptasilabico
```

«Romancillo hexasílabo» y «Romancillo heptasílabo» son los nombres preferentes del proyecto
para esas dos arquitecturas; «Endecha» y «Romance endecha» quedan como equivalentes de ambas,
según el criterio del IP.

**«Romance heroico» no está registrado como denominación**, a diferencia de «Romance real».
Si el nombre no vive en ninguna parte deja de ser recuperable, y eso incumple el principio de
asignabilidad.

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

1. ¿`Endecha` y `Romance endecha` deben seguir siendo equivalentes de las dos arquitecturas
   menores o reservarse para la heptasílaba? No bloquea el registro.
2. ¿Debe registrarse «Romance heroico» como denominación de la arquitectura endecasílaba?
   Hoy solo está «Romance real».
