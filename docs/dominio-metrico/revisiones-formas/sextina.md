# Sextina

Estado: revisada con los datos del proyecto y bibliografía · 30 de julio de 2026

## Decisión

Una forma de nivel composición con dos configuraciones fijas.

| Configuración | Extensión | Estructura |
| --- | ---: | --- |
| `clasica_6x6_mas_3` | 39 versos | 6 estrofas × 6 versos + remate de 3 |
| `doble_12x6_mas_3` | 75 versos | 12 estrofas × 6 versos + remate de 3 |

Todos los versos son endecasílabos. No hay rima convencional: seis palabras finales
ocupan las posiciones `ABCDEF` de la primera estrofa y se permutan así:

```text
ABCDEF → FAEBDC → CFDABE → ECBFAD → DEACFB → BDFECA
```

El remate recupera las seis palabras, una en el interior y otra al final de cada uno de
sus tres versos. La configuración doble completa dos veces el ciclo de seis estrofas y
mantiene un único remate.

La doble no constituye una forma nueva: modifica el número de ciclos, pero conserva la
misma identidad, metro, regla léxica y cierre.

## Registrador

Los recorridos son:

```text
Sextina → Clásica → guardar
Sextina → Doble → guardar
```

El editor solo elige la configuración. El catálogo deriva el metro, la extensión, las
estrofas, el remate y el orden de las palabras finales. No se pide copiar las seis
palabras concretas porque el proyecto no registra el texto del poema en este nivel.

El rango debe ser múltiplo de 39 o de 75 según la configuración. El editor V2
materializa automáticamente las seis o doce estrofas y el remate para que puedan
localizarse desviaciones sin pedir datos redundantes.

Una alteración del metro, una permutación diferente o la ausencia de una palabra en el
remate se registra como desviación localizada.

## Demarcador

La sextina se reconoce por la conjunción de:

1. endecasílabos;
2. composición fija de 39 o 75 versos;
3. estructura `6 × 6 + 3` o `12 × 6 + 3`;
4. ausencia de rima convencional;
5. permutación de seis palabras finales y recuperación de las seis en el remate.

La repetición léxica se compila desde `patrones_repeticion` y
`patron_repeticion_posiciones`. No depende de una regla manual del demarcador.

## Relaciones y tradiciones

No se crea una familia por compartir seis versos con sextetos o sextillas: la sextina
es una composición completa y su identidad depende de la permutación léxica.

La fuente permite registrar dos relaciones históricas distintas:

- tradición provenzal · `origen`, por la invención atribuida a Arnaut Daniel;
- tradición italiana · `adaptacion`, por su introducción con Dante y su cultivo por
  Petrarca.

## Trazabilidad

```text
sextina → FORMA Sextina
          ├── CONFIGURACIÓN Clásica · 6 × 6 + 3
          └── CONFIGURACIÓN Doble · 12 × 6 + 3
```

El UUID anterior se conserva como identidad de la forma y como origen del destino de
migración.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, pp. 216-218:
define la sextina de 39 endecasílabos, sus seis estrofas, el remate, la permutación de
palabras-rima y su historia provenzal e italiana.

La sextina doble procede del criterio ya incorporado por el IP al vocabulario del
proyecto; la fuente citada formaliza la configuración clásica.

## Dudas para el IP

Ninguna bloquea el registro. Queda por confirmar si el proyecto desea fijar un orden
concreto de las seis palabras dentro del remate; la norma actual exige que aparezcan
las seis, tres en el interior y tres al final, sin imponer una pareja determinada.
