# Estrategias de precomputación — catálogo, fichas, comparativas, laboratorio

> Documento de **diseño y decisión** (no de implementación). Recoge opciones para
> precalcular agregados métricos/dramáticos y servirlos rápido a escala (hoy ~60
> obras; objetivo ~3000 en pocos años). Léelo con calma; al final hay una tabla
> de decisión y una recomendación por superficie.
>
> **Estado:** propuesta abierta. Nada de esto está implementado todavía.

---

## 0. El problema de fondo

Hoy casi todo se calcula **en cada petición**: la ficha llama a `get_obra_ficha_publica`
(una RPC que recorre secuencias, autoría, distribución de formas…) y el catálogo
hace varias queries en cascada (obras → grupos → atribuciones → autores → géneros).

Con 60 obras esto va sobrado. Con 3000 obras y vistas más ricas (un barcode por
obra en el catálogo, comparativas entre obras, laboratorio de datos), recalcular
todo en cada visita se vuelve:

- **Lento**: agregaciones sobre cientos de miles de filas de `secuencias_metricas`
  en cada carga.
- **Caro**: muchas lecturas repetidas de datos que cambian poco (una obra
  publicada se edita rara vez).
- **Difícil de cachear**: cada filtro/orden distinto es una query distinta.

La idea de la **precomputación**: calcular una vez (al editar/publicar) y guardar
el resultado ya digerido. Las vistas leen ese resultado, no los datos crudos.

### Qué cambia poco y qué se consulta mucho

| Dato | Frecuencia de cambio | Frecuencia de lectura | ¿Precomputar? |
|---|---|---|---|
| Secuencias de una obra publicada | Muy baja | Alta (ficha, catálogo, lab) | **Sí, claro** |
| Distribución de formas por obra | Muy baja | Alta | **Sí** |
| Conjunto de formas presentes por obra | Muy baja | Alta (filtro métrico) | **Sí** |
| Listado de obras (título, fecha) | Baja | Muy alta | Quizá (vista materializada) |
| Comparativas entre N obras | N/A (derivado) | Media | Derivar de agregados |

Regla general: **precomputa lo que se lee mucho y cambia poco**. Lo que cambia en
cada request (p. ej. el filtrado por el viewer) no se precomputa, se filtra sobre
datos ya precomputados.

---

## 1. Las cuatro estrategias base

Antes de ir superficie por superficie, conviene tener claras las cuatro técnicas.
Casi todo el documento es combinarlas.

### A) Columna/tabla de agregados por obra (snapshot)

Una tabla `obras_metrica_resumen` (o columnas `jsonb` en `obras`) con el resultado
ya calculado **por obra**: perfil de formas, barcode resumido, conjunto de formas
presentes, totales… Se **recalcula con un trigger** cuando cambian las secuencias
de esa obra, o con una función que se llama al publicar.

- **Pro**: lectura O(1) por obra; el catálogo trae 1 fila ligera por obra.
- **Pro**: escala a miles de obras sin tocar el coste de lectura.
- **Contra**: hay que mantener la coherencia (triggers o recálculo explícito).
- **Contra**: requiere migración y disciplina ("¿quién recalcula y cuándo?").

### B) Vista materializada (materialized view)

Postgres guarda el resultado de una query compleja como una tabla física, que se
**refresca** (manual, por cron, o `REFRESH ... CONCURRENTLY`).

- **Pro**: defines la lógica como SQL una vez; Postgres gestiona el almacenamiento.
- **Pro**: ideal para listados/agregados globales (catálogo, estadísticas del corpus).
- **Contra**: el refresco es **todo o nada** por vista (no incremental nativo); con
  miles de obras un refresh completo puede ser pesado si es muy frecuente.
- **Contra**: datos "algo viejos" entre refrescos (aceptable para obras publicadas).

### C) Caché HTTP / CDN (lo que ya hacéis)

Cabeceras `cache-control` con `s-maxage` + `stale-while-revalidate`. El catálogo ya
las usa (`s-maxage=300, stale-while-revalidate=600`). No precomputa en BD, pero
evita recalcular en cada visita anónima.

- **Pro**: cero esquema, ya está en marcha; absorbe picos de tráfico anónimo.
- **Contra**: no ayuda a usuarios logueados (`private, no-store`), ni a queries
  únicas (cada combinación de filtros es otra URL → otra entrada de caché).
- **Rol**: complemento, no sustituto. Cachear **encima** de datos ya precomputados.

### D) Caché de aplicación (memoria/KV)

Guardar en memoria del server (o un KV como Vercel KV/Redis) resultados calculados,
con TTL e invalidación por clave de obra.

- **Pro**: flexible, invalidación fina.
- **Contra**: infra extra; en serverless la memoria no persiste entre invocaciones
  (necesitas KV externo). Probablemente **innecesario** si A/B están bien hechos.

