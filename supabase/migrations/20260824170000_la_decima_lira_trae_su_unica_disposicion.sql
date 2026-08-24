-- La décima-lira trae su única disposición
--
-- Última de la serie alirada. Como la novena, queda fuera de la horquilla que documenta el
-- *Diccionario* —«entre los cuatro y ocho versos»— y ninguna de las seis monografías la registra.
-- **Pero a diferencia de la novena, esta tiene un testimonio**, y viene del corpus:
--
-- > El editor de *Elisa Dido* llama «décimas-estancias» al patrón **aBaBcDcDeE**.
--
-- No es una de las seis fuentes autorizadas, y por eso no se registra como afirmación de fuente
-- sino como disposición documentada en el corpus, que para un catálogo de verso dramático es la
-- evidencia más pertinente que hay. La tradición crítica llama a esa estrofa «décima-estancia»; el
-- nombre queda recogido como denominación alternativa, y el preferente es el sistemático.
--
-- **Y es el caso que fijó el criterio del 24 de agosto de 2026.** El IP se preguntó si `aBaBcDcDeE`
-- podía leerse como estancia de canción —fronte `aB` + `aB`, sirima `cDcDeE`— y lo consideró
-- forzado. Lo único que le falta frente al modelo petrarquista es el eslabón: la sirima abre en `c`
-- y la fronte cierra en `B`, de modo que no retoma nada. De ahí salió la regla que ahora está en
-- [criterios de nivel § 3.4](../../docs/dominio-metrico/criterios-de-nivel.md): **es estancia si hay
-- eslabón; es alirada si no lo hay.** Esta forma existe porque esa regla la separó de la canción.
--
-- Su medida se declara como en toda la serie, conjunto de siete y once, y no como secuencia de
-- posiciones: el testimonio alterna 7 y 11 con regularidad, pero es **un** testimonio y no basta
-- para fijar que la alternancia sea la norma. Eso queda dicho en la descripción del esquema.
--
-- La pregunta de disposición se declara **opcional**: ofrece la única documentada, y quien anote
-- una décima-lira que no siga ese patrón puede dejarla en blanco hasta que **B1** permita declarar
-- un esquema que el catálogo no tenga. Forzar a elegir la única que hay obligaría a mentir.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_rima uuid;
	v_lira uuid;
	v_lira_arq uuid;
	v_novena uuid;
	v_cancion uuid;
	v_consonante uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_termino uuid;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de diez versos que mezcla endecasílabos y heptasílabos y rima en consonante. '
		|| 'Pertenece a la serie de las estrofas aliradas: tiene la materia de la canción italiana '
		|| 'y no se ordena como una estancia, porque no trae eslabón —el verso que abriría la '
		|| 'segunda mitad retomando la rima con que se cerró la primera—. Es la de la serie que más '
		|| 'se confunde con una canción, hasta el punto de que la tradición crítica la llama '
		|| '«décima-estancia»: su disposición documentada, aBaBcDcDeE, repite la cabeza como lo '
		|| 'haría una fronte partida en dos piedi, y solo la ausencia de eslabón la separa de una '
		|| 'estancia de diez versos. Ninguna de las fuentes del catálogo la describe; su testimonio '
		|| 'viene del corpus.';
