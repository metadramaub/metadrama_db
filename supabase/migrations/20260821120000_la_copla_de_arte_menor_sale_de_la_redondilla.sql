-- La copla de arte menor sale de la redondilla
--
-- Primera de las seis migraciones que llenan el hueco de las estrofas de ocho, once y doce versos.
-- El pendiente que las pedía —«crear la octavilla, la oncena y la copla mixta»— estaba mal
-- planteado: se escribió desde una lectura parcial, y al contrastar las seis fuentes resulta que
-- **«octavilla» no es una forma sino un nombre**, y que la estrofa que nombra **ya estaba en el
-- catálogo, escondida dentro de la redondilla** como la arquitectura `doble_enlazada`.
--
-- **Las estrofas de ocho versos de arte menor son dos, y se distinguen por si las dos semiestrofas
-- comparten una rima.** Jauralde lo dice con todas las letras:
--
-- > «En rigor, la **copla de arte menor** es la estrofa de ocho versos octosílabos, divididos en
-- > dos semiestrofas (4-4) **que se enlazan por una rima** y no tienen más de tres. A su lado, la
-- > **copla castellana**, muy semejante y algo posterior, como derivada de la de arte menor,
-- > **alcanza una cuarta rima**, por lo que cada semiestrofa es una auténtica redondilla.»
--
-- Y Navarro pone esa oposición en serie con las otras dos del catálogo: la copla manriqueña
-- «desligaba una sextilla de otra con separación semejante a la practicada entre **las redondillas
-- de la copla castellana y las quintillas de la copla real**». Es el mismo corte a ocho, a diez y
-- a doce versos, y el catálogo lo resolvía de tres maneras distintas: a diez, dos formas —décima y
-- copla real—; a ocho, una arquitectura de la redondilla; a doce, una arquitectura de la sextilla.
--
-- **El criterio que ordena esto, y que se escribe con estas migraciones:** lo que hace forma aparte
-- es la articulación —cuántos miembros, de qué tamaño y si comparten rima—; la medida y la
-- disposición son arquitectura; el nombre no decide nada. Con un indicio duro: **una arquitectura
-- no cambia la extensión de la unidad de su forma**, y `doble_enlazada` declaraba
-- `unidad_versos = 8` dentro de una forma cuya unidad es 4.
--
-- Así que la copla de arte menor pasa a forma con lo que ya tenía, y gana lo que le faltaba:
--
-- 1. **Sus otras disposiciones.** Solo declaraba `abba:acca`. Navarro § 64 da además
--    `abab:baab` y `abab:bccb`, dice que «las combinaciones de las rimas coinciden con las de las
--    coplas de arte mayor» y que **«las variedades de tres rimas desempeñaron papel
--    predominante»**. `abab:bccb` es además la que Quilis elige como ejemplo.
--
-- 2. **Sus nombres.** El *Diccionario* remite «octavilla» a esta forma y registra *octava de arte
--    menor*, *octava redondilla* y *redondilla de ocho versos*.
--
-- 3. **Sus fuentes.** Ninguna afirmación tenía: era una arquitectura sin bibliografía propia.
--    Morley y Bruerton no la registran, y eso también consta.
--
-- 4. **Sus dos redondillas, declaradas como partes** que reutilizan `redondilla · octosilabica`,
--    como hacen la copla real con la quintilla y la novena con las dos.
--
-- *Lo que se dice en la definición y conviene no perder de vista:* la unión de las dos semiestrofas
-- es aquí una rima compartida, que se oye. En la copla castellana no hay tal rima, y por eso allí
-- la unión es más frágil — Navarro: «un simple efecto de representación gráfica».

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_redondilla uuid;
	v_redondilla_octo uuid;
	v_doble uuid;
	v_metrico uuid;
	v_seccion1 uuid;
	v_seccion2 uuid;
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
		'Estrofa de ocho versos de arte menor, normalmente octosílabos, repartidos en dos '
		|| 'semiestrofas de cuatro que **comparten una rima**: entre las dos no hay más de tres '
		|| 'clases, y al menos una vuelve de la primera mitad a la segunda. Cada semiestrofa se '
		|| 'dispone como una redondilla, abrazada o cruzada, y esa rima común es lo que las cose en '
		|| 'una sola estrofa y la separa de la copla castellana, que estrena cuatro rimas y deja '
		|| 'las dos mitades sueltas. Admite versos quebrados de cuatro sílabas. Fue instrumento '
		|| 'principal de los decires del siglo XV —Santillana la emplea en la *Coronación de Mosén '
		|| 'Jordi*— y su popularidad descendió desde mediados de siglo, a medida que se extendía la '
		|| 'copla castellana de cuatro rimas.';

	c_descripcion constant text :=
		'Ocho octosílabos en dos grupos de cuatro con dos o tres clases de rima consonante. La '
		|| 'primera mitad se mantiene con regularidad en abrazada o cruzada, y la segunda es donde '
		|| 'se concentra la variación. El quiebro, cuando lo hay, es tetrasílabo.';
