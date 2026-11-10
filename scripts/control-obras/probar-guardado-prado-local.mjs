/** Caso sintético: 309 redondillas, no una reconstrucción de lo elegido por la editora. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
exigirAislamiento();
const base = 'incidencia_prado_20261110';
const args = ['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d',base,'-v','ON_ERROR_STOP=1'];
const preparacion = `begin;
${process.argv.includes('--lotes') ? readFileSync('backups/incidencia-prado-20261110/guardar-optimizado.sql','utf8') : ''}
${process.argv.includes('--inline-catalogo') ? 'alter function public.opciones_eleccion_derivadas() reset search_path;' : ''}
${process.argv.includes('--validaciones-definer') ? `alter function public.validar_estructura_anotacion_diferida() security definer;
alter function public.validar_extension_patron_anotacion_realizaciones() security definer;
alter function public.validar_arquitectura_de_realizacion() security definer;
alter function public.validar_densidad_de_pareados_regulares() security definer;` : ''}
load 'auto_explain';
set local auto_explain.log_min_duration='${process.argv.includes('--integridad')?'-1':'100ms'}';
set local auto_explain.log_nested_statements=on;
set local auto_explain.log_analyze=on;
set local auto_explain.log_level=notice;
create temp table prueba_payload as
with original as (select * from public.anotaciones_metricas where anotacion_id='3cf9f3fe-73e4-4e01-9f86-2efd0fba3349'),
opcion as (select o.opcion_eleccion_id from public.opciones_eleccion_metrica o
 join public.grupos_eleccion_metrica g using(grupo_eleccion_id) join original a using(arquitectura_id)
 join public.esquemas_rima r using(esquema_rima_id) where r.notacion='abba' limit 1),
unidades as (select i,gen_random_uuid() as id from generate_series(1,309) i)
select jsonb_build_object('anotacion_id',null,'secuencia_id','dca7f9e7-6782-4603-ad36-eba5c2f9f5b7',
 'orden',1,'v_ini',1,'v_fin',1236,'forma_id',a.forma_id,'arquitectura_id',a.arquitectura_id,
 'unidades',(select jsonb_agg(jsonb_build_object('realizacion_id',id,'realizacion_padre_id',null,'seccion_id',null,'orden',i,'v_ini',(i-1)*4+1,'v_fin',i*4)) from unidades),
 'elecciones',(select jsonb_agg(jsonb_build_object('realizacion_id',id,'dimension','rima','opcion_eleccion_id',o.opcion_eleccion_id)) from unidades cross join opcion o),
 'desviaciones','[]'::jsonb) as dato from original a;
grant select on prueba_payload to authenticated;
set local role authenticated;
set local request.jwt.claim.sub='454c3ec5-9628-4ae0-842f-8adacc3e6b31';
set local request.jwt.claims='{"sub":"454c3ec5-9628-4ae0-842f-8adacc3e6b31","role":"authenticated"}';
-- El bloque de integridad contiene dos peticiones y dos rechazos en una sola sentencia.
-- Se mide y exige por separado el límite de ocho segundos de cada guardado completo.
set local statement_timeout='${process.argv.includes('--integridad')?'30s':'8s'}';
${process.argv.includes('--integridad') ? `do $prueba$
declare
 p jsonb := (select dato from prueba_payload);
 a uuid;
 a2 uuid;
 otro uuid;
 inicio timestamptz := clock_timestamp();
begin
 a:=public.guardar_anotacion_metrica(p);
 set constraints all immediate;
 set constraints all deferred;
 if (select count(*) from public.anotacion_realizaciones where anotacion_id=a)<>309
  or (select count(*) from public.anotacion_elecciones where anotacion_id=a)<>309 then raise exception 'Contenido incompleto'; end if;
 raise notice 'Primer guardado y validaciones: % ms',extract(epoch from clock_timestamp()-inicio)*1000;
 if clock_timestamp()-inicio>interval '8s' then raise exception 'Primer guardado supera ocho segundos'; end if;
 p:=jsonb_set(p,'{anotacion_id}',to_jsonb(a));
 inicio:=clock_timestamp();
 a2:=public.guardar_anotacion_metrica(p);
 set constraints all immediate;
 set constraints all deferred;
 if a2<>a or (select count(*) from public.anotaciones_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7')<>1 then raise exception 'Reintento duplicado'; end if;
 raise notice 'Repetición y validaciones: % ms',extract(epoch from clock_timestamp()-inicio)*1000;
 if clock_timestamp()-inicio>interval '8s' then raise exception 'Segundo guardado supera ocho segundos'; end if;
 begin
  perform public.guardar_anotacion_metrica(jsonb_set(p,'{elecciones}','[]'));
  raise exception using errcode='ZX002',message='Se aceptó una respuesta obligatoria ausente';
 exception when sqlstate 'P0001' then null;
 end;
 if (select count(*) from public.anotacion_elecciones where anotacion_id=a)<>309 then raise exception 'Se perdió contenido tras rechazar una petición'; end if;
 select e.user_id into otro from public.editores e join public.vocabularios v on v.termino_id=e.role
 where lower(v.termino)='editor' and coalesce(e.activo,true) and e.user_id<>'454c3ec5-9628-4ae0-842f-8adacc3e6b31' limit 1;
 if otro is null then raise exception 'Falta editor ajeno para probar permisos'; end if;
 perform set_config('request.jwt.claim.sub',otro::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',otro,'role','authenticated')::text,true);
 begin
  perform public.guardar_anotacion_metrica(p);
  raise exception using errcode='ZX002',message='Se permitió guardar a un editor ajeno';
 exception when insufficient_privilege then null;
 end;
 raise notice 'Comprobados reintento, integridad, rechazo de datos incompletos y permisos de otro editor';
end $prueba$;` : `
select public.guardar_anotacion_metrica(dato) from prueba_payload;
set constraints all immediate;`}
rollback;`;
const inicio=Date.now();
const r=spawnSync('docker',args,{input:preparacion,encoding:'utf8',maxBuffer:64*1024*1024});
writeFileSync(`backups/incidencia-prado-20261110/guardado-sintetico-local${process.argv.includes('--inline-catalogo')?'-inline':''}${process.argv.includes('--validaciones-definer')?'-validaciones':''}${process.argv.includes('--lotes')?'-lotes':''}${process.argv.includes('--integridad')?'-integridad':''}.log`,r.stdout+r.stderr,'utf8');
console.log({exit:r.status,ms:Date.now()-inicio,final:r.stderr.slice(r.status===0?-800:-4000),salida:r.stdout});
if(r.status!==0) process.exitCode=r.status;
