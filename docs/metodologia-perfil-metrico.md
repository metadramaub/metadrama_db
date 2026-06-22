# Metodología del perfil métrico (obra y autor)

> **Para qué sirve este documento.** Recoge las **decisiones metodológicas** detrás de los
> datos precomputados (`obras_resumen`, `autores_resumen`): qué mide cada cosa, cómo se calcula
> y, sobre todo, **por qué** se decidió así. El [plan de implementación](plan-precomputacion-implementacion.md)
> dice *qué* se hace y *en qué estado* está; este dice *por qué* y con qué criterio, para poder
> recordar y defender las decisiones cuando el corpus crezca o haya que revisarlas.
>
> **Fuente de verdad del cálculo precomputado:** las funciones SQL de las migraciones
> (`recompute_obra_resumen`, `recompute_autor_resumen`). Si este documento y el SQL difieren,
> manda el SQL y se corrige aquí. Las distancias provisionales del laboratorio (§4) son una
> excepción deliberada: se calculan en cliente desde `src/lib/laboratorio/distancias.ts`, sin
> persistirse en tablas.
>
> **Principios rectores:**
> 1. **La DB es la fuente de verdad** de campos y vocabularios; no se inventan equivalencias.
> 2. **No falsear datos:** nunca se atribuye una métrica a una autoría que no está establecida,
>    ni se presenta como "típico" algo calculado sobre una muestra que no lo soporta.
>
> **Documento vivo.** Es el lugar **canónico** donde se anota *qué se cuantifica, cómo y por qué*.
> Cada vez que se añada o cambie una medida, algoritmo o agregación (en obra, autor o lo que venga),
> **anótese aquí** la definición y su justificación. Si una medida se calcula pero no está descrita
> abajo, falta documentarla.

---

## 1. Métricas a nivel de obra (`obras_resumen`)

Canon del cálculo:
[20260618220000_obras_resumen_nucleo.sql](../supabase/migrations/20260618220000_obras_resumen_nucleo.sql)
(métricas) y [20260619143000_obras_resumen_estructura_barcode.sql](../supabase/migrations/20260619143000_obras_resumen_estructura_barcode.sql)
(cortes de estructura). La **fuente de datos** es `secuencias_metricas` (una fila por secuencia
métrica: rango `v_ini`–`v_fin`, `n_versos`, `estrofa_tipo_id`, flags, intervenciones…), más las
tablas satélite que se citan en cada medida.

### 1.0 Arquitectura del recompute

`recompute_obra_resumen(obra)` es un **wrapper** estable (el que llaman endpoints, dashboard y
`recompute_all`) que ejecuta dos pasos:
- `recompute_obra_resumen_metricas` — todas las medidas de §1.2–§1.8.
- `recompute_obra_resumen_estructura` — solo los cortes `jornadas_tramos`/`cuadros_tramos` (§1.7).

*Por qué separados:* la estructura se añadió después (mini-barcode del catálogo) y es un cálculo
barato e independiente; partirlo evita reescribir la función métrica grande. El resumen se
**recalcula entero al pulsar el botón**, no en el autosave; un trigger en `secuencias_metricas`
(y tablas satélite) solo marca `metrica_sucia` (write barato).

### 1.1 Resolución de forma (forma raíz)

La forma de una secuencia es el **padre** del `estrofa_tipo` si existe (p. ej. `romance_e-a` →
`romance`); si no, la forma misma. Jerarquía real: **dos niveles** (padre → hijo) + `tipo_forma`
(`forma_espanola` / `forma_italiana`); la rima del hijo va en `patron_especifico` ('e-a', 'i-o').
Todas las medidas por forma usan esta **forma raíz**.
> **`irregular`** es un `estrofa_tipo` real y aparece con normalidad en formas/tramos, pero **no es
> una forma comparable** (denota pasaje métricamente irregular). No se toca en las medidas de datos;
> habrá que tratarlo aparte al construir distancias entre formas (Fase 8).

### 1.2 Extensión y estructura

- **`total_versos`** = `sum(n_versos)` de las secuencias. *No* se usa `obras.total_versos`
  (nullable, mantenimiento incierto). Decisión 0.5 del plan abierta para reconciliarlos.
