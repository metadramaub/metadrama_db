-- Fase 3 del plan de precomputación (docs/plan-precomputacion-implementacion.md):
-- Perfil métrico de autor (autores_resumen).
--
-- Decisiones metodológicas en docs/metodologia-perfil-metrico.md (§2):
--   - Regla mono-autor (§2.1): una unidad cuenta para el autor X si su grupo de atribución tiene
--     EXACTAMENTE una atribución perfil_metrico=true y esa atribución tiene EXACTAMENTE un autor (X).
--     Grupo de obra -> toda la obra; grupo de jornada -> esa jornada. El scope lo fija el grupo
--     (grupos_atribucion tiene XOR obra_id/jornada_id), no las columnas legadas de atribuciones.
--   - Ponderación por extensión (§2.2): perfil_formas = suma de versos por forma.
--   - Dos medidas de diversidad (§2.3): la media solo sobre obras enteras (jornadas excluidas por
--     sesgo de muestra; NULL si no hay obras enteras); el agregado sobre todo el material.
--   - Dos alcances (§2.4): publico (publicadas+visibles) y completo (todas las publicadas, admin/IP).
--
-- Aplicar a mano por el SQL Editor del panel (puerto 5432 bloqueado). Registrar luego en
-- supabase_migrations.schema_migrations con INSERT manual y editar database.types.ts a mano.

begin;

-- ============================================================
-- Tabla autores_resumen (dos filas por autor: alcance publico/completo)
-- ============================================================
create table if not exists public.autores_resumen (
  autor_id uuid not null references public.autores(autor_id) on delete cascade,
  alcance  text  not null check (alcance in ('publico', 'completo')),

  -- Señales crudas (la banda de fiabilidad se deriva en lectura, §2.5)
  n_obras_completas  int not null default 0,
  n_jornadas_sueltas int not null default 0,
  total_versos_autor int not null default 0,

  -- Perfil agregado por extensión: {forma_slug: n_versos} (obras enteras + jornadas mono-autor)
  perfil_formas jsonb not null default '{}'::jsonb,

  -- Diversidad: media solo sobre obras enteras (NULL si no hay); agregado sobre todo el material
  numero_efectivo_formas_medio    float,
  numero_efectivo_formas_agregado float,

  metrica_sucia  boolean not null default false,
  actualizado_en timestamptz not null default now(),

  primary key (autor_id, alcance)
);

create index if not exists idx_autores_resumen_alcance on public.autores_resumen (alcance);

-- ============================================================
-- RLS: las filas 'publico' las lee cualquiera (son seguras por construcción: solo obras
-- visibles); las 'completo' solo admin/IP. Escritura solo via funciones SECURITY DEFINER.
-- ============================================================
alter table public.autores_resumen enable row level security;

drop policy if exists "autores_resumen_anon_select" on public.autores_resumen;
create policy "autores_resumen_anon_select"
  on public.autores_resumen for select
  to anon
  using (alcance = 'publico');

drop policy if exists "autores_resumen_auth_select" on public.autores_resumen;
create policy "autores_resumen_auth_select"
  on public.autores_resumen for select
  to authenticated
  using (
    alcance = 'publico'
    or (alcance = 'completo' and public.auth_is_admin_or_ip())
  );

-- ============================================================
-- Helper: número efectivo de formas a partir de un perfil {forma: versos}.
--   exp(-Σ pᵢ·ln pᵢ) sobre las proporciones de versos. NULL si el perfil está vacío.
-- ============================================================
create or replace function public.numero_efectivo_from_perfil(p_perfil jsonb)
returns float
language sql
immutable
as $$
  with entries as (
    select (value)::float as versos
    from jsonb_each_text(coalesce(p_perfil, '{}'::jsonb))
    where (value)::float > 0
  ),
  tot as (select sum(versos) as total from entries)
  select case
    when coalesce((select total from tot), 0) > 0
    then exp(-sum((e.versos / t.total) * ln(e.versos / t.total)))
    else null
  end
  from entries e cross join tot t;
$$;

