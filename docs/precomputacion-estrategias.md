# Decisiones de precomputación — especificación para implementación

> Documento de decisión consolidado. Recoge qué se precomputa, dónde, cuándo y cómo lo
> consume cada superficie. Está pensado para guiar la implementación directa en el proyecto.
> No incluye código: define contratos y lógica, no sintaxis concreta.
>
> Versión revisada tras discusión sobre medidas de polimetría, distancias entre formas,
> y perfiles de autor. Incorpora la decisión de basar las distancias en rasgos métricos
> formalizados (rima, metro, naturaleza estrófica) que aún no existen en el vocabulario
> y se codificarán manualmente más adelante.

---

## 1. Decisión de arquitectura general

**Dónde vive todo:** Supabase (PostgreSQL). Sin ficheros estáticos externos por ahora.
Si el corpus crece a varios cientos de obras y el compute de Supabase empieza a notarse,
se añade una capa de exportación a JSON estáticos como extensión del mismo proceso de
publicación, sin cambiar el modelo de datos.

**Principio rector:** `secuencias_metricas` es la fuente de verdad. Todo lo que hay en
`obras_resumen` es derivado y reconstruible desde cero. Debe existir siempre una función
`recompute_all()` que regenere toda la tabla desde los datos crudos.

**Cuándo se activa la precomputación:** exclusivamente al pulsar el botón
"Actualizar datos públicos" en el dashboard de una obra. El autosave (cada 10s) escribe
en las tablas crudas y activa un flag de suciedad, pero no toca nada precomputado.

---

## 2. Nueva tabla: `obras_resumen`

Tabla central. Una fila por obra. Consolida todo lo que antes estaba disperso en queries
en cascada o calculado en cada petición. Sustituye la propuesta de tener `obras_barcode_resumen`
y `obra_analitica` como tablas separadas.

### 2.1 Columnas

**Identificador**
- `obra_id` — uuid, PK, FK a `obras.obra_id`

**Extensión y estructura**
- `total_versos` — int. Total de versos de la obra (redundante con `obras.total_versos`;
  se mantiene aquí para que el catálogo no necesite JOIN con `obras` para este dato).
- `n_secuencias` — int. Número total de secuencias métricas.
- `n_jornadas` — int. Número de jornadas (count de `jornadas` para la obra).

**Métricas de diversidad métrica (revisadas)**
- `n_formas_distintas` — int. Número de formas estróficas distintas usadas. Riqueza pura.
- `numero_efectivo_formas` — float. **Medida principal de diversidad.** Número de Hill de
  orden 1: `exp(H)` con H = entropía de Shannon en logaritmo natural sobre las proporciones
  de versos por forma. Interpretación directa: "esta obra equivale a D formas en
  distribución uniforme". Una obra monométrica da 1; mitad y mitad de dos formas da 2;
  cuatro formas al 25% dan 4; cuatro formas muy desequilibradas (85/5/5/5) dan ~1,6.
  **No depende del tamaño del vocabulario**, así que añadir formas nuevas al vocabulario
  no altera el valor de ninguna obra ya catalogada. Esto la hace estable en el tiempo y
  citable, a diferencia de la propuesta anterior (Shannon normalizado contra V).
- `p_max` — float [0–1]. Proporción de versos de la forma dominante sobre el total.
  Complementa el número efectivo: indica cuán dominada está la obra por una sola forma.
  El cociente `numero_efectivo_formas / n_formas_distintas` indica equilibrio: si una obra
  tiene 8 formas presentes pero número efectivo 2, seis de esas formas son anecdóticas.

> **Decisión tomada:** se abandonan `polimetria_score` (Shannon / log2(V)) y el uso de
> `tasa_cambio` como "polimetría" en el filtro. Razón: el primero depende del vocabulario
> total y deja de ser comparable cuando este crece (cosa que ocurrirá durante años en un
> proyecto en construcción); el segundo mide frecuencia de transición, no variedad, y una
> obra que alterna dos formas muchas veces saldría como muy polimétrica siendo pobre en
> repertorio. El número efectivo de formas captura el concepto filológico de polimetría
> de forma robusta e interpretable.

