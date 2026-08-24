-- La octava alirada cierra siempre en pareado
--
-- Segunda de las formas aliradas que faltaban, y la que cierra la serie que el *Diccionario*
-- documenta: «la unidad estrófica oscila entre los cuatro y ocho versos (cuarteto-lira, lira
-- garcilasiana, sexteto-lira, septeto alirado y **octava alirada**)». Con esta, el catálogo tiene
-- las cinco.
--
-- Tiene entrada propia, y la entrada fija una invariante:
--
-- > «octava alirada (Navarro Tomás). Estrofa formada por ocho versos, endecasílabos y
-- > heptasílabos, con **cuatro rimas consonantes** que presentan distintas disposiciones, pero que
-- > **terminan siempre en un pareado**.»
--
-- Navarro Tomás, en el § 229, la enuncia además con el criterio que el IP propone para toda la
-- serie, y lo dice antes que nosotros:
--
-- > «Ciertas combinaciones de ocho versos **con aspecto de estancias** pueden más bien considerarse
-- > como octavas aliradas. Ejemplo de esta clase es la estrofa ABAbCcDD, usada por Fray Diego Tadeo
-- > González en *El murciélago alevoso*, y por Arriaza en *Contra la seducción*. El esquema
-- > ABcaBCdD [es] de la oda de Lista.»
--
-- Sus dos esquemas entran como disposiciones documentadas —`ababccdd` y `abcabcdd`—, y los dos
-- confirman lo que dice la entrada: cuatro rimas y pareado final.
--
-- *Lo que no queda modelado:* que el pareado final sea **invariante** está dicho en la descripción
-- y en la afirmación, no en la estructura. Declararlo como sección obligatoria sobre una
-- disposición que la norma deja abierta es el mismo problema que B1 tiene pendiente en la sextilla
-- y en el sexteto —dónde registrar la disposición que se ve cuando la norma no la fija—, y se
-- resolverá de una vez para todo el catálogo, no aquí a medias.
--
-- La usa una secuencia real: *La gran Semíramis*, vv. 564-690. **Mide 127 versos, que no es
-- múltiplo de ocho**, así que la propuesta de migración la marcará para revisar. Es lo que se
-- quiere: que salte.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_lira uuid;
	v_lira_arq uuid;
	v_cuarteto uuid;
	v_consonante uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_termino uuid;
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_n integer;
	v_notaciones text;

	c_definicion constant text :=
		'Estrofa de ocho versos que mezcla endecasílabos y heptasílabos y reparte cuatro rimas '
		|| 'consonantes en disposiciones variables, con una condición que no falla: los dos últimos '
		|| 'versos forman pareado. Es la mayor de las estrofas aliradas y la que más fácilmente se '
		|| 'confunde con una estancia de canción, porque tiene su misma materia; lo que la separa es '
		|| 'que prescinde de la ordenación en fronte y sirima, de modo que el pasaje repite ocho '
		|| 'versos iguales en vez de articularlos en piedi y remate.';
