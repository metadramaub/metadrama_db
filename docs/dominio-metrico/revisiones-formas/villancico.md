# Villancico

Estado: revisado, con dudas acotadas · 1 de agosto de 2026

## Decisión

El villancico es una forma compuesta articulada por coplas y un estribillo. `Cabeza`,
`estribillo` y `represa` no son tres formas:

- **estribillo** nombra la unidad por su función recurrente;
- **cabeza** nombra su primera aparición solo cuando abre la composición;
- **represa** nombra cada aparición posterior, total o parcial.

Por ello se reconocen dos configuraciones según la posición de la primera aparición del
estribillo. La copla no contiene el estribillo: copla y represa son secciones hermanas
dentro de un ciclo repetible.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `villancico` · compuesta |
| Configuración 1 | `estribillo_inicial` · cabeza → ciclos de copla y represa |
| Configuración 2 | `estribillo_tras_primera_copla` · primera copla → estribillo → ciclos posteriores |
| Metro | 6 u 8 sílabas, sin orden fijo |
| Mudanza | 4 versos · `abba` o `abab` entre las posibilidades reconocidas |
| Enlace o vuelta | sección opcional de la copla |
| Represa | total, parcial o implícita |

En ambas configuraciones, la copla contiene la mudanza y el posible enlace o vuelta. El
patrón de rima se responde en cada mudanza. La represa se responde en el ciclo: la opción
total crea una sección con la extensión de la primera aparición del estribillo; la parcial
crea una sección cuya longitud indica el editor; la implícita no inventa versos.

La segunda configuración también admite que no haya un ciclo posterior. Elegirla equivale
a afirmar que la sección situada después de la primera copla cumple la función de
estribillo por una rúbrica, indicación musical u otra evidencia. Una sección final aislada
no se clasifica automáticamente como estribillo: puede ser cierre, remate o epílogo.

## La mudanza reutiliza la redondilla, y el villancico no es una tirada de redondillas

La mudanza son cuatro octosílabos con `abba` o `abab`: **estructuralmente es una redondilla**,
y por eso reutiliza su arquitectura en vez de copiar su repertorio. Un pasaje que sea una
mudanza suelta se analiza con las mismas categorías que cualquier otra redondilla, que es para
lo que sirve tener las estrofas básicas desgranadas.

Pero **el villancico no está compuesto de redondillas**, y esa relación no se declara. La
reutilización es mecánica —trae el repertorio de esquemas y autoriza a la pregunta a apuntar a
ellos— y no afirma ningún parentesco. Para afirmarlo está `compuesta_por`, que se declara
aparte y solo cuando es cierto: el villancico se formó como composición con estribillo, no
sumando redondillas, y su mudanza es una parte que nunca aparece sola.

Es la misma distinción que separa a la copla real, que **sí** declara `compuesta_por
quintilla` porque efectivamente se formó de dos quintillas, del soneto, que reutiliza el
repertorio del terceto sin haberse formado de tercetos.

## Ejemplo de almacenamiento definitivo: estribillo inicial

Villancico de diez versos: cabeza de tres, una copla con mudanza `abab`, un verso de enlace
o vuelta y represa parcial de dos versos.

### `secuencias_metricas`

| secuencia_id | obra_id | v_ini | v_fin | n_versos | forma_metrica_id |
| --- | --- | ---: | ---: | ---: | --- |
| `SEC-VIL-1` | `OBRA-1` | 1 | 10 | 10 | `villancico` |

### `secuencia_arquitecturas`

| secuencia_id | arquitectura_id | observaciones |
| --- | --- | --- |
| `SEC-VIL-1` | `estribillo_inicial` | `NULL` |

### `realizaciones_metricas`

| unidad_id | secuencia_id | unidad_padre_id | seccion_id | orden | v_ini | v_fin |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `CAB-1` | `SEC-VIL-1` | `NULL` | `cabeza` | 1 | 1 | 3 |
| `CIC-1` | `SEC-VIL-1` | `NULL` | `ciclo_copla` | 2 | 4 | 10 |
| `COP-1` | `SEC-VIL-1` | `CIC-1` | `copla` | 3 | 4 | 8 |
| `MUD-1` | `SEC-VIL-1` | `COP-1` | `mudanza` | 4 | 4 | 7 |
| `ENV-1` | `SEC-VIL-1` | `COP-1` | `enlace_vuelta` | 5 | 8 | 8 |
| `REP-1` | `SEC-VIL-1` | `CIC-1` | `represa` | 6 | 9 | 10 |

`COP-1` y `REP-1` son hermanas. `CIC-1` calcula su rango a partir de ambas; `COP-1`, a
partir de la mudanza y el enlace o vuelta.

