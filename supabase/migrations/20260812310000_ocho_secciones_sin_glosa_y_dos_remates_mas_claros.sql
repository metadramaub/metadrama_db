-- Ocho secciones dejan de glosar lo que la ficha ya estructura y dos remates se expresan mejor.
--
-- La única pérdida aparente de información afecta a la doble sextina de Montemayor. Antes de
-- quitar su nota, la limitación comprobada en Navarro Tomás pasa a la afirmación bibliográfica:
-- el autor menciona los seis vocablos y los dos tercetos, pero no detalla su disposición interna.

do $$
declare
	afirmaciones_actualizadas integer;
	secciones_actualizadas integer;
	objetivos integer;
begin
	-- Esta actualización se hace primero: si la afirmación viva no coincide exactamente con la
	-- revisada, toda la migración se detiene y ninguna nota desaparece.
	update public.afirmaciones_fuentes_metricas af
	set resumen = af.resumen ||
		' Presenta en ella los mismos seis vocablos clave, pero no detalla su disposición dentro de los dos tercetos.',
		updated_at = now()
	from public.formas_metricas f
	where af.forma_id = f.forma_id
		and f.slug = 'sextina'
		and af.localizador = '§§ 115 y 167'
		and af.resumen = 'Documenta sextinas endecasílabas en Montemayor, Gil Polo, Herrera y Bermúdez, y su uso raro en Cervantes, Rioja y tres comedias de Lope anteriores a 1604. En el libro V de la *Diana* registra una doble de doce estrofas con combinaciones distintas y dos tercetos finales, es decir, 78 versos.';

	get diagnostics afirmaciones_actualizadas = row_count;
	if afirmaciones_actualizadas <> 1 then
		raise exception 'se esperaba ampliar una afirmación de Navarro Tomás y se actualizaron %', afirmaciones_actualizadas;
	end if;

	with objetivo(
		forma_slug, arquitectura_slug, seccion_slug, nota_actual, nota_nueva
	) as (values
		(
			'terceto_encadenado', 'endecasilabica_consonante', 'serventesio',
			'La cadena se cierra con una estrofa de cuatro versos cruzada, cuyas dos primeras clases vienen del último terceto.',
			null::text
		),
		(
			'terceto_encadenado', 'octosilabica_consonante', 'serventesio',
			'La cadena se cierra con una estrofa de cuatro versos cruzada, cuyas dos primeras clases vienen del último terceto.',
			null::text
		),
		(
			'sextina', 'doble_montemayor', 'estrofa',
			'Cada sección realiza la forma estrófica Sextina.',
			null::text
		),
		(
			'sextina', 'doble_montemayor', 'terceto_final',
			'Los seis vocablos vuelven en los dos tercetos; la fuente no precisa su distribución por parejas.',
			null::text
		),
		(
			'sextina', 'clasica', 'estrofa',
			'Cada sección realiza la forma estrófica Sextina.',
			null::text
		),
		(
			'cancion_petrarquista', 'regular_13_versos', 'remate',
			'Puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o presentar un esquema nuevo, siempre con heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.',
			'El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.'
		),
		(
			'cancion_petrarquista', 'estancias_consonantes_variables', 'remate',
			'Puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o presentar un esquema nuevo, siempre con heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.',
			'El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.'
		),
		(
			'cancion_petrarquista', 'sin_rima_con_pareado_final', 'cuerpo',
			'Extensión variable, sin contar los dos versos del pareado final.',
			null::text
		),
		(
			'cancion_petrarquista', 'sin_rima_con_pareado_final', 'estancia',
			'La extensión se deriva del cuerpo y del pareado final.',
			null::text
		),
		(
			'sextina', 'doble_petrarquista', 'estrofa',
			'Cada sección realiza la forma estrófica Sextina.',
			null::text
		)
	)
	select count(*) into objetivos
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	join public.estructuras_secciones s
		on s.arquitectura_id = a.arquitectura_id and s.slug = o.seccion_slug
	where s.nota = o.nota_actual;

	if objetivos <> 10 then
		raise exception 'se encontraron % de las diez notas de sección aprobadas', objetivos;
	end if;

	with objetivo(
		forma_slug, arquitectura_slug, seccion_slug, nota_actual, nota_nueva
	) as (values
		('terceto_encadenado', 'endecasilabica_consonante', 'serventesio', 'La cadena se cierra con una estrofa de cuatro versos cruzada, cuyas dos primeras clases vienen del último terceto.', null::text),
		('terceto_encadenado', 'octosilabica_consonante', 'serventesio', 'La cadena se cierra con una estrofa de cuatro versos cruzada, cuyas dos primeras clases vienen del último terceto.', null::text),
		('sextina', 'doble_montemayor', 'estrofa', 'Cada sección realiza la forma estrófica Sextina.', null::text),
		('sextina', 'doble_montemayor', 'terceto_final', 'Los seis vocablos vuelven en los dos tercetos; la fuente no precisa su distribución por parejas.', null::text),
		('sextina', 'clasica', 'estrofa', 'Cada sección realiza la forma estrófica Sextina.', null::text),
		('cancion_petrarquista', 'regular_13_versos', 'remate', 'Puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o presentar un esquema nuevo, siempre con heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.', 'El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.'),
		('cancion_petrarquista', 'estancias_consonantes_variables', 'remate', 'Puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o presentar un esquema nuevo, siempre con heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.', 'El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.'),
		('cancion_petrarquista', 'sin_rima_con_pareado_final', 'cuerpo', 'Extensión variable, sin contar los dos versos del pareado final.', null::text),
		('cancion_petrarquista', 'sin_rima_con_pareado_final', 'estancia', 'La extensión se deriva del cuerpo y del pareado final.', null::text),
		('sextina', 'doble_petrarquista', 'estrofa', 'Cada sección realiza la forma estrófica Sextina.', null::text)
	)
	update public.estructuras_secciones s
	set nota = o.nota_nueva, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	where s.arquitectura_id = a.arquitectura_id
		and s.slug = o.seccion_slug
		and s.nota = o.nota_actual;

	get diagnostics secciones_actualizadas = row_count;
	if secciones_actualizadas <> 10 then
		raise exception 'se esperaban diez notas de sección actualizadas y se cambiaron %', secciones_actualizadas;
	end if;
end;
$$;
