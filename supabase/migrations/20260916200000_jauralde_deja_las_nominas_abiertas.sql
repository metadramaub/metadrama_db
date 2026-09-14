-- Jauralde deja las nóminas abiertas, que es como las escribió
--
-- Las seis afirmaciones de fondo de Jauralde Pou. El texto de cada una es el que David aprobó con
-- el viejo y el nuevo delante, y **el SQL se generó desde `propuestas.json`** en vez de retecleando:
-- la guarda final comprueba igualdad exacta con el texto aprobado, no un parecido.
--
-- ══ La nómina cerrada, un defecto que no teníamos tipificado
--
-- El libro escribe «Santillana, Mena, Imperial...» y «Juan del Encina, Castillejo, Hurtado de
-- Mendoza, Cervantes...», con puntos suspensivos, y las dos fichas cambiaban los puntos por una
-- conjunción: «Santillana, Mena **e** Imperial», «Hurtado de Mendoza **y** Cervantes». Una lista
-- que el autor deja abierta a propósito pasa a leerse como completa.
--
-- Es **la enumeración truncada al revés**: no falta nadie, sobra el cierre. La taxonomía del plan
-- tiene «omisión relevante» para lo que se calla, y no tenía nombre para esto.
--
-- ══ Lo demás
--
--   9e2b7557  Copla de arte mayor. Perdía el patrón rítmico concreto: el libro da «óoo ó **en cada
--             hemistiquio**, con una o dos sílabas antes y después» y la ficha lo resumía como «un
--             hemistiquio de ritmo marcado», que ni da el patrón ni dice que valga para los dos.
--   2cc0d171  Copla real. Se quedaba con el hecho del quebrado tardío y soltaba el motivo: el libro
--             dice que terminó por quebrar alguno de sus versos «**para jugar con variedades
--             distintas**», o sea como recurso buscado, no como algo que le pasó a la forma.
--   49b4e370  Décima. Daba por hecho lo que la fuente presenta con un «**se suele señalar** que la
--             inventó Vicente Espinel», y ponía en boca de Jorge Guillén —«que él mismo describe»—
--             una caracterización que es narración de Jauralde sobre lo que Guillén hizo.
--   e20a8b27  Novena. Decía que el de Castillejo era «el único ejemplo con quebrado», y en el mismo
--             epígrafe están las diez novenas de Avellaneda en *La Cruz*, endecasílabas quebradas en
--             cuarta posición por un heptasílabo, `ABBa:CDCCD`. Entran en el texto nuevo. Y el
--             localizador citaba «§ 2.5.7», que no es un apartado: Jauralde no numera secciones, y
--             esa cadena es en otras partes del libro notación de esquemas acentuales.
--   c63316b9  Seguidilla · Real. La más enredada. La ficha ataba el nombre de sor Juana al esquema
--             10-6-10-6, y lo que el libro dice es que «sor Juana Inés de la Cruz llamó a **una de
--             estas combinaciones** "seguidilla real", por imitación de la endecha real», siendo el
--             `10A+6b+10C+6b` el ejemplo modernista **de Gabriel y Galán**. Y añadía que «el
--             *Diccionario* y Navarro Tomás reservan el nombre de gitana para 6-6-(10/11/12)-6»,
--             frase que no aparece en Jauralde en ninguna forma reconocible.
--   5d3cd719  Silva. «Se adoptó como variedad teatral» no está en el epígrafe «Silva» sino en
--             «Estrofas de pareados», hablando de los pareados de 7-11 que acaban llamándose silva
--             de consonantes. El dato es de la silva, así que se declara el segundo sitio y se
--             recoge de paso lo que la misma frase dice y no teníamos: que el nombre «a su vez
--             extiende su denominación a los ovillejos».

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- 9e2b7557 · Copla de arte mayor · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '9e2b7557-82bd-48fa-a218-8da4577cfe1e'::uuid and resumen like '%con un hemistiquio de ritmo marcado%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 9e2b7557 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La define como combinación de ocho versos con dos o tres rimas consonantes distribuidas en dos cuartetos que se enlazan por la misma rima de los versos cuarto y quinto. Precisa que, dada la estructura rítmica del verso —«óoo ó **en cada hemistiquio**, con una o dos sílabas antes y después»—, su número de sílabas varía entre diez y dieciséis. Señala que con ella escribieron los grandes poemas del siglo XV «Santillana, Mena, Imperial…», y deja la nómina abierta.',
		localizador = 'Apartado «Coplas de arte mayor»'
	where afirmacion_id = '9e2b7557-82bd-48fa-a218-8da4577cfe1e'::uuid;

	-- 2cc0d171 · Copla real · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '2cc0d171-8117-4452-bbb8-b0ae5554ac69'::uuid and resumen like '%Hurtado de Mendoza y Cervantes%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 2cc0d171 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La describe como combinación de diez octosílabos en dos semiestrofas unidas por tres o cuatro rimas, aparecida a lo largo del siglo XV, quizá como elaboración de las coplas castellanas y de arte menor. Advierte que las semiestrofas no son necesariamente iguales y que la forma 4-6 precede a la 5-5, que solo se hace mayoritaria a finales del siglo XV. Afirma que es quizá la copla de mayor vigencia durante el periodo áureo, cuando se llamaron redondillas castellanas y fue «estrofa preferida por Juan del Encina, Castillejo, Hurtado de Mendoza, Cervantes…», con la nómina abierta, «sobre todo por su uso en los tablados». Y que «a la larga terminó por quebrar alguno de sus versos **para jugar con variedades distintas**».',
		localizador = 'Apartado «Copla real»'
	where afirmacion_id = '2cc0d171-8117-4452-bbb8-b0ae5554ac69'::uuid;

	-- 49b4e370 · Décima · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '49b4e370-893f-41a0-a356-cce9572f6f1e'::uuid and resumen like '%que él mismo describe como ensayo frente a la consonancia%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 49b4e370 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Recorre la historia de la estrofa: aparición tardía, «muy a finales del siglo XVI», porque «**se suele señalar** que la inventó Vicente Espinel en sus *Diversas rimas* (1591)», y el nombre de espinela desde *La Dorotea* de Lope; popularísima desde entonces «para todo tipo de circunstancias, incluyendo los parlamentos teatrales». **Le documenta cuatro medidas además de la octosílaba, cada una con ejemplo**: hexasilábica con estribillo en **Góngora**, endecasilábica en la *Elegía moral a la Virtud* de **Meléndez Valdés** y en las «baladas» de Rubén Darío, pentasilábica en Concha Méndez y heptasilábica en Luis García Montero. Registra también experimentos que no son realizaciones de la forma: la escala métrica de Darío «empezando por décima de bisílabo, luego trisílabo», las décimas en verso blanco y las asonantadas de Jorge Guillén en *Cántico*, que presenta como ensayo sobre la estrofa —«al rimarlas en asonante en vez de en consonante, que era lo tradicional»—.',
		localizador = 'Apartado «Estrofas de diez versos»'
	where afirmacion_id = '49b4e370-893f-41a0-a356-cce9572f6f1e'::uuid;

	-- e20a8b27 · Novena · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e20a8b27-5d07-4505-a074-bc379baa029f'::uuid and resumen like '%el único ejemplo con quebrado%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e20a8b27 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma abundante en los cancioneros del siglo XV, con `abba:cdccd` como realización destacada: así el *Diálogo entre el amor y un viejo* de Rodrigo Cota, y también Cervantes en *El Laberinto de amor* y Villamediana. Señala que el orden inicial fue redondilla más quintilla (4+5) y que la forma derivó a juegos de rima más complicados hasta aislar cada semiestrofa y ensayar variantes, incluida la de 5+4. Atribuye a Cristóbal de Castillejo cierta preferencia por la novena y da de él un ejemplo con quebrado que abre la quintilla final, «8a 8b 8b 8a 4c 8c 8d 8d 8c»; registra además las diez novenas de Avellaneda en *La Cruz*, de endecasílabos quebrados en cuarta posición por un heptasílabo y con rimas totales, `ABBa:CDCCD`.',
		localizador = 'Apartados «Estrofas» y «Estrofas de nueve versos»'
	where afirmacion_id = 'e20a8b27-5d07-4505-a074-bc379baa029f'::uuid;

	-- c63316b9 · Seguidilla · Real · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'c63316b9-b1b3-4fa3-b0bc-b9adac2ab9af'::uuid and resumen like '%El Diccionario y Navarro Tomás reservan%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación c63316b9 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Recoge el nombre en dos sitios. En las combinaciones de seis y diez sílabas dice que «sor Juana Inés de la Cruz llamó a una de estas combinaciones "seguidilla real", por imitación de la endecha real, y las compuso con garbo», y añade que reaparecen en el modernismo, con un ejemplo de Gabriel y Galán en `10A+6b+10C+6b`. Y en el apartado de las seguidillas vuelve a nombrarla identificándola con la gitana: «seguidilla real, como la denomina sor Juana Inés de la Cruz, o gitana, en la terminología de Augusto Ferrán».',
		localizador = 'Apartados «Otros cuartetos mixtos» y «Seguidillas»'
	where afirmacion_id = 'c63316b9-b1b3-4fa3-b0bc-b9adac2ab9af'::uuid;

	-- 5d3cd719 · Silva · Jauralde Pou 2020
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '5d3cd719-520e-4d52-a0b8-bbbd97662353'::uuid and resumen like '%silva de consonantes y se adoptó como variedad teatral%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 5d3cd719 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Describe la silva primitiva como heptasílabos y endecasílabos con rima consonante dispuesta de manera aleatoria, y sitúa su origen a comienzos del siglo XVII, con Quevedo antes de las *Soledades*. Registra que la combinación de siete y once acabó llamándose silva de consonantes —nombre que «a su vez extiende su denominación a los ovillejos»— y que se adoptó también como variedad teatral, y que la silva moderna, de base 4-7-11-14, es normalmente de versos blancos.',
		localizador = 'Apartados «Silva», en «Series», y «Estrofas de pareados»'
	where afirmacion_id = '5d3cd719-520e-4d52-a0b8-bbbd97662353'::uuid;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Igualdad exacta con el texto aprobado, una por una. No basta con que haya cambiado: tiene que
	-- haber quedado eso y no otra cosa.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '9e2b7557-82bd-48fa-a218-8da4577cfe1e'::uuid
		and resumen = 'La define como combinación de ocho versos con dos o tres rimas consonantes distribuidas en dos cuartetos que se enlazan por la misma rima de los versos cuarto y quinto. Precisa que, dada la estructura rítmica del verso —«óoo ó **en cada hemistiquio**, con una o dos sílabas antes y después»—, su número de sílabas varía entre diez y dieciséis. Señala que con ella escribieron los grandes poemas del siglo XV «Santillana, Mena, Imperial…», y deja la nómina abierta.'
		and localizador = 'Apartado «Coplas de arte mayor»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 9e2b7557 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '2cc0d171-8117-4452-bbb8-b0ae5554ac69'::uuid
		and resumen = 'La describe como combinación de diez octosílabos en dos semiestrofas unidas por tres o cuatro rimas, aparecida a lo largo del siglo XV, quizá como elaboración de las coplas castellanas y de arte menor. Advierte que las semiestrofas no son necesariamente iguales y que la forma 4-6 precede a la 5-5, que solo se hace mayoritaria a finales del siglo XV. Afirma que es quizá la copla de mayor vigencia durante el periodo áureo, cuando se llamaron redondillas castellanas y fue «estrofa preferida por Juan del Encina, Castillejo, Hurtado de Mendoza, Cervantes…», con la nómina abierta, «sobre todo por su uso en los tablados». Y que «a la larga terminó por quebrar alguno de sus versos **para jugar con variedades distintas**».'
		and localizador = 'Apartado «Copla real»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 2cc0d171 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '49b4e370-893f-41a0-a356-cce9572f6f1e'::uuid
		and resumen = 'Recorre la historia de la estrofa: aparición tardía, «muy a finales del siglo XVI», porque «**se suele señalar** que la inventó Vicente Espinel en sus *Diversas rimas* (1591)», y el nombre de espinela desde *La Dorotea* de Lope; popularísima desde entonces «para todo tipo de circunstancias, incluyendo los parlamentos teatrales». **Le documenta cuatro medidas además de la octosílaba, cada una con ejemplo**: hexasilábica con estribillo en **Góngora**, endecasilábica en la *Elegía moral a la Virtud* de **Meléndez Valdés** y en las «baladas» de Rubén Darío, pentasilábica en Concha Méndez y heptasilábica en Luis García Montero. Registra también experimentos que no son realizaciones de la forma: la escala métrica de Darío «empezando por décima de bisílabo, luego trisílabo», las décimas en verso blanco y las asonantadas de Jorge Guillén en *Cántico*, que presenta como ensayo sobre la estrofa —«al rimarlas en asonante en vez de en consonante, que era lo tradicional»—.'
		and localizador = 'Apartado «Estrofas de diez versos»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 49b4e370 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e20a8b27-5d07-4505-a074-bc379baa029f'::uuid
		and resumen = 'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma abundante en los cancioneros del siglo XV, con `abba:cdccd` como realización destacada: así el *Diálogo entre el amor y un viejo* de Rodrigo Cota, y también Cervantes en *El Laberinto de amor* y Villamediana. Señala que el orden inicial fue redondilla más quintilla (4+5) y que la forma derivó a juegos de rima más complicados hasta aislar cada semiestrofa y ensayar variantes, incluida la de 5+4. Atribuye a Cristóbal de Castillejo cierta preferencia por la novena y da de él un ejemplo con quebrado que abre la quintilla final, «8a 8b 8b 8a 4c 8c 8d 8d 8c»; registra además las diez novenas de Avellaneda en *La Cruz*, de endecasílabos quebrados en cuarta posición por un heptasílabo y con rimas totales, `ABBa:CDCCD`.'
		and localizador = 'Apartados «Estrofas» y «Estrofas de nueve versos»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e20a8b27 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'c63316b9-b1b3-4fa3-b0bc-b9adac2ab9af'::uuid
		and resumen = 'Recoge el nombre en dos sitios. En las combinaciones de seis y diez sílabas dice que «sor Juana Inés de la Cruz llamó a una de estas combinaciones "seguidilla real", por imitación de la endecha real, y las compuso con garbo», y añade que reaparecen en el modernismo, con un ejemplo de Gabriel y Galán en `10A+6b+10C+6b`. Y en el apartado de las seguidillas vuelve a nombrarla identificándola con la gitana: «seguidilla real, como la denomina sor Juana Inés de la Cruz, o gitana, en la terminología de Augusto Ferrán».'
		and localizador = 'Apartados «Otros cuartetos mixtos» y «Seguidillas»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación c63316b9 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '5d3cd719-520e-4d52-a0b8-bbbd97662353'::uuid
		and resumen = 'Describe la silva primitiva como heptasílabos y endecasílabos con rima consonante dispuesta de manera aleatoria, y sitúa su origen a comienzos del siglo XVII, con Quevedo antes de las *Soledades*. Registra que la combinación de siete y once acabó llamándose silva de consonantes —nombre que «a su vez extiende su denominación a los ovillejos»— y que se adoptó también como variedad teatral, y que la silva moderna, de base 4-7-11-14, es normalmente de versos blancos.'
		and localizador = 'Apartados «Silva», en «Series», y «Estrofas de pareados»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 5d3cd719 no ha quedado con el texto aprobado.';
	end if;

	-- Y que ninguna de las dos nóminas ha vuelto a cerrarse.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2020
		and (a.resumen like '%Santillana, Mena e Imperial%'
			or a.resumen like '%Hurtado de Mendoza y Cervantes%');
	if v_cuantas > 0 then
		raise exception 'Alguna nómina sigue cerrada con conjunción.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
