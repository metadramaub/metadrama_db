-- El septeto pregunta por sus agudos
--
-- Paso 8b, cuatro de cuatro de B2. Toca 2 arquitecturas, que ganan una casilla sobre un rasgo que ya declaran.
--
-- Las dos arquitecturas del septeto declaran `final_acentual: agudo` como **admitida**, con techo de
-- tres posiciones —es lo que la tradición llama *septeto agudo*, y así entró el 21 de agosto de
-- 2026—, y ninguna lo preguntaba.
--
-- Casilla y no posiciones, por la misma razón que en el sexteto alejandrino: lo que el editor no
-- puede deducir es si el pasaje los trae. Aquí, además, el septeto endecasilábico **no declara
-- ninguna disposición**, así que no hay esquema del que leer dónde caen; el techo de tres queda como
-- lo que la norma admite, no como una lista que recorrer.
--
-- *Las dos arquitecturas llevan la misma casilla: el rasgo es de la forma, no de la medida.*
--
-- **La opción no se crea: se deriva.** `opciones_eleccion_metrica` es una vista, y la rama de rasgo
-- ofrece los valores que la arquitectura declara en `arquitectura_rasgos`. Crear la pregunta basta,
-- y la guarda **consulta la vista** para comprobar que sale con la suya.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_par text[];
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'septeto' and activo;
	if v_forma is null then
		raise exception 'La forma «septeto» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['endecasilabica', 'final_acentual', 'agudo', 'admitida'],
		array['compuesta', 'final_acentual', 'agudo', 'admitida']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de septeto no está activa.', v_par[1];
		end if;

		select rasgo_id into v_rasgo from public.rasgos_metricos where slug = v_par[2] and activo;
		if v_rasgo is null then
			raise exception 'El rasgo «%» no está activo.', v_par[2];
		end if;

		-- Lo que la arquitectura declara es lo que la cabecera dice, con su valor y su modalidad.
		-- Si alguien lo cambió, esta pregunta ofrecería otra cosa de la que anuncia.
		select count(*) into v_n
		from public.arquitectura_rasgos ar
		join public.rasgo_valores rv on rv.valor_id = ar.valor_id
		where ar.arquitectura_id = v_arq and ar.rasgo_id = v_rasgo
			and rv.slug = v_par[3] and ar.modalidad = v_par[4];
		if v_n <> 1 then
			raise exception 'La arquitectura «%» no declara «%» como % (% filas).',
				v_par[1], v_par[3], v_par[4], v_n;
		end if;

		-- Y la norma no lo fija: si todas sus filas fueran definitorias, no habría nada que
		-- preguntar. Es la regla 4 del § 3.6, comprobada sobre el dato.
		select count(*) into v_n
		from public.arquitectura_rasgos ar
		where ar.arquitectura_id = v_arq and ar.rasgo_id = v_rasgo
			and ar.modalidad <> 'definitoria';
		if v_n = 0 then
			raise exception 'El rasgo «%» está fijado por la norma en «%»: no se pregunta.',
				v_par[2], v_par[1];
		end if;

		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and rasgo_id = v_rasgo and activo
		) then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
				permite_aplicar_global, activo, orden, tipo_control, define_norma, rasgo_id,
				ayuda_editor
			)
			values (
				v_arq, 'final_acentual_destacado', 'rasgo', 'secuencia', 0, 1,
				false, true, 2, 'opciones', false, v_rasgo,
				'Márcalo si el pasaje trae los finales agudos que la tradición llama septeto agudo.'
			);
		end if;

		-- La pregunta sale con su valor. Ejecutando la vista, no leyendo el catálogo.
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.rasgo_id = v_rasgo and g.activo and o.activo;
		if v_n <> 1 then
			raise exception 'La pregunta de «%» en «%» ofrece % opciones, y debía ofrecer una.',
				v_par[2], v_par[1], v_n;
		end if;

		-- Se pregunta, y se deja no contestar: marcarla o dejarla vacía **es** la respuesta.
		select count(*) into v_n
		from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq and rasgo_id = v_rasgo and activo
			and (selecciones_min <> 0 or selecciones_max <> 1 or alcance <> 'secuencia');
		if v_n <> 0 then
			raise exception 'La pregunta de «%» en «%» no es una casilla del pasaje.', v_par[2], v_par[1];
		end if;
	end loop;

	-- Lo que la forma declara no ha cambiado: ni una fila de rasgo se ha tocado.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_forma and ar.updated_at > now() - interval '1 minute';
	if v_n <> 0 then
		raise exception '% rasgos de septeto se han modificado, y no debía moverse ninguno.', v_n;
	end if;

	if public.get_forma_metrica_publica('septeto') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de septeto ha dejado de responder.';
	end if;
end $$;

commit;
