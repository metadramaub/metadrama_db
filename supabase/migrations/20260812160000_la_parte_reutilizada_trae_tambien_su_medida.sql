-- La parte reutilizada trae también su medida.
--
-- Al dibujar la unidad verso a verso salió a la vista lo que la prosa tapaba: una parte que
-- reutiliza otra arquitectura no tiene medida propia y la proyección tampoco enviaba la de
-- aquella, así que su tramo quedaba en blanco. Pasa en el cuerpo de la seguidilla compuesta
-- —cuatro versos sin medida, cuando son los 7-5-7-5 de la seguidilla simple— y en la estrofa de
-- las tres sextinas, que son seis endecasílabos declarados en la sextina estrófica.
--
-- Se manda en claves nuevas en lugar de ampliar `esquemasMetricos`, que es lo que `main` lee
-- para el bloque «Medida»: si las de las arquitecturas reutilizadas entraran ahí, la ficha
-- desplegada listaría la medida de la redondilla dentro de la décima.

create or replace function public.get_forma_metrica_publica_jerarquica(p_slug text)
returns jsonb
language sql
stable
set search_path to 'public'
as $function$
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
),
arquitecturas_reutilizadas as (
	select distinct s.arquitectura_referenciada_id as arquitectura_id
	from public.estructuras_secciones s
	where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		and s.arquitectura_referenciada_id is not null
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
				s.primera_realizacion_define_patron,
				s.esquema_metrico_id,
				s.esquema_rima_id,
				s.orden
			from public.estructuras_secciones s
			where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb),
	-- Qué forma hay al otro lado de cada arquitectura reutilizada, para poder enlazarla.
	'formasReferenciadas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.forma_nombre)
		from (
			select distinct
				a.arquitectura_id,
				a.nombre as arquitectura_nombre,
				f.forma_id,
				f.slug as forma_slug,
				f.nombre as forma_nombre,
				f.nivel_estructural
			from public.estructuras_secciones s
			join public.arquitecturas_forma a
				on a.arquitectura_id = s.arquitectura_referenciada_id
			join public.formas_metricas f on f.forma_id = a.forma_id
			where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
				and f.activo
		) x
	), '[]'::jsonb),
	-- La medida y la rima de lo reutilizado, con sus posiciones dentro para no multiplicar
	-- claves. Solo lo que declara la unidad de aquella arquitectura: sus propias partes son
	-- asunto de su ficha.
	'arquitecturasReutilizadas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.arquitectura_id)
		from (
			select
				r.arquitectura_id,
				coalesce((
					select jsonb_agg(jsonb_build_object(
						'tipo_secuencia', em.tipo_secuencia,
						'medida_uniforme', em.medida_uniforme,
						'posiciones', coalesce((
							select jsonb_agg(jsonb_build_object(
								'posicion', p.posicion,
								'alternativa', p.alternativa,
								'opcional', p.opcional,
								'silabas', m.silabas
							) order by p.posicion, p.alternativa)
							from public.esquema_metrico_posiciones p
							left join public.metros m on m.metro_id = p.metro_id
							where p.esquema_metrico_id = em.esquema_metrico_id
						), '[]'::jsonb),
						'opciones', coalesce((
							select jsonb_agg(jsonb_build_object('silabas', m.silabas, 'rol', o.rol)
								order by o.orden nulls last)
							from public.esquema_metrico_opciones o
							left join public.metros m on m.metro_id = o.metro_id
							where o.esquema_metrico_id = em.esquema_metrico_id
						), '[]'::jsonb)
					))
					from public.esquemas_metricos em
					where em.arquitectura_id = r.arquitectura_id and em.seccion_id is null
				), '[]'::jsonb) as esquemas_metricos,
				coalesce((
					select jsonb_agg(jsonb_build_object(
						'esquema_rima_id', er.esquema_rima_id,
						'nombre', er.nombre,
						'notacion', er.notacion,
						'modalidad', er.modalidad,
						'posiciones', coalesce((
							select jsonb_agg(jsonb_build_object(
								'bloque', p.bloque,
								'posicion', p.posicion,
								'clase_rima', p.clase_rima,
								'suelto', p.suelto,
								'seccion', p.seccion
							) order by p.bloque, p.posicion)
							from public.esquema_rima_posiciones p
							where p.esquema_rima_id = er.esquema_rima_id
						), '[]'::jsonb)
					))
					from public.esquemas_rima er
					where er.arquitectura_id = r.arquitectura_id and er.seccion_id is null
				), '[]'::jsonb) as esquemas_rima
			from arquitecturas_reutilizadas r
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
				r.nombre,
				r.modalidad,
				r.descripcion,
				r.materializa_seccion_id,
				r.extension_desde_seccion_id
			from public.repeticiones_metricas r
			where r.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb),
	'restriccionesRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.esquema_rima_id, x.tipo)
		from (
			select
				x.restriccion_id,
				x.esquema_rima_id,
				x.tipo,
				x.valor_numero,
				x.valor_texto,
				x.esquema_referido_id,
				x.descripcion
			from public.esquema_rima_restricciones x
			join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
			where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$function$;

do $$
declare
	reutilizadas jsonb;
	medida jsonb;
begin
	reutilizadas := public.get_forma_metrica_publica_jerarquica('sextina') -> 'arquitecturasReutilizadas';
	if jsonb_array_length(reutilizadas) = 0 then
		raise exception 'la sextina reutiliza la sextina estrófica y no llegó ninguna arquitectura';
	end if;
	medida := reutilizadas -> 0 -> 'esquemas_metricos' -> 0 -> 'posiciones' -> 0 -> 'silabas';
	if medida is null then
		raise exception 'la arquitectura reutilizada llegó sin las sílabas de su medida';
	end if;
end;
$$;
