-- Cinco localizadores del cubo material, sin tocar una palabra de prosa
--
-- Los cinco del bloque material que se arreglan sin que nadie tenga que leer un texto nuevo: el
-- contenido de las cinco fichas se comprobó exacto y lo único que fallaba era dónde decía que
-- estaba. Comprobados uno a uno por mí en el PDF o en el volcado.
--
--   f776aada  Seguidilla · Caparrós 2014      pp. 191-194 → pp. 192-195
--             La 191 no trata la seguidilla: es el final del apartado anterior, la variante de la
--             sáfica de Francisco de la Torre (hoja 188). El apartado arranca en la 192 —«la
--             seguidilla es una composición de cuatro versos…»— y la gitana, que la ficha recoge,
--             está en la 195 (hoja 192). Sobraba una página por delante y faltaba una por detrás.
--
--   19fc8274  Octava aguda · Jauralde 2020    «Octavillas y octavas»
--                                           → «Estrofas de ocho versos», «Octavilla heptasilábica»
--                                             y «Octavas endecasilábicas»
--             «Octavillas y octavas» no es un epígrafe: es la frase con que arranca el de las
--             estrofas de ocho versos. Era la última de las cuatro fichas que lo citaban. Y la
--             afirmación está repartida en tres sitios: la fecha y el ejemplo de *El reo de muerte*
--             en el primero, el de *La orgía* de Zorrilla en el segundo y la extensión a las
--             estrofas de arte mayor en el tercero.
--
--   d8f31c19  Novena · Navarro Tomás 1972     «§ "Novena, 4-5" y § "Copla de pie quebrado: Novena"»
--                                           → §§ 67 y 68
--             Los dos títulos no existen así en el original: son rótulos compuestos a partir de la
--             prosa. Este libro se cita por § numerado, como hace correctamente la ficha vecina de
--             la oncena, que declara los mismos dos.
--
--   14228466  Pareado · Morley y Bruerton     «Cap. V, "Pareados"» → «Cap. V, "Pareados", p. 39»
--             El capítulo tiene **dos** epígrafes llamados «Pareados» con definiciones distintas: el
--             octosílabo de los metros españoles, en la p. 39, y el endecasílabo de las formas
--             italianas, en la p. 41. La ficha habla de «dísticos de octosílabos», así que es el
--             primero, y la página lo desambigua.
--
--   2d0599a0  Sexteto · Jauralde 2020         se añade «Pentadecasílabos»
--             La ficha enumera los sextetos por medida y llega hasta los pentadecasilábicos, y esos
--             no están en el capítulo de las estrofas de seis versos sino en el del verso
--             pentadecasílabo, en otro sitio del libro.
--
-- No entra aquí, y conviene dejarlo escrito, el cuarteto de Jauralde (`7453d194`): la pasada A le
-- puso «anclaje equivocado» diciendo que su primera frase venía de la introducción del capítulo, y
-- la localización ciega lo desmiente. Las dos mitades de esa ficha describen la misma frase del
-- libro —«al cuarteto endecasilábico cruzado (ABAB) se lo suele denominar serventesio»—, de modo
-- que el localizador es correcto y lo único que se le podría reprochar es decir dos veces lo mismo,
-- que no es un defecto de los que aquí se corrigen.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['f776aada-4def-45b1-add8-f711b9affc48', 'pp. 191-194', 'pp. 192-195'],
		array['19fc8274-116c-47cb-9beb-8c447c96b7aa',
			'Apartado «Octavillas y octavas»',
			'Apartados «Estrofas de ocho versos», «Octavilla heptasilábica» y «Octavas endecasilábicas»'],
		array['d8f31c19-6307-43c3-bcae-25311834d2c7',
			'§ «Novena, 4-5» y § «Copla de pie quebrado: Novena»',
			'§§ 67 y 68'],
		array['14228466-1aae-4efa-b58a-f1aa23a5968c', 'Cap. V, «Pareados»', 'Cap. V, «Pareados», p. 39'],
		array['2d0599a0-63ef-4512-aab5-464671d4a4c4',
			'Apartados «Estrofas de seis versos», «Sextetos» y «Sextina real»',
			'Apartados «Estrofas de seis versos», «Sextetos», «Sextina real» y «Pentadecasílabos»']
	];
	v_fila text[];
	v_ids uuid[] := '{}';
	v_cuantas integer;
	v_puestos integer := 0;
	v_resumen_antes text;
	v_resumen_despues text;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	foreach v_fila slice 1 in array v_cambios loop
		v_ids := v_ids || (v_fila[1])::uuid;
	end loop;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_antes
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where afirmacion_id = (v_fila[1])::uuid and localizador = v_fila[2];
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				left(v_fila[1], 8), v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3]
		where afirmacion_id = (v_fila[1])::uuid;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where afirmacion_id = (v_fila[1])::uuid and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Y con esto se acaba «Octavillas y octavas» en el catálogo entero: era la cuarta y última.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where localizador like '%Octavillas y octavas%';
	if v_cuantas <> 0 then
		raise exception 'Todavía quedan % afirmaciones citando «Octavillas y octavas».', v_cuantas;
	end if;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_despues
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);
	if v_resumen_despues is distinct from v_resumen_antes then
		raise exception 'Ha cambiado el texto de alguna afirmación, y esta migración solo movía localizadores.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
