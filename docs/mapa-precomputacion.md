# Mapa de la precomputación

Qué se guarda, qué se calcula en vivo, qué llega a la ficha y qué está registrado sin salir por
ningún lado. Contrastado contra la base el 8 de septiembre de 2026, con las doce obras de prueba
dentro.

## Las tres capas

**1 · Lo anotado.** `secuencias_metricas` y, colgando de ella, `anotaciones_metricas` →
`anotacion_realizaciones` (las unidades y sus partes), `anotacion_elecciones` (las respuestas) y
`anotacion_desviaciones`. Aparte, `secuencias_caracterizaciones_rango`, y la estructura en
`jornadas` y `cuadros`. Hoy: 433 secuencias, 5.759 elecciones, 7 desviaciones, 6 caracterizaciones.

**2 · Lo precomputado.** `obras_resumen` (24 columnas) y `autores_resumen` (11). Se rehacen al
pulsar «Actualizar datos públicos» o con `recompute_all()`, y **solo para obras publicadas**. Es
lo que alimenta el buscador de `/obras` y el perfil de autor.

**3 · La ficha, en vivo.** `get_obra_ficha_publica_base_without_slugs(obra, include_hidden)` lee
las tablas crudas en cada visita. Por eso funciona la vista previa: una obra sin publicar no tiene
resumen, pero sí ficha. **La ficha no lee el resumen para nada.**

Esa duplicidad es deliberada, pero significa que **cada medida hay que escribirla dos veces** —una
en el resumen y otra en la función de ficha— o no aparece en los dos sitios. Es la causa de la
mayoría de las rarezas que estás viendo.

## Qué guarda `obras_resumen`

| columna | qué es | quién la lee |
|---|---|---|
| `total_versos`, `n_secuencias`, `n_jornadas` | recuentos | buscador |
| `n_formas_distintas`, `numero_efectivo_formas`, `p_max` | diversidad métrica | buscador, perfil de autor |
| `densidad_transiciones` | cambios de forma por cien versos | buscador |
| `pct_cantado` | proporción de versos cantados | nadie todavía |
| `tramos` | el código de barras: `{i, f, s, t}` por tramo fusionado | buscador |
| `perfil_formas` | `{forma_slug: versos}` | buscador, perfil de autor |
| `formas_presentes`, `metros_presentes`, `tipos_forma_presentes`, `subtipos_presentes`, `variaciones_presentes` | arrays para filtrar | buscador |
| `tiene_versos_partidos`, `tiene_cambio_espacio` | banderas | buscador |
| `intervencion_femenina`, `intervencion_donaire`, `intervencion_sobrenaturales` | resumen de las tres preguntas | buscador |
| `jornadas_tramos`, `cuadros_tramos` | los cortes que se dibujan encima del barcode | buscador |
| `metrica_sucia`, `actualizado_en` | control | dashboard |

`autores_resumen` guarda el agregado por autor: obras completas, jornadas sueltas, versos, perfil
de formas —y `perfil_formas_hijos`, el desglose por arquitectura—, y dos números efectivos, el
medio y el agregado.

## Qué llega hoy a la ficha

```
obra          título, variantes, datación, género, edición, bibliografía, observaciones, autoría de la ficha
autoria       el bloque de atribución
estructura    jornadas[] y cuadros[] con sus rangos
metrica
  secuencias[]  v_ini, v_fin, n_versos, sinopsis,
                jornada_id/num, cuadro_id/num,
                estrofa_forma_slug, estrofa_forma_term, estrofa_tipo_term, estrofa_tipo_forma,
                subtipos_estrofa[]  ← una entrada POR UNIDAD
                versos_partidos, inaugura_espacio, evento_sobrenatural,
                intervencion_personajes_femeninos / _figuras_donaire / _personajes_sobrenaturales,
                caracterizaciones_rango[]
  distribucion_formas[]  forma, forma_slug, versos, porcentaje, forma_tipo_forma
sinopsis_metrica[]
comentarios_publicos[]
```

## Lo que está registrado y no sale por ningún lado

Esto es el grueso de lo que hay que decidir.

| dato | dónde está | resumen | ficha |
|---|---|---|---|
| **Asonancia del romance** y los demás rasgos | `anotacion_elecciones.valor_rasgo_id` | no | **no** |
| **Metro elegido por unidad** | `anotacion_elecciones.metro_id` | solo como array de presencia | no |
| **Esquema de rima por unidad** | `anotacion_elecciones.esquema_rima_id` | solo como array | sí, pero como «subtipo» suelto |
| **Desviaciones** —lagunas, hipométricos, rimas ajenas— | `anotacion_desviaciones` | no | **no** |
| **Las partes de la unidad** —estancia, mudanza, sirima— | `anotacion_realizaciones` | no | no |
| **La arquitectura** | `anotaciones_metricas.arquitectura_id` | no | sí, mal usada (rotula el barcode) |
| **Versos cantados y prosa** | `secuencias_caracterizaciones_rango` | solo `pct_cantado` | sí, pero solo dentro del modal |
| **Personajes femeninos / donaire / sobrenaturales por secuencia** | `secuencias_metricas` | solo el agregado | sí, sin usar |
| **Cuadro de cada secuencia** | se calcula al vuelo | `cuadros_tramos` | **nulo en el 13 %** |

