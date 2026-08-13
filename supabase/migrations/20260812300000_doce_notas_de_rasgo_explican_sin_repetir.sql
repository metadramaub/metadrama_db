-- Doce notas de rasgo explican la relación entre los datos sin volver a enumerarlos.
--
-- El valor estructurado sigue dando la respuesta breve —densidad total, pareados regulares,
-- predominantes, ocasionales o ninguno—. La nota se limita a precisar su alcance: una
-- distribución variable no deja versos sin rima, un pareado aislado no organiza la silva libre
-- y el umbral del cincuenta por ciento separa el endecasílabo suelto de la silva.

do $$
declare
	actualizadas integer;
	objetivos integer;
begin
	-- Las dos atribuciones que se condensan en las notas del endecasílabo suelto permanecen en la
	-- tabla de afirmaciones, donde se conserva también la observación histórica sobre Lope.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'endecasilabo_suelto'
			and af.resumen ilike '%menor del 50 por ciento%'
			and af.resumen ilike '%dísticos%'
	) then
		raise exception 'falta la afirmación de Morley y Bruerton sobre el endecasílabo suelto';
	end if;

	-- La repetición de una misma distribución en todas las estancias tampoco depende de la nota.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'cancion_petrarquista'
			and af.resumen ilike '%idéntico en cada estrofa%'
	) then
		raise exception 'falta la afirmación de fuente sobre la distribución repetida de la canción';
	end if;

	-- La lectura del pareado como unidad de la silva de consonantes conserva su afirmación propia.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'silva' and a.slug = 'consonante_regular'
			and af.resumen ilike '%unidad estrófica%'
	) then
		raise exception 'falta la afirmación sobre el pareado como unidad de la silva regular';
	end if;

	-- La lista incluye el valor porque una arquitectura puede declarar el mismo rasgo con más de
	-- una modalidad, como ocurre con la densidad del endecasílabo suelto.
	with objetivo(
		forma_slug, arquitectura_slug, rasgo_slug, valor_slug, modalidad,
		nota_actual, nota_nueva
	) as (values
		(
			'silva', 'consonante_irregular', 'organizacion_en_pareados', 'predominantes',
			'definitoria',
			'Los pareados organizan predominantemente la serie.',
			'Los pareados predominan, pero no forman una pauta regular ni excluyen otros enlaces.'
		),
		(
			'endecasilabo_suelto', 'endecasilabica', 'densidad_de_rima', 'esporadica',
			'admitida',
			'Morley y Bruerton cuentan el pasaje como suelto mientras los versos rimados no lleguen a la mitad, y observan que Lope intercalaba dísticos con frecuencia creciente.',
			'El pasaje sigue siendo suelto mientras los versos rimados no alcancen la mitad.'
		),
		(
			'endecasilabo_suelto', 'endecasilabica', 'organizacion_en_pareados', 'ocasionales',
			'admitida',
			'Los dísticos que Lope intercalaba desde 1588 no convierten el pasaje en silva: lo que lo convertiría es que rimara más de la mitad de los versos.',
			'Los pareados ocasionales no alteran la clasificación mientras los versos rimados no alcancen la mitad.'
		),
		(
			'silva', 'libre', 'organizacion_en_pareados', 'ninguna',
			'definitoria',
			'No se organiza en pareados; si aparece alguno, es un caso aislado.',
			'Puede aparecer algún pareado aislado sin que la serie se organice en pareados.'
		),
		(
			'copla_de_pie_quebrado', 'octosilabica_con_quebrados', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		),
		(
			'sextilla', 'pie_quebrado', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		),
		(
			'cancion_petrarquista', 'estancias_consonantes_variables', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución elegida se repite en todas las estancias; la variación afecta al patrón, no a la presencia de rima.'
		),
		(
			'silva', 'consonante_regular', 'organizacion_en_pareados', 'regulares',
			'definitoria',
			'La alternancia 7-11 y el esquema aA | bB | cC organizan la serie en pareados sistemáticos.',
			'El pareado constituye la unidad regular de organización de esta arquitectura.'
		),
		(
			'sexteto', 'dodecasilabica', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		),
		(
			'sexteto', 'alejandrina', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		),
		(
			'sextilla', 'heptasilabica', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		),
		(
			'sextilla', 'hexasilabica', 'densidad_de_rima', 'total',
			'definitoria',
			'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.',
			'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
		)
	)
	select count(*) into objetivos
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	join public.rasgos_metricos rg on rg.slug = o.rasgo_slug
	join public.rasgo_valores rv on rv.rasgo_id = rg.rasgo_id and rv.slug = o.valor_slug
	join public.arquitectura_rasgos ar
		on ar.arquitectura_id = a.arquitectura_id
		and ar.rasgo_id = rg.rasgo_id
		and ar.valor_id = rv.valor_id
		and ar.modalidad = o.modalidad
	where ar.nota = o.nota_actual;

	if objetivos <> 12 then
		raise exception 'se encontraron % de las doce notas de rasgo aprobadas', objetivos;
	end if;

	with objetivo(
		forma_slug, arquitectura_slug, rasgo_slug, valor_slug, modalidad,
		nota_actual, nota_nueva
	) as (values
		('silva', 'consonante_irregular', 'organizacion_en_pareados', 'predominantes', 'definitoria', 'Los pareados organizan predominantemente la serie.', 'Los pareados predominan, pero no forman una pauta regular ni excluyen otros enlaces.'),
		('endecasilabo_suelto', 'endecasilabica', 'densidad_de_rima', 'esporadica', 'admitida', 'Morley y Bruerton cuentan el pasaje como suelto mientras los versos rimados no lleguen a la mitad, y observan que Lope intercalaba dísticos con frecuencia creciente.', 'El pasaje sigue siendo suelto mientras los versos rimados no alcancen la mitad.'),
		('endecasilabo_suelto', 'endecasilabica', 'organizacion_en_pareados', 'ocasionales', 'admitida', 'Los dísticos que Lope intercalaba desde 1588 no convierten el pasaje en silva: lo que lo convertiría es que rimara más de la mitad de los versos.', 'Los pareados ocasionales no alteran la clasificación mientras los versos rimados no alcancen la mitad.'),
		('silva', 'libre', 'organizacion_en_pareados', 'ninguna', 'definitoria', 'No se organiza en pareados; si aparece alguno, es un caso aislado.', 'Puede aparecer algún pareado aislado sin que la serie se organice en pareados.'),
		('copla_de_pie_quebrado', 'octosilabica_con_quebrados', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'),
		('sextilla', 'pie_quebrado', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'),
		('cancion_petrarquista', 'estancias_consonantes_variables', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución elegida se repite en todas las estancias; la variación afecta al patrón, no a la presencia de rima.'),
		('silva', 'consonante_regular', 'organizacion_en_pareados', 'regulares', 'definitoria', 'La alternancia 7-11 y el esquema aA | bB | cC organizan la serie en pareados sistemáticos.', 'El pareado constituye la unidad regular de organización de esta arquitectura.'),
		('sexteto', 'dodecasilabica', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'),
		('sexteto', 'alejandrina', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'),
		('sextilla', 'heptasilabica', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'),
		('sextilla', 'hexasilabica', 'densidad_de_rima', 'total', 'definitoria', 'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.', 'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.')
	)
	update public.arquitectura_rasgos ar
	set nota = o.nota_nueva, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	join public.rasgos_metricos rg on rg.slug = o.rasgo_slug
	join public.rasgo_valores rv on rv.rasgo_id = rg.rasgo_id and rv.slug = o.valor_slug
	where ar.arquitectura_id = a.arquitectura_id
		and ar.rasgo_id = rg.rasgo_id
		and ar.valor_id = rv.valor_id
		and ar.modalidad = o.modalidad
		and ar.nota = o.nota_actual;

	get diagnostics actualizadas = row_count;
	if actualizadas <> 12 then
		raise exception 'se esperaban doce notas actualizadas y se cambiaron %', actualizadas;
	end if;
end;
$$;
