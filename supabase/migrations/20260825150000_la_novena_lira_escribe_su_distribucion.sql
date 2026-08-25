-- La novena-lira escribe su distribución
--
-- Paso 7b de B1, cuatro de diez. Toca 1 arquitectura: 1 con solo campo abierto.
--
-- La novena-lira entró el 24 de agosto de 2026 al sistematizar la serie alirada de cuatro a diez, y
-- **nació con el hueco**: un patrón `distribucion-variable` sin restricciones, sin ninguna
-- disposición catalogada y sin pregunta. Era la única forma del catálogo que no decía absolutamente
-- nada de su rima ni dejaba decirlo.
--
-- Sus hermanas de la serie sí tienen disposición catalogada —el cuarteto-lira dos, la octava-lira
-- dos, la décima-lira una—, así que esta se queda con el campo abierto hasta que el corpus o las
-- fuentes den alguna.
--
-- **Las opciones no se crean: se derivan.** `opciones_eleccion_metrica` es una vista sobre
-- `opciones_eleccion_derivadas()`, que ofrece los esquemas concretos de la arquitectura —o los de la
-- que reutiliza la sección— y deja fuera los patrones abiertos. Crear la pregunta basta; la guarda
-- **consulta la vista** para comprobar que cada una sale con las opciones que le tocan, porque una
-- pregunta declarada y sin lista no está probada.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_par text[];
	v_n integer;
	v_total integer := 0;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'novena_lira' and activo;
	if v_forma is null then
		raise exception 'La forma «novena_lira» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['heterometrica_consonante', 'esquema_rima', '0']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de novena_lira no está activa.', v_par[1];
		end if;

		-- El repertorio vivo es el que la cabecera describe. Si alguien lo cambió, esta migración
		-- ofrecería otra cosa de la que dice ofrecer.
		select count(*) into v_n
		from public.esquemas_rima
		where arquitectura_id = v_arq
			and tipo_secuencia not in ('abierta', 'restricciones')
			and seccion_id is null;
		if v_n <> v_par[3]::integer then
			raise exception 'La arquitectura «%» tiene % disposiciones catalogadas, y se esperaban %.',
				v_par[1], v_n, v_par[3];
		end if;

		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and dimension = 'rima' and activo
		) then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
				permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
			)
			values (
				v_arq, 'esquema_rima', 'rima', 'unidad', 1, 1,
				true, true, 1, v_par[2], false, 'Nueve versos heterométricos de rima consonante y distribución variable. Escribe la que leas, con una letra por verso.'
			);
		else
			update public.grupos_eleccion_metrica
			set tipo_control = v_par[2], ayuda_editor = coalesce(ayuda_editor, 'Nueve versos heterométricos de rima consonante y distribución variable. Escribe la que leas, con una letra por verso.')
			where arquitectura_id = v_arq and dimension = 'rima' and activo;
		end if;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Ejecutando la vista, no leyendo el catálogo.
	for v_arq in
		select a.arquitectura_id from public.arquitecturas_forma a
		where a.forma_id = v_forma and a.activo
			and exists (
				select 1 from public.grupos_eleccion_metrica g
				where g.arquitectura_id = a.arquitectura_id and g.dimension = 'rima' and g.activo
			)
	loop
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.dimension = 'rima' and g.activo and o.activo;
		v_total := v_total + v_n;
	end loop;
	if v_total <> 0 then
		raise exception 'Las preguntas de novena_lira ofrecen % opciones, y se esperaban 0.', v_total;
	end if;

	-- Ninguna arquitectura de la forma se queda sin poder registrar su rima.
	select count(*) into v_n
	from public.arquitecturas_forma a
	where a.forma_id = v_forma and a.activo
		and not exists (
			select 1 from public.grupos_eleccion_metrica g
			where g.arquitectura_id = a.arquitectura_id and g.dimension = 'rima' and g.activo
		)

	;
	if v_n <> 0 then
		raise exception '% arquitecturas de novena_lira siguen sin preguntar su rima.', v_n;
	end if;

	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('novena_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de novena_lira ha dejado de responder.';
	end if;
end $$;

commit;
