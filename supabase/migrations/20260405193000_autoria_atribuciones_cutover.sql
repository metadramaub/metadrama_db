-- Cutover total de autoria:
-- - elimina modelo legacy rangos/rangos_autores
-- - crea modelo de atribuciones (obra/jornada) + autores por atribucion
-- - elimina columnas legacy obras.autoria y obras.url_informe_autoria
-- - elimina contexto rango_id en comentarios internos

begin;

-- ---------------------------------------------------------------------------
-- 1) Vocabularios de autoria
-- ---------------------------------------------------------------------------
insert into public.vocabularios (
	categoria,
	termino,
	termino_padre_id,
	nivel,
	orden,
	activo,
	created_at,
	updated_at
)
values
	('tipo_atribucion', 'tradicional', null, 1, 10, true, now(), now()),
	('tipo_atribucion', 'estilometria_lexica', null, 1, 20, true, now(), now()),
	('modalidad_atribucion', 'unica', null, 1, 10, true, now(), now()),
	('modalidad_atribucion', 'alternativa', null, 1, 20, true, now(), now()),
	('modalidad_atribucion', 'colaborativa', null, 1, 30, true, now(), now())
on conflict (categoria, termino)
do update set
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = true,
	updated_at = now();

-- ---------------------------------------------------------------------------
-- 2) Nuevo modelo: atribuciones + atribucion_autores
-- ---------------------------------------------------------------------------
create table if not exists public.atribuciones (
	atribucion_id uuid default extensions.uuid_generate_v4() not null,
	obra_id uuid null,
	jornada_id uuid null,
	tipo_atribucion_id uuid not null,
	modalidad_atribucion_id uuid not null,
	fuente text not null default '',
	url text null,
	adoptada boolean not null default false,
	notas text null,
	created_at timestamp with time zone default now() not null,
	updated_at timestamp with time zone default now() not null,
	constraint atribuciones_pkey primary key (atribucion_id),
	constraint atribuciones_scope_xor_chk check (
		(coalesce((obra_id is not null)::int, 0) + coalesce((jornada_id is not null)::int, 0)) = 1
	),
	constraint atribuciones_obra_id_fkey foreign key (obra_id) references public.obras (obra_id) on delete cascade,
	constraint atribuciones_jornada_id_fkey foreign key (jornada_id) references public.jornadas (jornada_id) on delete cascade,
	constraint atribuciones_tipo_atribucion_id_fkey foreign key (tipo_atribucion_id) references public.vocabularios (termino_id),
	constraint atribuciones_modalidad_atribucion_id_fkey foreign key (modalidad_atribucion_id) references public.vocabularios (termino_id)
);

create table if not exists public.atribucion_autores (
	atribucion_id uuid not null,
	autor_id uuid not null,
	orden integer null,
	created_at timestamp with time zone default now() not null,
	updated_at timestamp with time zone default now() not null,
	constraint atribucion_autores_pkey primary key (atribucion_id, autor_id),
	constraint atribucion_autores_atribucion_id_fkey foreign key (atribucion_id) references public.atribuciones (atribucion_id) on delete cascade,
	constraint atribucion_autores_autor_id_fkey foreign key (autor_id) references public.autores (autor_id) on delete cascade
);

create index if not exists idx_atribuciones_obra on public.atribuciones (obra_id);
create index if not exists idx_atribuciones_jornada on public.atribuciones (jornada_id);
create index if not exists idx_atribuciones_adoptada on public.atribuciones (adoptada);
create index if not exists idx_atribucion_autores_atribucion on public.atribucion_autores (atribucion_id);
create index if not exists idx_atribucion_autores_autor on public.atribucion_autores (autor_id);

create unique index if not exists uniq_atribucion_adoptada_por_obra
on public.atribuciones (obra_id)
where obra_id is not null and adoptada;

create unique index if not exists uniq_atribucion_adoptada_por_jornada
on public.atribuciones (jornada_id)
where jornada_id is not null and adoptada;

