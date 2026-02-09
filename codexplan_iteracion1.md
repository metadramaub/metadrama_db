**Plan**

# **METADRAMA Iteración 1: Backoffice MVP + Scaffolding Público**

## **Resumen**

Implementar desde cero una app SvelteKit en este repo (actualmente solo contiene [diagrama_supabase.db](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#)) con enfoque server-first, autenticación Supabase moderna (@supabase/ssr), dashboard privado funcional para edición métrica (tabs 1-3), validaciones en servidor, autoguardado con debounce de 10s, aviso de conflictos vía Realtime, y estructura pública mínima (sin lógica de datos avanzada).

La base de datos se tratará en modo híbrido: partir del esquema remoto actual (db pull) y versionar en repo solo cambios nuevos no destructivos.

## **Decisiones cerradas**

- Alcance de iteración 1: solo backoffice funcional + scaffolding público mínimo.
- Auth: @supabase/ssr.
- Datos: patrón server-first (endpoints/actions de SvelteKit + Zod).
- Estados: workflow editorial estricto por rol.
- Conflictos concurrentes: last write wins con aviso.
- obras.autoria: sincronización por trigger en PostgreSQL.
- RLS: auditoría y parcheo sobre políticas existentes.
- vocabularios: seed SQL versionado.
- Rutas de obra en dashboard: UUID.
- Realtime MVP: avisos y refresco, no coedición campo a campo.
- Testing MVP: unit + integración crítica.

## **Alcance y No Alcance**

- En alcance: auth/login/logout, protección de rutas privadas, layout dashboard, home dashboard, listado de obras, editor de obra tabs datos, estructura, secuencias, autoguardado, validaciones, comentarios internos mínimos, flujo de estado básico, sidebar por rol, scaffolding público.
- Fuera de alcance: lógica completa tabs autoría, análisis, revisión (se dejan placeholders), búsquedas/filtros públicos avanzados, gráficos, gestión de usuarios, coedición en vivo completa, i18n formal multilengua.

## **Interfaces públicas / APIs / tipos a crear**

### **Rutas SvelteKit**

| **Ruta** | **Tipo** | **Resultado iteración 1** |
| --- | --- | --- |
| /login | pública auth | formulario email/password + redirect |
| /(dashboard)/+layout | privada | guard + sidebar + breadcrumbs |
| /dashboard | privada | cards de obras asignadas + resumen por rol |
| /obras | privada | tabla de obras con filtros básicos |
| /obras/[id] | privada | editor con tabs 1-3 funcionales, tabs 4-6 placeholder |
| / /obras /obras/[id] /autores /autores/[id] /about | pública | scaffolding visual/placeholder |

### **Endpoints internos (server-first, JSON)**

| **Endpoint** | **Método** | **Payload principal** | **Respuesta** |
| --- | --- | --- | --- |
| /api/obras | GET | filtros estado, editor, q, paginación | lista + total |
| /api/obras/[id] | GET | - | obra completa para editor |
| /api/obras/[id]/datos | PATCH | título, variantes, género, fechas, edición | obra actualizada + updated_at |
| /api/obras/[id]/estructura/jornadas | POST | jornada_num, v_ini, v_fin | jornada creada |
| /api/obras/[id]/estructura/jornadas/[jornadaId] | PATCH/DELETE | campos jornada | jornada actualizada/eliminada |
| /api/obras/[id]/estructura/cuadros | POST | jornada_id, cuadro_num, v_ini, v_fin, descripcion, certeza_editor | cuadro creado |
| /api/obras/[id]/estructura/cuadros/[cuadroId] | PATCH/DELETE | campos cuadro | cuadro actualizado/eliminado |
| /api/obras/[id]/secuencias | GET/POST | filtros + alta secuencia | lista/creada |
| /api/obras/[id]/secuencias/[secuenciaId] | PATCH/DELETE | campos secuencia | secuencia actualizada/eliminada |
| /api/obras/[id]/secuencias/[secuenciaId]/metros | PUT | metro_ids[] | relación actualizada |
| /api/obras/[id]/estado | PATCH | estado destino + comentario opcional | estado actualizado |
| /api/obras/[id]/comentarios | GET/POST | comentario texto | historial / comentario creado |
| /api/vocabularios | GET | categorías | vocabulario cacheable |

### **Tipos y validadores**

- [database.types.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) generado desde Supabase.
- [obra.types.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) con DTOs de API.
- [validators.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) con Zod para ObraDatosPatch, JornadaInput, CuadroInput, SecuenciaInput, CambioEstadoInput, ComentarioInput.
- [permissions.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) con helpers de rol y transiciones válidas.

### **Interfaces SQL nuevas (no destructivas)**

- Trigger function para mantener obras.autoria sincronizada al cambiar rangos/rangos_autores.
- Triggers updated_at solo donde falten.
- Seed SQL idempotente de vocabularios (upsert por (categoria, termino)).

## **Plan de implementación detallado**

### **Fase 0: Bootstrap de proyecto**

1. Crear SvelteKit + TypeScript + ESLint + Prettier en este repo.
2. Instalar dependencias: Supabase, Tailwind, shadcn-svelte, Zod, TanStack Table, Lucide, date-fns.
3. Configurar Tailwind y base UI (src/lib/components/ui).
4. Crear .env.example con VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, SUPABASE_PROJECT_REF.

### **Fase 1: Supabase híbrido y tipado**

1. Inicializar supabase/ y vincular proyecto remoto.
2. Ejecutar supabase db pull para snapshot inicial local versionado.
3. Añadir migraciones nuevas no destructivas para triggers/funciones faltantes.
4. Añadir [001_vocabularios.sql](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) idempotente.
5. Añadir scripts npm: db:pull, db:types, db:migrate, db:seed.
6. Generar [database.types.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#) desde proyecto remoto.

### **Fase 2: Auth y guardas de ruta**

1. Configurar clientes Supabase SSR/browser (src/lib/services/supabase).
2. [hooks.server.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#): sesión por request + refresh cookie.
3. [+layout.server.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#): redirección a /login si no hay sesión.
4. /login: formulario y manejo errores.
5. Sidebar con datos de editores (nombre + rol; sin foto).

### **Fase 3: RBAC y RLS (auditar/parchear)**

1. Matriz de permisos en backend ([permissions.ts](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/david/.vscode/extensions/openai.chatgpt-0.4.71-win32-x64/webview/#)) y reutilizada por endpoints.
2. Auditoría de políticas actuales tabla por tabla y parche mínimo.
3. Garantizar que editor solo modifique obras asignadas en estados editables.
4. Garantizar que visible_publico solo cambie por admin/IP.
5. Garantizar comentarios internos solo para usuarios con acceso a la obra.

### **Fase 4: Dashboard home y listado obras**

1. /dashboard: cards de obras asignadas con estado, updated_at relativo y progreso.
2. /obras: tabla TanStack con filtros (estado/editor para roles altos), orden por updated_at.
3. Botón “continuar edición” a /obras/[id].

### **Fase 5: Editor de obra tabs 1-3**

1. Estructura tabs y carga lazy del tab activo.
2. Tab Datos: formulario completo + autoguardado 10s + indicador dirty/saving.
3. Tab Estructura: jornadas colapsables, cuadros CRUD, orden automático por v_ini.
4. Tab Secuencias: tabla + sidebar edición + filtros rápidos + CRUD completo.
5. Validaciones en frontend y backend con mismos esquemas Zod.
6. Respuestas 409 para solapes con detalle de conflicto para UI.

### **Fase 6: Realtime de conflictos**

1. Suscripción por obra_id a cambios de obras, jornadas, cuadros, secuencias_metricas.
2. Si llega cambio externo y no hay dirty local: refetch silencioso.
3. Si llega cambio externo con dirty local: banner/toast “otro editor guardó cambios; tu próximo guardado sobrescribirá”.
4. Política final: last write wins.

### **Fase 7: Scaffolding público mínimo**

1. Crear layout público con header/footer básicos.
2. Crear rutas públicas con placeholders y estructura final.
3. Sin consultas complejas ni rendering de datos definitivos en iteración 1.

### **Fase 8: Placeholders tabs 4-6**

1. Renderizar tabs autoría, análisis, revisión como “Próximamente (Iteración 2)”.
2. Mantener navegación y layout final para no rehacer estructura luego.

## **Matriz de estado y permisos (MVP)**

| **Rol** | **Lectura** | **Edición contenido obra** | **Cambio estado** |
| --- | --- | --- | --- |
| editor | obras asignadas | sí, solo en borrador y pendiente | borrador ↔ pendiente |
| revisor | todas | no (solo comentarios/revisión) | pendiente ↔ en_revision, en_revision → validado, validado → en_revision |
| admin/IP | todas | sí | cualquier transición, incluido publicado |

## **Validaciones obligatorias**

- v_ini < v_fin en jornadas, cuadros y secuencias.
- No solapes por ámbito: jornadas en obra, cuadros en jornada, secuencias en obra.
- Secuencia requiere estrofa_tipo_id.
- Secuencia requiere al menos un metro_id.
- Campos requeridos de Datos de obra: titulo, genero_id, edicion.
- Transición de estado inválida por rol devuelve 403.
- Errores de validación devuelven 422 con mapa de campos.

## **Pruebas y escenarios**

| **Tipo** | **Casos** |
| --- | --- |
| Unit (Vitest) | validadores Zod de tabs 1-3, util de progreso, util de transiciones de estado |
| Integración backend | permisos por rol en endpoints, bloqueo por obra no asignada, respuesta 409 en solapes, guardado parcial/autosave |
| Integración datos | trigger de obras.autoria al cambiar rangos/rangos_autores |
| Integración realtime | aviso al recibir actualización externa con dirty local y sin dirty local |

## **Criterios de aceptación iteración 1**

1. Usuario no autenticado no accede a rutas /(dashboard).
2. Editor autenticado ve y edita solo sus obras asignadas.
3. Autoguardado funciona a los 10s y muestra estado visual claro.
4. Solapes de versos no se persisten y se comunican al usuario.
5. Secuencias se gestionan completas (CRUD + metros N:M) con validaciones.
6. Workflow de estados respeta matriz por rol.
7. Cambios concurrentes generan aviso de conflicto en UI.
8. obras.autoria queda sincronizada automáticamente por trigger.
9. Rutas públicas existen y renderizan estructura mínima sin funcionalidades avanzadas.

## **Supuestos y defaults explícitos**

- Existe proyecto Supabase remoto activo con datos de prueba y credenciales disponibles.
- Se usa npm como gestor de paquetes.
- Idioma de UI: español.
- Fechas almacenadas en UTC, mostradas en formato relativo español.
- TipTap y lógica completa tabs 4-6 se difieren a iteración 2.
- No se introduce TanStack Query en iteración 1; se usa load + stores nativos.
- No se hacen cambios destructivos de esquema en la fase híbr