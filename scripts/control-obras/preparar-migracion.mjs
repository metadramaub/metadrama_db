/** Compone la migración transaccional y una reversión conservadora desde la copia auditada. */
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
const dir=readFileSync('backups/control-obras/ultimo-despliegue.txt','utf8').trim();
const inv=JSON.parse(readFileSync(dir+'/inventario.json','utf8'));
const bloque=n=>inv.filas.find(x=>x.bloque===n).datos;
const ident=s=>'"'+s.replaceAll('"','""')+'"';
const lit=s=>"'"+s.replaceAll("'","''")+"'";
function cuerpo(nombre){
 let s=readFileSync('scripts/control-obras/'+nombre,'utf8');
 if((s.match(/^begin;\r?$/gmi)??[]).length!==1||(s.match(/^commit;\r?$/gmi)??[]).length!==1)throw Error('Límites transaccionales inesperados');
 s=s.replace(/^begin;\r?\n/mi,'').replace(/^commit;\r?$/mi,'');
 if(nombre.startsWith('001-'))s=s.replace(/ if current_database\(\)<>'control_obras_preparacion' then\r?\n  raise exception 'Candidata restringida a la restauración local control_obras_preparacion';\r?\n end if;\r?\n/,'');
 else s=s.replace(/do \$\$ begin if current_database\(\)<>'control_obras_preparacion' then raise exception 'Solo ensayo local'; end if; end \$\$;\r?\n/,'');
 if(s.includes("current_database()<>'control_obras_preparacion'"))throw Error('No se retiró la guarda local');
 return s;
}
let sql=`-- Generado por scripts/control-obras/preparar-migracion.mjs; no editar a mano.
-- Requiere copia completa comprobada y despliegue coordinado de la aplicación.
begin;
set local lock_timeout='5s';
set local statement_timeout='120s';
lock table public.obras,public.importaciones_metricas in share row exclusive mode;
do $$ begin
 if not exists(select 1 from supabase_migrations.schema_migrations where version='20261110130000') then
  raise exception 'Falta la corrección previa del timeout métrico'; end if;
 if to_regclass('public.obras_editoriales') is not null then
  raise exception 'El modelo editorial ya está activo; comprobar el historial antes de repetir'; end if;
end $$;
create temporary table _control_obras_origen on commit drop as select obra_id,to_jsonb(o) as fila from public.obras o;
create temporary table _control_importaciones_origen on commit drop as select importacion_id,to_jsonb(i) as fila from public.importaciones_metricas i;
`;
sql+=cuerpo('001-expandir-ensayo.sql')+'\n'+cuerpo('002-cambio-ensayo.sql');
sql+=`
do $$ begin
 if exists(select 1 from _control_obras_origen a full join public.obras b using(obra_id)
  where a.fila is distinct from to_jsonb(b)) then raise exception 'Se alteró el registro original de una obra'; end if;
 if exists(select 1 from _control_importaciones_origen a full join public.importaciones_metricas b using(importacion_id)
  where a.fila is distinct from to_jsonb(b)) then raise exception 'Se alteró una importación original'; end if;
end $$;
-- Contratos JSON nuevos: la cola debe regenerar también las obras que no cambiaron de fecha.
update public.obras_resumen set metrica_sucia=true;
update public.autores_resumen set metrica_sucia=true;
notify pgrst,'reload schema';
commit;
`;
const archivoVersionado='supabase/migrations/20261110200000_control_de_obras_y_dataciones.sql';
// Canonizar antes del ensayo: Git debe conservar exactamente los bytes que se apliquen.
sql=sql.replace(/\r\n/g,'\n');
const archivo=dir+'/20261110200000_control_de_obras_y_dataciones.sql';
const versionada=spawnSync('git',['ls-files','--error-unmatch',archivoVersionado],{encoding:'utf8'}).status===0;
if(versionada&&readFileSync(archivoVersionado,'utf8')!==sql)throw Error('La migración ya está versionada: crear otra versión en lugar de modificarla');
writeFileSync(archivo,sql,'utf8');
// Mantener la candidata fuera de db push hasta la activación coordinada. Solo retirar nuestra
// salida idéntica no versionada; la copia completa acaba de verificarse byte a byte.
if(!versionada&&existsSync(archivoVersionado)){
 if(readFileSync(archivoVersionado,'utf8')!==sql)throw Error('Hay una candidata local distinta; no se retira');
 if(readFileSync(archivo,'utf8')!==sql)throw Error('La copia de la candidata no es idéntica');
 unlinkSync(archivoVersionado);
}

