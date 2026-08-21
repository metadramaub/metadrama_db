-- El villancico separa el enlace de la vuelta
--
-- Revisión de su prosa, que destapó un error de modelado. El villancico y el zéjel fueron de las
-- primeras fichas que se tocaron y entonces solo se les podó prosa: no se les mejoró la definición
-- ni se les escribieron notas.
--
-- 0. **«Enlace o vuelta» estaba mal.** La sección se creó como si enlace y vuelta fueran dos
--    nombres de lo mismo. No lo son, y tampoco es cierto —como sugiere la formulación comprimida
--    del *Diccionario*— que el enlace sea sin más el primer verso de la vuelta. Navarro Tomás:
--
--    > «En la disposición de su tercera parte, **formada por los versos de enlace y vuelta**, el
--    > villancico ofrece mayor variedad de combinaciones que en las partes anteriores.»
--    > «Antes de la vuelta se intercalan **uno o más versos de enlace**, alguno de los cuales rima
--    > con la mudanza.»
--    > «…dos pareados, seguidos, **sin enlace intermedio**, por el verso de vuelta.»
--
--    Los casos que da lo confirman: cuatro versos finales de los que unos riman con la mudanza,
--    otros quedan sueltos o riman entre sí y el último vuelve al tema, `abba:cdcd:deea`; tres, dos
--    de enlace y uno de vuelta, `abb:cdcd:cdb`; un solo verso suelto entre mudanza y vuelta,
--    `abb:cddc:ebb`; y con tema pareado, «uno de los dos versos finales enlazaba con la mudanza y
--    otro servía de vuelta al estribillo», `aa:bccb:ba`. El enlace es de uno a tres versos, puede
--    rimar con la mudanza o quedar suelto, y puede faltar; la vuelta es lo que recupera la rima de
--    la cabeza.
--
--    Se desdobla, plano dentro de la copla. `tipo_seccion` ya tenía las dos etiquetas en uso: el
--    `enlace` es el de la décima espinela, los dos versos que unen sus redondillas, y la `vuelta`
--    es la del zéjel. El villancico era el único sitio donde iban fundidas. Comprobado antes de
--    tocar nada: **ninguna elección del editor apunta a estas secciones ni a sus grupos**, así que
--    el desdoblamiento no choca con ningún `ON DELETE RESTRICT`.
--
--    Y la regla de extensión pasa a la copla, que es donde se cumple: «Existía una armonía entre la
--    terminación y el principio del villancico. Cuando el tema se reducía a menos de cuatro versos,
--    el final experimentaba la misma abreviación».
--
-- 1. **La definición no nombraba las partes como las nombra la tradición** —cabeza, y también
--    villancico, letra o tema; pie para la estrofa— ni decía la correspondencia de extensión.
--
-- 2. **Cabeza y copla pueden llevar sus otros nombres.** `denominaciones_metricas` admite
--    `seccion_id` y el árbol de partes los imprime («· también …»): son un dato con destino propio
--    en el modelo, no materia de nota.
--
-- 3. **La nota de la mudanza se quedaba corta.** No decía que la tradición cuenta ahí **dos
--    mudanzas** de dos versos, ni que es la parte más estable de la forma —redondilla o cuarteta—,
--    ni que se documentan mudanzas excepcionales de seis versos.
--
-- 4. **La rejilla dibuja solo la mudanza y no lo advertía.** Bajo el rótulo RIMA salen `abba`,
--    `abab` y `-a-a`, que son disposiciones de la mudanza y no de la composición. Ahora lo dice la
--    descripción de la arquitectura.
--
-- 5. **Faltaba el vínculo con la redondilla**, que es lo que Quilis y Caparrós subrayan: la
--    redondilla —o cuarteta— de la mudanza es la parte que menos varía.
--
-- 6. **La descripción de «Estribillo tras la primera copla» mezclaba dos cosas**: el orden de las
--    partes, que es lo que la hace arquitectura aparte, y la realización moderna de Navarro Tomás,
--    que es una cuestión de medida. La medida se va al esquema métrico.
--
-- 7. **Morley y Bruerton no registran el villancico.** Su repertorio español no tiene ninguna forma
--    con estribillo, y su «canción» es la *canzone* italiana.
--
-- 8. **Diez grupos de elección sin ayuda al editor.** Los de medida existen precisamente porque las
--    partes pueden ir en medidas distintas, y eso no se leía en ninguna parte.
--
-- *No lleva «También llamada» y está bien: los otros nombres que dan las fuentes —cabeza, letra,
-- tema, pie— nombran partes, no la forma.*

