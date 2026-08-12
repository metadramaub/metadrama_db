-- La caja de la letra no es cosmética: distingue arte menor y arte mayor.
-- La ayuda vive en el catálogo y el editor conserva exactamente la notación introducida.
update public.grupos_eleccion_metrica
set
	ayuda_editor = 'Escribe una letra por verso: minúscula para arte menor y mayúscula para arte mayor. La misma disposición debe mantenerse en todas las estancias.',
	updated_at = now()
where slug = 'esquema_rima_estancia'
	and arquitectura_id = (
		select arquitectura_id
		from public.arquitecturas_forma
		where slug = 'estancias_consonantes_variables'
	);
