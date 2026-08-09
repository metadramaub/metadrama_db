-- El zéjel contrastado con las seis fuentes autorizadas.
--
-- No declaraba ninguna afirmación: era la última de las tres formas que se quedaron sin
-- respaldo al retirarse las cinco fuentes no autorizadas. Su formalización técnica —estribillo,
-- ciclo de copla con mudanza monorrima de tres versos y verso de vuelta— **la confirman las
-- cinco fuentes que lo tratan**, de modo que la estructura no cambia. Lo que aportan es su
-- nombre alternativo, su historia y una duda resuelta.
--
-- 1. Tiene otro nombre y el catálogo no lo tenía: **estribote**. El Diccionario lo da como
--    término equivalente junto a «estrabot», y Caparrós 2014 explica que se aplicó a esta misma
--    forma hasta el siglo XV, por usarse el esquema como finida de un poema más amplio. Se
--    codifican como denominaciones, con su fuente.
--
-- 2. **Queda resuelta la duda 1 para el IP: el estribillo de uno o dos versos es correcto.**
--    Caparrós 2014 y el Diccionario dicen «un estribillo de uno o dos versos»; Quilis precisa
--    que en el zéjel «de ordinario, son dos», frente al villancico, donde generalmente son tres
--    o cuatro. Es decir: el dístico es lo ordinario, no lo exigido. La arquitectura ya admite
--    uno o dos y no hay que reservar el zéjel estricto para el dístico.
--
-- 3. Lo que separa al zéjel del villancico es la mudanza, y conviene que la definición lo diga
--    porque es la confusión más probable. Quilis: en el villancico la mudanza es una redondilla
--    y en el zéjel un trístico monorrimo. Caparrós 2014 añade la segunda diferencia, que el
--    catálogo ya modela: **la ausencia de verso de enlace**. La relación `contrasta_con` entre
--    ambas formas ya existía; ahora la definición no depende de ella para entenderse.
--
-- 4. Es forma del corpus, no solo medieval, y eso no constaba. Navarro Tomás documenta que en
--    el Siglo de Oro la tradición del zéjel persistía «principalmente en la lírica devota y en
--    las canciones del teatro», con ejemplos en *Los baños de Argel* de Cervantes y en dos
--    comedias de Lope de Vega. Es el dato que justifica que la forma esté en un catálogo de
--    verso dramático.
--
-- 5. Se documentan variantes que el catálogo no admite y que **no se añaden**: Navarro Tomás
--    registra zéjeles en arte mayor, modificaciones del estribillo y la vuelta —`aba:cccba`,
--    `abba:cccaca`— y una variante con la mudanza reducida a dos versos, `aa:bba`, presente
--    también en el Siglo de Oro. Quedan como afirmación y como duda: la mudanza de tres versos
--    es hoy definitoria de la forma y relajarla es una decisión del IP, no de esta revisión.
--
-- Morley y Bruerton no lo registran entre las formas métricas de Lope, pese a que Navarro Tomás
-- documenta zéjeles en dos de sus comedias: su repertorio describe la versificación del diálogo
-- y agrupa bajo «coplas» las estrofas breves que no encajan en definiciones más específicas.
--
-- No se toca ninguna secuencia real: ningún término legado propone hoy esta forma.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'zejel';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_y_coplas_monorrimas';

	if num_nonnulls(
		v_forma, v_arq, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 7 then
		raise exception 'Falta el zéjel vigente, su arquitectura o una fuente autorizada';
	end if;

	-- La definición dice qué es y qué lo separa del villancico, que es su vecino más cercano.
	update public.formas_metricas
	set definicion = 'Composición de forma fija y arte menor, normalmente octosílaba, que abre con un estribillo de uno o dos versos y continúa con una o más coplas. Cada copla se divide en una mudanza de tres versos monorrimos, con una rima nueva en cada estrofa, y un verso de vuelta que recupera la rima del estribillo; después el estribillo suele repetirse. Se distingue del villancico por esa mudanza monorrima, frente a la redondilla, y porque la vuelta sigue a la mudanza sin verso de enlace.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Estribillo inicial de uno o dos versos seguido de ciclos formados por una copla y la posible reaparición del estribillo. La copla contiene tres versos monorrimos de mudanza y un verso de vuelta.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- Los otros nombres de la forma.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Estribote', 'estribote', false, v_dicc),
		(v_forma, 'Estrabot', 'estrabot', false, v_dicc);

	-- Una afirmación por cada fuente que lo trata. Morley y Bruerton no lo registran.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_quilis, v_forma, '§ 6.3.2',
		 'Explica que procede de una forma popular de la poesía arábigo-española y aparece en la lírica castellana en el siglo XIV. Lo describe normalmente en octosílabos, con estribillo de uno o dos versos, mudanza de tres versos monorrimos y un cuarto verso de vuelta que rima con el estribillo, según el esquema aa-bbba. Precisa que se diferencia del villancico sobre todo por la mudanza —redondilla en el villancico, trístico monorrimo en el zéjel— y, de manera menos constante, por el estribillo: en el villancico suele tener tres o cuatro versos y en el zéjel, de ordinario, dos.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 14, 92 y 211',
		 'Atribuye su invención a Mucáddam de Cabra hacia 920 y lo describe como estribillo breve, terceto monorrimo de mudanza cuyo consonante cambia en cada estrofa y verso final de vuelta que recoge la rima del estribillo. Señala que la forma típica aa:bbba mantiene su predominio, pero registra zéjeles en arte mayor y variantes que modifican estribillo y vuelta, como aba:cccba y abba:cccaca. En el Siglo de Oro la tradición persistía principalmente en la lírica devota y en las canciones del teatro, con ejemplos en *Los baños de Argel* de Cervantes y en *Los amores de Albanio e Ismenia* y *El vaquero de Moraña* de Lope de Vega; documenta además la variante con la mudanza reducida a dos versos, aa:bba.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 213-214',
		 'Lo define como poema de forma fija cuyas partes son un estribillo de uno o dos versos que riman entre sí y una estrofa dividida en un cuerpo o mudanza de tres versos monorrimos y un verso de vuelta que rima con el estribillo, siendo el octosílabo el verso más usado. De origen mozárabe, se emplea en canciones de amor y preferentemente de escarnio, y su uso llega hasta el siglo XVII. Lo diferencia del villancico por la forma de la mudanza y por la ausencia del verso de enlace con ella, y explica que el nombre de estribote se dio a esta misma forma hasta el siglo XV.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entrada «zéjel»',
		 'Lo define como poema de forma fija con un estribillo de uno o dos versos y una estrofa dividida en un cuerpo o mudanza de tres versos monorrimos y un verso de vuelta que rima con el estribillo, con el octosílabo como verso más usado. Indica que se diferencia del villancico por la forma de la mudanza y de la vuelta, que su uso llega hasta el siglo XVII, y recoge estrabot, estribote y villancico como otros términos aplicados a esta forma.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Zéjel» y «Villancico»',
		 'Lo presenta como una forma estrófica antiquísima y, en realidad, un modo de villancico, formada por una cabeza o estribillo, una mudanza de un terceto monorrimo y una vuelta a la rima del estribillo, según el esquema aa: bbba. Reserva el término villancico para las composiciones cuya mudanza no es monorrima y emplea otros nombres, entre ellos el de zéjel, cuando sí lo es. Señala que el terceto monorrimo fue mayoritariamente la forma primitiva del cuerpo del zéjel.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 5 then
		raise exception 'El Zéjel debe tener cinco afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas where forma_id = v_forma;
	if v_n <> 2 then
		raise exception 'El Zéjel debe declarar dos denominaciones, no %', v_n;
	end if;

	-- La mudanza sigue siendo de tres versos: es lo definitorio y no se relaja aquí.
	select versos_min into v_n from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'mudanza';
	if v_n <> 3 then
		raise exception 'La mudanza del zéjel debe seguir siendo de tres versos, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
