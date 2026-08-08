-- La sextilla contrastada con las seis fuentes autorizadas.
--
-- Solo declaraba la afirmación de Caparrós 2014, y su definición contaba lo que el catálogo
-- distingue en vez de decir qué es la forma. Las seis fuentes la tratan y coinciden en el
-- núcleo —seis versos de arte menor con rima consonante y disposición variable—, de modo que
-- la definición no cambia de fondo; lo que cambia es todo lo que había alrededor.
--
-- 1. La disposición tiene nombres y el catálogo no los tenía. Las seis fuentes nombran
--    disposiciones concretas: alterna ababab, correlativa o simétrica abcabc, paralela. El
--    Diccionario las atribuye a Baehr y Navarro Tomás las emplea desde el repertorio
--    juglaresco. Se declaran como esquemas de rima con nombre en la arquitectura octosilábica,
--    que es donde las fuentes las documentan, y como denominaciones donde la tradición les dio
--    nombre propio. No se cierra el repertorio: la disposición sigue siendo abierta.
--
-- 2. «Copla manriqueña» estaba solo en un esquema de la doble, y las fuentes la dan también
--    para la sextilla simple de pie quebrado. Quilis, Caparrós 2014 y el Diccionario llaman
--    copla de Jorge Manrique, estrofa manriqueña o copla manriqueña a la sextilla 8-8-4-8-8-4,
--    no a la de doce versos. Se añaden las denominaciones equivalentes sobre la arquitectura
--    de pie quebrado —«Copla de Jorge Manrique», «Estrofa manriqueña»—, que es lo que el IP
--    pidió: que un nombre equivalente se codifique como dato y no solo se mencione en la
--    afirmación.
--
-- 3. El quebrado no siempre va en tercero y sexto. El catálogo lo daba por invariable. El
--    Diccionario ilustra su entrada «sextilla de pie quebrado» con una estrofa de Lucas
--    Fernández quebrada en segundo y quinto, y Jauralde documenta las sextillas de Ricardo Gil
--    con el tetrasílabo en segundo y quinto. La posición típica se conserva como la que el
--    corpus necesita, pero deja de afirmarse como norma: la nota del rasgo lo dice.
--
-- 4. Las medidas 6, 7 y 8 son un recorte del corpus. Jauralde ordena las sextillas por medida
--    y describe también tetrasilábicas y pentasilábicas. Las tres del catálogo se conservan;
--    que sean tres y no cinco se anota como duda, no se resuelve aquí.
--
-- No se toca ninguna secuencia real ni se cambia ninguna equivalencia: los términos legados de
-- la sextilla siguen resolviendo a las mismas arquitecturas.

begin;

