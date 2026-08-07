-- «Represa» se conserva en los resúmenes bibliográficos que documentan ese término.
-- Las definiciones y etiquetas propias del catálogo usan «repetición del estribillo».

begin;

update public.estructuras_secciones s
set
	nombre = case
		when a.slug = 'estribillo_inicial' and s.slug = 'ciclo_copla'
			then 'Ciclo de copla y repetición del estribillo'
		else s.nombre
	end,
	nota = case
		when a.slug = 'estribillo_inicial' and s.slug = 'ciclo_copla'
			then 'Unidad repetible formada por una copla y la repetición del estribillo que la sigue.'
		when a.slug = 'estribillo_tras_primera_copla' and s.slug = 'ciclo_copla'
			then 'Serie de ciclos posteriores, cada uno formado por una copla y la repetición del estribillo que la sigue.'
		else s.nota
	end,
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico';

update public.repeticiones_metricas r
set
	regla = case r.slug
		when 'represa_total'
			then 'La repetición reproduce íntegramente la primera aparición del estribillo.'
		when 'represa_parcial'
			then 'La repetición reproduce solo una parte de la primera aparición del estribillo.'
		when 'represa_implicita'
			then 'La repetición del estribillo queda sobreentendida y no se realiza materialmente.'
		else r.regla
	end,
	descripcion = case r.slug
		when 'represa_total' then 'Repetición material completa del estribillo.'
		when 'represa_parcial' then 'Repetición material parcial del estribillo.'
		when 'represa_implicita' then 'Repetición funcional del estribillo sin versos añadidos.'
		else r.descripcion
	end,
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f using (forma_id)
where r.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico';

commit;
