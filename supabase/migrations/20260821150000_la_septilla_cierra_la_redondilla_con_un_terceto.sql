-- La septilla cierra la redondilla con un terceto
--
-- Cuarta de las seis, y **no estaba en el pendiente**: apareció al leer las fuentes. El hueco de
-- las estrofas de siete versos es tan real como el de las de ocho, y lo tapaba lo mismo — la copla
-- de pie quebrado, que cubría de cinco a doce.
--
-- Navarro § 67: «**Septilla, 4-3**: consta de una redondilla seguida por un terceto que enlaza
-- alguno de sus versos con una de las rimas anteriores». Da `abba:cca` en Villasandino y en el
-- *Planto de la reina doña Margarita* de Santillana, `abba:ccb` en Pérez de Guzmán, `abab:cbc` en
-- Macías, y `abab:abb` y `abab:ccb` en las serranas del Arcipreste de Hita. Caparrós la recoge como
-- la copla de arte menor de siete versos y advierte que «la forma de siete versos es llamada por
-- algunos copla mixta»; Jauralde la llama así sin reservas —«la copla mixta (de siete)»— y da un
-- ejemplo áureo, de **Baltasar del Alcázar, con el quinto verso quebrado**.
--
-- **«Copla mixta» va aquí como denominación y no como forma.** En Navarro es el rótulo de un
-- grupo —septilla 4-3, novena 4-5, oncena 5-6 y doble sextilla—, y el *Diccionario* lo estira a
-- «desde siete hasta doce versos». Una forma de rango repetiría exactamente el error de la copla de
-- pie quebrado: mientras una forma general cubre el intervalo, las estrofas reales que hay dentro
-- no se echan de menos. Las dos fuentes recientes, además, reservan el término para la de siete.
--
-- *Dos cosas que salieron leyendo y que no se tocan aquí, anotadas en pendientes para que no se
-- pierdan:* Quilis § 5.4.6.1 describe una **séptima de arte mayor** de rima libre, con la sola
-- condición de que no vayan tres versos seguidos con la misma rima, que es otra estructura; y
-- Navarro § 131 describe una **septilla enlazada**, serie encadenada sobre base de quintilla, que
-- documenta en la *Propalladia* de Torres Naharro y en los entremeses de Sebastián de Horozco —es
-- decir, **en el teatro áureo**—.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_redondilla uuid;
	v_redondilla_octo uuid;
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
		'Estrofa de siete versos octosílabos en dos miembros desiguales: una redondilla y, detrás, '
		|| 'un terceto que **enlaza al menos uno de sus versos con una rima de la redondilla**. Ese '
		|| 'enlace es lo que la hace estrofa y no una redondilla seguida de un terceto suelto, y '
		|| 'admite varias soluciones: el terceto puede cerrar con la rima que abrió la redondilla, '
		|| 'recoger la interior, o alternar con las dos. Lleva dos o tres clases de rima consonante '
		|| 'y admite algún verso quebrado en cuatro sílabas. Es forma medieval que llega al Siglo '
		|| 'de Oro, y la más breve de las estrofas que reparten sus versos en dos miembros de '
		|| 'distinta extensión, delante de la novena y la oncena.';

	c_descripcion constant text :=
		'Siete octosílabos, cuatro y tres. La redondilla se dispone abrazada o cruzada; el terceto '
		|| 'que la sigue trae al menos una rima de ella. El quiebro, cuando lo hay, es tetrasílabo.';
