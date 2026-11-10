/** Compara el guardado anterior y el corregido en una restauración aislada; siempre rollback. */
import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
exigirAislamiento();
const destino='backups/incidencia-prado-20261110';
const args=['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d','incidencia_prado_20261110','-v','ON_ERROR_STOP=1'];
const sql=s=>docker(args,s).trim();
const original=JSON.parse(readFileSync(`${destino}/funciones-a-corregir-live.json`,'utf8')).map(x=>x.definicion+';').join('\n');
const admin=sql("select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and lower(v.termino) in ('admin','ip') order by e.created_at limit 1");
const casos=JSON.parse(sql(`select jsonb_agg(to_jsonb(c)) from (
 select distinct on (f.forma_id) f.nombre,a.anotacion_id,
 to_jsonb(a)||jsonb_build_object('unidades',(select coalesce(jsonb_agg(to_jsonb(r) order by r.orden,r.realizacion_id),'[]') from public.anotacion_realizaciones r where r.anotacion_id=a.anotacion_id),
 'elecciones',(select coalesce(jsonb_agg(to_jsonb(e)),'[]') from public.anotacion_elecciones_resueltas e where e.anotacion_id=a.anotacion_id),
 'desviaciones',(select coalesce(jsonb_agg(to_jsonb(d)),'[]') from public.anotacion_desviaciones d where d.anotacion_id=a.anotacion_id)) as datos
 from public.anotaciones_metricas a join public.formas_metricas f using(forma_id)
 where (select count(*) from public.anotacion_realizaciones r where r.anotacion_id=a.anotacion_id)<=10
 order by f.forma_id,a.anotacion_id
) c;`));
const registro=[];
const normalizar=x=>Array.isArray(x)?x.map(normalizar).sort((a,b)=>JSON.stringify(a).localeCompare(JSON.stringify(b))):x&&typeof x==='object'?Object.fromEntries(Object.entries(x).filter(([k])=>!['created_at','updated_at'].includes(k)).sort(([a],[b])=>a.localeCompare(b)).map(([k,v])=>[k,normalizar(v)])):x;
const literal=x=>`'${JSON.stringify(x).replaceAll("'","''")}'::jsonb`;
for(const caso of casos){
 const resultados=[];
 for(const version of ['anterior','corregido']){
  const inicio=Date.now();
  const r=spawnSync('docker',args,{encoding:'utf8',maxBuffer:16*1024*1024,input:`begin;
   ${version==='anterior'?original:''}
   set local role authenticated;
   set local request.jwt.claim.sub='${admin}';
   set local request.jwt.claims='{"sub":"${admin}","role":"authenticated"}';
   set local statement_timeout='8s';
   select public.guardar_anotacion_metrica(${literal(caso.datos)});
   set constraints all immediate;
   select jsonb_build_object('anotacion',(select to_jsonb(a)-'updated_at' from public.anotaciones_metricas a where a.anotacion_id='${caso.anotacion_id}'),
    'unidades',(select coalesce(jsonb_agg(to_jsonb(r)-'created_at' order by r.realizacion_id),'[]') from public.anotacion_realizaciones r where r.anotacion_id='${caso.anotacion_id}'),
    'elecciones',(select coalesce(jsonb_agg(to_jsonb(e)-'created_at'-'eleccion_id' order by e.realizacion_id,e.dimension,e.valor_texto,e.esquema_rima_id,e.metro_id,e.valor_rasgo_id,e.posicion_unidad),'[]') from public.anotacion_elecciones e where e.anotacion_id='${caso.anotacion_id}'),
    'desviaciones',(select coalesce(jsonb_agg(to_jsonb(d)-'created_at'-'desviacion_id' order by d.v_ini,d.v_fin,d.dimension),'[]') from public.anotacion_desviaciones d where d.anotacion_id='${caso.anotacion_id}'));
   rollback;`});
  const salida=r.stdout.trim().split('\n').at(-1);
  resultados.push({version,ok:r.status===0,ms:Date.now()-inicio,datos:r.status===0?salida:null,error:r.status!==0?r.stderr.trim().split('\n')[0]:null});
 }
 const [antes,despues]=resultados;
 const equivalente=antes.ok===despues.ok && (antes.ok?JSON.stringify(normalizar(JSON.parse(antes.datos)))===JSON.stringify(normalizar(JSON.parse(despues.datos))):antes.error===despues.error);
 registro.push({forma:caso.nombre,equivalente,resultados});
 console.log(caso.nombre,{equivalente,anterior:antes.ms,corregido:despues.ms,ok:despues.ok});
}
writeFileSync(`${destino}/regresion.json`,JSON.stringify(registro,null,2),'utf8');
if(registro.some(x=>!x.equivalente)) throw Error('Hay diferencias que revisar');
console.log(`${registro.length} formas contrastadas; errores anteriores conservados expresamente en el informe.`);
