# Versología

Base de datos y herramientas de estilometría estrófica para el verso dramático español.
Proyecto de Gaston Gilabert y David Merino Recalde, publicado en
`versologia.metadrama.org`. El repositorio se llama `metadrama_db` y la marca interna
antigua es METADRAMA: son el mismo proyecto.

Dos públicos: un **equipo editorial** que anota obras desde el dashboard, y una **zona
pública** de consulta e investigación. Toda la web está además tras una contraseña global
mientras el proyecto no se abre.

**Stack:** SvelteKit 2 + Svelte 5 (runes) · TypeScript · Tailwind · Supabase (PostgreSQL,
auth, RLS) · Vitest · Vercel. La aplicación y la documentación están en español.

## Comandos

```sh
npm run dev            # desarrollo
npm run check          # tipos + svelte-check
npm run test           # vitest
npm run lint           # eslint
npm run db:push        # aplica migraciones al Supabase enlazado
npm run db:types       # regenera src/lib/types/database.types.ts
npm run audit:metrica  # audita el catálogo métrico contra los criterios de nivel
npm run audit:campos   # comprueba que los campos editables del gestor existen como columna
npm run migracion:informe  # regenera docs/dominio-metrico/migracion/, un informe por obra
npm run equivalencias:informe  # regenera el estado de las equivalencias con el vocabulario legado
```

## Los tres subsistemas

La app son tres cosas distintas. Antes de tocar nada, identifica en cuál estás.

### 1. Editorial — el núcleo

Donde el equipo anota las obras. Es lo que está en producción y lo que usan los editores
ahora mismo.

- `src/routes/(dashboard)/dashboard/obras/[id]/` — editor de obra por pestañas
- `src/lib/components/editor/` — las pestañas: datos, estructura, secuencias, autoría,
  observaciones, revisión, comentarios internos
- `src/routes/api/obras/[id]/**` — la mayor parte de los endpoints del proyecto
- `src/lib/server/` — acceso a datos: `obras.ts`, `autores.ts`, `autoria.ts`,
  `comentarios.ts`, `auth.ts`, `revision-checklist.ts`
- `src/lib/content/dashboard-guide/` — el manual del editor, en Markdown

Sin documentación en `docs/`. La guía del dashboard es lo más cercano a una
especificación de cómo se espera que se anote.

### 2. Zona pública

- `src/routes/(public)/` — portada, catálogo, ficha de obra, autores, laboratorio,
  demarcador, proyecto, recursos, cómo citarnos
- `src/lib/server/public-obras.ts`, `ficha-secciones.ts`, `secciones-publicas.ts`
- Se alimenta de **precomputados** (`obras_resumen`, `autores_resumen`), no de las tablas
  crudas. Se regeneran solo al pulsar «Actualizar datos públicos» en el dashboard; el
  autosave marca suciedad pero no recalcula. `recompute_all()` lo reconstruye todo.
- Qué mide cada dato precomputado y por qué: [docs/metodologia-perfil-metrico.md](docs/metodologia-perfil-metrico.md)

### 3. Dominio métrico nuevo — en construcción

Catálogo métrico, editor de secuencias V2 y demarcador nuevo. Es lo más reciente y lo que
está en obras. **Convive con el sistema viejo sin tocarlo.**

- `src/routes/(dashboard)/dashboard/metrica/` — gestor del catálogo, editor V2 y
  compilación del demarcador
- `src/lib/components/metrica/catalogo/` — gestor del catálogo
- `src/lib/components/metrica/editor-v2/` — el editor V2
- `src/lib/server/catalogo-metrico.ts`, `src/lib/metrica/`, `src/routes/api/metrica/`
- `src/lib/demarcador-nuevo/`

Cuando el editor V2 esté aprobado sustituirá al selector que hoy está en producción, y se
migrarán todas las secuencias que ahora dependen del vocabulario viejo. Hasta entonces,
todo el razonamiento vive en `docs/dominio-metrico/` porque el diseño sigue abierto.

**Empieza por [docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md).**
No leas los 20 documentos: ese archivo dice cuáles tocan según la tarea.

**La revisión del catálogo está terminada.** Las 27 formas activas y los dos tramos sin forma se
contrastaron con seis monografías hasta el 8 de agosto de 2026, y **las seis lecturas
transversales sobre el catálogo entero quedaron cerradas el 10**: el concepto de variedad, la
automatización de las preguntas del editor, la reutilización de secciones, la modalidad y la
primacía, las reglas de repetición y el modelo de esquemas abiertos. El relato está en
[docs/dominio-metrico/revision-del-catalogo-estado.md](docs/dominio-metrico/revision-del-catalogo-estado.md),
que es el único sitio donde se lleva esa cuenta.

