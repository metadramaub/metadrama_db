begin;

-- El sexteto alejandrino se quedó sin posiciones.
--
-- Al repartir el sexteto por medidas, las posiciones se generaron filtrando por metro
-- simple. El alejandrino es compuesto —dos heptasílabos con cesura—, así que su esquema
-- quedó declarado como secuencia fija y vacío.

insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
select esquema.esquema_metrico_id, posicion.n, metro.metro_id, 1
from public.esquemas_metricos esquema
join public.arquitecturas_forma arquitectura
	on arquitectura.arquitectura_id = esquema.arquitectura_id
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
cross join generate_series(1, 6) as posicion(n)
join public.metros metro on metro.silabas = 14
where forma.slug = 'sexteto'
	and arquitectura.slug = 'alejandrina'
	and not exists (
		select 1 from public.esquema_metrico_posiciones existente
		where existente.esquema_metrico_id = esquema.esquema_metrico_id
	);

do $$
declare
	v_total integer;
begin
	select count(*) into v_total
	from public.esquema_metrico_posiciones posicion
	join public.esquemas_metricos esquema on esquema.esquema_metrico_id = posicion.esquema_metrico_id
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sexteto' and arquitectura.slug = 'alejandrina';
	if v_total <> 6 then
		raise exception 'El sexteto alejandrino debe tener seis posiciones y tiene %', v_total;
	end if;
end;
$$;

commit;
