begin;
-- Incluye el corpus entero; este límite de ensayo no modifica el guardado individual de ocho segundos.
set local statement_timeout='600s';
create function pg_temp.exigir(cond boolean,nombre text) returns void language plpgsql as $$
begin if cond is distinct from true then raise exception 'FALLO: %',nombre; end if; end $$;
do $$
declare gestor uuid; editor uuid; oid uuid; publicada uuid; autor uuid; fallo boolean; d jsonb; original text;
begin
 select e.user_id into gestor from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino in ('admin','ip') limit 1;
 select e.user_id into editor from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino='editor' limit 1;
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 set local role authenticated;
 insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo de datación: ñ y acentos','sin_ficha') returning obra_id into oid;
 perform public.iniciar_ficha_completa(oid,editor,false);
 reset role;
 perform set_config('request.jwt.claim.sub',editor::text,true);
 set local role authenticated;
 perform public.iniciar_ficha_completa(oid,null,true);
 update public.obras_editoriales set dataciones='[
  {"clase":"referencia","inicio":null,"fin":1600,"inicio_inclusivo":true,"fin_inclusivo":false,"aproximada":false,"fuente":"  Estudio: año y edición\nSin recortar  "},
  {"clase":"metrica","inicio":1590,"fin":1598,"inicio_inclusivo":false,"fin_inclusivo":true,"aproximada":true,"fuente":"Análisis métrico"}]'
 where obra_id=oid;
 perform pg_temp.exigir((select inicio is null and fin=1600 and not fin_inclusivo and fuente=E'  Estudio: año y edición\nSin recortar  '
  from public.obras_dataciones where obra_id=oid and clase='referencia'),'Una fuente literal y un límite estricto se conservan');
 update public.obras_editoriales set edicion='Otra edición' where obra_id=oid;
 perform pg_temp.exigir((select not fin_inclusivo from public.obras_dataciones where obra_id=oid and clase='referencia'),'Guardar otros datos no pierde calificadores');
 fallo:=false;
 begin update public.obras_editoriales set dataciones='[{"clase":"referencia","inicio":1600,"fin":1600,"inicio_inclusivo":false,"fin_inclusivo":true}]' where obra_id=oid;
 exception when check_violation then fallo:=true; end;
 perform pg_temp.exigir(fallo,'Se rechaza el intervalo sin ningún año posible');
 fallo:=false;
 begin update public.obras_editoriales set dataciones='[{"clase":"referencia","inicio":1600},{"clase":"referencia","fin":1600}]' where obra_id=oid;
 exception when invalid_parameter_value then fallo:=true; end;
 perform pg_temp.exigir(fallo,'No se repite una clase');
 fallo:=false;
 begin update public.obras_dataciones set fin=1700 where obra_id=oid;
 exception when insufficient_privilege then fallo:=true; end;
 perform pg_temp.exigir(fallo,'Sin atajo de escritura directa');
 reset role;
 perform pg_temp.exigir((select fecha_inicio_trad is null and fecha_fin_trad is null and fuente_fecha is null from public.obras where obra_id=oid),'Las columnas históricas no se actualizan');
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 select f.obra_id into publicada from public.fichas_completas f join public.vocabularios v on v.termino_id=f.estado where v.termino='publicado' and f.visible_publico limit 1;
 perform pg_temp.exigir(publicada is not null,'Existe una ficha publicada para ejecutar los productores');
 update public.obras_editoriales set dataciones='[{"clase":"referencia","inicio":null,"fin":1600,"fin_inclusivo":false,"fuente":"Fuente de prueba"},{"clase":"metrica","inicio":1700,"fin":1702}]' where obra_id=publicada;
 perform pg_temp.exigir((select metrica_sucia from public.obras_resumen where obra_id=publicada),'Cambiar datación invalida el resumen');
 d:=public.ficha_publica_base_json(publicada,true);
 perform pg_temp.exigir(d#>>'{obra,dataciones,1,clase}'='referencia' and (d#>>'{obra,dataciones,1,fin_inclusivo}')::boolean=false,'La ficha JSON conserva ambas propuestas y límites');
 perform public.recompute_all();
 perform pg_temp.exigir((select payload::text like '%dataciones%' from public.artefactos_publicos where clave='indices/obras/publico.json'),'El índice recalculado lleva dataciones');
 perform pg_temp.exigir(public.corpus_comparativas_artefacto_json('publico')::text like '%dataciones%','La comparación recalculada lleva dataciones');
 select aa.autor_id into autor from public.atribuciones a join public.atribucion_autores aa using(atribucion_id) where a.obra_id=publicada limit 1;
 if autor is not null then
  perform pg_temp.exigir(public.autor_ficha_artefacto_json(autor,'publico')::text like '%dataciones%','El artefacto de autor lleva dataciones');
  perform public.get_autor_publico((select slug from public.autores where autor_id=autor));
 end if;
 perform set_config('request.jwt.claim.sub','',true);
 set local role anon;
 perform pg_temp.exigir((select dataciones::text like '%fin_inclusivo%' from public.obras_consulta_publica where obra_id=publicada),'La salida pública conserva calificadores');
 reset role;
 perform set_config('request.jwt.claim.sub',editor::text,true);
 set local role authenticated;
 update public.obras_editoriales set dataciones='[]' where obra_id=oid;
 perform pg_temp.exigir((select fecha_fin_trad is null and dataciones='[]'::jsonb from public.obras_editoriales where obra_id=oid),'Se pueden borrar fechas sin reaparecer el legado');
 reset role;
end $$;
select 'OK dataciones, fuentes, borrado, permisos, invalidación y ejecución de productores reales';
rollback;
