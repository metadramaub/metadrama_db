# Lira

Estado: revisada con los datos del proyecto y bibliografía · 29 de julio de 2026

## Decisión

Una forma y una configuración fija.

| Elemento | Valor |
| --- | --- |
| Forma | `lira` · estrofa |
| Configuración | `heptasilabica_endecasilabica_consonante` |
| Extensión | 5 versos |
| Patrón métrico | `7-11-7-7-11` |
| Rima | consonante |
| Patrón de rima | `aBabB` |

Las mayúsculas de la fórmula indican los versos endecasílabos. Las clases de rima son
dos: `a` en los versos 1 y 3; `b` en los versos 2, 4 y 5.

## Registrador

El recorrido es:

```text
Lira → guardar
```

No se pregunta por medida, rima, esquema ni estructura porque todos son definitorios.
Una tirada de liras se registra como una secuencia cuyo rango debe ser múltiplo de
cinco. Las unidades se derivan del rango y no necesitan materializarse si el editor no
debe elegir nada distinto en ellas.

Una realización que incumpla una posición se registra como desviación localizada; no
se crea otra configuración a partir de ella.

## Demarcador

La forma se identifica mediante la conjunción de:

1. unidad de cinco versos;
2. orden métrico `7-11-7-7-11`;
3. rima consonante;
4. esquema `aBabB`.

El demarcador no necesita preguntas editoriales guardadas en la base para la lira:
compila esas propiedades directamente de la configuración y sus posiciones.

## Denominaciones

Se registran como nombres de la misma forma:

- «lira garcilasiana», denominación equivalente;
- «estrofa de fray Luis de León», denominación histórica.

No se crea una familia ni una relación automática con el sexteto-lira. Esa relación se
decidirá al revisar la segunda forma y no se infiere solo por el nombre.

## Trazabilidad

```text
lira → FORMA Lira
     ├── PATRÓN MÉTRICO 7-11-7-7-11
     └── PATRÓN DE RIMA aBabB
```

El UUID anterior se conserva como identidad de la forma y como origen de su destino de
migración.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 195: define la
lira, lira garcilasiana o estrofa de fray Luis de León como cinco versos heptasílabos
y endecasílabos con rima consonante `7A 11B 7A 7B 11B`.

El catálogo conserva la fórmula `7a 11B 7a 7b 11B` usada por el proyecto para que la
mayúscula indique arte mayor sin convertir `B` y `b` en clases de rima diferentes.

## Dudas para el IP

Ninguna imprescindible para registrar o demarcar la forma.
