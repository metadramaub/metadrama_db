begin;

do $$
declare
	v_borrador_id uuid;
	v_pendiente_id uuid;
	v_en_revision_id uuid;
	v_validado_id uuid;
	v_vista_previa_id uuid;
	v_listo_para_publicar_id uuid;
	v_publicado_id uuid;
begin
	select termino_id into v_borrador_id from public.vocabularios where categoria = 'estado' and termino = 'borrador' limit 1;
	select termino_id into v_pendiente_id from public.vocabularios where categoria = 'estado' and termino = 'pendiente' limit 1;
	select termino_id into v_en_revision_id from public.vocabularios where categoria = 'estado' and termino = 'en_revision' limit 1;
	select termino_id into v_validado_id from public.vocabularios where categoria = 'estado' and termino = 'validado' limit 1;
	select termino_id into v_vista_previa_id from public.vocabularios where categoria = 'estado' and termino = 'vista_previa' limit 1;
	select termino_id into v_listo_para_publicar_id from public.vocabularios where categoria = 'estado' and termino = 'listo_para_publicar' limit 1;
	select termino_id into v_publicado_id from public.vocabularios where categoria = 'estado' and termino = 'publicado' limit 1;

	if v_vista_previa_id is null then
		if v_pendiente_id is not null then
			update public.vocabularios
			set termino = 'vista_previa',
				etiqueta = 'Vista previa',
				orden = 20,
				activo = true,
				updated_at = now()
			where termino_id = v_pendiente_id;
			v_vista_previa_id := v_pendiente_id;
		else
			insert into public.vocabularios (termino_id, categoria, termino, etiqueta, nivel, orden, activo, created_at, updated_at)
			values ('55b5460d-0ac7-46b5-a8d7-60450ecfdb54', 'estado', 'vista_previa', 'Vista previa', 1, 20, true, now(), now())
			returning termino_id into v_vista_previa_id;
		end if;
	else
		update public.vocabularios
		set etiqueta = 'Vista previa',
			orden = 20,
			activo = true,
			updated_at = now()
		where termino_id = v_vista_previa_id;
	end if;

	if v_listo_para_publicar_id is null then
		if v_validado_id is not null then
			update public.vocabularios
			set termino = 'listo_para_publicar',
				etiqueta = 'Listo para publicar',
				orden = 30,
				activo = true,
				updated_at = now()
			where termino_id = v_validado_id;
			v_listo_para_publicar_id := v_validado_id;
		else
			insert into public.vocabularios (termino_id, categoria, termino, etiqueta, nivel, orden, activo, created_at, updated_at)
			values ('41e7d7d7-ef1d-4df5-bc6c-c9db8e4695ea', 'estado', 'listo_para_publicar', 'Listo para publicar', 1, 30, true, now(), now())
			returning termino_id into v_listo_para_publicar_id;
		end if;
	else
		update public.vocabularios
		set etiqueta = 'Listo para publicar',
			orden = 30,
			activo = true,
			updated_at = now()
		where termino_id = v_listo_para_publicar_id;
	end if;

	if v_borrador_id is not null then
		update public.vocabularios
		set etiqueta = null, orden = 10, activo = true, updated_at = now()
		where termino_id = v_borrador_id;
	end if;

	if v_publicado_id is not null then
		update public.vocabularios
		set etiqueta = null, orden = 40, activo = true, updated_at = now()
		where termino_id = v_publicado_id;
	end if;

	update public.obras
	set estado = v_vista_previa_id,
		fecha_cambio_estado = coalesce(fecha_cambio_estado, now())
	where estado = any(array[v_pendiente_id, v_en_revision_id])
	and estado is distinct from v_vista_previa_id;

	update public.obras
	set estado = v_listo_para_publicar_id,
		fecha_cambio_estado = coalesce(fecha_cambio_estado, now())
	where estado = v_validado_id
	and estado is distinct from v_listo_para_publicar_id;

	update public.vocabularios
	set activo = false,
		orden = null,
		updated_at = now()
	where categoria = 'estado'
		and termino in ('pendiente', 'en_revision', 'validado')
		and termino_id not in (v_vista_previa_id, v_listo_para_publicar_id);
