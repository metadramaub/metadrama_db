-- Cada forma tiene una tradición, y solo una
--
-- La tradición se declaraba de dos maneras a la vez. Treinta y cuatro formas tenían una; la sextina
-- —y su estrofa— tenían **tres**, escritas como una genealogía —provenzal, italiana, española—; y
-- nueve no tenían ninguna. Con eso, la ficha no puede decir de qué tradición es una forma sin
-- elegir por su cuenta, y la precomputación tampoco.
--
-- **Se declara la más relevante, una por forma.** Lo decidió David el 7 de septiembre de 2026, y el
-- argumento es el que sostiene el criterio: si el paso posterior contara, toda forma italiana sería
-- también española, porque todas se adaptaron aquí. Así que la sextina es **italiana** —es la
-- tradición por la que llega al verso castellano, y así la clasifica Domínguez Caparrós, que la
-- pone entre las «formas italianas» junto a la canción y el soneto—, y se retiran su fila
-- provenzal y su fila española. Con ellas se va la tradición provenzal entera, que no clasificaba
-- ninguna otra forma.
--
-- **Y las siete que faltaban se buscan en las fuentes**, que es lo que pedía el criterio del
-- catálogo. Quedan sin tradición **solo los dos tramos sin forma**, y eso es correcto: la
-- versificación irregular y el verso aislado no pertenecen a ninguna.
--
-- Qué dice cada fuente, forma por forma:
--
--   * **Cuarteto** · italiana. El *Diccionario* lo define como «combinación estrófica de cuatro
--     versos de arte mayor» que riman ABAB o ABBA: es el cuarteto endecasílabo importado con el
--     endecasílabo italiano. El de octosílabos ya tiene nombre propio en el catálogo —redondilla—,
--     y es española.
--   * **Cuarteto-lira, octava-lira, novena-lira, décima-lira** · italianas. Son la serie de la
--     lira, que el catálogo ya declara italiana en la lira, el sexteto-lira y el septeto-lira; el
--     *Diccionario* las define por la mezcla de endecasílabos y heptasílabos, que es la
--     combinación aclimatada por Garcilaso. Se sistematizaron el 24 de agosto de 2026 y nacieron
--     sin tradición por eso, no por duda.
--   * **Endecha real** · española. Navarro Tomás (§ 207) la documenta naciendo aquí: Bermúdez y
--     Cervantes la emplean en versos sueltos, aparece con rima abrazada en el *Romancero general* y
--     hacia mediados del XVII se generaliza «la forma asonantada a manera de romance». Es la
--     endecha castellana con un endecasílabo en el cuarto verso, no una forma importada.
--   * **Pareado** · española. Es la de apoyo más débil de las siete, y conviene saberlo: el
--     *Diccionario* lo define sin adscribirlo, porque dos versos que riman existen en cualquier
--     tradición. Se declara española porque Navarro Tomás lo documenta en la lírica castellana
--     desde sus orígenes —los trece pareados de «Eya velar» en Berceo, los pareados enlazados del
--     cósante— y porque en el teatro funciona como estribillo y como remate, no como forma
--     importada. Que una de sus arquitecturas sea alirada dice de qué mide, no de dónde viene.

begin;

do $tradiciones$
declare
	v_espanola uuid;
	v_italiana uuid;
	v_provenzal uuid;
	v_sin_tradicion integer;
	v_con_varias integer;
