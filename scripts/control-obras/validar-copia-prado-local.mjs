/** Restaura la instantánea nueva SOLO en la copia de incidencia, conservando antes otra copia. */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { docker, contenedor, exigirAislamiento } from './local-db.mjs';
exigirAislamiento();
const destino='backups/incidencia-prado-20261110';
const base='incidencia_prado_20261110';
const carpeta=process.argv[2];
if(!carpeta?.startsWith(destino+'/')) throw Error('Se exige una instantánea de esta incidencia');
const args=['exec','-i',contenedor,'psql','-X','-qAt','-U','supabase_admin','-d',base,'-v','ON_ERROR_STOP=1'];
const sql=s=>docker(args,s).trim();
const copia=`${destino}/antes-validar-copia.dump`;
if(existsSync(copia)) throw Error('La copia previa ya existe; no se sobrescribe');
writeFileSync(copia,docker(['exec',contenedor,'pg_dump','-U','supabase_admin','-d',base,'-Fc'],undefined,true));
sql(`set session_replication_role=replica;
do $$ declare tablas text; begin
 select string_agg(format('%I.%I',n.nspname,c.relname),',') into tablas
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname in ('public','auth','storage','supabase_migrations') and c.relkind='r';
 execute 'truncate table '||tablas||' restart identity cascade';
end $$;`);
docker(['exec','-i',contenedor,'pg_restore','-U','supabase_admin','-d',base,'--data-only','--disable-triggers','--single-transaction','--exit-on-error'],readFileSync(`${carpeta}/datos-consistentes.dump`));
const huellas=JSON.parse(sql(`select coalesce(jsonb_agg(to_jsonb(t)),'[]') from (${readFileSync(`${carpeta}/huellas.sql`,'utf8').trim().replace(/;$/,'')}) t;`));
const remoto=JSON.parse(readFileSync(`${carpeta}/huellas-remotas.json`,'utf8')).tablas;
const diferencias=huellas.filter(h=>!remoto.some(r=>r.tabla===h.tabla&&r.filas===h.filas&&r.sha256===h.sha256));
writeFileSync(`${destino}/validacion-restauracion.json`,JSON.stringify({tablas:huellas,diferencias},null,2),'utf8');
if(diferencias.length) throw Error('Huellas distintas: comprobar también posibles ediciones concurrentes en Supabase');
sql(`do $$ declare fk record; campos text; union_campos text; faltantes bigint; begin
 for fk in select c.*,n.nspname as esquema,t.relname as tabla,nr.nspname as esquema_referido,tr.relname as tabla_referida
 from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace
 join pg_class tr on tr.oid=c.confrelid join pg_namespace nr on nr.oid=tr.relnamespace
 where c.contype='f' and n.nspname in ('public','auth','storage','supabase_migrations') loop
  select string_agg(format('h.%I is not null',a.attname),' and ' order by k.i),
   string_agg(format('h.%I=p.%I',a.attname,b.attname),' and ' order by k.i)
  into campos,union_campos from generate_subscripts(fk.conkey,1) k(i)
  join pg_attribute a on a.attrelid=fk.conrelid and a.attnum=fk.conkey[k.i]
  join pg_attribute b on b.attrelid=fk.confrelid and b.attnum=fk.confkey[k.i];
  execute format('select count(*) from %I.%I h where %s and not exists(select 1 from %I.%I p where %s)',fk.esquema,fk.tabla,campos,fk.esquema_referido,fk.tabla_referida,union_campos) into faltantes;
  if faltantes>0 then raise exception 'Referencias inválidas en %',fk.conname; end if;
 end loop;
end $$;`);
console.log(`Restauración nueva comprobada: ${huellas.length} tablas idénticas y referencias válidas. No se modificó Supabase.`);
