/** Solo lectura: contrasta la métrica y las funciones del timeout con la copia sellada. */
import { readFileSync, writeFileSync } from 'node:fs';
import { query } from '../lib/consulta.mjs';
const destino=process.argv[2];
if(!destino?.startsWith('backups/control-obras/produccion/'))throw Error('Destino privado de producción requerido');
const copia=readFileSync('backups/control-obras/ultimo-despliegue.txt','utf8').trim();
const previas=JSON.parse(readFileSync(copia+'/huellas-remotas.json','utf8')).tablas;
const tablas=['secuencias_metricas','jornadas','cuadros','anotaciones_metricas','anotacion_realizaciones','anotacion_elecciones','anotacion_desviaciones','importaciones_metricas'];
const huellas=query(tablas.map(t=>`select 'public.${t}' as tabla,count(*)::integer as filas,encode(extensions.digest(coalesce(string_agg(encode(extensions.digest(convert_to(to_jsonb(t)::text,'UTF8'),'sha256'),'hex'),'' order by encode(extensions.digest(convert_to(to_jsonb(t)::text,'UTF8'),'sha256'),'hex')),''),'sha256'),'hex') as sha256 from public.${t} t`).join(' union all '));
const diferencias=huellas.filter(h=>!previas.some(a=>h.tabla===a.tabla&&h.filas===a.filas&&h.sha256===a.sha256));
const inv=JSON.parse(readFileSync(copia+'/inventario.json','utf8'));
const originales=inv.filas.find(f=>f.bloque==='funciones').datos;
const nombres=['opciones_eleccion_derivadas','validar_estructura_anotacion','guardar_anotacion_metrica','validar_estructura_anotacion_diferida','validar_extension_patron_anotacion_realizaciones','validar_arquitectura_de_realizacion','validar_densidad_de_pareados_regulares'];
const funciones=query(`select p.oid::regprocedure::text as firma,pg_get_functiondef(p.oid) as definicion from pg_proc p where pronamespace='public'::regnamespace and proname in (${nombres.map(n=>"'"+n+"'").join(',')}) order by proname;`);
const funcionesCambiadas=funciones.filter(f=>f.definicion!==originales.find(o=>o.firma===f.firma)?.definicion).map(f=>f.firma);
const resultado={fecha:new Date().toISOString(),copia,huellas,diferencias,funcionesTimeoutComprobadas:funciones.length,funcionesCambiadas};
writeFileSync(destino+'/integridad.json',JSON.stringify(resultado,null,2),'utf8');
if(diferencias.length||funcionesCambiadas.length||funciones.length!==7)throw Error('Hay diferencias: revisar actividad concurrente antes de concluir');
console.log('Ocho tablas y siete funciones idénticas a la copia sellada.');
