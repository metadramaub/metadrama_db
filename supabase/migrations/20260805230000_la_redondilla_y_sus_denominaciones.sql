-- La redondilla: definición, denominaciones y las seis fuentes.
--
-- Segunda forma de la revisión, y la segunda del corpus con 63 secuencias. Se aplica la
-- norma de `docs/dominio-metrico/donde-vive-la-prosa.md`, y de paso se corrige el romance.
--
-- **El romance.** La afirmación de Jauralde decía que «lo clasifica entre las series y no
-- entre las estrofas». No es suyo: Quilis lo pone bajo «Poemas no estróficos», Caparrós 2014
-- tiene capítulo de «Series no estróficas» y la propia entrada del Diccionario empieza
-- «Poema formado por una **serie**». Es consenso, y además el catálogo ya lo codifica en
-- `nivel_estructural = 'serie'`. Atribuir a una fuente lo que dicen todas la hace decir menos
-- de lo que dice. Se queda con lo que sí es suyo.
--
-- **La redondilla.**
--
-- 1 · La definición terminaba en «El catálogo reconoce realizaciones de seis, siete y ocho
--     sílabas y la configuración doble enlazada». Habla del catálogo, no de la redondilla, y
--     usa «configuración», que es vocabulario retirado.
--
-- 2 · Las descripciones de arquitectura decían «Cuatro versos de 7 sílabas» y «Cuatro
--     octosílabos»: el esquema métrico ya lo dice, y la ficha lo imprime. Pasan a decir qué
--     distingue a cada realización, que es lo que la tradición ha hecho con ella.
--
-- 3 · Dos esquemas de rima describían su propia notación —«Dos rimas consonantes dispuestas
--     de forma abrazada» sobre `abba`, que además ya se llama «Abrazada»—. Y los otros cinco
--     no describían nada. La incoherencia se resuelve por abajo: se borran las dos.
--
-- 4 · «Cuarteta» vivía dentro de una de esas descripciones, en prosa. Su sitio es
--     `denominaciones_metricas`, que tiene columna para colgar de un esquema de rima. Con
--     ella entran «Redondilla mayor» y «Redondilla menor», que el Diccionario documenta y el
--     catálogo no tenía: la redondilla no tenía **ninguna** denominación registrada.
--
-- 5 · La doble enlazada escribía `abbaacca` y describía «abba:acca». Manda la norma de la
--     notación: los dos puntos marcan la pausa dentro del bloque, igual que en la décima
--     `ABBA:ACCDDC`. La notación es etiqueta, no se parsea en ningún sitio.
--
-- Las páginas salen de `scripts/lib/localizar.mjs` sobre los volcados de `bibliografía/txt/`.

begin;

do $$
declare
	v_romance uuid;
	v_forma uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_octo uuid;
	v_hexa uuid;
	v_n integer;
