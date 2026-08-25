-- El sexteto alejandrino pregunta por sus agudos
--
-- Paso 8b, tres de cuatro de B2. Toca 1 arquitectura, que gana una casilla sobre un rasgo que ya declara.
--
-- El sexteto alejandrino declara `final_acentual: agudo` como **habitual**, con techo de dos
-- posiciones, y no lo preguntaba. Es el tercero de los cuatro repartos sin criterio que B2
-- inventarió: el final acentual se preguntaba en cinco arquitecturas y no en esta.
--
-- **Y va como casilla, no por posiciones.** La regla 5 del § 3.6 dice que un rasgo posicional se
-- pregunta por posiciones **solo si el esquema no dice ya dónde cae**, y aquí lo dice: los agudos
-- son la clase `b` de su `AABCCB`, versos tercero y sexto. Preguntar dónde caen modelaría el mismo
-- hecho dos veces. Lo que el editor no puede deducir es *si* el pasaje los trae, porque es habitual
-- y no definitorio.
--
-- *`posiciones_max` se queda en dos: sigue siendo verdad que la norma admite hasta dos agudos,
-- aunque la pregunta no los recorra.*
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
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto' and activo;
	if v_forma is null then
		raise exception 'La forma «sexteto» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['alejandrina', 'final_acentual', 'agudo', 'habitual']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de sexteto no está activa.', v_par[1];
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
				'Márcalo si los versos que cierran cada mitad terminan en palabra aguda.'
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
		raise exception '% rasgos de sexteto se han modificado, y no debía moverse ninguno.', v_n;
	end if;

	if public.get_forma_metrica_publica('sexteto') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de sexteto ha dejado de responder.';
	end if;
end $$;

commit;
