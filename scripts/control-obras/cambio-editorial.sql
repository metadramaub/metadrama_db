-- Escritura única de la proyección. Las columnas editoriales antiguas quedan congeladas
-- para recuperación hasta la contracción; ninguna función adaptada debe leerlas.
create or replace function public.auth_puede_editar_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.fichas_completas f
  join public.editores e on e.user_id=auth.uid() join public.vocabularios v on v.termino_id=e.role
  where f.obra_id=p_obra_id and (f.procedencia_registro='legado' or f.inicio_elaboracion is not null)
   and coalesce(e.activo,true) and
   (v.termino in ('admin','ip') or (v.termino in ('editor','revisor') and f.editor_asignado=e.user_id)));
$$;
-- Los registros heredados no tienen una fecha de inicio reconstruible; mantienen su acceso.
create or replace function public.auth_obra_es_detallada(p_obra uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.fichas_completas f where f.obra_id=p_obra
  and (f.procedencia_registro='legado' or f.inicio_elaboracion is not null));
$$;
create or replace function public.auth_puede_ver_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.editores e join public.vocabularios v on v.termino_id=e.role
  where e.user_id=auth.uid() and coalesce(e.activo,true) and
   (v.termino in ('admin','ip') or exists(select 1 from public.fichas_completas f
    where f.obra_id=p_obra_id and (f.editor_asignado=e.user_id or exists(
     select 1 from public.obras_revisores r where r.obra_id=f.obra_id and r.revisor_id=e.user_id)))));
$$;

create or replace function public.escribir_obra_editorial() returns trigger
language plpgsql security definer set search_path='' as $$
declare
 actor uuid:=auth.uid(); gestor boolean:=public.auth_is_admin_or_ip();
 servicio boolean:=coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role',current_setting('request.jwt.claim.role',true),'')='service_role'
                   or (actor is null and session_user in ('postgres','supabase_admin'));
 id uuid; borrador uuid; actual public.fichas_completas%rowtype; fechas jsonb; marca_actual timestamptz;
