-- Reparto editorial atómico, con comprobación de la selección que revisó el gestor.
create table if not exists public.asignaciones_historial (
  cambio_id uuid primary key default gen_random_uuid(),
  lote_id uuid not null,
  obra_id uuid not null references public.obras(obra_id) on delete cascade,
  realizado_por uuid not null references public.editores(user_id),
  operacion text not null check (operacion in ('editor', 'add_reviewer', 'remove_reviewer')),
  antes jsonb not null,
  despues jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.asignaciones_historial enable row level security;
revoke all on public.asignaciones_historial from anon, authenticated;
grant select on public.asignaciones_historial to authenticated;
grant all on public.asignaciones_historial to service_role;
drop policy if exists asignaciones_historial_gestores on public.asignaciones_historial;
create policy asignaciones_historial_gestores on public.asignaciones_historial
for select to authenticated using (exists (
  select 1 from public.editores e join public.vocabularios v on v.termino_id = e.role
  where e.user_id = auth.uid() and coalesce(e.activo, true) and lower(v.termino) in ('admin', 'ip')
));
create index if not exists asignaciones_historial_obra_fecha
  on public.asignaciones_historial(obra_id, created_at desc);

create or replace function public.gestionar_asignaciones_lote(
  p_operacion text, p_destino uuid, p_obras jsonb
) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_lote uuid := gen_random_uuid();
  v_peticion record;
  v_obra public.obras%rowtype;
  v_anteriores uuid[];
  v_esperados uuid[];
  v_nuevos uuid[];
  v_antes jsonb;
  v_despues jsonb;
  v_cambios integer := 0;
begin
  if not exists (
    select 1 from public.editores e join public.vocabularios v on v.termino_id = e.role
    where e.user_id = v_actor and coalesce(e.activo, true) and lower(v.termino) in ('admin', 'ip')
  ) then
    raise exception 'Solo administración o IP pueden cambiar asignaciones.' using errcode = '42501';
  end if;
  if p_operacion is null or p_operacion not in ('editor', 'add_reviewer', 'remove_reviewer') then
    raise exception 'Operación de asignación inválida.' using errcode = '22023';
  end if;
  if p_obras is null or jsonb_typeof(p_obras) <> 'array' then
    raise exception 'Selecciona las obras.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_obras) not between 1 and 500 then
    raise exception 'Selecciona entre 1 y 500 obras.' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_obras) x
    where jsonb_typeof(x) <> 'object' or not (x ? 'obra_id' and x ? 'editor_asignado' and x ? 'reviewer_ids')
      or x->>'obra_id' is null or jsonb_typeof(x->'reviewer_ids') <> 'array'
  ) then
    raise exception 'La selección está incompleta. Recarga la página.' using errcode = '22023';
  end if;
  if (select count(distinct (x->>'obra_id')::uuid) from jsonb_array_elements(p_obras) x) <> jsonb_array_length(p_obras) then
    raise exception 'La selección contiene obras repetidas.' using errcode = '22023';
  end if;
  -- Bloquea el destino para impedir que se deshabilite durante el reparto.
  perform 1 from public.editores e where e.user_id = p_destino
    and (p_operacion = 'remove_reviewer' or coalesce(e.activo, true)) for share;
  if not found then
    raise exception 'El editor de destino no existe o está deshabilitado.' using errcode = '22023';
  end if;
  -- Orden estable: dos lotes solapados no toman las obras en orden inverso.
  for v_peticion in
    select x from jsonb_array_elements(p_obras) x order by (x->>'obra_id')::uuid
  loop
    select * into v_obra from public.obras where obra_id = (v_peticion.x->>'obra_id')::uuid for update;
    if not found then
      raise exception 'Una obra ya no existe. Recarga la página.' using errcode = '40001';
    end if;
    select coalesce(array_agg(r.revisor_id order by r.revisor_id), '{}'::uuid[]) into v_anteriores
      from public.obras_revisores r where r.obra_id = v_obra.obra_id;
    select coalesce(array_agg(value::uuid order by value::uuid), '{}'::uuid[]) into v_esperados
      from jsonb_array_elements_text(v_peticion.x->'reviewer_ids');
    if v_obra.editor_asignado is distinct from (v_peticion.x->>'editor_asignado')::uuid
      or v_anteriores is distinct from v_esperados then
      raise exception 'Han cambiado las asignaciones de «%». Recarga la página y revisa el lote.', v_obra.titulo using errcode = '40001';
    end if;
    v_antes := jsonb_build_object('editor_asignado', v_obra.editor_asignado, 'reviewer_ids', v_anteriores);
    if p_operacion = 'editor' then
      -- El editor responsable no puede ser también revisor de la misma obra.
      delete from public.obras_revisores where obra_id = v_obra.obra_id and revisor_id = p_destino;
      if v_obra.editor_asignado is distinct from p_destino then
        update public.obras set editor_asignado = p_destino where obra_id = v_obra.obra_id;
      end if;
      v_obra.editor_asignado := p_destino;
    elsif p_operacion = 'add_reviewer' then
      if v_obra.editor_asignado = p_destino then
        raise exception '«%» ya tiene a esa persona como editor responsable. No puede revisar su propia obra.', v_obra.titulo using errcode = '22023';
      end if;
      insert into public.obras_revisores(obra_id, revisor_id, asignado_por)
        values (v_obra.obra_id, p_destino, v_actor) on conflict (obra_id, revisor_id) do nothing;
    else
      delete from public.obras_revisores where obra_id = v_obra.obra_id and revisor_id = p_destino;
    end if;
    select coalesce(array_agg(r.revisor_id order by r.revisor_id), '{}'::uuid[]) into v_nuevos
      from public.obras_revisores r where r.obra_id = v_obra.obra_id;
    v_despues := jsonb_build_object('editor_asignado', v_obra.editor_asignado, 'reviewer_ids', v_nuevos);
    if v_antes is distinct from v_despues then
      insert into public.asignaciones_historial(lote_id, obra_id, realizado_por, operacion, antes, despues)
        values (v_lote, v_obra.obra_id, v_actor, p_operacion, v_antes, v_despues);
      v_cambios := v_cambios + 1;
    end if;
  end loop;
  return v_cambios;
end;
$$;
revoke all on function public.gestionar_asignaciones_lote(text, uuid, jsonb) from public, anon;
grant execute on function public.gestionar_asignaciones_lote(text, uuid, jsonb) to authenticated;
