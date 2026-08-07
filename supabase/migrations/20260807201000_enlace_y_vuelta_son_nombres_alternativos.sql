-- En el modelo del villancico, «enlace» y «vuelta» son denominaciones alternativas
-- de una misma sección, no dos partes sucesivas.

begin;

update public.estructuras_secciones s
set
	nombre = 'Enlace o vuelta',
	nota = 'Parte final de la copla que enlaza la mudanza con el estribillo.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and s.slug in ('enlace_vuelta', 'enlace_vuelta_inicial');

update public.estructuras_secciones s
set
	nota = 'Unidad formada por una mudanza y, cuando se realiza, por el enlace o vuelta.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and s.slug = 'copla';

update public.estructuras_secciones s
set
	nota = 'Parte de la copla anterior al enlace o vuelta, normalmente organizada en dos miembros simétricos.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and s.slug in ('mudanza', 'mudanza_inicial');

commit;
