begin;

alter table public.patrones_metricos
	add column nombre text null
		check (nombre is null or btrim(nombre) <> '');

comment on column public.patrones_metricos.nombre is
	'Nombre editorial breve para distinguir patrones de una misma configuración. La descripción conserva la explicación extensa.';

update public.configuraciones_forma c
set slug = 'octosilabico_asonante'
from public.formas_metricas f
where c.forma_id = f.forma_id
	and f.slug = 'romance'
	and c.slug = 'principal';

update public.patrones_metricos pm
set nombre = 'Octosílabo repetido'
from public.configuraciones_forma c
join public.formas_metricas f on f.forma_id = c.forma_id
where pm.configuracion_id = c.configuracion_id
	and f.slug = 'romance'
	and c.slug = 'octosilabico_asonante';

update public.catalogo_metrico_estado
set modelo_version = 3
where id;

commit;
