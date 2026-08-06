-- El pareado: descripciones, denominación y las seis fuentes.
--
-- Duodécima forma de la revisión. La definición está bien y **no se toca**: es casi literalmente
-- la del Diccionario —«estrofa formada por dos versos, de igual o de diferente medida, que
-- riman en consonante o en asonante»—, de modo que la decisión de no acotar ni la medida ni el
-- régimen de rima tiene respaldo directo. Lo que falta es todo lo demás.
--
-- 1 · **El esquema métrico cuenta la migración.** Decía «Importado como conjunto de medidas; el
--     orden no se infiere del vocabulario legado». De dónde vino un dato es historia de la
--     migración y no se cuenta en el catálogo. Pasa a decir qué significa ese conjunto: que la
--     medida no está fijada y se declara verso a verso, lo que además permite el dístico
--     heterométrico que la definición admite.
--
-- 2 · **Los dos esquemas de rima comparten notación y no decían nada.** Los dos se escriben
--     `aa` porque la notación marca el arte, no el régimen; lo que los separa es el nombre.
--     Ahora cada uno explica su régimen, que es lo único que los distingue.
--
-- 3 · **«Dístico» no estaba registrado**, y es el nombre con el que la bibliografía lo nombra a
--     menudo.
--
-- Lo que las fuentes añaden, y una discrepancia de alcance:
--
-- · **El pareado es la base de otras formas.** El Diccionario lo dice y ata varios cabos del
--   catálogo de una vez: sobre el pareado se construyen la silva de consonantes, el perqué, la
--   aleluya y los juegos dialogados, y muchos estribillos tienen su forma. Es la razón de que
--   la escala `Organización en pareados` corra por el endecasílabo suelto, la silva y el propio
--   pareado.
--
-- · **Morley y Bruerton lo acotan mucho más**: para ellos los pareados son dísticos de
--   octosílabos, y raramente de seis sílabas. El catálogo sigue al Diccionario y admite de
--   cuatro a catorce. Se registra la diferencia, que importa para leerlos a ellos.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if v_forma is null or v_arq is null then
		raise exception 'Falta el pareado o su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- 1 · La medida dice qué es, no de dónde vino.
	update public.esquemas_metricos
	set descripcion = 'La medida no está fijada: se declara verso a verso, de modo que los dos pueden ser iguales o distintos.'
	where arquitectura_id = v_arq;

	-- 2 · Cada régimen explica lo único que lo separa del otro.
	update public.esquemas_rima
	set descripcion = case nombre
		when 'Consonante' then
			'Los dos versos coinciden en todos los sonidos desde la última vocal acentuada.'
		when 'Asonante' then
			'Los dos versos coinciden solo en las vocales desde la última acentuada. La notación es la misma porque marca el arte del verso, no el régimen de la rima.'
		else descripcion
	end
	where arquitectura_id = v_arq;

	-- 3 · El otro nombre.
	insert into public.denominaciones_metricas (forma_id, nombre, slug_normalizado, preferente)
	values (v_forma, 'Dístico', 'distico', false)
	on conflict do nothing;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- Sobre qué se construye, que explica media docena de formas del catálogo.
		(v_dicc, v_forma, 'Entrada «pareado», p. 258',
			'Señala que es forma más propia de la poesía narrativa, epigramática, didáctica o dramática que de la lírica, y sobre todo que **es la forma sobre la que se construyen otras**: la silva de consonantes, el perqué, la aleluya, las canciones de coro y los juegos dialogados. Añade que muchos estribillos tienen también forma de pareado.',
			'alta'),

		-- El otro nombre, y la notación.
		(v_cap14, v_forma, 'p. 184',
			'Recoge «dístico» como otro nombre del pareado y lo nota `a a`, sin fijar medida ni régimen de rima.',
			'alta'),

		-- Para qué sirve solo.
		(v_quilis, v_forma, 'p. 91',
			'Lo describe como la estrofa más sencilla, capaz de formar por sí sola una estrofa, y señala su empleo como expresión popular en refranes y máximas filosóficas. Precisa que los dos versos pueden ser iguales o diferentes en medida.',
			'alta'),

		-- Dónde aparece el octosílabo, y qué le pasó al narrativo.
		(v_navarro, v_forma, '§ 58',
			'Registra el pareado octosílabo en estribillos de canciones, en máximas y proverbios intercalados, y en motes y divisas. Observa que el pareado narrativo de la poesía juglaresca, ya restringido entre los poetas de clerecía, quedó casi enteramente desterrado de la métrica del siglo XV.',
			'alta'),

		-- Su antigüedad y su papel en el teatro.
		(v_jauralde, v_forma, '«Estrofas de dos versos»',
			'Lo sitúa entre las formas originarias y primitivas de la poesía, y recoge sus modalidades en la lírica tradicional: el cosante, el perqué, las canciones infantiles. Señala que aparece esporádicamente en la comedia del Siglo de Oro, donde resulta muy funcional para intervenciones breves y concisas, y que su función más importante ha sido servir de estribillo.',
			'alta'),

		-- Y hasta dónde lo acotan quienes datan a Lope.
		(v_mb, v_forma, 'Cap. V, «Pareados»',
			'Lo acotan mucho más: para ellos los pareados son dísticos de octosílabos, que también se encuentran, aunque raramente, en versos de seis sílabas.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Pareado · medida, 2 regímenes de rima, 1 denominación y % afirmaciones', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