### `secuencia_elecciones_metricas`

| secuencia_id | unidad_id | grupo_eleccion_id | opcion_eleccion_id |
| --- | --- | --- | --- |
| `SEC-VIL-1` | `CAB-1` | `medida_cabeza` | `hexasilabo` |
| `SEC-VIL-1` | `MUD-1` | `medida_mudanza` | `octosilabo` |
| `SEC-VIL-1` | `MUD-1` | `rima_mudanza` | `abab` |
| `SEC-VIL-1` | `CIC-1` | `represa_estribillo` | `parcial` |

## Ejemplo de almacenamiento definitivo: sin cabeza

La secuencia efectiva es `copla → estribillo → copla → represa`. El primer estribillo no
es cabeza porque ocupa los versos 5–7.

### `secuencia_arquitecturas`

| secuencia_id | arquitectura_id | observaciones |
| --- | --- | --- |
| `SEC-VIL-2` | `estribillo_tras_primera_copla` | `NULL` |

### `realizaciones_metricas`

| unidad_id | secuencia_id | unidad_padre_id | seccion_id | orden | v_ini | v_fin |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `PRI-1` | `SEC-VIL-2` | `NULL` | `primer_ciclo` | 1 | 1 | 7 |
| `COP-1` | `SEC-VIL-2` | `PRI-1` | `copla` | 2 | 1 | 4 |
| `MUD-1` | `SEC-VIL-2` | `COP-1` | `mudanza` | 3 | 1 | 4 |
| `EST-1` | `SEC-VIL-2` | `PRI-1` | `estribillo` | 4 | 5 | 7 |
| `CIC-2` | `SEC-VIL-2` | `NULL` | `ciclo_copla` | 5 | 8 | 14 |
| `COP-2` | `SEC-VIL-2` | `CIC-2` | `copla` | 6 | 8 | 11 |
| `MUD-2` | `SEC-VIL-2` | `COP-2` | `mudanza` | 7 | 8 | 11 |
| `REP-2` | `SEC-VIL-2` | `CIC-2` | `represa` | 8 | 12 | 14 |

La primera aparición se guarda como `estribillo`; solo `REP-2` es una represa. Una
repetición total deriva sus tres versos de `EST-1`.

## Tablas de observaciones

No reciben filas por la posición del primer estribillo, los patrones admitidos, el enlace
o vuelta ni el tipo de represa: son elecciones normalizadas. Solo una realización que se
aparte de las posibilidades del catálogo produce una desviación.

## Editor y demarcador

El editor pregunta primero dónde aparece por primera vez el estribillo mediante las dos
configuraciones. Después muestra solo:

1. la medida de cada sección;
2. el esquema de cada mudanza;
3. el enlace o vuelta, solo si se añade;
4. el modo de cada represa.

**La medida se pregunta por sección, no por secuencia.** Lo habitual es que un villancico
sea isosilábico, pero puede combinar medidas —una cabeza hexasílaba con coplas
octosílabas—, y afirmarlo en bloque registraría que hay seises y ochos sin decir dónde. Que
el editor pueda declarar de una vez que toda la composición usa una sola medida es un atajo
de interfaz, no una afirmación del modelo.

Se ofrecen 6 y 8 porque son las medidas típicas. Otra distinta se registra como desviación,
que es el mecanismo previsto para lo que la norma no contempla.

El demarcador puede usar la presencia y posición del estribillo, la mudanza y el enlace o
vuelta sin exigir que el usuario conozca toda la terminología técnica.

## Trazabilidad

El término heredado conserva su identificador. La migración elimina únicamente las
secuencias de prueba V2 del villancico porque su árbol anterior afirmaba erróneamente que
el estribillo era parte de la copla. No afecta a obras ni a secuencias reales.

## Fuentes

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 211-212, describe la estructura
canónica con cabeza inicial, coplas, mudanza, vuelta y repetición, y el uso habitual de
octosílabos o hexasílabos.

Ana M. Rodado Ruiz, «La métrica cancioneril en la época de los Reyes Católicos», explica
la denominación de la unidad inicial como estribillo, cabeza, villancico, letra o tema.
La edición de *Inundación castálida* de sor Juana aporta testimonios rotulados con coplas
seguidas de estribillo, útiles para distinguir la función recurrente de la posición
inicial.

## Dudas para el IP

1. ¿La mudanza debe representarse como una sección de cuatro versos o como dos mudanzas
   simétricas de dos versos?
2. ¿El enlace o vuelta puede tener cualquier extensión igual o superior a un verso?
3. ¿`abba` y `abab` son los únicos esquemas reconocidos o solo los primeros formalizados?
