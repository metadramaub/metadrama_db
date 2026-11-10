/** Dos conexiones reales: una reasigna mientras otra intenta guardar con la fila anterior. */
import { spawn } from 'node:child_process';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
export async function probarConcurrencia(base) {
	exigirAislamiento();
	if(!/^control_obras_fechas_\d+$/.test(base))throw Error('Solo bases desechables del ensayo');
	const args=['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d',base,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];
	const sql=s=>docker(args,s).trim();
	const perfiles=JSON.parse(sql(`select jsonb_build_object(
 'gestor',(select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino in ('admin','ip') limit 1),
 'editor',(select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino='editor' limit 1));`));
	if(!perfiles.gestor||!perfiles.editor)throw Error('Faltan perfiles de ensayo');
	const id=sql(`set request.jwt.claim.sub='${perfiles.gestor}';
 insert into public.obras_editoriales(titulo,tipo_ficha,editor_asignado)
 values('Ensayo de concurrencia ${crypto.randomUUID()}','completa','${perfiles.editor}') returning obra_id;`).split('\n').at(-1);
	if(!/^[0-9a-f-]{36}$/.test(id))throw Error('Identidad de prueba no reconocida');
	sql(`set request.jwt.claim.sub='${perfiles.gestor}';select public.iniciar_ficha_completa('${id}',null,true);`);
	const conectar=()=>{
		const proceso=spawn('docker',args);let salida='',error='';
		const fin=new Promise((resolve,reject)=>{proceso.on('error',reject);proceso.on('close',code=>resolve({code,salida,error}));});
		proceso.stdout.on('data',b=>salida+=b.toString('utf8'));proceso.stderr.on('data',b=>error+=b.toString('utf8'));
		return {proceso,fin,leer:()=>salida};
	};
	const a=conectar();let b;
	try{
		a.proceso.stdin.write(`set statement_timeout='20s'; begin; set local request.jwt.claim.sub='${perfiles.gestor}';set local role authenticated;
 update public.obras_editoriales set editor_asignado='${perfiles.gestor}' where obra_id='${id}';select 'LISTO';\n`);
		const limite=Date.now()+15000;
		while(!a.leer().includes('LISTO')){if(Date.now()>limite)throw Error('No se confirmó el bloqueo inicial');await new Promise(r=>setTimeout(r,50));}
		b=conectar();
		b.proceso.stdin.end(`set application_name='concurrencia-${id}';set statement_timeout='20s';begin;
 set local request.jwt.claim.sub='${perfiles.editor}';set local role authenticated;
 update public.obras_editoriales set observaciones='No debe sobrescribir el nuevo encargo' where obra_id='${id}';commit;\n`);
		let espera=false;
		while(!espera){
			espera=sql(`select exists(select 1 from pg_stat_activity where datname='${base}' and application_name='concurrencia-${id}' and wait_event_type='Lock');`)==='t';
			if(!espera){if(Date.now()>limite)throw Error('El segundo guardado no esperó el bloqueo');await new Promise(r=>setTimeout(r,50));}
		}
		a.proceso.stdin.end('commit;\n');
		const [ra,rb]=await Promise.all([a.fin,b.fin]);
		if(ra.code!==0||rb.code===0||!rb.error.includes('40001'))throw Error('No se rechazó el guardado concurrente con 40001');
		if(sql(`select editor_asignado='${perfiles.gestor}'::uuid and observaciones is null from public.fichas_completas where obra_id='${id}';`)!=='t')throw Error('Se sobrescribió el encargo o el contenido');
		return true;
	}finally{
		if(!a.proceso.stdin.destroyed)a.proceso.stdin.end('rollback;\n');
		if(b&&!b.proceso.stdin.destroyed)b.proceso.stdin.end('rollback;\n');
		await Promise.allSettled([a.fin,...(b?[b.fin]:[])]);
		sql(`set request.jwt.claim.sub='${perfiles.gestor}';delete from public.obras_editoriales where obra_id='${id}';`);
	}
}
