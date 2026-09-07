-- Lo que no hay en la obra no se pregunta en cada secuencia
--
-- Cada secuencia declara si en ella intervienen figuras de donaire y personajes sobrenaturales. En
-- una comedia sin figura del donaire eso son cuarenta y seis veces «sin intervención», una por
-- secuencia, para decir algo que se sabe de la obra entera: que no la hay. Y mientras no se
-- respondan, la checklist de revisión las cuenta como trabajo pendiente.
--
-- **La obra lo declara una vez.** Tres preguntas nuevas en sus datos —si hay figuras de donaire, si
-- hay personajes sobrenaturales y si hay eventos sobrenaturales—, y cuando la respuesta es que no,
-- sus secuencias quedan respondidas y bloqueadas, con el aviso de dónde se cambia.
--
-- **El evento sobrenatural es nuevo y no es lo mismo que el personaje.** Un milagro, una aparición
-- o una transformación ocurren aunque no hable nadie sobrenatural, y hasta hoy no había dónde
-- anotarlo. Se responde sí o no, como «versos partidos»: la escala de intervención —exclusiva,
-- compartida— es de quien habla, y un evento no habla.
--
-- **Los personajes femeninos no entran aquí.** Se dan por presentes en toda obra del corpus, así
-- que su pregunta sigue siendo de cada secuencia y no se declara arriba.
--
-- **La declaración de la obra se siembra de lo anotado**, que es lo que evita volver sobre obras
-- terminadas: hay donaire en 6 obras y personajes sobrenaturales en 3, de las 12 que tienen
-- secuencias. Donde alguna secuencia lo declara, la obra dice que sí; donde todas dicen que no,
-- dice que no; donde queda alguna sin responder, la obra se queda sin responder, porque de un hueco
-- no se deduce una ausencia.
--
-- **Y la coherencia no se deja a la pantalla.** Dos disparadores la sostienen en la base: una
-- secuencia no puede declarar lo que su obra niega, y una obra no puede negar lo que alguna de sus
-- secuencias declara. Al negar, la obra responde por las secuencias que aún no lo habían hecho.

begin;

-- ---------------------------------------------------------------------------
-- Las columnas
-- ---------------------------------------------------------------------------

alter table public.obras
	add column if not exists tiene_figuras_donaire boolean,
	add column if not exists tiene_personajes_sobrenaturales boolean,
	add column if not exists tiene_eventos_sobrenaturales boolean;

comment on column public.obras.tiene_figuras_donaire is
	'Si en la obra hay figuras de donaire. En falso, ninguna secuencia puede declarar su intervención.';
comment on column public.obras.tiene_personajes_sobrenaturales is
	'Si en la obra hay personajes sobrenaturales: alegóricos, magos, santos que obran milagros, apariciones.';
comment on column public.obras.tiene_eventos_sobrenaturales is
	'Si en la obra ocurren eventos sobrenaturales, hable o no un personaje sobrenatural.';

alter table public.secuencias_metricas
	add column if not exists evento_sobrenatural boolean;

comment on column public.secuencias_metricas.evento_sobrenatural is
	'Si en esta secuencia ocurre un evento sobrenatural. Ocurre o no ocurre: no lleva la escala de intervención, que es de quien habla.';

-- ---------------------------------------------------------------------------
-- La siembra
-- ---------------------------------------------------------------------------

do $siembra$
declare
	v_si integer;
	v_no integer;
begin
	update public.obras o
	set tiene_figuras_donaire = case
			when exists (
				select 1 from public.secuencias_metricas sm
				where sm.obra_id = o.obra_id
				  and sm.intervencion_figuras_donaire in ('exclusiva', 'compartida')
			) then true
			when exists (select 1 from public.secuencias_metricas sm where sm.obra_id = o.obra_id)
			 and not exists (
				select 1 from public.secuencias_metricas sm
				where sm.obra_id = o.obra_id and sm.intervencion_figuras_donaire is null
			) then false
			else null
		end,
		tiene_personajes_sobrenaturales = case
			when exists (
				select 1 from public.secuencias_metricas sm
				where sm.obra_id = o.obra_id
				  and sm.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida')
			) then true
			when exists (select 1 from public.secuencias_metricas sm where sm.obra_id = o.obra_id)
			 and not exists (
				select 1 from public.secuencias_metricas sm
				where sm.obra_id = o.obra_id and sm.intervencion_personajes_sobrenaturales is null
			) then false
			else null
		end;

	select
		count(*) filter (where tiene_figuras_donaire),
		count(*) filter (where tiene_figuras_donaire = false)
	into v_si, v_no
	from public.obras;
	raise notice 'Donaire declarado: % obras con, % sin', v_si, v_no;

	select
		count(*) filter (where tiene_personajes_sobrenaturales),
		count(*) filter (where tiene_personajes_sobrenaturales = false)
	into v_si, v_no
	from public.obras;
	raise notice 'Sobrenaturales declarados: % obras con, % sin', v_si, v_no;