begin
 select termino_id into borrador from public.vocabularios where categoria='estado' and termino='borrador';
 if tg_op='INSERT' then
  if not(gestor or servicio or (new.tipo_ficha='basica' and public.auth_puede_importar_metrica())) then
   raise exception 'No puedes crear obras' using errcode='42501';
  end if;
  id:=coalesce(new.obra_id,gen_random_uuid());
  insert into public.obras(obra_id,titulo,titulo_normalizado,variantes_titulo,genero_id,total_versos,slug,estado,tipo_ficha)
  values(id,new.titulo,new.titulo_normalizado,new.variantes_titulo,new.genero_id,
   new.total_versos,coalesce(new.slug,''),borrador,case when new.tipo_ficha='basica' then 'minima' else 'completa' end);
  perform public.escribir_dataciones_obra(id,coalesce(new.dataciones,jsonb_build_array(
   jsonb_build_object('clase','referencia','inicio',new.fecha_inicio_trad,'fin',new.fecha_fin_trad,'fuente',new.fuente_fecha),
   jsonb_build_object('clase','metrica','inicio',new.fecha_inicio_metadrama,'fin',new.fecha_fin_metadrama))));
  if new.tipo_ficha='completa' or new.editor_asignado is not null or
     (new.tipo_ficha is null and (new.edicion is not null or new.estado is not null)) then
   insert into public.fichas_completas(obra_id,editor_asignado,fecha_asignacion,procedencia_registro,
    estado,edicion_base,bibliografia,observaciones,visible_publico,sin_figuras_donaire,
    sin_personajes_sobrenaturales,sin_eventos_sobrenaturales)
   values(id,new.editor_asignado,case when new.editor_asignado is not null then now() end,
    'nuevo',coalesce(new.estado,borrador),new.edicion,new.bibliografia,new.observaciones,
    coalesce(new.visible_publico,false),coalesce(new.sin_figuras_donaire,false),
    coalesce(new.sin_personajes_sobrenaturales,false),coalesce(new.sin_eventos_sobrenaturales,false));
  end if;
  -- Al importar, la fila de importación se escribe después y el tipo de la proyección aún es sin_ficha.
  new.obra_id:=id;
  select slug,created_at,updated_at,dataciones into new.slug,new.created_at,new.updated_at,new.dataciones from public.obras_editoriales where obra_id=id;
  return new;
 end if;
 id:=old.obra_id;
 select updated_at into marca_actual from public.obras where obra_id=id for update;
 if not found then raise exception 'Obra no encontrada' using errcode='P0002'; end if;
 if marca_actual is distinct from old.updated_at then
  raise exception 'La obra ha cambiado durante el guardado. Conserva los cambios y recarga los datos' using errcode='40001';
 end if;
 if new.obra_id is distinct from old.obra_id and tg_op='UPDATE' then raise exception 'No se cambia la identidad'; end if;
 if tg_op='DELETE' then
  if not(gestor or servicio) then raise exception 'No puedes eliminar obras' using errcode='42501'; end if;
  delete from public.obras where obra_id=id; return old;
 end if;
 if not(gestor or servicio or public.auth_puede_editar_obra(id)) then
  -- La RPC del importador completa extensión antes de confirmar la copia, sin elaboración completa.
  if not(public.auth_puede_importar_metrica() and (old.tipo_ficha='sin_ficha' or exists(
      select 1 from public.importaciones_metricas where obra_id=id and importado_por=actor)) and
    (to_jsonb(new)-'total_versos')=(to_jsonb(old)-'total_versos')) then
   raise exception 'No puedes editar esta obra' using errcode='42501';
  end if;
 end if;
 if new.tipo_ficha is distinct from old.tipo_ficha then
  raise exception 'Utiliza la operación de inicio o importación de ficha' using errcode='23514';
 end if;
 if old.tipo_ficha<>'completa' and row(new.editor_asignado,new.edicion,new.bibliografia,new.observaciones,
  new.visible_publico,new.estado,new.sin_figuras_donaire,new.sin_personajes_sobrenaturales,new.sin_eventos_sobrenaturales)
  is distinct from row(old.editor_asignado,old.edicion,old.bibliografia,old.observaciones,
  old.visible_publico,old.estado,old.sin_figuras_donaire,old.sin_personajes_sobrenaturales,old.sin_eventos_sobrenaturales) then
  raise exception 'Estos datos requieren una ficha completa' using errcode='PT409';
 end if;
 if not(gestor or servicio) and row(new.editor_asignado,new.visible_publico,new.autor_ficha_publico)
    is distinct from row(old.editor_asignado,old.visible_publico,old.autor_ficha_publico) then
  raise exception 'Asignación y publicación reservadas a gestores' using errcode='42501';
 end if;
 if not(gestor or servicio) and new.estado is distinct from old.estado and not exists(
  select 1 from public.vocabularios a cross join public.vocabularios b
  where a.termino_id=old.estado and b.termino_id=new.estado and
   (a.termino||':'||b.termino) in ('borrador:vista_previa','vista_previa:borrador',
     'vista_previa:listo_para_publicar','listo_para_publicar:borrador')) then
  raise exception 'Transición editorial no permitida' using errcode='42501';
 end if;
 if not(gestor or servicio) and old.tipo_ficha='completa' and old.estado<>borrador and
    (to_jsonb(new)-'estado') is distinct from (to_jsonb(old)-'estado') then
  raise exception 'El contenido solo se edita en borrador' using errcode='42501';
 end if;
 update public.obras set titulo=new.titulo,titulo_normalizado=new.titulo_normalizado,
  variantes_titulo=new.variantes_titulo,genero_id=new.genero_id,
  total_versos=new.total_versos,slug=new.slug where obra_id=id;
 if new.dataciones is distinct from old.dataciones then
  perform public.escribir_dataciones_obra(id,new.dataciones);
 elsif row(new.fecha_inicio_trad,new.fecha_fin_trad,new.fuente_fecha,new.fecha_inicio_metadrama,new.fecha_fin_metadrama)
   is distinct from row(old.fecha_inicio_trad,old.fecha_fin_trad,old.fuente_fecha,old.fecha_inicio_metadrama,old.fecha_fin_metadrama) then
  -- Compatibilidad temporal con clientes anteriores; las demás ediciones no pierden los calificadores.
  select jsonb_agg(coalesce((select to_jsonb(d)-'obra_id' from public.obras_dataciones d
   where d.obra_id=id and d.clase=x->>'clase'),'{}')||x) into fechas from jsonb_array_elements(jsonb_build_array(
   jsonb_build_object('clase','referencia','inicio',new.fecha_inicio_trad,'fin',new.fecha_fin_trad,'fuente',new.fuente_fecha),
   jsonb_build_object('clase','metrica','inicio',new.fecha_inicio_metadrama,'fin',new.fecha_fin_metadrama))) x;
  perform public.escribir_dataciones_obra(id,fechas);
 end if;
 update public.fichas_completas set editor_asignado=new.editor_asignado,
  fecha_asignacion=case when editor_asignado is distinct from new.editor_asignado then now() else fecha_asignacion end,
  edicion_base=new.edicion,bibliografia=new.bibliografia,observaciones=new.observaciones,
  estado=new.estado,visible_publico=new.visible_publico,fecha_cambio_estado=case when estado is distinct from new.estado then now() else fecha_cambio_estado end,
  sin_figuras_donaire=new.sin_figuras_donaire,sin_personajes_sobrenaturales=new.sin_personajes_sobrenaturales,
  sin_eventos_sobrenaturales=new.sin_eventos_sobrenaturales,updated_at=now() where obra_id=id;
 select * into new from public.obras_editoriales where obra_id=id;
 return new;
