-- Un verso solo no rima con nadie
--
-- El verso aislado heredó las dos preguntas del tramo irregular, y una de ellas no tiene sentido
-- ahí: **un solo verso no rima con nada**. Si rimara con el verso anterior o con el siguiente, no
-- sería un verso aislado: formaría parte de esa otra forma, y es ahí donde hay que anotarlo.
--
-- Le queda la medida, que es lo único observable de un verso solo.

begin;

delete from public.grupos_eleccion_metrica g
using public.arquitecturas_forma a, public.formas_metricas f
where g.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id
	and f.slug = 'verso_aislado'
	and g.dimension = 'rima';

do $comprobacion$
declare
	v_aislado integer;
	v_irregular integer;
	v_rima integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_aislado
	from public.preguntas_metricas g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'verso_aislado' and g.activo;

	if v_aislado <> 1 then
		raise exception 'El verso aislado ofrece % preguntas, y es una: la medida.', v_aislado;
	end if;

	-- Y la que le queda es la medida, no otra cosa.
	select count(*) into v_rima
	from public.preguntas_metricas g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'verso_aislado' and g.activo and g.dimension = 'metro';

	if v_rima <> 1 then
		raise exception 'Al verso aislado no le queda su pregunta de medida.';
	end if;

	-- La versificación irregular conserva las suyas: seis, dos por arte.
	select count(*) into v_irregular
	from public.preguntas_metricas g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'irregular' and g.activo;

	if v_irregular <> 6 then
		raise exception 'La versificación irregular ofrece % preguntas, y son 6.', v_irregular;
	end if;

	raise notice 'El verso aislado pregunta solo su medida; la irregular conserva sus 6 preguntas.';
end
$comprobacion$;

commit;
