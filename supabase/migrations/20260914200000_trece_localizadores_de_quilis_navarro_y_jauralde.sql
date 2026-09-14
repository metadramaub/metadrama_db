-- Trece localizadores de Quilis, Navarro Tomás y Jauralde llevan ya al pasaje
--
-- Resueltos con la **pasada C**, la localización ciega, sobre veinticuatro afirmaciones cuyo
-- localizador estaba en duda. Y comprobados después uno a uno abriendo el PDF —o el volcado, en
-- Jauralde, que viene de un epub sin paginar— porque **la tercera pasada tampoco es de fiar por sí
-- sola**: en Quilis dio mal tres de las cuatro páginas.
--
-- Eso es lo que estas trece correcciones enseñan de método, y conviene dejarlo escrito: ninguna de
-- las tres pasadas acierta siempre, y ninguna se equivoca siempre. La endecha real de Quilis está
-- en la p. 162: el catálogo decía 163, la pasada C dijo 161 y **la que acertó fue la B**, que se
-- había equivocado en tres de cuatro el día anterior en otro libro. Las pasadas señalan dónde
-- mirar; quien decide es quien abre la hoja y lee el número impreso al pie.
--
-- **Quilis 1969.** Este PDF escaneó pliegos dobles, dos páginas por hoja, así que cada hoja trae
-- el contenido de la página izquierda, su pie, el de la derecha y el suyo. Leer el § y quedarse
-- con el primer número que aparece da sistemáticamente la página anterior.
--
--   75d992b5  Endecha real         § 6.4.1, p. 163      → § 6.4.1, p. 162
--             Hoja 82: «Cuando el romance tiene menos de ocho sílabas recibe los nombres de:
--             a) endecha, si los versos constan de siete sílabas…» va antes del pie «162».
--   1c9b7d26  Sextina              § 6.3.4, pp. 167-168 → § 6.3.4, pp. 129-130
--             Hoja 65: «6.3.4. La sextina» con Arnaut Daniel, entre los pies «128» y «129».
--   089f66ae  Copla de arte mayor  § 5.4.7.1            → § 5.4.7.1, p. 106
--   44ce6251  Redondilla           p. 94                → § 5.4.3.2, p. 95
--             **Esta iba a confirmarse sin cambio y también estaba mal.** En la hoja 48, el
--             § 5.4.3.1 «Cuarteto» va antes del pie «94» y el § 5.4.3.2 «Redondilla» después: la
--             redondilla está en la 95. Se le añade además el § , que es como se cita esta fuente.
--
-- **Navarro Tomás 1972.** Aquí los localizadores no estaban mal, estaban **incompletos**: la
-- afirmación recoge una cláusula de un § que no declaraba.
--
--   eccebfab  Septilla enlazada    § 131                → §§ 131 y 154
--   412ad16e  Sextilla enlazada    § 131                → §§ 131 y 154
--             Las dos cierran con «el teatro dio preferencia a las estrofas octosílabas enlazadas
--             de seis y siete versos», que es del § 154 «Resumen», no del 131.
--   e7c94f87  Sextilla             §§ 22, 38, 63 y 308  → §§ 22, 38, 63, 69 y 308
--             «Establece cuatro sílabas como medida general del quebrado del octosílabo…» es el
--             § 69 «Regla del pie quebrado», que no se citaba. Es el mismo § que ya estaba
--             anotado como huérfano para la fase de exhaustividad.
--
-- **Jauralde Pou 2020.** Epub sin paginar: aquí se cita el epígrafe, y **casi ninguno de los
-- citados existía**. Los títulos reales se han leído en el volcado como líneas de encabezado.
--
--   de48e693  Copla de arte menor  «Octavillas y octavas» → «Estrofas de ocho versos»
--   a691813f  Copla castellana     «Octavillas y octavas» → «Estrofas de ocho versos» y «Madrigal»
--             «Octavillas y octavas» no es un epígrafe: es la frase con que arranca el de las
--             estrofas de ocho versos, y el error se copió a cuatro fichas. Aquí se arreglan dos;
--             la octava aguda y la septilla esperan su localización ciega. La copla castellana
--             vuelve además en «Madrigal», a propósito del epigrama.
--   b436934c  Copla manriqueña     «Coplas de pie quebrado» → «Formas mixtas»
--   4c90a1f0  Canción petrarquista «Canción petrarquista» y «Estancias» → «Canción» y «Estancias»
--             El epígrafe se titula «Canción» a secas; «canción petrarquista» es una expresión del
--             cuerpo del texto que se tomó por un título.
--   f1a44360  Endecha real · heptasílaba  «§ 3.6, Cuartetas de heptasílabos» → «Cuartetos mixtos»
--   d4bf348a  Endecha real · hexasílaba   «§ 3.6, Cuartetas de heptasílabos» → «Cuartetos mixtos»
--             «Cuartetas de heptasílabos» sí existe, pero trata las cuartetas puras y no menciona
--             la endecha real. Y «§ 3.6» no es nada: Jauralde no numera secciones.
--
-- No se toca una palabra de prosa, y la guarda lo comprueba comparando el texto de las trece antes
-- y después.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['75d992b5-0272-4fa1-b1e2-29ed7d5da1a0', '§ 6.4.1, p. 163', '§ 6.4.1, p. 162'],
		array['1c9b7d26-c0fc-4d7a-bc4f-e3430c53b954', '§ 6.3.4, pp. 167-168', '§ 6.3.4, pp. 129-130'],
		array['089f66ae-33fa-4cfb-9bb2-28352fe7d807', '§ 5.4.7.1', '§ 5.4.7.1, p. 106'],
		array['44ce6251-0dd2-4227-afa9-93f71b2f177c', 'p. 94', '§ 5.4.3.2, p. 95'],
		array['eccebfab-9412-48ef-9268-ec2f58b57b4e', '§ 131', '§§ 131 y 154'],
		array['412ad16e-be41-444f-a34d-082c65deb5b4', '§ 131', '§§ 131 y 154'],
		array['e7c94f87-3a9e-4da8-b97c-5b8d906cf351', '§§ 22, 38, 63 y 308', '§§ 22, 38, 63, 69 y 308'],
		array['de48e693-40e9-4bd2-930f-4c6579362b3c', 'Apartado «Octavillas y octavas»', 'Apartado «Estrofas de ocho versos»'],
		array['a691813f-d06f-4e1a-8f93-f6c381e44b13', 'Apartado «Octavillas y octavas»', 'Apartados «Estrofas de ocho versos» y «Madrigal»'],
		array['b436934c-b817-49c7-9008-aac56fb54b00', 'Apartado «Coplas de pie quebrado»', 'Apartado «Formas mixtas»'],
		array['4c90a1f0-f814-43ec-89c2-3c6dfef0b0fc', 'Apartados «Canción petrarquista» y «Estancias»', 'Apartados «Canción» y «Estancias»'],
		array['f1a44360-8acf-4af5-adf0-b8779f159d7d', '§ 3.6, «Cuartetas de heptasílabos»', 'Apartado «Cuartetos mixtos»'],
		array['d4bf348a-e678-44eb-8d5a-64e66d608b6c', '§ 3.6, «Cuartetas de heptasílabos»', 'Apartado «Cuartetos mixtos»']
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

	-- Ya no debe quedar ninguna afirmación de Jauralde citando «§ 3.6», que no es nada en un libro
	-- sin secciones numeradas. Con «Octavillas y octavas» **quedan dos**, la octava aguda y la
	-- septilla, que todavía no han pasado por la localización ciega: se corrigen cuando la tengan,
	-- y decir aquí que son dos es la manera de que este recuento signifique algo. La primera
	-- versión de esta guarda exigía cero y tumbó la migración, que es exactamente lo que tenía que
	-- hacer.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2020 and a.localizador like '%§ 3.6%';
	if v_cuantas <> 0 then
		raise exception 'Quedan % afirmaciones de Jauralde citando «§ 3.6».', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2020 and a.localizador like '%Octavillas y octavas%';
	if v_cuantas <> 2 then
		raise exception 'Esperaba que quedaran 2 afirmaciones con «Octavillas y octavas» y quedan %.', v_cuantas;
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
