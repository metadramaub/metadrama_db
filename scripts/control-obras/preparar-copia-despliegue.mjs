/** Copia de solo lectura del Supabase enlazado. CLI secuencial: comparte credencial temporal. */
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
const marca = new Date().toISOString().replace(/[-:]/g,'').replace('T','-').slice(0,15);
const dir = join('backups/control-obras/despliegue',marca);
mkdirSync('backups/control-obras/despliegue',{recursive:true});
mkdirSync(dir,{recursive:false});
function ejecutar(args,nombre) {
	const r=spawnSync(process.execPath,args,{encoding:'utf8',maxBuffer:64*1024*1024});
	writeFileSync(join(dir,nombre+'.log'),String(r.stdout??'')+'\n'+String(r.stderr??r.error?.message??''),'utf8');
	if(r.status!==0)throw Error('No se completó '+nombre+'; diagnóstico en la copia privada. No se ha escrito en Supabase.');
	console.log('Copia: '+nombre+' correcto.');
}
const cli='node_modules/supabase/dist/supabase.js';
for(const [nombre,opciones] of [
	['schema',[]],['data',['--data-only']],['roles',['--role-only']],
	['managed-schema',['--schema','auth,storage,supabase_migrations']],
	['managed-data',['--data-only','--schema','auth,storage,supabase_migrations']]
]){
	ejecutar([cli,'db','dump','--linked',...opciones,'-f',join(dir,nombre+'.sql')],nombre);
	if(statSync(join(dir,nombre+'.sql')).size===0)throw Error('Volcado vacío: '+nombre);
}
ejecutar(['scripts/control-obras/copiar-instantanea.mjs',dir],'instantanea-consistente');
ejecutar(['scripts/control-obras/inventariar.mjs',dir],'inventario');
ejecutar(['scripts/control-obras/huellas.mjs',dir],'huellas');
ejecutar(['scripts/snapshot-obras.mjs','--salida',join(dir,'obras')],'snapshot-obras');
if(readFileSync(join(dir,'datos-consistentes.dump')).subarray(0,5).toString()!=='PGDMP')throw Error('Instantánea no reconocida');
writeFileSync(join(dir,'copia.json'),JSON.stringify({creada_en:new Date().toISOString(),origen:'Supabase enlazado; solo lectura',completa:true},null,2),'utf8');
writeFileSync('backups/control-obras/ultimo-despliegue.txt',dir,'utf8');
console.log('Copia completa actualizada: '+dir);
