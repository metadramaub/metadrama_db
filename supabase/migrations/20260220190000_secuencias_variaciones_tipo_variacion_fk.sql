-- Normaliza tipos de variacion de secuencias a FK contra vocabularios.tipo_variacion
-- y define taxonomia jerarquica con padre "irregular".

-- 1) Inserta/actualiza terminos canonicos
insert into public.vocabularios (
	categoria,
	termino,
	termino_padre_id,
	nivel,
	orden,
	activo,
	definicion
)
values
	('tipo_variacion', 'cantado', null, 1, 10, true, 'Versos cantados dentro de una secuencia.'),
	('tipo_variacion', 'irregular', null, 1, 20, true, 'Agrupador de irregularidades metricas puntuales.'),
	('tipo_variacion', 'hipometrico', null, 2, 21, true, 'Verso irregular con menos silabas de las esperadas.'),
	('tipo_variacion', 'hipermetrico', null, 2, 22, true, 'Verso irregular con mas silabas de las esperadas.'),
	('tipo_variacion', 'rima_defectuosa', null, 1, 30, true, 'Rima no esperada en una secuencia.'),
	('tipo_variacion', 'laguna', null, 1, 40, true, 'Versos faltantes (rango conocido).'),
	('tipo_variacion', 'prosa', null, 1, 50, true, 'Intervalo entre versos donde aparece texto en prosa.')
on conflict (categoria, termino)
do update
set
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = excluded.activo,
	definicion = excluded.definicion,
	updated_at = now();

-- 2) Ajusta jerarquia: hipometrico/hipermetrico cuelgan de irregular
update public.vocabularios as child
set
	termino_padre_id = parent.termino_id,
	nivel = 2,
	updated_at = now()
from public.vocabularios as parent
where child.categoria = 'tipo_variacion'
	and parent.categoria = 'tipo_variacion'
	and parent.termino = 'irregular'
	and child.termino in ('hipometrico', 'hipermetrico');

update public.vocabularios
set
	termino_padre_id = null,
	nivel = 1,
	updated_at = now()
where categoria = 'tipo_variacion'
	and termino in ('cantado', 'irregular', 'rima_defectuosa', 'laguna', 'prosa');

-- 3) Migra secuencias_variaciones a FK tipo_variacion_id
alter table public.secuencias_variaciones
	add column if not exists tipo_variacion_id uuid;

update public.secuencias_variaciones as sv
set tipo_variacion_id = v.termino_id
from public.vocabularios as v
where v.categoria = 'tipo_variacion'
	and lower(v.termino) = (
		case lower(trim(coalesce(sv.tipo_variacion, '')))
			when 'irregular/hipometrico' then 'hipometrico'
			when 'irregular/hipermetrico' then 'hipermetrico'
			else lower(trim(coalesce(sv.tipo_variacion, '')))
		end
	)
	and sv.tipo_variacion_id is null;

do $$
declare
	remaining integer;
begin
	select count(*)
	into remaining
	from public.secuencias_variaciones
	where tipo_variacion_id is null;

	if remaining > 0 then
		raise exception
			'No se pudieron mapear % filas de secuencias_variaciones a vocabularios.tipo_variacion',
			remaining;
	end if;
end $$;

alter table public.secuencias_variaciones
	alter column tipo_variacion_id set not null;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'secuencias_variaciones_tipo_variacion_id_fkey'
	) then
		alter table public.secuencias_variaciones
			add constraint secuencias_variaciones_tipo_variacion_id_fkey
			foreign key (tipo_variacion_id)
			references public.vocabularios (termino_id);
	end if;
end $$;

create index if not exists idx_variaciones_tipo_id
	on public.secuencias_variaciones (tipo_variacion_id);

drop index if exists public.idx_variaciones_tipo;

alter table public.secuencias_variaciones
	drop column if exists tipo_variacion;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'secuencias_variaciones_v_ini_le_v_fin_chk'
	) then
		alter table public.secuencias_variaciones
			add constraint secuencias_variaciones_v_ini_le_v_fin_chk
			check (v_ini <= v_fin);
	end if;
end $$;
