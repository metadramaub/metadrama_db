-- Las RPC públicas envían la estructura, no solo su nombre.
--
-- La ficha de `/formas` describía la estructura de una arquitectura en prosa porque no tenía
-- otra cosa: `get_forma_metrica_publica` enviaba de la medida únicamente `nombre` y
-- `descripcion`, y de la rima solo las posiciones que llevaban sección, sin la clase ni el
-- verso suelto. Es decir, la página no tenía ni los números ni las letras, y lo que se leía
-- como notación —«7-7-11-7-7-11…»— era el nombre que alguien escribió a mano en
-- `esquemas_metricos.nombre`. Treinta y tres arquitecturas isosilábicas decían lo mismo con
-- veintiuna redacciones distintas.
--
-- Esta migración no cambia ningún dato: amplía lo que las dos proyecciones envían para que la
-- rejilla de posiciones —`src/lib/metrica/rejilla.ts`— pueda dibujar la unidad verso a verso en
-- la ficha, en el demarcador y en el recuadro de la norma del editor V2.
--
-- Lo que se añade a `get_forma_metrica_publica`:
--   · esquemasMetricos: identificador, tipo de secuencia, medida uniforme y sección;
--   · posicionesMetricas y opcionesMetricas, con las sílabas ya resueltas;
--   · esquemasRima: modalidad y tipo de secuencia, que decidían cuál dibujar y se perdían;
--   · posicionesRimaCompletas: todas, con clase de rima y verso suelto. Es una clave nueva y no
--     un arreglo de `posicionesRima` porque `main` comparte esta base y lee la vieja;
--   · gruposEleccion: `seccion_tratada_id`, por el que el servidor ya filtraba sin recibirlo;
--   · arquitecturaRasgos: `posiciones_max` —la copla real admite hasta dos quebrados—;
--   · variedades: modalidad y los dos esquemas que emparejan;
--   · repeticiones: identificador y la sección que materializan.
--
-- Y a `obtener_catalogo_demarcador`, lo que le faltaba para no mentir: `alternativa` en las
-- posiciones métricas —sin ella la seguidilla gitana, que es 6-6-(10/11/12)-6, se pintaba con
-- doce casillas—, el `rol` de las opciones y la sección de las posiciones de rima.

create or replace function public.get_forma_metrica_publica(p_slug text)
returns jsonb
language sql
stable
set search_path to 'public'
as $function$
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
esquemas_metricos_objetivo as (
	select e.*
	from public.esquemas_metricos e
	join arquitecturas_objetivo a using (arquitectura_id)
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
			select e.esquema_metrico_id, e.arquitectura_id, e.nombre, e.descripcion,
				e.tipo_secuencia, e.medida_uniforme, e.seccion_id
			from esquemas_metricos_objetivo e
		) x
	), '[]'::jsonb),
	-- Las sílabas van resueltas: la rejilla dibuja números, no identificadores de metro.
	'posicionesMetricas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.esquema_metrico_id, x.posicion, x.alternativa)
		from (
			select p.esquema_metrico_id, p.posicion, p.alternativa, p.opcional, p.nota,
				m.silabas, m.nombre as metro
			from public.esquema_metrico_posiciones p
			join esquemas_metricos_objetivo e using (esquema_metrico_id)
			left join public.metros m on m.metro_id = p.metro_id
		) x
	), '[]'::jsonb),
	'opcionesMetricas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.esquema_metrico_id, x.orden nulls last, x.silabas)
		from (
			select o.esquema_metrico_id, o.rol, o.orden, o.nota, m.silabas, m.nombre as metro
			from public.esquema_metrico_opciones o
			join esquemas_metricos_objetivo e using (esquema_metrico_id)
			left join public.metros m on m.metro_id = o.metro_id
		) x
	), '[]'::jsonb),
	'esquemasRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select esquema_rima_id, arquitectura_id, nombre, notacion, descripcion, seccion_id,
				modalidad, tipo_secuencia
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
	-- `posicionesRima` se queda **exactamente** como estaba, con su filtro y su orden: `main`
	-- comparte esta base y lee esa clave para nombrar las partes de un esquema. Si dejara de
	-- filtrar, la versión desplegada rotularía «Null, versos 1-4» hasta el siguiente despliegue.
	'posicionesRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.bloque, x.posicion)
		from (
			select p.esquema_rima_id, p.bloque, p.posicion, p.seccion, p.nota
			from public.esquema_rima_posiciones p
			join esquemas_rima_objetivo e using (esquema_rima_id)
			where p.seccion is not null
		) x
	), '[]'::jsonb),
	-- Todas, con su clase y su verso suelto: sin ellas no hay letras que dibujar.
	'posicionesRimaCompletas', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.esquema_rima_id, x.bloque, x.posicion)
		from (
			select p.esquema_rima_id, p.bloque, p.posicion, p.seccion, p.nota,
				p.clase_rima, p.suelto, p.opcional
			from public.esquema_rima_posiciones p
			join esquemas_rima_objetivo e using (esquema_rima_id)
		) x
	), '[]'::jsonb),
	'secciones', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.orden)
		from (
			select seccion_id, arquitectura_id, nombre, nota, versos_min, versos_max,
				repeticiones_min, repeticiones_max, arquitectura_referenciada_id, orden,
				tipo_seccion, primera_realizacion_define_patron
			from secciones_objetivo
		) x
	), '[]'::jsonb),
	'gruposEleccion', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select grupo_eleccion_id, seccion_id, seccion_tratada_id, dimension, alcance
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
			select v.variedad_id, v.arquitectura_id, v.nombre, v.descripcion, v.orden,
				v.modalidad, v.esquema_metrico_id, v.esquema_rima_id
			from public.variedades_arquitectura v
			join arquitecturas_objetivo a using (arquitectura_id)
			where v.activo
		) x
	), '[]'::jsonb),
	'arquitecturaRasgos', coalesce((
		select jsonb_agg(to_jsonb(x))
		from (
			select ar.arquitectura_id, ar.rasgo_id, ar.valor_id, ar.modalidad, ar.nota,
				ar.posiciones_max
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
			select r.repeticion_id, r.arquitectura_id, r.tipo, r.nombre, r.modalidad,
				r.descripcion, r.materializa_seccion_id
			from public.repeticiones_metricas r
			join arquitecturas_objetivo a using (arquitectura_id)
		) x
	), '[]'::jsonb)
);
$function$;

