# Sexteto-lira

Estado: revisado con los datos del proyecto y bibliografía · 1 de agosto de 2026

## Decisión

Una forma, una configuración y siete variedades admitidas. Las variedades no son
formas ni configuraciones: cada una enlaza un patrón métrico con un patrón de rima.

| Elemento | Valor |
| --- | --- |
| Forma | `sexteto_lira` · estrofa |
| Configuración | `heterometrica_consonante` |
| Extensión | 6 versos |
| Medidas | heptasílabos y endecasílabos |
| Rima | consonante, tres clases |
| Cierre | pareado con la tercera rima |
| Variedades | siete combinaciones reconocidas por el proyecto |
| Rasgo admitido | `final_acentual = esdrujulo` |

## Por qué hace falta una combinación

El catálogo contiene cinco patrones métricos:

| Patrón | Secuencia |
| --- | --- |
| M1 | `7-11-7-11-7-11` |
| M2 | `11-7-7-11-7-11` |
| M3 | `7-7-7-11-7-11` |
| M4 | `7-7-7-7-7-11` |
| M5 | `11-7-7-11-11-11` |

Y tres patrones de rima:

| Patrón | Esquema |
| --- | --- |
| R1 | `ababcc` |
| R2 | `abbacc` |
| R3 | `aabbcc` |

No se admite su producto cartesiano de quince parejas. El proyecto reconoce estas
siete:

| Variedad | Patrón métrico | Rima | Fórmula conjunta |
| --- | --- | --- | --- |
| A1, preferente | M1 | R1 | `aBaBcC` |
| A2 | M2 | R1 | `AbaBcC` |
| A3 | M3 | R1 | `abaBcC` |
| B1 | M4 | R2 | `abbacC` |
| B2 | M5 | R2 | `AbbACC` |
| C1 | M2 | R3 | `AabBcC` |
| C2 | M5 | R3 | `AabBCC` |

`variedades_arquitectura` guarda estas parejas exactas. Así se evita:

- ofrecer combinaciones no documentadas;
- copiar un mismo patrón en varias configuraciones;
- convertir siete realizaciones en siete formas falsas.

## Registrador

Una tirada se registra como una secuencia cuyo rango debe ser múltiplo de seis. El
editor responde en cada unidad:

1. «¿Qué variedad de sexteto-lira presenta?»;
2. opcionalmente, una vez para la secuencia, si predominan finales esdrújulos.

La interfaz permite aplicar la variedad de la primera estrofa a toda la tirada y
cambiar únicamente las unidades diferentes. Una fórmula admitida es una elección, no
una desviación.

## Demarcador

El demarcador identifica la forma por seis versos, combinación de 7 y 11 sílabas,
consonancia, tres rimas y pareado final. Las siete fórmulas concretan realizaciones
admitidas para el registro y el análisis; no producen siete candidatos independientes.

## Del vocabulario jerárquico al catálogo

```text
sexteto_lira                       → FORMA Sexteto-lira
├── sexteto_lira_a1_aBaBcC        → COMBINACIÓN A1
├── sexteto_lira_a2_AbaBcC        → COMBINACIÓN A2
├── sexteto_lira_a3_abaBcC        → COMBINACIÓN A3
├── sexteto_lira_b1_abbacC        → COMBINACIÓN B1
├── sexteto_lira_b2_AbbACC        → COMBINACIÓN B2
├── sexteto_lira_c1_AabBcC        → COMBINACIÓN C1
├── sexteto_lira_c2_AabBCC        → COMBINACIÓN C2
└── sexteto_lira_de_esdrujulos    → RASGO final_acentual = esdrujulo
```

Los tamaños erróneos heredados dejan de intervenir: toda variedad deriva seis versos
de la configuración y de las seis posiciones normalizadas.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 198: define el
sexteto-lira como combinación de heptasílabos y endecasílabos con rima consonante y
señala que puede presentar distintos esquemas.

Las siete variedades concretas proceden de los datos estructurados por el IP para el
proyecto. La fuente bibliográfica sustenta la identidad general, no se usa para
sustituir ese repertorio aurisecular.

## Posible relajación del repertorio

Las siete combinaciones se consideran por ahora las reconocidas por el proyecto, no
necesariamente un inventario universal cerrado. Si el IP confirma que existen otras
parejas admisibles pero no que medida y rima se combinen libremente, se conservará el
modelo actual y se añadirán las nuevas combinaciones al catálogo cuando se documenten.

Solo se eliminaría el acoplamiento y se ofrecerían por separado patrón métrico y patrón
de rima si el IP confirma que ambos ejes son independientes y que cualquier pareja es
válida. Para hallazgos todavía no catalogados puede incorporarse una opción «Otra
combinación» que despliegue ambas elecciones y deje la observación pendiente de
validación, sin tratarla automáticamente como desviación.

## Dudas para el IP

1. ¿Las siete variedades forman un repertorio cerrado, son las reconocidas hasta ahora
   o medida y rima pueden combinarse libremente?
2. ¿A1 debe seguir mostrándose públicamente como la variedad habitual o preferente?
3. ¿Una tirada puede cambiar de variedad entre estrofas sin dejar de constituir una
   única secuencia?
