-- El pie quebrado es un rasgo de cada estrofa
--
-- Primer paso de la decisión del IP del 20 de agosto de 2026: el quebrado deja de ser una forma
-- —«copla de pie quebrado», que se retirará en la migración siguiente— y pasa a declararse donde
-- las fuentes lo documentan, en cada estrofa. La razón está en las fuentes y en el propio nombre:
-- el *Diccionario* define «copla» como «estrofa», sin más, de modo que «copla de pie quebrado»
-- significa «estrofa con algún verso quebrado» y no nombra ninguna estructura. Y Navarro Tomás
-- abre su § 68 con la frase que lo zanja: «En realidad, todas las estrofas de versos plenos
-- tuvieron sus réplicas en variedades quebradas».
--
-- El catálogo ya tenía el rasgo `pie_quebrado` en la sextilla y en la copla real, con dos
-- mecanismos distintos y los dos correctos. Esta migración los ordena en tres niveles, según lo
-- que la tradición fije en cada caso:
--
--   * **arquitectura propia con medidas fijas**, cuando la tradición fija dónde cae el quiebro
--     —la sextilla de pie quebrado, en el tercer verso y el sexto—;
--   * **rasgo admitido con grupo de posiciones**, cuando el quiebro es corriente pero móvil
--     —la copla real, y ahora la novena—;
--   * **rasgo admitido a secas**, cuando está documentado pero es raro y nadie fija posiciones
--     —la redondilla—.
--
-- Lo que **no** se declara, y por qué:
--
--   * **La quintilla.** Las fuentes no la dan nunca como estrofa quebrada autónoma: Navarro lo
--     dice siempre desde la copla real, «el modelo de la copla real, 5-5, suele ser afectado por
--     el pie quebrado, sobre todo en su segunda mitad», y esa mitad ya lo declara. Para que quien
--     busque la quintilla quebrada la encuentre, lo dice el vínculo entre las dos formas.
--   * **La décima.** La «décima de pie quebrado» que Navarro indiza se articula 4-6 o 6-4, y la
--     del catálogo es la espinela, 4+2+4. No es la misma estrofa.
--
-- La novena es el caso más limpio de todos, porque los ejemplos de Navarro casan uno a uno con
-- sus dos arquitecturas: «Abundan relativamente las coplas de 4-5, con algún verso corto,
-- generalmente en la quintilla… Coplas de 5-4, con quintilla en octosílabos plenos y con
-- quebrados en la redondilla». El quiebro cambia de mitad con el orden, y así se declara.
--
-- Queda una cosa sin sitio, y se anota en cuestiones en vez de forzarla: el nombre **«novena de
-- pie quebrado»**, que Navarro indiza, nombra una realización que depende de un rasgo y no una
-- arquitectura. `denominaciones_metricas` solo sabe colgar de forma, arquitectura, esquema,
-- variedad, sección o repetición, así que colgarlo de la forma diría que la novena se llama
-- siempre así. Va en la definición y en la nota del rasgo, que es donde se lee con su condición.

begin;

do $$
declare
	v_novena uuid;
	v_redondilla uuid;
	v_quintilla uuid;
	v_copla_real uuid;
	v_arq_4_5 uuid;
	v_arq_5_4 uuid;
	v_redonda_octo uuid;
	v_rasgo_quebrado uuid;
	v_octosilabo uuid;
	v_tetrasilabo uuid;
	v_pentasilabo uuid;
	v_actual text;
	v_n integer;
	fila record;

	c_def_novena constant text :=
		'Estrofa de nueve versos. Sus realizaciones no comparten necesariamente metro, rima ni '
		|| 'articulación interna. Entre las formas históricas más caracterizadas se encuentra la '
		|| 'copla novena, que combina una redondilla y una quintilla, normalmente en orden 4+5 y '
		|| 'también 5+4. Una y otra admiten que alguno de sus versos se quiebre en otro más breve, '
		|| 'y así quebrada la estrofa recibe el nombre de novena de pie quebrado.';

	c_def_redondilla constant text :=
		'Estrofa de cuatro versos de arte menor con rima consonante repartida en dos clases, sin '
		|| 'ningún verso suelto. La disposición puede ser abrazada (abba) o cruzada (abab), y las '
		|| 'dos aparecen en una misma composición. El octosílabo es su realización no marcada; el '
		|| 'heptasílabo y el hexasílabo son mucho menos frecuentes. Los cancioneros del siglo XV '
		|| 'la practicaron también con algún verso quebrado, cruzada y abrazada, aunque es '
		|| 'realización rara y no llegó a tener disposición fijada.';

	c_nota_4_5 constant text :=
		'En el orden 4+5 el quiebro cae generalmente en la quintilla. Navarro Tomás llama novena '
		|| 'de pie quebrado a la estrofa así realizada.';

	c_nota_5_4 constant text :=
		'En el orden 5+4 el quiebro pasa a la redondilla, con la quintilla en octosílabos plenos. '
		|| 'Navarro Tomás llama novena de pie quebrado a la estrofa así realizada.';

	c_nota_redondilla constant text :=
		'Navarro Tomás documenta la redondilla quebrada en los cancioneros del siglo XV, cruzada '
		|| 'y abrazada, sin fijar en qué versos cae el quiebro.';

	c_ayuda constant text :=
		'Selecciona únicamente las posiciones quebradas; el resto de los versos son octosílabos.';

	c_nota_copla_real constant text :=
		'Las dos quintillas se separan por una pausa estructural y conservan rimas independientes. '
		|| 'El pie quebrado de la quintilla pertenece a este vínculo: la tradición no describe la '
		|| 'quintilla quebrada como estrofa suelta, sino como una de las dos mitades de la copla '
		|| 'real, y sobre todo la segunda.';

	c_nota_novena constant text :=
		'La copla novena combina una redondilla y una quintilla; sus dos arquitecturas invierten '
		|| 'el orden de los componentes. El quiebro cambia de sitio con ellas: en el orden 4+5 cae '
		|| 'generalmente en la quintilla, y en el 5+4, en la redondilla, con la quintilla en '
		|| 'octosílabos plenos.';
