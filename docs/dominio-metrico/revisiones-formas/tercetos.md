# Tercetos

Estado: revisado, con dudas parciales · 28 de julio de 2026

## Decisión

La familia `tercetos` agrupa tres formas de distinto nivel. No hay una forma genérica
adicional ni una jerarquía de subtipos.

## Formalización

| Forma | Nivel | Norma |
| --- | --- | --- |
| `terceto` | estrofa | 3 endecasílabos; consonancia entre 1 y 3 |
| `terceto_encadenado` | serie | `ABA \| BCB \| CDC \| … \| YZYZ` |
| `tercetos_sin_encadenar` | serie | `A-A \| B-B \| …` o `-AA \| -BB \| …` |

Las series repiten unidades de tres versos, pero su extensión total es abierta. El cierre
del encadenado añade un verso al último terceto para formar el serventesio `YZYZ`.
`terceto_octosilabo` queda provisionalmente como configuración no demarcable del
encadenado. `terceto_de_esdrujulos` se transforma en rasgo transversal.

## Registrador

- `terceto`: configuración automática y final esdrújulo opcional; múltiplos de 3.
- `terceto_encadenado`: la configuración contiene el encadenamiento y el cierre, por lo
  que no se vuelven a preguntar; su longitud es `3n + 1`.
- `tercetos_sin_encadenar`: el editor elige `A-A` o `-AA`; la serie contiene al menos dos
  unidades y su longitud es múltiplo de 3.

Las rupturas locales se registran como desviaciones, no como otra configuración.

## Demarcador

Primero distingue una unidad de tres versos de una serie. En las series pregunta si la
rima central enlaza con el terceto siguiente. El cierre o las excepciones solo se
consultan cuando resulten necesarias.

## Trazabilidad

Los nombres heredados `AXABYB` y `XAAYBB` se conservan como origen de los patrones
normalizados. Ninguna de estas decisiones duplica formas.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), p. 185: terceto de arte mayor,
normalmente endecasílabo y consonante; documenta la serie encadenada y más de un cierre.
METADRAMA adopta por ahora `YZYZ`, según el IP.

## Dudas para el IP

1. ¿El terceto octosilábico conserva siempre el encadenamiento?
2. ¿Un verso excepcional sin rima es variante admitida o desviación?
3. ¿La repetición de una misma rima cuatro veces es variante o desviación?
4. ¿Cuántas unidades mínimas exige una serie encadenada?
5. ¿Los cierres en pareado o cuarteto de las series sin encadenar son canónicos o
   desviaciones documentadas?