begin
	select tradicion_id into v_espanola from public.tradiciones_metricas where nombre = 'Española';
	select tradicion_id into v_italiana from public.tradiciones_metricas where nombre = 'Italiana';
	select tradicion_id into v_provenzal from public.tradiciones_metricas where nombre = 'Provenzal';

	if v_espanola is null or v_italiana is null then
		raise exception 'Faltan las tradiciones española o italiana: el catálogo no es el esperado.';
	end if;

	-- ------------------------------------------------------------ La sextina se queda con una
	delete from public.formas_tradiciones ft
	using public.formas_metricas f
	where f.forma_id = ft.forma_id
	  and f.slug in ('sextina', 'sextina_estrofa')
	  and ft.tradicion_id <> v_italiana;

	if v_provenzal is not null then
		if exists (select 1 from public.formas_tradiciones where tradicion_id = v_provenzal) then
			raise exception 'La tradición provenzal sigue clasificando alguna forma: no se puede retirar.';
		end if;
		delete from public.tradiciones_metricas where tradicion_id = v_provenzal;
	end if;

	-- ------------------------------------------------------------ Las siete que faltaban
	insert into public.formas_tradiciones (forma_id, tradicion_id, cronologia, nota)
	select f.forma_id, t.tradicion_id, v.cronologia, v.nota
	from (values
		('cuarteto', 'italiana', 'Desde el siglo XVI',
			'Cuarteto de arte mayor, de endecasílabos, que llega con el endecasílabo italiano; el de octosílabos es la redondilla.'),
		('cuarteto_lira', 'italiana', 'Desde el siglo XVI',
			'De la serie de la lira: combinación de endecasílabos y heptasílabos aclimatada por Garcilaso.'),
		('octava_lira', 'italiana', 'Desde el siglo XVI',
			'De la serie de la lira: combinación de endecasílabos y heptasílabos aclimatada por Garcilaso.'),
		('novena_lira', 'italiana', 'Desde el siglo XVI',
			'De la serie de la lira: combinación de endecasílabos y heptasílabos aclimatada por Garcilaso.'),
		('decima_lira', 'italiana', 'Desde el siglo XVI',
			'De la serie de la lira: combinación de endecasílabos y heptasílabos aclimatada por Garcilaso.'),
		('endecha_real', 'espanola', 'Desde el siglo XVI',
			'Endecha castellana con endecasílabo final. Bermúdez y Cervantes la emplean en versos sueltos y hacia mediados del XVII se generaliza asonantada, a manera de romance (Navarro Tomás, § 207).'),
		('pareado', 'espanola', 'Desde los orígenes de la lírica castellana',
			'Documentado en castellano desde sus orígenes —los pareados de «Eya velar», los del cósante— y en el teatro como estribillo y como remate. Las fuentes no lo adscriben a ninguna tradición, porque dos versos que riman existen en todas: se declara la más relevante para este corpus.')
	) as v(slug, tradicion, cronologia, nota)
	join public.formas_metricas f on f.slug = v.slug
	cross join lateral (
		select case when v.tradicion = 'italiana' then v_italiana else v_espanola end as tradicion_id
	) t
	where not exists (
		select 1 from public.formas_tradiciones ft where ft.forma_id = f.forma_id
	);

	-- ------------------------------------------------------------ La guarda
	select count(*) into v_sin_tradicion
	from public.formas_metricas f
	where f.activo
	  and f.tipo_registro = 'forma'
	  and not exists (select 1 from public.formas_tradiciones ft where ft.forma_id = f.forma_id);

	if v_sin_tradicion > 0 then
		raise exception '% formas siguen sin tradición', v_sin_tradicion;
	end if;

	select count(*) into v_con_varias
	from (
		select ft.forma_id
		from public.formas_tradiciones ft
		join public.formas_metricas f using (forma_id)
		where f.activo
		group by ft.forma_id
		having count(*) > 1
	) varias;

	if v_con_varias > 0 then
		raise exception '% formas declaran más de una tradición', v_con_varias;
	end if;

	if exists (
		select 1
		from public.formas_tradiciones ft
		join public.formas_metricas f using (forma_id)
		where f.activo and f.tipo_registro = 'sin_forma'
	) then
		raise exception 'Un tramo sin forma no puede declarar tradición.';
	end if;

	raise notice 'Cada forma activa declara una tradición, y solo los tramos sin forma no la tienen.';
end
$tradiciones$;

-- La ficha de una forma se arma de esto: que se ejecute con las filas nuevas, y no solo que el dato
-- esté puesto.
do $ficha$
declare
	v_ficha jsonb;
begin
	v_ficha := public.get_forma_metrica_publica('pareado');
	if v_ficha is null then
		raise exception 'La ficha pública del pareado devolvió nulo.';
	end if;
	raise notice 'Ficha del pareado comprobada.';
end
$ficha$;

commit;
