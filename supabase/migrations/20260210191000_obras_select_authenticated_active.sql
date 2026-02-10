-- Temporary wide read policy for dashboard: any authenticated active editor can read all obras.
-- This matches current project decision (shared visibility among internal editors).

alter table public.obras enable row level security;

drop policy if exists "obras_select_authenticated_active" on public.obras;
create policy "obras_select_authenticated_active"
on public.obras
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
