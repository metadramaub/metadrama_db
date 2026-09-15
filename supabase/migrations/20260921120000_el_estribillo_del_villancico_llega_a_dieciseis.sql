-- El estribillo del villancico llega a dieciséis versos, y la ficha lo cerraba en siete
--
-- Dos revisiones pedidas por David antes de pasar a la lectura dirigida. La segunda era la que se
-- esperaba; la primera apareció al ir a comprobarla.
--
-- ══ El villancico de Navarro Tomás
--
-- El motivo de mirarlo era menor: el localizador citaba el **§ 274**, que existe —villancicos de
-- Iglesias de la Casa, Arriaza y Arjona, p. 336— pero del que la ficha no toma nada. Un § de más,
-- como lo fue el § 128 en la copla real.
--
-- Al abrir el § 212 para confirmarlo apareció lo otro. La ficha decía «estribillos **de dos a siete
-- versos**». El siete sale del ejemplo de Góngora que Navarro pone allí —«el estribillo consta de
-- siete versos»—, pero **unas líneas más abajo, en ese mismo §**, sobre los villancicos de sor Juana
-- Inés de la Cruz:
--
--   «Los estribillos, **de muy diversa extensión entre dos y dieciséis versos**, se distinguen sobre
--   todo en los villancicos de sor Juana por el amplio repertorio de sus metros y por la libertad de
--   sus combinaciones.»
--
-- **La ficha se quedó con el primer número que encontró y cerró el rango en menos de la mitad.** Es
-- justo la clase de defecto que la lectura dirigida busca: una cifra que es verdad a medias porque el
-- pasaje sigue. Ninguna comprobación mecánica podía verlo, porque el número que la ficha da está en
-- el pasaje.
--
-- El localizador queda con los cinco § de los que la ficha sí toma algo, con sus páginas, más el
-- repertorio final. *El repertorio de Navarro remite además a los §§ 274 y 352; se dejan fuera porque
-- el localizador dice dónde está lo que la ficha afirma, no todo lo que el libro trae.*
--
-- ══ La sextilla enlazada del *Diccionario*
--
-- La ficha decía «**describe la sextilla como estrofa cerrada sobre sí misma**», y el *Diccionario* no
-- usa esa expresión ni ninguna parecida: era nuestra manera de decir que ninguna variedad contempla
-- enlace. La sustituye lo que sí se puede comprobar, y que además **dice qué se ha mirado** —las
-- cuatro variedades, una por una—, que es lo que sostiene un silencio.
--
-- Aprobado por David el 21 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_antes bigint;
	v_despues bigint;
	v_loc_antes constant text := '§§ 93, 145, 212, 274, 446 y 494; apartado final «Villancico»';
	v_loc_despues constant text := '§§ 93, 145, 212, 446 y 494, pp. 171-173, 235-236, 287-288, 456 y 492; y repertorio final, p. 541';
begin
	create temporary table cambios_villancico (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_villancico (id8, antes, despues)
	values
		('cfc21591', 'Reconstruye su evolución desde la cantiga medieval y documenta una gran variedad histórica. Presenta como modelo preferente del siglo XVI el estribillo de tres versos, la mudanza en redondilla y el enlace, vuelta y represa; junto a abba registra abab y la forma asonantada abcb. Recoge estribillos de dos a siete versos, mudanzas excepcionales de seis, ampliación o supresión del enlace y la vuelta, y repeticiones parciales o totales. De los dos ejemplos modernos que recoge, el del § 494 —la *Gacela del mercado matutino* de García Lorca— lleva «estribillo… cuarteta heptasílaba» y «el cuerpo de la canción… redondilla octosílaba»; y del § 446 —*Verde verderol*, de Juan Ramón Jiménez, con pareado de versos desiguales como estribillo— dice que es «ejemplo aislado de esta antigua forma de canción en el presente período».', 'Reconstruye su evolución desde la cantiga medieval y documenta una gran variedad histórica. Presenta como modelo preferente del siglo XVI el estribillo de tres versos, la mudanza en redondilla y el enlace, vuelta y represa; junto a abba registra abab y la forma asonantada abcb. Recoge estribillos «de muy diversa extensión entre dos y dieciséis versos», mudanzas excepcionales de seis, ampliación o supresión del enlace y la vuelta, y repeticiones parciales o totales. De los dos ejemplos modernos que recoge, el del § 494 —la *Gacela del mercado matutino* de García Lorca— lleva «estribillo… cuarteta heptasílaba» y «el cuerpo de la canción… redondilla octosílaba»; y del § 446 —*Verde verderol*, de Juan Ramón Jiménez, con pareado de versos desiguales como estribillo— dice que es «ejemplo aislado de esta antigua forma de canción en el presente período».'),
		('da0d0e2d', 'No la registra. Describe la sextilla como estrofa cerrada sobre sí misma, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», ninguna de ellas es una sextilla enlazada.', 'No la registra. Ninguna de sus variedades de sextilla —alterna, correlativa, paralela y de pie quebrado— contempla el enlace con la estrofa siguiente, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», ninguna de ellas es una sextilla enlazada.');

	select count(*) into v_n
	from cambios_villancico c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> 2 then
		raise exception 'Solo % de 2 fichas tienen el texto que esta migración espera; no toco ninguna.', v_n;
	end if;

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'cfc21591' and localizador = v_loc_antes;
	if v_n <> 1 then
		raise exception 'El localizador del villancico no es hoy el que esta migración espera.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_villancico c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	update public.afirmaciones_fuentes_metricas
	set localizador = v_loc_despues
	where left(afirmacion_id::text, 8) = 'cfc21591';

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_villancico c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> 2 then
		raise exception 'Solo % de 2 quedaron con el texto nuevo.', v_n;
	end if;

	-- Que el rango truncado no queda en ninguna ficha, ni la glosa de la sextilla.
	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where resumen like '%estribillos de dos a siete versos%'
		or resumen like '%cerrada sobre sí misma%';
	if v_n <> 0 then
		raise exception '% fichas conservan lo que esta migración retira.', v_n;
	end if;

	-- Y que el § 274, del que la ficha no toma nada, sale del localizador.
	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'cfc21591'
		and (localizador <> v_loc_despues or localizador like '%274%');
	if v_n <> 0 then
		raise exception 'El localizador del villancico no quedó como se esperaba.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
