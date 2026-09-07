-- La evocación métrica es un fenómeno enunciativo
--
-- La evocación vivía en dos columnas propias de `secuencias_metricas` —un sí/no y su explicación—
-- y se preguntaba en el panel de la secuencia, al lado de «versos partidos» e «inaugura espacio».
-- Pero no es eso: es lo mismo que `cantado` y `prosa` —qué se está haciendo con la voz dentro del
-- pasaje— y su sitio es `secuencias_caracterizaciones_rango`, donde ya viven los otros dos.
--
-- **Afecta a la secuencia entera, y eso no la saca del mecanismo por rango.** Su caracterización
-- nace con el rango completo de la secuencia; que se pueda acotar después es ganancia, no
-- problema: la evocación de un pasaje largo suele empezar en un verso concreto.
--
-- **Se pierde a propósito la distinción entre «no» y «pendiente».** Las columnas admitían nulo, y
-- la checklist de revisión contaba ese nulo como trabajo por hacer. Una caracterización no se
-- declara negativa: no está la que no hay, igual que nadie declara que un pasaje no se canta. Las
-- 270 secuencias que decían «no» o no decían nada quedan sin caracterización, y son
-- indistinguibles; las 6 que la declaran se conservan enteras, con su texto.
--
-- **La ficha pública se rehace aquí.** `get_obra_ficha_publica_base_without_slugs` publicaba las
-- dos columnas, y borrarlas sin tocarla dejaría la ficha rota en ejecución sin que nada avisara
-- antes: el cuerpo entrecomillado no se revalida al borrar una columna. La ficha ya pinta la tabla
-- de caracterizaciones por rango, así que la evocación aparece ahí sola, con su rango y su
-- explicación en «observaciones».

begin;

-- ---------------------------------------------------------------------------
-- El término
-- ---------------------------------------------------------------------------

insert into public.vocabularios (categoria, termino, etiqueta, termino_padre_id, nivel, orden, definicion, activo)
select
	'caracterizacion_rango',
	'evocacion_metrica',
	'Evocación métrica',
	padre.termino_id,
	2,
	30,
	'Pasaje en el que el cambio de metro se debe a que un personaje adopta, imita o reproduce la voz de otro.',
	true
from public.vocabularios padre
where padre.categoria = 'caracterizacion_rango'
  and padre.termino = 'fenomenos_enunciativos'
  and not exists (
	select 1 from public.vocabularios v
	where v.categoria = 'caracterizacion_rango' and v.termino = 'evocacion_metrica'
  );

-- ---------------------------------------------------------------------------
-- El traslado
-- ---------------------------------------------------------------------------

do $traslado$
declare
	v_termino uuid;
	v_declaradas integer;
	v_trasladadas integer;
begin
	select termino_id into v_termino
	from public.vocabularios
	where categoria = 'caracterizacion_rango' and termino = 'evocacion_metrica';

	if v_termino is null then
		raise exception 'No se creó el término «evocacion_metrica»: ¿existe el padre «fenomenos_enunciativos»?';
	end if;

	-- Si las columnas ya no están, la migración se aplicó antes y no hay nada que trasladar.
	if not exists (
		select 1 from information_schema.columns
		where table_schema = 'public'
		  and table_name = 'secuencias_metricas'
		  and column_name = 'evocacion_metrica'
	) then
		raise notice 'Las columnas de evocación ya no están: el traslado ya se hizo.';
		return;
	end if;

	execute 'select count(*) from public.secuencias_metricas where evocacion_metrica' into v_declaradas;

	execute format($sql$
		insert into public.secuencias_caracterizaciones_rango
			(secuencia_id, tipo_caracterizacion_rango_id, v_ini, v_fin, observaciones)
		select
			sm.secuencia_id,
			%L::uuid,
			sm.v_ini,
			sm.v_fin,
			nullif(btrim(coalesce(sm.evocacion_metrica_texto, '')), '')
		from public.secuencias_metricas sm
		where sm.evocacion_metrica
		  and not exists (
			select 1
			from public.secuencias_caracterizaciones_rango c
			where c.secuencia_id = sm.secuencia_id
			  and c.tipo_caracterizacion_rango_id = %L::uuid
		  )
	$sql$, v_termino, v_termino);

	get diagnostics v_trasladadas = row_count;

	if v_trasladadas <> v_declaradas then
		raise exception 'Se declaraban % evocaciones y se trasladaron %', v_declaradas, v_trasladadas;
	end if;

	raise notice 'Evocaciones trasladadas: %', v_trasladadas;
