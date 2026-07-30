begin;

-- Bloque C de la migración estructural del dominio métrico.
--
-- Una forma define una unidad y la secuencia contiene N realizaciones de ella. Cuántas
-- hay se deriva del rango que el editor delimita; no se declara en ninguna parte. Hasta
-- ahora la extensión de esa unidad vivía en tres sitios distintos según la forma: en
-- `numero_versos` cuando era fija y la forma era estrofa o composición; en una sección
-- raíz cuando alguien la creó; y en ninguna parte para la lira, la octava real, el
-- terceto, la sexta rima y el pareado, que por eso no podían materializar sus unidades.
--
-- La arquitectura pasa a declarar el intervalo `unidad_versos_min` · `unidad_versos_max`
-- —fija cuando coinciden— y `numero_versos` desaparece absorbida. Con ella desaparece el
-- disparador que anulaba la extensión según el nivel estructural, que existía solo para
-- proteger un campo mal ubicado.
--
-- Las nueve secciones que solo servían para decir que la unidad se repite se retiran. No
-- eran filas muertas: ocho grupos de elección de alcance `unidad` colgaban de ellas y el
-- editor las usaba como ancla para materializar las unidades del pasaje. Por eso una
-- pregunta por unidad puede ahora no apuntar a ninguna sección, y una realización del
-- editor puede no realizar ninguna: la realización de la unidad no es la realización de
-- una sección.

-- ---------------------------------------------------------------------------
-- 1 · Fuera los disparadores que protegían el campo mal ubicado
--
-- Se retiran antes de tocar los datos: un cuerpo plpgsql es texto y sigue nombrando la
-- columna hasta que falla en ejecución.
-- ---------------------------------------------------------------------------

drop trigger if exists trigger_normalizar_numero_versos_configuracion
	on public.arquitecturas_forma;
drop trigger if exists trigger_normalizar_extensiones_al_cambiar_nivel_metrico
	on public.formas_metricas;
drop function if exists public.normalizar_extension_configuracion_metrica();
drop function if exists public.normalizar_extensiones_al_cambiar_nivel_metrico();

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura declara la extensión de la unidad
-- ---------------------------------------------------------------------------

alter table public.arquitecturas_forma
	add column unidad_versos_min integer,
	add column unidad_versos_max integer;

comment on column public.arquitecturas_forma.unidad_versos_min is
	'Extensión mínima de la unidad que define la forma. La unidad es fija cuando coincide con el máximo.';
comment on column public.arquitecturas_forma.unidad_versos_max is
	'Extensión máxima de la unidad que define la forma. Nula cuando la unidad no tiene extensión declarada, como en las series.';

update public.arquitecturas_forma
set unidad_versos_min = numero_versos,
	unidad_versos_max = numero_versos
where numero_versos is not null;

-- La copla de pie quebrado llevaba su intervalo de 5 a 12 versos en la sección fantasma,
-- que es justo lo que `numero_versos` no sabía expresar.
with unidad_en_seccion as (
	select
		seccion.arquitectura_id,
		min(seccion.versos_min) as versos_min,
		max(seccion.versos_max) as versos_max
	from public.estructuras_secciones seccion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = seccion.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.nivel_estructural <> 'serie'
	group by seccion.arquitectura_id
	having count(*) = 1
		and bool_and(seccion.seccion_padre_id is null)
		and bool_and(seccion.versos_min is not null and seccion.versos_max is not null)
)
update public.arquitecturas_forma arquitectura
set unidad_versos_min = unidad.versos_min,
	unidad_versos_max = unidad.versos_max
from unidad_en_seccion unidad
where unidad.arquitectura_id = arquitectura.arquitectura_id
	and arquitectura.unidad_versos_min is null;

-- Ninguna sección fantasma puede contradecir la extensión que ya declaraba la
-- arquitectura: si lo hiciera, retirarla perdería información.
do $$
declare
	v_conflicto text;
begin
	select string_agg(format('%s (%s–%s frente a %s)',
		arquitectura.slug, seccion.versos_min, seccion.versos_max, arquitectura.unidad_versos_min), ', ')
	into v_conflicto
	from public.estructuras_secciones seccion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = seccion.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.nivel_estructural <> 'serie'
		and seccion.seccion_padre_id is null
		and seccion.versos_min is not null
		and arquitectura.unidad_versos_min is not null
		and 1 = (
			select count(*)
			from public.estructuras_secciones hermana
			where hermana.arquitectura_id = seccion.arquitectura_id
		)
		and (
			seccion.versos_min is distinct from arquitectura.unidad_versos_min
			or seccion.versos_max is distinct from arquitectura.unidad_versos_max
		);

	if v_conflicto is not null then
		raise exception 'La sección de la unidad contradice la extensión declarada: %', v_conflicto;
	end if;
end;
$$;

alter table public.arquitecturas_forma
	drop column numero_versos;

alter table public.arquitecturas_forma
	add constraint arquitecturas_forma_unidad_versos_check check (
		(unidad_versos_min is null and unidad_versos_max is null)
		or (
			unidad_versos_min is not null
			and unidad_versos_max is not null
			and unidad_versos_min > 0
			and unidad_versos_max >= unidad_versos_min
		)
	);

-- ---------------------------------------------------------------------------
-- 3 · Fuera las nueve secciones que solo repetían la unidad
--
-- El criterio es el del informe de conformidad: única sección de su arquitectura, raíz y
-- sin partes internas, en una forma que no es una serie. En las series la sección
-- repetible sí describe el ritmo interno de la propia serie y se conserva.
-- ---------------------------------------------------------------------------

