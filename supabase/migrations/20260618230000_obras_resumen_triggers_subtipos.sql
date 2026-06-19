-- Fase 2 (complemento) del plan de precomputación:
-- Cierra el hueco de suciedad: el trigger original solo cubría secuencias_metricas,
-- pero el resumen también depende de:
--   - secuencias_caracterizaciones_rango → pct_cantado, variaciones_presentes
--   - jornadas                            → n_jornadas
--   - secuencias_subtipos_estrofa         → (nuevo) subtipos_presentes
--
-- Añade subtipos_presentes al resumen para que los subtipos de estrofa puedan
-- usarse como filtro del catálogo, igual que variaciones_presentes.

begin;

-- =========================================================
-- Nueva columna: subtipos_presentes (slugs de subtipos de estrofa usados en la obra)
-- =========================================================
alter table public.obras_resumen
  add column if not exists subtipos_presentes text[];

create index if not exists idx_obras_resumen_subtipos
  on public.obras_resumen using gin (subtipos_presentes);

-- =========================================================
-- Trigger de suciedad para tablas hijas referenciadas por secuencia_id
-- (resuelve obra_id a través de secuencias_metricas).
-- =========================================================
create or replace function public.mark_obra_resumen_dirty_by_secuencia()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_obra_id uuid;
begin
  select sm.obra_id
  into v_obra_id
  from public.secuencias_metricas sm
  where sm.secuencia_id = coalesce(new.secuencia_id, old.secuencia_id);

  -- Si la secuencia ya no existe (cascada de borrado), el trigger de
  -- secuencias_metricas ya marcó la obra; aquí no hace falta nada.
  if v_obra_id is not null then
    update public.obras_resumen
    set metrica_sucia = true
    where obra_id = v_obra_id;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_mark_resumen_dirty_caracterizaciones
  on public.secuencias_caracterizaciones_rango;
create trigger trg_mark_resumen_dirty_caracterizaciones
  after insert or update or delete on public.secuencias_caracterizaciones_rango
  for each row execute function public.mark_obra_resumen_dirty_by_secuencia();

drop trigger if exists trg_mark_resumen_dirty_subtipos
  on public.secuencias_subtipos_estrofa;
create trigger trg_mark_resumen_dirty_subtipos
  after insert or update or delete on public.secuencias_subtipos_estrofa
  for each row execute function public.mark_obra_resumen_dirty_by_secuencia();

-- jornadas tiene obra_id directamente → reutiliza la función original.
drop trigger if exists trg_mark_resumen_dirty_jornadas on public.jornadas;
create trigger trg_mark_resumen_dirty_jornadas
  after insert or update or delete on public.jornadas
  for each row execute function public.mark_obra_resumen_dirty();

