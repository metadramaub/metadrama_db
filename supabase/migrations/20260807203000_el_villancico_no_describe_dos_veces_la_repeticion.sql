-- El nombre público distingue ya las tres realizaciones y `regla` explica su comportamiento.
-- `descripcion` queda disponible para los patrones en los que aporte información adicional,
-- pero en estas repeticiones del villancico solo parafraseaba ambas cosas.

begin;

update public.repeticiones_metricas r
set
	descripcion = null,
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where r.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and r.slug in ('represa_total', 'represa_parcial', 'represa_implicita');

commit;
