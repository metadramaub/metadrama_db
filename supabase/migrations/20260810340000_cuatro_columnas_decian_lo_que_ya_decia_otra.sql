-- Cuatro columnas decían lo que ya decía otra.
--
-- El inventario de «columnas que no distinguen nada» juntaba cosas de naturaleza distinta. Al
-- rehacerlo en vivo se separaron tres grupos, y este cierra dos de ellos.
--
--   **`formas_metricas.seleccionable` duplica `tipo_registro`.** La guía del gestor dice que «un
--   mero esquema no debe ser seleccionable», o sea que se inventó para separar identidades de
--   esquemas —y eso ya lo dice `tipo_registro`, con sus 27 `forma` y sus 2 `sin_forma`—. El
--   editor del gestor, además, **forzaba `seleccionable = true` cuando el registro es
--   `sin_forma`**: el único caso que podía ponerla en falso estaba codificado para no hacerlo.
--
--   **`esquema_rima_enlaces.obligatorio`, `esquema_rima_restricciones.obligatoria` y
--   `esquema_rima_enlaces.tipo_enlace` duplican `modalidad`.** Trece enlaces, todos `misma_rima`
--   y obligatorios; once restricciones, todas obligatorias. Y antes que por el dato, por el
--   concepto: **una restricción que no obliga no es una restricción**. Cuánto obliga algo lo dice
--   `modalidad`, que es la escala que gradúa lo que la tradición ha fijado.
--
-- El tercer grupo —`activo` en las ocho tablas del catálogo— **no se toca**: no es una columna
-- vacía sino un mecanismo de retirada sin estrenar, lo leen diecisiete objetos SQL, y el IP
-- decidió el 10 de agosto de 2026 resolverlo al fusionar `develop` con `main`, cuando se vea qué
-- se retira de verdad al migrar las secuencias del vocabulario legado.
--
-- NO CAMBIA NINGUNA CONDUCTA. `obtener_catalogo_demarcador` ya filtraba además por
-- `tipo_registro = 'forma'`, así que quitarle `seleccionable` no altera a quién deja pasar; y
-- `validar_secuencia_editor_metrico` trata el caso `sin_forma` por su cuenta unas líneas más
-- abajo. Las 29 entradas eran seleccionables.
--
-- Las tres funciones se recrean ANTES de quitar las columnas, porque un cuerpo entrecomillado no
-- se revalida al borrar una columna: si se quitara primero, quedarían rotas en silencio hasta que
-- alguien las llamara. Y la guarda **las ejecuta**, las tres, incluido el disparador mediante una
-- inserción real que se deshace acto seguido.

begin;

-- 1 · El demarcador deja de mirar `seleccionable`. Ya miraba `tipo_registro`.

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
$function$;

-- 2 · El disparador del editor V2. El caso `sin_forma` lo trata él mismo unas líneas más abajo,
--     así que `seleccionable` no le decía nada que no supiera.

create or replace function public.validar_secuencia_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_tipo_registro text;
	v_slug text;
begin
	select tipo_registro, slug
	into v_tipo_registro, v_slug
	from public.formas_metricas
	where forma_id = new.forma_id
		and activo;

	if v_tipo_registro is null then
		raise exception 'La entrada métrica no está activa';
	end if;

	if v_tipo_registro = 'sin_forma' then
		if new.arquitectura_id is not null then
			raise exception 'Una tramo sin forma no admite arquitectura normativa';
		end if;
		if v_slug = 'verso_aislado' and new.v_fin <> new.v_ini then
			raise exception 'Verso aislado debe abarcar exactamente un verso';
		end if;
		if v_slug = 'irregular' and new.v_fin - new.v_ini + 1 < 2 then
			raise exception 'Versificación irregular debe abarcar al menos dos versos';
		end if;
		return new;
	end if;

	if new.arquitectura_id is null or not exists (
		select 1
		from public.arquitecturas_forma configuracion
		where configuracion.arquitectura_id = new.arquitectura_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
	) then
		raise exception 'La arquitectura no pertenece a una forma activa';
	end if;

	return new;
end;
$function$;

-- 3 · La ficha pública deja de proyectar `obligatoria`, que siempre valía lo mismo.

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
				x.descripcion
			from public.esquema_rima_restricciones x
			join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
			where er.arquitectura_id in (select arquitectura_id from arquitecturas_objetivo)
		) x
	), '[]'::jsonb)
);
$function$;