end $$;
revoke all on function public.escribir_obra_editorial() from public,anon,authenticated;
drop trigger if exists escritura_obra_editorial on public.obras_editoriales;
create trigger escritura_obra_editorial instead of insert or update or delete on public.obras_editoriales
 for each row execute function public.escribir_obra_editorial();

-- Mover los disparadores cuya semántica pertenece a la completa.
drop trigger if exists obras_declaran_por_sus_secuencias on public.obras;
create trigger completas_declaran_por_sus_secuencias after update of sin_figuras_donaire,sin_personajes_sobrenaturales,sin_eventos_sobrenaturales
 on public.fichas_completas for each row execute function public.obra_declara_por_sus_secuencias();
drop trigger if exists trigger_obras_enforce_public_visibility on public.obras;
create trigger completas_visibilidad before insert or update on public.fichas_completas
 for each row execute function public.obras_enforce_public_visibility();
drop trigger if exists trigger_obras_sync_autor_ficha_publico on public.obras;
create trigger completas_credito before insert or update of editor_asignado on public.fichas_completas
 for each row execute function public.sync_obra_autor_ficha_publico();
drop trigger if exists trg_obras_recuerda_su_publicacion on public.obras;
create trigger completas_recuerda_publicacion before insert or update on public.fichas_completas
 for each row execute function public.obra_recuerda_su_publicacion();
drop trigger if exists trg_mark_autores_dirty_on_obra on public.obras;
create trigger completas_autores_dirty after update of visible_publico,estado on public.fichas_completas
 for each row execute function public.mark_autores_resumen_dirty_on_obra();
drop trigger if exists trg_mark_resumen_dirty_editor_asignado on public.obras;
create trigger completas_editor_dirty after update of editor_asignado on public.fichas_completas
 for each row execute function public.mark_obra_resumen_dirty_by_editor_asignado();

-- Una obra sin encargo no abre el editor. La creación de la completa es explícita.
create or replace function public.iniciar_ficha_completa(p_obra uuid,p_editor uuid default null,p_iniciar boolean default false)
returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); borrador uuid; f public.fichas_completas%rowtype;
begin
 perform 1 from public.obras where obra_id=p_obra for update;
 if not found then raise exception 'Obra no encontrada' using errcode='P0002'; end if;
 if not public.auth_is_admin_or_ip() then
  select * into f from public.fichas_completas where obra_id=p_obra;
  if not found or f.editor_asignado is distinct from actor or not public.auth_puede_ver_obra(p_obra) or p_editor is not null then
   raise exception 'Solo gestores pueden encargar una completa' using errcode='42501';
  end if;
 elsif exists(select 1 from public.importaciones_metricas where obra_id=p_obra) and
       not exists(select 1 from public.fichas_completas where obra_id=p_obra) then
  raise exception 'La transición de básica a completa está pendiente' using errcode='23514';
 end if;
 if p_editor is not null and not exists(select 1 from public.editores where user_id=p_editor and coalesce(activo,true)) then
  raise exception 'Editor no disponible' using errcode='22023';
 end if;
 select termino_id into borrador from public.vocabularios where categoria='estado' and termino='borrador';
 insert into public.fichas_completas(obra_id,editor_asignado,fecha_asignacion,procedencia_registro,estado,inicio_elaboracion)
 values(p_obra,p_editor,case when p_editor is not null then now() end,'nuevo',borrador,case when p_iniciar then now() end)
 on conflict(obra_id) do update set inicio_elaboracion=case when p_iniciar then coalesce(fichas_completas.inicio_elaboracion,now()) else fichas_completas.inicio_elaboracion end;
end $$;
revoke all on function public.iniciar_ficha_completa(uuid,uuid,boolean) from public,anon;
grant execute on function public.iniciar_ficha_completa(uuid,uuid,boolean) to authenticated;

-- El núcleo no acepta escrituras directas de usuarios: pasan por la proyección con sus guardas.
create or replace function public.listar_corpus_gestion() returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.auth_is_admin_or_ip() then raise exception 'Solo gestores pueden consultar corpus' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('codigo',codigo,'nombre',nombre) order by codigo) from public.corpus),'[]'::jsonb);
end $$;
revoke all on function public.listar_corpus_gestion() from public,anon;
grant execute on function public.listar_corpus_gestion() to authenticated;