- **`n_secuencias`** = nº de secuencias métricas.
- **`n_jornadas`** = nº de jornadas de la obra.

### 1.3 Diversidad métrica

- **`n_formas_distintas`** = nº de formas raíz distintas. Recuento simple (sensible a la longitud:
  obras largas tienden a más formas). Útil como cifra cruda, no como medida de diversidad.
- **`numero_efectivo_formas`** = `exp(H)`, con `H = −Σ pᵢ·ln pᵢ` sobre las **proporciones de versos
  por forma**. Número de Hill de orden 1 (= "número efectivo de formas").
  - *Por qué este y no `n_formas_distintas`:* es **robusto a la longitud** (no crece sin límite con
    los versos) y mide el **reparto** (dominancia/uniformidad), no el recuento. Una obra con 8
    formas donde una copa el 95 % tiene diversidad efectiva ≈ 1; otra con 3 formas al 33 % ≈ 3.
  - *Sin denominador V:* no depende del tamaño del vocabulario, así que **añadir formas nuevas al
    vocabulario no obliga a recalcular** el corpus por esta métrica.
  - Excluye del cálculo las secuencias sin forma asignada.
- **`p_max`** = proporción de versos de la forma dominante (∈ (0, 1]). Complementa al número
  efectivo: distingue "una forma manda" (p_max alto) de reparto plano (p_max bajo).

### 1.4 Densidad / ritmo de cambio métrico

- **`densidad_transiciones`** = `(n_secuencias / total_versos) × 100`. Cambios métricos por cada 100
  versos: alta = polimetría "picada" (muchos tramos cortos); baja = tiradas largas de una forma.

### 1.5 Caracterizaciones por rango (`secuencias_caracterizaciones_rango`)

Estas no dependen de la forma, sino de rangos `v_ini`–`v_fin` declarados sobre la secuencia, con un
`tipo_caracterizacion_rango` del vocabulario `caracterizacion_rango`.

- **`pct_cantado`** = versos en rangos de tipo **`cantado`** / `total_versos`. "Cantado" **no es una
  forma** (error frecuente): es un término de `fenomenos_enunciativos` (hijo de `caracterizacion_rango`).
  Calcularlo desde la forma daría siempre 0.
- **`variaciones_presentes`** (array) = términos de `caracterizacion_rango` usados en la obra, para
  filtrar. Familias reales: `fenomenos_enunciativos` (cantado, prosa), `irregularidades_metricas`
  (hipometrico, hipermetrico, rima_defectuosa, laguna), `final_acentual` (mayoria_agudas,
  mayoria_esdrujulas). (Sustituye a la tabla `secuencias_variaciones`, ya inexistente.)

### 1.6 Contexto dramático

- **`intervencion_femenina` / `intervencion_donaire` / `intervencion_sobrenaturales`**: el enum real
  es **por secuencia** (`sin_intervencion | exclusiva | compartida`). Agregado a nivel de obra: si
  coexisten `exclusiva` y `compartida` → **`mixta`**; si solo una → esa; si ninguna →
  `sin_intervencion`. (No existen 'ninguna' ni 'mixta' a nivel de secuencia; 'mixta' es solo el
  agregado de obra.)
- **`tiene_versos_partidos`** = `bool_or(versos_partidos)` sobre las secuencias.
- **`tiene_cambio_espacio`** = `bool_or(inaugura_espacio)` sobre las secuencias.

### 1.7 Visualización: barcode métrico y cortes estructurales

- **`tramos`** (jsonb) = barcode de formas. Tramos **contiguos de la misma forma raíz se fusionan**
  con el algoritmo estándar de *islas* (gaps-and-islands: `rn − row_number() over (partition by
  forma)` es constante dentro de cada racha contigua). Cada tramo: `{i: v_ini, f: v_fin, s:
  forma_slug, t: tipo_forma}`. Sustituye el cálculo en vivo que antes hacía el cliente.
- **`perfil_formas`** (jsonb) = `{forma_slug: n_versos}`. Es la base del número efectivo y del
  perfil de autor (§2.2). No fusiona: suma versos por forma en toda la obra.
- **`jornadas_tramos`** (jsonb) = `[{i: v_ini, f: v_fin, n: jornada_num}]`. Cortes de jornada para
  pintar divisiones sobre el mini-barcode del catálogo.
