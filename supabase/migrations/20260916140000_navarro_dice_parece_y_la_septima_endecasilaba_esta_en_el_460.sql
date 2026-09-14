-- Navarro dice «parece», y su séptima endecasílaba está en el § 460
--
-- Seis de las siete afirmaciones de fondo de Navarro Tomás. La séptima, la del verso aislado, se
-- queda fuera a la espera de una decisión distinta que se explica al final.
--
-- ══ Dos endurecimientos con la misma forma exacta
--
--   7dfaccd6  Lira, § 462. «Últimamente **parece** renacer con nueva vitalidad en repetidas
--             manifestaciones» se recogía como «observa que vuelve a cultivarse con vitalidad».
--   e7df73d9  Pareado, § 58. «El pareado narrativo de la poesía juglaresca, restringido entre los
--             poetas de clerecía, **parece** casi enteramente desterrado de la métrica del siglo
--             XV» se recogía como «quedó casi enteramente desterrado». Se aprovecha para añadir la
--             excepción que él mismo anota a continuación, el *Razonamiento que fizo don Alfonso
--             Enríquez fablando con él mesmo*, que no estaba recogida.
--
--   Las dos veces el verbo es el mismo y las dos veces se perdió. Es el defecto que ninguna
--   comprobación mecánica ve, porque el resumen sigue sonando bien.
--
-- ══ Dos invenciones
--
--   4c7fbe60  Cuarteto, § 463. «En el corpus áureo la relación es la inversa, porque la abrazada es
--             la del soneto» no está ahí ni en ninguna otra parte: el § 463 trata la poesía del
--             siglo XX de cabo a rabo —Pellicer, Carrera Andrade, Guillén, Florit, José Luis Cano,
--             Pérez Clotet— y no menciona el Siglo de Oro ni el soneto. Entra en cambio lo que sí
--             dice y no recogíamos: el `AbBa` con endecasílabos y heptasílabos alternos de Guillén.
--   7fb1122d  Cuarteto-lira. La ficha decía que Navarro la llama «cuarteto alirado». Esa cadena
--             **no aparece ninguna vez en el libro**. Y el localizador era «s. v. "cuarteto
--             alirado", recogido en el Diccionario»: un remite a otro libro dentro de una ficha de
--             Navarro. Lo que sí hay es su propio «Índice de estrofas» con una entrada titulada
--             «Cuarteto-lira», que es el nombre que este catálogo ya usa, con definición y esquemas.
--
-- ══ Dos que retiran cosa ajena
--
--   11ffbe13  Copla castellana, § 65. La frase sobre Lope y los monólogos no está en el § 65 ni en
--             las otras dos apariciones de la forma en el libro. El único pasaje que une a Lope con
--             el monólogo octosílabo es el § 176, y allí habla del **perqué**, otra estrofa. Y la
--             cita entrecomillada se comía un pronombre: el original dice «Llegaron **éstas** a ser
--             de uso tan familiar…».
--   cabb1f04  Septeto. Describía el reparto 4-3 **en octosílabos**, que es la septilla y ya está
--             recogido en su propia ficha. Sobraban además una «septilla aguda» que es otra estrofa
--             —octosílaba, del siglo XIX, `aaé:bbbé`, § 308— y una atribución de términos al
--             *Diccionario*.
--
--             **El septeto de arte mayor sí lo trata Navarro, y en otro sitio**: el § 460,
--             «Séptima», donde lo define como «una estrofa endecasílaba de antigua tradición
--             provenzal, compuesta de cuarteto y terceto» y lo presenta como **modelo de la copla
--             mixta octosílaba** de la poesía castellana medieval. Eso responde de paso a la duda
--             de si separar septeto y septilla por el arte del verso era invento nuestro: es la
--             suya. Llama «séptima» a la endecasílaba y «septilla, 4-3» a la octosílaba.
--
-- ══ Lo que queda abierto
--
-- **El verso aislado** (`fce5025f`) no entra. Su afirmación describe la glosa del mote, y la
-- pregunta que abre no es sobre ella sino sobre la forma: la definición de «Verso aislado» dice que
-- «el caso más caracterizado es el mote», y eso la empuja a leerse como forma real cuando lo que es
-- —y ella misma lo dice al final— es un tramo sin forma, una salida editorial. Cambiar eso es tocar
-- la prosa de la forma, no una afirmación de fuente, y se decide aparte.
--
-- **Y la relación entre septeto y septilla.** Hoy está registrada como `contrasta_con`, por el arte
-- del verso. Con el § 460 en la mano hay además una derivación documentada —la séptima endecasílaba
-- como modelo de la copla mixta octosílaba—, que ninguna otra de las seis fuentes afirma. Si se
-- añade, es una relación nueva y se decide aparte.

begin;

