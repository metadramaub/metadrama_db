-- Cursor de actividad reciente vista por usuario (sin historial de notificaciones).

create table if not exists public.dashboard_activity_state (
	user_id uuid primary key references public.editores (user_id) on delete cascade,
	last_seen_at timestamptz null,
	updated_at timestamptz not null default now()
);

create index if not exists dashboard_activity_state_last_seen_idx
	on public.dashboard_activity_state (last_seen_at);

drop trigger if exists trigger_dashboard_activity_state_updated_at on public.dashboard_activity_state;
create trigger trigger_dashboard_activity_state_updated_at
before update on public.dashboard_activity_state
for each row execute function public.actualizar_updated_at();

alter table public.dashboard_activity_state enable row level security;

drop policy if exists "dashboard_activity_state_select_self" on public.dashboard_activity_state;
create policy "dashboard_activity_state_select_self"
on public.dashboard_activity_state
for select
to authenticated
using (
	user_id = auth.uid()
	and exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
);

drop policy if exists "dashboard_activity_state_insert_self" on public.dashboard_activity_state;
create policy "dashboard_activity_state_insert_self"
on public.dashboard_activity_state
for insert
to authenticated
with check (
	user_id = auth.uid()
	and exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
);

drop policy if exists "dashboard_activity_state_update_self" on public.dashboard_activity_state;
create policy "dashboard_activity_state_update_self"
on public.dashboard_activity_state
for update
to authenticated
using (
	user_id = auth.uid()
	and exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
)
with check (
	user_id = auth.uid()
	and exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
);

drop policy if exists "dashboard_activity_state_delete_self" on public.dashboard_activity_state;
create policy "dashboard_activity_state_delete_self"
on public.dashboard_activity_state
for delete
to authenticated
using (
	user_id = auth.uid()
	and exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
);
