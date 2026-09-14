-- Los localizadores de Domínguez Caparrós 2014 llevan ya al pasaje
--
-- El localizador drifted es, con diferencia, el defecto más numeroso de la auditoría: 33 marcados
-- por la pasada A y 20 más que añadió la lectura ciega. En Caparrós 2014 se ve de dónde sale el
-- vicio con toda claridad: **«pp. 205 y ss.» es literalmente el mismo localizador en cinco
-- afirmaciones distintas** —copla castellana, copla de arte menor, octava aguda, septeto y
-- septilla—, y la página 205 no trata ninguna de las cinco: trata la copla real y el comienzo de
-- la décima espinela. Se copió una vez y se arrastró.
--
-- Aquí se corrigen seis, las que **las dos pasadas sitúan en el mismo sitio y se han comprobado
-- además abriendo el PDF hoja por hoja**, leyendo el número impreso al pie. El desfase de este
-- libro es hoja + 3 = página impresa, y así se verificó en cada una:
--
--   3d5e851e  Copla castellana    pp. 205 y ss. → p. 202        hoja 199, pie «202»
--   f7c945ff  Copla de arte menor pp. 205 y ss. → p. 201        hoja 198, pie «201»
--   cde408cf  Copla manriqueña    pp. 200 y ss. → pp. 196-197   hojas 193-194, pies «196» y «197»
--   7e08e2e3  Septeto             pp. 205 y ss. → p. 199        hoja 196, cabecera «10.2.6. Septeto»
--   cf0381d4  Sexteto-lira        p. 198        → p. 199        hoja 196, con sus dos ejemplos
--   c08b7611  Zéjel               pp. 213-214   → pp. 210-211   hojas 207-208, «11.1.1 • Zéjel»
--
-- **No se toca una palabra de prosa.** Lo que cada afirmación dice de su fuente se comprobó exacto
-- en las dos pasadas; lo único que fallaba era dónde decía que estaba.
--
-- Las otras once afirmaciones materiales de esta fuente no entran aquí, y conviene decir por qué:
--
--   - En cuatro las dos pasadas **no coinciden** en la página nueva —octava aguda, septilla,
--     cuarteto, soneto—, y un localizador corregido a medias es peor que uno malo, porque parece
--     comprobado. Piden una tercera lectura.
--   - Cuatro citan «Índice de estrofas», que **es un epígrafe de Navarro Tomás y no existe en este
--     libro**: son silencios, y un silencio no se arregla con una página, sino declarando su
--     ámbito.
--   - Y la de la octava real (`12fecf35`) resultó no ser un problema de localizador. Al abrir la
--     hoja 199 se ve que el marcador de la nota 180 va pegado al final de los esquemas de rima de
--     la copla castellana —«… a b a b c d d c 180.»— y que el párrafo de la octava real no lleva
--     ninguno. La nota dice: «Para la discusión de si se trata de una estrofa o de la unión de dos
--     estrofas, véase F. Lázaro Carreter (1983)», que es la pregunta de la copla castellana —ocho
--     octosílabos en dos semiestrofas—, no la de la octava real, que es una sola estrofa ABABABCC.
--     Nuestra afirmación se la atribuye a la octava real, así que **hay texto que reescribir** y va
--     con las de fondo.

begin;

do $$
declare
	-- El par es (identificador, localizador que tiene que tener ahora, localizador nuevo). Se
	-- declara el valor antiguo **y se exige** antes de tocar nada: si alguien ya lo corrigió a mano,
	-- o si esta migración se reaplicara sobre un estado distinto, tiene que fallar en vez de
	-- machacar en silencio lo que hubiera.
	v_cambios constant text[][] := array[
		array['3d5e851e-bd12-4d98-b452-f7a3ff565ab7', 'pp. 205 y ss.', 'p. 202'],
		array['f7c945ff-464c-4b6f-96a6-4f0e92bfba59', 'pp. 205 y ss.', 'p. 201'],
		array['cde408cf-6e98-440d-b9f0-605c6d345d73', 'pp. 200 y ss.', 'pp. 196-197'],
		array['7e08e2e3-661d-4f4b-9072-47191e850aed', 'pp. 205 y ss.', 'p. 199'],
		array['cf0381d4-bc7d-48b4-b143-1c0e90f3342e', 'p. 198', 'p. 199'],
		array['c08b7611-236b-4f83-ae46-d64c0975cbaf', 'pp. 213-214', 'pp. 210-211']
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

	-- `unnest` aplana un array de dos dimensiones hasta los escalares, así que no sirve para
	-- recorrer estas filas: hay que usar `foreach … slice 1`, y los identificadores se juntan aparte.
	foreach v_fila slice 1 in array v_cambios loop
		v_ids := v_ids || (v_fila[1])::uuid;
	end loop;

	-- La prosa entera de las seis, antes de tocar. Esta migración promete no cambiar ni una letra
	-- de lo que dicen las afirmaciones, y esa promesa se comprueba al final en vez de confiarse.
	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_antes
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		where a.afirmacion_id = (v_fila[1])::uuid
			and a.localizador = v_fila[2]
			and f.anio = 2014;
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				left(v_fila[1], 8), v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3]
		where afirmacion_id = (v_fila[1])::uuid;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que las seis llevan el localizador nuevo.
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

	-- Que no quedó ninguna afirmación de esta fuente citando «pp. 205 y ss.», que era el
	-- localizador copiado. Quedan las dos que no se tocan aquí —octava aguda y septilla—, así que
	-- la cuenta esperada es 2, no 0: decirlo es la única manera de que este recuento signifique algo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2014 and a.localizador = 'pp. 205 y ss.';
	if v_cuantas <> 2 then
		raise exception 'Esperaba que quedaran 2 afirmaciones con «pp. 205 y ss.» y quedan %.', v_cuantas;
	end if;

	-- Y que la prosa está intacta.
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
