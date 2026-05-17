-- Refactor de autorias: evidencias separadas de propuestas atributivas.
-- Mantiene tipo_atribucion_id y fuente_autoria en atribuciones como espejo legado temporal.

create table if not exists public.atribucion_evidencias (
	atribucion_evidencia_id uuid default extensions.uuid_generate_v4() not null,
	atribucion_id uuid not null references public.atribuciones (atribucion_id) on delete cascade,
	tipo_atribucion_id uuid not null references public.vocabularios (termino_id),
	fuente_autoria text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	constraint atribucion_evidencias_pkey primary key (atribucion_evidencia_id),
	constraint atribucion_evidencias_tipo_unico unique (atribucion_id, tipo_atribucion_id)
);

alter table public.atribucion_evidencias
	drop column if exists orden;

create index if not exists idx_atribucion_evidencias_atribucion
on public.atribucion_evidencias (atribucion_id);

create index if not exists idx_atribucion_evidencias_tipo
on public.atribucion_evidencias (tipo_atribucion_id);

drop trigger if exists trigger_atribucion_evidencias_updated_at on public.atribucion_evidencias;
create trigger trigger_atribucion_evidencias_updated_at
before update on public.atribucion_evidencias
for each row execute function public.actualizar_updated_at();

create or replace function public.validate_atribucion_evidencia_vocab_refs()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
declare
	v_tipo_categoria text;
begin
	select categoria
	into v_tipo_categoria
	from public.vocabularios
	where termino_id = new.tipo_atribucion_id;

	if v_tipo_categoria is distinct from 'tipo_atribucion' then
		raise exception using
			errcode = '23514',
			message = 'tipo_atribucion_id debe apuntar a vocabularios.categoria=tipo_atribucion';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_validate_atribucion_evidencia_vocab_refs on public.atribucion_evidencias;
create trigger trigger_validate_atribucion_evidencia_vocab_refs
before insert or update of tipo_atribucion_id on public.atribucion_evidencias
for each row execute function public.validate_atribucion_evidencia_vocab_refs();

insert into public.atribucion_evidencias (
	atribucion_id,
	tipo_atribucion_id,
	fuente_autoria,
	created_at,
	updated_at
)
select
	a.atribucion_id,
	a.tipo_atribucion_id,
	a.fuente_autoria,
	coalesce(a.created_at, now()),
	coalesce(a.updated_at, now())
from public.atribuciones a
where not exists (
	select 1
	from public.atribucion_evidencias ae
	where ae.atribucion_id = a.atribucion_id
		and ae.tipo_atribucion_id = a.tipo_atribucion_id
);

delete from public.atribuciones a
using public.vocabularios v
where a.composicion_autoria_id = v.termino_id
	and v.categoria = 'composicion_autoria'
	and v.termino = 'desconocida';

delete from public.vocabularios
where categoria = 'composicion_autoria'
	and termino = 'desconocida';

do $$
declare
	r record;
	e record;
	v_existing_id uuid;
	v_existing_text text;
begin
	for r in
		with signatures as (
			select
				a.atribucion_id,
				a.grupo_atribucion_id,
				a.composicion_autoria_id,
				coalesce(
					string_agg(aa.autor_id::text, ',' order by coalesce(aa.orden, 2147483647), aa.autor_id),
					''
				) as autores_key,
				a.atribucion_preferente,
				a.usable_perfil_metrico,
				a.disponible_laboratorio,
				a.created_at
			from public.atribuciones a
			left join public.atribucion_autores aa on aa.atribucion_id = a.atribucion_id
			where a.grupo_atribucion_id is not null
			group by
				a.atribucion_id,
				a.grupo_atribucion_id,
				a.composicion_autoria_id,
				a.atribucion_preferente,
				a.usable_perfil_metrico,
				a.disponible_laboratorio,
				a.created_at
		),
		ranked as (
			select
				s.*,
				first_value(s.atribucion_id) over (
					partition by s.grupo_atribucion_id, s.composicion_autoria_id, s.autores_key
					order by s.atribucion_preferente desc, s.created_at, s.atribucion_id
				) as keep_id,
				count(*) over (
					partition by s.grupo_atribucion_id, s.composicion_autoria_id, s.autores_key
				) as duplicate_count
			from signatures s
		)
		select
			keep_id,
			atribucion_id as duplicate_id
		from ranked
		where duplicate_count > 1
			and atribucion_id <> keep_id
		order by keep_id, duplicate_id
	loop
		for e in
			select *
			from public.atribucion_evidencias
			where atribucion_id = r.duplicate_id
			order by created_at, atribucion_evidencia_id
		loop
			select ae.atribucion_evidencia_id, ae.fuente_autoria
			into v_existing_id, v_existing_text
			from public.atribucion_evidencias ae
			where ae.atribucion_id = r.keep_id
				and ae.tipo_atribucion_id = e.tipo_atribucion_id
			limit 1;

			if v_existing_id is null then
				insert into public.atribucion_evidencias (
					atribucion_id,
					tipo_atribucion_id,
					fuente_autoria,
					created_at,
					updated_at
				)
				values (
					r.keep_id,
					e.tipo_atribucion_id,
					e.fuente_autoria,
					e.created_at,
					now()
				);
			elsif nullif(trim(coalesce(e.fuente_autoria, '')), '') is not null
				and position(trim(e.fuente_autoria) in coalesce(v_existing_text, '')) = 0 then
				update public.atribucion_evidencias
				set fuente_autoria = concat_ws(E'\n\n', nullif(trim(coalesce(v_existing_text, '')), ''), trim(e.fuente_autoria)),
					updated_at = now()
				where atribucion_evidencia_id = v_existing_id;
			end if;
		end loop;

		update public.atribuciones keep_attr
		set
			usable_perfil_metrico = keep_attr.usable_perfil_metrico or duplicate_attr.usable_perfil_metrico,
			disponible_laboratorio = keep_attr.disponible_laboratorio or duplicate_attr.disponible_laboratorio,
			updated_at = now()
		from public.atribuciones duplicate_attr
		where keep_attr.atribucion_id = r.keep_id
			and duplicate_attr.atribucion_id = r.duplicate_id;

		if exists (
			select 1
			from public.atribuciones
			where atribucion_id = r.duplicate_id
				and atribucion_preferente
		) then
			update public.atribuciones
			set atribucion_preferente = false,
				adoptada = false,
				updated_at = now()
			where atribucion_id = r.duplicate_id;

			update public.atribuciones
			set atribucion_preferente = true,
				adoptada = true,
				updated_at = now()
			where atribucion_id = r.keep_id;
		end if;

		delete from public.atribuciones
		where atribucion_id = r.duplicate_id;
	end loop;
