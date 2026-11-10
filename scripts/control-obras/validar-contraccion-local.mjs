/** Ejecuta contratos, recuperación con datos posteriores y reaplicación; solo copia aislada. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
exigirAislamiento();
const dir=readFileSync('backups/control-obras/contraccion/ultima-restauracion.txt','utf8').trim();
if(existsSync(dir+'/manifest.json'))throw Error('Ensayo sellado: no se modifican sus evidencias');
const {base,copia}=JSON.parse(readFileSync(dir+'/restauracion.json','utf8'));
if(!/^control_obras_contraccion_\d+$/.test(base))throw Error('Solo ensayo desechable');
const sql=s=>docker(['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d',base,'-v','ON_ERROR_STOP=1'],s).trim();
const filas=s=>JSON.parse(sql(`select coalesce(jsonb_agg(to_jsonb(t)),'[]') from (${s}) t;`));
const meta=JSON.parse(readFileSync(dir+'/candidata.json','utf8'));
const soloRecuperacion=process.argv[2]==='--recuperacion';
if(process.argv.slice(2).some(a=>a!=='--recuperacion'))throw Error('Opción desconocida');
if(sql("select count(*) from information_schema.columns where table_schema='public' and table_name='obras' and column_name='tipo_ficha'")!=='0')sql(readFileSync(dir+'/contraccion.sql','utf8'));
for(const n of ['pruebas-cambio','pruebas-dataciones','pruebas-produccion-transaccionales']){
 if(soloRecuperacion){if(!readFileSync(dir+'/'+n+'.log','utf8').includes('OK '))throw Error('Falta prueba previa correcta');continue;}
 const salida=sql(readFileSync('scripts/control-obras/'+n+'.sql','utf8'));
 writeFileSync(dir+'/'+n+'.log',salida,'utf8');console.log(salida);
}
const [gestor]=filas("select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where v.termino in ('admin','ip') and coalesce(e.activo,true) limit 1");
// La creación está fuera de las pruebas revertidas para comprobar una edición posterior real.
const id=sql(`set request.jwt.claim.sub='${gestor.user_id}'; insert into public.obras_editoriales(titulo,tipo_ficha,editor_asignado)
 values('Ensayo de recuperación posterior a contracción','completa','${gestor.user_id}') returning obra_id;`).split('\n').at(-1);
if(!/^[0-9a-f-]{36}$/.test(id))throw Error('No se identificó la obra de prueba');
sql(`set request.jwt.claim.sub='${gestor.user_id}';update public.obras_editoriales set edicion='Edición posterior: ñ y acentos',observaciones='Análisis conservado',
 dataciones='[{"clase":"referencia","fin":1600,"fin_inclusivo":false,"fuente":"Fuente posterior"}]' where obra_id='${id}';`);
const contratoAntes=filas('select * from public.obras_editoriales order by obra_id');
sql(readFileSync(dir+'/revertir-contraccion.sql','utf8'));
const contratoDespues=filas('select * from public.obras_editoriales order by obra_id');
if(JSON.stringify(contratoAntes)!==JSON.stringify(contratoDespues))throw Error('La reversión alteró el contrato o los datos posteriores');
sql(readFileSync(dir+'/contraccion.sql','utf8'));
if(JSON.stringify(contratoAntes)!==JSON.stringify(filas('select * from public.obras_editoriales order by obra_id')))throw Error('Reaplicar alteró datos');
sql(`set request.jwt.claim.sub='${gestor.user_id}'; delete from public.obras_editoriales where obra_id='${id}';`);
const originales=JSON.parse(readFileSync(copia+'/huellas-remotas.json','utf8')).tablas;
const protegidas=['secuencias_metricas','jornadas','cuadros','anotaciones_metricas','anotacion_realizaciones','anotacion_elecciones','anotacion_desviaciones','importaciones_metricas'];
const restauradas=filas(readFileSync(copia+'/huellas.sql','utf8').trim().replace(/;$/,''));
const diferencias=restauradas.filter(a=>protegidas.some(t=>a.tabla==='public.'+t)&&!originales.some(b=>a.tabla===b.tabla&&a.filas===b.filas&&a.sha256===b.sha256));
if(diferencias.length)throw Error('Cambió métrica o procedencia');
const columnas=filas("select column_name from information_schema.columns where table_schema='public' and table_name='obras' order by ordinal_position").map(c=>c.column_name);
if(meta.columnasRetiradas.some(c=>columnas.includes(c)))throw Error('Sigue una columna retirada');
// El extractor debe ejecutarse; no basta que sus consultas compilen.
const extraidas=JSON.parse(sql(readFileSync('scripts/analitica/extraer-aportaciones-local.sql','utf8')));
if(extraidas.registros.some(r=>!Array.isArray(r.dataciones)))throw Error('Extracción sin el contrato de fechas');
const resultado={fecha:new Date().toISOString(),sha256:meta.sha256,base,copia,columnasNucleo:columnas,pruebasSQL:true,
 reversionConDatosPosteriores:true,reaplicacionComprobada:true,tablasProtegidas:protegidas.length,diferencias,
 registrosAnaliticos:extraidas.registros.length};
writeFileSync(dir+'/validacion.json',JSON.stringify(resultado,null,2),'utf8');console.log(resultado);
