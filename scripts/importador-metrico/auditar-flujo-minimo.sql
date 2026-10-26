-- Solo lectura. Estados, publicación y campos de fuente para simplificar el flujo mínimo.
select jsonb_build_object(
  'fecha_consulta',current_date,
  'origen','SELECT de solo lectura; sin modificar vocabularios, atribuciones ni estados',
  'vocabularios',(
    select jsonb_agg(jsonb_build_object('categoria',categoria,'termino',termino,
      'termino_id',termino_id) order by categoria,termino)
    from public.vocabularios where categoria in (
      'estado','genero','tipo_atribucion','modalidad_atribucion','composicion_autoria'
    )
  ),
  'campos_fuente',(
    select jsonb_agg(to_jsonb(q) order by q.table_name,q.column_name)
    from (select table_name,column_name,udt_name,is_nullable
      from information_schema.columns where table_schema='public' and (
        (table_name='obras' and column_name in ('fuente_fecha','genero_id','editor_asignado'))
        or (table_name in ('atribuciones','atribucion_evidencias') and column_name='fuente_autoria')
      )) q
  ),
  'funciones',(
    select jsonb_agg(jsonb_build_object('nombre',p.proname,
      'definicion',pg_get_functiondef(p.oid)) order by p.proname)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in (
      'obras_enforce_public_visibility','obra_publica_visible','can_view_obra_ficha_publica',
      'perfil_metrico_unidades','validate_atribucion_vocab_refs',
      'validate_atribucion_evidencia_vocab_refs'
    )
  )
) as evidencia;
