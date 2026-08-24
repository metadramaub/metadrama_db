-- El cuarteto-lira abre la serie alirada
--
-- Primera de las formas que faltaban en la serie de estrofas aliradas. La propuesta del IP —24 de
-- agosto de 2026— es sistematizar los nombres: donde la crítica dice «cuarteto alirado», «lira
-- garcilasiana», «lira-sextina» o «septeto alirado», el catálogo dirá cuarteto-lira, lira,
-- sexteto-lira y septeto-lira, y **reservará «canción» para lo que siga el modelo petrarquista**.
--
-- Esa distinción no es un bautismo nuestro: la enuncia el *Diccionario*, y es estructural.
--
-- > «canción alirada. Canción a la italiana cuyas estrofas, cortas y simétricas, **prescinden de
-- > la ordenación rigurosa de la estancia** y combinan endecasílabos y heptasílabos con rima
-- > consonante. Es decir, utiliza como unidad estrófica la lira.»
--
-- Una estrofa alirada es, entonces, la que tiene la materia de la canción —siete y once,
-- consonante, repetida sin cambio— **y le falta la ordenación**: fronte en dos piedi, eslabón y
-- sirima. Eso se comprueba en el dato, no se decide por el nombre.
--
-- Y la misma entrada acota la serie:
--
-- > «…una variante de la canción a la italiana en que la unidad estrófica **oscila entre los
-- > cuatro y ocho versos** (cuarteto-lira, lira garcilasiana, sexteto-lira, septeto alirado y
-- > octava alirada).»
--
-- El catálogo tenía ya la lira, el sexteto-lira y el septeto-lira. Esta es la de cuatro, con
-- entrada propia:
--
-- > «cuarteto-lira. Combinación estrófica de cuatro versos, endecasílabos y heptasílabos **en
-- > proporción variable**, que riman, normalmente en consonante, el primero con el tercero y el
-- > segundo con el cuarto; o el primero con el cuarto y el segundo con el tercero. Puede
-- > encontrarse también con rima asonante o con algún verso suelto.»
--
-- De ahí sale todo lo que se declara: cuatro versos, la mezcla de siete y once **sin orden fijo**
-- —por eso el esquema métrico es un conjunto y no una secuencia de posiciones—, y dos
-- disposiciones, la cruzada y la abrazada.
--
-- *Lo que la entrada admite y aquí no se modela:* la rima asonante y el verso suelto. Son
-- realizaciones que el* Diccionario *registra de pasada, sin definirlas ni darles nombre, y por
-- [criterios de nivel § 3.6](../../docs/dominio-metrico/criterios-de-nivel.md) eso no basta para
-- fijar la norma. Quedan dichas en la definición y en la afirmación de la fuente; si alguien las
-- necesita, las pedirá.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_lira uuid;
	v_lira_arq uuid;
	v_consonante uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_n integer;
	v_notaciones text;

	c_definicion constant text :=
		'Estrofa de cuatro versos que mezcla endecasílabos y heptasílabos en proporción variable y '
		|| 'rima en consonante, cruzada —el primero con el tercero y el segundo con el cuarto— o '
		|| 'abrazada —el primero con el cuarto y el segundo con el tercero—. Es la menor de las '
		|| 'estrofas aliradas: tiene la materia de la canción italiana, siete y once consonantes '
		|| 'repetidos sin cambio de una estrofa a otra, y le falta su ordenación en fronte y '
		|| 'sirima, que es lo que separa una estrofa alirada de una estancia. La tradición registra '
		|| 'también realizaciones con rima asonante o con algún verso suelto.';
