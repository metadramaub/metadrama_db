# Zéjel

Estado: revisado, con dudas acotadas · 29 de julio de 2026

## Decisión

El zéjel se conserva como una forma compuesta con una configuración canónica. Reutiliza
las funciones estructurales `cabeza`, `copla`, `mudanza`, `vuelta` y `represa`, pero no
la arquitectura completa del villancico. Su rasgo distintivo es una copla fija de cuatro
versos: tres monorrimos de mudanza y un verso de vuelta que recupera la rima del
estribillo, sin enlace independiente.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `zejel` · compuesta |
| Configuración | `estribillo_y_coplas_monorrimas` |
| Metro | normalmente 6 u 8 sílabas, sin orden fijo |
| Cabeza | primera aparición del estribillo · 1 o 2 versos |
| Ciclo repetible | copla + posible represa |
| Copla | mudanza de 3 versos + vuelta de 1 |
| Rima | consonante · `A(A) \| BBBA` |
| Mudanza | tres versos monorrimos con una rima nueva |
| Vuelta | recupera directamente la rima del estribillo |
| Represa | total o sin realización material |

Las letras `A` y `B` expresan relaciones, no timbres concretos. Cada copla puede introducir
una nueva rima para su mudanza, mientras la vuelta conserva la relación con el estribillo.
La segunda posición de la cabeza es opcional: con un verso el esquema es `A | BBBA`; con
dos, `AA | BBBA`.

No se crea una sección `enlace`: en el zéjel la vuelta sigue directamente a los tres versos
de mudanza. Tampoco se crea un rasgo nuevo para la monorrimia, porque ya queda formalizada
por las tres posiciones `B` del patrón de rima.

## Registrador

La configuración se resuelve automáticamente porque solo hay una. El editor:

1. indica si aparecen versos de 6, de 8 o de ambas medidas;
2. delimita la cabeza y las coplas;
3. responde, para cada ciclo, si el estribillo reaparece materialmente.

La mudanza de tres versos, su monorrimia, el verso de vuelta y su relación con el estribillo
se derivan del catálogo. No se preguntan. Si hay represa total, el registrador crea su
sección y deriva su extensión de la cabeza; si no aparece materialmente, no inventa versos
ni afirma que la repetición quede implícita.

## Ejemplo de almacenamiento definitivo

Zéjel octosilábico de doce versos: cabeza de dos versos, dos coplas y una represa total
después de la primera.

### `secuencias_metricas`

| secuencia_id | obra_id | v_ini | v_fin | n_versos | forma_metrica_id |
| --- | --- | ---: | ---: | ---: | --- |
| `SEC-ZEJ-1` | `OBRA-1` | 1 | 12 | 12 | `zejel` |

### `secuencia_configuraciones`

| secuencia_id | configuracion_id | observaciones |
| --- | --- | --- |
| `SEC-ZEJ-1` | `estribillo_y_coplas_monorrimas` | `NULL` |

### `unidades_metricas`

| unidad_id | secuencia_id | unidad_padre_id | seccion_id | orden | v_ini | v_fin |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `CAB-1` | `SEC-ZEJ-1` | `NULL` | `cabeza` | 1 | 1 | 2 |
| `CIC-1` | `SEC-ZEJ-1` | `NULL` | `ciclo_copla` | 2 | 3 | 8 |
| `COP-1` | `SEC-ZEJ-1` | `CIC-1` | `copla` | 3 | 3 | 6 |
| `MUD-1` | `SEC-ZEJ-1` | `COP-1` | `mudanza` | 4 | 3 | 5 |
| `VUE-1` | `SEC-ZEJ-1` | `COP-1` | `vuelta` | 5 | 6 | 6 |
| `REP-1` | `SEC-ZEJ-1` | `CIC-1` | `represa` | 6 | 7 | 8 |
| `CIC-2` | `SEC-ZEJ-1` | `NULL` | `ciclo_copla` | 7 | 9 | 12 |
| `COP-2` | `SEC-ZEJ-1` | `CIC-2` | `copla` | 8 | 9 | 12 |
| `MUD-2` | `SEC-ZEJ-1` | `COP-2` | `mudanza` | 9 | 9 | 11 |
| `VUE-2` | `SEC-ZEJ-1` | `COP-2` | `vuelta` | 10 | 12 | 12 |

### `secuencia_elecciones_metricas`

| secuencia_id | unidad_id | grupo_eleccion_id | opcion_eleccion_id |
| --- | --- | --- | --- |
| `SEC-ZEJ-1` | `NULL` | `medidas_realizadas` | `octosilabo` |
| `SEC-ZEJ-1` | `CIC-1` | `represa_estribillo` | `total` |
| `SEC-ZEJ-1` | `CIC-2` | `represa_estribillo` | `sin_represa_material` |

No se guardan elecciones para `BBBA`: es la norma de la configuración. Una rima distinta,
una mudanza con otra extensión o un enlace añadido se registrarían como desviaciones.

## Demarcador

Debe preguntar por estribillo inicial, coplas de cuatro versos, mudanza monorrima de tres
y vuelta a la rima del estribillo. La repetición material ayuda a confirmar, pero no se
trata como condición absoluta porque la definición del proyecto la considera habitual.
La diferencia principal frente al villancico es estructural: tres monorrimos más vuelta
directa, no una mudanza de cuatro con posible enlace o vuelta.

## Trazabilidad

El término heredado conserva su UUID como `forma_id`. La migración reemplaza solo su
configuración provisional y elimina, si las hubiera, realizaciones de prueba del editor
V2. No modifica obras ni secuencias registradas por los editores.

## Fuentes

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 210-211, describe un estribillo
de uno o dos versos, una mudanza de tres versos monorrimos y un verso de vuelta que rima
con el estribillo; señala el octosílabo como medida más usada.

María Soledad Carrasco Urgoiti, «“Allega, morico, allega”. Notas sobre un villancico del
siglo XVI y sus glosas», *Revista de Dialectología y Tradiciones Populares*, 35
(1979-1980), pp. 101-112, caracteriza el zéjel estricto por dístico inicial, mudanza
monorrima de tres versos y vuelta consonante a la rima del dístico.

## Dudas para el IP

1. ¿El catálogo del proyecto admite tanto estribillos de un verso como dísticos o debe
   reservar el zéjel estricto para el dístico?
2. ¿La represa parcial debe admitirse cuando aparezca en el corpus o se tratará como
   desviación respecto de esta configuración?
3. ¿Hexasílabo y octosílabo forman un repertorio cerrado para el corpus o cualquier otra
   medida documentada se registrará como desviación?
