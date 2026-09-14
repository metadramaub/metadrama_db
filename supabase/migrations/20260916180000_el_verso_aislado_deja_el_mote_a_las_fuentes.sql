-- El verso aislado deja el mote a las fuentes
--
-- Dos cambios que van juntos porque son el mismo reparto: **la definición dice lo que hace el
-- catálogo y la afirmación dice lo que dice un libro.**
--
-- ══ La definición de la forma
--
-- El verso aislado es un **tramo sin forma**, una salida editorial para el verso que no se integra
-- en lo anterior ni en lo siguiente, y su propia definición lo decía al final: «por eso el catálogo
-- lo registra como tramo sin forma y no como forma». Pero en medio ponía como caso más
-- caracterizado el mote, «verso suelto al que sigue una glosa que acaba repitiéndolo», y eso la
-- empujaba a leerse al revés: como si ahí hubiera una forma literaria latente. Nadie va a anotar un
-- mote bajo esta ficha, y si algún día el mote se eleva a forma propia, será por su cuenta.
--
-- Se queda el caso funcional, que es el que un editor se encuentra de verdad en una comedia: los
-- proverbios, refranes y sentencias que el diálogo intercala con medida reconocible.
--
-- **Esto acorta una definición, y la norma del proyecto es que las definiciones se mejoran
-- alargando.** No es una excepción por concisión: lo que sale no es prosa sobrante sino un ejemplo
-- que estaba haciendo trabajo de modelo, y el trabajo de modelo lo hace la definición o lo hace una
-- forma, no un ejemplo de paso.
--
-- ══ La afirmación de Navarro Tomás
--
-- Cerraba con «El verso único queda así integrado en una composición mayor sin pertenecer a la
-- estrofa que lo glosa». Esa frase no está en el § 76: es una lectura nuestra, y puesta ahí se lee
-- como suya. Lo que Navarro describe es la glosa del mote, y eso se queda.
--
-- **Y no se añade que sea «lo más parecido» a nuestro verso aislado**, aunque lo sea, porque eso
-- tampoco lo dice él. No hace falta: la afirmación cuelga del verso aislado, así que quien la lea
-- ahí ya ve la proximidad. Es la misma razón por la que se retiró «donde Quilis da CDC DCD» del
-- soneto de Jauralde: la sección relaciona por sí sola al poner las seis fuentes juntas, y decirlo
-- dentro de una la atribuye a quien no lo dijo.
--
-- David aprobó los dos textos el 16 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := 'fa1289ed-b854-4428-a575-55edf29b335a';
	v_afirmacion constant uuid := 'fce5025f-147d-45be-8a52-01c072154802';
	v_def_antigua constant text :=
		'Un único verso que no se integra en la forma anterior ni en la siguiente, y que tampoco es '
		'una licencia dentro de ninguna de las dos. El caso más caracterizado es el mote, verso suelto '
		'al que sigue una glosa que acaba repitiéndolo; también lo son los proverbios, refranes y '
		'sentencias que el diálogo intercala con medida reconocible. Que un verso solo sea verso es '
		'discutible, porque le falta la repetición en que descansa el ritmo, y por eso el catálogo lo '
		'registra como tramo sin forma y no como forma.';
	v_def_nueva constant text :=
		'Un único verso que no se integra en la forma anterior ni en la siguiente, y que tampoco es '
		'una licencia dentro de ninguna de las dos. Es el caso de los proverbios, refranes y '
		'sentencias que el diálogo intercala con medida reconocible. Que un verso solo sea verso es '
		'discutible, porque le falta la repetición en que descansa el ritmo, y por eso el catálogo lo '
		'registra como tramo sin forma y no como forma.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma and nombre = 'Verso aislado' and definicion = v_def_antigua;
	if v_cuantas <> 1 then
		raise exception 'La definición del verso aislado no es la que espero; no la toco.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_afirmacion
		and resumen like '%El verso único queda así integrado%'
		and localizador = '§ 76';
	if v_cuantas <> 1 then
		raise exception 'La afirmación de Navarro sobre el verso aislado no está como espero.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.formas_metricas
	set definicion = v_def_nueva
	where forma_id = v_forma;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Al describir la glosa explica que la del mote comprendía regularmente tres partes y que la '
			'primera era el mote, en un solo verso, seguido de una paráfrasis breve en redondilla o '
			'quintilla que terminaba repitiéndolo.',
		localizador = '§ 76, «Glosa», pp. 149-150'
	where afirmacion_id = v_afirmacion;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que el mote sale de la definición y se queda el caso funcional, y que no se ha llevado por
	-- delante lo que la definición dice de sí misma, que es lo que la sostiene como tramo sin forma.
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma
		and definicion not like '%mote%'
		and definicion like '%proverbios, refranes y sentencias%'
		and definicion like '%tramo sin forma y no como forma%';
	if v_cuantas <> 1 then
		raise exception 'La definición del verso aislado no ha quedado como se pretendía.';
	end if;

	-- Que la afirmación pierde la inferencia y conserva lo que sí dice Navarro.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_afirmacion
		and resumen not like '%El verso único queda%'
		and resumen like '%comprendía regularmente tres partes%'
		and resumen like '%terminaba repitiéndolo%'
		and localizador = '§ 76, «Glosa», pp. 149-150';
	if v_cuantas <> 1 then
		raise exception 'La afirmación de Navarro no ha quedado como se pretendía.';
	end if;

	-- Y que el mote sigue documentado en alguna parte: sale de la definición porque pasa a vivir
	-- en las fuentes, no porque deje de interesar.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where fo.forma_id = v_forma and a.resumen like '%mote%';
	if v_cuantas < 1 then
		raise exception 'El mote ha desaparecido también de las fuentes del verso aislado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
