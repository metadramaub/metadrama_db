/** Auth y REST reales en el contenedor aislado; cuentas de revisión nuevas, sin correo. */
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {randomBytes,createHmac} from 'node:crypto';
import {contenedor,docker,sql,exigirAislamiento} from './local-db.mjs';
exigirAislamiento();
const dir='backups/control-obras/visual';mkdirSync(dir,{recursive:true});
const configPath=dir+'/acceso.json';
if(existsSync(configPath))throw Error('Ya existe una configuración de revisión; no se sobrescriben cuentas ni claves.');
writeFileSync(dir+'/antes-visual.dump',docker(['exec',contenedor,'pg_dump','-U','supabase_admin','-d','control_obras_preparacion','-Fc'],undefined,true));
const jwt=randomBytes(32).toString('hex'),clave=randomBytes(32).toString('hex');
sql(`alter role authenticator password '${clave}'; alter role supabase_auth_admin password '${clave}';`);
const procesos=docker(['exec',contenedor,'ps','-eo','pid,args']);
for(const linea of procesos.split('\n')){const m=linea.match(/^\s*(\d+)\s+\/tmp\/(postgrest|auth-control)\s*$/);if(m)docker(['exec','-u','root',contenedor,'kill','-KILL',m[1]]);}
const lanzar=(variables,bin,log)=>docker(['exec','-d',...Object.entries(variables).flatMap(([k,v])=>['-e',k+'='+v]),contenedor,'bash','-c',`exec ${bin} >${log} 2>&1`]);
lanzar({PGRST_DB_URI:`postgresql://authenticator:${clave}@127.0.0.1:5432/control_obras_preparacion`,PGRST_DB_ANON_ROLE:'anon',PGRST_JWT_SECRET:jwt,PGRST_SERVER_HOST:'127.0.0.1',PGRST_SERVER_PORT:'58080'},'/tmp/postgrest','/tmp/control-visual-rest.log');
lanzar({GOTRUE_DB_DRIVER:'postgres',GOTRUE_DB_DATABASE_URL:`postgresql://supabase_auth_admin:${clave}@127.0.0.1:5432/control_obras_preparacion?sslmode=disable`,GOTRUE_JWT_SECRET:jwt,GOTRUE_JWT_AUD:'authenticated',GOTRUE_JWT_ADMIN_ROLES:'service_role',GOTRUE_JWT_DEFAULT_GROUP_NAME:'authenticated',GOTRUE_API_HOST:'127.0.0.1',PORT:'9999',API_EXTERNAL_URL:'http://127.0.0.1:55425',GOTRUE_SITE_URL:'http://127.0.0.1:5195',GOTRUE_MAILER_AUTOCONFIRM:'true',GOTRUE_DISABLE_SIGNUP:'false'},'/tmp/auth-control','/tmp/control-visual-auth.log');
const http=(path,body)=>{
	const out=docker(['exec','-i',contenedor,'curl','--silent','--show-error','--max-time','15','-w','\n%{http_code}',...(body?['-X','POST','-H','Content-Type: application/json','--data-binary','@-']:[]),'http://127.0.0.1:9999'+path],body?JSON.stringify(body):undefined);
	const k=out.lastIndexOf('\n');return {status:Number(out.slice(k+1)),data:out.slice(0,k)?JSON.parse(out.slice(0,k)):null};
};
let lista=false;
for(let i=0;i<20;i++){try{if(http('/health').status===200){lista=true;break;}}catch{}await new Promise(r=>setTimeout(r,300));}
if(!lista)throw Error('Auth aislado no está listo; revisar /tmp/control-visual-auth.log.');
const usuarios=[];
for(const rol of ['admin','editor']){
	const email=`control-${rol}-${Date.now()}@example.invalid`,password=randomBytes(24).toString('base64url');
	const r=http('/signup',{email,password});
	if(r.status!==200||!r.data?.user?.id){writeFileSync(dir+'/auth-error.json',JSON.stringify(r,null,2));throw Error('No se pudo crear la cuenta sintética '+rol);}
	const id=r.data.user.id;
	sql(`insert into public.editores(user_id,nombre_completo,email,role,activo,puede_importar_metrica) values('${id}','Revisión local ${rol}','${email}',(select termino_id from public.vocabularios where categoria='role_editor' and termino='${rol}'),true,true);`);
	usuarios.push({id,rol,email,password});
}
const firmar=role=>{const h=Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');const p=Buffer.from(JSON.stringify({role,iss:'supabase',exp:Math.floor(Date.now()/1000)+86400})).toString('base64url');return h+'.'+p+'.'+createHmac('sha256',jwt).update(h+'.'+p).digest('base64url');};
writeFileSync(configPath,JSON.stringify({api:'http://127.0.0.1:55425',web:'http://127.0.0.1:5195',anonKey:firmar('anon'),serviceKey:firmar('service_role'),globalPassword:randomBytes(18).toString('base64url'),usuarios},null,2)+'\n','utf8');
console.log('Auth y REST preparados sin red exterior. Dos cuentas sintéticas guardadas solo en backups privado.');
