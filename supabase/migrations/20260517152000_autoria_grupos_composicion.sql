-- Refactor de autorias: grupos OR y composicion interna AND.
-- Mantiene columnas legadas para compatibilidad transitoria.

insert into public.vocabularios (
	termino_id,
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
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f101', 'composicion_autoria', 'individual', null, 1, 10, true, now(), now()),
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f102', 'composicion_autoria', 'colaborada', null, 1, 20, true, now(), now()),
	('9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f104', 'tipo_atribucion', 'propuesta_versologia', null, 1, 30, true, now(), now())
on conflict (termino_id) do update
set categoria = excluded.categoria,
	termino = excluded.termino,
	orden = excluded.orden,
	activo = true,
	updated_at = now();

create table if not exists public.grupos_atribucion (
	grupo_atribucion_id uuid default extensions.uuid_generate_v4() not null,
	obra_id uuid null references public.obras (obra_id) on delete cascade,
	jornada_id uuid null references public.jornadas (jornada_id) on delete cascade,
	nombre text null,
	notas text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	constraint grupos_atribucion_pkey primary key (grupo_atribucion_id),
	constraint grupos_atribucion_scope_xor_chk check (
		(obra_id is not null and jornada_id is null)
		or (obra_id is null and jornada_id is not null)
	)
);

create index if not exists idx_grupos_atribucion_obra on public.grupos_atribucion (obra_id);
create index if not exists idx_grupos_atribucion_jornada on public.grupos_atribucion (jornada_id);

drop trigger if exists trigger_grupos_atribucion_updated_at on public.grupos_atribucion;
create trigger trigger_grupos_atribucion_updated_at
before update on public.grupos_atribucion
for each row execute function public.actualizar_updated_at();

alter table public.atribuciones
	add column if not exists grupo_atribucion_id uuid references public.grupos_atribucion (grupo_atribucion_id) on delete cascade,
	add column if not exists composicion_autoria_id uuid references public.vocabularios (termino_id),
	add column if not exists atribucion_preferente boolean not null default false,
	add column if not exists usable_perfil_metrico boolean not null default false,
	add column if not exists disponible_laboratorio boolean not null default true;

create index if not exists idx_atribuciones_grupo on public.atribuciones (grupo_atribucion_id);
create index if not exists idx_atribuciones_composicion on public.atribuciones (composicion_autoria_id);
create index if not exists idx_atribuciones_preferente on public.atribuciones (atribucion_preferente);
create index if not exists idx_atribuciones_perfil_metrico on public.atribuciones (usable_perfil_metrico);
create index if not exists idx_atribuciones_laboratorio on public.atribuciones (disponible_laboratorio);

drop index if exists public.uniq_atribucion_adoptada_por_obra;
drop index if exists public.uniq_atribucion_adoptada_por_jornada;

create unique index if not exists uniq_atribucion_preferente_por_grupo
on public.atribuciones (grupo_atribucion_id)
where grupo_atribucion_id is not null and atribucion_preferente;

create or replace function public.validate_atribucion_vocab_refs()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
declare
	v_tipo_categoria text;
	v_modalidad_categoria text;
	v_composicion_categoria text;
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

	if new.composicion_autoria_id is not null then
		select categoria into v_composicion_categoria
		from public.vocabularios
		where termino_id = new.composicion_autoria_id;

		if v_composicion_categoria is distinct from 'composicion_autoria' then
			raise exception using
				errcode = '23514',
				message = 'composicion_autoria_id debe apuntar a vocabularios.categoria=composicion_autoria';
		end if;
	end if;

	return new;
end;
$$;

do $$
declare
	v_attr record;
	v_group_id uuid;
	v_modalidad text;
	v_composicion_id uuid;
	v_candidate_names text;
	v_revision_note text;
begin
	for v_attr in
		select a.*, lower(coalesce(vm.termino, '')) as modalidad_term
		from public.atribuciones a
		left join public.vocabularios vm on vm.termino_id = a.modalidad_atribucion_id
		where a.grupo_atribucion_id is null
	loop
		v_revision_note := null;
		v_candidate_names := null;

		insert into public.grupos_atribucion (obra_id, jornada_id, created_at, updated_at)
		values (v_attr.obra_id, v_attr.jornada_id, coalesce(v_attr.created_at, now()), coalesce(v_attr.updated_at, now()))
		returning grupo_atribucion_id into v_group_id;

		v_modalidad := translate(v_attr.modalidad_term, 'áéíóúü', 'aeiouu');
		if v_modalidad = 'colaborativa' then
			select termino_id into v_composicion_id
			from public.vocabularios
			where categoria = 'composicion_autoria' and termino = 'colaborada'
			limit 1;
		elsif v_modalidad in ('desconocida', 'no_atribuida') then
			delete from public.atribuciones
			where atribucion_id = v_attr.atribucion_id;
			continue;
		elsif v_modalidad = 'alternativa' then
			select string_agg(au.nombre_completo, ', ' order by coalesce(aa.orden, 2147483647), au.nombre_completo)
			into v_candidate_names
			from public.atribucion_autores aa
			join public.autores au on au.autor_id = aa.autor_id
			where aa.atribucion_id = v_attr.atribucion_id;

			v_revision_note := 'REVISIÓN MANUAL: esta atribución procedía de modalidad_atribucion=alternativa. Candidatos anteriores: '
				|| coalesce(v_candidate_names, 'sin autores registrados') || '.';

			update public.grupos_atribucion
			set notas = v_revision_note
			where grupo_atribucion_id = v_group_id;

			delete from public.atribuciones
			where atribucion_id = v_attr.atribucion_id;
			continue;
		else
			select termino_id into v_composicion_id
			from public.vocabularios
			where categoria = 'composicion_autoria' and termino = 'individual'
			limit 1;
		end if;

		update public.atribuciones
		set grupo_atribucion_id = v_group_id,
			composicion_autoria_id = v_composicion_id,
			atribucion_preferente = coalesce(v_attr.adoptada, false),
			usable_perfil_metrico = false,
			disponible_laboratorio = true,
			notas = case
				when v_revision_note is null then v_attr.notas
				else concat_ws(E'\n\n', nullif(v_attr.notas, ''), v_revision_note)
			end
		where atribucion_id = v_attr.atribucion_id;

		v_revision_note := null;
		v_candidate_names := null;
	end loop;
end $$;

alter table public.grupos_atribucion enable row level security;

drop policy if exists "grupos_atribucion_select_authenticated" on public.grupos_atribucion;
drop policy if exists "grupos_atribucion_select_assigned_reviewer" on public.grupos_atribucion;
drop policy if exists "grupos_atribucion_insert_authenticated" on public.grupos_atribucion;
drop policy if exists "grupos_atribucion_update_authenticated" on public.grupos_atribucion;
drop policy if exists "grupos_atribucion_delete_authenticated" on public.grupos_atribucion;

create policy "grupos_atribucion_select_authenticated"
on public.grupos_atribucion
for select
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where o.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip', 'revisor'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "grupos_atribucion_select_assigned_reviewer"
on public.grupos_atribucion
for select
to authenticated
using (
	exists (
		select 1
		from public.obras_revisores r
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where r.revisor_id = auth.uid()
			and r.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
	)
);

create policy "grupos_atribucion_insert_authenticated"
on public.grupos_atribucion
for insert
to authenticated
with check (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where o.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "grupos_atribucion_update_authenticated"
on public.grupos_atribucion
for update
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where o.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
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
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where o.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "grupos_atribucion_delete_authenticated"
on public.grupos_atribucion
for delete
to authenticated
using (
	exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		left join public.jornadas j on j.jornada_id = grupos_atribucion.jornada_id
		where o.obra_id = coalesce(grupos_atribucion.obra_id, j.obra_id)
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

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
		grupos_base as (
			select
				g.grupo_atribucion_id,
				g.obra_id as obra_ref_id,
				g.jornada_id,
				j.jornada_num,
				g.nombre,
				g.notas,
				g.created_at
			from public.grupos_atribucion g
			left join public.jornadas j on j.jornada_id = g.jornada_id
			where coalesce(g.obra_id, j.obra_id) = v_obra.obra_id
		),
		propuestas_base as (
			select
				a.atribucion_id,
				a.grupo_atribucion_id,
				a.tipo_atribucion_id,
				coalesce(vt.termino, 'sin_tipo') as tipo_atribucion_term,
				a.composicion_autoria_id,
				coalesce(vc.termino, 'individual') as composicion_autoria_term,
				a.fuente_autoria,
				a.atribucion_preferente,
				a.notas,
				a.created_at
			from public.atribuciones a
			join grupos_base gb on gb.grupo_atribucion_id = a.grupo_atribucion_id
			left join public.vocabularios vt on vt.termino_id = a.tipo_atribucion_id
			left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
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
				select distinct au.autor_id, au.nombre_completo
				from propuestas_base pb
				join public.atribucion_autores aa on aa.atribucion_id = pb.atribucion_id
				join public.autores au on au.autor_id = aa.autor_id
				where pb.atribucion_preferente
			) t
		),
		grupos_autoria_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'grupo_atribucion_id', gb.grupo_atribucion_id,
						'scope', case when gb.jornada_id is null then 'obra' else 'jornada' end,
						'obra_id', gb.obra_ref_id,
						'jornada_id', gb.jornada_id,
						'jornada_num', gb.jornada_num,
						'nombre', gb.nombre,
						'notas', gb.notas,
						'propuestas', coalesce(prop.items, '[]'::jsonb)
					)
					order by case when gb.jornada_id is null then 0 else 1 end, coalesce(gb.jornada_num, 0), gb.created_at
				),
				'[]'::jsonb
			) as items
			from grupos_base gb
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'atribucion_id', pb.atribucion_id,
							'tipo_atribucion_id', pb.tipo_atribucion_id,
							'tipo_atribucion_term', pb.tipo_atribucion_term,
							'composicion_autoria_id', pb.composicion_autoria_id,
							'composicion_autoria_term', pb.composicion_autoria_term,
							'fuente_autoria', pb.fuente_autoria,
							'atribucion_preferente', pb.atribucion_preferente,
							'notas', pb.notas,
							'autores', coalesce(aut.items, '[]'::jsonb)
						)
						order by pb.atribucion_preferente desc, pb.created_at, pb.atribucion_id
					),
					'[]'::jsonb
				) as items
				from propuestas_base pb
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'autor_id', au.autor_id,
								'nombre_completo', au.nombre_completo
							)
							order by coalesce(aa.orden, 2147483647), au.nombre_completo
						),
						'[]'::jsonb
					) as items
					from public.atribucion_autores aa
					join public.autores au on au.autor_id = aa.autor_id
					where aa.atribucion_id = pb.atribucion_id
				) aut on true
				where pb.grupo_atribucion_id = gb.grupo_atribucion_id
			) prop on true
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
				'grupos', (select items from grupos_autoria_json)
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

grant execute on function public.get_obra_ficha_publica(uuid, boolean) to anon;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to authenticated;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to service_role;
