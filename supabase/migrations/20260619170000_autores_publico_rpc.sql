-- Fase 6 del plan de precomputación: exposición pública de autores.
--
-- `autores` NO tiene política SELECT para anon (solo editores activos), así que la zona
-- pública necesita funciones SECURITY DEFINER para leer identidad de autor y sus obras,
-- aplicando dentro el muro de visibilidad (estado=publicado y visible_publico, salvo
-- p_include_hidden para admin/IP). El perfil métrico agregado se lee aparte de
-- autores_resumen (su RLS ya reparte alcance publico/completo por rol).
--
-- Ver docs/metodologia-perfil-metrico.md §3 (dos conjuntos: perfil vs obras asociadas).
-- Aplicar a mano por el SQL Editor.

begin;

-- ============================================================
-- get_autor_publico(slug, include_hidden): identidad + obras asociadas (todas,
--   etiquetando el vínculo), filtradas por visibilidad. NULL si el slug no existe.
-- ============================================================
-- include_hidden NO se acepta del cliente (sería escalada): se decide aquí con
-- auth_is_admin_or_ip() sobre el contexto de auth real, igual que la RLS.
create or replace function public.get_autor_publico(
  p_slug text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_publicado_id uuid;
  v_autor public.autores%rowtype;
  v_admin boolean := public.auth_is_admin_or_ip();
begin
  select termino_id into v_publicado_id
  from public.vocabularios
  where categoria = 'estado' and lower(termino) = 'publicado'
  limit 1;
  if v_publicado_id is null then
    return null;
  end if;

  select * into v_autor from public.autores where slug = p_slug limit 1;
  if not found then
    return null;
  end if;

  return (
    with autor_links as (
      -- una fila por atribución (de cualquier grupo, scope obra o jornada) donde aparece el autor
      select
        coalesce(g.obra_id, j.obra_id) as obra_id,
        a.atribucion_id,
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
      where aa.autor_id = v_autor.autor_id
    ),
    visible_obras as (
      select distinct al.obra_id
      from autor_links al
      join public.obras o on o.obra_id = al.obra_id
      where o.estado = v_publicado_id
        and (v_admin or coalesce(o.visible_publico, false))
    ),
    perfil_obras as (
      -- obras donde el autor tiene una unidad mono-autor que sostiene su perfil métrico
      select distinct u.obra_id
      from public.perfil_metrico_unidades() u
      where u.autor_id = v_autor.autor_id
    ),
    obras_json as (
      select coalesce(jsonb_agg(item order by sort_fecha nulls last, sort_titulo), '[]'::jsonb) as items
      from (
        select
          o.fecha_inicio_trad as sort_fecha,
          lower(o.titulo)     as sort_titulo,
          jsonb_build_object(
            'obra_id', o.obra_id,
            'slug', o.slug,
            'titulo', o.titulo,
            'genero_term', (select vg.termino from public.vocabularios vg
                            where vg.termino_id = o.genero_id limit 1),
            'fecha_inicio_trad', o.fecha_inicio_trad,
            'fecha_fin_trad', o.fecha_fin_trad,
            'total_versos', coalesce(orr.total_versos, o.total_versos),
            'visible_publico', coalesce(o.visible_publico, false),
            'tramos', coalesce(orr.tramos, '[]'::jsonb),
            'jornadas_tramos', coalesce(orr.jornadas_tramos, '[]'::jsonb),
            'cuadros_tramos', coalesce(orr.cuadros_tramos, '[]'::jsonb),
            'sostiene_perfil', (po.obra_id is not null),
            'vinculos', (
              select coalesce(jsonb_agg(distinct jsonb_build_object(
                'scope', al.scope,
                'jornada_num', al.jornada_num,
                'composicion_term', al.composicion_term,
                'perfil_metrico', al.perfil_metrico,
                'unica_propuesta', (al.n_prop_grupo = 1)
              )), '[]'::jsonb)
              from autor_links al
              where al.obra_id = o.obra_id
            )
          ) as item
        from visible_obras vo
        join public.obras o on o.obra_id = vo.obra_id
        left join public.obras_resumen orr on orr.obra_id = o.obra_id
        left join perfil_obras po on po.obra_id = o.obra_id
      ) sub
    )
    select jsonb_build_object(
      'autor', jsonb_build_object(
        'autor_id', v_autor.autor_id,
        'slug', v_autor.slug,
        'nombre_completo', v_autor.nombre_completo,
        'variantes_nombre', coalesce(v_autor.variantes_nombre, '{}'::text[]),
        'viaf_id', v_autor.viaf_id,
        'wikidata_id', v_autor.wikidata_id,
        'bnedatos_id', v_autor.bnedatos_id
      ),
      'obras', (select items from obras_json)
    )
  );
end;
$$;

grant execute on function public.get_autor_publico(text) to anon;
grant execute on function public.get_autor_publico(text) to authenticated;
grant execute on function public.get_autor_publico(text) to service_role;

-- ============================================================
-- get_autores_listado_publico(): directorio de autores CON perfil métrico. El
--   alcance se decide aquí por rol (admin/IP → completo; resto → publico), no por
--   un flag del cliente.
-- ============================================================
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
