-- Directorio público mínimo del equipo editorial.
-- Expone solo nombre y ORCID de los perfiles activos cuyo rol es editor.

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
				'nombre_completo', e.nombre_completo,
				'orcid', e.orcid
			)
			order by lower(e.nombre_completo), e.nombre_completo
		),
		'[]'::jsonb
	)
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where rol.categoria = 'role_editor'
		and lower(rol.termino) = 'editor'
		and coalesce(e.activo, true);
$$;

revoke all on function public.get_equipo_publico() from public;
grant execute on function public.get_equipo_publico() to anon;
grant execute on function public.get_equipo_publico() to authenticated;
grant execute on function public.get_equipo_publico() to service_role;

comment on function public.get_equipo_publico() is
	'Directorio público de editores activos: solo nombre completo y ORCID.';
