-- La copla de pie quebrado deja de ser una forma
--
-- Segundo y último paso de la decisión del IP. La primera migración declaró el quebrado como
-- rasgo en las estrofas que las fuentes documentan; esta retira la forma general, que era el
-- único sitio donde el quebrado fingía ser una estructura.
--
-- **Por qué no era una forma.** No tenía extensión propia —de cinco a doce versos— porque no es
-- una estrofa: es una propiedad de cualquier estrofa octosilábica. De ahí que solapara con tres
-- formas a la vez: con la sextilla de pie quebrado en seis versos, con la copla real en diez y
-- con la doble sextilla en doce, sin que nada dijera al editor cuál elegir. El *Diccionario*
-- define «copla» como «estrofa», sin más, de modo que su nombre significa «estrofa con algún
-- verso quebrado»; y Navarro Tomás lo dice en una frase: «todas las estrofas de versos plenos
-- tuvieron sus réplicas en variedades quebradas».
--
-- **Qué pasa con su bibliografía.** Sus seis afirmaciones son buenas y están localizadas, y no
-- se pierden: cinco pasan al rasgo `pie_quebrado`, que desde la migración anterior es un destino
-- visible, y así se leen en las cuatro formas que declaran el quebrado y no solo en una. La
-- sexta se retira porque ya estaba dicha.
--
-- Al moverlas aparecieron dos solapamientos, y se resuelven fusionando y no duplicando:
--
--   * **Morley y Bruerton.** La afirmación de la sextilla ya traía la frase entera —«octosílabos
--     combinados con su quebrado de cuatro o cinco sílabas, en estrofas de cinco a doce versos»—.
--     Esa frase es la que ahora hace falta en las cuatro formas, así que va al rasgo, y de la
--     de la sextilla se recorta: allí queda lo suyo, que es que M&B no definen la sextilla como
--     forma independiente.
--   * **Jauralde.** Su afirmación de la copla estaba contenida casi entera en la de la sextilla,
--     que ya dice que llama sextillas simétricas a las coplas de pie quebrado. Se retira, y su
--     única aportación —las variantes modernas, incluso con versos blancos— se añade allí.
--   * Se borra además una afirmación de Caparrós 2014 que colgaba del rasgo desde hace meses sin
--     que nadie pudiera verla, «pp. 196-197», contenida entera en la que ahora ocupa su sitio.
--
-- **Y el nombre no desaparece.** Quilis escribe que «la sextilla más conocida es la llamada
-- Copla de pie quebrado, Copla de Jorge Manrique o Estrofa manriqueña», así que «Copla de pie
-- quebrado» pasa a ser denominación de la arquitectura de pie quebrado de la sextilla, junto a
-- las tres manriqueñas que ya lleva. Quien busque el nombre lo encuentra donde su fuente lo pone.
--
-- Nada depende ya de la forma: su única secuencia era una prueba y el IP la borró.

begin;

do $$
declare
	v_copla uuid;
	v_arq_copla uuid;
	v_sextilla uuid;
	v_arq_quebrada uuid;
	v_rasgo uuid;
	v_fuente_quilis uuid;
	v_actual text;
	v_n integer;

	c_mb_sextilla constant text :=
		'No definen la sextilla como forma independiente en su repertorio de Lope de Vega. Reúnen '
		|| 'bajo «coplas» las estrofas breves que no encajan en definiciones más específicas, y '
		|| 'describen aparte las coplas de pie quebrado.';

	c_jauralde_sextilla constant text :=
		'Reserva el nombre de sextilla para las estrofas de seis versos de arte menor y las ordena '
		|| 'por medida, describiendo sextillas tetrasilábicas, pentasilábicas, hexasilábicas, '
		|| 'heptasilábicas y octosilábicas. Documenta la sextilla alterna ababab en el repertorio '
		|| 'juglaresco y en el Libro de Buen Amor, y el tipo aabccb en la Historia Troyana. Llama '
		|| 'a las coplas de pie quebrado sextillas simétricas cuyos versos tercero y sexto son '
		|| 'menores, con disposición más usual abc:abc, y advierte que el orden de las rimas varía '
		|| 'de una composición a otra; entre sus variaciones cita las sextillas de Ricardo Gil, '
		|| 'donde el tetrasílabo quiebra el segundo verso y el quinto, y variantes modernas que '
		|| 'llegan a dejar versos blancos.';
