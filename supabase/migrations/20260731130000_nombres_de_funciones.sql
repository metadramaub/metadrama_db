begin;

-- Los nombres de las funciones hablan también el vocabulario de la ontología.
--
-- El bloque D tradujo restricciones, índices, políticas y disparadores, pero dejó fuera las
-- funciones: renombrarlas obliga a recrear la vista de reglas de longitud y a cambiar el
-- nombre de un parámetro que la ruta de API pasa por su nombre. Se hace aquí.
--
-- Al releer los cuerpos apareció además un resto del bloque A que nadie había ejecutado:
-- `sincronizar_posiciones_patron_rima_fijo` seguía leyendo `new.esquema`, la columna que
-- aquel bloque renombró a `notacion`. El disparador se dispara al insertar o actualizar un
-- esquema de rima, así que cualquier alta de un esquema `secuencia_fija` habría fallado con
-- «record "new" has no field "esquema"». Desde el bloque A no se ha dado de alta ninguno,
-- y por eso no se notó.

-- ---------------------------------------------------------------------------
-- 1 · La regla de longitud es de la arquitectura
-- ---------------------------------------------------------------------------

drop view public.arquitecturas_reglas_longitud;
drop function public.regla_longitud_configuracion_metrica(uuid);

create function public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
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
as $$
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
		where metrico.arquitectura_id = p_arquitectura_id
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

comment on function public.regla_longitud_arquitectura_metrica(uuid) is
	'Deriva la congruencia que debe cumplir la longitud inclusiva de una secuencia a partir de la unidad declarada. No duplica la norma del catálogo.';

create view public.arquitecturas_reglas_longitud with (security_invoker = true) as
select
	arquitectura.arquitectura_id,
	arquitectura.nombre as arquitectura_nombre,
	regla.modulo_versos,
	regla.residuo_versos,
	regla.minimo_versos,
	regla.origen,
	regla.explicacion
from public.arquitecturas_forma arquitectura
cross join lateral public.regla_longitud_arquitectura_metrica(arquitectura.arquitectura_id) regla
where arquitectura.activo;

comment on view public.arquitecturas_reglas_longitud is
	'Reglas de compatibilidad de longitud derivadas para el registrador de secuencias.';

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura principal de una forma
-- ---------------------------------------------------------------------------

drop function public.marcar_configuracion_metrica_principal(uuid);

