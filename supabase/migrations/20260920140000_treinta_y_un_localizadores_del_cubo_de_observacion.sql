-- Treinta y un localizadores del cubo de observación, y cuatro de ellos estaban mal
--
-- Tercera y última tanda. **Ninguna palabra de prosa se toca**, y una guarda lo exige.
--
-- La pasada C —localización ciega, que no ve el localizador del catálogo y busca el pasaje por su
-- cuenta— recorrió las cincuenta afirmaciones de este cubo. Veintisiete solo ganan la página o el §
-- que les faltaba. **Cuatro estaban equivocadas:**
--
--   `588025c8`  decía «§ 57 y repertorio final». El caso de Tirso de Molina no está en el § 57 sino
--               en el **§ 199**, ciento cincuenta páginas más allá, en otro período del libro.
--   `c5992665`  decía «§ 131». La frase sobre el teatro está en el **§ 154**. La ficha ya avisaba
--               con «en su recorrido del período», así que el texto era honesto y el localizador no.
--   `62e8c279`  citaba «§§ 66 y 128». Del § 128 no se toma nada: sale.
--   `95628176`  citaba «pp. 198-199», pero el contraste con la sextilla que la ficha declara vive
--               en la **p. 197**, fuera del rango.
--
-- ══ Dos decisiones
--
-- **`ec3f5532` va a «pp. 307-308» y no a la 307**, que es lo que proponía la C: los dos terrenos que
-- el texto nuevo añade —poemas mitológicos, poesías festivas— están ya en la página siguiente. Era
-- justo el salto de página que hacía parecer que la enumeración se cerraba en Andrés Bello.
--
-- **No se sigue a la C en los tres silencios de Morley y Bruerton.** Propone recortar
-- `Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39` a solo el epígrafe, y eso perdería
-- el rango del capítulo entero, que es **lo que sostiene el silencio**: sin él la ficha dice dónde
-- está lo que sí hay, pero no que se haya mirado todo lo demás.
--
-- ══ Las páginas de Navarro Tomás
--
-- Trece, leídas hoja a hoja en el PDF. El desfase entre la hoja y la página impresa **se movió de
-- −6 a −8 dentro del mismo lote**, que es la razón por la que el plan marcaba esta paginación como
-- lo primero que había que probar y por la que ningún número sale aquí del volcado.
--
-- ══ Y una uniformidad
--
-- En el *Diccionario*, `a6d9d28c` y `51476304` pasan de «s. v.» a «Entrada», que es la forma que
-- usan 53 de sus 63 fichas. De `51476304` caen además «septeto-estancia» y «lira»: **no son entradas
-- aparte**, sino el bloque OTROS TÉRMINOS de la propia entrada y su remisión interna «V. lira, 2».
--
-- Quedan fuera de este cubo ocho fichas del *Diccionario* con «s. v.» y quince sin página; se
-- anotan para la pasada de consistencia.
--
-- Aprobados por David el 20 de septiembre de 2026.

begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 31;
	v_antes bigint;
	v_despues bigint;
	v_otro_antes text;
	v_otro_despues text;
