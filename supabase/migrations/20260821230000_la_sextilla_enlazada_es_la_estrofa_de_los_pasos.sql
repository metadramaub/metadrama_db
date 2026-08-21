-- La sextilla enlazada es la estrofa de los pasos
--
-- Cuarta de las cinco, y **la que más importa a este catálogo**. Navarro Tomás § 131 la documenta
-- donde el proyecto trabaja:
--
-- > «Se encuentra la sextilla enlazada en **la mayor parte de los pasos y entremeses comprendidos
-- > en la *Turiana*, de Timoneda**, y en la epístola cuarta de la *Propalladia*, de Torres Naharro.
-- > Es asimismo la estrofa en que aparecen compuestas la farsa del Sacramento, la del Pueblo gentil
-- > y la de Moselina y el auto de *La muerte de Abel*.»
--
-- Y en su recorrido del período: **«el teatro dio preferencia a las estrofas octosílabas enlazadas
-- de seis y siete versos»**.
--
-- Su mecánica, dicha por él verso a verso: «el primer octosílabo de cada estrofa recoge la rima
-- final de la estrofa anterior; el segundo es un pie quebrado con otra rima que se repite en el
-- tercer verso; los versos cuarto y quinto forman entre sí un pareado; el sexto se une a la
-- consonancia del segundo y tercero». Y la lectura que la resume: «se trata de **la quintilla con
-- quebrado inicial de Castillejo a la cual se antepone un octosílabo** rimado con el último verso
-- de la estrofa precedente». La composición arranca con una redondilla suelta, que da la rima
-- inicial a la primera sextilla.
--
-- De ahí sus dos partes: un **verso de enlace** y una **quintilla** que reutiliza la del catálogo.
-- La quintilla lleva aquí su primer verso quebrado, que es la realización que Navarro atribuye a
-- Castillejo y llama «la estrofa más usada» por él. *El catálogo no declara hoy el quiebro en la
-- quintilla suelta —lo declara en la copla real, como una de sus dos mitades—; aquí se declara en
-- esta arquitectura, y la cuestión de si la quintilla debe admitirlo por su cuenta queda anotada
-- en pendientes.*

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_quintilla uuid;
	v_quintilla_arq uuid;
	v_sextilla uuid;
	v_hermana uuid;
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
		'Serie de estrofas de seis versos octosílabos, con el segundo quebrado, en que **la rima '
		|| 'pasa de una estrofa a la siguiente**: el primer verso recoge la rima con que terminó la '
		|| 'anterior, y los cinco restantes forman una quintilla cuyo primer verso es el quebrado. '
		|| 'Dentro de la estrofa, el quebrado y el tercer verso riman entre sí, el cuarto y el '
		|| 'quinto forman pareado, y el sexto vuelve a la rima del quebrado, quedando así abierta '
		|| 'la clase que abrirá la estrofa siguiente. La composición arranca con una redondilla '
		|| 'suelta que da la rima inicial. Es la estrofa que el teatro prefirió en su momento: '
		|| 'Timoneda la emplea en la mayor parte de los pasos y entremeses de la *Turiana*, y en '
		|| 'ella están compuestas varias farsas y autos del repertorio primitivo.';