> **Tesis del documento**: la base debe ser **(A) agregados por obra** para lo
> "por obra" y **(B) vista materializada** para lo "global del corpus", con **(C)
> caché HTTP** encima. (D) solo si algo lo pide de verdad.

---

## 2. El barcode del catálogo (caso motivador)

Objetivo: un barcode de obra completa en cada tarjeta del catálogo + filtro por
forma métrica. El problema: 3000 obras × 100-300 secuencias = 300k-900k filas. No
se pueden traer todas en cada carga.

### Qué necesita un barcode, mínimamente

Por obra, una lista de **tramos** `{ v_ini, v_fin, forma_slug, tipo_forma }`
ordenados. **No** hace falta cada secuencia con todos sus campos: para pintar el
catálogo basta el tramo y su color. Los subtipos/caracterizaciones se pueden omitir
en la miniatura del catálogo (se ven en la ficha).

### Opción 2.1 — Barcode resumido precomputado (recomendada)

Tabla nueva:

```
obras_barcode_resumen (
  obra_id            uuid primary key references obras,
  total_versos       int,
  tramos             jsonb,   -- [{ "i": 1, "f": 48, "s": "romance", "t": "forma_espanola" }, ...]
  formas_presentes   text[],  -- ['romance','soneto',...]  (para el filtro)
  perfil_formas      jsonb,   -- { "romance": 1200, "soneto": 56, ... } versos por forma
  actualizado_en     timestamptz default now()
)
```

- El catálogo hace **1 query** (`select obra_id,total_versos,tramos,formas_presentes
  from obras_barcode_resumen where obra_id in (...)`), trayendo un `jsonb` ligero por
  obra (decenas de tramos, no cientos de filas).
- El **filtro por forma** opera sobre `formas_presentes` (array indexable con GIN):
  `where formas_presentes && array['soneto']` → instantáneo.
- Los `tramos` ya traen `forma_slug`+`tipo_forma`, así que el color se resuelve con
  el helper `colorForForma` **sin más datos** (mismo color que ficha/barcode/pie).

**¿Cuánto pesa?** Un barcode resumido tras fusionar tramos contiguos de la misma
forma suele ser ~20-60 tramos. 3000 obras × ~50 tramos × ~40 bytes ≈ pocos MB. Una
página de catálogo (30-100 obras) son KB. Perfectamente manejable.

**¿Cómo se mantiene al día?** Tres sub-opciones (de más simple a más automático):

1. **Recálculo al publicar/editar** (explícito): una función SQL
   `recompute_obra_barcode(obra_id)` que el backend llama tras guardar secuencias o
   al cambiar estado a publicado. Simple y predecible; el editor controla cuándo.
2. **Trigger en `secuencias_metricas`** (automático): `AFTER INSERT/UPDATE/DELETE`
   marca la obra como "sucia" o recalcula su fila. Coherencia fuerte, pero ojo con
   ediciones masivas (recalcular en cada fila es caro → mejor "marcar sucia" +
   recalcular en batch).
3. **Cola de recálculo** (desacoplado): el trigger encola `obra_id`; un job procesa
   la cola. Robusto a escala, más piezas.

> Para vuestro ritmo de edición (obras que se publican y casi no cambian), **la
> opción 1 (recálculo explícito al guardar/publicar)** es la más sencilla y
> suficiente. El trigger se puede añadir después si hace falta.

### Opción 2.2 — Lazy-load por obra visible

El catálogo carga sin barcodes; cada tarjeta pide el suyo al entrar en viewport
(`IntersectionObserver`) a un endpoint `+server.ts` cacheado por CDN.

- **Pro**: cero migración; solo pintas lo que se ve.
- **Contra**: N peticiones (aunque cacheadas), más lógica en cliente, y el **filtro
  por forma no funciona** sin datos agregados (volverías a necesitar A para filtrar).
- **Veredicto**: sirve como paso intermedio, pero como el filtro métrico necesita
  agregados igualmente, mejor ir directo a 2.1.

### Opción 2.3 — Paginación + secuencias de la página

Paginar (p. ej. 30 obras/página) y traer secuencias solo de esas 30.

- **Pro**: limita el volumen por carga sin precomputar nada.
- **Contra**: cambia el modelo actual (hoy es client-side sin paginar); el filtro
  por forma sobre TODO el corpus seguiría necesitando agregados; ordenar por algo
  métrico global obliga a precomputar igualmente.
- **Veredicto**: la paginación es buena idea **además** de 2.1 (no traer 3000
  barcodes de golpe aunque sean ligeros), pero no sustituye la precomputación.

### Recomendación catálogo

