begin;

alter table public.comentarios_internos
	add column if not exists updated_at timestamptz;

alter table public.cuadros
	add column if not exists created_at timestamptz,
	add column if not exists updated_at timestamptz;

alter table public.dashboard_activity_state
	add column if not exists created_at timestamptz;

alter table public.estrofa_tipo_metros
	add column if not exists updated_at timestamptz;

alter table public.jornadas
	add column if not exists created_at timestamptz,
	add column if not exists updated_at timestamptz;

alter table public.obras_revisores
	add column if not exists updated_at timestamptz;

alter table public.proyecto_activo
	add column if not exists created_at timestamptz,
	add column if not exists updated_at timestamptz;

alter table public.rangos_autores
	add column if not exists created_at timestamptz,
	add column if not exists updated_at timestamptz;

alter table public.secuencias_variaciones
	add column if not exists created_at timestamptz,
	add column if not exists updated_at timestamptz;

update public.autores
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.comentarios_internos
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.cuadros
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.dashboard_activity_state
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.editores
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.estrofa_tipo_metros
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.jornadas
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.obras
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.obras_revisores
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.proyecto_activo
set
	created_at = coalesce(created_at, "timestamp" at time zone 'UTC', now()),
	updated_at = coalesce(updated_at, "timestamp" at time zone 'UTC', created_at, now())
where created_at is null or updated_at is null;

update public.rangos
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.rangos_autores
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.secuencias_metricas
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.secuencias_subtipos_estrofa
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.secuencias_variaciones
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

update public.vocabularios
set
	created_at = coalesce(created_at, updated_at, now()),
	updated_at = coalesce(updated_at, created_at, now())
where created_at is null or updated_at is null;

alter table public.autores
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.comentarios_internos
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.cuadros
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.dashboard_activity_state
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.editores
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.estrofa_tipo_metros
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.jornadas
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.obras
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.obras_revisores
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.proyecto_activo
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.rangos
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.rangos_autores
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.secuencias_metricas
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.secuencias_subtipos_estrofa
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.secuencias_variaciones
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

alter table public.vocabularios
	alter column created_at set default now(),
	alter column created_at set not null,
	alter column updated_at set default now(),
	alter column updated_at set not null;

drop trigger if exists trigger_comentarios_internos_updated_at on public.comentarios_internos;
create trigger trigger_comentarios_internos_updated_at
before update on public.comentarios_internos
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_cuadros_updated_at on public.cuadros;
create trigger trigger_cuadros_updated_at
before update on public.cuadros
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_estrofa_tipo_metros_updated_at on public.estrofa_tipo_metros;
create trigger trigger_estrofa_tipo_metros_updated_at
before update on public.estrofa_tipo_metros
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_jornadas_updated_at on public.jornadas;
create trigger trigger_jornadas_updated_at
before update on public.jornadas
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_obras_revisores_updated_at on public.obras_revisores;
create trigger trigger_obras_revisores_updated_at
before update on public.obras_revisores
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_proyecto_activo_updated_at on public.proyecto_activo;
create trigger trigger_proyecto_activo_updated_at
before update on public.proyecto_activo
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_rangos_autores_updated_at on public.rangos_autores;
create trigger trigger_rangos_autores_updated_at
before update on public.rangos_autores
for each row execute function public.actualizar_updated_at();

drop trigger if exists trigger_secuencias_variaciones_updated_at on public.secuencias_variaciones;
create trigger trigger_secuencias_variaciones_updated_at
before update on public.secuencias_variaciones
for each row execute function public.actualizar_updated_at();

commit;
