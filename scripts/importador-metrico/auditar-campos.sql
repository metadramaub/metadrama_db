-- Solo lectura. Referencias existentes para proponer los campos de la métrica mínima.
with tablas as (
  select unnest(array[
    'obras','jornadas','secuencias_metricas','formas_metricas','arquitecturas_forma',
    'estructuras_secciones','metros','esquemas_rima','rasgos_metricos','rasgo_valores',
    'repeticiones_metricas','grupos_atribucion','atribuciones','atribucion_autores','editores'
  ]) as nombre
)
select jsonb_build_object(
  'fecha_consulta',current_date,
  'origen','SELECT de solo lectura; columnas y referencias observadas, sin guardados ni migraciones',
  'columnas',(
    select jsonb_agg(to_jsonb(q) order by q.table_name,q.ordinal_position)
    from (select table_name,ordinal_position,column_name,udt_name,is_nullable,column_default
      from information_schema.columns where table_schema='public'
      and table_name in (select nombre from tablas)) q
  ),
  'restricciones',(
    select jsonb_agg(jsonb_build_object('tabla',c.relname,'nombre',co.conname,
      'tipo',co.contype,'definicion',pg_get_constraintdef(co.oid,true)) order by c.relname,co.conname)
    from pg_constraint co join pg_class c on c.oid=co.conrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname in (select nombre from tablas)
  ),
  'formas_ejemplo',(
    select jsonb_agg(jsonb_build_object('forma_id',forma_id,'slug',slug,'activo',activo) order by slug)
    from public.formas_metricas where slug in ('cancion','pareado','redondilla','terceto','terceto_encadenado')
  ),
  'metros_ejemplo',(
    select jsonb_agg(jsonb_build_object('metro_id',metro_id,'slug',slug,'activo',activo) order by slug)
    from public.metros where slug in ('heptasilabo','endecasilabo','octosilabo')
  ),
  'secciones_cancion',(
    select jsonb_agg(jsonb_build_object('forma',f.slug,'arquitectura',a.slug,
      'seccion',s.nombre,'tipo_seccion',s.tipo_seccion) order by a.slug,s.orden)
    from public.formas_metricas f join public.arquitecturas_forma a using(forma_id)
    left join public.estructuras_secciones s using(arquitectura_id) where f.slug='cancion'
  )
) as evidencia;
