-- Un control de esquema vale también para el metro
--
-- Hasta hoy el editor podía **escribir la disposición de rima que veía** cuando el catálogo no la
-- tenía —lo abrió B1, con `esquema_rima` y `opciones_y_esquema`—, pero no podía escribir **las
-- medidas**. Los veintisiete grupos de metro del catálogo entero eran `opciones` cerradas, y el
-- validador exigía expresamente que un control de esquema fuera de la dimensión de rima.
--
-- Eso deja sin registrar lo que el IP quiere que se registre. Las formas aliradas nuevas —cuarteto,
-- septeto, octava, novena y décima-lira— se dejaron **abiertas de metro y de rima** a propósito,
-- porque todavía no se sabe qué hay en el corpus y la base es donde se va a documentar. Un editor
-- que vea `11 7 7 11` en un cuarteto-lira no tenía dónde ponerlo.
--
-- **Esta migración solo abre la puerta**: añade el valor `esquema_metrico`, deja que el híbrido
-- sirva a las dos dimensiones, y hace que la guarda diga de cada control a qué dimensión pertenece.
-- Las preguntas de cada forma van aparte, una migración por forma.
--
-- *La función se copia de su definición viva y solo se le cambia ese bloque.* Lo demás que valida
-- —el alcance, la sección, el rasgo— no tiene nada que ver con esto.

begin;

do $$
declare
	v_grupo_id uuid;
	v_arquitectura_id uuid;
	v_error text;
begin
	-- ------------------------------------------------------------------ Antes de tocar nada
	if to_regprocedure('public.validar_grupo_eleccion_metrica()') is null then
		raise exception 'No está la guarda de los grupos de elección.';
	end if;
	if exists (
		select 1 from pg_constraint
		where conrelid = 'public.grupos_eleccion_metrica'::regclass
			and conname = 'grupos_eleccion_metrica_tipo_control_check'
			and pg_get_constraintdef(oid) like '%esquema_metrico%'
	) then
		raise exception 'El control de esquema métrico ya está admitido.';
	end if;

	alter table public.grupos_eleccion_metrica
		drop constraint grupos_eleccion_metrica_tipo_control_check;
	alter table public.grupos_eleccion_metrica
		add constraint grupos_eleccion_metrica_tipo_control_check
		check (tipo_control in ('opciones', 'esquema_rima', 'esquema_metrico', 'opciones_y_esquema'));

	create or replace function public.validar_grupo_eleccion_metrica()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
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

		-- Los dos controles que ofrecen escribir un esquema hablan siempre de rima, y una unidad
		-- rima de una sola manera. Lo que los separa es el mínimo: el abierto exige respuesta y el
		-- híbrido admite dejarla en blanco, porque el esquema catalogado se marca solo si es el que
		-- se ha visto.
		if new.tipo_control in ('esquema_rima', 'esquema_metrico', 'opciones_y_esquema') then
			-- **Un control de esquema vale para las dos dimensiones que tienen esquema.** Hasta hoy
			-- solo valía para la rima, y por eso un editor podía escribir la disposición que veía
			-- pero no las medidas. El valor del control dice qué clase de esquema se escribe y la
			-- dimensión tiene que decir lo mismo; el híbrido sirve a las dos.
			if new.tipo_control = 'esquema_rima' and new.dimension <> 'rima' then
				raise exception 'Un control de esquema de rima pertenece a la dimensión de rima';
			end if;
			if new.tipo_control = 'esquema_metrico' and new.dimension <> 'metro' then
				raise exception 'Un control de esquema métrico pertenece a la dimensión de metro';
			end if;
			if new.tipo_control = 'opciones_y_esquema' and new.dimension not in ('rima', 'metro') then
				raise exception 'Un control híbrido pertenece a la dimensión de rima o de metro';
			end if;
			if new.selecciones_max <> 1 then
				raise exception 'Un control de esquema admite una sola respuesta';
			end if;
		end if;

		if new.tipo_control in ('esquema_rima', 'esquema_metrico') and new.selecciones_min <> 1 then
			raise exception 'Un control de esquema abierto necesita exactamente una respuesta';
		end if;

		return new;
	end;
	$function$
;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Una función SQL no está probada hasta que se ejecuta**, y una guarda menos: su cuerpo no se
	-- revalida al reemplazarla. Se prueban los tres caminos sobre una arquitectura de verdad, y se
	-- deshace lo escrito.

	select arquitectura_id into v_arquitectura_id
	from public.arquitecturas_forma where activo limit 1;
	if v_arquitectura_id is null then
		raise exception 'No hay ninguna arquitectura donde comprobarlo.';
	end if;

	-- 1 · Un control de esquema métrico en la dimensión de metro: entra.
	insert into public.grupos_eleccion_metrica
		(arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min, selecciones_max,
		 activo, orden)
	values (v_arquitectura_id, 'prueba-migracion-metro', 'metro', 'unidad', 'esquema_metrico',
		1, 1, false, 9999)
	returning grupo_eleccion_id into v_grupo_id;

	-- 2 · El mismo control en la dimensión de rima: se rechaza.
	begin
		insert into public.grupos_eleccion_metrica
			(arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min,
			 selecciones_max, activo, orden)
		values (v_arquitectura_id, 'prueba-migracion-mal', 'rima', 'unidad', 'esquema_metrico',
			1, 1, false, 9998);
		raise exception 'La guarda ha admitido un esquema métrico en la dimensión de rima.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%pertenece a la dimensión de metro%' then
			raise exception 'La guarda ha fallado por otra razón: %', v_error;
		end if;
	end;

	-- 3 · Y el híbrido sí vale en metro, que es lo que esto viene a permitir.
	insert into public.grupos_eleccion_metrica
		(arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min, selecciones_max,
		 activo, orden)
	values (v_arquitectura_id, 'prueba-migracion-hibrido', 'metro', 'unidad', 'opciones_y_esquema',
		1, 1, false, 9997);

	delete from public.grupos_eleccion_metrica
	where slug in ('prueba-migracion-metro', 'prueba-migracion-mal', 'prueba-migracion-hibrido');

	-- Y la rima sigue funcionando como funcionaba: quedan los grupos que ya había.
	if (select count(*) from public.grupos_eleccion_metrica
		where tipo_control in ('esquema_rima', 'opciones_y_esquema') and dimension = 'rima') = 0
	then
		raise exception 'No queda ningún control de esquema de rima; algo se ha llevado por delante.';
	end if;
end $$;

commit;
