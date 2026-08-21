-- La copla castellana estrena cuatro rimas
--
-- Segunda de las seis. La pareja de la copla de arte menor, y **la que de verdad faltaba**: es la
-- estrofa de ocho versos del Siglo de Oro, y el catálogo no tenía dónde ponerla. Jauralde:
--
-- > «la de arte menor domina durante el siglo XIV y es mayoritaria en el siglo XV la castellana,
-- > **que es la que permanece como forma popularísima a lo largo de los siglos XVI y XVII**.»
--
-- Y el *Diccionario*: «Se empleó en la poesía menos elevada, especialmente en decires del final de
-- la Edad Media, **en el teatro** y en el género epigramático del siglo XVI».
--
-- Lo que la separa de su hermana es una sola cosa, y es estructural: **estrena cuatro rimas**, de
-- modo que ninguna vuelve de la primera semiestrofa a la segunda y cada mitad es una redondilla
-- entera. Navarro § 65 lo dice como consecuencia: «Suprimido el enlace de la rima, la unión de las
-- semiestrofas quedaba reducida a un simple efecto de representación gráfica».
--
-- **Esa frase es también el problema de anotación de esta forma, y la definición lo dice.** Sin
-- rima compartida, una copla castellana y dos redondillas seguidas son el mismo dibujo: lo que las
-- separa es cómo el texto las agrupa. No es un defecto del catálogo sino de la cosa, y conviene que
-- se lea en la ficha antes que en la duda de un editor.
--
-- Sus cuatro disposiciones son las que enumeran Navarro y Caparrós, que coinciden: las dos mitades
-- pueden ir las dos cruzadas, las dos abrazadas, o combinarse en cualquier orden. Admite algún
-- verso tetrasílabo —Santillana quiebra el sexto en el *Diálogo de Bías contra Fortuna*—, y el
-- quiebro va como rasgo, que es donde el catálogo lo puso el 20 de agosto de 2026.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_hermana uuid;
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
		'Estrofa de ocho versos octosílabos repartidos en dos semiestrofas de cuatro que **no '
		|| 'comparten ninguna rima**: cada una estrena las suyas, de modo que las dos son '
		|| 'redondillas enteras y la estrofa suma cuatro clases consonantes. Pueden ir las dos '
		|| 'cruzadas, las dos abrazadas o combinarse en cualquier orden. Algún verso puede aparecer '
		|| 'quebrado en cuatro sílabas. Esa cuarta rima es lo único que la separa de la copla de '
		|| 'arte menor, donde una rima vuelve de la primera mitad a la segunda, y de ahí que se la '
		|| 'tenga por más sencilla: derivada de aquella, se impuso sobre ella en el siglo XV y '
		|| 'siguió siendo la estrofa corriente de ocho versos en el XVI y el XVII, en el teatro y '
		|| 'en el epigrama. Sin rima que enlace las dos mitades, lo que la distingue de dos '
		|| 'redondillas seguidas no es la organización métrica sino la manera en que el texto las '
		|| 'agrupa: lo que une las semiestrofas, dicho por la tradición, es la disposición gráfica.';

	c_descripcion constant text :=
		'Ocho octosílabos en dos grupos de cuatro, con dos clases de rima consonante en cada uno y '
		|| 'ninguna común a los dos. El quiebro, cuando lo hay, es tetrasílabo.';
