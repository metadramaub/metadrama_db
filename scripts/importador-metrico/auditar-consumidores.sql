-- Solo lectura. Referencias directas a obras; no sustituye la revisión de dependencias transitivas.
select jsonb_build_object(
  'fecha', current_date,
  'origen', 'SELECT de solo lectura; firmas, huellas y permisos, sin datos de obras o personas',
  'alcance', 'Funciones que mencionan obras o dashboard y vistas que mencionan obras o secuencias_metricas. No acredita ejecución ni auditoría transitiva completa.',
  'funciones', (
    select jsonb_agg(jsonb_build_object(
      'nombre',p.proname,'firma',p.oid::regprocedure::text,'security_definer',p.prosecdef,
      'sha256_definicion',encode(extensions.digest(pg_get_functiondef(p.oid),'sha256'),'hex'),
      'execute_anon',has_function_privilege('anon',p.oid,'execute'),
      'execute_authenticated',has_function_privilege('authenticated',p.oid,'execute')
    ) order by p.proname,p.oid)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'
      and (p.prosrc ilike '%obras%' or p.proname ilike '%dashboard%')
  ),
  'vistas', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'nombre',viewname,'sha256_definicion',encode(extensions.digest(definition,'sha256'),'hex')
    ) order by viewname),'[]'::jsonb)
    from pg_views where schemaname='public'
      and (definition ilike '%obras%' or definition ilike '%secuencias_metricas%')
  )
) as auditoria;
