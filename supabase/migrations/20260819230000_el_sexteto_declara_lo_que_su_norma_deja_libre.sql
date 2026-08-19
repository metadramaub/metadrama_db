-- El sexteto declara lo que su norma deja libre
--
-- Revisión de la prosa y del modelo del sexteto. Trece decisiones aprobadas por el IP el 19 de
-- agosto de 2026. Lo que aquí se corrige tiene un hilo común: la ficha decía a la vez que la
-- disposición está abierta y que ABABCC es lo normal, sin que se viera qué acota la norma
-- cuando la disposición no se fija.
--
-- 1. La definición hablaba como el gestor —«cada realización se registra por el esquema
--    observado»— y nombraba una categoría interna, «forma general», que el lector no tiene.
-- 2. La ficha se contradecía sobre el arte menor: la definición exigía arte mayor y el contraste
--    con la sextilla admitía la mezcla de medidas, repitiendo a Caparrós 2014 en lugar de decir
--    lo que el catálogo hace, que es mandar lo mixto regular al sexteto-lira. La nota nueva
--    remite además al par gemelo —redondilla y cuarteto—, para que se vea que el reparto por
--    arte del verso no es una excepción de estas dos formas sino el criterio de la tradición.
-- 3. `ABABCC` estaba marcado `excepcional` a un dedo de una definición que lo llama el más
--    difundido. La modalidad mide frecuencia, y estaba leyendo mal a las fuentes: lo que Quilis
--    y Navarro Tomás dicen es que **el sexteto endecasílabo entero** es raro en el Siglo de Oro,
--    no que ABABCC sea raro entre los sextetos. Pasa a `habitual`; la escasez de la estrofa se
--    queda donde le toca, en la descripción de la arquitectura.
-- 4. La densidad de rima faltaba justamente en la arquitectura principal. No era una decisión:
--    la endecasilábica se libraba del aviso `patron_rima_sin_regla` por tener declarado el
--    ABABCC, y las otras dos, sin esquema concreto, no tuvieron esa salida. Pero un esquema
--    concreto no dice nada de la disposición abierta, que es la que la norma declara. Se declara
--    en las tres.
-- 5. «Sexteto clásico» no lo dice ninguna de las cinco fuentes ni el vocabulario legado: entró
--    con el arrastre del 9 de agosto, cuando la sexta rima pasó de variedad a denominación. Se
--    retira. «Sextina real» y «Sextina antigua» sí están documentadas y se quedan.
-- 7. La alejandrina narraba en prosa una disposición que tres fuentes coinciden en describir
--    —Quilis, Caparrós 2014 y Navarro Tomás— y que la ficha no podía dibujar. Se declara como
--    esquema `AABCCB` con su rasgo de finales agudos, igual que la endecasilábica declara el
--    suyo. Sin los dos puntos con que la escribe Navarro: el disparador que reparte la notación
--    en posiciones solo entiende letras y guiones, y la división no se dibujaría de todos modos.
-- 10. Faltaba el contraste con el sexteto-lira, que la definición del sexteto-lira ya narraba
--    desde su lado. Como las relaciones son bidireccionales, una fila sirve a las dos fichas.
-- 12. La ayuda del editor invitaba a escribir guiones —versos sueltos— en tres arquitecturas
--    cuya densidad de rima es total.
--
-- Nada de esto alcanza a ninguna anotación: el corpus no tiene todavía ningún sexteto.

begin;