- **`cuadros_tramos`** (jsonb) = `[{i, f, n: cuadro_num, j: jornada_num}]`. Cortes de cuadro.

### 1.8 Arrays de filtro (facetas del catálogo)

Guardan **slugs** (`termino`) para filtrar por solapamiento (`&&`/GIN). La etiqueta visible se
resuelve en lectura (§1.9):
- **`formas_presentes`** — formas raíz presentes.
- **`tipos_forma_presentes`** — `forma_espanola` / `forma_italiana`.
- **`metros_presentes`** — vía la tabla `estrofa_tipo_metros` (estrofa_tipo ↔ metro). **Cobertura
  parcial**: en el seed solo romance↔octosílabo y silva↔hepta/endecasílabo; muchas formas aún sin
  metro asignado → se aceptan vacíos, no se inventan.
- **`variaciones_presentes`** — §1.5.
- **`subtipos_presentes`** — subtipos de estrofa (p. ej. subquintillas) vía `secuencias_subtipos_estrofa`,
  filtrables como las variaciones. En el catálogo cuelgan bajo su forma raíz en el selector jerárquico.

### 1.9 Slugs vs etiquetas

Las tablas precomputadas guardan **`termino`** (slug, clave estable), **nunca `etiqueta`** (editable
→ quedaría obsoleta al renombrar). La etiqueta visible se resuelve **en lectura** desde el
vocabulario, vía un loader cacheado (TTL 60s, invalidado en mutaciones de vocabulario). *Riesgo
conocido:* si se renombra un `termino`, los arrays quedan obsoletos hasta el siguiente recompute;
se asume y, si hace falta, se fuerza `recompute_all()`.

### 1.10 Derivados en el catálogo (no son columnas)

El catálogo **consume** lo anterior sin añadir dato nuevo: mini-barcode (`CatalogMetricBar` /
`MetricBarcode`) desde `tramos`(+cortes), chips de diversidad/densidad/nº formas, orden por
`diversidad` (`numero_efectivo_formas`) o `densidad` (`densidad_transiciones`), y facetas de filtro
desde los arrays de §1.8. Todo *gated* por la visibilidad de secciones públicas.

---

## 2. Perfil métrico de autor (`autores_resumen`)

El perfil de un autor **no es el promedio de los perfiles de sus obras**: la agregación tiene
decisiones metodológicas que deben ser **únicas y coherentes** en todas las vistas (ficha de
autor y laboratorio). Por eso se precomputa. Decisiones cerradas el **2026-06-19**.

### 2.1 Qué obras alimentan el perfil — regla de atribución mono-autor

> **Principio:** una unidad métrica cuenta para un autor **solo si su autoría es inequívoca y
> de un solo autor en ese ámbito**. Nunca se reparte la métrica de una obra entre coautores ni
> se atribuye a una propuesta de autoría dudosa.

Modelo real de autoría: `obras → grupos_atribucion → atribuciones → atribucion_autores → autores`.
- El **scope** lo fija el grupo (`grupos_atribucion` tiene XOR `obra_id`/`jornada_id`): hay grupos
  de **obra** y grupos de **jornada**.
- Un grupo puede tener **varias atribuciones rivales** (propuestas).
- `atribuciones.perfil_metrico` (boolean) marca **la** atribución elegida como base del análisis
  métrico. (Es el flag canónico; `usable_perfil_metrico`/`atribucion_preferente` ya no existen.)
- Una atribución puede listar **varios autores** (`composicion_autoria = colaborada`).

**Unidad atribuible a un autor X** = un grupo que cumple **las dos** condiciones:
1. tiene **exactamente una** atribución con `perfil_metrico = true`, y
2. esa atribución tiene **exactamente un** autor, que es X.

De ahí:
- **Grupo de obra** mono-autor → cuenta **toda la obra** para X.
- **Grupo de jornada** mono-autor → cuenta **esa jornada** para X (comedias en colaboración).
- **Obra con ≥2 autores a nivel obra** (atribución de obra colaborada, o varias propuestas) →
  **no cuenta a nivel obra para nadie**; solo cuentan sus jornadas que sean mono-autor.

