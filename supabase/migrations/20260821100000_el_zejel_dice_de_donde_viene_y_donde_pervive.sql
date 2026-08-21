-- El zéjel dice de dónde viene y dónde pervive
--
-- Revisión de su prosa, la última del catálogo. Como el villancico, fue de las primeras fichas que
-- se tocaron y entonces solo se le podó prosa. Su modelado está bien —contrastado entero contra la
-- base y contra la ficha servida— y no se toca ninguna parte.
--
-- 1. **Una afirmación duplicada, y la peor de las dos iba primera.** Bajo «Domínguez Caparrós 2014»
--    salían dos párrafos seguidos: uno colgado de la **arquitectura** (pp. 210-211), de dos líneas,
--    y otro de la forma (pp. 213-214), completo. El primero era un resumen pobre del segundo, con
--    el añadido de leerse como si describiera algo distinto por venir rotulado «sobre Estribillo y
--    coplas monorrimas». Se retira.
--
-- 2. **La definición no decía por qué el zéjel está en un catálogo de verso dramático.** Navarro
--    Tomás documenta que en el Siglo de Oro pervive sobre todo en la lírica devota y **en las
--    canciones del teatro**, con ejemplos en *Los baños de Argel* de Cervantes y en *Los amores de
--    Albanio e Ismenia* y *El vaquero de Moraña* de Lope. Eso no estaba en ninguna parte de la
--    prosa propia de la ficha: solo bajando a las fuentes. Con ello entran también el origen
--    arábigo-andalusí, la notación canónica `aa:bbba` y el nombre antiguo de estribote.
--
-- 3. **La mudanza no tenía nota**, y es donde caben las variantes que ninguna otra parte de la
--    ficha recoge: el terceto monorrimo como forma primitiva y mayoritaria, la reducción a dos
--    versos, `aa:bba`, las variantes que alteran estribillo y vuelta y los zéjeles en arte mayor.
--    No se modelan: quedan dichas.
--
-- 4. **La nota de la cabeza explicaba el nombre y no la cosa.** Decía «La función es estribillo;
--    "cabeza" indica que su primera aparición abre la composición». Ahora dice primero qué es y
--    deja la aclaración del nombre al final, como la del villancico.
--
-- 5. **Morley y Bruerton tampoco registran el zéjel**, por la misma razón que no registran el
--    villancico: su repertorio español no tiene ninguna forma con estribillo.
--
-- 6. **Cuatro grupos de elección sin ayuda al editor.**
--
-- *Comprobado y sin cambio: el régimen `consonante` que declara la arquitectura es correcto
-- —Navarro Tomás dice que el consonante de la mudanza cambia en cada estrofa— y no contradice a su
-- única disposición, de modo que no es el caso del pareado. Y el matiz de que «estribote» fue su
-- nombre hasta el siglo XV pasa a la definición, porque `denominaciones_metricas` no tiene columna
-- donde anotarlo.*

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Composición de forma fija y arte menor, normalmente octosílaba, que abre con un estribillo '
		|| 'de uno o dos versos y continúa con una o más coplas. Cada copla se divide en una '
		|| 'mudanza de tres versos monorrimos, con una rima nueva en cada estrofa, y un verso de '
		|| 'vuelta que recupera la rima del estribillo; después el estribillo suele repetirse. El '
		|| 'esquema resultante, aa:bbba, es el que la tradición reconoce como típico. Procede de la '
		|| 'lírica arábigo-andalusí —se atribuye su invención a Mucáddam de Cabra, hacia el año '
		|| '920— y entra en la castellana en el siglo XIV, en canciones de amor y sobre todo de '
		|| 'escarnio; hasta el siglo XV se le llamó estribote. Su uso llega al XVII: en el Siglo de '
		|| 'Oro pervive principalmente en la lírica devota y en las canciones del teatro, con '
		|| 'ejemplos en *Los baños de Argel* de Cervantes y en *Los amores de Albanio e Ismenia* y '
		|| '*El vaquero de Moraña* de Lope de Vega. Se distingue del villancico por la mudanza '
		|| 'monorrima de tres versos y porque la vuelta sigue directamente, sin versos de enlace.';

	c_nota_cabeza constant text :=
		'Uno o dos versos que riman entre sí y fijan la rima a la que vuelve cada copla. Su función '
		|| 'es la de estribillo, y como tal puede repetirse después de cada copla; se le llama '
		|| 'cabeza porque su primera aparición abre la composición.';

	c_nota_mudanza constant text :=
		'Tres versos monorrimos con una rima nueva en cada copla. El terceto monorrimo fue la forma '
		|| 'primitiva del cuerpo del zéjel y siguió siendo la mayoritaria; se documenta también '
		|| 'reducido a dos versos, aa:bba, junto a variantes que alteran el estribillo y la vuelta, '
		|| 'como aba:cccba y abba:cccaca, y a zéjeles en arte mayor.';

	c_mb constant text :=
		'Su repertorio de metros españoles no incluye ninguna forma con estribillo: define la '
		|| 'redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla y el '
		|| 'pareado, y reúne aparte, bajo «coplas», las estrofas cortas que no se incluyen en '
		|| 'definiciones más específicas, que es donde una copla de zéjel caería. Su «canción» es '
		|| 'la canzone italiana de siete y once sílabas, no esta forma.';

	c_ayuda_medida constant text :=
		'El estribillo y las coplas pueden ir en medidas distintas, y por eso la medida se pregunta '
		|| 'parte por parte. Indica la de los versos de esta.';

	c_ayuda_represa constant text :=
		'La edición crítica debe ofrecer los versos repetidos. Indica si el estribillo vuelve tras '
		|| 'cada copla o si no reaparece.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'zejel';
	if v_forma is null then
		raise exception 'No existe el zéjel.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_y_coplas_monorrimas' and activo;
	if v_arq is null then
		raise exception 'El zéjel no tiene su arquitectura activa.';
	end if;

	-- --------------------------------------------------------- 1. La afirmación duplicada
	-- Se borra la de la arquitectura, no la de la forma: la de la forma es la completa.
	delete from public.afirmaciones_fuentes_metricas
	where arquitectura_id = v_arq and fuente_id = v_dc14;

	if exists (
		select 1 from public.afirmaciones_fuentes_metricas where arquitectura_id = v_arq
	) then
		raise exception 'La arquitectura del zéjel sigue teniendo afirmaciones propias.';
	end if;
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_dc14 and localizador = 'pp. 213-214'
	) then
		raise exception 'Se ha perdido la afirmación completa de Caparrós 2014.';
	end if;

	-- ---------------------------------------------------------------- 2. La definición
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%sin verso de enlace.' and v_actual is distinct from c_definicion then
		raise exception 'La definición del zéjel no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ------------------------------------------------------------- 3 y 4. Las dos notas
	select nota into v_actual from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'cabeza';
	if v_actual not like 'La función es estribillo%' and v_actual is distinct from c_nota_cabeza
	then
		raise exception 'La nota de la cabeza del zéjel no es la esperada. Dice: %', v_actual;
	end if;
	update public.estructuras_secciones set nota = c_nota_cabeza
	where arquitectura_id = v_arq and slug = 'cabeza';

	update public.estructuras_secciones set nota = c_nota_mudanza
	where arquitectura_id = v_arq and slug = 'mudanza';

	select count(*) into v_n
	from public.estructuras_secciones
	where arquitectura_id = v_arq and slug in ('cabeza', 'mudanza') and nota is not null;
	if v_n <> 2 then
		raise exception 'Alguna de las dos partes del zéjel se ha quedado sin nota.';
	end if;

	-- ------------------------------------------------------------- 5. Morley y Bruerton
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_mb
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		values (
			v_mb, v_forma,
			'Capítulo «Definición de las Formas Métricas», epígrafes «Metros Españoles», «Coplas» y '
			|| '«Canción (Canzone)»',
			c_mb, 'alta'
		);
	else
		update public.afirmaciones_fuentes_metricas set resumen = c_mb
		where forma_id = v_forma and fuente_id = v_mb;
	end if;

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El zéjel tiene % afirmaciones, no las seis, una por monografía.', v_n;
	end if;

	-- ------------------------------------------------------------ 6. La ayuda al editor
	update public.grupos_eleccion_metrica set ayuda_editor = c_ayuda_medida
	where arquitectura_id = v_arq and dimension = 'metro' and ayuda_editor is null;

	update public.grupos_eleccion_metrica set ayuda_editor = c_ayuda_represa
	where arquitectura_id = v_arq and dimension = 'repeticion' and ayuda_editor is null;

	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and activo and ayuda_editor is null;
	if v_n <> 0 then
		raise exception 'Quedan % grupos del zéjel sin ayuda al editor.', v_n;
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	if public.get_forma_metrica_publica('zejel') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del zéjel ha dejado de responder.';
	end if;

	-- Caparrós 2014 se lee una sola vez en la ficha.
	select count(*) into v_n
	from jsonb_array_elements(public.get_forma_metrica_publica('zejel') -> 'afirmaciones') a
	where a ->> 'fuente_id' = v_dc14::text;
	if v_n <> 1 then
		raise exception 'Caparrós 2014 sale % veces en la ficha del zéjel.', v_n;
	end if;

	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('zejel') -> 'afirmaciones'
		) a
		where a ->> 'fuente_id' = v_mb::text
	) then
		raise exception 'La ficha del zéjel no trae la afirmación de Morley y Bruerton.';
	end if;
end $$;

commit;
