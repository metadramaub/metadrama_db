-- El terceto baja al arte menor
--
-- Primera de A3, el pendiente de las medidas que el catálogo no tiene, y **la única de las cinco
-- con respaldo en el corpus áureo**. Jauralde, al describir el tercetillo monorrimo: es «raro en
-- los Siglos de Oro, cuando **solo se utiliza para diálogos teatrales (por Lope de Vega y otros
-- autores)**»; y del autónomo dice que, tras la poesía medieval y los cancioneros, aparece «en
-- ejemplos sueltos —así, **en comedias de Lope**—».
--
-- **La septilla lo estaba esperando.** Creada el 21 de agosto, su sección «Terceto» quedó como la
-- única del catálogo sin `arquitectura_referenciada_id`, porque el terceto solo existía en
-- endecasílabos. Ahora la referencia.
--
-- Y el tercetillo no es «el terceto en arte menor» sin más: **trae una disposición que la forma no
-- tenía y un régimen que tampoco**.
--
-- 1. **La disposición monorrima.** El terceto del catálogo solo declaraba `-AA` y `A-A`, las dos
--    con un verso suelto. La que las fuentes destacan en arte menor es `aaa`: Navarro Tomás le da
--    epígrafe propio —§ 21, «Terceto monorrimo», sobre la *Doctrina cristiana* de Pedro de
--    Veragüe—, Caparrós 2014 ejemplifica el tercetillo con dos monorrimos octosílabos de Rubén
--    Darío, y Jauralde lo llama «tercetillo monorrimo». *Es además el trístico que el zéjel ya
--    tenía por dentro, en su mudanza, sin que hubiera arquitectura que una sección pudiera
--    referenciar.*
--
-- 2. **La asonancia.** El *Diccionario*: «tercetillo. Terceto en versos de arte menor. La rima
--    puede adoptar las distintas disposiciones del terceto, **y puede ser asonante**». El terceto
--    era consonante en su única arquitectura, así que la forma pasa a declarar dos regímenes.
--
-- **Las medidas van como arquitecturas de la misma forma**, no como forma aparte —criterio del IP,
-- y es lo que el catálogo hace con los romancillos dentro del romance—. Octosilábica y
-- hexasilábica: Navarro documenta el monorrimo octosílabo y Jauralde da la base del tercetillo como
-- «octosilábica o hexasilábica». *La definición dice «arte menor» y no cierra la puerta a que
-- aparezcan la pentasílaba o la tetrasílaba, más raras.*
--
-- *Una decisión de presentación:* las tres disposiciones se declaran en consonante y se añade una
-- cuarta, monorrima asonante, en vez de duplicar las tres en los dos regímenes. Seis filas casi
-- idénticas por arquitectura dirían lo mismo y se leerían peor; la descripción dice que la
-- asonancia se documenta sobre todo en el tercetillo popular.

begin;

