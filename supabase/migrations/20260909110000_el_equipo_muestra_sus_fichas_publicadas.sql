-- Añade al directorio del equipo las fichas públicas asignadas a cada editor.
-- Las personas se ordenan por número de fichas publicadas y, en caso de empate, por nombre.

create or replace function public.get_equipo_publico()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
	select coalesce(
		jsonb_agg(
			jsonb_build_object(
				'nombre_completo', equipo.nombre_completo,
				'orcid', equipo.orcid,
				'total_obras', equipo.total_obras,
				'obras', equipo.obras
			)
			order by equipo.total_obras desc, lower(equipo.nombre_completo), equipo.nombre_completo
		),
		'[]'::jsonb
	)
	from (
		select
			e.nombre_completo,
			e.orcid,
			count(o.obra_id)::integer as total_obras,
			coalesce(
				jsonb_agg(
					jsonb_build_object(
						'titulo', o.titulo,
						'slug', o.slug
					)
					order by lower(o.titulo), o.titulo
				) filter (where o.obra_id is not null),
				'[]'::jsonb
			) as obras
		from public.editores e
		join public.vocabularios rol on rol.termino_id = e.role
		left join public.obras o
			on o.editor_asignado = e.user_id
			and o.visible_publico is true
		where rol.categoria = 'role_editor'
			and lower(rol.termino) = 'editor'
			and coalesce(e.activo, true)
			and lower(trim(e.nombre_completo)) <> 'sin asignar'
		group by e.user_id, e.nombre_completo, e.orcid
	) equipo;
$$;

comment on function public.get_equipo_publico() is
	'Directorio público de editores activos con nombre, ORCID y fichas públicas asignadas.';
