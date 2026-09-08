-- Una sola funcion construye la ficha
--
-- El recompute y la funcion de ficha se escribian en paralelo: cada medida habia que escribirla dos
-- veces -en `recompute_obra_resumen_metricas` y en la ficha- o solo aparecia en una de las dos
-- superficies. De ahi vienen casi todas las diferencias entre lo que ensena el buscador y lo que
-- ensena la ficha.
--
-- Se parte en dos lo que era una sola cosa:
--
--   `ficha_publica_json(obra, include_hidden)`  construye la ficha y no mira quien pregunta.
--   `get_obra_ficha_publica_base_without_slugs` comprueba el permiso y delega.
--
-- Con eso una obra publicada podra tener su ficha guardada y una en vista previa calcularsela al
-- vuelo, siendo **la misma ficha por construccion**. Guardarla es el paso siguiente; aqui solo se
-- separan, para que el cambio se pueda comprobar solo.

-- **La que construye la ficha.** No mira quien pregunta: eso es del portero, que la llama despues
-- de comprobarlo. Separarlas es lo que permite que una obra publicada tenga su ficha guardada y una
-- en vista previa se la calcule al vuelo, y que las dos sean **la misma ficha** por construccion y
-- no por disciplina: hasta hoy el recompute y la ficha se escribian en paralelo, y cada medida
-- habia que escribirla dos veces o solo aparecia en una de las dos superficies.
create or replace function public.ficha_publica_json(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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

-- **El portero.** Comprueba quien mira y delega. Su cuerpo era antes las trescientas lineas de
-- arriba, y por eso nadie podia reutilizar la ficha sin arrastrar el permiso.
create or replace function public.get_obra_ficha_publica_base_without_slugs(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $portero$
begin
	if not exists (
		select 1
		from public.obras o
		where o.obra_id = p_obra_id
			and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
	) then
		return null;
	end if;

	return public.ficha_publica_json(p_obra_id, p_include_hidden);
end;
$portero$;

-- `ficha_publica_json` no comprueba permisos, asi que **no se concede a nadie**: se llama desde el
-- portero y desde el recompute, las dos funciones `security definer` que si los comprueban.
revoke all on function public.ficha_publica_json(uuid, boolean) from public, anon, authenticated;

-- **Una funcion SQL no esta probada hasta que se ejecuta.** Se comprueba que las dos devuelven lo
-- mismo para quien puede ver la obra, y que el portero sigue negandola a quien no.
do $guarda$
declare
	v_obra uuid;
	v_admin uuid;
	v_directa jsonb;
	v_portero jsonb;
begin
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip')
	order by e.created_at
	limit 1;
	if v_admin is null then
		raise notice 'Sin editor admin: no se puede comprobar la ficha.';
		return;
	end if;
	perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

	select sm.obra_id into v_obra
	from public.secuencias_metricas sm
	join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
	group by sm.obra_id
	order by count(*) desc
	limit 1;
	if v_obra is null then
		raise notice 'No hay ninguna obra anotada: nada que comprobar.';
		return;
	end if;

	v_directa := public.ficha_publica_json(v_obra, true);
	v_portero := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);

	if v_directa is null then
		raise exception 'ficha_publica_json devolvio nulo para %', v_obra;
	end if;
	if v_directa is distinct from v_portero then
		raise exception 'El portero y la productora no devuelven lo mismo para %', v_obra;
	end if;
	if jsonb_array_length(v_directa->'metrica'->'secuencias') = 0 then
		raise exception 'La ficha de % no trae secuencias', v_obra;
	end if;

	-- Y el portero sigue negando lo que no se puede ver: sin identidad, una obra en borrador no sale.
	perform set_config('request.jwt.claims', '', true);
	if public.get_obra_ficha_publica_base_without_slugs(
		(select obra_id from public.obras o
		 join public.vocabularios v on v.termino_id = o.estado
		 where v.termino = 'borrador' limit 1),
		false
	) is not null then
		raise exception 'El portero deja pasar una obra en borrador sin identidad';
	end if;

	raise notice 'Productora y portero coinciden sobre %, con % secuencias.',
		v_obra, jsonb_array_length(v_directa->'metrica'->'secuencias');
end;
$guarda$;
