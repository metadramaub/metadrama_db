-- Seis invenciones y dos epígrafes que no existen
--
-- **Las ocho salen de la pasada C sobre el cubo de confirmación**, que la hoja de correcciones
-- describía como «conformes sin ninguna divergencia señalada, no piden decisión». Ese cubo nunca
-- había pasado por localización ciega: A y B las cincuenta y siete, C ninguna. Todas están
-- comprobadas después en el original, porque la C tampoco decide sola —en esta misma tanda dio
-- cuatro falsos positivos—.
--
-- ══ Lo que se le atribuía a una fuente y no dice
--
--   e0c28298  Terceto · Morley y Bruerton. Notábamos `AXA` y `XAA`; el capítulo escribe `AXABYB` y
--             `XAAYBB`, que son esquemas de dos estrofas seguidas. Y le atribuíamos la glosa «donde
--             X es el verso sin rima»: **usan la X dos veces y no la definen ninguna**. El capítulo
--             no tiene nota de convenciones.
--   31a59df9  Sextina · Domínguez Caparrós 2014. «El ejemplo de Herrera realiza ese cierre como
--             **AB-DE-CF**» — la sigla **no aparece ni una vez en el libro**. Él escribe solo que «el
--             remate utiliza las seis palabras finales; cada uno de los tres versos incluye una en
--             el interior y otra al final», y reproduce el terceto sin rotular las parejas.
--
--             **Y la guarda encontró de dónde venía.** Escrita para exigir que la sigla no quedara en
--             ninguna ficha del catálogo, falló señalando una segunda: la sextina de **Quilis**,
--             `1c9b7d26`. Pero ahí es correcta —`AB-DE-CF` es notación suya, la última línea de su
--             tabla de permutaciones del § 6.3.4, rotulando la contera—. De modo que la sigla no se
--             inventó: **se copió de la ficha de Quilis a la de Caparrós**, que es la familia de
--             defectos más repetida de esta auditoría, y por primera vez con el donante identificado.
--   a5822734  Soneto · Morley y Bruerton. «solo variables **los dos tercetos**» donde ellos escriben
--             «**El sexteto varía**». Partimos en dos la unidad con que ellos cuentan.
--
-- ══ Lo que no es de la fuente sino nuestro
--
--   17f41e6d  Septeto · Quilis. Llevaba «es la única de las seis fuentes que la trata como forma con
--             entrada propia y no como término». **Comparar las seis es trabajo de la sección**, que
--             las pone juntas, no de una de ellas.
--   b85a2577  Silva libre · *Diccionario*. Cerraba con «no coincide con **la arquitectura que aquí
--             lleva ese nombre**»: no está en el diccionario **y habla del catálogo** desde dentro de
--             una fuente. Es lo mismo que se corrigió el 16 de septiembre en la silva consonante.
--
-- ══ Dos epígrafes que no existen
--
--   ac2eb17b  Seguidilla · Jauralde. Citaba «Formas mixtas en cuartetos y septetos». **Ese encabezado
--             no existe**: el libro tiene un `h3` «Formas mixtas en septetos» —donde está la
--             seguidilla compuesta— y un `h6` «Formas mixtas» en las estrofas de ocho versos. El
--             localizador fundía los dos en uno inventado. **No lo encontró ninguna pasada**: salió
--             al cotejar los cincuenta localizadores de Jauralde contra los 214 encabezados reales
--             del epub.
--   0ffbdeb3  Octava real · Jauralde. Citaba «Octava real», que **es un rótulo del cuerpo, no un
--             encabezado**. El epígrafe es «Octavas endecasilábicas». Es el mismo error que costó
--             cuatro fichas con «Octavillas y octavas», y solo el epub lo distingue.
--
-- ══ Y un localizador incompleto
--
--   2b540a21  Copla real · Morley y Bruerton. Su entrada dice «la segunda siempre es la n.º 5, y la
--             primera casi siempre es la n.º 1»: **los esquemas están en el epígrafe anterior**,
--             «Quintilla», que es donde se numeran. La traducción que hace la ficha es correcta
--             —comprobada número a número—, pero apuntaba solo a la mitad.
--
-- Textos aprobados por David el 19 de septiembre de 2026.

begin;

