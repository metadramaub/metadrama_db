begin;

-- Los datos públicos dejan de modelarse como una tabla que crece una columna por cada uso.
-- Esta tabla es el almacén actual de artefactos JSON; sus claves son deliberadamente rutas para
-- que, cuando convenga, los mismos payloads puedan copiarse a R2 sin cambiar sus contratos.
create table public.artefactos_publicos (
	clave text primary key,
	tipo text not null check (tipo in (
		'obra_ficha', 'obra_analisis', 'obras_indice',
		'autor_ficha', 'autores_indice', 'corpus_comparativas'
	)),
	entidad_id uuid,
	alcance text not null default 'publico' check (alcance in ('publico', 'completo')),
	version_esquema integer not null check (version_esquema > 0),
	payload jsonb not null,
	sucio boolean not null default false,
	generado_en timestamptz not null default now(),
	constraint artefactos_publicos_clave_no_vacia check (btrim(clave) <> '')
);

comment on table public.artefactos_publicos is
	'Artefactos JSON públicos versionados. La clave coincide con su futura ruta de objeto; payload no se consulta como modelo relacional.';
comment on column public.artefactos_publicos.clave is
	'Ruta estable del artefacto, por ejemplo obras/<uuid>/analisis/publico.json.';
comment on column public.artefactos_publicos.sucio is
	'Hay cambios de origen posteriores a generado_en; el payload anterior se conserva hasta el siguiente recálculo.';

create index artefactos_publicos_tipo_alcance_idx
	on public.artefactos_publicos (tipo, alcance);
create index artefactos_publicos_entidad_idx
	on public.artefactos_publicos (entidad_id, tipo, alcance)
	where entidad_id is not null;

alter table public.artefactos_publicos enable row level security;

create policy artefactos_publicos_anon_select
	on public.artefactos_publicos for select to anon
	using (
		alcance = 'publico'
		and (
			tipo not in ('obra_ficha', 'obra_analisis')
			or (entidad_id is not null and public.obra_publica_visible(entidad_id))
		)
	);

create policy artefactos_publicos_auth_select
	on public.artefactos_publicos for select to authenticated
	using (
		public.auth_is_admin_or_ip()
		or (
			alcance = 'publico'
			and tipo in ('obra_ficha', 'obra_analisis')
			and entidad_id is not null
			and public.obra_publicada_asignada(entidad_id, auth.uid())
		)
		or (
			alcance = 'publico'
			and (
				tipo not in ('obra_ficha', 'obra_analisis')
				or (entidad_id is not null and public.obra_publica_visible(entidad_id))
			)
		)
	);

-- Solo las funciones productoras escriben. No se concede insert/update/delete a clientes.
grant select on public.artefactos_publicos to anon, authenticated;

create or replace function public.guardar_artefacto_publico(
	p_clave text,
	p_tipo text,
	p_entidad_id uuid,
	p_alcance text,
	p_payload jsonb,
	p_version_esquema integer default 1
)
returns void
language sql
security definer
set search_path = public
as $$
	insert into public.artefactos_publicos (
		clave, tipo, entidad_id, alcance, version_esquema, payload, sucio, generado_en
	) values (
		p_clave, p_tipo, p_entidad_id, p_alcance, p_version_esquema, p_payload, false, now()
	)
	on conflict (clave) do update set
		tipo = excluded.tipo,
		entidad_id = excluded.entidad_id,
		alcance = excluded.alcance,
		version_esquema = excluded.version_esquema,
		payload = excluded.payload,
		sucio = false,
		generado_en = now();
$$;

revoke all on function public.guardar_artefacto_publico(text, text, uuid, text, jsonb, integer)
	from public, anon, authenticated;
grant execute on function public.guardar_artefacto_publico(text, text, uuid, text, jsonb, integer)
	to service_role;

