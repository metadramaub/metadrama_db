# Romancillos

Estado: revisado con los datos del proyecto y bibliografía · 30 de julio de 2026

## Decisión

Los romancillos no constituyen una forma ni una familia independientes. Son dos
configuraciones exactas de `romance`, porque conservan la serie abierta, la asonancia
en los versos pares y los impares sueltos; solo cambia el metro.

| Configuración | Metro | Nombre preferente del proyecto |
| --- | ---: | --- |
| `hexasilabico_romancillo` | 6 | Romancillo hexasílabo |
| `heptasilabico_romancillo` | 7 | Romancillo heptasílabo |

No se mantiene una configuración genérica «Romancillo» con una elección posterior
entre 6 y 7. Las dos medidas producen categorías útiles para filtrar y comparar y ya
están identificadas por separado en los datos del IP.

## Registrador

El recorrido mínimo es:

```text
Romance → Romancillo hexasílabo o heptasílabo
         → vocales de la asonancia → guardar
```

El metro, la alternancia `-a`, la asonancia en los pares y los impares sueltos se
derivan de la configuración. El rango debe contener un número par de versos.

## Demarcador

La arquitectura identifica `Romance`; la medida distingue sus configuraciones:

```text
Romance
├── Romancillo hexasílabo: 6 sílabas + -a repetido
├── Romancillo heptasílabo: 7 sílabas + -a repetido
├── Octosilábico:          8 sílabas + -a repetido
└── Heroico:              11 sílabas + -a repetido
```

Esto permite agrupar por forma para estudiar todos los romances y por configuración o
metro para distinguir sus realizaciones.

## Trazabilidad

Los hijos antiguos tienen destinos exactos:

```text
romancillo_hexasilabo  → Romance + configuración hexasilabico_romancillo
romancillo_heptasilabo → Romance + configuración heptasilabico_romancillo
```

La raíz antigua `romancillo` mezclaba ambas medidas. Se retira como entidad, pero queda
marcada para revisión en la futura migración de secuencias: si un registro no permite
conocer la medida, no se asignará por conjetura.

## Fuente y terminología

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, pp. 226–227,
denomina `endecha` al romance heptasílabo y `romancillo` al romance de menos de siete
sílabas.

El proyecto conserva el criterio ya incorporado por el IP: `Romancillo hexasílabo` y
`Romancillo heptasílabo` son los nombres preferentes; `Endecha` y `Romance endecha`
quedan como denominaciones equivalentes de ambas configuraciones. La divergencia queda
documentada para su revisión, sin sobrescribir el criterio del corpus.

## Duda para el IP

Confirmar si `Endecha` y `Romance endecha` deben seguir siendo equivalentes de las dos
configuraciones o reservarse para la heptasílaba. Esta decisión no bloquea la
formalización ni el registro.
