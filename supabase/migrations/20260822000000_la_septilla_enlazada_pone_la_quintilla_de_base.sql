-- La septilla enlazada pone la quintilla de base
--
-- Última de las cinco, y tercera de las estrofas enlazadas de Navarro Tomás § 131. Es la hermana
-- mayor de la sextilla enlazada, y él las compara pieza a pieza:
--
-- > «Con análoga técnica, la septilla enlazada rima su primer verso con el último de la estrofa
-- > anterior, y hace que el segundo, quebrado, sea consonante del siguiente, **el cual por su parte
-- > forma una quintilla regular con los cuatro restantes**. […] La base de la estrofa está
-- > constituida en este caso por la quintilla, **en lugar de la redondilla que sirve de fondo a la
-- > sextilla de su misma especie**. **Los dos versos de enlace son análogos en una y otra.**»
--
-- De ahí sus tres partes, que son las dos de la sextilla enlazada más un verso en la base: el
-- **verso de enlace**, que recoge la rima con que terminó la estrofa anterior; el **quebrado**, que
-- estrena la clase; y la **quintilla**, que empieza por esa misma clase y la devuelve al final para
-- que la recoja la estrofa siguiente. La composición arranca con una quintilla suelta que da la
-- rima al primer enlace: `abaab-bccdccd-defeef…`.
--
-- **Y también es teatro.** «Figura la septilla enlazada en varias de las poesías llamadas capítulos
-- y lamentaciones de amor en la *Propalladia* de Torres Naharro y **en los entremeses de Sebastián
-- de Horozco**.»

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_quintilla uuid;
	v_quintilla_arq uuid;
	v_septilla uuid;
	v_sextilla_enl uuid;
	v_redondilla_enl uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_espanola uuid := 'bf56b9c7-1261-41db-8a0c-d82529f88dd3';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_octosilabo uuid := '82bd7a89-675e-41a9-9324-538589731000';
	v_tetrasilabo uuid := 'b7d3c277-feaf-4f2f-905a-cfddc45773c4';
	v_rasgo_quebrado uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Serie de estrofas de siete versos octosílabos, con el segundo quebrado, en que **la rima '
		|| 'pasa de una estrofa a la siguiente**. Los dos primeros versos hacen el enlace: el '
		|| 'primero recoge la rima con que terminó la estrofa anterior, y el segundo, quebrado, '
		|| 'estrena la clase que sostendrá esta. Los cinco restantes forman una quintilla regular '
		|| 'que abre con esa misma clase y la devuelve en su último verso, de donde la tomará la '
		|| 'estrofa que viene. Es la sextilla enlazada con un verso más: los dos versos de enlace '
		|| 'son los mismos, y lo que cambia es la base, quintilla aquí y redondilla allí. La '
		|| 'composición arranca con una quintilla suelta que da la rima al primer enlace. Se '
		|| 'documenta en el teatro primitivo y en la poesía de cancionero.';
