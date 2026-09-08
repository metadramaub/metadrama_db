-- La obra publicada guarda su ficha entera
--
-- Segunda mitad del paso 1. Separada ya la funcion que construye la ficha de la que comprueba el
-- permiso, el recompute guarda **esa misma ficha** en el resumen: una obra publicada deja de
-- calcularse en cada visita y el navegador la carga de una vez.
--
-- Se guarda `ficha_publica_json(obra, false)`, o sea **lo que ve un anonimo**. El permiso no es
-- contenido: lo que solo ven admin, IP o el editor asignado -una obra en vista previa, un
-- comentario oculto- se sigue resolviendo al vuelo, que es para lo que queda el calculo en vivo.
--
-- Entra tambien `tiene_evento_sobrenatural`, que se registra por secuencia desde el 7 de septiembre
-- y no se agregaba: quedaba pendiente para no escribir dos veces la misma funcion.
--
-- Y se retira `obras_anotacion_nueva`, el interruptor por obra de cuando la migracion iba a hacerse
-- por anotacion en sombra. Salio de `guardar_anotacion_metrica` el 27 de agosto de 2026 y desde
-- entonces no gobierna nada.

alter table public.obras_resumen
  add column if not exists ficha jsonb,
  add column if not exists tiene_evento_sobrenatural boolean not null default false;

comment on column public.obras_resumen.ficha is
  'La ficha publica completa, tal como la ve un anonimo. La construye ficha_publica_json y es lo que carga el navegador de una obra publicada.';

drop table if exists public.obras_anotacion_nueva;

