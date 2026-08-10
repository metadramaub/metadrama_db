-- El ciclo ya no es una continuación.
--
-- Al fundir el primer ciclo con los demás quedó un solo ciclo, pero conservando el nombre que
-- tenía cuando era el segundo: «Continuación». Es lo que ve el editor y lo que sale en la ficha
-- pública, así que se corrige. Se le da el mismo nombre que en la otra arquitectura del villancico,
-- que ya lo tenía bien.

begin;

update public.estructuras_secciones s
set nombre = 'Ciclo de copla y estribillo',
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = s.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug = 'villancico'
	and s.tipo_seccion = 'ciclo_copla';

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	select count(*), string_agg(distinct s.nombre, ' / ') into v_n, v_mal
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and s.tipo_seccion = 'ciclo_copla';
	if v_n <> 2 or v_mal <> 'Ciclo de copla y estribillo' then
		raise exception '% ciclos del villancico se llaman «%»', v_n, v_mal;
	end if;

	-- Ninguna sección del villancico se queda sin nombre por el camino.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and coalesce(btrim(s.nombre), '') = '';
	if v_n <> 0 then
		raise exception '% secciones del villancico sin nombre', v_n;
	end if;

	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if v_json is null then
		raise exception 'La ficha del villancico salió vacía';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
