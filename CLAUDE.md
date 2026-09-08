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
npm run audit:metrica  # audita el catálogo métrico contra los criterios de nivel (D1–D16)
npm run audit:editor   # audita qué le pide el editor V2 a cada forma
npm run audit:anotaciones  # comprueba que lo anotado sigue encajando con el catálogo
npm run poda:informe   # regenera la propuesta de poda de la prosa del catálogo
npm run migracion:informe  # regenera docs/dominio-metrico/migracion/, un informe por obra
npm run equivalencias:informe  # regenera el estado de las equivalencias con el vocabulario legado
npm run snapshot:obras # foto fija, un JSON por obra, de todo lo anotado hoy (a backups/)
npm run guion:pruebas  # escribe en xml-lope/guiones/ lo que se va a anotar, sin tocar la base
npm run aplicar:guiones # y lo escribe en la base, borrando antes las obras de prueba anteriores
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

- `src/routes/(public)/` — portada, obras —el buscador, con su vista simple en
  `/obras/listado` y la ficha en `/obras/<slug>`—, autores, laboratorio, demarcador,
  proyecto, recursos, cómo citarnos
- `src/lib/server/public-obras.ts`, `ficha-secciones.ts`, `secciones-publicas.ts`
- El buscador se alimenta de **precomputados** (`obras_resumen`, `autores_resumen`), no de las
  tablas crudas. Se regeneran solo al pulsar «Actualizar datos públicos» en el dashboard; el
  autosave marca suciedad pero no recalcula. `recompute_all()` lo reconstruye todo, y **solo para
  obras publicadas**.
