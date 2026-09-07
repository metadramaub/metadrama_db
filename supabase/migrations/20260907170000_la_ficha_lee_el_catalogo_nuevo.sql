-- La ficha lee el catálogo nuevo
--
-- La precomputación ya lo leía, pero **la ficha no se sirve de ella**: se arma en vivo, contra la
-- base, cada vez que alguien la abre. Eso es lo que permite mirar una obra en vista previa antes de
-- publicarla —cuando todavía no hay nada precomputado—, y es una propiedad que conviene conservar.
--
-- Lo que pasaba es que ese cálculo en vivo seguía entrando por el vocabulario legado, en tres
-- sitios: las secuencias, la sinopsis métrica y la distribución de formas. Con una obra anotada con
-- el catálogo nuevo, la ficha enseñaba **«sin_estrofa» en todas las secuencias** y una distribución
-- vacía.
--
-- Ahora los tres leen `formas_de_la_obra()`, el mismo sitio del que lee la precomputación, y la
-- correspondencia es la que ya había: donde estaba el término hijo va la **arquitectura** —la
-- realización concreta— y donde estaba el padre va la **forma**.
--
-- `formas_de_la_obra()` se rehace para devolver también los nombres y el identificador de la
-- arquitectura, que es lo que la ficha enseña. La precomputación no se entera: sigue leyendo las
-- mismas columnas que leía.

begin;

drop function if exists public.formas_de_la_obra(uuid);

create function public.formas_de_la_obra(p_obra_id uuid)
returns table (
	secuencia_id uuid,
	v_ini integer,
	v_fin integer,
	n_versos integer,
	forma_slug text,
	forma_nombre text,
	arquitectura_id uuid,
	arquitectura_slug text,
	arquitectura_nombre text,
	tipo_forma text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
	-- **Una secuencia, una anotación.** La tabla admite varias por orden, y si alguna vez las
	-- hubiera, el perfil tiene que contar la secuencia una sola vez: manda la primera.
	select distinct on (sm.secuencia_id)
		sm.secuencia_id,
		sm.v_ini,
		sm.v_fin,
		sm.n_versos,
		f.slug as forma_slug,
		f.nombre as forma_nombre,
		arq.arquitectura_id,
		arq.slug as arquitectura_slug,
		arq.nombre as arquitectura_nombre,
		case t.nombre
			when 'Española' then 'forma_espanola'
			when 'Italiana' then 'forma_italiana'
		end as tipo_forma
	from public.secuencias_metricas sm
	left join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
	left join public.formas_metricas f on f.forma_id = a.forma_id
	left join public.arquitecturas_forma arq on arq.arquitectura_id = a.arquitectura_id
	left join public.formas_tradiciones ft on ft.forma_id = f.forma_id
	left join public.tradiciones_metricas t on t.tradicion_id = ft.tradicion_id
	where sm.obra_id = p_obra_id
	order by sm.secuencia_id, a.orden nulls last;
$function$;

comment on function public.formas_de_la_obra(uuid) is
	'Qué forma, arquitectura y tradición realiza cada secuencia de una obra, según el catálogo nuevo. Único sitio donde vive ese emparejamiento: de aquí leen la precomputación y la ficha pública.';

CREATE OR REPLACE FUNCTION public.get_obra_ficha_publica_base_without_slugs(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
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
		and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
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
			select
				sse.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'subtipo_secuencia_id', sse.subtipo_secuencia_id,
							'subtipo_estrofa_id', sse.subtipo_estrofa_id,
							'subtipo_estrofa_term', coalesce(sv.etiqueta, sv.termino, 'sin_subtipo'),
							'v_ini', sse.v_ini,
							'v_fin', sse.v_fin
						)
						order by sse.v_ini, sse.v_fin, sse.subtipo_secuencia_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_subtipos_estrofa sse
			join public.secuencias_metricas sm on sm.secuencia_id = sse.secuencia_id
			left join public.vocabularios sv on sv.termino_id = sse.subtipo_estrofa_id
			where sm.obra_id = v_obra.obra_id
			group by sse.secuencia_id
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
						'caracterizaciones_rango', coalesce(cseq.items, '[]'::jsonb),
						'subtipos_estrofa', coalesce(sseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.formas_de_la_obra(v_obra.obra_id) fo on fo.secuencia_id = sm.secuencia_id
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
			left join subtipos_by_secuencia sseq on sseq.secuencia_id = sm.secuencia_id
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
$function$;;

-- ---------------------------------------------------------------------------
-- La guarda ejecuta lo que toca
--
-- Se llama a la ficha de una obra anotada con el catálogo nuevo y se comprueba lo que antes salía
-- mal: que sus secuencias digan qué forma son y que la distribución no venga vacía. Y después, la
-- de una obra del corpus legado, que tiene que seguir abriendo aunque su métrica ya no se lea.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_admin uuid;
	v_obra uuid;
	v_ficha jsonb;
	v_sin_forma integer;
	v_distribucion integer;
begin
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
	limit 1;

	if v_admin is null then
		raise exception 'No hay ningún admin: la ficha no se puede ejecutar aquí.';
	end if;

	perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

	-- Una obra anotada con el catálogo nuevo y que se pueda ver.
	select o.obra_id into v_obra
	from public.obras o
	where exists (
		select 1
		from public.secuencias_metricas sm
		join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
		where sm.obra_id = o.obra_id
	)
	and public.can_view_obra_ficha_publica(o.obra_id, true)
	limit 1;

	if v_obra is null then
		raise exception 'Ninguna obra anotada con el catálogo nuevo se puede ver: la ficha no se comprueba.';
	end if;

	v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);
	if v_ficha is null then
		raise exception 'La ficha de la obra anotada % devolvió nulo', v_obra;
	end if;

	select count(*)
	into v_sin_forma
	from jsonb_array_elements(v_ficha -> 'metrica' -> 'secuencias') sec
	where sec ->> 'estrofa_forma_term' = 'sin_estrofa';

	if v_sin_forma > 0 then
		raise exception 'La ficha de % enseña % secuencias sin forma, y están anotadas', v_obra, v_sin_forma;
	end if;

	v_distribucion := jsonb_array_length(v_ficha -> 'metrica' -> 'distribucion_formas');
	if v_distribucion = 0 then
		raise exception 'La ficha de % no reparte ninguna forma', v_obra;
	end if;

	raise notice 'Ficha de la obra anotada %: % formas en la distribución', v_obra, v_distribucion;

	-- Y una del corpus legado: sin métrica que leer, pero tiene que abrir.
	select o.obra_id into v_obra
	from public.obras o
	where exists (select 1 from public.secuencias_metricas sm where sm.obra_id = o.obra_id)
	  and not exists (
		select 1
		from public.secuencias_metricas sm
		join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
		where sm.obra_id = o.obra_id
	  )
	  and public.can_view_obra_ficha_publica(o.obra_id, true)
	limit 1;

	if v_obra is not null then
		v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);
		if v_ficha is null then
			raise exception 'La ficha de la obra legada % devolvió nulo', v_obra;
		end if;
		if jsonb_array_length(v_ficha -> 'metrica' -> 'secuencias') = 0 then
			raise exception 'La ficha de la obra legada % perdió sus secuencias', v_obra;
		end if;
		raise notice 'Ficha de una obra legada comprobada: abre, con % secuencias y sin métrica',
			jsonb_array_length(v_ficha -> 'metrica' -> 'secuencias');
	end if;

	perform set_config('request.jwt.claims', '', true);
end
$guarda$;

commit;
