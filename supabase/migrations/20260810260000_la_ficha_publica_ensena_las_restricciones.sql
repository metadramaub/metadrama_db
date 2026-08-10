-- Tres funciones vuelven a funcionar, y la ficha pública enseña las restricciones.
--
-- URGENTE Y MÍO. Al retirar `repeticiones_metricas.regla` hace un rato, en esta misma sesión,
-- quedaron rotas **tres** funciones que la nombraban: `get_forma_metrica_publica`,
-- `get_forma_metrica_publica_jerarquica` y `obtener_catalogo_demarcador`. Es decir, todas las
-- fichas de `/formas` y otra vez la compilación del demarcador.
--
-- Es la cuarta vez esta semana que muerde lo mismo, y siempre igual: un cuerpo `language sql`
-- entrecomillado no se revalida al borrar una columna, así que `db push` aplicó el borrado sin
-- una queja y solo falla quien las ejecuta. La guarda de aquella migración comprobaba el dato
-- —las once repeticiones, las tres salvedades conservadas— pero **no ejecutó lo que lee ese
-- dato**, que es la lección que faltaba aprender.
--
-- Las tres pasan a leer `r.nombre`, que es lo que sustituyó a `regla` como manera de nombrar una
-- repetición.
--
-- Y DE PASO, LO QUE LA TRANSVERSAL NECESITABA: la ficha gana `restriccionesRima`. Las
-- restricciones son la norma de los esquemas abiertos —los que no tienen posiciones que
-- enseñar— y hasta ahora no se veían en ninguna parte. Sin eso no se puede podar la prosa que
-- ahora duplican, porque la norma desaparecería de la página.

begin;

