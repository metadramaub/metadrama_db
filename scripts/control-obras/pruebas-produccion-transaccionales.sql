-- Comprobación breve tras aplicar el modelo. Solo crea fixtures dentro de una transacción revertida.
begin;
set local lock_timeout='3s';
set local statement_timeout='20s';
create function pg_temp.exigir(cond boolean,nombre text) returns void language plpgsql as $$
begin if cond is distinct from true then raise exception 'FALLO: %',nombre; end if; end $$;
do $$
declare gestor uuid; editor uuid; propia uuid; ajena uuid; jornada uuid; fallo boolean; n integer; esperadas integer;
begin
 select e.user_id into gestor from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino in ('admin','ip') limit 1;
 select e.user_id into editor from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino='editor' limit 1;
 perform pg_temp.exigir(gestor is not null and editor is not null,'Perfiles disponibles');
 perform set_config('request.jwt.claim.sub',gestor::text,true);
 set local role authenticated;
 insert into public.obras_editoriales(titulo,tipo_ficha) values('Ensayo transaccional de control','sin_ficha') returning obra_id into propia;
 perform pg_temp.exigir(not exists(select 1 from public.fichas_completas where obra_id=propia),'Crear no inicia completa');
 perform public.iniciar_ficha_completa(propia,editor,false);
 insert into public.obras_editoriales(titulo,tipo_ficha,editor_asignado) values('Ensayo transaccional ajeno','completa',gestor) returning obra_id into ajena;
 perform set_config('request.jwt.claim.sub',editor::text,true);
 perform pg_temp.exigir(not exists(select 1 from public.obras_editoriales where obra_id=ajena),'Editor no ve obra ajena');
 fallo:=false;begin insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin) values(propia,1,1,4);exception when insufficient_privilege then fallo:=true;end;
 perform pg_temp.exigir(fallo,'Encargo sin inicio no admite contenido');
 perform public.iniciar_ficha_completa(propia,null,true);
 update public.obras_editoriales set edicion='Edición de ensayo reversible',dataciones='[{"clase":"referencia","inicio":null,"fin":1600,"fin_inclusivo":false,"fuente":"Fuente reversible"},{"clase":"metrica","inicio":1590,"fin":1595,"aproximada":true}]' where obra_id=propia;
 insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin) values(propia,1,1,4) returning jornada_id into jornada;
 insert into public.cuadros(jornada_id,cuadro_num,v_ini,v_fin) values(jornada,1,1,4);
 insert into public.secuencias_metricas(obra_id,v_ini,v_fin,n_versos) values(propia,1,4,4);
 perform pg_temp.exigir((select dataciones @> '[{"clase":"referencia","fin":1600,"fin_inclusivo":false}]'::jsonb from public.obras_editoriales where obra_id=propia),'Fechas con límites persistidas');
 fallo:=false;begin update public.obras set titulo='No debe escribirse' where obra_id=propia;exception when insufficient_privilege then fallo:=true;end;
 perform pg_temp.exigir(fallo,'Sin escritura directa del núcleo');
 reset role;
 perform pg_temp.exigir((select to_jsonb(o)->>'edicion' is null and to_jsonb(o)->>'editor_asignado' is null from public.obras o where obra_id=propia),'Datos editoriales en completa');
 perform pg_temp.exigir((select edicion_base='Edición de ensayo reversible' from public.fichas_completas where obra_id=propia),'Edición conservada');
 select count(*) into esperadas from public.fichas_completas f join public.vocabularios v on v.termino_id=f.estado where v.termino='publicado' and f.visible_publico;
 perform set_config('request.jwt.claim.sub','',true);
 perform set_config('request.jwt.claims','{"role":"anon"}',true);
 set local role anon;
 select count(*) into n from public.obras_consulta_publica;
 perform pg_temp.exigir(n=esperadas,'Público solo publicado y visible');
 reset role;
 perform pg_temp.exigir((select inicio is null and fin=1612 and fin_inclusivo from public.obras_dataciones where obra_id='443d1994-5ded-436e-a89f-54dcd538d732' and clase='referencia'),'Límite de 1612 confirmado');
end $$;
select 'OK creación, encargo, inicio, edición, estructura, dataciones y acceso público; todo revertido';
rollback;
