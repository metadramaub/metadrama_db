begin transaction isolation level repeatable read read only;
select 'columnas' as bloque, coalesce(jsonb_agg(to_jsonb(t)),'[]') as datos
from (select table_name,column_name,data_type,is_nullable,column_default
      from information_schema.columns where table_schema='public'
      order by table_name,ordinal_position) t
union all
select 'restricciones',coalesce(jsonb_agg(jsonb_build_object(
  'tabla',c.conrelid::regclass::text,'nombre',c.conname,'definicion',pg_get_constraintdef(c.oid))), '[]')
from pg_constraint c join pg_namespace n on n.oid=c.connamespace where n.nspname='public'
union all
select 'funciones',coalesce(jsonb_agg(jsonb_build_object(
  'firma',p.oid::regprocedure::text,'definicion',pg_get_functiondef(p.oid),
  'security_definer',p.prosecdef,'config',p.proconfig,
  'execute_anon',has_function_privilege('anon',p.oid,'execute'),
  'execute_authenticated',has_function_privilege('authenticated',p.oid,'execute'))),'[]')
from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f'
union all
select 'vistas',coalesce(jsonb_agg(jsonb_build_object('nombre',c.relname,'tipo',c.relkind,
  'definicion',pg_get_viewdef(c.oid,true),'opciones',c.reloptions)),'[]')
from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('v','m')
union all
select 'politicas',coalesce(jsonb_agg(to_jsonb(p)),'[]') from pg_policies p where schemaname='public'
union all
select 'triggers',coalesce(jsonb_agg(jsonb_build_object('tabla',t.tgrelid::regclass::text,
  'nombre',t.tgname,'definicion',pg_get_triggerdef(t.oid))),'[]')
from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and not t.tgisinternal
union all
select 'obras',coalesce(jsonb_agg(to_jsonb(o) order by o.obra_id),'[]') from public.obras o
union all
select 'importaciones_integridad',coalesce(jsonb_agg(jsonb_build_object(
  'importacion_id',i.importacion_id,'obra_id',i.obra_id,'importado_por',i.importado_por,
  'usada_en_corpus',i.usada_en_corpus,'edicion_base',i.datos_confirmados#>>'{metadatos,edicion_base}',
  'huella_declarada',i.sha256_jsonb,
  'huella_calculada',encode(extensions.digest(convert_to(i.datos_confirmados::text,'UTF8'),'sha256'),'hex'),
  'huella_entrada',encode(extensions.digest(convert_to(i.entrada_original::text,'UTF8'),'sha256'),'hex'))),'[]')
from public.importaciones_metricas i
union all
select 'referencias_obras',coalesce(jsonb_agg(jsonb_build_object('tabla',c.conrelid::regclass::text,
  'nombre',c.conname,'definicion',pg_get_constraintdef(c.oid))),'[]')
from pg_constraint c where c.contype='f' and c.confrelid='public.obras'::regclass
union all
select 'dependencias_catalogo',coalesce(jsonb_agg(jsonb_build_object(
 'objeto',pg_describe_object(d.classid,d.objid,d.objsubid),'columna',a.attname,'tipo',d.deptype)),'[]')
from pg_depend d left join pg_attribute a on a.attrelid=d.refobjid and a.attnum=d.refobjsubid
where d.refobjid='public.obras'::regclass
union all
select 'migraciones',coalesce(jsonb_agg(jsonb_build_object('version',version,'nombre',name) order by version),'[]')
from supabase_migrations.schema_migrations;
commit;
