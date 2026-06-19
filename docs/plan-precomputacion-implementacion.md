# Plan de implementación — Precomputación métrica contra el código real

> Aterrizaje del documento de decisiones [precomputacion-estrategias.md](precomputacion-estrategias.md)
> sobre el código y el esquema reales del proyecto. Detecta inconsistencias, choques con
> lo existente (en especial permisos/visibilidad por rol) y propone un plan por fases para
> avanzar en sesiones sucesivas sin romper la zona pública.
>
> **Principio rector de este documento:** la fuente de verdad son los **campos y vocabularios
> reales de la base de datos**, no los nombres ni definiciones del documento de decisiones.
> Donde el documento y la DB difieren, **manda la DB** y se corrige el contrato, no se inventa
> un mapeo para forzar la equivalencia.
>
> Relación con [plan-zona-publica.md](plan-zona-publica.md): aquel construyó el control de
> visibilidad por secciones/scope (Fases 0–6) y la reescritura de catálogo + ficha. Este plan
> aporta la **capa de datos métricos precomputados** que alimenta esas superficies. Las fases
> de consumo (ficha, catálogo, autor, laboratorio) son la cara de datos de la Fase 6 de aquel
> plan.

---

## 0. Estado y retoma (actualizado 2026-06-19)

> **Para retomar en otra sesión:** lee esta sección y nada más para saber dónde estamos.
> El detalle de cada fase está más abajo (§4).

### Estado por fase
| Fase | Qué es | Estado |
|---|---|---|
| 1 | Núcleo `obras_resumen` + trigger + `recompute_obra_resumen`/`recompute_all` | ✅ hecho y aplicado |
| 2 | Botón "Actualizar datos públicos" (ficha dashboard) + endpoint | ✅ hecho |
| 2-bis | Triggers de suciedad ampliados (caracterizaciones, subtipos, jornadas/cuadros) + `subtipos_presentes` | ✅ hecho y aplicado |
| 2-ter | Botón `recompute_all` global en `dashboard/publicacion` (admin/IP) | ✅ hecho |
| 3 | `autores_resumen` (perfil de autor) | ⏳ **pendiente** (no empezado) |
| 4 | Consumo en ficha pública | ❌ **descartada** (la ficha se queda en vivo; ver §4) |
| 5a | Perfil métrico en resultados del catálogo + orden diversidad/densidad | ✅ hecho |
| 5b | Panel de filtros métricos (formas, metros, tipo, subtipos, variaciones, densidad) | ✅ hecho |
| 5c | Etiquetas vía vocabulario cacheado + selector jerárquico (subtipos bajo quintilla) | ✅ hecho |
| 5d | Pendientes del catálogo (mini-barcode con estructura, variaciones, dramaturgia; caché HTTP no bloqueante) | ⏳ **en curso** |
| 6 | Fichas de autor públicas (hoy placeholder) | ⏳ pendiente (depende de Fase 3) |
| 7 | Laboratorio + `obras_similares` (coseno provisional) | ⏳ pendiente |
| 8 | Rasgos métricos en vocabulario → `formas_distancia` → distancias ponderadas | 🔒 bloqueada (trabajo filológico manual) |

### Migraciones (todas aplicadas a mano por SQL Editor)
- ✅ `20260618220000_obras_resumen_nucleo.sql`
- ✅ `20260618230000_obras_resumen_triggers_subtipos.sql`
- ✅ `20260619120000_obras_resumen_rls_publico.sql`
- ✅ `20260619133000_obras_resumen_dirty_cuadros.sql`
- ⏳ `20260619143000_obras_resumen_estructura_barcode.sql` (pendiente de aplicar)
- `recompute_all()` ya ejecutado (formas/subtipos poblados). **Nota:** tras editar secuencias hay
  que pulsar el botón por obra, o `recompute_all` global, para refrescar el resumen.
  Tras aplicar `20260619143000`, ejecutar `recompute_all()` para poblar `jornadas_tramos`/
  `cuadros_tramos` en obras ya publicadas.

### Próximo paso recomendado
1. **🔴 Arreglar la invalidación de caché HTTP del catálogo** (Fase 5d): al cambiar la visibilidad
   de una sección, la respuesta anónima cacheada no se refresca (~5-15 min). Es un fallo real del
   sistema de publicación, transversal (afecta a catálogo y a cualquier página pública cacheada).
2. Luego, a elegir: **Fase 3** (perfil de autor, desbloquea Fase 6) o **Fase 5d** filtros
   dramatúrgicos (datos ya en `obras_resumen`).

### Decisiones del equipo aún abiertas (§3)
- 0.3 Permiso del botón: hoy implementado como **admin/IP o editor asignado** (revisar si se quiere).
- 0.5 `total_versos` autoritativo (hoy el resumen calcula `sum(n_versos)`).
- 0.6 Ponderación del perfil de autor (bloquea Fase 3): por extensión vs por obra; y qué obras cuentan.
- 0.8 Longitud de tramo en distancia secuencial (Fase 7).
- 0.9 Pesos de rasgos métricos (Fase 8).

