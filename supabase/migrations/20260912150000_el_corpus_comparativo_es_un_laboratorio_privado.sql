begin;

-- El universo que se compara puede ser el corpus público, pero el documento completo no es una
-- API pública: contiene una matriz por obra pensada para explorar medidas en el laboratorio. La
-- ficha recibirá más adelante una proyección pequeña y explícita de las comparaciones aprobadas.
drop policy if exists artefactos_publicos_anon_select on public.artefactos_publicos;
create policy artefactos_publicos_anon_select
	on public.artefactos_publicos for select to anon
	using (
		alcance = 'publico'
		and tipo <> 'corpus_comparativas'
		and (
			tipo not in ('obra_ficha', 'obra_analisis')
			or (entidad_id is not null and public.obra_publica_visible(entidad_id))
		)
	);

drop policy if exists artefactos_publicos_auth_select on public.artefactos_publicos;
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
			and tipo <> 'corpus_comparativas'
			and (
				tipo not in ('obra_ficha', 'obra_analisis')
				or (entidad_id is not null and public.obra_publica_visible(entidad_id))
			)
		)
	);

comment on table public.artefactos_publicos is
	'Artefactos JSON versionados. Los de zona pública son legibles según RLS; corpus_comparativas es un banco de trabajo privado aunque su alcance pueda ser publico.';

-- Una forma común de describir cualquier distribución evita que cada gráfico invente nombres o
-- percentiles distintos. Los NULL no forman parte de la muestra y n lo deja visible.
create or replace function public.resumen_estadistico_json(p_valores numeric[])
returns jsonb
language sql
immutable
set search_path = public
as $$
	select jsonb_build_object(
		'n', count(v)::integer,
		'media', avg(v),
		'q1', percentile_cont(0.25) within group (order by v),
		'mediana', percentile_cont(0.5) within group (order by v),
		'q3', percentile_cont(0.75) within group (order by v),
		'minimo', min(v),
		'maximo', max(v)
	)
	from unnest(coalesce(p_valores, array[]::numeric[])) valores(v)
	where v is not null;
$$;

revoke all on function public.resumen_estadistico_json(numeric[])
	from public, anon, authenticated;
grant execute on function public.resumen_estadistico_json(numeric[]) to service_role;

-- V2 conserva hechos compactos que ya estaban en la ficha y añade solo agregados estables. No
-- copia títulos ni prosa. Eso permite ensayar comparaciones nuevas sin ensanchar obras_resumen.
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
		'obra_analisis', p_obra_id, 'publico', v_analisis, 2
	);
end;
$$;

