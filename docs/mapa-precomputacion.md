# Mapa de la precomputación

> **Este documento se genera.** Lo escribe `npm run precomputacion:informe` leyendo la base y
> **ejecutando la ficha**, así que no se edita a mano: lo que se cambia es el guion. Lo que la base
> no puede saber —para qué sirve cada columna y quién la lee— vive en `scripts/informe-precomputacion.mjs`,
> y una columna que nadie haya descrito sale marcada como **sin describir**.

Regenerado el 12 de septiembre de 2026.

## Las cuatro capas

**1 · Lo anotado.** `secuencias_metricas` y, colgando de ella, `anotaciones_metricas` →
`anotacion_realizaciones` (las unidades y sus partes), `anotacion_elecciones` (las respuestas) y
`anotacion_desviaciones`. Aparte, `secuencias_caracterizaciones_rango`, y la estructura en
`jornadas` y `cuadros`.

**2 · El cálculo intermedio.** `obras_resumen` y `autores_resumen` conservan los agregados
relacionales que usan los productores. Ya no son el contrato que consumen las páginas públicas.

**3 · Los artefactos servibles.** `artefactos_publicos` guarda JSON versionados por consumidor:
fichas y análisis de obra, fichas de autor, índices ligeros y comparativas del corpus. Sus claves
tienen forma de ruta de objeto para poder trasladarlos a R2 sin cambiar el contrato.

**4 · La vista previa.** Solo una obra que aún no está publicada ejecuta `ficha_publica_json` en
vivo. Al pulsar «Actualizar datos públicos», la cola reconstruye primero los artefactos de obra,
después los de autor y al final los índices y comparativas globales.

## Cuántas hay

| | |
|---|--:|
| obras | 107 |
| obras publicadas | 11 |
| filas en `obras_resumen` | 21 |
| artefactos JSON | 36 |
| artefactos pendientes de actualizar | 0 |
| secuencias | 713 |
| secuencias con anotación del catálogo nuevo | 449 |
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
| `autores` | ARRAY | nombres de autoría preparados para filtrar y presentar | buscador, portada |

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

## Qué guarda `artefactos_publicos`

| columna | tipo | qué es | quién la lee |
|---|---|---|---|
| `clave` | text | ruta estable del artefacto y futura clave de objeto | servidor público |
| `tipo` | text | familia del contrato JSON | servidor público |
| `entidad_id` | uuid | obra o autor al que pertenece, si procede | productores |
| `alcance` | text | qué obras entran en el agregado | perfil de autor |
| `version_esquema` | integer | versión explícita del contrato | productores y consumidores |
| `payload` | jsonb | documento JSON servido como unidad | rutas públicas |
| `sucio` | boolean | hay cambios posteriores; se conserva la última versión coherente | cola y diagnóstico |
| `generado_en` | timestamp with time zone | momento en que se reemplazó el artefacto | cola y diagnóstico |

| contrato | alcance | artefactos | tamaño de los payloads | sucios |
|---|---|--:|--:|--:|
| `autor_ficha` | completo | 4 | 16.0 KiB | 0 |
| `autor_ficha` | publico | 4 | 16.0 KiB | 0 |
| `autores_indice` | completo | 1 | 1.8 KiB | 0 |
| `autores_indice` | publico | 1 | 1.8 KiB | 0 |
| `corpus_comparativas` | completo | 1 | 2.9 KiB | 0 |
| `corpus_comparativas` | publico | 1 | 2.9 KiB | 0 |
| `obra_analisis` | publico | 11 | 571.9 KiB | 0 |
| `obra_ficha` | publico | 11 | 841.9 KiB | 0 |
| `obras_indice` | completo | 1 | 14.9 KiB | 0 |
| `obras_indice` | publico | 1 | 14.9 KiB | 0 |

## Qué devuelve la ficha

Ejecutada sobre la obra con más secuencias anotadas.

Bloques: `obra`, `autoria`, `metrica`, `estructura`, `sinopsis_metrica`, `comentarios_publicos`.

Y de cada secuencia: `v_fin`, `v_ini`, `metros`, `rasgos`, `n_versos`, `sinopsis`, `cuadro_id`, `cuadro_num`, `forma_slug`, `jornada_id`, `tipo_forma`, `variedades`, `jornada_num`, `desviaciones`, `forma_nombre`, `secuencia_id`, `esquemas_rima`, `arquitectura_id`, `cuadro_continua`, `versos_partidos`, `inaugura_espacio`, `arquitectura_slug`, `nivel_estructural`, `arquitectura_nombre`, `evento_sobrenatural`, `caracterizaciones_rango`, `intervencion_figuras_donaire`, `intervencion_personajes_femeninos`, `intervencion_personajes_sobrenaturales`.

## Lo que se puede registrar, y dónde aparece

Lo que tiene filas y no llega a ninguna de las dos superficies está anotado y no se ve.

| dato | filas hoy | columna del resumen | en la ficha |
|---|--:|---|:--:|
| Rasgos observados (asonancia, densidad de rima, final acentual) | 184 | — | sí |
| Metro elegido por unidad | 446 | `metros_presentes` | sí |
| Esquema de rima elegido por unidad | 5100 | `subtipos_presentes` | sí |
| Variedad elegida dentro de una arquitectura | 3 | — | sí |
| Desviaciones (lagunas, hipométricos, rima ajena) | 8 | — | sí |
| Partes de la unidad (estancia, mudanza, sirima) | 826 | — | **no** |
| Caracterizaciones por rango (cantado, prosa, evocación) | 242 | `pct_cantado` | sí |
| Versos partidos | 276 | `tiene_versos_partidos` | sí |
| Inaugura espacio | 164 | `tiene_cambio_espacio` | sí |
| Evento sobrenatural | 44 | `tiene_evento_sobrenatural` | sí |
| Intervención de personajes femeninos | 586 | `intervencion_femenina` | sí |
| Intervención de figuras de donaire | 161 | `intervencion_donaire` | sí |
| Intervención de personajes sobrenaturales | 80 | `intervencion_sobrenaturales` | sí |

## Comprobaciones

- **Secuencias sin cuadro en la obra de muestra: 0.** Debe ser cero: una secuencia
  pertenece al cuadro donde empieza, y que la tirada siga sonando después del corte se dice en
  `cuadro_continua`. Si esto sube, alguien ha vuelto a exigir que la secuencia quepa entera.
- **Columnas sin describir:** 0. Cada una es una medida que se añadió sin decir para qué sirve.
