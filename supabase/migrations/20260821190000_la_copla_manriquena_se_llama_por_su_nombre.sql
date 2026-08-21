-- La copla manriqueña se llama por su nombre
--
-- Corrección de la migración de ayer mismo. La estrofa de doce se creó como «Doble sextilla», que
-- **la describe pero no la nombra**, y el catálogo no hace eso en ningún otro sitio: la de diez se
-- llama copla real y no «doble quintilla», y la de nueve, novena. El criterio es el mismo que
-- ordenó estas seis formas —la estructura decide el nivel, el nombre lo da la tradición— y aquí se
-- había aplicado solo la primera mitad.
--
-- Pasa a **Copla manriqueña**, y «Doble sextilla» queda como denominación, que es lo que es: el
-- término descriptivo con que Navarro Tomás y Jauralde la designan al contar los doce versos.
--
-- **Y el nombre deja de estar en dos sitios.** Las tres denominaciones manriqueñas colgaban también
-- de `sextilla · pie_quebrado`, porque Quilis y Domínguez Caparrós llaman manriqueña a la estrofa
-- de seis mientras Navarro y Jauralde la reservan para la agrupación de doce. Con la forma ya
-- nombrada así, tenerlas en los dos sitios haría que una búsqueda por «copla manriqueña» devolviera
-- dos cosas distintas. Se retiran de la arquitectura —que conserva «Copla de pie quebrado»— y **el
-- reparto del nombre sigue dicho donde importa**: en la descripción de esa arquitectura, que ya lo
-- explica fuente por fuente, y ahora también en la definición de la forma.

begin;

do $$
declare
	v_forma uuid;
	v_simple uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de doce versos formada por dos sextillas de pie quebrado seguidas, con sus rimas '
		|| 'independientes: ninguna pasa de la primera a la segunda. Es la estrofa de las *Coplas* '
		|| 'de Jorge Manrique a la muerte de su padre, de donde le viene el nombre, y su disposición '
		|| 'más conocida reparte los doce versos en cuatro tercetos correlativos, '
		|| '`abc:abc-def:def`, con el tercer verso de cada terceto quebrado. La tradición documenta '
		|| 'antes otras: sextillas de dos rimas repetidas en las dos mitades, o con el orden '
		|| 'invertido en la segunda. El nombre se reparte según qué versos se cuenten: Navarro Tomás '
		|| 'y Jauralde llaman manriqueña a esta agrupación de doce, y Quilis y Domínguez Caparrós a '
		|| 'la sextilla de seis que la compone. Métricamente no se distingue de dos sextillas '
		|| 'puestas una detrás de otra —la medida y la rima se organizan igual, y lo que corre de '
		|| 'una a otra es el sentido del texto—, y esa es también la relación de la copla castellana '
		|| 'con dos redondillas y de la copla real con dos quintillas: lo que une las semiestrofas '
		|| 'es la manera en que el poema las agrupa.';
begin
	select forma_id into v_forma from public.formas_metricas
	where slug in ('doble_sextilla', 'copla_manriquena');
	if v_forma is null then
		raise exception 'No existe la estrofa de doce versos que hay que renombrar.';
	end if;

	select nombre into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not in ('Doble sextilla', 'Copla manriqueña') then
		raise exception 'La estrofa de doce se llama «%», que no es lo esperado.', v_actual;
	end if;

	update public.formas_metricas set
		slug = 'copla_manriquena',
		nombre = 'Copla manriqueña',
		definicion = c_definicion
	where forma_id = v_forma;

	-- «Copla manriqueña» ya no es alias: es el nombre. «Doble sextilla» pasa a serlo.
	delete from public.denominaciones_metricas
	where forma_id = v_forma and slug_normalizado = 'copla_manriquena';

	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Doble sextilla', 'doble_sextilla', false, v_navarro
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'doble_sextilla'
	);

	-- ----------------------------------------- El nombre deja de estar en la sextilla
	select a.arquitectura_id into v_simple
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sextilla' and a.slug = 'pie_quebrado';
	if v_simple is null then
		raise exception 'No aparece la sextilla de pie quebrado.';
	end if;

	delete from public.denominaciones_metricas
	where arquitectura_id = v_simple
		and slug_normalizado in ('copla_manriquena', 'estrofa_manriquena', 'copla_de_jorge_manrique');

	-- ------------------------------------------------------------------ Comprobaciones
	-- La forma se llama por su nombre y conserva los otros dos que la tradición le da.
	select string_agg(d.nombre, ', ' order by d.nombre) into v_actual
	from public.denominaciones_metricas d where d.forma_id = v_forma;
	if v_actual is distinct from 'Copla de Jorge Manrique, Doble sextilla, Estrofa manriqueña' then
		raise exception 'Los otros nombres de la copla manriqueña son «%».', v_actual;
	end if;

	-- Y «manriqueña» apunta a una sola cosa en el catálogo entero.
	select count(*) into v_n
	from public.denominaciones_metricas d
	where d.slug_normalizado like '%manriquen%' or d.slug_normalizado like '%jorge_manrique%';
	if v_n <> 2 then
		raise exception '«Manriqueña» nombra % entidades del catálogo, no solo la forma.', v_n;
	end if;

	-- La arquitectura que la realiza conserva el nombre que sí es suyo.
	if not exists (
		select 1 from public.denominaciones_metricas
		where arquitectura_id = v_simple and slug_normalizado = 'copla_de_pie_quebrado'
	) then
		raise exception 'La sextilla de pie quebrado ha perdido su propio nombre.';
	end if;

	-- El reparto del nombre sigue explicado en las dos fichas.
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_simple;
	if v_actual not like '%El nombre de manriqueña se reparte%' then
		raise exception 'La sextilla de pie quebrado ya no explica el reparto del nombre.';
	end if;

	if public.get_forma_metrica_publica('copla_manriquena') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la copla manriqueña no responde.';
	end if;
	if public.get_forma_metrica_publica('doble_sextilla') -> 'formas' <> '[]'::jsonb then
		raise exception 'El slug viejo sigue respondiendo: el renombrado no se ha aplicado.';
	end if;
end $$;

commit;