begin
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';
	select arquitectura_id into v_lira_arq from public.arquitecturas_forma
	where forma_id = v_lira and activo limit 1;
	select forma_id into v_novena from public.formas_metricas where slug = 'novena_lira';
	select forma_id into v_cancion from public.formas_metricas where slug = 'cancion_petrarquista';
	if v_lira_arq is null or v_novena is null then
		raise exception 'Falta la lira o la novena-lira: esta cierra esa serie.';
	end if;

	select tipo_rima_id into v_consonante from public.arquitecturas_forma
	where arquitectura_id = v_lira_arq;
	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select termino_id into v_termino from public.vocabularios
	where termino = 'decima_lira' and categoria = 'estrofa_tipo';
	if v_consonante is null or v_hepta is null or v_endeca is null then
		raise exception 'Falta el régimen consonante, el heptasílabo o el endecasílabo.';
	end if;

	-- El criterio que justifica esta forma tiene que estar puesto: si la canción no declara su
	-- eslabón, la regla que separa una cosa de otra no existe y esta forma no se sostiene.
	if not exists (
		select 1 from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where a.forma_id = v_cancion and s.slug = 'eslabon'
	) then
		raise exception 'La canción no declara eslabón: sin él, esta forma no se distingue de ella.';
	end if;

	-- ------------------------------------------------------------------ La forma
	select forma_id into v_forma from public.formas_metricas where slug = 'decima_lira';
	if v_forma is null then
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, activo, orden, origen_termino_id)
		select 'decima_lira', 'Décima-lira', c_definicion, f.nivel_estructural, true, f.orden,
			v_termino
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
			'Diez versos de siete y once sílabas con rima consonante. La norma no fija la '
			|| 'proporción de cada medida ni el reparto de las rimas; el catálogo recoge la única '
			|| 'disposición de la que hay testimonio, y admite que aparezcan otras.',
			true, true, 'admitida', v_consonante, true, 1, 10, 10
		)
		returning arquitectura_id into v_arq;

		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);

		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values (
			v_arq, 'ababcdcdee', 'Décima-estancia · aBaBcDcDeE', 'ababcdcdee', v_consonante,
			'admitida', 'secuencia',
			'Dos parejas de rima cruzada y un pareado final. En el testimonio que la documenta los '
			|| 'heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo '
			|| 'testimonio y no basta para fijar esa alternancia como norma. Repite la cabeza como '
			|| 'lo haría una fronte y no trae eslabón, que es lo que la deja del lado alirado.'
		)
		returning esquema_rima_id into v_rima;

		-- Opcional a propósito: ofrecer una sola disposición y obligar a elegirla sería obligar a
		-- mentir a quien encuentre otra.
		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
			permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
		)
		values (
			v_arq, 'disposicion_rima', 'rima', 'unidad', 0, 1, true, true, 1, 'opciones', false,
			'Marca la disposición si es la documentada. Si la estrofa rima de otro modo, déjalo en '
			|| 'blanco y anótalo en observaciones: el catálogo solo tiene testimonio de una.'
		);
	end if;

	-- ------------------------------------------------------------------ Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Décima-lira', 'decima_lira', true, null
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'decima_lira'
	);

	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Décima-estancia', 'decima_estancia', false, null
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'decima_estancia'
	);

	-- ------------------------------------------------------------------ Los vínculos
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_novena, 'relacionada_con',
		'Las dos cierran la serie alirada por arriba y ninguna de las dos la documentan las fuentes '
		|| 'del catálogo. Solo las separa la extensión, diez versos frente a nueve; de esta hay '
		|| 'testimonio en el corpus y de aquella no.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_novena)
			or (forma_origen_id = v_novena and forma_destino_id = v_forma)
	);

	if v_cancion is not null then
		insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
		select v_forma, v_cancion, 'relacionada_con',
			'Es la estrofa alirada que más se acerca a una estancia de canción: misma materia, y una '
			|| 'disposición que repite la cabeza como lo haría una fronte partida en dos piedi. Lo '
			|| 'único que las separa es el eslabón, que la canción trae y esta no. De ahí que la '
			|| 'tradición crítica la llame «décima-estancia».'
		where not exists (
			select 1 from public.forma_relaciones
			where (forma_origen_id = v_forma and forma_destino_id = v_cancion)
				or (forma_origen_id = v_cancion and forma_destino_id = v_forma)
		);
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	select unidad_versos_min into v_n from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_n <> 10 then
		raise exception 'La unidad de la décima-lira mide % versos, no diez.', v_n;
	end if;

	-- Su disposición mide diez posiciones: si no, la notación está mal escrita.
	select length(notacion) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 10 then
		raise exception 'La notación de la décima-lira tiene % signos, no diez.', v_n;
	end if;

	-- Y no trae eslabón, que es lo que la hace alirada y no canción: su segunda mitad abre con
	-- una rima nueva y no con la que cerró la primera.
	if exists (
		select 1 from public.esquemas_rima
		where arquitectura_id = v_arq and substr(notacion, 6, 1) = substr(notacion, 4, 1)
	) then
		raise exception 'La disposición de la décima-lira retoma la rima de la cabeza: sería estancia.';
	end if;

	-- La pregunta es opcional y ofrece la única documentada.
	select count(*) into v_n from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id = v_arq;
	if v_n <> 1 then
		raise exception 'La pregunta de la décima-lira ofrece % opciones, y hay una documentada.', v_n;
	end if;

	select selecciones_min into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug = 'disposicion_rima';
	if v_n <> 0 then
		raise exception 'La disposición de la décima-lira es obligatoria, y solo hay una que ofrecer.';
	end if;

	-- La serie alirada queda completa de cuatro a diez.
	select count(*) into v_n from public.formas_metricas
	where activo and slug in ('cuarteto_lira', 'lira', 'sexteto_lira', 'septeto_lira',
		'octava_lira', 'novena_lira', 'decima_lira');
	if v_n <> 7 then
		raise exception 'La serie alirada tiene % formas, no las siete de cuatro a diez.', v_n;
	end if;

	if public.get_forma_metrica_publica('decima_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la décima-lira no responde.';
	end if;
end $$;

commit;