end;
$$;

create or replace function public.can_view_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
	select exists (
		select 1
		from public.obras o
		join public.vocabularios estado
			on estado.termino_id = o.estado
			and estado.categoria = 'estado'
		where o.obra_id = p_obra_id
			and (
				(
					lower(estado.termino) = 'publicado'
					and (
						coalesce(o.visible_publico, false)
						or (
							coalesce(p_include_hidden, false)
							and (
								public.auth_is_admin_or_ip()
								or o.editor_asignado = auth.uid()
							)
						)
					)
				)
				or (
					lower(estado.termino) in ('vista_previa', 'listo_para_publicar')
					and (
						public.auth_is_admin_or_ip()
						or o.editor_asignado = auth.uid()
					)
				)
			)
	);
$$;

grant execute on function public.can_view_obra_ficha_publica(uuid, boolean) to anon;
grant execute on function public.can_view_obra_ficha_publica(uuid, boolean) to authenticated;
grant execute on function public.can_view_obra_ficha_publica(uuid, boolean) to service_role;

create or replace function public.get_obra_comentarios_publicos(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language sql
security definer
set search_path = public
as $$
	select coalesce(
		jsonb_agg(
			jsonb_build_object(
				'comentario_id', ci.comentario_id,
				'comentario', ci.comentario,
				'created_at', ci.created_at,
				'seccion', ci.seccion,
				'secuencia_id', ci.secuencia_id,
				'jornada_id', ci.jornada_id,
				'cuadro_id', ci.cuadro_id,
				'nombre_editor', e.nombre_completo
			)
			order by ci.created_at, ci.comentario_id
		),
		'[]'::jsonb
	)
	from public.obras o
	join public.comentarios_internos ci
		on ci.obra_id = o.obra_id
	join public.vocabularios tipo
		on tipo.termino_id = ci.tipo_comentario_id
		and tipo.categoria = 'tipo_comentario'
		and tipo.termino = 'observacion_publica'
	left join public.editores e
		on e.user_id = ci.user_id
	where o.obra_id = p_obra_id
		and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
		and ci.visible_publico = true;
$$;

grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to anon;
grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to authenticated;
grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to service_role;

create or replace function public.get_obra_ficha_publica_base_without_slugs(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(est_parent.etiqueta, est_parent.termino, est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_slug', coalesce(est_parent.termino, est.termino),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'evocacion_metrica', sm.evocacion_metrica,
						'evocacion_metrica_texto', sm.evocacion_metrica_texto,
						'intervencion_personajes_femeninos', sm.intervencion_personajes_femeninos,
						'intervencion_figuras_donaire', sm.intervencion_figuras_donaire,
						'intervencion_personajes_sobrenaturales', sm.intervencion_personajes_sobrenaturales,
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
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_slug', coalesce(est_parent.termino, est.termino),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'sinopsis', sm.sinopsis
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(est_parent.etiqueta, est_parent.termino, est.etiqueta, est.termino, 'sin_estrofa') as forma,
				coalesce(est_parent.termino, est.termino) as forma_slug,
				coalesce(est_parent.tipo_forma, est.tipo_forma) as forma_tipo_forma,
				sum(sm.n_versos)::int as versos
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			where sm.obra_id = v_obra.obra_id
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
				'estado_term', (
					select ve.termino
					from public.vocabularios ve
					where ve.termino_id = v_obra.estado
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
$$;

grant execute on function public.get_obra_ficha_publica_base_without_slugs(uuid, boolean) to anon;
grant execute on function public.get_obra_ficha_publica_base_without_slugs(uuid, boolean) to authenticated;
grant execute on function public.get_obra_ficha_publica_base_without_slugs(uuid, boolean) to service_role;

commit;
