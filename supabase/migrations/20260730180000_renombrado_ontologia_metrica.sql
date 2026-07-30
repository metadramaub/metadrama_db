begin;

-- Bloque A de la migración estructural del dominio métrico.
-- Renombra tablas, columnas y valores controlados para que la base hable el
-- vocabulario de docs/dominio-metrico/ontologia-metrica.md. No cambia el
-- significado de ningún dato: el informe de conformidad debe dar el mismo
-- resultado antes y después.

-- La vista de reglas de longitud se elimina ahora y se recrea al final: renombrar
-- una vista no cambia los nombres de sus columnas de salida.
drop view if exists public.configuraciones_forma_reglas_longitud;

-- 1 · Tablas

alter table public.configuraciones_forma rename to arquitecturas_forma;
alter table public.configuracion_rasgos rename to arquitectura_rasgos;
alter table public.patrones_metricos rename to esquemas_metricos;
alter table public.patron_metrico_posiciones rename to esquema_metrico_posiciones;
alter table public.patron_metrico_opciones rename to esquema_metrico_opciones;
alter table public.patrones_rima rename to esquemas_rima;
alter table public.patron_rima_posiciones rename to esquema_rima_posiciones;
alter table public.patron_rima_enlaces rename to esquema_rima_enlaces;
alter table public.patron_rima_restricciones rename to esquema_rima_restricciones;
alter table public.patrones_repeticion rename to repeticiones_metricas;
alter table public.patron_repeticion_posiciones rename to repeticion_posiciones;
alter table public.combinaciones_patrones_configuracion rename to variedades_arquitectura;
alter table public.unidades_editor_metrico rename to realizaciones_editor_metrico;

-- 2 · Columnas

alter table public.afirmaciones_fuentes_metricas rename column configuracion_id to arquitectura_id;
alter table public.afirmaciones_fuentes_metricas rename column patron_metrico_id to esquema_metrico_id;
alter table public.afirmaciones_fuentes_metricas rename column patron_rima_id to esquema_rima_id;
alter table public.variedades_arquitectura rename column combinacion_id to variedad_id;
alter table public.variedades_arquitectura rename column configuracion_id to arquitectura_id;
alter table public.variedades_arquitectura rename column patron_metrico_id to esquema_metrico_id;
alter table public.variedades_arquitectura rename column patron_rima_id to esquema_rima_id;
alter table public.arquitectura_rasgos rename column configuracion_id to arquitectura_id;
alter table public.arquitecturas_forma rename column configuracion_id to arquitectura_id;
alter table public.denominaciones_metricas rename column configuracion_id to arquitectura_id;
alter table public.denominaciones_metricas rename column patron_metrico_id to esquema_metrico_id;
alter table public.denominaciones_metricas rename column patron_rima_id to esquema_rima_id;
alter table public.denominaciones_metricas rename column patron_repeticion_id to repeticion_id;
alter table public.desviaciones_editor_metrico rename column unidad_prueba_id to realizacion_prueba_id;
alter table public.desviaciones_editor_metrico rename column patron_rima_observado_id to esquema_rima_observado_id;
alter table public.desviaciones_editor_metrico rename column patron_repeticion_observado_id to repeticion_observada_id;
alter table public.elecciones_editor_metrico rename column unidad_prueba_id to realizacion_prueba_id;
alter table public.estructuras_secciones rename column configuracion_id to arquitectura_id;
alter table public.estructuras_secciones rename column patron_metrico_id to esquema_metrico_id;
alter table public.estructuras_secciones rename column patron_rima_id to esquema_rima_id;
alter table public.estructuras_secciones rename column configuracion_referenciada_id to arquitectura_referenciada_id;
alter table public.grupos_eleccion_metrica rename column configuracion_id to arquitectura_id;
alter table public.migracion_termino_destinos rename column configuracion_id to arquitectura_id;
alter table public.migracion_termino_destinos rename column patron_rima_id to esquema_rima_id;
alter table public.migracion_termino_destinos rename column patron_metrico_id to esquema_metrico_id;
alter table public.migracion_termino_destinos rename column combinacion_id to variedad_id;
alter table public.opciones_eleccion_metrica rename column patron_metrico_id to esquema_metrico_id;
alter table public.opciones_eleccion_metrica rename column patron_rima_id to esquema_rima_id;
alter table public.opciones_eleccion_metrica rename column patron_repeticion_id to repeticion_id;
alter table public.opciones_eleccion_metrica rename column combinacion_id to variedad_id;
alter table public.esquema_metrico_opciones rename column patron_metrico_id to esquema_metrico_id;
alter table public.esquema_metrico_posiciones rename column patron_metrico_id to esquema_metrico_id;
alter table public.repeticion_posiciones rename column patron_repeticion_id to repeticion_id;
alter table public.esquema_rima_enlaces rename column patron_rima_id to esquema_rima_id;
alter table public.esquema_rima_posiciones rename column patron_rima_id to esquema_rima_id;
alter table public.esquema_rima_restricciones rename column patron_rima_id to esquema_rima_id;
alter table public.esquemas_metricos rename column patron_metrico_id to esquema_metrico_id;
alter table public.esquemas_metricos rename column configuracion_id to arquitectura_id;
alter table public.repeticiones_metricas rename column patron_repeticion_id to repeticion_id;
alter table public.repeticiones_metricas rename column configuracion_id to arquitectura_id;
alter table public.esquemas_rima rename column patron_rima_id to esquema_rima_id;
alter table public.esquemas_rima rename column configuracion_id to arquitectura_id;
alter table public.secuencias_editor_metrico rename column configuracion_id to arquitectura_id;
alter table public.realizaciones_editor_metrico rename column unidad_prueba_id to realizacion_prueba_id;
alter table public.realizaciones_editor_metrico rename column unidad_padre_id to realizacion_padre_id;