-- 4 · Ya nadie las lee: se van.

alter table public.formas_metricas drop column if exists seleccionable;
alter table public.esquema_rima_enlaces drop column if exists obligatorio;
alter table public.esquema_rima_enlaces drop column if exists tipo_enlace;
alter table public.esquema_rima_restricciones drop column if exists obligatoria;

do $$
declare
	v_n integer;
	v_json jsonb;
	v_forma uuid;
	v_arquitectura uuid;
	v_editor uuid;
	v_prueba uuid;
	v_escenario uuid;
begin
	-- Ninguna de las cuatro sobrevive en ninguna tabla.
	select count(*) into v_n
	from information_schema.columns
	where table_schema = 'public'
		and column_name in ('seleccionable', 'obligatorio', 'obligatoria', 'tipo_enlace');
	if v_n <> 0 then
		raise exception 'Quedan % columnas de las retiradas', v_n;
	end if;

	-- Ni en el cuerpo de ninguna función o vista, que es donde se esconden.
	select count(*) into v_n
	from pg_proc p
	join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public'
		and p.prokind = 'f'
		and (pg_get_functiondef(p.oid) ~ '\mseleccionable\M'
			or pg_get_functiondef(p.oid) ~ '\mobligatori[ao]\M'
			or pg_get_functiondef(p.oid) ~ '\mtipo_enlace\M');
	if v_n <> 0 then
		raise exception '% funciones siguen nombrando una columna retirada', v_n;
	end if;

	-- Se ejecuta el demarcador entero. Aquí sale vacío —es `security definer` y filtra por
	-- `auth_is_admin_or_ip()`, que en una migración no es nadie—, pero eso no le resta valor a la
	-- prueba: `jsonb_build_object` evalúa igualmente sus dieciséis subconsultas, y una columna
	-- retirada reventaría al resolverse. Lo que se comprueba es que el cuerpo corre entero.
	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ?& array['forms', 'architectures', 'rhymePatterns', 'choiceOptions', 'vocabularies']) then
		raise exception 'El catálogo del demarcador salió sin sus claves: %', v_json;
	end if;

	-- Y a quién deja pasar se comprueba aparte, sobre el filtro que le queda: las 27 formas, sin
	-- los dos tramos sin forma. Es exactamente a quien dejaba pasar antes, porque ya filtraba por
	-- `tipo_registro` además de por `seleccionable`.
	select count(*) into v_n
	from public.formas_metricas
	where activo and tipo_registro = 'forma';
	if v_n <> 27 then
		raise exception 'El demarcador dejaría pasar % formas en vez de 27', v_n;
	end if;

	-- Y la ficha pública jerárquica de todas y cada una de las formas.
	for v_forma in select forma_id from public.formas_metricas loop
		select public.get_forma_metrica_publica_jerarquica(f.slug) into v_json
		from public.formas_metricas f where f.forma_id = v_forma;
		if v_json is null then
			raise exception 'La ficha jerárquica salió vacía para una forma';
		end if;
	end loop;

	-- El disparador solo se ejecuta insertando. Se prueban sus dos caminos —una forma con
	-- arquitectura y un tramo sin forma— y se deshace lo insertado.
	select e.user_id into v_editor from public.editores e limit 1;
	select s.escenario_id into v_escenario from public.escenarios_editor_metrico s limit 1;

	select a.forma_id, a.arquitectura_id into v_forma, v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.tipo_registro = 'forma' and a.activo
	limit 1;

	insert into public.secuencias_editor_metrico
		(escenario_id, orden, v_ini, v_fin, forma_id, arquitectura_id, created_by, updated_by)
	values (v_escenario, 9999, 1, 4, v_forma, v_arquitectura, v_editor, v_editor)
	returning secuencia_prueba_id into v_prueba;
	delete from public.secuencias_editor_metrico where secuencia_prueba_id = v_prueba;

	select forma_id into v_forma from public.formas_metricas where slug = 'verso_aislado';

	insert into public.secuencias_editor_metrico
		(escenario_id, orden, v_ini, v_fin, forma_id, created_by, updated_by)
	values (v_escenario, 9999, 1, 1, v_forma, v_editor, v_editor)
	returning secuencia_prueba_id into v_prueba;
	delete from public.secuencias_editor_metrico where secuencia_prueba_id = v_prueba;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
