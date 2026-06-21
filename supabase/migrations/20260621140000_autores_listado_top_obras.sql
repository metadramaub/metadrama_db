-- Añade top_obras (5 principales por extensión) a cada autor del listado público.
-- Son las obras que sostienen su perfil (unidades mono-autor perfil_metrico), filtradas por
-- visibilidad (admin/IP ve no visibles; resto solo visibles), ordenadas por nº de versos.

begin;

create or replace function public.get_autores_listado_publico()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  with adm as (select public.auth_is_admin_or_ip() as is_admin),
  -- Obras del perfil por autor (distinct), con versos y filtro de visibilidad por rol.
  autor_obras as (
    select distinct
      u.autor_id,
      o.obra_id,
      o.slug,
      o.titulo,
      coalesce(orr.total_versos, o.total_versos) as total_versos
    from public.perfil_metrico_unidades() u
    join public.obras o on o.obra_id = u.obra_id
    join public.vocabularios ev
      on ev.termino_id = o.estado and ev.categoria = 'estado' and lower(ev.termino) = 'publicado'
    left join public.obras_resumen orr on orr.obra_id = o.obra_id
    cross join adm
    where adm.is_admin or coalesce(o.visible_publico, false)
  ),
  -- Top 5 por autor (por extensión).
  top_obras as (
    select autor_id,
      coalesce(jsonb_agg(
        jsonb_build_object('slug', slug, 'titulo', titulo, 'total_versos', total_versos)
        order by total_versos desc nulls last, titulo
      ), '[]'::jsonb) as items
    from (
      select autor_id, slug, titulo, total_versos,
        row_number() over (partition by autor_id order by total_versos desc nulls last, titulo) as rn
      from autor_obras
    ) ranked
    where rn <= 5
    group by autor_id
  )
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
        'perfil_formas', ar.perfil_formas,
        'top_obras', coalesce(t.items, '[]'::jsonb)
      ) as item
    from public.autores_resumen ar
    join public.autores a on a.autor_id = ar.autor_id
    left join top_obras t on t.autor_id = ar.autor_id
    where ar.alcance = case when (select is_admin from adm) then 'completo' else 'publico' end
  ) sub;
$$;

grant execute on function public.get_autores_listado_publico() to anon;
grant execute on function public.get_autores_listado_publico() to authenticated;
grant execute on function public.get_autores_listado_publico() to service_role;

commit;
