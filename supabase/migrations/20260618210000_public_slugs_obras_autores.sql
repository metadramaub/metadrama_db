-- Slugs publicos persistidos para obras y autores.
-- Se guardan en tabla para que sean editables desde Supabase Dashboard y
-- se generan en base de datos para cubrir inserciones/ediciones fuera de la app.

begin;

alter table public.obras add column if not exists slug text;
alter table public.autores add column if not exists slug text;

create or replace function public.metadrama_slugify(value text)
returns text
language plpgsql
immutable
as $$
declare
	v text := lower(coalesce(value, ''));
begin
	v := replace(v, 'æ', 'ae');
	v := replace(v, 'œ', 'oe');
	v := replace(v, 'ß', 'ss');
	v := translate(v, 'áàâäãåāăą', 'aaaaaaaaa');
	v := translate(v, 'éèêëēĕėęě', 'eeeeeeeee');
	v := translate(v, 'íìîïīĭįı', 'iiiiiiii');
	v := translate(v, 'óòôöõøōŏő', 'ooooooooo');
	v := translate(v, 'úùûüūŭůűų', 'uuuuuuuuu');
	v := translate(v, 'ñçýÿšž', 'ncyysz');
	v := regexp_replace(v, '[^a-z0-9]+', '-', 'g');
	v := regexp_replace(v, '(^-+|-+$)', '', 'g');
	return v;
end;
$$;

create or replace function public.next_obras_slug(base text, current_obra_id uuid)
returns text
language plpgsql
volatile
set search_path = public
as $$
declare
	v_base text := coalesce(nullif(public.metadrama_slugify(base), ''), 'obra');
	v_candidate text := v_base;
	v_suffix integer := 2;
begin
	loop
		if not exists (
			select 1
			from public.obras o
			where o.slug = v_candidate
				and (current_obra_id is null or o.obra_id <> current_obra_id)
		) then
			return v_candidate;
		end if;

		v_candidate := v_base || '-' || v_suffix::text;
		v_suffix := v_suffix + 1;
	end loop;
end;
$$;

create or replace function public.next_autores_slug(base text, current_autor_id uuid)
returns text
language plpgsql
volatile
set search_path = public
as $$
declare
	v_base text := coalesce(nullif(public.metadrama_slugify(base), ''), 'autor');
	v_candidate text := v_base;
	v_suffix integer := 2;
begin
	loop
		if not exists (
			select 1
			from public.autores a
			where a.slug = v_candidate
				and (current_autor_id is null or a.autor_id <> current_autor_id)
		) then
			return v_candidate;
		end if;

		v_candidate := v_base || '-' || v_suffix::text;
		v_suffix := v_suffix + 1;
	end loop;
end;
$$;

do $$
declare
	r record;
begin
	for r in
		select o.obra_id, public.metadrama_slugify(o.titulo) as base
		from public.obras o
		where o.slug is null or btrim(o.slug) = ''
		order by public.metadrama_slugify(o.titulo), o.titulo, o.obra_id
	loop
		update public.obras
		set slug = public.next_obras_slug(r.base, r.obra_id)
		where obra_id = r.obra_id;
	end loop;
end;
$$;

do $$
declare
	r record;
begin
	for r in
		select a.autor_id, public.metadrama_slugify(a.nombre_completo) as base
		from public.autores a
		where a.slug is null or btrim(a.slug) = ''
		order by public.metadrama_slugify(a.nombre_completo), a.nombre_completo, a.autor_id
	loop
		update public.autores
		set slug = public.next_autores_slug(r.base, r.autor_id)
		where autor_id = r.autor_id;
	end loop;
end;
$$;

alter table public.obras alter column slug set not null;
alter table public.autores alter column slug set not null;

do $$
begin
	if not exists (
		select 1 from pg_constraint where conname = 'obras_slug_key' and conrelid = 'public.obras'::regclass
	) then
		alter table public.obras add constraint obras_slug_key unique (slug);
	end if;

	if not exists (
		select 1 from pg_constraint where conname = 'autores_slug_key' and conrelid = 'public.autores'::regclass
	) then
		alter table public.autores add constraint autores_slug_key unique (slug);
	end if;
end;
$$;

create or replace function public.set_obras_slug()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_old_base text;
begin
	if tg_op = 'INSERT' then
		if new.slug is null or btrim(new.slug) = '' then
			new.slug := public.next_obras_slug(new.titulo, new.obra_id);
		else
			new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'obra');
		end if;
		return new;
	end if;

	if new.slug is null or btrim(new.slug) = '' then
		new.slug := public.next_obras_slug(new.titulo, new.obra_id);
		return new;
	end if;

	if new.slug is distinct from old.slug then
		new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'obra');
		return new;
	end if;

	if new.titulo is distinct from old.titulo then
		v_old_base := coalesce(nullif(public.metadrama_slugify(old.titulo), ''), 'obra');
		if old.slug ~ ('^' || v_old_base || '(-[0-9]+)?$') then
			new.slug := public.next_obras_slug(new.titulo, new.obra_id);
		else
			new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'obra');
		end if;
	else
		new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'obra');
	end if;

	return new;
end;
$$;

create or replace function public.set_autores_slug()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_old_base text;
begin
	if tg_op = 'INSERT' then
		if new.slug is null or btrim(new.slug) = '' then
			new.slug := public.next_autores_slug(new.nombre_completo, new.autor_id);
		else
			new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'autor');
		end if;
		return new;
	end if;

	if new.slug is null or btrim(new.slug) = '' then
		new.slug := public.next_autores_slug(new.nombre_completo, new.autor_id);
		return new;
	end if;

	if new.slug is distinct from old.slug then
		new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'autor');
		return new;
	end if;

	if new.nombre_completo is distinct from old.nombre_completo then
		v_old_base := coalesce(nullif(public.metadrama_slugify(old.nombre_completo), ''), 'autor');
		if old.slug ~ ('^' || v_old_base || '(-[0-9]+)?$') then
			new.slug := public.next_autores_slug(new.nombre_completo, new.autor_id);
		else
			new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'autor');
		end if;
	else
		new.slug := coalesce(nullif(public.metadrama_slugify(new.slug), ''), 'autor');
	end if;

	return new;
end;
$$;

drop trigger if exists trg_set_obras_slug on public.obras;
create trigger trg_set_obras_slug
	before insert or update of titulo, slug on public.obras
	for each row execute function public.set_obras_slug();

drop trigger if exists trg_set_autores_slug on public.autores;
create trigger trg_set_autores_slug
	before insert or update of nombre_completo, slug on public.autores
	for each row execute function public.set_autores_slug();

alter function public.get_obra_ficha_publica(uuid, boolean)
	rename to get_obra_ficha_publica_base_without_slugs;

create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_payload jsonb;
	v_obra_slug text;
	v_author_slugs jsonb := '{}'::jsonb;
begin
	v_payload := public.get_obra_ficha_publica_base_without_slugs(p_obra_id, p_include_hidden);

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
$$;

grant execute on function public.get_obra_ficha_publica(uuid, boolean) to anon;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to authenticated;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to service_role;

commit;
