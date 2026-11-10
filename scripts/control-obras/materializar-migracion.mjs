/** Último paso de preparación, solo después de autorizar la activación coordinada.
 * Por defecto comprueba sin escribir; --escribir coloca exactamente el SQL probado en db push.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
const escribir=process.argv.includes('--escribir');
if(process.argv.slice(2).some(x=>x!=='--escribir'))throw Error('Opción desconocida');
const dir=readFileSync('backups/control-obras/ultimo-despliegue.txt','utf8').trim();
const ensayo=readFileSync('backups/control-obras/fechas/ultimo-ensayo.txt','utf8').trim();
const meta=JSON.parse(readFileSync(dir+'/migracion.json','utf8'));
const r=JSON.parse(readFileSync(ensayo+'/resultado.json','utf8'));
const destino='supabase/migrations/20261110200000_control_de_obras_y_dataciones.sql';
if(meta.archivoVersionado!==destino||r.copiaActual!==dir||!r.migracionFinal||!r.reversionComprobada||!r.concurrenciaComprobada||
 !r.correccionTimeoutConservada||!Object.values(r.entradas).includes(meta.sha256))throw Error('Falta el ensayo completo de esta candidata');
const bytes=readFileSync(meta.archivo);
if(createHash('sha256').update(bytes).digest('hex')!==meta.sha256)throw Error('La candidata cambió después del ensayo');
const hash=args=>{const p=spawnSync('git',args,{encoding:'utf8'});if(p.status!==0)throw Error('No se pudo comprobar el tratamiento de Git');return p.stdout.trim();};
if(hash(['hash-object','--no-filters',meta.archivo])!==hash(['hash-object','--path='+destino,meta.archivo]))throw Error('Git transformaría los bytes probados');
if(existsSync(destino)&&!readFileSync(destino).equals(bytes))throw Error('Ya existe una migración diferente; no se sobrescribe');
if(escribir&&!existsSync(destino))writeFileSync(destino,bytes,{flag:'wx'});
console.log(escribir?'Migración materializada con los mismos bytes probados. No se ha ejecutado SQL.':'Migración preparada y comprobada; no se ha creado ningún archivo para db push.');