drop function if exists public.validate_atribucion_vocab_refs();
create function public.validate_atribucion_vocab_refs()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
declare
	v_tipo_categoria text;
	v_modalidad_categoria text;
begin
	select categoria into v_tipo_categoria
	from public.vocabularios
	where termino_id = new.tipo_atribucion_id;

	if v_tipo_categoria is distinct from 'tipo_atribucion' then
		raise exception using
			errcode = '23514',
			message = 'tipo_atribucion_id debe apuntar a vocabularios.categoria=tipo_atribucion';
	end if;

	select categoria into v_modalidad_categoria
	from public.vocabularios
	where termino_id = new.modalidad_atribucion_id;

	if v_modalidad_categoria is distinct from 'modalidad_atribucion' then
		raise exception using
			errcode = '23514',
			message = 'modalidad_atribucion_id debe apuntar a vocabularios.categoria=modalidad_atribucion';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_validate_atribucion_vocab_refs on public.atribuciones;
create trigger trigger_validate_atribucion_vocab_refs
before insert or update on public.atribuciones
for each row
execute function public.validate_atribucion_vocab_refs();

drop trigger if exists trigger_atribuciones_updated_at on public.atribuciones;
create trigger trigger_atribuciones_updated_at
before update on public.atribuciones
for each row
execute function public.actualizar_updated_at();

drop trigger if exists trigger_atribucion_autores_updated_at on public.atribucion_autores;
create trigger trigger_atribucion_autores_updated_at
before update on public.atribucion_autores
for each row
execute function public.actualizar_updated_at();

alter table public.atribuciones enable row level security;
alter table public.atribucion_autores enable row level security;

drop policy if exists "atribuciones_select_authenticated" on public.atribuciones;
drop policy if exists "atribuciones_select_assigned_reviewer" on public.atribuciones;
drop policy if exists "atribuciones_insert_authenticated" on public.atribuciones;
drop policy if exists "atribuciones_update_authenticated" on public.atribuciones;
drop policy if exists "atribuciones_delete_authenticated" on public.atribuciones;

create policy "atribuciones_select_authenticated"
on public.atribuciones
for select
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where coalesce(e.activo, true)
			and (
				(atribuciones.obra_id is not null and o.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = o.obra_id
					)
				)
			)
			and (
				lower(vr.termino) = any (array['admin', 'ip', 'revisor'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribuciones_select_assigned_reviewer"
on public.atribuciones
for select
to authenticated
using (
	exists (
		select 1
		from public.obras_revisores r
		where r.revisor_id = auth.uid()
			and (
				(atribuciones.obra_id is not null and r.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = r.obra_id
					)
				)
			)
	)
);

create policy "atribuciones_insert_authenticated"
on public.atribuciones
for insert
to authenticated
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where coalesce(e.activo, true)
			and (
				(atribuciones.obra_id is not null and o.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = o.obra_id
					)
				)
			)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribuciones_update_authenticated"
on public.atribuciones
for update
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where coalesce(e.activo, true)
			and (
				(atribuciones.obra_id is not null and o.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = o.obra_id
					)
				)
			)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where coalesce(e.activo, true)
			and (
				(atribuciones.obra_id is not null and o.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = o.obra_id
					)
				)
			)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribuciones_delete_authenticated"
on public.atribuciones
for delete
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where coalesce(e.activo, true)
			and (
				(atribuciones.obra_id is not null and o.obra_id = atribuciones.obra_id)
				or (
					atribuciones.jornada_id is not null
					and exists (
						select 1
						from public.jornadas j
						where j.jornada_id = atribuciones.jornada_id
							and j.obra_id = o.obra_id
					)
				)
			)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

