-- Las vocales de la asonancia van en orden
--
-- Los veinte valores del rasgo no tenían `orden`, así que la derivación los numeraba como venían y
-- el editor los leía revueltos: la octava aguda ofrecía «o · i · a · u · e» y la seguidilla las
-- veinte sin ningún criterio. Una lista de vocales que no empieza por la `a` cuesta de leer.
--
-- Van **por la vocal tónica y luego por la final**, que es como se nombran y como se aprenden:
-- `a`, `a-a`, `a-e`, `a-o`, `e`, `e-a`… La aguda de cada vocal encabeza su grupo, porque es la misma
-- vocal sin final que la siga.

begin;

update public.rasgo_valores rv
set orden = puesto.orden
from (
	select v.valor_id, row_number() over (order by v.nombre) as orden
	from public.rasgo_valores v
	join public.rasgos_metricos r on r.rasgo_id = v.rasgo_id
	where r.slug = 'vocales_asonancia'
) puesto
where puesto.valor_id = rv.valor_id
	and rv.orden is distinct from puesto.orden;

do $comprobacion$
declare
	v_primera text;
	v_orden text;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee la derivación**, no la tabla: lo que importa es el orden en que llegan las opciones
	-- al editor, y eso lo decide la función.
	select string_agg(o.nombre, ' ' order by o.orden)
	into v_orden
	from public.opciones_eleccion_metrica o
	join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.slug = 'vocales_asonancia' and f.slug = 'octava_aguda' and a.slug = 'octosilabica';

	if v_orden is distinct from 'a e i o u' then
		raise exception 'La octava aguda ofrece las vocales como «%», y deben ir «a e i o u».', v_orden;
	end if;

	-- Y en una que las tiene todas, la primera es la `a`.
	select o.nombre into v_primera
	from public.opciones_eleccion_metrica o
	join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.slug = 'vocales_asonancia' and f.slug = 'seguidilla'
	order by o.orden
	limit 1;

	if v_primera is distinct from 'a' then
		raise exception 'La seguidilla empieza su lista por «%» y no por la «a».', v_primera;
	end if;

	raise notice 'Las vocales llegan en orden: la octava aguda ofrece «%».', v_orden;
end
$comprobacion$;

commit;