CREATE OR REPLACE FUNCTION public.get_forma_metrica_publica(p_slug text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
with
forma_objetivo as (
	select *
	from public.formas_metricas
	where activo and slug = p_slug
),
arquitecturas_objetivo as (
	select a.*
	from public.arquitecturas_forma a
	join forma_objetivo f using (forma_id)
	where a.activo
),
secciones_objetivo as (
	select s.*
	from public.estructuras_secciones s
	join arquitecturas_objetivo a using (arquitectura_id)
),
grupos_objetivo as (
	select g.*
	from public.grupos_eleccion_metrica g
	join arquitecturas_objetivo a using (arquitectura_id)
	where g.activo
),
opciones_objetivo as (
	select o.*
	from public.opciones_eleccion_metrica o
	join grupos_objetivo g using (grupo_eleccion_id)
),
esquemas_rima_objetivo as (
	select distinct e.*
	from public.esquemas_rima e
	where e.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		or e.esquema_rima_id in (
			select esquema_rima_id
			from opciones_objetivo
			where esquema_rima_id is not null
		)
),
relaciones_objetivo as (
	select r.*
	from public.forma_relaciones r
	where r.forma_origen_id in (select forma_id from forma_objetivo)
		or r.forma_destino_id in (select forma_id from forma_objetivo)
),
formas_necesarias as (
	select f.*
	from public.formas_metricas f
	where f.activo and (
		f.forma_id in (select forma_id from forma_objetivo)
		or f.forma_id in (select forma_origen_id from relaciones_objetivo)
		or f.forma_id in (select forma_destino_id from relaciones_objetivo)
	)
),
arquitecturas_necesarias as (
	select a.*
	from public.arquitecturas_forma a
	where a.activo and (
		a.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		or a.arquitectura_id in (
			select arquitectura_referenciada_id
			from secciones_objetivo
			where arquitectura_referenciada_id is not null
		)
	)
),
afirmaciones_objetivo as (
	select af.*
	from public.afirmaciones_fuentes_metricas af
	where af.forma_id in (select forma_id from forma_objetivo)
		or af.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
)
select jsonb_build_object(
	'formas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select forma_id, slug, nombre, definicion, tipo_registro, nivel_estructural, orden
			from formas_necesarias
		) x
	), '[]'::jsonb),
	'arquitecturas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden nulls last, x.nombre)
		from (
			select arquitectura_id, forma_id, slug, nombre, descripcion, principal, modalidad,
				unidad_versos_min, unidad_versos_max, tipo_rima_id, orden
			from arquitecturas_necesarias
		) x
	), '[]'::jsonb),
	'esquemasMetricos', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select e.arquitectura_id, e.nombre, e.descripcion
			from public.esquemas_metricos e
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb),
	'esquemasRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select esquema_rima_id, arquitectura_id, nombre, notacion, descripcion, ambito
			from esquemas_rima_objetivo
		) x
	), '[]'::jsonb),
	'enlacesRima', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select l.esquema_rima_id, l.posicion_origen, l.posicion_destino,
				l.desplazamiento_bloque, l.nota
			from public.esquema_rima_enlaces l
			join esquemas_rima_objetivo e using (esquema_rima_id)
		) x
	), '[]'::jsonb),
	'posicionesRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.bloque, x.posicion)
		from (
			select p.esquema_rima_id, p.bloque, p.posicion, p.seccion, p.nota
			from public.esquema_rima_posiciones p
			join esquemas_rima_objetivo e using (esquema_rima_id)
			where p.seccion is not null
		) x
	), '[]'::jsonb),
	'secciones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden)
		from (
			select seccion_id, arquitectura_id, nombre, nota, versos_min, versos_max,
				repeticiones_min, repeticiones_max, arquitectura_referenciada_id, orden
			from secciones_objetivo
		) x
	), '[]'::jsonb),
	'gruposEleccion', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select grupo_eleccion_id, seccion_id, dimension
			from grupos_objetivo
		) x
	), '[]'::jsonb),
	'opcionesEleccion', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden)
		from (
			select grupo_eleccion_id, esquema_rima_id, nombre, orden
			from opciones_objetivo
		) x
	), '[]'::jsonb),
	'variedades', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden)
		from (
			select v.arquitectura_id, v.nombre, v.descripcion, v.orden
			from public.variedades_arquitectura v
			join arquitecturas_objetivo a using (arquitectura_id)
			where v.activo
		) x
	), '[]'::jsonb),
	'arquitecturaRasgos', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select ar.arquitectura_id, ar.rasgo_id, ar.valor_id, ar.modalidad, ar.nota
			from public.arquitectura_rasgos ar
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb),
	'rasgos', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select distinct r.rasgo_id, r.nombre
			from public.rasgos_metricos r
			join public.arquitectura_rasgos ar using (rasgo_id)
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb),
	'valores', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select distinct v.valor_id, v.nombre
			from public.rasgo_valores v
			join public.arquitectura_rasgos ar using (valor_id)
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb),
	'tiposRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.termino)
		from (
			select distinct v.termino_id, v.termino, v.etiqueta
			from public.vocabularios v
			join arquitecturas_objetivo a on a.tipo_rima_id = v.termino_id
			where v.categoria = 'tipo_rima'
		) x
	), '[]'::jsonb),
	'denominaciones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select d.forma_id, d.arquitectura_id, d.esquema_rima_id, d.nombre, d.preferente
			from public.denominaciones_metricas d
			where d.forma_id in (select forma_id from forma_objetivo)
				or d.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
				or d.esquema_rima_id in (select esquema_rima_id from esquemas_rima_objetivo)
		) x
	), '[]'::jsonb),
	'tradiciones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select distinct t.tradicion_id, t.nombre
			from public.tradiciones_metricas t
			join public.formas_tradiciones ft using (tradicion_id)
			join forma_objetivo f using (forma_id)
		) x
	), '[]'::jsonb),
	'formasTradiciones', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select ft.forma_id, ft.tradicion_id
			from public.formas_tradiciones ft
			join forma_objetivo f using (forma_id)
		) x
	), '[]'::jsonb),
	'afirmaciones', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza
			from afirmaciones_objetivo
		) x
	), '[]'::jsonb),
	'fuentes', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.anio)
		from (
			select distinct f.fuente_id, f.cita, f.autoria, f.titulo, f.anio
			from public.fuentes_metricas f
			join afirmaciones_objetivo a using (fuente_id)
		) x
	), '[]'::jsonb),
	'relaciones', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select forma_origen_id, forma_destino_id, tipo_relacion, nota
			from relaciones_objetivo
		) x
	), '[]'::jsonb),
	'repeticiones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.modalidad, x.nombre)
		from (
			select r.arquitectura_id, r.tipo, r.nombre, r.modalidad, r.descripcion
			from public.repeticiones_metricas r
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb)
);
$function$
;

