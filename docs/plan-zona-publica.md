# Plan — Zona pública con control de visibilidad por secciones

> Documento de trabajo para diseñar e implementar la parte pública de la web
> (buscador/catálogo, fichas de obra, laboratorio, demarcador) con control de
> roles/permisos y un panel de control para encender/apagar secciones.
>
> **Estado:** diseño cerrado, pendiente de implementar. Empezar por la Fase 0.

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

### Fase 4 — Aplicación en UI
- Envolver bloques de la ficha
  ([obras/[id]/+page.svelte](../src/routes/(public)/obras/[id]/+page.svelte)) y los
  ítems de navegación ([navigation.ts](../src/lib/config/navigation.ts)) con los
  flags resueltos. Cosmético; la garantía está en Fase 3.

### Fase 5 — Panel de control en el dashboard
- Ruta `(dashboard)/dashboard/publicacion`, protegida a admin/IP
  (`requireEditorProfile` + check de rol, reusar [auth.ts](../src/lib/server/auth.ts)).
- UI de toggles `activa` + selector `scope_minimo` por sección, agrupados
  (Páginas / Ficha). Endpoint API que escriba en `secciones_publicas`
  (respaldado por RLS).
- Opcional: "preview as anon/authenticated" para verificar cada nivel sin
  desloguearse.

---

## 7. Orden de ejecución recomendado

1. **Fase 0** primero y aislada (refactor de seguridad, su propio commit + tests).
2. **1 → 2** mergeables sin efecto visible (todo encendido / permisivo).
3. **3 → 4** incrementales.
4. **5** al final.

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