*Por qué:* atribuir la métrica de una obra colaborada a uno de sus autores falsearía su perfil;
atribuirla a "propuestas" dudosas convertiría hipótesis en dato. La regla es deliberadamente
conservadora: ante la duda, no cuenta.

### 2.2 Ponderación: **por extensión** (un verso = un voto)

`perfil_formas` agregado del autor = **suma de versos por forma** sobre todas sus unidades.
- *Por qué:* es la opción que el documento de estrategias recomienda y la más natural de
  agregar; refleja el peso real de cada forma en su producción.
- *Alternativa descartada:* "por obra" (normalizar cada obra al 100 % y promediar) daría el
  mismo voto a una loa de 200 versos que a una comedia de 3000. Si en el futuro se quiere esa
  lectura, ya la aporta el `numero_efectivo_formas_medio` (§2.3), sin necesidad de cambiar la
  ponderación del perfil.

### 2.3 Dos medidas de diversidad — y por qué las jornadas se tratan distinto

Son **dos métricas con dominios distintos**, no redundantes:

| Métrica | Sobre qué se calcula | Qué responde |
|---|---|---|
| `numero_efectivo_formas_agregado` | El `perfil_formas` agregado de **todas** las unidades (obras enteras **+** jornadas sueltas) | "¿Cómo de variado es **todo su repertorio**?" |
| `numero_efectivo_formas_medio` | Media del nº efectivo **solo de sus obras enteras** mono-autor (jornadas sueltas **excluidas**) | "¿Cómo de variada es **una obra típica** suya?" |

**Por qué las jornadas entran en el agregado pero NO en la media** (decisión clave, 2026-06-19):
- En el **agregado** no hay problema: sumar versos por forma es asociativo, da igual cómo se
  agruparan; es un único reparto sobre todo el material atribuido.
- En la **media** sí: una **jornada suelta es una muestra truncada y sesgada** de la estructura
  métrica de una obra (una jornada puede estar dominada por una forma por diseño dramático). Su
  número efectivo **no es comparable** con el de una obra completa; promediarlos juntos
  contaminaría la media con un sesgo estadístico. Por eso "diversidad de una obra típica" se
  calcula **solo sobre obras completas**.
- Si un autor **no tiene ninguna obra entera propia** (solo fragmentos de colaboradas),
  `numero_efectivo_formas_medio` queda **NULL → "no aplicable"**, dicho con honestidad, en vez
  de inventar un valor.

> **Nota de recall.** El default es: jornadas **incluidas en el agregado, excluidas de la media**.
> Si en el futuro las jornadas sueltas resultan problemáticas también para el agregado (p. ej.
> demasiadas y muy sesgadas), la decisión sería excluirlas del todo del perfil del autor — es un
> cambio acotado en `recompute_autor_resumen`. Hoy **no** se excluyen del agregado.

### 2.4 Dos alcances: `publico` y `completo`

El perfil depende del **rol** del que mira, igual que la visibilidad de `obras`:

| `alcance` | Agrega sobre | Lo ve |
|---|---|---|
| `publico` | Obras **publicadas y visibles** | anónimo y usuario logueado |
| `completo` | **Todas** las obras publicadas (incl. no visibles) | admin / IP |

- *Por qué dos:* un agregado no se puede "des-sumar". Para que admin/IP vean el perfil con obras
  aún no visibles **sin** filtrar esos datos al público, hay que materializar **dos** agregados.
- *Para qué el `completo`:* admin/IP **previsualizan cómo cambiará el perfil de un autor al
  publicar una obra nueva antes de hacerla visible a todos** — relevante mientras el corpus crece
  y los datos se mueven mucho.
- Se materializan como **dos filas por autor**, PK `(autor_id, alcance)`. La RLS deja leer las
  filas `publico` a cualquiera y las `completo` solo a admin/IP (`auth_is_admin_or_ip()`), así
  que el reparto por rol es automático y las filas `publico` son **seguras por construcción**.

### 2.5 Fiabilidad: señal cruda + banda derivada en lectura

El perfil de un autor con 1 obra es ruido; con 30, robusto. Para marcarlo:
- **No** se guarda una columna `fiabilidad`. Se guardan las **señales crudas**
  `total_versos_autor` y `n_obras_completas` (+ `n_jornadas_sueltas`).
