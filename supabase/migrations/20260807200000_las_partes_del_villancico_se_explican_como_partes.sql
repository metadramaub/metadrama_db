-- Las notas de sección definen función y posición. Las cantidades, repeticiones y rimas
-- se leen de sus campos estructurados y no se duplican en prosa.
--
-- Los nodos que agrupan ciclos son necesarios para expresar la secuencia computable,
-- pero sus nombres deben presentarlos como fases estructurales, no como partes métricas
-- tradicionales. La distinción interna entre enlace y vuelta queda pendiente de la revisión
-- conjunta de casos abiertos; aquí se evita tratarlos como alternativas terminológicas.

begin;

with secciones_villancico as (
	select s.seccion_id, a.slug as arquitectura_slug, s.slug as seccion_slug
	from public.estructuras_secciones s
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'villancico'
)
update public.estructuras_secciones s
set
	nombre = case
		when v.arquitectura_slug = 'estribillo_inicial' and v.seccion_slug = 'cabeza'
			then 'Cabeza'
		when v.arquitectura_slug = 'estribillo_inicial' and v.seccion_slug = 'ciclo_copla'
			then 'Ciclo de copla y represa'
		when v.arquitectura_slug = 'estribillo_tras_primera_copla' and v.seccion_slug = 'primer_ciclo'
			then 'Secuencia inicial'
		when v.arquitectura_slug = 'estribillo_tras_primera_copla' and v.seccion_slug = 'ciclo_copla'
			then 'Continuación'
		when v.seccion_slug in ('enlace_vuelta', 'enlace_vuelta_inicial')
			then 'Enlace y vuelta'
		else s.nombre
	end,
	nota = case
		when v.arquitectura_slug = 'estribillo_inicial' and v.seccion_slug = 'cabeza'
			then 'Primera aparición del estribillo cuando ocupa la posición inicial de la composición.'
		when v.arquitectura_slug = 'estribillo_inicial' and v.seccion_slug = 'ciclo_copla'
			then 'Unidad repetible formada por una copla y la represa que la sigue.'
		when v.arquitectura_slug = 'estribillo_tras_primera_copla' and v.seccion_slug = 'primer_ciclo'
			then 'Fase inicial formada por una copla seguida de la primera aparición del estribillo.'
		when v.arquitectura_slug = 'estribillo_tras_primera_copla' and v.seccion_slug = 'ciclo_copla'
			then 'Serie de ciclos posteriores, cada uno formado por una copla y la represa que la sigue.'
		when v.seccion_slug = 'copla_inicial'
			then 'Copla que abre la composición y precede a la primera aparición del estribillo.'
		when v.seccion_slug = 'copla'
			then 'Unidad formada por una mudanza y, cuando se realizan, por el enlace y la vuelta.'
		when v.seccion_slug in ('mudanza', 'mudanza_inicial')
			then 'Parte de la copla anterior al enlace y la vuelta, normalmente organizada en dos miembros simétricos.'
		when v.seccion_slug in ('enlace_vuelta', 'enlace_vuelta_inicial')
			then 'Tramo final de la copla que enlaza con la mudanza y recupera la rima del estribillo.'
		when v.seccion_slug = 'estribillo'
			then 'Primera aparición del estribillo, situada después de la copla inicial.'
		when v.seccion_slug = 'represa'
			then 'Reaparición del estribillo después de una copla.'
		else s.nota
	end,
	updated_at = now()
from secciones_villancico v
where s.seccion_id = v.seccion_id;

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
	), '[]'::jsonb),
	'repeticiones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.arquitectura_id, x.slug)
		from (
			select
				r.repeticion_id,
				r.arquitectura_id,
				r.slug,
				r.tipo,
				r.regla,
				r.modalidad,
				r.descripcion
			from public.repeticiones_metricas r
			where r.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$$;

revoke all on function public.get_forma_metrica_publica_jerarquica(text) from public;
grant execute on function public.get_forma_metrica_publica_jerarquica(text)
	to anon, authenticated, service_role;

commit;
