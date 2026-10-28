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

-- Consulta complementaria del 28-10-2026 para la edición de datos mínimos.
-- En la referencia local se conservan solo los contextos de las formas del piloto.
select r.slug,r.nombre,
  (select jsonb_agg(jsonb_build_object('slug',v.slug,'nombre',v.nombre) order by v.orden)
   from public.rasgo_valores v where v.rasgo_id=r.rasgo_id and v.activo) valores,
  jsonb_agg(distinct jsonb_build_object('forma',f.slug,'arquitectura',a.slug,'valor_slug',v.slug)) contextos
from public.rasgos_metricos r
join public.arquitectura_rasgos ar using(rasgo_id)
join public.arquitecturas_forma a using(arquitectura_id)
join public.formas_metricas f using(forma_id)
left join public.rasgo_valores v on v.valor_id=ar.valor_id
where r.activo and a.activo and f.activo and r.tipo_valor='catalogo'
group by r.rasgo_id order by r.slug;

select slug,nombre from public.metros where activo order by silabas,nombre;
