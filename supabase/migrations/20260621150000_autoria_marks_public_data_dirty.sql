-- Marca datos publicos precomputados como sucios cuando cambia la autoria.
-- La autoria alimenta:
--   - ficha publica de obra (autores/fuentes de autoria)
--   - perfil metrico de autores cuando una propuesta tiene perfil_metrico=true
--   - listados publicos de autores

begin;

create or replace function public.resolve_obra_id_for_atribucion(p_atribucion_id uuid)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(a.obra_id, g.obra_id, j.obra_id)
  from public.atribuciones a
  left join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
  left join public.jornadas j on j.jornada_id = coalesce(a.jornada_id, g.jornada_id)
  where a.atribucion_id = p_atribucion_id
  limit 1;
$$;

create or replace function public.resolve_obra_id_for_grupo_atribucion(
  p_obra_id uuid,
  p_jornada_id uuid
)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    p_obra_id,
    (select j.obra_id from public.jornadas j where j.jornada_id = p_jornada_id limit 1)
  );
$$;

create or replace function public.mark_public_data_dirty_for_obra(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_obra_id is null then
    return;
  end if;

  update public.obras_resumen
  set metrica_sucia = true
  where obra_id = p_obra_id;

  update public.autores_resumen
  set metrica_sucia = true
  where autor_id in (
    select distinct u.autor_id
    from public.perfil_metrico_unidades() u
    where u.obra_id = p_obra_id
  );
end;
$$;

create or replace function public.mark_public_data_dirty_for_autor(p_autor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_autor_id is null then
    return;
  end if;

  update public.autores_resumen
  set metrica_sucia = true
  where autor_id = p_autor_id;
end;
$$;

create or replace function public.mark_public_data_dirty_by_grupo_atribucion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.mark_public_data_dirty_for_obra(
      public.resolve_obra_id_for_grupo_atribucion(old.obra_id, old.jornada_id)
    );
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.mark_public_data_dirty_for_obra(
      public.resolve_obra_id_for_grupo_atribucion(new.obra_id, new.jornada_id)
    );
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.mark_public_data_dirty_by_atribucion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.mark_public_data_dirty_for_obra(
      coalesce(
        public.resolve_obra_id_for_grupo_atribucion(old.obra_id, old.jornada_id),
        public.resolve_obra_id_for_atribucion(old.atribucion_id)
      )
    );
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.mark_public_data_dirty_for_obra(
      coalesce(
        public.resolve_obra_id_for_grupo_atribucion(new.obra_id, new.jornada_id),
        public.resolve_obra_id_for_atribucion(new.atribucion_id)
      )
    );
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.mark_public_data_dirty_by_atribucion_autor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.mark_public_data_dirty_for_obra(public.resolve_obra_id_for_atribucion(old.atribucion_id));
    perform public.mark_public_data_dirty_for_autor(old.autor_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.mark_public_data_dirty_for_obra(public.resolve_obra_id_for_atribucion(new.atribucion_id));
    perform public.mark_public_data_dirty_for_autor(new.autor_id);
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.mark_public_data_dirty_by_atribucion_evidencia()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.mark_public_data_dirty_for_obra(public.resolve_obra_id_for_atribucion(old.atribucion_id));
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.mark_public_data_dirty_for_obra(public.resolve_obra_id_for_atribucion(new.atribucion_id));
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_mark_public_data_dirty_grupos_atribucion on public.grupos_atribucion;
create trigger trg_mark_public_data_dirty_grupos_atribucion
  after insert or update or delete on public.grupos_atribucion
  for each row execute function public.mark_public_data_dirty_by_grupo_atribucion();

drop trigger if exists trg_mark_public_data_dirty_atribuciones on public.atribuciones;
create trigger trg_mark_public_data_dirty_atribuciones
  after insert or update or delete on public.atribuciones
  for each row execute function public.mark_public_data_dirty_by_atribucion();

drop trigger if exists trg_mark_public_data_dirty_atribucion_autores on public.atribucion_autores;
create trigger trg_mark_public_data_dirty_atribucion_autores
  after insert or update or delete on public.atribucion_autores
  for each row execute function public.mark_public_data_dirty_by_atribucion_autor();

drop trigger if exists trg_mark_public_data_dirty_atribucion_evidencias on public.atribucion_evidencias;
create trigger trg_mark_public_data_dirty_atribucion_evidencias
  after insert or update or delete on public.atribucion_evidencias
  for each row execute function public.mark_public_data_dirty_by_atribucion_evidencia();

commit;
