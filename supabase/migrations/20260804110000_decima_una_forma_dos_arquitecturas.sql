-- La décima vuelve a ser una sola forma con dos arquitecturas.
--
-- El vocabulario viejo tenía una raíz `decima` y dos hijas. La raíz y `decima_espinela`
-- son literalmente lo mismo: mismo patrón `abbaaccddc`, mismo tamaño 10, y cada una declara
-- a la otra en `equivalencias`. Era una raíz duplicada, no una forma general.
--
-- Al importar, la aumentada salió fuera como forma aparte porque doce versos no cabían en
-- una forma de diez. Ese obstáculo ya no existe: la extensión la declara la arquitectura
-- (`unidad_versos_min`/`max`), no la forma. La redondilla, de cuatro versos, aloja desde
-- julio una arquitectura «Doble enlazada» de ocho. Esto es el mismo movimiento.
--
-- No se crea una arquitectura genérica configurable: en el corpus no hay ni una décima de
-- diez versos que no sea espinela, y el editor debe responder lo mínimo.
--
-- Cuidado al leer la definición: la copla real es también diez octosílabos consonantes. Lo
-- que las separa es la pausa —espinela 4 + 2 + 4, copla real 5 + 5—, así que la definición
-- lleva la articulación y no solo la medida.

begin;

do $$
declare
	v_forma_decima uuid;
	v_forma_aumentada uuid;
	v_arq_espinela uuid;
	v_arq_aumentada uuid;
	v_term_decima uuid;
	v_term_espinela uuid;
	v_term_aumentada uuid;
begin
	select termino_id into v_term_decima from public.vocabularios
	where categoria = 'estrofa_tipo' and termino = 'decima';
	select termino_id into v_term_espinela from public.vocabularios
	where categoria = 'estrofa_tipo' and termino = 'decima_espinela';
	select termino_id into v_term_aumentada from public.vocabularios
	where categoria = 'estrofa_tipo' and termino = 'decima_aumentada';

	if v_term_decima is null or v_term_espinela is null or v_term_aumentada is null then
		raise exception 'No están los tres términos legados de la décima';
	end if;

	-- La forma «Décima espinela» reutiliza el UUID del término legado del que salió.
	select forma_id into v_forma_decima from public.formas_metricas where slug = 'decima_espinela';
	select forma_id into v_forma_aumentada from public.formas_metricas where slug = 'decima_aumentada';

	if v_forma_decima is null or v_forma_aumentada is null then
		raise exception 'No están las dos formas de décima que hay que fundir (¿ya se aplicó esta migración?)';
	end if;

	select arquitectura_id into v_arq_espinela from public.arquitecturas_forma
	where forma_id = v_forma_decima;
	select arquitectura_id into v_arq_aumentada from public.arquitecturas_forma
	where forma_id = v_forma_aumentada;

	if v_arq_espinela is null or v_arq_aumentada is null then
		raise exception 'Cada décima debía tener exactamente una arquitectura';
	end if;

	-- 1 · La forma pasa a ser la décima, y reclama la raíz legada.
	update public.formas_metricas
	set
		slug = 'decima',
		nombre = 'Décima',
		definicion = 'Estrofa de diez versos octosílabos con rima consonante, articulada en 4 + 2 + 4 y con pausa característica tras el cuarto verso. Los dos versos centrales enlazan la primera redondilla con la segunda. La pausa tras el cuarto verso la distingue de la copla real, que también consta de diez octosílabos pero se articula en 5 + 5. El catálogo reconoce además una realización aumentada de doce versos.',
		origen_termino_id = v_term_decima
	where forma_id = v_forma_decima;

	-- 2 · Su arquitectura es la espinela, y reclama el término de la espinela.
	update public.arquitecturas_forma
	set
		slug = 'espinela',
		nombre = 'Espinela',
		descripcion = 'Diez octosílabos consonantes con rima abba:accddc, pausa tras el cuarto verso y estructura 4 + 2 + 4.',
		origen_termino_id = v_term_espinela
	where arquitectura_id = v_arq_espinela;

	-- 3 · La aumentada deja de ser principal antes de mudarse: solo puede haber una
	-- principal activa por forma, y las dos lo eran en su forma anterior.
	update public.arquitecturas_forma
	set principal = false
	where arquitectura_id = v_arq_aumentada;

	update public.arquitecturas_forma
	set
		forma_id = v_forma_decima,
		slug = 'aumentada',
		nombre = 'Aumentada',
		descripcion = 'Doce octosílabos consonantes con rima abba:accddeed, pausa tras el cuarto verso y estructura 4 + 8.',
		modalidad = 'admitida',
		orden = 20,
		origen_termino_id = v_term_aumentada
	where arquitectura_id = v_arq_aumentada;

	-- 4 · Lo que colgaba de la forma retirada se traslada. La tradición solo si la décima no
	-- la tiene ya, porque el par (forma, tradición) es único.
	insert into public.formas_tradiciones (forma_id, tradicion_id, cronologia, nota)
	select v_forma_decima, ft.tradicion_id, ft.cronologia, ft.nota
	from public.formas_tradiciones ft
	where ft.forma_id = v_forma_aumentada
		and not exists (
			select 1 from public.formas_tradiciones existente
			where existente.forma_id = v_forma_decima
				and existente.tradicion_id = ft.tradicion_id
		);

	update public.afirmaciones_fuentes_metricas
	set forma_id = v_forma_decima
	where forma_id = v_forma_aumentada;

	-- 5 · Los nombres tradicionales siguen siendo buscables, ahora como denominaciones de
	-- la arquitectura que nombran.
	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, tipo_alias, idioma, preferente)
	values
		(v_arq_espinela, 'Décima espinela', 'decima_espinela', 'equivalente', 'es', true),
		(v_arq_aumentada, 'Décima aumentada', 'decima_aumentada', 'equivalente', 'es', true)
	on conflict do nothing;

	-- 6 · La forma vacía se retira. Sus secciones y esquemas ya se mudaron con la
	-- arquitectura, así que la cascada no se lleva nada por delante.
	delete from public.formas_metricas where forma_id = v_forma_aumentada;

	raise notice 'Décima: una forma con las arquitecturas Espinela (10) y Aumentada (12).';
end $$;

-- El catálogo cambió: el demarcador compilado queda desactualizado y hay que regenerarlo.
update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