begin
	select forma_id into v_romance from public.formas_metricas where slug = 'romance';
	select forma_id into v_forma from public.formas_metricas where slug = 'redondilla';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	select arquitectura_id into v_octo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica';
	select arquitectura_id into v_hexa from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'hexasilabica';

	if v_forma is null or v_romance is null or v_octo is null or v_hexa is null then
		raise exception 'Falta la redondilla, el romance o alguna de sus arquitecturas';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- El romance: dejar en la afirmación de Jauralde solo lo que es suyo.
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Extiende el nombre de romancillo a los pentasílabos y tetrasílabos, además del heptasílabo y el hexasílabo que recoge el catálogo. Sitúa el romance heroico en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores, de modo que en el teatro áureo es una realización tardía y rara.'
	where fuente_id = v_jauralde and forma_id = v_romance;

	-- 1 · La definición dice qué es la redondilla y se calla lo que decidió el catálogo.
	update public.formas_metricas
	set definicion = 'Estrofa de cuatro versos de arte menor con rima consonante repartida en dos clases, sin ningún verso suelto. La disposición puede ser abrazada (abba) o cruzada (abab). El octosílabo es su realización no marcada.'
	where forma_id = v_forma;

	-- 2 · Cada arquitectura dice qué la distingue, no su medida, que ya está en el dato.
	update public.arquitecturas_forma a
	set descripcion = case a.slug
		when 'octosilabica' then
			'Realización no marcada, que la tradición nombra redondilla mayor. Con el romance y la décima, uno de los tres moldes del diálogo en la comedia nueva.'
		when 'heptasilabica' then
			'Realización ocasional, que la bibliografía registra junto a la hexasílaba como alternativa poco frecuente a la octosílaba.'
		when 'hexasilabica' then
			'Realización ocasional, que la tradición nombra redondilla menor y que la lírica popular cultivó con preferencia.'
		when 'doble_enlazada' then
			'Dos redondillas abrazadas que comparten la rima exterior: la segunda no estrena sus dos clases, sino solo una.'
		else a.descripcion
	end
	where a.forma_id = v_forma;

	-- 3 · Un esquema de rima no se describe a sí mismo: su nombre y su notación ya lo dicen.
	update public.esquemas_rima er
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and er.notacion in ('abba', 'abab');

	-- 5 · La pausa del bloque se marca, como en la décima.
	update public.esquemas_rima er
	set notacion = 'abba:acca'
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and er.notacion = 'abbaacca';

	-- 4 · Las denominaciones, a la tabla que existe para ellas.
	insert into public.denominaciones_metricas
		(forma_id, arquitectura_id, esquema_rima_id, nombre, slug_normalizado, tipo_alias, preferente)
	select null, null, er.esquema_rima_id, 'Cuarteta', 'cuarteta', 'equivalente', false
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma and er.notacion = 'abab'
	on conflict do nothing;

	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, tipo_alias, preferente)
	values
		(v_octo, 'Redondilla mayor', 'redondilla_mayor', 'equivalente', false),
		(v_hexa, 'Redondilla menor', 'redondilla_menor', 'equivalente', false)
	on conflict do nothing;

	-- Las fuentes: una afirmación por cosa que cada una añade.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma where forma_id = v_forma
		);

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- De dónde sale cada disposición, y cuál es la antigua.
		(v_navarro, v_forma, '§ 37, p. 90',
			'La disposición cruzada es la antigua: nace de la emancipación de los hemistiquios del dístico octonario, con correspondencia de rimas interiores, y se documenta ya en el siglo XII. La abrazada se explica como modificación suya y empieza a conocerse en el siglo XIV.',
			'alta'),

		-- Por qué un solo nombre cubre las dos disposiciones.
		(v_navarro, v_forma, '§ 37, nota 7, p. 90',
			'El nombre «redondilla» no empezó a usarse hasta el siglo XVI, y Rengifo lo aplicó a la vez a las formas abab y abba, además de a estrofas de cinco o más versos. Advierte también que a la redondilla abab se le ha dado a veces el nombre de serventesio, que corresponde más propiamente al cuarteto endecasílabo.',
			'alta'),

		-- Lo mismo desde el diccionario, y el aviso para leer tratados áureos.
		(v_dicc, v_forma, 'Entrada «redondilla», p. 300',
			'Define la redondilla incluyendo las dos disposiciones bajo un mismo nombre, y advierte que en los tratadistas del Siglo de Oro el término era mucho más amplio: abarcaba también la quintilla, la sextilla, la septilla y la octavilla. Añade que modernamente se ha empleado además la rima asonante, que el catálogo no admite en esta forma.',
			'alta'),

		-- Qué es exactamente una cuarteta, y dónde se usa.
		(v_dicc, v_forma, 'Entrada «cuarteta», p. 95',
			'Reserva «cuarteta» para la disposición cruzada en versos octosílabos o menores, y señala que se usa normalmente en poesía narrativa y en los diálogos del teatro.',
			'alta'),

		-- La misma jerarquía que adopta el catálogo, en otra fuente.
		(v_quilis, v_forma, 'p. 94',
			'Trata la cuarteta como variante de la redondilla y no como estrofa independiente, que es la relación que el catálogo establece entre las dos disposiciones.',
			'alta'),

		-- El octosílabo, nombrado por la estrofa.
		(v_cap14, v_forma, 'p. 138',
			'Recoge «verso de redondilla mayor» entre los nombres tradicionales del octosílabo, junto a verso de arte menor y de arte real: la estrofa llegó a dar nombre al verso.',
			'alta'),

		-- Cuándo la rima abrazada deja de ser estrófica.
		(v_cap14, v_forma, 'p. 116',
			'Observa que la disposición abrazada característica de la redondilla se prolonga con frecuencia más allá de una estrofa, encadenando clases nuevas —abba cddc effe…—, de modo que la misma rima sirve para una estrofa y para una serie.',
			'alta'),

		-- Por qué pesa tanto en este corpus, y qué medidas admite.
		(v_jauralde, v_forma, '«Estrofas de cuatro versos»',
			'Registra las tres medidas del catálogo: frecuentemente octosílaba, pero también heptasílaba y hexasílaba. Señala que la comedia nueva encumbró su uso hasta equipararla, con el romance y las décimas, al habla coloquial en prosa.',
			'alta'),

		-- Y dónde el catálogo va más allá de la bibliografía sobre la que se data a Lope.
		(v_mb, v_forma, 'Cap. V, «Redondilla»',
			'Reservan el nombre para la disposición abrazada —cuatro octosílabos ABBA, ocasionalmente de seis o siete sílabas— y no incluyen la cruzada. El catálogo es aquí deliberadamente más amplio y acoge las dos, siguiendo al Diccionario y a Navarro Tomás.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Redondilla · definición, 4 descripciones, 5 denominaciones y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
