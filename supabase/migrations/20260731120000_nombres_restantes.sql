begin;

-- Tres identificadores que la traducción del bloque D no alcanzó: nombraban el patrón sin
-- la palabra `id` detrás, así que ninguna de las reglas de sustitución los reconoció.

alter index public.denominaciones_metricas_patron_metrico_slug_idx
	rename to denominaciones_metricas_esquema_metrico_slug_idx;

alter index public.denominaciones_metricas_patron_rima_slug_idx
	rename to denominaciones_metricas_esquema_rima_slug_idx;

alter table public.desviaciones_editor_metrico
	rename constraint desviaciones_editor_metrico_patron_rima_observado_id_fkey
	to desviaciones_editor_metrico_esquema_rima_observado_id_fkey;

commit;
