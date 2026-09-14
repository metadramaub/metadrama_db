-- La tercera de la familia: la sextilla enlazada del Diccionario
--
-- La cláusula «su repertorio de enlaces entre estrofas es el de la gaya ciencia» estaba en tres
-- fichas del *Diccionario*. Dos se corrigieron en la migración 20260916220000; esta es la tercera,
-- y **la encontró la guarda de aquella**, que exigía que no quedara ninguna.
--
-- Importa dónde estaba: en el cubo de las **conformes**. La pasada A la dio por buena con una
-- observación, la lectura ciega no la contradijo y el cotejo no la señaló, de modo que no estaba
-- previsto que nadie volviera a mirarla. Lo que la sacó a la luz no fue una pasada ni una
-- comprobación mecánica, sino **exigirle a una migración que dejara el catálogo sin rastro de una
-- frase falsa**, en vez de limitarse a arreglar las fichas de la lista.
--
-- El silencio que declara es correcto: no hay «sextilla enlazada» en el diccionario. Lo falso era
-- la explicación, porque sí registra el enlace entre estrofas en otras medidas, con entradas para
-- el «sexteto enlazado» y el «terceto enlazado».

begin;

do $$
declare
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'da0d0e2d-bbaf-41dd-83ba-417d4c37e7a5'::uuid
		and resumen like '%repertorio de enlaces entre estrofas es el de la gaya ciencia%';
	if v_cuantas <> 1 then
		raise exception 'La sextilla enlazada no tiene hoy el texto que espero; no la toco.';
	end if;

	update public.afirmaciones_fuentes_metricas
	set resumen = 'No la registra. Describe la sextilla como estrofa cerrada sobre sí misma, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», ninguna de ellas es una sextilla enlazada.',
		localizador = 'Entradas «sextilla», «copla encadenada» y «sexteto enlazado»'
	where afirmacion_id = 'da0d0e2d-bbaf-41dd-83ba-417d4c37e7a5'::uuid;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = 'da0d0e2d-bbaf-41dd-83ba-417d4c37e7a5'::uuid
		and resumen = 'No la registra. Describe la sextilla como estrofa cerrada sobre sí misma, y aunque sí tiene entrada para el enlace entre estrofas en otras medidas —«sexteto enlazado», lema que lleva la marca de autoridad «(Navarro Tomás)», y «terceto enlazado»— y para la copla encadenada de la gaya ciencia, «estrofa en la que hay lexaprén», ninguna de ellas es una sextilla enlazada.'
		and localizador = 'Entradas «sextilla», «copla encadenada» y «sexteto enlazado»';
	if v_cuantas <> 1 then
		raise exception 'La sextilla enlazada no ha quedado con el texto aprobado.';
	end if;

	-- Y ahora sí: ninguna afirmación del Diccionario sigue diciéndolo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2016 and a.resumen like '%repertorio de enlaces entre estrofas es el de la gaya ciencia%';
	if v_cuantas <> 0 then
		raise exception 'Todavía quedan % afirmaciones con el repertorio de enlaces falso.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