**2.1 (barcode resumido precomputado) + paginación + caché HTTP encima.** El filtro
por forma sale gratis del array `formas_presentes`. El selector de formas se
**reutiliza del dashboard** (mismo componente de selección de vocabulario), poblado
con las formas raíz realmente presentes en el corpus.

---

## 3. Fichas de obra

Hoy la ficha llama `get_obra_ficha_publica` por obra. Para **una** obra eso está
bien (es una sola obra, no miles). Pero hay margen:

### 3.1 — Mantener RPC por-obra, pero cachear

La ficha de una obra publicada cambia poco. Cachear la respuesta por `obra_id` (CDN
con `s-maxage` alto + `stale-while-revalidate`, invalidando al editar) evita
recalcular la RPC en cada visita. Bajo coste, alto retorno.

### 3.2 — Snapshot de ficha precomputado

Guardar el `jsonb` completo de la ficha pública en una columna/tabla
`obras_ficha_publica_cache(obra_id, payload jsonb, actualizado_en)`, recalculado al
publicar/editar. La ruta pública leería el snapshot en vez de ejecutar la RPC.

- **Pro**: lectura O(1), sin recorrer secuencias en vivo.
- **Pro**: desacopla "render público" de "lógica de cálculo" (la RPC pasa a ser el
  *generador* del snapshot, no el *servidor* en caliente).
- **Contra**: hay que invalidar/recalcular al editar; el snapshot puede quedar viejo
  si el recálculo falla (mitigable con `actualizado_en` y recálculo idempotente).
- **Cuándo vale la pena**: cuando la RPC empiece a notarse (obras muy largas, mucho
  tráfico). Hoy probablemente **3.1 (cachear) basta**.

### Recomendación fichas

Empezar por **3.1 (caché HTTP por obra)**. Saltar a **3.2 (snapshot)** solo si se
mide latencia alta. El barcode resumido de §2 se puede **reutilizar dentro de la
ficha** para el barcode de obra completa, evitando recalcular tramos.

---

## 4. Comparativas entre obras