-- Proyección compacta para análisis. Conserva hechos normalizados por secuencia porque todavía no
-- sabemos todas las comparaciones futuras; omite prosa, comentarios y etiquetas duplicadas.
create or replace function public.analisis_obra_publico_json(p_obra_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
	v_ficha jsonb;
	v_secuencias jsonb;
	v_hechos jsonb;
	v_transiciones jsonb;
	v_fenomenos jsonb;
	v_total integer;
begin
	select r.ficha into v_ficha
	from public.obras_resumen r
	where r.obra_id = p_obra_id;

	if v_ficha is null then
		return null;
	end if;

	v_secuencias := coalesce(v_ficha #> '{metrica,secuencias}', '[]'::jsonb);
	v_total := jsonb_array_length(v_secuencias);

	select coalesce(jsonb_agg(
		jsonb_strip_nulls(jsonb_build_object(
			'id', s.value ->> 'secuencia_id',
			'i', (s.value ->> 'v_ini')::integer,
			'f', (s.value ->> 'v_fin')::integer,
			'n', (s.value ->> 'n_versos')::integer,
			'j', (s.value ->> 'jornada_num')::integer,
			'c', (s.value ->> 'cuadro_num')::integer,
			'forma', s.value ->> 'forma_slug',
			'arquitectura', s.value ->> 'arquitectura_slug',
			'versos_partidos', (s.value ->> 'versos_partidos')::boolean,
			'cambio_espacio', (s.value ->> 'inaugura_espacio')::boolean,
			'evento_sobrenatural', (s.value ->> 'evento_sobrenatural')::boolean,
			'intervencion_femenina', s.value ->> 'intervencion_personajes_femeninos',
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

	return jsonb_build_object(
		'schema_version', 1,
		'obra_id', p_obra_id,
		'total_secuencias', v_total,
		'total_transiciones', greatest(v_total - 1, 0),
		'secuencias', v_hechos,
		'transiciones', v_transiciones,
		'fenomenos', v_fenomenos
	);
end;
$$;

revoke all on function public.analisis_obra_publico_json(uuid) from public, anon, authenticated;
grant execute on function public.analisis_obra_publico_json(uuid) to service_role;

create or replace function public.recompute_artefactos_obra(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_ficha jsonb;
	v_analisis jsonb;
begin
	select ficha into v_ficha from public.obras_resumen where obra_id = p_obra_id;
	if v_ficha is null then
		raise exception 'La obra % no tiene ficha precomputada', p_obra_id;
	end if;

	v_analisis := public.analisis_obra_publico_json(p_obra_id);
	perform public.guardar_artefacto_publico(
		format('obras/%s/ficha/publico.json', p_obra_id),
		'obra_ficha', p_obra_id, 'publico',
		jsonb_build_object('schema_version', 1, 'ficha', v_ficha), 1
	);
	perform public.guardar_artefacto_publico(
		format('obras/%s/analisis/publico.json', p_obra_id),
		'obra_analisis', p_obra_id, 'publico', v_analisis, 1
	);
end;
$$;

-- Perfil de una obra o de uno de sus rangos, leído del artefacto compacto por secuencia.
-- El fallback solo cubre el despliegue inicial: desaparece del camino normal en cuanto todas las
-- obras publicadas han pasado una vez por la cola.
create or replace function public.perfil_artefacto_obra_rango(
	p_obra_id uuid,
	p_v_ini integer default null,
	p_v_fin integer default null,
	p_nivel text default 'forma'
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
	v_payload jsonb;
	v_perfil jsonb;
begin
	if p_nivel not in ('forma', 'arquitectura') then
		raise exception 'Nivel de perfil desconocido: %', p_nivel;
	end if;

	select payload into v_payload
	from public.artefactos_publicos
	where clave = format('obras/%s/analisis/publico.json', p_obra_id)
		and not sucio;

	if v_payload is null then
		if p_nivel = 'forma' then
			return public.perfil_formas_rango(p_obra_id, p_v_ini, p_v_fin);
		end if;
		return public.perfil_formas_hijos_rango(p_obra_id, p_v_ini, p_v_fin);
	end if;

	select coalesce(jsonb_object_agg(clave, versos), '{}'::jsonb)
	into v_perfil
	from (
		select
			case
				when p_nivel = 'forma' then s.value ->> 'forma'
				else concat_ws('/', s.value ->> 'forma', s.value ->> 'arquitectura')
			end as clave,
			sum(coalesce((s.value ->> 'n')::integer, 0))::integer as versos
		from jsonb_array_elements(coalesce(v_payload -> 'secuencias', '[]'::jsonb)) s(value)
		where (p_v_ini is null or (s.value ->> 'i')::integer >= p_v_ini)
			and (p_v_fin is null or (s.value ->> 'f')::integer <= p_v_fin)
			and s.value ->> 'forma' is not null
			and (p_nivel = 'forma' or s.value ->> 'arquitectura' is not null)
		group by 1
	) perfiles
	where clave is not null and clave <> '';

	return coalesce(v_perfil, '{}'::jsonb);
end;
$$;

revoke all on function public.perfil_artefacto_obra_rango(uuid, integer, integer, text)
	from public, anon, authenticated;
grant execute on function public.perfil_artefacto_obra_rango(uuid, integer, integer, text)
	to service_role;

-- El perfil de autor se compone con los artefactos de sus obras. La relación de autoría y los
-- límites de jornada siguen siendo relacionales; el contenido métrico ya no vuelve a las tablas
-- de anotación ni necesita cargar fichas completas.
create or replace function public.recompute_autor_resumen(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_alcance text;
	v_perfil jsonb;
	v_perfil_hijos jsonb;
	v_total integer;
	v_n_obras integer;
	v_n_jorn integer;
	v_ne_medio double precision;
	v_ne_agg double precision;
	v_n_units integer;
begin
	foreach v_alcance in array array['publico', 'completo'] loop
		with units as (
			select u.scope, u.obra_id, u.jornada_v_ini, u.jornada_v_fin
			from public.perfil_metrico_unidades() u
			where u.autor_id = p_autor_id
		), elig as (
			select un.*
			from units un
			join public.obras o on o.obra_id = un.obra_id
			join public.vocabularios v
				on v.termino_id = o.estado
				and v.categoria = 'estado'
				and lower(v.termino) = 'publicado'
			where v_alcance = 'completo' or coalesce(o.visible_publico, false)
		), unit_perfil as (
			select
				e.scope,
				public.perfil_artefacto_obra_rango(
					e.obra_id,
					case when e.scope = 'obra' then null else e.jornada_v_ini end,
					case when e.scope = 'obra' then null else e.jornada_v_fin end,
					'forma'
				) as perfil,
				public.perfil_artefacto_obra_rango(
					e.obra_id,
					case when e.scope = 'obra' then null else e.jornada_v_ini end,
					case when e.scope = 'obra' then null else e.jornada_v_fin end,
					'arquitectura'
				) as perfil_hijos,
				case when e.scope = 'obra' then r.numero_efectivo_formas else null end as ne_obra
			from elig e
			left join public.obras_resumen r on r.obra_id = e.obra_id
		), unit_calc as (
			select
				up.*,
				coalesce((select sum(value::integer) from jsonb_each_text(up.perfil)), 0) as versos
			from unit_perfil up
		), perfil_pairs as (
			select kv.key as forma, sum(kv.value::integer) as versos
			from unit_calc uc cross join lateral jsonb_each_text(uc.perfil) kv
			group by kv.key
		), perfil_pairs_hijos as (
			select kv.key as forma, sum(kv.value::integer) as versos
			from unit_calc uc cross join lateral jsonb_each_text(uc.perfil_hijos) kv
			group by kv.key
		), agg as (
			select
				coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_agg,
				coalesce(sum(versos), 0)::integer as total_versos
			from perfil_pairs
		), agg_hijos as (
			select coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_hijos_agg
			from perfil_pairs_hijos
		), counts as (
			select
				count(*) filter (where scope = 'obra')::integer as n_obras,
				count(*) filter (where scope = 'jornada')::integer as n_jorn,
				avg(ne_obra) filter (where scope = 'obra') as ne_medio,
				count(*)::integer as n_units
			from unit_calc
		)
		select
			a.perfil_agg, ah.perfil_hijos_agg, a.total_versos,
			c.n_obras, c.n_jorn, c.ne_medio, c.n_units
		into v_perfil, v_perfil_hijos, v_total, v_n_obras, v_n_jorn, v_ne_medio, v_n_units
		from agg a cross join agg_hijos ah cross join counts c;

		if coalesce(v_n_units, 0) = 0 then
			delete from public.autores_resumen
			where autor_id = p_autor_id and alcance = v_alcance;
		else
			v_ne_agg := public.numero_efectivo_from_perfil(v_perfil);

			insert into public.autores_resumen (
				autor_id, alcance,
				n_obras_completas, n_jornadas_sueltas, total_versos_autor,
				perfil_formas, perfil_formas_hijos,
				numero_efectivo_formas_medio, numero_efectivo_formas_agregado,
				metrica_sucia, actualizado_en
			) values (
				p_autor_id, v_alcance,
				coalesce(v_n_obras, 0), coalesce(v_n_jorn, 0), coalesce(v_total, 0),
				coalesce(v_perfil, '{}'::jsonb), coalesce(v_perfil_hijos, '{}'::jsonb),
				v_ne_medio, v_ne_agg, false, now()
			)
			on conflict (autor_id, alcance) do update set
				n_obras_completas = excluded.n_obras_completas,
				n_jornadas_sueltas = excluded.n_jornadas_sueltas,
				total_versos_autor = excluded.total_versos_autor,
				perfil_formas = excluded.perfil_formas,
				perfil_formas_hijos = excluded.perfil_formas_hijos,
				numero_efectivo_formas_medio = excluded.numero_efectivo_formas_medio,
				numero_efectivo_formas_agregado = excluded.numero_efectivo_formas_agregado,
				metrica_sucia = false,
				actualizado_en = now();
		end if;
	end loop;
end;
$$;

grant execute on function public.recompute_autor_resumen(uuid) to authenticated, service_role;

create or replace function public.autor_ficha_artefacto_json(
	p_autor_id uuid,
	p_alcance text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
	v_autor public.autores%rowtype;
	v_resumen public.autores_resumen%rowtype;
	v_publicado_id uuid;
	v_obras jsonb;
begin
	if p_alcance not in ('publico', 'completo') then
		raise exception 'Alcance desconocido: %', p_alcance;
	end if;

	select * into v_autor from public.autores where autor_id = p_autor_id;
	select * into v_resumen
	from public.autores_resumen
	where autor_id = p_autor_id and alcance = p_alcance;
	if v_autor.autor_id is null or v_resumen.autor_id is null then
		return null;
	end if;

	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	with autor_links as (
		select
			coalesce(g.obra_id, j.obra_id) as obra_id,
			a.perfil_metrico,
			coalesce(vc.termino, 'individual') as composicion_term,
			case when g.jornada_id is null then 'obra' else 'jornada' end as scope,
			j.jornada_num,
			(select count(*) from public.atribuciones a2
				where a2.grupo_atribucion_id = a.grupo_atribucion_id) as n_prop_grupo
		from public.atribucion_autores aa
		join public.atribuciones a on a.atribucion_id = aa.atribucion_id
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
		where aa.autor_id = p_autor_id
	), obras_elegibles as (
		select distinct al.obra_id
		from autor_links al
		join public.obras o on o.obra_id = al.obra_id
		where o.estado = v_publicado_id
			and (p_alcance = 'completo' or coalesce(o.visible_publico, false))
	), perfil_obras as (
		select distinct u.obra_id
		from public.perfil_metrico_unidades() u
		where u.autor_id = p_autor_id
	), items as (
		select
			o.fecha_inicio_trad as sort_fecha,
			lower(o.titulo) as sort_titulo,
			jsonb_build_object(
				'obra_id', o.obra_id,
				'slug', o.slug,
				'titulo', o.titulo,
				'genero_term', (select vg.termino from public.vocabularios vg
					where vg.termino_id = o.genero_id limit 1),
				'fecha_inicio_trad', o.fecha_inicio_trad,
				'fecha_fin_trad', o.fecha_fin_trad,
				'total_versos', coalesce(r.total_versos, o.total_versos),
				'visible_publico', coalesce(o.visible_publico, false),
				'tramos', coalesce(r.tramos, '[]'::jsonb),
				'jornadas_tramos', coalesce(r.jornadas_tramos, '[]'::jsonb),
				'cuadros_tramos', coalesce(r.cuadros_tramos, '[]'::jsonb),
				'numero_efectivo_formas', r.numero_efectivo_formas,
				'densidad_transiciones', r.densidad_transiciones,
				'n_formas_distintas', r.n_formas_distintas,
				'sostiene_perfil', po.obra_id is not null,
				'vinculos', (
					select coalesce(jsonb_agg(distinct jsonb_build_object(
						'scope', al.scope,
						'jornada_num', al.jornada_num,
						'composicion_term', al.composicion_term,
						'perfil_metrico', al.perfil_metrico,
						'unica_propuesta', al.n_prop_grupo = 1
					)), '[]'::jsonb)
					from autor_links al where al.obra_id = o.obra_id
				)
			) as item
		from obras_elegibles oe
		join public.obras o on o.obra_id = oe.obra_id
		left join public.obras_resumen r on r.obra_id = o.obra_id
		left join perfil_obras po on po.obra_id = o.obra_id
	)
	select coalesce(jsonb_agg(item order by sort_fecha nulls last, sort_titulo), '[]'::jsonb)
	into v_obras
	from items;

	return jsonb_build_object(
		'schema_version', 1,
		'alcance', p_alcance,
		'autor', jsonb_build_object(
			'autor_id', v_autor.autor_id,
			'slug', v_autor.slug,
			'nombre_completo', v_autor.nombre_completo,
			'variantes_nombre', coalesce(v_autor.variantes_nombre, array[]::text[]),
			'viaf_id', v_autor.viaf_id,
			'wikidata_id', v_autor.wikidata_id,
			'bnedatos_id', v_autor.bnedatos_id
		),
		'obras', v_obras,
		'resumen', jsonb_build_object(
			'n_obras_completas', v_resumen.n_obras_completas,
			'n_jornadas_sueltas', v_resumen.n_jornadas_sueltas,
			'total_versos_autor', v_resumen.total_versos_autor,
			'perfil_formas', v_resumen.perfil_formas,
			'perfil_formas_hijos', v_resumen.perfil_formas_hijos,
			'numero_efectivo_formas_medio', v_resumen.numero_efectivo_formas_medio,
			'numero_efectivo_formas_agregado', v_resumen.numero_efectivo_formas_agregado
		)
	);
end;
$$;

create or replace function public.recompute_artefactos_autor(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_alcance text;
	v_payload jsonb;
begin
	foreach v_alcance in array array['publico', 'completo'] loop
		v_payload := public.autor_ficha_artefacto_json(p_autor_id, v_alcance);
		if v_payload is not null then
			perform public.guardar_artefacto_publico(
				format('autores/%s/ficha/%s.json', p_autor_id, v_alcance),
				'autor_ficha', p_autor_id, v_alcance, v_payload, 1
			);
		end if;
	end loop;
end;
$$;

create or replace function public.recompute_artefactos_globales()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_alcance text;
	v_publicado_id uuid;
	v_obras jsonb;
	v_autores jsonb;
	v_comparativas jsonb;
begin
	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	foreach v_alcance in array array['publico', 'completo'] loop
		select coalesce(jsonb_agg(jsonb_build_object(
			'obra_id', o.obra_id,
			'slug', o.slug,
			'titulo', o.titulo,
			'fecha_inicio_trad', o.fecha_inicio_trad,
			'fecha_fin_trad', o.fecha_fin_trad,
			'fecha_inicio_metadrama', o.fecha_inicio_metadrama,
			'fecha_fin_metadrama', o.fecha_fin_metadrama,
			'total_versos', o.total_versos,
			'genero_id', o.genero_id,
			'updated_at', o.updated_at,
			'visible_publico', o.visible_publico,
			'autores', coalesce(r.autores, array[]::text[]),
			'tramos', coalesce(r.tramos, '[]'::jsonb),
			'jornadas_tramos', coalesce(r.jornadas_tramos, '[]'::jsonb),
			'cuadros_tramos', coalesce(r.cuadros_tramos, '[]'::jsonb),
			'numero_efectivo_formas', r.numero_efectivo_formas,
			'densidad_transiciones', r.densidad_transiciones,
			'n_formas_distintas', r.n_formas_distintas,
			'formas_presentes', coalesce(r.formas_presentes, array[]::text[]),
			'metros_presentes', coalesce(r.metros_presentes, array[]::text[]),
			'tipos_forma_presentes', coalesce(r.tipos_forma_presentes, array[]::text[]),
			'variaciones_presentes', coalesce(r.variaciones_presentes, array[]::text[]),
			'subtipos_presentes', coalesce(r.subtipos_presentes, array[]::text[])
		) order by lower(o.titulo), o.obra_id), '[]'::jsonb)
		into v_obras
		from public.obras o
		join public.obras_resumen r on r.obra_id = o.obra_id
		where o.estado = v_publicado_id
			and (v_alcance = 'completo' or coalesce(o.visible_publico, false));

		perform public.guardar_artefacto_publico(
			format('indices/obras/%s.json', v_alcance),
			'obras_indice', null, v_alcance,
			jsonb_build_object('schema_version', 1, 'alcance', v_alcance, 'obras', v_obras), 1
		);

		select coalesce(jsonb_agg(jsonb_build_object(
			'autor_id', a.autor_id,
			'slug', a.slug,
			'nombre_completo', a.nombre_completo,
			'wikidata_id', a.wikidata_id,
			'total_versos_autor', (ar.payload #>> '{resumen,total_versos_autor}')::integer,
			'n_obras_completas', (ar.payload #>> '{resumen,n_obras_completas}')::integer,
			'n_jornadas_sueltas', (ar.payload #>> '{resumen,n_jornadas_sueltas}')::integer,
			'numero_efectivo_formas_agregado',
				(ar.payload #>> '{resumen,numero_efectivo_formas_agregado}')::double precision,
			'perfil_formas', coalesce(ar.payload #> '{resumen,perfil_formas}', '{}'::jsonb),
			'top_obras', (
				select coalesce(jsonb_agg(jsonb_build_object(
					'slug', top_obra.value ->> 'slug',
					'titulo', top_obra.value ->> 'titulo',
					'total_versos', (top_obra.value ->> 'total_versos')::integer
				) order by (top_obra.value ->> 'total_versos')::integer desc nulls last,
					top_obra.value ->> 'titulo'), '[]'::jsonb)
				from (
					select obra.value
					from jsonb_array_elements(coalesce(ar.payload -> 'obras', '[]'::jsonb)) obra(value)
					where (obra.value ->> 'sostiene_perfil')::boolean
					order by (obra.value ->> 'total_versos')::integer desc nulls last,
						obra.value ->> 'titulo'
					limit 5
				) top_obra
			)
		) order by lower(a.nombre_completo), a.autor_id), '[]'::jsonb)
		into v_autores
		from public.autores a
		join public.artefactos_publicos ar
			on ar.entidad_id = a.autor_id
			and ar.tipo = 'autor_ficha'
			and ar.alcance = v_alcance
			and not ar.sucio;

		perform public.guardar_artefacto_publico(
			format('indices/autores/%s.json', v_alcance),
			'autores_indice', null, v_alcance,
			jsonb_build_object('schema_version', 1, 'alcance', v_alcance, 'autores', v_autores), 1
		);

		with obras_elegibles as (
			select ap.payload
			from public.artefactos_publicos ap
			join public.obras o on o.obra_id = ap.entidad_id
			where ap.tipo = 'obra_analisis'
				and ap.alcance = 'publico'
				and not ap.sucio
				and o.estado = v_publicado_id
				and (v_alcance = 'completo' or coalesce(o.visible_publico, false))
		), universo as (
			select count(*)::integer as n from obras_elegibles
		), pares_transiciones as (
			select
				t.value ->> 'de' as de,
				t.value ->> 'a' as a
			from obras_elegibles o
			cross join lateral jsonb_array_elements(coalesce(o.payload -> 'transiciones', '[]'::jsonb)) t(value)
			group by t.value ->> 'de', t.value ->> 'a'
		), valores_transiciones as (
			select
				p.de,
				p.a,
				coalesce((
					select (t.value ->> 'veces')::integer
					from jsonb_array_elements(coalesce(o.payload -> 'transiciones', '[]'::jsonb)) t(value)
					where t.value ->> 'de' = p.de and t.value ->> 'a' = p.a
					limit 1
				), 0) as veces
			from pares_transiciones p cross join obras_elegibles o
		), transiciones as (
			select
				de,
				a,
				count(*) filter (where veces > 0)::integer as obras_con,
				sum(veces)::integer as ocurrencias,
				avg(veces) as media,
				percentile_cont(0.25) within group (order by veces) as q1,
				percentile_cont(0.5) within group (order by veces) as mediana,
				percentile_cont(0.75) within group (order by veces) as q3,
				max(veces)::integer as maximo
			from valores_transiciones
			group by de, a
		), transiciones_json as (
			select coalesce(jsonb_agg(jsonb_build_object(
				'de', t.de,
				'a', t.a,
				'obras_con_transicion', t.obras_con,
				'obras_analizables', u.n,
				'proporcion_obras', case when u.n > 0 then t.obras_con::numeric / u.n else null end,
				'ocurrencias_totales', t.ocurrencias,
				'media_ocurrencias', t.media,
				'q1_ocurrencias', t.q1,
				'mediana_ocurrencias', t.mediana,
				'q3_ocurrencias', t.q3,
				'maximo_ocurrencias', t.maximo
			) order by t.obras_con desc, t.de, t.a), '[]'::jsonb) as valor
			from transiciones t cross join universo u
		), valores_fenomenos as (
			select
				f.key as fenomeno,
				(f.value ->> 'proporcion')::numeric as proporcion
			from obras_elegibles o
			cross join lateral jsonb_each(coalesce(o.payload -> 'fenomenos', '{}'::jsonb)) f
			where (f.value ->> 'total_respondidas')::integer > 0
		), fenomenos as (
			select
				fenomeno,
				count(*)::integer as obras_analizables,
				avg(proporcion) as media,
				percentile_cont(0.25) within group (order by proporcion) as q1,
				percentile_cont(0.5) within group (order by proporcion) as mediana,
				percentile_cont(0.75) within group (order by proporcion) as q3,
				min(proporcion) as minimo,
				max(proporcion) as maximo
			from valores_fenomenos
			group by fenomeno
		), fenomenos_json as (
			select coalesce(jsonb_object_agg(fenomeno, jsonb_build_object(
				'obras_analizables', obras_analizables,
				'media', media,
				'q1', q1,
				'mediana', mediana,
				'q3', q3,
				'minimo', minimo,
				'maximo', maximo
			)), '{}'::jsonb) as valor
			from fenomenos
		)
		select jsonb_build_object(
			'schema_version', 1,
			'alcance', v_alcance,
			'obras_analizables', u.n,
			'transiciones', tj.valor,
			'fenomenos', fj.valor
		)
		into v_comparativas
		from universo u cross join transiciones_json tj cross join fenomenos_json fj;

		perform public.guardar_artefacto_publico(
			format('corpus/comparativas/%s.json', v_alcance),
			'corpus_comparativas', null, v_alcance, v_comparativas, 1
		);
	end loop;
end;
$$;

-- El botón de una obra conserva su nombre y permiso, pero ahora actualiza todo el grafo derivado.
create or replace function public.recompute_obra_y_autores(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_autor uuid;
begin
	perform public.recompute_obra_resumen(p_obra_id);
	perform public.recompute_artefactos_obra(p_obra_id);

	for v_autor in
		select distinct u.autor_id
		from public.perfil_metrico_unidades() u
		where u.obra_id = p_obra_id and u.autor_id is not null
	loop
		perform public.recompute_autor_resumen(v_autor);
		perform public.recompute_artefactos_autor(v_autor);
	end loop;

	perform public.recompute_artefactos_globales();
end;
$$;

-- El cierre de la cola materializa artefactos después de que la interfaz haya recalculado las obras
-- y los autores uno a uno. Así no se repite el trabajo pesado y el último paso sí es atómico.
create or replace function public.finalizar_recompute_datos_publicos()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
	v_eliminados integer;
	v_id uuid;
	v_publicado_id uuid;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden finalizar el recálculo público' using errcode = '42501';
	end if;

	delete from public.autores_resumen resumen
	where not exists (
		select 1 from public.perfil_metrico_unidades() unidad
		where unidad.autor_id = resumen.autor_id
	);
	get diagnostics v_eliminados = row_count;

	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	for v_id in select obra_id from public.obras where estado = v_publicado_id loop
		perform public.recompute_artefactos_obra(v_id);
	end loop;
	for v_id in select distinct autor_id from public.autores_resumen loop
		perform public.recompute_artefactos_autor(v_id);
	end loop;

	delete from public.artefactos_publicos ap
	where ap.tipo in ('obra_ficha', 'obra_analisis')
		and not exists (select 1 from public.obras o where o.obra_id = ap.entidad_id and o.estado = v_publicado_id);
	delete from public.artefactos_publicos ap
	where ap.tipo = 'autor_ficha'
		and not exists (select 1 from public.autores_resumen ar where ar.autor_id = ap.entidad_id and ar.alcance = ap.alcance);

	perform public.recompute_artefactos_globales();
	return v_eliminados;
end;
$$;

-- Los cambios de origen no borran la versión servible: la marcan como anterior hasta el recompute.
create or replace function public.marcar_artefactos_obra_sucios()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.metrica_sucia then
		update public.artefactos_publicos set sucio = true
		where entidad_id = new.obra_id and tipo in ('obra_ficha', 'obra_analisis');
		update public.artefactos_publicos set sucio = true
		where tipo in ('obras_indice', 'autores_indice', 'corpus_comparativas');
	end if;
	return new;
end;
$$;

drop trigger if exists trg_marcar_artefactos_obra_sucios on public.obras_resumen;
create trigger trg_marcar_artefactos_obra_sucios
	after insert or update on public.obras_resumen
	for each row execute function public.marcar_artefactos_obra_sucios();

create or replace function public.marcar_artefactos_autor_sucios()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.metrica_sucia then
		update public.artefactos_publicos set sucio = true
		where entidad_id = new.autor_id and tipo = 'autor_ficha';
		update public.artefactos_publicos set sucio = true where tipo = 'autores_indice';
	end if;
	return new;
end;
$$;

drop trigger if exists trg_marcar_artefactos_autor_sucios on public.autores_resumen;
create trigger trg_marcar_artefactos_autor_sucios
	after insert or update on public.autores_resumen
	for each row execute function public.marcar_artefactos_autor_sucios();

-- Pasos pequeños de la cola HTTP. Mantienen cada petición acotada, pero producen el JSON de esa
-- entidad en el mismo paso para que los autores posteriores ya agreguen desde artefactos.
create or replace function public.recompute_obra_artefactos_global(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden recalcular artefactos globales' using errcode = '42501';
	end if;
	perform public.recompute_obra_resumen(p_obra_id);
	perform public.recompute_artefactos_obra(p_obra_id);
end;
$$;

create or replace function public.recompute_autor_artefactos_global(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden recalcular artefactos globales' using errcode = '42501';
	end if;
	perform public.recompute_autor_resumen(p_autor_id);
	perform public.recompute_artefactos_autor(p_autor_id);
end;
$$;

-- Mantenimiento SQL completo con el mismo resultado que la cola de la interfaz.
create or replace function public.recompute_all()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_obra_id uuid;
	v_autor_id uuid;
	v_publicado_id uuid;
begin
	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then raise exception 'No existe estado=publicado en vocabularios'; end if;

	for v_obra_id in select obra_id from public.obras where estado = v_publicado_id loop
		perform public.recompute_obra_resumen(v_obra_id);
		perform public.recompute_artefactos_obra(v_obra_id);
	end loop;
	for v_autor_id in select distinct autor_id from public.perfil_metrico_unidades() where autor_id is not null loop
		perform public.recompute_autor_resumen(v_autor_id);
		perform public.recompute_artefactos_autor(v_autor_id);
	end loop;
	delete from public.autores_resumen ar
	where not exists (select 1 from public.perfil_metrico_unidades() u where u.autor_id = ar.autor_id);
	perform public.recompute_artefactos_globales();
end;
$$;

revoke execute on function public.recompute_all() from public, anon, authenticated;
grant execute on function public.recompute_all() to service_role;
grant execute on function public.recompute_obra_y_autores(uuid) to authenticated, service_role;
grant execute on function public.recompute_artefactos_obra(uuid) to service_role;
grant execute on function public.recompute_artefactos_autor(uuid) to service_role;
grant execute on function public.recompute_artefactos_globales() to service_role;
revoke all on function public.recompute_obra_artefactos_global(uuid) from public, anon;
revoke all on function public.recompute_autor_artefactos_global(uuid) from public, anon;
grant execute on function public.recompute_obra_artefactos_global(uuid) to authenticated, service_role;
grant execute on function public.recompute_autor_artefactos_global(uuid) to authenticated, service_role;
revoke all on function public.autor_ficha_artefacto_json(uuid, text)
	from public, anon, authenticated;
grant execute on function public.autor_ficha_artefacto_json(uuid, text) to service_role;

commit;
