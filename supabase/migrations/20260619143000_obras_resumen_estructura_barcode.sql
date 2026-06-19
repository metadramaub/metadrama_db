-- Fase 5d: cortes de estructura para el mini-barcode del catálogo.
--
-- Añade al resumen público dos payloads pequeños:
--   - jornadas_tramos: [{i,f,n}]
--   - cuadros_tramos:  [{i,f,n,j}]
--
-- Se calculan al pulsar "Actualizar datos públicos" junto con el resto del resumen.

begin;

alter table public.obras_resumen
  add column if not exists jornadas_tramos jsonb,
  add column if not exists cuadros_tramos jsonb;

create or replace function public.recompute_obra_resumen_estructura(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.obras_resumen
  set
    jornadas_tramos = (
      select coalesce(
        jsonb_agg(
          jsonb_build_object('i', j.v_ini, 'f', j.v_fin, 'n', j.jornada_num)
          order by j.v_ini, j.v_fin, j.jornada_num
        ),
        '[]'::jsonb
      )
      from public.jornadas j
      where j.obra_id = p_obra_id
    ),
    cuadros_tramos = (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'i', c.v_ini,
            'f', c.v_fin,
            'n', c.cuadro_num,
            'j', j.jornada_num
          )
          order by c.v_ini, c.v_fin, j.jornada_num, c.cuadro_num
        ),
        '[]'::jsonb
      )
      from public.cuadros c
      join public.jornadas j on j.jornada_id = c.jornada_id
      where j.obra_id = p_obra_id
    )
  where obra_id = p_obra_id;
end;
$$;

-- Conserva la función grande existente como cálculo métrico interno y deja el
-- nombre público como wrapper estable para endpoints, dashboard y llamadas manuales.
do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'recompute_obra_resumen'
      and pg_get_function_arguments(p.oid) = 'p_obra_id uuid'
  )
  and not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'recompute_obra_resumen_metricas'
      and pg_get_function_arguments(p.oid) = 'p_obra_id uuid'
  ) then
    execute 'alter function public.recompute_obra_resumen(uuid) rename to recompute_obra_resumen_metricas';
  end if;
end $$;

create or replace function public.recompute_obra_resumen(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recompute_obra_resumen_metricas(p_obra_id);
  perform public.recompute_obra_resumen_estructura(p_obra_id);
end;
$$;

create or replace function public.recompute_all()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_obra_id uuid;
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
end;
$$;

grant execute on function public.recompute_obra_resumen(uuid) to authenticated;
grant execute on function public.recompute_obra_resumen(uuid) to service_role;
grant execute on function public.recompute_obra_resumen_estructura(uuid) to authenticated;
grant execute on function public.recompute_obra_resumen_estructura(uuid) to service_role;
grant execute on function public.recompute_all() to authenticated;
grant execute on function public.recompute_all() to service_role;

commit;
