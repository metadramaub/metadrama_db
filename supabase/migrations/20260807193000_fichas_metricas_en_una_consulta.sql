-- El índice y la ficha pública descargaban el catálogo entero mediante veinte peticiones
-- simultáneas. Además de lento y frágil, eso hacía que la ficha omitiera entidades que no
-- estaban en aquel cargador, como las reglas de repetición del villancico.
--
-- Estas dos funciones devuelven datos crudos agrupados, no contenido redactado: la
-- transformación de presentación sigue en TypeScript. El índice conserva todas las formas
-- para que la interfaz pueda filtrarlas en runtime; la ficha limita cada tabla a la forma,
-- sus arquitecturas y las dependencias que realmente necesita.

begin;

create or replace function public.get_catalogo_formas_publicas()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
	select jsonb_build_object(
		'formas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select forma_id, slug, nombre, definicion, tipo_registro, nivel_estructural, orden
				from public.formas_metricas
				where activo
			) x
		), '[]'::jsonb),
		'arquitecturas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.orden nulls last, x.nombre)
			from (
				select arquitectura_id, forma_id, tipo_rima_id, orden, nombre
				from public.arquitecturas_forma
				where activo
			) x
		), '[]'::jsonb),
		'tiposRima', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.termino)
			from (
				select termino_id, termino, etiqueta
				from public.vocabularios
				where categoria = 'tipo_rima'
			) x
		), '[]'::jsonb),
		'denominaciones', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select forma_id, arquitectura_id, esquema_rima_id, nombre, preferente
				from public.denominaciones_metricas
				where forma_id is not null
			) x
		), '[]'::jsonb),
		'tradiciones', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select tradicion_id, nombre
				from public.tradiciones_metricas
			) x
		), '[]'::jsonb),
		'formasTradiciones', coalesce((
			select jsonb_agg(to_jsonb(x))
			from (
				select forma_id, tradicion_id
				from public.formas_tradiciones
			) x
		), '[]'::jsonb)
	);
$$;

create or replace function public.get_forma_metrica_publica(p_slug text)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
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
		select jsonb_agg(to_jsonb(x) order by x.modalidad, x.regla)
		from (
			select r.arquitectura_id, r.tipo, r.regla, r.modalidad, r.descripcion
			from public.repeticiones_metricas r
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb)
);
$$;

revoke all on function public.get_catalogo_formas_publicas() from public;
revoke all on function public.get_forma_metrica_publica(text) from public;
grant execute on function public.get_catalogo_formas_publicas() to anon, authenticated, service_role;
grant execute on function public.get_forma_metrica_publica(text) to anon, authenticated, service_role;

commit;
