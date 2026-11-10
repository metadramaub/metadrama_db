-- Generado por scripts/control-obras/preparar-contraccion.mjs; ensayar antes de materializar.
begin;
set local lock_timeout='5s'; set local statement_timeout='120s';
lock table public.obras,public.fichas_completas,public.obras_dataciones in share row exclusive mode;
do $$ begin
 if not exists(select 1 from supabase_migrations.schema_migrations where version='20261110200000') then raise exception 'Falta la migración editorial'; end if;
 if md5(pg_get_functiondef('public.escribir_obra_editorial()'::regprocedure))<>'e15f071ec601ea6cc44f12754acac0a4' then raise exception 'El escritor cambió desde el inventario; volver a auditar'; end if;
 if exists(select 1 from public.obras_revisores r left join public.fichas_completas f using(obra_id) where f.obra_id is null) then raise exception 'Revisor sin completa'; end if;
end $$;
create temporary table _editorial_antes_contraccion on commit drop as select obra_id,to_jsonb(o) as fila from public.obras_editoriales o;
CREATE OR REPLACE FUNCTION public.escribir_obra_editorial()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  insert into public.obras(obra_id,titulo,titulo_normalizado,variantes_titulo,genero_id,total_versos,slug)
  values(id,new.titulo,new.titulo_normalizado,new.variantes_titulo,new.genero_id,new.total_versos,coalesce(new.slug,''));
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
end $function$
;
drop trigger impedir_publicacion_minima on public.obras;
drop function public.impedir_publicacion_minima();
drop function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]);
drop view if exists public.control_obras_preparacion;
drop policy if exists "obras_basicas_delete" on public.obras;
drop policy if exists "obras_basicas_insert" on public.obras;
drop policy if exists "obras_basicas_update" on public.obras;
drop policy if exists "obras_delete_authenticated" on public.obras;
drop policy if exists "obras_insert_authenticated" on public.obras;
drop policy if exists "obras_update_authenticated" on public.obras;
alter table public.obras_revisores drop constraint obras_revisores_obra_id_fkey;
alter table public.obras_revisores add constraint obras_revisores_obra_id_fkey foreign key(obra_id) references public.fichas_completas(obra_id) on delete cascade;
create index if not exists fichas_completas_por_editor on public.fichas_completas(editor_asignado);
create index if not exists fichas_completas_por_estado on public.fichas_completas(estado);
create index if not exists fichas_completas_por_visibilidad on public.fichas_completas(visible_publico);
alter table public.obras drop column "edicion",
 drop column "editor_asignado",
 drop column "fecha_asignacion",
 drop column "estado",
 drop column "visible_publico",
 drop column "fecha_cambio_estado",
 drop column "fecha_publicacion",
 drop column "autor_ficha_publico",
 drop column "bibliografia",
 drop column "observaciones",
 drop column "sin_figuras_donaire",
 drop column "sin_personajes_sobrenaturales",
 drop column "sin_eventos_sobrenaturales",
 drop column "tipo_ficha",
 drop column "fecha_inicio_trad",
 drop column "fecha_fin_trad",
 drop column "fuente_fecha",
 drop column "fecha_inicio_metadrama",
 drop column "fecha_fin_metadrama";
do $$ begin
 if exists(select 1 from _editorial_antes_contraccion a full join public.obras_editoriales b using(obra_id) where a.fila is distinct from to_jsonb(b)) then raise exception 'La contracción cambió el contrato o sus datos'; end if;
end $$;
notify pgrst,'reload schema';
commit;
