# Cuarteto

Estado: revisado · 1 de agosto de 2026

## Decisión

La estrofa de cuatro versos de arte mayor con rima consonante. Es la mitad que le faltaba a
una rejilla que la tradición nombra con cuatro palabras distintas:

| | `abba` | `abab` |
| --- | --- | --- |
| **arte menor** | redondilla | cuarteta |
| **arte mayor** | cuarteto | serventesio |

El catálogo tenía la fila de arriba —la forma [redondilla](./redondilla.md), con «Cuarteta»
como denominación de su disposición cruzada— y no la de abajo. Y como no existía, **los
cuartetos del soneto no tenían a qué apuntar** y declaraban su propio esquema, mientras sus
tercetos sí reutilizaban el terceto: dos tratamientos del mismo hecho dentro de la misma
arquitectura.

| Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | ---: |
| `endecasilabica` · principal | 4 × 11 | `ABBA` preferente · `ABAB` admitida | 4 |

La separación respecto de la redondilla es la del **arte**, exactamente como el sexteto se
separa de la sextilla. Y «Serventesio» es la denominación equivalente de la disposición
cruzada, igual que «Cuarteta» lo es en el arte menor.

## Quién lo reutiliza

El [soneto](./soneto.md): sus cuartetos declaran `arquitectura_referenciada_id` a esta
arquitectura y su pregunta ofrece las dos disposiciones desde aquí, sin copiarlas.

Y el [terceto encadenado](./tercetos.md), que cierra su cadena con un serventesio: su sección
final reutiliza esta arquitectura en la versión endecasilábica, y la octosilábica cierra con
una cuarteta reutilizando la redondilla. Cada arte cierra con su estrofa de cuatro versos.

Reutilizar **no afirma parentesco**. El soneto no se formó sumando cuartetos y tercetos, así
que no declara `compuesta_por`. Esa relación se reserva para lo que sí ocurrió: la copla
real, que se formó de dos quintillas.

## Registrador

```text
Cuarteto → abrazada o cruzada → guardar
```

El metro y la consonancia se derivan. El rango debe ser múltiplo de cuatro, y una tirada de
cuartetos es una secuencia con N unidades, no otra forma.

## Demarcador

Cuatro endecasílabos consonantes. La disposición distingue el cuarteto del serventesio, y el
arte lo distingue de la redondilla y la cuarteta.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, pp. 190-191: define el
cuarteto como estrofa de cuatro versos de arte mayor con rima `ABBA`, y llama serventesio al
de rima `ABAB`.

## Dudas para el IP

1. ¿Debe registrarse alguna otra medida de arte mayor —dodecasílabo, alejandrino— o basta el
   endecasílabo mientras el corpus no documente otra?
**Resuelto:** la **cuaderna vía** queda fuera porque no aparece en el Siglo de Oro. Si
hiciera falta, entraría como **arquitectura de esta forma** —cuatro alejandrinos monorrimos—,
no como forma propia: comparte la extensión y el arte, y solo cambia la disposición de la
rima.
