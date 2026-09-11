-- La regla de longitud dice «un verso» cuando es uno
--
-- `regla_longitud_arquitectura_metrica` construye la cola de su explicación con un plural fijo:
-- «con un cierre opcional de %s versos». Mientras el único cierre opcional de extensión fija fue
-- el del terceto encadenado, de cuatro versos, no se notaba. Con el remate de un verso la frase
-- sale mal escrita, y esa frase se lee en tres sitios: la ficha de la forma, la pregunta que el
-- demarcador construye a partir de la regla y la caja del pasaje del editor.
--
-- Se reescribe entera porque un cuerpo entrecomillado no admite parches: es la misma función con
-- ese `format` partido en dos, y nada más.

begin;

CREATE OR REPLACE FUNCTION public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
 RETURNS TABLE(modulo_versos integer, residuo_versos integer, minimo_versos integer, origen text, explicacion text, desplazamientos integer[])
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
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
		v_opcionales integer[];
		v_desplazamientos integer[];
		v_opcional integer;
		v_cola text;
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
					format('unidades completas de %s versos', v_unidad_min),
					array[0];
			elsif v_unidad_max > v_unidad_min then
				-- Una unidad de extensión variable no produce congruencia: solo su mínimo.
				return query
				select
					1,
					0,
					v_unidad_min,
					'unidad'::text,
					format('unidades de %s a %s versos', v_unidad_min, v_unidad_max),
					array[0];
			end if;
			return;
		end if;

		-- Las secciones opcionales de extensión fija —cero o una vez, siempre los mismos versos—
		-- no impiden derivar la longitud: **la desplazan**. Se recogen aparte para sumarlas
		-- después, y dejan de contar como secciones no derivables, que es lo que en agosto de 2026
		-- tiró la rama entera al descartarlas.
		select coalesce(array_agg(seccion.versos_min order by seccion.orden), array[]::integer[])
		into v_opcionales
		from public.estructuras_secciones seccion
		where seccion.arquitectura_id = p_arquitectura_id
			and seccion.seccion_padre_id is null
			and seccion.versos_min is not null
			and seccion.versos_min = seccion.versos_max
			and coalesce(seccion.repeticiones_min, 0) = 0
			and seccion.repeticiones_max = 1;

		select
			count(*)::integer,
			count(*) filter (
				where seccion.versos_min is null
					or seccion.versos_max is null
					or seccion.versos_min <> seccion.versos_max
					or (
						seccion.repeticiones_max is not null
						and coalesce(seccion.repeticiones_min, 0) <> seccion.repeticiones_max
						and not (
							coalesce(seccion.repeticiones_min, 0) = 0
							and seccion.repeticiones_max = 1
						)
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

		-- Todos los totales que las partes opcionales pueden añadir, como sumas de subconjuntos.
		-- Con una sola parte son dos: sin ella y con ella.
		v_desplazamientos := array[0];
		foreach v_opcional in array v_opcionales loop
			select array_agg(distinct suma order by suma)
			into v_desplazamientos
			from (
				select unnest(v_desplazamientos) as suma
				union all
				select unnest(v_desplazamientos) + v_opcional
			) sumas;
		end loop;

		if cardinality(v_desplazamientos) = 1 then
			v_cola := '';
		elsif cardinality(v_desplazamientos) = 2 then
			v_cola := format(
				', con un cierre opcional de %s %s',
				v_desplazamientos[2],
				case when v_desplazamientos[2] = 1 then 'verso' else 'versos' end
			);
		else
			v_cola := format(
				', con cierres opcionales que suman %s versos',
				array_to_string(v_desplazamientos[2:], ', ')
			);
		end if;

		if v_total_secciones > 0 and v_secciones_no_derivables = 0 then
			if v_secciones_abiertas = 0 and v_longitud_minima > 1 then
				return query
				select
					v_longitud_minima,
					0,
					v_longitud_minima,
					'secciones_fijas'::text,
					format('estructuras completas de %s versos', v_longitud_minima) || v_cola,
					v_desplazamientos;
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
					end || v_cola,
					v_desplazamientos;
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
				format('ciclos completos de rima de %s versos', v_longitud_ciclo) || v_cola,
				v_desplazamientos;
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
				format('ciclos métricos completos de %s versos', v_longitud_ciclo) || v_cola,
				v_desplazamientos;
		end if;
	end;
	$function$;

do $guarda$
declare
	v_arq uuid;
	v_regla record;
begin
	-- La guarda ejecuta: se pide la regla de una arquitectura con cierre opcional de un verso y se
	-- lee la frase que devuelve.
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura endecasilábica del terceto encadenado.';
	end if;

	select * into v_regla from public.regla_longitud_arquitectura_metrica(v_arq) limit 1;

	if v_regla.explicacion not like '%cierre opcional de 1 verso' then
		raise exception 'La explicación sigue mal escrita. Dice: %', v_regla.explicacion;
	end if;
end
$guarda$;

commit;
