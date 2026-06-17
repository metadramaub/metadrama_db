# MetaDrama DB

Aplicación SvelteKit + Supabase para edición y consulta de datos métricos.

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

-> Hacerlo de vez en ucando para tener foto legible del modelo actual y no depender solo de navegar migraciones.

### Tipos TypeScript tras cambios de esquema

```sh
npm run db:types
```

## Flujo cuando hay cambios de BD

1. Crear o ajustar migración en `supabase/migrations`.
2. Aplicar cambios en remoto con `npm run db:push`.
3. Regenerar tipos con `npm run db:types`.
4. Bajar snapshot actualizado con:
   `npx supabase db dump --linked -s public -f supabase/schema.snapshot.sql`