### Qué quedó fuera (y por qué)
- **Fase 4 (ficha desde precomputado): descartada.** La ficha es rica/interactiva y por-visitante;
  `tramos` la regresaría. Se mantiene en vivo. Congelarla a snapshot sería trabajo propio mayor.
- **Distancia entre autores: pospuesta** (doc §3.5) hasta tener volumen por autor.
- **Estáticos a JSON: no ahora** (doc §12), solo si el corpus crece y el compute se nota.
- **No denormalizar etiquetas** en el resumen: se guardan slugs y la etiqueta se resuelve en lectura
  (vocabulario cacheado, Fase 5c).

---

## 1. Aterrizaje: cada concepto del documento contra el dato real

Verificado contra [database.types.ts](src/lib/types/database.types.ts),
[001_vocabularios.sql](supabase/seed/001_vocabularios.sql) y las migraciones de
[supabase/migrations/](supabase/migrations/).

| Concepto del documento | Estado real en la DB | Qué se toma |
|---|---|---|
| Tablas `obras_resumen`, `autores_resumen`, `obras_similares`, `formas_distancia` | **No existen.** | Crear en fases. |
| `secuencias_metricas` (fuente de verdad) | Existe. Columnas reales: `obra_id`, `v_ini`, `v_fin`, `n_versos`, `estrofa_tipo_id`, `inaugura_espacio`, `versos_partidos`, `evocacion_metrica`(+texto), `intervencion_personajes_femeninos`, `intervencion_figuras_donaire`, `intervencion_personajes_sobrenaturales`, `sinopsis`, `certeza_editor`. | Base del recompute. |
| Formas estróficas y jerarquía | `vocabularios` categoría `estrofa_tipo`, **2 niveles**: padre (romance, redondilla, quintilla, decima, silva) → hijo (romance_e-a, romance_i-o). `tipo_forma` ∈ {`forma_espanola`, `forma_italiana`} (CHECK). `patron_especifico` guarda la rima del hijo ('e-a', 'i-o'). | Slug de forma = `termino` de la raíz; tipo = `tipo_forma`. Confirma "solo 2 niveles + tipo_forma" del doc. |
| Metros (`metros_presentes`) | Categoría real `metro` (octosilabo, endecasilabo, heptasilabo) enlazada vía tabla `estrofa_tipo_metros` (estrofa_tipo ↔ metro). En el seed solo romance↔octosilabo y silva↔hepta/endeca; redondilla/quintilla/decima **sin metro**. | Real, pero cobertura parcial: derivar metro desde la forma vía `estrofa_tipo_metros`; aceptar que muchas formas no tienen metro asignado todavía. |
| `% cantado` (`pct_cantado`) | ⚠️ **"cantado" NO es un tipo de forma.** Es un `caracterizacion_rango` (hijo de `fenomenos_enunciativos`), declarado **por rango** (`v_ini`/`v_fin`) en `secuencias_caracterizaciones_rango`. | **Corrección:** `pct_cantado` = versos en rangos con `tipo_caracterizacion_rango` = 'cantado' / total. No depende de la forma. |
| `variaciones_presentes` (doc cita `secuencias_variaciones.tipo_variacion_id`) | ⚠️ Esa tabla/columna **no existe**: se refactorizó (migración [caracterizacion_rango_refactor](supabase/migrations/20260402120000_caracterizacion_rango_refactor.sql)) a `secuencias_caracterizaciones_rango.tipo_caracterizacion_rango_id`, categoría `caracterizacion_rango`. Términos reales: fenomenos_enunciativos (cantado, prosa), irregularidades_metricas (hipometrico, hipermetrico, rima_defectuosa, laguna), final_acentual (mayoria_agudas, mayoria_esdrujulas). | **Resuelto:** fuente real = `secuencias_caracterizaciones_rango`. Pendiente del doc nº6 cerrado contra el dato. |
| `intervencion_femenina/donaire/sobrenaturales` (doc: 'ninguna'/'exclusiva'/'compartida'/'mixta') | Enum real **por secuencia**: `sin_intervencion | exclusiva | compartida` ([validators.ts:115](src/lib/utils/validators.ts#L115)). No existe 'ninguna' ni 'mixta' a nivel de secuencia. | Derivar el valor de obra desde el enum real: sin ninguna → `sin_intervencion`; todas exclusiva → `exclusiva`; todas compartida → `compartida`; mezcla → `mixta`. Usar el término real `sin_intervencion`, no 'ninguna'. |
| `tramos` (barcode) | Hoy el barcode se construye **en cliente** desde `metrica.secuencias` vía [ficha-metric-adapter.ts](src/lib/components/metrica/) tras la RPC. La RPC ya calcula `distribucion_formas` (forma+versos+%). | `tramos` y `perfil_formas` precomputados sustituyen ese cálculo en vivo (ver choque nº4). |
| `numero_efectivo_formas`, `p_max`, `densidad_transiciones`, `n_formas_distintas` | No existen; calculables desde `secuencias_metricas`. | Calcular en el recompute. |
| Rasgos métricos para `formas_distancia` (rima, metro, naturaleza estrófica, tamaño) | ⚠️ **No existen como columnas.** Solo hay señales parciales: `tipo_forma`, `patron_especifico` (rima del hijo de romance), `estrofa_tipo_metros` (metro). Falta rima asonante/consonante explícita, naturaleza estrófica y tamaño de estrofa. | Confirma el bloqueo del doc: distancias ponderadas aplazadas; coseno provisional. |
| Botón "Actualizar datos públicos" / autosave | Autosave real cada 10s en [SecuenciasTab.svelte:1156](src/lib/components/editor/SecuenciasTab.svelte#L1156) (`save('autosave')`) que escribe en tablas crudas vía API. No hay botón de publicación de datos. | Trigger de suciedad + botón nuevos. |
| `get_obra_ficha_publica` | RPC real `SECURITY DEFINER` ([ficha_publica_sinopsis_metrica](supabase/migrations/20260618170000_ficha_publica_sinopsis_metrica.sql)) con muro `estado = publicado` absoluto y `p_include_hidden` para relajar `visible_publico`. | Punto de integración de la ficha. |
| Permisos admin/IP/editor | `role_editor` = editor/admin/IP; `canReadAllObras` = admin∨IP ([permissions.ts:40](src/lib/utils/permissions.ts#L40)); scope efectivo por obra en [public-obras.ts](src/lib/server/public-obras.ts). | Reusar, no reinventar. |

---

## 2. Inconsistencias, problemas y choques con lo existente

Ordenados por gravedad. Los nº1–3 son **bloqueantes de seguridad/coherencia**; el resto, decisiones de diseño.

### 🔴 1. RLS y visibilidad de las tablas precomputadas (choque directo con el modelo de roles)

El documento (pendiente nº9) solo dice "SELECT anónimo solo para obras públicas, alineado con
`obras`". Pero el modelo real de visibilidad **no es un simple `visible_publico = true`**:

- RLS real de `obras` para **anon** ([unify_estado_visibility](supabase/migrations/20260216120000_unify_estado_visibility.sql#L70)):
  `visible_publico = true AND estado = publicado`.
- El **catálogo** ([catalogo/+page.server.ts:109](src/routes/(public)/catalogo/+page.server.ts#L109))
  relaja `visible_publico` para el **editor asignado a esa obra** vía `.or(editor_asignado.eq.userId)`,
  consultando con el cliente del usuario (no RPC).
- La **ficha** lo resuelve por RPC `SECURITY DEFINER` con `p_include_hidden` calculado en TS
  según `resolveObraScope(viewer, obra)`.

**Choque:** si `obras_resumen`/`autores_resumen` se consultan **directamente** (PostgREST/`locals.supabase`)
con una RLS ingenua ("anon lee todo"), se **filtran datos de obras publicadas-no-visibles** (tramos,
perfil, métricas) que el muro de `obras` oculta. Y replicar en la RLS de una segunda tabla la
excepción del editor-asignado (un `EXISTS` contra `obras` con `auth.uid()`) es frágil y duplica la
lógica de visibilidad en dos sitios.

**Decisión a tomar (recomendada):** exponer los datos precomputados al público **a través de
funciones `SECURITY DEFINER`** (una `get_catalogo_publico(...)` y la `get_obra_ficha_publica`
existente leyendo de `obras_resumen`), igual que ya se hace con la ficha — **una sola fuente de
verdad de visibilidad**. La RLS de las tablas precomputadas queda restrictiva por defecto (sin
SELECT para anon/authenticated; solo `service_role`/definer). Alternativa: RLS con `EXISTS` contra
`obras` replicando anon + editor-asignado; más superficie de error. **Esto condiciona §9.1/§9.4 del
documento** (que asumían JOIN directo).

### 🟢 2. `/catalogo` y `/obras` son superficies distintas (no hay duplicación que converger)

Aclaración (corrige una lectura previa errónea): **no compiten**.
- [catalogo/+page.server.ts](src/routes/(public)/catalogo/+page.server.ts) — **buscador avanzado**:
  panel de filtros ([catalog-filters.ts](src/lib/catalogo/catalog-filters.ts)) y secciones
  (`catalogo.filtros.metrica`, etc.). Es la superficie donde entran los filtros y el perfil métricos.
- [obras/+page.server.ts](src/routes/(public)/obras/+page.server.ts) — **listado simple** de títulos
  ordenados por título, sin filtros avanzados.

**Implicación para el plan:** los filtros/orden/perfil métricos de la Fase 5 van **solo en `/catalogo`**.
`/obras` se mantiene como listado simple (a lo sumo podría leer `total_versos`/básicos del resumen,
pero no es objetivo). No hay convergencia ni deprecación pendientes. Ambas siguen compartiendo la
misma lógica de visibilidad por obra, así que el choque nº1 (RLS) aplica a las dos.

### 🔴 3. `pct_cantado` y `variaciones_presentes` mal definidos en el doc (ya corregidos arriba)

No es solo una etiqueta: cambian **qué tabla y qué filtro** alimentan el recompute. "cantado" sale
de `secuencias_caracterizaciones_rango` (por rango), no de la forma. Implementarlo como el doc dice
(forma de tipo cantado) daría **siempre 0** porque ninguna forma tiene ese tipo. Tomado el dato real.

### 🟠 4. Duplicación de fuente de verdad métrica (RPC vs resumen)

La RPC de ficha ya calcula en vivo `distribucion_formas` (≈ `perfil_formas`) y el barcode se arma en
cliente desde `secuencias` (≈ `tramos`). Al introducir `obras_resumen` habrá **dos cálculos del mismo
dato**. Riesgo: que diverjan (uno publicado, otro en vivo). **Decisión:** cuando exista `obras_resumen`,
la ficha debe leer `tramos`/`perfil_formas` de ahí (dato publicado, coherente con el botón) y
**dejar de recalcular** distribución/barcode en vivo, o mantener el cálculo en vivo solo como
*fallback* mientras no haya fila de resumen.

### 🟠 5. `total_versos`: dos fuentes que pueden divergir

`obras.total_versos` es nullable y de mantenimiento incierto; el doc guarda otra copia en
`obras_resumen` como `sum(n_versos)`. Pueden discrepar (huecos entre secuencias, prosa, lagunas).
**Decidir cuál es autoritativa** para el público y documentarlo. Recomendado: el resumen calcula
`sum(n_versos)` y se compara con `obras.total_versos` en el recompute para detectar inconsistencias.

### 🟠 6. Orden "Autor" del catálogo (doc §9.1) apunta al campo equivocado

El doc mapea orden "Autor" → `obras.autor_ficha_publico`. Pero `autor_ficha_publico` es el **autor de
la ficha (editor/cita)**, no el dramaturgo: la RPC lo expone junto a `autor_ficha_email/orcid_publico`
sacados de `editores`. El dramaturgo va por `atribuciones → atribucion_autores → autores`, y el
catálogo actual ya ordena "autor" por el dramaturgo ([catalog-filters.ts:369](src/lib/catalogo/catalog-filters.ts#L369)).
**Mantener el orden por dramaturgo**; no usar `autor_ficha_publico` para esto.

### 🟠 7. Estabilidad de slugs de forma en arrays de filtro (pendiente nº8 del doc)

Los arrays (`formas_presentes`, `metros_presentes`, `tramos.s`) guardarían `vocabularios.termino`
como slug. `termino` **no es único globalmente** (lo es por `(categoria, termino)`), y si un admin
renombra un término desde el panel de vocabularios, los datos precomputados quedan **obsoletos**
hasta el siguiente recompute (la precomputación es por obra, al pulsar el botón → asimetría del doc §7.4).
**Decidir:** guardar `termino_id` (UUID estable) en los arrays y resolver la etiqueta en cliente, o
asumir la obsolescencia temporal y forzar `recompute_all()` tras renombrar. Para colorear ya existe
`estrofa_forma_slug` en la RPC ([ficha_forma_color_slug](supabase/migrations/20260618190000_ficha_forma_color_slug.sql)).

### 🟠 8. Invalidación de caché tras el botón

La ficha y el catálogo emiten cabeceras de caché agresivas para anónimos
(`s-maxage=300, stale-while-revalidate=600`). Hoy **nada revalida** al cambiar datos. Tras pulsar
"Actualizar datos públicos", el público seguiría viendo lo cacheado hasta 5–10 min. El doc menciona
"ISR con revalidación al pulsar el botón" pero no hay mecanismo. **Definir** revalidación (purgar
ruta de la obra/catálogo) en el flujo del botón, o aceptar el desfase y documentarlo.

### ✅ 9-bis. Cobertura del trigger de suciedad (RESUELTO en Fase 2)

El trigger inicial solo cubría `secuencias_metricas`, pero el resumen depende de más tablas.
Migración [20260618230000](supabase/migrations/20260618230000_obras_resumen_triggers_subtipos.sql)
extiende la suciedad a **todas** las entradas del resumen:
- `secuencias_caracterizaciones_rango` → `pct_cantado`, `variaciones_presentes` (vía secuencia_id).
- `secuencias_subtipos_estrofa` → nuevo `subtipos_presentes` (vía secuencia_id).
- `jornadas` → `n_jornadas` (vía obra_id).
- `cuadros` → estructura del mini-barcode público (vía `jornada_id`, añadido en
  [20260619133000](supabase/migrations/20260619133000_obras_resumen_dirty_cuadros.sql)).

Se añadió `subtipos_presentes` (text[] + GIN) para que los subtipos de estrofa sean
**filtrables en el catálogo** igual que `variaciones_presentes`. Cambios de obra (fechas,
género, título…) **no** ensucian el resumen: no se precomputan, se leen en vivo de `obras`.

### 🟡 9. Trigger de suciedad: estado "nunca publicado" y contexto de seguridad

- El trigger (§5) solo marca `metrica_sucia` si **existe** fila en `obras_resumen`. Una obra publicada
  que nunca pulsó el botón **no tiene fila** → el dashboard no puede mostrar "hay cambios sin publicar".
  Hay que tratar "sin fila" como estado "datos no publicados nunca".
- El trigger se dispara durante el autosave del editor (cuyo cliente tiene RLS de editor). Debe ser
  `SECURITY DEFINER` para escribir `obras_resumen` con independencia del rol que edita.

### 🟡 10. Permiso del botón: editor asignado vs admin/IP

El doc §8.1 dice "visible para editor asignado y admin". Esto **encaja** con el modelo (el editor
asignado ya ve su obra como admin/IP por obra). Pero el botón **escribe datos públicos**: conviene
decidir si el editor asignado puede publicar datos o solo admin/IP (como `canManagePublicacion`,
`canToggleVisibility`, que son admin/IP). Recomendado: **alinear con `canToggleVisibility`**
(admin/IP), porque publicar datos al público es análogo a abrir visibilidad. Si se quiere permitir
al editor, crear un permiso nuevo explícito.

### 🟡 11. `autores_resumen.n_obras`: ¿qué obras cuentan?

El doc dice "obras catalogadas y publicadas". Pero el público ve `publicado AND visible_publico`.
**Decidir** si el perfil de autor agrega sobre publicadas, o publicadas-y-visibles, y si el agregado
puede filtrarse a una obra que el visitante no debería ver. Coherente con el choque nº1.

### 🟡 12. Restricción operativa de migraciones (no es del doc, pero condiciona todo)

El puerto 5432 está bloqueado: **las migraciones se aplican a mano por el SQL Editor** y los tipos se
editan a mano ([database.types.ts](src/lib/types/database.types.ts)); ver nota en
[plan-zona-publica.md](plan-zona-publica.md). Cada fase con SQL debe contemplar este flujo (registro
en `supabase_migrations.schema_migrations` con INSERT manual y edición manual de tipos).

---

## 3. Decisiones a cerrar antes de codificar (Fase 0)

No requieren código; bloquean o condicionan fases. Marcar resueltas en este documento.

1. **Vía de exposición pública de datos precomputados:** RPC `SECURITY DEFINER` (recomendado) vs RLS
   replicada. (Choque nº1.) — *Condiciona Fases 1, 4, 5.*
2. ~~**Catálogo canónico.**~~ **RESUELTO/no aplica:** `/catalogo` (buscador avanzado) y `/obras`
   (listado simple) son superficies distintas; no hay que elegir ni converger. (Choque nº2.)
3. **Permiso del botón:** admin/IP vs incluir editor asignado. (Choque nº10.) — *Condiciona Fase 2.*
4. **Slugs en arrays:** `termino` (texto) vs `termino_id` (UUID). (Choque nº7.) — *Condiciona Fase 1.*
5. **`total_versos` autoritativo:** `obras.total_versos` vs `sum(n_versos)`. (Choque nº5.)
6. **Ponderación del perfil de autor:** por extensión (recomendado por el doc) vs por obra; y qué
   obras cuentan (publicadas vs publicadas+visibles). (Choque nº11.) — *Condiciona Fase 3.*
7. **Invalidación de caché tras el botón:** mecanismo concreto o desfase aceptado. (Choque nº8.)
8. **Tratamiento de longitud de tramo en distancia secuencial** (doc §3.4) — *solo afecta a Fase 7.*
9. **Pesos de rasgos métricos** (decisión filológica) — *solo afecta a Fase 8.*

---

## 4. Plan por fases (incremental, una o pocas por sesión)

Cada fase es mergeable y deja el sistema funcionando. El orden minimiza riesgo: primero la capa de
datos (invisible al público), luego el botón, luego el consumo superficie a superficie.

### Fase 1 — Núcleo de precomputación de obra (sin UI) 🧱
**Objetivo:** tener `obras_resumen` poblada y reconstruible, sin que el público lo note todavía.

- **Migración** (a mano por SQL Editor): tabla `obras_resumen` con las columnas que el **dato real
  permite hoy** — `obra_id` PK/FK, `total_versos` (`sum(n_versos)`), `n_secuencias`, `n_jornadas`,
  `n_formas_distintas`, `numero_efectivo_formas`, `p_max`, `densidad_transiciones`, `pct_cantado`
  (vía caracterizacion_rango 'cantado'), `tramos` jsonb, `perfil_formas` jsonb, `formas_presentes`,
  `metros_presentes` (vía `estrofa_tipo_metros`), `tipos_forma_presentes`, `variaciones_presentes`
  (vía `secuencias_caracterizaciones_rango`), flags (`tiene_versos_partidos`, `tiene_cambio_espacio`),
  `intervencion_*` derivados (con el enum real), `metrica_sucia`, `actualizado_en`. Índices GIN/BTREE
  del doc §2.2.
- **Trigger** `metrica_sucia` en `secuencias_metricas` (`AFTER INSERT/UPDATE/DELETE`, `SECURITY DEFINER`).
- **Funciones** `recompute_obra_resumen(obra_id)` y `recompute_all()`. Todo lo no calculable hoy
  (distancias ponderadas) queda fuera; los campos sin dato (p. ej. formas sin metro) quedan vacíos,
  no inventados.
- **RLS** restrictiva (según decisión Fase 0.1).
- **Tipos** a mano en database.types.ts.
- **Verificación:** ejecutar `recompute_all()` sobre el corpus real y **contrastar** `perfil_formas`
  con el `distribucion_formas` que ya devuelve la RPC para varias obras (deben coincidir). Sin tocar UI.

*Dependencias:* decisiones Fase 0.1, 0.4, 0.5. *Entregable:* datos correctos, invisibles.

### Fase 2 — Botón "Actualizar datos públicos" + endpoint 🔘
**Objetivo:** que un humano dispare el recompute de una obra desde el dashboard.

- **Endpoint** (patrón de [visibilidad/+server.ts](src/routes/api/obras/[id]/visibilidad/+server.ts)):
  verifica permiso (Fase 0.3), exige `estado = publicado`, llama `recompute_obra_resumen` vía RPC,
  invalida caché (Fase 0.7).
- **UI** en el header del dashboard de obra ([obras/[id]/+page.svelte](src/routes/(dashboard)/dashboard/obras/[id]/+page.svelte)):
  estado visual según `metrica_sucia` (y "nunca publicado" si no hay fila — choque nº9); bloqueado con
  tooltip si no está publicada (doc §8.3).
- **Verificación:** editar una secuencia → flag sucio; pulsar → datos actualizados y flag limpio;
  obra no publicada → botón bloqueado.

*Dependencias:* Fase 1. *Entregable:* publicación de datos operativa (aún sin consumo público nuevo).

#### Fase 2-ter — Recompute global desde publicación ✅
- **Endpoint** `/api/datos-publicos/recompute-all`: solo admin/IP (`canManagePublicacion`), llama
  `recompute_all()` y devuelve conteo informativo de filas en `obras_resumen`.
- **UI** en `dashboard/publicacion`: bloque "Datos métricos precomputados" con botón
  "Recalcular todos los datos públicos" y estado running/done/error.
- **Uso previsto:** reconstrucción global tras inconsistencias o cambios de vocabulario que
  afecten a slugs/jerarquías/metros; no sustituye el botón por obra en el flujo normal.

### Fase 3 — Perfil de autor (`autores_resumen`) 👤
**Objetivo:** agregado por autor, encadenado al botón.

- **Migración:** tabla `autores_resumen` (doc §4.1) con la ponderación decidida (Fase 0.6).
- **Función** `recompute_autor_resumen(autor_id)`; el botón de obra marca sucios y recalcula los
  autores afectados vía `atribuciones → atribucion_autores` (doc §4.2).
- **RLS** coherente con la decisión de exposición (Fase 0.1) y con qué obras cuentan (choque nº11).
- **Verificación:** recompute de una obra propaga al perfil del autor; agregados correctos.

*Dependencias:* Fases 1–2, decisión 0.6. *Entregable:* perfiles de autor listos para consumir.

### Fase 4 — ~~Consumo en la ficha pública~~ ❌ DESCARTADA (decisión 2026-06-19)
**La ficha se mantiene en vivo.** Al aterrizarla contra el código se vio que la ficha es una
vista **rica e interactiva y por-visitante** que `tramos`/`perfil_formas` no pueden alimentar sin
regresión:
- El barcode es **por secuencia**, con **subtipos como subsegmentos** y **clic → modal** de detalle
  (intervenciones, caracterizaciones, sinopsis, comentarios), más vista "por jornadas".
  `tramos` solo tiene tramos de forma fusionados (`{i,f,s,t}`): no hay secuencias, ni subtipos, ni
  detalle. Cambiar el barcode a `tramos` **perdería** toda esa interactividad.
- La ficha filtra secciones **según rol** y el editor asignado ve lo oculto: es intrínsecamente
  por-visitante, no un snapshot único.
- La RPC computa `distribucion_formas` en vivo, coherente con el barcode en vivo: **no hay
  duplicación dañina** mientras la ficha sea en vivo (el choque nº4 solo aplicaría si ficha y
  catálogo tuvieran que coincidir, pero sirven propósitos distintos).

Congelar la ficha a snapshot publicado exigiría precomputar el **payload completo** (no solo
agregados) y resolver el filtrado por-rol sobre el snapshot: esfuerzo mayor, no justificado ahora.
`tramos`/`perfil_formas` rinden en el **catálogo** (Fase 5) y el **laboratorio** (Fase 7), que es
donde se consumen. Si en el futuro se quiere "público = snapshot" para la ficha, se abre como
trabajo propio.

### Fase 5 — Buscador avanzado `/catalogo` con datos métricos reales 🔎
**Objetivo:** filtros y orden métricos sobre `obras_resumen` en el **buscador avanzado**
([catalogo/](src/routes/(public)/catalogo/+page.svelte)). `/obras` se mantiene como listado simple.
Se entrega en dos incrementos.

#### Fase 5a — Perfil métrico en resultados + orden ✅
- **RLS pública de `obras_resumen`** ([20260619120000](supabase/migrations/20260619120000_obras_resumen_rls_publico.sql)):
  helpers `SECURITY DEFINER` (`obra_publica_visible`, `obra_publicada_asignada`) + políticas que
  replican la visibilidad de `obras` (anon: publicada+visible; auth: admin/IP · editor asignado ·
  visibles). Sustituye la política `using(true)` (que filtraba resumen de publicadas-no-visibles).
- **Servidor** ([catalogo/+page.server.ts](src/routes/(public)/catalogo/+page.server.ts)): trae
  `tramos`, `numero_efectivo_formas`, `densidad_transiciones`, `n_formas_distintas` del resumen,
  solo si el orden métrico o el perfil en resultados son visibles para el visitante.
- **Mini-barcode** [CatalogMetricBar](src/lib/components/catalogo/CatalogMetricBar.svelte) desde
  `tramos` (color por `colorForForma`) + chips diversidad/densidad/nº formas en cada resultado,
  gated por `catalogo.resultados.perfil_metrico`.
- **Orden** por `diversidad`/`densidad`, gated por `catalogo.filtros.metrica` (parse/serialize/sort
  con gating en [catalog-filters.ts](src/lib/catalogo/catalog-filters.ts) + tests).
- Mergeable sin efecto visible: ambas secciones arrancan `activa=false`; el admin las enciende
  desde `dashboard/publicacion`.

#### Fase 5b — Panel de filtros métricos ✅
- Controles en [CatalogFilterPanel](src/lib/components/catalogo/CatalogFilterPanel.svelte): formas,
  metros, tipo de forma, subtipos y variaciones (multi-select por solapamiento `&&`) + densidad
  (rango), gated por `catalogo.filtros.metrica`.
- Lógica en [catalog-filters.ts](src/lib/catalogo/catalog-filters.ts): filtros métricos en
  parse/serialize/normalize/filter/chips/removeChip, con gating por visibilidad; `deriveCatalogBounds`
  añade `densidad`. Tests nuevos (overlap + gating).
- Servidor: facetas (`formas_presentes`, `metros_presentes`, `tipos_forma_presentes`,
  `variaciones_presentes`, `subtipos_presentes`) adjuntas a cada obra y opciones con **etiqueta
  visible** resuelta del vocabulario (`displayTerm`), solo si el grupo métrico es visible.
- Mergeable sin efecto visible: todo gated por `catalogo.filtros.metrica` (hoy `activa=false`).

#### Fase 5c — Etiquetas, jerarquía y componente compartido ✅
- **Estrategia de etiquetas (termino → etiqueta):** las tablas precomputadas guardan **slugs**
  (`termino`, clave estable), nunca `etiqueta` (editable → quedaría obsoleta). Las etiquetas se
  resuelven en **lectura** desde el vocabulario, vía un **loader cacheado**
  [vocabulario-publico.ts](src/lib/server/vocabulario-publico.ts) (`loadPublicVocabulario` +
  `buildPublicVocabularioMaps`, TTL 60s, invalidado en las mutaciones de vocabulario). El catálogo
  lo usa para **género y facetas** con una sola fuente cacheada (de ~2 queries/carga a 0 en cache hit).
- **Componente compartido:** el selector reusa [CheckDropdown](src/lib/components/ui/check-dropdown.svelte)
  en modo `hierarchical` (el mismo del dashboard); no se crea ningún componente nuevo.
- **Subtipos bajo su raíz:** un único **selector jerárquico de forma estrófica**; los subtipos
  (subquintillas) van anidados bajo `quintilla` (`parentId` = slug del padre). Se eliminó el
  desplegable separado de subtipos. La selección combinada se divide en las dos facetas reales
  (`buildFormaSelectorItems` + `splitFormaSelection`, con tests). Chip único "Forma estrófica".

#### Fase 5d — Pendientes menores del catálogo
- **Caché HTTP del catálogo:** al cambiar la visibilidad
  de una sección, la respuesta anónima cacheada (`s-maxage=300, swr=600`) **no se invalida**, así
  que el cambio tarda ~5-15 min en verse (se confirmó: `/catalogo?x=1` lo evita). Decisión
  2026-06-19: **no bloquear ni bajar cachés**; la configuración de visibilidad será estable y
  se prefiere velocidad pública.
- Mini-barcode con el mismo componente base de la ficha (`MetricBarcode`), escala D3, tooltip
  nativo simple y cortes de jornadas/cuadros desde `obras_resumen.jornadas_tramos`/
  `cuadros_tramos` — **implementado, pendiente aplicar migración 20260619143000**.
- Sección `catalogo.filtros.dramaturgia`: intervención femenina/donaire/sobrenaturales, versos
  partidos, cambio de espacio (campos ya en `obras_resumen`, faltan facetas + UI).
- Variaciones agrupadas por su categoría padre (fenómenos enunciativos / irregularidades…), igual
  que las formas, reusando el modo jerárquico del CheckDropdown.
- Tooltip del mini-barcode con etiqueta visible (hoy usa slug prettificado).
- Evaluar mover el filtrado a servidor si el corpus crece (hoy en cliente).

*Dependencias:* Fases 1–2, decisión 0.1 (resuelta: RLS replicada con helpers definer).

### Fase 6 — Fichas de autor públicas 👥
**Objetivo:** construir las páginas de autor (hoy placeholders: [autores/[slug]](src/routes/(public)/autores/[slug]/+page.svelte))
consumiendo `autores_resumen`; marcar `fiabilidad` baja. Sin distancia entre autores (doc §3.5).

*Dependencias:* Fase 3.

### Fase 7 — Laboratorio: carga + distancias provisionales + `obras_similares` 🧪
**Objetivo:** construir el laboratorio (hoy placeholder) sobre el resumen.

- Carga inicial desde `obras_resumen` (doc §9.4).
- Distancia composicional/secuencial **provisional con coseno plano**, documentada como aproximación.
- Tabla `obras_similares` (top-N con umbral y `similitud` expuesta; doc §7), priorizando secuencial.
- UMAP/heatmap en cliente.
- Resolver antes el tratamiento de longitud de tramo (Fase 0.8).

*Dependencias:* Fase 1.

### Fase 8 — Rasgos métricos → `formas_distancia` → distancias ponderadas (BLOQUEADA) 🔒
**Objetivo:** calidad real de las distancias. **Bloqueada por trabajo filológico manual.**

- Codificar manualmente en `vocabularios` los rasgos que hoy no existen (rima asonante/consonante,
  naturaleza estrófica, tamaño estrófico; metro y `patron_especifico` ya parciales).
- **Nota sobre `irregular`:** es un `estrofa_tipo` real del corpus y aparece en `formas_presentes`/
  `tramos` con normalidad (no tocar en las fases de datos). Pero **no es una forma comparable** como
  romance/redondilla: representa pasaje métricamente irregular, no una forma fija. Al construir
  `formas_distancia` hay que decidir su tratamiento (excluirla de las distancias, o asignarle máxima
  distancia a todo lo demás) para que no contamine la geometría composicional/secuencial.
- Decidir pesos (Fase 0.9), generar `formas_distancia`, sustituir coseno por transporte óptimo
  (composicional) y Levenshtein ponderado (secuencial) — **sin migración de datos** (`perfil_formas`/
  `tramos` ya bastan).
- Distancia entre autores: pospuesta hasta volumen suficiente.

*Dependencias:* todo lo anterior + codificación de rasgos por el equipo.

---

## 5. Resumen de orden recomendado

1. **Fase 5d** — arreglar la invalidación de caché HTTP del catálogo.
2. **Fase 3** — perfil de autor (`autores_resumen`).
3. **Fase 6** — fichas de autor públicas.
4. **Fase 7** — laboratorio + similares (coseno provisional).
5. **Fase 8** — rasgos + distancias ponderadas (cuando el equipo codifique los rasgos).

Fases 1, 2, 2-bis, 2-ter y 5a–5c ya están implementadas. Fase 4 queda descartada por
decisión explícita: la ficha pública se mantiene en vivo. Fase 5d agrupa pendientes
del catálogo y del sistema de publicación que conviene cerrar antes de seguir ampliando
superficies públicas.
