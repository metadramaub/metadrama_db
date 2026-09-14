-- Cuatro fichas de Caparrós que citaban un epígrafe de Navarro Tomás
--
-- La última tanda del cubo material, y la que deja a la vista la familia de defectos más extendida
-- de toda la auditoría: **una cláusula se escribe una vez y se copia a las fichas hermanas**. Aquí
-- el copiado es un localizador ajeno —«Índice de estrofas» es un epígrafe de Navarro Tomás y no
-- existe en este libro— y estaba en cuatro fichas de Caparrós. Se arreglan tres; la cuarta se
-- explica al final.
--
-- ══ Los cuatro cambios
--
--   12fecf35  Octava real            p. 202, nota 180 → pp. 202-203
--             La nota 180 no es suya: su marcador va pegado al final de los esquemas de rima de la
--             **copla castellana** —«a b a b c d d c 180»—, un párrafo antes, y el párrafo de la
--             octava real no lleva ninguno. La ficha se la atribuía y con ella la discusión de
--             Lázaro Carreter sobre si es una estrofa o la unión de dos, que es de la castellana.
--             Y la octava de *La Araucana* empieza en la 202 y termina en la 203.
--
--   28847825  Oncena                 Índice de estrofas → p. 207
--             Además del localizador ajeno, la ficha remitía al *Diccionario* dentro de la voz de
--             Caparrós: «que sí registra en el *Diccionario* bajo "undécima"». Comparar dos fuentes
--             dentro de una es trabajo de la sección, no de la afirmación. El silencio gana en
--             cambio una prueba literal, en la p. 207: «No son frecuentes los esquemas fijos de
--             estrofas más allá de los diez versos».
--
--   5aa7f3eb  Redondilla enlazada    Índice de estrofas → pp. 185 y 188
--             Dos páginas, porque la ausencia se comprueba en dos sitios: en la 185 define el único
--             encadenamiento que sí admite, el del terceto, y en la 188 define la redondilla con
--             esquema fijo `abba` y sin variante enlazada.
--
--   274d62c8  Sextilla enlazada      Índice de estrofas → pp. 196-198
--             El apartado de las estrofas de seis versos va de la 196 a la 198: la 199 ya es el
--             septeto. El silencio gana también prueba literal: al tratar la copla de Jorge
--             Manrique dice que se ha considerado como estrofa de doce versos «pero las rimas
--             siempre son distintas en cada sextilla», que es exactamente negar el enlace.
--
-- ══ La cuarta, que no entra
--
-- **`11b899c3`, la septilla enlazada**, lleva el mismo «Índice de estrofas» y no estaba en ninguna
-- tanda: la pasada A la había dado por conforme. La encontró la guarda que iba a comprobar que la
-- cláusula desaparecía del catálogo entero, y no al revés. Su apartado es el 10.2.6, pp. 199-200,
-- pero es un cambio nuevo y lo aprueba David aparte.
--
-- Por eso la guarda de abajo **no exige cero**: exige que la única que quede sea esa, con su nombre
-- escrito, para que el día que se arregle la migración siguiente no pueda dejarse otra detrás.
--
-- David aprobó los cuatro textos el 17 de septiembre de 2026.

begin;

