-- La novena-lira entra por simetría
--
-- Penúltima de la serie alirada, y **la única forma del catálogo que no se apoya en ninguna
-- fuente**. Conviene que eso quede dicho aquí y en su propia definición, no escondido.
--
-- El *Diccionario* acota la serie que documenta: la unidad «oscila entre los cuatro y ocho versos
-- (cuarteto-lira, lira garcilasiana, sexteto-lira, septeto alirado y octava alirada)». La de nueve
-- queda fuera de esa horquilla, ninguna de las seis monografías la registra, y **no se ha
-- encontrado ningún testimonio en el corpus**: no hay secuencia anotada cuya extensión sea múltiplo
-- de nueve entre los pasajes aliterados aparcados.
--
-- Entra por **simetría del sistema**, criterio que el IP aceptó expresamente el 24 de agosto de
-- 2026 para esta serie: una estrofa alirada puede tener cualquier número de versos, y que la
-- tradición no haya bautizado la de nueve no la hace imposible. Es además el criterio que hace útil
-- un catálogo de investigación —si aparece una, habrá dónde ponerla, y será esta base la que la
-- documente en vez de dejarla como «irregular»—.
--
-- Por eso se declara **lo poco que se puede declarar y nada más**:
--
-- - nueve versos por unidad;
-- - la mezcla de siete y once en proporción variable, como en toda la serie;
-- - rima consonante.
--
-- **No se le pone pregunta de disposición de rima**, porque no hay ninguna documentada que ofrecer
-- y una pregunta activa sin opciones es un defecto que el auditor detecta. La disposición se
-- registrará cuando el editor pueda declarar un esquema que el catálogo no tenga, que es el
-- pendiente **B1** y afecta igual a la sextilla y al sexteto. Mientras tanto la forma existe, se
-- puede asignar a una secuencia, y lo que no se puede es decir cómo rimaba.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_lira uuid;
	v_lira_arq uuid;
	v_octava uuid;
	v_consonante uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_termino uuid;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de nueve versos que mezcla endecasílabos y heptasílabos en proporción variable y '
		|| 'rima en consonante, sin que la norma fije cómo se reparten las rimas. Pertenece a la '
		|| 'serie de las estrofas aliradas: tiene la materia de la canción italiana —siete y once '
		|| 'consonantes, repetidos sin cambio de una estrofa a otra— y no se ordena como una '
		|| 'estancia, porque no trae eslabón. A diferencia de las demás de su serie, ninguna de las '
		|| 'fuentes del catálogo la describe ni le da nombre: el Diccionario documenta las aliradas '
		|| 'entre los cuatro y los ocho versos, y esta queda fuera de esa horquilla. Se registra '
		|| 'porque una estrofa alirada admite cualquier extensión y porque el nombre se forma como '
		|| 'los demás de la serie, de modo que un pasaje de nueve versos de siete y once tenga dónde '
		|| 'caer en vez de quedarse sin forma.';
begin
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';
	select arquitectura_id into v_lira_arq from public.arquitecturas_forma
	where forma_id = v_lira and activo limit 1;
	select forma_id into v_octava from public.formas_metricas where slug = 'octava_lira';
	if v_lira_arq is null or v_octava is null then
		raise exception 'Falta la lira o la octava-lira: esta continúa esa serie.';
	end if;

	select tipo_rima_id into v_consonante from public.arquitecturas_forma
	where arquitectura_id = v_lira_arq;
	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select termino_id into v_termino from public.vocabularios
	where termino = 'novena_lira' and categoria = 'estrofa_tipo';
	if v_consonante is null or v_hepta is null or v_endeca is null then
		raise exception 'Falta el régimen consonante, el heptasílabo o el endecasílabo.';
	end if;

	-- ------------------------------------------------------------------ La forma
	select forma_id into v_forma from public.formas_metricas where slug = 'novena_lira';
	if v_forma is null then
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, activo, orden, origen_termino_id)
		select 'novena_lira', 'Novena-lira', c_definicion, f.nivel_estructural, true, f.orden,
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
			'Nueve versos de siete y once sílabas en proporción variable, con rima consonante. La '
			|| 'norma no fija ni cuántos versos son de cada medida ni cómo se reparten las rimas: '
			|| 'de esta forma no se conoce ninguna disposición documentada, de modo que lo único '
			|| 'que declara son la extensión, la materia y el régimen.',
			true, true, 'admitida', v_consonante, true, 1, 9, 9
		)
		returning arquitectura_id into v_arq;

		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);
	end if;

	-- ------------------------------------------------------------------ El vínculo
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_octava, 'relacionada_con',
		'Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho. '
		|| 'La octava tiene disposiciones documentadas y una invariante —cierra en pareado—; de la '
		|| 'novena no se conoce ninguna.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_octava)
			or (forma_origen_id = v_octava and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select unidad_versos_min into v_n from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_n <> 9 then
		raise exception 'La unidad de la novena-lira mide % versos, no nueve.', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_metrico_opciones o
	join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
	where em.arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'La novena-lira ofrece % medidas, no siete y once.', v_n;
	end if;

	-- Lo que esta migración NO debe haber creado: una pregunta sin nada que ofrecer.
	select count(*) into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and activo;
	if v_n <> 0 then
		raise exception 'La novena-lira ha entrado con % preguntas, y no debía traer ninguna.', v_n;
	end if;

	-- Y la garantía general del catálogo sigue en pie tras añadirla.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.activo and a.activo and f.activo and g.tipo_control = 'opciones'
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		);
	if v_n <> 0 then
		raise exception 'Hay % preguntas activas sin ninguna opción.', v_n;
	end if;

	if public.get_forma_metrica_publica('novena_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la novena-lira no responde.';
	end if;
end $$;

commit;
