-- Las tres últimas de fondo: la quintilla, la sextilla y la copla real de Caparrós
--
-- Con esta migración **el cubo de fondo queda a cero**. Eran treinta y cinco afirmaciones en las
-- que la fuente decía algo distinto de lo que el catálogo le atribuía, o en las que no se había
-- podido confirmar lo dicho, y se han corregido una a una con el texto viejo y el nuevo enfrentados.
--
--   78f48b2b  Quintilla. La ficha ataba a la p. 195 dos datos de dos sitios. Lo que la 195 dice es
--             que «la quintilla, antiguamente llamada también redondilla, es una combinación de
--             cinco versos octosílabos, o menores, con dos rimas consonantes distintas», y nada más
--             sobre el nombre; lo de los tratadistas del Siglo de Oro es la **nota 174 de la
--             p. 188**, anclada al epígrafe de la redondilla, y ya está recogida en la ficha del
--             cuarteto de esta misma fuente, con su página. Aquí se queda lo que la 195 sostiene, y
--             entra de paso la definición, que no teníamos.
--   c0160a43  Sextilla. La regla de la sinafía o compensación cuando el quebrado tiene cinco
--             sílabas no está en el capítulo de las combinaciones estróficas sino en el de la
--             sílaba, el § 4.4, que la ilustra con las mismas Coplas de Jorge Manrique. El dato es
--             de la sextilla de pie quebrado, así que se declara el segundo sitio y el texto dice
--             que se explica aparte.
--   cda0d43d  Copla real. El localizador señalaba la p. 199, que trata el septeto; la copla real se
--             define en la 205, comprobado en la hoja 202 del PDF. Y el contraste que la ficha
--             atribuía a la décima espinela no es con ella: la frase «nótese que, a diferencia de
--             la copla real, **en este ejemplo** hay una rima común a las dos partes de la estrofa»
--             va **antes** de la definición y se refiere al ejemplo de décima antigua que acaba de
--             dar. La espinela no aparece en esa página.

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- 78f48b2b · Quintilla · Domínguez Caparrós 2014
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '78f48b2b-0ee9-4001-b805-d1c583ed5ac8'::uuid and resumen like '%lo que explica que en los tratadistas del Siglo de Oro%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 78f48b2b no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Advierte que la quintilla se llamó antiguamente también redondilla, y la define como combinación de cinco versos octosílabos, o menores, con dos rimas consonantes distintas.',
		localizador = 'p. 195'
	where afirmacion_id = '78f48b2b-0ee9-4001-b805-d1c583ed5ac8'::uuid;

	-- c0160a43 · Sextilla · Domínguez Caparrós 2014
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'c0160a43-9878-4a2c-aa75-9d7f597139e5'::uuid and resumen like '%y explica que cuando el quebrado tiene cinco sílabas%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación c0160a43 no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, cuyo esquema escribe `- a a b b a`: el primer verso queda sin rima. El poema de Manuel Machado que cita en heptasílabos rima `aababa`. Describe la copla de Jorge Manrique como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c, y explica aparte, en el capítulo de la sílaba, que cuando el quebrado tiene cinco sílabas métricas la medida se resuelve por sinafía o compensación con el octosílabo anterior. Recoge que se ha considerado también estrofa de doce versos cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada una.',
		localizador = 'pp. 196-198, y § 4.4, pp. 65-66'
	where afirmacion_id = 'c0160a43-9878-4a2c-aa75-9d7f597139e5'::uuid;

	-- cda0d43d · Copla real · Domínguez Caparrós 2014
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'cda0d43d-fd2f-475c-86da-30d5d85d5967'::uuid and resumen like '%Contrasta esa independencia de rimas con la décima espinela%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación cda0d43d no tiene hoy el texto que espero; no la toco.';
	end if;
	update public.afirmaciones_fuentes_metricas
	set resumen = 'La define como combinación de diez octosílabos agrupados en dos quintillas con rimas consonantes independientes, y precisa que las dos semiestrofas pueden tener o no el mismo esquema de distribución. Recoge que a veces se la llama quintilla doble y décima falsa, la sitúa en el grupo de las coplas medievales y afirma que su cultivo llega hasta el Siglo de Oro. Al ejemplificar una décima antigua anota el contraste: «nótese que, a diferencia de la copla real, en este ejemplo hay una rima común a las dos partes de la estrofa».',
		localizador = 'p. 205'
	where afirmacion_id = 'cda0d43d-fd2f-475c-86da-30d5d85d5967'::uuid;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = '78f48b2b-0ee9-4001-b805-d1c583ed5ac8'::uuid
		and resumen = 'Advierte que la quintilla se llamó antiguamente también redondilla, y la define como combinación de cinco versos octosílabos, o menores, con dos rimas consonantes distintas.'
		and localizador = 'p. 195';
	if v_cuantas <> 1 then
		raise exception 'La afirmación 78f48b2b no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'c0160a43-9878-4a2c-aa75-9d7f597139e5'::uuid
		and resumen = 'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, cuyo esquema escribe `- a a b b a`: el primer verso queda sin rima. El poema de Manuel Machado que cita en heptasílabos rima `aababa`. Describe la copla de Jorge Manrique como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c, y explica aparte, en el capítulo de la sílaba, que cuando el quebrado tiene cinco sílabas métricas la medida se resuelve por sinafía o compensación con el octosílabo anterior. Recoge que se ha considerado también estrofa de doce versos cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada una.'
		and localizador = 'pp. 196-198, y § 4.4, pp. 65-66';
	if v_cuantas <> 1 then
		raise exception 'La afirmación c0160a43 no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'cda0d43d-fd2f-475c-86da-30d5d85d5967'::uuid
		and resumen = 'La define como combinación de diez octosílabos agrupados en dos quintillas con rimas consonantes independientes, y precisa que las dos semiestrofas pueden tener o no el mismo esquema de distribución. Recoge que a veces se la llama quintilla doble y décima falsa, la sitúa en el grupo de las coplas medievales y afirma que su cultivo llega hasta el Siglo de Oro. Al ejemplificar una décima antigua anota el contraste: «nótese que, a diferencia de la copla real, en este ejemplo hay una rima común a las dos partes de la estrofa».'
		and localizador = 'p. 205';
	if v_cuantas <> 1 then
		raise exception 'La afirmación cda0d43d no ha quedado con el texto aprobado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