do $$
declare
	v_12fecf35_res constant text :=
			'La define como combinación de ocho endecasílabos consonantes de esquema ABABABCC y recoge '
			'«octava rima» y «octava heroica» como sus otros nombres. La ejemplifica con el comienzo de *La '
			'Araucana* de Ercilla.';
	v_28847825_res constant text :=
			'No le dedica epígrafe: su recorrido de las combinaciones estróficas termina en las de diez '
			'versos, y al cerrarlo anota que «no son frecuentes los esquemas fijos de estrofas más allá de '
			'los diez versos».';
	v_5aa7f3eb_res constant text :=
			'No la registra. Su recorrido de las combinaciones estróficas no contempla series en que la rima '
			'pase de una estrofa a la siguiente, fuera del terceto encadenado, que define en la p. 185; su '
			'redondilla, en la 188, la define con esquema fijo `abba` y sin variante enlazada.';
	v_274d62c8_res constant text :=
			'No la registra. Su recorrido de las estrofas de seis versos no contempla que la rima pase de una '
			'a la siguiente: al tratar la copla de Jorge Manrique dice que se ha considerado también como '
			'estrofa de doce versos, «pero las rimas siempre son distintas en cada sextilla».';
	v_ids constant uuid[] := array[
		'12fecf35-82b3-4d33-a8a9-e3e908827dc3'::uuid,
		'28847825-ca27-4671-a282-835d581610df'::uuid,
		'5aa7f3eb-5592-44c0-840a-cf47a3807f61'::uuid,
		'274d62c8-ea70-4044-8bc1-07a5e617bb8b'::uuid
	];
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que las cuatro son de Caparrós 2014, no vaya a ser que un uuid esté mal copiado.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.afirmacion_id = any(v_ids) and f.anio = 2014 and f.autoria = 'José Domínguez Caparrós';
	if v_cuantas <> 4 then
		raise exception 'Esperaba 4 afirmaciones de Domínguez Caparrós 2014 y encuentro %.', v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- Octava real · Domínguez Caparrós 2014
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '12fecf35-82b3-4d33-a8a9-e3e908827dc3'::uuid and localizador = 'p. 202, nota 180';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 12fecf35 no tiene hoy el localizador «p. 202, nota 180»; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = v_12fecf35_res, localizador = 'pp. 202-203'
	where afirmacion_id = '12fecf35-82b3-4d33-a8a9-e3e908827dc3'::uuid;

	-- Oncena · Domínguez Caparrós 2014
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '28847825-ca27-4671-a282-835d581610df'::uuid and localizador = 'Índice de estrofas';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 28847825 no tiene hoy el localizador «Índice de estrofas»; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = v_28847825_res, localizador = 'p. 207'
	where afirmacion_id = '28847825-ca27-4671-a282-835d581610df'::uuid;

	-- Redondilla enlazada · Domínguez Caparrós 2014
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '5aa7f3eb-5592-44c0-840a-cf47a3807f61'::uuid and localizador = 'Índice de estrofas';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 5aa7f3eb no tiene hoy el localizador «Índice de estrofas»; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = v_5aa7f3eb_res, localizador = 'pp. 185 y 188'
	where afirmacion_id = '5aa7f3eb-5592-44c0-840a-cf47a3807f61'::uuid;

	-- Sextilla enlazada · Domínguez Caparrós 2014
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '274d62c8-ea70-4044-8bc1-07a5e617bb8b'::uuid and localizador = 'Índice de estrofas';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 274d62c8 no tiene hoy el localizador «Índice de estrofas»; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = v_274d62c8_res, localizador = 'pp. 196-198'
	where afirmacion_id = '274d62c8-ea70-4044-8bc1-07a5e617bb8b'::uuid;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que cada una quedó **exactamente** con el texto que David aprobó, carácter a carácter. Estas
	-- cuatro cadenas salen de propuestas.json, que es lo que él leyó en el chat.
	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '12fecf35-82b3-4d33-a8a9-e3e908827dc3'::uuid
		and resumen = v_12fecf35_res
		and localizador = 'pp. 202-203';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 12fecf35 no ha quedado con el texto aprobado por David.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '28847825-ca27-4671-a282-835d581610df'::uuid
		and resumen = v_28847825_res
		and localizador = 'p. 207';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 28847825 no ha quedado con el texto aprobado por David.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '5aa7f3eb-5592-44c0-840a-cf47a3807f61'::uuid
		and resumen = v_5aa7f3eb_res
		and localizador = 'pp. 185 y 188';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 5aa7f3eb no ha quedado con el texto aprobado por David.';
	end if;

	select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '274d62c8-ea70-4044-8bc1-07a5e617bb8b'::uuid
		and resumen = v_274d62c8_res
		and localizador = 'pp. 196-198';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 274d62c8 no ha quedado con el texto aprobado por David.';
	end if;

	-- Que ninguna de las cuatro sigue comparándose con otro libro ni atribuyéndose la nota 180.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids)
		and (resumen like '%Diccionario%' or resumen like '%Lázaro Carreter%' or localizador like '%nota 180%');
	if v_cuantas > 0 then
		raise exception 'Quedan % afirmaciones remitiendo a otro libro o a la nota 180.', v_cuantas;
	end if;

	-- Y el epígrafe ajeno: de las cuatro de Caparrós que lo citaban solo puede quedar la septilla
	-- enlazada, que se decide aparte. Si algún día aparece otra, esto lo dice.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2014 and a.localizador like '%Índice de estrofas%';
	if v_cuantas <> 1 then
		raise exception 'Esperaba que quedase solo la septilla enlazada con «Índice de estrofas», y quedan %.',
			v_cuantas;
	end if;
	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