do $$
declare
	v_e0c28298 constant text :=
		'Notan las dos disposiciones del terceto suelto sobre dos estrofas seguidas, `AXABYB` y '
		'`XAAYBB`, y añaden que el primer tipo puede acabar en un pareado o en un cuarteto.';
	v_31a59df9 constant text :=
		'Define la forma clásica como 39 endecasílabos en seis estrofas y un remate, explica la '
		'permutación canónica y exige en el remate una palabra interior y otra final por verso. Lo '
		'ejemplifica con la primera sextina de Fernando de Herrera, reproducida entera.';
	v_a5822734 constant text :=
		'Describen los ocho primeros versos como de **rígido orden** ABBAABBA y el sexteto como la '
		'parte que varía, de la que dan cuatro disposiciones: la A es CDCDCD, la B CDECDE, la C CDEDCE '
		'y la D CDCEDE. Advierten que hay otras y remiten al estudio de Dorothy C. Clarke sobre las '
		'rimas de los tercetos en el soneto áureo.';
	v_17f41e6d constant text :=
		'Le da epígrafe propio bajo «estrofas de siete versos», con el nombre de séptima: «poco usada '
		'en nuestra métrica. Está constituida por siete versos de arte mayor, cuya rima queda a gusto '
		'del poeta, con la sola condición de que tres versos no vayan seguidos de la misma rima total». '
		'Ejemplifica con Rubén Darío.';
	v_b85a2577 constant text :=
		'Recoge la silva libre de Isabel Paraíso: composición de versos de distinta medida, par e '
		'impar, que no se organiza en estrofas y generalmente prescinde de la rima, con subtipos impar, '
		'par, híbrida y mixta.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'e0c28298' and resumen like '%AXA%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e0c28298 no dice hoy lo que se viene a quitar.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = v_e0c28298
	where left(afirmacion_id::text, 8) = 'e0c28298';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '31a59df9' and resumen like '%AB-DE-CF%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 31a59df9 no dice hoy lo que se viene a quitar.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = v_31a59df9
	where left(afirmacion_id::text, 8) = '31a59df9';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'a5822734' and resumen like '%los dos tercetos%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación a5822734 no dice hoy lo que se viene a quitar.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = v_a5822734
	where left(afirmacion_id::text, 8) = 'a5822734';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '17f41e6d' and resumen like '%única de las seis fuentes%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 17f41e6d no dice hoy lo que se viene a quitar.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = v_17f41e6d
	where left(afirmacion_id::text, 8) = '17f41e6d';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'b85a2577' and resumen like '%la arquitectura que aquí lleva ese nombre%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación b85a2577 no dice hoy lo que se viene a quitar.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = v_b85a2577
	where left(afirmacion_id::text, 8) = 'b85a2577';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'ac2eb17b' and localizador = 'Apartados «Seguidillas» y «Formas mixtas en cuartetos y septetos»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación ac2eb17b no tiene hoy el localizador que espero.';
	end if;
	update public.afirmaciones_fuentes_metricas set localizador = 'Apartados «Seguidillas» y «Formas mixtas en septetos»'
	where left(afirmacion_id::text, 8) = 'ac2eb17b';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '0ffbdeb3' and localizador = '«Estrofas» → «Octava real»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 0ffbdeb3 no tiene hoy el localizador que espero.';
	end if;
	update public.afirmaciones_fuentes_metricas set localizador = 'Apartado «Octavas endecasilábicas»'
	where left(afirmacion_id::text, 8) = '0ffbdeb3';

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '2b540a21' and localizador = 'Cap. V, «Copla real», p. 38';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 2b540a21 no tiene hoy el localizador que espero.';
	end if;
	update public.afirmaciones_fuentes_metricas set localizador = 'Cap. V, epígrafes «Quintilla» y «Copla real», p. 38'
	where left(afirmacion_id::text, 8) = '2b540a21';

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'e0c28298' and resumen = v_e0c28298;
	if v_cuantas <> 1 then
		raise exception 'La afirmación e0c28298 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '31a59df9' and resumen = v_31a59df9;
	if v_cuantas <> 1 then
		raise exception 'La afirmación 31a59df9 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'a5822734' and resumen = v_a5822734;
	if v_cuantas <> 1 then
		raise exception 'La afirmación a5822734 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '17f41e6d' and resumen = v_17f41e6d;
	if v_cuantas <> 1 then
		raise exception 'La afirmación 17f41e6d no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'b85a2577' and resumen = v_b85a2577;
	if v_cuantas <> 1 then
		raise exception 'La afirmación b85a2577 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'ac2eb17b' and localizador = 'Apartados «Seguidillas» y «Formas mixtas en septetos»';
	if v_cuantas <> 1 then
		raise exception 'El localizador de ac2eb17b no ha quedado como se pretendía.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '0ffbdeb3' and localizador = 'Apartado «Octavas endecasilábicas»';
	if v_cuantas <> 1 then
		raise exception 'El localizador de 0ffbdeb3 no ha quedado como se pretendía.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '2b540a21' and localizador = 'Cap. V, epígrafes «Quintilla» y «Copla real», p. 38';
	if v_cuantas <> 1 then
		raise exception 'El localizador de 2b540a21 no ha quedado como se pretendía.';
	end if;

	-- Que no queda rastro de lo que se retira, en ninguna parte del catálogo.
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where resumen like '%X es el verso sin rima%'
		or resumen like '%única de las seis fuentes%'
		or resumen like '%la arquitectura que aquí lleva ese nombre%';
	if v_cuantas <> 0 then
		raise exception 'Quedan % afirmaciones con algo de lo que se retira.', v_cuantas;
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where localizador like '%Formas mixtas en cuartetos%' or localizador = '«Estrofas» → «Octava real»';
	if v_cuantas <> 0 then
		raise exception 'Quedan % localizadores citando un epígrafe que no existe.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
