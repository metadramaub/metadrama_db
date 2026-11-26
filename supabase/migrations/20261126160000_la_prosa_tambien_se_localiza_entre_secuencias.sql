-- La secuencia que guarda la marca decide su atribución. Los dos versos
-- localizan el pasaje, incluso cuando son los extremos de secuencias contiguas.
begin;

create or replace function public.prosa_localizacion_valida(
  p_secuencia uuid, p_anterior integer, p_posterior integer
)
returns boolean
language sql stable
set search_path = ''
as $funcion$
  select p_anterior < p_posterior and exists (
    select 1 from public.secuencias_metricas s
    where s.secuencia_id = p_secuencia and (
      (p_anterior >= s.v_ini and p_posterior <= s.v_fin)
      or (p_posterior - p_anterior = 1 and exists (
        select 1 from public.secuencias_metricas vecina
        where vecina.obra_id = s.obra_id and vecina.secuencia_id <> s.secuencia_id
          and (
            (s.v_fin = p_anterior and vecina.v_ini = p_posterior)
            or (vecina.v_fin = p_anterior and s.v_ini = p_posterior)
          )
      ))
    )
  );
$funcion$;

create or replace function public.comprobar_localizacion_prosa()
returns trigger
language plpgsql security definer
set search_path = ''
as $funcion$
declare
  v_marca record;
begin
  -- Al final de la transacción la marca puede haber vuelto a cambiar o haberse retirado.
  select c.*, s.obra_id, s.v_ini as inicio, s.v_fin as fin into v_marca
  from public.secuencias_caracterizaciones_rango c
  join public.secuencias_metricas s using (secuencia_id)
  join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
  where c.caracterizacion_rango_id = new.caracterizacion_rango_id
    and v.categoria = 'caracterizacion_rango' and v.termino = 'prosa';
  if not found then return null; end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_marca.obra_id::text, 20261126));
  if not public.prosa_localizacion_valida(v_marca.secuencia_id, v_marca.v_ini, v_marca.v_fin) then
    raise exception using errcode = '23514',
      message = 'La prosa debe quedar entre dos versos de la secuencia o en la frontera con una secuencia contigua de la misma obra.';
  end if;

  if (v_marca.v_ini < v_marca.inicio or v_marca.v_fin > v_marca.fin) and exists (
    select 1 from public.secuencias_caracterizaciones_rango c
    join public.secuencias_metricas s using (secuencia_id)
    where s.obra_id = v_marca.obra_id
      and c.tipo_caracterizacion_rango_id = v_marca.tipo_caracterizacion_rango_id
      and c.v_ini = v_marca.v_ini and c.v_fin = v_marca.v_fin
      and c.caracterizacion_rango_id <> v_marca.caracterizacion_rango_id
  ) then
    raise exception using errcode = '23505',
      message = 'Ya hay una marca de prosa en esa frontera. Edítala desde la secuencia a la que pertenece.';
  end if;
  return null;
end;
$funcion$;

create or replace function public.comprobar_prosa_al_cambiar_secuencia()
returns trigger
language plpgsql security definer
set search_path = ''
as $funcion$
declare
  v_obras uuid[];
  v_obra uuid;
begin
  if tg_op = 'UPDATE' and (old.v_ini, old.v_fin, old.obra_id)
      is not distinct from (new.v_ini, new.v_fin, new.obra_id) then
    return null;
  end if;
  v_obras := case when tg_op = 'DELETE' then array[old.obra_id]
    else array[old.obra_id, new.obra_id] end;
  for v_obra in select distinct id from unnest(v_obras) id where id is not null order by id loop
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_obra::text, 20261126));
    if exists (
      select 1 from public.secuencias_caracterizaciones_rango c
      join public.secuencias_metricas s using (secuencia_id)
      join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
      where s.obra_id = v_obra
        and v.categoria = 'caracterizacion_rango' and v.termino = 'prosa'
        and not public.prosa_localizacion_valida(c.secuencia_id, c.v_ini, c.v_fin)
    ) then
      raise exception using errcode = '23514',
        message = 'Este cambio deja una marca de prosa sin una localización válida. Revisa la marca antes de cambiar la secuencia.';
    end if;
  end loop;
  return null;
end;
$funcion$;

revoke execute on function public.prosa_localizacion_valida(uuid, integer, integer)
  from public, anon, authenticated;
revoke execute on function public.comprobar_localizacion_prosa() from public, anon, authenticated;
revoke execute on function public.comprobar_prosa_al_cambiar_secuencia() from public, anon, authenticated;

drop trigger if exists prosa_localizacion_valida on public.secuencias_caracterizaciones_rango;
create constraint trigger prosa_localizacion_valida
  after insert or update on public.secuencias_caracterizaciones_rango
  deferrable initially deferred for each row
  execute function public.comprobar_localizacion_prosa();

drop trigger if exists prosa_valida_al_cambiar_secuencia on public.secuencias_metricas;
create constraint trigger prosa_valida_al_cambiar_secuencia
  after update of v_ini, v_fin, obra_id or delete on public.secuencias_metricas
  deferrable initially deferred for each row
  execute function public.comprobar_prosa_al_cambiar_secuencia();

commit;