create temporary table secciones_de_la_unidad on commit drop as
select seccion.seccion_id
from public.estructuras_secciones seccion
join public.arquitecturas_forma arquitectura
	on arquitectura.arquitectura_id = seccion.arquitectura_id
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where forma.nivel_estructural <> 'serie'
	and seccion.seccion_padre_id is null
	and 1 = (
		select count(*)
		from public.estructuras_secciones hermana
		where hermana.arquitectura_id = seccion.arquitectura_id
	);

do $$
declare
	v_total integer;
begin
	select count(*) into v_total from secciones_de_la_unidad;
	if v_total <> 9 then
		raise exception 'Se esperaban 9 secciones que solo repiten la unidad y hay %', v_total;
	end if;
end;
$$;

-- Una pregunta por unidad puede referirse a la unidad entera y no a una parte suya.
update public.grupos_eleccion_metrica
set seccion_id = null
where seccion_id in (select seccion_id from secciones_de_la_unidad);

delete from public.estructuras_secciones
where seccion_id in (select seccion_id from secciones_de_la_unidad);

comment on table public.estructuras_secciones is
	'Partes del interior de la unidad, con extensión y repetición propias. Una sección no existe nunca para decir que la unidad se repite: eso se deriva del rango.';
comment on column public.grupos_eleccion_metrica.seccion_id is
	'Sección a la que se refiere la pregunta. Nula cuando el alcance es la unidad entera y no una de sus partes.';

-- ---------------------------------------------------------------------------
-- 4 · La realización de la unidad no es la realización de una sección
-- ---------------------------------------------------------------------------

alter table public.realizaciones_editor_metrico
	alter column seccion_id drop not null;

alter table public.realizaciones_editor_metrico
	add constraint realizaciones_editor_metrico_unidad_check check (
		seccion_id is not null or realizacion_padre_id is null
	);

comment on column public.realizaciones_editor_metrico.seccion_id is
	'Sección realizada. Nula cuando la realización es la de la unidad que define la forma, que no es parte de nada.';

-- ---------------------------------------------------------------------------
-- 5 · La regla de longitud deja de recorrer secciones para derivar el múltiplo
--
-- Cuando la arquitectura declara su unidad, el múltiplo es la unidad. El recorrido de
-- secciones se conserva para las series, donde la sección repetible describe el ritmo
-- interno de la propia serie y no hay unidad declarada.
-- ---------------------------------------------------------------------------

create or replace function public.regla_longitud_configuracion_metrica(p_configuracion_id uuid)
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
	select configuracion.unidad_versos_min, configuracion.unidad_versos_max
	into v_unidad_min, v_unidad_max
	from public.arquitecturas_forma configuracion
	where configuracion.arquitectura_id = p_configuracion_id
		and configuracion.activo;

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

comment on function public.regla_longitud_configuracion_metrica(uuid) is
	'Deriva la congruencia que debe cumplir la longitud inclusiva de una secuencia a partir de la unidad declarada. No duplica la norma del catálogo.';

-- ---------------------------------------------------------------------------
-- 6 · Las validaciones del editor dejan de emparejar la sección del grupo con la de la
--     unidad cuando la pregunta se refiere a la unidad entera
-- ---------------------------------------------------------------------------

create or replace function public.validar_unidad_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
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

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La unidad debe quedar dentro del rango de la secuencia';
	end if;

	-- Una realización sin sección es la realización de la unidad que define la forma.
	-- No es parte de nada y no puede colgar de ninguna otra.
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
		and arquitectura_id = v_configuracion_id;

	if not found then
		raise exception 'La sección de la unidad no pertenece a la arquitectura seleccionada';
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

		if not found then
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

create or replace function public.validar_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $_$
declare
	v_configuracion_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_padre_unidad uuid;
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
		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre_unidad, v_longitud_esperada
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;

		if v_seccion_grupo is null then
			-- La pregunta se refiere a la unidad entera, no a una de sus partes.
			if v_padre_unidad is not null then
				raise exception 'La pregunta se refiere a la unidad y no a una de sus partes';
			end if;
		elsif v_seccion_grupo is distinct from v_seccion_unidad then
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

-- Cuando la arquitectura declara su unidad, cuántas realizaciones raíz hay lo gobierna el
-- rango de la secuencia y no la repetición declarada en la sección.
create or replace function public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid)
returns void
language plpgsql
set search_path to 'public'
as $$
declare
	v_configuracion_id uuid;
	v_unidad_declarada boolean;
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

	select unidad_versos_min is not null
	into v_unidad_declarada
	from public.arquitecturas_forma
	where arquitectura_id = v_configuracion_id;

	if not coalesce(v_unidad_declarada, false) then
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
	end if;

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

-- ---------------------------------------------------------------------------
-- 7 · El guardado admite realizaciones sin sección y preguntas sin sección
-- ---------------------------------------------------------------------------

create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
returns uuid
language plpgsql
security definer
set search_path to 'public'
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
			nullif(v_item ->> 'seccion_id', '')::uuid,
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

	-- Una pregunta sin sección se aplica a la unidad entera, que es la realización que no
	-- cuelga de ninguna otra.
	for v_grupo in
		select grupo.*, unidad.realizacion_prueba_id
		from public.realizaciones_editor_metrico unidad
		join public.grupos_eleccion_metrica grupo
			on grupo.arquitectura_id = (p_datos ->> 'arquitectura_id')::uuid
			and grupo.activo
			and grupo.alcance = 'unidad'
			and (
				(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
				or grupo.seccion_id = unidad.seccion_id
			)
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

update public.catalogo_metrico_estado
set modelo_version = 45,
	actualizado_en = now()
where id = true;

commit;
