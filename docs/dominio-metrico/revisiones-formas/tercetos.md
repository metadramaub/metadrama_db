# Tercetos

Estado: revisado, con dudas parciales · 1 de agosto de 2026

## Decisión

Dos formas, no tres. Una estrofa de tres versos y una serie cuya rima enlaza las unidades.

| Forma | Nivel | Norma |
| --- | --- | --- |
| `terceto` | estrofa | 3 endecasílabos consonantes; uno de los tres queda suelto |
| `terceto_encadenado` | serie | encadenamiento y cierre en serventesio, en dos medidas |

`tercetos_sin_encadenar` no era una forma sino una tirada: una serie cuya única sección se
repetía es N tercetos, y cuántos contiene un pasaje lo dice el rango. Sus dos disposiciones
—`A-A`, con el verso central suelto, y `-AA`, con el primero suelto— son ahora los dos
esquemas de rima del terceto, entre los que el editor elige.

El encadenado sí es forma aparte, y por una razón que no es de grado: su rima cruza el
límite de la unidad, de modo que la secuencia entera es **una sola unidad abierta** y no una
repetición de unidades independientes.

Y **cierra con una estrofa cruzada de cuatro versos**, no con un terceto y un verso suelto
detrás. La endecasilábica cierra con un serventesio y reutiliza `cuarteto · endecasilabica`;
la octosilábica cierra con una cuarteta y reutiliza `redondilla · octosilabica`. Cada una
termina en la estrofa de cuatro versos de su propio arte, cuyas dos primeras clases vienen del
último terceto de la cadena.

La extensión no cambia por decirlo así: una cadena de n tercetos más un verso y una cadena de
n−1 tercetos más un serventesio son el mismo número de versos, `3n + 1`.

El encadenado tiene dos arquitecturas, que se distinguen **solo por la medida**:

| Arquitectura | Metro | Rima |
| --- | --- | --- |
| `endecasilabico_consonante` · principal | 11 | `ABA \| BCB \| CDC \| … \| YZYZ` |
| `octosilabico` | 8 | `aba \| bcb \| cdc \| … \| yzyz` |

El terceto octosílabo adapta a los octosílabos españoles los tercetos encadenados de raíz
italiana y no cambia nada más: mismo encadenamiento, mismo cierre, mismas dos secciones. Por
eso es una arquitectura por medida, como las cuatro del romance, y no una forma.

Su esquema de rima se copia en vez de reutilizarse porque un esquema pertenece a una sola
arquitectura. Es el precio conocido de repartir por medidas: el romance lo paga con cuatro
copias de su asonancia y la redondilla con dos disposiciones por medida.

`terceto_de_esdrujulos` es un rasgo transversal, no una forma.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `terceto` | Forma `terceto` |
| `terceto_encadenado` | Forma `terceto_encadenado` |
| `tercetos_sin_encadenar` | Los dos esquemas de rima del terceto |
| `AXABYB` | Esquema `verso-central-suelto`, notación `A-A` |
| `XAAYBB` | Esquema `primer-verso-suelto`, notación `-AA` |
| `terceto_octosilabo` | Arquitectura `octosilabico` del encadenado, con su rima propia |
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

1. ¿Un verso excepcional sin rima es variante admitida o desviación?
2. ¿La repetición de una misma rima cuatro veces es variante o desviación?
3. ¿Cuántas unidades mínimas exige una serie encadenada?
4. ¿Los cierres en pareado o cuarteto de las antiguas series sin encadenar son canónicos o
   desviaciones documentadas?