do $$
declare
	v_castellana constant uuid := '11ffbe13-861e-4892-829d-2088b3be5d95';
	v_cuarteto constant uuid := '4c7fbe60-c4fa-4411-9c75-3cbf51f9ec91';
	v_cuartetolira constant uuid := '7fb1122d-e990-4ccc-984e-14706e6174e6';
	v_lira constant uuid := '7dfaccd6-54e3-44e8-a50b-caaa5f65914e';
	v_pareado constant uuid := 'e7df73d9-a58f-433d-b015-e44d9d9eed7a';
	v_septeto constant uuid := 'cabb1f04-f582-4407-ad2f-7408a4dcf3e7';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1972
		and a.afirmacion_id in (v_castellana, v_cuarteto, v_cuartetolira, v_lira, v_pareado, v_septeto);
	if v_cuantas <> 6 then
		raise exception 'Esperaba 6 afirmaciones de Navarro Tomás 1972 y encuentro %.', v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'La define como ocho octosílabos en dos grupos de cuatro **con cuatro rimas, como pareja de '
		'redondillas independientes**, y enumera las cuatro disposiciones: las dos mitades cruzadas, '
		'`abab:cdcd`; las dos abrazadas, `abba:cddc`; o combinadas, `abab:cddc` y `abba:cdcd`. La sigue '
		'históricamente: no hay ningún ejemplo en el *Cancionero de Baena* de 1445; Santillana la usa '
		'en las coplas sobre el Condestable y, con el sexto verso quebrado, en el *Diálogo de Bías '
		'contra Fortuna* y en los *Gozos de Nuestra Señora*; en el *Cancionero general* de 1511 ya '
		'supera a la de arte menor, y «llegaron éstas a ser de uso tan familiar en el siglo XVI que '
		'recibieron el nombre de coplas castellanas». Observa además lo que su falta de enlace '
		'implica: «suprimido el enlace de la rima, la unión de las semiestrofas quedaba reducida a un '
		'simple efecto de representación gráfica».'
	where afirmacion_id = v_castellana;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Observa que en la poesía del siglo XX «se ha mantenido su ejercicio, aunque en menor grado '
		'que en los períodos romántico y modernista», y que el tipo más frecuente es el de '
		'endecasílabos plenos con rimas cruzadas, `ABAB`, frente a la variedad abrazada, que documenta '
		'con menos ejemplos. Registra además el empleo de esa variedad con endecasílabos y '
		'heptasílabos alternos, `AbBa`, en Jorge Guillén.'
	where afirmacion_id = v_cuarteto;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'La llama cuarteto-lira, y la define como «combinación de cuatro versos de once y siete '
			'sílabas, `AbAb`, `aBaB`, `ABaB`, `AbBA`, etc.», con remisiones a seis períodos, del '
			'Renacimiento al Posmodernismo.',
		localizador = '§ 505, «Índice de estrofas», p. 533'
	where afirmacion_id = v_cuartetolira;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Sigue el rastro de la lira renacentista hasta el siglo XX: la emplearon García Lorca en una '
		'oda de homenaje a fray Luis de León y el argentino Ricardo E. Molinari, y añade que '
		'«últimamente **parece** renacer con nueva vitalidad en repetidas manifestaciones».'
	where afirmacion_id = v_lira;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Registra el pareado octosílabo en estribillos de canciones, en máximas o proverbios '
		'intercalados en algunos decires, y en motes y divisas. Del pareado narrativo de la poesía '
		'juglaresca, restringido entre los poetas de clerecía, dice que «**parece** casi enteramente '
		'desterrado de la métrica del siglo XV», y anota que se halla por excepción en el '
		'*Razonamiento que fizo don Alfonso Enríquez fablando con él mesmo*.'
	where afirmacion_id = v_pareado;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Le da epígrafe propio como «Séptima»: «una estrofa endecasílaba de antigua tradición '
			'provenzal, compuesta de cuarteto y terceto», que presenta como modelo de la copla mixta '
			'octosílaba de la poesía castellana medieval. La documenta en *Adolescencia*, de Dionisio '
			'Ridruejo, «con la misma disposición `ABAB:CBC` de una cantiga de Macías en el *Cancionero '
			'de Baena*», y al final del *18 de julio*, de Alberti.',
		localizador = '§ 460, «Séptima», pp. 473-474'
	where afirmacion_id = v_septeto;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que no queda nada de lo retirado.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_castellana, v_cuarteto, v_cuartetolira, v_lira, v_pareado, v_septeto)
		and (resumen like '%corpus áureo%'
			or resumen like '%cuarteto alirado%'
			or resumen like '%septilla aguda%'
			or resumen like '%monólogos de sus comedias%'
			or resumen like '%vuelve a cultivarse con vitalidad%'
			or resumen like '%quedó casi enteramente desterrado%'
			or localizador like '%recogido en el Diccionario%');
	if v_cuantas > 0 then
		raise exception 'Sigue habiendo % afirmaciones con algo de lo que se retira.', v_cuantas;
	end if;

	-- Que los dos «parece» están, que es el punto de dos de las seis.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_lira, v_pareado) and resumen like '%**parece**%';
	if v_cuantas <> 2 then
		raise exception 'Alguno de los dos «parece» no ha entrado: cuadran %.', v_cuantas;
	end if;

	-- Que la cita de la copla castellana lleva ya el pronombre del original.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_castellana and resumen like '%llegaron éstas a ser de uso tan familiar%';
	if v_cuantas <> 1 then
		raise exception 'La cita de la copla castellana sigue sin el «éstas» del original.';
	end if;

	-- Y que el septeto apunta al § 460 y dice lo suyo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_septeto
		and localizador = '§ 460, «Séptima», pp. 473-474'
		and resumen like '%estrofa endecasílaba de antigua tradición provenzal%'
		and resumen like '%ABAB:CBC%';
	if v_cuantas <> 1 then
		raise exception 'El septeto no ha quedado apuntando al § 460.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