create or replace function public.destino_importacion_metrica(p_obra uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.auth_puede_importar_metrica() then raise exception 'No puedes importar' using errcode='42501'; end if;
 return (select jsonb_build_object('obra_id',o.obra_id,'titulo',o.titulo) from public.obras_editoriales o
  where o.obra_id=p_obra and o.tipo_ficha='sin_ficha');
end $$;
revoke all on function public.destino_importacion_metrica(uuid) from public,anon;
grant execute on function public.destino_importacion_metrica(uuid) to authenticated;

create or replace function public.gestionar_corpus(p_operacion text,p_codigo text,p_nombre text default null,p_obras uuid[] default '{}')
returns void language plpgsql security definer set search_path='' as $$
declare id uuid;
begin
 if not public.auth_is_admin_or_ip() then raise exception 'Solo gestores pueden modificar corpus' using errcode='42501'; end if;
 if p_operacion not in ('crear','renombrar','anadir','retirar') or p_codigo is null or btrim(p_codigo)='' then
  raise exception 'Operación o código inválido' using errcode='22023'; end if;
 if p_operacion='crear' then
  if p_nombre is null or btrim(p_nombre)='' then raise exception 'Indica un nombre' using errcode='22023'; end if;
  insert into public.corpus(codigo,nombre) values(btrim(p_codigo),btrim(p_nombre)); return;
 end if;
 select corpus_id into id from public.corpus where codigo=p_codigo for update;
 if not found then raise exception 'Corpus no encontrado' using errcode='P0002'; end if;
 if p_operacion='renombrar' then
  if p_nombre is null or btrim(p_nombre)='' then raise exception 'Indica un nombre' using errcode='22023'; end if;
  update public.corpus set nombre=btrim(p_nombre) where corpus_id=id; return;
 end if;
 if coalesce(cardinality(p_obras),0) not between 1 and 500 then raise exception 'Selecciona entre 1 y 500 obras' using errcode='22023'; end if;
 if p_operacion='anadir' then
  insert into public.obras_corpus(obra_id,corpus_id) select distinct unnest(p_obras),id on conflict do nothing;
 else delete from public.obras_corpus where corpus_id=id and obra_id=any(p_obras); end if;
end $$;
revoke all on function public.gestionar_corpus(text,text,text,uuid[]) from public,anon;
grant execute on function public.gestionar_corpus(text,text,text,uuid[]) to authenticated;

revoke insert,update,delete on public.obras from authenticated,anon;
-- El escritor antiguo es SECURITY DEFINER: revocar la tabla por sí solo no lo desactiva.
-- Se conserva para la reversión, sin permitir nuevas importaciones fuera del contrato básico.
revoke execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) from public,anon,authenticated,service_role;
-- Sustituir políticas SELECT permisivas antiguas; no esconder solo la pestaña.
do $$ declare p record; begin
 for p in select policyname from pg_policies where schemaname='public' and tablename='obras' and cmd='SELECT' loop
  execute format('drop policy %I on public.obras',p.policyname);
 end loop;
end $$;
create policy obras_consulta_editorial on public.obras for select to authenticated using(
 public.auth_is_admin_or_ip() or public.auth_puede_ver_obra(obra_id) or
 (public.auth_puede_importar_metrica() and exists(select 1 from public.importaciones_metricas i where i.obra_id=obras.obra_id)));
-- La salida individual pública sigue exclusivamente en RPC y artefactos autorizados.
revoke select on public.obras,public.obras_editoriales from anon;
-- Los lectores públicos necesitan identidad/visibilidad antes de recuperar su artefacto.
-- Proyección cerrada: nunca entrega observaciones, bibliografía ni datos de importación.
create or replace view public.obras_consulta_publica with(security_barrier=true) as
 select o.obra_id,o.titulo,o.slug,o.genero_id,f.estado,f.visible_publico,f.editor_asignado,
  dr.inicio as fecha_inicio_trad,dr.fin as fecha_fin_trad,dm.inicio as fecha_inicio_metadrama,dm.fin as fecha_fin_metadrama,
  o.total_versos,o.updated_at,
  coalesce((select jsonb_agg(to_jsonb(d)-'obra_id' order by d.clase) from public.obras_dataciones d where d.obra_id=o.obra_id),'[]'::jsonb) as dataciones
 from public.obras o join public.fichas_completas f using(obra_id)
 left join public.obras_dataciones dr on dr.obra_id=o.obra_id and dr.clase='referencia'
 left join public.obras_dataciones dm on dm.obra_id=o.obra_id and dm.clase='metrica'
 where public.can_view_obra_ficha_publica(o.obra_id,true);
revoke all on public.obras_consulta_publica from public;
grant select on public.obras_consulta_publica to anon,authenticated,service_role;
notify pgrst,'reload schema';