-- ============================================================
-- Helper: perfil_formas {forma: versos} restringido a un rango de versos de una obra.
--   Para unidades de scope jornada (§2.1). Misma resolución de forma raíz (padre si existe)
--   que recompute_obra_resumen.
-- ============================================================
create or replace function public.perfil_formas_rango(p_obra_id uuid, p_v_ini int, p_v_fin int)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_object_agg(forma_slug, versos), '{}'::jsonb)
  from (
    select coalesce(ep.termino, est.termino) as forma_slug, sum(sm.n_versos)::int as versos
    from public.secuencias_metricas sm
    left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
    left join public.vocabularios ep  on ep.termino_id  = est.termino_padre_id
    where sm.obra_id = p_obra_id
      and sm.v_ini >= p_v_ini
      and sm.v_fin <= p_v_fin
    group by coalesce(ep.termino, est.termino)
    having coalesce(ep.termino, est.termino) is not null
  ) t;
$$;

-- ============================================================
-- Helper: unidades mono-autor con perfil_metrico (§2.1).
--   (autor_id, scope, obra_id, jornada_id, jornada_v_ini, jornada_v_fin)
-- ============================================================
create or replace function public.perfil_metrico_unidades()
returns table (
  autor_id      uuid,
  scope         text,
  obra_id       uuid,
  jornada_id    uuid,
  jornada_v_ini int,
  jornada_v_fin int
)
language sql
stable
security definer
set search_path = public
as $$
  with grupos_mono as (
    -- grupos con EXACTAMENTE una atribución perfil_metrico=true
    -- (uuid no tiene agregado min/max; como count=1, array_agg[1] toma el único valor)
    select a.grupo_atribucion_id, (array_agg(a.atribucion_id))[1] as atribucion_id
    from public.atribuciones a
    where a.perfil_metrico
    group by a.grupo_atribucion_id
    having count(*) = 1
  ),
  atrib_mono as (
    -- de esas, las que tienen EXACTAMENTE un autor
    select gm.grupo_atribucion_id, gm.atribucion_id, (array_agg(aa.autor_id))[1] as autor_id
    from grupos_mono gm
    join public.atribucion_autores aa on aa.atribucion_id = gm.atribucion_id
    group by gm.grupo_atribucion_id, gm.atribucion_id
    having count(*) = 1
  )
  select
    am.autor_id,
    case when g.obra_id is not null then 'obra' else 'jornada' end as scope,
    coalesce(g.obra_id, j.obra_id) as obra_id,
    g.jornada_id,
    j.v_ini,
    j.v_fin
  from atrib_mono am
  join public.grupos_atribucion g on g.grupo_atribucion_id = am.grupo_atribucion_id
  left join public.jornadas j on j.jornada_id = g.jornada_id;
$$;

