begin;

update public.patrones_metricos patron
set
	longitud_minima = null,
	longitud_maxima = null
from public.configuraciones_forma configuracion
join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
where patron.configuracion_id = configuracion.configuracion_id
	and forma.slug = 'quintilla'
	and configuracion.slug = 'octosilabica_consonante'
	and patron.tipo = 'secuencia_fija';

update public.catalogo_metrico_estado
set modelo_version = 6
where id;

commit;