// La reversión mantiene todas las tablas y datos nuevos. Nunca restaura a ciegas un volcado antiguo.
let revertir=`-- Generado desde la copia ${inv.consultado_en}. Tomar otra copia antes de ejecutarlo.
-- Restaurar la aplicación compatible con el modelo anterior como parte de la misma operación.
-- No elimina tablas, corpus, dataciones, importaciones ni trabajos posteriores a la migración.
begin;
set local lock_timeout='5s'; set local statement_timeout='120s';
lock table public.obras,public.fichas_completas,public.obras_dataciones in share row exclusive mode;
update public.obras o set editor_asignado=f.editor_asignado,fecha_asignacion=f.fecha_asignacion,
 edicion=f.edicion_base,bibliografia=f.bibliografia,observaciones=f.observaciones,
 estado=f.estado,visible_publico=f.visible_publico,fecha_cambio_estado=f.fecha_cambio_estado,
 fecha_publicacion=f.fecha_publicacion,autor_ficha_publico=f.autor_ficha_publico,
 sin_figuras_donaire=f.sin_figuras_donaire,sin_personajes_sobrenaturales=f.sin_personajes_sobrenaturales,
 sin_eventos_sobrenaturales=f.sin_eventos_sobrenaturales from public.fichas_completas f where f.obra_id=o.obra_id;
update public.obras o set fecha_inicio_trad=dr.inicio,fecha_fin_trad=dr.fin,fuente_fecha=dr.fuente,
 fecha_inicio_metadrama=dm.inicio,fecha_fin_metadrama=dm.fin
 from public.obras_editoriales v left join public.obras_dataciones dr on dr.obra_id=v.obra_id and dr.clase='referencia'
 left join public.obras_dataciones dm on dm.obra_id=v.obra_id and dm.clase='metrica' where o.obra_id=v.obra_id;
update public.obras o set edicion=i.datos_confirmados#>>'{metadatos,edicion_base}'
 from public.importaciones_metricas i where i.obra_id=o.obra_id and not exists(select 1 from public.fichas_completas f where f.obra_id=o.obra_id);
`;
for(const f of bloque('funciones')){
 if(/public\.obras\b/.test(f.definicion)||['auth_puede_ver_obra','auth_puede_editar_obra','auth_obra_es_detallada'].some(n=>f.firma.startsWith(n+'(')))revertir+=f.definicion+';\n';
}
const politicas=bloque('politicas').filter(p=>p.schemaname==='public');
const tablas=[...new Set(politicas.map(p=>p.tablename))];
revertir+=`do $$ declare p record; begin for p in select tablename,policyname from pg_policies where schemaname='public' and tablename=any(array[${tablas.map(lit).join(',')}]) loop
 execute format('drop policy %I on public.%I',p.policyname,p.tablename); end loop; end $$;\n`;
for(const p of politicas){
 const roles=Array.isArray(p.roles)?p.roles: String(p.roles).replace(/[{}]/g,'').split(',');
 revertir+=`create policy ${ident(p.policyname)} on public.${ident(p.tablename)} as ${p.permissive} for ${p.cmd} to ${roles.map(ident).join(',')}${p.qual?' using ('+p.qual+')':''}${p.with_check?' with check ('+p.with_check+')':''};\n`;
}
for(const t of bloque('triggers').filter(t=>['obras','public.obras'].includes(t.tabla)))revertir+=`drop trigger if exists ${ident(t.nombre)} on public.obras;\n${t.definicion};\n`;
const esquema=readFileSync(dir+'/schema.sql','utf8');
revertir+=esquema.split('\n').filter(l=>/^(GRANT|REVOKE) .*ON TABLE "public"\."obras"/.test(l)||/^(GRANT|REVOKE) .*ON FUNCTION "public"\."guardar_ficha_minima"/.test(l)).join('\n')+'\n';
revertir+=`revoke all on public.obras_editoriales,public.obras_consulta_publica,public.control_obras_preparacion,
 public.fichas_completas,public.obras_dataciones,public.corpus,public.obras_corpus from anon,authenticated;
revoke execute on function public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid),
 public.iniciar_ficha_completa(uuid,uuid,boolean),public.gestionar_corpus(text,text,text,uuid[]),
 public.listar_corpus_gestion(),public.destino_importacion_metrica(uuid) from anon,authenticated;
grant execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) to authenticated;
update public.obras_resumen set metrica_sucia=true;
update public.autores_resumen set metrica_sucia=true;
notify pgrst,'reload schema';
commit;
`;
writeFileSync(dir+'/revertir-control-obras.sql',revertir.replace(/\r\n/g,'\n'),'utf8');
writeFileSync(dir+'/migracion.json',JSON.stringify({archivo,archivoVersionado,generada_en:new Date().toISOString(),sha256:createHash('sha256').update(sql).digest('hex'),reversionConservaDatos:true},null,2),'utf8');
console.log('Migración y reversión generadas. No se ha escrito en Supabase.');