- La banda **baja / media / alta** se **deriva en la capa de lectura** (TS) desde una **constante
  editable**. *Por qué:* cambiar los umbrales es una decisión de presentación; así se ajusta
  **sin recompute ni migración**, editando un número.
- Umbrales tentativos (a afinar): por `total_versos_autor` — p. ej. `< 1500` baja, `1500–6000`
  media, `> 6000` alta. (Ajustar cuando haya volumen real.)

### 2.6 Mantenimiento e invalidación

- **Botón "Actualizar datos públicos" de una obra** → recalcula esa obra **y** los autores
  afectados (los que tienen alguna unidad mono-autor en ella). Vía `recompute_obra_y_autores`.
- **Cambiar `visible_publico` / `estado` de una obra** → marca a sus autores `metrica_sucia`
  (afecta solo al alcance `publico`). El recálculo ocurre en el **siguiente botón** o en
  `recompute_all`. *Por qué diferido:* coherente con la política de "visibilidad estable, no
  invalidar cachés"; los cambios de visibilidad son raros.
- **`recompute_all`** reconstruye todas las obras y luego todos los autores una sola vez, y borra
  filas de autores que ya no tienen ninguna unidad.

### 2.7 Qué NO se hace (y por qué)

- **Distancia entre autores:** pospuesta hasta tener volumen suficiente por autor (comparar un
  autor de 30 obras con uno de 1 es comparar señal con ruido). Se guarda el perfil; la comparación
  se aplaza.
- **Biografía, fechas de nacimiento/muerte, nota biográfica:** **no hay campo** en `autores`
  (solo nombre, variantes, slug e identificadores de autoridad VIAF/Wikidata/BNE). No se inventa;
  como mucho se enlaza a las autoridades externas desde los IDs existentes.

---

## 3. Ficha de autor: dos conjuntos de obras distintos

Consecuencia directa del principio "no falsear" (§2.1):

| Conjunto | Qué incluye | Para qué |
|---|---|---|
| **Perfil métrico** | Solo unidades mono-autor `perfil_metrico=true` (obras enteras + jornadas sueltas, §2.1) | Los agregados de `autores_resumen` |
| **Obras asociadas** | **Todas** las obras donde el autor aparece en *cualquier* atribución (incl. propuestas rivales, colaboraciones y jornadas) | La lista de la ficha, **etiquetando** cada vínculo |

La ficha **muestra todas** las obras asociadas, pero **marca la naturaleza** de cada vínculo
(segura / propuesta, scope obra / jornada, individual / colaborada) para no dar por cierta una
autoría que no lo es. Las obras asociadas se resuelven **en vivo** y **filtradas por la
visibilidad del visitante**; no se precomputan.

---

## 4. Laboratorio: distancias provisionales entre obras

Primera versión implementada el **2026-06-22** en
[`src/lib/laboratorio/distancias.ts`](../src/lib/laboratorio/distancias.ts). Es una capa
**exploratoria y no persistida**: no crea tablas, no añade endpoint específico y no materializa
similitudes. La página del laboratorio carga obras publicadas con `perfil_formas` y `tramos` desde
`obras_resumen`, aplica la misma lógica de visibilidad que el catálogo y calcula las distancias en
cliente sobre la **selección activa** de obras.

> **Estado metodológico:** estas distancias sirven para exploración y diagnóstico visual, no como
> resultado final estable. La futura fase de distancias entre formas deberá sustituir parte de este
> cálculo por una matriz `formas_distancia`.

### 4.1 Distancia composicional

`distanciaComposicional(perfilA, perfilB)` compara dos perfiles `{forma_slug: n_versos}`:

1. normaliza cada perfil a proporciones, dividiendo los versos de cada forma por el total de versos
   con forma asignada;
2. alinea ambos perfiles sobre la **unión** de formas presentes, dando peso 0 a las formas ausentes;
3. calcula la **divergencia de Jensen-Shannon** con logaritmo en base 2:
   `JS(P,Q) = 1/2 KL(P,M) + 1/2 KL(Q,M)`, con `M = 1/2(P+Q)`;
