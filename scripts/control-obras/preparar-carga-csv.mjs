/** Preparación de metadatos provisionales desde el CSV; solo produce un plan privado y SQL de ensayo. */
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fechaCsv} from './fecha-csv.mjs';
const dir='backups/control-obras/visual';
const cotejo=JSON.parse(readFileSync(dir+'/cotejo-csv-conciliado.json','utf8'));
if(cotejo.resumen.unicas!==cotejo.resumen.filas)throw Error('Quedan identidades por resolver');
const normalizar=s=>s.normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase().replace(/[^\p{L}\p{N}]+/gu,' ').trim();
const aliases=new Map([
 ['Miguel de Cervantes Saavedra','Miguel de Cervantes'],['Gabriel Lobo Lasso','Gabriel Lobo Laso de la Vega'],
 ['Lope de Vega Carpio','Lope de Vega'],['Guillén de Castro y Bellvís','Guillem de Castro'],
 ['Gaspar de Aguilar','Gaspar Aguilar'],['Pedro Calderón de la Barca','Calderón de la Barca'],
 ['Antonio Coello','Antonio Coello y Ochoa'],['Antonio de Solís y Rivadeneyra','Antonio de Solís'],
 ['Cristóbal de Morales y Guerrero','Cristóbal de Morales'],['Agustín Moreto y Cavana','Agustín Moreto'],
 ['Sor Juana Inés de Cruz','Sor Juana Inés de la Cruz']
].map(([a,b])=>[normalizar(a),b]));
const canon=s=>aliases.get(normalizar(s))??s.trim();
const filas=cotejo.entradas.map(r=>{
 const fuente=r.fuente,trad=fuente['Atribución tradicional'],lex=fuente['Atribución ETSO'];
 const propuestas=new Map();
 const añadir=(nombre,tipo,literal)=>{
  const autor=/^An[oó]nimo\b/iu.test(nombre)?null:canon(nombre.replace(/\s*\(atribuida\)\s*$/iu,''));
  const clave=autor?normalizar(autor):'desconocida';
  const p=propuestas.get(clave)??{autor,evidencias:[]};
  // ETSO puede repetir el mismo candidato; no se crean propuestas o evidencias duplicadas.
  if(!p.evidencias.some(e=>e.tipo===tipo))p.evidencias.push({tipo,literal});
  propuestas.set(clave,p);
 };
 añadir(trad,'tradicional',trad);
 if(!/^No\b/iu.test(lex)){
  const candidatos=[...lex.matchAll(/([^\[\]]+)\s*\[(Segura|Probable)\]/gu)];
  if(!candidatos.length)throw Error('Resultado ETSO no reconocido en fila '+r.numero);
  for(const m of candidatos)añadir(m[1].replace(/^\s*y\s+/u,'').trim(),'estilometria_lexica',`${m[1].replace(/^\s*y\s+/u,'').trim()} [${m[2]}]`);
 }
 return {numero:r.numero,obra_id:r.candidatos[0].obra_id,titulo:r.candidatos[0].titulo,
  corpus:fuente.Tipo==='Plus'?null:fuente.Tipo,
  fecha:fechaCsv(fuente.Datación),fecha_literal:fuente.Datación,fuente_fecha:fuente['Fuente fecha'],
  propuestas:[...propuestas.values()],resultado_etso:lex,fuente_original:fuente};
});
const sha=createHash('sha256').update(readFileSync(dir+'/csv-original.json')).digest('hex');
const plan={origen_sha256:sha,criterio:'Solo completar vacíos; conservar fechas, propuestas y asignaciones existentes. Pertenencias aditivas. Resultados ETSO no concluyentes se conservan en la fuente sin fabricar autores.',filas};
writeFileSync(dir+'/plan-carga-csv.json',JSON.stringify(plan,null,2),'utf8');
const literal=x=>`'${JSON.stringify(x).replaceAll("'","''")}'::jsonb`;
let sql=`begin;
set local lock_timeout='5s'; set local statement_timeout='120s';
do $$ begin if current_database()<>'control_obras_preparacion' then raise exception 'Solo ensayo local'; end if; end $$;
create temporary table _carga_control_candidata(fila jsonb) on commit drop;
insert into _carga_control_candidata values ${filas.map(r=>'('+literal({...r,origen_sha256:sha})+')').join(',\n')};
`;
sql+=readFileSync(new URL('./carga-csv.sql',import.meta.url),'utf8');
sql+='\ncommit;\n';
writeFileSync(dir+'/carga-csv-ensayo.sql',sql,'utf8');
console.log({obras:filas.length,propuestas:filas.reduce((n,f)=>n+f.propuestas.length,0),fechasConUnLimite:filas.filter(f=>(f.fecha.inicio===null)!==(f.fecha.fin===null)).length});
