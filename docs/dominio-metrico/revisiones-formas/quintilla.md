# Quintilla

Estado: revisada, pendiente del IP · 28 de julio de 2026

## Decisión

Una forma, una configuración y ocho patrones de rima. Los patrones no son formas ni
configuraciones. Se mantiene el criterio del IP para el corpus, aunque difiera de una
preceptiva general.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `quintilla` · estrofa |
| Configuración | `octosilabica_consonante` |
| Extensión | 5 versos |
| Metro | 8 sílabas |
| Rima | consonante |
| Patrones | `ababa`, `abbab`, `abaab`, `aabab`, `aabba`, `abbaa`, `ababb`, `abbba` |

Los siete primeros se registran como ordinarios y `abbba` como excepción documentada
por el IP. Cada esquema tiene cinco posiciones normalizadas.

## Registrador

El rango genera una unidad por cada cinco versos. El editor elige el esquema de cada
quintilla, puede aplicarlo a todas y modifica solo las que cambian. La medida, la
consonancia y la extensión se derivan. Un rango que no sea múltiplo de cinco no se puede
guardar.

## Ejemplo de almacenamiento definitivo

El ejemplo representa una secuencia de tres quintillas, vv. 20-34. La primera y la tercera
presentan `ababa`; la segunda, `abbab`. Los nombres legibles representan los UUID de las
entidades del catálogo.

### `secuencias_metricas`

| secuencia_id | obra_id | v_ini | v_fin | n_versos | forma_metrica_id |
| --- | --- | ---: | ---: | ---: | --- |
| `SEC-QUI-1` | `OBRA-1` | 20 | 34 | 15 | `quintilla` |

### `secuencia_configuraciones`

| secuencia_id | configuracion_id | observaciones |
| --- | --- | --- |
| `SEC-QUI-1` | `octosilabica_consonante` | `NULL` |

### `unidades_metricas`

| unidad_id | secuencia_id | unidad_padre_id | seccion_id | orden | v_ini | v_fin |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `QUI-1` | `SEC-QUI-1` | `NULL` | `quintilla` | 1 | 20 | 24 |
| `QUI-2` | `SEC-QUI-1` | `NULL` | `quintilla` | 2 | 25 | 29 |
| `QUI-3` | `SEC-QUI-1` | `NULL` | `quintilla` | 3 | 30 | 34 |

### `secuencia_elecciones_metricas`

| secuencia_id | unidad_id | grupo_eleccion_id | opcion_eleccion_id |
| --- | --- | --- | --- |
| `SEC-QUI-1` | `QUI-1` | `esquema_rima` | `ababa` |
| `SEC-QUI-1` | `QUI-2` | `esquema_rima` | `abbab` |
| `SEC-QUI-1` | `QUI-3` | `esquema_rima` | `ababa` |

Cada opción referencia su fila de `patrones_rima`. El octosílabo, la consonancia y la
extensión de cinco versos se derivan de `octosilabica_consonante`; no se repiten por
quintilla.

### Tablas de observaciones

No reciben filas porque las tres unidades cumplen la norma. Si un verso concreto fuera
heptasílabo, se añadiría una observación de dimensión `medida` sobre ese verso y su detalle
en `secuencia_metros_observados`; no se cambiaría la configuración de toda la secuencia.

## Demarcador

Debe identificar la quintilla por cinco versos octosílabos y rima consonante. El esquema
concreto solo se consulta si hace falta describir la realización; nunca produce otra
forma.

## Trazabilidad

Los ocho términos hijos conservan `origen_termino_id`. La definición importada decía
«siete modalidades» pero enumeraba ocho; el catálogo distingue siete ordinarias y una
excepción.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 188 y 195: cinco versos de arte
menor, dos rimas consonantes, sin versos sueltos, máximo de dos rimas consecutivas y sin
pareado final. El catálogo no impone automáticamente esta delimitación porque el IP
trabaja con un criterio específico para el corpus áureo.

## Dudas para el IP

1. ¿Los ocho esquemas forman un repertorio cerrado o son los reconocidos hasta ahora?
2. ¿Por qué no se incluye `aabaa`?
3. ¿`abbaa` y `ababb`, con pareado final, son variedades ordinarias del proyecto?
4. ¿La definición pública debe explicar expresamente la diferencia con la preceptiva
   general?
