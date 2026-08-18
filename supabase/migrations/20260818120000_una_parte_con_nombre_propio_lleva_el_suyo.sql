-- Una parte con nombre propio puede llevar el suyo
--
-- El eslabón de la estancia se llama también «chiave», y ese nombre se guardó donde le toca:
-- `denominaciones_metricas.seccion_id`. Pero la ficha no lo recogía —su consulta buscaba
-- denominaciones de forma, de arquitectura y de esquema, no de sección—, así que el dato entró
-- en el catálogo y se quedó sin salir a ninguna pantalla.
--
-- La función se reescribe **entera y sin más cambio que ese**, porque `create or replace` exige
-- el cuerpo completo. Se generó a partir de la definición viva para no transcribirla a mano.
--
-- Y una función SQL no está probada hasta que se ejecuta: al final se ejecuta sobre la canción
-- y se comprueba que «Chiave» sale por la puerta que antes no existía.

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
			select d.forma_id, d.arquitectura_id, d.esquema_rima_id, d.seccion_id,
				d.nombre, d.preferente
			from public.denominaciones_metricas d
			where d.forma_id in (select forma_id from forma_objetivo)
				or d.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
				or d.esquema_rima_id in (select esquema_rima_id from esquemas_rima_objetivo)
				-- El eslabón de la estancia también se llama «chiave», y una parte con nombre
				-- propio puede llevar el suyo igual que lo lleva una forma o una arquitectura.
				or d.seccion_id in (select seccion_id from secciones_objetivo)
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

do $$
declare
	v_payload jsonb;
	v_chiave integer;
begin
	v_payload := public.get_forma_metrica_publica_jerarquica('cancion_petrarquista');

	if v_payload is null or v_payload->'secciones' is null then
		raise exception 'La ficha de la canción no devuelve secciones.';
	end if;

	select count(*) into v_chiave
	from jsonb_array_elements(v_payload->'denominaciones') d
	where d->>'nombre' = 'Chiave' and d->>'seccion_id' is not null;

	if v_chiave <> 1 then
		raise exception 'La denominación «Chiave» sale % veces de la ficha; se esperaba 1.', v_chiave;
	end if;
end $$;

commit;
