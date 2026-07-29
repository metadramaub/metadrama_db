begin;

update public.configuraciones_forma configuracion
set
	nombre = case configuracion.slug
		when 'octosilabica_abba' then '8 sílabas'
		when 'heptasilabica_abba' then '7 sílabas'
		when 'hexasilabica_abba' then '6 sílabas'
	end,
	updated_at = now()
from public.formas_metricas forma
where configuracion.forma_id = forma.forma_id
	and forma.slug = 'redondilla'
	and configuracion.slug in (
		'octosilabica_abba',
		'heptasilabica_abba',
		'hexasilabica_abba'
	);

update public.catalogo_metrico_estado
set
	modelo_version = 28,
	actualizado_en = now()
where id = true;

commit;
