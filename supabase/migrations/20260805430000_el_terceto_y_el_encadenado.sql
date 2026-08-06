-- El terceto y el terceto encadenado: definiciones, un error y las seis fuentes.
--
-- Décima y undécima formas de la revisión. Se hacen juntas porque el catálogo las separa y
-- casi ninguna fuente lo hace: entender por qué las separa es la mitad del trabajo.
--
-- **Un error en la definición del terceto.** Decía «al menos, el primero rima con el tercero».
-- Es falso para uno de sus dos esquemas: en `-AA` el primer verso está declarado **suelto** y
-- riman el segundo y el tercero. Comprobado en `esquema_rima_posiciones`. Lo que sí vale para
-- los dos es que **dos de los tres versos riman entre sí y el otro queda suelto**.
--
-- **Una referencia a algo que no existe.** La misma definición remitía a «tercetos sin
-- encadenar» como si fuera una categoría del catálogo. No lo es: se decidió que era una tirada
-- de tercetos, no una forma, y sus dos disposiciones son justamente los dos esquemas de rima
-- del terceto. La definición no puede mandar al lector a un sitio que no existe.
--
-- **Un nombre que contradice a su sección.** Los dos esquemas del encadenado se llamaban igual,
-- «Encadenamiento consonante con cierre en serventesio», pero sus secciones no: la
-- endecasilábica cierra con «Serventesio final» y la octosilábica con «Redondilla cruzada
-- final». Un serventesio es de arte mayor, así que en octosílabos el nombre miente. Se corrige
-- el del esquema, que es el que estaba mal, y de paso se escribe su descripción, que faltaba.
--
-- Lo que las fuentes resuelven, y que estaba abierto en `cuestiones-para-el-ip.md`:
--
-- · **El verso sin rima y la rima usada cuatro veces son variantes, no desviaciones.** Lo dicen
--   Morley y Bruerton de la terza rima: los tercetos acaban generalmente como empiezan, «pero
--   de vez en cuando aparecen variantes: un verso sin rima, o una rima usada cuatro veces».
--
-- · **Los cierres en pareado o cuarteto de las series sin encadenar son canónicos.** También
--   Morley y Bruerton: del tipo `AXABYB` dicen que «puede acabar en un pareado o en un
--   cuarteto». Y su notación `AXA` / `XAA`, con X para el verso sin rima, es exactamente la
--   del catálogo: `A-A` y `-AA`.
--
-- Y una divergencia de fondo que se registra sin cambiar nada: **el Diccionario no separa las
-- dos formas.** Su entrada «terceto» describe directamente la cadena ABA BCB CDC… YZYZ, y
-- «terceto encadenado» remite a ella. El catálogo las separa porque la rima del encadenado
-- cruza el límite de la unidad, de modo que la serie entera es una sola unidad abierta y no una
-- sucesión de estrofas.

begin;