do $$
declare
	v_forma uuid;
	v_septilla uuid;
	v_seccion uuid;
	v_arq uuid;
	v_octo_arq uuid;
	v_metrico uuid;
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_asonante uuid := 'c5b9a139-a184-471a-b7a7-aa65ed377e85';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_actual text;
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de tres versos. En arte mayor —endecasílabos— dos riman en consonante y el tercero '
		|| 'queda suelto, sea el primero (–AA) o el central (A–A). **En arte menor recibe nombre '
		|| 'propio, tercetillo**, y ahí lo corriente es que los tres rimen entre sí, monorrimos, '
		|| 'aunque admite también las disposiciones con verso suelto y la rima puede ser asonante. '
		|| 'Rara vez aparece aislada: lo normal es que se suceda en series o que entre en la '
		|| 'composición de otra forma, como los dos tercetos del soneto o el que cierra la '
		|| 'septilla. El tercetillo monorrimo es frecuente en la poesía medieval de base octosílaba '
		|| 'o hexasílaba —es el trístico de la mudanza del zéjel— y en el Siglo de Oro se emplea '
		|| 'sobre todo en el diálogo teatral. Cuando las unidades se enlazan por la rima, la serie '
		|| 'resultante es el terceto encadenado, que es otra forma porque deja de ser una estrofa.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'terceto';
	select forma_id into v_septilla from public.formas_metricas where slug = 'septilla';
	if v_forma is null or v_septilla is null then
		raise exception 'Falta el terceto o la septilla.';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like 'Estrofa de tres versos endecasílabos%' and v_actual is distinct from c_definicion
	then
		raise exception 'La definición del terceto no es la esperada. Empieza: %', left(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ------------------------------------------------- Las dos arquitecturas de arte menor
	foreach v_fila slice 1 in array array[
		array['octosilabica', 'Octosilábica', 'habitual', '2', '82bd7a89-675e-41a9-9324-538589731000',
			'El tercetillo por antonomasia: tres octosílabos, lo corriente monorrimos. Es la base '
			|| 'del trístico medieval —la mudanza del zéjel es uno— y la medida en que el Siglo de '
			|| 'Oro lo lleva al diálogo teatral.'],
		array['hexasilabica', 'Hexasilábica', 'admitida', '3', '6e6e3a7e-40d2-4aff-bab7-27044174b5e5',
			'La otra base que la tradición documenta para el tercetillo, junto a la octosílaba.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];

		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			values (v_forma, v_fila[1], v_fila[2], v_fila[6], false, true, v_fila[3],
				null, true, v_fila[4]::integer, 3, 3)
			returning arquitectura_id into v_arq;
		else
			update public.arquitecturas_forma set descripcion = v_fila[6] where arquitectura_id = v_arq;
		end if;

		if v_fila[1] = 'octosilabica' then
			v_octo_arq := v_arq;
		end if;

		-- La medida
		select esquema_metrico_id into v_metrico from public.esquemas_metricos
		where arquitectura_id = v_arq;
		if v_metrico is null then
			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido')
			returning esquema_metrico_id into v_metrico;

			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[5]::uuid, 1);
		end if;

		-- Las disposiciones: tres consonantes y la monorrima también en asonante
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		select v_arq, x.slug, x.nombre, x.notacion, x.regimen, x.modalidad, 'secuencia', x.descripcion
		from (values
			('monorrimo', 'Monorrimo', 'aaa', v_consonante, 'habitual',
				'Los tres versos riman entre sí. Es la disposición que las fuentes destacan en arte '
				|| 'menor, y la del trístico medieval.'),
			('primer-verso-suelto', 'Primer verso suelto', '-aa', v_consonante, 'admitida',
				'La misma disposición que el terceto endecasílabo, aquí en arte menor.'),
			('verso-central-suelto', 'Verso central suelto', 'a-a', v_consonante, 'admitida',
				'La otra disposición que el terceto endecasílabo declara.'),
			('monorrimo-asonante', 'Monorrimo asonante', 'aaa', v_asonante, 'admitida',
				'El tercetillo admite la asonancia, que el terceto de arte mayor no declara. Se '
				|| 'documenta sobre todo en el tercetillo popular.')
		) as x(slug, nombre, notacion, regimen, modalidad, descripcion)
		where not exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = v_arq and er.slug = x.slug
		);

		-- Los nombres que la tradición le da, y que solo valen en arte menor
		insert into public.denominaciones_metricas
			(arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
		select v_arq, x.nombre, x.slug, false, v_dc16
		from (values ('Tercetillo', 'tercetillo'), ('Tercerilla', 'tercerilla'),
			('Tercerillo', 'tercerillo')) as x(nombre, slug)
		where not exists (
			select 1 from public.denominaciones_metricas
			where arquitectura_id = v_arq and slug_normalizado = x.slug
		);
	end loop;

	-- La endecasilábica sigue declarando su régimen arriba, y ahora la forma varía: se baja.
	update public.arquitecturas_forma set tipo_rima_id = null
	where forma_id = v_forma and slug = 'endecasilabica_consonante';

	update public.esquemas_rima er set tipo_rima_id = v_consonante
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma and a.slug = 'endecasilabica_consonante'
		and er.tipo_rima_id is null;

	-- ------------------------------------------------ La septilla deja de esperar
	select seccion_id into v_seccion from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_septilla and s.slug = 'terceto';
	if v_seccion is null then
		raise exception 'No aparece la sección del terceto en la septilla.';
	end if;

	update public.estructuras_secciones set
		arquitectura_referenciada_id = v_octo_arq,
		nota = 'No es un terceto independiente: al menos uno de sus tres versos recoge una rima de '
			|| 'la redondilla, y ese enlace es lo que cierra la estrofa. Va en octosílabos, de modo '
			|| 'que es un tercetillo.'
	where seccion_id = v_seccion;

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_septilla, v_forma, 'compuesta_por',
		'Los tres versos que cierran la septilla son un tercetillo, el terceto en arte menor. Lo '
		|| 'que la septilla añade es que no rima solo: al menos uno de sus versos recoge una clase '
		|| 'de la redondilla que lo precede.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_septilla and forma_destino_id = v_forma
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_dc16::text, 's. v. «tercetillo», «tercerilla» y «tercerillo»',
			'Le da entrada propia y la define entera: «tercetillo. Terceto en versos de arte menor. '
			|| 'La rima puede adoptar las distintas disposiciones del terceto, **y puede ser '
			|| 'asonante**». Registra tercerilla y tercerillo como los otros dos nombres.'],
		array[v_dc14::text, 'Apartado «Combinaciones estróficas castellanas»',
			'«El terceto en versos de arte menor se llama tercetillo, tercerilla o tercerillo», y lo '
			|| 'ejemplifica con dos **tercetillos monorrimos octosílabos** de «A Goya», de Rubén '
			|| 'Darío.'],
		array[v_navarro::text, '§ 21',
			'Le da epígrafe propio con el nombre de **terceto monorrimo**: «en tercetos octosílabos '
			|| 'monorrimos compuso Pedro de Veragüe su *Doctrina cristiana*», y describe el pie '
			|| 'quebrado que acompaña a cada terceto como estribillo —de sus 154 quebrados, 123 son '
			|| 'tetrasílabos y 31 pentasílabos—.'],
		array[v_jauralde::text, 'Apartado «Estrofas de tres versos»',
			'Es quien lo sitúa en el corpus de este catálogo: **«el tercetillo monorrimo es '
			|| 'frecuente en composiciones medievales de base octosilábica o hexasilábica (como el '
			|| 'zéjel, el villancico, normal como estribillo, con uno de sus versos quebrado, etc.), '
			|| 'raro en los Siglos de Oro, cuando solo se utiliza para diálogos teatrales (por Lope '
			|| 'de Vega y otros autores), y nuevamente variado y frecuente a partir del '
			|| 'modernismo»**. Del terceto autónomo añade que, tras la poesía medieval tardía y los '
			|| 'cancioneros, aparece «en ejemplos sueltos —así, en comedias de Lope—» antes de que '
			|| 'los modernistas recuperen la estrofa.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
				and localizador = v_fila[2]
		);
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 3 then
		raise exception 'El terceto tiene % arquitecturas, no las tres.', v_n;
	end if;

	-- La forma declara ahora dos regímenes, y ninguna arquitectura lo declara arriba.
	if exists (
		select 1 from public.arquitecturas_forma
		where forma_id = v_forma and activo and tipo_rima_id is not null
	) then
		raise exception 'Alguna arquitectura del terceto declara el régimen arriba teniendo varios.';
	end if;
	if exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_forma and er.tipo_rima_id is null
	) then
		raise exception 'Alguna disposición del terceto no declara su régimen.';
	end if;
	select count(distinct er.tipo_rima_id) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma;
	if v_n <> 2 then
		raise exception 'El terceto declara % regímenes, no los dos.', v_n;
	end if;

	-- Y el monorrimo existe en las dos medidas de arte menor, que es lo que faltaba.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma and er.notacion = 'aaa';
	if v_n <> 4 then
		raise exception 'El monorrimo aparece % veces, y deben ser cuatro.', v_n;
	end if;

	-- La septilla ya no tiene ninguna parte sin la forma que la realiza.
	if exists (
		select 1 from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'septilla' and s.arquitectura_referenciada_id is null
	) then
		raise exception 'La septilla sigue teniendo una parte sin realizar.';
	end if;

	foreach v_fila slice 1 in array array[array['terceto'], array['septilla'], array['soneto']] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