Ese último es un fallo con nombre. La ficha empareja secuencia con cuadro exigiendo que la
secuencia **quepa entera** dentro del cuadro, y como el 31 % de los cambios de cuadro cae dentro de
una tirada —lo hemos copiado de las cinco comedias leídas a mano, donde pasa igual—, **6 de las 33
secuencias de *Las batuecas* se quedan sin cuadro**. Hoy eso es un `null`; es justamente lo que tú
quieres medir como «cuántos cambios de cuadro están diluidos».

Y `pct_cantado` no es un porcentaje: guarda `0.0077` para una obra con el 0,77 % cantado. O se
renombra o se multiplica.

## Tus diez ideas, y qué haría falta para cada una

Ordenadas por lo que cuestan, no por tu orden.

### Sale ya, solo hay que enseñarlo

**Espacios inaugurados.** `inaugura_espacio` llega a la ficha y no lo pinta nadie. Cero trabajo de
precomputación.

**Versos cantados y prosa.** Ya llegan por secuencia; hoy solo se ven al abrir el modal. Para
enseñarlos en el barcode y en un bloque propio no hace falta precomputar nada nuevo —el `pct_cantado`
del resumen ya existe, y arreglarlo es una línea.

**Personajes femeninos, donaire y sobrenaturales: en qué secuencias.** El dato está en cada
secuencia de la ficha. Lo único que falta es el listado.

### Necesita una medida nueva, pero es aritmética sobre lo que hay

**Italianos contra españoles, global y por jornada.** `estrofa_tipo_forma` ya viene en cada
secuencia; el reparto por jornada es una suma. Al resumen añadiría `perfil_tradiciones` y
`perfil_por_jornada`, porque el buscador también los querrá.

**Evolución de cada forma por jornadas.** Lo mismo: `{jornada: {forma_slug: versos}}`. Con eso el
gráfico de colores se dibuja solo, reusando la paleta que ya existe.

**Versos partidos: en qué estrofas sí y en cuáles no.** Cruce de `versos_partidos` con la forma.
Una columna `formas_con_versos_partidos` y listo.

**Cuadros diluidos.** Aquí primero hay que **arreglar el emparejamiento**: una secuencia que cruza
un cuadro debe quedarse con el cuadro donde empieza, no con ninguno. Hecho eso, la medida es
`cuadros cuyo v_ini coincide con un v_ini de secuencia / total`, que es exactamente el 69 % que
tienen las obras de prueba. Merece columna propia: `coincidencia_cuadro_forma`.

**Datos medibles de la obra.** Largo medio de tirada, tirada más larga, número de tiradas por
forma, versos por jornada. Todo suma sobre `tramos`, que ya está guardado.

### Necesita que la ficha lea lo que hoy ignora

**Explotación de los versos cantados: métrica y personajes.** El «qué métrica» sale de cruzar la
caracterización con la forma de su secuencia. El «qué personajes» **no está registrado**: hoy solo
sabemos si en la secuencia interviene una mujer, un donaire o un sobrenatural, no quién canta. Eso
es modelo nuevo, no precomputación.

**Rasgos y desviaciones.** La asonancia de cada romance, la densidad de rima de la silva, las
lagunas. No llegan a la ficha en absoluto y son lo que más se nota que falta —tenemos 57 asonancias
anotadas y ninguna se ve—. Requiere tocar la función de ficha, no el resumen.

### Es otra cosa

**Patrones automáticos.** «La octava aparece tres veces después de la décima», «los italianos van
de más a menos». Son **bigramas de transición entre formas** y una regresión de la proporción
italiana a lo largo de la obra. Se calculan sobre `tramos`, que ya está guardado, pero no son un
campo más: son una tabla o un JSON aparte, y conviene decidirlos con calma. Aquí las obras de
prueba **no valen para validar**: los patrones que encuentre serán los del generador, no los de
Lope. Sirven para probar que la maquinaria funciona y se dibuja bien; para creerse un hallazgo hará
falta corpus real.

## Lo que propongo como regla

**Al resumen va lo que el buscador necesita filtrar u ordenar, y lo que cuesta caro de calcular.**
A la ficha en vivo, todo lo demás.

Y una consecuencia que hay que aceptar: **cada medida nueva se escribe dos veces**, en
`recompute_obra_resumen_metricas` y en la función de ficha, o solo aparece en un sitio. La
alternativa —que la ficha lea el resumen cuando existe— rompería la vista previa, que es lo que hoy
permite ver una obra antes de publicarla.

## Los tres fallos que este mapa destapa

1. **El 13 % de las secuencias no tiene cuadro** porque el emparejamiento exige que quepa entera.
2. **`pct_cantado` guarda una fracción** y se llama porcentaje.
3. **El barcode rotula la arquitectura** («Octosilábica consonante») donde debería decir la forma
   («Quintilla»), y dibuja **una raya por unidad** porque los subtipos llegan uno por estrofa.
