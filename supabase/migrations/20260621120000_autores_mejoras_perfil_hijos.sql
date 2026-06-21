-- Mejoras 2026-06-21 sobre la zona pública de autores (sobre Fases 3 y 6, ya aplicadas).
--
-- Va en migración nueva (no editando las ya aplicadas 20260619160000/170000) para que
-- `supabase db push` la detecte y aplique. Todo idempotente.
--
--   1. autores_resumen.perfil_formas_hijos: perfil a nivel HOJA {estrofa_tipo_slug: versos}
--      para el desglose de formas hijas en la leyenda del perfil de autor (docs §2.3).
--   2. recompute_autor_resumen: agrega también ese perfil hoja.
--   3. get_autor_publico: añade numero_efectivo_formas/densidad_transiciones/n_formas_distintas
--      por obra (tarjeta del catálogo reutilizada en la ficha de autor).
--
-- TRAS APLICAR: ejecutar recompute_all() para poblar perfil_formas_hijos.

begin;

-- 1. Columna de perfil a nivel hoja
alter table public.autores_resumen
  add column if not exists perfil_formas_hijos jsonb not null default '{}'::jsonb;

-- 2. Helper: perfil hoja {estrofa_tipo_slug: versos} en un rango (o toda la obra si los límites
--    son null). NO colapsa al padre: la clave es la forma realmente usada (hijo o raíz).
create or replace function public.perfil_formas_hijos_rango(
  p_obra_id uuid,
  p_v_ini int default null,
  p_v_fin int default null
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_object_agg(forma_slug, versos), '{}'::jsonb)
  from (
    select est.termino as forma_slug, sum(sm.n_versos)::int as versos
    from public.secuencias_metricas sm
    join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    where sm.obra_id = p_obra_id
      and (p_v_ini is null or sm.v_ini >= p_v_ini)
      and (p_v_fin is null or sm.v_fin <= p_v_fin)
    group by est.termino
    having est.termino is not null
  ) t;
$$;

grant execute on function public.perfil_formas_hijos_rango(uuid, int, int) to authenticated;
grant execute on function public.perfil_formas_hijos_rango(uuid, int, int) to service_role;

-- 3. recompute_autor_resumen: agrega perfil_formas (raíz) y perfil_formas_hijos (hoja).
create or replace function public.recompute_autor_resumen(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alcance      text;
  v_perfil       jsonb;
  v_perfil_hijos jsonb;
  v_total        int;
  v_n_obras      int;
  v_n_jorn       int;
  v_ne_medio     float;
  v_ne_agg       float;
  v_n_units      int;
begin
  foreach v_alcance in array array['publico', 'completo']
  loop
    with units as (
      select u.scope, u.obra_id, u.jornada_v_ini, u.jornada_v_fin
      from public.perfil_metrico_unidades() u
      where u.autor_id = p_autor_id
    ),
    elig as (
      select un.*
      from units un
      join public.obras o on o.obra_id = un.obra_id
      join public.vocabularios v
        on v.termino_id = o.estado
       and v.categoria = 'estado'
       and lower(v.termino) = 'publicado'
      where v_alcance = 'completo'
         or coalesce(o.visible_publico, false) = true
    ),
    unit_perfil as (
      select
        e.scope,
        case when e.scope = 'obra'
             then coalesce(orr.perfil_formas, '{}'::jsonb)
             else public.perfil_formas_rango(e.obra_id, e.jornada_v_ini, e.jornada_v_fin)
        end as perfil,
        case when e.scope = 'obra'
             then public.perfil_formas_hijos_rango(e.obra_id, null, null)
             else public.perfil_formas_hijos_rango(e.obra_id, e.jornada_v_ini, e.jornada_v_fin)
        end as perfil_hijos,
        case when e.scope = 'obra' then orr.numero_efectivo_formas else null end as ne_obra
      from elig e
      left join public.obras_resumen orr on orr.obra_id = e.obra_id
    ),
    unit_calc as (
      select
        up.scope,
        up.perfil,
        up.perfil_hijos,
        up.ne_obra,
        coalesce((select sum((value)::int) from jsonb_each_text(up.perfil)), 0) as versos
      from unit_perfil up
    ),
    perfil_pairs as (
      select kv.key as forma, sum((kv.value)::int) as versos
      from unit_calc uc
      cross join lateral jsonb_each_text(uc.perfil) kv
      group by kv.key
    ),
    perfil_pairs_hijos as (
      select kv.key as forma, sum((kv.value)::int) as versos
      from unit_calc uc
      cross join lateral jsonb_each_text(uc.perfil_hijos) kv
      group by kv.key
    ),
    agg as (
      select
        coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_agg,
        coalesce(sum(versos), 0)::int as total_versos
      from perfil_pairs
    ),
    agg_hijos as (
      select coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_hijos_agg
      from perfil_pairs_hijos
    ),
    counts as (
      select
        count(*) filter (where scope = 'obra')::int    as n_obras,
        count(*) filter (where scope = 'jornada')::int as n_jorn,
        avg(ne_obra) filter (where scope = 'obra')      as ne_medio,
        count(*)::int                                    as n_units
      from unit_calc
    )
    select
      agg.perfil_agg, agg_hijos.perfil_hijos_agg, agg.total_versos,
      counts.n_obras, counts.n_jorn, counts.ne_medio, counts.n_units
    into v_perfil, v_perfil_hijos, v_total, v_n_obras, v_n_jorn, v_ne_medio, v_n_units
    from agg cross join agg_hijos cross join counts;

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
        v_ne_medio, v_ne_agg,
        false, now()
      )
      on conflict (autor_id, alcance) do update set
        n_obras_completas               = excluded.n_obras_completas,
        n_jornadas_sueltas              = excluded.n_jornadas_sueltas,
        total_versos_autor              = excluded.total_versos_autor,
        perfil_formas                   = excluded.perfil_formas,
        perfil_formas_hijos             = excluded.perfil_formas_hijos,
        numero_efectivo_formas_medio    = excluded.numero_efectivo_formas_medio,
        numero_efectivo_formas_agregado = excluded.numero_efectivo_formas_agregado,
        metrica_sucia                   = false,
        actualizado_en                  = now();
    end if;
  end loop;
end;
$$;

grant execute on function public.recompute_autor_resumen(uuid) to authenticated;
grant execute on function public.recompute_autor_resumen(uuid) to service_role;

-- 4. get_autor_publico: añade métricas por obra para la tarjeta del catálogo.
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
            'numero_efectivo_formas', orr.numero_efectivo_formas,
            'densidad_transiciones', orr.densidad_transiciones,
            'n_formas_distintas', orr.n_formas_distintas,
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

commit;