- **La ficha, en cambio, se calcula hoy en vivo** con
  `get_obra_ficha_publica_base_without_slugs`, y por eso funciona la vista previa. Eso está
  cambiando: lo pactado el 8 de septiembre de 2026 es que **en vivo se quede solo la vista previa** y
  que una obra publicada esté enteramente precomputada. Los cinco pasos, en
  [el contexto métrico](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#el-plan-pactado-en-cinco-pasos).
- Qué mide cada dato precomputado y por qué: [docs/metodologia-perfil-metrico.md](docs/metodologia-perfil-metrico.md)
- Dónde vive cada dato hoy, dato a dato: [docs/mapa-precomputacion.md](docs/mapa-precomputacion.md)

### 3. Dominio métrico nuevo — en construcción

Catálogo métrico, editor de secuencias V2 y demarcador nuevo. Es lo más reciente y lo que
está en obras. **Desde el 7 de septiembre de 2026 es también lo único que lee la zona pública.**

- `src/routes/(public)/recursos/catalogo-metrico/` — el catálogo publicado, ficha por forma
- `src/lib/components/metrica/catalogo/` — sus componentes
- `src/lib/components/metrica/editor-v2/` — el editor V2, en la pestaña de secuencias
- `src/lib/server/catalogo-metrico.ts`, `src/lib/metrica/`, `src/routes/api/metrica/`
- `src/lib/demarcador-metrico/` y `src/lib/server/demarcador-metrico.ts` — el demarcador nuevo,
  que compila su catálogo desde la base en cada carga de `/recursos/demarcador`
- **`src/lib/metrica/rejilla.ts`** — la arquitectura dibujada verso a verso, y de dónde sale el
  perfil de cada una. Es puro y está probado; lo pinta
  `src/lib/components/metrica/MetricPositionGrid.svelte`, que consumen la ficha de `/formas`, el
  demarcador y el recuadro de la norma del editor V2. Si una forma se dibuja mal, el fallo está en
  el catálogo, no aquí: no hay reglas filológicas escritas en ese módulo.
- **`src/lib/components/metrica/PublicArchitectureCard.svelte`** — la ficha de una arquitectura,
  leída dimensión a dimensión y marcando qué fija la norma, qué elige la realización y qué se
  observa al anotar. **Cada decisión de esa pantalla viene de un caso que se leía mal y está
  comentada en el propio componente**; el razonamiento del día en que se rehízo quedó en
  [histórico](docs/dominio-metrico/historico/catalogo-publico-2026-08-12.md).

El editor V2 sustituyó ya al selector anterior; **queda migrar las secuencias que dependen del
vocabulario viejo**, obra por obra y a mano con los editores. Todo el razonamiento vive en
`docs/dominio-metrico/` porque el diseño sigue abierto.

**Empieza por [docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md).**
No leas la carpeta entera: ese archivo dice qué documentos tocan según la tarea, y
[el índice](docs/dominio-metrico/README.md) los agrupa por para qué sirven.

**La revisión del catálogo está terminada, y con ella la de su prosa.** Las formas activas y los
dos tramos sin forma se contrastaron con seis monografías hasta el 8 de agosto de 2026; las seis
lecturas transversales sobre el catálogo entero se cerraron el 10; y **la prosa de las 28 fichas
quedó revisada forma por forma el 21 de agosto**. Ese mismo día entraron **seis formas nuevas** al llenar el hueco
de las estrofas de siete, ocho, once y doce versos —copla de arte menor, copla castellana, octava
aguda, septilla, oncena y copla manriqueña—, y el 22 otras cinco al cerrar las de siete y las
**estrofas enlazadas** que Navarro Tomás documenta en el teatro primitivo —septeto, septeto-lira,
redondilla enlazada, sextilla enlazada y septilla enlazada—, y el 24 de agosto **las cuatro que le
faltaban a la serie alirada** —cuarteto-lira, octava-lira, novena-lira y décima-lira—, al
sistematizarla entera: el catálogo tiene hoy **41 formas y 2 tramos sin forma**. El diario de ese proceso está archivado en
[historico/](docs/dominio-metrico/historico/). **Lo que sigue sin decidir**, forma por forma y con
el pasaje de la fuente de cada caso, está en
[cuestiones para el IP](docs/dominio-metrico/cuestiones-para-el-ip.md): son decisiones
filológicas, no técnicas, y las toma el IP.

**El editor V2 es ya el que ven los editores**, y `develop` se fusionó a `main` el 7 de septiembre
de 2026. Los campos propios de la secuencia y el paso de la precomputación y la ficha al catálogo
nuevo se cerraron ese mismo día. **El trabajo en curso es llevar la zona pública a lo
precomputado**: la ficha en vivo se queda solo para la vista previa, y una obra publicada estará
enteramente precomputada. Los cinco pasos y el estado, en
[el plan pactado](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#el-plan-pactado-en-cinco-pasos).
Migrar lo ya anotado viene después.

**Lo demás que queda pendiente está inventariado** en
[CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#qué-queda-pendiente).
El bloque A son los casos en que una secuencia real no tendría dónde caer; el B, aquellos en que un
editor no puede registrar lo que ve; el C, deudas del modelo sin urgencia.

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
declarar lo que la norma no fija. **Los dos diagramas `.svg` se rehicieron el 10 de agosto de
2026** y cada documento muestra el suyo: si cambias el modelo, míralos.

**Una función SQL no está probada hasta que se ejecuta.** Un cuerpo entrecomillado no se revalida
al borrar una columna, y PL/pgSQL resuelve los campos de un `record` en ejecución: `db push`,
`npm run check` y las pruebas pasan sobre código roto. En una semana mordió cuatro veces, una de
ellas dejando el demarcador cinco días sin funcionar y otra todas las fichas de `/formas`. **Las
guardas de las migraciones ejecutan lo que tocan**, no solo comprueban el dato.

**La frontera entre lo viejo y lo nuevo cayó el 7 de septiembre de 2026.** El editor V2 escribe en
las tablas `anotacion_*` y **la zona pública lee solo de ahí**: el recompute, el buscador y la ficha
pasaron al catálogo nuevo sin puente al vocabulario legado. Lo que no ha cambiado es que el editor
no toca `secuencias_metricas.estrofa_tipo_id`. Quedan **263 secuencias** con el vocabulario legado
—en las 88 obras en borrador y las 5 en vista previa— y **hasta que se migren no tienen perfil**.
Las 12 obras publicadas son de prueba: se generan con `npm run guion:pruebas` y
`npm run aplicar:guiones`, y **no sirven para validar un hallazgo**, solo para comprobar que la
maquinaria calcula y dibuja.

**Migraciones.** Una migración aplicada no se edita nunca — `db push` la ignora en
silencio. Para cambiar algo ya migrado, se escribe una migración nueva con sentencias
idempotentes. Tras cambiar funciones de recompute, ejecutar `recompute_all()`.

**La base de datos es la fuente de verdad.** Los precomputados, el catálogo del
demarcador, las fichas y las redes son proyecciones regenerables. Si un documento y el SQL
difieren, manda el SQL.

**Ramas.** Se trabaja en `main`, que es la versión desplegada: `develop` se fusionó el 7 de
septiembre de 2026. Hay un solo Supabase, sin proyecto de staging, así que **un cambio de esquema
aparece en producción al instante**. Antes de una migración que toque datos anotados: copia completa
—`README.md`— y `npm run snapshot:obras`, que deja un JSON legible por obra en `backups/`.

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
| `src/lib/demarcador/` — demarcador legado, sobre JSON estáticos | `src/lib/demarcador-metrico/` — el motor nuevo, sobre el catálogo |
| `src/routes/(public)/obras/` — buscador público de obras, antes `/catalogo` | `src/lib/components/metrica/catalogo/` — gestor del catálogo métrico |
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
