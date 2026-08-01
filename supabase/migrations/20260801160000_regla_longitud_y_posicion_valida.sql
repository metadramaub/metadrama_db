begin;

-- Se restaura la regla de longitud completa.
--
-- Al recrear esta función para el renombrado de vocabularios se simplificó de más: quedaron
-- la rama de la unidad declarada y una versión débil de la del ciclo de rima, y desaparecieron
-- la rama que deriva la longitud desde las secciones y la del ciclo métrico.
--
-- La consecuencia era concreta. El terceto encadenado tiene una sección repetible de tres
-- versos y una fija de uno, así que su regla es «múltiplos de tres más uno». Sin la rama de
-- secciones la base decía «múltiplos de tres», y habría rechazado como incompatible el rango
-- de cualquier serie encadenada real. Ninguna secuencia guardada lo ha sufrido, porque no hay
-- ninguna.
--
-- Vuelve el original con los nombres nuevos: `tipo_secuencia = 'ciclo'` donde decía
-- `comportamiento = 'secuencia_repetible'`.

create or replace function public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
returns table (
	modulo_versos integer,
	residuo_versos integer,
	minimo_versos integer,
	origen text,
	explicacion text
)
language plpgsql
stable
set search_path to 'public'
as $regla$
declare
	v_unidad_min integer;
	v_unidad_max integer;
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
	select arquitectura.unidad_versos_min, arquitectura.unidad_versos_max
	into v_unidad_min, v_unidad_max
	from public.arquitecturas_forma arquitectura
	where arquitectura.arquitectura_id = p_arquitectura_id
		and arquitectura.activo;

	if not found then
		return;
	end if;

	if v_unidad_min is not null then
		if v_unidad_min = v_unidad_max and v_unidad_min > 1 then
			return query
			select
				v_unidad_min,
				0,
				v_unidad_min,
				'unidad'::text,
				format('unidades completas de %s versos', v_unidad_min);
		elsif v_unidad_max > v_unidad_min then
			-- Una unidad de extensión variable no produce congruencia: solo su mínimo.
			return query
			select
				1,
				0,
				v_unidad_min,
				'unidad'::text,
				format('unidades de %s a %s versos', v_unidad_min, v_unidad_max);
		end if;
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
	where seccion.arquitectura_id = p_arquitectura_id
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
		where rima.arquitectura_id = p_arquitectura_id
			and rima.tipo_secuencia = 'ciclo'
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
		where metrico.arquitectura_id = p_arquitectura_id
			and metrico.tipo_secuencia = 'ciclo'
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
$regla$;

-- ---------------------------------------------------------------------------
-- Una posición respondida tiene que caber en la realización que la responde
-- ---------------------------------------------------------------------------
--
-- La copla de pie quebrado admite unidades de cinco a doce versos y ofrece cuarenta y ocho
-- opciones que cubren las doce posiciones, porque el catálogo no puede saber cuántos versos
-- tendrá cada copla. Nada impedía responder «el verso 11 es tetrasílabo» en una copla de
-- cinco, ni responder dos medidas distintas para la misma posición.
--
-- Es la única forma con unidad variable y opciones posicionales, así que es la única que
-- puede desbordar. La comprobación no cabe en el catálogo —ahí la unidad es un rango— y solo
-- es posible al guardar, cuando ya se sabe cuántos versos tiene esa realización.

create or replace function public.validar_posicion_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $validar$
declare
	v_posicion integer;
	v_versos integer;
	v_repetida integer;
begin
	select posicion_unidad into v_posicion
	from public.opciones_eleccion_metrica
	where opcion_eleccion_id = new.opcion_eleccion_id;

	if v_posicion is null or new.realizacion_prueba_id is null then
		return new;
	end if;

	select v_fin - v_ini + 1 into v_versos
	from public.realizaciones_editor_metrico
	where realizacion_prueba_id = new.realizacion_prueba_id;

	if v_versos is not null and v_posicion > v_versos then
		raise exception
			'La posición % no existe: la realización tiene % versos', v_posicion, v_versos;
	end if;

	select count(*) into v_repetida
	from public.elecciones_editor_metrico eleccion
	join public.opciones_eleccion_metrica opcion
		on opcion.opcion_eleccion_id = eleccion.opcion_eleccion_id
	where eleccion.realizacion_prueba_id = new.realizacion_prueba_id
		and eleccion.grupo_eleccion_id = new.grupo_eleccion_id
		and eleccion.eleccion_prueba_id is distinct from new.eleccion_prueba_id
		and opcion.posicion_unidad = v_posicion;

	if v_repetida > 0 then
		raise exception 'Ya hay una respuesta para la posición %', v_posicion;
	end if;

	return new;
end;
$validar$;

drop trigger if exists validar_posicion_eleccion on public.elecciones_editor_metrico;
create trigger validar_posicion_eleccion
	before insert or update on public.elecciones_editor_metrico
	for each row execute function public.validar_posicion_eleccion_editor_metrico();

commit;
