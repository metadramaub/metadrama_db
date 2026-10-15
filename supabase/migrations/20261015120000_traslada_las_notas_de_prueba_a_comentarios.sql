-- Conserva las observaciones originales; registra el traslado sin duplicarlas en la ficha.
begin;

create table if not exists public.traslados_observaciones_caracterizacion (
  caracterizacion_rango_id uuid primary key,
  comentario_id uuid not null unique,
  obra_id uuid not null references public.obras(obra_id) on delete cascade,
  origen jsonb not null,
  trasladado_por uuid not null references public.editores(user_id),
  trasladado_en timestamptz not null default now()
);
comment on table public.traslados_observaciones_caracterizacion is
  'Rastro privado del traslado de notas históricas. Sin FK a la caracterización ni al comentario: conserva el origen si se retira la fila legada o se elimina el comentario. No reaparece la nota antigua al borrar el comentario.';
alter table public.traslados_observaciones_caracterizacion enable row level security;
revoke all on public.traslados_observaciones_caracterizacion from public, anon, authenticated;
grant all on public.traslados_observaciones_caracterizacion to service_role;

create or replace function public.trasladar_observaciones_a_comentarios(
  p_caracterizaciones uuid[], p_responsable uuid
) returns integer language plpgsql set search_path = public as $$
declare
  v_id uuid;
  v_nota record;
  v_anterior public.traslados_observaciones_caracterizacion%rowtype;
  v_comentario uuid;
  v_tipo_comentario uuid;
  v_total integer := 0;
  v_texto text;
begin
  if not exists (
    select 1 from public.editores e join public.vocabularios v on v.termino_id = e.role
    where e.user_id = p_responsable and v.termino in ('admin','ip')
  ) then raise exception 'El traslado necesita un responsable admin o IP'; end if;

  select termino_id into strict v_tipo_comentario from public.vocabularios
  where categoria = 'tipo_comentario' and termino = 'observacion_publica';

  for v_id in select distinct unnest(p_caracterizaciones) order by 1 loop
    select r.*, o.obra_id, o.editor_asignado, v.termino as tipo into v_nota
    from public.secuencias_caracterizaciones_rango r
    join public.secuencias_metricas s using (secuencia_id)
    join public.obras o using (obra_id)
    join public.vocabularios v on v.termino_id = r.tipo_caracterizacion_rango_id
    where r.caracterizacion_rango_id = v_id for update of r;
    if not found then raise exception 'No existe la caracterización %', v_id; end if;
    if nullif(btrim(v_nota.observaciones), '') is null then
      raise exception 'La caracterización % no tiene nota que trasladar', v_id;
    end if;
    if v_nota.tipo not in ('cantado','prosa','evocacion_metrica') then
      raise exception 'El destino de % requiere revisión individual; no es una nota enunciativa', v_id;
    end if;
    if v_nota.editor_asignado is null then raise exception 'Falta autor para %', v_id; end if;

    select * into v_anterior from public.traslados_observaciones_caracterizacion
    where caracterizacion_rango_id = v_id;
    if found then
      if v_anterior.origen ->> 'observaciones' is distinct from v_nota.observaciones
        or (v_anterior.origen ->> 'secuencia_id')::uuid is distinct from v_nota.secuencia_id
        or (v_anterior.origen ->> 'v_ini')::integer is distinct from v_nota.v_ini
        or (v_anterior.origen ->> 'v_fin')::integer is distinct from v_nota.v_fin
        or (v_anterior.origen ->> 'tipo_caracterizacion_rango_id')::uuid is distinct from v_nota.tipo_caracterizacion_rango_id
      then raise exception 'Ha cambiado el origen ya trasladado de %; revisar antes de repetir', v_id; end if;
      continue; -- No sobrescribir comentarios que el editor haya corregido o eliminado.
    end if;

    v_texto := case when v_nota.v_ini = v_nota.v_fin
      then format('**V. %s.**', v_nota.v_ini)
      else format('**Vv. %s–%s.**', v_nota.v_ini, v_nota.v_fin) end
      || E'\n\n' || v_nota.observaciones;

    insert into public.comentarios_internos (
      obra_id, secuencia_id, user_id, comentario, tipo_comentario_id,
      visible_publico, publicado_por, publicado_at, created_at
    ) values (
      v_nota.obra_id, v_nota.secuencia_id, v_nota.editor_asignado, v_texto, v_tipo_comentario,
      true, p_responsable, now(), v_nota.created_at
    ) returning comentario_id into v_comentario;

    insert into public.traslados_observaciones_caracterizacion (
      caracterizacion_rango_id, comentario_id, obra_id, origen, trasladado_por
    ) values (v_id, v_comentario, v_nota.obra_id, to_jsonb(v_nota), p_responsable);
    v_total := v_total + 1;
  end loop;
  return v_total;