create function public.marcar_arquitectura_metrica_principal(p_arquitectura_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
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
	where arquitectura_id = p_arquitectura_id
	for update;

	if v_forma_id is null then
		raise exception 'Arquitectura métrica no encontrada'
			using errcode = 'P0002';
	end if;

	update public.arquitecturas_forma
	set principal = arquitectura_id = p_arquitectura_id
	where forma_id = v_forma_id
		and activo;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Un tramo sin forma no tiene arquitectura, dicho desde los dos lados
-- ---------------------------------------------------------------------------

drop trigger trigger_validar_arquitectura_forma_no_editorial on public.arquitecturas_forma;
drop function public.validar_configuracion_forma_no_editorial();

create function public.validar_arquitectura_de_forma_con_norma()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
	if exists (
		select 1
		from public.formas_metricas
		where forma_id = new.forma_id
			and tipo_registro = 'sin_forma'
	) then
		raise exception 'Un tramo sin forma no puede tener arquitecturas normativas';
	end if;
	return new;
end;
$$;

create trigger trigger_validar_arquitectura_de_forma_con_norma
	before insert or update of forma_id on public.arquitecturas_forma
	for each row execute function public.validar_arquitectura_de_forma_con_norma();

drop trigger trigger_validar_forma_salida_editorial on public.formas_metricas;
drop function public.validar_forma_salida_editorial();

create function public.validar_tramo_sin_forma_sin_arquitectura()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
	if new.tipo_registro = 'sin_forma' and exists (
		select 1
		from public.arquitecturas_forma
		where forma_id = new.forma_id
	) then
		raise exception 'Un tramo sin forma no puede tener arquitecturas normativas';
	end if;
	return new;
end;
$$;

create trigger trigger_validar_tramo_sin_forma_sin_arquitectura
	before insert or update of tipo_registro on public.formas_metricas
	for each row execute function public.validar_tramo_sin_forma_sin_arquitectura();

-- ---------------------------------------------------------------------------
-- 4 · Las posiciones de un esquema de rima fijo se derivan de su notación
--
-- El cuerpo seguía nombrando `esquema`, que el bloque A renombró a `notacion`.
-- ---------------------------------------------------------------------------

drop trigger esquemas_rima_sincronizar_posiciones_fijas on public.esquemas_rima;
drop function public.sincronizar_posiciones_patron_rima_fijo();

create function public.sincronizar_posiciones_esquema_rima_fijo()
returns trigger
language plpgsql
set search_path to 'public'
as $_$
declare
	v_posicion integer;
	v_clase text;
begin
	if new.comportamiento <> 'secuencia_fija'
		or new.notacion is null
		or new.notacion !~ '^[A-Za-z-]+$'
	then
		return new;
	end if;

	delete from public.esquema_rima_posiciones
	where esquema_rima_id = new.esquema_rima_id;

	for v_posicion in 1..char_length(new.notacion) loop
		v_clase := substring(new.notacion from v_posicion for 1);

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

comment on function public.sincronizar_posiciones_esquema_rima_fijo() is
	'Convierte automáticamente una notación fija simple, como ababa o -a-a, en posiciones computables. Los esquemas complejos continúan editándose mediante sus posiciones.';

create trigger esquemas_rima_sincronizar_posiciones_fijas
	after insert or update of notacion, comportamiento on public.esquemas_rima
	for each row execute function public.sincronizar_posiciones_esquema_rima_fijo();

-- ---------------------------------------------------------------------------
-- 5 · Una variedad empareja esquemas de su misma arquitectura
-- ---------------------------------------------------------------------------

drop trigger trigger_variedades_arquitectura_validar on public.variedades_arquitectura;
drop function public.validar_combinacion_patrones_configuracion();

create function public.validar_variedad_arquitectura()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
	v_arquitectura_metrica_id uuid;
	v_arquitectura_rima_id uuid;
begin
	select arquitectura_id into v_arquitectura_metrica_id
	from public.esquemas_metricos
	where esquema_metrico_id = new.esquema_metrico_id;

	select arquitectura_id into v_arquitectura_rima_id
	from public.esquemas_rima
	where esquema_rima_id = new.esquema_rima_id;

	if v_arquitectura_metrica_id is distinct from new.arquitectura_id
		or v_arquitectura_rima_id is distinct from new.arquitectura_id
	then
		raise exception
			'Los esquemas de la variedad deben pertenecer a su misma arquitectura';
	end if;

	return new;
end;
$$;

create trigger trigger_variedades_arquitectura_validar
	before insert or update on public.variedades_arquitectura
	for each row execute function public.validar_variedad_arquitectura();

-- ---------------------------------------------------------------------------
-- 6 · La realización, no la unidad: el disparador valida cualquier realización
-- ---------------------------------------------------------------------------

drop trigger trigger_validar_unidad_editor_metrico on public.realizaciones_editor_metrico;
drop function public.validar_unidad_editor_metrico();

create function public.validar_realizacion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
	v_arquitectura_id uuid;
	v_secuencia_ini integer;
	v_secuencia_fin integer;
	v_seccion_padre_esperada uuid;
	v_seccion_padre_real uuid;
	v_padre_ini integer;
	v_padre_fin integer;
begin
	select arquitectura_id, v_ini, v_fin
	into v_arquitectura_id, v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La realización debe quedar dentro del rango de la secuencia';
	end if;

	-- Una realización sin sección es la realización de la unidad que define la forma.
	if new.seccion_id is null then
		if new.realizacion_padre_id is not null then
			raise exception 'La realización de la unidad no cuelga de ninguna otra';
		end if;
		return new;
	end if;

	select seccion_padre_id
	into v_seccion_padre_esperada
	from public.estructuras_secciones
	where seccion_id = new.seccion_id
		and arquitectura_id = v_arquitectura_id;

	if not found then
		raise exception 'La sección realizada no pertenece a la arquitectura seleccionada';
	end if;

	if new.realizacion_padre_id is null then
		raise exception 'Una sección se realiza siempre dentro de una unidad';
	end if;

	select seccion_id, v_ini, v_fin
	into v_seccion_padre_real, v_padre_ini, v_padre_fin
	from public.realizaciones_editor_metrico
	where realizacion_prueba_id = new.realizacion_padre_id
		and secuencia_prueba_id = new.secuencia_prueba_id;

	if not found then
		raise exception 'La realización superior debe pertenecer a la misma secuencia';
	end if;
	-- Una sección raíz cuelga de la unidad, cuya realización no tiene sección; una sección
	-- interna cuelga de la realización de su sección superior.
	if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
		raise exception 'La realización superior no corresponde a la jerarquía de la sección';
	end if;
	if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
		raise exception 'La sección interna debe quedar dentro del rango de su unidad';
	end if;

	return new;
end;
$$;

create trigger trigger_validar_realizacion_editor_metrico
	before insert or update on public.realizaciones_editor_metrico
	for each row execute function public.validar_realizacion_editor_metrico();

-- Los permisos de las funciones nuevas replican los de las que sustituyen.
grant all on function public.regla_longitud_arquitectura_metrica(uuid) to anon, authenticated, service_role;
grant all on function public.marcar_arquitectura_metrica_principal(uuid) to anon, authenticated, service_role;
grant all on function public.validar_arquitectura_de_forma_con_norma() to anon, authenticated, service_role;
grant all on function public.validar_tramo_sin_forma_sin_arquitectura() to anon, authenticated, service_role;
grant all on function public.sincronizar_posiciones_esquema_rima_fijo() to anon, authenticated, service_role;
grant all on function public.validar_variedad_arquitectura() to anon, authenticated, service_role;
grant all on function public.validar_realizacion_editor_metrico() to anon, authenticated, service_role;

grant all on table public.arquitecturas_reglas_longitud to anon, authenticated, service_role;

-- La ruta de API invoca `marcar_arquitectura_metrica_principal` por su nombre, así que
-- código y base vuelven a tener que entrar juntos.
update public.catalogo_metrico_estado
set modelo_version = 48,
	actualizado_en = now()
where id = true;

commit;
