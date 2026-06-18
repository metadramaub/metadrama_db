-- Grupos internos del catálogo público.
-- Idempotente: no pisa valores que ya haya configurado el panel de publicación.

insert into public.secciones_publicas (seccion_id, label, descripcion, activa, scope_minimo, orden) values
  ('catalogo.filtros.basicos',             'Catálogo · Filtros básicos',             'Búsqueda, autoría, género y ordenación del catálogo.',                    true, 'anon', 210),
  ('catalogo.filtros.datacion_extension',  'Catálogo · Datación y extensión',        'Filtros de rango por datación y total de versos.',                       true, 'anon', 220),
  ('catalogo.filtros.metrica',             'Catálogo · Filtros métricos',            'Filtros por formas, metros, jornadas y rasgos métricos agregados.',       false, 'admin_ip', 230),
  ('catalogo.filtros.dramaturgia',         'Catálogo · Filtros dramatúrgicos',       'Filtros por personajes, espacio y caracterizaciones dramatúrgicas.',      false, 'admin_ip', 240),
  ('catalogo.resultados.perfil_metrico',   'Catálogo · Perfil métrico en resultados','Resumen visual métrico compacto en cada resultado del catálogo.',         false, 'admin_ip', 250),
  ('catalogo.laboratorio',                 'Catálogo · Envío al laboratorio',        'Selección de obras del catálogo para análisis comparado en laboratorio.', false, 'admin_ip', 260)
on conflict (seccion_id) do nothing;
