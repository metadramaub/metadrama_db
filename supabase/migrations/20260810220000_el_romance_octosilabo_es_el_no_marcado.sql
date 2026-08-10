-- El romance octosílabo es la realización no marcada; las otras tres reciben nombre propio.
--
-- Último caso que dejó abierto la lectura de la modalidad. Las cuatro medidas del romance eran
-- `habitual`, de modo que la columna no distinguía nada en la forma más frecuente del corpus.
--
-- Se dio por pendiente de ampliar fuentes, y era un error de método: se buscaron las
-- afirmaciones que hablan de frecuencia y se pasaron por alto las dos que deciden el caso sin
-- nombrarla.
--
--   La **definición de la forma**: «el octosílabo es su realización no marcada —cuando se dice
--   *romance* sin más, se entiende octosílabo—, y las demás medidas reciben nombre propio».
--
--   El *Diccionario* 2016, desde el otro lado: «cuando el romance se compone en versos distintos
--   del octosílabo recibe denominaciones específicas: romancillo el de versos de menos de ocho
--   sílabas y romance heroico el endecasílabo».
--
-- Que las otras tres tengan nombre propio —romancillo, endecha, romance heroico— es lo que las
-- marca, y esos nombres viven donde les toca, en `denominaciones_metricas`. Que la tradición las
-- reconozca no las hace corrientes: las hace **nombrables**, que es otra cosa. Era justo la
-- confusión que hacía inútil la columna.
--
-- LAS TRES BAJAN A `admitida`, NO A `excepcional`, y es deliberado. Del romance heroico dice
-- Jauralde que se sitúa «en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores»,
-- que es una afirmación cronológica antes que de frecuencia, y la segunda mitad del XVII cae de
-- lleno en el corpus. Marcarlo raro sería ir más allá de lo que la fuente sostiene, que es lo que
-- esta lectura ha evitado en las cinco tablas.

begin;

update public.arquitecturas_forma a
set modalidad = 'admitida', updated_at = now()
from public.formas_metricas f
where f.forma_id = a.forma_id and f.slug = 'romance' and not a.principal;

do $$
declare
	v_mal text;
	v_n integer;
begin
	select string_agg(a.slug || '=' || a.modalidad, ' ' order by a.slug) into v_mal
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'romance' and a.activo;
	if v_mal <> 'endecasilabica=admitida heptasilabica=admitida hexasilabica=admitida '
		|| 'octosilabica=habitual' then
		raise exception 'El romance quedó como: %', v_mal;
	end if;

	-- Y ya no queda ninguna forma cuyas arquitecturas digan todas lo mismo teniendo una
	-- realización general declarada: era el síntoma de que la columna no clasificaba.
	select count(*) into v_n from (
		select 1 from public.formas_metricas f
		join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.activo
		where f.activo
		group by f.forma_id
		having count(*) > 1 and count(distinct a.modalidad) = 1 and bool_or(a.modalidad = 'habitual')
	) s;
	if v_n <> 0 then
		raise exception '% formas marcan todas sus arquitecturas como habituales', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