begin
	select forma_id into v_novena from public.formas_metricas where slug = 'novena';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_copla_real from public.formas_metricas where slug = 'copla_real';

	if v_novena is null or v_redondilla is null or v_quintilla is null or v_copla_real is null then
		raise exception 'Falta alguna de las cuatro formas implicadas.';
	end if;

	select arquitectura_id into v_arq_4_5 from public.arquitecturas_forma
	where forma_id = v_novena and slug = 'redondilla_quintilla' and activo;
	select arquitectura_id into v_arq_5_4 from public.arquitecturas_forma
	where forma_id = v_novena and slug = 'quintilla_redondilla' and activo;
	select arquitectura_id into v_redonda_octo from public.arquitecturas_forma
	where forma_id = v_redondilla and slug = 'octosilabica' and activo;

	if v_arq_4_5 is null or v_arq_5_4 is null or v_redonda_octo is null then
		raise exception 'Falta alguna arquitectura activa de la novena o de la redondilla.';
	end if;

	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';
	select metro_id into v_octosilabo from public.metros where slug = 'octosilabo';
	select metro_id into v_tetrasilabo from public.metros where slug = 'tetrasilabo';
	select metro_id into v_pentasilabo from public.metros where slug = 'pentasilabo';

	if v_rasgo_quebrado is null or v_octosilabo is null
		or v_tetrasilabo is null or v_pentasilabo is null
	then
		raise exception 'Falta el rasgo «pie_quebrado» o alguno de los tres metros.';
	end if;

	-- ------------------------------------------------------ La novena, como la copla real
	-- El octosílabo se marca `dominante` y los dos quebrados, `quebrado`: la función
	-- `opciones_eleccion_derivadas()` ofrece solo los marcados como quebrado en cuanto alguno
	-- lleva rol, y sin el dominante el esquema perdería su medida de base.
	--
	-- Y esa misma función exige `medida_uniforme is not null` para derivar las posiciones. El
	-- esquema de la novena lo tenía sin decidir y el de la copla real dice `false`, que es lo que
	-- corresponde a una estrofa cuyos versos no miden todos lo mismo cuando hay quiebro. Sin esto
	-- la pregunta existiría vacía: la primera versión de esta migración se detuvo justo ahí.
	for fila in
		select unnest(array[v_arq_4_5, v_arq_5_4]) as arquitectura
	loop
		update public.esquemas_metricos
		set medida_uniforme = false
		where arquitectura_id = fila.arquitectura and slug = '8-repetido';

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden, rol)
		select em.esquema_metrico_id, m.metro_id, m.orden, m.rol
		from public.esquemas_metricos em
		cross join (values
			(1, 'dominante'),
			(2, 'quebrado'),
			(3, 'quebrado')
		) as t(orden, rol)
		join lateral (
			select case t.orden when 1 then v_octosilabo when 2 then v_tetrasilabo
				else v_pentasilabo end as metro_id, t.orden, t.rol
		) m on true
		where em.arquitectura_id = fila.arquitectura and em.slug = '8-repetido'
		on conflict (esquema_metrico_id, metro_id) do update
			set rol = excluded.rol, orden = excluded.orden;

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min,
			selecciones_max, permite_aplicar_global, ayuda_editor, orden, estado_revision, activo
		)
		values (
			fila.arquitectura, 'posiciones_pie_quebrado', 'metro', 'unidad', 'opciones', 0,
			2, true, c_ayuda, 3, 'revisada', true
		)
		on conflict (arquitectura_id, slug) do update
			set selecciones_min = excluded.selecciones_min,
				selecciones_max = excluded.selecciones_max,
				ayuda_editor = excluded.ayuda_editor,
				activo = true;
	end loop;

	insert into public.arquitectura_rasgos
		(arquitectura_id, rasgo_id, valor_id, modalidad, nota, posiciones_max)
	values (v_arq_4_5, v_rasgo_quebrado, null, 'admitida', c_nota_4_5, 2)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update
		set nota = excluded.nota, posiciones_max = excluded.posiciones_max;

	insert into public.arquitectura_rasgos
		(arquitectura_id, rasgo_id, valor_id, modalidad, nota, posiciones_max)
	values (v_arq_5_4, v_rasgo_quebrado, null, 'admitida', c_nota_5_4, 2)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update
		set nota = excluded.nota, posiciones_max = excluded.posiciones_max;

	-- Que la pregunta exista no basta: se comprueba que la función deriva sus opciones y que
	-- ofrece las dos medidas del quebrado en las nueve posiciones de la estrofa.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id in (v_arq_4_5, v_arq_5_4) and g.slug = 'posiciones_pie_quebrado';
	if v_n <> 36 then
		raise exception 'Las dos novenas derivan % opciones de quebrado, no 36 (9 versos × 2 medidas × 2).', v_n;
	end if;
	if exists (
		select 1
		from public.grupos_eleccion_metrica g
		where g.arquitectura_id in (v_arq_4_5, v_arq_5_4)
			and g.slug = 'posiciones_pie_quebrado'
			and not exists (
				select 1 from public.opciones_eleccion_metrica o
				where o.grupo_eleccion_id = g.grupo_eleccion_id and o.metro_id = v_pentasilabo
			)
	) then
		raise exception 'Alguna novena no ofrece el pentasílabo entre sus quebrados.';
	end if;

	-- --------------------------------- La redondilla, con el rasgo y sin grupo de posiciones
	-- Se declara solo en la octosilábica: el quebrado lo es del octosílabo, y la doble enlazada
	-- no aparece quebrada en las fuentes. Sin opciones métricas a propósito — añadirlas
	-- convertiría su medida en variable y le quitaría la rejilla, que es lo que se lee de ella.
	insert into public.arquitectura_rasgos
		(arquitectura_id, rasgo_id, valor_id, modalidad, nota, posiciones_max)
	values (v_redonda_octo, v_rasgo_quebrado, null, 'admitida', c_nota_redondilla, null)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update
		set nota = excluded.nota, posiciones_max = excluded.posiciones_max;

	if exists (
		select 1 from public.esquema_metrico_opciones o
		join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
		where em.arquitectura_id = v_redonda_octo
	) then
		raise exception 'La redondilla octosilábica ha ganado opciones métricas y perderá su rejilla.';
	end if;

	-- ------------------------------------------------------------------ Las definiciones
	select definicion into v_actual from public.formas_metricas where forma_id = v_novena;
	if v_actual not like '%normalmente en orden 4+5 y también 5+4.'
		and v_actual is distinct from c_def_novena
	then
		raise exception 'La definición de la novena no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_def_novena where forma_id = v_novena;

	select definicion into v_actual from public.formas_metricas where forma_id = v_redondilla;
	if v_actual not like '%mucho menos frecuentes.' and v_actual is distinct from c_def_redondilla then
		raise exception 'La definición de la redondilla no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_def_redondilla where forma_id = v_redondilla;

	-- --------------------------------------------------------- Los vínculos entre formas
	-- Donde busca quien busque la quintilla quebrada: en el vínculo con la copla real.
	select nota into v_actual from public.forma_relaciones
	where forma_origen_id = v_copla_real
		and forma_destino_id = v_quintilla
		and tipo_relacion = 'compuesta_por';

	if not found then
		raise exception 'No existe el vínculo entre la copla real y la quintilla.';
	end if;
	if v_actual not like '%conservan rimas independientes.'
		and v_actual is distinct from c_nota_copla_real
	then
		raise exception 'La nota del vínculo con la quintilla no es la esperada. Dice: %', v_actual;
	end if;
	update public.forma_relaciones set nota = c_nota_copla_real
	where forma_origen_id = v_copla_real
		and forma_destino_id = v_quintilla
		and tipo_relacion = 'compuesta_por';

	-- Y los dos vínculos de la novena dicen ahora en qué mitad cae el quiebro.
	update public.forma_relaciones set nota = c_nota_novena
	where forma_origen_id = v_novena
		and forma_destino_id in (v_quintilla, v_redondilla)
		and tipo_relacion = 'compuesta_por';

	get diagnostics v_n = row_count;
	if v_n <> 2 then
		raise exception 'La novena tiene % vínculos de composición, no dos.', v_n;
	end if;
end $$;

commit;
