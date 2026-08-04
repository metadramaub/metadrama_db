-- Fase 0 de la migración de anotaciones: la anotación en sombra.
--
-- Una prueba del editor V2 puede colgar de un escenario ficticio, como hasta ahora, o
-- señalar una secuencia métrica real. Nunca las dos cosas. La secuencia real no cambia ni
-- una columna y no sabe que la están anotando: todo el árbol nuevo —realizaciones,
-- elecciones, desviaciones— sigue colgando de la prueba.
--
-- Se revierte borrando la columna. Ver docs/dominio-metrico/plan-migracion-anotaciones.md §6.

-- ---------------------------------------------------------------------------
-- 1 · Una prueba puede señalar una secuencia real
-- ---------------------------------------------------------------------------

alter table public.secuencias_editor_metrico
	alter column escenario_id drop not null;

alter table public.secuencias_editor_metrico
	add column if not exists secuencia_id uuid null
	references public.secuencias_metricas (secuencia_id)
	on update cascade on delete cascade;

-- Si una secuencia real desaparece, su sombra se va con ella. Es deliberado: el
-- laboratorio no puede bloquear una operación de producción.

comment on column public.secuencias_editor_metrico.secuencia_id is
	'Secuencia métrica real que esta prueba anota en paralelo, sin tocarla. Nula cuando la prueba cuelga de un escenario ficticio.';

-- O escenario, o secuencia real. Nunca ninguna y nunca las dos.
alter table public.secuencias_editor_metrico
	drop constraint if exists secuencias_editor_metrico_origen_check;

alter table public.secuencias_editor_metrico
	add constraint secuencias_editor_metrico_origen_check
	check (num_nonnulls(escenario_id, secuencia_id) = 1);

-- Una sola sombra por secuencia real: si hubiera dos, el contraste entre modelos no
-- tendría respuesta única.
create unique index if not exists secuencias_editor_metrico_secuencia_unica
	on public.secuencias_editor_metrico (secuencia_id)
	where secuencia_id is not null;

-- ---------------------------------------------------------------------------
-- 2 · Qué obras abren el editor nuevo
--
-- El interruptor vive en el lado del laboratorio y no en `obras`: producción no se entera
-- de que esto existe, y retirar la fase es borrar una tabla.
-- ---------------------------------------------------------------------------

create table if not exists public.obras_editor_metrico_v2 (
	obra_id uuid primary key references public.obras (obra_id)
		on update cascade on delete cascade,
	nota text null,
	created_by uuid not null default auth.uid() references public.editores (user_id)
		on update cascade on delete restrict,
	created_at timestamptz not null default now()
);

comment on table public.obras_editor_metrico_v2 is
	'Obras abiertas al editor de secuencias V2 durante la anotación en sombra. Se eligen por las formas que traen, no por quién las anota. Las demás siguen con el editor de siempre.';

alter table public.obras_editor_metrico_v2 enable row level security;

drop policy if exists obras_editor_metrico_v2_lectura on public.obras_editor_metrico_v2;
create policy obras_editor_metrico_v2_lectura
	on public.obras_editor_metrico_v2
	for select
	to authenticated
	using (public.auth_is_admin_or_ip());

drop policy if exists obras_editor_metrico_v2_escritura on public.obras_editor_metrico_v2;
create policy obras_editor_metrico_v2_escritura
	on public.obras_editor_metrico_v2
	for all
	to authenticated
	using (public.auth_is_admin_or_ip())
	with check (public.auth_is_admin_or_ip());

-- ---------------------------------------------------------------------------
-- 3 · La propuesta: qué diría el catálogo nuevo de una secuencia ya anotada
--
-- Cada entidad del catálogo declara de qué término legado salió, en `origen_termino_id`.
-- Eso es el mapa de correspondencias vigente: `migracion_terminos_metricos` y
-- `migracion_termino_destinos` están vacías desde que se retiró la matriz de importación.
--
-- Esta vista no decide nada ni escribe nada: propone, para que el editor revise en vez de
-- reanotar desde cero, y para que se pueda medir cuánto acierta el mapa.
-- ---------------------------------------------------------------------------

create or replace view public.propuesta_metrica_secuencia as
select
	s.secuencia_id,
	s.obra_id,
	s.v_ini,
	s.v_fin,
	s.estrofa_tipo_id,
	v.termino as termino_legado,
	f.forma_id as forma_propuesta_id,
	f.nombre as forma_propuesta,
	-- Solo se propone arquitectura cuando la forma tiene una sola o una prototípica: si hay
	-- varias y ninguna manda, la elección es del editor y no se adivina.
	a.arquitectura_id as arquitectura_propuesta_id,
	a.nombre as arquitectura_propuesta
from public.secuencias_metricas s
left join public.vocabularios v
	on v.termino_id = s.estrofa_tipo_id
left join public.formas_metricas f
	on f.origen_termino_id = s.estrofa_tipo_id
	or f.forma_id = s.estrofa_tipo_id
left join lateral (
	select arq.arquitectura_id, arq.nombre
	from public.arquitecturas_forma arq
	where arq.forma_id = f.forma_id
		and arq.activo
	order by arq.principal desc, arq.orden nulls last
	limit 1
) a on f.forma_id is not null;

comment on view public.propuesta_metrica_secuencia is
	'Qué forma y arquitectura del catálogo nuevo corresponden a cada secuencia ya anotada, siguiendo `origen_termino_id`. Es una propuesta para revisar, no una asignación.';

grant select on public.propuesta_metrica_secuencia to authenticated;
