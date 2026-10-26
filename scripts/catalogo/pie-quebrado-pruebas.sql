create function pg_temp.ok(p boolean,n text) returns text language plpgsql as $$begin
 if p is distinct from true then raise exception 'FALLO: %',n; end if; return 'OK: '||n; end$$;
create function pg_temp.rechaza(s text,n text) returns text language plpgsql as $$begin
 begin execute s; exception when check_violation then return 'OK: '||n; end;
 raise exception 'FALLO: se aceptó %',n; end$$;
create function pg_temp.medidas(pos integer[]) returns jsonb language sql as $$
 select coalesce(jsonb_agg(jsonb_build_object('posicion',n,'metro_id',m.metro_id)),'[]'::jsonb)
 from unnest(pos) n cross join public.metros m where m.silabas=4$$;
create temporary table arqs as select f.slug forma,a.slug,a.arquitectura_id from public.arquitecturas_forma a join public.formas_metricas f using(forma_id);

select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[3,6])),'sextilla 3/6 y respuestas antiguas') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[2,5])),'sextilla 2/5') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,
 jsonb_build_array(jsonb_build_object('posicion',2,'metro_id',(select metro_id from public.metros where silabas=4)),
 jsonb_build_object('posicion',5,'metro_id',(select metro_id from public.metros where silabas=5)))),
 'se conservan las alternativas de cuatro y cinco sílabas') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(not public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[2,6])),'sextilla híbrida 2/6 rechazada') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(not public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[3])),'sextilla con un solo quebrado rechazada') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(not public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[2,3,5,6])),'no se mezclan ambas disposiciones') from arqs where forma='sextilla' and slug='pie_quebrado';
select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[]::integer[])),'quintilla sin quebrados') from arqs where forma='quintilla' and slug='octosilabica_consonante';
select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[1])),'quintilla con quebrado inicial') from arqs where forma='quintilla' and slug='octosilabica_consonante';
select pg_temp.ok(public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[2,5])),'quintilla 2/5') from arqs where forma='quintilla' and slug='octosilabica_consonante';
select pg_temp.ok(not public.admite_disposicion_quebrados(arquitectura_id,pg_temp.medidas(array[1,5])),'quintilla híbrida 1/5 rechazada') from arqs where forma='quintilla' and slug='octosilabica_consonante';
select pg_temp.ok((select count(*)=16 from public.opciones_eleccion_metrica o join public.preguntas_metricas g using(grupo_eleccion_id) join arqs a using(arquitectura_id) where a.forma='copla_castellana' and g.dimension='metro'),'copla castellana: ocho candidatos con dos medidas');
select pg_temp.ok((select count(*)=8 from public.opciones_eleccion_metrica o join public.preguntas_metricas g using(grupo_eleccion_id) join arqs a using(arquitectura_id) where a.forma='novena' and a.slug='quintilla_redondilla' and g.dimension='metro' and o.posicion_unidad between 6 and 9),'novena 5+4: quebrados en la redondilla');
select pg_temp.ok((select count(*)=10 from public.opciones_eleccion_metrica o join public.preguntas_metricas g using(grupo_eleccion_id) join arqs a using(arquitectura_id) where a.forma='novena' and a.slug='redondilla_quintilla' and g.dimension='metro' and o.posicion_unidad between 5 and 9),'novena 4+5: quebrados en la quintilla');
select pg_temp.ok((select g.selecciones_max=9 from public.grupos_eleccion_metrica g join arqs a using(arquitectura_id) where a.forma='copla_real' and g.dimension='metro'),'copla real: más de dos quebrados conservando octosílabo pleno');
select pg_temp.ok(not exists(select 1 from public.formas_metricas where slug='copla_de_pie_quebrado' and activo),'no se reactiva la forma general');
select pg_temp.ok(not has_function_privilege('authenticated','public.comprobar_disposiciones_quebrados(uuid)','EXECUTE'),'comprobador de anotaciones sin endpoint público');

insert into auth.users(id) values('00000000-0000-4000-8000-000000000101');
insert into public.editores(user_id,nombre_completo,email,role,activo)
 values('00000000-0000-4000-8000-000000000101','Prueba quebrados','quebrados@example.invalid',
 (select termino_id from public.vocabularios where termino='admin' and categoria='role_editor' limit 1),true);
insert into public.anotacion_escenarios_prueba(escenario_id,nombre,created_by,updated_by)
 values('00000000-0000-4000-8000-000000000102','Prueba aislada','00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000101');
begin;
insert into public.anotaciones_metricas(anotacion_id,escenario_id,orden,v_ini,v_fin,forma_id,arquitectura_id,created_by,updated_by)
 select '00000000-0000-4000-8000-000000000103','00000000-0000-4000-8000-000000000102',1,1,6,f.forma_id,a.arquitectura_id,'00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000101'
 from public.formas_metricas f join public.arquitecturas_forma a using(forma_id) where f.slug='sextilla' and a.slug='pie_quebrado';
insert into public.anotacion_realizaciones(realizacion_id,anotacion_id,orden,v_ini,v_fin)
 values('00000000-0000-4000-8000-000000000104','00000000-0000-4000-8000-000000000103',1,1,6);
insert into public.anotacion_elecciones(anotacion_id,realizacion_id,dimension,metro_id,posicion_unidad)
 select '00000000-0000-4000-8000-000000000103','00000000-0000-4000-8000-000000000104','metro',m.metro_id,n from public.metros m cross join unnest(array[2,5]) n where m.silabas=4;
commit;
select pg_temp.ok(true,'guardado integrado de 2/5 con restricciones diferidas');
select pg_temp.rechaza($q$update public.anotacion_elecciones set posicion_unidad=6 where anotacion_id='00000000-0000-4000-8000-000000000103' and posicion_unidad=5; set constraints all immediate$q$,'el disparador impide convertir 2/5 en 2/6');

begin;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
set local role authenticated;
with cambiadas as (
 update public.anotacion_elecciones set observaciones='prueba autenticada'
 where anotacion_id='00000000-0000-4000-8000-000000000103' returning eleccion_id
) select pg_temp.ok((select count(*) from cambiadas)=2,'authenticated modifica efectivamente las dos respuestas');
commit;
select pg_temp.ok(true,'validación diferida con rol authenticated');
