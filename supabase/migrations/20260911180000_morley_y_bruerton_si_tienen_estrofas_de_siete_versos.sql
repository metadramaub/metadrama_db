-- Morley y Bruerton sí tienen estrofas de siete versos
--
-- El septeto y la septilla afirmaban en `/formas` que «su repertorio no tiene ninguna estrofa de
-- siete versos», el septeto además «ni entre los metros españoles ni entre las formas italianas».
-- Es falso, y lo desmiente el propio capítulo V que se cita como fuente: la **seguidilla** se
-- define ahí «en estrofas de cuatro o siete versos», las **coplas de pie quebrado** van «en
-- estrofas (en Lope) de cinco a doce versos» y la **canción**, entre las formas italianas, en
-- «estrofas de 5 a 20 versos». Tres rangos que incluyen el siete, dos de ellos entre los metros
-- españoles.
--
-- Lo encontró la auditoría de las fuentes el 11 de septiembre de 2026, y por duplicado: dos
-- verificadores que no se veían entre sí dieron con el mismo contraejemplo en las dos fichas.
-- La causa es una sola y está en las dos: la enumeración del repertorio que ambas arrastran
-- —«define la redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla y el
-- pareado»— **se deja fuera las coplas de pie quebrado**, que son justo las de rango ancho.
--
-- Lo que sigue siendo cierto, y se conserva, es que no le dan epígrafe propio a ninguna de las
-- dos formas. Eso es lo que la afirmación debía decir desde el principio.
--
-- Se corrige además el localizador. Un silencio no tiene página, tiene **ámbito**: lo que hay que
-- declarar es qué se recorrió para concluir que la forma no estaba, y ahora se puede, porque la
-- copia del capítulo lleva las páginas desde ese mismo día.
--
-- El texto anterior queda en este comentario por si hiciera falta:
--   Septeto:  «No la registran. Su repertorio no tiene ninguna estrofa de siete versos, ni entre
--              los metros españoles ni entre las formas italianas.»
--   Septilla: «No la registran. Su repertorio no tiene ninguna estrofa de siete versos, y lo que
--              no encaja lo reúnen bajo «coplas», las estrofas cortas que no se incluyen en
--              definiciones más específicas.»

begin;

do $$
declare
	v_septeto constant uuid := '3737944e-2bed-4280-8cbe-05fd0c995a3e';
	v_septilla constant uuid := 'cf1fd154-4e03-4267-aea1-8d3179b7b324';
	v_tocadas integer;
	v_quedan integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- ------------------------------------------------------------------ Antes
	--
	-- Que las dos filas son las que se creen, y de la fuente que se cree. Si alguien las hubiera
	-- retirado o reasignado, esta migración no debe inventarse nada.
	select count(*) into v_tocadas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.afirmacion_id in (v_septeto, v_septilla) and f.anio = 1968;
	if v_tocadas <> 2 then
		raise exception 'Esperaba las dos afirmaciones de Morley y Bruerton y encontré %.', v_tocadas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ------------------------------------------------------------------ La corrección
	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio ni nombre. Su repertorio sí alcanza los siete versos por otras '
			'vías: entre las formas italianas, la canción se define en «estrofas de 5 a 20 versos»; y '
			'entre los metros españoles, la seguidilla «en estrofas de cuatro o siete versos» y las '
			'coplas de pie quebrado «en estrofas (en Lope) de cinco a doce versos». Ninguno de esos '
			'rangos distingue el siete ni le da nombre.',
		localizador = 'Cap. V, pp. 38-41'
	where afirmacion_id = v_septeto;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio. Lo que no encaja en una definición específica lo reúnen bajo '
			'«coplas», «estrofas cortas que no se incluyen en definiciones más específicas», que es '
			'donde podría caer. Con siete versos sí registran la seguidilla, «en estrofas de cuatro o '
			'siete versos», y las coplas de pie quebrado, «en estrofas (en Lope) de cinco a doce '
			'versos», aunque en ninguno de los dos casos como forma con nombre propio.',
		localizador = 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'
	where afirmacion_id = v_septilla;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se comprueba lo que se toca**, no que la sentencia se haya escrito. Que la frase falsa ya
	-- no está en ninguna de las dos, y que la revisión del catálogo subió: si no sube, el gestor
	-- serviría lo viejo desde su caché y la web seguiría diciendo lo que se acaba de corregir.
	select count(*) into v_quedan
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_septeto, v_septilla)
		and resumen ilike '%no tiene ninguna estrofa de siete versos%';
	if v_quedan > 0 then
		raise exception 'Quedan % afirmaciones con la generalización falsa.', v_quedan;
	end if;

	select count(*) into v_quedan
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_septeto, v_septilla)
		and resumen ilike '%estrofas de cuatro o siete versos%';
	if v_quedan <> 2 then
		raise exception 'Esperaba el contraejemplo de la seguidilla en las dos y está en %.', v_quedan;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
