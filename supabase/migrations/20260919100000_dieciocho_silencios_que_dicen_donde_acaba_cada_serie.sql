-- Dieciocho silencios que ahora se leen como lo que son
--
-- **Una fuente que calla no deja hueco en la ficha.** La sección enseña seis voces, y donde una no
-- aparece el lector no puede distinguir «esta fuente no lo dice» de «esto no lo hemos mirado». La
-- regla de exhaustividad pide registrar el silencio igual que la palabra, y la fase 4 dejó
-- veintidós celdas por escribir. Estas son dieciocho; las cuatro de la sextina van aparte.
--
-- ══ Y al justificarlos apareció algo que no se buscaba
--
-- Trece de los dieciocho son de la serie alirada, y la primera redacción decía de todos lo mismo:
-- «no la registra». **Es falso por omisión.** Ninguna de las cinco calla por olvido: **cada una deja
-- de enumerar estrofas aliradas en el punto exacto en que empieza a llamarlas canción**, y dos lo
-- dicen con todas las letras.
--
--   Morley y Bruerton  «Todas las liras no son más que formas especializadas de la *canzone*», y su
--                      canción son «estrofas de 5 a 20 versos»: las dos series se solapan enteras.
--   Quilis             Lira y sexteto-lira, y de ahí en adelante su canción, «normalmente entre
--                      seis y doce» versos.
--   Caparrós 2014      Cuarteto, sexteto y septeto lira; su estancia empieza en «no menos de nueve».
--   *Diccionario*      Acota la canción alirada «entre los cuatro y ocho versos» y la estancia en
--                      «no menos de nueve»: **encajan sin hueco ni solapamiento**.
--   Jauralde           Hasta el octeto-lira, y define la estancia «por encima de los ocho versos
--                      **(para diferenciarla de las liras)**».
--
-- De modo que cada afirmación dice dónde acaba la serie de esa fuente y por qué, en su propia voz.
-- Solo el primer grupo —cuatro celdas de Morley y Bruerton— es puramente negativo, y ahí la razón
-- también es suya: su repertorio no es el de la métrica española sino el de las formas que Lope usa.
--
-- El hallazgo está recogido para el IP en `cuestiones-para-el-ip.md`, «Canción petrarquista» 6: dos
-- fuentes ponen la juntura de las dos series en el mismo sitio, el 8/9, que es justo donde Navarro
-- mete una alirada de nueve versos.
--
-- Textos aprobados por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_loc_A constant text := 'Capítulo «Definición de las Formas Métricas»';
	v_res_A constant text :=
		'No la registra. Su repertorio no es el de la métrica española sino el de las formas que Lope '
		'usa en sus comedias, y lo componen veintiuna entradas entre las que esta no figura.';
	v_loc_B constant text := 'Capítulo «Definición de las Formas Métricas», epígrafes «Liras» y «Canción (Canzone)»';
	v_res_B constant text :=
		'No la registra por separado. Su entrada «Liras» describe la de seis versos y anota que «el '
		'nombre de lira también se aplica a una estrofa de 5 versos», sin enumerar otras extensiones, '
		'porque para ellos la cuestión no se plantea: «todas las liras no son más que formas '
		'especializadas de la *canzone*». Su canción, en efecto, son «versos de siete y once sílabas, '
		'agrupados en estrofas de 5 a 20 versos».';
	v_loc_C constant text := '§§ 5.4.4.3, 5.4.5.2 y 6.3.6';
	v_res_C constant text :=
		'No la registra. De la serie alirada trata solo dos extensiones, con epígrafe propio cada una: '
		'la lira de cinco versos, § 5.4.4.3, y el sexteto-lira, § 5.4.5.2. Lo que pasa de ahí queda en '
		'su canción, cuyas estrofas «normalmente oscilaban entre seis y doce» versos.';
	v_loc_D constant text := 'pp. 190, 199-200 y 214';
	v_res_D constant text :=
		'No la registra. Nombra tres extensiones de la serie alirada —el cuarteto lira, el sexteto lira '
		'y el septeto lira— y no pasa de ahí: su estancia empieza en «no menos de nueve» versos.';
	v_loc_E constant text := 'Entradas «canción alirada», p. 60, y «estancia», p. 163';
	v_res_E constant text :=
		'No la registra, y dice por qué: acota la canción alirada como aquella cuya unidad estrófica '
		'«oscila entre los cuatro y ocho versos», y enumera las cinco que la componen —cuarteto-lira, '
		'lira garcilasiana, sexteto-lira, septeto alirado y octava alirada—. Una estrofa de nueve queda '
		'fuera de esa horquilla, y en la suya entra la estancia, que define como de «no menos de nueve '
		'ni más de veinte» versos.';
	v_loc_F constant text := 'Apartados «Cuartetos mixtos», «Formas mixtas» y «Estancias»';
	v_res_F constant text :=
		'No la registra. Enumera la serie alirada desde el cuarteto hasta el octeto-lira y se detiene '
		'ahí, porque a partir de esa extensión la llama de otra manera: define la estancia como estrofa '
		'de siete y once sílabas dispuestos de modo aleatorio, «normalmente por encima de los ocho '
		'versos (para diferenciarla de las liras)».';
	v_n integer;
	v_esperadas constant integer := 18;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table silencios_tanda (
		forma_slug text not null,
		anio integer not null,
		localizador text not null,
		resumen text not null
	) on commit drop;

	insert into silencios_tanda (forma_slug, anio, localizador, resumen)
	values
		('endecha_real', 1968, v_loc_A, v_res_A),
		('estrofa_safica', 1968, v_loc_A, v_res_A),
		('octava_aguda', 1968, v_loc_A, v_res_A),
		('verso_aislado', 1968, v_loc_A, v_res_A),
		('cuarteto_lira', 1968, v_loc_B, v_res_B),
		('octava_lira', 1968, v_loc_B, v_res_B),
		('novena_lira', 1968, v_loc_B, v_res_B),
		('decima_lira', 1968, v_loc_B, v_res_B),
		('cuarteto_lira', 1969, v_loc_C, v_res_C),
		('octava_lira', 1969, v_loc_C, v_res_C),
		('novena_lira', 1969, v_loc_C, v_res_C),
		('decima_lira', 1969, v_loc_C, v_res_C),
		('octava_lira', 2014, v_loc_D, v_res_D),
		('novena_lira', 2014, v_loc_D, v_res_D),
		('decima_lira', 2014, v_loc_D, v_res_D),
		('novena_lira', 2016, v_loc_E, v_res_E),
		('novena_lira', 2020, v_loc_F, v_res_F),
		('decima_lira', 2020, v_loc_F, v_res_F);

	-- Que las 18 formas y las seis fuentes existen, y que las celdas están hoy vacías.
	select count(*) into v_n
	from silencios_tanda t
	join public.formas_metricas f on f.slug = t.forma_slug and f.activo
	join public.fuentes_metricas fu on fu.anio = t.anio;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % celdas resuelven forma y fuente.', v_n, v_esperadas;
	end if;

	select count(*) into v_n
	from silencios_tanda t
	join public.formas_metricas f on f.slug = t.forma_slug
	join public.fuentes_metricas fu on fu.anio = t.anio
	join public.afirmaciones_fuentes_metricas a on a.fuente_id = fu.fuente_id
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = f.forma_id;
	if v_n <> 0 then
		raise exception '% de las celdas tienen ya afirmación; ninguna debía tenerla.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	select fu.fuente_id, f.forma_id, t.localizador, t.resumen, 'alta'
	from silencios_tanda t
	join public.formas_metricas f on f.slug = t.forma_slug
	join public.fuentes_metricas fu on fu.anio = t.anio;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que entraron las dieciocho, cada una con su texto.
	select count(*) into v_n
	from silencios_tanda t
	join public.formas_metricas f on f.slug = t.forma_slug
	join public.fuentes_metricas fu on fu.anio = t.anio
	join public.afirmaciones_fuentes_metricas a
		on a.forma_id = f.forma_id and a.fuente_id = fu.fuente_id
		and a.localizador = t.localizador and a.resumen = t.resumen;
	if v_n <> v_esperadas then
		raise exception 'Entraron % de % silencios.', v_n, v_esperadas;
	end if;

	-- Que ninguno dice solo «no la registra»: todos menos los de Morley y Bruerton puramente
	-- negativos explican dónde acaba la serie de su fuente, y eso se comprueba pidiendo que citen.
	select count(*) into v_n
	from silencios_tanda t
	where t.resumen not like '%canzone%'
		and t.resumen not like '%seis y doce%'
		and t.resumen not like '%no menos de nueve%'
		and t.resumen not like '%por encima de los ocho%'
		and t.resumen not like '%veintiuna entradas%';
	if v_n <> 0 then
		raise exception '% silencios no dicen en qué se apoyan.', v_n;
	end if;

	-- Que las cuatro liras hablan ya con las seis fuentes, que es lo que cierra la serie.
	select count(*) into v_n
	from public.formas_metricas f
	where f.slug in ('cuarteto_lira', 'octava_lira', 'novena_lira', 'decima_lira')
		and (
			select count(distinct a.fuente_id)
			from public.afirmaciones_fuentes_metricas a
			left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
			where coalesce(a.forma_id, ar.forma_id) = f.forma_id
		) = 6;
	if v_n <> 4 then
		raise exception 'Solo % de las cuatro liras hablan con las seis fuentes.', v_n;
	end if;

	-- Y que la octava aguda, la endecha real, la sáfica y el verso aislado también.
	select count(*) into v_n
	from public.formas_metricas f
	where f.slug in ('octava_aguda', 'endecha_real', 'estrofa_safica', 'verso_aislado')
		and (
			select count(distinct a.fuente_id)
			from public.afirmaciones_fuentes_metricas a
			left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
			where coalesce(a.forma_id, ar.forma_id) = f.forma_id
		) = 6;
	if v_n <> 4 then
		raise exception 'Solo % de las otras cuatro hablan con las seis fuentes.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
