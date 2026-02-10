-- Enforce review-only behavior for assigned reviewers on obras.
-- Reviewers can comment, but they cannot update obras rows directly.

-- Remove reviewer-specific update policy introduced in Iteration 2.
drop policy if exists "obras_update_assigned_reviewer" on public.obras;

-- Recreate core update policy without global/assigned reviewer write paths.
drop policy if exists "obras_update_authenticated" on public.obras;
create policy "obras_update_authenticated"
on public.obras
for update
to authenticated
using (
	exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and obras.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and obras.editor_asignado = e.user_id)
			)
	)
);
