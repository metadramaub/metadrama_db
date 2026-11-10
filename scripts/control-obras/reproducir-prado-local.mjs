/** Solo copia aislada del modelo anterior: nunca utiliza conexión a Supabase. */
import { readFileSync, writeFileSync } from 'node:fs';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
exigirAislamiento();
const destino = 'backups/incidencia-prado-20261110';
const sql = s => docker(['exec','-i',contenedor,'psql','-X','-q','-At','-U','supabase_admin','-d','incidencia_prado_20261110','-v','ON_ERROR_STOP=1'], s).trim();
const contexto = JSON.parse(readFileSync(`${destino}/2026-11-10T12-27-30-314Z/contexto.json`, 'utf8'));
const literal = x => `'${JSON.stringify(x).replaceAll("'", "''")}'::jsonb`;
if (sql("select to_regclass('public.obras_editoriales') is null") !== 't') throw Error('Se exige modelo anterior');
const secuencias = contexto.filter(x=>x.tipo==='secuencia').map(x=>x.dato);
for (const s of secuencias) {
 sql(`insert into public.secuencias_metricas select * from jsonb_populate_record(null::public.secuencias_metricas, ${literal(s)}) on conflict(secuencia_id) do nothing;`);
}
const autenticar = `set local role authenticated;
 set local request.jwt.claim.sub='454c3ec5-9628-4ae0-842f-8adacc3e6b31';
 set local request.jwt.claims='{"sub":"454c3ec5-9628-4ae0-842f-8adacc3e6b31","role":"authenticated"}';`;
for (const [nombre, consulta] of [
 ['lectura-secuencia', "select v_ini,v_fin from public.secuencias_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7'"],
 ['lectura-anotacion', "select anotacion_id from public.anotaciones_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7'"]
]) {
 const inicio = Date.now();
 const r = sql(`begin; ${autenticar} set local statement_timeout='15s'; explain(analyze,buffers,format json) ${consulta}; rollback;`);
 writeFileSync(`${destino}/${nombre}-local.json`, r, 'utf8');
 console.log(nombre, {msConConexion:Date.now()-inicio, bytes:r.length});
}
console.log(sql(`select a.anotacion_id,f.nombre,a.v_ini,a.v_fin,a.arquitectura_id,
 (select count(*) from anotacion_realizaciones r where r.anotacion_id=a.anotacion_id) as unidades,
 (select count(*) from anotacion_elecciones e where e.anotacion_id=a.anotacion_id) as elecciones
 from anotaciones_metricas a join formas_metricas f using(forma_id) order by unidades,elecciones limit 12;`));