**Densidad de transiciones (no es polimetría)**
- `densidad_transiciones` — float. Cambios de estrofa por cada 100 versos:
  `(n_secuencias / total_versos) * 100`. Es lo que el documento anterior llamaba
  `tasa_cambio`. **Se conserva, pero etiquetada por lo que es**: densidad de cambios
  métricos, no polimetría. Mide ritmo de conmutación formal, no variedad. Puede exponerse
  como filtro/orden propio en el buscador con esa etiqueta, sin confundirlo con la
  diversidad. No se guarda además `longitud_media_sec` por ser su inverso exacto
  (`total_versos / n_secuencias`); si se necesita en alguna vista, se deriva en cliente.

**% cantado**
- `pct_cantado` — float [0–1]. Proporción de versos en secuencias cuya forma es de tipo
  "cantado". Pendiente de confirmar qué `categoria` o `etiqueta` de `vocabularios`
  identifica las formas cantadas.

**Datos estructurados para visualización**
- `tramos` — jsonb. Array de tramos fusionados para el barcode:
  `[{"i": v_ini, "f": v_fin, "s": forma_slug, "t": tipo_forma}]`. Tramos contiguos de la
  misma forma se fusionan. Ordenados por `v_ini`. `tipo_forma` es `"forma_espanola"`,
  `"forma_italiana"` o `null`. Sirve para pintar el barcode y como base de la distancia
  secuencial. **Ver §3.4 sobre la longitud de tramo en la distancia secuencial.**
- `perfil_formas` — jsonb. Mapa `{forma_slug: n_versos}`. Versos por forma, sin normalizar.
  La normalización (dividir por `total_versos`) se hace en el consumidor. Base de la
  distancia composicional.

**Arrays para filtros (indexados con GIN)**
- `formas_presentes` — text[]. Slugs de todas las formas presentes (filtro "contiene X").
- `metros_presentes` — text[]. Slugs de metros específicos via `estrofa_tipo_metros`.
- `tipos_forma_presentes` — text[]. Subconjunto de `['forma_espanola', 'forma_italiana']`.
- `variaciones_presentes` — text[]. Tipos de variación/caracterización presentes.
  **Pendiente:** el spec del buscador referencia `secuencias_variaciones.tipo_variacion_id`,
  tabla inexistente en el esquema actual. Confirmar si la fuente es
  `secuencias_caracterizaciones_rango` o una tabla por crear. Campo vacío hasta aclararlo.

**Flags de contexto dramático**
- `tiene_versos_partidos` — boolean. True si alguna secuencia tiene `versos_partidos`.
- `tiene_cambio_espacio` — boolean. True si alguna secuencia tiene `inaugura_espacio`.
- `intervencion_femenina` — text: `'ninguna'` / `'exclusiva'` / `'compartida'` / `'mixta'`,
  derivado de `intervencion_personajes_femeninos` de todas las secuencias.
- `intervencion_donaire` — text. Mismo esquema sobre `intervencion_figuras_donaire`.
- `intervencion_sobrenaturales` — text. Mismo esquema sobre `intervencion_personajes_sobrenaturales`.

**Estado de precomputación**
- `metrica_sucia` — boolean, default false. True si las secuencias cambiaron desde el
  último recálculo. Lo activa el trigger (§5). Lo limpia el recompute. El dashboard lo usa
  para mostrar "hay cambios sin publicar".
- `actualizado_en` — timestamptz. Momento del último recálculo.

### 2.2 Índices

```
GIN sobre formas_presentes, metros_presentes, tipos_forma_presentes, variaciones_presentes
BTREE sobre numero_efectivo_formas   (orden por diversidad)
BTREE sobre densidad_transiciones    (filtro/orden de densidad)
BTREE sobre n_formas_distintas
BTREE sobre total_versos
```

---

## 3. Distancias entre formas, obras y autores

Esta sección recoge el cambio de mayor calado respecto a la versión anterior. La
distancia composicional ya no es coseno plano sobre las formas tratadas como ejes
ortogonales. Pasa a basarse en una **matriz de distancia entre formas** derivada de
rasgos métricos formalizados.

### 3.1 La matriz de distancia entre formas (`formas_distancia`)

**Estado: depende de datos que aún no existen.** Los rasgos métricos de cada forma
(rima, metro, naturaleza estrófica, etc.) **no están codificados todavía** en
`vocabularios`. Se codificarán manualmente más adelante. Esta sección define el
contrato hacia el que se trabaja; la matriz no puede generarse hasta que existan
los rasgos.

