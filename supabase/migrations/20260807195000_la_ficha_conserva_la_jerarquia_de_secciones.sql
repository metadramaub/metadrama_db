-- La ficha agregada conservaba las secciones, pero no su relación padre-hijo. Como `orden`
-- es local a cada padre, presentarlas como una lista plana mezclaba ciclos, coplas, mudanzas
-- y represas. La función jerárquica mantiene una sola llamada y añade los campos necesarios
-- para reconstruir el árbol en la capa de presentación.

begin;

create or replace function public.get_forma_metrica_publica_jerarquica(p_slug text)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
with
forma_objetivo as (
	select forma_id
	from public.formas_metricas
	where activo and slug = p_slug
),
arquitecturas_objetivo as (
	select arquitectura_id
	from public.arquitecturas_forma
	where activo and forma_id in (select forma_id from forma_objetivo)
)
select public.get_forma_metrica_publica(p_slug) || jsonb_build_object(
	'secciones', coalesce((
		select jsonb_agg(
			to_jsonb(x)
			order by x.arquitectura_id, x.seccion_padre_id nulls first, x.orden, x.slug
		)
		from (
			select
				s.seccion_id,
				s.arquitectura_id,
				s.seccion_padre_id,
				s.slug,
				s.tipo_seccion,
				s.nombre,
				s.nota,
				s.versos_min,
				s.versos_max,
				s.repeticiones_min,
				s.repeticiones_max,
				s.arquitectura_referenciada_id,
				s.orden
			from public.estructuras_secciones s
			where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$$;

revoke all on function public.get_forma_metrica_publica_jerarquica(text) from public;
grant execute on function public.get_forma_metrica_publica_jerarquica(text)
	to anon, authenticated, service_role;

commit;