-- La notación legible se distingue del comportamiento computable.
alter table public.esquemas_rima rename column esquema to notacion;
comment on column public.esquemas_rima.notacion is
	'Representación legible del esquema. El comportamiento computable vive en las posiciones, los enlaces y las restricciones.';

-- 3 · Funciones que nombran las entidades renombradas
create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
returns uuid
language plpgsql
SECURITY DEFINER
set search_path = 'public'
as $$
declare
	v_secuencia_id uuid;
	v_item jsonb;
	v_grupo record;
	v_total integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
			using errcode = '42501';
	end if;

	v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;

	if v_secuencia_id is null then
		insert into public.secuencias_editor_metrico (
			escenario_id, orden, v_ini, v_fin, forma_id, arquitectura_id,
			observaciones, created_by, updated_by
		)
		values (
			(p_datos ->> 'escenario_id')::uuid,
			(p_datos ->> 'orden')::integer,
			(p_datos ->> 'v_ini')::integer,
			(p_datos ->> 'v_fin')::integer,
			(p_datos ->> 'forma_id')::uuid,
			(p_datos ->> 'arquitectura_id')::uuid,
			nullif(btrim(p_datos ->> 'observaciones'), ''),
			auth.uid(),
			auth.uid()
		)
		returning secuencia_prueba_id into v_secuencia_id;
	else
		update public.secuencias_editor_metrico
		set
			escenario_id = (p_datos ->> 'escenario_id')::uuid,
			orden = (p_datos ->> 'orden')::integer,
			v_ini = (p_datos ->> 'v_ini')::integer,
			v_fin = (p_datos ->> 'v_fin')::integer,
			forma_id = (p_datos ->> 'forma_id')::uuid,
			arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid,
			observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
			updated_by = auth.uid()
		where secuencia_prueba_id = v_secuencia_id
			and exists (
				select 1 from public.escenarios_editor_metrico
				where escenario_id = (p_datos ->> 'escenario_id')::uuid
			);

		if not found then
			raise exception 'Secuencia métrica de prueba no encontrada';
		end if;
	end if;

	delete from public.desviaciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.elecciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.realizaciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
	loop
		insert into public.realizaciones_editor_metrico (
			realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id,
			orden, v_ini, v_fin, etiqueta, observaciones
		)
		values (
			(v_item ->> 'realizacion_prueba_id')::uuid,
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_padre_id', '')::uuid,
			(v_item ->> 'seccion_id')::uuid,
			(v_item ->> 'orden')::integer,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			nullif(btrim(v_item ->> 'etiqueta'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
	loop
		insert into public.elecciones_editor_metrico (
			secuencia_prueba_id,
			realizacion_prueba_id,
			grupo_eleccion_id,
			opcion_eleccion_id,
			valor_texto,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			nullif(v_item ->> 'opcion_eleccion_id', '')::uuid,
			nullif(btrim(v_item ->> 'valor_texto'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
	loop
		insert into public.desviaciones_editor_metrico (
			secuencia_prueba_id, realizacion_prueba_id, v_ini, v_fin, dimension,
			relacion_norma, metro_observado_id, esquema_rima_observado_id,
			seccion_observada_id, repeticion_observada_id,
			valor_rasgo_observado_id, observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			v_item ->> 'dimension',
			v_item ->> 'relacion_norma',
			nullif(v_item ->> 'metro_observado_id', '')::uuid,
			nullif(v_item ->> 'esquema_rima_observado_id', '')::uuid,
			nullif(v_item ->> 'seccion_observada_id', '')::uuid,
			nullif(v_item ->> 'repeticion_observada_id', '')::uuid,
			nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_grupo in
		select *
		from public.grupos_eleccion_metrica
		where arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
			and activo
			and alcance = 'secuencia'
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id
			and realizacion_prueba_id is null;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	for v_grupo in
		select grupo.*, unidad.realizacion_prueba_id
		from public.realizaciones_editor_metrico unidad
		join public.grupos_eleccion_metrica grupo
			on grupo.arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
			and grupo.activo
			and grupo.alcance = 'unidad'
			and (grupo.seccion_id is null or grupo.seccion_id = unidad.seccion_id)
		where unidad.secuencia_prueba_id = v_secuencia_id
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and realizacion_prueba_id = v_grupo.realizacion_prueba_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	return v_secuencia_id;
end;
$$;

create or replace function public.marcar_configuracion_metrica_principal(p_configuracion_id uuid)
returns void
language plpgsql
SECURITY DEFINER
set search_path = 'public'
as $$
declare
	v_forma_id uuid;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden modificar el catálogo métrico'
			using errcode = '42501';
	end if;

	select forma_id
	into v_forma_id
	from public.arquitecturas_forma
	where arquitectura_id = p_configuracion_id
	for update;

	if v_forma_id is null then
		raise exception 'Arquitectura métrica no encontrada'
			using errcode = 'P0002';
	end if;

	update public.arquitecturas_forma
	set principal = arquitectura_id = p_configuracion_id
	where forma_id = v_forma_id
		and activo;
end;
$$;

create or replace function public.normalizar_extensiones_al_cambiar_nivel_metrico()
returns trigger
language plpgsql
set search_path = 'public'
as $$
begin
	if new.nivel_estructural not in ('estrofa', 'composicion') then
		update public.arquitecturas_forma
		set numero_versos = null
		where forma_id = new.forma_id
			and numero_versos is not null;
	end if;

	return new;
end;
$$;

create or replace function public.regla_longitud_configuracion_metrica(p_configuracion_id uuid)
returns TABLE(modulo_versos integer, residuo_versos integer, minimo_versos integer, origen text, explicacion text)
language plpgsql
STABLE
set search_path = 'public'
as $$
declare
	v_numero_versos integer;
	v_total_secciones integer;
	v_secciones_no_derivables integer;
	v_secciones_abiertas integer;
	v_longitud_abierta integer;
	v_longitud_minima integer;
	v_longitud_fija integer;
	v_total_patrones integer;
	v_patrones_con_posiciones integer;
	v_longitudes_distintas integer;
	v_longitud_ciclo integer;
begin
	select configuracion.numero_versos
	into v_numero_versos
	from public.arquitecturas_forma configuracion
	where configuracion.arquitectura_id = p_configuracion_id
		and configuracion.activo;

	if not found then
		return;
	end if;

	if v_numero_versos is not null and v_numero_versos > 1 then
		return query
		select
			v_numero_versos,
			0,
			v_numero_versos,
			'numero_versos'::text,
			format('unidades completas de %s versos', v_numero_versos);
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (
			where seccion.versos_min is null
				or seccion.versos_max is null
				or seccion.versos_min <> seccion.versos_max
				or (
					seccion.repeticiones_max is not null
					and coalesce(seccion.repeticiones_min, 0) <> seccion.repeticiones_max
				)
		)::integer,
		count(*) filter (where seccion.repeticiones_max is null)::integer,
		max(seccion.versos_min) filter (where seccion.repeticiones_max is null)::integer,
		coalesce(
			sum(seccion.versos_min * coalesce(seccion.repeticiones_min, 0)),
			0
		)::integer,
		coalesce(
			sum(
				seccion.versos_min * coalesce(seccion.repeticiones_min, 0)
			) filter (where seccion.repeticiones_max is not null),
			0
		)::integer
	into
		v_total_secciones,
		v_secciones_no_derivables,
		v_secciones_abiertas,
		v_longitud_abierta,
		v_longitud_minima,
		v_longitud_fija
	from public.estructuras_secciones seccion
	where seccion.arquitectura_id = p_configuracion_id
		and seccion.seccion_padre_id is null;

	if v_total_secciones > 0 and v_secciones_no_derivables = 0 then
		if v_secciones_abiertas = 0 and v_longitud_minima > 1 then
			return query
			select
				v_longitud_minima,
				0,
				v_longitud_minima,
				'secciones_fijas'::text,
				format('estructuras completas de %s versos', v_longitud_minima);
			return;
		elsif v_secciones_abiertas = 1 and v_longitud_abierta > 1 then
			return query
			select
				v_longitud_abierta,
				mod(v_longitud_fija, v_longitud_abierta),
				v_longitud_minima,
				'secciones_repetibles'::text,
				case
					when v_longitud_fija = 0 then
						format('bloques completos de %s versos', v_longitud_abierta)
					else
						format(
							'bloques completos de %s versos más %s %s fijo%s',
							v_longitud_abierta,
							v_longitud_fija,
							case when v_longitud_fija = 1 then 'verso' else 'versos' end,
							case when v_longitud_fija = 1 then '' else 's' end
						)
				end;
			return;
		end if;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			rima.esquema_rima_id,
			count(posicion.posicion_id)::integer as longitud
		from public.esquemas_rima rima
		left join public.esquema_rima_posiciones posicion
			on posicion.esquema_rima_id = rima.esquema_rima_id
		where rima.arquitectura_id = p_configuracion_id
			and rima.comportamiento = 'secuencia_repetible'
			and rima.estado_revision <> 'retirada'
		group by rima.esquema_rima_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_rima'::text,
			format('ciclos completos de rima de %s versos', v_longitud_ciclo);
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			metrico.esquema_metrico_id,
			count(posicion.posicion_id)::integer as longitud
		from public.esquemas_metricos metrico
		left join public.esquema_metrico_posiciones posicion
			on posicion.esquema_metrico_id = metrico.esquema_metrico_id
		where metrico.arquitectura_id = p_configuracion_id
			and metrico.tipo = 'secuencia_repetible'
			and metrico.estado_revision <> 'retirada'
		group by metrico.esquema_metrico_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_metrico'::text,
			format('ciclos métricos completos de %s versos', v_longitud_ciclo);
	end if;
end;
$$;

create or replace function public.sincronizar_posiciones_patron_rima_fijo()
returns trigger
language plpgsql
set search_path = 'public'
as $_$
declare
	v_posicion integer;
	v_clase text;
begin
	if new.comportamiento <> 'secuencia_fija'
		or new.esquema is null
		or new.esquema !~ '^[A-Za-z-]+$'
	then
		return new;
	end if;

	delete from public.esquema_rima_posiciones
	where esquema_rima_id = new.esquema_rima_id;

	for v_posicion in 1..char_length(new.esquema) loop
		v_clase := substring(new.esquema from v_posicion for 1);

		insert into public.esquema_rima_posiciones (
			esquema_rima_id,
			bloque,
			posicion,
			ubicacion,
			clase_rima,
			suelto,
			opcional
		)
		values (
			new.esquema_rima_id,
			1,
			v_posicion,
			'final',
			case when v_clase = '-' then null else v_clase end,
			v_clase = '-',
			false
		);
	end loop;

	return new;
end;
$_$;

create or replace function public.validar_combinacion_patrones_configuracion()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_configuracion_metrica_id uuid;
	v_configuracion_rima_id uuid;
begin
	select arquitectura_id into v_configuracion_metrica_id
	from public.esquemas_metricos
	where esquema_metrico_id = new.esquema_metrico_id;

	select arquitectura_id into v_configuracion_rima_id
	from public.esquemas_rima
	where esquema_rima_id = new.esquema_rima_id;

	if v_configuracion_metrica_id is distinct from new.arquitectura_id
		or v_configuracion_rima_id is distinct from new.arquitectura_id
	then
		raise exception
			'Los patrones de la combinación deben pertenecer a su misma arquitectura';
	end if;

	return new;
end;
$$;

create or replace function public.validar_configuracion_forma_no_editorial()
returns trigger
language plpgsql
set search_path = 'public'
as $$
begin
	if exists (
		select 1
		from public.formas_metricas
		where forma_id = new.forma_id
			and tipo_registro = 'sin_forma'
	) then
		raise exception 'Una tramo sin forma no puede tener arquitecturas normativas';
	end if;
	return new;
end;
$$;

create or replace function public.validar_desviacion_editor_metrico()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_secuencia_ini integer;
	v_secuencia_fin integer;
	v_configuracion_id uuid;
begin
	select v_ini, v_fin, arquitectura_id
	into v_secuencia_ini, v_secuencia_fin, v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if v_configuracion_id is null then
		raise exception 'Una tramo sin forma no admite desviaciones respecto de una norma inexistente';
	end if;
	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La desviación debe quedar dentro del rango de la secuencia';
	end if;
	if new.realizacion_prueba_id is not null and not exists (
		select 1 from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id
	) then
		raise exception 'La unidad de la desviación no pertenece a la secuencia';
	end if;
	return new;
end;
$$;

create or replace function public.validar_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path = 'public'
as $_$
declare
	v_configuracion_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_maximo integer;
	v_tipo_control text;
	v_longitud_esperada integer;
	v_total integer;
begin
	select arquitectura_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select alcance, seccion_id, selecciones_max, tipo_control
	into v_alcance, v_seccion_grupo, v_maximo, v_tipo_control
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and arquitectura_id = v_configuracion_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la arquitectura seleccionada';
	end if;

	if v_tipo_control = 'opciones' then
		if new.opcion_eleccion_id is null or new.valor_texto is not null then
			raise exception 'Esta pregunta necesita una opción normalizada';
		end if;
		if not exists (
			select 1 from public.opciones_eleccion_metrica
			where opcion_eleccion_id = new.opcion_eleccion_id
				and grupo_eleccion_id = new.grupo_eleccion_id
				and activo
		) then
			raise exception 'La opción no pertenece al grupo de elección';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		if new.opcion_eleccion_id is not null or new.valor_texto is null then
			raise exception 'Esta pregunta necesita un esquema de rima observado';
		end if;
		new.valor_texto := upper(regexp_replace(btrim(new.valor_texto), '\s+', '', 'g'));
		if new.valor_texto !~ '^[A-Z-]+$' then
			raise exception 'El esquema de rima solo admite letras y guiones';
		end if;
	else
		raise exception 'Tipo de control editorial no reconocido';
	end if;

	if v_alcance = 'secuencia' and new.realizacion_prueba_id is not null then
		raise exception 'Una elección de secuencia no puede vincularse a una unidad';
	elsif v_alcance = 'unidad' and new.realizacion_prueba_id is null then
		raise exception 'Una elección de unidad necesita una unidad concreta';
	end if;

	if new.realizacion_prueba_id is not null then
		select seccion_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_longitud_esperada
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if v_seccion_unidad is null then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
		if v_seccion_grupo is not null and v_seccion_grupo <> v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		select v_fin - v_ini + 1
		into v_longitud_esperada
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = new.secuencia_prueba_id;
	end if;

	if v_tipo_control = 'esquema_rima'
		and length(new.valor_texto) <> v_longitud_esperada
	then
		raise exception
			'El esquema de rima debe tener % posiciones y tiene %',
			v_longitud_esperada,
			length(new.valor_texto);
	end if;

	select count(*)
	into v_total
	from public.elecciones_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id
		and grupo_eleccion_id = new.grupo_eleccion_id
		and realizacion_prueba_id is not distinct from new.realizacion_prueba_id
		and eleccion_prueba_id <> new.eleccion_prueba_id;

	if v_total + 1 > v_maximo then
		raise exception 'La elección supera la cardinalidad máxima del grupo';
	end if;

	return new;
end;
$_$;

create or replace function public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid)
returns void
language plpgsql
set search_path = 'public'
as $$
declare
	v_configuracion_id uuid;
	v_seccion record;
	v_padre record;
	v_total integer;
begin
	select arquitectura_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = p_secuencia_id;

	if v_configuracion_id is null or not exists (
		select 1
		from public.estructuras_secciones
		where arquitectura_id = v_configuracion_id
			and seccion_padre_id is not null
	) then
		return;
	end if;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where arquitectura_id = v_configuracion_id
			and seccion_padre_id is null
	loop
		select count(*) into v_total
		from public.realizaciones_editor_metrico
		where secuencia_prueba_id = p_secuencia_id
			and realizacion_padre_id is null
			and seccion_id = v_seccion.seccion_id;

		if v_total < coalesce(v_seccion.repeticiones_min, 0) then
			raise exception 'La sección «%» necesita al menos % realizaciones',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_min;
		end if;
		if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
			raise exception 'La sección «%» admite como máximo % realizaciones',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_max;
		end if;
	end loop;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where arquitectura_id = v_configuracion_id
			and seccion_padre_id is not null
	loop
		for v_padre in
			select realizacion_prueba_id
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and seccion_id = v_seccion.seccion_padre_id
		loop
			select count(*) into v_total
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and realizacion_padre_id = v_padre.realizacion_prueba_id
				and seccion_id = v_seccion.seccion_id;

			if v_total < coalesce(v_seccion.repeticiones_min, 0) then
				raise exception 'Cada unidad superior necesita al menos % realizaciones de «%»',
					v_seccion.repeticiones_min,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
			if v_seccion.repeticiones_max is not null
				and v_total > v_seccion.repeticiones_max
			then
				raise exception 'Cada unidad superior admite como máximo % realizaciones de «%»',
					v_seccion.repeticiones_max,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
		end loop;
	end loop;
end;
$$;

create or replace function public.validar_forma_salida_editorial()
returns trigger
language plpgsql
set search_path = 'public'
as $$
begin
	if new.tipo_registro = 'sin_forma' and exists (
		select 1
		from public.arquitecturas_forma
		where forma_id = new.forma_id
	) then
		raise exception 'Una tramo sin forma no puede tener arquitecturas normativas';
	end if;
	return new;
end;
$$;

create or replace function public.validar_grupo_eleccion_metrica()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_configuracion_seccion uuid;
begin
	if new.seccion_id is not null then
		select arquitectura_id
		into v_configuracion_seccion
		from public.estructuras_secciones
		where seccion_id = new.seccion_id;

		if v_configuracion_seccion is distinct from new.arquitectura_id then
			raise exception 'La sección de alcance no pertenece a la arquitectura del grupo';
		end if;
	end if;

	if new.tipo_control = 'esquema_rima' then
		if new.dimension <> 'rima' then
			raise exception 'Un control de esquema debe pertenecer a la dimensión de rima';
		end if;
		if new.selecciones_min <> 1 or new.selecciones_max <> 1 then
			raise exception 'Un control de esquema necesita exactamente una respuesta';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_dimension text;
	v_configuracion_id uuid;
	v_seccion_grupo_id uuid;
	v_configuracion_referenciada_id uuid;
	v_objetivo_configuracion_id uuid;
	v_rasgo_id uuid;
begin
	select
		grupo.dimension,
		grupo.arquitectura_id,
		grupo.seccion_id,
		seccion.arquitectura_referenciada_id
	into
		v_dimension,
		v_configuracion_id,
		v_seccion_grupo_id,
		v_configuracion_referenciada_id
	from public.grupos_eleccion_metrica grupo
	left join public.estructuras_secciones seccion
		on seccion.seccion_id = grupo.seccion_id
	where grupo.grupo_eleccion_id = new.grupo_eleccion_id;

	if v_dimension = 'metro'
		and num_nonnulls(new.metro_id, new.esquema_metrico_id) <> 1
	then
		raise exception 'Una opción de medida debe apuntar a un metro o esquema métrico';
	elsif v_dimension = 'rima' and new.esquema_rima_id is null then
		raise exception 'Una opción de rima debe apuntar a un esquema de rima';
	elsif v_dimension = 'combinacion' and new.variedad_id is null then
		raise exception 'Una opción combinada debe apuntar a una variedad';
	elsif v_dimension = 'estructura' and new.seccion_id is null then
		raise exception 'Una opción estructural debe apuntar a una sección';
	elsif v_dimension = 'repeticion' and new.repeticion_id is null then
		raise exception 'Una opción de repetición debe apuntar a un patrón de repetición';
	elsif v_dimension = 'rasgo'
		and num_nonnulls(new.rasgo_id, new.valor_rasgo_id) <> 1
	then
		raise exception
			'Una opción de rasgo debe apuntar a un rasgo booleano o a un valor controlado';
	end if;

	if new.esquema_metrico_id is not null then
		select arquitectura_id into v_objetivo_configuracion_id
		from public.esquemas_metricos
		where esquema_metrico_id = new.esquema_metrico_id;
	elsif new.esquema_rima_id is not null then
		select arquitectura_id into v_objetivo_configuracion_id
		from public.esquemas_rima
		where esquema_rima_id = new.esquema_rima_id;
	elsif new.variedad_id is not null then
		select arquitectura_id into v_objetivo_configuracion_id
		from public.variedades_arquitectura
		where variedad_id = new.variedad_id;
	elsif new.seccion_id is not null then
		select arquitectura_id into v_objetivo_configuracion_id
		from public.estructuras_secciones
		where seccion_id = new.seccion_id;
	elsif new.repeticion_id is not null then
		select arquitectura_id into v_objetivo_configuracion_id
		from public.repeticiones_metricas
		where repeticion_id = new.repeticion_id;
	elsif new.valor_rasgo_id is not null then
		select rasgo_id into v_rasgo_id
		from public.rasgo_valores
		where valor_id = new.valor_rasgo_id;
	end if;

	if v_objetivo_configuracion_id is not null
		and v_objetivo_configuracion_id is distinct from v_configuracion_id
		and (
			v_seccion_grupo_id is null
			or v_objetivo_configuracion_id is distinct from v_configuracion_referenciada_id
		)
	then
		raise exception
			'La opción no pertenece a la arquitectura del grupo ni a la arquitectura reutilizada por su sección';
	end if;

	if v_dimension = 'rasgo' then
		v_rasgo_id := coalesce(new.rasgo_id, v_rasgo_id);
		if not exists (
			select 1
			from public.arquitectura_rasgos
			where arquitectura_id = v_configuracion_id
				and rasgo_id = v_rasgo_id
		) then
			raise exception 'El rasgo de la opción no está admitido por la arquitectura';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_secuencia_editor_metrico()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_tipo_registro text;
	v_slug text;
begin
	select tipo_registro, slug
	into v_tipo_registro, v_slug
	from public.formas_metricas
	where forma_id = new.forma_id
		and activo
		and seleccionable;

	if v_tipo_registro is null then
		raise exception 'La entrada métrica no está activa o no es seleccionable';
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
		raise exception 'La arquitectura no pertenece a una forma activa y seleccionable';
	end if;

	return new;
end;
$$;

create or replace function public.validar_unidad_editor_metrico()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
	v_configuracion_id uuid;
	v_secuencia_ini integer;
	v_secuencia_fin integer;
	v_seccion_padre_esperada uuid;
	v_seccion_padre_real uuid;
	v_padre_ini integer;
	v_padre_fin integer;
begin
	select arquitectura_id, v_ini, v_fin
	into v_configuracion_id, v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select seccion_padre_id
	into v_seccion_padre_esperada
	from public.estructuras_secciones
	where seccion_id = new.seccion_id
		and arquitectura_id = v_configuracion_id;

	if not found then
		raise exception 'La sección de la unidad no pertenece a la arquitectura seleccionada';
	end if;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La unidad debe quedar dentro del rango de la secuencia';
	end if;

	if new.realizacion_padre_id is null then
		if v_seccion_padre_esperada is not null then
			raise exception 'La sección interna necesita su unidad superior';
		end if;
	else
		select seccion_id, v_ini, v_fin
		into v_seccion_padre_real, v_padre_ini, v_padre_fin
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_padre_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if v_seccion_padre_real is null then
			raise exception 'La unidad superior debe pertenecer a la misma secuencia';
		end if;
		if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
			raise exception 'La unidad superior no corresponde a la jerarquía de la sección';
		end if;
		if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
			raise exception 'La sección interna debe quedar dentro del rango de su unidad superior';
		end if;
	end if;

	return new;
end;
$$;


-- 4 · Valores controlados

-- Las restricciones se retiran antes de tocar los datos: los disparadores de
-- formas_metricas ya nombran las entidades nuevas a estas alturas.
alter table public.formas_metricas
	drop constraint formas_metricas_tipo_registro_check,
	drop constraint formas_metricas_salida_editorial_check,
	drop constraint formas_metricas_check,
	drop constraint formas_metricas_nivel_estructural_check;

-- El eje residual se sustituye por el grado de especificación: una forma general
-- se define por rasgos amplios y no se ha especializado; no es una última opción.
alter table public.formas_metricas
	add column grado_especificacion text null;

update public.formas_metricas
set grado_especificacion = case
	when tipo_registro = 'salida_editorial' then null
	when residual then 'general'
	else 'especifica'
end;

update public.formas_metricas
set tipo_registro = 'sin_forma'
where tipo_registro = 'salida_editorial';

-- Los niveles estructurales siguen la organización de la bibliografía de referencia:
-- estrofa, composición de estructura fija y serie no estrófica.
update public.formas_metricas
set nivel_estructural = 'composicion'
where nivel_estructural = 'compuesta';

alter table public.formas_metricas
	drop column residual;

alter table public.formas_metricas
	add constraint formas_metricas_tipo_registro_check
		check (tipo_registro in ('forma', 'sin_forma')),
	add constraint formas_metricas_nivel_estructural_check
		check (nivel_estructural in ('verso', 'estrofa', 'serie', 'composicion')),
	add constraint formas_metricas_grado_especificacion_check
		check (
			(tipo_registro = 'forma' and grado_especificacion in ('general', 'especifica'))
			or (tipo_registro = 'sin_forma' and grado_especificacion is null)
		),
	add constraint formas_metricas_seleccionable_check
		check (grado_especificacion is distinct from 'general' or seleccionable);

comment on column public.formas_metricas.tipo_registro is
	'Distingue las formas de los tramos sin forma, que comparten el selector por razones operativas pero carecen de norma.';
comment on column public.formas_metricas.grado_especificacion is
	'Una forma general se define por rasgos amplios y no se ha especializado; una específica fija esa norma. El demarcador ofrece la más específica que encaje.';
comment on column public.formas_metricas.nivel_estructural is
	'Qué es la unidad de la forma: la estrofa, el poema completo de una composición de estructura fija, o la serie abierta.';

comment on table public.arquitecturas_forma is
	'Realizaciones estructurales admitidas por una forma. Constantes en toda la secuencia.';
comment on table public.variedades_arquitectura is
	'Parejas de esquema métrico y esquema de rima que el proyecto reconoce dentro de una arquitectura. No crean formas ni arquitecturas.';
comment on table public.realizaciones_editor_metrico is
	'Realizaciones de secciones dentro de una secuencia de prueba. La unidad es lo que define la forma; esto son sus partes materializadas.';

-- 5 · Vista de reglas de longitud, con sus columnas de salida renombradas

create view public.arquitecturas_reglas_longitud
with (security_invoker = 'true') as
select
	arquitectura.arquitectura_id,
	arquitectura.nombre as arquitectura_nombre,
	regla.modulo_versos,
	regla.residuo_versos,
	regla.minimo_versos,
	regla.origen,
	regla.explicacion
from public.arquitecturas_forma arquitectura
cross join lateral public.regla_longitud_configuracion_metrica(arquitectura.arquitectura_id)
	regla (modulo_versos, residuo_versos, minimo_versos, origen, explicacion)
where arquitectura.activo;

comment on view public.arquitecturas_reglas_longitud is
	'Reglas de compatibilidad de longitud derivadas para el registrador de secuencias.';

update public.catalogo_metrico_estado
set modelo_version = 43,
	actualizado_en = now()
where id = true;

commit;
