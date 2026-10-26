-- Solo SELECT: estructura y seguridad necesarias para preparar el guardado mínimo.
select jsonb_build_object(
  'fecha_consulta',current_date,
  'origen','SELECT de solo lectura; preparación de persistencia, sin DDL ni datos personales',
  'columnas',(select jsonb_agg(to_jsonb(c) order by c.table_name,c.ordinal_position)
    from (select table_schema,table_name,ordinal_position,column_name,udt_name,is_nullable,column_default
      from information_schema.columns) c where c.table_schema='public' and c.table_name in
    ('editores','autores','obras','jornadas','secuencias_metricas','grupos_atribucion',
     'atribuciones','atribucion_autores','atribucion_evidencias','formas_metricas','arquitecturas_forma',
     'metros','estructuras_secciones','vocabularios')),
  'restricciones',(select jsonb_agg(jsonb_build_object('tabla',r.relname,'nombre',c.conname,
    'definicion',pg_get_constraintdef(c.oid)) order by r.relname,c.conname)
    from pg_constraint c join pg_class r on r.oid=c.conrelid join pg_namespace n on n.oid=r.relnamespace
    where n.nspname='public' and r.relname in ('editores','autores','obras','jornadas',
      'secuencias_metricas','grupos_atribucion','atribuciones','atribucion_autores','atribucion_evidencias',
      'formas_metricas','arquitecturas_forma')),
  'politicas',(select jsonb_agg(to_jsonb(p) order by p.tablename,p.policyname)
    from pg_policies p where p.schemaname='public'),
  'permisos_columnas',(select jsonb_agg(to_jsonb(g) order by g.table_name,g.grantee,g.column_name,g.privilege_type)
    from information_schema.column_privileges g where g.table_schema='public' and
      g.table_name in ('editores','obras') and g.grantee in ('anon','authenticated','service_role')),
  'triggers',(select jsonb_agg(jsonb_build_object('tabla',r.relname,'nombre',t.tgname,
    'definicion',pg_get_triggerdef(t.oid),'funcion',p.proname) order by r.relname,t.tgname)
    from pg_trigger t join pg_class r on r.oid=t.tgrelid join pg_namespace n on n.oid=r.relnamespace
      join pg_proc p on p.oid=t.tgfoid
    where n.nspname='public' and not t.tgisinternal and r.relname in
      ('editores','obras','jornadas','secuencias_metricas','grupos_atribucion',
       'atribuciones','atribucion_autores','atribucion_evidencias')),
  'funciones',(select jsonb_agg(jsonb_build_object('nombre',p.proname,
    'definicion',pg_get_functiondef(p.oid)) order by p.proname,p.oid)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and
    (p.oid in (select t.tgfoid from pg_trigger t join pg_class r on r.oid=t.tgrelid
      join pg_namespace n on n.oid=r.relnamespace where n.nspname='public' and not t.tgisinternal
      and r.relname in ('editores','obras','jornadas','secuencias_metricas','grupos_atribucion',
        'atribuciones','atribucion_autores','atribucion_evidencias'))
    or p.proname in ('auth_puede_editar_obra','auth_puede_ver_obra','auth_is_admin_or_ip',
      'obra_publica_visible','can_view_obra_ficha_publica','perfil_metrico_unidades')))
) as evidencia;
