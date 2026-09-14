-- Seis localizadores del Diccionario y de Jauralde llevan ya al pasaje
--
-- Tercera tanda resuelta con la pasada C y comprobada después abriendo el PDF o el volcado. De las
-- veinte afirmaciones que trajo esta remesa, estas seis son las que **no necesitan tocar una
-- palabra de prosa**: el texto de la ficha se comprobó exacto y lo único que fallaba era dónde
-- decía que estaba.
--
-- **Diccionario 2016.** Un diccionario reparte lo que dice entre la entrada plena y sus remisiones,
-- y tres de estas cuatro afirmaciones recogen algo de cada sitio sin declararlo.
--
--   e69543b4  Copla manriqueña  «copla de pie quebrado» y «copla mixta»
--                             → «copla de Jorge Manrique», p. 90, y «copla mixta», p. 91
--             Hoja 92: «copla de Jorge Manrique. Copla de pie quebrado en la que se combinan dos
--             grupos de tres versos…», y debajo «copla manriqueña. copla de Jorge Manrique.»: la
--             manriqueña es una remisión pura. Hoja 93: «copla mixta (Navarro Tomás). …dividida
--             en dos semiestrofas de distinta extensión o en dos sextillas», que es la cita
--             literal de nuestra ficha.
--   4886c9d5  Endecha real      «endecha real», p. 150
--                             → «endecha real», p. 150, y «cuarteto de endecha», p. 98
--             La página estaba bien. Lo que faltaba es que **la atribución a Navarro Tomás no
--             está en esa entrada**: está en la de remisión «cuarteto de endecha (Navarro Tomás).
--             endecha real.», bajo la letra C, sesenta páginas antes.
--   087b9c6b  Sextilla · Hexasílaba  «lay», p. 148 → «lay», p. 215
--             La entrada es la correcta y la página no: la 148 es «endecha». El lay está en la
--             215 (hoja 217), y dice casi palabra por palabra lo que la ficha recoge.
--
-- **Jauralde Pou 2020.** Epub sin paginar: se cita el epígrafe. Y aquí el vicio tiene una forma
-- reconocible: **se citan como epígrafes frases que solo son el arranque de un apartado**. Ninguno
-- de los cuatro títulos que se corrigen existe como encabezado en el libro; los nuevos se han
-- comprobado uno a uno buscándolos como línea de encabezado, no como texto del cuerpo.
--
--   880f3d66  Pareado   «Estrofas de dos versos»  → «Estrofas de pareados»
--   8b5581b0  Oncena    «Oncena»                  → «Estrofas de once versos»
--   90ca3952  Septilla  «Copla mixta» y «Octavillas y octavas»
--                     → «Estrofas de ocho versos» y «Septillas octosilábicas»
--
-- Un detalle del volcado que conviene dejar escrito: los encabezados de este epub salen con la
-- primera letra separada —«E STROFAS DE ONCE VERSOS»—. Es un artefacto de la extracción, no el
-- título del libro, así que el localizador escribe el título de verdad.
--
-- La guarda comprueba el texto de las seis antes y después, porque esta migración promete no
-- cambiar ni una letra de lo que dicen.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['e69543b4-a3ed-4019-a1f4-274520660254',
			's. v. «copla de pie quebrado» y «copla mixta»',
			'Entradas «copla de Jorge Manrique», p. 90, y «copla mixta», p. 91'],
		array['4886c9d5-c5d3-44a5-8196-0c137a0a14ae',
			's. v. «endecha real», p. 150',
			'Entradas «endecha real», p. 150, y «cuarteto de endecha», p. 98'],
		array['087b9c6b-fb20-43f6-858c-a32c18abed81',
			'Entrada «lay», p. 148',
			'Entrada «lay», p. 215'],
		array['880f3d66-cff1-47db-a295-d4ba805ec398',
			'«Estrofas de dos versos»',
			'Apartado «Estrofas de pareados»'],
		array['8b5581b0-baff-46fd-b102-6c37cc4b6981',
			'Apartado «Oncena»',
			'Apartado «Estrofas de once versos»'],
		array['90ca3952-0438-4d24-80ff-70821855ffb3',
			'Apartados «Copla mixta» y «Octavillas y octavas»',
			'Apartados «Estrofas de ocho versos» y «Septillas octosilábicas»']
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

	-- Con esto se acaba «Octavillas y octavas» en Jauralde: era la frase con que arranca el
	-- apartado de las estrofas de ocho versos, y se había copiado a cuatro fichas.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2020 and a.localizador like '%Octavillas y octavas%';
	if v_cuantas <> 1 then
		raise exception 'Esperaba que quedara 1 afirmación con «Octavillas y octavas» —la octava aguda, que pide reescritura— y quedan %.', v_cuantas;
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
