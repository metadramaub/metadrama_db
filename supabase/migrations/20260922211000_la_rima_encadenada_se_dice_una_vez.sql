-- La rima encadenada se dice una vez
--
-- La ficha del endecasílabo encadenado pintaba seguidas la restricción del esquema de rima y la
-- descripción del mismo esquema, que decían lo mismo. Queda la restricción, que es lo que la ficha
-- deriva, con la precisión de las sílabas; la descripción se retira.

begin;

update public.esquema_rima_restricciones rr
set descripcion = 'La rima final de cada verso se repite en el interior del siguiente, en las sílabas sexta y séptima —a veces en la cuarta y quinta—; entre finales de verso no hay rima.'
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
where rr.esquema_rima_id = er.esquema_rima_id and f.slug = 'endecasilabo_encadenado' and er.slug = 'rima-encadenada';

update public.esquemas_rima er
set descripcion = null
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where er.arquitectura_id = a.arquitectura_id and f.slug = 'endecasilabo_encadenado' and er.slug = 'rima-encadenada';

do $$
begin
	if (select count(*) from public.esquema_rima_restricciones rr
		join public.esquemas_rima er on er.esquema_rima_id = rr.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'endecasilabo_encadenado' and rr.descripcion like '%sexta y séptima%') <> 1 then
		raise exception 'La restricción del encadenado no quedó escrita.';
	end if;
	perform public.get_forma_metrica_publica_jerarquica('endecasilabo_encadenado');
end $$;

commit;
