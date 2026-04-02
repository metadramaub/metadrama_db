-- Refactor de variaciones de secuencia a caracterizaciones por rango
-- y traslado de final_acentual desde secuencias_metricas a rangos internos.

-- 1) Vocabulario: tipo_variacion -> caracterizacion_rango
update public.vocabularios
set categoria = 'caracterizacion_rango',
	updated_at = now()
where categoria = 'tipo_variacion';

update public.vocabularios
set
	termino = 'irregularidades_metricas',
	definicion = 'Agrupador de irregularidades metricas puntuales.',
	updated_at = now()
where categoria = 'caracterizacion_rango'
	and termino = 'irregular';

insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	termino_padre_id,
	nivel,
	orden,
	activo,
	definicion,
	created_at,
	updated_at
)
values
	(
		'6eb2af74-f69e-4d69-8f67-2e8d7b1d8db1',
		'caracterizacion_rango',
		'fenomenos_enunciativos',
		null,
		1,
		10,
		true,
		'Fenomenos enunciativos o expresivos declarables por rango dentro de una secuencia.',
		now(),
		now()
	),
	(
		'5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9',
		'caracterizacion_rango',
		'final_acentual',
		null,
		1,
		30,
		true,
		'Marcas por rango para tramos donde predominan finales agudos o esdrujulos.',
		now(),
		now()
	),
	(
		'04649d89-bc9b-46c1-82cf-6c4606e9d901',
		'caracterizacion_rango',
		'mayoria_agudas',
		'5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9',
		2,
		31,
		true,
		'Tramo donde predominan los finales de verso agudos.',
		now(),
		now()
	),
	(
		'74fa5872-c359-4242-ab0b-cffc85c0d557',
		'caracterizacion_rango',
		'mayoria_esdrujulas',
		'5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9',
		2,
		32,
		true,
		'Tramo donde predominan los finales de verso esdrujulos.',
		now(),
		now()
	)
on conflict (categoria, termino)
do update set
	termino_padre_id = excluded.termino_padre_id,
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = excluded.activo,
	definicion = excluded.definicion,
	updated_at = now();

update public.vocabularios as child
set
	termino_padre_id = parent.termino_id,
	nivel = 2,
	updated_at = now()
from public.vocabularios as parent
where child.categoria = 'caracterizacion_rango'
	and parent.categoria = 'caracterizacion_rango'
	and parent.termino = 'fenomenos_enunciativos'
	and child.termino in ('cantado', 'prosa');

update public.vocabularios as child
set
	termino_padre_id = parent.termino_id,
	nivel = 2,
	updated_at = now()
from public.vocabularios as parent
where child.categoria = 'caracterizacion_rango'
	and parent.categoria = 'caracterizacion_rango'
	and parent.termino = 'irregularidades_metricas'
	and child.termino in ('hipometrico', 'hipermetrico', 'rima_defectuosa', 'laguna');

update public.vocabularios
set
	termino_padre_id = null,
	nivel = 1,
	updated_at = now()
where categoria = 'caracterizacion_rango'
	and termino in ('fenomenos_enunciativos', 'irregularidades_metricas', 'final_acentual');

-- 2) Elimina final_acentual como dato de secuencia
alter table public.secuencias_metricas
	drop constraint if exists secuencias_metricas_final_acentual_chk;

alter table public.secuencias_metricas
	drop column if exists final_acentual;

-- 3) Renombra tabla y columnas
alter table public.secuencias_variaciones
	rename to secuencias_caracterizaciones_rango;

alter table public.secuencias_caracterizaciones_rango
	rename column variacion_id to caracterizacion_rango_id;

alter table public.secuencias_caracterizaciones_rango
	rename column tipo_variacion_id to tipo_caracterizacion_rango_id;

alter table public.secuencias_caracterizaciones_rango
	rename constraint secuencias_variaciones_v_ini_le_v_fin_chk to secuencias_caracterizaciones_rango_v_ini_le_v_fin_chk;

alter table public.secuencias_caracterizaciones_rango
	rename constraint secuencias_variaciones_pkey to secuencias_caracterizaciones_rango_pkey;

alter table public.secuencias_caracterizaciones_rango
	rename constraint secuencias_variaciones_secuencia_id_fkey to secuencias_caracterizaciones_rango_secuencia_id_fkey;

alter table public.secuencias_caracterizaciones_rango
	rename constraint secuencias_variaciones_tipo_variacion_id_fkey to secuencias_caracterizaciones_rango_tipo_caracterizacion_rango_id_fkey;

alter index public.idx_variaciones_secuencia
	rename to idx_caracterizaciones_rango_secuencia;

alter index public.idx_variaciones_tipo_id
	rename to idx_caracterizaciones_rango_tipo_id;

alter trigger trigger_secuencias_variaciones_updated_at
	on public.secuencias_caracterizaciones_rango
	rename to trigger_secuencias_caracterizaciones_rango_updated_at;

alter policy secuencias_variaciones_delete_authenticated
	on public.secuencias_caracterizaciones_rango
	rename to secuencias_caracterizaciones_rango_delete_authenticated;

alter policy secuencias_variaciones_insert_authenticated
	on public.secuencias_caracterizaciones_rango
	rename to secuencias_caracterizaciones_rango_insert_authenticated;

alter policy secuencias_variaciones_select_assigned_reviewer
	on public.secuencias_caracterizaciones_rango
	rename to secuencias_caracterizaciones_rango_select_assigned_reviewer;

alter policy secuencias_variaciones_select_authenticated
	on public.secuencias_caracterizaciones_rango
	rename to secuencias_caracterizaciones_rango_select_authenticated;

alter policy secuencias_variaciones_update_authenticated
	on public.secuencias_caracterizaciones_rango
	rename to secuencias_caracterizaciones_rango_update_authenticated;

comment on table public.secuencias_caracterizaciones_rango is
	'Caracterizaciones por rango dentro de una secuencia metrico-editorial.';

-- 4) Ficha publica: expone caracterizaciones_rango con los nombres nuevos
create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
) returns jsonb
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