end
$traslado$;

-- ---------------------------------------------------------------------------
-- La ficha deja de publicar las dos columnas
--
-- Es el cuerpo que hoy está en producción, sin las dos claves. Nada más cambia.
-- ---------------------------------------------------------------------------

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
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(est_parent.etiqueta, est_parent.termino, est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_slug', coalesce(est_parent.termino, est.termino),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
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

-- ---------------------------------------------------------------------------
-- Las columnas se van
-- ---------------------------------------------------------------------------

alter table public.secuencias_metricas
	drop column if exists evocacion_metrica,
	drop column if exists evocacion_metrica_texto;

-- ---------------------------------------------------------------------------
-- La guarda ejecuta lo que toca
--
-- `db push` y las pruebas pasan sobre PL/pgSQL roto: un cuerpo entrecomillado no se revalida al
-- borrar una columna. Así que la ficha se llama de verdad, sobre una obra con secuencias, y se
-- comprueba que la evocación llega por donde ahora tiene que llegar.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_admin uuid;
	v_obra uuid;
	v_ficha jsonb;
	v_evocaciones integer;
	v_esperadas integer;
begin
	-- **La ficha no se le enseña a cualquiera.** `can_view_obra_ficha_publica` mira el estado de la
	-- obra y quién pregunta, y en una migración no pregunta nadie: sin identidad devolvería nulo y
	-- la guarda pasaría sin haber ejecutado una sola línea del cuerpo. Se toma prestada la de un
	-- admin, y solo dentro de esta transacción.
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
	limit 1;

	if v_admin is null then
		raise notice 'No hay ningún admin: la ficha no se puede ejecutar aquí.';
		return;
	end if;

	perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

	-- Una obra que ya se pueda ver y que además tenga evocación, para que la guarda compruebe algo.
	select sm.obra_id into v_obra
	from public.secuencias_caracterizaciones_rango c
	join public.secuencias_metricas sm on sm.secuencia_id = c.secuencia_id
	join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
	where v.categoria = 'caracterizacion_rango'
	  and v.termino = 'evocacion_metrica'
	  and public.can_view_obra_ficha_publica(sm.obra_id, true)
	limit 1;

	if v_obra is null then
		raise notice 'Ninguna obra visible tiene evocación: la ficha no se comprueba aquí.';
		perform set_config('request.jwt.claims', '', true);
		return;
	end if;

	v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);

	if v_ficha is null then
		raise exception 'La ficha de la obra % devolvió nulo', v_obra;
	end if;

	-- Lo que la ficha enseña tiene que ser exactamente lo que la tabla guarda para esa obra.
	select count(*)
	into v_esperadas
	from public.secuencias_caracterizaciones_rango c
	join public.secuencias_metricas sm on sm.secuencia_id = c.secuencia_id
	join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
	where sm.obra_id = v_obra
	  and v.categoria = 'caracterizacion_rango'
	  and v.termino = 'evocacion_metrica';

	select count(*)
	into v_evocaciones
	from jsonb_array_elements(v_ficha -> 'metrica' -> 'secuencias') sec,
	     jsonb_array_elements(sec -> 'caracterizaciones_rango') car
	where car ->> 'tipo_caracterizacion_rango_term' = 'Evocación métrica';

	if v_evocaciones <> v_esperadas then
		raise exception 'La obra % guarda % evocaciones y la ficha enseña %', v_obra, v_esperadas, v_evocaciones;
	end if;

	if exists (
		select 1
		from jsonb_array_elements(v_ficha -> 'metrica' -> 'secuencias') sec
		where sec ? 'evocacion_metrica'
	) then
		raise exception 'La ficha sigue publicando la clave evocacion_metrica.';
	end if;

	perform set_config('request.jwt.claims', '', true);
	raise notice 'Ficha comprobada sobre la obra %: % evocaciones por rango', v_obra, v_evocaciones;
end
$guarda$;

commit;
