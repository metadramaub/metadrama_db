-- Solo lectura. Referencia acotada para las propuestas del primer lote del importador.
select jsonb_build_object(
  'esquema', 'versologia-catalogo-piloto/0.1',
  'estado', (select to_jsonb(e) from public.catalogo_metrico_estado e),
  'formas', (
    select jsonb_agg(jsonb_build_object(
      'forma_id', f.forma_id, 'nombre', f.nombre, 'slug', f.slug,
      'tipo_registro', f.tipo_registro, 'definicion', f.definicion,
      'arquitecturas', coalesce((
        select jsonb_agg(jsonb_build_object(
          'arquitectura_id', a.arquitectura_id, 'nombre', a.nombre,
          'slug', a.slug, 'descripcion', a.descripcion
        ) order by a.slug)
        from public.arquitecturas_forma a where a.forma_id = f.forma_id and a.activo
      ), '[]'::jsonb)
    ) order by f.slug)
    from public.formas_metricas f
    where f.activo and (
      f.slug in ('redondilla', 'quintilla', 'terceto', 'terceto_encadenado',
        'endecasilabo_encadenado', 'endecasilabo_suelto', 'octava_real', 'romance',
        'soneto', 'villancico', 'zejel', 'romancillo', 'cancion', 'cancion_petrarquista',
        'cancion_sin_rima', 'silva', 'verso_aislado')
      or f.nombre ilike '%letrilla%'
    )
  ),
  'denominaciones_consultadas', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'nombre', d.nombre, 'forma_id', d.forma_id, 'arquitectura_id', d.arquitectura_id,
      'rasgo_id', d.rasgo_id, 'fuente_id', d.fuente_id
    ) order by d.nombre), '[]'::jsonb)
    from public.denominaciones_metricas d
    where d.nombre ilike '%letrilla%' or d.nombre ilike '%terceto%'
      or d.nombre ilike '%estancia%' or d.nombre ilike '%suelto%' or d.nombre ilike '%pareado%'
  ),
  'rasgos_consultados', (
    select jsonb_agg(jsonb_build_object('rasgo_id', r.rasgo_id, 'slug', r.slug, 'nombre', r.nombre))
    from public.rasgos_metricos r
    where r.slug in ('distico_final', 'asonancia', 'encadenamiento_interior')
  )
) as catalogo;