begin
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';
	select arquitectura_id into v_lira_arq from public.arquitecturas_forma
	where forma_id = v_lira and activo limit 1;
	if v_lira_arq is null then
		raise exception 'No existe la lira, de la que esta forma toma su régimen.';
	end if;

	select tipo_rima_id into v_consonante from public.arquitecturas_forma
	where arquitectura_id = v_lira_arq;
	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	if v_consonante is null or v_hepta is null or v_endeca is null then
		raise exception 'Falta el régimen consonante, el heptasílabo o el endecasílabo.';
	end if;

	-- La serie alirada estaba en 5, 6 y 7 antes de esta.
	select count(*) into v_n from public.formas_metricas
	where activo and slug in ('lira', 'sexteto_lira', 'septeto_lira');
	if v_n <> 3 then
		raise exception 'La serie alirada tiene % formas de las tres esperadas.', v_n;
	end if;

	-- ------------------------------------------------------------------ La forma
	select forma_id into v_forma from public.formas_metricas where slug = 'cuarteto_lira';
	if v_forma is null then
		insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, activo, orden)
		select 'cuarteto_lira', 'Cuarteto-lira', c_definicion, f.nivel_estructural, true, f.orden
		from public.formas_metricas f where f.forma_id = v_lira
		returning forma_id into v_forma;
	else
		update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;
	end if;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heterometrica_consonante';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (
			v_forma, 'heterometrica_consonante', 'Heterométrica consonante',
			'Cuatro versos de siete y once sílabas en proporción variable —la norma no fija cuántos '
			|| 'de cada uno ni en qué orden— con rima consonante. Lo único que se elige de la rima '
			|| 'es si cruza o abraza.',
			true, true, 'habitual', v_consonante, true, 1, 4, 4
		)
		returning arquitectura_id into v_arq;

		-- La medida: siete y once sin orden fijo, que es lo que dice «en proporción variable»
		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);

		-- Las dos disposiciones que la fuente enuncia
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values
			(v_arq, 'abab', 'Cruzada · abab', 'abab', v_consonante, 'admitida', 'secuencia',
				'Rima el primero con el tercero y el segundo con el cuarto.'),
			(v_arq, 'abba', 'Abrazada · abba', 'abba', v_consonante, 'admitida', 'secuencia',
				'Rima el primero con el cuarto y el segundo con el tercero.');

		-- Y la pregunta: cuál de las dos, que se responde estrofa a estrofa
		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
			permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
		)
		values (
			v_arq, 'disposicion_rima', 'rima', 'unidad', 1, 1, true, true, 1, 'opciones', false,
			'Marca si la rima cruza o abraza en cada estrofa.'
		);
	end if;

	-- ------------------------------------------------------------------ Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Cuarteto-lira', 'cuarteto_lira', true, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'cuarteto_lira'
	);

	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Cuarteto alirado', 'cuarteto_alirado', false, v_navarro
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'cuarteto_alirado'
	);

	-- ------------------------------------------------------------------ Lo que dicen las fuentes
	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	select v_dc16, v_forma, 's. v. «cuarteto-lira»',
		'La define como estrofa de cuatro versos, endecasílabos y heptasílabos en proporción '
		|| 'variable, que riman normalmente en consonante, el primero con el tercero y el segundo '
		|| 'con el cuarto, o el primero con el cuarto y el segundo con el tercero. Añade que puede '
		|| 'encontrarse también con rima asonante o con algún verso suelto.',
		'alta'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_dc16 and localizador = 's. v. «cuarteto-lira»'
	);

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	select v_dc16, v_forma, 's. v. «canción alirada»',
		'Sitúa el cuarteto-lira en la serie de estrofas aliradas, cuya unidad «oscila entre los '
		|| 'cuatro y ocho versos», junto a la lira garcilasiana, el sexteto-lira, el septeto '
		|| 'alirado y la octava alirada. Y separa la serie de la canción por la estructura: sus '
		|| 'estrofas «prescinden de la ordenación rigurosa de la estancia».',
		'alta'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_dc16 and localizador = 's. v. «canción alirada»'
	);

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	select v_navarro, v_forma, 's. v. «cuarteto alirado», recogido en el Diccionario',
		'Navarro Tomás la llama cuarteto alirado; el Diccionario remite ese nombre a cuarteto-lira.',
		'media'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_navarro
	);

	-- ------------------------------------------------------------------ El vínculo con la lira
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_lira, 'relacionada_con',
		'Las dos son estrofas aliradas: misma mezcla de siete y once, misma rima consonante y '
		|| 'misma repetición sin cambio. Lo único que las separa es la extensión de la estrofa, '
		|| 'cuatro versos frente a cinco.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_lira)
			or (forma_origen_id = v_lira and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 1 then
		raise exception 'El cuarteto-lira tiene % arquitecturas, no una.', v_n;
	end if;

	-- Cuatro versos, ni uno más: es lo que lo separa de la lira.
	select unidad_versos_min into v_n from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_n <> 4 then
		raise exception 'La unidad del cuarteto-lira mide % versos, no cuatro.', v_n;
	end if;

	-- Las dos medidas y las dos disposiciones que enuncia la fuente.
	select count(*) into v_n
	from public.esquema_metrico_opciones o
	join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
	where em.arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'El cuarteto-lira ofrece % medidas, no siete y once.', v_n;
	end if;

	select string_agg(notacion, ' y ' order by notacion) into v_notaciones
	from public.esquemas_rima where arquitectura_id = v_arq;
	if v_notaciones is distinct from 'abab y abba' then
		raise exception 'Las disposiciones del cuarteto-lira son «%», y deberían ser abab y abba.', v_notaciones;
	end if;

	-- Su pregunta ofrece las dos, sin la cual el editor no podría registrar cuál vio.
	select count(*) into v_n from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'La pregunta del cuarteto-lira ofrece % opciones, no las dos.', v_n;
	end if;

	if public.get_forma_metrica_publica('cuarteto_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del cuarteto-lira no responde.';
	end if;
	if public.get_forma_metrica_publica('lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la lira ha dejado de responder.';
	end if;
end $$;

commit;
