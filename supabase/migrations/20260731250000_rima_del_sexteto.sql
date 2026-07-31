begin;

-- El sexteto declara su consonancia.
--
-- Al repartirlo por medidas no se trasladó el tipo de rima, y sus tres arquitecturas
-- quedaron sin decir que la norma exige consonancia. Es lo único que su norma fija sobre la
-- rima: la disposición queda abierta porque el sexteto es la forma general y no hay
-- repertorio cerrado que registrar.

update public.arquitecturas_forma arquitectura
set tipo_rima_id = (
	select termino_id from public.vocabularios
	where categoria = 'tipo_rima' and termino = 'consonante'
)
from public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = 'sexteto'
	and arquitectura.tipo_rima_id is null;

update public.esquemas_rima rima
set tipo_rima_id = (
	select termino_id from public.vocabularios
	where categoria = 'tipo_rima' and termino = 'consonante'
)
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where arquitectura.arquitectura_id = rima.arquitectura_id
	and forma.slug = 'sexteto'
	and rima.tipo_rima_id is null;

do $$
declare
	v_sin integer;
begin
	select count(*) into v_sin
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sexteto' and arquitectura.tipo_rima_id is null;
	if v_sin > 0 then
		raise exception '% arquitecturas del sexteto siguen sin tipo de rima', v_sin;
	end if;
end;
$$;

commit;
