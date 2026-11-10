/** Puente de loopback hacia Docker sin red + Vite separado; no modifica .env.local. */
import {readFileSync} from 'node:fs';
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {contenedor,exigirAislamiento} from './local-db.mjs';
exigirAislamiento();
const c=JSON.parse(readFileSync('backups/control-obras/visual/acceso.json','utf8'));
if(c.api!=='http://127.0.0.1:55425'||c.web!=='http://127.0.0.1:5195')throw Error('Direcciones no locales');
const bridge=createServer(async(req,res)=>{
	res.setHeader('Access-Control-Allow-Origin',c.web);res.setHeader('Access-Control-Allow-Credentials','true');res.setHeader('Access-Control-Allow-Headers','authorization,apikey,content-type,x-client-info,x-supabase-api-version,prefer,range,x-upsert');res.setHeader('Access-Control-Expose-Headers','content-range,range-unit');res.setHeader('Access-Control-Allow-Methods','GET,POST,PATCH,PUT,DELETE,OPTIONS');
	if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
	const auth=req.url.startsWith('/auth/v1/'),rest=req.url.startsWith('/rest/v1/');
	if(!auth&&!rest){res.writeHead(404);res.end();return;}
	const path=req.url.slice(auth?8:8),puerto=auth?9999:58080;
	const partes=[];for await(const b of req)partes.push(b);
	const args=['exec','-i',contenedor,'curl','--silent','--show-error','--include','--max-time','30','-X',req.method];
	for(const [k,v] of Object.entries(req.headers))if(!['host','connection','content-length','accept-encoding'].includes(k)&&v)args.push('-H',`${k}: ${v}`);
	args.push('--data-binary','@-','http://127.0.0.1:'+puerto+path);
	const child=spawn('docker',args);const out=[];child.stdout.on('data',b=>out.push(b));child.stderr.resume();
	child.on('error',()=>{res.writeHead(502);res.end('Puente local no disponible');});
	child.on('close',code=>{if(code){if(!res.headersSent)res.writeHead(502);res.end('Falló la API aislada');return;}const b=Buffer.concat(out),k=b.indexOf('\r\n\r\n');if(k<0){res.writeHead(502);res.end();return;}const lines=b.subarray(0,k).toString('latin1').split('\r\n');res.statusCode=Number(lines.shift().split(' ')[1]);for(const line of lines){const p=line.indexOf(':');const name=line.slice(0,p);if(p>0&&!['transfer-encoding','connection','access-control-allow-origin','content-length'].includes(name.toLowerCase()))res.setHeader(name,line.slice(p+1).trim());}res.end(b.subarray(k+4));});
	child.stdin.end(Buffer.concat(partes));
});
bridge.listen(55425,'127.0.0.1',()=>console.log('Puente aislado en 127.0.0.1:55425.'));
const web=spawn(process.execPath,['node_modules/vite/bin/vite.js','--host','127.0.0.1','--port','5195','--strictPort'],{stdio:'inherit',env:{...process.env,PUBLIC_SUPABASE_URL:c.api,VITE_SUPABASE_URL:c.api,PUBLIC_SUPABASE_ANON_KEY:c.anonKey,VITE_SUPABASE_ANON_KEY:c.anonKey,SUPABASE_SERVICE_ROLE_KEY:c.serviceKey,GLOBAL_ACCESS_PASSWORD:c.globalPassword,OBRAS_EDITORIALES_V2:'true'}});
web.on('exit',code=>{bridge.close();process.exitCode=code??1;});
process.on('SIGINT',()=>{web.kill();bridge.close();});
