-- El septeto-lira de Caparrós no era un silencio, y el verso libre de Jauralde tenía dos casas
--
-- Las dos únicas afirmaciones que, tras regenerar los extractos, seguían sin pasaje: su localizador
-- no se podía seguir. Al ir a dárselo, resultaron ser dos casos distintos.
--
-- ══ `4ebe5647` · la ficha era falsa
--
-- Decía que Caparrós «describe la canción alirada y sus estrofas —el cuarteto lira entre ellas—
-- **sin dar epígrafe propio a la de siete versos**», que suena a silencio. Pero en la p. 200, dentro
-- del § 10.2.6 «Septeto»:
--
--   «Puede adoptar la forma de **septeto lira**: endecasílabos y heptasílabos con rima consonante.
--   De Fray Luis de León, "A don Pedro Portocarrero", son los versos del ejemplo.»
--
-- **Lo nombra, lo define y lo ejemplifica.** Un lector de la ficha concluiría que Caparrós no trata
-- el septeto-lira, y lo trata. Importa doble: esa forma tiene una propuesta sin redactar y la
-- frontera alirada/canción está esperando al IP.
--
-- La canción alirada, en cambio, aparece **una sola vez en todo el libro**, de pasada, al definir el
-- cuarteto lira en la p. 190. La ficha decía que Caparrós «la describe», y no la describe.
--
-- ══ `1b182f52` · la ficha era fiel
--
-- Comprobadas sus dos mitades en el epub, literales las dos. Lo que fallaba era el localizador,
-- «Apartado sobre el verso libre», y por una razón concreta: **el libro tiene dos encabezados de
-- verso libre** —un `h5` «VERSO LIBRE» en el capítulo del verso y otro `h5` «EL VERSO LIBRE» en el
-- de las estrofas—, y esa fórmula no dice cuál. Se cita el segundo, con el `h6` «Verso irregular»
-- que cuelga de él y que es donde está la primera mitad de la afirmación.
--
-- Aprobado por David el 20 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_esperadas constant integer := 1;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_septeto (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_septeto (id8, antes, despues)
	values
		('4ebe5647', 'Describe la canción alirada y sus estrofas —el cuarteto lira entre ellas— sin dar epígrafe propio a la de siete versos.', 'Bajo el epígrafe «Septeto» define el septeto, séptima o septilla como toda estrofa de siete versos, dice que «no son muy frecuentes estas estrofas en la poesía castellana» y precisa que «**puede adoptar la forma de septeto lira: endecasílabos y heptasílabos con rima consonante**», con un ejemplo de fray Luis de León. No le da epígrafe propio ni esquema de rima, y menciona la canción alirada solo de pasada, al definir el cuarteto lira.');

	-- Que cada una tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_septeto c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_septeto c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_septeto c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;


do $$
declare
	v_n integer;
	v_esperadas constant integer := 2;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_sin_pasaje (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_sin_pasaje (id8, antes, despues)
	values
		('4ebe5647', 'Apartado de la canción alirada', '§§ 10.2.3 y 10.2.6, pp. 190 y 199-200'),
		('1b182f52', 'Apartado sobre el verso libre', '«El verso libre», y dentro de él «Verso irregular»');

	-- Que cada una tiene hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_sin_pasaje c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % tienen el texto que esta migración espera; no toco ninguna.', v_n, v_esperadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set localizador = c.despues
	from cambios_sin_pasaje c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n
	from cambios_sin_pasaje c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.despues;
	if v_n <> v_esperadas then
		raise exception 'Solo % de % quedaron con el texto nuevo.', v_n, v_esperadas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
