-- La ficha de un tramo no enseña arquitecturas
--
-- Al darles arquitecturas a la versificación irregular y al verso aislado, su ficha pública pasó a
-- pintarlas: tres tarjetas que dicen «Extensión · Abierto», «Rima · Fijo» y «El catálogo no declara
-- el régimen de rima» de unas arquitecturas que **no declaran nada a propósito**. Existen para que
-- las preguntas del editor tengan de dónde colgar, y la ficha las lee como si describieran una
-- norma.
--
-- El listado del catálogo ya las dejaba fuera —`get_catalogo_formas_publicas` no devuelve
-- ninguna—, así que lo que se arregla aquí es la incoherencia entre el listado y la ficha.

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
		-- **Un tramo sin forma no enseña las suyas.** Existen para colgar de ellas las preguntas
		-- del editor, no para describir una norma, y esta ficha las lee como si la describieran:
		-- las pintaba diciendo «Rima · Fijo» de algo que no fija nada.
		select a.*
		from public.arquitecturas_forma a
		join forma_objetivo f using (forma_id)
		where a.activo and f.tipo_registro = 'forma'
	),
	secciones_objetivo as (
		select s.*
		from public.estructuras_secciones s
		join arquitecturas_objetivo a using (arquitectura_id)
	),
	grupos_objetivo as (
		select g.*
		from public.preguntas_metricas g
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
			-- Una afirmación puede hablar de un rasgo y no de una forma: el pie quebrado lo
			-- documentan seis monografías sin que ninguna sea de la sextilla ni de la novena.
			-- Se trae si alguna arquitectura de esta forma declara ese rasgo.
			or af.rasgo_id in (
				select ar.rasgo_id from public.arquitectura_rasgos ar
				where ar.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
			)
	)
	select jsonb_build_object(
		'formas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select x0.forma_id, x0.slug, x0.nombre, x0.definicion, x0.tipo_registro,
					x0.nivel_estructural,
					-- La extensión de la unidad, tomada de la arquitectura **principal**, que es la
					-- realización canónica de la forma: la décima son diez versos aunque su aumentada
					-- mida doce. Nula donde no hay unidad —las series y las composiciones de extensión
					-- variable—, y eso no es un hueco: una serie no tiene número de versos.
					(
						select a.unidad_versos_min
						from public.arquitecturas_forma a
						where a.forma_id = x0.forma_id and a.activo
						order by a.principal desc, a.orden nulls last, a.nombre
						limit 1
					) as unidad_versos
				from formas_necesarias x0
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
					coalesce(m.composicion, m.silabas::text) as silabas, m.nombre as metro
				from public.esquema_metrico_posiciones p
				join esquemas_metricos_objetivo e using (esquema_metrico_id)
				left join public.metros m on m.metro_id = p.metro_id
			) x
		), '[]'::jsonb),
		'opcionesMetricas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.esquema_metrico_id, x.orden nulls last, x.silabas)
			from (
				select o.esquema_metrico_id, o.rol, o.orden, o.nota,
					coalesce(m.composicion, m.silabas::text) as silabas, m.nombre as metro
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
				select distinct r.rasgo_id, r.nombre, r.slug
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
				select d.forma_id, d.arquitectura_id, d.esquema_rima_id, d.seccion_id, d.rasgo_id,
					d.nombre, d.preferente
				from public.denominaciones_metricas d
				where d.forma_id in (select forma_id from forma_objetivo)
					or d.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
					or d.esquema_rima_id in (select esquema_rima_id from esquemas_rima_objetivo)
					-- El eslabón de la estancia también se llama «chiave», y una parte con nombre
					-- propio puede llevar el suyo igual que lo lleva una forma o una arquitectura.
					or d.seccion_id in (select seccion_id from secciones_objetivo)
					-- Y una realización se nombra por el rasgo que la distingue: la novena con algún
					-- verso corto se llama «novena de pie quebrado». El rasgo no es aquí el destino
					-- sino el matiz — el destino sigue siendo la forma o la arquitectura.
					or d.rasgo_id in (
						select ar.rasgo_id from public.arquitectura_rasgos ar
						where ar.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
					)
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
				select fuente_id, forma_id, arquitectura_id, rasgo_id, localizador, resumen, confianza
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

CREATE OR REPLACE FUNCTION public.get_forma_metrica_publica_jerarquica(p_slug text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
with
forma_objetivo as (
	select forma_id, tipo_registro
	from public.formas_metricas
	where activo and slug = p_slug
),
arquitecturas_objetivo as (
	-- Igual que en la ficha: las arquitecturas de un tramo no se publican.
	select arquitectura_id
	from public.arquitecturas_forma
	where activo and forma_id in (
		select forma_id from forma_objetivo where tipo_registro = 'forma'
	)
),
arquitecturas_reutilizadas as (
	select distinct s.arquitectura_referenciada_id as arquitectura_id
	from public.estructuras_secciones s
	where s.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		and s.arquitectura_referenciada_id is not null
),
grupos_objetivo as (
	select g.*
	from public.preguntas_metricas g
	where g.activo and g.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
)
select public.get_forma_metrica_publica(p_slug) || jsonb_build_object(
	'tiposRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.termino)
		from (
			select distinct v.termino_id, v.termino, v.etiqueta
			from public.vocabularios v
			where v.categoria = 'tipo_rima'
				and (
					v.termino_id in (
						select a.tipo_rima_id from public.arquitecturas_forma a
						where a.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
					)
					or v.termino_id in (
						select er.tipo_rima_id from public.esquemas_rima er
						where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
					)
				)
		) x
	), '[]'::jsonb),
	'esquemasRima', coalesce((
		select jsonb_agg(to_jsonb(x) order by x.nombre)
		from (
			select er.esquema_rima_id, er.arquitectura_id, er.nombre, er.notacion, er.descripcion,
				er.seccion_id, er.modalidad, er.tipo_secuencia, er.tipo_rima_id
			from public.esquemas_rima er
			where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
				or er.esquema_rima_id in (
					select o.esquema_rima_id
					from public.opciones_eleccion_metrica o
					join grupos_objetivo g using (grupo_eleccion_id)
					where o.esquema_rima_id is not null
				)
		) x
	), '[]'::jsonb),
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

do $comprobacion$
declare
	v_arqs integer;
	v_arqs_forma integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecutan las dos**, que es lo único que prueba que compilan de verdad.
	select jsonb_array_length(
		coalesce(public.get_forma_metrica_publica('irregular') -> 'arquitecturas', '[]'::jsonb)
	) into v_arqs;

	if v_arqs <> 0 then
		raise exception 'La ficha del tramo sigue enseñando % arquitecturas.', v_arqs;
	end if;

	perform public.get_forma_metrica_publica_jerarquica('irregular');

	-- Y una forma de verdad no ha perdido las suyas.
	select jsonb_array_length(
		coalesce(public.get_forma_metrica_publica('soneto') -> 'arquitecturas', '[]'::jsonb)
	) into v_arqs_forma;

	if v_arqs_forma < 1 then
		raise exception 'El soneto se ha quedado sin arquitecturas en su ficha.';
	end if;

	perform public.get_forma_metrica_publica_jerarquica('soneto');

	raise notice 'El tramo no enseña arquitecturas y el soneto conserva sus %.', v_arqs_forma;
end
$comprobacion$;

commit;
