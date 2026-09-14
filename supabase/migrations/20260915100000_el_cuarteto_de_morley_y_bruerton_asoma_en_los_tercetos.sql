-- El cuarteto de Morley y Bruerton asoma en los tercetos, no en los sueltos
--
-- La afirmación decía que el cuarteto «aparece en su descripción de los sueltos, como uno de los
-- cierres posibles de un pasaje». El epígrafe «Sueltos» (p. 40) no menciona el cuarteto en ningún
-- punto: cita el cierre en pareado y nada más.
--
-- **La palabra «cuarteto» aparece una sola vez en todo el capítulo V**, y es en el epígrafe
-- «Tercetos (sin encadenar)», también en la p. 40:
--
--   «Endecasílabos, ya sea `AXABYB`, etc., o `XAAYBB`, etc. **El primer tipo puede acabar en un
--    pareado o en un cuarteto.**»
--
-- Lo que la afirmación dice de fondo —que Morley y Bruerton no definen el cuarteto como forma
-- independiente y que solo asoma como cierre posible de un pasaje— es exacto. Lo que fallaba era
-- el epígrafe del que se decía que salía. Lo vieron la pasada A y la pasada C por separado, y se
-- confirmó leyendo el capítulo entero, que son cuatro páginas y diecinueve epígrafes.
--
-- El localizador pasa además de «Cap. V» a secas —que no distingue entre esos diecinueve— al
-- epígrafe y la página concretos. Es el caso de localizador no seguible que el plan pone como
-- ejemplo: con «Cap. V» nadie llega al pasaje.
--
-- David lo aprobó el 15 de septiembre de 2026.

begin;

do $$
declare
	v_cuarteto constant uuid := '339090a5-b69e-487f-8aa2-dbe0f82f3ce2';
	v_antiguo constant text :=
		'No lo definen como forma independiente: el cuarteto aparece en su descripción de los sueltos, '
		'como uno de los cierres posibles de un pasaje.';
	v_nuevo constant text :=
		'No lo definen como forma independiente: el cuarteto aparece en su descripción de los tercetos '
		'sin encadenar, como uno de los cierres posibles de un pasaje.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_cuarteto and resumen = v_antiguo and localizador = 'Cap. V';
	if v_cuantas <> 1 then
		raise exception 'La afirmación del cuarteto no está como espero; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_nuevo,
		localizador = 'Cap. V, «Tercetos (sin encadenar)», p. 40'
	where afirmacion_id = v_cuarteto;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que ya no dice «sueltos», que dice de dónde sale de verdad, y que no se ha perdido lo que la
	-- afirmación sostenía, que era lo correcto de ella.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_cuarteto
		and resumen not like '%descripción de los sueltos%'
		and resumen like '%tercetos sin encadenar%'
		and resumen like '%No lo definen como forma independiente%'
		and resumen like '%cierres posibles de un pasaje%'
		and localizador = 'Cap. V, «Tercetos (sin encadenar)», p. 40';
	if v_cuantas <> 1 then
		raise exception 'El cuarteto no ha quedado como se pretendía.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