Comparar el perfil métrico de varias obras (p. ej. "soneto vs. romance en obras de
1610-1620", o comparar 3 obras lado a lado).

La clave: **una comparativa es una agregación sobre agregados ya precomputados**, no
sobre datos crudos. Si cada obra tiene su `perfil_formas` (§2.1), una comparativa es:

- Seleccionar N obras (por filtro o elección manual).
- Leer sus `perfil_formas` (N filas ligeras).
- Combinar en cliente o en una RPC que reciba `obra_ids[]`.

### 4.1 — Sobre el resumen por obra (recomendada)

Con `obras_barcode_resumen.perfil_formas` ya existente, la comparativa no necesita
tocar `secuencias_metricas`. Una RPC `compare_obras(obra_ids uuid[])` lee los
perfiles y devuelve la matriz forma×obra. Rápido y escala.

### 4.2 — Agregados por cohorte (vista materializada)

Para comparativas por **grupos** (década, género, autor): una vista materializada
`metrica_por_decada` / `metrica_por_genero` con los promedios precalculados. Se
refresca periódicamente. Ideal para gráficos del laboratorio (§5) que comparan
cohortes grandes.

### Recomendación comparativas

**4.1** para comparar obras concretas (deriva del resumen por obra). **4.2** (vistas
materializadas por cohorte) para comparativas agregadas del laboratorio.

---

## 5. Laboratorio de datos

El laboratorio explora el corpus entero: distribuciones globales, evolución temporal
de formas, correlaciones (p. ej. polimetría vs. década). Esto es **lo más pesado**
si se calcula en vivo, y **lo que más se beneficia** de precomputación.

### 5.1 — Vistas materializadas temáticas

Una por pregunta analítica recurrente:

- `lab_formas_por_decada` — versos/% por forma y década.
- `lab_polimetria_por_obra` — nº de formas distintas, índice de polimetría por obra.
- `lab_presencia_personajes` — agregados de intervención (femeninos/donaire/
  sobrenaturales) por cohorte.
- `lab_corpus_totales` — totales del corpus (nº obras, versos, formas) para cabeceras.

Se refrescan en bloque (cron diario/nocturno o `REFRESH CONCURRENTLY` tras
publicaciones). El laboratorio lee la vista, nunca los datos crudos.

### 5.2 — Tabla de hechos (fact table) para análisis libre

Si el laboratorio quiere consultas **ad hoc** (no solo gráficos predefinidos), una
tabla de hechos desnormalizada ayuda:

```
hechos_metrica (
  obra_id, decada, genero_id, forma_slug, tipo_forma,
  versos, n_secuencias, ...
)
```

Una fila por (obra, forma). Indexada, permite `group by` rápido por cualquier eje
sin tocar `secuencias_metricas`. Se rellena al recalcular el resumen por obra (§2.1)
— mismo trigger/función, dos destinos.

### Recomendación laboratorio

**5.1 (vistas materializadas por pregunta)** para los gráficos del laboratorio, y
**5.2 (fact table)** si se quiere exploración libre. Ambas se alimentan del mismo
recálculo por obra, así que el coste marginal de añadirlas es bajo una vez exista §2.

---

## 6. Coherencia: ¿quién recalcula y cuándo?

El punto débil de toda precomputación es la **invalidación**. Opciones, combinables:

1. **Recálculo explícito al guardar/publicar** (lo más simple): el backend llama a
   `recompute_obra(obra_id)` tras guardar secuencias o cambiar estado. Cubre el 95%
   de los casos porque las obras cambian al editarse, no solas.
2. **Trigger "marcar sucia"**: `AFTER` en `secuencias_metricas` pone
   `obras.metrica_sucia = true`. Un job (o el propio acceso) recalcula las sucias.
   Evita recalcular en cada fila de una edición masiva.
3. **Refresco programado**: las vistas materializadas (§4.2, §5) se refrescan por
   cron, no en caliente.
4. **`actualizado_en` + recálculo idempotente**: cada agregado guarda su timestamp;
   si algo falla, se detecta y se reintenta sin corromper.

> **Principio**: el dato crudo (`secuencias_metricas`) es la **fuente de verdad**;
> los agregados son **derivados reconstruibles**. Siempre debe existir un comando
> "recalcula todo desde cero" (full rebuild) para reparar inconsistencias.

### Nota sobre vuestra restricción de red

Las migraciones se aplican a mano por el SQL Editor (la red bloquea el puerto de
Postgres). Esto **no afecta** a la precomputación en runtime (triggers/funciones se
ejecutan en la BD, no desde aquí), pero sí implica que **crear** las tablas/vistas/
funciones será una migración manual más. El recálculo en sí corre dentro de Postgres.

---

## 7. Tabla de decisión (resumen)

| Superficie | Estrategia recomendada | Técnica | Migración | Prioridad |
|---|---|---|---|---|
| Catálogo (barcode + filtro forma) | Resumen por obra + paginación + caché | A + C | Sí (tabla + función) | **Alta** (lo pediste) |
| Ficha de obra | Caché HTTP por obra; snapshot si hace falta | C (→ A) | No (luego sí) | Media |
| Comparar obras concretas | Derivar del resumen por obra | A + RPC | Reusa la de catálogo | Media |
| Comparativas por cohorte | Vista materializada por grupo | B | Sí (vistas) | Baja |
| Laboratorio (gráficos) | Vistas materializadas temáticas | B | Sí (vistas) | Baja |
| Laboratorio (ad hoc) | Fact table | A (fact) | Sí (tabla) | Baja |

---

## 8. Camino sugerido (si decides avanzar)

Orden que **maximiza reutilización** y minimiza retrabajo:

1. **`obras_barcode_resumen`** (tabla A) con `tramos`, `formas_presentes`,
   `perfil_formas`, y una función `recompute_obra_barcode(obra_id)` llamada al
   guardar/publicar. → Desbloquea **catálogo** (barcode + filtro forma) y aporta el
   `perfil_formas` que necesitan **comparativas** y **laboratorio**.
2. **Paginación** del catálogo + reutilizar el selector de formas del dashboard
   sobre `formas_presentes`.
3. **Caché HTTP** afinada (ya existe; revisar invalidación al editar).
4. Cuando lleguen comparativas/laboratorio: **RPC `compare_obras`** y **vistas
   materializadas** alimentadas por el mismo recálculo.
5. (Opcional, si se mide latencia) **snapshot de ficha** y **fact table**.

La pieza 1 es la palanca: una vez existe el resumen por obra, el resto se apoya en
él en lugar de recalcular sobre `secuencias_metricas`.

---

## 9. Preguntas abiertas para decidir

- ¿El barcode del catálogo necesita subtipos/caracterizaciones, o basta forma+rango?
  (Asumido: basta forma+rango; los detalles se ven en la ficha.)
- ¿Recálculo **explícito al publicar** o **trigger automático**? (Recomendado:
  explícito ahora, trigger si surge necesidad.)
- ¿El filtro por forma es **presencia** ("contiene soneto"), **predominancia**, o
  **ambos**? (`formas_presentes` cubre presencia; `perfil_formas` cubre % para los
  otros dos sin coste extra de almacenamiento.)
- ¿Paginar el catálogo desde ya, o seguir client-side hasta que duela? (Con 60 obras
  aún no duele; conviene paginar antes de acercarse a varios cientos.)
- ¿Las vistas materializadas se refrescan por cron, o tras cada publicación?
