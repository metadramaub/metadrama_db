-- El recuento de las estrofas de ocho versos va entero
--
-- La afirmación de la octava aguda cita entre comillas el recuento con que Domínguez Caparrós abre
-- el epígrafe «10.2.7. Estrofas de ocho versos», y **se come el primer término de la enumeración**.
--
--   Nuestra ficha:  «la copla de arte menor, la copla castellana, la octava real, la octava y la
--                    octavilla agudas»
--   El libro, p. 200 (hoja 197 del PDF, pie impreso «200»):
--                   «Las principales estrofas de ocho versos son: la copla de arte mayor, la copla
--                    de arte menor, la copla castellana, la octava real, la octava y la octavilla
--                    agudas.»
--
-- Es una cita inexacta, y de las que engañan: lo entrecomillado se lee como el repertorio completo
-- de la fuente para las estrofas de ocho versos, y falta una de las seis. No lo vio ninguna de las
-- tres pasadas. Salió al abrir la hoja para comprobar el localizador de esta misma afirmación, que
-- se corrigió en la migración 20260914160000.
--
-- David lo aprobó el 14 de septiembre de 2026. Se restituye el término que falta y no se toca nada
-- más: el resto de la afirmación se comprobó exacto.

begin;

do $$
declare
	v_octava constant uuid := 'b22cf39e-bda9-4377-9c81-85735cec0662';
	v_antiguo constant text :=
		'La incluye en su recuento de las estrofas de ocho versos —«la copla de arte menor, la copla '
		'castellana, la octava real, la octava y la octavilla agudas»— y precisa que cuando la octava '
		'aguda va en versos de arte menor se llama octavilla aguda u octava italiana.';
	v_nuevo constant text :=
		'La incluye en su recuento de las estrofas de ocho versos —«la copla de arte mayor, la copla '
		'de arte menor, la copla castellana, la octava real, la octava y la octavilla agudas»— y '
		'precisa que cuando la octava aguda va en versos de arte menor se llama octavilla aguda u '
		'octava italiana.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Se exige el texto antiguo entero, no un fragmento: si alguien lo ha retocado por su cuenta,
	-- esta migración tiene que pararse en vez de machacar lo que hubiera.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_octava and resumen = v_antiguo;
	if v_cuantas <> 1 then
		raise exception 'La afirmación de la octava aguda no tiene hoy el texto que espero; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_nuevo
	where afirmacion_id = v_octava;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que el término restituido está, que la enumeración sigue completa hasta el final y que no se
	-- ha perdido la segunda mitad de la afirmación, que estaba bien.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_octava
		and resumen like '%la copla de arte mayor, la copla de arte menor, la copla castellana, la octava real, la octava y la octavilla agudas%'
		and resumen like '%octavilla aguda u octava italiana%';
	if v_cuantas <> 1 then
		raise exception 'La cita no ha quedado completa.';
	end if;

	-- Y que el localizador sigue donde lo dejó la migración anterior: esta no lo toca.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_octava and localizador = 'pp. 200 y 203';
	if v_cuantas <> 1 then
		raise exception 'El localizador de la octava aguda ya no es «pp. 200 y 203».';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
