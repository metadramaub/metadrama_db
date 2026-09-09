-- La portada solo lee la proyección pública precomputada.
--
-- Las cifras se agregan dentro de PostgreSQL sobre obras_resumen, sin enviar al
-- servidor todas las obras ni sus fichas. La obra destacada se elige en la
-- configuración de la aplicación y aquí solo se devuelve su resumen publicado.

create or replace function public.get_portada_publica(p_obra_destacada_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
	with visibles as materialized (
		select
			r.obra_id,
			r.total_versos,
			r.formas_presentes,
			r.autores,
			r.tramos,
			r.jornadas_tramos,
			r.cuadros_tramos,
			r.ficha,
			nullif(r.ficha #>> '{obra,fecha_inicio_trad}', '')::integer as fecha_inicio_trad,
			nullif(r.ficha #>> '{obra,fecha_fin_trad}', '')::integer as fecha_fin_trad
		from public.obras_resumen r
		where r.ficha is not null
	),
	fechas as (
		select fecha
		from visibles v
		cross join lateral unnest(array[v.fecha_inicio_trad, v.fecha_fin_trad]) as valores(fecha)
		where fecha is not null
	),
	formas as (
		select count(distinct forma)::integer as total
		from visibles v
		cross join lateral unnest(coalesce(v.formas_presentes, '{}'::text[])) as valores(forma)
	),
	autores as (
		select count(distinct autor)::integer as total
		from visibles v
		cross join lateral unnest(coalesce(v.autores, '{}'::text[])) as valores(autor)
	),
	destacada as (
		select jsonb_build_object(
			'slug', v.ficha #>> '{obra,slug}',
			'titulo', v.ficha #>> '{obra,titulo}',
			'total_versos', v.total_versos,
			'tramos', coalesce(v.tramos, '[]'::jsonb),
			'jornadas_tramos', coalesce(v.jornadas_tramos, '[]'::jsonb),
			'cuadros_tramos', coalesce(v.cuadros_tramos, '[]'::jsonb)
		) as item
		from visibles v
		where v.obra_id = p_obra_destacada_id
		limit 1
	)
	select jsonb_build_object(
		'stats', jsonb_build_object(
			'obras', (select count(*)::integer from visibles),
			'autores', coalesce((select total from autores), 0),
			'versos', coalesce((select sum(total_versos)::bigint from visibles), 0),
			'formas', coalesce((select total from formas), 0),
			'datacionInicio', (select min(fecha) from fechas),
			'datacionFin', (select max(fecha) from fechas)
		),
		'featuredObra', (select item from destacada)
	);
$$;

comment on function public.get_portada_publica(uuid) is
	'Resume las obras publicadas visibles y devuelve una obra destacada desde obras_resumen.';

grant execute on function public.get_portada_publica(uuid) to anon;
grant execute on function public.get_portada_publica(uuid) to authenticated;
grant execute on function public.get_portada_publica(uuid) to service_role;
