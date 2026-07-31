begin;

-- Las tradiciones se pueblan desde la clasificación previa del proyecto.
--
-- `vocabularios.tipo_forma` guarda, para cada término del vocabulario métrico heredado, si
-- la forma es española o italiana. Es la clasificación que el proyecto ya había hecho y,
-- según la decisión registrada en la ontología, autoridad suficiente para asignar la
-- pertenencia: la tradición es un ámbito histórico de procedencia, no una herencia
-- estructural, así que no transmite rasgos ni organiza el selector.
--
-- Cada forma del catálogo conserva en `origen_termino_id` el término del que procede.
-- Cuando ese término es un hijo dentro de la jerarquía heredada —la décima espinela cuelga
-- de `decima`— el tipo se toma del padre, que es donde la clasificación lo declaraba.
--
-- Cuatro formas quedan sin tradición, y es lo correcto:
--
-- - `irregular` y `verso_aislado` son tramos sin forma: no proceden de ninguna tradición.
-- - `pareado` y `tercetos_sin_encadenar` se crearon en el catálogo nuevo y no tienen
--   término de origen, así que no hay clasificación previa que trasladar. Asignarles una
--   tradición sería inventarla.
--
-- Las dos pertenencias ya registradas a mano —con su nota sobre Dante y Petrarca— se
-- conservan: la inserción no pisa lo que ya existe.

insert into public.formas_tradiciones (forma_id, tradicion_id)
select
	forma.forma_id,
	tradicion.tradicion_id
from public.formas_metricas forma
join public.vocabularios termino
	on termino.termino_id = forma.origen_termino_id
left join public.vocabularios termino_padre
	on termino_padre.termino_id = termino.termino_padre_id
join public.tradiciones_metricas tradicion
	on tradicion.slug = case coalesce(termino.tipo_forma, termino_padre.tipo_forma)
		when 'forma_espanola' then 'espanola'
		when 'forma_italiana' then 'italiana'
	end
where forma.tipo_registro = 'forma'
on conflict (forma_id, tradicion_id) do nothing;

do $$
declare
	v_sin_tradicion text;
	v_total integer;
begin
	-- Ninguna forma con clasificación previa puede quedarse sin pertenencia.
	select string_agg(forma.slug, ', ' order by forma.slug)
	into v_sin_tradicion
	from public.formas_metricas forma
	join public.vocabularios termino
		on termino.termino_id = forma.origen_termino_id
	left join public.vocabularios termino_padre
		on termino_padre.termino_id = termino.termino_padre_id
	where forma.tipo_registro = 'forma'
		and coalesce(termino.tipo_forma, termino_padre.tipo_forma) is not null
		and not exists (
			select 1
			from public.formas_tradiciones pertenencia
			where pertenencia.forma_id = forma.forma_id
		);

	if v_sin_tradicion is not null then
		raise exception 'Formas con clasificación previa y sin tradición: %', v_sin_tradicion;
	end if;

	select count(distinct forma_id) into v_total from public.formas_tradiciones;
	if v_total <> 28 then
		raise exception 'Se esperaban 28 formas con tradición y hay %', v_total;
	end if;
end;
$$;

commit;