begin
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_septilla from public.formas_metricas where slug = 'septilla';
	select forma_id into v_sextilla_enl from public.formas_metricas where slug = 'sextilla_enlazada';
	select forma_id into v_redondilla_enl from public.formas_metricas where slug = 'redondilla_enlazada';
	select arquitectura_id into v_quintilla_arq from public.arquitecturas_forma
	where forma_id = v_quintilla and slug = 'octosilabica_consonante';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';
	if v_quintilla_arq is null or v_septilla is null or v_sextilla_enl is null
		or v_redondilla_enl is null
	then
		raise exception 'Falta la quintilla, la septilla o alguna de las dos enlazadas anteriores.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'septilla_enlazada') then
		select forma_id into v_forma from public.formas_metricas where slug = 'septilla_enlazada';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('septilla_enlazada', 'Septilla enlazada', c_definicion, 'serie', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica_con_quebrado';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'octosilabica_con_quebrado', 'Octosilábica con quebrado',
			'Dos versos de enlace —un octosílabo y un quebrado— y, detrás, una quintilla regular. El '
			|| 'octosílabo no rima dentro de la estrofa: rima con el último verso de la anterior. Y '
			|| 'el último de la quintilla no cierra nada: abre la clase que recogerá la siguiente.',
			true, true, 'habitual', v_consonante, true, 1, 7, 7)
		returning arquitectura_id into v_arq;
	end if;

	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq;
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq, 'secuencia', '8-4-8-8-8-8-8')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, x.posicion, x.metro, 1
		from (values (1, v_octosilabo), (2, v_tetrasilabo), (3, v_octosilabo), (4, v_octosilabo),
			(5, v_octosilabo), (6, v_octosilabo), (7, v_octosilabo)) as x(posicion, metro);
	end if;

	select esquema_rima_id into v_esquema from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'enlazada';
	if v_esquema is null then
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values (v_arq, 'enlazada', 'Enlazada por los dos primeros versos', '[abbcbbc]…',
			v_consonante, 'definitoria', 'ciclo',
			'La primera clase aparece una sola vez y no queda suelta: es la rima con que terminó la '
			|| 'estrofa anterior. La segunda vuelve cuatro veces —el quebrado y tres versos de la '
			|| 'quintilla— y es la que sostiene la estrofa; la tercera cierra, y es la que se pasa '
			|| 'a la siguiente.')
		returning esquema_rima_id into v_esquema;

		insert into public.esquema_rima_posiciones
			(esquema_rima_id, bloque, posicion, clase_rima, nota)
		values
			(v_esquema, 1, 1, 'a', 'Recoge la rima con que terminó la estrofa anterior.'),
			(v_esquema, 1, 2, 'b', 'Quebrado: estrena la clase con que abre la quintilla.'),
			(v_esquema, 1, 3, 'b', null),
			(v_esquema, 1, 4, 'c', null),
			(v_esquema, 1, 5, 'b', null),
			(v_esquema, 1, 6, 'b', null),
			(v_esquema, 1, 7, 'c', 'Cierra la quintilla, y su rima abrirá la estrofa siguiente.');
	end if;

	-- Las tres partes
	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id, nota
	)
	select v_arq, x.tipo, x.slug, x.nombre, x.orden, 1, 1, x.versos, x.versos, x.ref, x.nota
	from (values
		('enlace', 'enlace', 'Verso de enlace', 1, 1, null::uuid,
			'Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la '
			|| 'anterior. En la primera estrofa de la composición, la que le da la rima es una '
			|| 'quintilla suelta que sirve de arranque.'),
		('quebrado', 'quebrado', 'Quebrado', 2, 1, null::uuid,
			'El segundo verso de enlace, más breve, que estrena la clase de rima con la que abre '
			|| 'la quintilla. Es análogo al de la sextilla enlazada.'),
		('quintilla', 'quintilla', 'Quintilla', 3, 5, v_quintilla_arq,
			'La base de la estrofa, donde la sextilla enlazada tiene una redondilla. Abre con la '
			|| 'clase del quebrado y cierra con la que pasará a la estrofa siguiente.')
	) as x(tipo, slug, nombre, orden, versos, ref, nota)
	where not exists (
		select 1 from public.estructuras_secciones s
		where s.arquitectura_id = v_arq and s.slug = x.slug
	);

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, posiciones_max, nota)
	select v_arq, v_rasgo_quebrado, 'definitoria', 1,
		'El segundo verso es quebrado, y es el segundo de los dos versos de enlace: los mismos que '
		|| 'la sextilla enlazada antepone a su base.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§ 131',
			'Es la única fuente que la describe. La presenta como la hermana de la sextilla '
			|| 'enlazada: «con análoga técnica, la septilla enlazada rima su primer verso con el '
			|| 'último de la estrofa anterior, y hace que el segundo, quebrado, sea consonante del '
			|| 'siguiente, el cual por su parte forma una quintilla regular con los cuatro '
			|| 'restantes», y la composición «principia con una quintilla que sirve de punto de '
			|| 'partida al primer enlace»: `abaab-bccdccd-defeef`. Precisa la diferencia entre las '
			|| 'dos: «la base de la estrofa está constituida en este caso por la quintilla, en lugar '
			|| 'de la redondilla que sirve de fondo a la sextilla de su misma especie. **Los dos '
			|| 'versos de enlace son análogos en una y otra**». **La documenta en el teatro**: '
			|| '«figura la septilla enlazada en varias de las poesías llamadas capítulos y '
			|| 'lamentaciones de amor en la *Propalladia* de Torres Naharro y en los entremeses de '
			|| 'Sebastián de Horozco». Y en su recorrido del período: «el teatro dio preferencia a '
			|| 'las estrofas octosílabas enlazadas de seis y siete versos».'],
		array[v_dc16::text, 's. v. «séptima» y «copla encadenada»',
			'No la registra. Sus estrofas de siete versos son cerradas, y su repertorio de enlaces '
			|| 'entre estrofas es el de la gaya ciencia —la copla encadenada, con lexaprén—, que '
			|| 'Navarro Tomás distingue expresamente de estas series.'],
		array[v_dc14::text, 'Índice de estrofas',
			'No la registra. Al tratar las estrofas de siete versos no contempla que la rima pase de '
			|| 'una a la siguiente.'],
		array[v_quilis::text, '§ 5.4.6',
			'No la registra. Sus estrofas de siete versos son la séptima de arte mayor y la '
			|| 'seguidilla compuesta, las dos cerradas sobre sí mismas.'],
		array[v_jauralde::text, 'Apartado «Estrofas de siete versos»',
			'No la registra con nombre ni epígrafe propio: sus septillas y septetos se organizan '
			|| 'en cuatro y tres, sin enlace con las estrofas vecinas.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»',
			'No la distinguen. Sus «coplas de pie quebrado» abarcan por extensión, de cinco a doce '
			|| 'versos, sin atender a si la rima enlaza una estrofa con la siguiente, y su corpus es '
			|| 'Lope, posterior al de los entremeses donde esta serie se documenta.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ Los vínculos
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, x.destino, x.tipo, x.nota
	from (values
		(v_quintilla, 'compuesta_por',
			'Cinco de sus siete versos son una quintilla regular, que abre con la clase del quebrado '
			|| 'y cierra con la que pasa a la estrofa siguiente. Es la base de la estrofa, donde la '
			|| 'sextilla enlazada tiene una redondilla.'),
		(v_sextilla_enl, 'relacionada_con',
			'Son la misma técnica en dos extensiones: los dos versos de enlace son idénticos —un '
			|| 'octosílabo que recoge la rima anterior y un quebrado que estrena la suya— y lo que '
			|| 'cambia es la base, redondilla en la de seis y quintilla en la de siete.'),
		(v_septilla, 'contrasta_con',
			'Las dos miden siete octosílabos, y se separan por si la estrofa se cierra: la septilla '
			|| 'reparte sus versos en redondilla y terceto y agota sus rimas dentro de sí; la '
			|| 'enlazada deja abiertas la primera y la última, que la atan a las estrofas vecinas.')
	) as x(destino, tipo, nota)
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = x.destino)
			or (forma_origen_id = x.destino and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	if not exists (
		select 1 from public.formas_metricas
		where forma_id = v_forma and nivel_estructural = 'serie'
	) then
		raise exception 'La septilla enlazada no ha quedado registrada como serie.';
	end if;

	select count(*) into v_n from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;
	if v_n <> 7 then
		raise exception 'La disposición dibuja % posiciones, no las siete.', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_posiciones where esquema_rima_id = v_esquema and clase_rima = 'a';
	if v_n <> 1 then
		raise exception 'La clase del verso de enlace aparece % veces dentro de la estrofa.', v_n;
	end if;

	-- Los cinco últimos versos son una quintilla regular: dos clases, sin ningún verso suelto.
	select count(distinct clase_rima) into v_n
	from public.esquema_rima_posiciones
	where esquema_rima_id = v_esquema and posicion between 3 and 7;
	if v_n <> 2 then
		raise exception 'La base de la estrofa reparte % clases, y una quintilla lleva dos.', v_n;
	end if;

	select count(*) into v_n
	from public.estructuras_secciones where arquitectura_id = v_arq;
	if v_n <> 3 then
		raise exception 'La septilla enlazada tiene % partes, no las tres.', v_n;
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La septilla enlazada cita % fuentes, no las seis.', v_n;
	end if;

	-- Las tres enlazadas se reconocen entre sí.
	foreach v_fila slice 1 in array array[
		array['redondilla_enlazada'], array['sextilla_enlazada'], array['septilla_enlazada']
	] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_fila[1]) -> 'relaciones'
			) r
			where r ->> 'tipo_relacion' = 'relacionada_con'
		) then
			raise exception 'La ficha de % no recoge su vínculo con las otras enlazadas.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
