begin;

-- `compuesta_por` expresa ya de forma precisa la relación estructural entre
-- copla real y quintilla. Se elimina la relación genérica anterior para evitar
-- dos aristas equivalentes en el catálogo y sus grafos.
delete from public.forma_relaciones relacion
using public.formas_metricas origen, public.formas_metricas destino
where relacion.forma_origen_id = origen.forma_id
	and relacion.forma_destino_id = destino.forma_id
	and origen.slug = 'copla_real'
	and destino.slug = 'quintilla'
	and relacion.tipo_relacion = 'relacionada_con';

update public.catalogo_metrico_estado
set modelo_version = 24,
	actualizado_en = now()
where id = true;

commit;