begin
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';
	select forma_id into v_hermana from public.formas_metricas where slug = 'redondilla_enlazada';
	select arquitectura_id into v_quintilla_arq from public.arquitecturas_forma
	where forma_id = v_quintilla and slug = 'octosilabica_consonante';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';
	if v_quintilla_arq is null or v_sextilla is null or v_hermana is null then
		raise exception 'Falta la quintilla octosilábica, la sextilla o la redondilla enlazada.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'sextilla_enlazada') then
		select forma_id into v_forma from public.formas_metricas where slug = 'sextilla_enlazada';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('sextilla_enlazada', 'Sextilla enlazada', c_definicion, 'serie', 'forma', true)
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
			'Un octosílabo de enlace y, detrás, una quintilla con su primer verso quebrado. El '
			|| 'octosílabo de enlace no rima dentro de la estrofa: rima con el último verso de la '
			|| 'anterior. Y el último verso no cierra nada: abre la clase que recogerá la siguiente.',
			true, true, 'habitual', v_consonante, true, 1, 6, 6)
		returning arquitectura_id into v_arq;
	end if;

	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq;
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq, 'secuencia', '8-4-8-8-8-8')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, x.posicion, x.metro, 1
		from (values (1, v_octosilabo), (2, v_tetrasilabo), (3, v_octosilabo),
			(4, v_octosilabo), (5, v_octosilabo), (6, v_octosilabo)) as x(posicion, metro);
	end if;

	select esquema_rima_id into v_esquema from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'enlazada';
	if v_esquema is null then
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values (v_arq, 'enlazada', 'Enlazada por el primer verso', '[abbccb]…', v_consonante,
			'definitoria', 'ciclo',
			'La primera clase aparece una sola vez dentro de la estrofa y no queda suelta: es la '
			|| 'rima con que terminó la anterior. La segunda vuelve tres veces —quebrado, tercer '
			|| 'verso y sexto— y es la que se pasa a la estrofa siguiente.')
		returning esquema_rima_id into v_esquema;

		insert into public.esquema_rima_posiciones
			(esquema_rima_id, bloque, posicion, clase_rima, nota)
		values
			(v_esquema, 1, 1, 'a', 'Recoge la rima con que terminó la estrofa anterior.'),
			(v_esquema, 1, 2, 'b', 'Quebrado: abre la clase que sostiene la estrofa.'),
			(v_esquema, 1, 3, 'b', null),
			(v_esquema, 1, 4, 'c', null),
			(v_esquema, 1, 5, 'c', null),
			(v_esquema, 1, 6, 'b', 'Cierra con la clase del quebrado, que abrirá la estrofa siguiente.');
	end if;

	-- Las dos partes: el enlace y la quintilla que reutiliza la del catálogo
	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id, nota
	)
	select v_arq, 'enlace', 'enlace', 'Verso de enlace', 1, 1, 1, 1, 1, null,
		'Un octosílabo que no rima con ninguno de su estrofa: recoge la rima final de la anterior. '
		|| 'En la primera estrofa de la composición, la que le da la rima es una redondilla suelta '
		|| 'que sirve de arranque.'
	where not exists (
		select 1 from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'enlace'
	);

	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id, nota
	)
	select v_arq, 'quintilla', 'quintilla', 'Quintilla', 2, 1, 1, 5, 5, v_quintilla_arq,
		'Es la quintilla con quebrado inicial que la tradición atribuye a Castillejo, aquí con el '
		|| 'octosílabo de enlace antepuesto.'
	where not exists (
		select 1 from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'quintilla'
	);

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, posiciones_max, nota)
	select v_arq, v_rasgo_quebrado, 'definitoria', 1,
		'El segundo verso es quebrado, y es el primero de la quintilla: es la disposición que la '
		|| 'tradición atribuye a Castillejo.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§ 131',
			'Es la única fuente que la describe, y la describe verso a verso: «el primer octosílabo '
			|| 'de cada estrofa recoge la rima final de la estrofa anterior; el segundo es un pie '
			|| 'quebrado con otra rima que se repite en el tercer verso; los versos cuarto y quinto '
			|| 'forman entre sí un pareado; el sexto se une a la consonancia del segundo y tercero», '
			|| 'y la composición «empieza con una redondilla de la cual arranca la rima inicial de '
			|| 'la primera sextilla». La resume así: «se trata de la quintilla con quebrado inicial '
			|| 'de Castillejo a la cual se antepone un octosílabo rimado con el último verso de la '
			|| 'estrofa precedente». **La documenta en el teatro**: «se encuentra la sextilla '
			|| 'enlazada en la mayor parte de los pasos y entremeses comprendidos en la *Turiana*, '
			|| 'de Timoneda, y en la epístola cuarta de la *Propalladia*, de Torres Naharro. Es '
			|| 'asimismo la estrofa en que aparecen compuestas la farsa del Sacramento, la del '
			|| 'Pueblo gentil y la de Moselina y el auto de *La muerte de Abel*». Y en su recorrido '
			|| 'del período lo generaliza: «el teatro dio preferencia a las estrofas octosílabas '
			|| 'enlazadas de seis y siete versos».'],
		array[v_dc16::text, 's. v. «sextilla» y «copla encadenada»',
			'No la registra. Describe la sextilla como estrofa cerrada sobre sí misma, y su '
			|| 'repertorio de enlaces entre estrofas es el de la gaya ciencia —la copla encadenada, '
			|| 'con lexaprén—, que Navarro Tomás distingue expresamente de estas series.'],
		array[v_dc14::text, 'Índice de estrofas',
			'No la registra. Su recorrido de las estrofas de seis versos no contempla que la rima '
			|| 'pase de una a la siguiente.'],
		array[v_quilis::text, '§ 5.4.5.4',
			'No la registra. Describe la sextilla y la copla de pie quebrado como estrofas cerradas, '
			|| 'sin enlace con las vecinas.'],
		array[v_jauralde::text, 'Apartado «Estrofas de seis versos»',
			'No la registra con nombre ni epígrafe propio.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»',
			'No la distinguen. Sus «coplas de pie quebrado» son octosílabos combinados con su '
			|| 'quebrado «en estrofas (en Lope) de cinco a doce versos», sin atender a si la rima '
			|| 'enlaza una estrofa con la siguiente. Su corpus es Lope, posterior al de los pasos y '
			|| 'entremeses donde esta serie se documenta.']
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
			'Cinco de sus seis versos son una quintilla, la de quebrado inicial que la tradición '
			|| 'atribuye a Castillejo. Lo que la sextilla enlazada añade es el octosílabo de delante, '
			|| 'que no rima dentro de la estrofa sino con la anterior.'),
		(v_sextilla, 'relacionada_con',
			'Mide seis versos octosílabos con quebrado, como la sextilla de pie quebrado, y no es '
			|| 'una sextilla: la sextilla cierra sus clases dentro de sí, y esta deja la primera y '
			|| 'la última atadas a las estrofas vecinas.'),
		(v_hermana, 'relacionada_con',
			'Son dos de las tres estrofas enlazadas, y se separan por dónde cae el quebrado y qué '
			|| 'papel hace: en la redondilla enlazada es el último verso y pasa la rima hacia '
			|| 'delante; aquí es el segundo, y lo que enlaza con la estrofa anterior es el primero.')
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
		raise exception 'La sextilla enlazada no ha quedado registrada como serie.';
	end if;

	select count(*) into v_n from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;
	if v_n <> 6 then
		raise exception 'La disposición dibuja % posiciones, no las seis.', v_n;
	end if;

	-- El primer verso aparece una sola vez: es el enlace, y por eso la forma es serie.
	select count(*) into v_n
	from public.esquema_rima_posiciones
	where esquema_rima_id = v_esquema and clase_rima = 'a';
	if v_n <> 1 then
		raise exception 'La clase del verso de enlace aparece % veces dentro de la estrofa.', v_n;
	end if;

	-- Y el último comparte clase con el quebrado, que es lo que pasa la rima adelante.
	if (select clase_rima from public.esquema_rima_posiciones
			where esquema_rima_id = v_esquema and posicion = 6)
		is distinct from
		(select clase_rima from public.esquema_rima_posiciones
			where esquema_rima_id = v_esquema and posicion = 2)
	then
		raise exception 'El último verso no vuelve a la rima del quebrado.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La sextilla enlazada cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('sextilla_enlazada') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la sextilla enlazada no responde.';
	end if;
end $$;

commit;
