# Seguidilla

Estado: revisada con los datos del proyecto y bibliografía · 1 de agosto de 2026

## Decisión

Una forma con dos configuraciones fijas.

| Configuración | Extensión | Patrón métrico | Patrón de rima |
| --- | ---: | --- | --- |
| `simple` | 4 versos | `7-5-7-5` | `-a-a` |
| `compuesta` | 7 versos | `7-5-7-5 + 5-7-5` | `-a-a + b-b` |

Ambas configuraciones son de arte menor y rima asonante. La compuesta reutiliza la
seguidilla simple como cuerpo y añade un estribillo final de tres versos: sus
pentasílabos extremos comparten una asonancia distinta y el heptasílabo central queda
suelto.

No se crean dos formas porque la compuesta es una ampliación estructural estable de la
misma forma. Tampoco se crea una familia basada únicamente en la extensión.

## Registrador

Los recorridos son:

```text
Seguidilla → Simple → guardar
Seguidilla → Compuesta → guardar
```

El editor solo elige la configuración. Metro, rima, esquema, extensión y secciones se
derivan del catálogo:

- la simple exige un rango múltiplo de 4;
- la compuesta exige un rango múltiplo de 7.

Una tirada materializa una unidad por cada bloque compatible. Las oscilaciones métricas,
una rima consonante o una posición que incumpla el esquema se registran como
desviaciones localizadas, no como preguntas ordinarias ni configuraciones nuevas.

## Demarcador

La forma se identifica por la alternancia de heptasílabos y pentasílabos, la asonancia
en las posiciones correspondientes y una extensión de cuatro o siete versos. La
configuración compuesta añade la estructura:

```text
Seguidilla compuesta
├── Cuerpo · seguidilla simple · 7-5-7-5 · -a-a
└── Estribillo final · 5-7-5 · b-b
```

El demarcador compila estas propiedades directamente de las dos configuraciones y no
depende de preguntas escritas manualmente.

## Trazabilidad

```text
seguidilla → FORMA Seguidilla
             ├── CONFIGURACIÓN Simple · 4 versos
             └── CONFIGURACIÓN Compuesta · 7 versos
```

El UUID anterior se conserva como identidad de la forma y como origen del destino de
migración.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, pp. 192-193:
describe la seguidilla simple `7-5-7-5`, con asonancia en los pentasílabos pares, y la
compuesta como adición de un estribillo `5-7-5` con asonancia entre sus extremos.

La fuente documenta también fluctuaciones de medida y realizaciones consonantes. El
catálogo conserva como norma el criterio más estricto fijado por el IP para el corpus;
los demás casos se anotan como desviaciones.

## Dudas para el IP

Ninguna imprescindible para registrar o demarcar la forma. Solo debe confirmarse en el
futuro si una oscilación métrica o una realización consonante frecuente en el corpus
merece convertirse en opción admitida.
