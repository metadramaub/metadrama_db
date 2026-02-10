-- Fix dashboard visibility of obras for authenticated editorial roles.
-- Ensures admin/IP/revisor can read all obras, editor only assigned ones,
-- and assigned reviewers can read their assigned works.

alter table public.obras enable row level security;

drop policy if exists "obras_select_dashboard_access" on public.obras;
create policy "obras_select_dashboard_access"
on public.obras
for select
to authenticated
using (
  exists (
    select 1
    from public.editores e
    join public.vocabularios vr on vr.termino_id = e.role
    where e.user_id = auth.uid()
      and coalesce(e.activo, true)
      and (
        lower(vr.termino) in ('admin', 'ip', 'revisor')
        or (lower(vr.termino) = 'editor' and obras.editor_asignado = e.user_id)
      )
  )
  or exists (
    select 1
    from public.obras_revisores r
    where r.obra_id = obras.obra_id
      and r.revisor_id = auth.uid()
  )
);
