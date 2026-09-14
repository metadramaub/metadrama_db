-- Navarro Tomás: cada cláusula vuelve al § que la dice
--
-- Cuatro afirmaciones del cubo material. Tres comparten la misma forma de defecto: la ficha reúne
-- cláusulas de dos §§ y las presenta seguidas, de modo que el lector las atribuye todas al último
-- que se nombra. El localizador ya declaraba los dos; lo que faltaba era **decir cuál dice qué**.
--
--   e2cb5403  Copla manriqueña. Abría con «le da epígrafe propio bajo "copla mixta"» y una cita que
--             es lo primero que se lee bajo el rótulo **«Doble sextilla» del § 67** —la variedad de
--             versos plenos, **sin pie quebrado**, ejemplificada con un madrigal de Juan de Mena—.
--             La manriqueña con quebrado, la de las *Coplas a la muerte de su padre*, es el § 68, y
--             es de donde sale todo lo demás de la ficha, que es largo y exacto. Se cambia la
--             entrada y nada más.
--   67814933  Oncena. Cerraba con dos cláusulas seguidas como si vinieran del mismo sitio. La
--             primera es del § 68; la segunda, «su cultivo no prosperó hasta después de mediados de
--             siglo», está en el § 67, dos líneas después del ejemplo de Álvarez Gato que la propia
--             ficha cita como material del 67. Se mueve ahí, y se cita como el libro la escribe:
--             «de mediados de siglo», no «del siglo XV».
--   6e55564b  Romance. La segunda frase decía que el octosílabo «es el resultado de partir y
--             regularizar aquel verso largo, no su punto de partida». **Eso no está en el § 25.** Y
--             tampoco está donde la pasada A dijo que estaría: propuso como original «por mayor
--             comodidad de la lectura», y la palabra «comodidad» no aparece en todo el libro —es una
--             de las citas del verificador que el validador ya había señalado como no halladas—. Lo
--             que Navarro dice, y está en el § 24, es más modesto y más interesante: que frente a
--             quienes restituían los romances al verso largo «ha prevalecido la costumbre de
--             imprimirlos como composiciones octosilábicas». No es una historia del verso, es una
--             **convención de imprenta que se impuso**. El localizador gana el § 24.
--
-- La cuarta es una cita:
--
--   dec0232d  Seguidilla · De tres versos. El ejemplo de Lope se citaba corrido y el original lo
--             imprime con rayas: «Callad un poco, — que me matan llorando — tan dulces ojos». Las
--             rayas son lo que marca los tres versos del 5-7-5, que es justo lo que el ejemplo está
--             ahí para enseñar; sin ellas no enseña nada.

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'dec0232d-2f88-4e1a-ada6-14b0b6e553a4'::uuid and resumen like '%que me matan llorando tan dulces ojos%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación dec0232d no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La variedad de tres versos, 5-7-5, fue bastante corriente a principios del siglo XVII, con ejemplo de Lope en Los pastores de Belén: «Callad un poco, — que me matan llorando — tan dulces ojos», donde las rayas marcan los tres versos. La seguidilla compuesta, que suma la variedad de cuatro versos y la de tres, empezó a divulgarse más tarde.', localizador = '§ 216'
	where afirmacion_id = 'dec0232d-2f88-4e1a-ada6-14b0b6e553a4'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e2cb5403-4002-49ce-984d-d062312c2afc'::uuid and resumen like '%Le da epígrafe propio bajo «copla mixta»%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e2cb5403 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Bajo el rótulo «Doble sextilla» del § 67 dice que «la estrofa de doce versos fue concebida ordinariamente como una pareja de sextillas», y es en el § 68, el del pie quebrado, donde sigue su historia disposición a disposición: en el *Cancionero de Baena* las dos sextillas se ajustan a dos únicas rimas, con los quebrados en posición interior, `aab:aab-aab:aab`; en Villasandino el orden se invierte en la segunda, `aab:aab-bba:bba`; Juan de Mena aplica rimas distintas a cada sextilla sin mover el verso corto. Y hacia la mitad del siglo aparece la que se impuso —cada sextilla con tres rimas correlativas propias y los versos cortos al final de cada terceto, `abc:abc-def:def`—, registrada primero en Juan de Mena y que «alcanzó fama permanente con las coplas de Jorge Manrique a la muerte de su padre». Explica además por qué: al individualizar las rimas de cada mitad, esa forma «desligaba una sextilla de otra con separación semejante a la practicada entre las redondillas de la copla castellana y las quintillas de la copla real».', localizador = '§§ 67 y 68'
	where afirmacion_id = 'e2cb5403-4002-49ce-984d-d062312c2afc'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '67814933-fcc4-4f5c-ad18-dbef1ba26c85'::uuid and resumen like '%y que su cultivo no prosperó hasta después de mediados del siglo XV%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 67814933 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La define bajo «copla mixta»: «oncena, 5-6: la primera semiestrofa es de ordinario una quintilla `abaab`; los seis octosílabos de la segunda parte se combinan de manera variable; en la mayor parte de los casos forman otra quintilla con un verso adicional». Da cuatro rimas como lo general y `abaab:cdccdd` como variedad frecuente, en el *Sermón trabado* de Íñigo de Mendoza; registra también de dos, tres y cinco —las cinco cuando el miembro de seis se organiza en tercetos correlativos— y la disposición inversa 6-5, con dos rimas en Juan de Mena (`ababba:babba`) y con cuatro en Álvarez Gato (`abaaab:cdccd`), y cierra ese repaso anotando que «su cultivo no prosperó hasta después de mediados de siglo». En su capítulo del pie quebrado añade lo decisivo: «la estrofa de once con quebrados fue más corriente que la de octosílabos plenos», con el *Claro escuro* de Juan de Mena como modelo —`abaab:cdecde`, quebrados en el octavo y el onceno—, repetido por Álvarez Gato, Gómez Manrique y Tapia, y precisa que no llegó a igualar la popularidad de las estrofas de ocho, diez y doce versos.', localizador = '§§ 67 y 68'
	where afirmacion_id = '67814933-fcc4-4f5c-ad18-dbef1ba26c85'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '6e55564b-b921-4288-8230-04c7ec70a1c4'::uuid and resumen like '%es el resultado de partir y regularizar aquel verso largo%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 6e55564b no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'El verso de los romances primitivos —el pie de romance que nombró Nebrija— era de medida variable: Nebrija «no debió considerar el pie de romance como simple suma de dos octosílabos regulares». Sobre su presentación en octosílabos señala que, frente a quienes como Milá y Menéndez Pelayo prefirieron restituir los romances a su primitiva representación en verso largo, «ha prevalecido la costumbre de imprimirlos como composiciones octosilábicas».', localizador = '§§ 24 y 25'
	where afirmacion_id = '6e55564b-b921-4288-8230-04c7ec70a1c4'::uuid;

	-- Igualdad exacta con el texto aprobado.
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'dec0232d-2f88-4e1a-ada6-14b0b6e553a4'::uuid and resumen = 'La variedad de tres versos, 5-7-5, fue bastante corriente a principios del siglo XVII, con ejemplo de Lope en Los pastores de Belén: «Callad un poco, — que me matan llorando — tan dulces ojos», donde las rayas marcan los tres versos. La seguidilla compuesta, que suma la variedad de cuatro versos y la de tres, empezó a divulgarse más tarde.' and localizador = '§ 216';
	if v_cuantas <> 1 then
		raise exception 'La afirmación dec0232d no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e2cb5403-4002-49ce-984d-d062312c2afc'::uuid and resumen = 'Bajo el rótulo «Doble sextilla» del § 67 dice que «la estrofa de doce versos fue concebida ordinariamente como una pareja de sextillas», y es en el § 68, el del pie quebrado, donde sigue su historia disposición a disposición: en el *Cancionero de Baena* las dos sextillas se ajustan a dos únicas rimas, con los quebrados en posición interior, `aab:aab-aab:aab`; en Villasandino el orden se invierte en la segunda, `aab:aab-bba:bba`; Juan de Mena aplica rimas distintas a cada sextilla sin mover el verso corto. Y hacia la mitad del siglo aparece la que se impuso —cada sextilla con tres rimas correlativas propias y los versos cortos al final de cada terceto, `abc:abc-def:def`—, registrada primero en Juan de Mena y que «alcanzó fama permanente con las coplas de Jorge Manrique a la muerte de su padre». Explica además por qué: al individualizar las rimas de cada mitad, esa forma «desligaba una sextilla de otra con separación semejante a la practicada entre las redondillas de la copla castellana y las quintillas de la copla real».' and localizador = '§§ 67 y 68';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e2cb5403 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '67814933-fcc4-4f5c-ad18-dbef1ba26c85'::uuid and resumen = 'La define bajo «copla mixta»: «oncena, 5-6: la primera semiestrofa es de ordinario una quintilla `abaab`; los seis octosílabos de la segunda parte se combinan de manera variable; en la mayor parte de los casos forman otra quintilla con un verso adicional». Da cuatro rimas como lo general y `abaab:cdccdd` como variedad frecuente, en el *Sermón trabado* de Íñigo de Mendoza; registra también de dos, tres y cinco —las cinco cuando el miembro de seis se organiza en tercetos correlativos— y la disposición inversa 6-5, con dos rimas en Juan de Mena (`ababba:babba`) y con cuatro en Álvarez Gato (`abaaab:cdccd`), y cierra ese repaso anotando que «su cultivo no prosperó hasta después de mediados de siglo». En su capítulo del pie quebrado añade lo decisivo: «la estrofa de once con quebrados fue más corriente que la de octosílabos plenos», con el *Claro escuro* de Juan de Mena como modelo —`abaab:cdecde`, quebrados en el octavo y el onceno—, repetido por Álvarez Gato, Gómez Manrique y Tapia, y precisa que no llegó a igualar la popularidad de las estrofas de ocho, diez y doce versos.' and localizador = '§§ 67 y 68';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 67814933 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '6e55564b-b921-4288-8230-04c7ec70a1c4'::uuid and resumen = 'El verso de los romances primitivos —el pie de romance que nombró Nebrija— era de medida variable: Nebrija «no debió considerar el pie de romance como simple suma de dos octosílabos regulares». Sobre su presentación en octosílabos señala que, frente a quienes como Milá y Menéndez Pelayo prefirieron restituir los romances a su primitiva representación en verso largo, «ha prevalecido la costumbre de imprimirlos como composiciones octosilábicas».' and localizador = '§§ 24 y 25';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 6e55564b no ha quedado con el texto aprobado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