CREATE OR REPLACE FUNCTION public.obtener_catalogo_demarcador()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
with access_check as materialized (
	select public.auth_is_admin_or_ip() as allowed
),
eligible_forms as materialized (
	select f.forma_id
	from public.formas_metricas f
	where f.activo
		and f.seleccionable
		and f.tipo_registro = 'forma'
		and (select allowed from access_check)
),
eligible_architectures as materialized (
	select a.arquitectura_id
	from public.arquitecturas_forma a
	join eligible_forms f on f.forma_id = a.forma_id
	where a.activo and a.demarcable
)
select jsonb_build_object(
	'forms', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select f.forma_id, f.slug, f.nombre, f.definicion, f.tipo_registro
			from public.formas_metricas f
			join eligible_forms e on e.forma_id = f.forma_id
			order by f.nombre
		) row_data
	),
	'architectures', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select a.arquitectura_id, a.forma_id, a.slug, a.nombre, a.descripcion,
				a.principal, a.modalidad, a.tipo_rima_id, a.unidad_versos_min, a.unidad_versos_max
			from public.arquitecturas_forma a
			join eligible_architectures e on e.arquitectura_id = a.arquitectura_id
			order by a.forma_id, a.principal desc, a.orden nulls last, a.nombre
		) row_data
	),
	'metricPatterns', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select p.esquema_metrico_id, p.arquitectura_id, p.ambito
			from public.esquemas_metricos p
			join eligible_architectures e on e.arquitectura_id = p.arquitectura_id
		) row_data
	),
	'metricPositions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select p.esquema_metrico_id, p.metro_id, p.posicion
			from public.esquema_metrico_posiciones p
			join public.esquemas_metricos m on m.esquema_metrico_id = p.esquema_metrico_id
			join eligible_architectures e on e.arquitectura_id = m.arquitectura_id
		) row_data
	),
	'metricOptions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select o.esquema_metrico_id, o.metro_id, o.orden
			from public.esquema_metrico_opciones o
			join public.esquemas_metricos m on m.esquema_metrico_id = o.esquema_metrico_id
			join eligible_architectures e on e.arquitectura_id = m.arquitectura_id
		) row_data
	),
	'metres', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select m.metro_id, m.slug, m.nombre, m.silabas
			from public.metros m where m.activo order by m.silabas, m.nombre
		) row_data
	),
	'rhymePatterns', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select r.esquema_rima_id, r.arquitectura_id, r.slug, r.nombre, r.notacion,
				r.tipo_rima_id, r.tipo_secuencia, r.ambito, r.modalidad
			from public.esquemas_rima r
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'rhymePositions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select p.esquema_rima_id, p.bloque, p.posicion, p.ubicacion, p.clase_rima, p.suelto
			from public.esquema_rima_posiciones p
			join public.esquemas_rima r on r.esquema_rima_id = p.esquema_rima_id
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'sections', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select s.seccion_id, s.arquitectura_id, s.seccion_padre_id, s.tipo_seccion,
				s.nombre, s.orden, s.repeticiones_min, s.repeticiones_max, s.versos_min, s.versos_max
			from public.estructuras_secciones s
			join eligible_architectures e on e.arquitectura_id = s.arquitectura_id
			order by s.arquitectura_id, s.orden
		) row_data
	),
	'repetitions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select r.repeticion_id, r.arquitectura_id, r.tipo, r.nombre, r.descripcion, r.modalidad, r.ambito
			from public.repeticiones_metricas r
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'traits', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select r.rasgo_id, r.slug, r.nombre, r.descripcion, r.tipo_valor,
				r.observabilidad, r.demarcable
			from public.rasgos_metricos r where r.activo and r.demarcable
			order by r.nombre
		) row_data
	),
	'traitValues', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select v.valor_id, v.rasgo_id, v.slug, v.nombre, v.descripcion, v.orden
			from public.rasgo_valores v
			join public.rasgos_metricos r on r.rasgo_id = v.rasgo_id
			where v.activo and r.activo and r.demarcable
			order by v.rasgo_id, v.orden nulls last, v.nombre
		) row_data
	),
	'architectureTraits', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select a.arquitectura_id, a.rasgo_id, a.valor_id, a.modalidad, a.nota
			from public.arquitectura_rasgos a
			join eligible_architectures e on e.arquitectura_id = a.arquitectura_id
			join public.rasgos_metricos r on r.rasgo_id = a.rasgo_id
			where r.activo and r.demarcable
		) row_data
	),
	'choiceGroups', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select g.grupo_eleccion_id, g.arquitectura_id, g.nombre, g.slug,
				g.ayuda_editor, g.dimension, g.define_norma, g.tipo_control
			from public.grupos_eleccion_metrica_resueltos g
			join eligible_architectures e on e.arquitectura_id = g.arquitectura_id
			where g.activo
		) row_data
	),
	'choiceOptions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select o.opcion_eleccion_id, o.grupo_eleccion_id, o.slug, o.nombre, o.descripcion, o.orden
			from public.opciones_eleccion_metrica o
			join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
			join eligible_architectures e on e.arquitectura_id = g.arquitectura_id
			where o.activo and g.activo
			order by o.grupo_eleccion_id, o.orden nulls last, o.nombre
		) row_data
	),
	'vocabularies', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select v.termino_id, v.termino, v.etiqueta, v.categoria
			from public.vocabularios v where v.activo
		) row_data
	)
);
$function$
;

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
				r.nombre,
				r.modalidad,
				r.descripcion
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
				x.obligatoria,
				x.descripcion
			from public.esquema_rima_restricciones x
			join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
			where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$$;