begin
	select forma_id into v_copla from public.formas_metricas where slug = 'copla_de_pie_quebrado';
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_copla is null or v_sextilla is null or v_rasgo is null then
		raise exception 'Falta la copla de pie quebrado, la sextilla o el rasgo del quebrado.';
	end if;

	select arquitectura_id into v_arq_copla from public.arquitecturas_forma
	where forma_id = v_copla and slug = 'octosilabica_con_quebrados';
	select arquitectura_id into v_arq_quebrada from public.arquitecturas_forma
	where forma_id = v_sextilla and slug = 'pie_quebrado' and activo;

	if v_arq_copla is null or v_arq_quebrada is null then
		raise exception 'Falta la arquitectura de la copla o la de pie quebrado de la sextilla.';
	end if;

	-- Nada del corpus la usa. Si algo la usara, esto lo dice antes de retirarla.
	select count(*) into v_n
	from public.secuencias_metricas s
	join public.vocabularios v on v.termino_id = s.estrofa_tipo_id
	where v.termino = 'copla_de_pie_quebrado';
	if v_n <> 0 then
		raise exception 'Hay % secuencias anotadas como copla de pie quebrado.', v_n;
	end if;

	-- --------------------------------------------- Su bibliografía pasa al rasgo
	-- Cinco de las seis. Jauralde no, porque la de la sextilla ya la contiene.
	update public.afirmaciones_fuentes_metricas
	set forma_id = null, rasgo_id = v_rasgo
	where forma_id = v_copla
		and fuente_id <> (select fuente_id from public.fuentes_metricas where anio = 2020);

	get diagnostics v_n = row_count;
	if v_n <> 5 then
		raise exception 'Se han movido % afirmaciones al rasgo, no cinco.', v_n;
	end if;

	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_copla;

	-- La de Caparrós que llevaba meses enterrada y que la recién llegada dice entera.
	delete from public.afirmaciones_fuentes_metricas
	where rasgo_id = v_rasgo and localizador = 'pp. 196-197';

	-- Y las dos de la sextilla que ahora repetirían: se recorta una y se completa la otra.
	select resumen into v_actual from public.afirmaciones_fuentes_metricas
	where forma_id = v_sextilla
		and fuente_id = (select fuente_id from public.fuentes_metricas where anio = 1968);
	if v_actual not like '%en estrofas de cinco a doce versos.'
		and v_actual is distinct from c_mb_sextilla
	then
		raise exception 'La afirmación de Morley y Bruerton sobre la sextilla no es la esperada.';
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = c_mb_sextilla
	where forma_id = v_sextilla
		and fuente_id = (select fuente_id from public.fuentes_metricas where anio = 1968);

	update public.afirmaciones_fuentes_metricas set resumen = c_jauralde_sextilla
	where forma_id = v_sextilla
		and fuente_id = (select fuente_id from public.fuentes_metricas where anio = 2020);

	-- ------------------------------------------------------ El nombre se queda, donde Quilis
	select fuente_id into v_fuente_quilis from public.fuentes_metricas where anio = 1969;

	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
	values (v_arq_quebrada, 'Copla de pie quebrado', 'copla_de_pie_quebrado', false, v_fuente_quilis)
	on conflict (arquitectura_id, slug_normalizado) where arquitectura_id is not null do update
		set nombre = excluded.nombre, fuente_id = excluded.fuente_id;

	-- ---------------------------------------------------------------- Se retira la forma
	-- El vínculo se borra: apuntaba a una forma que la ficha ya no va a traer, y lo que decía
	-- —que la sextilla quebrada es la copla de pie quebrado por antonomasia— lo dice ahora su
	-- denominación.
	delete from public.forma_relaciones
	where forma_origen_id = v_copla or forma_destino_id = v_copla;

	update public.arquitecturas_forma
	set activo = false, estado_revision = 'retirada'
	where arquitectura_id = v_arq_copla;

	update public.formas_metricas
	set activo = false, estado_revision = 'retirada'
	where forma_id = v_copla;

	-- ------------------------------------------------------------------- Comprobaciones
	-- La ficha de la sextilla trae el nombre y ya no trae el vínculo muerto.
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('sextilla') -> 'denominaciones'
		) d
		where d ->> 'nombre' = 'Copla de pie quebrado'
	) then
		raise exception 'La sextilla no recoge el nombre «Copla de pie quebrado».';
	end if;

	-- Las cinco afirmaciones se leen en las cuatro formas que declaran el quebrado.
	foreach v_actual in array array['sextilla', 'copla_real', 'novena', 'redondilla'] loop
		select count(*) into v_n
		from jsonb_array_elements(public.get_forma_metrica_publica(v_actual) -> 'afirmaciones') a
		where a ->> 'rasgo_id' = v_rasgo::text;
		if v_n <> 5 then
			raise exception 'La ficha de % trae % afirmaciones del quebrado, no cinco.', v_actual, v_n;
		end if;
	end loop;

	-- Y la forma retirada ya no existe para nadie: ni ficha, ni catálogo, ni demarcador.
	if public.get_forma_metrica_publica('copla_de_pie_quebrado') -> 'formas' <> '[]'::jsonb then
		raise exception 'La copla de pie quebrado sigue teniendo ficha.';
	end if;
	if exists (
		select 1 from jsonb_array_elements(
			public.obtener_catalogo_demarcador() -> 'forms'
		) f
		where f ->> 'slug' = 'copla_de_pie_quebrado'
	) then
		raise exception 'El demarcador sigue ofreciendo la copla de pie quebrado.';
	end if;
end $$;

commit;
