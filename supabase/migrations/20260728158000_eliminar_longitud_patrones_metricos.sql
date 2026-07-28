begin;

alter table public.patrones_metricos
	drop column longitud_minima,
	drop column longitud_maxima;

comment on table public.patrones_metricos is
	'Distribución de medidas dentro de una configuración. La extensión pertenece a la configuración o a una sección; en patrones posicionales, la longitud se deriva de sus posiciones.';

update public.catalogo_metrico_estado
set modelo_version = 7
where id;

commit;
