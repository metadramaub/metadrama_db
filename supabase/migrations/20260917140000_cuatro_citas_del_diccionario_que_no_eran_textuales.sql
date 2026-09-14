-- Cuatro citas del Diccionario que no eran textuales
--
-- Lo entrecomillado en una afirmación pretende ser transcripción, y en estas cuatro no lo era.
-- Ninguna cambiaba el sentido de un modo escandaloso, y esa es justamente la razón de arreglarlas:
-- una cita que se parece a la fuente y no es la fuente es peor que una paráfrasis honesta, porque
-- pasa por prueba.
--
--   f0bfb1cc  Copla de arte menor. Faltaba una palabra que dice a qué se refiere «la primera»:
--             «una de las rimas de la primera **redondilla** puede repetirse en la segunda».
--   9499bbd8  Septilla. La cita suprimía sin marcarlo el inciso «—rara vez versos de arte mayor—»,
--             que es lo que acota la copla mixta al arte menor, o sea lo que separa la septilla del
--             septeto. No es un adorno que se caiga.
--   871a22ab  Silva · Consonante regular. Perdía un «de» y el arranque de la frase: el original dice
--             «se trata, en realidad, de una forma estructurada en pareados». La página, la 397, se
--             comprobó en la hoja 399 del PDF y ya era correcta.
--   572ec834  Septeto. La más gorda de las cuatro. La cita del septeto agudo estaba fundida y
--             recortada sin puntos suspensivos —«con dos o tres versos agudos —normalmente el
--             último, y el otro hacia la mitad de la estrofa—»— donde el original dice «Septeto con
--             dos o tres versos agudos. Normalmente, el último verso es agudo, y el otro agudo se
--             coloca hacia la mitad de la estrofa —verso tercero o cuarto—». Y con el recorte se
--             perdía entero el caso siguiente, que ahora entra: «si los versos agudos son tres, el
--             último lo es, y los otros dos van alternados en la primera mitad de la estrofa».

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'f0bfb1cc-12ec-4f72-9a01-4bbee888c9fc'::uuid and resumen like '%de las rimas de la primera puede repetirse%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación f0bfb1cc no tiene hoy la cita que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = 'Repite la definición y añade los otros nombres: la entrada «octavilla» remite a esta forma en su tercera acepción —«estrofa de ocho versos formada por dos redondillas y en la que una de las rimas de la primera redondilla puede repetirse en la segunda»— y registra como equivalentes octava de arte menor, octava redondilla y redondilla de ocho versos. Es forma menos solemne que la copla de arte mayor, propia de la poesía menos elevada y de los decires de fines de la Edad Media.'
	where afirmacion_id = 'f0bfb1cc-12ec-4f72-9a01-4bbee888c9fc'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '572ec834-34d4-4b64-8c95-1ea687759a13'::uuid and resumen like '%normalmente el último, y el otro hacia la mitad de la estrofa%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 572ec834 no tiene hoy la cita que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = 'Da «séptima» como nombre de la estrofa de siete versos, «de arte mayor, menor o mezclados los de arte mayor con los de arte menor», con septeto, septilla, septina y seteta como otros términos. En su segunda acepción recoge la definición de Quilis: siete versos de arte mayor «que riman a gusto del poeta, con la única condición de que no rimen tres versos seguidos», y ejemplifica con Dionisio Ridruejo, cerrando con que «la combinación de siete versos de arte mayor no es muy usada en la poesía castellana». Atribuye a Navarro Tomás dos variedades: el **septeto agudo**, «con dos o tres versos agudos. Normalmente, el último verso es agudo, y el otro agudo se coloca hacia la mitad de la estrofa —verso tercero o cuarto—», del que añade que «si los versos agudos son tres, el último lo es, y los otros dos van alternados en la primera mitad de la estrofa», con ejemplo de Leandro Fernández de Moratín; y el **septeto compuesto**, «dividido en un cuarteto y un terceto, unidos o no por la rima», con ejemplo de Zorrilla.'
	where afirmacion_id = '572ec834-34d4-4b64-8c95-1ea687759a13'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '9499bbd8-35fd-4adc-aca2-cdb24d49b00f'::uuid and resumen like '%doce versos octosílabos, dividida en dos semiestrofas%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 9499bbd8 no tiene hoy la cita que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = 'Recoge la forma de siete versos con el esquema `abba:cca` y dice que «es llamada por algunos copla mixta». En su entrada propia define la copla mixta en sentido ancho —«desde siete hasta doce versos octosílabos —rara vez versos de arte mayor— y que está dividida en dos semiestrofas de distinta extensión o en dos sextillas», con dos, tres o cuatro rimas—, la ejemplifica precisamente con una de siete del Marqués de Santillana y la fecha: «es forma medieval que llega hasta el Siglo de Oro».'
	where afirmacion_id = '9499bbd8-35fd-4adc-aca2-cdb24d49b00f'::uuid;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '871a22ab-99df-411f-b76f-8b97272a436f'::uuid and resumen like '%es «en realidad una forma estructurada en pareados%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 871a22ab no tiene hoy la cita que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = 'Sostiene de la silva de consonantes que «se trata, en realidad, de una forma estructurada en pareados, que constituyen su unidad estrófica». De ahí que esta arquitectura, sola entre las cuatro, declare el pareado como parte de su esquema de rima.'
	where afirmacion_id = '871a22ab-99df-411f-b76f-8b97272a436f'::uuid;

	-- Igualdad exacta con el texto aprobado.
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'f0bfb1cc-12ec-4f72-9a01-4bbee888c9fc'::uuid and resumen = 'Repite la definición y añade los otros nombres: la entrada «octavilla» remite a esta forma en su tercera acepción —«estrofa de ocho versos formada por dos redondillas y en la que una de las rimas de la primera redondilla puede repetirse en la segunda»— y registra como equivalentes octava de arte menor, octava redondilla y redondilla de ocho versos. Es forma menos solemne que la copla de arte mayor, propia de la poesía menos elevada y de los decires de fines de la Edad Media.';
	if v_cuantas <> 1 then
		raise exception 'La afirmación f0bfb1cc no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '572ec834-34d4-4b64-8c95-1ea687759a13'::uuid and resumen = 'Da «séptima» como nombre de la estrofa de siete versos, «de arte mayor, menor o mezclados los de arte mayor con los de arte menor», con septeto, septilla, septina y seteta como otros términos. En su segunda acepción recoge la definición de Quilis: siete versos de arte mayor «que riman a gusto del poeta, con la única condición de que no rimen tres versos seguidos», y ejemplifica con Dionisio Ridruejo, cerrando con que «la combinación de siete versos de arte mayor no es muy usada en la poesía castellana». Atribuye a Navarro Tomás dos variedades: el **septeto agudo**, «con dos o tres versos agudos. Normalmente, el último verso es agudo, y el otro agudo se coloca hacia la mitad de la estrofa —verso tercero o cuarto—», del que añade que «si los versos agudos son tres, el último lo es, y los otros dos van alternados en la primera mitad de la estrofa», con ejemplo de Leandro Fernández de Moratín; y el **septeto compuesto**, «dividido en un cuarteto y un terceto, unidos o no por la rima», con ejemplo de Zorrilla.';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 572ec834 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '9499bbd8-35fd-4adc-aca2-cdb24d49b00f'::uuid and resumen = 'Recoge la forma de siete versos con el esquema `abba:cca` y dice que «es llamada por algunos copla mixta». En su entrada propia define la copla mixta en sentido ancho —«desde siete hasta doce versos octosílabos —rara vez versos de arte mayor— y que está dividida en dos semiestrofas de distinta extensión o en dos sextillas», con dos, tres o cuatro rimas—, la ejemplifica precisamente con una de siete del Marqués de Santillana y la fecha: «es forma medieval que llega hasta el Siglo de Oro».';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 9499bbd8 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '871a22ab-99df-411f-b76f-8b97272a436f'::uuid and resumen = 'Sostiene de la silva de consonantes que «se trata, en realidad, de una forma estructurada en pareados, que constituyen su unidad estrófica». De ahí que esta arquitectura, sola entre las cuatro, declare el pareado como parte de su esquema de rima.';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 871a22ab no ha quedado con el texto aprobado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