begin
	if exists (select 1 from public.formas_metricas where slug = 'copla_castellana') then
		select forma_id into v_forma from public.formas_metricas where slug = 'copla_castellana';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('copla_castellana', 'Copla castellana', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	select forma_id into v_hermana from public.formas_metricas where slug = 'copla_de_arte_menor';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select arquitectura_id into v_redondilla_octo from public.arquitecturas_forma
	where forma_id = v_redondilla and slug = 'octosilabica';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_hermana is null or v_redondilla_octo is null or v_rasgo_quebrado is null then
		raise exception 'Falta la copla de arte menor, la redondilla octosilábica o el rasgo.';
	end if;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'octosilabica', 'Octosilábica', c_descripcion, true, true, 'habitual',
			v_consonante, true, 1, 8, 8)
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
	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id
	)
	select v_arq, 'redondilla', x.slug, x.nombre, x.orden, 1, 1, 4, 4, v_redondilla_octo
	from (values
		('primera_redondilla', 'Primera redondilla', 1),
		('segunda_redondilla', 'Segunda redondilla', 2)
	) as x(slug, nombre, orden)
	where not exists (
		select 1 from public.estructuras_secciones s
		where s.arquitectura_id = v_arq and s.slug = x.slug
	);

	-- ------------------------------------------------------------------ Las disposiciones
	foreach v_fila slice 1 in array array[
		array['abbacddc', 'abba|cddc', 'habitual',
			'Las dos mitades abrazadas. Es la que Castillejo emplea en la «Canción a Nuestra Señora, '
			|| 'viniendo en la mar» y la que Santillana quiebra en el sexto verso.'],
		array['ababcdcd', 'abab|cdcd', 'admitida', 'Las dos mitades cruzadas.'],
		array['abbacdcd', 'abba|cdcd', 'admitida', 'Abrazada la primera, cruzada la segunda.'],
		array['ababcddc', 'abab|cddc', 'admitida', 'Cruzada la primera, abrazada la segunda.']
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
		'El quiebro es tetrasílabo y suele ser uno solo. Se documenta en el sexto verso, y también '
		|| 'alternando versos plenos y quebrados en las dos semiestrofas.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_quilis::text, '§ 5.4.7.4',
			'La trata bajo «octavilla», junto a la copla de arte menor, y explica las dos por su '
			|| 'origen común: durante la Edad Media la redondilla no tuvo vida independiente, y la '
			|| 'duplicación de una o la combinación de dos dio lugar a estrofas de uso frecuente en '
			|| 'los cancioneros del siglo XV. Añade que cuando los octosílabos alternan con versos '
			|| 'de cuatro sílabas se originan las coplas de pie quebrado, muy difundidas en el siglo '
			|| 'XV y principios del XVI, y cita el *Diálogo de Bías contra Fortuna* y los '
			|| '*Proverbios morales* de Santillana.'],
		array[v_navarro::text, '§ 65',
			'La define como ocho octosílabos en dos grupos de cuatro **con cuatro rimas, como pareja '
			|| 'de redondillas independientes**, y enumera las cuatro disposiciones: las dos mitades '
			|| 'cruzadas, `abab:cdcd`; las dos abrazadas, `abba:cddc`; o combinadas, `abab:cddc` y '
			|| '`abba:cdcd`. La sigue históricamente: no hay ningún ejemplo en el *Cancionero de '
			|| 'Baena* de 1445; Santillana la usa en las coplas sobre el Condestable y, con el sexto '
			|| 'verso quebrado, en el *Diálogo de Bías contra Fortuna* y en los *Gozos de Nuestra '
			|| 'Señora*; en el *Cancionero general* de 1511 ya supera a la de arte menor, y «llegaron '
			|| 'a ser de uso tan familiar en el siglo XVI que recibieron el nombre de coplas '
			|| 'castellanas». Observa además lo que su falta de enlace implica: «suprimido el enlace '
			|| 'de la rima, la unión de las semiestrofas quedaba reducida a un simple efecto de '
			|| 'representación gráfica».'],
		array[v_dc14::text, 'pp. 205 y ss.',
			'La define como ocho octosílabos —algunos de ellos pueden ser tetrasílabos— divididos en '
			|| 'dos semiestrofas de cuatro versos, con dos rimas consonantes diferentes en cada una, '
			|| 'y da las cuatro disposiciones más frecuentes. Ejemplifica con la «Canción a Nuestra '
			|| 'Señora, viniendo en la mar» de Cristóbal de Castillejo. Señala que por tener una rima '
			|| 'más que la copla de arte menor es más sencilla que ella, con la que está emparentada, '
			|| 'y que se empleó en decires del final de la Edad Media, **en el teatro** y en el '
			|| 'género epigramático del siglo XVI.'],
		array[v_dc16::text, 's. v. «copla castellana»',
			'Repite la definición y las cuatro disposiciones, y ejemplifica con Baltasar del Alcázar. '
			|| 'La sitúa en la poesía menos elevada, en los decires del final de la Edad Media, en el '
			|| 'teatro y en el epigrama del siglo XVI.'],
		array[v_jauralde::text, 'Apartado «Octavillas y octavas»',
			'La presenta como derivada de la copla de arte menor y «algo posterior»: «alcanza una '
			|| 'cuarta rima, por lo que cada semiestrofa es una auténtica redondilla». Da el reparto '
			|| 'histórico —la de arte menor domina el siglo XIV, la castellana es mayoritaria en el '
			|| 'XV— y **la señala como la que permanece, forma popularísima a lo largo de los siglos '
			|| 'XVI y XVII**. Al tratar el epigrama la nombra otra vez: optó por «la brevedad de dos '
			|| 'redondillas (es decir: de una copla castellana) o dos quintillas».'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafes «Metros Españoles» y «Coplas»',
			'No la registran. Su repertorio de metros españoles no tiene ninguna estrofa de ocho '
			|| 'versos de arte menor, y lo que no encaja lo reúnen bajo «coplas», las estrofas cortas '
			|| 'que no se incluyen en definiciones más específicas: es donde caería un pasaje de dos '
			|| 'redondillas agrupadas.']
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
		'Cada semiestrofa es una redondilla entera, con sus dos clases propias. Que ninguna rima '
		|| 'pase de una a otra es lo que hace de esta forma la suma de dos redondillas y no una '
		|| 'estrofa con enlace interior.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_redondilla
	);

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_hermana, 'derivada_de',
		'Las dos son ocho octosílabos en dos grupos de cuatro, y se separan por una sola cosa: la '
		|| 'de arte menor comparte una rima entre las semiestrofas y no pasa de tres clases; la '
		|| 'castellana estrena cuatro y deja las dos mitades sueltas. La castellana es la posterior '
		|| 'y acabó imponiéndose: domina el siglo XV y sigue siendo la corriente en el XVI y el '
		|| 'XVII, mientras la de arte menor se retira con los decires.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_hermana)
			or (forma_origen_id = v_hermana and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 4 then
		raise exception 'La copla castellana declara % disposiciones, no las cuatro.', v_n;
	end if;

	-- Las cuatro estrenan cuatro clases y ninguna vuelve de una mitad a la otra: es la forma.
	if exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = v_arq
			and (
				(select count(distinct p.clase_rima) from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id) <> 4
				or exists (
					select 1
					from public.esquema_rima_posiciones p1
					join public.esquema_rima_posiciones p2
						on p2.esquema_rima_id = p1.esquema_rima_id and p2.bloque = 2
					where p1.esquema_rima_id = er.esquema_rima_id and p1.bloque = 1
						and p1.clase_rima = p2.clase_rima
				)
			)
	) then
		raise exception 'Alguna disposición no estrena cuatro clases o enlaza las dos mitades.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La copla castellana cita % fuentes, no las seis.', v_n;
	end if;

	-- El vínculo entre las dos hermanas se lee por los dos extremos.
	foreach v_fila slice 1 in array array[
		array['copla_castellana'], array['copla_de_arte_menor']
	] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_fila[1]) -> 'relaciones'
			) r
			where r ->> 'tipo_relacion' = 'derivada_de'
		) then
			raise exception 'La ficha de % no recoge el vínculo entre las dos coplas.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