end;
$$;

with first_evidence as (
	select distinct on (ae.atribucion_id)
		ae.atribucion_id,
		ae.tipo_atribucion_id,
		ae.fuente_autoria
	from public.atribucion_evidencias ae
	left join public.vocabularios vt on vt.termino_id = ae.tipo_atribucion_id
	order by ae.atribucion_id, coalesce(vt.termino, ''), ae.created_at, ae.atribucion_evidencia_id
)
update public.atribuciones a
set tipo_atribucion_id = fe.tipo_atribucion_id,
	fuente_autoria = fe.fuente_autoria,
	updated_at = now()
from first_evidence fe
where fe.atribucion_id = a.atribucion_id;

alter table public.atribucion_evidencias enable row level security;

drop policy if exists "atribucion_evidencias_select_authenticated" on public.atribucion_evidencias;
drop policy if exists "atribucion_evidencias_select_assigned_reviewer" on public.atribucion_evidencias;
drop policy if exists "atribucion_evidencias_insert_authenticated" on public.atribucion_evidencias;
drop policy if exists "atribucion_evidencias_update_authenticated" on public.atribucion_evidencias;
drop policy if exists "atribucion_evidencias_delete_authenticated" on public.atribucion_evidencias;

create policy "atribucion_evidencias_select_authenticated"
on public.atribucion_evidencias
for select
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		join public.obras o on o.obra_id = coalesce(g.obra_id, (select j.obra_id from public.jornadas j where j.jornada_id = g.jornada_id))
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_evidencias.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip', 'revisor'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_evidencias_select_assigned_reviewer"
on public.atribucion_evidencias
for select
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		join public.obras_revisores r on r.obra_id = coalesce(g.obra_id, j.obra_id)
		where a.atribucion_id = atribucion_evidencias.atribucion_id
			and r.revisor_id = auth.uid()
	)
);

create policy "atribucion_evidencias_insert_authenticated"
on public.atribucion_evidencias
for insert
to authenticated
with check (
	exists (
		select 1
		from public.atribuciones a
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		join public.obras o on o.obra_id = coalesce(g.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_evidencias.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_evidencias_update_authenticated"
on public.atribucion_evidencias
for update
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		join public.obras o on o.obra_id = coalesce(g.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_evidencias.atribucion_id
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
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		join public.obras o on o.obra_id = coalesce(g.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_evidencias.atribucion_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) = any (array['admin', 'ip'])
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	)
);

create policy "atribucion_evidencias_delete_authenticated"
on public.atribucion_evidencias
for delete
to authenticated
using (
	exists (
		select 1
		from public.atribuciones a
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		join public.obras o on o.obra_id = coalesce(g.obra_id, j.obra_id)
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where a.atribucion_id = atribucion_evidencias.atribucion_id
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
				a.composicion_autoria_id,
				coalesce(vc.termino, 'individual') as composicion_autoria_term,
				a.atribucion_preferente,
				a.created_at
			from public.atribuciones a
			join grupos_base gb on gb.grupo_atribucion_id = a.grupo_atribucion_id
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
							'composicion_autoria_id', pb.composicion_autoria_id,
							'composicion_autoria_term', pb.composicion_autoria_term,
							'atribucion_preferente', pb.atribucion_preferente,
							'autores', coalesce(aut.items, '[]'::jsonb),
							'evidencias', coalesce(evi.items, '[]'::jsonb)
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
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'atribucion_evidencia_id', ae.atribucion_evidencia_id,
								'tipo_atribucion_id', ae.tipo_atribucion_id,
								'tipo_atribucion_term', coalesce(vt.termino, 'sin_tipo'),
								'fuente_autoria', ae.fuente_autoria
							)
							order by coalesce(vt.termino, ''), ae.created_at, ae.atribucion_evidencia_id
						),
						'[]'::jsonb
					) as items
					from public.atribucion_evidencias ae
					left join public.vocabularios vt on vt.termino_id = ae.tipo_atribucion_id
					where ae.atribucion_id = pb.atribucion_id
				) evi on true
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
		),
		comentarios_publicos_json as (
			select public.get_obra_comentarios_publicos(v_obra.obra_id, p_include_hidden) as items
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
			),
			'comentarios_publicos',
			coalesce((select items from comentarios_publicos_json), '[]'::jsonb)
		)
	);
end;
$$;

grant execute on function public.get_obra_ficha_publica(uuid, boolean) to anon;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to authenticated;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to service_role;

alter table public.atribuciones
	drop column if exists notas;