-- ============================================================
-- recompute_autor_resumen(autor_id): recalcula las dos filas (publico/completo).
-- ============================================================
create or replace function public.recompute_autor_resumen(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alcance  text;
  v_perfil   jsonb;
  v_total    int;
  v_n_obras  int;
  v_n_jorn   int;
  v_ne_medio float;
  v_ne_agg   float;
  v_n_units  int;
begin
  foreach v_alcance in array array['publico', 'completo']
  loop
    with units as (
      select u.scope, u.obra_id, u.jornada_v_ini, u.jornada_v_fin
      from public.perfil_metrico_unidades() u
      where u.autor_id = p_autor_id
    ),
    elig as (
      -- alcance completo = obra publicada; alcance publico = publicada y visible
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
        case when e.scope = 'obra' then orr.numero_efectivo_formas else null end as ne_obra
      from elig e
      left join public.obras_resumen orr on orr.obra_id = e.obra_id
    ),
    unit_calc as (
      select
        up.scope,
        up.perfil,
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
    agg as (
      select
        coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_agg,
        coalesce(sum(versos), 0)::int as total_versos
      from perfil_pairs
    ),
    counts as (
      select
        count(*) filter (where scope = 'obra')::int    as n_obras,
        count(*) filter (where scope = 'jornada')::int as n_jorn,
        avg(ne_obra) filter (where scope = 'obra')      as ne_medio,
        count(*)::int                                    as n_units
      from unit_calc
    )
    select agg.perfil_agg, agg.total_versos, counts.n_obras, counts.n_jorn, counts.ne_medio, counts.n_units
    into v_perfil, v_total, v_n_obras, v_n_jorn, v_ne_medio, v_n_units
    from agg cross join counts;

    if coalesce(v_n_units, 0) = 0 then
      -- el autor no tiene unidades en este alcance: no debe haber fila
      delete from public.autores_resumen
      where autor_id = p_autor_id and alcance = v_alcance;
    else
      v_ne_agg := public.numero_efectivo_from_perfil(v_perfil);

      insert into public.autores_resumen (
        autor_id, alcance,
        n_obras_completas, n_jornadas_sueltas, total_versos_autor,
        perfil_formas, numero_efectivo_formas_medio, numero_efectivo_formas_agregado,
        metrica_sucia, actualizado_en
      ) values (
        p_autor_id, v_alcance,
        coalesce(v_n_obras, 0), coalesce(v_n_jorn, 0), coalesce(v_total, 0),
        coalesce(v_perfil, '{}'::jsonb), v_ne_medio, v_ne_agg,
        false, now()
      )
      on conflict (autor_id, alcance) do update set
        n_obras_completas               = excluded.n_obras_completas,
        n_jornadas_sueltas              = excluded.n_jornadas_sueltas,
        total_versos_autor              = excluded.total_versos_autor,
        perfil_formas                   = excluded.perfil_formas,
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

-- ============================================================
-- recompute_obra_y_autores(obra_id): recompute de la obra + de sus autores afectados.
--   Lo llama el botón "Actualizar datos públicos" (encadenado, §2.6).
-- ============================================================
create or replace function public.recompute_obra_y_autores(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_autor uuid;
begin
  perform public.recompute_obra_resumen(p_obra_id);

  for v_autor in
    select distinct u.autor_id
    from public.perfil_metrico_unidades() u
    where u.obra_id = p_obra_id
  loop
    perform public.recompute_autor_resumen(v_autor);
  end loop;
end;
$$;

grant execute on function public.recompute_obra_y_autores(uuid) to authenticated;
grant execute on function public.recompute_obra_y_autores(uuid) to service_role;

-- ============================================================
-- Marca autores sucios al cambiar visibilidad/estado de una obra (§2.6).
--   Afecta solo al alcance 'publico'; recálculo diferido (siguiente botón o recompute_all).
-- ============================================================
create or replace function public.mark_autores_resumen_dirty_on_obra()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (new.visible_publico is distinct from old.visible_publico)
     or (new.estado is distinct from old.estado) then
    update public.autores_resumen
    set metrica_sucia = true
    where autor_id in (
      select distinct u.autor_id
      from public.perfil_metrico_unidades() u
      where u.obra_id = new.obra_id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_mark_autores_dirty_on_obra on public.obras;
create trigger trg_mark_autores_dirty_on_obra
  after update of visible_publico, estado on public.obras
  for each row execute function public.mark_autores_resumen_dirty_on_obra();

-- ============================================================
-- recompute_all(): reemplaza la versión previa para añadir la fase de autores.
--   1) resumen de cada obra publicada; 2) resumen de cada autor con unidades (una vez);
--   3) limpia autores sin unidades.
-- ============================================================
create or replace function public.recompute_all()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_obra_id      uuid;
  v_autor_id     uuid;
  v_publicado_id uuid;
begin
  select termino_id into v_publicado_id
  from public.vocabularios
  where categoria = 'estado' and lower(termino) = 'publicado'
  limit 1;

  if v_publicado_id is null then
    raise exception 'No existe estado=publicado en vocabularios';
  end if;

  for v_obra_id in
    select o.obra_id from public.obras o where o.estado = v_publicado_id
  loop
    perform public.recompute_obra_resumen(v_obra_id);
  end loop;

  for v_autor_id in
    select distinct u.autor_id from public.perfil_metrico_unidades() u
  loop
    perform public.recompute_autor_resumen(v_autor_id);
  end loop;

  delete from public.autores_resumen ar
  where not exists (
    select 1 from public.perfil_metrico_unidades() u where u.autor_id = ar.autor_id
  );
end;
$$;

grant execute on function public.recompute_all() to authenticated;
grant execute on function public.recompute_all() to service_role;

commit;