CREATE OR REPLACE FUNCTION public.recompute_obra_resumen_metricas(p_obra_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_tiene_evento_sobrenatural boolean;
  v_ficha                     jsonb;
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
      fo.v_ini,
      fo.v_fin,
      fo.n_versos,
      fo.forma_slug,
      fo.tipo_forma,
      row_number() over (order by fo.v_ini) as rn
    from public.formas_de_la_obra(p_obra_id) fo
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
    -- **Una secuencia sin forma no entra en el reparto.** Hoy son las 92 obras del corpus legado, y
    -- una clave nula no cabe en un objeto: `jsonb_object_agg` lo rechaza y se lleva el recompute
    -- entero por delante. El barcode sí las conserva, porque ahí lo que se dibuja es el pasaje.
    select forma_slug, sum(n_versos)::int as n_versos
    from seq_formas
    where forma_slug is not null
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
  from public.formas_de_la_obra(p_obra_id) t;

  -- 5. Metros presentes.
  --
  -- **Salen de dos sitios y hay que sumarlos.** La medida de toda forma isosilábica es
  -- arquitectura y no se pregunta —una obra entera de redondillas no tendría ninguna respuesta de
  -- metro—, y donde sí se pregunta, la medida es lo que el editor eligió. Así que se unen lo que
  -- la arquitectura fija en sus esquemas y lo que la anotación responde.
  select array_agg(distinct slug) filter (where slug is not null)
  into v_metros_presentes
  from (
    select m.slug
    from public.anotaciones_metricas a
    join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
    join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
    join public.esquema_metrico_posiciones emp on emp.esquema_metrico_id = em.esquema_metrico_id
    join public.metros m on m.metro_id = emp.metro_id
    where sm.obra_id = p_obra_id

    union

    select m.slug
    from public.anotaciones_metricas a
    join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
    join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
    join public.metros m on m.metro_id = e.metro_id
    where sm.obra_id = p_obra_id
  ) metros;

  -- 6. Variaciones presentes (caracterizacion_rango usados en secuencias de la obra)
  select array_agg(distinct v.termino) filter (where v.termino is not null)
  into v_variaciones_presentes
  from public.secuencias_metricas sm
  join public.secuencias_caracterizaciones_rango scr on scr.secuencia_id = sm.secuencia_id
  join public.vocabularios v on v.termino_id = scr.tipo_caracterizacion_rango_id
  where sm.obra_id = p_obra_id;

  -- 6b. Los esquemas de rima elegidos, que son el filtro que antes daban los subtipos de estrofa.
  --
  -- Las 379 filas de `secuencias_subtipos_estrofa` eran todas esquemas de quintilla: nombraban la
  -- disposición de la rima, que en el catálogo nuevo es una respuesta y no un término aparte.
  select array_agg(distinct er.slug) filter (where er.slug is not null)
  into v_subtipos_presentes
  from public.anotaciones_metricas a
  join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
  join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
  join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
  where sm.obra_id = p_obra_id;

  -- 7. n_formas_distintas y p_max
  select
    count(distinct forma_slug)::int,
    max(pct)
  into v_n_formas_distintas, v_p_max
  from (
    select
      fo.forma_slug,
      sum(fo.n_versos)::float / nullif(v_total_versos, 0) as pct
    from public.formas_de_la_obra(p_obra_id) fo
    group by fo.forma_slug
  ) forma_pcts;

  -- 8. Número efectivo de formas: exp(H) con H = −Σ p_i · ln(p_i)
  select exp(-sum(p_i * ln(nullif(p_i, 0))))
  into v_numero_efectivo_formas
  from (
    select sum(fo.n_versos)::float / nullif(v_total_versos, 0) as p_i
    from public.formas_de_la_obra(p_obra_id) fo
    where fo.forma_slug is not null
    group by fo.forma_slug
  ) proportions;

  -- 9. Densidad de transiciones
  v_densidad_transiciones := case
    when v_total_versos > 0 then (v_n_secuencias::float / v_total_versos) * 100
    else 0
  end;

  -- 10. % cantado (caracterizacion_rango = 'cantado')
  -- **En porcentaje, como dice su nombre.** Guardaba la fraccion -0,0077 para una obra con el
  -- 0,77 % cantado-, y nadie la leia todavia, asi que se corrige antes de que alguien la pinte.
  select coalesce(
    sum(scr.v_fin - scr.v_ini + 1)::float * 100 / nullif(v_total_versos, 0),
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
  -- **La ficha se guarda entera.** Es la misma que devuelve `ficha_publica_json`, asi que el
  -- navegador puede cargarla de una vez en lugar de pedirle a la base que la construya en cada
  -- visita. Lo que aqui se guarda es **lo que ve un anonimo**: el permiso no es contenido, y lo que
  -- solo ven admin, IP o el editor asignado se resuelve aparte.
  select coalesce(sm.evento_sobrenatural, false)
  into v_tiene_evento_sobrenatural
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id and sm.evento_sobrenatural
  limit 1;
  v_tiene_evento_sobrenatural := coalesce(v_tiene_evento_sobrenatural, false);

  v_ficha := public.ficha_publica_json(p_obra_id, false);

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
    tiene_evento_sobrenatural, ficha,
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
    v_tiene_evento_sobrenatural, v_ficha,
    false, now()
  )
  on conflict (obra_id) do update set
    tiene_evento_sobrenatural   = excluded.tiene_evento_sobrenatural,
    ficha                       = excluded.ficha,
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
$function$;

-- **Se ejecuta.** Se recomputa una obra anotada y se comprueba que lo guardado es identico a lo que
-- devuelve la productora: si dejaran de serlo, el buscador y la ficha volverian a separarse.
do $guarda$
declare
  v_obra uuid;
  v_guardada jsonb;
  v_viva jsonb;
  v_secuencias int;
begin
  select sm.obra_id into v_obra
  from public.secuencias_metricas sm
  join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
  group by sm.obra_id
  order by count(*) desc
  limit 1;
  if v_obra is null then
    raise notice 'No hay ninguna obra anotada: nada que comprobar.';
    return;
  end if;

  perform public.recompute_obra_resumen_metricas(v_obra);

  select ficha into v_guardada from public.obras_resumen where obra_id = v_obra;
  v_viva := public.ficha_publica_json(v_obra, false);

  if v_guardada is null then
    raise exception 'El recompute no guardo la ficha de %', v_obra;
  end if;
  if v_guardada is distinct from v_viva then
    raise exception 'Lo guardado y lo vivo difieren para %', v_obra;
  end if;

  v_secuencias := jsonb_array_length(v_guardada->'metrica'->'secuencias');
  if v_secuencias = 0 then
    raise exception 'La ficha guardada de % no trae secuencias', v_obra;
  end if;

  if to_regclass('public.obras_anotacion_nueva') is not null then
    raise exception 'La tabla del interruptor sigue ahi';
  end if;

  raise notice 'Ficha guardada para %: % secuencias, % de JSON.',
    v_obra, v_secuencias, pg_size_pretty(length(v_guardada::text)::bigint);
end;
$guarda$;
