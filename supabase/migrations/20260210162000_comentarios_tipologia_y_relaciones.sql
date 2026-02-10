-- Centraliza la tipologia de comentarios internos y agrega relacion opcional
-- con entidades concretas del analisis (secuencia/jornada/cuadro/rango).

-- 1) Vocabulario de tipos de comentario
insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	orden,
	activo,
	definicion
)
values
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f001', 'tipo_comentario', 'general', 10, true, 'Comentario interno general'),
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f002', 'tipo_comentario', 'revision', 20, true, 'Comentario del flujo de revision'),
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f003', 'tipo_comentario', 'tecnico', 30, true, 'Incidencia tecnica o de metadatos'),
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f004', 'tipo_comentario', 'estado', 40, true, 'Comentario asociado a cambio de estado')
on conflict (categoria, termino)
do update
set
	activo = true,
	orden = excluded.orden,
	definicion = excluded.definicion,
	updated_at = now();

-- 2) Nuevas columnas de tipologia y contexto
alter table public.comentarios_internos
	add column if not exists tipo_comentario_id uuid,
	add column if not exists secuencia_id uuid,
	add column if not exists jornada_id uuid,
	add column if not exists cuadro_id uuid,
	add column if not exists rango_id uuid;

-- 3) Backfill de filas existentes a tipo "general"
update public.comentarios_internos ci
set tipo_comentario_id = v.termino_id
from public.vocabularios v
where v.categoria = 'tipo_comentario'
	and v.termino = 'general'
	and ci.tipo_comentario_id is null;

-- 4) Constraints y FKs
alter table public.comentarios_internos
	alter column tipo_comentario_id set not null;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_tipo_comentario_id_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_tipo_comentario_id_fkey
			foreign key (tipo_comentario_id)
			references public.vocabularios (termino_id);
	end if;
end $$;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_secuencia_id_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_secuencia_id_fkey
			foreign key (secuencia_id)
			references public.secuencias_metricas (secuencia_id)
			on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_jornada_id_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_jornada_id_fkey
			foreign key (jornada_id)
			references public.jornadas (jornada_id)
			on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_cuadro_id_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_cuadro_id_fkey
			foreign key (cuadro_id)
			references public.cuadros (cuadro_id)
			on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_rango_id_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_rango_id_fkey
			foreign key (rango_id)
			references public.rangos (rango_id)
			on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_un_contexto_chk'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_un_contexto_chk
			check (
				(
					(coalesce((secuencia_id is not null)::int, 0))
					+ (coalesce((jornada_id is not null)::int, 0))
					+ (coalesce((cuadro_id is not null)::int, 0))
					+ (coalesce((rango_id is not null)::int, 0))
				) <= 1
			);
	end if;
end $$;

-- 5) Indices de consulta
create index if not exists idx_comentarios_tipo on public.comentarios_internos (tipo_comentario_id);
create index if not exists idx_comentarios_secuencia on public.comentarios_internos (secuencia_id);
create index if not exists idx_comentarios_jornada on public.comentarios_internos (jornada_id);
create index if not exists idx_comentarios_cuadro on public.comentarios_internos (cuadro_id);
create index if not exists idx_comentarios_rango on public.comentarios_internos (rango_id);