begin
	if exists (select 1 from public.formas_metricas where slug = 'copla_de_arte_menor') then
		select forma_id into v_forma from public.formas_metricas where slug = 'copla_de_arte_menor';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('copla_de_arte_menor', 'Copla de arte menor', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola)
	on conflict do nothing;

	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select arquitectura_id into v_redondilla_octo from public.arquitecturas_forma
	where forma_id = v_redondilla and slug = 'octosilabica';
	select arquitectura_id into v_doble from public.arquitecturas_forma
	where forma_id = v_redondilla and slug = 'doble_enlazada';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_redondilla_octo is null or v_doble is null or v_rasgo_quebrado is null then
		raise exception 'Falta la redondilla octosilábica, su doble enlazada o el rasgo del quiebro.';
	end if;

	-- Nada anotado depende de la arquitectura que se retira.
	select count(*) into v_n from public.secuencias_editor_metrico where arquitectura_id = v_doble;
	if v_n <> 0 then
		raise exception 'Hay % secuencias anotadas sobre la redondilla doble.', v_n;
	end if;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (
			v_forma, 'octosilabica', 'Octosilábica', c_descripcion, true, true, 'habitual',
			v_consonante, true, 1, 8, 8
		)
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

	-- ------------------------------------------------------------------- Las dos redondillas
	select seccion_id into v_seccion1 from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'primera_redondilla';
	if v_seccion1 is null then
		insert into public.estructuras_secciones (
			arquitectura_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id
		)
		values (v_arq, 'redondilla', 'primera_redondilla', 'Primera redondilla', 1,
			1, 1, 4, 4, v_redondilla_octo)
		returning seccion_id into v_seccion1;
	end if;

	select seccion_id into v_seccion2 from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'segunda_redondilla';
	if v_seccion2 is null then
		insert into public.estructuras_secciones (
			arquitectura_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id,
			nota
		)
		values (v_arq, 'redondilla', 'segunda_redondilla', 'Segunda redondilla', 2,
			1, 1, 4, 4, v_redondilla_octo,
			'Es donde se concentra la variación: la primera mitad se mantiene con regularidad en '
			|| 'abrazada o cruzada, y esta recoge además la rima que vuelve.')
		returning seccion_id into v_seccion2;
	end if;

	-- ------------------------------------------------------------------ Las disposiciones
	-- La notación con `|` no dispara el generador de posiciones, que solo acepta `^[A-Za-z-]+$`;
	-- se escriben a mano, un bloque por semiestrofa, como ya las tenía la doble enlazada.
	foreach v_fila slice 1 in array array[
		array['abbaacca', 'abba|acca', 'habitual',
			'La que el Marqués de Santillana emplea en la *Coronación de Mosén Jordi*: la segunda '
			|| 'redondilla no estrena sus dos clases, sino solo una.'],
		array['ababbaab', 'abab|baab', 'admitida',
			'Cruzada y luego abrazada, con las dos clases de la primera mitad invertidas en la '
			|| 'segunda. Es la que Juan Ruiz usó antes que los poetas de don Juan II.'],
		array['ababbccb', 'abab|bccb', 'admitida',
			'Tres clases: la segunda mitad conserva la b de la primera y estrena una sola. Las '
			|| 'variedades de tres rimas fueron las predominantes.']
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
				case when g.i <= 4 then 'primera_redondilla' else 'segunda_redondilla' end,
				substring(replace(v_fila[2], '|', '') from g.i for 1)
			from generate_series(1, 8) as g(i);
		end if;
	end loop;

	-- --------------------------------------------------------------------- El quiebro
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	select v_arq, v_rasgo_quebrado, 'admitida',
		'El quiebro es tetrasílabo. Se documenta en semiestrofas alternando versos plenos y '
		|| 'quebrados, y también con un solo verso corto en la segunda mitad.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- -------------------------------------------------------------------- Los nombres
	foreach v_fila slice 1 in array array[
		array['Octavilla', 'octavilla'],
		array['Octava de arte menor', 'octava_de_arte_menor'],
		array['Octava redondilla', 'octava_redondilla'],
		array['Redondilla de ocho versos', 'redondilla_de_ocho_versos']
	] loop
		insert into public.denominaciones_metricas
			(forma_id, nombre, slug_normalizado, preferente, fuente_id)
		select v_forma, v_fila[1], v_fila[2], false, v_dc16
		where not exists (
			select 1 from public.denominaciones_metricas
			where forma_id = v_forma and slug_normalizado = v_fila[2]
		);
	end loop;

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_quilis::text, '§ 5.4.7.4',
			'La trata bajo «octavilla», junto a la copla castellana, y las explica por su origen '
			|| 'común: durante la Edad Media la redondilla no tuvo vida independiente, y la '
			|| 'duplicación de una o la combinación de dos dio lugar a estrofas de uso frecuente en '
			|| 'los cancioneros del siglo XV. Elige `abab:bccb` como ejemplo de la de tres rimas.'],
		array[v_navarro::text, '§ 64',
			'La define como ocho octosílabos repartidos en dos grupos de cuatro y enlazados por dos '
			|| 'o tres rimas, cuyas combinaciones coinciden con las de la copla de arte mayor: '
			|| '`abab:baab`, `abab:bccb`, `abba:acca`. Señala que las variedades de tres rimas '
			|| 'desempeñaron papel predominante y que fue instrumento principal en los decires del '
			|| '*Cancionero de Baena*, con papel paralelo al de la copla de arte mayor en los '
			|| '*Loores de claros varones de España*, *El sueño* de Santillana y las *Coplas contra '
			|| 'los pecados mortales* de Juan de Mena. La da por gallegoportuguesa de procedencia '
			|| '—`abab:bccb` en Juan Ruiz y `abba:acca` en López de Ayala, antes que en los poetas '
			|| 'de don Juan II— y explica su declive desde mediados de siglo por la extensión de la '
			|| 'copla castellana de cuatro rimas.'],
		array[v_dc14::text, 'pp. 205 y ss.',
			'La define como ocho octosílabos con dos o tres rimas consonantes distribuidas en dos '
			|| 'redondillas de rima abrazada o cruzada, y precisa la condición: frente a la copla de '
			|| 'arte mayor tiene más libertad en la disposición, **siempre que una de las rimas sea '
			|| 'común a las dos semiestrofas**. Admite versos quebrados de cuatro sílabas. Da como '
			|| 'ejemplo la *Coronación de Mosén Jordi* del Marqués de Santillana.'],
		array[v_dc16::text, 's. v. «copla de arte menor» y «octavilla»',
			'Repite la definición y añade los otros nombres: la entrada «octavilla» remite a esta '
			|| 'forma en su tercera acepción —«estrofa de ocho versos formada por dos redondillas y '
			|| 'en la que una de las rimas de la primera puede repetirse en la segunda»— y registra '
			|| 'como equivalentes octava de arte menor, octava redondilla y redondilla de ocho '
			|| 'versos. Es forma menos solemne que la copla de arte mayor, propia de la poesía menos '
			|| 'elevada y de los decires de fines de la Edad Media.'],
		array[v_jauralde::text, 'Apartado «Octavillas y octavas»',
			'Da el criterio en su forma más nítida: «en rigor, la copla de arte menor es la estrofa '
			|| 'de ocho versos octosílabos, divididos en dos semiestrofas (4-4) que se enlazan por '
			|| 'una rima y no tienen más de tres». La sitúa dominando el siglo XIV y cediendo en el '
			|| 'XV ante la copla castellana, que alcanza una cuarta rima y que es la que permanece '
			|| 'en los siglos XVI y XVII. Advierte además que bajo «octavillas» se esconde «el ancho '
			|| 'hueco de las coplas de arte menor, con sus muchas variedades».'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafes «Metros Españoles» y «Coplas»',
			'No la registran. Su repertorio de metros españoles no tiene ninguna estrofa de ocho '
			|| 'versos de arte menor —define la redondilla, la quintilla, la copla real, la décima, '
			|| 'el romance, la seguidilla y el pareado—, y lo que no encaja lo reúne bajo «coplas», '
			|| 'las estrofas cortas que no se incluyen en definiciones más específicas.']
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
	select v_forma, v_redondilla, 'compuesta_por',
		'Cada semiestrofa se dispone como una redondilla, abrazada o cruzada. Lo que la copla '
		|| 'añade es una rima que vuelve de la primera a la segunda, y es lo que impide leerla como '
		|| 'dos redondillas seguidas.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_redondilla
	);

	-- ------------------------------------------------- La arquitectura vieja se retira
	update public.arquitecturas_forma set activo = false where arquitectura_id = v_doble;

	-- ------------------------------------------------------------------ Comprobaciones
	if exists (
		select 1 from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'redondilla' and a.activo and a.unidad_versos_max > 4
	) then
		raise exception 'La redondilla sigue teniendo una arquitectura de más de cuatro versos.';
	end if;

	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 3 then
		raise exception 'La copla de arte menor declara % disposiciones, no las tres.', v_n;
	end if;

	-- Las tres reparten ocho posiciones en dos bloques, y ninguna estrena cuatro clases.
	if exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = v_arq
			and (
				(select count(*) from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id) <> 8
				or (select count(distinct p.clase_rima) from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id) > 3
			)
	) then
		raise exception 'Alguna disposición no tiene ocho posiciones o pasa de tres clases.';
	end if;

	-- Y en las tres vuelve al menos una rima de la primera mitad a la segunda: es la forma.
	if exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = v_arq
			and not exists (
				select 1
				from public.esquema_rima_posiciones p1
				join public.esquema_rima_posiciones p2
					on p2.esquema_rima_id = p1.esquema_rima_id and p2.bloque = 2
				where p1.esquema_rima_id = er.esquema_rima_id and p1.bloque = 1
					and p1.clase_rima = p2.clase_rima
			)
	) then
		raise exception 'Alguna disposición deja las dos semiestrofas sin rima común.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La copla de arte menor cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('copla_de_arte_menor') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la copla de arte menor no responde.';
	end if;
end $$;

commit;