**Por qué no basta la jerarquía actual:** `vocabularios` tiene solo dos niveles
(raíz–hijo, sin nietos) y la única herencia es `tipo_forma` (español/italiano).
Una distancia de árbol sobre eso solo distingue tres grados (misma forma, mismo padre,
distinto padre) más el salto español/italiano. Demasiado grueso para que aporte algo
sobre el coseno. La solución es describir cada forma por un **vector de rasgos** y
medir distancia entre vectores.

**Rasgos previstos** (a codificar manualmente en `vocabularios`, conjunto mínimo):
- **Metro / longitud de verso**: octosílabo, endecasílabo, heptasílabo, mixto
  hepta-endecasílabo, etc. Frontera más gruesa (arte menor vs arte mayor).
- **Tipo de rima**: asonante / consonante / suelto-blanco. Distingue romance de redondilla
  pese a compartir metro.
- **Naturaleza estrófica**: estrófica cerrada (molde fijo repetido) / tirada continua /
  forma fija singular. Distingue romance (tirada) de redondilla (estrófica) de soneto (fija).
- **Tamaño de la unidad estrófica** cuando aplica (redondilla 4, quintilla 5, octava 8,
  décima 10; nulo para romance, silva).
- (Opcional, no en el primer conjunto) esquema de rima concreto (abba vs abab). Se añade
  solo si la validación con datos muestra que dos formas que deberían distinguirse salen
  pegadas. Riesgo de sobreajuste si se añaden demasiados rasgos.

**Cómo se combina en distancia:** suma ponderada de diferencias rasgo a rasgo. **El peso
de cada rasgo es una decisión filológica del equipo, no técnica** (¿una diferencia de
metro pesa más que una de rima? casi seguro sí, pero cuánto lo decide el equipo). La matriz
es el lugar donde el criterio metrista se vuelve operativo y debe documentarse de forma
explícita y revisable.

**Generación y almacenamiento:** una vez existan los rasgos en `vocabularios`, la matriz
es un subproducto automático: tabla `formas_distancia(forma_a, forma_b, distancia)` o, dado
que con ~50 formas son ~2500 celdas, un único jsonb cacheado. Se regenera cuando cambian
los rasgos o se añade una forma. Es pequeña y estable.

**Una sola matriz, dos usos:** la misma `formas_distancia` alimenta la distancia
composicional (§3.2) y la secuencial (§3.4). La misma noción de "cercanía entre formas"
gobierna ambos análisis, lo que da coherencia.

### 3.2 Distancia composicional entre obras

