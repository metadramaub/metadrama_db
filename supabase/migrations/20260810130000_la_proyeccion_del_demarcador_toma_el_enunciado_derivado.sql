-- La proyección del demarcador toma el enunciado de donde ahora se deriva.
--
-- `obtener_catalogo_demarcador()` seleccionaba `g.nombre` de `grupos_eleccion_metrica`, y esa
-- columna dejó de existir al derivarse el enunciado. La función es `language sql` con el cuerpo
-- entre comillas, así que **Postgres no la revalida al borrar la columna**: pasó la migración
-- anterior sin una queja y habría fallado en la primera compilación del demarcador. Es el mismo
-- modo de fallo que ya mordió una vez con un disparador, y por la misma razón.
--
-- Se rehace entera —no se puede cambiar una línea suelta de un cuerpo entrecomillado— apuntando
-- el bloque de las preguntas a la vista, y con una guarda que **la ejecuta**, que es lo único
-- que demuestra que compila.
--
-- Y ejecutarla destapó que **ya estaba rota desde el 5 de agosto**, por lo mismo: la migración
-- `20260805460000` retiró `formas_metricas.grado_especificacion` y la proyección seguía
-- pidiéndola. Cuatro días sin que nada avisara, porque nadie la ejecuta salvo el demarcador
-- nuevo y ninguna prueba llega hasta ahí. La columna se quita: no la usa nada del código, que
-- pide aparte el `nivel_estructural` que sí necesita.
--
-- Y una segunda, más reciente y de la misma casa: `arquitectura_rasgos.valor_numero` y
-- `valor_texto` se retiraron el 9 de agosto al quedar el valor de un rasgo siempre de
-- vocabulario, y la proyección seguía pidiéndolas. También se quitan.

begin;

create or replace function public.obtener_catalogo_demarcador()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $function$
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
			select r.repeticion_id, r.arquitectura_id, r.tipo, r.regla, r.descripcion, r.modalidad, r.ambito
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
$function$;

do $$
declare
	v_payload jsonb;
	v_n integer;
begin
	-- Ejecutarla es la prueba. Crearla no lo es: el cuerpo entrecomillado no se mira hasta aquí,
	-- y es al ejecutarlo cuando Postgres resuelve cada columna que nombra. Así salieron las dos
	-- que llevaban meses y días rotas.
	--
	-- Lo que no se puede comprobar aquí es el contenido: la función es `security definer` y
	-- comprueba admin/IP, y en una migración no hay sesión, de modo que devuelve las listas
	-- vacías por diseño. Que estén todas las claves demuestra que el cuerpo entero se planificó.
	v_payload := public.obtener_catalogo_demarcador();

	select count(*) into v_n
	from unnest(array['forms', 'architectures', 'metricPatterns', 'metricPositions',
		'metricOptions', 'metres', 'rhymePatterns', 'rhymePositions', 'sections', 'repetitions',
		'traits', 'traitValues', 'architectureTraits', 'choiceGroups', 'choiceOptions',
		'vocabularies']) k
	where not v_payload ? k;
	if v_n <> 0 then
		raise exception 'A la proyección del demarcador le faltan % bloques', v_n;
	end if;

	-- Y el enunciado, que es lo que esta migración cambia, se comprueba donde sí se puede ver.
	select count(*) into v_n
	from public.grupos_eleccion_metrica_resueltos
	where activo and coalesce(btrim(nombre), '') = '';
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin enunciado', v_n;
	end if;
end;
$$;

commit;