drop policy if exists "atribucion_autores_select_authenticated" on public.atribucion_autores;
drop policy if exists "atribucion_autores_select_assigned_reviewer" on public.atribucion_autores;
drop policy if exists "atribucion_autores_insert_authenticated" on public.atribucion_autores;
drop policy if exists "atribucion_autores_update_authenticated" on public.atribucion_autores;
drop policy if exists "atribucion_autores_delete_authenticated" on public.atribucion_autores;

create policy "atribucion_autores_select_authenticated"
on public.atribucion_autores
for select
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras o on o.obra_id = coalesce(a.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_autores.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip', 'revisor'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_autores_select_assigned_reviewer"
on public.atribucion_autores
for select
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras_revisores r on r.obra_id = coalesce(a.obra_id, j.obra_id)
		where a.atribucion_id = atribucion_autores.atribucion_id
			and r.revisor_id = auth.uid()
	)
);

create policy "atribucion_autores_insert_authenticated"
on public.atribucion_autores
for insert
to authenticated
with check (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras o on o.obra_id = coalesce(a.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_autores.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_autores_update_authenticated"
on public.atribucion_autores
for update
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras o on o.obra_id = coalesce(a.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_autores.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
)
with check (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras o on o.obra_id = coalesce(a.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_autores.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_autores_delete_authenticated"
on public.atribucion_autores
for delete
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		left join public.jornadas j on j.jornada_id = a.jornada_id
		join public.obras o on o.obra_id = coalesce(a.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_autores.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

-- ---------------------------------------------------------------------------
-- 3) Reemplazo de RPC pública para nueva autoria (sin rangos)
-- ---------------------------------------------------------------------------
create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = 'public'
as $$
declare
	v_publicado_id uuid;
	v_obra public.obras%rowtype;
begin
	select v.termino_id
	into v_publicado_id
	from public.vocabularios v
	where v.categoria = 'estado'
		and lower(v.termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		return null;
	end if;

	select o.*
	into v_obra
	from public.obras o
	where o.obra_id = p_obra_id
		and o.estado = v_publicado_id
		and (p_include_hidden or coalesce(o.visible_publico, false))
	limit 1;

	if not found then
		return null;
	end if;

	return (
		with jornadas_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'jornada_id', j.jornada_id,
						'jornada_num', j.jornada_num,
						'v_ini', j.v_ini,
						'v_fin', j.v_fin
					)
					order by j.jornada_num
				),
				'[]'::jsonb
			) as items
			from public.jornadas j
			where j.obra_id = v_obra.obra_id
		),
		cuadros_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'cuadro_id', c.cuadro_id,
						'jornada_id', c.jornada_id,
						'cuadro_num', c.cuadro_num,
						'v_ini', c.v_ini,
						'v_fin', c.v_fin
					)
					order by j.jornada_num, c.cuadro_num
				),
				'[]'::jsonb
			) as items
			from public.cuadros c
			join public.jornadas j on j.jornada_id = c.jornada_id
			where j.obra_id = v_obra.obra_id
		),
		atribuciones_base as (
			select
				a.atribucion_id,
				a.obra_id as obra_ref_id,
				a.jornada_id,
				j.jornada_num,
				a.tipo_atribucion_id,
				coalesce(vt.termino, 'sin_tipo') as tipo_atribucion_term,
				a.modalidad_atribucion_id,
				coalesce(vm.termino, 'sin_modalidad') as modalidad_atribucion_term,
				a.fuente,
				a.url,
				a.adoptada,
				a.notas,
				a.created_at
			from public.atribuciones a
			left join public.jornadas j on j.jornada_id = a.jornada_id
			left join public.vocabularios vt on vt.termino_id = a.tipo_atribucion_id
			left join public.vocabularios vm on vm.termino_id = a.modalidad_atribucion_id
			where coalesce(a.obra_id, j.obra_id) = v_obra.obra_id
		),
		autoria_autores_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'autor_id', t.autor_id,
						'nombre_completo', t.nombre_completo
					)
					order by t.nombre_completo
				),
				'[]'::jsonb
			) as items
			from (
				select distinct a.autor_id, a.nombre_completo
				from atribuciones_base ab
				join public.atribucion_autores aa on aa.atribucion_id = ab.atribucion_id
				join public.autores a on a.autor_id = aa.autor_id
				where ab.adoptada
			) t
		),
		atribuciones_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'atribucion_id', ab.atribucion_id,
						'scope', case when ab.jornada_id is null then 'obra' else 'jornada' end,
						'obra_id', ab.obra_ref_id,
						'jornada_id', ab.jornada_id,
						'jornada_num', ab.jornada_num,
						'tipo_atribucion_id', ab.tipo_atribucion_id,
						'tipo_atribucion_term', ab.tipo_atribucion_term,
						'modalidad_atribucion_id', ab.modalidad_atribucion_id,
						'modalidad_atribucion_term', ab.modalidad_atribucion_term,
						'fuente', ab.fuente,
						'url', ab.url,
						'adoptada', ab.adoptada,
						'notas', ab.notas,
						'autores', coalesce(aut.items, '[]'::jsonb)
					)
					order by coalesce(ab.jornada_num, 0), ab.atribucion_id
				),
				'[]'::jsonb
			) as items
			from atribuciones_base ab
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'autor_id', a.autor_id,
							'nombre_completo', a.nombre_completo
						)
						order by coalesce(aa.orden, 2147483647), a.nombre_completo
					),
					'[]'::jsonb
				) as items
				from public.atribucion_autores aa
				join public.autores a on a.autor_id = aa.autor_id
				where aa.atribucion_id = ab.atribucion_id
			) aut on true
		),
		informe_autoria as (
			select ab.url
			from atribuciones_base ab
			where ab.adoptada
				and ab.url is not null
				and length(trim(ab.url)) > 0
			order by
				case when ab.jornada_id is null then 0 else 1 end,
				ab.created_at desc
			limit 1
		),
		caracterizaciones_by_secuencia as (
			select
				scr.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'caracterizacion_rango_id', scr.caracterizacion_rango_id,
							'tipo_caracterizacion_rango_id', scr.tipo_caracterizacion_rango_id,
							'tipo_caracterizacion_rango_term', coalesce(tv.termino, 'sin_tipo'),
							'v_ini', scr.v_ini,
							'v_fin', scr.v_fin,
							'observaciones', scr.observaciones
						)
						order by scr.v_ini, scr.v_fin, scr.caracterizacion_rango_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_caracterizaciones_rango scr
			join public.secuencias_metricas sm on sm.secuencia_id = scr.secuencia_id
			left join public.vocabularios tv on tv.termino_id = scr.tipo_caracterizacion_rango_id
			where sm.obra_id = v_obra.obra_id
			group by scr.secuencia_id
		),
		secuencias_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.termino, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(est_parent.termino, est.termino, 'sin_estrofa'),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'personaje_femenino', sm.personaje_femenino,
						'personajes_donaire', sm.personajes_donaire,
						'personajes_sobrenatural', sm.personajes_sobrenatural,
						'sinopsis', sm.sinopsis,
						'jornada_id', jornada_ref.jornada_id,
						'jornada_num', jornada_ref.jornada_num,
						'cuadro_id', cuadro_ref.cuadro_id,
						'cuadro_num', cuadro_ref.cuadro_num,
						'caracterizaciones_rango', coalesce(cseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			left join lateral (
				select j.jornada_id, j.jornada_num
				from public.jornadas j
				where j.obra_id = sm.obra_id
					and sm.v_ini >= j.v_ini
					and sm.v_fin <= j.v_fin
				order by j.jornada_num
				limit 1
			) jornada_ref on true
			left join lateral (
				select c.cuadro_id, c.cuadro_num
				from public.cuadros c
				where c.jornada_id = jornada_ref.jornada_id
					and sm.v_ini >= c.v_ini
					and sm.v_fin <= c.v_fin
				order by c.cuadro_num
				limit 1
			) cuadro_ref on true
			left join caracterizaciones_by_secuencia cseq on cseq.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(est_parent.termino, est.termino, 'sin_estrofa') as forma,
				sum(sm.n_versos)::int as versos
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			where sm.obra_id = v_obra.obra_id
			group by 1
		),
		distribucion_totales as (
			select coalesce(sum(d.versos), 0)::numeric as versos_totales
			from distribucion_base d
		),
		distribucion_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'forma', d.forma,
						'versos', d.versos,
						'porcentaje',
							case
								when t.versos_totales > 0 then round((d.versos::numeric * 100.0) / t.versos_totales, 2)
								else 0
							end
					)
					order by d.versos desc, d.forma
				),
				'[]'::jsonb
			) as items
			from distribucion_base d
			cross join distribucion_totales t
		)
		select jsonb_build_object(
			'obra',
			jsonb_build_object(
				'obra_id', v_obra.obra_id,
				'titulo', v_obra.titulo,
				'variantes_titulo', coalesce(v_obra.variantes_titulo, '{}'::text[]),
				'fecha_inicio_trad', v_obra.fecha_inicio_trad,
				'fecha_fin_trad', v_obra.fecha_fin_trad,
				'fuente_fecha', v_obra.fuente_fecha,
				'genero_term', (
					select vg.termino
					from public.vocabularios vg
					where vg.termino_id = v_obra.genero_id
					limit 1
				),
				'total_versos', v_obra.total_versos,
				'edicion', v_obra.edicion,
				'observaciones', v_obra.observaciones,
				'bibliografia', v_obra.bibliografia,
				'updated_at', v_obra.updated_at,
				'autor_ficha_publico', v_obra.autor_ficha_publico,
				'autor_ficha_email_publico', (
					select e.email
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'autor_ficha_orcid_publico', (
					select e.orcid
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'visible_publico', v_obra.visible_publico
			),
			'autoria',
			jsonb_build_object(
				'autores', (select items from autoria_autores_json),
				'atribuciones', (select items from atribuciones_json),
				'informe_url', (select url from informe_autoria)
			),
			'estructura',
			jsonb_build_object(
				'jornadas', (select items from jornadas_json),
				'cuadros', (select items from cuadros_json)
			),
			'metrica',
			jsonb_build_object(
				'secuencias', (select items from secuencias_json),
				'distribucion_formas', (select items from distribucion_json)
			)
		)
	);
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Comentarios: quitar contexto rango_id
-- ---------------------------------------------------------------------------
alter table public.comentarios_internos
	drop constraint if exists comentarios_internos_rango_id_fkey;

drop index if exists public.idx_comentarios_rango;

alter table public.comentarios_internos
	drop constraint if exists comentarios_internos_un_contexto_chk;

alter table public.comentarios_internos
	drop column if exists rango_id;

alter table public.comentarios_internos
	add constraint comentarios_internos_un_contexto_chk check (
		(
			coalesce((secuencia_id is not null)::int, 0)
			+ coalesce((jornada_id is not null)::int, 0)
			+ coalesce((cuadro_id is not null)::int, 0)
		) <= 1
	);

-- ---------------------------------------------------------------------------
-- 5) Eliminar legado de autoria por rangos
-- ---------------------------------------------------------------------------
drop trigger if exists trigger_actualizar_autoria on public.rangos_autores;
drop trigger if exists trigger_actualizar_autoria_por_cambio_autor on public.autores;
drop function if exists public.actualizar_autoria_obra();
drop function if exists public.actualizar_autoria_obras_por_autor();

drop table if exists public.rangos_autores;
drop table if exists public.rangos;

alter table public.obras
	drop column if exists autoria,
	drop column if exists url_informe_autoria;

comment on table public.jornadas is 'División estructural formal de la obra. Puede tener atribuciones específicas.';
comment on table public.secuencias_metricas is 'Unidad de análisis métrico.';

commit;
