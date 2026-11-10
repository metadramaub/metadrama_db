/** Integración real de las API SvelteKit con Auth/PostgREST aislados. Sin navegador ni datos reales nuevos. */
import { readFileSync,writeFileSync } from 'node:fs';
import { createHmac,randomBytes } from 'node:crypto';
import { createServerClient } from '@supabase/ssr';
import { exigirAislamiento,filas } from './local-db.mjs';
exigirAislamiento();
const config=JSON.parse(readFileSync('backups/control-obras/visual/acceso.json','utf8'));
if(config.web!=='http://127.0.0.1:5195'||config.api!=='http://127.0.0.1:55425')throw Error('Solo entorno local de ensayo');
const comprobaciones=[];
const exigir=(condicion,nombre)=>{if(!condicion)throw Error(nombre);comprobaciones.push(nombre);};
async function sesion(rol){
 const usuario=config.usuarios.find(u=>u.rol===rol),jar=new Map();
 const payload=`v1.${Math.floor(Date.now()/1000)}.${randomBytes(16).toString('base64url')}`;
 jar.set('metadrama_global_access',payload+'.'+createHmac('sha256',config.globalPassword).update(payload).digest('base64url'));
 const cliente=createServerClient(config.api,config.anonKey,{cookies:{getAll:()=>[...jar].map(([name,value])=>({name,value})),setAll:items=>items.forEach(x=>jar.set(x.name,x.value))}});
 const r=await cliente.auth.signInWithPassword({email:usuario.email,password:usuario.password});
 if(r.error)throw Error('No se pudo abrir sesión sintética '+rol);
 return {usuario,cliente,jar};
}
async function peticion(s,ruta,method='GET',body,esperado=200){
 const inicio=Date.now();
 const r=await fetch(config.web+ruta,{method,redirect:'manual',signal:AbortSignal.timeout(60000),headers:{Origin:config.web,Cookie:[...s.jar].map(([k,v])=>`${k}=${v}`).join('; '),...(body?{'Content-Type':'application/json'}:{})},body:body?JSON.stringify(body):undefined});
 const texto=await r.text();let dato;try{dato=JSON.parse(texto);}catch{dato=null;}
 if(r.status!==esperado)throw Error(`${method} ${ruta}: ${r.status}, se esperaba ${esperado}. ${dato?.message??dato?.error??''}`);
 comprobaciones.push(`${method} ${ruta.replace(/[0-9a-f]{8}-[0-9a-f-]{27,}/g,':id')} → ${r.status} (${Date.now()-inicio} ms)`);
 return dato;
}
const admin=await sesion('admin'),editor=await sesion('editor');
 let id,revisionId;
