-- Veintidós localizadores ganan la página que la pasada C leyó
--
-- La localización ciega no solo refuta: **de las cincuenta y siete del cubo de confirmación,
-- cuarenta y cuatro estaban bien localizadas**, y al confirmarlas dejó la página impresa que el
-- catálogo no tenía. Estas veintidós la ganan. No se toca una palabra de prosa, y una guarda lo
-- exige.
--
-- **Las siete de Navarro Tomás son lo más valioso.** El plan de la auditoría marcaba su paginación
-- como «lo primero que hay que probar», porque el volcado conserva treinta y siete números en
-- quinientas setenta y tres páginas y el desfase entre hoja y página impresa **no es constante**:
-- crece de +5 a +8 a lo largo del libro. Cada una de estas páginas se leyó abriendo la hoja del PDF
-- y mirando el número impreso.
--
-- Dos cambian además de forma, no solo de precisión:
--
--   9e0a5051  Terceto · Caparrós 2014 citaba el apartado «Combinaciones estróficas castellanas»,
--             que es un capítulo entero de treinta páginas. Esta fuente se cita por página, y es la
--             187.
--   b3cc8411  Sextilla hexasílaba · Navarro. Sus tres disposiciones están en cuatro sitios
--             distintos, y el localizador nombraba dos. La formulación literal de la alterna solo
--             está en el «Resumen» del § 30; el lay solo se define en el «Índice de estrofas».
--
-- Y uno pierde una entrada: **`095ef92a`, la octava aguda del *Diccionario*, citaba tres voces y el
-- contenido está en dos**, «octava aguda» y «octavilla aguda». La tercera, «octavilla», no aporta
-- nada que no esté en esas.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['e45bdc99', '§ 6.3.6', '§ 6.3.6, pp. 142-143'],
		array['6cab6e9a', '§§ 5.4.3.3 y 5.4.6.2', '§§ 5.4.3.3, pp. 96-97, y 5.4.6.2, p. 105'],
		array['17f41e6d', '§ 5.4.6.1', '§ 5.4.6.1, p. 105'],
		array['669606fe', '§ 5.4.5.4', '§ 5.4.5.4, pp. 103-104'],
		array['96d366f5', '§ 5.4.5.4', '§ 5.4.5.4, pp. 103-104'],
		array['17b8a51f', '§ 68, nota 18', '§ 68, nota 18, p. 134'],
		array['2c90f723', '§ 216', '§ 216, p. 292'],
		array['738e37aa', '§ 216', '§ 216, p. 293'],
		array['cfb377cd', '§§ 161, 162 y 229', '§§ 161 y 162, pp. 256-257, y § 229, p. 309'],
		array['6b347966', '§ 67', '§ 67, p. 132'],
		array['6ac2be86', '§§ 110, 161 y 229', '§§ 110, p. 207; 161, p. 256; y 229, p. 309'],
		array['9e0a5051', 'Apartado «Combinaciones estróficas castellanas»', 'p. 187'],
		array['095ef92a', 's. v. «octava aguda», «octavilla aguda» y «octavilla»', 'Entradas «octava aguda», pp. 242-243, y «octavilla aguda», p. 248'],
		array['a5a6805b', 's. v. «octava alirada»', 'Entrada «octava alirada», p. 243'],
		array['4e0d8da8', 's. v. «undécima» y «oncena»', 'Entradas «undécima», p. 444, y «oncena», p. 253'],
		array['8c5f0a5b', 'Entrada «seguidilla»', 'Entrada «seguidilla», pp. 375-376'],
		array['7fd372ca', 'Entradas «seguidilla» y sus variedades', 'Entradas «seguidilla», «seguidilla compuesta», «seguidilla chamberga», «seguidilla gitana», «seguidilla real» y «seguidilla simple arromanzada», pp. 375-378'],
		array['bf1583ba', 'Entradas «bordón» y «seguidilla compuesta»', 'Entradas «bordón», pp. 56-57, y «seguidilla compuesta», pp. 376-377'],
		array['484e23f9', 's. v. «tercetillo», «tercerilla» y «tercerillo»', 'Entradas «tercetillo», «tercerilla» y «tercerillo», p. 427'],
		array['35e489c0', 'Entrada «versificación irregular»', 'Entrada «versificación irregular», p. 453'],
		array['5e28fc29', 'Entrada «zéjel»', 'Entrada «zéjel», pp. 500-501'],
		array['b3cc8411', '§ 30, § 245 y glosario, s. v. «Lay»', '§§ 22, p. 68, y 30, p. 79; § 245, nota 14, p. 317; § 86, p. 162, e «Índice de estrofas», p. 536']
	];
	v_fila text[];
	v_tocadas text[] := '{}';
	v_cuantas integer;
	v_puestos integer := 0;
	v_prosa_antes text;
	v_prosa_despues text;
	v_antes bigint;
	v_despues bigint;
begin
	foreach v_fila slice 1 in array v_cambios loop
		v_tocadas := v_tocadas || v_fila[1];
	end loop;

	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_antes
	from public.afirmaciones_fuentes_metricas where left(afirmacion_id::text, 8) = any(v_tocadas);

	select revision into v_antes from public.catalogo_metrico_estado where id;

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[2];
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				v_fila[1], v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3] where left(afirmacion_id::text, 8) = v_fila[1];
	end loop;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Que las siete de Navarro Tomás llevan ya página, que era el punto débil declarado del plan.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1972 and left(a.afirmacion_id::text, 8) = any(v_tocadas)
		and a.localizador ~ 'pp?[.] [0-9]';
	if v_cuantas <> 7 then
		raise exception 'Solo % de las siete de Navarro llevan página.', v_cuantas;
	end if;

	-- Y que no se ha tocado una palabra de prosa: esto movía localizadores.
	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_despues
	from public.afirmaciones_fuentes_metricas where left(afirmacion_id::text, 8) = any(v_tocadas);
	if v_prosa_despues is distinct from v_prosa_antes then
		raise exception 'Ha cambiado la prosa de alguna afirmación, y esta migración no la tocaba.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
