-- Permitir lectura de perfiles de editores activos para dashboard interno.

alter table public.editores enable row level security;

drop policy if exists "editores_select_active_authenticated" on public.editores;
create policy "editores_select_active_authenticated"
on public.editores
for select
to authenticated
using (coalesce(activo, true));