do $$
declare
	v_forma uuid;
	v_lira uuid;
	v_sextilla uuid;
	v_endeca uuid;
	v_aleja uuid;
	v_dodeca uuid;
	v_ababcc uuid;
	v_aabccb uuid;
	v_rasgo_densidad uuid;
	v_valor_total uuid;
	v_rasgo_final uuid;
	v_valor_agudo uuid;
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de seis versos de arte mayor, todos de la misma medida y todos rimados en '
		|| 'consonante, cuya disposición de rimas no está fijada. Eso es justamente lo que la '
		|| 'separa de las demás estrofas de seis versos: no reserva un orden de consonancias, '
		|| 'sino que admite cualquiera que alcance a los seis versos, de modo que la medida y la '
		|| 'consonancia son lo que la norma exige y la disposición es lo que cada estrofa trae '
		|| 'consigo. La bibliografía ha dado nombre a algunas de esas disposiciones, y la más '
		|| 'difundida con diferencia, ABABCC, se llama sexta rima. Cuando los seis versos son de '
		|| 'arte menor la estrofa se llama sextilla; cuando alternan endecasílabos y '
		|| 'heptasílabos, sexteto-lira.';

	c_endeca constant text :=
		'Seis endecasílabos. Es la medida propia de la estrofa, la que le vino de Italia y la '
		|| 'única que el Siglo de Oro documenta, aunque con escasez: las otras dos son cultivo '
		|| 'posterior.';

	c_aleja constant text :=
		'Seis alejandrinos. Es medida moderna en esta estrofa, y suele repartirse en dos '
		|| 'semiestrofas simétricas de tres versos.';

	c_dodeca constant text :=
		'Seis dodecasílabos. Es la más tardía de las tres: la cultivaron sobre todo los poetas '
		|| 'modernistas.';

	c_nota_sextilla constant text :=
		'La misma estrofa de seis versos, separada por el arte de sus versos: se llama sextilla '
		|| 'cuando son de arte menor y sexteto cuando son de arte mayor. Es el mismo reparto que '
		|| 'separa la redondilla del cuarteto en las estrofas de cuatro, y viene de la tradición, '
		|| 'que define a cada una por exclusión de la otra. Cuando la estrofa mezcla '
		|| 'endecasílabos y heptasílabos con regularidad no es ninguna de las dos, sino '
		|| 'sexteto-lira.';

	c_nota_lira constant text :=
		'Las dos son estrofas de seis versos con rima consonante y las dos suelen cerrar en '
		|| 'pareado; lo que las separa es la medida. El sexteto la mantiene igual en los seis '
		|| 'versos, y el sexteto-lira alterna endecasílabos con heptasílabos. Entre el aBaBcC del '
		|| 'sexteto-lira y la sexta rima ABABCC no hay más diferencia que el heptasílabo en los '
		|| 'impares.';

	c_nota_densidad constant text :=
		'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.';

	c_nota_agudo constant text :=
		'Riman en agudo los versos tercero y sexto, que son los que cierran cada semiestrofa.';

	c_ayuda constant text :=
		'Escribe las seis posiciones con letras, por ejemplo AABCCB. Los seis versos riman: no hay '
		|| 'sueltos.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto';
	select forma_id into v_lira from public.formas_metricas where slug = 'sexteto_lira';
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';

	if v_forma is null or v_lira is null or v_sextilla is null then
		raise exception 'Falta alguna de las tres formas de seis versos implicadas.';
	end if;

	select arquitectura_id into v_endeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica' and activo;
	select arquitectura_id into v_aleja from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'alejandrina' and activo;
	select arquitectura_id into v_dodeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'dodecasilabica' and activo;

	if v_endeca is null or v_aleja is null or v_dodeca is null then
		raise exception 'El sexteto no tiene sus tres arquitecturas activas.';
	end if;

	-- ------------------------------------------------------------------- 1. La definición
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%cada realización se registra por el esquema observado%'
		and v_actual is distinct from c_definicion
	then
		raise exception 'La definición del sexteto no es la esperada. Empieza: %', left(v_actual, 90);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ---------------------------------------------------- 6, 7 y 8. Las tres descripciones
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_endeca;
	if v_actual not like '%Es la realización más frecuente%' and v_actual is distinct from c_endeca then
		raise exception 'La descripción de la endecasilábica no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_endeca where arquitectura_id = v_endeca;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_aleja;
	if v_actual not like '%cuyos finales riman entre sí en agudo%'
		and v_actual is distinct from c_aleja
	then
		raise exception 'La descripción de la alejandrina no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_aleja where arquitectura_id = v_aleja;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_dodeca;
	if v_actual not like '%medida que cultivaron sobre todo los poetas modernistas%'
		and v_actual is distinct from c_dodeca
	then
		raise exception 'La descripción de la dodecasilábica no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_dodeca where arquitectura_id = v_dodeca;

	-- --------------------------------------- 3. ABABCC deja de ser una rareza del sexteto
	select esquema_rima_id, modalidad into v_ababcc, v_actual
	from public.esquemas_rima where arquitectura_id = v_endeca and slug = 'ababcc';

	if v_ababcc is null then
		raise exception 'La endecasilábica no tiene el esquema «ababcc».';
	end if;
	if v_actual is distinct from 'excepcional' and v_actual is distinct from 'habitual' then
		raise exception 'La modalidad de ABABCC no es la esperada. Dice: %', v_actual;
	end if;
	update public.esquemas_rima set modalidad = 'habitual' where esquema_rima_id = v_ababcc;

	-- ------------------------------------- 5. Un nombre que no sostiene ninguna fuente
	delete from public.denominaciones_metricas
	where esquema_rima_id = v_ababcc and slug_normalizado = 'sexteto_clasico';

	-- Los tres que se quedan siguen ahí, y «Sexta rima» sigue siendo el preferente.
	select count(*) into v_n from public.denominaciones_metricas where esquema_rima_id = v_ababcc;
	if v_n <> 3 then
		raise exception 'El ABABCC se queda con % denominaciones, no con tres.', v_n;
	end if;
	if not exists (
		select 1 from public.denominaciones_metricas
		where esquema_rima_id = v_ababcc and slug_normalizado = 'sexta_rima' and preferente
	) then
		raise exception 'La sexta rima ha dejado de ser la denominación preferente del ABABCC.';
	end if;

	-- --------------------------------- 4. La densidad se declara en las tres, no en dos
	select rasgo_id into v_rasgo_densidad from public.rasgos_metricos where slug = 'densidad_de_rima';
	select valor_id into v_valor_total
	from public.rasgo_valores where rasgo_id = v_rasgo_densidad and slug = 'total';

	if v_rasgo_densidad is null or v_valor_total is null then
		raise exception 'No existe el rasgo «densidad_de_rima» con valor «total».';
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values (v_endeca, v_rasgo_densidad, v_valor_total, 'definitoria', c_nota_densidad)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update set nota = excluded.nota;

	select count(*) into v_n
	from public.arquitectura_rasgos
	where rasgo_id = v_rasgo_densidad
		and arquitectura_id in (v_endeca, v_aleja, v_dodeca)
		and valor_id = v_valor_total
		and modalidad = 'definitoria';
	if v_n <> 3 then
		raise exception 'Solo % de las tres arquitecturas del sexteto declaran densidad total.', v_n;
	end if;

	-- ------------------ 7. La alejandrina declara su disposición en vez de contarla en prosa
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
		estado_revision
	)
	select v_aleja, 'aabccb', 'Sexteto simétrico', 'AABCCB', a.tipo_rima_id, 'habitual',
		'secuencia', 'revisada'
	from public.arquitecturas_forma a
	where a.arquitectura_id = v_aleja
	on conflict (arquitectura_id, slug) do update
		set nombre = excluded.nombre,
			notacion = excluded.notacion,
			modalidad = excluded.modalidad,
			tipo_secuencia = excluded.tipo_secuencia;

	select esquema_rima_id into v_aabccb
	from public.esquemas_rima where arquitectura_id = v_aleja and slug = 'aabccb';

	-- El disparador `sincronizar_posiciones_esquema_rima_fijo` reparte la notación en posiciones.
	-- Se comprueba que lo ha hecho, y con las clases que se esperan: no basta con que existan.
	if (
		select string_agg(clase_rima, '' order by posicion)
		from public.esquema_rima_posiciones where esquema_rima_id = v_aabccb
	) is distinct from 'AABCCB' then
		raise exception 'Las posiciones del sexteto simétrico no dicen AABCCB.';
	end if;
	if exists (
		select 1 from public.esquema_rima_posiciones
		where esquema_rima_id = v_aabccb and suelto
	) then
		raise exception 'El sexteto simétrico ha quedado con algún verso suelto.';
	end if;

	select rasgo_id into v_rasgo_final from public.rasgos_metricos where slug = 'final_acentual';
	select valor_id into v_valor_agudo
	from public.rasgo_valores where rasgo_id = v_rasgo_final and slug = 'agudo';

	if v_rasgo_final is null or v_valor_agudo is null then
		raise exception 'No existe el rasgo «final_acentual» con valor «agudo».';
	end if;

	insert into public.arquitectura_rasgos
		(arquitectura_id, rasgo_id, valor_id, modalidad, nota, posiciones_max)
	values (v_aleja, v_rasgo_final, v_valor_agudo, 'habitual', c_nota_agudo, 2)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update
		set nota = excluded.nota, posiciones_max = excluded.posiciones_max;

	-- ------------------------------------------ 2. El contraste con la sextilla se desdice
	select nota into v_actual from public.forma_relaciones
	where forma_origen_id = v_sextilla
		and forma_destino_id = v_forma
		and tipo_relacion = 'contrasta_con';

	if not found then
		raise exception 'No existe el contraste entre la sextilla y el sexteto.';
	end if;
	if v_actual not like '%o mezclan las dos medidas%'
		and v_actual is distinct from c_nota_sextilla
	then
		raise exception 'La nota del contraste con la sextilla no es la esperada. Dice: %', v_actual;
	end if;
	update public.forma_relaciones set nota = c_nota_sextilla
	where forma_origen_id = v_sextilla
		and forma_destino_id = v_forma
		and tipo_relacion = 'contrasta_con';

	-- ----------------------------------------------- 10. El contraste con el sexteto-lira
	if not exists (
		select 1 from public.forma_relaciones
		where tipo_relacion = 'contrasta_con'
			and ((forma_origen_id = v_forma and forma_destino_id = v_lira)
				or (forma_origen_id = v_lira and forma_destino_id = v_forma))
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
		values (v_forma, v_lira, 'contrasta_con', c_nota_lira, 'revisada');
	else
		update public.forma_relaciones set nota = c_nota_lira
		where tipo_relacion = 'contrasta_con'
			and ((forma_origen_id = v_forma and forma_destino_id = v_lira)
				or (forma_origen_id = v_lira and forma_destino_id = v_forma));
	end if;

	-- ------------------------------ 12. La ayuda del editor invitaba a escribir sueltos
	update public.grupos_eleccion_metrica
	set ayuda_editor = c_ayuda
	where arquitectura_id in (v_endeca, v_aleja, v_dodeca) and slug = 'esquema_rima_observado';

	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where arquitectura_id in (v_endeca, v_aleja, v_dodeca)
		and slug = 'esquema_rima_observado'
		and ayuda_editor = c_ayuda;
	if v_n <> 3 then
		raise exception 'Solo % de las tres ayudas del editor se han actualizado.', v_n;
	end if;

	if exists (
		select 1 from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		where a.forma_id = v_forma and g.ayuda_editor like '%guiones%'
	) then
		raise exception 'Alguna ayuda del sexteto sigue invitando a escribir guiones.';
	end if;
end $$;

commit;