begin
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select arquitectura_id into v_redondilla_octo from public.arquitecturas_forma
	where forma_id = v_redondilla and slug = 'octosilabica';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';
	if v_redondilla_octo is null or v_rasgo_quebrado is null then
		raise exception 'Falta la redondilla octosilábica o el rasgo del quiebro.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'septilla') then
		select forma_id into v_forma from public.formas_metricas where slug = 'septilla';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('septilla', 'Septilla', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'octosilabica', 'Octosilábica', c_descripcion, true, true, 'habitual',
			v_consonante, true, 1, 7, 7)
		returning arquitectura_id into v_arq;
	else
		update public.arquitecturas_forma set descripcion = c_descripcion where arquitectura_id = v_arq;
	end if;

	-- --------------------------------------------------------------- La medida y el quiebro
	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq and slug = '8-repetido';
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'ciclo', '8-repetido', false)
		returning esquema_metrico_id into v_metrico;
	end if;

	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	select v_metrico, 1, v_octosilabo, 1
	where not exists (
		select 1 from public.esquema_metrico_posiciones where esquema_metrico_id = v_metrico
	);

	insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden, rol)
	select v_metrico, x.metro_id, x.orden, x.rol
	from (values (v_octosilabo, 1, 'dominante'), (v_tetrasilabo, 2, 'quebrado')) as x(metro_id, orden, rol)
	where not exists (
		select 1 from public.esquema_metrico_opciones o
		where o.esquema_metrico_id = v_metrico and o.metro_id = x.metro_id
	);

	-- ------------------------------------------------------------------- Los dos miembros
	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id, nota
	)
	select v_arq, 'redondilla', 'redondilla', 'Redondilla', 1, 1, 1, 4, 4, v_redondilla_octo, null
	where not exists (
		select 1 from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'redondilla'
	);

	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	select v_arq, 'terceto', 'terceto', 'Terceto', 2, 1, 1, 3, 3,
		'No es un terceto independiente: al menos uno de sus tres versos recoge una rima de la '
		|| 'redondilla, y ese enlace es lo que cierra la estrofa. Va en octosílabos, de modo que no '
		|| 'es el terceto endecasílabo que el catálogo registra aparte.'
	where not exists (
		select 1 from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'terceto'
	);

	-- ------------------------------------------------------------------ Las disposiciones
	foreach v_fila slice 1 in array array[
		array['abbacca', 'abba|cca', 'habitual',
			'El terceto estrena una clase en sus dos primeros versos y cierra con la que abrió la '
			|| 'redondilla. Es la que dan Villasandino y el *Planto de la reina doña Margarita* de '
			|| 'Santillana, y la que las fuentes citan como esquema de la forma.'],
		array['abbaccb', 'abba|ccb', 'admitida',
			'El terceto cierra con la rima interior de la redondilla en vez de con la exterior.'],
		array['ababcbc', 'abab|cbc', 'admitida',
			'La redondilla va cruzada y el terceto alterna una clase nueva con la rima que trae.'],
		array['ababccb', 'abab|ccb', 'admitida',
			'Una de las dos que el Arcipreste de Hita emplea en sus serranas.'],
		array['abababb', 'abab|abb', 'admitida',
			'La otra del Arcipreste: el terceto no estrena ninguna clase y se hace entero con las '
			|| 'dos de la redondilla, de modo que la estrofa se sostiene sobre dos rimas.']
	] loop
		select esquema_rima_id into v_esquema from public.esquemas_rima
		where arquitectura_id = v_arq and slug = v_fila[1];
		if v_esquema is null then
			insert into public.esquemas_rima (
				arquitectura_id, slug, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion
			)
			values (v_arq, v_fila[1], v_fila[2], v_consonante, v_fila[3], 'secuencia', v_fila[4])
			returning esquema_rima_id into v_esquema;

			insert into public.esquema_rima_posiciones
				(esquema_rima_id, bloque, posicion, seccion, clase_rima)
			select v_esquema,
				case when g.i <= 4 then 1 else 2 end,
				case when g.i <= 4 then g.i else g.i - 4 end,
				case when g.i <= 4 then 'redondilla' else 'terceto' end,
				substring(replace(v_fila[2], '|', '') from g.i for 1)
			from generate_series(1, 7) as g(i);
		end if;
	end loop;

	-- --------------------------------------------------------------------- El quiebro
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	select v_arq, v_rasgo_quebrado, 'admitida',
		'El quiebro es tetrasílabo y se documenta en el quinto verso, el primero del terceto.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- -------------------------------------------------------------------- El nombre
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Copla mixta', 'copla_mixta', false, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'copla_mixta'
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§ 67',
			'La define bajo el rótulo «copla mixta»: «septilla, 4-3: consta de una redondilla '
			|| 'seguida por un terceto que enlaza alguno de sus versos con una de las rimas '
			|| 'anteriores». Da `abba:cca` en varias poesías de Villasandino y en el *Planto de la '
			|| 'reina doña Margarita* de Santillana, `abba:ccb` en Pérez de Guzmán y `abab:cbc` en '
			|| 'Macías, y señala que el Arcipreste de Hita la había empleado con dos o tres rimas, '
			|| '`abab:abb` y `abab:ccb`, en sus serranas del Cornejo y de Malangosto. La hace venir '
			|| 'del provenzal a través del gallegoportugués, y en su índice la registra como «séptima '
			|| 'o septilla de 4-3». *Describe aparte, § 131, una septilla enlazada que es otra cosa: '
			|| 'serie encadenada sobre base de quintilla, documentada en la Propalladia de Torres '
			|| 'Naharro y en los entremeses de Sebastián de Horozco.*'],
		array[v_dc14::text, 'pp. 205 y ss.',
			'La presenta como la copla de arte menor de siete versos, con el esquema `abba:cca`, y '
			|| 'anota que Navarro Tomás llama copla mixta a esta forma. Ejemplifica con el *Planto '
			|| 'de la Reina Margarida* del Marqués de Santillana.'],
		array[v_dc16::text, 's. v. «copla de arte menor» y «copla mixta»',
			'Recoge la forma de siete versos con el esquema `abba:cca` y dice que «es llamada por '
			|| 'algunos copla mixta». En su entrada propia define la copla mixta en sentido ancho '
			|| '—«desde siete hasta doce versos octosílabos, dividida en dos semiestrofas de distinta '
			|| 'extensión o en dos sextillas», con dos, tres o cuatro rimas—, la ejemplifica '
			|| 'precisamente con una de siete del Marqués de Santillana y la fecha: «es forma '
			|| 'medieval que llega hasta el Siglo de Oro».'],
		array[v_jauralde::text, 'Apartados «Copla mixta» y «Octavillas y octavas»',
			'La llama copla mixta sin reservas —«la copla mixta (de siete)», junto a la copla real de '
			|| 'diez y la copla novena de nueve— y describe su mecanismo: «forma usual de la copla '
			|| 'mixta (4-3), en donde la primera redondilla enlaza con la rima de alguno de los '
			|| 'versos finales», con ejemplos del *Cancionero general*. Da además una realización '
			|| 'áurea, de Baltasar del Alcázar, con el quinto verso quebrado.'],
		array[v_quilis::text, '§ 5.4.6.1',
			'No registra esta estrofa. Bajo «estrofas de siete versos» describe una **séptima de '
			|| 'arte mayor**, que dice poco usada en la métrica española y cuya rima «queda a gusto '
			|| 'del poeta, con la sola condición de que tres versos no vayan seguidos de la misma '
			|| 'rima», y ejemplifica con Rubén Darío: es otra estructura, no la de cuatro y tres.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas»',
			'No la registran. Su repertorio no tiene ninguna estrofa de siete versos, y lo que no '
			|| 'encaja lo reúnen bajo «coplas», las estrofas cortas que no se incluyen en '
			|| 'definiciones más específicas.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ El vínculo
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_redondilla, 'compuesta_por',
		'La redondilla abre la estrofa y le presta al terceto la rima con que se cierra. Es la '
		|| 'misma base sobre la que se levantan la copla de arte menor y la copla castellana, aquí '
		|| 'con un miembro más corto detrás.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_redondilla
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 5 then
		raise exception 'La septilla declara % disposiciones, no las cinco.', v_n;
	end if;

	-- En las cinco el terceto trae al menos una rima de la redondilla: es lo que la hace estrofa.
	if exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = v_arq
			and (
				(select count(*) from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id) <> 7
				or not exists (
					select 1
					from public.esquema_rima_posiciones p1
					join public.esquema_rima_posiciones p2
						on p2.esquema_rima_id = p1.esquema_rima_id and p2.bloque = 2
					where p1.esquema_rima_id = er.esquema_rima_id and p1.bloque = 1
						and p1.clase_rima = p2.clase_rima
				)
			)
	) then
		raise exception 'Alguna disposición no tiene siete versos o deja el terceto sin enlace.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La septilla cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('septilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la septilla no responde.';
	end if;
end $$;

commit;
