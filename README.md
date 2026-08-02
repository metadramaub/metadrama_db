# Versología

Base de datos y herramientas de estilometría estrófica para el verso dramático español,
de Gaston Gilabert y David Merino Recalde. Se publica en `versologia.metadrama.org`. Este
repositorio se llama `metadrama_db` y la marca interna antigua es METADRAMA: son el mismo
proyecto.

La aplicación es un SvelteKit + Supabase con dos caras: un **dashboard** donde el equipo
editorial anota las obras, y una **zona pública** de consulta —catálogo, ficha de obra,
autores, laboratorio y demarcador— alimentada por datos precomputados. Toda la web está
tras una contraseña global mientras el proyecto no se abre.

## Por dónde empezar

- **[CLAUDE.md](CLAUDE.md)** — mapa del proyecto: los tres subsistemas, dónde vive cada
  cosa, las reglas duras y qué documentación leer según la tarea. Es la puerta de entrada.
- **[docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md](docs/dominio-metrico/CONTEXTO-PARA-CONTINUAR.md)**
  — el dominio métrico nuevo (catálogo, editor V2, demarcador), que está en construcción.
- **[docs/metodologia-perfil-metrico.md](docs/metodologia-perfil-metrico.md)** — qué mide
  cada dato precomputado de obra y autor, y por qué.

El resto de este archivo cubre el arranque y la operativa de la base de datos.

## Requisitos

- Node.js 20+
- npm
- Supabase CLI

## Arranque rápido

```sh
npm install
npm run dev
```

## Comandos de desarrollo

```sh
# validación de tipos + Svelte
npm run check

# tests
npm run test

# build producción
npm run build
```

## Base de datos (Supabase)

Comandos más usados en este repo:

```sh
# push de migraciones al proyecto remoto linkeado
npm run db:push
# equivalente:
npx supabase db push

# pull de esquema remoto como nueva migración
npm run db:pull
# equivalente:
npx supabase db pull

# diff de cambios locales de esquema
npm run db:diff
# equivalente:
npx supabase db diff

# push incluyendo seed
npm run db:seed
```

### Backup antes de migraciones remotas

La carpeta `/backups/` está ignorada por Git y se usa para copias locales que no deben subirse a GitHub.

`supabase db dump` ejecuta `pg_dump` dentro de un contenedor, así que Docker Desktop debe estar arrancado antes de hacer el backup. Como según la documentación de Supabase el dump por defecto no incluye datos ni roles, para una copia completa de trabajo conviene guardar tres archivos: esquema, datos y roles.

En PowerShell, desde la raíz del repo:

```powershell
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = Join-Path 'backups\supabase' $stamp
New-Item -ItemType Directory -Force -Path $dir | Out-Null

npx supabase db dump --linked -f (Join-Path $dir 'schema.sql')
npx supabase db dump --linked --data-only -f (Join-Path $dir 'data.sql')
npx supabase db dump --linked --role-only -f (Join-Path $dir 'roles.sql')

Get-ChildItem -LiteralPath $dir | Select-Object Name,Length
```

No aplicar migraciones si alguno de los archivos queda con `Length` 0 o si la CLI informa errores. En ese caso, revisar que Docker Desktop esté activo y repetir el proceso en una carpeta nueva.

### Snapshot del esquema actual (recomendado periódicamente)

```sh
npx supabase db dump --linked -s public -f supabase/schema.snapshot.sql
```

-> Hacerlo de vez en cuando para tener foto legible del modelo actual y no depender solo de navegar migraciones.

### Tipos TypeScript tras cambios de esquema

```sh
npm run db:types
```

## Flujo cuando hay cambios de BD

1. Crear una migración nueva en `supabase/migrations`.
2. Aplicar cambios en remoto con `npm run db:push`.
3. Regenerar tipos con `npm run db:types`.
4. Bajar snapshot actualizado con:
   `npx supabase db dump --linked -s public -f supabase/schema.snapshot.sql`

> **Una migración aplicada no se edita.** `db push` solo aplica las que aún no están
> registradas en `supabase_migrations.schema_migrations`, así que editar una ya aplicada
> se ignora en silencio. Para cambiar algo ya migrado, escribir una migración nueva con
> sentencias idempotentes (`add column if not exists`, `create or replace function`).
> Si el cambio afecta a funciones de recompute, ejecutar después `recompute_all()`.
