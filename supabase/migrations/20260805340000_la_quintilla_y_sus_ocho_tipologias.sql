-- La quintilla: definición, las ocho tipologías descritas y las seis fuentes.
--
-- Sexta forma de la revisión y la tercera del corpus con 16 secuencias. Tenía una sola
-- afirmación, de una sola fuente, y las ocho tipologías sin describir.
--
-- 1 · **La definición enumeraba los ocho esquemas** que la ficha lista justo debajo, y
--     explicaba cuál es la excepción. Eso lo dice ahora cada tipología en su descripción. La
--     definición se queda con lo que **genera** esos ocho, que es lo que ninguna lista dice:
--     las condiciones que una quintilla debe cumplir.
--
-- 2 · **La arquitectura hablaba del registro**: «las ocho distribuciones reconocidas se
--     registran como patrones alternativos de esta configuración, no como formas ni
--     configuraciones independientes». Habla del registrador, y usa dos veces «configuración»,
--     que es vocabulario retirado. Como la quintilla tiene una sola arquitectura, no hay
--     hermanas de las que distinguirla: se queda vacía.
--
-- 3 · **Las ocho tipologías no decían nada.** Ahora cada una dice qué la caracteriza y, cuando
--     la bibliografía lo documenta, su frecuencia: las fuentes no las tratan como ocho casos
--     equivalentes.
--
-- El punto interesante de esta forma es que **las fuentes no coinciden en cuántas son**:
--
--   · Quilis da **cinco** —ababa, abaab, abbab, aabab, aabba—, las que salen de prohibir tres
--     rimas seguidas y el pareado final.
--   · Rengifo, en 1592, da esas mismas cinco y en ese orden, según Morley y Bruerton.
--   · Navarro Tomás da **siete**, numeradas 1 a 7, que son exactamente las siete primeras del
--     catálogo y en el mismo orden: de ahí vienen sus nombres «Tipología 1» a «Tipología 7».
--   · Morley y Bruerton dan las mismas siete y advierten que las dos últimas acaban en pareado
--     y son muy raras; registran además `abbba` como caso suelto que atribuyen a errata o a
--     una adaptación deliberada.
--   · Jauralde recoge `abbba` sin marcarlo como anómalo, y añade combinaciones con versos
--     sueltos que el catálogo no admite.
--
-- El catálogo declara las ocho, con `abbba` marcada como excepcional en su propio nombre. Es
-- una posición intermedia entre Morley y Bruerton, que la mencionan sin admitirla, y Jauralde,
-- que la admite sin reparos.
--
-- Y una divergencia de medida que se registra sin cambiar nada: el Diccionario dice
-- «octosílabos **o menores**» y Jauralde documenta quintillas hexasilábicas y heptasilábicas.
-- La única arquitectura del catálogo es octosilábica. Queda escrito para que el IP decida.

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
	v_sin_descripcion integer;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'quintilla';
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
		raise exception 'Falta la quintilla o su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- 1 · La definición dice lo que genera las ocho, no las enumera.
	update public.formas_metricas
	set definicion = 'Estrofa de cinco versos octosílabos con rima consonante repartida en dos clases, sin ningún verso suelto. La disposición no está fijada: vale cualquiera que no ponga tres versos seguidos con la misma rima ni cierre la estrofa en pareado. De esas dos condiciones salen las disposiciones que la tradición ha ido fijando.'
	where forma_id = v_forma;

	-- 2 · Arquitectura única: nada que distinguir, nada que decir.
	update public.arquitecturas_forma
	set descripcion = null
	where arquitectura_id = v_arq;

	-- 3 · Cada tipología dice qué la caracteriza y qué frecuencia le atribuye la bibliografía.
	update public.esquemas_rima
	set descripcion = case notacion
		when 'ababa' then
			'Las dos clases alternan verso a verso. Es la disposición más simple y más antigua, y la más frecuente en el teatro áureo.'
		when 'abbab' then
			'La segunda clase se abraza en el centro y vuelve a cerrar: abba más un verso que retoma la segunda.'
		when 'abaab' then
			'La primera clase se repite en el centro y la segunda cierra la estrofa.'
		when 'aabab' then
			'Abre con un pareado y sigue alternando. La bibliografía la registra como muy rara.'
		when 'aabba' then
			'Dos pareados encadenados que la primera clase abre y cierra. Es la segunda más frecuente.'
		when 'abbaa' then
			'Redondilla abrazada más un verso que repite su clase, de modo que la estrofa acaba en pareado. Poco frecuente.'
		when 'ababb' then
			'Alterna como la primera y acaba en pareado de la segunda clase. Poco frecuente.'
		when 'abbba' then
			'Tres versos seguidos con la misma rima, lo que ninguna otra disposición admite. Aparece de tarde en tarde y no todas las fuentes la aceptan como quintilla regular.'
		else descripcion
	end
	where arquitectura_id = v_arq;

	select count(*) into v_sin_descripcion
	from public.esquemas_rima where arquitectura_id = v_arq and descripcion is null;
	if v_sin_descripcion > 0 then
		raise exception 'Quedan % tipologías de quintilla sin describir', v_sin_descripcion;
	end if;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- Las condiciones que generan las disposiciones, y una medida que el catálogo no recoge.
		(v_dicc, v_forma, 'Entrada «quintilla», p. 296',
			'Fija cuatro condiciones: cinco versos octosílabos **o menores**, dos clases de rima consonante, no más de dos versos seguidos con la misma rima, y ni pareado final ni verso suelto. Añade que es estrofa muy usada en el teatro del Siglo de Oro, sobre todo en las partes narrativas y líricas, y que dentro de un mismo poema puede variar la disposición de unas quintillas a otras.',
			'alta'),

		-- Cinco, no siete ni ocho.
		(v_quilis, v_forma, 'pp. 98-99',
			'Deriva las disposiciones de las dos prohibiciones —ni tres versos seguidos con la misma rima ni pareado final— y concluye que las combinaciones posibles son **cinco**: ababa, abaab, abbab, aabab y aabba.',
			'alta'),

		-- De dónde salen los números que el catálogo usa.
		(v_navarro, v_forma, '§ 62',
			'Sostiene que la quintilla debió formarse sobre la redondilla por simple adición de un verso, y que se fue definiendo en el siglo XV dentro de las canciones y estrofas compuestas antes de hacerse independiente. Enumera **siete** tipos y los numera: 1 ababa, 2 abbab, 3 abaab, 4 aabab, 5 aabba, 6 abbaa, 7 ababb.',
			'alta'),

		-- Las mismas siete, con su frecuencia y el estatuto de la octava.
		(v_mb, v_forma, 'Cap. V, «Quintilla»',
			'Dan las mismas siete combinaciones y precisan que Rengifo, en su Arte poética de 1592, recoge solo las cinco primeras y en ese orden, omitiendo las dos que acaban en pareado, que se hallan alguna vez pero con muy poca frecuencia. Sobre su uso: la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara. Registran además que alguna vez aparece el tipo ABBBA, y lo atribuyen a un error de imprenta o a una adaptación especial para expresar un pensamiento.',
			'alta'),

		-- La octava sin reparos, y medidas que el catálogo no recoge.
		(v_jauralde, v_forma, '«Estrofas» → «Quintillas»',
			'Recoge abbba entre las disposiciones de la quintilla octosílaba sin marcarla como anómala, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca— que describe como transgresión de las viejas normas.',
			'alta'),

		-- El nombre antiguo, que explica un aviso ya registrado en la redondilla.
		(v_cap14, v_forma, 'p. 195',
			'Advierte que la quintilla se llamó antiguamente también redondilla, lo que explica que en los tratadistas del Siglo de Oro ese nombre cubriera estrofas de cinco o más versos.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Quintilla · definición, 8 tipologías descritas y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
