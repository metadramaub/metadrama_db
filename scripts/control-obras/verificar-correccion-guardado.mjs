/** Comprueba el despliegue mediante lecturas; no crea anotaciones en la obra real. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { query } from '../lib/consulta.mjs';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
const nombres=[
 'guardar_anotacion_metrica','opciones_eleccion_derivadas','validar_estructura_anotacion',
 'validar_estructura_anotacion_diferida','validar_extension_patron_anotacion_realizaciones',
 'validar_arquitectura_de_realizacion','validar_densidad_de_pareados_regulares'
];
const listado=nombres.map(n=>`'${n}'`).join(',');
const funciones=`select p.proname,pg_get_functiondef(p.oid) as definicion,p.prosecdef,p.proconfig,pg_get_userbyid(p.proowner) as propietario
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in (${listado}) order by p.proname`;
exigirAislamiento();
const esperado=JSON.parse(docker(['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d','incidencia_prado_20261110','-v','ON_ERROR_STOP=1'],`select jsonb_agg(to_jsonb(t)) from (${funciones}) t;`).trim());
const actual=query(`begin read only; ${funciones}; commit;`);
const normalizar=x=>JSON.stringify(x,Object.keys(x).sort());
const diferencias=actual.filter(a=>!esperado.some(e=>normalizar(a)===normalizar(e)));
const estado=query(`begin read only;
select exists(select 1 from supabase_migrations.schema_migrations where version='20261110130000') as migracion_aplicada,
 to_regclass('public.obras_editoriales') is not null as modelo_nuevo_aplicado,
 (select count(*) from public.anotaciones_metricas where secuencia_id='dca7f9e7-6782-4603-ad36-eba5c2f9f5b7') as anotaciones_prado,
 (select jsonb_agg(jsonb_build_object('secuencia_id',s.secuencia_id,'v_ini',s.v_ini,'v_fin',s.v_fin)) from public.secuencias_metricas s where s.obra_id='4df0c5c3-ee25-4a8c-9794-1e7800868365') as secuencias_prado;
commit;`);
const destino=`backups/incidencia-prado-20261110/despues-${new Date().toISOString().replace(/[:.]/g,'-')}`;
mkdirSync(destino,{recursive:true});
writeFileSync(`${destino}/verificacion.json`,JSON.stringify({funciones:actual,diferencias,estado},null,2),'utf8');
if(actual.length!==7||diferencias.length||!estado[0].migracion_aplicada||estado[0].modelo_nuevo_aplicado) throw Error('Revisar verificación del despliegue');
console.log(JSON.stringify({funcionesCoincidenConEnsayo:actual.length,estado,destino},null,2));
