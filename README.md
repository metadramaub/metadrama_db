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
