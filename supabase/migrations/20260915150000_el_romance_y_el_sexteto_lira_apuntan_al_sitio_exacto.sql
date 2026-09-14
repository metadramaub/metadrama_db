-- El romance y el sexteto-lira apuntan ya al sitio exacto
--
-- Dos localizadores, sin tocar prosa. Los dos vienen de haber acusado antes a la ficha de decir
-- algo falso cuando lo que decía era verdad, así que conviene dejar escrito por qué.
--
-- **`008e03ef` · Romance · Diccionario 2016.** La ficha dice que romancillo es el romance de menos
-- de ocho sílabas «lo que cubre por igual el hexasílabo y el heptasílabo», y la localización ciega
-- la dio por no documentada: en la entrada «romancillo» solo aparece nombrado el hexasílabo. Pero
-- **el localizador ya declaraba también la entrada «endecha»**, y es ahí donde está lo otro: «Poema
-- de asunto triste cuya forma métrica es la de **un romancillo de versos de siete sílabas**
-- generalmente…» (p. 148, hoja 150). El verificador buscó dentro de una sola de las tres entradas
-- declaradas. Lo único que fallaba era una página: «romance heroico» está en la **369**, no en la
-- 368 —hoja 371, pie impreso «369»—, y las otras dos, 370 y 148, estaban bien.
--
-- **`4751f45b` · Sexteto-lira · Jauralde.** Dos pasadas señalaron que fray Luis de León y la
-- *Llama de amor viva* no aparecen en ninguno de los dos apartados citados, y estuvo a punto de
-- tratarse como invención. No lo es: el libro dice, en el capítulo de la lira de cinco versos,
-- que «muy pronto prefirieron las variedades del **sexteto-lira (que ya está en las traducciones
-- luisianas o en *Llama de amor viva*, de san Juan de la Cruz)**». La ficha decía la verdad; lo que
-- le faltaba era declarar el tercer sitio. Se añade «Quinteto-lira», que es el epígrafe bajo el
-- que cae ese pasaje.
--
-- La lección, por si sirve más adelante: **que una pasada no encuentre algo dentro del epígrafe
-- que espera no significa que no esté**, y menos cuando el propio localizador nombra más de un
-- sitio.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['008e03ef-8c25-4d9f-8a72-19134e8e08dd',
			'Entradas «romancillo» (p. 370), «endecha» (p. 148) y «romance heroico» (p. 368)',
			'Entradas «romancillo» (p. 370), «endecha» (p. 148) y «romance heroico» (p. 369)'],
		array['4751f45b-a4ec-420f-a29a-7bce53befa45',
			'Apartados «Variedades de la lira, el sexteto-lira» y «Estrofas de seis versos»',
			'Apartados «Variedades de la lira, el sexteto-lira», «Estrofas de seis versos» y «Quinteto-lira»']
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