-- =========================================================
-- recompute_obra_resumen: ahora también calcula subtipos_presentes
-- =========================================================
create or replace function public.recompute_obra_resumen(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_versos              int;
  v_n_secuencias              int;
  v_n_jornadas                int;
  v_tramos                    jsonb;
  v_perfil_formas             jsonb;
  v_formas_presentes          text[];
  v_tipos_forma_presentes     text[];
  v_metros_presentes          text[];
  v_variaciones_presentes     text[];
  v_subtipos_presentes        text[];
  v_n_formas_distintas        int;
  v_numero_efectivo_formas    float;
  v_p_max                     float;
  v_densidad_transiciones     float;
  v_pct_cantado               float;
  v_tiene_versos_partidos     boolean;
  v_tiene_cambio_espacio      boolean;
  v_intervencion_femenina     text;
  v_intervencion_donaire      text;
  v_intervencion_sobrenaturales text;
begin
  -- 1. Total versos y número de secuencias
  select
    coalesce(sum(sm.n_versos), 0)::int,
    count(*)::int
  into v_total_versos, v_n_secuencias
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 2. Número de jornadas
  select count(*)::int
  into v_n_jornadas
  from public.jornadas j
  where j.obra_id = p_obra_id;

  -- 3. Tramos fusionados y perfil de formas
  with seq_formas as (
    select
      sm.v_ini,
      sm.v_fin,
      sm.n_versos,
      coalesce(ep.termino,    est.termino)    as forma_slug,
      coalesce(ep.tipo_forma, est.tipo_forma) as tipo_forma,
      row_number() over (order by sm.v_ini)   as rn
    from public.secuencias_metricas sm
    left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    left join public.vocabularios ep  on ep.termino_id  = est.termino_padre_id
    where sm.obra_id = p_obra_id
  ),
  island_groups as (
    select *,
      rn - row_number() over (partition by forma_slug order by rn) as grp
    from seq_formas
  ),
  merged_tramos as (
    select
      forma_slug,
      tipo_forma,
      min(v_ini) as v_ini,
      max(v_fin)  as v_fin
    from island_groups
    group by forma_slug, tipo_forma, grp
  ),
  perfil as (
    select forma_slug, sum(n_versos)::int as n_versos
    from seq_formas
    group by forma_slug
  )
  select
    (select coalesce(
        jsonb_agg(
          jsonb_build_object('i', v_ini, 'f', v_fin, 's', forma_slug, 't', tipo_forma)
          order by v_ini
        ),
        '[]'::jsonb
      ) from merged_tramos),
    (select coalesce(jsonb_object_agg(forma_slug, n_versos), '{}'::jsonb) from perfil)
  into v_tramos, v_perfil_formas;

  -- 4. Arrays de filtro: formas y tipos de forma
  select
    array_agg(distinct forma_slug) filter (where forma_slug is not null),
    array_agg(distinct tipo_forma) filter (where tipo_forma is not null)
  into v_formas_presentes, v_tipos_forma_presentes
  from (
    select
      coalesce(ep.termino,    est.termino)    as forma_slug,
      coalesce(ep.tipo_forma, est.tipo_forma) as tipo_forma
    from public.secuencias_metricas sm
    left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    left join public.vocabularios ep  on ep.termino_id  = est.termino_padre_id
    where sm.obra_id = p_obra_id
  ) t;

  -- 5. Metros presentes (vía tabla estrofa_tipo_metros)
  select array_agg(distinct m.termino) filter (where m.termino is not null)
  into v_metros_presentes
  from public.secuencias_metricas sm
  join public.estrofa_tipo_metros etm on etm.estrofa_tipo_id = sm.estrofa_tipo_id
  join public.vocabularios m           on m.termino_id = etm.metro_id
  where sm.obra_id = p_obra_id;

  -- 6. Variaciones presentes (caracterizacion_rango usados en secuencias de la obra)
  select array_agg(distinct v.termino) filter (where v.termino is not null)
  into v_variaciones_presentes
  from public.secuencias_metricas sm
  join public.secuencias_caracterizaciones_rango scr on scr.secuencia_id = sm.secuencia_id
  join public.vocabularios v on v.termino_id = scr.tipo_caracterizacion_rango_id
  where sm.obra_id = p_obra_id;

  -- 6b. Subtipos de estrofa presentes (para filtro de catálogo)
  select array_agg(distinct sv.termino) filter (where sv.termino is not null)
  into v_subtipos_presentes
  from public.secuencias_metricas sm
  join public.secuencias_subtipos_estrofa sse on sse.secuencia_id = sm.secuencia_id
  join public.vocabularios sv on sv.termino_id = sse.subtipo_estrofa_id
  where sm.obra_id = p_obra_id;

  -- 7. n_formas_distintas y p_max
  select
    count(distinct forma_slug)::int,
    max(pct)
  into v_n_formas_distintas, v_p_max
  from (
    select
      coalesce(ep.termino, est.termino)                              as forma_slug,
      sum(sm.n_versos)::float / nullif(v_total_versos, 0) as pct
    from public.secuencias_metricas sm
    left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    left join public.vocabularios ep  on ep.termino_id  = est.termino_padre_id
    where sm.obra_id = p_obra_id
    group by coalesce(ep.termino, est.termino)
  ) forma_pcts;

  -- 8. Número efectivo de formas: exp(H) con H = −Σ p_i · ln(p_i)
  select exp(-sum(p_i * ln(nullif(p_i, 0))))
  into v_numero_efectivo_formas
  from (
    select sum(sm.n_versos)::float / nullif(v_total_versos, 0) as p_i
    from public.secuencias_metricas sm
    left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    left join public.vocabularios ep  on ep.termino_id  = est.termino_padre_id
    where sm.obra_id = p_obra_id
      and coalesce(ep.termino, est.termino) is not null
    group by coalesce(ep.termino, est.termino)
  ) proportions;

  -- 9. Densidad de transiciones
  v_densidad_transiciones := case
    when v_total_versos > 0 then (v_n_secuencias::float / v_total_versos) * 100
    else 0
  end;

  -- 10. % cantado (caracterizacion_rango = 'cantado')
  select coalesce(
    sum(scr.v_fin - scr.v_ini + 1)::float / nullif(v_total_versos, 0),
    0
  )
  into v_pct_cantado
  from public.secuencias_metricas sm
  join public.secuencias_caracterizaciones_rango scr
    on scr.secuencia_id = sm.secuencia_id
  join public.vocabularios vcant
    on vcant.termino_id = scr.tipo_caracterizacion_rango_id
   and vcant.categoria  = 'caracterizacion_rango'
   and vcant.termino    = 'cantado'
  where sm.obra_id = p_obra_id;

  -- 11. Flags booleanos
  select
    bool_or(coalesce(sm.versos_partidos,   false)),
    bool_or(coalesce(sm.inaugura_espacio,  false))
  into v_tiene_versos_partidos, v_tiene_cambio_espacio
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 12. Intervenciones agregadas (enum real: sin_intervencion|exclusiva|compartida → mixta)
  select
    case
      when count(case when sm.intervencion_personajes_femeninos = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_personajes_femeninos = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_personajes_femeninos = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_personajes_femeninos = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end,
    case
      when count(case when sm.intervencion_figuras_donaire = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_figuras_donaire = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_figuras_donaire = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_figuras_donaire = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end,
    case
      when count(case when sm.intervencion_personajes_sobrenaturales = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_personajes_sobrenaturales = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_personajes_sobrenaturales = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_personajes_sobrenaturales = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end
  into v_intervencion_femenina, v_intervencion_donaire, v_intervencion_sobrenaturales
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 13. UPSERT
  insert into public.obras_resumen (
    obra_id,
    total_versos, n_secuencias, n_jornadas,
    n_formas_distintas, numero_efectivo_formas, p_max, densidad_transiciones,
    pct_cantado,
    tramos, perfil_formas,
    formas_presentes, metros_presentes, tipos_forma_presentes, variaciones_presentes,
    subtipos_presentes,
    tiene_versos_partidos, tiene_cambio_espacio,
    intervencion_femenina, intervencion_donaire, intervencion_sobrenaturales,
    metrica_sucia, actualizado_en
  ) values (
    p_obra_id,
    v_total_versos, v_n_secuencias, v_n_jornadas,
    v_n_formas_distintas, v_numero_efectivo_formas, v_p_max, v_densidad_transiciones,
    v_pct_cantado,
    v_tramos, v_perfil_formas,
    v_formas_presentes, v_metros_presentes, v_tipos_forma_presentes, v_variaciones_presentes,
    v_subtipos_presentes,
    v_tiene_versos_partidos, v_tiene_cambio_espacio,
    v_intervencion_femenina, v_intervencion_donaire, v_intervencion_sobrenaturales,
    false, now()
  )
  on conflict (obra_id) do update set
    total_versos                = excluded.total_versos,
    n_secuencias                = excluded.n_secuencias,
    n_jornadas                  = excluded.n_jornadas,
    n_formas_distintas          = excluded.n_formas_distintas,
    numero_efectivo_formas      = excluded.numero_efectivo_formas,
    p_max                       = excluded.p_max,
    densidad_transiciones       = excluded.densidad_transiciones,
    pct_cantado                 = excluded.pct_cantado,
    tramos                      = excluded.tramos,
    perfil_formas               = excluded.perfil_formas,
    formas_presentes            = excluded.formas_presentes,
    metros_presentes            = excluded.metros_presentes,
    tipos_forma_presentes       = excluded.tipos_forma_presentes,
    variaciones_presentes       = excluded.variaciones_presentes,
    subtipos_presentes          = excluded.subtipos_presentes,
    tiene_versos_partidos       = excluded.tiene_versos_partidos,
    tiene_cambio_espacio        = excluded.tiene_cambio_espacio,
    intervencion_femenina       = excluded.intervencion_femenina,
    intervencion_donaire        = excluded.intervencion_donaire,
    intervencion_sobrenaturales = excluded.intervencion_sobrenaturales,
    metrica_sucia               = false,
    actualizado_en              = now();
end;
$$;

commit;
