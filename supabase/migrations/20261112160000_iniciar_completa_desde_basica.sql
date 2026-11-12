-- El encargo y el inicio son operaciones distintas. La básica confirmada
-- conserva su identidad y su aportación analítica hasta la publicación.
create function public.encargar_completa_desde_basica(p_obra uuid, p_editor uuid)
returns void language plpgsql security definer set search_path='' as $$
declare
  borrador uuid;
  revisores uuid[];
begin
  if not public.auth_is_admin_or_ip() or not public.auth_puede_importar_metrica() then
    raise exception 'Solo admin o IP pueden encargar una ficha completa' using errcode='42501';
  end if;
  perform 1 from public.obras where obra_id=p_obra for update;
  if not found then raise exception 'Obra no encontrada' using errcode='P0002'; end if;
  perform 1 from public.editores where user_id=p_editor and coalesce(activo,true) for share;
  if not found then
    raise exception 'Selecciona un editor activo' using errcode='22023';
  end if;
  if not exists(select 1 from public.importaciones_metricas where obra_id=p_obra and usada_en_corpus) then
    raise exception 'La obra ya no tiene una ficha básica vigente' using errcode='23514';
  end if;
  if exists(select 1 from public.fichas_completas where obra_id=p_obra and editor_asignado=p_editor and inicio_elaboracion is null) then return; end if;
  if exists(select 1 from public.fichas_completas where obra_id=p_obra) then
    raise exception 'La ficha completa ya está encargada' using errcode='23514';
  end if;
  select termino_id into strict borrador from public.vocabularios where categoria='estado' and termino='borrador';
  select coalesce(array_agg(revisor_id order by revisor_id), '{}'::uuid[]) into revisores
  from public.obras_revisores where obra_id=p_obra;
  delete from public.obras_revisores where obra_id=p_obra and revisor_id=p_editor;
  insert into public.fichas_completas(obra_id,editor_asignado,fecha_asignacion,procedencia_registro,estado)
  values(p_obra,p_editor,now(),'nuevo',borrador);
  insert into public.asignaciones_historial(lote_id,obra_id,realizado_por,operacion,antes,despues)
  values(gen_random_uuid(),p_obra,auth.uid(),'editor',
    jsonb_build_object('editor_asignado',null,'reviewer_ids',revisores),
    jsonb_build_object('editor_asignado',p_editor,'reviewer_ids',array_remove(revisores,p_editor)));
end;
$$;
revoke all on function public.encargar_completa_desde_basica(uuid,uuid) from public,anon;
grant execute on function public.encargar_completa_desde_basica(uuid,uuid) to authenticated;

alter table public.fichas_completas add column importacion_reutilizada uuid references public.importaciones_metricas(importacion_id);

-- Conservar el RPC ordinario y evitar que omita la elección de arranque.
alter function public.iniciar_ficha_completa(uuid,uuid,boolean) rename to iniciar_ficha_completa_sin_basica;
revoke all on function public.iniciar_ficha_completa_sin_basica(uuid,uuid,boolean) from public,anon,authenticated;
create function public.iniciar_ficha_completa(p_obra uuid,p_editor uuid default null,p_iniciar boolean default false)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform 1 from public.obras where obra_id=p_obra for update;
  if p_iniciar and exists(select 1 from public.importaciones_metricas where obra_id=p_obra)
    and exists(select 1 from public.fichas_completas where obra_id=p_obra and inicio_elaboracion is null) then
    raise exception 'Elige cómo iniciar la completa a partir de la ficha básica' using errcode='23514';
  end if;
  perform public.iniciar_ficha_completa_sin_basica(p_obra,p_editor,p_iniciar);
end;
$$;
revoke all on function public.iniciar_ficha_completa(uuid,uuid,boolean) from public,anon;
grant execute on function public.iniciar_ficha_completa(uuid,uuid,boolean) to authenticated;

create function public.iniciar_completa_desde_basica(p_obra uuid,p_reutilizar boolean,p_edicion text)
returns void language plpgsql security definer set search_path='' as $$
declare
  ficha public.fichas_completas%rowtype;
  basica public.importaciones_metricas%rowtype;
  edicion text;
  dependencia record;
  hay_dependencia boolean;