-- La jerárquica solo reemplaza tres bloques; el resto lo hereda de la anterior. `secciones` gana
-- aquí `primera_realizacion_define_patron`, que es lo que distingue la canción de una estrofa
-- que se repite sin más, y `repeticiones` mantiene la sección que materializa.
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

create or replace function public.obtener_catalogo_demarcador()
returns jsonb
language sql
stable security definer
set search_path to 'public', 'pg_temp'
as $function$
with access_check as materialized (
	select public.auth_is_admin_or_ip() as allowed
),
eligible_forms as materialized (
	select f.forma_id
	from public.formas_metricas f
	where f.activo
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
			select p.esquema_metrico_id, p.arquitectura_id, p.seccion_id,
				p.tipo_secuencia, p.medida_uniforme
			from public.esquemas_metricos p
			join eligible_architectures e on e.arquitectura_id = p.arquitectura_id
		) row_data
	),
	'metricPositions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select p.esquema_metrico_id, p.metro_id, p.posicion, p.alternativa, p.opcional
			from public.esquema_metrico_posiciones p
			join public.esquemas_metricos m on m.esquema_metrico_id = p.esquema_metrico_id
			join eligible_architectures e on e.arquitectura_id = m.arquitectura_id
		) row_data
	),
	'metricOptions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select o.esquema_metrico_id, o.metro_id, o.orden, o.rol
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
				r.tipo_rima_id, r.tipo_secuencia, r.seccion_id, r.modalidad
			from public.esquemas_rima r
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'rhymePositions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select p.esquema_rima_id, p.bloque, p.posicion, p.ubicacion, p.clase_rima,
				p.suelto, p.seccion, p.opcional
			from public.esquema_rima_posiciones p
			join public.esquemas_rima r on r.esquema_rima_id = p.esquema_rima_id
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'rhymeLinks', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select l.esquema_rima_id, l.posicion_origen, l.posicion_destino,
				l.desplazamiento_bloque, l.nota
			from public.esquema_rima_enlaces l
			join public.esquemas_rima r on r.esquema_rima_id = l.esquema_rima_id
			join eligible_architectures e on e.arquitectura_id = r.arquitectura_id
		) row_data
	),
	'sections', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select s.seccion_id, s.arquitectura_id, s.seccion_padre_id, s.tipo_seccion,
				s.nombre, s.orden, s.repeticiones_min, s.repeticiones_max, s.versos_min,
				s.versos_max, s.arquitectura_referenciada_id
			from public.estructuras_secciones s
			join eligible_architectures e on e.arquitectura_id = s.arquitectura_id
			order by s.arquitectura_id, s.orden
		) row_data
	),
	'repetitions', (
		select coalesce(jsonb_agg(to_jsonb(row_data)), '[]'::jsonb)
		from (
			select r.repeticion_id, r.arquitectura_id, r.tipo, r.nombre, r.descripcion, r.modalidad
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
			select a.arquitectura_id, a.rasgo_id, a.valor_id, a.modalidad, a.nota, a.posiciones_max
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
$function$;

-- La guarda ejecuta lo que toca. Un cuerpo entrecomillado no se revalida al cambiar una
-- columna, y comprobar que la columna existe no comprueba que la función siga compilando.
do $$
declare
	payload jsonb;
	demarcador jsonb;
begin
	payload := public.get_forma_metrica_publica_jerarquica('soneto');
	if jsonb_array_length(payload -> 'posicionesMetricas') = 0 then
		raise exception 'get_forma_metrica_publica no envía posiciones métricas';
	end if;
	if jsonb_array_length(payload -> 'posicionesRimaCompletas') < 14 then
		raise exception 'get_forma_metrica_publica envía % posiciones de rima del soneto, se esperaban al menos 14',
			jsonb_array_length(payload -> 'posicionesRimaCompletas');
	end if;
	if not (payload -> 'posicionesRimaCompletas' -> 0 ? 'clase_rima') then
		raise exception 'las posiciones de rima llegan sin clase de rima';
	end if;
	if not (payload -> 'esquemasRima' -> 0 ? 'modalidad') then
		raise exception 'los esquemas de rima llegan sin modalidad';
	end if;
	if not (payload -> 'secciones' -> 0 ? 'primera_realizacion_define_patron') then
		raise exception 'las secciones llegan sin primera_realizacion_define_patron';
	end if;

	-- El demarcador se compila con permisos de admin; aquí basta con que la función corra y
	-- devuelva las columnas nuevas cuando haya datos que devolver.
	demarcador := public.obtener_catalogo_demarcador();
	if demarcador is null then
		raise exception 'obtener_catalogo_demarcador no devolvió nada';
	end if;
	if jsonb_array_length(demarcador -> 'metricPositions') > 0
		and not (demarcador -> 'metricPositions' -> 0 ? 'alternativa') then
		raise exception 'las posiciones métricas del demarcador llegan sin alternativa';
	end if;
end;
$$;
