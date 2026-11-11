-- Conserva la datación literal y la procedencia de la carga del CSV.
update public.obras_dataciones
set fuente = regexp_replace(fuente, E'\\nFuente: https?://(www\\.)?etso\\.es/[^[:space:]]+$', '', 'i')
where clase = 'referencia'
  and fuente like 'CSV control de corpus 9c9d2dc07837, fila %'
  and fuente ~* E'\\nFuente: https?://(www\\.)?etso\\.es/[^[:space:]]+$';
