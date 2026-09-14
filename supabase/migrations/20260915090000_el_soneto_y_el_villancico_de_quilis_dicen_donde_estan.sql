-- El soneto y el villancico de Quilis dicen ya dónde están, que es en dos sitios cada uno
--
-- Las dos afirmaciones estaban **incompletas**, no equivocadas: su localizador cubría la primera
-- mitad de lo que dicen y callaba de dónde sale la segunda. Es el defecto que solo aparece cuando
-- se busca cada aserción por separado, que es lo que hace la pasada C.
--
--   a0b8fde4  Soneto      p. 132   → § 6.3.5, pp. 132-133
--             La definición, el esquema ABBA-ABBA-CDC-DCD y la preferencia de Petrarca están en la
--             p. 132; «En el Barroco alcanza el soneto su mayor auge y esplendor» está en la 133.
--             En la hoja 67 del PDF las dos páginas van seguidas: la frase del Barroco cae por
--             debajo del pie «132» y por encima del «133».
--   1bb37fb5  Villancico  § 6.3.1  → §§ 6.3.1, p. 121, y 6.3.2, p. 127
--             La definición y la estructura son del § 6.3.1, p. 121. Pero la comparación con el
--             zéjel —«El zéjel y el villancico se diferencian fundamentalmente por la forma de la
--             mudanza: en el villancico es una redondilla, y en el zéjel es un trístico»— **cierra
--             el § 6.3.2, el del zéjel**, en la p. 127, justo antes de que arranque «6.3.3. La
--             glosa». La afirmación la recogía sin decir de dónde venía.
--
-- Las dos las localizaron igual la pasada A y la C, y se han comprobado abriendo las hojas 61, 64
-- y 67 del PDF. Este libro se escaneó en pliegos dobles, dos páginas impresas por hoja, así que el
-- número al pie solo dice de qué página es lo que va **por encima** de él.
--
-- Se añade además el § al soneto, que se citaba solo por página, porque esta fuente se cita por §
-- y por página.
--
-- No se toca una palabra de prosa.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['a0b8fde4-a70e-4945-857a-a9c477e2630a', 'p. 132', '§ 6.3.5, pp. 132-133'],
		array['1bb37fb5-4877-4af9-85c4-41679421f118', '§ 6.3.1', '§§ 6.3.1, p. 121, y 6.3.2, p. 127']
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
