-- El JSON extraído y los datos del alta conservan su procedencia.
create or replace function public.proteger_copia_importacion() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (to_jsonb(new)-'usada_en_corpus') is not distinct from (to_jsonb(old)-'usada_en_corpus') then
    return new;
  end if;
  if current_user = 'service_role'
    and (to_jsonb(new)-array['datos_confirmados','sha256_jsonb','modificado_en'])
      is not distinct from (to_jsonb(old)-array['datos_confirmados','sha256_jsonb','modificado_en']) then
    return new;
  end if;
  raise exception using errcode='23514', message='La copia solo puede modificarse desde la edición métrica';
end;
$$;

create or replace function public.consultar_importacion_metrica(p_importacion uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('importacion_id',i.importacion_id,'obra_id',i.obra_id,
  'importado_por',e.nombre_completo,'importado_en',i.importado_en,'modificado_en',i.modificado_en,
  'puede_editar', public.auth_puede_importar_metrica()
    and (public.auth_is_admin_or_ip() or i.importado_por=auth.uid())
    and i.usada_en_corpus
    and not exists (select 1 from public.fichas_completas f where f.obra_id=i.obra_id),
  'datos_confirmados',i.datos_confirmados,'entrada_original',i.entrada_original)
 from public.importaciones_metricas i join public.editores e on e.user_id=i.importado_por
 where i.importacion_id=p_importacion and public.auth_puede_consultar_importacion(i.obra_id);
$$;

-- Solo el servidor llama a esta función tras validar la edición contra la ficha vigente.
grant usage on schema extensions to service_role;
grant execute on function public.esquema_documento_minimo() to service_role;
grant execute on function public.comprobar_destino_minimo(jsonb) to service_role;

create function public.editar_metrica_ficha_basica(
  p_importacion uuid, p_actor uuid, p_modificado_en timestamptz, p_datos jsonb
) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  ficha public.importaciones_metricas%rowtype;
  obra uuid;
  rol text;
  fila jsonb;
  secuencia uuid;
  forma uuid;
  arquitectura uuid;
  inicio integer;
  fin integer;
begin
  select lower(v.termino) into rol
  from public.editores e join public.vocabularios v on v.termino_id=e.role
  where e.user_id=p_actor and coalesce(e.activo,true)
    and (lower(v.termino) in ('admin','ip') or (lower(v.termino)='editor' and e.puede_importar_metrica));
  if rol is null then
    raise exception using errcode='42501', message='La sesión no puede editar la métrica importada';
  end if;

  select o.obra_id into obra
  from public.obras o join public.importaciones_metricas i using (obra_id)
  where i.importacion_id=p_importacion for update of o;
  select * into ficha from public.importaciones_metricas
  where importacion_id=p_importacion and obra_id=obra for update;
  if not found then
    raise exception using errcode='P0002', message='La ficha ya no está disponible';
  end if;
  if rol='editor' and ficha.importado_por<>p_actor then
    raise exception using errcode='42501', message='Solo puedes editar las fichas que importaste';
  end if;
  if not ficha.usada_en_corpus or exists (select 1 from public.fichas_completas where obra_id=obra) then
    raise exception using errcode='23514', message='La obra ya no tiene una ficha básica vigente';
  end if;
  if ficha.modificado_en is distinct from p_modificado_en then
    raise exception using errcode='40001', message='La ficha ha cambiado. Recarga antes de volver a editar';
  end if;
  -- Solo se admiten los cambios métricos. Los demás campos se copian del JSON
  -- de la base para mantener intactos incluso los registros de esquemas anteriores.
  p_datos := (ficha.datos_confirmados-array['segmentos','comprobacion'])
    || jsonb_build_object('segmentos',p_datos->'segmentos','comprobacion',p_datos->'comprobacion');
  if pg_column_size(p_datos)>10485760
    or not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos) then
    raise exception using errcode='23514', message='La corrección no cumple el contrato de ficha básica';
  end if;
  if p_datos = ficha.datos_confirmados then return; end if;

  perform 1 from public.secuencias_metricas where obra_id=obra for update;
  if exists (
    select 1 from public.secuencias_metricas s
    where s.obra_id=obra and not exists (
      select 1 from public.metrica_minima_secuencias m
      where m.secuencia_id=s.secuencia_id and m.importacion_id=p_importacion
    )
  ) then
    raise exception using errcode='23514', message='La obra contiene secuencias ajenas a la importación';
  end if;

  -- Quitar solo los rangos sustituidos, y únicamente si no tienen datos dependientes.
  for secuencia in
    select s.secuencia_id from public.secuencias_metricas s
    join public.metrica_minima_secuencias m using (secuencia_id)
    where s.obra_id=obra and m.importacion_id=p_importacion and not exists (
      select 1 from jsonb_array_elements(p_datos->'segmentos') j
      where (j->>'v_ini')::int=s.v_ini and (j->>'v_fin')::int=s.v_fin
    )
  loop
    if exists (select 1 from public.secuencias_metricas s where s.secuencia_id=secuencia and
      num_nonnulls(s.estrofa_tipo_id,s.inaugura_espacio,s.intervencion_personajes_femeninos,
        s.intervencion_figuras_donaire,s.intervencion_personajes_sobrenaturales,s.sinopsis,
        s.versos_partidos,s.evento_sobrenatural,s.generos_intervinientes)>0)
      or exists (select 1 from public.anotaciones_metricas where secuencia_id=secuencia)
      or exists (select 1 from public.comentarios_internos where secuencia_id=secuencia)
      or exists (select 1 from public.migracion_secuencias where secuencia_id=secuencia)
      or exists (select 1 from public.secuencias_subtipos_estrofa where secuencia_id=secuencia)
      or exists (select 1 from public.secuencias_caracterizaciones_rango where secuencia_id=secuencia) then
      raise exception using errcode='23514', message='Un rango que se quiere sustituir tiene datos asociados';
    end if;
    delete from public.secuencias_metricas where secuencia_id=secuencia;
  end loop;

  -- Las referencias pueden cambiar al dividir o unir. Se reconstruye la proyección
  -- mínima conservando los identificadores de los rangos que siguen existiendo.
  delete from public.metrica_minima_secuencias where importacion_id=p_importacion;
  for fila in select value from jsonb_array_elements(p_datos->'segmentos') loop
    inicio := (fila->>'v_ini')::int;
    fin := (fila->>'v_fin')::int;
    select secuencia_id into secuencia from public.secuencias_metricas
      where obra_id=obra and v_ini=inicio and v_fin=fin;
    if not found then
      insert into public.secuencias_metricas(obra_id,v_ini,v_fin,n_versos)
      values(obra,inicio,fin,fin-inicio+1) returning secuencia_id into secuencia;
    end if;
    perform public.comprobar_destino_minimo(fila->'identificacion');
    select forma_id into forma from public.formas_metricas where slug=fila#>>'{identificacion,forma_slug}';
    select arquitectura_id into arquitectura from public.arquitecturas_forma
      where forma_id=forma and slug=fila#>>'{identificacion,arquitectura_slug}';
    insert into public.metrica_minima_secuencias(secuencia_id,importacion_id,segmento_ref,forma_id,
      arquitectura_id,segmentacion,datos_minimos)
    values(secuencia,p_importacion,fila->>'ref',forma,arquitectura,fila->>'segmentacion',
      fila-array['ref','v_ini','v_fin','identificacion','segmentacion']);
  end loop;

  update public.importaciones_metricas set datos_confirmados=p_datos,
    sha256_jsonb=encode(extensions.digest(convert_to(p_datos::text,'UTF8'),'sha256'),'hex'),
    modificado_en=clock_timestamp()
  where importacion_id=p_importacion;
end;
$$;
revoke all on function public.editar_metrica_ficha_basica(uuid,uuid,timestamptz,jsonb) from public,anon,authenticated;
grant execute on function public.editar_metrica_ficha_basica(uuid,uuid,timestamptz,jsonb) to service_role;