4. devuelve un valor acotado en `[0,1]`: `0` significa perfiles idénticos y `1`, distribuciones sin
   solapamiento.

*Por qué esta medida provisional:* Jensen-Shannon es simétrica, está acotada y funciona bien para
perfiles de proporciones. Pero trata todas las formas como categorías igualmente separadas: no sabe
que dos formas puedan ser métricamente próximas. Por eso se marca como **provisional**; deberá
sustituirse por transporte óptimo o una medida equivalente cuando exista una matriz
`formas_distancia`.

### 4.2 Distancia secuencial

`distanciaSecuencial(tramosA, tramosB, versosPorSimbolo = 25)` compara la **secuencia de formas** de
dos obras a partir de los `tramos` del barcode (`{i, f, s, t}`). En la interfaz se presenta como
**tamaño de bloque**: cada bloque representa aproximadamente ese número de versos:

1. discretiza cada tramo en una cadena de bloques, repitiendo `s` aproximadamente
   `round((f - i + 1) / versosPorSimbolo)` veces;
2. garantiza un mínimo de 1 bloque por tramo para que los tramos cortos no desaparezcan;
3. calcula una distancia de edición **Levenshtein** entre las dos cadenas, con coste uniforme de
   inserción, borrado y sustitución;
4. normaliza por la longitud de la cadena más larga para devolver un valor en `[0,1]`.

*Qué capta:* a diferencia de `perfil_formas`, conserva una lectura aproximada del orden y la
duración relativa de los bloques métricos. Por ejemplo, dos obras con las mismas formas pero pesos
invertidos (`romance` largo + `redondilla` corta frente a `romance` corto + `redondilla` larga)
deben separarse aunque compartan vocabulario.

*Parámetros provisionales:* `versosPorSimbolo` queda configurable en la interfaz del laboratorio
porque controla la granularidad de la discretización. El coste de sustitución uniforme también es
provisional: en una fase posterior debe ponderarse con `formas_distancia`, para que sustituir dos
formas cercanas no cueste lo mismo que sustituir formas métricamente lejanas.

### 4.3 Visualización actual

Para una selección activa de `N` obras, el laboratorio calcula dos matrices `N × N`, simétricas y con
diagonal 0:

- **matriz composicional**, usando `perfil_formas`;
- **matriz secuencial**, usando `tramos` y el valor configurable de `versosPorSimbolo`.

Se muestran como dos mapas de calor separados, en pestañas independientes. No se calcula ni se
muestra una distancia global combinada. La vista de **obras más cercanas** a una obra de referencia
también se separa por criterio: una lista ordenada por distancia composicional y otra por distancia
secuencial, siempre con el valor numérico de distancia junto al título.

La página añade además un gráfico de puntos **forma × obra** sobre la selección activa, implementado
con ECharts:

- cada fila es una forma métrica presente en alguna obra seleccionada;
- cada columna es una obra seleccionada;
- el tamaño del punto representa el peso proporcional de esa forma dentro de la obra, calculado
  desde `perfil_formas`.

Este gráfico no es una distancia: sirve para inspeccionar visualmente qué formas explican las
proximidades o separaciones que aparecen en las matrices.

También incorpora un gráfico de evolución por **quinquenios**:

- cada obra se asigna a un bloque de cinco años usando `fecha_inicio_trad` y, si falta, `fecha_fin_trad`;
- dentro de cada quinquenio se suman los versos de las obras seleccionadas;
- cada serie representa una forma métrica;
- el valor mostrado es el porcentaje de versos de esa forma sobre el total de versos métricos del
  quinquenio;
- la interfaz permite seleccionar qué formas entran en el gráfico, con accesos rápidos al top 5 y
  top 10 por volumen en la selección.

Este gráfico temporal depende mucho de la selección activa y de la datación disponible. Debe leerse
como exploración de tendencias dentro del subconjunto elegido, no como evolución global del corpus
salvo que la selección cubra el corpus de forma equilibrada.

### 4.4 Qué NO se hace todavía

- No se combinan las dos distancias en un único score.
- No se precomputan pares en una tabla `obras_similares`.
- No se calcula proyección UMAP ni reducción dimensional.
- No se comparan autores por distancia: sigue vigente la cautela de §2.7.
