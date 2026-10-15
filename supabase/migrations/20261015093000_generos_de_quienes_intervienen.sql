-- El género caracteriza las voces que hablan o cantan, también las colectivas.
-- NULL sigue siendo pendiente. Indeterminado es una respuesta, no una falta de revisión.
-- La columna anterior permanece como proyección de compatibilidad durante el despliegue.
begin;

lock table public.secuencias_metricas in share row exclusive mode;
create temporary table genero_antes on commit drop as
select secuencia_id, to_jsonb(s) as fila from public.secuencias_metricas s;

create or replace function public.generos_desde_intervencion_femenina(valor text)
returns text[] language sql immutable set search_path = public as $$
  select case valor
    when 'sin_intervencion' then array['masculino']
    when 'exclusiva' then array['femenino']
    when 'compartida' then array['masculino','femenino']
    else null::text[] end;
$$;

create or replace function public.intervencion_femenina_desde_generos(valores text[])
returns text language sql immutable set search_path = public as $$
  select case
    when valores is null then null
    when valores = array['femenino'] then 'exclusiva'
    when 'femenino' = any(valores) then 'compartida'
    when 'indeterminado' = any(valores) then null
    else 'sin_intervencion' end;
$$;

create or replace function public.ordenar_generos_intervinientes(valores text[])
returns text[] language sql immutable strict set search_path = public as $$
  select array(select distinct valor from unnest(valores) valor
    order by valor);
$$;

create or replace function public.generos_intervinientes_validos(valores text[])
returns boolean language sql immutable strict set search_path = public as $$
  select array_ndims(valores) = 1 and array_lower(valores, 1) = 1
    and cardinality(valores) between 1 and 3
    and array_position(valores, null) is null
    and valores <@ array['masculino','femenino','indeterminado']
    and cardinality(valores) = cardinality(public.ordenar_generos_intervinientes(valores));
$$;

alter table public.secuencias_metricas add column if not exists generos_intervinientes text[];
comment on column public.secuencias_metricas.generos_intervinientes is
  'Género de quienes hablan o cantan: masculino, femenino, indeterminado; selección múltiple. NULL = pendiente. Indeterminado incluye voces no identificables y personajes sin género definido.';
comment on column public.secuencias_metricas.intervencion_personajes_femeninos is
  'Compatibilidad del modelo anterior. El dato activo es generos_intervinientes. No permite expresar las siete combinaciones; no utilizar como fuente para nuevas consultas.';

update public.secuencias_metricas set generos_intervinientes =
  public.generos_desde_intervencion_femenina(intervencion_personajes_femeninos)
where generos_intervinientes is null and intervencion_personajes_femeninos is not null;

alter table public.secuencias_metricas drop constraint if exists secuencias_generos_intervinientes_chk;
alter table public.secuencias_metricas add constraint secuencias_generos_intervinientes_chk
  check (generos_intervinientes is null or public.generos_intervinientes_validos(generos_intervinientes));

create or replace function public.sincronizar_generos_intervinientes()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.generos_intervinientes is null then
      new.generos_intervinientes := public.generos_desde_intervencion_femenina(new.intervencion_personajes_femeninos);
    end if;
  elsif new.generos_intervinientes is not distinct from old.generos_intervinientes
    and new.intervencion_personajes_femeninos is distinct from old.intervencion_personajes_femeninos then
    new.generos_intervinientes := public.generos_desde_intervencion_femenina(new.intervencion_personajes_femeninos);
  end if;
  if new.generos_intervinientes is not null then
    if not public.generos_intervinientes_validos(new.generos_intervinientes) then
      raise exception 'Selecciona de uno a tres géneros diferentes: masculino, femenino, indeterminado'
        using errcode = '23514';
    end if;
    -- Orden estable, independiente del orden de los clics.
    select array_agg(valor order by posicion) into new.generos_intervinientes
    from unnest(array['masculino','femenino','indeterminado']) with ordinality g(valor,posicion)
    where valor = any(new.generos_intervinientes);
  end if;
  new.intervencion_personajes_femeninos := public.intervencion_femenina_desde_generos(new.generos_intervinientes);
  return new;
