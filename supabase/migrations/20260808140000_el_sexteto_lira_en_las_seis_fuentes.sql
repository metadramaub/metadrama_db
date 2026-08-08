-- El sexteto-lira contrastado con las seis fuentes autorizadas.
--
-- Solo declaraba la afirmación de Caparrós 2014, y su definición describía el reparto interno
-- del catálogo —«siete tipologías que combinan cinco patrones métricos y tres distribuciones»—
-- en vez de decir qué es la forma. Las seis fuentes la tratan, y las seis la subordinan a la
-- lira.
--
-- 1. Su identidad es la de una lira de seis versos, y eso faltaba. El Diccionario la define
--    literalmente como «Lira de seis versos» y remite a ella desde «lira-sestina» y «sexteto
--    alirado». Jauralde la llama «la variedad más usada de la lira». Navarro Tomás la sitúa
--    entre las estrofas aliradas y observa que la sustitución de los endecasílabos impares por
--    heptasílabos es el único rasgo que la separa de la sexta rima. La definición lo dice
--    ahora, y la relación `derivada_de lira` que ya existía deja de ser el único sitio donde
--    consta.
--
-- 2. Morley y Bruerton, que son la fuente especializada en el verso dramático de Lope, no la
--    llaman sexteto-lira: la llaman **Lira**, sin más, y describen exactamente esta estrofa de
--    seis versos. Es el nombre con el que está anotada la métrica de las comedias, así que se
--    declara como denominación con su fuente, además de constar en la afirmación. Lo mismo se
--    hace con «sexteto alirado» y «lira-sestina», que el Diccionario da como equivalentes.
--
-- 3. El repertorio de siete tipologías no es cerrado, y las fuentes lo demuestran. Navarro
--    Tomás enumera aBaBCC, AbAbcC, AbbAcC, AabBCC «etc.» y Morley y Bruerton aBaBcC, abbacC,
--    AabBcC, AabBCC «etc.». Entre ellas, AbAbcC y AbbAcC no están en el catálogo. No se añaden
--    aquí: al declarar la modalidad de las siete como admitidas y no como repertorio cerrado,
--    la forma queda descrita sin comprometer el modelo. Cuáles falten y en qué nivel viven es
--    lo que debe resolver la lectura transversal de la variedad, porque siete de las ocho
--    variedades del catálogo están en esta forma.
--
-- 4. Morley y Bruerton añaden una restricción que el catálogo no recogía: en Lope el último
--    verso es siempre endecasílabo. Las cinco tipologías métricas la cumplen, de modo que no
--    hay nada que corregir; se registra porque es un dato del corpus dramático y no una
--    casualidad del reparto.
--
-- 5. Navarro Tomás documenta el sexteto simétrico abC:abC de san Juan de la Cruz, que es de
--    seis versos de siete y once sílabas pero no cierra con pareado, de modo que no cabe en la
--    definición de esta forma. Queda en la afirmación, no se fuerza como tipología.
--
-- No se toca ninguna secuencia real. Las siete tipologías conservan su slug y su origen
-- legado, así que las equivalencias no se mueven.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_lira uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto_lira';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heterometrica_consonante';
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';

	if num_nonnulls(
		v_forma, v_arq, v_lira,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 9 then
		raise exception 'Falta el sexteto-lira vigente, su arquitectura, la lira o una fuente';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición dice qué es la forma y de dónde viene, no cuántas tipologías guarda el
	-- catálogo: eso lo lista la ficha debajo.
	update public.formas_metricas
	set definicion = 'Lira de seis versos: estrofa de heptasílabos y endecasílabos con rima consonante en tres clases, cuyos cuatro primeros versos alternan o abrazan las dos primeras y cuyos dos últimos cierran con un pareado que introduce la tercera. El orden de las medidas y la disposición de las rimas varían conjuntamente, de modo que cada realización se registra por la tipología observada.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Seis versos que combinan heptasílabos y endecasílabos y terminan en endecasílabo. La tipología determina conjuntamente el orden de las medidas y la distribución de las tres rimas.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- Los nombres con los que la bibliografía designa esta misma estrofa. «Lira» es el que usan
	-- Morley y Bruerton, con el que está descrita la métrica de las comedias de Lope.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Lira', 'lira_de_seis_versos', false, v_mb),
		(v_forma, 'Sexteto alirado', 'sexteto_alirado', false, v_dicc),
		(v_forma, 'Lira-sestina', 'lira_sestina', false, v_dicc);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafe «Liras»',
		 'Llaman lira, sin otro nombre, a la estrofa de seis versos de siete y once sílabas con tres rimas, en la que los cuatro primeros llevan dos rimas y los dos últimos forman un pareado con la tercera. Precisan que en Lope de Vega el último verso tiene once sílabas. Consideran regular la forma aBaBcC y citan además abbacC, AabBcC y AabBCC entre otras. Observan que el tipo adoptado al comienzo de un pasaje suele conservarse a lo largo de todo él.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 5.4.5.2',
		 'Define el sexteto-lira como estrofa formada por heptasílabos y endecasílabos alternados con rima aBaBcC, y la ejemplifica con la traducción del *O navis* de Horacio por fray Luis de León. Añade que san Juan de la Cruz empleó también esta estrofa disponiendo los metros y las rimas de manera simétrica.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 110, 161 y 229',
		 'Describe la estrofa de seis versos de siete y once sílabas en orden alterno, con los cuatro primeros de rimas cruzadas y los dos últimos pareados, aBaBcC, que fray Luis de León empleó en sus traducciones de Horacio. Señala que la sustitución de los endecasílabos impares por heptasílabos es el único rasgo que la diferencia de la sexta rima italiana. Registra que sirvió en el teatro para escenas líricas, con ejemplos de Virués, Cervantes, Lope de Vega y Montalbán, y que ofrece varias combinaciones de versos y rimas: aBaBCC, AbAbcC, AbbAcC, AabBCC y otras. Documenta aparte el sexteto simétrico abC:abC que san Juan de la Cruz usó en la *Llama de amor viva*.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'p. 198',
		 'Define el sexteto lira como la combinación de heptasílabos y endecasílabos con rima consonante que puede presentar distintos esquemas, y lo ejemplifica con la «Oda V» de las *Eróticas o amatorias* de Esteban Manuel de Villegas y con «La nube de verano» de Rubén Darío.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entrada «sexteto-lira»',
		 'Lo define como lira de seis versos y precisa que es una clase de lira que sirve como estrofa de la canción alirada. Lo ejemplifica con unos versos de fray Luis de León y recoge «lira-sestina» y «sexteto alirado» como otros nombres de la misma estrofa.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Variedades de la lira, el sexteto-lira» y «Estrofas de seis versos»',
		 'Lo presenta como la variedad más usada de la lira, probablemente, y señala que no se quedó en la poesía lírica sino que acabó por invadir las tablas teatrales, ocupando muchas veces el lugar de la canción, como en casi todas las de Lope de Vega en sus *Rimas sacras*. Lo documenta ya en las traducciones de fray Luis de León y en la *Llama de amor viva* de san Juan de la Cruz, y lo cuenta entre los sextetos mixtos, que aparta como grupo propio junto a los simétricos.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El Sexteto-lira debe tener seis afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas where forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'El Sexteto-lira debe declarar tres denominaciones, no %', v_n;
	end if;

	-- Las siete tipologías siguen siendo las reconocidas, y siguen sin ser un repertorio
	-- cerrado: dos fuentes enumeran combinaciones que el catálogo no tiene y terminan en «etc.».
	select count(*) into v_n from public.variedades_arquitectura where arquitectura_id = v_arq;
	if v_n <> 7 then
		raise exception 'El Sexteto-lira debe conservar sus siete tipologías, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