begin;

do $$
declare
	v_forma uuid;
	v_a1 uuid;
	v_a2 uuid;
	v_redondilla uuid;
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_arq uuid;
	v_copla uuid;
	v_enlace uuid;
	v_vuelta uuid;
	v_grupo public.grupos_eleccion_metrica%rowtype;
	v_seccion uuid;
	v_actual text;
	v_n integer;
	v_par text[];

	c_definicion constant text :=
		'Forma compuesta de arte menor articulada por un estribillo y una o más coplas. El '
		|| 'estribillo inicial —que la tradición llama cabeza, y también villancico, letra o tema— '
		|| 'tiene de dos a cuatro versos y fija la rima a la que vuelve la composición. Cada copla, '
		|| 'llamada también pie, se abre con una mudanza, normalmente de cuatro versos organizados '
		|| 'en dos miembros simétricos, y se cierra con los versos de enlace y de vuelta: el enlace '
		|| '—uno, y a veces dos o tres— recoge la rima del último verso de la mudanza o queda '
		|| 'suelto, y la vuelta recupera la de la cabeza. Enlace y vuelta se corresponden en '
		|| 'extensión con el estribillo, de modo que cuando la cabeza se abrevia el final de la '
		|| 'copla se abrevia con ella, y al acabar se ha recuperado el principio aunque el '
		|| 'estribillo todavía no se haya cantado otra vez. Después de cada copla el estribillo '
		|| 'puede volver entero o en parte. Predominan los octosílabos y hexasílabos, que pueden '
		|| 'distribuirse de manera distinta entre el estribillo y las coplas. Lo más estable de la '
		|| 'forma es la redondilla o cuarteta de la mudanza; lo que más varía es el comienzo y el '
		|| 'final, y la tradición documenta tanto la ampliación como la supresión del enlace y de '
		|| 'la vuelta, así como configuraciones en las que una copla precede a la primera aparición '
		|| 'del estribillo.';

	c_nota_copla constant text :=
		'Enlace y vuelta se corresponden en extensión con la cabeza: cuando la cabeza se reduce a '
		|| 'menos de cuatro versos, el final de la copla se abrevia con ella. Con cabeza de tres '
		|| 'versos el final tiene tres, repartidos entre las dos funciones; con cabeza pareada, un '
		|| 'verso enlaza con la mudanza y el otro vuelve al estribillo.';

	c_nota_mudanza constant text :=
		'Es la parte más estable de la forma: una redondilla o una cuarteta. La tradición cuenta '
		|| 'aquí dos mudanzas simétricas de dos versos cada una, que el catálogo registra como una '
		|| 'sola parte de cuatro porque lo que se mantiene es la estrofa entera. Se documentan '
		|| 'también, excepcionalmente, mudanzas de seis versos.';

	c_nota_enlace constant text :=
		'Los versos que median entre la mudanza y la vuelta. Lo corriente es uno, que recoge la '
		|| 'rima del último verso de la mudanza; se documentan dos y tres, que pueden rimar entre '
		|| 'sí o quedar sueltos. Puede faltar, y entonces la vuelta sigue directamente a la '
		|| 'mudanza.';

	c_nota_vuelta constant text :=
		'Recupera la rima de la cabeza y cierra la copla. Lo corriente es uno o dos versos. No '
		|| 'repite el texto del estribillo: eso es la represa, que viene después y es otra parte.';

	c_desc_a1 constant text :=
		'El estribillo inicial funciona como cabeza. Le siguen uno o más ciclos formados por una '
		|| 'copla —con mudanza y, cuando aparecen, enlace y vuelta— y una posible repetición total '
		|| 'o parcial del estribillo. La composición entera no fija un esquema de rima: lo fija su '
		|| 'mudanza, y a partir de ella enlazan la vuelta y el regreso a la cabeza.';

	c_desc_a2 constant text :=
		'Una copla precede a la primera aparición del estribillo, que desde ahí cierra cada ciclo. '
		|| 'Las partes conservan la organización de la configuración clásica; lo que cambia es el '
		|| 'orden con que la composición empieza.';

	c_metrico_a2 constant text :=
		'El estribillo y las coplas suelen compartir medida, pero pueden emplear metros distintos: '
		|| 'se documenta una cuarteta octosilábica seguida por un estribillo en cuarteta hexasílaba.';

	c_relacion constant text :=
		'La mudanza del villancico es una redondilla —o una cuarteta, cuando la disposición es '
		|| 'cruzada o asonantada— y es la parte que menos varía de la forma: el estribillo y el '
		|| 'final de la copla admiten bastantes cambios de extensión y de rima, y la estrofa '
		|| 'central se mantiene.';

	c_mb constant text :=
		'Su repertorio de metros españoles no incluye ninguna forma con estribillo: define la '
		|| 'redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla y el '
		|| 'pareado, y reúne aparte, bajo «coplas», las estrofas cortas que no se incluyen en '
		|| 'definiciones más específicas, que es donde una copla de villancico caería. Su «canción» '
		|| 'es la canzone italiana de siete y once sílabas, no esta forma.';

	c_ayuda_medida constant text :=
		'El estribillo y las coplas pueden ir en medidas distintas, y por eso la medida se pregunta '
		|| 'parte por parte. Indica la de los versos de esta.';

	c_ayuda_rima constant text :=
		'Se elige cómo rima la mudanza, no la composición entera: el villancico no fija un esquema '
		|| 'de conjunto. Marca la disposición que se lea en los versos de la mudanza.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'villancico';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	if v_forma is null or v_redondilla is null then
		raise exception 'Falta el villancico o la redondilla.';
	end if;

	select arquitectura_id into v_a1 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_inicial' and activo;
	select arquitectura_id into v_a2 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_tras_primera_copla' and activo;
	if v_a1 is null or v_a2 is null then
		raise exception 'El villancico no tiene sus dos arquitecturas activas.';
	end if;

	-- ============================================ 0. El enlace deja de ser la vuelta
	-- Nada anotado depende de estas secciones. Si algún día lo hubiera, esta migración se para
	-- antes de tocarlas en vez de romper el trabajo de un editor.
	select count(*) into v_n
	from public.elecciones_editor_metrico e
	join public.estructuras_secciones s on s.seccion_id = e.seccion_id
	where s.arquitectura_id in (v_a1, v_a2);
	if v_n <> 0 then
		raise exception 'Hay % elecciones anotadas sobre las partes del villancico.', v_n;
	end if;

	foreach v_arq in array array[v_a1, v_a2] loop
		select seccion_id into v_copla from public.estructuras_secciones
		where arquitectura_id = v_arq and slug = 'copla';
		if v_copla is null then
			raise exception 'Falta la copla en una arquitectura del villancico.';
		end if;

		-- La sección fundida se convierte en el enlace: así ningún `RESTRICT` entra en juego y el
		-- grupo de medida que la señala sigue señalando una fila viva.
		select seccion_id into v_enlace from public.estructuras_secciones
		where arquitectura_id = v_arq and slug in ('enlace_vuelta', 'enlace');
		if v_enlace is null then
			raise exception 'No aparece la parte final de la copla en una arquitectura.';
		end if;

		update public.estructuras_secciones set
			slug = 'enlace',
			nombre = 'Enlace',
			tipo_seccion = 'enlace',
			versos_min = 1,
			versos_max = 3,
			repeticiones_min = 0,
			repeticiones_max = 1,
			orden = 2,
			seccion_padre_id = v_copla,
			nota = c_nota_enlace
		where seccion_id = v_enlace;

		select seccion_id into v_vuelta from public.estructuras_secciones
		where arquitectura_id = v_arq and slug = 'vuelta';

		if v_vuelta is null then
			insert into public.estructuras_secciones (
				arquitectura_id, seccion_padre_id, tipo_seccion, slug, nombre, orden,
				repeticiones_min, repeticiones_max, versos_min, versos_max, nota
			)
			values (v_arq, v_copla, 'vuelta', 'vuelta', 'Vuelta', 3, 0, 1, 1, 3, c_nota_vuelta)
			returning seccion_id into v_vuelta;
		else
			update public.estructuras_secciones set nota = c_nota_vuelta
			where seccion_id = v_vuelta;
		end if;

		-- La regla de extensión se cumple en la copla entera, no en ninguna de las dos partes.
		update public.estructuras_secciones set nota = c_nota_copla where seccion_id = v_copla;
		update public.estructuras_secciones set nota = c_nota_mudanza
		where arquitectura_id = v_arq and slug = 'mudanza';

		-- El grupo de medida se desdobla con ellas.
		update public.grupos_eleccion_metrica set slug = 'medida_enlace'
		where arquitectura_id = v_arq and slug = 'medida_enlace_vuelta';

		select * into v_grupo from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq and slug = 'medida_enlace';
		if not found then
			raise exception 'No aparece el grupo de medida del final de la copla.';
		end if;

		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and slug = 'medida_vuelta'
		) then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, seccion_id, selecciones_min,
				selecciones_max, permite_aplicar_global, activo, orden, tipo_control, define_norma
			)
			values (
				v_arq, 'medida_vuelta', v_grupo.dimension, v_grupo.alcance, v_vuelta,
				v_grupo.selecciones_min, v_grupo.selecciones_max, v_grupo.permite_aplicar_global,
				v_grupo.activo, v_grupo.orden, v_grupo.tipo_control, v_grupo.define_norma
			);
		else
			update public.grupos_eleccion_metrica set seccion_id = v_vuelta
			where arquitectura_id = v_arq and slug = 'medida_vuelta';
		end if;
	end loop;

	-- Las dos partes existen en las dos arquitecturas, cada una bajo su copla y en su orden.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.estructuras_secciones p on p.seccion_id = s.seccion_padre_id
	where s.arquitectura_id in (v_a1, v_a2)
		and p.slug = 'copla'
		and (s.slug, s.tipo_seccion, s.orden) in (('enlace', 'enlace', 2), ('vuelta', 'vuelta', 3));
	if v_n <> 4 then
		raise exception 'El desdoblamiento ha dejado % partes de las cuatro esperadas.', v_n;
	end if;
	if exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id in (v_a1, v_a2) and tipo_seccion = 'enlace_vuelta'
	) then
		raise exception 'Sigue habiendo una parte que funde el enlace con la vuelta.';
	end if;

	-- Y cada una tiene quien le pregunte la medida.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	where g.arquitectura_id in (v_a1, v_a2) and s.slug in ('enlace', 'vuelta');
	if v_n <> 4 then
		raise exception 'Solo % de los cuatro grupos de medida del final apuntan a su parte.', v_n;
	end if;

	-- ---------------------------------------------------------------- 1. La definición
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%precede a la primera aparición del estribillo.'
		and v_actual is distinct from c_definicion
	then
		raise exception 'La definición del villancico no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ------------------------------------------------- 2. Los otros nombres de las partes
	-- El estribillo, se llame cabeza (arquitectura principal) o estribillo (la otra).
	for v_seccion in
		select s.seccion_id from public.estructuras_secciones s
		where (s.arquitectura_id = v_a1 and s.slug = 'cabeza')
			or (s.arquitectura_id = v_a2 and s.slug = 'estribillo')
	loop
		foreach v_par slice 1 in array array[
			array['Villancico', 'villancico'],
			array['Letra', 'letra'],
			array['Tema', 'tema']
		] loop
			if not exists (
				select 1 from public.denominaciones_metricas
				where seccion_id = v_seccion and slug_normalizado = v_par[2]
			) then
				insert into public.denominaciones_metricas
					(seccion_id, nombre, slug_normalizado, preferente, fuente_id)
				values (v_seccion, v_par[1], v_par[2], false, v_dc16);
			end if;
		end loop;
	end loop;

	for v_seccion in
		select s.seccion_id from public.estructuras_secciones s
		where s.arquitectura_id in (v_a1, v_a2) and s.slug = 'copla'
	loop
		foreach v_par slice 1 in array array[
			array['Pie', 'pie'],
			array['Estrofa', 'estrofa']
		] loop
			if not exists (
				select 1 from public.denominaciones_metricas
				where seccion_id = v_seccion and slug_normalizado = v_par[2]
			) then
				insert into public.denominaciones_metricas
					(seccion_id, nombre, slug_normalizado, preferente, fuente_id)
				values (v_seccion, v_par[1], v_par[2], false, v_dc16);
			end if;
		end loop;
	end loop;

	select count(*) into v_n
	from public.denominaciones_metricas d
	join public.estructuras_secciones s on s.seccion_id = d.seccion_id
	where s.arquitectura_id in (v_a1, v_a2);
	if v_n <> 10 then
		raise exception 'Las partes del villancico llevan % nombres, no los diez.', v_n;
	end if;

	-- ------------------------------------------------------------------- 3. Las notas
	select count(*) into v_n
	from public.estructuras_secciones
	where arquitectura_id in (v_a1, v_a2)
		and slug in ('copla', 'mudanza', 'enlace', 'vuelta') and nota is not null;
	if v_n <> 8 then
		raise exception 'Solo % de las ocho partes de la copla llevan nota.', v_n;
	end if;

	-- ------------------------------------------------- 4 y 6. Lo que dice cada arquitectura
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_a1;
	if v_actual not like '%parcial del estribillo.' and v_actual is distinct from c_desc_a1 then
		raise exception 'La descripción de «Estribillo inicial» no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_desc_a1 where arquitectura_id = v_a1;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_a2;
	if v_actual not like '%sin enlace ni vuelta.' and v_actual is distinct from c_desc_a2 then
		raise exception 'La descripción de la otra arquitectura no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_desc_a2 where arquitectura_id = v_a2;

	update public.esquemas_metricos set descripcion = c_metrico_a2 where arquitectura_id = v_a2;

	-- El dato de la cuarteta hexasílaba no se pierde al salir de la descripción.
	if not exists (
		select 1 from public.esquemas_metricos
		where arquitectura_id = v_a2 and descripcion like '%cuarteta hexasílaba%'
	) then
		raise exception 'La realización de cuarteta y cuarteta se ha perdido.';
	end if;

	-- --------------------------------------------------------- 5. Vínculo con la redondilla
	if not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_redondilla
			and tipo_relacion = 'compuesta_por'
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota)
		values (v_forma, v_redondilla, 'compuesta_por', c_relacion);
	else
		update public.forma_relaciones set nota = c_relacion
		where forma_origen_id = v_forma and forma_destino_id = v_redondilla
			and tipo_relacion = 'compuesta_por';
	end if;

	-- ------------------------------------------------------------- 7. Morley y Bruerton
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

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El villancico cita % fuentes distintas, no las seis.', v_n;
	end if;

	-- ------------------------------------------------------------ 8. La ayuda al editor
	update public.grupos_eleccion_metrica set ayuda_editor = c_ayuda_medida
	where arquitectura_id in (v_a1, v_a2) and dimension = 'metro' and ayuda_editor is null;

	update public.grupos_eleccion_metrica set ayuda_editor = c_ayuda_rima
	where arquitectura_id in (v_a1, v_a2) and dimension = 'rima' and ayuda_editor is null;

	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where arquitectura_id in (v_a1, v_a2) and activo and ayuda_editor is null;
	if v_n <> 0 then
		raise exception 'Quedan % grupos del villancico sin ayuda al editor.', v_n;
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Los grupos nuevos derivan sus opciones: si no, el editor mostraría una pregunta vacía.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id in (v_a1, v_a2) and g.slug = 'medida_vuelta';
	if v_n <> 4 then
		raise exception 'La medida de la vuelta ofrece % opciones, no las cuatro.', v_n;
	end if;

	-- La ficha responde, trae los nombres en sus partes y el vínculo se lee por los dos extremos.
	if public.get_forma_metrica_publica('villancico') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del villancico ha dejado de responder.';
	end if;

	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('villancico') -> 'denominaciones'
		) d
		where d ->> 'seccion_id' is not null
	) then
		raise exception 'La ficha del villancico no trae los nombres de sus partes.';
	end if;

	foreach v_actual in array array['villancico', 'redondilla'] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_actual) -> 'relaciones'
			) r
			where r ->> 'tipo_relacion' = 'compuesta_por'
		) then
			raise exception 'La ficha de % no recoge el vínculo de composición.', v_actual;
		end if;
	end loop;
end $$;

commit;
