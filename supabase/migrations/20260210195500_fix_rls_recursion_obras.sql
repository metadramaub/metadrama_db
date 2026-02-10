-- Fix infinite recursion between RLS policies on obras <-> obras_revisores.
-- Root cause:
-- - obras select policies read obras_revisores
-- - obras_revisores select policy read obras
-- This migration breaks that cycle.

-- 1) Remove obras SELECT policies that depend on obras_revisores.
drop policy if exists "obras_select_dashboard_access" on public.obras;
drop policy if exists "obras_select_assigned_reviewer" on public.obras;

-- 2) Recreate obras_revisores SELECT policy without referencing public.obras.
drop policy if exists "obras_revisores_select" on public.obras_revisores;
create policy "obras_revisores_select"
on public.obras_revisores
for select
to authenticated
using (
  exists (
    select 1
    from public.editores e
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
  )
);
