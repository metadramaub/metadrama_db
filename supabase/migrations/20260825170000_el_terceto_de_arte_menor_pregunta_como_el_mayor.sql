-- El terceto de arte menor pregunta como el mayor
--
-- Paso 7b de B1, seis de diez. Toca 2 arquitecturas: 2 con lista y salida abierta.
--
-- **La incoherencia más visible del catálogo, y en la misma forma.** El terceto endecasilábico
-- pregunta su disposición entre dos opciones desde que se creó; el octosilábico y el hexasilábico
-- tienen **cuatro cada uno** —monorrimo consonante, monorrimo asonante, primer verso suelto y verso
-- central suelto— y no preguntaban nada. Dos arquitecturas de la misma forma, con más repertorio que
-- su hermana, resolviendo el mismo hecho de dos maneras.
--
-- Las dos entraron el 22 de agosto de 2026 con el tercetillo, y la pregunta se quedó por el camino.
--
-- *Ojo a un detalle que la regla 3 bis explica:* el monorrimo consonante y el asonante comparten
-- notación `aaa` y solo se separan por el régimen, igual que los dos de la octava aguda. La lista los
-- distingue porque la etiqueta derivada añade el régimen cuando la arquitectura no declara uno
-- solo.
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
	select forma_id into v_forma from public.formas_metricas where slug = 'terceto' and activo;
	if v_forma is null then
		raise exception 'La forma «terceto» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['octosilabica', 'opciones_y_esquema', '4'],
		array['hexasilabica', 'opciones_y_esquema', '4']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de terceto no está activa.', v_par[1];
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
				true, true, 1, v_par[2], false, 'Tres versos que pueden ir monorrimos, con el primero suelto o con el central suelto. Marca lo que leas; si es otra cosa, escríbela.'
			);
		else
			update public.grupos_eleccion_metrica
			set tipo_control = v_par[2], ayuda_editor = coalesce(ayuda_editor, 'Tres versos que pueden ir monorrimos, con el primero suelto o con el central suelto. Marca lo que leas; si es otra cosa, escríbela.')
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
	if v_total <> 10 then
		raise exception 'Las preguntas de terceto ofrecen % opciones, y se esperaban 10.', v_total;
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
		raise exception '% arquitecturas de terceto siguen sin preguntar su rima.', v_n;
	end if;

	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('terceto') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de terceto ha dejado de responder.';
	end if;
end $$;

commit;
