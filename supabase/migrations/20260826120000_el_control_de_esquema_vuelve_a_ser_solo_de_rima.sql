-- El control de esquema vuelve a ser solo de rima
--
-- Deshace `20260826110000`, que **no debí aplicar**: ni estaba aprobada ni resolvía nada.
--
-- La aplicé para que un editor pudiera escribir a mano el esquema métrico de una estrofa alirada,
-- porque cuatro arquitecturas —cuarteto, octava, novena y décima-lira— admiten endecasílabos y
-- heptasílabos sin decir en qué orden, y no preguntan cuál se ve. El hueco es real. **La salida era
-- falsa**, y el catálogo ya tenía la buena.
--
-- El **pareado alirado** la enseña: pregunta `medida_del_pareado` con `selecciones 2-2`, y la
-- derivación produce una opción por verso y medida —«Verso 1 · Heptasílabo», «Verso 1 ·
-- Endecasílabo», «Verso 2 · …»—, cada una con su `posicion_unidad`. La respuesta queda
-- **descompuesta por posición**, que es lo que hace falta para contar, comparar y, cuando una
-- disposición resulte frecuente, incorporarla al catálogo. Escribirla a mano la habría guardado
-- como una cadena.
--
-- Las cuatro aliradas tienen la unidad de extensión fija —4, 8, 9 y 10 versos—, así que lo que les
-- falta son **cuatro filas** en `grupos_eleccion_metrica` copiando esa forma. Ningún control nuevo.
--
-- *Censo que lo sostiene, contado sobre las 71 arquitecturas con unidad:* **50** fijan la medida por
-- posiciones y no tienen nada que preguntar; **10** son de pie quebrado y las diez preguntan; **11**
-- declaran solo un repertorio, y de esas **siete ya preguntan** —el pareado alirado, las dos
-- canciones, el villancico y el zéjel parte por parte— y cuatro no.
--
-- *La función se copia de su definición viva y se le deshacen las dos ediciones.* Lo demás que
-- valida no se toca.

begin;

do $$
declare
	v_error text;
	v_arquitectura_id uuid;
begin
	-- ------------------------------------------------------------------ Antes de tocar nada
	if not exists (
		select 1 from pg_constraint
		where conrelid = 'public.grupos_eleccion_metrica'::regclass
			and conname = 'grupos_eleccion_metrica_tipo_control_check'
			and pg_get_constraintdef(oid) like '%esquema_metrico%'
	) then
		raise exception 'El control de esquema métrico ya no está admitido; no hay nada que deshacer.';
	end if;

	-- **Nadie puede estar usándolo.** Si alguien lo usara, quitarlo dejaría filas fuera de la
	-- restricción, y esto dejaría de ser una vuelta atrás para ser una pérdida.
	if exists (select 1 from public.grupos_eleccion_metrica where tipo_control = 'esquema_metrico') then
		raise exception 'Hay grupos con el control nuevo: revísalos antes de deshacerlo.';
	end if;

	alter table public.grupos_eleccion_metrica
		drop constraint grupos_eleccion_metrica_tipo_control_check;
	alter table public.grupos_eleccion_metrica
		add constraint grupos_eleccion_metrica_tipo_control_check
		check (tipo_control in ('opciones', 'esquema_rima', 'opciones_y_esquema'));

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
		if new.tipo_control in ('esquema_rima', 'opciones_y_esquema') then
			if new.dimension <> 'rima' then
				raise exception 'Un control de esquema debe pertenecer a la dimensión de rima';
			end if;
			if new.selecciones_max <> 1 then
				raise exception 'Un control de esquema admite una sola respuesta';
			end if;
		end if;

		if new.tipo_control = 'esquema_rima' and new.selecciones_min <> 1 then
			raise exception 'Un control de esquema abierto necesita exactamente una respuesta';
		end if;

		return new;
	end;
	$function$
;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- La guarda se ejecuta, que un cuerpo entrecomillado no se revalida al reemplazarlo.

	select arquitectura_id into v_arquitectura_id
	from public.arquitecturas_forma where activo limit 1;
	if v_arquitectura_id is null then
		raise exception 'No hay ninguna arquitectura donde comprobarlo.';
	end if;

	-- 1 · El valor retirado ya no entra.
	begin
		insert into public.grupos_eleccion_metrica
			(arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min,
			 selecciones_max, activo, orden)
		values (v_arquitectura_id, 'prueba-revertir', 'metro', 'unidad', 'esquema_metrico',
			1, 1, false, 9999);
		raise exception 'La restricción sigue admitiendo el control retirado.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%tipo_control_check%' then
			raise exception 'Ha fallado por otra razón: %', v_error;
		end if;
	end;

	-- 2 · Y la rima vuelve a comportarse como antes: un híbrido en metro se rechaza otra vez.
	begin
		insert into public.grupos_eleccion_metrica
			(arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min,
			 selecciones_max, activo, orden)
		values (v_arquitectura_id, 'prueba-revertir-2', 'metro', 'unidad', 'opciones_y_esquema',
			1, 1, false, 9998);
		raise exception 'La guarda sigue admitiendo un control de esquema fuera de la rima.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%dimensión de rima%' then
			raise exception 'Ha fallado por otra razón: %', v_error;
		end if;
	end;

	-- 3 · Y lo que siempre valió, sigue valiendo.
	if (select count(*) from public.grupos_eleccion_metrica
		where tipo_control in ('esquema_rima', 'opciones_y_esquema') and dimension = 'rima') = 0
	then
		raise exception 'No queda ningún control de esquema de rima.';
	end if;

	delete from public.grupos_eleccion_metrica where slug like 'prueba-revertir%';
end $$;

commit;
