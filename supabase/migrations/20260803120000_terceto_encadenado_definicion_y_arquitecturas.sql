begin;

-- La forma tenía todavía una definición exclusivamente endecasilábica, aunque el catálogo
-- ya reconoce y demarca una segunda arquitectura octosilábica. La definición general debe
-- expresar lo compartido; el origen y la adaptación pertenecen a cada arquitectura.

update public.formas_metricas
set definicion = 'Serie métrica continua de versos isométricos con rima consonante, organizada en tercetos encadenados. La rima del segundo verso de cada terceto se retoma en el primero y el tercero del siguiente, de acuerdo con la sucesión ABA | BCB | CDC | … . La cadena termina en una estrofa cruzada de cuatro versos que recupera la rima pendiente. Su realización principal conserva el endecasílabo de origen italiano y el catálogo admite también una adaptación octosilábica al metro español.',
	updated_at = now()
where slug = 'terceto_encadenado';

update public.arquitecturas_forma arquitectura
set descripcion = case arquitectura.slug
		when 'endecasilabico_consonante' then
			'Realización principal de origen italiano: serie de endecasílabos consonantes enlazados de tres en tres y cerrada con un serventesio.'
		when 'octosilabico' then
			'Adaptación al metro español de la serie italiana: conserva el encadenamiento consonante, lo realiza en octosílabos y cierra con una cuarteta.'
		else arquitectura.descripcion
	end,
	updated_at = now()
from public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = 'terceto_encadenado'
	and arquitectura.slug in ('endecasilabico_consonante', 'octosilabico');

do $$
declare
	v_formas integer;
	v_arquitecturas integer;
begin
	select count(*) into v_formas
	from public.formas_metricas
	where slug = 'terceto_encadenado'
		and definicion like '%adaptación octosilábica%';

	select count(*) into v_arquitecturas
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado'
		and arquitectura.slug in ('endecasilabico_consonante', 'octosilabico')
		and arquitectura.descripcion is not null;

	if v_formas <> 1 or v_arquitecturas <> 2 then
		raise exception
			'La definición del terceto encadenado no quedó completa: % formas y % arquitecturas',
			v_formas,
			v_arquitecturas;
	end if;
end;
$$;

commit;
