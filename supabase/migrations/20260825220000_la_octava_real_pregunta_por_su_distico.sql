-- La octava real pregunta por su dístico
--
-- Paso 8a, una de cuatro de B2. Toca 1 arquitectura, que gana una casilla sobre un rasgo que ya declara.
--
-- **El caso que abrió B2.** El endecasílabo suelto declara `distico_final` como habitual y lo
-- pregunta desde que se creó; la octava real lo declara **con la misma modalidad** y no lo
-- preguntaba. Dos formas, el mismo rasgo, el mismo grado, y dos tratamientos.
--
-- Por la regla 4 de [criterios de nivel § 3.6](../../docs/dominio-metrico/criterios-de-nivel.md) —un
-- rasgo se pregunta si y solo si la norma no lo fija—, `habitual` se pregunta. La octava real ya
-- tenía su casilla del final esdrújulo; ahora tiene también la del dístico, que es lo que su propia
-- descripción viene diciendo.
--
-- *Nada de lo que la forma declara cambia: el rasgo sigue siendo habitual y con el mismo valor.
-- Cambia que se pueda decir si el pasaje lo trae.*
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
	select forma_id into v_forma from public.formas_metricas where slug = 'octava_real' and activo;
	if v_forma is null then
		raise exception 'La forma «octava_real» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['endecasilabica_consonante', 'distico_final', 'presente', 'habitual']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de octava_real no está activa.', v_par[1];
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
				v_arq, 'distico_final', 'rasgo', 'secuencia', 0, 1,
				false, true, 2, 'opciones', false, v_rasgo,
				'El pareado final que cierra la estrofa. La norma lo da por habitual, no por seguro: márcalo si lo lees.'
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
		raise exception '% rasgos de octava_real se han modificado, y no debía moverse ninguno.', v_n;
	end if;

	if public.get_forma_metrica_publica('octava_real') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de octava_real ha dejado de responder.';
	end if;
end $$;

commit;
