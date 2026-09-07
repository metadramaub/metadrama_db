-- La precomputación lee el catálogo nuevo
--
-- Todo el perfil métrico de una obra —el barcode, el reparto de formas, los arrays de filtro, el
-- número efectivo— entraba por el mismo sitio repetido cuatro veces: el join de
-- `secuencias_metricas` con `vocabularios` a través de `estrofa_tipo_id`, que es el vocabulario
-- legado. Mientras eso fuera así, **una obra anotada con el catálogo nuevo tenía perfil vacío**, y
-- no había manera de publicar ninguna.
--
-- Aquí se sustituye. No se conserva la lectura anterior: la ficha va a cambiar con ella, y mantener
-- dos maneras de responder a «qué forma realiza esta secuencia» era garantizar que se separaran.
-- **Las 92 obras del corpus se quedan sin perfil hasta que se migren**, obra por obra y con sus
-- editores. Los agregados degradan a vacío y no revientan: es la misma degradación que ya tenían
-- las secuencias sin forma.
--
-- **Un solo domicilio.** `formas_de_la_obra()` es ahora el único sitio donde se dice qué forma,
-- qué arquitectura y qué tradición realiza cada secuencia, y de ella leen el recompute de la obra
-- y los dos ayudantes del perfil de autor. Antes ese join estaba escrito seis veces.
--
-- Tres decisiones que se ven en la pantalla pública:
--
-- * **El color del barcode sale de la tradición.** Cada tramo llevaba `tipo_forma`, con los valores
--   `forma_espanola` y `forma_italiana`, y la ficha colorea con eso. Se derivan de la tradición de
--   la forma, que desde el 7 de septiembre de 2026 es una y solo una. Los dos tramos sin forma van
--   sin valor, que es lo que les corresponde.
-- * **Los metros se suman de dos sitios.** La medida de toda forma isosilábica es arquitectura y no
--   se pregunta, así que con solo lo respondido una obra entera de redondillas se quedaría sin
--   metros. Se unen los que la arquitectura fija en sus esquemas y los que la anotación responde.
-- * **Los subtipos pasan a ser los esquemas de rima elegidos.** Las 379 filas de
--   `secuencias_subtipos_estrofa` eran todas esquemas de quintilla: nombraban la disposición de la
--   rima, que en el catálogo nuevo es una respuesta y no un término aparte.
--
-- Lo que no depende del vocabulario métrico no se toca: caracterizaciones, porcentaje de cantado,
-- intervenciones, versos partidos y cambio de espacio siguen leyéndose igual.

begin;

-- ---------------------------------------------------------------------------
-- Qué forma realiza cada secuencia
-- ---------------------------------------------------------------------------

