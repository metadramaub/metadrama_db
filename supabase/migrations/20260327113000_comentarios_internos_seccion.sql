alter table public.comentarios_internos
add column seccion text;

update public.comentarios_internos
set seccion = 'revision'
where seccion is null
  and secuencia_id is null
  and jornada_id is null
  and cuadro_id is null
  and rango_id is null;

alter table public.comentarios_internos
add constraint comentarios_internos_seccion_chk
check (
  seccion is null
  or seccion = any (array['datos', 'estructura', 'secuencias', 'autoria', 'observaciones', 'revision'])
);
