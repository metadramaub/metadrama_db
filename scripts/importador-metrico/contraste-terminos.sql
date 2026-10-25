-- Solo lectura. Afirmaciones del catálogo: no sustituyen la lectura directa de los libros.
select a.afirmacion_id, a.localizador, a.resumen,
  f.anio, f.cita, f.url, fo.slug as forma
from public.afirmaciones_fuentes_metricas a
join public.fuentes_metricas f using (fuente_id)
left join public.formas_metricas fo on fo.forma_id = a.forma_id
where fo.slug in ('terceto', 'terceto_encadenado', 'cancion', 'cancion_sin_rima',
  'cancion_petrarquista', 'villancico', 'zejel')
  or a.resumen ilike '%letrilla%'
order by fo.slug, f.anio;
