-- Las ocho relaciones pendientes conservan su nota y explican únicamente el vínculo entre formas.
--
-- Mencionar la forma de destino no es redundante aquí: es la función propia de una relación. Se
-- retira, en cambio, lo que ya dicen cantidades, arquitecturas, rejillas y regímenes declarados.

do $$
declare
	actualizadas integer;
	objetivos integer;
begin
	-- Las diferencias que sostienen las notas siguen presentes en datos o afirmaciones de fuente.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'copla_real'
			and af.resumen ilike '%dos quintillas%'
			and af.resumen ilike '%rimas consonantes independientes%'
	) then
		raise exception 'falta la afirmación sobre las dos quintillas independientes de la copla real';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'decima' and af.resumen ilike '%finales del siglo XVI%'
	) then
		raise exception 'falta la afirmación histórica sobre la aparición de la décima';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'sexteto_lira'
			and af.resumen ilike '%lira de seis versos%'
	) then
		raise exception 'falta la afirmación que define el sexteto-lira desde la lira';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		left join public.formas_metricas f on f.forma_id = af.forma_id
		left join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
		left join public.formas_metricas fa on fa.forma_id = a.forma_id
		where coalesce(f.slug, fa.slug) = 'endecha_real'
			and af.resumen ilike '%romance heptasílabo%'
			and af.resumen ilike '%cada cuarteta%'
	) then
		raise exception 'falta la afirmación que relaciona la endecha real con el romance';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'sextina'
			and af.resumen ilike '%remite%«sextina real» a sexta rima%'
	) or not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'sexteto'
			and af.resumen ilike '%sexta rima%ABABCC%'
	) then
		raise exception 'faltan las afirmaciones que distinguen sextina, sexta rima y sextina real';
	end if;

	with objetivo(origen_slug, destino_slug, tipo_relacion, nota_actual, nota_nueva) as (values
		(
			'copla_real', 'quintilla', 'compuesta_por',
			'La copla real se organiza como dos quintillas separadas por la pausa 5 + 5.',
			'Las dos quintillas se separan por una pausa estructural y conservan rimas independientes.'
		),
		(
			'decima', 'copla_real', 'sucede_historicamente_a',
			'La espinela reemplaza progresivamente a la copla real como modalidad dominante de décima entre finales del siglo XVI y las primeras décadas del XVII. No se afirma una invención individual ni una derivación exclusiva.',
			'Entre finales del siglo XVI y las primeras décadas del XVII, la espinela reemplaza progresivamente a la copla real como modalidad dominante de décima. Se trata de una sucesión histórica más que de una derivación entre ambas formas.'
		),
		(
			'sexteto_lira', 'lira', 'derivada_de',
			'El sexteto-lira no es un sexteto modificado: amplía la lira garcilasiana a seis versos y conserva su principio constructivo, el contraste entre el heptasílabo que impulsa y el endecasílabo que reposa.',
			'Es una variedad de la lira garcilasiana ampliada a seis versos, no una modificación del sexteto isosilábico: conserva la combinación de heptasílabos y endecasílabos y el cierre en pareado.'
		),
		(
			'terceto_encadenado', 'terceto', 'relacionada_con',
			'La serie se construye con unidades de terceto enlazadas, pero no es un subtipo ni una repetición del terceto: la rima del verso central de cada unidad vive en la siguiente, de modo que el pasaje no se puede dividir en tercetos independientes. Esa es la razón de que sean dos formas y no una estrofa que se repite.',
			'Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente; por eso constituye una serie indivisible y no una repetición de tercetos independientes.'
		),
		(
			'terceto_encadenado', 'cuarteto', 'relacionada_con',
			'La serie encadenada cierra con una estrofa cruzada de cuatro versos: un serventesio en la endecasilábica y una redondilla cruzada en la octosilábica, porque «serventesio» nombra solo el cuarteto de arte mayor.',
			'El cierre cruzado recibe el nombre correspondiente al arte de sus cuatro versos: serventesio en la arquitectura endecasilábica y redondilla cruzada en la octosilábica.'
		),
		(
			'endecha_real', 'romance', 'derivada_de',
			'Es un romance heptasílabo cuyo cuarto verso se alarga a endecasílabo. Conserva de él la asonancia única sostenida durante toda la composición y la extensión libre; lo que la separa es la heterometría regular y que la rima cae cada cuatro versos, no cada dos.',
			'Deriva del romance heptasílabo, pero alarga a endecasílabo el cuarto verso de cada cuarteto. Conserva la asonancia única sostenida durante toda la composición y la extensión libre; la distinguen la heterometría regular y que la asonancia recaiga cada cuatro versos, no cada dos.'
		),
		(
			'sextina', 'sextina_estrofa', 'compuesta_por',
			'La composición consta de seis sextinas en la arquitectura clásica y de doce en las dos arquitecturas dobles.',
			'La arquitectura clásica repite seis veces la estrofa; las dos arquitecturas dobles, doce.'
		),
		(
			'sexteto', 'sextina', 'contrasta_con',
			'Parte de la bibliografía llama sexta rima a la composición de treinta y nueve versos y sextina real a la estrofa ABABCC de seis. Son formas distintas: la composición encadena seis estrofas y un remate repitiendo las mismas palabras finales, sin que sus versos rimen entre sí; la estrofa de seis versos rima en consonante y puede repetirse libremente.',
			'«Sextina» designa la composición de palabras finales repetidas, mientras que «sexta rima» —también llamada «sextina real» por parte de la bibliografía— designa el sexteto endecasílabo ABABCC. La primera carece de rima convencional; la segunda es una estrofa consonante de seis versos.'
		)
	)
	select count(*) into objetivos
	from objetivo o
	join public.formas_metricas fo on fo.slug = o.origen_slug
	join public.formas_metricas fd on fd.slug = o.destino_slug
	join public.forma_relaciones r
		on r.forma_origen_id = fo.forma_id
		and r.forma_destino_id = fd.forma_id
		and r.tipo_relacion = o.tipo_relacion
	where r.nota = o.nota_actual;

	if objetivos <> 8 then
		raise exception 'se encontraron % de las ocho relaciones aprobadas', objetivos;
	end if;

	with objetivo(origen_slug, destino_slug, tipo_relacion, nota_actual, nota_nueva) as (values
		('copla_real', 'quintilla', 'compuesta_por', 'La copla real se organiza como dos quintillas separadas por la pausa 5 + 5.', 'Las dos quintillas se separan por una pausa estructural y conservan rimas independientes.'),
		('decima', 'copla_real', 'sucede_historicamente_a', 'La espinela reemplaza progresivamente a la copla real como modalidad dominante de décima entre finales del siglo XVI y las primeras décadas del XVII. No se afirma una invención individual ni una derivación exclusiva.', 'Entre finales del siglo XVI y las primeras décadas del XVII, la espinela reemplaza progresivamente a la copla real como modalidad dominante de décima. Se trata de una sucesión histórica más que de una derivación entre ambas formas.'),
		('sexteto_lira', 'lira', 'derivada_de', 'El sexteto-lira no es un sexteto modificado: amplía la lira garcilasiana a seis versos y conserva su principio constructivo, el contraste entre el heptasílabo que impulsa y el endecasílabo que reposa.', 'Es una variedad de la lira garcilasiana ampliada a seis versos, no una modificación del sexteto isosilábico: conserva la combinación de heptasílabos y endecasílabos y el cierre en pareado.'),
		('terceto_encadenado', 'terceto', 'relacionada_con', 'La serie se construye con unidades de terceto enlazadas, pero no es un subtipo ni una repetición del terceto: la rima del verso central de cada unidad vive en la siguiente, de modo que el pasaje no se puede dividir en tercetos independientes. Esa es la razón de que sean dos formas y no una estrofa que se repite.', 'Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente; por eso constituye una serie indivisible y no una repetición de tercetos independientes.'),
		('terceto_encadenado', 'cuarteto', 'relacionada_con', 'La serie encadenada cierra con una estrofa cruzada de cuatro versos: un serventesio en la endecasilábica y una redondilla cruzada en la octosilábica, porque «serventesio» nombra solo el cuarteto de arte mayor.', 'El cierre cruzado recibe el nombre correspondiente al arte de sus cuatro versos: serventesio en la arquitectura endecasilábica y redondilla cruzada en la octosilábica.'),
		('endecha_real', 'romance', 'derivada_de', 'Es un romance heptasílabo cuyo cuarto verso se alarga a endecasílabo. Conserva de él la asonancia única sostenida durante toda la composición y la extensión libre; lo que la separa es la heterometría regular y que la rima cae cada cuatro versos, no cada dos.', 'Deriva del romance heptasílabo, pero alarga a endecasílabo el cuarto verso de cada cuarteto. Conserva la asonancia única sostenida durante toda la composición y la extensión libre; la distinguen la heterometría regular y que la asonancia recaiga cada cuatro versos, no cada dos.'),
		('sextina', 'sextina_estrofa', 'compuesta_por', 'La composición consta de seis sextinas en la arquitectura clásica y de doce en las dos arquitecturas dobles.', 'La arquitectura clásica repite seis veces la estrofa; las dos arquitecturas dobles, doce.'),
		('sexteto', 'sextina', 'contrasta_con', 'Parte de la bibliografía llama sexta rima a la composición de treinta y nueve versos y sextina real a la estrofa ABABCC de seis. Son formas distintas: la composición encadena seis estrofas y un remate repitiendo las mismas palabras finales, sin que sus versos rimen entre sí; la estrofa de seis versos rima en consonante y puede repetirse libremente.', '«Sextina» designa la composición de palabras finales repetidas, mientras que «sexta rima» —también llamada «sextina real» por parte de la bibliografía— designa el sexteto endecasílabo ABABCC. La primera carece de rima convencional; la segunda es una estrofa consonante de seis versos.')
	)
	update public.forma_relaciones r
	set nota = o.nota_nueva, updated_at = now()
	from objetivo o
	join public.formas_metricas fo on fo.slug = o.origen_slug
	join public.formas_metricas fd on fd.slug = o.destino_slug
	where r.forma_origen_id = fo.forma_id
		and r.forma_destino_id = fd.forma_id
		and r.tipo_relacion = o.tipo_relacion
		and r.nota = o.nota_actual;

	get diagnostics actualizadas = row_count;
	if actualizadas <> 8 then
		raise exception 'se esperaban ocho relaciones actualizadas y se cambiaron %', actualizadas;
	end if;
end;
$$;