end
$siembra$;

-- ---------------------------------------------------------------------------
-- La coherencia, sostenida por la base
-- ---------------------------------------------------------------------------

create or replace function public.secuencia_respeta_lo_declarado_en_la_obra()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_obra public.obras%rowtype;
begin
	select * into v_obra from public.obras where obra_id = new.obra_id;
	if not found then
		return new;
	end if;

	if v_obra.tiene_figuras_donaire = false
	   and new.intervencion_figuras_donaire in ('exclusiva', 'compartida') then
		raise exception 'La obra declara que no tiene figuras de donaire: cámbialo en los datos de la obra antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.tiene_personajes_sobrenaturales = false
	   and new.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida') then
		raise exception 'La obra declara que no tiene personajes sobrenaturales: cámbialo en los datos de la obra antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.tiene_eventos_sobrenaturales = false and new.evento_sobrenatural then
		raise exception 'La obra declara que no tiene eventos sobrenaturales: cámbialo en los datos de la obra antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	return new;
end
$function$;

drop trigger if exists secuencias_respetan_lo_declarado on public.secuencias_metricas;
create trigger secuencias_respetan_lo_declarado
	before insert or update of
		intervencion_figuras_donaire,
		intervencion_personajes_sobrenaturales,
		evento_sobrenatural,
		obra_id
	on public.secuencias_metricas
	for each row
	execute function public.secuencia_respeta_lo_declarado_en_la_obra();

create or replace function public.obra_declara_por_sus_secuencias()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
	-- **Negar es responder por las secuencias que callaban**, no borrar lo que dicen. Por eso
	-- primero se comprueba que ninguna diga lo contrario, y solo entonces se rellenan los huecos.
	if new.tiene_figuras_donaire = false then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id
			  and sm.intervencion_figuras_donaire in ('exclusiva', 'compartida')
		) then
			raise exception 'Alguna secuencia declara la intervención de una figura de donaire: quítala antes de decir que la obra no las tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set intervencion_figuras_donaire = 'sin_intervencion'
		where obra_id = new.obra_id and intervencion_figuras_donaire is null;
	end if;

	if new.tiene_personajes_sobrenaturales = false then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id
			  and sm.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida')
		) then
			raise exception 'Alguna secuencia declara la intervención de un personaje sobrenatural: quítala antes de decir que la obra no los tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set intervencion_personajes_sobrenaturales = 'sin_intervencion'
		where obra_id = new.obra_id and intervencion_personajes_sobrenaturales is null;
	end if;

	if new.tiene_eventos_sobrenaturales = false then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id and sm.evento_sobrenatural
		) then
			raise exception 'Alguna secuencia declara un evento sobrenatural: quítalo antes de decir que la obra no los tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set evento_sobrenatural = false
		where obra_id = new.obra_id and evento_sobrenatural is null;
	end if;

	return new;
end
$function$;

drop trigger if exists obras_declaran_por_sus_secuencias on public.obras;
create trigger obras_declaran_por_sus_secuencias
	after update of
		tiene_figuras_donaire,
		tiene_personajes_sobrenaturales,
		tiene_eventos_sobrenaturales
	on public.obras
	for each row
	execute function public.obra_declara_por_sus_secuencias();

-- La siembra no deja obras en falso con secuencias en nulo —solo dice que no cuando ninguna estaba
-- sin responder—, pero de ahora en adelante quien lo garantiza es el disparador, y conviene que la
-- base quede como quedará siempre.
update public.secuencias_metricas sm
set intervencion_figuras_donaire = 'sin_intervencion'
from public.obras o
where o.obra_id = sm.obra_id
  and o.tiene_figuras_donaire = false
  and sm.intervencion_figuras_donaire is null;

update public.secuencias_metricas sm
set intervencion_personajes_sobrenaturales = 'sin_intervencion'
from public.obras o
where o.obra_id = sm.obra_id
  and o.tiene_personajes_sobrenaturales = false
  and sm.intervencion_personajes_sobrenaturales is null;

