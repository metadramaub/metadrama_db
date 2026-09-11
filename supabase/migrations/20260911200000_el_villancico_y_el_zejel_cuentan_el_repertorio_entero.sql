-- El villancico y el zéjel cuentan el repertorio entero
--
-- Las dos afirmaciones son ciertas y se conservan: Morley y Bruerton no registran ninguna forma
-- con estribillo, y se comprobó por búsqueda íntegra del capítulo —la palabra no aparece ni una
-- vez—. Lo que arrastraban era la enumeración incompleta del repertorio, la misma que falseó seis
-- afirmaciones en `20260911180000` y `20260911190000`: **faltaban las coplas de pie quebrado**.
--
-- Aquí no falsea nada, porque lo que se afirma es una ausencia de estribillo y no un recuento de
-- versos. Pero es la misma frase defectuosa, y dejarla después de corregir las otras seis sería
-- dejar la semilla: se copia de una ficha a otra, que es exactamente como se propagó.
--
-- Se ajusta además la fuerza de una inferencia nuestra. Que una copla de villancico o de zéjel
-- «caería» bajo «coplas» no lo dicen Morley y Bruerton: lo deducimos de cómo definen ese cajón.
-- Enunciado como posibilidad —«podría caer»— dice lo mismo sin atribuirles una clasificación que
-- no hacen. Lo señaló David al comprobar la afirmación del villancico contra la fuente, el 11 de
-- septiembre de 2026.
--
-- Y el localizador pasa a declarar el ámbito recorrido con sus páginas, como el resto de los
-- silencios de esta fuente.

begin;

do $$
declare
	v_villancico constant uuid := 'd1ea2ecf-b107-4f3f-b49f-97e7fcf1b725';
	v_zejel constant uuid := 'f5e83325-1e40-4465-98b9-173cd0fffcff';
	v_ambas constant uuid[] := array[v_villancico, v_zejel];
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.afirmacion_id = any(v_ambas) and f.anio = 1968;
	if v_cuantas <> 2 then
		raise exception 'Esperaba las dos afirmaciones y encontré %.', v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'Su repertorio de metros españoles no incluye ninguna forma con estribillo: define la '
			'redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla, el pareado '
			'y las coplas de pie quebrado, y reúne aparte, bajo «coplas», las estrofas cortas que no '
			'se incluyen en definiciones más específicas, que es donde podría caer una copla de '
			'villancico. Su «canción» es la canzone italiana de siete y once sílabas, no esta forma.',
		localizador = 'Cap. V, pp. 38-41; epígrafes «Coplas», p. 39, y «Canción (Canzone)», p. 40'
	where afirmacion_id = v_villancico;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'Su repertorio de metros españoles no incluye ninguna forma con estribillo: define la '
			'redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla, el pareado '
			'y las coplas de pie quebrado, y reúne aparte, bajo «coplas», las estrofas cortas que no '
			'se incluyen en definiciones más específicas, que es donde podría caer una copla de '
			'zéjel. Su «canción» es la canzone italiana de siete y once sílabas, no esta forma.',
		localizador = 'Cap. V, pp. 38-41; epígrafes «Coplas», p. 39, y «Canción (Canzone)», p. 40'
	where afirmacion_id = v_zejel;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que la enumeración está completa, que la inferencia ya no se afirma, y que lo que la
	-- afirmación sostiene —la ausencia de estribillo— sigue en pie: no se corrige lo que era cierto.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ambas) and resumen ilike '%y las coplas de pie quebrado%';
	if v_cuantas <> 2 then
		raise exception 'La enumeración sigue incompleta en % de las dos.', 2 - v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ambas) and resumen ilike '%caería%';
	if v_cuantas > 0 then
		raise exception 'Queda % afirmación dando por hecha una inferencia propia.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ambas) and resumen ilike '%ninguna forma con estribillo%';
	if v_cuantas <> 2 then
		raise exception 'Se ha perdido lo que la afirmación sostenía en % de las dos.', 2 - v_cuantas;
	end if;

	-- Y que en toda la fuente no queda ninguna enumeración del repertorio sin el pie quebrado.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1968
		and a.resumen ilike '%define la redondilla%'
		and a.resumen not ilike '%y las coplas de pie quebrado%';
	if v_cuantas > 0 then
		raise exception 'Quedan % enumeraciones incompletas en Morley y Bruerton.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