begin
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';
	select arquitectura_id into v_lira_arq from public.arquitecturas_forma
	where forma_id = v_lira and activo limit 1;
	select forma_id into v_cuarteto from public.formas_metricas where slug = 'cuarteto_lira';
	if v_lira_arq is null or v_cuarteto is null then
		raise exception 'Falta la lira o el cuarteto-lira: esta forma cierra esa serie.';
	end if;

	select tipo_rima_id into v_consonante from public.arquitecturas_forma
	where arquitectura_id = v_lira_arq;
	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select termino_id into v_termino from public.vocabularios
	where termino = 'octava_lira' and categoria = 'estrofa_tipo';
	if v_consonante is null or v_hepta is null or v_endeca is null then
		raise exception 'Falta el régimen consonante, el heptasílabo o el endecasílabo.';
	end if;

	-- ------------------------------------------------------------------ La forma
	select forma_id into v_forma from public.formas_metricas where slug = 'octava_lira';
	if v_forma is null then
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, activo, orden, origen_termino_id)
		select 'octava_lira', 'Octava-lira', c_definicion, f.nivel_estructural, true, f.orden,
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
			'Ocho versos de siete y once sílabas en proporción variable, con cuatro rimas '
			|| 'consonantes. La norma no fija cómo se reparten esas cuatro rimas por los seis '
			|| 'primeros versos —de ahí que la tradición documente disposiciones distintas—, pero sí '
			|| 'que los dos últimos rimen entre sí.',
			true, true, 'habitual', v_consonante, true, 1, 8, 8
		)
		returning arquitectura_id into v_arq;

		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);

		-- Las dos disposiciones que documenta Navarro Tomás
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values
			(v_arq, 'ababccdd', 'Cruzada con pareados · ababccdd', 'ababccdd', v_consonante,
				'admitida', 'secuencia',
				'Cruza las dos primeras rimas y cierra con dos pareados. Es la que Navarro Tomás '
				|| 'documenta en Fray Diego Tadeo González y en Arriaza.'),
			(v_arq, 'abcabcdd', 'Con seis versos enlazados · abcabcdd', 'abcabcdd', v_consonante,
				'admitida', 'secuencia',
				'Tres rimas que se enlazan a lo largo de los seis primeros versos, y el pareado que '
				|| 'cierra. Es la de la oda de Lista.');

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
			permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
		)
		values (
			v_arq, 'disposicion_rima', 'rima', 'unidad', 1, 1, true, true, 1, 'opciones', false,
			'Marca cómo se reparten las cuatro rimas en cada estrofa. Las dos que se ofrecen son las '
			|| 'documentadas; la norma admite otras.'
		);
	end if;

	-- ------------------------------------------------------------------ Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Octava-lira', 'octava_lira', true, null
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'octava_lira'
	);

	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Octava alirada', 'octava_alirada', false, v_navarro
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'octava_alirada'
	);

	-- ------------------------------------------------------------------ Lo que dicen las fuentes
	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	select v_dc16, v_forma, 's. v. «octava alirada»',
		'La atribuye a Navarro Tomás y la define como estrofa de ocho versos, endecasílabos y '
		|| 'heptasílabos, con cuatro rimas consonantes que presentan distintas disposiciones, pero '
		|| 'que terminan siempre en un pareado.',
		'alta'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_dc16 and localizador = 's. v. «octava alirada»'
	);

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	select v_navarro, v_forma, '§ 229, «Estrofas aliradas»',
		'Sostiene que ciertas combinaciones de ocho versos «con aspecto de estancias» deben '
		|| 'considerarse más bien octavas aliradas, y documenta dos: ABAbCcDD, en Fray Diego Tadeo '
		|| 'González y en Arriaza, y ABcaBCdD, en la oda de Lista. Es el criterio que separa la '
		|| 'estrofa alirada de la estancia de canción, enunciado sobre la forma que más se presta a '
		|| 'confundirlas.',
		'alta'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_navarro
	);

	-- ------------------------------------------------------------------ Los vínculos
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_lira, 'relacionada_con',
		'Las dos son estrofas aliradas: misma mezcla de siete y once, misma rima consonante y misma '
		|| 'repetición sin cambio. Lo único que las separa es la extensión, ocho versos frente a '
		|| 'cinco. Y las dos comparten el cierre en pareado, que Jauralde da por seña de identidad '
		|| 'de la lira y el Diccionario por invariante de la octava.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_lira)
			or (forma_origen_id = v_lira and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 1 then
		raise exception 'La octava-lira tiene % arquitecturas, no una.', v_n;
	end if;

	select unidad_versos_min into v_n from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_n <> 8 then
		raise exception 'La unidad de la octava-lira mide % versos, no ocho.', v_n;
	end if;

	-- Las dos disposiciones documentadas, y las dos acaban en pareado, que es la invariante.
	select string_agg(notacion, ' y ' order by notacion) into v_notaciones
	from public.esquemas_rima where arquitectura_id = v_arq;
	if v_notaciones is distinct from 'ababccdd y abcabcdd' then
		raise exception 'Las disposiciones de la octava-lira son «%».', v_notaciones;
	end if;

	select count(*) into v_n from public.esquemas_rima
	where arquitectura_id = v_arq and right(notacion, 2) not in ('dd', 'cc', 'bb', 'aa');
	if v_n <> 0 then
		raise exception '% disposiciones de la octava-lira no acaban en pareado.', v_n;
	end if;

	-- Y las cuatro rimas que la entrada le atribuye.
	select count(*) into v_n from public.esquemas_rima er
	where er.arquitectura_id = v_arq
		and (select count(distinct c) from unnest(string_to_array(er.notacion, null)) c) <> 4;
	if v_n <> 0 then
		raise exception '% disposiciones de la octava-lira no reparten cuatro rimas.', v_n;
	end if;

	-- La serie alirada queda completa entre cuatro y ocho, salvo la de nueve y la de diez.
	select count(*) into v_n from public.formas_metricas
	where activo and slug in ('cuarteto_lira', 'lira', 'sexteto_lira', 'septeto_lira', 'octava_lira');
	if v_n <> 5 then
		raise exception 'La serie alirada tiene % formas, no las cinco documentadas.', v_n;
	end if;

	if public.get_forma_metrica_publica('octava_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la octava-lira no responde.';
	end if;
end $$;

commit;