comment on function public.get_forma_metrica_publica_jerarquica(text) is
	'La ficha pública de una forma, con lo que la función base no da: sus secciones con la jerarquía, sus repeticiones y las restricciones de sus esquemas de rima. Las restricciones son la norma de los esquemas abiertos, que no tienen posiciones que enseñar.';

revoke all on function public.get_forma_metrica_publica_jerarquica(text) from public;
grant execute on function public.get_forma_metrica_publica_jerarquica(text) to authenticated, anon;

do $$
declare
	v_payload jsonb;
	v_n integer;
	v_slug text;
begin
	-- Ejecutarlas es lo único que las comprueba, y sobre **todas** las formas: lo que se rompió
	-- vivía en un bloque que solo se planifica al llamarlas.
	for v_slug in select slug from public.formas_metricas where activo order by slug loop
		v_payload := public.get_forma_metrica_publica_jerarquica(v_slug);
		if v_payload is null then
			raise exception 'La ficha pública de «%» no devuelve nada', v_slug;
		end if;
		if not (v_payload ? 'secciones' and v_payload ? 'repeticiones'
			and v_payload ? 'restriccionesRima' and v_payload ? 'esquemasRima') then
			raise exception 'A la ficha pública de «%» le faltan bloques', v_slug;
		end if;
	end loop;

	-- Y la del demarcador, que se rompió por lo mismo.
	v_payload := public.obtener_catalogo_demarcador();
	if not (v_payload ? 'repetitions' and v_payload ? 'forms') then
		raise exception 'A la proyección del demarcador le faltan bloques';
	end if;

	-- Las restricciones llegan a la ficha de su forma.
	select jsonb_array_length(
		public.get_forma_metrica_publica_jerarquica('sextilla') -> 'restriccionesRima'
	) into v_n;
	if v_n <> 2 then
		raise exception 'La sextilla lleva % restricciones a su ficha en vez de 2', v_n;
	end if;

	select jsonb_array_length(
		public.get_forma_metrica_publica_jerarquica('silva') -> 'restriccionesRima'
	) into v_n;
	if v_n <> 3 then
		raise exception 'La silva lleva % restricciones a su ficha en vez de 3', v_n;
	end if;
end;
$$;

commit;
