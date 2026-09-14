-- El repertorio de enlaces del Diccionario no se agota en la gaya ciencia
--
-- Las cinco afirmaciones de fondo del *Diccionario de métrica española*. El SQL se generó desde
-- `propuestas.json` y la guarda final comprueba igualdad exacta con el texto que David aprobó.
--
-- ══ El par de las enlazadas, y una contradicción nuestra
--
-- Las fichas de la redondilla enlazada y de la septilla enlazada cerraban las dos igual: «su
-- repertorio de enlaces entre estrofas es el de la gaya ciencia —la copla encadenada, en la que hay
-- lexaprén—, que Navarro Tomás distingue expresamente de estas series».
--
-- El silencio es correcto —no hay «redondilla enlazada» ni «septeto enlazado» en el diccionario—,
-- pero la explicación es falsa. El *Diccionario* **sí registra el enlace entre estrofas**: tiene
-- entrada propia para el «sexteto enlazado», «sexteto en que el primer verso —o el primero y el
-- último— no rima con ninguno de la estrofa, sino con el último del sexteto anterior», y otra para
-- el «terceto enlazado». Lo que no tiene es una redondilla ni una septilla enlazadas.
--
-- **La cláusula está en tres fichas, no en dos.** La tercera es la de la sextilla enlazada, y la
-- guarda de esta migración la encontró al exigir que no quedara ninguna. No entra aquí porque su
-- texto nuevo está sin aprobar, y conviene subrayar dónde estaba: en el cubo de las **conformes**.
-- La pasada A la dio por buena con una observación, de modo que no estaba previsto ni mirarla.
--
-- **Y el catálogo ya se contradecía a sí mismo.** La ficha del sexteto de esta misma fuente termina
-- diciendo que «tipifica además el sexteto agudo, el alterno, el correlativo, **el enlazado**, el
-- libre y el simétrico». Tres afirmaciones de un mismo libro, dos afirmando que su único enlace es
-- el de la gaya ciencia y la tercera nombrando el que lo desmiente.
--
-- ══ Sobre la marca de autoridad, que no es vocabulario importado
--
-- Los textos nuevos dicen que «sexteto enlazado» lleva la marca «(Navarro Tomás)». Conviene
-- distinguirlo de lo que se ha estado retirando toda esta ronda —«donde Quilis da CDC DCD», «que sí
-- recoge en el *Diccionario*»—, que eran comparaciones **nuestras** metidas en la voz de una fuente.
-- Aquí no: **el paréntesis lo imprime el libro**. Es una convención suya y sistemática, en 713
-- entradas, para señalar de quién es el término y no de quién es la definición: 152 llevan la marca
-- de Navarro Tomás, 117 la de Rafael de Balbín, 66 la de Dorothy C. Clarke, 45 la de Baehr, 17 la
-- de Quilis. Callarla sería perder información que la fuente da. Por eso mismo el guion de la
-- auditoría tuvo que aprender a reconocer entradas con la forma `lema (Autoridad).`: sin eso, el
-- localizador de media obra habría salido inexistente.
--
-- ══ Dos omisiones y un endurecimiento
--
--   e5868e5e  Endecha real. La entrada tiene seis líneas y le faltaban dos cosas: los «pareados de
--             doce sílabas» como tercera variante de verso, y los ejemplos concretos de las otras
--             formas métricas en que pueden hallarse endechas, «redondillas o versos sueltos».
--   515d9993  Octava real. La fuente documenta dos tradiciones, «asociada a la poesía épica **o a la
--             lírica de tono elevado**», y la ficha recogía solo la primera.
--   ce5d5f5c  Sexteto. «La introducción de heptasílabos —**especialmente** a partir del
--             Romanticismo» se había quedado en «desde el Romanticismo», que se lee como un origen
--             fijado ahí y no como un fenómeno posible antes y más frecuente después.

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- e5868e5e · Endecha real · Diccionario 2016
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e5868e5e-aa76-462c-84f0-7602af0657a1'::uuid and resumen like '%aunque admite versos de cinco o de seis sílabas%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e5868e5e no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La endecha, sin más, es poema de asunto triste en forma de romancillo heptasílabo «generalmente», aunque admite también versos de cinco o de seis sílabas, o pareados de doce. Y como el nombre «se refiere más bien al asunto propio del poema», dice que es posible encontrar endechas en otras formas métricas, «redondillas o versos sueltos, por ejemplo».',
		localizador = 'Entrada «endecha», p. 148'
	where afirmacion_id = 'e5868e5e-aa76-462c-84f0-7602af0657a1'::uuid;

	-- 515d9993 · Octava real · Diccionario 2016
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '515d9993-f408-49be-8ce4-847eebfe6797'::uuid and resumen like '%tradicionalmente asociada a la poesía épica.%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 515d9993 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Advierte que «es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos». Añade que la estrofa suele subdividirse en dos grupos de cuatro versos según su contenido, y que está «tradicionalmente asociada a la poesía épica o a la lírica de tono elevado».',
		localizador = 'Entrada «octava real», p. 246'
	where afirmacion_id = '515d9993-f408-49be-8ce4-847eebfe6797'::uuid;

	-- 423b6dca · Redondilla enlazada · Diccionario 2016
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '423b6dca-b7fe-4179-ba6a-241ff640e236'::uuid and resumen like '%Su repertorio de enlaces entre estrofas es el de la gaya ciencia%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 423b6dca no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'No la registra. Sí tiene entradas para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)» con que este diccionario señala de quién es el término, y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», con «copla capfinida» y «canción de coleo» como otros términos. Ninguna de ellas es una redondilla enlazada.',
		localizador = 'Entradas «copla encadenada», «copla capfinida» y «sexteto enlazado»'
	where afirmacion_id = '423b6dca-b7fe-4179-ba6a-241ff640e236'::uuid;

	-- b55ae482 · Septilla enlazada · Diccionario 2016
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'b55ae482-7f6d-40e5-acb7-f55caf07a4d4'::uuid and resumen like '%Sus estrofas de siete versos son cerradas, y su repertorio%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación b55ae482 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'No la registra: su entrada «séptima» no recoge ninguna variedad enlazada y no hay «septeto enlazado» ni equivalente. Sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén».',
		localizador = 'Entradas «séptima», «copla encadenada» y «sexteto enlazado»'
	where afirmacion_id = 'b55ae482-7f6d-40e5-acb7-f55caf07a4d4'::uuid;

	-- ce5d5f5c · Sexteto · Diccionario 2016
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'ce5d5f5c-c17a-46c6-aa71-19df4113c16c'::uuid and resumen like '%introducción de heptasílabos desde el Romanticismo%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación ce5d5f5c no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Define el sexteto como estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante que puede adoptar variadas disposiciones, y advierte que a veces el término se aplica también a la estrofa compuesta en versos de arte menor. La sexta rima es el sexteto de endecasílabos que rima el primero con el tercero, el segundo con el cuarto y el quinto con el sexto, con modificaciones posibles del esquema y la introducción de heptasílabos «**especialmente** a partir del Romanticismo». Tipifica además el sexteto agudo, el alterno, el correlativo, el enlazado, el libre y el simétrico.',
		localizador = 'Entradas «sexteto» y «sexta rima»'
	where afirmacion_id = 'ce5d5f5c-c17a-46c6-aa71-19df4113c16c'::uuid;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Igualdad exacta con el texto aprobado, una por una.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'e5868e5e-aa76-462c-84f0-7602af0657a1'::uuid
		and resumen = 'La endecha, sin más, es poema de asunto triste en forma de romancillo heptasílabo «generalmente», aunque admite también versos de cinco o de seis sílabas, o pareados de doce. Y como el nombre «se refiere más bien al asunto propio del poema», dice que es posible encontrar endechas en otras formas métricas, «redondillas o versos sueltos, por ejemplo».'
		and localizador = 'Entrada «endecha», p. 148';
	if v_cuantas <> 1 then
		raise exception 'La afirmación e5868e5e no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '515d9993-f408-49be-8ce4-847eebfe6797'::uuid
		and resumen = 'Advierte que «es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos». Añade que la estrofa suele subdividirse en dos grupos de cuatro versos según su contenido, y que está «tradicionalmente asociada a la poesía épica o a la lírica de tono elevado».'
		and localizador = 'Entrada «octava real», p. 246';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 515d9993 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '423b6dca-b7fe-4179-ba6a-241ff640e236'::uuid
		and resumen = 'No la registra. Sí tiene entradas para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)» con que este diccionario señala de quién es el término, y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», con «copla capfinida» y «canción de coleo» como otros términos. Ninguna de ellas es una redondilla enlazada.'
		and localizador = 'Entradas «copla encadenada», «copla capfinida» y «sexteto enlazado»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 423b6dca no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'b55ae482-7f6d-40e5-acb7-f55caf07a4d4'::uuid
		and resumen = 'No la registra: su entrada «séptima» no recoge ninguna variedad enlazada y no hay «septeto enlazado» ni equivalente. Sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén».'
		and localizador = 'Entradas «séptima», «copla encadenada» y «sexteto enlazado»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación b55ae482 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'ce5d5f5c-c17a-46c6-aa71-19df4113c16c'::uuid
		and resumen = 'Define el sexteto como estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante que puede adoptar variadas disposiciones, y advierte que a veces el término se aplica también a la estrofa compuesta en versos de arte menor. La sexta rima es el sexteto de endecasílabos que rima el primero con el tercero, el segundo con el cuarto y el quinto con el sexto, con modificaciones posibles del esquema y la introducción de heptasílabos «**especialmente** a partir del Romanticismo». Tipifica además el sexteto agudo, el alterno, el correlativo, el enlazado, el libre y el simétrico.'
		and localizador = 'Entradas «sexteto» y «sexta rima»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación ce5d5f5c no ha quedado con el texto aprobado.';
	end if;

	-- Queda **una** afirmación de esta fuente diciendo que su repertorio de enlaces se agota en la
	-- gaya ciencia: la de la sextilla enlazada, que lleva la misma cláusula copiada y que no entra
	-- aquí porque su texto nuevo está sin aprobar. Decir que es una, y cuál, es la única manera de
	-- que este recuento signifique algo. La primera versión de la guarda exigía cero y tumbó la
	-- migración, que es exactamente lo que tenía que hacer: fue así como se descubrió la tercera.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2016 and a.resumen like '%repertorio de enlaces entre estrofas es el de la gaya ciencia%';
	if v_cuantas <> 1 then
		raise exception 'Esperaba que quedara 1 afirmación con el repertorio de enlaces falso —la sextilla enlazada— y quedan %.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