end;
$$;
drop trigger if exists trg_sincronizar_generos_intervinientes on public.secuencias_metricas;
create trigger trg_sincronizar_generos_intervinientes before insert or update on public.secuencias_metricas
  for each row execute function public.sincronizar_generos_intervinientes();

-- El origen exacto permanece en la copia y el snapshot previos. Esta guarda exige una
-- conversión fiel de cada fila y que ninguna otra anotación haya cambiado.
do $$ begin
  if exists (
    select 1 from genero_antes a full join public.secuencias_metricas s using (secuencia_id)
    where a.secuencia_id is null or s.secuencia_id is null
      or s.generos_intervinientes is distinct from public.generos_desde_intervencion_femenina(a.fila ->> 'intervencion_personajes_femeninos')
      or (to_jsonb(s) - 'generos_intervinientes' - 'updated_at') is distinct from (a.fila - 'updated_at')
  ) then raise exception 'La conversión de géneros no conserva las anotaciones'; end if;
end $$;

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

CREATE OR REPLACE FUNCTION public.analisis_obra_publico_json(p_obra_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_ficha jsonb;
	v_secuencias jsonb;
	v_cuadros jsonb;
	v_jornadas jsonb;
	v_hechos jsonb;
	v_transiciones jsonb;
	v_fenomenos jsonb;
	v_perfil_formas jsonb;
	v_enunciacion jsonb;
	v_articulacion jsonb;
	v_metricas jsonb;
	v_total integer;
	v_total_versos integer;
	v_n_jornadas integer;
	v_n_formas integer;
	v_diversidad double precision;
	v_densidad double precision;
begin
	select
		r.ficha,
		r.total_versos,
		r.n_jornadas,
		r.n_formas_distintas,
		r.numero_efectivo_formas,
		r.densidad_transiciones
	into
		v_ficha,
		v_total_versos,
		v_n_jornadas,
		v_n_formas,
		v_diversidad,
		v_densidad
	from public.obras_resumen r
	where r.obra_id = p_obra_id;

	if v_ficha is null then
		return null;
	end if;

	v_secuencias := coalesce(v_ficha #> '{metrica,secuencias}', '[]'::jsonb);
	v_cuadros := coalesce(v_ficha #> '{estructura,cuadros}', '[]'::jsonb);
	v_jornadas := coalesce(v_ficha #> '{estructura,jornadas}', '[]'::jsonb);
	v_total := jsonb_array_length(v_secuencias);
	v_total_versos := coalesce(v_total_versos, (
		select sum((s.value ->> 'n_versos')::integer)::integer
		from jsonb_array_elements(v_secuencias) s(value)
	), 0);

	select coalesce(jsonb_agg(
		jsonb_strip_nulls(jsonb_build_object(
			'id', s.value ->> 'secuencia_id',
			'i', (s.value ->> 'v_ini')::integer,
			'f', (s.value ->> 'v_fin')::integer,
			'n', (s.value ->> 'n_versos')::integer,
			'j', (s.value ->> 'jornada_num')::integer,
			'c', (s.value ->> 'cuadro_num')::integer,
			'forma', s.value ->> 'forma_slug',
			'tipo_forma', s.value ->> 'tipo_forma',
			'arquitectura', s.value ->> 'arquitectura_slug',
			'cuadro_continua', (s.value ->> 'cuadro_continua')::boolean,
			'cortes_cuadro', (
				select count(*)::integer
				from jsonb_array_elements(v_cuadros) cuadro(value)
				where (cuadro.value ->> 'cuadro_num')::integer > 1
					and (cuadro.value ->> 'v_ini')::integer > (s.value ->> 'v_ini')::integer
					and (cuadro.value ->> 'v_ini')::integer <= (s.value ->> 'v_fin')::integer
			),
			'versos_partidos', (s.value ->> 'versos_partidos')::boolean,
			'cambio_espacio', (s.value ->> 'inaugura_espacio')::boolean,
			'evento_sobrenatural', (s.value ->> 'evento_sobrenatural')::boolean,
			'intervencion_femenina', s.value ->> 'intervencion_personajes_femeninos',
			'generos_intervinientes', s.value -> 'generos_intervinientes',
			'intervencion_donaire', s.value ->> 'intervencion_figuras_donaire',
			'intervencion_sobrenaturales', s.value ->> 'intervencion_personajes_sobrenaturales',
			'caracterizaciones', coalesce(s.value -> 'caracterizaciones_rango', '[]'::jsonb),
			'metros', coalesce(s.value -> 'metros', '[]'::jsonb),
			'esquemas', coalesce(s.value -> 'esquemas_rima', '[]'::jsonb),
			'rasgos', coalesce(s.value -> 'rasgos', '[]'::jsonb),
			'variedades', coalesce(s.value -> 'variedades', '[]'::jsonb),
			'desviaciones', coalesce(s.value -> 'desviaciones', '[]'::jsonb)
		)) order by s.ordinality), '[]'::jsonb)
	into v_hechos
	from jsonb_array_elements(v_secuencias) with ordinality s(value, ordinality);

	with sec as (
		select
			coalesce(nullif(value ->> 'forma_slug', ''), 'sin-forma-anotada') as forma,
			value ->> 'tipo_forma' as tipo_forma,
			(value ->> 'n_versos')::integer as versos
		from jsonb_array_elements(v_secuencias)
	), agrupadas as (
		select forma, max(tipo_forma) as tipo_forma, sum(versos)::integer as versos,
			count(*)::integer as secuencias
		from sec
		group by forma
	)
	select coalesce(jsonb_object_agg(forma, jsonb_build_object(
		'tipo_forma', tipo_forma,
		'versos', versos,
		'secuencias', secuencias,
		'proporcion_versos', case when v_total_versos > 0 then versos::numeric / v_total_versos else null end,
		'longitud_media_secuencia', case when secuencias > 0 then versos::numeric / secuencias else null end
	)), '{}'::jsonb)
	into v_perfil_formas
	from agrupadas;

	with orden as (
		select
			s.ordinality,
			coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada') as forma,
			lag(coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada'))
				over (order by s.ordinality) as forma_anterior
		from jsonb_array_elements(v_secuencias) with ordinality s(value, ordinality)
	), grupos as (
		select forma_anterior as de, forma as a, count(*)::integer as veces
		from orden
		where forma_anterior is not null
		group by forma_anterior, forma
	)
	select coalesce(jsonb_agg(jsonb_build_object(
		'de', de,
		'a', a,
		'veces', veces
	) order by veces desc, de, a), '[]'::jsonb)
	into v_transiciones
	from grupos;

	with sec as (
		select value
		from jsonb_array_elements(v_secuencias)
	), metricas(nombre, campo, es_intervencion) as (
		values
			('versos_partidos', 'versos_partidos', false),
			('cambios_espacio', 'inaugura_espacio', false),
			('eventos_sobrenaturales', 'evento_sobrenatural', false),
			('intervencion_femenina', 'intervencion_personajes_femeninos', true),
			('intervencion_donaire', 'intervencion_figuras_donaire', true),
			('intervencion_sobrenaturales', 'intervencion_personajes_sobrenaturales', true)
	), conteos as (
		select
			m.nombre,
			count(*) filter (
				where case when m.es_intervencion
					then s.value ->> m.campo in ('exclusiva', 'compartida')
					else (s.value ->> m.campo)::boolean is true end
			)::integer as si,
			count(*) filter (
				where case when m.es_intervencion
					then s.value ->> m.campo = 'sin_intervencion'
					else (s.value ->> m.campo)::boolean is false end
			)::integer as no,
			count(*) filter (where s.value ->> m.campo is null)::integer as sin_respuesta,
			count(*) filter (where s.value ->> m.campo = 'exclusiva')::integer as exclusiva,
			count(*) filter (where s.value ->> m.campo = 'compartida')::integer as compartida
		from metricas m cross join sec s
		group by m.nombre
	)
	select coalesce(jsonb_object_agg(nombre, jsonb_build_object(
		'si', si,
		'no', no,
		'sin_respuesta', sin_respuesta,
		'total_respondidas', si + no,
		'proporcion', case when si + no > 0 then si::numeric / (si + no) else null end,
		'exclusiva', exclusiva,
		'compartida', compartida
	)), '{}'::jsonb)
	into v_fenomenos
	from conteos;

	-- Cada género tiene el mismo denominador: secuencias con respuesta. Las categorías
	-- se solapan; «no» significa no seleccionado, no una inferencia sobre voces indeterminadas.
	select v_fenomenos || coalesce(jsonb_object_agg('intervencion_' || g.nombre, jsonb_build_object(
		'si', g.si, 'no', g.respondidas - g.si, 'sin_respuesta', v_total - g.respondidas,
		'total_respondidas', g.respondidas,
		'proporcion', g.si::numeric / nullif(g.respondidas, 0),
		'exclusiva', g.exclusiva, 'compartida', g.si - g.exclusiva
	)), '{}'::jsonb) into v_fenomenos
	from (
		select m.nombre,
			count(*) filter (where s.value -> 'generos_intervinientes' ? m.genero)::integer as si,
			count(*) filter (where jsonb_typeof(s.value -> 'generos_intervinientes') = 'array')::integer as respondidas,
			count(*) filter (where s.value -> 'generos_intervinientes' = jsonb_build_array(m.genero))::integer as exclusiva
		from (values ('masculina','masculino'),('femenina','femenino'),('indeterminada','indeterminado')) m(nombre,genero)
		left join jsonb_array_elements(v_secuencias) s(value) on true
		group by m.nombre
	) g;

	-- range_agg fusiona rangos solapados o contiguos antes de contar versos: el mismo pasaje no
	-- pesa dos veces si una caracterización se registró en fragmentos coincidentes.
	with rangos_crudos as (
		select
			replace(
				translate(lower(c.value ->> 'tipo_caracterizacion_rango_term'), 'áéíóúüñ', 'aeiouun'),
				' ', '_'
			) as tipo,
			int4range(
				(c.value ->> 'v_ini')::integer,
				(c.value ->> 'v_fin')::integer + 1,
				'[)'
			) as rango,
			coalesce(nullif(s.value ->> 'forma_slug', ''), 'sin-forma-anotada') as forma
		from jsonb_array_elements(v_secuencias) s(value)
		cross join lateral jsonb_array_elements(coalesce(s.value -> 'caracterizaciones_rango', '[]'::jsonb)) c(value)
		where nullif(c.value ->> 'tipo_caracterizacion_rango_term', '') is not null
	), rangos as (
		select * from rangos_crudos
		where tipo in ('cantado', 'prosa', 'evocacion_metrica')
	), por_tipo as (
		select tipo, range_agg(rango) as rangos, array_agg(distinct forma order by forma) as formas
		from rangos
		group by tipo
	), conteos as (
		select
			tipo,
			coalesce((select sum(upper(r) - lower(r)) from unnest(rangos) r), 0)::integer as versos,
			formas
		from por_tipo
	)
	select coalesce(jsonb_object_agg(tipo, jsonb_build_object(
		'versos', versos,
		'proporcion_versos', case when v_total_versos > 0 then versos::numeric / v_total_versos else null end,
		'formas', to_jsonb(formas)
	)), '{}'::jsonb)
	into v_enunciacion
	from conteos;

	with cuadros_ordenados as (
		select
			(c.value ->> 'v_ini')::integer as limite,
			row_number() over (
				partition by c.value ->> 'jornada_id'
				order by (c.value ->> 'v_ini')::integer
			) as posicion
		from jsonb_array_elements(v_cuadros) c(value)
	), limites as (
		select limite from cuadros_ordenados where posicion > 1
	), sec as (
		select
			s.value ->> 'secuencia_id' as id,
			(s.value ->> 'v_ini')::integer as v_ini,
			(s.value ->> 'v_fin')::integer as v_fin,
			coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada') as forma
		from jsonb_array_elements(v_secuencias) s(value)
	), clasificados as (
		select
			l.limite,
			anterior.id as anterior_id,
			siguiente.id as siguiente_id,
			anterior.forma as forma_anterior,
			siguiente.forma as forma_siguiente
		from limites l
		left join lateral (
			select id, forma from sec where v_ini <= l.limite - 1 and v_fin >= l.limite - 1 limit 1
		) anterior on true
		left join lateral (
			select id, forma from sec where v_ini <= l.limite and v_fin >= l.limite limit 1
		) siguiente on true
	), conteos as (
		select
			count(*)::integer as total,
			count(*) filter (where anterior_id is null or siguiente_id is null)::integer as sin_cobertura,
			count(*) filter (where anterior_id = siguiente_id)::integer as parten_secuencia,
			count(*) filter (where anterior_id is not null and siguiente_id is not null and anterior_id <> siguiente_id)::integer as cambian_secuencia,
			count(*) filter (where anterior_id is not null and siguiente_id is not null and anterior_id <> siguiente_id and forma_anterior = forma_siguiente)::integer as cambian_secuencia_misma_forma
		from clasificados
	), extremos as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'jornada', (j.value ->> 'jornada_num')::integer,
			'abre', (
				select coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada')
				from jsonb_array_elements(v_secuencias) s(value)
				where (s.value ->> 'v_ini')::integer between (j.value ->> 'v_ini')::integer and (j.value ->> 'v_fin')::integer
				order by (s.value ->> 'v_ini')::integer limit 1
			),
			'cierra', (
				select coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada')
				from jsonb_array_elements(v_secuencias) s(value)
				where (s.value ->> 'v_ini')::integer between (j.value ->> 'v_ini')::integer and (j.value ->> 'v_fin')::integer
				order by (s.value ->> 'v_ini')::integer desc limit 1
			)
		) order by (j.value ->> 'jornada_num')::integer), '[]'::jsonb) as jornadas
		from jsonb_array_elements(v_jornadas) j(value)
	)
	select jsonb_build_object(
		'cambios_cuadro_total', c.total,
		'cambios_cuadro_sin_cobertura', c.sin_cobertura,
		'cambios_cuadro_que_parten_secuencia', c.parten_secuencia,
		'cambios_cuadro_con_cambio_secuencia', c.cambian_secuencia,
		'cambios_secuencia_misma_forma', c.cambian_secuencia_misma_forma,
		'proporcion_cambios_cuadro_con_cambio_secuencia',
			case when c.total - c.sin_cobertura > 0
				then c.cambian_secuencia::numeric / (c.total - c.sin_cobertura) else null end,
		'jornadas', e.jornadas
	)
	into v_articulacion
	from conteos c cross join extremos e;

	v_metricas := jsonb_build_object(
		'total_versos', v_total_versos,
		'total_secuencias', v_total,
		'n_jornadas', v_n_jornadas,
		'n_formas_distintas', v_n_formas,
		'numero_efectivo_formas', v_diversidad,
		'densidad_transiciones', v_densidad,
		'longitud_media_secuencia', case when v_total > 0 then v_total_versos::numeric / v_total else null end,
		'proporcion_italiana', case when v_total_versos > 0 then (
			select coalesce(sum((s.value ->> 'n_versos')::integer), 0)::numeric / v_total_versos
			from jsonb_array_elements(v_secuencias) s(value)
			where s.value ->> 'tipo_forma' = 'forma_italiana'
		) else null end,
		'proporcion_sin_forma', case when v_total_versos > 0 then (
			select coalesce(sum((s.value ->> 'n_versos')::integer), 0)::numeric / v_total_versos
			from jsonb_array_elements(v_secuencias) s(value)
			where nullif(s.value ->> 'forma_slug', '') is null
		) else null end
	);

	return jsonb_build_object(
		'schema_version', 2,
		'obra_id', p_obra_id,
		'total_secuencias', v_total,
		'total_transiciones', greatest(v_total - 1, 0),
		'metricas', v_metricas,
		'perfil_formas', v_perfil_formas,
		'articulacion', v_articulacion,
		'enunciacion', v_enunciacion,
		'secuencias', v_hechos,
		'transiciones', v_transiciones,
		'fenomenos', v_fenomenos
	);
end;
$function$
;

-- Pruebas de escritura y lectura reales. El bloque interior se revierte por completo.
do $pruebas$
declare
  v_id uuid;
  v_obra uuid;
  v_valores text[];
  v_esperado text[];
  v_ficha jsonb;
  v_analisis jsonb;
  v_caso jsonb;
  v_genero text;
  v_nombre text;
  v_si integer;
  v_respondidas integer;
begin
  select s.secuencia_id, s.obra_id into v_id, v_obra
  from public.secuencias_metricas s join public.obras o using (obra_id)
  order by (o.titulo ilike '%(prueba)%') desc, s.secuencia_id limit 1;
  if v_id is null then raise exception 'No hay secuencia para ejecutar las guardas'; end if;
  begin
    for v_caso in select value from jsonb_array_elements('[
      ["masculino"], ["femenino"], ["indeterminado"],
      ["masculino","femenino"], ["masculino","indeterminado"],
      ["femenino","indeterminado"], ["masculino","femenino","indeterminado"]
    ]'::jsonb) loop
      select array_agg(value) into v_esperado from jsonb_array_elements_text(v_caso);
      update public.secuencias_metricas set generos_intervinientes = v_esperado where secuencia_id = v_id;
      select generos_intervinientes into v_valores from public.secuencias_metricas where secuencia_id = v_id;
      if v_valores is distinct from v_esperado then raise exception 'No se conserva la combinación %', v_esperado; end if;
      v_ficha := public.ficha_publica_base_json(v_obra, true);
      if not exists (select 1 from jsonb_array_elements(v_ficha #> '{metrica,secuencias}') s
        where s ->> 'secuencia_id' = v_id::text and s -> 'generos_intervinientes' = to_jsonb(v_esperado))
      then raise exception 'La ficha no devuelve los géneros'; end if;
      perform public.recompute_obra_resumen(v_obra);
      v_analisis := public.analisis_obra_publico_json(v_obra);
      if not exists (select 1 from jsonb_array_elements(v_analisis -> 'secuencias') s
        where s ->> 'id' = v_id::text and s -> 'generos_intervinientes' = to_jsonb(v_esperado))
      then raise exception 'El análisis no devuelve los géneros'; end if;
      for v_genero, v_nombre in select * from (values
        ('masculino','masculina'),('femenino','femenina'),('indeterminado','indeterminada')) m(g,n) loop
        select count(*) filter (where v_genero = any(generos_intervinientes)),
          count(generos_intervinientes) into v_si, v_respondidas
        from public.secuencias_metricas where obra_id = v_obra;
        if (v_analisis #>> array['fenomenos','intervencion_' || v_nombre,'si'])::integer is distinct from v_si
          or (v_analisis #>> array['fenomenos','intervencion_' || v_nombre,'total_respondidas'])::integer is distinct from v_respondidas
        then raise exception 'El laboratorio cuenta mal %', v_genero; end if;
      end loop;
    end loop;
    for v_caso in select value from jsonb_array_elements('[[],["otro"],["femenino","femenino"],[null]]'::jsonb) loop
      select coalesce(array_agg(value), array[]::text[]) into v_valores from jsonb_array_elements_text(v_caso);
      begin
        update public.secuencias_metricas set generos_intervinientes = v_valores where secuencia_id = v_id;
        raise exception 'Se ha aceptado una selección inválida: %', v_valores;
      exception when check_violation then null;
      end;
    end loop;
    update public.secuencias_metricas set generos_intervinientes = null where secuencia_id = v_id;
    if exists (select 1 from public.secuencias_metricas where secuencia_id = v_id
      and (generos_intervinientes is not null or intervencion_personajes_femeninos is not null))
    then raise exception 'No se conserva el pendiente'; end if;
    update public.secuencias_metricas set intervencion_personajes_femeninos = 'exclusiva' where secuencia_id = v_id;
    if (select generos_intervinientes from public.secuencias_metricas where secuencia_id = v_id) is distinct from array['femenino']
    then raise exception 'Falla la escritura de compatibilidad'; end if;
    raise exception using errcode = 'PT001', message = 'Revertir exclusivamente los escenarios de prueba';
  exception when sqlstate 'PT001' then null;
  end;
end;
$pruebas$;

-- Regeneración atómica: ninguna ficha o comparativa publicada conserva el contrato anterior.
select public.recompute_all();

-- Toda secuencia publicada incluye el conjunto, también cuando está pendiente (JSON null).
do $$ begin
  if exists (select 1 from public.artefactos_publicos a
    cross join lateral jsonb_array_elements(a.payload #> '{ficha,metrica,secuencias}') s
    where a.tipo = 'obra_ficha' and not (s ? 'generos_intervinientes'))
  then raise exception 'Hay fichas publicadas sin géneros'; end if;
end $$;
commit;
