-- La ficha distingue lo que la arquitectura declara de lo que se pregunta al anotar.
--
-- `arquitectura_rasgos` guarda juntas tres cosas que no se leen igual, y la ficha las pintaba en
-- una sola lista llamada «Rasgos que admite»:
--
--   1. **Lo que la arquitectura afirma** y nadie pregunta: la densidad total del sexteto, el pie
--      quebrado de la sextilla. Son norma, y salían como si fueran opcionales.
--   2. **Lo que se pregunta y es excluyente**: la silva libre declara densidad `Total` y
--      `Mayoritaria`, y su grupo admite una sola respuesta. Salían como dos líneas seguidas, que
--      es exactamente lo contrario de lo que significan.
--   3. **Lo que se pregunta y es un sí o un no**: el final acentual esdrújulo, un grupo de una
--      opción que se puede dejar vacía.
--
-- Lo que las separa es el grupo de elección: si el rasgo tiene uno, con cuántas opciones y
-- cuántas respuestas admite. La proyección no enviaba nada de eso —`gruposEleccion` iba sin
-- `rasgo_id` ni `selecciones_*`, y `opcionesEleccion` sin `valor_rasgo_id` ni `variedad_id`—, así
-- que la ficha no podía distinguirlas aunque quisiera.
--
-- Las dos claves se redefinen aquí, en la jerárquica, en lugar de reescribir entera la función
-- que las produce. Solo añaden columnas: lo que `main` lee de ellas sigue estando.

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
),
grupos_objetivo as (
	select g.*
	from public.grupos_eleccion_metrica g
	where g.activo and g.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
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
	-- Con qué se pregunta cada cosa: el rasgo al que apunta y cuántas respuestas admite.
	'gruposEleccion', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden nulls last, x.slug)
		from (
			select
				g.grupo_eleccion_id,
				g.arquitectura_id,
				g.slug,
				g.dimension,
				g.alcance,
				g.seccion_id,
				g.seccion_tratada_id,
				g.rasgo_id,
				g.selecciones_min,
				g.selecciones_max,
				g.define_norma,
				g.orden
			from grupos_objetivo g
		) x
	), '[]'::jsonb),
	'opcionesEleccion', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden nulls last, x.nombre)
		from (
			select
				o.grupo_eleccion_id,
				o.nombre,
				o.descripcion,
				o.orden,
				o.esquema_rima_id,
				o.esquema_metrico_id,
				o.metro_id,
				o.valor_rasgo_id,
				o.variedad_id,
				o.seccion_id,
				o.repeticion_id
			from public.opciones_eleccion_metrica o
			join grupos_objetivo g using (grupo_eleccion_id)
			where o.activo
		) x
	), '[]'::jsonb),
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
	silva jsonb;
	grupos_con_rasgo integer;
	opciones_con_valor integer;
begin
	silva := public.get_forma_metrica_publica_jerarquica('silva');

	select count(*) into grupos_con_rasgo
	from jsonb_array_elements(silva -> 'gruposEleccion') g
	where g ->> 'rasgo_id' is not null;
	if grupos_con_rasgo = 0 then
		raise exception 'la silva pregunta por rasgos y ningún grupo llegó con su rasgo_id';
	end if;

	select count(*) into opciones_con_valor
	from jsonb_array_elements(silva -> 'opcionesEleccion') o
	where o ->> 'valor_rasgo_id' is not null;
	if opciones_con_valor = 0 then
		raise exception 'las opciones de rasgo llegaron sin el valor al que apuntan';
	end if;

	-- Las siete variedades del sexteto-lira son la única dimensión `combinacion` del catálogo:
	-- si dejan de llegar con su variedad, la ficha vuelve a partir en dos lo que es un par.
	if not exists (
		select 1
		from jsonb_array_elements(
			public.get_forma_metrica_publica_jerarquica('sexteto_lira') -> 'opcionesEleccion'
		) o
		where o ->> 'variedad_id' is not null
	) then
		raise exception 'las opciones del sexteto-lira llegaron sin su variedad';
	end if;
end;
$$;
