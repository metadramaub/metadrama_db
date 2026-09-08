# Mapa de la precomputación

> **Este documento se genera.** Lo escribe `npm run precomputacion:informe` leyendo la base y
> **ejecutando la ficha**, así que no se edita a mano: lo que se cambia es el guion. Lo que la base
> no puede saber —para qué sirve cada columna y quién la lee— vive en `scripts/informe-precomputacion.mjs`,
> y una columna que nadie haya descrito sale marcada como **sin describir**.

Regenerado el 8 de septiembre de 2026.

## Las tres capas

**1 · Lo anotado.** `secuencias_metricas` y, colgando de ella, `anotaciones_metricas` →
`anotacion_realizaciones` (las unidades y sus partes), `anotacion_elecciones` (las respuestas) y
`anotacion_desviaciones`. Aparte, `secuencias_caracterizaciones_rango`, y la estructura en
`jornadas` y `cuadros`.

**2 · Lo precomputado.** `obras_resumen` y `autores_resumen`. Se rehacen al pulsar «Actualizar
datos públicos» o con `recompute_all()`, y **solo para obras publicadas**.

**3 · La ficha.** `get_obra_ficha_publica_base_without_slugs(obra, include_hidden)` lee hoy las
tablas crudas en cada visita. Lo pactado el 8 de septiembre de 2026 es que **eso se quede solo para
la vista previa** y que una obra publicada esté enteramente precomputada; los cinco pasos están en
[el contexto métrico](dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#el-plan-pactado-en-cinco-pasos).

Mientras las dos superficies se escriban por separado, **cada medida hay que escribirla dos veces**
—en `recompute_obra_resumen_metricas` y en la función de ficha— o solo aparece en un sitio. Ese es
el problema que el paso 1 del plan viene a cerrar.

## Cuántas hay

| | |
|---|--:|
| obras | 105 |
| obras publicadas | 12 |
| filas en `obras_resumen` | 21 |
| secuencias | 710 |
| secuencias con anotación del catálogo nuevo | 446 |
| secuencias que aún hablan el vocabulario legado | 263 |

## Qué guarda `obras_resumen`

| columna | tipo | qué es | quién la lee |
|---|---|---|---|
| `obra_id` | uuid | clave | — |
| `total_versos` | integer | recuento | buscador, ficha |
| `n_secuencias` | integer | recuento | buscador |
| `n_jornadas` | integer | recuento | buscador |
| `n_formas_distintas` | integer | cuántas formas aparecen | buscador, perfil de autor |
| `numero_efectivo_formas` | double precision | diversidad métrica: exp(H) | buscador, perfil de autor |
| `p_max` | double precision | peso de la forma dominante | buscador |
| `densidad_transiciones` | double precision | cambios de forma por cien versos | buscador |
| `pct_cantado` | double precision | porcentaje de versos cantados | nadie todavía |
| `tramos` | jsonb | el código de barras: {i, f, s, t} por tramo fusionado | buscador |
| `perfil_formas` | jsonb | {forma_slug: versos} | buscador, perfil de autor |
| `formas_presentes` | ARRAY | filtro | buscador |
| `metros_presentes` | ARRAY | filtro | buscador |
| `tipos_forma_presentes` | ARRAY | filtro: española / italiana | buscador |
| `variaciones_presentes` | ARRAY | filtro | buscador |
| `tiene_versos_partidos` | boolean | bandera | buscador |
| `tiene_cambio_espacio` | boolean | bandera | buscador |
| `intervencion_femenina` | text | agregado de la pregunta por secuencia | buscador |
| `intervencion_donaire` | text | agregado de la pregunta por secuencia | buscador |
| `intervencion_sobrenaturales` | text | agregado de la pregunta por secuencia | buscador |
| `metrica_sucia` | boolean | control: hay que recomputar | dashboard |
| `actualizado_en` | timestamp with time zone | control | dashboard |
| `subtipos_presentes` | ARRAY | filtro: esquemas de rima | buscador |
| `jornadas_tramos` | jsonb | los cortes de jornada que se dibujan sobre el barcode | buscador |
| `cuadros_tramos` | jsonb | los cortes de cuadro que se dibujan sobre el barcode | buscador |
| `ficha` | jsonb | **la ficha pública completa**, tal como la ve un anónimo: la construye `ficha_publica_json` | la ficha de una obra publicada |
| `tiene_evento_sobrenatural` | boolean | bandera | buscador |

## Qué guarda `autores_resumen`

| columna | tipo | qué es | quién la lee |
|---|---|---|---|
| `autor_id` | uuid | clave | — |
| `alcance` | text | qué obras entran en el agregado | perfil de autor |
| `n_obras_completas` | integer | recuento | perfil de autor |
| `n_jornadas_sueltas` | integer | recuento | perfil de autor |
| `total_versos_autor` | integer | recuento | perfil de autor |
| `perfil_formas` | jsonb | {forma_slug: versos} | buscador, perfil de autor |
| `numero_efectivo_formas_medio` | double precision | diversidad media de sus obras | perfil de autor |
| `numero_efectivo_formas_agregado` | double precision | diversidad del conjunto | perfil de autor |
| `metrica_sucia` | boolean | control: hay que recomputar | dashboard |
| `actualizado_en` | timestamp with time zone | control | dashboard |
| `perfil_formas_hijos` | jsonb | desglose por arquitectura | perfil de autor |

## Qué devuelve la ficha

Ejecutada sobre la obra con más secuencias anotadas.

Bloques: `obra`, `autoria`, `metrica`, `estructura`, `sinopsis_metrica`, `comentarios_publicos`.

Y de cada secuencia: `v_fin`, `v_ini`, `metros`, `rasgos`, `n_versos`, `sinopsis`, `cuadro_id`, `cuadro_num`, `jornada_id`, `jornada_num`, `desviaciones`, `secuencia_id`, `cuadro_continua`, `estrofa_tipo_id`, `versos_partidos`, `inaugura_espacio`, `subtipos_estrofa`, `estrofa_tipo_term`, `estrofa_forma_slug`, `estrofa_forma_term`, `estrofa_tipo_forma`, `evento_sobrenatural`, `caracterizaciones_rango`, `intervencion_figuras_donaire`, `intervencion_personajes_femeninos`, `intervencion_personajes_sobrenaturales`.

## Lo que se puede registrar, y dónde aparece

Lo que tiene filas y no llega a ninguna de las dos superficies está anotado y no se ve.

| dato | filas hoy | columna del resumen | en la ficha |
|---|--:|---|:--:|
| Rasgos observados (asonancia, densidad de rima, final acentual) | 182 | — | sí |
| Metro elegido por unidad | 446 | `metros_presentes` | sí |
| Esquema de rima elegido por unidad | 5100 | `subtipos_presentes` | sí |
| Desviaciones (lagunas, hipométricos, rima ajena) | 7 | — | sí |
| Partes de la unidad (estancia, mudanza, sirima) | 826 | — | **no** |
| Caracterizaciones por rango (cantado, prosa, evocación) | 241 | `pct_cantado` | sí |
| Versos partidos | 275 | `tiene_versos_partidos` | sí |
| Inaugura espacio | 163 | `tiene_cambio_espacio` | sí |
| Evento sobrenatural | 44 | `tiene_evento_sobrenatural` | sí |
| Intervención de personajes femeninos | 585 | `intervencion_femenina` | sí |
| Intervención de figuras de donaire | 160 | `intervencion_donaire` | sí |
| Intervención de personajes sobrenaturales | 80 | `intervencion_sobrenaturales` | sí |

## Comprobaciones

- **Secuencias sin cuadro en la obra de muestra: 0.** Debe ser cero: una secuencia
  pertenece al cuadro donde empieza, y que la tirada siga sonando después del corte se dice en
  `cuadro_continua`. Si esto sube, alguien ha vuelto a exigir que la secuencia quepa entera.
- **Columnas sin describir:** 0. Cada una es una medida que se añadió sin decir para qué sirve.
