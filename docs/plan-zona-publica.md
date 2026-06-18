# Plan — Zona pública con control de visibilidad por secciones

> Documento de trabajo para diseñar e implementar la parte pública de la web
> (buscador/catálogo, fichas de obra, laboratorio, demarcador) con control de
> roles/permisos y un panel de control para encender/apagar secciones.
>
> **Estado:** Fases 0-3 ✅, 5 ✅. **Fase 6 EN CURSO**: catálogo v1 ✅, ficha
> pendiente. Fase 4 anulada.
>
> ### Fase 6 — progreso
> - **Catálogo v1 ✅** (incremental, filtros básicos) — reescrito desde cero.
>   - Server [obras/+page.server.ts]: trae género + total_versos, resuelve
>     género por obra, y expone `filterOptions` (autores y géneros presentes en las
>     obras visibles, no opciones huérfanas).
>   - UI [obras/+page.svelte]: panel de filtros (texto, autor, género) + orden
>     (título/autor/fecha/versos/actualización), filtrado en CLIENTE (pocas obras →
>     en memoria; migrar a servidor si crece). Mantiene las etiquetas "Tu ficha" /
>     "Solo con login editorial" de la Fase 0.
>   - Verificado en vivo: 200, renderiza filtros y datos reales. 0 errores, 181 tests.
>   - **Pendientes del catálogo** (iteraciones siguientes): barcode métrico por obra,
>     filtros métricos avanzados (formas, metros, variaciones, polimetría, presencia
>     de personajes), rango de datación/versos con dual-range del mockup. Requieren
>     agregaciones métricas — auditar datos disponibles antes.
> - **Ficha — pendiente.** Reescritura con arquitectura de secciones + aplicar
>   `sectionVisibility` con {#if} (resuelve el pendiente B: ocultar secciones
>   apagadas en vez de mostrarlas vacías).
>
> ### 🔄 Replanteo de estrategia (2026-06-18)
> La parte pública es **temprana y maleable**: la ficha está a medias y el catálogo
> es un mockup. Decisión del usuario:
> - **Backend primero (Fases 3→5)**: dejar el sistema de control completo y
>   funcionando (datos filtrados + panel admin) ANTES de tocar la UI.
> - **Luego UI de cero (nueva Fase 6)**: rehacer catálogo Y ficha desde cero, con
>   arquitectura de secciones limpia. El catálogo DEBE basarse en el diseño de
>   [/mockup/catalogo](../src/routes/(public)/mockup/catalogo/+page.svelte) (801
>   líneas, ya tiene filtros, dual-range, barcode, datos mock en
>   [catalogo-mock.ts](../src/lib/mock/catalogo-mock.ts)).
> - **La antigua Fase 4 (envolver la ficha ACTUAL con flags) queda ANULADA**: esa
>   ficha se reescribe, así que los flags se aplican directamente en la UI nueva.
> - El backend (Fases 0-3) es independiente de la reescritura de UI y se conserva.
>
> ### ⚠️ Flujo de migraciones (importante)
> Este equipo (gestionado por la UAB) **bloquea el puerto 5432** saliente a nivel
> local — no es la red (443 a la misma IP del pooler sí conecta). Por eso
> `supabase db push` / `db dump` **se cuelgan en "Initialising login role..."** en
> cualquier red, incl. móvil. **Las migraciones se aplican a mano por el SQL Editor
> del panel de Supabase** (HTTPS/443) y se registran en
> `supabase_migrations.schema_migrations` con un INSERT manual. Los tipos
> (`database.types.ts`) se editan a mano (no se puede `db:types`/`db:pull` desde aquí).
>
> ### Registro de progreso
> - **Fase 0 ✅** (commit pendiente) — Scope efectivo por obra. Implementado y
>   verificado: 167/167 tests verdes, 0 errores de tipos. Sin tocar la BD.
>   - `resolveObraScope` + `canViewPublishedObra` + tipo `PublicObraVisibility`
>     en [public-obras.ts](../src/lib/server/public-obras.ts).
>   - Ficha y catálogo usan el scope efectivo por obra (editor asignado ve su
>     ficha como admin/IP); muro `estado = publicado` intacto.
>   - UI catálogo: etiqueta "Tu ficha · aún no visible sin login".
>   - Tests: [public-obras.test.ts](../src/lib/server/public-obras.test.ts) (8 casos).
> - **Decisión operativa:** NO se hará backup de BD antes de la Fase 1 (el usuario
>   tiene una copia local reciente). El equipo bloquea 5432 localmente, así que
>   `supabase db dump` no funciona desde aquí de todos modos.
> - **Fase 1 ✅** — Tabla `secciones_publicas` + RLS + seed (10 secciones).
>   Migración
>   [20260618120000_secciones_publicas.sql](../supabase/migrations/20260618120000_secciones_publicas.sql)
>   **aplicada a mano por SQL Editor** (10 filas verificadas) y registrada en el
>   historial. Tipos añadidos a mano en
>   [database.types.ts](../src/lib/types/database.types.ts).
> - **Consolidación ✅** — Eliminada la función SQL duplicada `is_admin_ip()`; se
>   usa el helper ya existente `auth_is_admin_or_ip()`. `public-obras.ts` ahora
>   reusa `canReadAllObras()`/`normalizeRole()` de permissions.ts en vez de
>   reimplementar `admin || ip`. Remoto y repo sincronizados.
> - **Fase 2 ✅** — Carga única de secciones en el layout público.
>   - Regla COMPARTIDA en [secciones-publicas.ts](../src/lib/secciones-publicas.ts)
>     (`scopeMeets`, `isSectionAvailable`, `buildSectionVisibilityMap`,
>     `isSectionVisible`); default seguro = sección desconocida no visible.
>   - Acceso a datos en
>     [server/secciones-publicas.ts](../src/lib/server/secciones-publicas.ts).
>   - [(public)/+layout.server.ts](../src/routes/(public)/+layout.server.ts) expone
>     `sectionVisibility` (mapa resuelto) y `viewerScope` a toda la zona pública.
>   - Tests [secciones-publicas.test.ts](../src/lib/secciones-publicas.test.ts) (6).
>   - Nota: aplicar el mapa en la UI se hace en la Fase 6 (UI nueva), no antes.
> - **Fase 3 ✅** — Filtrado de DATOS de la ficha en el `load` (TypeScript, no SQL).
>   - [server/ficha-secciones.ts](../src/lib/server/ficha-secciones.ts):
>     `applyFichaSectionVisibility` recorta bloques apagados/restringidos sin mutar
>     el original. Sub-secciones: autoria, autoria.fuentes (mantiene autoría, quita
>     evidencias), metrica, observaciones, bibliografia, comentarios_publicos.
>   - Filtrado contra el scope EFECTIVO de la obra (editor asignado ve sus
>     sub-secciones restringidas); el `load` reconstruye el mapa con `obraScope`,
>     no con el global del layout.
>   - El dato NO sale del servidor si la sección está apagada (no es solo {#if}).
>   - Tests [ficha-secciones.test.ts](../src/lib/server/ficha-secciones.test.ts) (8).
> - **Optimización de consumo ✅** (cuentas free de Vercel/Supabase) — recortadas
>   las 2 fugas de queries por request:
>   - `resolvePublicViewerContext` ahora memoiza por request (WeakMap con el cliente
>     supabase como clave) → evita el doble cálculo de scope layout+página (−3
>     queries/request en ficha y catálogo).
>   - `loadPublicSections` cachea las 10 filas en memoria del servidor (TTL 60s);
>     `invalidatePublicSectionsCache()` listo para que el panel admin (Fase 5) lo
>     llame tras guardar. En serverless el caché es best-effort por instancia, lo
>     cual es aceptable para datos casi-estáticos.
>   - Resultado: ficha pasa de ~10-11 a ~7 queries/visita. Free tier NO cobra por nº
>     de queries; el límite real es transferencia (5 GB Supabase / 100 GB Vercel) y
>     la respuesta es de KB → sin riesgo con tráfico académico.
>   - **Pendiente para cuando se publique:** ping de mantenimiento (cron ligero)
>     para evitar la pausa de Supabase free tras 7 días sin actividad.
> - **Fase 5 ✅** — Panel de control admin `/dashboard/publicacion`.
>   - Permiso `canManagePublicacion` en permissions.ts (admin/IP).
>   - Endpoint PATCH
>     [api/secciones-publicas/[id]](../src/routes/api/secciones-publicas/[id]/+server.ts):
>     valida con `seccionPublicaPatchSchema`, protege con `requireEditorProfile` +
>     `canManagePublicacion`, llama a `invalidatePublicSectionsCache()` tras escribir.
>   - Página
>     [publicacion](../src/routes/(dashboard)/dashboard/publicacion/+page.svelte):
>     toggles `activa` + selector `scope_minimo` por sección, agrupados Páginas /
>     Ficha, guardado optimista con feedback por fila.
>   - Enlace en el Sidebar visible solo para admin/IP.
>   - Verificado: tipos 0 errores, 181 tests, y protección de rutas (303 a login sin
>     sesión, 401 en el endpoint). La verificación visual con login la hace el usuario.
> - **Guard de páginas públicas ✅** (parte de aplicar flags a PÁGINAS, no a la ficha)
>   - `requireSectionVisible(locals, seccionId)` en
>     [server/secciones-publicas.ts](../src/lib/server/secciones-publicas.ts): lanza
>     404 (no delata existencia) si la sección está apagada o el scope no alcanza.
>   - Aplicado en: catalogo, autores, laboratorio, demarcador. El **demarcador dejó
>     de ser `prerender = true`** (necesita servidor para comprobar el flag).
>   - El menú superior, el menú móvil y el footer ocultan los enlaces de páginas
>     apagadas (mapeo href→seccion_id en [(public)/+layout.svelte]).
>   - Verificado en vivo: demarcador (admin/IP) → 404 para anónimo y desaparece del
>     menú; catálogo (anon) → 200 y visible.
>   - **PENDIENTE (B), para la Fase 6:** la ficha de obra aún muestra secciones
>     vacías ("No hay secuencias…") en vez de ocultarlas cuando su sección está
>     apagada. El DATO ya se filtra (Fase 3); falta el {#if sectionVisible} en la UI,
>     que se hará al reescribir la ficha (no se parchea la ficha actual).

---

## 1. Decisión de arquitectura

**Una sola versión COMPLETA, atenuada según login/rol** — NO versiones paralelas.

Razones:
- El catálogo y la ficha **ya** funcionan así (una query/RPC + filtro por scope).
- Una sola fuente de verdad evita fugas de datos (el riesgo real de tener
  versiones paralelas: que la "anon" muestre por error un campo sensible).
- El filtrado vive **en el servidor** (`load` / RPC), nunca solo en el cliente
  con `{#if}`. Si el dato es sensible, no debe salir del servidor.

---

## 2. Dos conceptos ortogonales (no mezclar)

| Concepto | Qué controla | Granularidad | Quién decide |
|---|---|---|---|
| **Permisos por scope** (ya existe) | Qué *datos* ve cada nivel de visitante | Por rol/login y **por obra** | Reglas fijas en código |
| **Feature flags de sección** (a construir) | Qué *secciones/apartados* están activas | Por sección + `scope_minimo` | El admin, desde un panel, en runtime |

Una sección puede estar **encendida** (flag) pero aun así **atenuada** por scope.
Regla de visibilidad de una sección:

```
sección visible  ⇔  activa = true  Y  scopeEfectivoDeLaObra >= scope_minimo
```

---

## 3. Modelo de scope EFECTIVO POR OBRA (clave)

El scope **no es global al visitante**: depende del par (visitante, obra).

`resolveObraScope(viewer, obra)` devuelve el scope efectivo:

- **admin / IP** → `admin_ip` siempre.
- **editor asignado a esa obra** (`obra.editor_asignado === user.id`) → `admin_ip`
  **para esa obra** (ve su ficha como la verían admin/IP, para revisar su trabajo).
- **cualquier otro logueado**, o editor en obra ajena → su scope base
  (`authenticated`, que a efectos de contenido restringido equivale a `anon`).
- **anónimo** → `anon`.

Base existente: `resolvePublicViewerContext()` en
[src/lib/server/public-obras.ts](../src/lib/server/public-obras.ts) ya devuelve
`anon | authenticated | admin_ip`. Falta la resolución **por obra**.

---

## 4. Regla de visibilidad DEFINITIVA (invariante)

Dos puertas independientes (ya existen en la BD):
1. `estado = publicado` (flujo editorial)
2. `visible_publico = true` (toggle de apertura al público)

Acceso en la **zona pública**:

| Visitante | Publicada + visible | Publicada, NO visible | No publicada |
|---|---|---|---|
| **Anónimo** | ✅ | ❌ | ❌ |
| **Logueado (no editor de la obra)** | ✅ | ❌ | ❌ |
| **Editor asignado a esa obra** | ✅ | ✅ | ❌ |
| **Admin / IP** | ✅ | ✅ | ❌ |

> ### ⛔ INVARIANTE DE PUBLICACIÓN (innegociable, transversal a todas las fases)
> En la zona pública, una obra solo es accesible (catálogo o ficha) si
> **`estado = publicado`**. Vale para TODOS los roles, sin excepción
> (admin, IP y editor incluidos). Las obras no publicadas se revisan desde el
> **dashboard**, nunca desde la web pública.
>
> Los feature flags, `scope_minimo` y el panel de control operan
> **exclusivamente sobre obras ya publicadas**: deciden qué secciones/campos se
> muestran, **nunca** si una obra no-publicada se vuelve visible.

`visible_publico` SÍ se relaja, pero solo para **admin/IP** y para el
**editor asignado a esa obra**.

### Estado actual del código vs. esta regla
- RPC `get_obra_ficha_publica`
  ([migración](../supabase/migrations/20260222193000_public_obras_ficha_rpc.sql),
  líneas ~73-74): el muro `o.estado = v_publicado_id` ya es absoluto ✅.
  La relajación de `visible_publico` vía `p_include_hidden` existe, pero hoy
  `p_include_hidden = canSeeAllPublished` es **global** y solo `true` para
  admin/IP → **el editor asignado a su obra no-visible recibe 404 hoy**. Lo
  arregla la Fase 0.
- Catálogo
  ([src/routes/(public)/obras/+page.server.ts](../src/routes/(public)/obras/+page.server.ts),
  líneas ~37-42): filtra `estado = publicado` ✅, pero relaja `visible_publico`
  solo para admin/IP global, **sin incluir al editor asignado**. Lo arregla la
  Fase 0.

---

## 5. Tabla de configuración `secciones_publicas`

Key-value tipado, una fila por sección/sub-sección:

| Campo | Tipo | Notas |
|---|---|---|
| `seccion_id` | slug (PK) | `catalogo`, `laboratorio`, `demarcador`, `autores`, `ficha.autoria`, `ficha.autoria.fuentes`, `ficha.metrica`, `ficha.observaciones`, `ficha.bibliografia`, `ficha.comentarios_publicos`, … |
| `label` | text | nombre legible en el panel |
| `descripcion` | text | ayuda en el panel |
| `activa` | boolean | on/off global (incluye apagar para admin) |
| `scope_minimo` | enum `anon \| authenticated \| admin_ip` | nivel mínimo para verla |
| `orden` | int | orden en el panel |

- `activa = false` → no aparece para nadie (útil para placeholders en obras:
  laboratorio, demarcador).
- `scope_minimo` → suelo de visibilidad configurable (ej. "Fuentes para la
  atribución" con `scope_minimo = authenticated`).
- **RLS:** lectura para todos (anon incl., define la propia web); escritura solo
  admin/IP. Reusar patrón de
  [iter2_reviewers_and_rls](../supabase/migrations/20260210180000_iter2_reviewers_and_rls.sql).
- **Alcance:** SOLO global. El control por-obra ya lo cubre `visible_publico` +
  el scope efectivo por obra. (Sin overrides por obra.)

---

## 6. Plan por fases

### Fase 0 — Scope efectivo por obra (refactor de seguridad, sin features nuevas)
**Hacer aislada, en su propio commit, con tests.** Es el cimiento.

- Añadir `resolveObraScope(viewer, obra)` en
  [public-obras.ts](../src/lib/server/public-obras.ts) (scope efectivo por par
  visitante-obra; contempla editor asignado vía `obra.editor_asignado`, igual
  que `buildObraCapabilities` en [auth.ts](../src/lib/server/auth.ts) ~L122).
- **Catálogo**: query =
  `estado = publicado` **AND** (`visible_publico = true` **OR**
  `editor_asignado = user.id` **OR** admin/IP). Marcar visualmente "tu ficha".
- **Ficha**: `p_include_hidden` pasa a depender de `resolveObraScope(viewer, obra)`,
  no del flag global. El muro `estado = publicado` de la RPC se mantiene intacto.
- **Tests obligados:**
  - editor en obra **no publicada** → 404 (muro).
  - editor en **SU** obra publicada-no-visible → ve.
  - editor en obra **ajena** publicada-no-visible → 404.
  - anónimo en publicada-no-visible → 404.

*Entregable: el editor ya ve su ficha y el resto como anónimo. Sin panel todavía.*

### Fase 1 — Tabla `secciones_publicas` (migración + RLS)
- Migración nueva en `supabase/migrations/` con el esquema de §5.
- Seed con el catálogo de slugs (páginas + sub-secciones de ficha).
- RLS: lectura pública, escritura admin/IP.
- Mergeable sin efecto visible: todo `activa = true`, `scope_minimo` permisivo.

### Fase 2 — Carga única en el layout público
- Crear `(public)/+layout.server.ts` que cargue `secciones_publicas` una vez y
  exponga un mapa resuelto en `data` (cacheable).
- Helper `isSectionVisible(seccionId, scopeEfectivo, sections)` compartido
  servidor/cliente.
- Placeholders (laboratorio, demarcador) ya ocultables con `activa` sin tocar su
  código.

### Fase 3 — Aplicación en DATOS (capa que evita fugas)
- Extender `get_obra_ficha_publica` (o filtrar en el `load` tras la RPC) para
  **no serializar** los bloques cuya sección esté apagada o cuyo `scope_minimo`
  supere el scope efectivo de esa obra.
- Aplicar igual a comentarios públicos y fuentes de atribución (candidatas a
  `scope_minimo = authenticated`).
- Prioridad: el dato no sale del servidor, no solo se oculta en el `{#if}`.

### Fase 4 — ~~Aplicación en UI sobre la ficha actual~~ ❌ ANULADA
La ficha actual se reescribe (Fase 6), así que no tiene sentido envolverla con
flags ahora. La aplicación de flags en la UI se hace directamente en la UI nueva.
Lo único que sí aplica de forma trivial y útil: ocultar páginas placeholder
(laboratorio, demarcador) según `activa` — se hará junto con la UI nueva o como
ajuste menor independiente.

### Fase 5 — Panel de control en el dashboard
- Ruta `(dashboard)/dashboard/publicacion`, protegida a admin/IP
  (`requireEditorProfile` + check de rol, reusar [auth.ts](../src/lib/server/auth.ts)).
- UI de toggles `activa` + selector `scope_minimo` por sección, agrupados
  (Páginas / Ficha). Endpoint API que escriba en `secciones_publicas`
  (respaldado por RLS).
- Opcional: "preview as anon/authenticated" para verificar cada nivel sin
  desloguearse.

### Fase 6 — Reescritura de la UI pública (catálogo + ficha desde cero)
Con el control ya funcionando (Fases 3+5), se rehace la UI consumiendo
`sectionVisibility` y los datos ya filtrados.
- **Catálogo**: rehacer basándose en el diseño de
  [/mockup/catalogo](../src/routes/(public)/mockup/catalogo/+page.svelte)
  (filtros, dual-range, barcode, variantes de fila ya existentes en
  [components/catalogo/mock/](../src/lib/components/catalogo/mock/)). Conectar a
  datos reales en vez de [catalogo-mock.ts](../src/lib/mock/catalogo-mock.ts).
- **Ficha**: rehacer con arquitectura de secciones limpia. Reusar lo que ya
  funciona bien (barcode métrico, modal de secuencias, pie de distribución,
  formato de autoría) — NO reinventar esos componentes.
- Aplicar `isSectionVisible(...)` para envolver cada sección/ítem de navegación.

---

## 7. Orden de ejecución recomendado

1. **Fase 0** ✅ aislada (refactor de seguridad, commit + tests).
2. **1 → 2** ✅ mergeables sin efecto visible (todo encendido / permisivo).
3. **Fase 3** — filtrado de datos por sección (siguiente).
4. **Fase 5** — panel de control admin.
5. **Fase 6** — reescritura de UI (catálogo + ficha) con el control ya operativo.
6. (Fase 4 anulada.)

---

## 8. Decisiones cerradas (para no relitigar)

- Granularidad: **fina + `scope_minimo` por sección** (páginas y sub-secciones de
  ficha).
- Alcance de los flags: **solo global** (sin override por obra).
- Doble gate de publicación: **`estado = publicado` Y `visible_publico = true`**,
  dos puertas independientes (modelo actual de la BD).
- Excepción de `visible_publico`: **admin/IP + editor asignado a esa obra**.
- Muro `estado = publicado`: **absoluto para todos** en la zona pública.

## 9. Pendiente de detallar antes/durante implementación

- Esquema SQL exacto de `secciones_publicas` (tipos, defaults, constraints).
- Lista definitiva y completa de slugs de sección.
- Si la RPC recibe el mapa de secciones como parámetro o se filtra en el `load`.
