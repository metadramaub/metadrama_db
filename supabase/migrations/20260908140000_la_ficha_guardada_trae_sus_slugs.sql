-- La ficha que se guarda trae ya sus slugs
--
-- Al partir la ficha en productora y portero quedo fuera un tercer trozo: `get_obra_ficha_publica`,
-- que anadia el slug de la obra y el de cada autor. Como la ficha guardada es la que va a leer el
-- navegador, tiene que venir completa: si los slugs se pegan despues, quien lea la tabla no los
-- tiene y hay que volver a la base a por ellos, que es justo lo que se quiere evitar.
--
-- Asi que la productora los incluye. El reparto queda:
--
--   `ficha_publica_base_json`   arma la ficha
--   `ficha_publica_json`        le pone los slugs -- es la que se guarda
--   `get_obra_ficha_publica`    comprueba el permiso y delega

do $comprobar$
begin
	if to_regprocedure('public.ficha_publica_json(uuid, boolean)') is null then
		raise exception 'No esta la productora que se iba a renombrar.';
	end if;
end $comprobar$;

alter function public.ficha_publica_json(uuid, boolean) rename to ficha_publica_base_json;

-- **La productora, con los slugs puestos.** Es la que guarda el recompute.
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
begin
	v_payload := public.ficha_publica_base_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	select o.slug
	into v_obra_slug
	from public.obras o
	where o.obra_id = p_obra_id;

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
						'slug',
						coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
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
														'slug',
														coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
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
revoke all on function public.ficha_publica_base_json(uuid, boolean) from public, anon, authenticated;

-- **El portero de siempre**, que ahora solo comprueba y delega.
create or replace function public.get_obra_ficha_publica(
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

-- Se recomputan las publicadas para que lo guardado traiga ya los slugs.
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

-- **Se ejecuta.** La ficha guardada tiene que traer el slug de la obra y el de cada autor, o el
-- navegador no podria enlazar a nadie sin volver a preguntar.
do $guarda$
declare
	v_obra uuid;
	v_ficha jsonb;
	v_sin_slug int;
begin
	select r.obra_id into v_obra
	from public.obras_resumen r
	where r.ficha is not null
		and jsonb_array_length(coalesce(r.ficha #> '{autoria,autores}', '[]'::jsonb)) > 0
	limit 1;
	if v_obra is null then
		raise notice 'Ninguna obra guardada tiene autores: nada que comprobar.';
		return;
	end if;

	select ficha into v_ficha from public.obras_resumen where obra_id = v_obra;

	if coalesce(v_ficha #>> '{obra,slug}', '') = '' then
		raise exception 'La ficha guardada de % no trae el slug de la obra', v_obra;
	end if;

	select count(*) into v_sin_slug
	from jsonb_array_elements(v_ficha #> '{autoria,autores}') a
	where coalesce(a->>'slug', '') = '';
	if v_sin_slug > 0 then
		raise exception '% autores sin slug en la ficha guardada de %', v_sin_slug, v_obra;
	end if;

	if v_ficha is distinct from public.ficha_publica_json(v_obra, false) then
		raise exception 'Lo guardado y lo vivo difieren para %', v_obra;
	end if;

	raise notice 'Ficha guardada con slugs: % y % autores.',
		v_ficha #>> '{obra,slug}', jsonb_array_length(v_ficha #> '{autoria,autores}');
end;
$guarda$;