**Lo que queda pendiente está inventariado** en
[CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#qué-queda-pendiente),
y el orden lo fijó el IP: **primero terminar el modelo; el editor V2, el gestor del catálogo y
el demarcador, al final**, porque se derivan de él y hacerlos antes obliga a hacerlos dos veces.

## Reglas duras

**Ningún documento es verdad: se contrasta con la base en vivo.** La documentación describe lo que
alguien creyó en su momento, y en agosto de 2026 se encontraron columnas retiradas, vocabularios
que la base nunca aceptó y garantías «implementadas» que no existían. Antes de apoyarte en una
afirmación sobre una tabla, una columna, un valor admitido o un disparador, **compruébala**.

**Al cambiar el modelo, revisa lo que lo describe.** Un cambio en el catálogo casi siempre obliga
a tocar [el modelo aplicado](docs/dominio-metrico/implementacion-metrica.md) —tablas, decisiones,
garantías— y a veces
[la ontología](docs/dominio-metrico/ontologia-verso-espanol.md), aunque esta es tan general que
rara vez la mueve un cambio pequeño: solo cuando aparece una manera nueva de decir algo, como
declarar lo que la norma no fija. Los dos diagramas `.svg` quedan pendientes de rehacer.

**Una función SQL no está probada hasta que se ejecuta.** Un cuerpo entrecomillado no se revalida
al borrar una columna, y PL/pgSQL resuelve los campos de un `record` en ejecución: `db push`,
`npm run check` y las pruebas pasan sobre código roto. En una semana mordió cuatro veces, una de
ellas dejando el demarcador cinco días sin funcionar y otra todas las fichas de `/formas`. **Las
guardas de las migraciones ejecutan lo que tocan**, no solo comprueban el dato.

**La frontera entre lo viejo y lo nuevo.** Las secuencias reales de las obras usan
`secuencias_metricas` con `estrofa_tipo_id` y el vocabulario métrico legado. El editor V2
escribe **únicamente** en tablas `*_editor_metrico`: no crea obras, no toca
`secuencias_metricas`, no alimenta fichas, buscadores ni resúmenes. Hay editores
trabajando; esta frontera no se adelanta.

**Migraciones.** Una migración aplicada no se edita nunca — `db push` la ignora en
silencio. Para cambiar algo ya migrado, se escribe una migración nueva con sentencias
idempotentes. Tras cambiar funciones de recompute, ejecutar `recompute_all()`.

**La base de datos es la fuente de verdad.** Los precomputados, el artefacto del
demarcador, las fichas y las redes son proyecciones regenerables. Si un documento y el SQL
difieren, manda el SQL.

**Ramas.** Se trabaja en `develop`. `main` es la versión desplegada y permanece estable.
Ambas comparten el mismo Supabase: no hay proyecto de staging.

### Invariantes de la zona pública

Verificadas contra el código, no copiadas de un plan.

- **El catálogo público solo muestra `estado = publicado`.** El muro es absoluto ahí, para
  todos los roles.
- **La ficha admite además vista previa editorial.** `can_view_obra_ficha_publica`
  (migración `20260624120000_editorial_preview_workflow.sql`) deja ver una obra en
  `vista_previa` o `listo_para_publicar` a admin/IP y al editor asignado; la ficha muestra
  entonces un aviso. Para el anónimo no cambia nada. Esa obra no aparece en el catálogo.
- **Doble puerta sobre lo publicado:** `estado = publicado` **y** `visible_publico = true`.
  Solo la segunda se relaja, y solo para admin/IP y para el editor asignado *a esa obra*.
- **El scope es por par (visitante, obra), no global:** `resolveObraScope` en
  `src/lib/server/public-obras.ts`. Un editor ve su ficha como la vería admin/IP, y las
  ajenas como anónimo. No decide acceso por sí solo: el muro de estado se aplica aparte.
- **Visibilidad de una sección:** `activa = true` y `scopeEfectivo >= scope_minimo`. El
  admin la gobierna desde `/dashboard/publicacion`. Los flags deciden qué secciones se
  muestran de una obra publicada; nunca vuelven visible una obra no publicada.
- **El filtrado vive en el servidor.** Si una sección está apagada, el dato no sale del
  `load` — no basta con un `{#if}` en la UI. Una sección desconocida es no visible.

### Roles y acceso

`editor`, `admin`, `ip`; `revisor` se normaliza a `editor`. Las reglas están en
`src/lib/utils/permissions.ts`, no dispersas por las rutas. Toda la web va tras una
contraseña global comprobada en `src/hooks.server.ts`, que redirige a `/acceso`.

## Nombres que se parecen y no son lo mismo

| Esto | No es esto |
|---|---|
| `src/lib/demarcador/` — demarcador legado, sobre JSON estáticos | `src/lib/demarcador-nuevo/` — compilado desde el catálogo métrico |
| `src/routes/(public)/catalogo/` — buscador público de obras | `src/lib/components/metrica/catalogo/` — gestor del catálogo métrico |
| `src/lib/catalogo/` — filtros del buscador de obras | `src/lib/metrica/catalogo.ts` — tipos del catálogo métrico |
| `src/routes/(public)/mockup/` — maqueta de diseño con datos falsos | la zona pública real |

## Documentación

- `docs/dominio-metrico/` — el dominio métrico nuevo. Entrada:
  [CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md)
- [docs/metodologia-perfil-metrico.md](docs/metodologia-perfil-metrico.md) — qué mide cada
  dato precomputado y por qué. Canónico: si añades una medida, se anota aquí.
- [docs/precomputacion-estrategias.md](docs/precomputacion-estrategias.md) y
  [docs/plan-precomputacion-implementacion.md](docs/plan-precomputacion-implementacion.md)
  — decisiones y estado de la capa precomputada.
- [docs/revision-de-vocabularios.md](docs/revision-de-vocabularios.md) — los tres sitios
  donde viven hoy los vocabularios y el inventario de los 60 enums en `CHECK`. Anotado, sin
  decidir: se revisa cuando el dominio métrico pase a `main`.
- `README.md` — arranque, migraciones y backups.

## Convenciones

- **Componentes reutilizables.** Los componentes de presentación no dependen de tipos de
  una superficie concreta: consumen tipos de presentación propios para servir en ficha,
  catálogo y perfil de autor. Ver `src/lib/components/metrica/metric-display.types.ts`.
- **Commits en español, sin `Co-Authored-By`,** escritos como los firma el autor del
  proyecto. Cuerpo explicativo cuando la decisión lo merece.
- Los tests van junto al código que prueban (`*.test.ts`).
