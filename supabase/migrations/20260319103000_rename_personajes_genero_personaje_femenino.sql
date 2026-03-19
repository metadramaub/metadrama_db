begin;

alter table public.secuencias_metricas
	rename column personajes_genero to personaje_femenino;

update public.secuencias_metricas
set personaje_femenino = case
	when personaje_femenino = 'mixto' then 'con_otros'
	when personaje_femenino = 'solo_femenino' then 'solo'
	when personaje_femenino = 'solo_masculino' then 'ausente'
	when personaje_femenino in ('ausente', 'solo', 'con_otros') then personaje_femenino
	else 'ausente'
end;

alter table public.secuencias_metricas
	alter column personaje_femenino set default 'ausente';

alter table public.secuencias_metricas
	alter column personaje_femenino set not null;

alter table public.secuencias_metricas
	drop constraint if exists secuencias_metricas_personajes_genero_chk;

alter table public.secuencias_metricas
	drop constraint if exists secuencias_metricas_personaje_femenino_chk;

alter table public.secuencias_metricas
	add constraint secuencias_metricas_personaje_femenino_chk
	check (personaje_femenino in ('ausente', 'solo', 'con_otros'));

comment on column public.secuencias_metricas.personaje_femenino is
	'Presencia de personaje femenino en la secuencia (ausente, solo, con_otros).';

create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
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
				from public.rangos r
				join public.rangos_autores ra on ra.rango_id = r.rango_id
				join public.autores a on a.autor_id = ra.autor_id
				where r.obra_id = v_obra.obra_id
			) t
		),
		rangos_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'rango_id', r.rango_id,
						'v_ini', r.v_ini,
						'v_fin', r.v_fin,
						'autores', coalesce(rautores.items, '[]'::jsonb)
					)
					order by r.v_ini
				),
				'[]'::jsonb
			) as items
			from public.rangos r
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'autor_id', a.autor_id,
							'nombre_completo', a.nombre_completo
						)
						order by a.nombre_completo
					),
					'[]'::jsonb
				) as items
				from public.rangos_autores ra
				join public.autores a on a.autor_id = ra.autor_id
				where ra.rango_id = r.rango_id
			) rautores on true
			where r.obra_id = v_obra.obra_id
		),
		variaciones_by_secuencia as (
			select
				sv.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'variacion_id', sv.variacion_id,
							'tipo_variacion_id', sv.tipo_variacion_id,
							'tipo_variacion_term', coalesce(tv.termino, 'sin_tipo'),
							'v_ini', sv.v_ini,
							'v_fin', sv.v_fin,
							'observaciones', sv.observaciones
						)
						order by sv.v_ini, sv.v_fin, sv.variacion_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_variaciones sv
			join public.secuencias_metricas sm on sm.secuencia_id = sv.secuencia_id
			left join public.vocabularios tv on tv.termino_id = sv.tipo_variacion_id
			where sm.obra_id = v_obra.obra_id
			group by sv.secuencia_id
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
						'variaciones', coalesce(vseq.items, '[]'::jsonb)
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
			left join variaciones_by_secuencia vseq on vseq.secuencia_id = sm.secuencia_id
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
				'url_informe_autoria', v_obra.url_informe_autoria,
				'visible_publico', v_obra.visible_publico
			),
			'autoria',
			jsonb_build_object(
				'autores', (select items from autoria_autores_json),
				'rangos', (select items from rangos_json)
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

commit;
