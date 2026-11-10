/** Prepara SQL y reversión desde el inventario actual. No ejecuta SQL ni escribe en migrations/. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
const dir=readFileSync('backups/control-obras/contraccion/ultima-restauracion.txt','utf8').trim();
if(existsSync(dir+'/manifest.json'))throw Error('Ensayo sellado: crear otra restauración, no sobrescribirlo');
const restauracion=JSON.parse(readFileSync(dir+'/restauracion.json','utf8'));
const inv=JSON.parse(readFileSync(restauracion.copia+'/inventario.json','utf8'));
const bloque=n=>inv.filas.find(b=>b.bloque===n).datos;
const movidos=['edicion','editor_asignado','fecha_asignacion','estado','visible_publico','fecha_cambio_estado',
 'fecha_publicacion','autor_ficha_publico','bibliografia','observaciones','sin_figuras_donaire',
 'sin_personajes_sobrenaturales','sin_eventos_sobrenaturales','tipo_ficha','fecha_inicio_trad',
 'fecha_fin_trad','fuente_fecha','fecha_inicio_metadrama','fecha_fin_metadrama'];
const ident=s=>'"'+s.replaceAll('"','""')+'"';
const funciones=bloque('funciones');
const original=funciones.find(f=>f.firma==='escribir_obra_editorial()')?.definicion;
if(!original)throw Error('Falta el escritor vigente');
const insercion=/insert into public\.obras\(obra_id,titulo,titulo_normalizado,variantes_titulo,genero_id,total_versos,slug,estado,tipo_ficha\)\s*values\(id,new\.titulo,new\.titulo_normalizado,new\.variantes_titulo,new\.genero_id,\s*new\.total_versos,coalesce\(new\.slug,''\),borrador,case when new\.tipo_ficha='basica' then 'minima' else 'completa' end\);/;
if(!insercion.test(original))throw Error('El escritor cambió: revisar la contracción');
const nuevo=original.replace(insercion,()=>`insert into public.obras(obra_id,titulo,titulo_normalizado,variantes_titulo,genero_id,total_versos,slug)
  values(id,new.titulo,new.titulo_normalizado,new.variantes_titulo,new.genero_id,new.total_versos,coalesce(new.slug,''));`);
const politicas=bloque('politicas').filter(p=>p.tablename==='obras'&&p.policyname!=='obras_consulta_editorial');
if(politicas.some(p=>p.cmd==='SELECT'))throw Error('Política de lectura inesperada');
const archivos=['guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])','impedir_publicacion_minima()'];
let sql=`-- Generado por scripts/control-obras/preparar-contraccion.mjs; ensayar antes de materializar.
begin;
set local lock_timeout='5s'; set local statement_timeout='120s';
lock table public.obras,public.fichas_completas,public.obras_dataciones in share row exclusive mode;
do $$ begin
 if not exists(select 1 from supabase_migrations.schema_migrations where version='20261110200000') then raise exception 'Falta la migración editorial'; end if;
 if md5(pg_get_functiondef('public.escribir_obra_editorial()'::regprocedure))<>'${createHash('md5').update(original).digest('hex')}' then raise exception 'El escritor cambió desde el inventario; volver a auditar'; end if;
 if exists(select 1 from public.obras_revisores r left join public.fichas_completas f using(obra_id) where f.obra_id is null) then raise exception 'Revisor sin completa'; end if;
end $$;
create temporary table _editorial_antes_contraccion on commit drop as select obra_id,to_jsonb(o) as fila from public.obras_editoriales o;
${nuevo};
drop trigger impedir_publicacion_minima on public.obras;
drop function public.impedir_publicacion_minima();
drop function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]);
drop view if exists public.control_obras_preparacion;
${politicas.map(p=>`drop policy if exists ${ident(p.policyname)} on public.obras;`).join('\n')}
alter table public.obras_revisores drop constraint obras_revisores_obra_id_fkey;
alter table public.obras_revisores add constraint obras_revisores_obra_id_fkey foreign key(obra_id) references public.fichas_completas(obra_id) on delete cascade;
create index if not exists fichas_completas_por_editor on public.fichas_completas(editor_asignado);
create index if not exists fichas_completas_por_estado on public.fichas_completas(estado);
create index if not exists fichas_completas_por_visibilidad on public.fichas_completas(visible_publico);
alter table public.obras ${movidos.map(c=>`drop column ${ident(c)}`).join(',\n ')};
do $$ begin
 if exists(select 1 from _editorial_antes_contraccion a full join public.obras_editoriales b using(obra_id) where a.fila is distinct from to_jsonb(b)) then raise exception 'La contracción cambió el contrato o sus datos'; end if;
end $$;
notify pgrst,'reload schema';
commit;
`;
sql=sql.replace(/\r\n/g,'\n');
writeFileSync(dir+'/contraccion.sql',sql,'utf8');
const columnas=bloque('columnas').filter(c=>c.table_name==='obras'&&movidos.includes(c.column_name));
if(columnas.length!==movidos.length)throw Error('Faltan columnas de origen');
let revertir=`-- Recupera el esquema previo usando los metadatos vigentes; no restaura una copia antigua.
begin;
set local lock_timeout='5s'; set local statement_timeout='120s';
lock table public.obras,public.fichas_completas,public.obras_dataciones in share row exclusive mode;
create temporary table _editorial_actual on commit drop as select * from public.obras_editoriales;
alter table public.obras ${columnas.map(c=>`add column ${ident(c.column_name)} ${c.data_type}`).join(',\n ')};
alter table public.obras disable trigger trigger_obras_updated_at;
update public.obras o set ${columnas.map(c=>`${ident(c.column_name)}=${c.column_name==='tipo_ficha'?"case when e.tipo_ficha='basica' then 'minima' else 'completa' end":'e.'+ident(c.column_name)}`).join(',\n ')} from _editorial_actual e where o.obra_id=e.obra_id;
alter table public.obras enable trigger trigger_obras_updated_at;
${columnas.flatMap(c=>[...(c.column_default?[`alter table public.obras alter column ${ident(c.column_name)} set default ${c.column_default};`]:[]),...(c.is_nullable==='NO'?[`alter table public.obras alter column ${ident(c.column_name)} set not null;`]:[])]).join('\n')}
${bloque('restricciones').filter(c=>['obras','public.obras'].includes(c.tabla)&&!['obras_pkey','obras_slug_key','obras_genero_id_fkey'].includes(c.nombre)).map(c=>`alter table public.obras add constraint ${ident(c.nombre)} ${c.definicion};`).join('\n')}
${original};
${archivos.map(a=>funciones.find(f=>f.firma===a)?.definicion+';').join('\n')}
revoke all on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) from public,anon,authenticated,service_role;
create trigger impedir_publicacion_minima before insert or update on public.obras for each row execute function public.impedir_publicacion_minima();
alter table public.obras_revisores drop constraint obras_revisores_obra_id_fkey;
alter table public.obras_revisores add constraint obras_revisores_obra_id_fkey foreign key(obra_id) references public.obras(obra_id) on delete cascade;
notify pgrst,'reload schema';
commit;
`;
if(revertir.includes('undefined'))throw Error('Reversión incompleta');
writeFileSync(dir+'/revertir-contraccion.sql',revertir.replace(/\r\n/g,'\n'),'utf8');
writeFileSync(dir+'/candidata.json',JSON.stringify({fecha:new Date().toISOString(),archivo:dir+'/contraccion.sql',sha256:createHash('sha256').update(sql).digest('hex'),columnasRetiradas:movidos,base:restauracion.base},null,2),'utf8');
console.log(`Contracción preparada: ${movidos.length} columnas; no se ha ejecutado SQL.`);
