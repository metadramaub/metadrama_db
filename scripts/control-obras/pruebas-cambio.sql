begin;
create function pg_temp.exigir(cond boolean,nombre text) returns void language plpgsql as $$
begin if cond is distinct from true then raise exception 'FALLO: %',nombre; end if; end $$;
create function pg_temp.probar_cambio() returns text language plpgsql as $$
declare gestor uuid; editor uuid; otra uuid; nueva uuid; importador uuid; origen record; id_importacion uuid; destino uuid;
        jornada uuid; cuadro uuid; secuencia uuid;
        fallo boolean; antes text; despues text; n integer;
begin
 select e.user_id into gestor from public.editores e join public.vocabularios v on v.termino_id=e.role
  where coalesce(e.activo,true) and v.termino in ('admin','ip') limit 1;
 select e.user_id into editor from public.editores e join public.vocabularios v on v.termino_id=e.role
  where coalesce(e.activo,true) and v.termino='editor' limit 1;
 perform pg_temp.exigir(gestor is not null and editor is not null,'Hay perfiles restaurados para gestores y editores');
 perform pg_temp.exigir(not coalesce(has_function_privilege('authenticated',to_regprocedure('public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])'),'execute'),false),'El escritor antiguo no elude la autoridad nueva');
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 set local role authenticated;
 insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo control: registro sin ficha','sin_ficha') returning obra_id into nueva;
 reset role;
 perform pg_temp.exigir((select tipo_ficha='sin_ficha' from public.obras_editoriales where obra_id=nueva),'Crear registro sin ficha');
 perform pg_temp.exigir(not exists(select 1 from public.fichas_completas where obra_id=nueva),'Registro no crea completa implícita');
 perform public.iniciar_ficha_completa(nueva,editor,false);
 perform pg_temp.exigir((select editor_asignado=editor and inicio_elaboracion is null from public.fichas_completas where obra_id=nueva),'Encargo separado del inicio');
 perform set_config('request.jwt.claim.sub',editor::text,true);
 set local role authenticated;
 fallo:=false;
 begin insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin) values(nueva,1,1,4);
 exception when insufficient_privilege then fallo:=true; end;
 perform pg_temp.exigir(fallo,'Encargo sin iniciar no admite estructura');
 perform public.iniciar_ficha_completa(nueva,null,true);
 update public.obras_editoriales set observaciones='Análisis de ensayo',edicion='Edición de ensayo' where obra_id=nueva;
 insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin) values(nueva,1,1,4) returning jornada_id into jornada;
 insert into public.cuadros(jornada_id,cuadro_num,v_ini,v_fin) values(jornada,1,1,4) returning cuadro_id into cuadro;
 insert into public.secuencias_metricas(obra_id,v_ini,v_fin,n_versos) values(nueva,1,4,4) returning secuencia_id into secuencia;
 perform pg_temp.exigir((select count(*)=1 from public.jornadas where obra_id=nueva),'Editor lee la estructura con asignación nueva');
 update public.secuencias_metricas set sinopsis='Ensayo de permisos nuevos' where secuencia_id=secuencia;
 perform pg_temp.exigir((select sinopsis='Ensayo de permisos nuevos' from public.secuencias_metricas where secuencia_id=secuencia),'Editor actualiza secuencia con encargo vigente');
 reset role;
 perform pg_temp.exigir((select inicio_elaboracion is not null and observaciones='Análisis de ensayo' and edicion_base='Edición de ensayo' from public.fichas_completas where obra_id=nueva),'Editor escribe en completa');
 perform pg_temp.exigir((select to_jsonb(o)->>'observaciones' is null and to_jsonb(o)->>'edicion' is null from public.obras o where obra_id=nueva),'No se escribe análisis en núcleo');
 set local role authenticated;
 fallo:=false;begin update public.obras_editoriales set visible_publico=true where obra_id=nueva;exception when insufficient_privilege then fallo:=true;end;
 perform pg_temp.exigir(fallo,'Editor no puede activar publicación');
 fallo:=false;begin update public.obras set titulo='Acceso directo' where obra_id=nueva;exception when insufficient_privilege then fallo:=true;end;
 perform pg_temp.exigir(fallo,'Sin escritura directa del núcleo');
 select count(*) into n from public.obras_editoriales;
 reset role;
 perform pg_temp.exigir(n<(select count(*) from public.obras),'Editor no ve listado ajeno');
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 select md5(string_agg(datos_confirmados::text,'' order by importacion_id)) into antes from public.importaciones_metricas;
 -- Reutilizar un documento real sin alterar el original: la transacción completa se revierte.
 select * into origen from public.importaciones_metricas limit 1;
 set local role authenticated;
 select (public.guardar_ficha_basica(gen_random_uuid(),origen.autor_id,origen.datos_confirmados,origen.entrada_original,
  array(select obra_id from public.coincidencias_importacion_metrica(origen.datos_confirmados#>>'{metadatos,titulo}')))->>'importacion_id')::uuid into id_importacion;
 reset role;
 perform pg_temp.exigir(id_importacion is not null,'Guardado real de básica con contrato compatible');
 perform pg_temp.exigir((select o.tipo_ficha='basica' and f.obra_id is null from public.importaciones_metricas i join public.obras_editoriales o using(obra_id) left join public.fichas_completas f using(obra_id) where i.importacion_id=id_importacion),'Importar básica no crea completa');
 set local role authenticated;
 perform public.eliminar_ficha_basica(id_importacion,origen.datos_confirmados#>>'{metadatos,titulo}');
 reset role;
 select md5(string_agg(datos_confirmados::text,'' order by importacion_id)) into despues from public.importaciones_metricas;
 perform pg_temp.exigir(antes=despues,'Eliminar básica de ensayo conserva originales');
 insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo: destino ya creado','sin_ficha') returning obra_id into destino;
 perform public.gestionar_corpus('anadir','C60',null,array[destino]);
 perform public.gestionar_corpus('anadir','LOPE',null,array[destino]);
 perform pg_temp.exigir((select cardinality(corpus)=2 from public.obras_editoriales where obra_id=destino),'Pertenencia múltiple');
 update public.editores set puede_importar_metrica=true where user_id=editor;
 perform set_config('request.jwt.claim.sub',editor::text,true);
 set local role authenticated;
 select (public.guardar_ficha_basica(gen_random_uuid(),origen.autor_id,origen.datos_confirmados,origen.entrada_original,
  array(select obra_id from public.coincidencias_importacion_metrica(origen.datos_confirmados#>>'{metadatos,titulo}')),destino)->>'importacion_id')::uuid into id_importacion;
 reset role;
 perform pg_temp.exigir((select obra_id=destino from public.importaciones_metricas where importacion_id=id_importacion),'Importar sobre identidad existente como editor autorizado');
 perform pg_temp.exigir((select titulo='Ensayo: destino ya creado' and cardinality(corpus)=2 and tipo_ficha='basica' from public.obras_editoriales where obra_id=destino),'Conservar metadatos y corpus del destino');
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 fallo:=false;begin perform public.iniciar_ficha_completa(destino,editor,false);exception when check_violation then fallo:=true;end;
 perform pg_temp.exigir(fallo,'No se activa transición pendiente de básica a completa');
 fallo:=false;begin perform public.gestionar_asignaciones_lote('editor',editor,jsonb_build_array(jsonb_build_object(
  'obra_id',destino,'editor_asignado',null,'reviewer_ids','[]'::jsonb)));exception when insufficient_privilege then fallo:=true;end;
 perform pg_temp.exigir(fallo,'Asignar una básica no registra un encargo ficticio');
 set local role authenticated;
 perform public.eliminar_ficha_basica(id_importacion,origen.datos_confirmados#>>'{metadatos,titulo}');
 reset role;
 perform pg_temp.exigir(exists(select 1 from public.obras_editoriales
  where obra_id=destino and titulo='Ensayo: destino ya creado' and cardinality(corpus)=2
    and tipo_ficha='sin_ficha' and total_versos is null and fecha_inicio_trad is not null
    and cardinality(autores)>0),'Eliminar la básica conserva identidad, corpus, datación y autoría');
 perform pg_temp.exigir(not exists(select 1 from public.importaciones_metricas where importacion_id=id_importacion)
  and not exists(select 1 from public.secuencias_metricas where obra_id=destino)
  and not exists(select 1 from public.jornadas where obra_id=destino),'Se retira la estructura importada');
 set local role authenticated;
 perform public.guardar_ficha_basica(gen_random_uuid(),origen.autor_id,origen.datos_confirmados,origen.entrada_original,
  array(select obra_id from public.coincidencias_importacion_metrica(origen.datos_confirmados#>>'{metadatos,titulo}')),destino);
 reset role;
 perform pg_temp.exigir(exists(select 1 from public.obras_editoriales where obra_id=destino and tipo_ficha='basica'),
  'La misma obra admite una nueva importación');
 insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo: encargo en lote','sin_ficha') returning obra_id into otra;
 perform public.gestionar_asignaciones_lote('editor',editor,jsonb_build_array(jsonb_build_object(
  'obra_id',otra,'editor_asignado',null,'reviewer_ids','[]'::jsonb)));
 perform pg_temp.exigir((select editor_asignado=editor and inicio_elaboracion is null from public.fichas_completas where obra_id=otra),'Asignación en lote crea encargo sin iniciar');
 perform set_config('request.jwt.claim.sub','',true);
 set local role anon;
 select count(*) into n from public.obras_consulta_publica;
 reset role;
 perform pg_temp.exigir(n=(select count(*) from public.fichas_completas f join public.vocabularios v on v.termino_id=f.estado where v.termino='publicado' and f.visible_publico),'Vista pública anónima solo publicado y visible');
 return 'OK creación, encargo, inicio, autosave, permisos, importación, eliminación y trazabilidad';
end $$;
select pg_temp.probar_cambio();
-- PostgREST autentica con claims JSON, sin las variables individuales antiguas.
set local request.jwt.claim.sub='';
set local request.jwt.claims='{"role":"service_role"}';
set session authorization authenticator;
set local role service_role;
insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo de servicio JSON','sin_ficha');
reset role;
reset session authorization;
select pg_temp.exigir(exists(select 1 from public.obras where titulo='Ensayo de servicio JSON'),'Escritura de servicio con claims JSON');
rollback;