begin
	create temporary table cambios_localizadores (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_localizadores (id8, antes, despues)
	values
		('d3241dd6', '§ 108', '§ 108, pp. 205-206'),
		('588025c8', '§ 57 y repertorio final', '§§ 57 y 199, pp. 122-123 y 278, y repertorio final, p. 532'),
		('266ebff2', '§ 64', '§ 64, p. 128'),
		('62e8c279', '§§ 66 y 128', '§ 66, pp. 131-132'),
		('886b9735', '§ 118', '§ 118, pp. 211-212'),
		('ec3f5532', '§ 226', '§ 226, pp. 307-308'),
		('d3328f68', '§ 229, «Estrofas aliradas»', '§ 229, «Estrofas aliradas», p. 309'),
		('142db9f5', '§ 62', '§ 62, p. 127'),
		('ce47ab90', '§ 154, «Resumen» del período renacentista', '§§ 131 y 154, pp. 221 y 247'),
		('c5992665', '§ 131', '§§ 131 y 154, pp. 220 y 247'),
		('22c63f36', '§§ 216, 450 y 498; repertorio final', '§§ 96, 216, 221, 450 y 498, pp. 177-181, 292-293, 303, 459 y 495, y repertorio final, p. 539'),
		('b1ac8dc3', '§§ 115 y 167', '§§ 115 y 167, pp. 210 y 259'),
		('a1e0457a', '§ 158', '§ 158, pp. 254-255'),
		('a6d9d28c', 's. v. «copla castellana»', 'Entrada «copla castellana», pp. 88-89'),
		('e034cf96', 'Entrada «copla de arte mayor»', 'Entrada «copla de arte mayor», p. 86'),
		('d06da334', 'Entrada «copla real»', 'Entrada «copla real», pp. 92-93'),
		('708ebd3f', 'Entrada «seguidilla gitana»', 'Entrada «seguidilla gitana», pp. 377-378'),
		('51476304', 's. v. «septeto alirado», «septeto-estancia» y «lira»', 'Entrada «septeto alirado», pp. 381-382'),
		('9df9b891', 'Entradas «sextilla» y sus variedades', 'Entradas «sextilla», «sextilla alterna», «sextilla correlativa», «sextilla paralela» y «sextilla de pie quebrado», pp. 389-391'),
		('aa1914ec', 'Entrada «verso único»', 'Entrada «verso único», pp. 492-493'),
		('b32dd1f7', 'Entrada «verso suelto»', 'Entrada «verso suelto», p. 492'),
		('14578fe2', '§ 6.4.3', '§ 6.4.3, p. 167'),
		('f3015660', '§ 5.4.6.1', '§ 5.4.6.1, p. 105'),
		('1d255c25', '§ 5.4.5', '§§ 5.4.5 a 5.4.5.4, pp. 101-103'),
		('8ef78bc8', 'p. 164', '§ 6.4.2, p. 164'),
		('5fc24618', 'pp. 92-93', '§ 5.4.2.1, p. 92'),
		('71d1e7df', '§ 6.3.2', '§ 6.3.2, pp. 125 y 127'),
		('e66e30cc', 'pp. 214-216', '§ 11.1.2, pp. 214-215'),
		('3fd5381e', 'p. 185', '§ 10.2.2, p. 185'),
		('95628176', 'pp. 198-199', '§ 10.2.5, pp. 197-199'),
		('96a4a4bd', 'Cap. V, epígrafes «Canción (Canzone)», p. 40, y «Canción sin rima», p. 41', 'Cap. V, epígrafes «Canción (Canzone)», pp. 40-41, y «Canción sin rima», p. 41');

	-- Que cada afirmación existe y tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % afirmaciones tienen el texto que esta migración espera; no toco ninguna.',
			v_n, v_esperadas;
	end if;

	-- Y que ninguna tiene ya el texto nuevo, que significaría que esto se aplicó por otra vía.
	select count(*) into v_n
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.despues;
	if v_n <> 0 then
		raise exception '% afirmaciones tienen ya el texto nuevo.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	select string_agg(a.resumen, '|' order by a.afirmacion_id) into v_otro_antes
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8;

	update public.afirmaciones_fuentes_metricas a
	set localizador = c.despues
	from cambios_localizadores c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las 31 quedaron con el texto nuevo, releído de la tabla.
	select count(*) into v_n
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	-- Que ninguna conserva el viejo.
	select count(*) into v_n
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;
	if v_n <> 0 then
		raise exception '% se quedaron con el texto viejo.', v_n;
	end if;

	select string_agg(a.resumen, '|' order by a.afirmacion_id) into v_otro_despues
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8;
	if v_otro_despues is distinct from v_otro_antes then
		raise exception 'Cambió alguna prosa y esta migración solo mueve localizadores.';
	end if;

	select count(*) into v_n
	from cambios_localizadores c
	join public.afirmaciones_fuentes_metricas a on left(a.afirmacion_id::text, 8) = c.id8
	where a.localizador !~ 'pp?[.] [0-9]';
	if v_n <> 0 then
		raise exception '% localizadores siguen sin página.', v_n;
	end if;


	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
