-- La canción petrarquista contrastada con las seis fuentes autorizadas.
--
-- Declaraba una sola afirmación, la de Caparrós 2014, y su ficha atribuía al criterio del IP
-- dos decisiones que en realidad **están en la bibliografía y se pueden documentar**. Las seis
-- fuentes la tratan.
--
-- 1. **Queda resuelta la duda 3 para el IP: el intervalo 5-20 es de Morley y Bruerton.** La
--    ficha decía que la fuente sitúa la estancia entre 9 y 20 —cierto en Caparrós 2014 y en el
--    Diccionario— y que el 5 lo fijaba el proyecto. Pero Morley y Bruerton, describiendo la
--    canción de Lope, dicen literalmente «estrofas de 5 a 20 versos». El límite inferior no es
--    una licencia del catálogo: es el dato de la fuente especializada en el corpus dramático.
--    Se conserva y ahora se sostiene.
--
-- 2. **La canción sin rima tampoco es una aportación sin fuente.** La ficha decía que procedía
--    del criterio del IP y que no se atribuía a ninguna fuente. Morley y Bruerton la registran
--    como forma propia —«Canción sin rima»— y la describen igual que el catálogo: versos de
--    siete y once sílabas en estrofas sin rima excepto un pareado final. La arquitectura
--    `sin_rima_con_pareado_final` queda respaldada.
--
-- 3. La forma tiene otros nombres y no tenía ninguno declarado. El Diccionario la registra bajo
--    «canción a la italiana» y remite a ella desde «canción petrarquista» y «canción extensa»;
--    Jauralde añade que con el término simple «canción» se alude normalmente a esta. Se
--    codifican como denominaciones.
--
-- 4. El esquema de la arquitectura regular tiene autor y modelo, y merece decirse. Navarro Tomás
--    documenta que `abCabC:cdeeDfF` es la estancia de la segunda égloga de Garcilaso, usada por
--    Herrera en su canción quinta e imitada después muchas veces, con la canción undécima de
--    Petrarca por modelo. Morley y Bruerton la llaman «regular» por ser la más corriente en
--    Lope, que es la razón de que el catálogo la tenga como arquitectura principal.
--
-- 5. Se documenta un límite que el catálogo roza y que conviene tener anotado: Jauralde sitúa la
--    estancia «normalmente por encima de los ocho versos (para diferenciarla de las liras)», y
--    el Diccionario describe la canción alirada como la variante cuya unidad estrófica oscila
--    entre cuatro y ocho versos. Es decir, el tramo bajo del intervalo 5-20 solapa con el
--    territorio de la lira y del sexteto-lira. No se toca el intervalo, que es el de Morley y
--    Bruerton; queda como duda para el IP.
--
-- No se toca ninguna secuencia real ni ninguna equivalencia.

begin;