end;
$$;
revoke all on function public.trasladar_observaciones_a_comentarios(uuid[],uuid) from public, anon, authenticated;
grant execute on function public.trasladar_observaciones_a_comentarios(uuid[],uuid) to service_role;

CREATE OR REPLACE FUNCTION public.ficha_publica_base_json(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_obra public.obras%rowtype;
begin
	select o.*
	into v_obra
	from public.obras o
	where o.obra_id = p_obra_id
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
				coalesce(vc.etiqueta, vc.termino, 'individual') as composicion_autoria_term,
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
				from grupos_base gb
				join propuestas_base pb on pb.grupo_atribucion_id = gb.grupo_atribucion_id
				join public.atribucion_autores aa on aa.atribucion_id = pb.atribucion_id
				join public.autores au on au.autor_id = aa.autor_id
				where gb.jornada_id is null
					and (
						select count(*)
						from propuestas_base pb_count
						where pb_count.grupo_atribucion_id = gb.grupo_atribucion_id
					) = 1
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
							'autores', coalesce(aut.items, '[]'::jsonb),
							'evidencias', coalesce(evi.items, '[]'::jsonb)
						)
						order by pb.created_at, pb.atribucion_id
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
								'tipo_atribucion_term', coalesce(vt.etiqueta, vt.termino, 'sin_tipo'),
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
							'tipo_caracterizacion_rango_term', coalesce(tv.etiqueta, tv.termino, 'sin_tipo'),
							'v_ini', scr.v_ini,
							'v_fin', scr.v_fin,
							'observaciones', case when exists (
                                select 1 from public.traslados_observaciones_caracterizacion t
                                where t.caracterizacion_rango_id = scr.caracterizacion_rango_id
                              ) then null else scr.observaciones end
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
		subtipos_by_secuencia as (
			-- **Los esquemas de una tirada se cuentan, no se enumeran.** El esquema de rima se responde
			-- una vez por estrofa, asi que una tirada de setenta y ocho redondillas traia setenta y ocho
			-- entradas y el codigo de barras se llenaba de rayas. Lo que dice algo es cuantas estrofas
			-- llevan cada disposicion: abba 64, abab 14. La clave conserva su nombre viejo porque es la
			-- que la ficha ya sabe pintar.
			select
				secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'subtipo_estrofa_id', esquema_rima_id,
							'subtipo_estrofa_term', nombre,
							'notacion', notacion,
							'unidades', unidades
						)
						order by unidades desc, nombre
					),
					'[]'::jsonb
				) as items
			from (
				select
					sm.secuencia_id,
					er.esquema_rima_id,
					coalesce(er.nombre, er.notacion, 'sin_subtipo') as nombre,
					er.notacion,
					count(*)::int as unidades
				from public.secuencias_metricas sm
				join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
				join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
				join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
				where sm.obra_id = v_obra.obra_id
				group by sm.secuencia_id, er.esquema_rima_id, er.nombre, er.notacion
			) contados
			group by secuencia_id
		),
		rasgos_by_secuencia as (
			-- **Lo que se observo y no es la forma.** La asonancia de un romance, la densidad de rima de
			-- una silva, el distico final de una tirada de sueltos: respuestas de la anotacion que hasta
			-- hoy no salian de la base. Solo de asonancias hay cincuenta y siete que nadie veia.
			select
				sm.secuencia_id,
				coalesce(
					jsonb_agg(
						distinct jsonb_build_object(
							'rasgo_slug', rm.slug,
							'rasgo_term', rm.nombre,
							'valor_slug', rv.slug,
							'valor_term', rv.nombre
						)
					),
					'[]'::jsonb
				) as items
			from public.secuencias_metricas sm
			join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
			join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
			join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
			join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
			where sm.obra_id = v_obra.obra_id
			group by sm.secuencia_id
		),
		metros_by_secuencia as (
			-- La medida de los versos tal como se respondio, con cuantas estrofas la llevan.
			select
				secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object('metro_slug', slug, 'metro_term', nombre, 'unidades', unidades)
						order by unidades desc, nombre
					),
					'[]'::jsonb
				) as items
			from (
				select sm.secuencia_id, m.slug, m.nombre, count(*)::int as unidades
				from public.secuencias_metricas sm
				join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
				join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
				join public.metros m on m.metro_id = e.metro_id
				where sm.obra_id = v_obra.obra_id
				group by sm.secuencia_id, m.slug, m.nombre
			) contados
			group by secuencia_id
		),
		desviaciones_by_secuencia as (
			-- **Lo que se aparta de la norma**: la laguna, el verso corto, la rima que no esta en el
			-- repertorio. Es de lo poco que el editor anota sobre lo que ve y no sobre lo que la forma
			-- prescribe, y tampoco llegaba a la ficha.
			select
				sm.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'dimension', d.dimension,
							'relacion_norma', d.relacion_norma,
							'v_ini', d.v_ini,
							'v_fin', d.v_fin,
							'observaciones', d.observaciones
						)
						order by d.v_ini
					),
					'[]'::jsonb
				) as items
			from public.secuencias_metricas sm
			join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
			join public.anotacion_desviaciones d on d.anotacion_id = a.anotacion_id
			where sm.obra_id = v_obra.obra_id
			group by sm.secuencia_id
		),
		secuencias_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', fo.arquitectura_id,
						'estrofa_tipo_term', coalesce(fo.arquitectura_nombre, fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_slug', fo.forma_slug,
						'estrofa_tipo_forma', fo.tipo_forma,
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'intervencion_personajes_femeninos', sm.intervencion_personajes_femeninos,
						'generos_intervinientes', sm.generos_intervinientes,
						'intervencion_figuras_donaire', sm.intervencion_figuras_donaire,
						'intervencion_personajes_sobrenaturales', sm.intervencion_personajes_sobrenaturales,
						'evento_sobrenatural', sm.evento_sobrenatural,
						'sinopsis', sm.sinopsis,
						'jornada_id', jornada_ref.jornada_id,
						'jornada_num', jornada_ref.jornada_num,
						'cuadro_id', cuadro_ref.cuadro_id,
						'cuadro_num', cuadro_ref.cuadro_num,
						'cuadro_continua', cuadro_ref.v_fin is not null and sm.v_fin > cuadro_ref.v_fin,
						'caracterizaciones_rango', coalesce(cseq.items, '[]'::jsonb),
						'subtipos_estrofa', coalesce(sseq.items, '[]'::jsonb),
						'rasgos', coalesce(rseq.items, '[]'::jsonb),
						'metros', coalesce(mseq.items, '[]'::jsonb),
						'desviaciones', coalesce(dseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.formas_de_la_obra(v_obra.obra_id) fo on fo.secuencia_id = sm.secuencia_id
			-- **Una secuencia pertenece al cuadro donde empieza.** Antes se exigia que cupiera entera,
			-- y como el tablado se vacia muchas veces en mitad de una tirada -pasa en el 31 % de los
			-- cambios de cuadro de Fuente Ovejuna y de Peribanez-, esas secuencias se quedaban sin
			-- cuadro: nulos donde habia un dato. Que la tirada siga sonando despues del corte no es un
			-- problema que resolver, es lo que hay que poder medir, y para eso va `cuadro_continua`.
			left join lateral (
				select j.jornada_id, j.jornada_num
				from public.jornadas j
				where j.obra_id = sm.obra_id
					and sm.v_ini between j.v_ini and j.v_fin
				order by j.jornada_num
				limit 1
			) jornada_ref on true
			left join lateral (
				select c.cuadro_id, c.cuadro_num, c.v_fin
				from public.cuadros c
				where c.jornada_id = jornada_ref.jornada_id
					and sm.v_ini between c.v_ini and c.v_fin
				order by c.cuadro_num
				limit 1
			) cuadro_ref on true
			left join caracterizaciones_by_secuencia cseq on cseq.secuencia_id = sm.secuencia_id
			left join subtipos_by_secuencia sseq on sseq.secuencia_id = sm.secuencia_id
			left join rasgos_by_secuencia rseq on rseq.secuencia_id = sm.secuencia_id
			left join metros_by_secuencia mseq on mseq.secuencia_id = sm.secuencia_id
			left join desviaciones_by_secuencia dseq on dseq.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		sinopsis_metrica_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', fo.arquitectura_id,
						'estrofa_tipo_term', coalesce(fo.arquitectura_nombre, fo.forma_nombre, 'sin_estrofa'),
						-- **La forma nombra el pasaje; la arquitectura es el detalle.** La sinopsis rotulaba
						-- «Octosilabica consonante» donde tenia que decir «Quintilla», y no podia arreglarse
						-- en la pantalla porque este bloque no mandaba el nombre de la forma.
						'estrofa_forma_term', coalesce(fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_slug', fo.forma_slug,
						'estrofa_tipo_forma', fo.tipo_forma,
						'sinopsis', sm.sinopsis
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.formas_de_la_obra(v_obra.obra_id) fo on fo.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(fo.forma_nombre, 'sin_estrofa') as forma,
				fo.forma_slug,
				fo.tipo_forma as forma_tipo_forma,
				sum(fo.n_versos)::int as versos
			from public.formas_de_la_obra(v_obra.obra_id) fo
			group by 1, 2, 3
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
						'forma_slug', d.forma_slug,
						'forma_tipo_forma', d.forma_tipo_forma,
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
					select coalesce(vg.etiqueta, vg.termino)
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
			'sinopsis_metrica',
			jsonb_build_object(
				'secuencias', (select items from sinopsis_metrica_json)
			),
			'comentarios_publicos',
			coalesce((select items from comentarios_publicos_json), '[]'::jsonb)
		)
	);
end;
$function$
;

create temporary table notas_prueba_esperadas on commit drop as
select * from jsonb_to_recordset('[{"caracterizacion_rango_id":"065646f3-07d4-4513-a53c-34193b10ae8d","created_at":"2026-09-18 08:06:36.890338+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"27ed752c-32fc-41ef-afb5-3c782dcd1886","observaciones":"Romance cantado por músicos dentro.","secuencia_id":"5a81be92-7a0b-43a9-bf72-97651562b8e5","slug":"el-marques-desdichado-prueba","tipo":"cantado","tipo_caracterizacion_rango_id":"e61fa399-7b03-4934-b960-db97903e6211","titulo":"El marqués desdichado (prueba)","updated_at":"2026-09-18 08:06:36.890338+00","v_fin":1398,"v_ini":1383},{"caracterizacion_rango_id":"36603ccf-f13a-40fb-9181-8385f8229523","created_at":"2026-09-18 08:05:07.32003+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"adf0a85e-7daf-4ca2-802a-fa57b49c4e08","observaciones":"Pasaje cantado.","secuencia_id":"12ed404d-fc49-4467-9448-165c097067fb","slug":"la-monja-de-avila-prueba","tipo":"cantado","tipo_caracterizacion_rango_id":"e61fa399-7b03-4934-b960-db97903e6211","titulo":"La monja de Ávila (prueba)","updated_at":"2026-09-18 08:05:07.32003+00","v_fin":2666,"v_ini":2665},{"caracterizacion_rango_id":"7bfff83c-1d18-46ca-bfc5-0e940d934865","created_at":"2026-09-18 08:05:24.104857+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"adf0a85e-7daf-4ca2-802a-fa57b49c4e08","observaciones":"Pasaje cantado.","secuencia_id":"4cf48f14-e3e3-419f-a105-0b70b239a3e0","slug":"la-monja-de-avila-prueba","tipo":"cantado","tipo_caracterizacion_rango_id":"e61fa399-7b03-4934-b960-db97903e6211","titulo":"La monja de Ávila (prueba)","updated_at":"2026-09-18 08:05:24.104857+00","v_fin":2682,"v_ini":2667},{"caracterizacion_rango_id":"ece5224f-89d2-442c-b696-b2af3452be05","created_at":"2026-09-18 07:55:16.696423+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"f810c864-6ed0-4f34-8c6b-264801bbd1ec","observaciones":"Pasaje cantado.","secuencia_id":"c2c49f60-9a09-4d5b-90e3-428bda731692","slug":"las-batuecas-del-duque-prueba","tipo":"cantado","tipo_caracterizacion_rango_id":"e61fa399-7b03-4934-b960-db97903e6211","titulo":"Las batuecas del duque (prueba)","updated_at":"2026-09-18 07:55:16.696423+00","v_fin":1875,"v_ini":1854},{"caracterizacion_rango_id":"51abe19e-9914-4621-89bf-075e9b7e0ad9","created_at":"2026-09-18 07:56:09.136791+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"119f23d5-658e-485e-92a6-92aef6ddf4b5","observaciones":"El villancico lo cantan los músicos.","secuencia_id":"0511c5f5-547b-491a-8633-adad5fbd19da","slug":"lo-fingido-y-lo-cierto-prueba","tipo":"cantado","tipo_caracterizacion_rango_id":"e61fa399-7b03-4934-b960-db97903e6211","titulo":"Lo fingido y lo cierto (prueba)","updated_at":"2026-09-18 07:56:09.136791+00","v_fin":1504,"v_ini":1471},{"caracterizacion_rango_id":"4503f1a2-11d7-458e-8767-8f787a7ba984","created_at":"2026-09-18 07:56:09.136791+00","editor_asignado":"fc61b25d-f171-4848-93d8-ea923501f7a7","obra_id":"119f23d5-658e-485e-92a6-92aef6ddf4b5","observaciones":"Pasaje en prosa dentro de la escena.","secuencia_id":"797a7b6d-2798-487a-bfa6-16b300a3b61c","slug":"lo-fingido-y-lo-cierto-prueba","tipo":"prosa","tipo_caracterizacion_rango_id":"a2086ad5-59fc-438e-aaf3-784efa95a0be","titulo":"Lo fingido y lo cierto (prueba)","updated_at":"2026-09-18 07:56:09.136791+00","v_fin":1596,"v_ini":1591}]'::jsonb)
  as n(caracterizacion_rango_id uuid, secuencia_id uuid, v_ini integer, v_fin integer,
       observaciones text, obra_id uuid, editor_asignado uuid);
create temporary table notas_antes on commit drop as
select caracterizacion_rango_id, to_jsonb(r) as fila from public.secuencias_caracterizaciones_rango r;

do $guardas$
declare
  v_ids uuid[];
  v_obra uuid;
  v_ficha jsonb;
  v_publica jsonb;
  v_actor uuid := 'fc61b25d-f171-4848-93d8-ea923501f7a7';
  v_creados integer;
begin
  if exists (select 1 from notas_prueba_esperadas e
    left join public.secuencias_caracterizaciones_rango r using (caracterizacion_rango_id)
    where r.caracterizacion_rango_id is null or r.observaciones is distinct from e.observaciones
      or r.secuencia_id is distinct from e.secuencia_id or r.v_ini <> e.v_ini or r.v_fin <> e.v_fin)
  then raise exception 'Ha cambiado alguna de las notas revisadas de prueba'; end if;

  select array_agg(caracterizacion_rango_id) into v_ids from notas_prueba_esperadas;
  v_creados := public.trasladar_observaciones_a_comentarios(v_ids, v_actor);
  if v_creados not in (0,6) then raise exception 'El traslado de pruebas es parcial'; end if;
  if public.trasladar_observaciones_a_comentarios(v_ids, v_actor) <> 0 then
    raise exception 'Repetir el traslado duplica los comentarios'; end if;

  if exists (select 1 from notas_prueba_esperadas e
    left join public.traslados_observaciones_caracterizacion t using (caracterizacion_rango_id)
    left join public.comentarios_internos c on c.comentario_id = t.comentario_id
    left join public.vocabularios v on v.termino_id = c.tipo_comentario_id
    where c.comentario_id is null or not c.visible_publico or c.user_id <> e.editor_asignado
      or c.secuencia_id <> e.secuencia_id or c.obra_id <> e.obra_id
      or v.termino is distinct from 'observacion_publica'
      or position(e.observaciones in c.comentario) = 0
      or c.comentario not like '**Vv. ' || e.v_ini || '–' || e.v_fin || '.**%')
  then raise exception 'Falla texto, autoría, contexto o visibilidad del comentario'; end if;
  if (select count(*) from public.traslados_observaciones_caracterizacion
      where caracterizacion_rango_id = any(v_ids)) <> 6 then raise exception 'Faltan traslados'; end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_actor)::text, true);
  for v_obra in select distinct obra_id from notas_prueba_esperadas loop
    v_ficha := public.ficha_publica_base_json(v_obra, true);
    if exists (select 1 from jsonb_array_elements(v_ficha #> '{metrica,secuencias}') s,
      jsonb_array_elements(s -> 'caracterizaciones_rango') r
      where (r ->> 'caracterizacion_rango_id')::uuid = any(v_ids)
        and r ->> 'observaciones' is not null)
    then raise exception 'La ficha repite la nota junto a la caracterización'; end if;
    if public.can_view_obra_ficha_publica(v_obra, true) then
      v_publica := public.get_obra_comentarios_publicos(v_obra, true);
      if exists (select 1 from public.traslados_observaciones_caracterizacion t
        where t.obra_id = v_obra and t.caracterizacion_rango_id = any(v_ids)
          and not exists (select 1 from jsonb_array_elements(v_publica) c
            where c ->> 'comentario_id' = t.comentario_id::text))
      then raise exception 'El lector público no devuelve el comentario'; end if;
    end if;
  end loop;

  if exists (select 1 from notas_antes a full join public.secuencias_caracterizaciones_rango r using(caracterizacion_rango_id)
    where a.fila is distinct from to_jsonb(r)) then raise exception 'Se ha modificado una caracterización original'; end if;
end;
$guardas$;
select public.recompute_all();
commit;
