-- Expone wikidata_id en el listado público de autores para poder enriquecer
-- las cards con imagen externa resuelta en servidor.

begin;

create or replace function public.get_autores_listado_publico()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(item order by nombre_norm), '[]'::jsonb)
  from (
    select
      lower(coalesce(a.nombre_normalizado, a.nombre_completo)) as nombre_norm,
      jsonb_build_object(
        'slug', a.slug,
        'nombre_completo', a.nombre_completo,
        'wikidata_id', a.wikidata_id,
        'total_versos_autor', ar.total_versos_autor,
        'n_obras_completas', ar.n_obras_completas,
        'n_jornadas_sueltas', ar.n_jornadas_sueltas,
        'numero_efectivo_formas_agregado', ar.numero_efectivo_formas_agregado,
        'perfil_formas', ar.perfil_formas
      ) as item
    from public.autores_resumen ar
    join public.autores a on a.autor_id = ar.autor_id
    where ar.alcance = case when (select public.auth_is_admin_or_ip()) then 'completo' else 'publico' end
  ) sub;
$$;

grant execute on function public.get_autores_listado_publico() to anon;
grant execute on function public.get_autores_listado_publico() to authenticated;
grant execute on function public.get_autores_listado_publico() to service_role;

commit;
