-- La copla real contrastada con las seis fuentes autorizadas.
--
-- No declaraba ninguna afirmación: es una de las tres formas que se quedaron sin respaldo al
-- retirarse las cinco fuentes que no cumplían el criterio de autoridad. Las seis autorizadas la
-- tratan, y coinciden en el núcleo que el catálogo ya tenía —diez octosílabos en dos quintillas
-- con rimas independientes—, de modo que la forma no cambia de fondo. Lo que aportan es todo lo
-- demás.
--
-- 1. Tiene nombres y el catálogo no tenía ninguno. Caparrós 2014 dice que se la llama a veces
--    quintilla doble y décima falsa; el Diccionario añade estancia real y remite desde las tres
--    entradas; Quilis registra que modernamente se ha denominado falsa décima. Jauralde aporta
--    el nombre que importa a un corpus dramático: en el Siglo de Oro se llamaron **redondillas
--    castellanas**, y era estrofa preferida por Juan del Encina, Castillejo, Hurtado de Mendoza
--    y Cervantes, sobre todo por su uso en los tablados. Se codifican como denominaciones, con
--    su fuente, además de constar en las afirmaciones.
--
-- 2. La independencia de las rimas es lo que la separa de la décima, y conviene que la
--    definición lo diga. El Diccionario y Caparrós 2014 subrayan que las dos semiestrofas
--    pueden tener o no el mismo esquema, pero que sus rimas son independientes; Caparrós lo
--    contrasta expresamente con la espinela, donde hay rima común a las dos partes. La relación
--    con la Décima ya existe como `sucede_historicamente_a`; ahora la definición explica en qué
--    se distinguen.
--
-- 3. La estructura 5+5 no fue siempre la única. Jauralde documenta que la forma 4-6 precede a
--    la 5-5, que solo se hace mayoritaria a finales del siglo XV, y Navarro Tomás describe el
--    mismo proceso desde el modelo 4-4. El catálogo registra la 5+5 porque es la del corpus
--    áureo; que no sea la única histórica se anota como afirmación y como duda, no se convierte
--    en arquitectura.
--
-- 4. Morley y Bruerton añaden una restricción del corpus dramático que el catálogo no recoge:
--    en Lope las dos quintillas son de tipo diferente, la segunda siempre AABBA y la primera
--    casi siempre ABABA. Hoy las dos preguntas ofrecen los ocho esquemas con independencia. No
--    se restringe el repertorio, porque el catálogo cubre más que a Lope y porque la libertad
--    de disposición es justamente lo que las otras cinco fuentes describen; queda como dato de
--    fuente y como duda para el IP.
--
-- No se toca ninguna secuencia real ni se cambia ninguna equivalencia.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'copla_real';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica_consonante';

	if num_nonnulls(
		v_forma, v_arq, v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 8 then
		raise exception 'Falta la copla real vigente, su arquitectura o una fuente autorizada';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición dice qué es la forma y qué la distingue de la décima, no cuántas
	-- configuraciones reconoce el catálogo: hay una sola.
	update public.formas_metricas
	set definicion = 'Estrofa de diez octosílabos organizada en dos quintillas separadas por una pausa estructural. Cada quintilla lleva sus propias rimas consonantes, sin ninguna común a las dos, y ambas pueden repetir o no el mismo esquema; esa independencia es lo que la separa de la décima espinela. Admite que uno o dos versos aparezcan quebrados.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Diez octosílabos repartidos en dos quintillas de cinco versos. Uno o dos pueden ser quebrados.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- Los nombres que la bibliografía le da. «Redondillas castellanas» es el del Siglo de Oro,
	-- que es el que puede aparecer en la documentación de una comedia.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Quintilla doble', 'quintilla_doble', false, v_cap14),
		(v_forma, 'Décima falsa', 'decima_falsa', false, v_cap14),
		(v_forma, 'Estancia real', 'estancia_real', false, v_dicc),
		(v_forma, 'Redondillas castellanas', 'redondillas_castellanas', false, v_jauralde);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafe «Copla real»',
		 'La describen como combinación fija de dos quintillas de tipo diferente. Precisan que en Lope de Vega la segunda es siempre la quintilla AABBA y la primera casi siempre ABABA, muy pocas veces ABBAB o ABAAB.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 5.4.8.1',
		 'La sitúa entre las estrofas de diez versos de arte menor y explica que, como la quintilla y la redondilla no tenían vida independiente en la Edad Media, a veces se fundían dos quintillas dando lugar a esta estrofa. Añade que modernamente se la ha denominado falsa décima y ejemplifica con un paso de Juan de Timoneda de esquema abaab cdccd.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 66 y 128',
		 'Explica que la copla de semiestrofas equivalentes 5-5, con dos rimas distintas en cada parte, apareció a mediados del siglo XV y se formó sobre el antiguo modelo de 4-4, en el que el papel de la redondilla sirvió de base para el triunfo de la quintilla. Señala que el tipo simétrico abaab:cdccd, repetido con preferencia por Juan de Mena, se destacó sobre las demás combinaciones hasta reconocerse como representación característica de la estrofa y como una de las más peculiares de la poesía castellana del siglo XV.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'p. 199',
		 'La define como combinación de diez octosílabos agrupados en dos quintillas con rimas consonantes independientes, y precisa que las dos semiestrofas pueden tener o no el mismo esquema de distribución. Recoge que a veces se la llama quintilla doble y décima falsa, la sitúa en el grupo de las coplas medievales y afirma que su cultivo llega hasta el Siglo de Oro. Contrasta esa independencia de rimas con la décima espinela, donde una rima es común a las dos partes.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entrada «copla real»',
		 'La define como combinación estrófica de diez octosílabos dividida en dos quintillas con rimas consonantes independientes, cuyas semiestrofas pueden tener o no el mismo esquema de distribución y admiten algún verso quebrado tetrasílabo. La incluye en el grupo de coplas muy frecuentes en la poesía medieval cuyo cultivo llega al Siglo de Oro, y recoge décima falsa, estancia real y quintilla doble como otros nombres.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartado «Copla real»',
		 'La describe como combinación de diez octosílabos en dos semiestrofas unidas por tres o cuatro rimas, aparecida a lo largo del siglo XV, quizá como elaboración de las coplas castellanas y de arte menor. Advierte que las semiestrofas no son necesariamente iguales y que la forma 4-6 precede a la 5-5, que solo se hace mayoritaria a finales del siglo XV. Afirma que es quizá la copla de mayor vigencia durante el periodo áureo, cuando se llamaron redondillas castellanas y fue estrofa preferida por Juan del Encina, Castillejo, Hurtado de Mendoza y Cervantes, sobre todo por su uso en los tablados, y que con el tiempo llegó a quebrar alguno de sus versos.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La Copla real debe tener seis afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas where forma_id = v_forma;
	if v_n <> 4 then
		raise exception 'La Copla real debe declarar cuatro denominaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.arquitecturas_forma
	where forma_id = v_forma and activo;
	if v_n <> 1 then
		raise exception 'La Copla real debe tener una sola arquitectura activa, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
