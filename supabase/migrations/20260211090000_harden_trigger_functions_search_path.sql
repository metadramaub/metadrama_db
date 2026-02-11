-- Security hardening for trigger functions flagged by Supabase Advisor:
-- lint 0011 function_search_path_mutable

create or replace function public.actualizar_autoria_obra()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_obra_id uuid;
begin
  -- Get obra_id from the affected rango
  select r.obra_id into v_obra_id
  from public.rangos r
  where r.rango_id = coalesce(new.rango_id, old.rango_id);

  -- Refresh obras.autoria for the affected obra
  update public.obras o
  set autoria = (
    select array_agg(distinct a.nombre_completo order by a.nombre_completo)
    from public.rangos r
    join public.rangos_autores ra on ra.rango_id = r.rango_id
    join public.autores a on a.autor_id = ra.autor_id
    where r.obra_id = v_obra_id
  )
  where o.obra_id = v_obra_id;

  return coalesce(new, old);
end;
$$;


create or replace function public.actualizar_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;
