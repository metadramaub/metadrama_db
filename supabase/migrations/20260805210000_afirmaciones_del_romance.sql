-- Las afirmaciones del romance, contrastadas contra el texto de las fuentes.
--
-- Al revisar la forma aparecieron dos que no dicen lo que dice la fuente, y duplicados:
--
-- · «Denomina romancillo al romance compuesto en versos de **menos de siete** sílabas». El
--   Diccionario dice «menos de **ocho**». La diferencia no es menor: con siete quedaría fuera
--   el heptasílabo, que es precisamente uno de los dos romancillos que nombran tanto Caparrós
--   como Morley y Bruerton.
--
-- · «Denomina endecha al romance compuesto en versos de siete sílabas». Caparrós dice otra
--   cosa: la endecha es un poema de asunto triste cuya forma **suele** ser un romancillo
--   heptasílabo, pero admite pentasílabos, hexasílabos o pareados de doce, y «el nombre se
--   refiere más bien al asunto propio del poema», de modo que hay endechas en redondillas o
--   en versos sueltos. Convertir eso en una identidad métrica es afirmar de más.
--
-- Se rehace el juego entero en vez de parchearlo: así queda una afirmación por cosa dicha,
-- sin solapes, y cada una se puede cotejar con su entrada del diccionario.

begin;

do $$
declare
	v_forma uuid;
	v_dicc uuid;
	v_mb uuid;
	v_hepta uuid;
	v_hexa uuid;
	v_endeca uuid;
	v_borradas integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance';
	select fuente_id into v_dicc from public.fuentes_metricas where titulo like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';

	select arquitectura_id into v_hepta from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heptasilabica';
	select arquitectura_id into v_hexa from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'hexasilabica';
	select arquitectura_id into v_endeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica';

	if v_forma is null or v_dicc is null or v_mb is null
		or v_hepta is null or v_hexa is null or v_endeca is null then
		raise exception 'Falta el romance, alguna de sus arquitecturas o alguna de las dos fuentes';
	end if;

	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (v_hepta, v_hexa, v_endeca)
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma where forma_id = v_forma
		);
	get diagnostics v_borradas = row_count;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	values
		(v_dicc, v_forma, null, 's. v. romance',
			'Serie de octosílabos indeterminada en número de versos, con rima asonante en todos los pares y los impares sueltos. Añade que puede dividirse por el sentido en grupos de cuatro versos y que admite estribillos o canciones intercalados.',
			'alta'),
		(v_dicc, v_forma, null, 's. v. romance',
			'Cuando el romance se compone en versos distintos del octosílabo recibe denominaciones específicas. Es la razón de que la medida sea aquí una arquitectura y no un rasgo.',
			'alta'),
		(v_mb, v_forma, null, 'V, «Romance»',
			'Nombra las variedades por su medida: romancillo o endechas en seis y siete sílabas, romance heroico o romance real en once.',
			'alta'),
		(v_dicc, null, v_hexa, 's. v. romancillo',
			'Romancillo es el romance en versos de menos de ocho sílabas, de modo que el nombre cubre por igual la realización hexasílaba y la heptasílaba.',
			'alta'),
		(v_dicc, null, v_hepta, 's. v. endecha',
			'La endecha es un poema de asunto triste cuya forma suele ser un romancillo heptasílabo, aunque admite versos de cinco o de seis sílabas y pareados de doce. El nombre se refiere antes al asunto que a la forma, y hay endechas en redondillas o en versos sueltos: por eso figura como denominación y no como identidad de esta arquitectura.',
			'alta'),
		(v_dicc, null, v_endeca, 's. v. romance heroico',
			'El romance heroico es el romance en versos endecasílabos.',
			'alta');

	raise notice 'Romance: % afirmaciones retiradas, 6 escritas contra el texto de las fuentes.', v_borradas;
end $$;

commit;
