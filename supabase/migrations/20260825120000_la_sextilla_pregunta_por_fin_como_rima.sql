-- La sextilla pregunta por fin cómo rima
--
-- Paso 7b de B1, una de diez. Toca 6 arquitecturas: 2 con lista y salida abierta y 4 con solo campo abierto.
--
-- **La sextilla es la que abrió B1**, el 20 de agosto de 2026, y llevaba desde entonces sin poder
-- registrar lo que un editor tiene delante. El sexteto —el mismo caso a seis versos de arte mayor—
-- pregunta su esquema en sus tres arquitecturas; la sextilla no lo preguntaba en **ninguna de las
-- seis**, la principal incluida, y sin embargo el catálogo le guarda cuatro disposiciones.
--
-- Las dos que tienen repertorio lo ofrecen con salida abierta; las cuatro medidas que entraron el 22
-- de agosto no tienen ni una disposición catalogada, así que solo se escribe.
--
-- *Y con esto se completan las dos oncenas sin tocarlas.* Su miembro de seis reutiliza la sextilla
-- octosilábica y hereda su pregunta en cuanto existe.
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
	select forma_id into v_forma from public.formas_metricas where slug = 'sextilla' and activo;
	if v_forma is null then
		raise exception 'La forma «sextilla» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['octosilabica', 'opciones_y_esquema', '4'],
		array['pie_quebrado', 'opciones_y_esquema', '1'],
		array['heptasilabica', 'esquema_rima', '0'],
		array['hexasilabica', 'esquema_rima', '0'],
		array['pentasilabica', 'esquema_rima', '0'],
		array['tetrasilabica', 'esquema_rima', '0']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de sextilla no está activa.', v_par[1];
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
				true, true, 1, v_par[2], false, 'Seis versos de arte menor que la norma no obliga a disponer de una manera. Marca la disposición que leas, y si no está en la lista, escríbela.'
			);
		else
			update public.grupos_eleccion_metrica
			set tipo_control = v_par[2], ayuda_editor = coalesce(ayuda_editor, 'Seis versos de arte menor que la norma no obliga a disponer de una manera. Marca la disposición que leas, y si no está en la lista, escríbela.')
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
	if v_total <> 5 then
		raise exception 'Las preguntas de sextilla ofrecen % opciones, y se esperaban 5.', v_total;
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
		raise exception '% arquitecturas de sextilla siguen sin preguntar su rima.', v_n;
	end if;

	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('sextilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de sextilla ha dejado de responder.';
	end if;
end $$;

commit;
