-- La sinopsis recibe el nombre de la forma, no solo el de su arquitectura
--
-- El bloque `sinopsis_metrica` mandaba `estrofa_tipo_term` -la arquitectura- y el slug de la forma,
-- pero no su nombre. La pantalla rotulaba entonces «Octosilabica consonante» donde tenia que decir
-- «Quintilla», y no habia manera de arreglarlo sin volver a la base a por la etiqueta.

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
$function$;
-- Se ejecuta y se recomputan las publicadas, para que lo guardado traiga ya la forma.
do $guarda$
declare
  v_obra uuid;
  v_admin uuid;
  v_sin_forma int;
begin
  select e.user_id into v_admin
  from public.editores e
  join public.vocabularios rol on rol.termino_id = e.role
  where lower(rol.termino) in ('admin', 'ip')
  order by e.created_at limit 1;
  if v_admin is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  end if;

  for v_obra in select r.obra_id from public.obras_resumen r where r.ficha is not null
  loop
    perform public.recompute_obra_resumen_metricas(v_obra);
  end loop;

  select r.obra_id into v_obra from public.obras_resumen r where r.ficha is not null limit 1;
  if v_obra is null then
    raise notice 'Ninguna obra publicada: nada que comprobar.';
    return;
  end if;

  -- **Por donde el dato vive de verdad**: `sinopsis_metrica` es un objeto con una clave
  -- `secuencias` dentro, no un array. Buscarlo mal hacia que la guarda reventara en vez de
  -- comprobar nada, que es la manera mas tonta de no enterarse de un fallo.
  select count(*) into v_sin_forma
  from public.obras_resumen r,
       jsonb_array_elements(r.ficha -> 'sinopsis_metrica' -> 'secuencias') s
  where r.obra_id = v_obra
    and coalesce(s->>'estrofa_forma_term', '') = '';

  if v_sin_forma > 0 then
    raise exception '% entradas de la sinopsis de % siguen sin nombre de forma', v_sin_forma, v_obra;
  end if;
  raise notice 'La sinopsis de % ya trae el nombre de la forma en todas sus entradas.', v_obra;
end;
$guarda$;
