/** Ensayo desde la última restauración del modelo de producción, sin la carga CSV anterior.
 * Crea otra base aislada; no sustituye la restauración que sirve a las pruebas de aplicación.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
import { probarConcurrencia } from './probar-concurrencia-local.mjs';
exigirAislamiento();
const base = 'control_obras_fechas_' + Date.now();
const copiaActual = process.argv.includes('--actual') ? readFileSync('backups/control-obras/ultimo-despliegue.txt','utf8').trim() : null;
const final=process.argv.includes('--final');
if(process.argv.slice(2).some(x=>!['--actual','--final'].includes(x))||final&&!copiaActual)throw Error('Opción desconocida o falta copia actual');
const dir = 'backups/control-obras/fechas/' + base;
mkdirSync(dir, { recursive: true });
const sql = (s, db = base) => docker(['exec','-i',contenedor,'psql','-X','-q','-At','-U','supabase_admin','-d',db,'-v','ON_ERROR_STOP=1'],s).trim();
const filas = (s) => JSON.parse(sql(`select coalesce(jsonb_agg(to_jsonb(t)),'[]') from (${s}) t;`));
// Esta plantilla es la restauración de la instantánea 20261110-174103, con el arreglo métrico.
// La restauración tiene las tablas de la expansión anterior vacías, sin lectores activados.
if (!copiaActual && sql("select to_regclass('public.obras_editoriales') is null and not exists(select 1 from public.fichas_completas)",'incidencia_prado_20261110') !== 't') throw Error('La plantilla ya no es el modelo operativo de producción');
sql(`create database ${base} template ${copiaActual ? 'template0' : 'incidencia_prado_20261110'};`,'postgres');
if(copiaActual){
	// Restaurar el esquema gestionado actual, que puede incorporar tablas nuevas de Storage/Auth.
	sql('create schema extensions; create schema vault; create publication supabase_realtime;');
	sql(readFileSync(copiaActual+'/managed-schema.sql','utf8'));
	// pg_cron solo se instala en postgres; esta copia no ejecuta tareas programadas.
	const esquema=readFileSync(copiaActual+'/schema.sql','utf8').replace(/^CREATE EXTENSION IF NOT EXISTS "pg_cron"[^\n]*;\r?$/gm,'');
	writeFileSync(dir+'/restauracion-schema-usado.sql',esquema,'utf8');
	sql(esquema);
	// El inventario actual debe coincidir con la restauración antes de incorporar los datos.
 const inv=JSON.parse(readFileSync(copiaActual+'/inventario.json','utf8'));
 const funciones=inv.filas.find(b=>b.bloque==='funciones').datos;
 const definiciones=filas("select p.oid::regprocedure::text as firma,pg_get_functiondef(p.oid) as definicion from pg_proc p where p.pronamespace='public'::regnamespace");
 const distintas=funciones.filter(f=>!definiciones.some(d=>d.firma===f.firma&&d.definicion===f.definicion));
	if(distintas.length)throw Error('La restauración difiere del esquema actual: '+distintas.map(f=>f.firma).join(', '));
 docker(['exec','-i',contenedor,'pg_restore','-U','supabase_admin','-d',base,'--data-only','--disable-triggers','--single-transaction','--exit-on-error'],readFileSync(copiaActual+'/datos-consistentes.dump'));
 const restauradas=filas(readFileSync(copiaActual+'/huellas.sql','utf8').trim().replace(/;$/,''));
 const remotas=JSON.parse(readFileSync(copiaActual+'/huellas-remotas.json','utf8')).tablas;
 if(restauradas.length!==remotas.length||restauradas.some(x=>!remotas.some(y=>y.tabla===x.tabla&&y.sha256===x.sha256&&y.filas===x.filas)))throw Error('Diferencias entre la instantánea actual y sus huellas; comprobar actividad concurrente');
 console.log('Instantánea actual restaurada: '+restauradas.length+' tablas idénticas.');
}
const guardar = (nombre, valor) => writeFileSync(dir+'/'+nombre,JSON.stringify(valor,null,2),'utf8');
const huellasDe = (tablas) => {
 if(tablas.some(t=>!/^[a-z_][a-z_0-9]*$/.test(t)))throw Error('Nombre de tabla no admitido');
 return JSON.parse(sql(`select jsonb_object_agg(nombre,huella) from (${tablas.map(t=>
  `select '${t}' as nombre,encode(extensions.digest(coalesce(string_agg(to_jsonb(t)::text,E'\n' order by to_jsonb(t)::text),''),'sha256'),'hex') as huella from public.${t} t`).join(' union all ')}) q`));
};
const protegidas = ['secuencias_metricas','jornadas','cuadros','anotaciones_metricas','anotacion_realizaciones','anotacion_elecciones','anotacion_desviaciones','importaciones_metricas'];
const huellas = () => huellasDe(protegidas);
const antes = huellas();
const funcionesTimeout = () => filas(`select proname,pg_get_functiondef(oid) as definicion from pg_proc where pronamespace='public'::regnamespace and proname in
 ('opciones_eleccion_derivadas','validar_estructura_anotacion','guardar_anotacion_metrica','validar_estructura_anotacion_diferida',
 'validar_extension_patron_anotacion_realizaciones','validar_arquitectura_de_realizacion','validar_densidad_de_pareados_regulares') order by proname`);
const timeoutOriginal = funcionesTimeout();
const fechas = filas('select obra_id,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,fuente_fecha,editor_asignado from public.obras order by obra_id');
guardar('fechas-originales.json',fechas);
const esperadas = fechas.map(d=>d.obra_id==='443d1994-5ded-436e-a89f-54dcd538d732'
 ? {...d,fecha_inicio_trad:null,fecha_fin_trad:1612} : d);
const archivos = final ? [JSON.parse(readFileSync(copiaActual+'/migracion.json','utf8')).archivo] : ['supabase/migrations/20261110170000_restaurar_autorias_tras_pruebas.sql',
 'scripts/control-obras/001-expandir-ensayo.sql','scripts/control-obras/002-cambio-ensayo.sql'];
for (const archivo of archivos) {
 sql(readFileSync(archivo,'utf8').replaceAll("current_database()<>'control_obras_preparacion'",`current_database()<>'${base}'`));
 console.log('Aplicado en copia nueva: '+archivo);
}
const trasladadas = filas('select obra_id,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,fuente_fecha,editor_asignado from public.obras_editoriales order by obra_id');
if(JSON.stringify(esperadas)!==JSON.stringify(trasladadas))throw Error('El traslado alteró fechas, fuentes o encargos fuera de la corrección autorizada');
const carga = readFileSync('backups/control-obras/visual/carga-csv-ensayo.sql','utf8').replaceAll("current_database()<>'control_obras_preparacion'",`current_database()<>'${base}'`);
sql(carga);
const actuales = filas('select obra_id,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,fuente_fecha,editor_asignado from public.obras_editoriales order by obra_id');
for(const a of esperadas){
 const b=actuales.find(x=>x.obra_id===a.obra_id);
 if(a.editor_asignado!==b.editor_asignado)throw Error('Se alteró un encargo');
 if((a.fecha_inicio_trad!==null||a.fecha_fin_trad!==null)&&(a.fecha_inicio_trad!==b.fecha_inicio_trad||a.fecha_fin_trad!==b.fecha_fin_trad||a.fuente_fecha!==b.fuente_fecha))throw Error('Se sustituyó una fecha o fuente existente');
 if(a.fuente_fecha && a.fuente_fecha!==b.fuente_fecha)throw Error('Se modificó una fuente anterior');
}
const dataciones = filas('select * from public.obras_dataciones order by obra_id,clase');
guardar('dataciones.json',dataciones);
const plan=JSON.parse(readFileSync('backups/control-obras/visual/plan-carga-csv.json','utf8'));
const discrepancias=[];
let incorporadas=0;
for(const p of plan.filas){
 const a=fechas.find(x=>x.obra_id===p.obra_id),d=dataciones.find(x=>x.obra_id===p.obra_id&&x.clase==='referencia');
 if(!d)throw Error('Falta la datación del CSV');
 if(a.fecha_inicio_trad===null&&a.fecha_fin_trad===null){
  for(const k of ['inicio','fin','inicio_inclusivo','fin_inclusivo','aproximada'])if(d[k]!==p.fecha[k])throw Error('Se perdió un calificador del CSV en '+p.numero);
  incorporadas++;
 }else if(['inicio','fin','inicio_inclusivo','fin_inclusivo','aproximada'].some(k=>d[k]!==p.fecha[k]))discrepancias.push({obra_id:p.obra_id,titulo:p.titulo,conservada:d,csv:p.fecha,literal:p.fecha_literal});
}
guardar('discrepancias-csv.json',discrepancias);
const tables=filas("select tablename from pg_tables where schemaname='public' order by tablename").map(x=>x.tablename);
const estado = () => huellasDe(tables);
const una=estado();sql(carga);const dos=estado();
if(JSON.stringify(una)!==JSON.stringify(dos))throw Error('La segunda carga produjo cambios');
for(const n of ['pruebas-cambio','pruebas-dataciones']) {
 const r=sql(readFileSync('scripts/control-obras/'+n+'.sql','utf8'));
 writeFileSync(dir+'/'+n+'.log',r,'utf8');console.log(r);
}
const concurrenciaComprobada=await probarConcurrencia(base);
console.log('Concurrencia: un guardado anterior no sobrescribe el encargo nuevo.');
if(JSON.stringify(dos)!==JSON.stringify(estado()))throw Error('Las pruebas no revirtieron todas sus escrituras');
if(JSON.stringify(antes)!==JSON.stringify(huellas()))throw Error('Cambió métrica o procedencia');
if(timeoutOriginal.length!==7||JSON.stringify(timeoutOriginal)!==JSON.stringify(funcionesTimeout()))throw Error('Se alteró la corrección del timeout métrico');
writeFileSync(dir+'/modelo-y-csv.dump',docker(['exec',contenedor,'pg_dump','-U','supabase_admin','-d',base,'-Fc'],undefined,true));
if(final){
 // Simular una edición posterior al cambio: la reversión debe conservarla y mantener las tablas nuevas.
 const prueba=sql(`select set_config('request.jwt.claim.sub',(select e.user_id::text from public.editores e join public.vocabularios v on v.termino_id=e.role where v.termino in ('admin','ip') and coalesce(e.activo,true) limit 1),false);
 insert into public.obras_editoriales(titulo,tipo_ficha,editor_asignado) values('Ensayo de conservación tras desplegar','completa',auth.uid()) returning obra_id;`).split('\n').at(-1);
 if(!/^[0-9a-f-]{36}$/.test(prueba))throw Error('No se creó la prueba de reversión');
 sql(`update public.fichas_completas set inicio_elaboracion=now(),edicion_base='Edición añadida después',observaciones='Análisis posterior: ñ y acentos' where obra_id='${prueba}';
 insert into public.obras_dataciones(obra_id,clase,inicio,fin,fin_inclusivo,fuente) values('${prueba}','referencia',null,1600,false,'Fuente posterior');`);
 const fechasNuevas=filas('select * from public.obras_dataciones order by obra_id,clase');
 const completas=filas('select obra_id,editor_asignado,edicion_base,observaciones from public.fichas_completas order by obra_id');
 sql(readFileSync(copiaActual+'/revertir-control-obras.sql','utf8'));
 if(JSON.stringify(fechasNuevas)!==JSON.stringify(filas('select * from public.obras_dataciones order by obra_id,clase')))throw Error('La reversión perdió dataciones nuevas');
 const nucleoRevertido=filas('select obra_id,editor_asignado,edicion,observaciones from public.obras');
 for(const f of completas){const o=nucleoRevertido.find(o=>o.obra_id===f.obra_id);
  if(!o||o.editor_asignado!==f.editor_asignado||o.edicion!==f.edicion_base||o.observaciones!==f.observaciones)throw Error('La reversión perdió análisis o asignación');}
 sql('set statement_timeout=600000; select public.recompute_all();');
 if(JSON.stringify(antes)!==JSON.stringify(huellas()))throw Error('La reversión modificó métrica o importaciones');
 if(JSON.stringify(timeoutOriginal)!==JSON.stringify(funcionesTimeout()))throw Error('La reversión perdió la corrección del timeout');
 console.log('Reversión ejecutada: conserva datos posteriores, métrica, JSON y límites en las tablas archivadas.');
}
const informe={comprobado_en:new Date().toISOString(),base,obras:fechas.length,fechasYFuentesConservadas:true,asignacionesConservadas:true,
 copiaActual,
 migracionFinal:final,reversionComprobada:final,
 concurrenciaComprobada,
 correccionesDatacionAutorizadas:[{obra:'El esclavo del demonio',obra_id:'443d1994-5ded-436e-a89f-54dcd538d732',inicio:null,fin:1612,fin_inclusivo:true}],
 metricasYJsonConservados:protegidas,cargaIdempotente:true,pruebasRevertidas:true,correccionTimeoutConservada:true,datacionesIncorporadas:incorporadas,
 discrepanciasSinSobrescribir:discrepancias.length,corpus:filas('select c.codigo,count(oc.obra_id) as obras from public.corpus c left join public.obras_corpus oc using(corpus_id) group by c.codigo order by c.codigo'),
 entradas: Object.fromEntries([...archivos,'backups/control-obras/visual/plan-carga-csv.json'].map(p=>[p,createHash('sha256').update(readFileSync(p)).digest('hex')]))};
guardar('resultado.json',informe);
writeFileSync('backups/control-obras/fechas/ultimo-ensayo.txt',dir,'utf8');
console.log(informe);