do $$
declare
	v_forma uuid;
	v_octo uuid;
	v_hepta uuid;
	v_hexa uuid;
	v_quebrado uuid;
	v_doble uuid;
	v_esq uuid;
	v_manriquena uuid;
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1'::uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sextilla';
	select arquitectura_id into v_octo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica';
	select arquitectura_id into v_hepta from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heptasilabica';
	select arquitectura_id into v_hexa from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'hexasilabica';
	select arquitectura_id into v_quebrado from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'pie_quebrado';
	select arquitectura_id into v_doble from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'doble_pie_quebrado';
	select esquema_rima_id into v_manriquena from public.esquemas_rima
	where arquitectura_id = v_doble and slug = 'abcabc-defdef';

	if num_nonnulls(
		v_forma, v_octo, v_hepta, v_hexa, v_quebrado, v_doble, v_manriquena,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 13 then
		raise exception 'Falta la sextilla vigente, una de sus partes o una fuente autorizada';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición dice qué es la forma, no qué distingue el catálogo dentro de ella.
	update public.formas_metricas
	set definicion = 'Estrofa de seis versos de arte menor con rima consonante cuya disposición no está fijada. La tradición ha nombrado algunas de sus disposiciones —alterna, correlativa, paralela— y admite que uno o más versos se quiebren en otros más breves, que es la variedad de la que procede la copla manriqueña.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Seis octosílabos. Es la medida más documentada y la que sostiene las disposiciones con nombre propio.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_octo;

	update public.arquitecturas_forma
	set descripcion = 'Seis heptasílabos.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_hepta;

	update public.arquitecturas_forma
	set descripcion = 'Seis hexasílabos, medida de la que Rubén Darío tomó el nombre de lay.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_hexa;

	update public.arquitecturas_forma
	set descripcion = 'Dos grupos de tres versos, cada uno cerrado por un verso más breve que los octosílabos que lo preceden. Es la sextilla de la que procede la copla de Jorge Manrique.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_quebrado;

	-- La posición del quebrado es la típica, no una norma sin excepción.
	update public.arquitectura_rasgos
	set nota = 'Se deriva del patrón métrico 8-8-4-8-8-4. Tercero y sexto son las posiciones típicas, pero no las únicas que la tradición documenta.',
		updated_at = now()
	where arquitectura_id = v_quebrado
		and rasgo_id = (select rasgo_id from public.rasgos_metricos where slug = 'pie_quebrado');

	-- Las disposiciones que la tradición nombra, sobre la medida donde se documentan. Siguen
	-- siendo admitidas: la disposición de la sextilla no se cierra.
	delete from public.esquemas_rima
	where arquitectura_id = v_octo and slug in ('ababab', 'abcabc', 'aabccb');
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values
		(v_octo, 'ababab', 'Alterna', 'ababab', v_consonante, 'unidad', 'admitida',
		 'secuencia', 'Dos rimas que se alternan verso a verso a lo largo de la estrofa.',
		 'revisada'),
		(v_octo, 'abcabc', 'Correlativa', 'abcabc', v_consonante, 'unidad', 'admitida',
		 'secuencia', 'Tres rimas que reaparecen en el mismo orden en la segunda mitad, de modo que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto.',
		 'revisada'),
		(v_octo, 'aabccb', 'Simétrica', 'aabccb', v_consonante, 'unidad', 'admitida',
		 'secuencia', 'Dos mitades de tres versos con la misma disposición interna, enlazadas por la rima que cierra cada una.',
		 'revisada');

	-- «Copla manriqueña» nombra la sextilla de pie quebrado, no solo la doble. Los nombres
	-- equivalentes se codifican como denominación, además de constar en las afirmaciones.
	delete from public.denominaciones_metricas where arquitectura_id = v_quebrado;
	insert into public.denominaciones_metricas (
		arquitectura_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_quebrado, 'Copla de Jorge Manrique', 'copla_de_jorge_manrique', false, v_quilis),
		(v_quebrado, 'Estrofa manriqueña', 'estrofa_manriquena', false, v_quilis),
		(v_quebrado, 'Copla manriqueña', 'copla_manriquena', false, v_dicc);

	-- Los nombres de las disposiciones con nombre propio. «Simétrica» y «paralela» nombran la
	-- misma disposición en dos fuentes: Navarro Tomás la escribe aab:ccb y el Diccionario la
	-- describe como dos mitades de tres versos ordenadas simétricamente.
	select esquema_rima_id into v_esq from public.esquemas_rima
	where arquitectura_id = v_octo and slug = 'aabccb';
	delete from public.denominaciones_metricas where esquema_rima_id = v_esq;
	insert into public.denominaciones_metricas (
		esquema_rima_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_esq, 'Sextilla simétrica', 'sextilla_simetrica', false, v_navarro),
		(v_esq, 'Sextilla paralela', 'sextilla_paralela', false, v_dicc);

	select esquema_rima_id into v_esq from public.esquemas_rima
	where arquitectura_id = v_octo and slug = 'abcabc';
	delete from public.denominaciones_metricas where esquema_rima_id = v_esq;
	insert into public.denominaciones_metricas (
		esquema_rima_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values (v_esq, 'Sextilla correlativa', 'sextilla_correlativa', false, v_dicc);

	select esquema_rima_id into v_esq from public.esquemas_rima
	where arquitectura_id = v_octo and slug = 'ababab';
	delete from public.denominaciones_metricas where esquema_rima_id = v_esq;
	insert into public.denominaciones_metricas (
		esquema_rima_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values (v_esq, 'Sextilla alterna', 'sextilla_alterna', false, v_dicc);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafes «Coplas» y «Coplas de pie quebrado»',
		 'No definen la sextilla como forma independiente en su repertorio de Lope de Vega. Reúnen bajo «coplas» las estrofas breves que no encajan en definiciones más específicas, y describen aparte las coplas de pie quebrado como octosílabos combinados con su quebrado de cuatro o cinco sílabas, en estrofas de cinco a doce versos.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 5.4.5.4',
		 'Define la sextilla como estrofa de versos de arte menor con varias combinaciones de rima, y cita aabaab, abcabc y ababab. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 22, 38, 63 y 308',
		 'Documenta la sextilla alterna ababab desde el repertorio juglaresco y la sextilla simétrica de tres rimas aab:ccb, junto a la variante de dos abb:abb. Señala que, fuera de su papel en las coplas de pie quebrado, la sextilla de octosílabos plenos se usó escasamente, y que aparece a veces en formas libres y asimétricas con algún quebrado. En el siglo XIX registra la sextilla del Martín Fierro, abbccb, con el primer verso suelto y sin eludir del todo la asonancia, y la sextilla aguda aaé:bbé.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 196-198',
		 'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, y con un poema de Manuel Machado compuesto en heptasílabos. Describe la copla de Jorge Manrique como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c y recoge que se ha considerado también estrofa de doce versos cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada una.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entradas «sextilla» y sus variedades',
		 'Define la sextilla como estrofa de seis versos de arte menor cuya rima puede adoptar variadas disposiciones, y recoge «redondilla de seis versos» como otro nombre. Tipifica la alterna, con dos rimas alternadas; la correlativa, en que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto; y la paralela, dividida en dos partes de tres versos ordenadas simétricamente. La sextilla de pie quebrado la describe como copla de pie quebrado en dos semiestrofas de tres versos, con disposiciones aabaab, aabccb o abcabc.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Estrofas de seis versos» y «Sextillas»',
		 'Reserva el nombre de sextilla para las estrofas de seis versos de arte menor y las ordena por medida, describiendo sextillas tetrasilábicas, pentasilábicas, hexasilábicas, heptasilábicas y octosilábicas. Documenta la sextilla alterna ababab en el repertorio juglaresco y en el Libro de Buen Amor, y el tipo aabccb en la Historia Troyana. Llama a las coplas de pie quebrado sextillas simétricas cuyos versos tercero y sexto son menores, con disposición más usual abc:abc, y advierte que el orden de las rimas varía de una composición a otra; entre sus variaciones cita las sextillas de Ricardo Gil, donde el tetrasílabo quiebra el segundo verso y el quinto.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La Sextilla debe tener seis afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_octo;
	if v_n <> 4 then
		raise exception 'La sextilla octosilábica debe tener cuatro esquemas de rima, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas d
	join public.arquitecturas_forma a on a.arquitectura_id = d.arquitectura_id
	where a.forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'La sextilla de pie quebrado debe declarar tres denominaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas d
	join public.esquemas_rima e on e.esquema_rima_id = d.esquema_rima_id
	where e.arquitectura_id = v_octo;
	if v_n <> 4 then
		raise exception 'Las disposiciones nombradas de la sextilla deben ser cuatro, no %', v_n;
	end if;

	select count(*) into v_n from public.arquitecturas_forma
	where forma_id = v_forma and activo;
	if v_n <> 5 then
		raise exception 'La Sextilla debe tener cinco arquitecturas activas, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
