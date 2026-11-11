-- La autoría global pertenece a la obra, con independencia de su ficha.
-- Las políticas de jornadas y las de los editores asignados siguen aplicándose.
create policy grupos_autoria_global_gestores on public.grupos_atribucion
  for all to authenticated
  using (obra_id is not null and (select public.auth_is_admin_or_ip()))
  with check (obra_id is not null and (select public.auth_is_admin_or_ip()));

create policy atribuciones_globales_gestores on public.atribuciones
  for all to authenticated
  using (obra_id is not null and (select public.auth_is_admin_or_ip()))
  with check (obra_id is not null and (select public.auth_is_admin_or_ip()));

create policy autores_de_atribuciones_globales_gestores on public.atribucion_autores
  for all to authenticated
  using ((select public.auth_is_admin_or_ip()) and exists (
    select 1 from public.atribuciones a
    where a.atribucion_id = atribucion_autores.atribucion_id and a.obra_id is not null
  ))
  with check ((select public.auth_is_admin_or_ip()) and exists (
    select 1 from public.atribuciones a
    where a.atribucion_id = atribucion_autores.atribucion_id and a.obra_id is not null
  ));

create policy evidencias_de_atribuciones_globales_gestores on public.atribucion_evidencias
  for all to authenticated
  using ((select public.auth_is_admin_or_ip()) and exists (
    select 1 from public.atribuciones a
    where a.atribucion_id = atribucion_evidencias.atribucion_id and a.obra_id is not null
  ))
  with check ((select public.auth_is_admin_or_ip()) and exists (
    select 1 from public.atribuciones a
    where a.atribucion_id = atribucion_evidencias.atribucion_id and a.obra_id is not null
  ));

create function public.guardar_autoria_global_previa(p_obra uuid, p_propuestas jsonb)
returns void language plpgsql security invoker set search_path = ''
as $$
declare
  grupo uuid;
  atribucion uuid;
  propuesta jsonb;
  evidencia jsonb;
  composicion uuid;
  modalidad uuid;
  tipo uuid;
begin
  if not public.auth_is_admin_or_ip() then
    raise exception 'Acceso reservado a admin e IP' using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_obra::text, 31));
  if not exists (
    select 1 from public.obras_editoriales o where o.obra_id = p_obra
      and (o.tipo_ficha in ('sin_ficha', 'basica')
        or (o.procedencia_registro = 'nuevo' and o.inicio_elaboracion is null))
  ) then
    raise exception 'Abre la ficha completa para editar su autoría' using errcode = 'PT409';
  end if;

  delete from public.grupos_atribucion where obra_id = p_obra;
  delete from public.atribuciones where obra_id = p_obra and grupo_atribucion_id is null;
  if jsonb_array_length(p_propuestas) = 0 then return; end if;
  insert into public.grupos_atribucion (obra_id) values (p_obra)
    returning grupo_atribucion_id into grupo;

  for propuesta in select value from jsonb_array_elements(p_propuestas) loop
    composicion := (propuesta->>'composicion_autoria_id')::uuid;
    select m.termino_id into strict modalidad
    from public.vocabularios c
    join public.vocabularios m on m.categoria = 'modalidad_atribucion' and m.termino = case c.termino
      when 'individual' then 'unica'
      when 'desconocida' then 'desconocida'
      when 'colaborada' then 'colaborativa'
    end
    where c.termino_id = composicion and c.categoria = 'composicion_autoria';
    evidencia := propuesta->'evidencias'->0;
    tipo := (evidencia->>'tipo_atribucion_id')::uuid;
    insert into public.atribuciones (
      grupo_atribucion_id, obra_id, composicion_autoria_id, modalidad_atribucion_id,
      tipo_atribucion_id, fuente_autoria, perfil_metrico
    ) values (
      grupo, p_obra, composicion, modalidad, tipo, evidencia->>'fuente_autoria',
      coalesce((propuesta->>'perfil_metrico')::boolean, false)
    ) returning atribucion_id into atribucion;

    insert into public.atribucion_autores (atribucion_id, autor_id, orden)
    select atribucion, (autor->>'autor_id')::uuid, coalesce((autor->>'orden')::integer, posicion::integer)
    from jsonb_array_elements(propuesta->'autores') with ordinality as fila(autor, posicion);

    insert into public.atribucion_evidencias (atribucion_id, tipo_atribucion_id, fuente_autoria)
    select atribucion, (fuente->>'tipo_atribucion_id')::uuid, fuente->>'fuente_autoria'
    from jsonb_array_elements(propuesta->'evidencias') as fuentes(fuente);
  end loop;
end;
$$;

revoke all on function public.guardar_autoria_global_previa(uuid, jsonb) from public, anon;
grant execute on function public.guardar_autoria_global_previa(uuid, jsonb) to authenticated;
