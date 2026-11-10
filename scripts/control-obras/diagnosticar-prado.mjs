/** Diagnóstico de solo lectura: no llama al guardado ni modifica la base compartida. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { query } from '../lib/consulta.mjs';
const destino = `backups/incidencia-prado-20261110/${new Date().toISOString().replace(/[:.]/g, '-')}`;
mkdirSync(destino, { recursive: true });
const guardar = (nombre, filas) => writeFileSync(`${destino}/${nombre}.json`, JSON.stringify(filas, null, 2), 'utf8');
guardar('contexto', query(`begin isolation level repeatable read read only;
select 'obra' as tipo, to_jsonb(o) as dato from public.obras o where obra_id='4df0c5c3-ee25-4a8c-9794-1e7800868365'
union all select 'secuencia',to_jsonb(s) from public.secuencias_metricas s where obra_id='4df0c5c3-ee25-4a8c-9794-1e7800868365'
union all select 'anotacion',to_jsonb(a) from public.anotaciones_metricas a join public.secuencias_metricas s using(secuencia_id) where s.obra_id='4df0c5c3-ee25-4a8c-9794-1e7800868365'
union all select 'politica',to_jsonb(p) from pg_policies p where schemaname='public' and tablename in ('obras','secuencias_metricas','anotaciones_metricas')
union all select 'funcion',jsonb_build_object('nombre',p.proname,'definicion',pg_get_functiondef(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and (p.proname like 'auth_%' or p.oid in (select tgfoid from pg_trigger where tgrelid='public.anotaciones_metricas'::regclass and not tgisinternal));
commit;`));
for (const [nombre, consulta] of [
 ['lectura-secuencia', "select v_ini,v_fin from public.secuencias_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7'"],
 ['lectura-anotacion', "select anotacion_id from public.anotaciones_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7'"]
]) {
 const inicio = Date.now();
 // EXPLAIN sin ANALYZE: muestra la expansión de las políticas sin ejecutar el plan en producción.
 const plan = query(`begin read only; set local role authenticated;
 set local request.jwt.claim.sub='454c3ec5-9628-4ae0-842f-8adacc3e6b31';
 set local request.jwt.claims='{"sub":"454c3ec5-9628-4ae0-842f-8adacc3e6b31","role":"authenticated"}';
 explain (format json) ${consulta}; rollback;`);
 guardar(nombre, plan);
 console.log(nombre, { milisegundosIncluyendoConexion: Date.now()-inicio, bytesPlan: JSON.stringify(plan).length });
}
console.log('Diagnóstico guardado:', destino);