try{
 await peticion(editor,'/api/obras?scope=all','GET',undefined,403);
 const creado=await peticion(admin,'/api/obras','POST',{titulo:`Ensayo API funcional ${Date.now()}`,editor_asignado:null},201);
 id=creado.obra.obra_id;
 exigir(creado.obra.tipo_ficha==='sin_ficha','Crear obra sin ficha desde API de aplicación');
 await peticion(editor,`/api/obras/${id}`,'GET',undefined,404);
 await peticion(admin,'/api/obras/asignaciones-lote','POST',{operation:'editor',target:editor.usuario.id,works:[{obra_id:id,editor_asignado:null,reviewer_ids:[]}]});
 let obra=(await peticion(editor,`/api/obras/${id}`)).obra;
 exigir(obra.inicio_elaboracion===null,'Asignar no inicia elaboración');
 await peticion(editor,`/api/obras/${id}/estructura/jornadas`,'POST',{jornada_num:1,v_ini:1,v_fin:4},403);
 await peticion(editor,`/api/obras/${id}/iniciar`,'POST');
 await peticion(editor,`/api/obras/${id}/datos`,'PATCH',{titulo:obra.titulo,variantes_titulo:[],genero_id:null,fecha_inicio_trad:1600,fecha_fin_trad:1604,fuente_fecha:'Fuente de ensayo',fecha_inicio_metadrama:null,fecha_fin_metadrama:null,edicion:'Edición de ensayo de aplicación'},409);
 await peticion(editor,`/api/obras/${id}/datos`,'PATCH',{titulo:obra.titulo,variantes_titulo:[],genero_id:null,
  dataciones:[{clase:'referencia',inicio:1600,fin:1604,inicio_inclusivo:true,fin_inclusivo:true,aproximada:false,fuente:'Fuente de ensayo'}],edicion:'Edición de ensayo de aplicación'});
 const dataciones=[{clase:'referencia',inicio:null,fin:1600,inicio_inclusivo:true,fin_inclusivo:false,aproximada:false,fuente:'  Fuente de ensayo: ñ y acentos  '},
  {clase:'metrica',inicio:1590,fin:1605,inicio_inclusivo:true,fin_inclusivo:true,aproximada:true,fuente:'Otra fuente'}];
 const datos={titulo:obra.titulo,variantes_titulo:[],genero_id:null,edicion:'Edición de ensayo de aplicación'};
 const fechas=(await peticion(editor,`/api/obras/${id}/datos`,'PATCH',{dataciones})).obra;
 exigir(fechas.dataciones.find(d=>d.clase==='referencia')?.fin_inclusivo===false&&fechas.dataciones.find(d=>d.clase==='referencia')?.fuente===dataciones[0].fuente,'La API guarda límites estrictos y fuentes literales');
 exigir(fechas.edicion==='Edición de ensayo de aplicación','Guardar solo fechas conserva los demás metadatos');
 await peticion(editor,`/api/obras/${id}/datos`,'PATCH',{...datos,dataciones:[{...dataciones[0],inicio:1600}]},422);
 const sinFechas=(await peticion(editor,`/api/obras/${id}/datos`,'PATCH',datos)).obra;
 exigir(JSON.stringify(sinFechas.dataciones)===JSON.stringify(fechas.dataciones),'Guardar metadatos sin fechas conserva las dos propuestas');
 exigir(filas(`select fecha_inicio_trad is null and fecha_fin_trad is null and fuente_fecha is null as congeladas from public.obras where obra_id='${id}'`)[0].congeladas,'La API no escribe fechas en las columnas históricas');
 const jornada=(await peticion(editor,`/api/obras/${id}/estructura/jornadas`,'POST',{jornada_num:1,v_ini:1,v_fin:4},201)).jornada;
 await peticion(editor,`/api/obras/${id}/estructura/cuadros`,'POST',{jornada_id:jornada.jornada_id,cuadro_num:1,v_ini:1,v_fin:4},201);
 const secuencia=(await peticion(editor,`/api/obras/${id}/secuencias`,'POST',{v_ini:1,v_fin:4,generos_intervinientes:null,intervencion_figuras_donaire:null,intervencion_personajes_sobrenaturales:null},201)).secuencia;
 const norma=filas(`select a.forma_id,a.arquitectura_id,o.opcion_eleccion_id from public.formas_metricas f
 join public.arquitecturas_forma a using(forma_id) join public.preguntas_metricas g using(arquitectura_id)
 join public.opciones_eleccion_metrica o using(grupo_eleccion_id) join public.esquemas_rima r using(esquema_rima_id)
 where f.slug='redondilla' and a.activo and r.notacion='abba' limit 1`)[0];
 const unidad=crypto.randomUUID();
 const anotacion={action:'save_sequence',anotacion_id:null,escenario_id:null,secuencia_id:secuencia.secuencia_id,orden:1,v_ini:1,v_fin:4,forma_id:norma.forma_id,arquitectura_id:norma.arquitectura_id,observaciones:null,
 unidades:[{realizacion_id:unidad,realizacion_padre_id:null,seccion_id:null,orden:1,v_ini:1,v_fin:4,etiqueta:null,observaciones:null}],
 elecciones:[{realizacion_id:unidad,dimension:'rima',opcion_eleccion_id:norma.opcion_eleccion_id,valor_texto:null,observaciones:null}],desviaciones:[]};
 const uno=await peticion(editor,'/api/metrica/anotacion','POST',anotacion);
 const dos=await peticion(editor,'/api/metrica/anotacion','POST',anotacion);
 exigir(uno.anotacion_id===dos.anotacion_id,'Reintento métrico conserva identidad aunque el formulario no conozca el ID');
 await peticion(editor,`/dashboard/obras/${id}`);
 const actuales=await peticion(editor,`/api/obras/${id}`);
 exigir(actuales.jornadas.length===1&&actuales.cuadros.length===1&&actuales.secuencias.length===1,'Lectura completa de estructura por editor asignado');
 const propio=(await peticion(editor,'/api/obras?scope=mine')).items.find(o=>o.obra_id===id);
 exigir(propio?.canEditContent===true,'Permisos de contenido tras inicio explícito');
 exigir(filas(`select edicion is null as antigua, f.edicion_base from public.obras o join public.fichas_completas f using(obra_id) where o.obra_id='${id}'`)[0].antigua,'La edición se escribe en la completa y no en la columna congelada');
 const revisable=await peticion(admin,'/api/obras','POST',{titulo:`Ensayo API revisión ${Date.now()}`,editor_asignado:admin.usuario.id},201);
 revisionId=revisable.obra.obra_id;
 await peticion(admin,'/api/obras/asignaciones-lote','POST',{operation:'add_reviewer',target:editor.usuario.id,works:[{obra_id:revisionId,editor_asignado:admin.usuario.id,reviewer_ids:[]}]});
 await peticion(editor,`/api/obras/${revisionId}`);
 await peticion(editor,`/api/obras/${revisionId}/iniciar`,'POST',undefined,403);
 await peticion(admin,`/api/obras/${revisionId}/iniciar`,'POST');
 await peticion(editor,`/api/obras/${revisionId}/datos`,'PATCH',{},403);
 await peticion(editor,'/api/obras/asignaciones-lote','POST',{operation:'editor',target:editor.usuario.id,works:[{obra_id:revisionId,editor_asignado:admin.usuario.id,reviewer_ids:[editor.usuario.id]}]},403);
}finally{
 if(revisionId){const r=await admin.cliente.from('obras_editoriales').delete().eq('obra_id',revisionId);if(r.error)throw Error('No se pudo retirar la obra de revisión sintética');}
 if(id){const r=await admin.cliente.from('obras_editoriales').delete().eq('obra_id',id);if(r.error)throw Error('No se pudo retirar la obra sintética: '+r.error.message);}
 writeFileSync('backups/control-obras/visual/pruebas-aplicacion.json',JSON.stringify({fecha:new Date().toISOString(),comprobaciones},null,2),'utf8');
 await Promise.allSettled([admin.cliente.auth.signOut({scope:'local'}),editor.cliente.auth.signOut({scope:'local'})]);
}
console.log(`${comprobaciones.length} comprobaciones de aplicación correctas; obra sintética retirada.`);