begin
  perform 1 from public.obras where obra_id=p_obra for update;
  select * into ficha from public.fichas_completas where obra_id=p_obra for update;
  if not found then raise exception 'La ficha completa todavía no está encargada' using errcode='23514'; end if;
  if not public.auth_puede_ver_obra(p_obra) or
    (not public.auth_is_admin_or_ip() and ficha.editor_asignado is distinct from auth.uid()) then
    raise exception 'Solo el editor responsable o admin/IP pueden iniciar la ficha' using errcode='42501';
  end if;
  if ficha.inicio_elaboracion is not null then return; end if;
  select * into basica from public.importaciones_metricas where obra_id=p_obra and usada_en_corpus for update;
  if not found or p_reutilizar is null then raise exception 'Selecciona cómo iniciar la ficha' using errcode='22023'; end if;
  edicion := btrim(case when p_reutilizar then basica.datos_confirmados#>>'{metadatos,edicion_base}' else p_edicion end);
  if edicion is null or edicion='' or length(edicion)>4000 then
    raise exception 'Indica una edición base válida' using errcode='22023';
  end if;

  perform 1 from public.jornadas where obra_id=p_obra for update;
  perform 1 from public.secuencias_metricas where obra_id=p_obra for update;
  if (select jsonb_agg(jsonb_build_array(jornada_num,v_ini,v_fin) order by jornada_num)
        from public.jornadas where obra_id=p_obra)
    is distinct from
      (select jsonb_agg(jsonb_build_array((j->>'numero')::int,(j->>'v_ini')::int,(j->>'v_fin')::int) order by (j->>'numero')::int)
        from jsonb_array_elements(basica.datos_confirmados->'jornadas') j)
    or (select jsonb_agg(jsonb_build_array(m.segmento_ref,s.v_ini,s.v_fin) order by s.v_ini)
        from public.secuencias_metricas s left join public.metrica_minima_secuencias m
          on m.secuencia_id=s.secuencia_id and m.importacion_id=basica.importacion_id where s.obra_id=p_obra)
    is distinct from
      (select jsonb_agg(jsonb_build_array(s->>'ref',(s->>'v_ini')::int,(s->>'v_fin')::int) order by (s->>'v_ini')::int)
        from jsonb_array_elements(basica.datos_confirmados->'segmentos') s) then
    raise exception 'La estructura guardada difiere de la ficha básica. Revisa la obra antes de iniciar' using errcode='23514';
  end if;

  if not p_reutilizar then
    if exists (select 1 from public.secuencias_metricas s where s.obra_id=p_obra and
      num_nonnulls(s.estrofa_tipo_id,s.inaugura_espacio,s.intervencion_personajes_femeninos,
        s.intervencion_figuras_donaire,s.intervencion_personajes_sobrenaturales,s.sinopsis,
        s.versos_partidos,s.evento_sobrenatural,s.generos_intervinientes)>0) then
      raise exception 'Las secuencias tienen datos editoriales asociados' using errcode='23514';
    end if;
    for dependencia in
      select c.conrelid::regclass origen,c.confrelid::regclass destino,a.attname fk,b.attname pk
      from pg_constraint c
      join pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1]
      join pg_attribute b on b.attrelid=c.confrelid and b.attnum=c.confkey[1]
      where c.contype='f' and c.confrelid in ('public.jornadas'::regclass,'public.secuencias_metricas'::regclass)
        and c.conrelid<>'public.metrica_minima_secuencias'::regclass and cardinality(c.conkey)=1
    loop
      execute format('select exists(select 1 from %s x join %s y on x.%I=y.%I where y.obra_id=$1)',
        dependencia.origen,dependencia.destino,dependencia.fk,dependencia.pk) into hay_dependencia using p_obra;
      if hay_dependencia then
        raise exception 'La estructura tiene datos vinculados en %',dependencia.origen using errcode='23514';
      end if;
    end loop;
    delete from public.secuencias_metricas where obra_id=p_obra;
    delete from public.jornadas where obra_id=p_obra;
    update public.obras set total_versos=null where obra_id=p_obra;
  end if;
  update public.fichas_completas
  set inicio_elaboracion=now(),edicion_base=edicion,
      importacion_reutilizada=case when p_reutilizar then basica.importacion_id end
  where obra_id=p_obra;
end;
$$;
revoke all on function public.iniciar_completa_desde_basica(uuid,boolean,text) from public,anon;
grant execute on function public.iniciar_completa_desde_basica(uuid,boolean,text) to authenticated;

create function public.propuestas_metricas_de_basica(p_obra uuid)
returns table(secuencia_id uuid, forma text, arquitectura text)
language sql stable security definer set search_path='' as $$
  select s.secuencia_id, f.nombre, a.nombre
  from public.fichas_completas c
  join public.importaciones_metricas i on i.importacion_id=c.importacion_reutilizada
  join public.metrica_minima_secuencias m on m.importacion_id=i.importacion_id
  join public.secuencias_metricas s on s.secuencia_id=m.secuencia_id and s.obra_id=c.obra_id
  join public.formas_metricas f on f.forma_id=m.forma_id and f.activo
  left join public.arquitecturas_forma a on a.arquitectura_id=m.arquitectura_id and a.activo
  where c.obra_id=p_obra and public.auth_puede_consultar_importacion(p_obra)
    and c.edicion_base=btrim(i.datos_confirmados#>>'{metadatos,edicion_base}')
    and exists(select 1 from jsonb_array_elements(i.datos_confirmados->'segmentos') x
      where x->>'ref'=m.segmento_ref and (x->>'v_ini')::int=s.v_ini and (x->>'v_fin')::int=s.v_fin)
    and not exists(select 1 from public.anotaciones_metricas n where n.secuencia_id=s.secuencia_id);
$$;
revoke all on function public.propuestas_metricas_de_basica(uuid) from public,anon;
grant execute on function public.propuestas_metricas_de_basica(uuid) to authenticated;