-- El documento grande conserva los valores por obra para que el laboratorio pueda formular una
-- pregunta nueva sin otra extracción. Los agregados evitan recalcular cuartiles en cada vista.
create or replace function public.corpus_comparativas_artefacto_json(p_alcance text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
	v_resultado jsonb;
begin
	if p_alcance not in ('publico', 'completo') then
		raise exception 'Alcance de comparativas desconocido: %', p_alcance;
	end if;

	with indice as (
		select coalesce(payload -> 'obras', '[]'::jsonb) as obras
		from public.artefactos_publicos
		where clave = format('indices/obras/%s.json', p_alcance) and not sucio
	), metadatos as (
		select item.value
		from indice i cross join lateral jsonb_array_elements(i.obras) item(value)
	), obras as (
		select
			ap.entidad_id as obra_id,
			ap.payload as analisis,
			m.value as meta
		from public.artefactos_publicos ap
		join metadatos m on m.value ->> 'obra_id' = ap.entidad_id::text
		where ap.tipo = 'obra_analisis'
			and ap.alcance = 'publico'
			and not ap.sucio
			and ap.version_esquema >= 2
	), universo as (
		select count(*)::integer as n from obras
	), filas_obras as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'obra_id', obra_id,
			'slug', meta ->> 'slug',
			'titulo', meta ->> 'titulo',
			'fecha_inicio_trad', (meta ->> 'fecha_inicio_trad')::integer,
			'fecha_fin_trad', (meta ->> 'fecha_fin_trad')::integer,
			'fecha_inicio_metadrama', (meta ->> 'fecha_inicio_metadrama')::integer,
			'fecha_fin_metadrama', (meta ->> 'fecha_fin_metadrama')::integer,
			'genero_id', meta ->> 'genero_id',
			'visible_publico', coalesce((meta ->> 'visible_publico')::boolean, false),
			'autores', coalesce(meta -> 'autores', '[]'::jsonb),
			'metricas', coalesce(analisis -> 'metricas', '{}'::jsonb),
			'perfil_formas', coalesce(analisis -> 'perfil_formas', '{}'::jsonb),
			'articulacion', coalesce(analisis -> 'articulacion', '{}'::jsonb),
			'enunciacion', coalesce(analisis -> 'enunciacion', '{}'::jsonb),
			'fenomenos', coalesce(analisis -> 'fenomenos', '{}'::jsonb),
			'transiciones', coalesce(analisis -> 'transiciones', '[]'::jsonb)
		) order by lower(meta ->> 'titulo'), obra_id), '[]'::jsonb) as valor
		from obras
	), valores_metricas as (
		select o.obra_id, v.nombre, v.valor
		from obras o
		cross join lateral (values
			('total_versos', (o.analisis #>> '{metricas,total_versos}')::numeric),
			('total_secuencias', (o.analisis #>> '{metricas,total_secuencias}')::numeric),
			('n_jornadas', (o.analisis #>> '{metricas,n_jornadas}')::numeric),
			('n_formas_distintas', (o.analisis #>> '{metricas,n_formas_distintas}')::numeric),
			('numero_efectivo_formas', (o.analisis #>> '{metricas,numero_efectivo_formas}')::numeric),
			('densidad_transiciones', (o.analisis #>> '{metricas,densidad_transiciones}')::numeric),
			('longitud_media_secuencia', (o.analisis #>> '{metricas,longitud_media_secuencia}')::numeric),
			('proporcion_italiana', (o.analisis #>> '{metricas,proporcion_italiana}')::numeric),
			('proporcion_sin_forma', (o.analisis #>> '{metricas,proporcion_sin_forma}')::numeric),
			('cambios_cuadro_total', (o.analisis #>> '{articulacion,cambios_cuadro_total}')::numeric),
			('proporcion_cambios_cuadro_con_cambio_secuencia',
				(o.analisis #>> '{articulacion,proporcion_cambios_cuadro_con_cambio_secuencia}')::numeric)
		) v(nombre, valor)
		where v.valor is not null
	), metricas_json as (
		select coalesce(jsonb_object_agg(nombre, estadisticas), '{}'::jsonb) as valor
		from (
			select nombre, public.resumen_estadistico_json(array_agg(valor order by obra_id)) as estadisticas
			from valores_metricas
			group by nombre
		) agrupadas
	), formas_universo as (
		select
			f.key as forma,
			max(f.value ->> 'tipo_forma') as tipo_forma
		from obras o
		cross join lateral jsonb_each(coalesce(o.analisis -> 'perfil_formas', '{}'::jsonb)) f
		where f.key <> 'sin-forma-anotada'
		group by f.key
	), valores_formas as (
		select
			f.forma,
			f.tipo_forma,
			o.obra_id,
			coalesce((o.analisis #>> array['perfil_formas', f.forma, 'versos'])::numeric, 0) as versos,
			coalesce((o.analisis #>> array['perfil_formas', f.forma, 'secuencias'])::numeric, 0) as secuencias,
			coalesce((o.analisis #>> array['perfil_formas', f.forma, 'proporcion_versos'])::numeric, 0) as proporcion,
			(o.analisis #>> array['perfil_formas', f.forma, 'longitud_media_secuencia'])::numeric as longitud_media
		from formas_universo f cross join obras o
	), formas_agregadas as (
		select
			forma,
			max(tipo_forma) as tipo_forma,
			count(*) filter (where versos > 0)::integer as obras_con_forma,
			max(u.n) as obras_analizables,
			sum(versos) as versos_totales,
			sum(secuencias) as secuencias_totales,
			public.resumen_estadistico_json(array_agg(proporcion order by obra_id)) as proporcion_versos,
			public.resumen_estadistico_json(array_agg(secuencias order by obra_id)) as secuencias_por_obra,
			public.resumen_estadistico_json(
				array_agg(longitud_media order by obra_id) filter (where longitud_media is not null)
			) as longitud_media_secuencia
		from valores_formas cross join universo u
		group by forma
	), formas_json as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'forma', forma,
			'tipo_forma', tipo_forma,
			'obras_con_forma', obras_con_forma,
			'obras_analizables', obras_analizables,
			'proporcion_obras', case when obras_analizables > 0
				then obras_con_forma::numeric / obras_analizables else null end,
			'versos_totales', versos_totales,
			'secuencias_totales', secuencias_totales,
			'proporcion_versos', proporcion_versos,
			'secuencias_por_obra', secuencias_por_obra,
			'longitud_media_secuencia', longitud_media_secuencia
		) order by obras_con_forma desc, forma), '[]'::jsonb) as valor
		from formas_agregadas
	), pares_transiciones as (
		select t.value ->> 'de' as de, t.value ->> 'a' as a
		from obras o
		cross join lateral jsonb_array_elements(coalesce(o.analisis -> 'transiciones', '[]'::jsonb)) t(value)
		group by t.value ->> 'de', t.value ->> 'a'
	), valores_transiciones as (
		select
			p.de,
			p.a,
			o.obra_id,
			coalesce((
				select (t.value ->> 'veces')::integer
				from jsonb_array_elements(coalesce(o.analisis -> 'transiciones', '[]'::jsonb)) t(value)
				where t.value ->> 'de' = p.de and t.value ->> 'a' = p.a
				limit 1
			), 0) as veces
		from pares_transiciones p cross join obras o
	), transiciones_agregadas as (
		select
			de,
			a,
			count(*) filter (where veces > 0)::integer as obras_con_transicion,
			max(u.n) as obras_analizables,
			sum(veces)::integer as ocurrencias_totales,
			public.resumen_estadistico_json(array_agg(veces::numeric order by obra_id)) as ocurrencias_por_obra
		from valores_transiciones cross join universo u
		group by de, a
	), transiciones_json as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'de', de,
			'a', a,
			'obras_con_transicion', obras_con_transicion,
			'obras_analizables', obras_analizables,
			'proporcion_obras', case when obras_analizables > 0
				then obras_con_transicion::numeric / obras_analizables else null end,
			'ocurrencias_totales', ocurrencias_totales,
			'ocurrencias_por_obra', ocurrencias_por_obra
		) order by obras_con_transicion desc, de, a), '[]'::jsonb) as valor
		from transiciones_agregadas
	), valores_fenomenos as (
		select
			f.key as fenomeno,
			o.obra_id,
			(f.value ->> 'proporcion')::numeric as proporcion
		from obras o
		cross join lateral jsonb_each(coalesce(o.analisis -> 'fenomenos', '{}'::jsonb)) f
		where (f.value ->> 'total_respondidas')::integer > 0
	), fenomenos_json as (
		select coalesce(jsonb_object_agg(fenomeno, estadisticas), '{}'::jsonb) as valor
		from (
			select fenomeno, public.resumen_estadistico_json(array_agg(proporcion order by obra_id)) as estadisticas
			from valores_fenomenos
			group by fenomeno
		) agrupados
	), enunciacion_universo as (
		select e.key as tipo
		from obras o cross join lateral jsonb_each(coalesce(o.analisis -> 'enunciacion', '{}'::jsonb)) e
		group by e.key
	), valores_enunciacion as (
		select
			e.tipo,
			o.obra_id,
			coalesce((o.analisis #>> array['enunciacion', e.tipo, 'proporcion_versos'])::numeric, 0) as proporcion
		from enunciacion_universo e cross join obras o
	), enunciacion_json as (
		select coalesce(jsonb_object_agg(tipo, jsonb_build_object(
			'obras_con_anotacion', obras_con,
			'obras_analizables', total,
			'proporcion_obras', case when total > 0 then obras_con::numeric / total else null end,
			'proporcion_versos', estadisticas
		)), '{}'::jsonb) as valor
		from (
			select
				tipo,
				count(*) filter (where proporcion > 0)::integer as obras_con,
				count(*)::integer as total,
				public.resumen_estadistico_json(array_agg(proporcion order by obra_id)) as estadisticas
			from valores_enunciacion
			group by tipo
		) agrupados
	), jornadas as (
		select
			o.obra_id,
			j.value ->> 'abre' as abre,
			j.value ->> 'cierra' as cierra
		from obras o
		cross join lateral jsonb_array_elements(coalesce(o.analisis #> '{articulacion,jornadas}', '[]'::jsonb)) j(value)
	), aperturas_json as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'forma', abre,
			'jornadas', jornadas,
			'obras', obras
		) order by jornadas desc, abre), '[]'::jsonb) as valor
		from (
			select abre, count(*)::integer as jornadas, count(distinct obra_id)::integer as obras
			from jornadas where abre is not null group by abre
		) agrupadas
	), cierres_json as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'forma', cierra,
			'jornadas', jornadas,
			'obras', obras
		) order by jornadas desc, cierra), '[]'::jsonb) as valor
		from (
			select cierra, count(*)::integer as jornadas, count(distinct obra_id)::integer as obras
			from jornadas where cierra is not null group by cierra
		) agrupadas
	), pares_extremos_json as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'abre', abre,
			'cierra', cierra,
			'jornadas', jornadas,
			'obras', obras
		) order by jornadas desc, abre, cierra), '[]'::jsonb) as valor
		from (
			select abre, cierra, count(*)::integer as jornadas, count(distinct obra_id)::integer as obras
			from jornadas where abre is not null and cierra is not null group by abre, cierra
		) agrupadas
	)
	select jsonb_build_object(
		'schema_version', 2,
		'privado', true,
		'alcance', p_alcance,
		'criterio_universo', jsonb_build_object(
			'estado', 'publicado',
			'visibilidad', case when p_alcance = 'publico' then 'visible_publico' else 'todas_las_publicadas' end
		),
		'obras_analizables', u.n,
		'obras', fo.valor,
		'metricas_obra', mj.valor,
		'formas', fj.valor,
		'transiciones', tj.valor,
		'fenomenos', fej.valor,
		'enunciacion', ej.valor,
		'extremos_jornada', jsonb_build_object(
			'aperturas', aj.valor,
			'cierres', cj.valor,
			'pares', pej.valor
		)
	)
	into v_resultado
	from universo u
		cross join filas_obras fo
		cross join metricas_json mj
		cross join formas_json fj
		cross join transiciones_json tj
		cross join fenomenos_json fej
		cross join enunciacion_json ej
		cross join aperturas_json aj
		cross join cierres_json cj
		cross join pares_extremos_json pej;

	return v_resultado;
end;
$$;

revoke all on function public.corpus_comparativas_artefacto_json(text)
	from public, anon, authenticated;
grant execute on function public.corpus_comparativas_artefacto_json(text) to service_role;

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

		v_comparativas := public.corpus_comparativas_artefacto_json(v_alcance);
		perform public.guardar_artefacto_publico(
			format('corpus/comparativas/%s.json', v_alcance),
			'corpus_comparativas', null, v_alcance, v_comparativas, 2
		);
	end loop;
end;
$$;

grant execute on function public.recompute_artefactos_obra(uuid) to service_role;
grant execute on function public.recompute_artefactos_globales() to service_role;

-- La función se ejecuta en la propia migración: además de materializar V2, obliga a PostgreSQL a
-- resolver todos los campos dinámicos de los cuerpos PL/pgSQL sobre datos reales.
select public.recompute_all();

do $$
declare
	v_analisis jsonb;
	v_corpus jsonb;
begin
	select payload into v_analisis
	from public.artefactos_publicos
	where tipo = 'obra_analisis'
	order by generado_en desc
	limit 1;

	select payload into v_corpus
	from public.artefactos_publicos
	where clave = 'corpus/comparativas/publico.json';

	if (v_analisis ->> 'schema_version')::integer <> 2
		or not (v_analisis ? 'metricas' and v_analisis ? 'articulacion' and v_analisis ? 'perfil_formas') then
		raise exception 'obra_analisis V2 no quedó materializado';
	end if;
	if (v_corpus ->> 'schema_version')::integer <> 2
		or not (v_corpus ? 'obras' and v_corpus ? 'metricas_obra' and v_corpus ? 'formas') then
		raise exception 'corpus_comparativas V2 no quedó materializado';
	end if;
end;
$$;

commit;
