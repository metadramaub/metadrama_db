/** Ensayo de carga, conservación de métrica y repetición sin cambios; nunca acepta conexión remota. */
import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {sql,filas,docker,contenedor,exigirAislamiento} from './local-db.mjs';
exigirAislamiento();
const dir='backups/control-obras/visual';
const copia=dir+'/antes-carga-csv.dump';
if(!existsSync(copia))writeFileSync(copia,docker(['exec',contenedor,'pg_dump','-U','supabase_admin','-d','control_obras_preparacion','-Fc'],undefined,true));
const protegidas=['secuencias_metricas','jornadas','cuadros','anotaciones_metricas','anotacion_realizaciones','anotacion_elecciones','anotacion_desviaciones','importaciones_metricas'];
const mutables=['obras','obras_dataciones','autores','grupos_atribucion','atribuciones','atribucion_autores','atribucion_evidencias','obras_corpus'];
const huellas=tablas=>Object.fromEntries(tablas.map(t=>[t,sql(`select encode(extensions.digest(coalesce(string_agg(to_jsonb(t)::text,E'\n' order by to_jsonb(t)::text),''),'sha256'),'hex') from public.${t} t;`)]));
const anteriores=huellas(protegidas);
const metadatos=filas('select obra_id,fecha_inicio_trad,fecha_fin_trad,editor_asignado from public.obras_editoriales');
const fuente=readFileSync(dir+'/carga-csv-ensayo.sql','utf8');
sql(fuente);
const posteriores=huellas(protegidas),primera=huellas(mutables);
for(const t of protegidas)if(anteriores[t]!==posteriores[t])throw Error('Se ha modificado métrica o procedencia: '+t);
const actuales=filas('select obra_id,fecha_inicio_trad,fecha_fin_trad,editor_asignado from public.obras_editoriales');
for(const a of metadatos){const b=actuales.find(x=>x.obra_id===a.obra_id);if(!b||a.editor_asignado!==b.editor_asignado)throw Error('Asignación modificada');if((a.fecha_inicio_trad!=null||a.fecha_fin_trad!=null)&&(a.fecha_inicio_trad!==b.fecha_inicio_trad||a.fecha_fin_trad!==b.fecha_fin_trad))throw Error('Datación existente modificada');}
sql(fuente);
const segunda=huellas(mutables);
for(const t of mutables)if(primera[t]!==segunda[t])throw Error('Carga no idempotente: '+t);
const duplicadas=filas(`select a.grupo_atribucion_id,a.composicion_autoria_id,(select array_agg(autor_id order by autor_id) from public.atribucion_autores aa where aa.atribucion_id=a.atribucion_id) as autores,count(*)
 from public.atribuciones a group by a.grupo_atribucion_id,a.composicion_autoria_id,autores having count(*)>1`);
if(duplicadas.length)throw Error('Propuestas duplicadas tras carga');
const informe={comprobado_en:new Date().toISOString(),metricasYJsonConservados:protegidas,asignacionesConservadas:true,fechasExistentesConservadas:true,cargaIdempotente:true,corpus:filas('select c.codigo,count(oc.obra_id) as obras from public.corpus c left join public.obras_corpus oc using(corpus_id) group by c.codigo order by c.codigo')};
writeFileSync(dir+'/validacion-carga-csv.json',JSON.stringify(informe,null,2),'utf8');
console.log(informe);