Cuando exista `formas_distancia`, la distancia composicional pasa de coseno a
**transporte óptimo** (Earth Mover's / Wasserstein) sobre los perfiles `perfil_formas`
normalizados, usando `formas_distancia` como coste de mover masa entre formas. Resultado:
"esta obra usa romance donde aquella usa redondilla" es diferencia pequeña; "romance vs
soneto" es grande. Es la geometría que un metrista reconocería.

**Antes de que existan los rasgos** (estado actual): se usa coseno plano sobre
`perfil_formas` como aproximación provisional, documentado como limitación conocida
(trata todas las formas como igual de distintas). El cambio de coseno a transporte óptimo
**no requiere migración de datos**: `perfil_formas` ya contiene lo necesario; solo cambia
la función de distancia cuando la matriz esté disponible.

### 3.3 Mejora intermedia sin rasgos (opcional)

Si se quiere algo mejor que el coseno plano antes de codificar todos los rasgos: calcular
el perfil también agregado por `tipo_forma` (español/italiano) y por padre, y combinar.
Aprovecha la poca jerarquía existente. Es un puente, no la solución. Prescindible si se
codifican los rasgos pronto.

### 3.4 Distancia secuencial entre obras

Sobre la secuencia ordenada de formas extraída de `tramos`. Algoritmo a validar con datos
reales (Levenshtein plano, Levenshtein ponderado, o Needleman-Wunsch). El **Levenshtein
ponderado usa `formas_distancia` como coste de sustitución**: sustituir una forma por otra
cercana cuesta menos que por una lejana. Misma matriz que la composicional.

**Aviso sobre longitud de tramo:** Levenshtein/Needleman-Wunsch sobre la secuencia de
formas **ignoran cuántos versos dura cada tramo**. Dos obras con idéntica secuencia de
formas pero longitudes muy distintas (un romance de 800 versos vs uno de 40) saldrían
idénticas. Si eso importa filológicamente —probablemente sí—, la secuencia que alimenta el
algoritmo debe incorporar la duración (p. ej. ponderar cada símbolo por su número de
versos, o alinear sobre series de versos en lugar de series de tramos). **Decidir esto
antes de fijar el algoritmo**, porque condiciona cómo se procesa `tramos`. `tramos` ya
guarda `i` y `f`, así que la longitud está disponible sin cambios de esquema.

### 3.5 Distancia entre autores

Hereda los problemas de la distancia entre obras y añade dos propios:

- **Agregación**: el perfil de un autor no es el promedio de los perfiles de sus obras.
  Hay que decidir si se pondera por obra (una obra = un voto) o por extensión (un verso =
  un voto). Las dos dan resultados distintos. **Decisión a tomar una vez, documentar, y
  precomputar** (§4), no improvisar en cada vista.
- **Fiabilidad**: comparar un autor con 30 obras catalogadas contra uno con 1 obra produce
  una distancia donde un extremo es robusto y el otro es ruido. La distancia entre autores
  solo tiene sentido por encima de cierto volumen de obra catalogada.

> **Decisión tomada:** se precomputa el **perfil de autor** (§4) ahora, porque la decisión
> de agregación debe ser única y coherente entre la ficha de autor y el laboratorio. Pero
> **no se expone distancia entre autores** hasta tener volumen suficiente por autor. El
> perfil se guarda; la comparación entre autores se pospone.

---

## 4. Nueva tabla: `autores_resumen`

Perfil métrico agregado por autor, para las fichas de autor y para análisis de autor en el
laboratorio. Se precomputa porque la agregación tiene una decisión metodológica que debe
ser única y coherente en todas las vistas.

### 4.1 Columnas

- `autor_id` — uuid, PK, FK a `autores.autor_id`
- `n_obras` — int. Obras catalogadas y publicadas del autor.
- `total_versos_autor` — int. Suma de versos de sus obras.
- `perfil_formas` — jsonb. Perfil agregado `{forma_slug: n_versos}`.
  **Ponderación: por extensión (un verso = un voto)** salvo decisión contraria del equipo;
  documentar la elección aquí cuando se confirme.
- `numero_efectivo_formas_medio` — float. Media del número efectivo de formas de sus obras.
  Mide la diversidad métrica típica de una obra suya (distinto de la diversidad de su
  producción total agregada).
- `numero_efectivo_formas_agregado` — float. Número efectivo calculado sobre el
  `perfil_formas` agregado del autor. Mide la diversidad de su repertorio total.
- `fiabilidad` — text o int. Indicador de cuánta obra sustenta el perfil (p. ej. nº de
  obras, o un nivel bajo/medio/alto). Para que las vistas marquen perfiles poco fiables.
- `metrica_sucia` — boolean. Marcado cuando se recalcula cualquiera de sus obras.
- `actualizado_en` — timestamptz.

### 4.2 Mantenimiento

Cuando `recompute_obra_resumen(obra_id)` se ejecuta, marca `autores_resumen.metrica_sucia`
para los autores de esa obra (via `atribuciones` → `atribucion_autores`). El recálculo del
perfil de autor se hace en la misma operación del botón o en un paso encadenado. La
distancia entre autores **no se calcula ni se guarda** (ver §3.5).

---

## 5. Trigger de suciedad en `secuencias_metricas`

`AFTER INSERT OR UPDATE OR DELETE` en `secuencias_metricas`. Para la `obra_id` afectada:

```
UPDATE obras_resumen SET metrica_sucia = true WHERE obra_id = <afectada>
```

Solo toca el flag. No recalcula. Write barato que no interfiere con el autosave. Si no
existe fila para esa obra (obra nueva nunca publicada), no hace nada.

---

## 6. Función `recompute_obra_resumen(obra_id)`

Recalcula y escribe todos los campos de `obras_resumen` para una obra. Se llama desde el
backend al pulsar "Actualizar datos públicos".

### 6.1 Qué lee
- `secuencias_metricas` WHERE `obra_id = $1` (principal)
- `vocabularios` (slugs, `tipo_forma`, identificación de formas cantadas)
- `estrofa_tipo_metros` + `vocabularios` (metros)
- `secuencias_caracterizaciones_rango` (variaciones, pendiente de confirmar)
- `jornadas` WHERE `obra_id = $1` (n_jornadas)

### 6.2 Qué calcula
1. Agrega secuencias: cuenta, suma versos, agrupa por forma.
2. Resuelve slugs desde `vocabularios`.
3. Fusiona tramos contiguos → `tramos` (jsonb).
4. `perfil_formas` (jsonb).
5. `n_formas_distintas`, `p_max`, `densidad_transiciones`.
6. `numero_efectivo_formas`: H = −Σ pᵢ ln pᵢ sobre proporciones de versos por forma;
   resultado = exp(H). **Sin denominador V.**
7. `pct_cantado` (pendiente: qué identifica las formas cantadas).
8. Arrays de filtro: `formas_presentes`, `metros_presentes`, `tipos_forma_presentes`,
   `variaciones_presentes`.
9. Flags de contexto dramático.
10. UPSERT en `obras_resumen`; `metrica_sucia = false`, `actualizado_en = now()`.
11. Marca `autores_resumen.metrica_sucia` para los autores de la obra.
12. Actualiza `obras_similares` para esta obra (§7), con la distancia disponible.

### 6.3 `recompute_all()`
Recorre todas las obras publicadas. Uso: reconstrucción tras inconsistencia, o cuando
cambie algo global. **Nota:** al haber adoptado `numero_efectivo_formas` (independiente de
V), **ya no hace falta recalcular todo el corpus al añadir formas al vocabulario** por
razón de la métrica de diversidad. Sí habrá que regenerar `formas_distancia` y, con ella,
`obras_similares`, cuando se añadan formas o se editen sus rasgos.

---

## 7. Tabla `obras_similares` (top-N más cercanas)

Almacena las obras más cercanas a cada obra. Alimenta la vista "más cercanas" del
laboratorio. **Revisada para evitar falsos hallazgos.**

### 7.1 Columnas
- `obra_id` — uuid, FK
- `similar_obra_id` — uuid, FK
- `tipo_distancia` — text: `'composicional'` / `'secuencial'`. Se guardan ambas.
- `similitud` — float [0–1]. **Se expone siempre en la UI, no solo el ranking.**
- `rank` — smallint.
- PK: `(obra_id, similar_obra_id, tipo_distancia)`

### 7.2 Cuántas y cuáles
Top-10 por obra y por tipo de distancia (la UI muestra 5; el margen permite ajustar sin
migración). Para 3000 obras × 2 distancias × 10 = 60.000 filas, ~4MB.

### 7.3 Problema del top-N y decisiones para no inducir a error

Un "top-5" siempre devuelve cinco obras, exista o no parecido real. En un corpus métrico
homogéneo —y el teatro áureo en romance y redondilla lo es— casi todas las obras se parecen
mucho en distancia composicional, y el top-5 composicional se vuelve ruido: las diferencias
entre la 1ª y la 5ª son insignificantes. Decisiones:

1. **Mostrar siempre el valor de `similitud`** junto a cada obra, no solo el orden.
2. **Umbral configurable**: por debajo de cierta similitud la vista dice "no hay obras
   métricamente cercanas a esta" en lugar de rellenar con las menos lejanas. El umbral es
   empírico (se fija con el corpus real); la arquitectura ya lo permite al guardar
   `similitud`. El top-N puede devolver menos de cinco o ninguna.
3. **La distancia secuencial discrimina más** en un corpus composicionalmente homogéneo
   (distingue obras con el mismo repertorio pero distinta arquitectura). Por defecto, la
   vista "más cercanas" debería priorizar la secuencial, o al menos dejar claro cuál
   discrimina más. Por eso se guardan ambas.

### 7.4 Asimetría
`recompute_obra_resumen` actualiza solo las filas de la obra recalculada, no las de las
demás respecto a ella. `obras_similares` es asimétrica hasta un `recompute_all()`. Trade-off
aceptable; documentarlo. Mientras `formas_distancia` no exista, la similitud composicional
se calcula con coseno provisional (§3.2).

---

## 8. El botón "Actualizar datos públicos"

### 8.1 Ubicación y permisos
Dashboard de edición de cada obra. Visible para editor asignado y admin.

### 8.2 Estado visual
- Desactivado / "Datos públicos al día": `metrica_sucia = false`.
- Activo / "Hay cambios sin publicar": `metrica_sucia = true`.
- Loading durante el recompute. Error sin limpiar el flag si falla.

### 8.3 Condición
Solo tiene efecto si `estado = publicado`. En revisión/borrador, bloqueado con tooltip.

### 8.4 Flujo backend
Recibe `obra_id`, verifica permiso, llama a `recompute_obra_resumen(obra_id)` via RPC,
devuelve resultado. Encadena el recálculo de `autores_resumen` de los autores afectados.
Sin exportación a estáticos por ahora.

---

## 9. Cómo consume cada superficie

### 9.1 Buscador / catálogo
JOIN `obras` + `obras_resumen`, filtrado y ordenado sobre campos precomputados.

| Filtro UI | Fuente |
|---|---|
| Título (fuzzy) | `obras.titulo`, `titulo_normalizado`, `variantes_titulo` |
| Autor | `autores` via `atribuciones` |
| Datación | `obras.fecha_inicio_trad`, `fecha_fin_trad` |
| Género | `obras.genero_id` |
| Formas estróficas | `formas_presentes && array[...]` |
| Metros | `metros_presentes && array[...]` |
| Tipo de forma | `tipos_forma_presentes && array[...]` |
| Versos partidos | `tiene_versos_partidos` |
| Densidad de transiciones (slider) | `densidad_transiciones BETWEEN x AND y` |
| Variaciones | `variaciones_presentes && array[...]` |
| Cambios de espacio | `tiene_cambio_espacio` |
| Género personajes | `intervencion_femenina IN (...)` |
| Donaire | `intervencion_donaire IN (...)` |
| Sobrenaturales | `intervencion_sobrenaturales IN (...)` |
| Total versos | `total_versos BETWEEN x AND y` |
| Nº jornadas | `n_jornadas IN (...)` |

| Orden UI | Columna |
|---|---|
| Autor | `obras.autor_ficha_publico` |
| Título | `obras.titulo_normalizado` |
| Fecha | `obras.fecha_inicio_trad` |
| Nº versos | `total_versos` |
| Diversidad métrica | `numero_efectivo_formas` |
| Densidad de transiciones | `densidad_transiciones` |
| Última actualización | `obras.updated_at` |

> **Nota de UI sobre "polimetría":** el slider que el spec del buscador llamaba "polimetría"
> debe renombrarse. Hay dos ejes distintos y conviene no fundirlos: **diversidad métrica**
> (`numero_efectivo_formas`, cuántas formas y cuán repartidas) y **densidad de transiciones**
> (`densidad_transiciones`, con qué frecuencia se cambia de forma). Decidir cuál o cuáles
> se exponen y con qué etiqueta clara.

Datos por obra en la query de catálogo: `obra_id`, `titulo`, `autor_ficha_publico`,
fechas, género, `total_versos`, `n_jornadas`, `n_formas_distintas`,
`numero_efectivo_formas`, `densidad_transiciones`, `tramos`, `formas_presentes`.

### 9.2 Fichas de obra
RPC `get_obra_ficha_publica` existente para el payload. El barcode lee `tramos` de
`obras_resumen` en vez de recalcular. Caché HTTP agresiva o ISR con revalidación al pulsar
el botón.

### 9.3 Fichas de autor
Leen `autores_resumen`: `perfil_formas` agregado para el gráfico de perfil, `n_obras`,
`total_versos_autor`, las dos medidas de número efectivo. Marcar visualmente si
`fiabilidad` es baja. **Sin distancia a otros autores** por ahora.

### 9.4 Laboratorio — carga inicial
Query única sobre los `obra_id` seleccionados, trayendo de `obras_resumen`:
`total_versos`, `n_secuencias`, `n_formas_distintas`, `p_max`, `numero_efectivo_formas`,
`densidad_transiciones`, `pct_cantado`, `tramos`, `perfil_formas`. Más `obras_similares`
si se usa la vista de cercanía. No hay más queries durante la sesión.

### 9.5 Laboratorio — distancia composicional
Con `formas_distancia` disponible: transporte óptimo sobre `perfil_formas` normalizados.
Provisionalmente (sin rasgos): coseno plano, marcado como aproximación. Cálculo en cliente
para selecciones pequeñas; endpoint de Vercel si la selección crece (timeout 10s).

### 9.6 Laboratorio — distancia secuencial
Sobre la secuencia de `tramos`. Algoritmo por validar; el ponderado usa `formas_distancia`.
Resolver antes el tratamiento de la longitud de tramo (§3.4).

### 9.7 Laboratorio — UMAP / scatter
Matriz de distancias (composicional) → proyección UMAP en cliente (`umap-js`). Selecciones
grandes (>100 obras): evaluar mover a endpoint.

### 9.8 Laboratorio — "más cercanas"
Lee `obras_similares` filtrando por `tipo_distancia`. Muestra `similitud`. Aplica umbral
(§7.3): puede devolver menos de cinco o ninguna. Prioriza secuencial por defecto.

### 9.9 Laboratorio — matriz de calor
En cliente desde las distancias ya calculadas (§9.5, §9.6). Dos pestañas. Sin query extra.

---

## 10. Medidas disponibles por superficie

### Por obra (en `obras_resumen`)
| Medida | Columna | Para |
|---|---|---|
| Total versos | `total_versos` | Buscador, Laboratorio |
| Nº secuencias | `n_secuencias` | Laboratorio |
| Nº formas distintas | `n_formas_distintas` | Buscador, Laboratorio |
| Forma dominante | `p_max` | Laboratorio |
| Diversidad métrica | `numero_efectivo_formas` | Buscador (orden), Laboratorio |
| Densidad transiciones | `densidad_transiciones` | Buscador (filtro), Laboratorio |
| % cantado | `pct_cantado` | Laboratorio |
| Perfil métrico | `perfil_formas` | Laboratorio (distancias, UMAP) |
| Secuencia de formas | `tramos` | Barcode, distancia secuencial |

### Por jornada
No precomputado. Si el laboratorio lo pide, tabla `jornadas_resumen` análoga, alimentada
por la misma función. Pendiente de demanda.

### Por autor (en `autores_resumen`)
Perfil agregado, volumen, diversidad media y agregada, fiabilidad. Distancia entre autores
pospuesta.

### Del corpus
No precomputado. Agregados globales (frecuencia por forma, evolución temporal, distribución
por género) por GROUP BY sobre `obras_resumen` en cliente o RPC. Se materializan solo si la
latencia lo exige.

---

## 11. Pendientes que requieren confirmación en el código real

1. **Rasgos métricos en `vocabularios`**: rima, metro, naturaleza estrófica, tamaño
   estrófico. **No existen aún; se codificarán manualmente.** Bloquean `formas_distancia`
   y, por tanto, las distancias ponderadas (composicional por transporte óptimo y secuencial
   ponderada). Hasta entonces, coseno plano provisional. **Este es el trabajo previo que
   desbloquea la calidad de todo el análisis de distancias.**
2. **Pesos de los rasgos** en la distancia entre formas: decisión filológica del equipo,
   documentar de forma explícita y revisable.
3. **Tratamiento de la longitud de tramo** en la distancia secuencial (§3.4): decidir antes
   de fijar el algoritmo.
4. **Ponderación del perfil de autor** (§4.1): por obra o por extensión. Decisión única.
5. **Formas cantadas**: qué `categoria`/`etiqueta` de `vocabularios` las identifica
   (para `pct_cantado`).
6. **Fuente de `variaciones_presentes`**: `secuencias_variaciones` no existe en el esquema;
   confirmar si es `secuencias_caracterizaciones_rango` o tabla por crear.
7. **Categoría de formas estróficas** en `vocabularios` (para filtrar al agregar perfiles).
8. **Slugs vs UUIDs en arrays de filtro**: confirmar que `vocabularios.termino` es único y
   estable; si hay riesgo de renombrado, usar `termino_id` y resolver etiqueta en cliente.
9. **RLS sobre `obras_resumen` y `autores_resumen`**: SELECT anónimo solo para obras
   públicas, alineado con la política de `obras`.

---

## 12. Camino futuro (no implementar ahora)

- **Estáticos**: si el corpus supera ~500 obras y el compute se nota, añadir al botón un
  paso de exportación de `obras_resumen` a JSON (Supabase Storage o R2). El frontend lee el
  JSON; la query a Supabase queda como fallback. Sin cambios de tabla ni de la función de
  recompute.
- **Distancia secuencial precomputada** para corpus grande: calcular el algoritmo pesado
  (Needleman-Wunsch ponderado) offline y poblar `obras_similares` con `tipo_distancia =
  'secuencial'`.
- **Similitud entre formas derivada de datos** (coocurrencia/contexto) en vez de solo de
  rasgos: solo con corpus grande, y como objeto de investigación, no como infraestructura.
  Riesgo de circularidad con corpus pequeño.
- **Distancia entre autores**: cuando haya volumen suficiente de obra por autor.