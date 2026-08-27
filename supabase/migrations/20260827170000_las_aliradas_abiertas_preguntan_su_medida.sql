-- Las aliradas abiertas preguntan su medida
--
-- El cuarteto-lira «mezcla endecasílabos y heptasílabos **en proporción variable**», y lo mismo la
-- octava, la novena y la décima liras: su esquema métrico declara el repertorio —7 y 11— y **ninguna
-- posición**, porque la norma no fija cuál va dónde. Pero no había ninguna pregunta de metro, así que
-- el editor solo podía elegir el esquema de rima y **la medida que leía no se registraba en ninguna
-- parte**.
--
-- Es el hueco B8 en el sitio donde el IP lo describió el 25 de agosto: «el cuarteto, septeto, octava,
-- novena y décima lira las dejamos abiertas tanto de metro como de rima […] entonces sí que queremos
-- que registren exactamente el esquema de metro y exactamente el esquema de rima».
--
-- Como en la manriqueña, no hace falta escribir opciones: la rama de
-- `opciones_eleccion_derivadas()` que atiende a los esquemas con `medida_uniforme` definida ofrece
-- **todo el repertorio en cada posición de la unidad**, que aquí es justo lo que se quiere: cuatro,
-- ocho, nueve o diez versos, cada uno de 7 u 11. Con `selecciones_min` igual a `selecciones_max` se
-- piden todos y no entra en el modo de «marcar excepciones».
--
-- **El septeto-lira se queda fuera.** Su esquema sí fija la medida verso a verso —`7 11 7 11 7 7 11`—
-- y su definición la presenta como «la realización que la documenta». Si esa forma admite otras
-- proporciones es una cuestión para el IP, no algo que decida esta migración.
--
-- **La lira y el sexteto-lira también quedan fuera**, y con razón distinta: la lira fija sus cinco
-- posiciones, y el sexteto-lira resuelve la variación por variedades, que ya tiene su pregunta.

begin;

do $$
declare
	v_arq record;
	v_grupo uuid;
	v_repertorio integer;
begin
	for v_arq in
		select a.arquitectura_id, f.nombre as forma, a.unidad_versos_min as versos,
			em.esquema_metrico_id, em.medida_uniforme
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		where f.activo and a.activo
			and f.nombre in ('Cuarteto-lira', 'Octava-lira', 'Novena-lira', 'Décima-lira')
	loop
		-- **Se comprueban los supuestos.** Si el esquema fijara posiciones, la forma no estaría
		-- abierta y esta pregunta sobraría; si no declarara repertorio, no habría qué ofrecer.
		if exists (
			select 1 from public.esquema_metrico_posiciones y
			where y.esquema_metrico_id = v_arq.esquema_metrico_id
		) then
			raise exception '% fija posiciones en su esquema: no es una medida abierta.', v_arq.forma;
		end if;

		if v_arq.medida_uniforme is null then
			raise exception '% no declara medida_uniforme, y entonces la pregunta no derivaría opciones.',
				v_arq.forma;
		end if;

		select count(*) into v_repertorio
		from public.esquema_metrico_opciones o
		where o.esquema_metrico_id = v_arq.esquema_metrico_id;

		if v_repertorio < 2 then
			raise exception '% ofrece % medidas en su repertorio y hacen falta al menos dos.',
				v_arq.forma, v_repertorio;
		end if;

		if coalesce(v_arq.versos, 0) < 1 then
			raise exception '% no declara cuántos versos tiene su unidad.', v_arq.forma;
		end if;

		select grupo_eleccion_id into v_grupo
		from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq.arquitectura_id and slug = 'medida_de_cada_verso';

		if v_grupo is null then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, tipo_control,
				selecciones_min, selecciones_max, permite_aplicar_global, define_norma,
				activo, orden, ayuda_editor
			)
			values (
				v_arq.arquitectura_id,
				'medida_de_cada_verso',
				'metro',
				'unidad',
				'opciones',
				v_arq.versos,
				v_arq.versos,
				true,
				false,
				true,
				2,
				'La forma combina heptasílabos y endecasílabos sin fijar en qué orden. Indica qué mide cada verso del pasaje que lees.'
			);
		else
			update public.grupos_eleccion_metrica
			set selecciones_min = v_arq.versos, selecciones_max = v_arq.versos, activo = true
			where grupo_eleccion_id = v_grupo;
		end if;
	end loop;
end $$;

do $$
declare
	v_fila record;
	v_reales integer;
	v_medidas text;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la vista**, que es lo que lee la aplicación.
	for v_fila in
		select f.nombre as forma, g.grupo_eleccion_id, g.selecciones_min as versos
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where g.slug = 'medida_de_cada_verso' and g.activo
	loop
		select count(*) into v_reales
		from public.opciones_eleccion_metrica o
		where o.grupo_eleccion_id = v_fila.grupo_eleccion_id;

		-- Dos medidas por cada verso de la unidad.
		if v_reales <> v_fila.versos * 2 then
			raise exception '% ofrece % opciones y se esperaban % (% versos × 2).',
				v_fila.forma, v_reales, v_fila.versos * 2, v_fila.versos;
		end if;

		select string_agg(distinct m.silabas::text, '/' order by m.silabas::text) into v_medidas
		from public.opciones_eleccion_metrica o
		join public.metros m on m.metro_id = o.metro_id
		where o.grupo_eleccion_id = v_fila.grupo_eleccion_id;

		if v_medidas <> '11/7' then
			raise exception '% ofrece medidas % y se esperaban 7 y 11.', v_fila.forma, v_medidas;
		end if;

		-- Y cada verso de la unidad tiene su par de opciones, no solo el primero.
		if (
			select count(distinct o.posicion_unidad)
			from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = v_fila.grupo_eleccion_id
		) <> v_fila.versos then
			raise exception '% no ofrece una elección por verso.', v_fila.forma;
		end if;
	end loop;

	select count(*) into v_reales
	from public.grupos_eleccion_metrica g
	where g.slug = 'medida_de_cada_verso' and g.activo;

	if v_reales <> 4 then
		raise exception 'Se esperaban las cuatro aliradas abiertas y hay %.', v_reales;
	end if;
end $$;

commit;
