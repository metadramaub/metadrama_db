-- Fase 2-bis (complemento): la estructura de la obra también ensucia el resumen.
--
-- La migración 20260618230000 ya cubría jornadas, pero no cuadros. Aunque el
-- resumen actual solo guarda n_jornadas, el mini-barcode del catálogo consume la
-- estructura publicada (jornadas/cuadros) y debe avisar si cambia tras publicar
-- datos públicos.

begin;

create or replace function public.mark_obra_resumen_dirty_by_cuadro()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_jornada_id uuid;
  v_obra_id uuid;
begin
  for v_jornada_id in
    select distinct jornada_id
    from (
      values
        (case when tg_op <> 'INSERT' then old.jornada_id else null end),
        (case when tg_op <> 'DELETE' then new.jornada_id else null end)
    ) as ids(jornada_id)
    where jornada_id is not null
  loop
    select j.obra_id
    into v_obra_id
    from public.jornadas j
    where j.jornada_id = v_jornada_id;

    if v_obra_id is not null then
      update public.obras_resumen
      set metrica_sucia = true
      where obra_id = v_obra_id;
    end if;
  end loop;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_mark_resumen_dirty_cuadros on public.cuadros;
create trigger trg_mark_resumen_dirty_cuadros
  after insert or update or delete on public.cuadros
  for each row execute function public.mark_obra_resumen_dirty_by_cuadro();

commit;