-- ---------------------------------------------------------------------------
-- La ficha publica el evento
--
-- Es el cuerpo que hoy está en producción, con una clave más. Nada más cambia.
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
-- La guarda ejecuta lo que toca
--
-- Un disparador no está probado hasta que se le hace saltar, y una función no está probada hasta
-- que se ejecuta. Así que aquí se intenta de verdad lo que tiene que estar prohibido, se comprueba
-- que la obra responde por sus secuencias al negar, y se llama a la ficha. Todo lo que se escribe
-- para probar se deshace: cada intento vive en su propio bloque y sale por una excepción.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_admin uuid;
	v_obra uuid;
	v_secuencia uuid;
	v_salto boolean;
	v_sin_responder integer;
	v_ficha jsonb;
begin
	-- 1 · Una secuencia no puede declarar lo que su obra niega.
	select o.obra_id, sm.secuencia_id
	into v_obra, v_secuencia
	from public.obras o
	join public.secuencias_metricas sm on sm.obra_id = o.obra_id
	where o.tiene_figuras_donaire = false
	limit 1;

	if v_secuencia is not null then
		v_salto := false;
		begin
			update public.secuencias_metricas
			set intervencion_figuras_donaire = 'exclusiva'
			where secuencia_id = v_secuencia;
			raise exception 'NO_SALTO';
		exception
			when check_violation then v_salto := true;
			when raise_exception then v_salto := false;
		end;
		if not v_salto then
			raise exception 'Una secuencia pudo declarar donaire en una obra que dice no tenerlo.';
		end if;
	else
		raise notice 'Ninguna obra niega el donaire con secuencias: el disparador de la secuencia no se prueba aquí.';
	end if;

	-- 2 · Una obra no puede negar lo que alguna de sus secuencias declara.
	select o.obra_id into v_obra
	from public.obras o
	where exists (
		select 1 from public.secuencias_metricas sm
		where sm.obra_id = o.obra_id
		  and sm.intervencion_figuras_donaire in ('exclusiva', 'compartida')
	)
	limit 1;

	if v_obra is not null then
		v_salto := false;
		begin
			update public.obras set tiene_figuras_donaire = false where obra_id = v_obra;
			raise exception 'NO_SALTO';
		exception
			when check_violation then v_salto := true;
			when raise_exception then v_salto := false;
		end;
		if not v_salto then
			raise exception 'Una obra pudo negar el donaire que alguna de sus secuencias declara.';
		end if;
	else
		raise notice 'Ninguna obra declara donaire: el disparador de la obra no se prueba aquí.';
	end if;

	-- 3 · Al negar, la obra responde por las secuencias que callaban.
	select o.obra_id into v_obra
	from public.obras o
	where exists (
		select 1 from public.secuencias_metricas sm
		where sm.obra_id = o.obra_id and sm.evento_sobrenatural is null
	)
	limit 1;

	if v_obra is not null then
		begin
			update public.obras set tiene_eventos_sobrenaturales = false where obra_id = v_obra;

			select count(*) into v_sin_responder
			from public.secuencias_metricas
			where obra_id = v_obra and evento_sobrenatural is null;

			if v_sin_responder > 0 then
				raise exception 'La obra % negó los eventos y % secuencias siguen sin responder', v_obra, v_sin_responder;
			end if;

			raise exception 'NO_SALTO';
		exception
			when raise_exception then
				if sqlerrm <> 'NO_SALTO' then
					raise;
				end if;
		end;
	end if;

	-- 4 · La ficha publica el evento. Con la identidad de un admin: sin ella devuelve nulo.
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
	limit 1;

	if v_admin is null then
		raise notice 'No hay ningún admin: la ficha no se comprueba aquí.';
		return;
	end if;

	perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

	select sm.obra_id into v_obra
	from public.secuencias_metricas sm
	where public.can_view_obra_ficha_publica(sm.obra_id, true)
	limit 1;

	if v_obra is null then
		raise notice 'Ninguna obra visible con secuencias: la ficha no se comprueba aquí.';
		perform set_config('request.jwt.claims', '', true);
		return;
	end if;

	v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);

	if v_ficha is null then
		raise exception 'La ficha de la obra % devolvió nulo', v_obra;
	end if;

	if not exists (
		select 1
		from jsonb_array_elements(v_ficha -> 'metrica' -> 'secuencias') sec
		where sec ? 'evento_sobrenatural'
	) then
		raise exception 'La ficha no publica evento_sobrenatural.';
	end if;

	perform set_config('request.jwt.claims', '', true);
	raise notice 'Disparadores probados y ficha comprobada sobre la obra %', v_obra;
end
$guarda$;

commit;