create or replace function public.formas_de_la_obra(p_obra_id uuid)
returns table (
	secuencia_id uuid,
	v_ini integer,
	v_fin integer,
	n_versos integer,
	forma_slug text,
	arquitectura_slug text,
	tipo_forma text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
	-- **Una secuencia, una anotación.** La tabla admite varias por orden, y si alguna vez las
	-- hubiera, el perfil tiene que contar la secuencia una sola vez: manda la primera.
	select distinct on (sm.secuencia_id)
		sm.secuencia_id,
		sm.v_ini,
		sm.v_fin,
		sm.n_versos,
		f.slug as forma_slug,
		arq.slug as arquitectura_slug,
		case t.nombre
			when 'Española' then 'forma_espanola'
			when 'Italiana' then 'forma_italiana'
		end as tipo_forma
	from public.secuencias_metricas sm
	left join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
	left join public.formas_metricas f on f.forma_id = a.forma_id
	left join public.arquitecturas_forma arq on arq.arquitectura_id = a.arquitectura_id
	left join public.formas_tradiciones ft on ft.forma_id = f.forma_id
	left join public.tradiciones_metricas t on t.tradicion_id = ft.tradicion_id
	where sm.obra_id = p_obra_id
	order by sm.secuencia_id, a.orden nulls last;
$function$;

comment on function public.formas_de_la_obra(uuid) is
	'Qué forma, arquitectura y tradición realiza cada secuencia de una obra, según el catálogo nuevo. Único sitio donde vive ese emparejamiento.';

-- ---------------------------------------------------------------------------
-- El perfil de una obra
-- ---------------------------------------------------------------------------

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
$function$;

-- ---------------------------------------------------------------------------
-- Los dos ayudantes del perfil de autor
--
-- `recompute_autor_resumen` no se toca: lee `obras_resumen.perfil_formas` y estas dos, que eran los
-- otros dos sitios donde estaba escrito el join legado. El de «hijos» agrupaba por el término hijo
-- —la variedad concreta, `soneto_regular_ABBAABBACDCDCD`—, y su equivalente nuevo es la
-- arquitectura, que es lo que la forma tiene debajo.
-- ---------------------------------------------------------------------------

create or replace function public.perfil_formas_rango(p_obra_id uuid, p_v_ini integer, p_v_fin integer)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
	select coalesce(jsonb_object_agg(forma_slug, versos), '{}'::jsonb)
	from (
		select fo.forma_slug, sum(fo.n_versos)::int as versos
		from public.formas_de_la_obra(p_obra_id) fo
		where fo.v_ini >= p_v_ini
			and fo.v_fin <= p_v_fin
			and fo.forma_slug is not null
		group by fo.forma_slug
	) t;
$function$;

create or replace function public.perfil_formas_hijos_rango(p_obra_id uuid, p_v_ini integer default null::integer, p_v_fin integer default null::integer)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
	select coalesce(jsonb_object_agg(arquitectura_slug, versos), '{}'::jsonb)
	from (
		select fo.arquitectura_slug, sum(fo.n_versos)::int as versos
		from public.formas_de_la_obra(p_obra_id) fo
		where (p_v_ini is null or fo.v_ini >= p_v_ini)
			and (p_v_fin is null or fo.v_fin <= p_v_fin)
			and fo.arquitectura_slug is not null
		group by fo.arquitectura_slug
	) t;
$function$;

-- ---------------------------------------------------------------------------
-- La guarda ejecuta lo que toca
--
-- Tres funciones acaban de reescribirse y ninguna se revalida al aplicarse: hay que llamarlas. Se
-- comprueban las dos mitades del cambio —que una obra anotada con el catálogo nuevo **tiene**
-- perfil, y que una anotada con el legado **degrada a vacío sin romperse**— y que la ficha pública
-- sigue ejecutándose.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_nueva uuid;
	v_legada uuid;
	v_resumen public.obras_resumen%rowtype;
	v_admin uuid;
	v_ficha jsonb;
begin
	-- Una obra anotada con el catálogo nuevo.
	select o.obra_id into v_nueva
	from public.obras o
	where exists (
		select 1
		from public.secuencias_metricas sm
		join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
		where sm.obra_id = o.obra_id
	)
	limit 1;

	if v_nueva is null then
		raise exception 'No hay ninguna obra anotada con el catálogo nuevo: la precomputación no se puede comprobar.';
	end if;

	perform public.recompute_obra_resumen(v_nueva);
	select * into v_resumen from public.obras_resumen where obra_id = v_nueva;

	if v_resumen.perfil_formas is null or v_resumen.perfil_formas = '{}'::jsonb then
		raise exception 'La obra % está anotada y su perfil de formas salió vacío', v_nueva;
	end if;
	if v_resumen.tramos is null or v_resumen.tramos = '[]'::jsonb then
		raise exception 'La obra % está anotada y su barcode salió vacío', v_nueva;
	end if;
	if v_resumen.metros_presentes is null or array_length(v_resumen.metros_presentes, 1) is null then
		raise exception 'La obra % está anotada y no declara ningún metro', v_nueva;
	end if;
	if v_resumen.n_formas_distintas is null or v_resumen.n_formas_distintas = 0 then
		raise exception 'La obra % está anotada y no cuenta ninguna forma', v_nueva;
	end if;

	raise notice 'Obra anotada %: % formas distintas, % metros, % tramos',
		v_nueva,
		v_resumen.n_formas_distintas,
		array_length(v_resumen.metros_presentes, 1),
		jsonb_array_length(v_resumen.tramos);

	-- Una obra del corpus legado: tiene secuencias y ninguna anotación.
	select o.obra_id into v_legada
	from public.obras o
	where exists (select 1 from public.secuencias_metricas sm where sm.obra_id = o.obra_id)
	  and not exists (
		select 1
		from public.secuencias_metricas sm
		join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
		where sm.obra_id = o.obra_id
	  )
	limit 1;

	if v_legada is not null then
		perform public.recompute_obra_resumen(v_legada);
		select * into v_resumen from public.obras_resumen where obra_id = v_legada;

		if v_resumen.perfil_formas <> '{}'::jsonb then
			raise exception 'La obra legada % no debería tener perfil todavía', v_legada;
		end if;
		if v_resumen.n_secuencias = 0 then
			raise exception 'La obra legada % perdió sus secuencias al recomputar', v_legada;
		end if;

		raise notice 'Obra legada %: % secuencias contadas y perfil vacío, como toca',
			v_legada, v_resumen.n_secuencias;
	end if;

	-- Y la ficha, que es quien lo lee.
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
	limit 1;

	if v_admin is not null then
		perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
		if public.can_view_obra_ficha_publica(v_nueva, true) then
			v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_nueva, true);
			if v_ficha is null then
				raise exception 'La ficha de la obra anotada % devolvió nulo', v_nueva;
			end if;
			raise notice 'Ficha comprobada sobre la obra anotada.';
		end if;
		perform set_config('request.jwt.claims', '', true);
	end if;
end
$guarda$;

commit;
