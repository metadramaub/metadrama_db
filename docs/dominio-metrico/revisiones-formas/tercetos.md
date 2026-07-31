# Tercetos

Estado: revisado, con dudas parciales · 31 de julio de 2026

## Decisión

Dos formas, no tres. Una estrofa de tres versos y una serie cuya rima enlaza las unidades.

| Forma | Nivel | Norma |
| --- | --- | --- |
| `terceto` | estrofa | 3 endecasílabos consonantes; uno de los tres queda suelto |
| `terceto_encadenado` | serie | `ABA \| BCB \| CDC \| … \| YZYZ` |

`tercetos_sin_encadenar` no era una forma sino una tirada: una serie cuya única sección se
repetía es N tercetos, y cuántos contiene un pasaje lo dice el rango. Sus dos disposiciones
—`A-A`, con el verso central suelto, y `-AA`, con el primero suelto— son ahora los dos
esquemas de rima del terceto, entre los que el editor elige.

El encadenado sí es forma aparte, y por una razón que no es de grado: su rima cruza el
límite de la unidad, de modo que la secuencia entera es **una sola unidad abierta** y no
una repetición de unidades independientes. El cierre añade un verso al último terceto para
formar el serventesio `YZYZ`.

`terceto_octosilabo` queda como arquitectura no demarcable del encadenado.
`terceto_de_esdrujulos` es un rasgo transversal, no una forma.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `terceto` | Forma `terceto` |
| `terceto_encadenado` | Forma `terceto_encadenado` |
| `tercetos_sin_encadenar` | Los dos esquemas de rima del terceto |
| `AXABYB` | Esquema `verso-central-suelto`, notación `A-A` |
| `XAAYBB` | Esquema `primer-verso-suelto`, notación `-AA` |
| `terceto_octosilabo` | Arquitectura `octosilabico` del encadenado |
| `terceto_de_esdrujulos` | Rasgo transversal |

## Registrador

- **Terceto**: elegir qué verso queda suelto, el primero o el central; final esdrújulo
  opcional. El rango debe ser múltiplo de 3 y la respuesta puede aplicarse a toda la
  tirada.
- **Terceto encadenado**: la arquitectura contiene el encadenamiento y el cierre, así que
  no se vuelven a preguntar. Su longitud es `3n + 1`.

Las rupturas locales se registran como desviaciones, no como otra arquitectura.

## Demarcador

Primero distingue una unidad de tres versos de una serie encadenada: la pregunta operativa
es si la rima central enlaza con el terceto siguiente. El cierre y las excepciones solo se
consultan cuando resultan necesarios.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), p. 185: terceto de arte mayor,
normalmente endecasílabo y consonante; documenta la serie encadenada y más de un cierre.
METADRAMA adopta por ahora `YZYZ`, según el IP.

## Dudas para el IP

1. ¿El terceto octosilábico conserva siempre el encadenamiento? Hoy su arquitectura no
   declara ninguna rima.
2. ¿Un verso excepcional sin rima es variante admitida o desviación?
3. ¿La repetición de una misma rima cuatro veces es variante o desviación?
4. ¿Cuántas unidades mínimas exige una serie encadenada?
5. ¿Los cierres en pareado o cuarteto de las antiguas series sin encadenar son canónicos o
   desviaciones documentadas?