do $$
declare
	v_terceto uuid;
	v_arq_t uuid;
	v_cadena uuid;
	v_octo uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_terceto from public.formas_metricas where slug = 'terceto';
	select arquitectura_id into v_arq_t from public.arquitecturas_forma where forma_id = v_terceto;
	select forma_id into v_cadena from public.formas_metricas where slug = 'terceto_encadenado';
	select arquitectura_id into v_octo from public.arquitecturas_forma
	where forma_id = v_cadena and slug = 'octosilabica_consonante';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if num_nonnulls(v_terceto, v_arq_t, v_cadena, v_octo) <> 4 then
		raise exception 'Falta el terceto, el encadenado o alguna de sus arquitecturas';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- El terceto: lo que vale para sus dos esquemas, y nada que no exista.
	update public.formas_metricas
	set definicion = 'Estrofa de tres versos endecasílabos en la que dos riman en consonante y el tercero queda suelto. Rara vez aparece aislada: lo normal es que se suceda en series o entre en la composición de otra forma, como los dos tercetos del soneto.'
	where forma_id = v_terceto;

	update public.arquitecturas_forma
	set descripcion = null
	where arquitectura_id = v_arq_t;

	-- El encadenado: la definición se queda con lo que lo define y suelta el esquema, que la
	-- ficha imprime debajo.
	update public.formas_metricas
	set definicion = 'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace no se cierra hasta el final, donde un verso más recupera la rima pendiente: la serie entera es una sola unidad abierta y no una sucesión de estrofas.'
	where forma_id = v_cadena;

	-- El cierre octosílabo no es un serventesio, que es de arte mayor.
	update public.esquemas_rima er
	set nombre = 'Encadenamiento consonante con cierre en redondilla cruzada',
		descripcion = 'La clase del segundo verso de cada terceto reaparece en el primero y el tercero de la unidad siguiente. El último terceto recibe un verso más y forma la redondilla cruzada final.'
	where er.arquitectura_id = v_octo;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id in (v_terceto, v_cadena)
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma
			where forma_id in (v_terceto, v_cadena)
		);

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- Sobre el terceto suelto: la notación que el catálogo adopta, y los cierres.
		(v_mb, v_terceto, 'Cap. V, «Tercetos (sin encadenar)»',
			'Notan las dos disposiciones del terceto suelto como `AXA` y `XAA`, donde X es el verso sin rima, y añaden que el primer tipo puede acabar en un pareado o en un cuarteto.',
			'alta'),

		-- Que el terceto rara vez va solo.
		(v_quilis, v_terceto, 'pp. 92-93',
			'Advierte que el terceto normalmente no se usa solo, sino en series con otros tercetos o dentro de otro tipo de estrofa, y pone como ejemplo el soneto.',
			'alta'),

		-- El nombre del terceto de arte menor, que el catálogo no recoge.
		(v_cap14, v_terceto, 'p. 185',
			'Define el terceto como tres versos de arte mayor, normalmente endecasílabos, y precisa que el terceto en versos de arte menor recibe nombre propio: tercetillo, tercerilla o tercerillo.',
			'alta'),

		-- Sobre la cadena: de dónde viene.
		(v_navarro, v_cadena, '§ 113',
			'Sitúa el origen de la serie encadenada en la *Divina Comedia*, de donde viene el enlace por la consonancia del segundo verso de cada terceto.',
			'alta'),

		-- Qué se admite dentro de la cadena y qué no.
		(v_mb, v_cadena, 'Cap. V, «Tercetos (terza rima)»',
			'Describen el encadenamiento ABABCBCDC… YZYZ y precisan que los tercetos acaban generalmente del mismo modo que comienzan, con una rima usada solo dos veces, pero que de vez en cuando aparecen **variantes**: un verso sin rima, o una rima usada cuatro veces.',
			'alta'),

		-- Cómo termina, y por qué son cuatro versos.
		(v_quilis, v_cadena, 'pp. 92-93',
			'Da el patrón ABA-BCB-CDC-…-XYX-YZYZ y explica que la última estrofa es de cuatro versos porque en realidad es un terceto al que se añade uno más para cerrar la rima que quedaba pendiente.',
			'alta'),

		-- Que la bibliografía no siempre las separa.
		(v_dicc, v_cadena, 'Entrada «terceto», p. 427',
			'No distingue las dos formas: define el terceto directamente como la serie ABA, BCB, CDC, …, YZYZ, y remite «terceto encadenado» a esa misma entrada. Añade que son posibles otras disposiciones en el enlace de la rima entre tercetos.',
			'alta'),

		-- La variedad que cabe en tres versos.
		(v_jauralde, v_cadena, '«Estrofas de tres versos»',
			'Sitúa los tercetos encadenados en un abanico que va de los tercetillos de arte menor a las largas composiciones encadenadas, pasando por tercetos monorrimos, quebrados o usados como estribillo.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Terceto y encadenado · 2 definiciones, 1 esquema renombrado y % afirmaciones', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
