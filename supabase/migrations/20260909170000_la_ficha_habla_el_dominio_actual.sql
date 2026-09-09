-- La ficha habla el dominio actual
--
-- El JSON público todavía llamaba `estrofa_tipo` a la arquitectura y `subtipos_estrofa` a las
-- respuestas de esquema de rima. Además, esas respuestas se contaban antes de salir y perdían la
-- realización y la sección a las que pertenecían: el navegador podía decir cuántos `CDC DCD`
-- había, pero no reconstruir `ABBA ABBA CDC DCD` como un soneto observado.
--
-- La base sigue guardando cada respuesta por separado. La ficha pública las entrega igual, con su
-- realización, sección y orden, y el cliente decide cómo agruparlas para presentarlas. También
-- salen las respuestas abiertas de rima y las variedades, que el contrato anterior omitía.

create or replace function public.ficha_publica_json(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $productora$
declare
	v_payload jsonb;
	v_obra_slug text;
	v_author_slugs jsonb := '{}'::jsonb;
	v_sequence jsonb;
	v_sequences jsonb := '[]'::jsonb;
	v_synopsis_sequence jsonb;
	v_synopsis_sequences jsonb := '[]'::jsonb;
	v_sequence_id uuid;
	v_annotation_id uuid;
	v_architecture_slug text;
	v_rhyme_schemes jsonb;
	v_features jsonb;
	v_metres jsonb;
	v_varieties jsonb;
begin
	v_payload := public.ficha_publica_base_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	select o.slug
	into v_obra_slug
	from public.obras o
	where o.obra_id = p_obra_id;

	-- Una secuencia conserva una sola anotación efectiva: la primera por orden, igual que
	-- `formas_de_la_obra`. Las respuestas salen sin aplanar su realización ni su sección.
	for v_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{metrica,secuencias}', '[]'::jsonb))
	loop
		v_sequence_id := (v_sequence ->> 'secuencia_id')::uuid;
		v_annotation_id := null;
		v_architecture_slug := null;

		select a.anotacion_id, arq.slug
		into v_annotation_id, v_architecture_slug
		from public.anotaciones_metricas a
		left join public.arquitecturas_forma arq on arq.arquitectura_id = a.arquitectura_id
		where a.secuencia_id = v_sequence_id
		order by a.orden, a.created_at, a.anotacion_id
		limit 1;

		select coalesce(jsonb_agg(row_data order by realization_order nulls first, section_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_rhyme_schemes
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'esquema_rima_id', er.esquema_rima_id,
					'nombre', coalesce(er.nombre, case when nullif(btrim(e.valor_texto), '') is not null then 'Esquema observado' end),
					'notacion', coalesce(er.notacion, nullif(btrim(e.valor_texto), '')),
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'posicion_unidad', e.posicion_unidad,
					'observaciones', e.observaciones
				) as row_data,
				r.orden as realization_order,
				section_ref.orden as section_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			left join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id, er.seccion_id)
			where e.anotacion_id = v_annotation_id
				and (
					e.esquema_rima_id is not null
					or (e.dimension = 'rima' and nullif(btrim(e.valor_texto), '') is not null)
				)
		) rows;

		select coalesce(jsonb_agg(row_data order by feature_name, feature_value, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_features
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'rasgo_slug', rm.slug,
					'rasgo_nombre', rm.nombre,
					'valor_slug', rv.slug,
					'valor_nombre', rv.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'observaciones', e.observaciones
				) as row_data,
				rm.nombre as feature_name,
				rv.nombre as feature_value,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
			join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id)
			where e.anotacion_id = v_annotation_id
		) rows;

		select coalesce(jsonb_agg(row_data order by metre_name, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_metres
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'metro_id', m.metro_id,
					'metro_slug', m.slug,
					'metro_nombre', m.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'posicion_unidad', e.posicion_unidad,
					'observaciones', e.observaciones
				) as row_data,
				m.nombre as metre_name,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.metros m on m.metro_id = e.metro_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id)
			where e.anotacion_id = v_annotation_id
		) rows;

		select coalesce(jsonb_agg(row_data order by variety_order nulls last, variety_name, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_varieties
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'variedad_id', va.variedad_id,
					'variedad_slug', va.slug,
					'variedad_nombre', va.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'observaciones', e.observaciones
				) as row_data,
				va.orden as variety_order,
				va.nombre as variety_name,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.variedades_arquitectura va on va.variedad_id = e.variedad_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			where e.anotacion_id = v_annotation_id
		) rows;

		v_sequence :=
			v_sequence
				- 'estrofa_tipo_id'
				- 'estrofa_tipo_term'
				- 'estrofa_forma_term'
				- 'estrofa_forma_slug'
				- 'estrofa_tipo_forma'
				- 'subtipos_estrofa'
				- 'rasgos'
				- 'metros'
			|| jsonb_build_object(
				'forma_nombre', v_sequence ->> 'estrofa_forma_term',
				'forma_slug', v_sequence -> 'estrofa_forma_slug',
				'tipo_forma', v_sequence -> 'estrofa_tipo_forma',
				'arquitectura_id', v_sequence -> 'estrofa_tipo_id',
				'arquitectura_slug', to_jsonb(v_architecture_slug),
				'arquitectura_nombre', v_sequence ->> 'estrofa_tipo_term',
				'esquemas_rima', v_rhyme_schemes,
				'rasgos', v_features,
				'metros', v_metres,
				'variedades', v_varieties
			);

		v_sequences := v_sequences || jsonb_build_array(v_sequence);
	end loop;

	v_payload := jsonb_set(v_payload, '{metrica,secuencias}', v_sequences, true);

	-- La sinopsis usa el mismo vocabulario actual, aunque no necesita las respuestas métricas.
	for v_synopsis_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{sinopsis_metrica,secuencias}', '[]'::jsonb))
	loop
		v_synopsis_sequence :=
			v_synopsis_sequence
				- 'estrofa_tipo_id'
				- 'estrofa_tipo_term'
				- 'estrofa_forma_term'
				- 'estrofa_forma_slug'
				- 'estrofa_tipo_forma'
			|| jsonb_build_object(
				'forma_nombre', coalesce(v_synopsis_sequence ->> 'estrofa_forma_term', v_synopsis_sequence ->> 'estrofa_tipo_term'),
				'forma_slug', v_synopsis_sequence -> 'estrofa_forma_slug',
				'tipo_forma', v_synopsis_sequence -> 'estrofa_tipo_forma',
				'arquitectura_id', v_synopsis_sequence -> 'estrofa_tipo_id',
				'arquitectura_nombre', v_synopsis_sequence ->> 'estrofa_tipo_term'
			);

		v_synopsis_sequences := v_synopsis_sequences || jsonb_build_array(v_synopsis_sequence);
	end loop;

	v_payload := jsonb_set(v_payload, '{sinopsis_metrica,secuencias}', v_synopsis_sequences, true);

	select coalesce(jsonb_object_agg(a.autor_id::text, a.slug), '{}'::jsonb)
	into v_author_slugs
	from public.autores a
	where exists (
		select 1
		from (
			select (author_item->>'autor_id')::uuid as autor_id
			from jsonb_path_query(v_payload, '$.autoria.autores[*]') as top_authors(author_item)
			where author_item ? 'autor_id'
			union
			select (author_item->>'autor_id')::uuid as autor_id
			from jsonb_path_query(v_payload, '$.autoria.grupos[*].propuestas[*].autores[*]') as nested_authors(author_item)
			where author_item ? 'autor_id'
		) ids
		where ids.autor_id = a.autor_id
	);

	v_payload := jsonb_set(v_payload, '{obra,slug}', to_jsonb(v_obra_slug), true);

	v_payload := jsonb_set(
		v_payload,
		'{autoria,autores}',
		coalesce(
			(
				select jsonb_agg(
					author_item || jsonb_build_object(
						'slug', coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
					)
					order by author_ord
				)
				from jsonb_array_elements(coalesce(v_payload #> '{autoria,autores}', '[]'::jsonb))
					with ordinality as author_rows(author_item, author_ord)
			),
			'[]'::jsonb
		),
		true
	);

	v_payload := jsonb_set(
		v_payload,
		'{autoria,grupos}',
		coalesce(
			(
				select jsonb_agg(
					group_item || jsonb_build_object(
						'propuestas',
						coalesce(
							(
								select jsonb_agg(
									proposal_item || jsonb_build_object(
										'autores',
										coalesce(
											(
												select jsonb_agg(
													author_item || jsonb_build_object(
														'slug', coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
													)
													order by author_ord
												)
												from jsonb_array_elements(coalesce(proposal_item->'autores', '[]'::jsonb))
													with ordinality as author_rows(author_item, author_ord)
											),
											'[]'::jsonb
										)
									)
									order by proposal_ord
								)
								from jsonb_array_elements(coalesce(group_item->'propuestas', '[]'::jsonb))
									with ordinality as proposal_rows(proposal_item, proposal_ord)
							),
							'[]'::jsonb
						)
					)
					order by group_ord
				)
				from jsonb_array_elements(coalesce(v_payload #> '{autoria,grupos}', '[]'::jsonb))
					with ordinality as group_rows(group_item, group_ord)
			),
			'[]'::jsonb
		),
		true
	);

	return v_payload;
end;
$productora$;

revoke all on function public.ficha_publica_json(uuid, boolean) from public, anon, authenticated;

-- Actualiza todas las fichas guardadas: a partir de aquí no queda ninguna publicada con el contrato
-- anterior esperando a que alguien edite la obra.
do $rehacer$
declare
	v_obra uuid;
begin
	for v_obra in
		select r.obra_id from public.obras_resumen r where r.ficha is not null
	loop
		perform public.recompute_obra_resumen_metricas(v_obra);
	end loop;
end;
$rehacer$;