do $$
declare
	v_forma uuid;
	v_regular uuid;
	v_variables uuid;
	v_sin_rima uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas
	where slug = 'cancion_petrarquista';
	select arquitectura_id into v_regular from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'regular_13_versos';
	select arquitectura_id into v_variables from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estancias_consonantes_variables';
	select arquitectura_id into v_sin_rima from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'sin_rima_con_pareado_final';

	if num_nonnulls(
		v_forma, v_regular, v_variables, v_sin_rima,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 10 then
		raise exception 'Falta la canción petrarquista vigente, una arquitectura o una fuente';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición dice qué es la composición, no qué distingue el catálogo dentro de ella.
	update public.formas_metricas
	set definicion = 'Composición formada por un mínimo de tres estancias de igual estructura, que combinan heptasílabos y endecasílabos consonantes, y que suele cerrarse con un fragmento de estancia más breve llamado remate, envío o *commiato*. Todas las estancias repiten la misma distribución de medidas y el mismo esquema de rima, que la primera establece; la estancia admite en cambio muy distintas extensiones y disposiciones.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Estancias de trece versos con distribución métrica y esquema consonante fijos, abCabC:cdeeDfF. Es la realización más frecuente en el corpus dramático.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_regular;

	update public.arquitecturas_forma
	set descripcion = 'Tres o más estancias de cinco a veinte versos. La primera declara su distribución de heptasílabos y endecasílabos y su esquema consonante, y las demás los repiten.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_variables;

	update public.arquitecturas_forma
	set descripcion = 'Estancias de heptasílabos y endecasílabos cuyo cuerpo queda sin rima y que cierran con un pareado consonante.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_sin_rima;

	-- Los otros nombres de la composición.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Canción a la italiana', 'cancion_a_la_italiana', false, v_dicc),
		(v_forma, 'Canción extensa', 'cancion_extensa', false, v_dicc),
		(v_forma, 'Canción', 'cancion', false, v_mb);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafes «Canción (Canzone)» y «Canción sin rima»',
		 'Describen la canción como versos de siete y once sílabas agrupados en estrofas de cinco a veinte versos, con un tipo de rima fijo e idéntico en cada estrofa de un mismo pasaje, y advierten que rara vez se encuentra un pasaje de rima mezclada. Llaman regular al tipo más corriente en Lope de Vega, de trece versos, abCabC:cdeeDfF, y señalan que rara vez la canción es toda de endecasílabos. Registran aparte la canción sin rima: versos de siete y once sílabas en estrofas sin rima, excepto un pareado final.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 6.3.6',
		 'La presenta como descendiente de la antigua *cansó* provenzal, introducida por Boscán sobre el modelo de la *canzone* italiana reelaborada por Dante, y advierte que fue ganando libertad entre los poetas españoles. Señala que el número de estancias y el de versos de cada una son variables —entre nueve y veinte en Petrarca, quince en la primera de Boscán, trece en Garcilaso— y que no había norma sobre la naturaleza ni la disposición de la rima, aunque el patrón de la primera estrofa debe repetirse rigurosamente en las demás. Describe la estancia como fronte dividida en dos *piedi*, una coda y un verso de unión llamado *volta* que rima con el último verso del segundo *piede*, y sitúa al final una estrofa más breve, la *tornata* o envío.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§ 108',
		 'Describe la estancia como la estrofa de las canciones y églogas renacentistas y, en contraste con la regularidad del soneto, como la más variable de la métrica italiana, cuya extensión y combinación de rimas dejaban amplio margen a la libertad del poeta. Explica que constaba de dos partes, la primera más breve y generalmente en endecasílabos, con los heptasílabos intercalados sobre todo en la segunda o marcando la transición entre ambas. Documenta que Boscán compuso canciones de hasta veintisiete estrofas de quince versos y Garcilaso composiciones de cuatro o cinco estancias de trece, y que la estancia abCabC:cdeeDfF de su segunda égloga, tomada de la canción undécima de Petrarca, fue usada por Herrera e imitada después en numerosas ocasiones.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 214-216',
		 'Define la estancia como estrofa de endecasílabos y heptasílabos, no menos de nueve ni más de veinte, normalmente sin orden predeterminado y rimados en consonante. Describe como frecuente, aunque no obligatorio, el esquema de fronte o *capo* formada por dos pies, un eslabón o llave que rima con el último verso de la fronte pero pertenece sintácticamente a la sirima, y una sirima o coda con rimas independientes que suele incluir dos o tres pareados. La canción se compone de un número indeterminado de estancias, tres como mínimo, todas de igual distribución de rimas y medidas, y acaba en un fragmento de estancia llamado remate, envío o *commiato*, en el que el poeta suele dirigirse a la canción.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entradas «canción a la italiana» y «estancia»',
		 'Registra la composición bajo el nombre de canción a la italiana y la define como poema de un número indeterminado de estancias, tres como mínimo, acabado en un fragmento de estancia que normalmente tiene el primer verso suelto, llamado remate, envío o *commiato*, con la misma distribución de rimas y de versos de once y siete sílabas en todas las estancias. Define la estancia entre nueve y veinte versos con fronte, eslabón y sirima. Describe aparte la canción alirada como variante cuyas estrofas, cortas y simétricas, prescinden de la ordenación rigurosa de la estancia y cuya unidad estrófica oscila entre cuatro y ocho versos.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Canción petrarquista» y «Estancias»',
		 'Explica que con el término simple «canción» suele aludirse a la petrarquista, cultivada desde el siglo XVI, frente a la canción medieval del siglo XV. La compone de un mínimo de tres estancias iguales terminadas en otra mucho más breve, el envío o *commiato*, en la que se señala explícitamente a la canción esa dedicatoria. Define la estancia como repetición regular de una estrofa de versos de siete y once sílabas dispuestos de modo aleatorio, normalmente por encima de los ocho versos, para diferenciarla de las liras, y observa que adoptó desde muy pronto estructuras más rígidas o flexibles según la cantidad y disposición de los versos.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La Canción petrarquista debe tener seis afirmaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas where forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'La Canción petrarquista debe declarar tres denominaciones, no %', v_n;
	end if;

	-- El intervalo de la estancia variable es el de Morley y Bruerton y no se toca.
	select versos_min into v_n from public.estructuras_secciones
	where arquitectura_id = v_variables and slug = 'estancia';
	if v_n <> 5 then
		raise exception 'La estancia variable debe seguir admitiendo desde 5 versos, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
