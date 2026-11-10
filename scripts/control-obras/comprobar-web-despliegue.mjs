/** Comprobaciones HTTP del servidor publicado; no sustituye una revisión visual. */
import { readFileSync, writeFileSync } from 'node:fs';
import { createHmac, randomBytes } from 'node:crypto';
import { parseEnv } from 'node:util';
import { query } from '../lib/consulta.mjs';
const fase=process.argv[2];
if(!['compatible','modelo-nuevo'].includes(fase))throw Error('Indica compatible o modelo-nuevo');
const origin='https://versologia.metadrama.org';
const env=parseEnv(readFileSync('.env.local','utf8'));
const password=env.GLOBAL_ACCESS_PASSWORD?.trim();
if(!password)throw Error('No hay contraseña global configurada localmente para verificar las rutas protegidas');
const resultados=[];
const abierto=await fetch(origin+'/acceso',{redirect:'manual',signal:AbortSignal.timeout(60000)});
if(abierto.status!==200)throw Error('La página de acceso no responde correctamente');
const reloj=Date.parse(abierto.headers.get('date')??'');await abierto.arrayBuffer();
const payload=`v1.${Math.floor((Number.isFinite(reloj)?reloj:Date.now())/1000)-5}.${randomBytes(16).toString('base64url')}`;
const cookie='metadrama_global_access='+payload+'.'+createHmac('sha256',password).update(payload).digest('base64url');
const [publica]=query(`select slug from public.obras o where public.can_view_obra_ficha_publica(o.obra_id,false) order by slug limit 1;`);
if(!publica?.slug)throw Error('No hay una obra pública de referencia');
for(const ruta of ['/obras/listado','/obras/'+encodeURIComponent(publica.slug),'/login','/api/obras?scope=all']){
 const inicio=Date.now(),r=await fetch(origin+ruta,{redirect:'manual',headers:{Cookie:cookie,'Cache-Control':'no-cache'},signal:AbortSignal.timeout(60000)});
 const ubicacion=r.headers.get('location');await r.arrayBuffer();
 const protegido=ruta.startsWith('/api/');
 const valido=protegido?([401,403].includes(r.status)||(r.status===303&&ubicacion?.startsWith('/login'))):r.status===200;
 resultados.push({ruta,estado:r.status,milisegundos:Date.now()-inicio,correcto:valido});
 if(!valido){writeFileSync(`backups/control-obras/visual/web-${fase}.json`,JSON.stringify(resultados,null,2));throw Error('Respuesta inesperada en '+ruta+': '+r.status);}
}
writeFileSync(`backups/control-obras/visual/web-${fase}.json`,JSON.stringify({comprobado_en:new Date().toISOString(),fase,resultados},null,2),'utf8');
console.log({fase,comprobaciones:resultados.length,todasCorrectas:true});
