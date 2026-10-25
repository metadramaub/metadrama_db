-- Solo lectura. Evidencia de esquema, garantías y consumidores para el diseño del importador.
with tablas as (
  select unnest(array[
    'obras','jornadas','cuadros','secuencias_metricas','anotaciones_metricas',
    'anotacion_realizaciones','anotacion_elecciones','anotacion_desviaciones',
    'atribuciones','atribucion_autores','atribucion_evidencias','grupos_atribucion',
    'secuencias_caracterizaciones_rango','obras_resumen','autores_resumen','artefactos_publicos'
  ]) as nombre
), funciones as (
  select p.oid,p.proname,p.prosecdef,p.provolatile,
    pg_get_function_identity_arguments(p.oid) as argumentos
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and (
    p.proname in (
      'guardar_anotacion_metrica','validar_anotacion_metrica','validar_anotacion_realizacion',
      'validar_anotacion_eleccion','validar_anotacion_desviacion','validar_estructura_anotacion',
      'validar_estructura_anotacion_diferida','validar_extension_patron_anotacion_realizaciones',
      'obra_publica_visible','can_view_obra_ficha_publica','obra_de_anotacion',
      'perfil_metrico_unidades','perfil_artefacto_obra_rango','formas_de_la_obra',
      'auth_puede_ver_obra','auth_puede_editar_obra',
      'recompute_obra_resumen_metricas','recompute_obra_resumen_estructura','recompute_obra_resumen',
      'recompute_autor_resumen','recompute_artefactos_obra','recompute_artefactos_autor',
      'recompute_artefactos_globales','plan_recompute_datos_publicos','finalizar_recompute_datos_publicos',
      'autor_ficha_artefacto_json','corpus_comparativas_artefacto_json','guardar_artefacto_publico',
      'ficha_publica_base_json','ficha_publica_dominio_json','marcar_artefactos_obra_sucios'
    ) or p.oid in (
      select tg.tgfoid from pg_trigger tg join pg_class c on c.oid=tg.tgrelid
      join pg_namespace ns on ns.oid=c.relnamespace
      where ns.nspname='public' and c.relname in (select nombre from tablas) and not tg.tgisinternal
    )
  )
)
select jsonb_build_object(
  'fecha_consulta',current_date,
  'origen','SELECT de solo lectura; DDL observado, sin ejecutar guardados ni recomputaciones',
  'columnas',(
    select jsonb_agg(to_jsonb(q) order by q.table_name,q.ordinal_position)
    from (select table_name,ordinal_position,column_name,data_type,udt_name,is_nullable,column_default
      from information_schema.columns
      where table_schema='public' and table_name in (select nombre from tablas)) q
  ),
  'restricciones',(
    select jsonb_agg(to_jsonb(q) order by q.tabla,q.nombre)
    from (select c.relname as tabla,co.conname as nombre,co.contype as tipo,
      pg_get_constraintdef(co.oid,true) as definicion
      from pg_constraint co join pg_class c on c.oid=co.conrelid
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public' and c.relname in (select nombre from tablas)) q
  ),
  'indices',(
    select jsonb_agg(to_jsonb(q) order by q.tablename,q.indexname)
    from (select tablename,indexname,indexdef from pg_indexes
      where schemaname='public' and tablename in (select nombre from tablas)) q
  ),
  'disparadores',(
    select jsonb_agg(to_jsonb(q) order by q.tabla,q.nombre)
    from (select c.relname as tabla,t.tgname as nombre,p.proname as funcion,
      pg_get_triggerdef(t.oid,true) as definicion
      from pg_trigger t join pg_class c on c.oid=t.tgrelid
      join pg_namespace n on n.oid=c.relnamespace join pg_proc p on p.oid=t.tgfoid
      where n.nspname='public' and c.relname in (select nombre from tablas) and not t.tgisinternal) q
  ),
  'rls',(
    select jsonb_agg(jsonb_build_object('tabla',c.relname,'activa',c.relrowsecurity,
      'forzada',c.relforcerowsecurity) order by c.relname)
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname in (select nombre from tablas)
  ),
  'politicas',(
    select jsonb_agg(to_jsonb(q) order by q.tablename,q.policyname)
    from (select tablename,policyname,permissive,roles,cmd,qual,with_check from pg_policies
      where schemaname='public' and tablename in (select nombre from tablas)) q
  ),
  'vistas',(
    select jsonb_agg(jsonb_build_object('nombre',viewname,'definicion',definition) order by viewname)
    from pg_views where schemaname='public' and (
      definition ilike '%anotaciones_metricas%' or definition ilike '%secuencias_metricas%'
    )
  ),
  'funciones',(
    select jsonb_agg(jsonb_build_object('nombre',proname,'argumentos',argumentos,
      'security_definer',prosecdef,'volatilidad',provolatile,
      'definicion',pg_get_functiondef(oid)) order by proname,argumentos)
    from funciones
  )
) as evidencia;
