-- Las coplas de pie quebrado faltaban en la cuenta
--
-- Cuatro afirmaciones más de Morley y Bruerton afirmaban ausencias que su propio capítulo V
-- desmiente, y todas por la misma razón que el septeto y la septilla —corregidos en
-- `20260911180000`—: **la enumeración de su repertorio se dejaba fuera las coplas de pie
-- quebrado**, que van «en estrofas (en Lope) de cinco a doce versos» y son justo las de rango
-- ancho. Con ellas dentro, la cuenta cambia:
--
--   * la **novena** decía que no hay ninguna estrofa de nueve versos — el rango incluye el nueve;
--   * la **oncena**, ninguna de once — lo incluye el rango, y también la canción italiana, «de 5
--     a 20 versos»;
--   * la **copla castellana** y la **copla de arte menor**, ninguna de ocho versos de arte menor
--     — y las coplas de pie quebrado son octosílabas con su quebrado, o sea de arte menor, en
--     estrofas que llegan a doce.
--
-- Esa última era la que quedaba por decidir, porque podía discutirse si una estrofa con quebrado
-- cuenta como de arte menor. **Lo resolvió el IP el 11 de septiembre de 2026**: el octosílabo es
-- arte menor, así que lo son; y lo que separa la copla castellana de la de arte menor no es el
-- metro sino si la rima enlaza las dos mitades. Morley y Bruerton no hacen esa distinción.
--
-- Lo cierto se conserva y se completa: no les dan epígrafe propio, y lo que no encaja lo reúnen
-- bajo «coplas». La enumeración del repertorio pasa a estar completa, que es lo que impide que el
-- error vuelva. Y el localizador declara el **ámbito recorrido** con sus páginas, porque un
-- silencio no se sitúa en una página sino en lo que se miró para afirmarlo.
--
-- Texto anterior, por si hiciera falta:
--   Novena:   «Su repertorio de metros españoles no incluye ninguna estrofa de nueve versos: …»
--   Oncena:   «No la registran. Su repertorio no tiene ninguna estrofa de once versos, …»
--   Castellana: «No la registran. Su repertorio de metros españoles no tiene ninguna estrofa de
--                ocho versos de arte menor, …»
--   Arte menor: «No la registran. Su repertorio de metros españoles no tiene ninguna estrofa de
--                ocho versos de arte menor —define la redondilla, …—, …»

begin;

do $$
declare
	v_novena constant uuid := 'eda23541-1a5c-4a26-b7a3-dd8bc37b27d4';
	v_oncena constant uuid := '074f0d3a-4ddf-45ea-af66-4f5cf1d75792';
	v_castellana constant uuid := 'fce52a1e-2da0-4e9a-a79e-a17c920197d0';
	v_artemenor constant uuid := '7f74a91b-1abe-4d72-aeaf-43336440777f';
	v_todas constant uuid[] := array[v_novena, v_oncena, v_castellana, v_artemenor];
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.afirmacion_id = any(v_todas) and f.anio = 1968;
	if v_cuantas <> 4 then
		raise exception 'Esperaba las cuatro afirmaciones de Morley y Bruerton y encontré %.', v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio. Su repertorio de metros españoles define la redondilla, la '
			'quintilla, la copla real, la décima, el romance, la seguidilla, el pareado y las coplas '
			'de pie quebrado, y reúne aparte, bajo «coplas», «estrofas cortas que no se incluyen en '
			'definiciones más específicas», que es donde podría caer. Las coplas de pie quebrado van '
			'«en estrofas (en Lope) de cinco a doce versos», rango que incluye el nueve sin '
			'distinguirlo ni nombrarlo.',
		localizador = 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'
	where afirmacion_id = v_novena;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio. Lo que no encaja en una definición específica lo reúnen bajo '
			'«coplas», «estrofas cortas que no se incluyen en definiciones más específicas», que es '
			'donde podría caer. Con once versos caben sus coplas de pie quebrado, «en estrofas (en '
			'Lope) de cinco a doce versos», y entre las formas italianas la canción, en «estrofas de '
			'5 a 20 versos»; ninguno de los dos rangos distingue el once ni le da nombre.',
		localizador = 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'
	where afirmacion_id = v_oncena;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio. Su repertorio de metros españoles define la redondilla, la '
			'quintilla, la copla real, la décima, el romance, la seguidilla, el pareado y las coplas '
			'de pie quebrado, y reúne aparte, bajo «coplas», «estrofas cortas que no se incluyen en '
			'definiciones más específicas», que es donde podría caer un pasaje de dos redondillas '
			'agrupadas. Sus coplas de pie quebrado sí son de arte menor y llegan a ocho versos —van '
			'«en estrofas (en Lope) de cinco a doce versos»—, pero combinan el octosílabo con su '
			'quebrado y el epígrafe no atiende a si la rima enlaza las dos mitades, que es lo que '
			'separaría esta forma de la copla de arte menor.',
		localizador = 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'
	where afirmacion_id = v_castellana;

	update public.afirmaciones_fuentes_metricas
	set
		resumen =
			'No le dan epígrafe propio. Su repertorio de metros españoles define la redondilla, la '
			'quintilla, la copla real, la décima, el romance, la seguidilla, el pareado y las coplas '
			'de pie quebrado, y reúne aparte, bajo «coplas», «estrofas cortas que no se incluyen en '
			'definiciones más específicas». Sus coplas de pie quebrado sí son de arte menor y llegan '
			'a ocho versos —van «en estrofas (en Lope) de cinco a doce versos»—, pero combinan el '
			'octosílabo con su quebrado y el epígrafe no distingue si la rima enlaza las dos '
			'mitades, que es lo que separaría esta forma de la copla castellana.',
		localizador = 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'
	where afirmacion_id = v_artemenor;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que ninguna sigue negando en bloque, que las cuatro traen ya el contraejemplo, y que la
	-- enumeración del repertorio —la que causó el error— incluye ahora las coplas de pie quebrado
	-- allí donde se enumera.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_todas)
		and (resumen ilike '%no tiene ninguna estrofa de%' or resumen ilike '%no incluye ninguna estrofa de%');
	if v_cuantas > 0 then
		raise exception 'Quedan % afirmaciones negando en bloque.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_todas) and resumen ilike '%cinco a doce versos%';
	if v_cuantas <> 4 then
		raise exception 'Esperaba el rango del pie quebrado en las cuatro y está en %.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_todas)
		and resumen ilike '%define la redondilla%'
		and resumen not ilike '%y las coplas de pie quebrado%';
	if v_cuantas > 0 then
		raise exception 'Hay % enumeraciones del repertorio sin las coplas de pie quebrado.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
