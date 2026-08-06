-- La endecha real es una serie, y su asonancia no cabe en la estrofa.
--
-- El catálogo la registraba como **estrofa cerrada** con rima `-a-A`: dos clases distintas
-- para el heptasílabo par y el endecasílabo final, rimando entre sí dentro de los cuatro
-- versos. **Ninguna de las seis fuentes afirma eso**, y tres lo contradicen expresamente.
--
-- Lo que dicen:
--
--   · **Navarro Tomás** (§ 207, p. 283): «una serie de cuartetos». La forma que se generalizó
--     hacia mediados del XVII es «la forma asonantada a manera de romance, abcB dBeB». La
--     asonancia recorre la composición entera; dentro de la estrofa no rima nada.
--   · **Domínguez Caparrós 2014** (p. 189): «con la misma rima asonante en los versos pares de
--     **toda la composición**. Se trata de la **unidad de composición** de una variedad del
--     tipo especial de romance llamado endecha».
--   · **El Diccionario** (s. v. «endecha real», p. 150): «Riman en asonante los versos pares»,
--     y a continuación abre el abanico: el endecasílabo puede ocupar otro lugar, los pares y
--     los impares pueden rimar por separado en consonante o asonante, y puede no haber rima.
--   · **Jauralde** (§ 3.6): el cuarteto de tres heptasílabos y un endecasílabo «se denominó
--     endecha real **cuando recibió rimas**»; antes lo emplearon en versos sueltos Cervantes y
--     Jerónimo Bermúdez.
--   · **Quilis** (§ 6.4.1, p. 163) no registra la endecha real: para él «endecha» es sin más el
--     romance heptasílabo. El vocabulario métrico antiguo del proyecto decía lo mismo, y por
--     eso la endecha real no estaba en él.
--
-- Dos errores, entonces, y no uno. El primero es de **nivel**: era una estrofa y es una serie,
-- como el romance del que sale, con la asonancia sostenida de principio a fin. El segundo es de
-- **rima**: `-a-A` afirmaba dos clases donde solo hay una, y la ponía dentro del cuarteto en vez
-- de entre cuartetos.
--
-- La serie se codifica igual que el romance: bloque cíclico y un enlace `misma_rima` que lleva
-- la última posición a la última del bloque siguiente. La notación pasa a `[---a]…`, con tres
-- versos sueltos y la asonancia en el cuarto.
--
-- Se declaran además las cuatro disposiciones que las fuentes documentan con nombre y ejemplo
-- —suelta, asonantada, cruzada y abrazada— y la de sor Juana, `abbaA`. La asonantada es la
-- definitoria; las demás quedan como variedades, que es la figura del modelo para lo que la
-- arquitectura admite sin que sea su norma.
--
-- El metro no cambia: tres heptasílabos y un endecasílabo, que es lo único en lo que las seis
-- fuentes coinciden sin matices.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_rima_asonantada uuid;
	v_rima_suelta uuid;
	v_rima_cruzada uuid;
	v_rima_abrazada uuid;
	v_rima_sorjuana uuid;
	v_metrico_sorjuana uuid;
	v_fuente_quilis uuid;
	v_fuente_nt uuid;
	v_fuente_cap uuid;
	v_fuente_dicc uuid;
	v_fuente_jauralde uuid;
	v_romance uuid;
	v_posiciones int;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecha_real';
	if v_forma is null then
		raise exception 'No está la endecha real en el catálogo';
	end if;

	select forma_id into v_romance from public.formas_metricas where slug = 'romance';

	select fuente_id into v_fuente_quilis from public.fuentes_metricas where anio = 1969;
	select fuente_id into v_fuente_nt from public.fuentes_metricas where anio = 1972;
	select fuente_id into v_fuente_cap from public.fuentes_metricas where anio = 2014;
	select fuente_id into v_fuente_dicc from public.fuentes_metricas where anio = 2016;
	select fuente_id into v_fuente_jauralde from public.fuentes_metricas where anio = 2020;

	-- 1 · El nivel. Pasa de estrofa a serie: la asonancia no se cierra en el cuarteto.

	update public.formas_metricas
	set nivel_estructural = 'serie',
		definicion = 'Serie de cuartetos formados por tres heptasílabos y un endecasílabo final, con una sola asonancia sostenida en los versos cuartos de toda la composición. Nació en verso suelto y recibió rima hacia mediados del siglo XVII, cuando se generalizó la forma asonantada; el endecasílabo que cierra cada cuarteto es lo que la separa de la endecha, que es el romance heptasílabo.'
	where forma_id = v_forma;

	select arquitectura_id into v_arq
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'heptasilabica_con_endecasilabo';
	if v_arq is null then
		raise exception 'No está la arquitectura heptasilábica con endecasílabo';
	end if;

	-- Una serie no tiene unidad de extensión: la fija el pasaje, como en el romance.
	update public.arquitecturas_forma
	set unidad_versos_min = null,
		unidad_versos_max = null,
		descripcion = 'Tres heptasílabos y un endecasílabo por cuarteto, repetidos durante toda la serie.'
	where arquitectura_id = v_arq;

	-- 2 · El metro, reescrito como ciclo, que es lo que corresponde a una serie.

	select esquema_metrico_id into v_metrico
	from public.esquemas_metricos where arquitectura_id = v_arq and nombre = '7-7-7-11';

	update public.esquemas_metricos
	set tipo_secuencia = 'ciclo',
		descripcion = 'Ciclo de cuatro posiciones: tres heptasílabos y un endecasílabo, repetido durante toda la serie.'
	where esquema_metrico_id = v_metrico;

	-- 3 · La rima. La asonantada, definitoria, con su enlace entre bloques.

	select esquema_rima_id into v_rima_asonantada
	from public.esquemas_rima where arquitectura_id = v_arq and notacion = '-a-A';
	if v_rima_asonantada is null then
		raise exception 'No está el esquema de rima -a-A que hay que corregir';
	end if;

	update public.esquemas_rima
	set notacion = '[---a]…',
		nombre = 'Asonancia sostenida en los versos cuartos',
		tipo_secuencia = 'ciclo',
		modalidad = 'definitoria',
		slug = 'asonantada',
		descripcion = 'Una sola asonancia recorre la composición entera, en el endecasílabo que cierra cada cuarteto: abcB dBeB. Los tres heptasílabos quedan sueltos.'
	where esquema_rima_id = v_rima_asonantada;

	-- Las cuatro posiciones: sueltas las tres primeras, asonante la cuarta. Una sola clase.
	delete from public.esquema_rima_posiciones where esquema_rima_id = v_rima_asonantada;
	insert into public.esquema_rima_posiciones
		(esquema_rima_id, bloque, seccion, posicion, ubicacion, clase_rima, suelto, opcional)
	values
		(v_rima_asonantada, 1, null, 1, 'final', null, true, false),
		(v_rima_asonantada, 1, null, 2, 'final', null, true, false),
		(v_rima_asonantada, 1, null, 3, 'final', null, true, false),
		(v_rima_asonantada, 1, null, 4, 'final', 'a', false, false);

	-- El enlace es lo que hace la serie: la asonancia del cuarto verso pasa al cuarto del
	-- cuarteto siguiente. Sin él, `[---a]…` sería una sucesión de cuartetos independientes.
	delete from public.esquema_rima_enlaces where esquema_rima_id = v_rima_asonantada;
	insert into public.esquema_rima_enlaces
		(esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
		 bloque_destino, posicion_destino, ubicacion_destino,
		 desplazamiento_bloque, tipo_enlace, obligatorio, nota)
	values
		(v_rima_asonantada, 1, 4, 'final', 1, 4, 'final', 1, 'misma_rima', true,
		 'La asonancia del endecasílabo se mantiene en el cuarteto siguiente y en todos los demás.');

	-- 4 · Las variedades que las fuentes documentan.

	-- La suelta, anterior a la rima: Cervantes en *La entretenida*, Bermúdez en *Nise laureada*.
	insert into public.esquemas_rima
		(arquitectura_id, nombre, slug, notacion, ambito, modalidad, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq, 'Versos sueltos', 'suelta', '[----]…', 'unidad', 'admitida', 'ciclo',
		 'Sin rima. Es la forma con que la combinación se empleó antes de recibir rimas.', 'revisada')
	returning esquema_rima_id into v_rima_suelta;

	-- La cruzada y la abrazada riman dentro del cuarteto y no lo enlazan con el siguiente: son
	-- estróficas, no seriales, y por eso no llevan enlace ni ciclan la asonancia.
	--
	-- Sus posiciones las escribe el trigger `sincronizar_posiciones_esquema_rima_fijo`, que las
	-- deriva letra a letra de la notación. **Y ahí toma la caja por clase**: de `-a-A` saca las
	-- clases `a` y `A` como si fueran dos rimas distintas, cuando la caja dice el arte del verso
	-- y no con quién rima —la lira escribe `aBabB` y sus cinco versos son dos rimas, no cuatro—.
	-- Se corrige la clase después de insertar, que es lo que hay que hacer mientras el trigger
	-- no distinga las dos cosas.
	insert into public.esquemas_rima
		(arquitectura_id, nombre, slug, notacion, ambito, modalidad, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq, 'Cruzada', 'cruzada', '-a-A', 'unidad', 'admitida', 'secuencia',
		 'Rima cruzada dentro del cuarteto, entre el segundo heptasílabo y el endecasílabo: *abaB* en la notación de las fuentes. La rima se cierra en el cuarteto y no pasa al siguiente.', 'revisada')
	returning esquema_rima_id into v_rima_cruzada;

	update public.esquema_rima_posiciones
	set clase_rima = 'a'
	where esquema_rima_id = v_rima_cruzada and posicion = 4;

	insert into public.esquemas_rima
		(arquitectura_id, nombre, slug, notacion, ambito, modalidad, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq, 'Abrazada', 'abrazada', 'abbA', 'unidad', 'admitida', 'secuencia',
		 'Rima abrazada: el endecasílabo cierra con la rima del primer heptasílabo, y los dos centrales riman entre sí. El *Romancero general* la trae al final de un romance.', 'revisada')
	returning esquema_rima_id into v_rima_abrazada;

	update public.esquema_rima_posiciones
	set clase_rima = 'a'
	where esquema_rima_id = v_rima_abrazada and posicion = 4;

	-- La de sor Juana suma un verso: redondilla heptasílaba más endecasílabo. Cinco posiciones,
	-- así que necesita su propio esquema métrico.
	insert into public.esquemas_metricos
		(arquitectura_id, nombre, slug, ambito, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq, '7-7-7-7-11', 'redondilla_con_endecasilabo', 'unidad', 'ciclo',
		 'Ciclo de cinco posiciones: una redondilla heptasílaba y un endecasílabo final.', 'revisada')
	returning esquema_metrico_id into v_metrico_sorjuana;

	insert into public.esquemas_rima
		(arquitectura_id, nombre, slug, notacion, ambito, modalidad, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq, 'Redondilla con endecasílabo', 'redondilla_con_endecasilabo', 'abbaA', 'unidad', 'excepcional', 'secuencia',
		 'Una redondilla heptasílaba seguida de un endecasílabo que repite la rima del primer verso. Es de sor Juana Inés de la Cruz y no consta en el teatro español.', 'revisada')
	returning esquema_rima_id into v_rima_sorjuana;

	update public.esquema_rima_posiciones
	set clase_rima = 'a'
	where esquema_rima_id = v_rima_sorjuana and posicion = 5;

	insert into public.variedades_arquitectura
		(arquitectura_id, slug, nombre, descripcion, esquema_metrico_id, esquema_rima_id, preferente, orden, estado_revision)
	values
		(v_arq, 'suelta', 'En versos sueltos',
		 'La combinación métrica sin rima, anterior a que la forma recibiera nombre.',
		 v_metrico, v_rima_suelta, false, 1, 'revisada'),
		(v_arq, 'cruzada', 'De rima cruzada',
		 'La asonancia se cierra dentro del cuarteto en vez de recorrer la serie.',
		 v_metrico, v_rima_cruzada, false, 2, 'revisada'),
		(v_arq, 'abrazada', 'De rima abrazada',
		 'El endecasílabo recoge la rima del primer heptasílabo.',
		 v_metrico, v_rima_abrazada, false, 3, 'revisada'),
		(v_arq, 'redondilla_con_endecasilabo', 'Con redondilla heptasílaba',
		 'Cinco versos en vez de cuatro: una redondilla heptasílaba y el endecasílabo final.',
		 v_metrico_sorjuana, v_rima_sorjuana, false, 4, 'revisada');

	-- 5 · Las denominaciones. El Diccionario da tres, y atribuye una a Navarro Tomás.

	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, idioma, preferente, fuente_id)
	values
		(v_forma, 'Endecha endecasílaba', 'endecha_endecasilaba', 'es', false, v_fuente_dicc),
		(v_forma, 'Endecha heroica', 'endecha_heroica', 'es', false, v_fuente_dicc),
		(v_forma, 'Cuarteto de endecha', 'cuarteto_de_endecha', 'es', false, v_fuente_dicc);

	-- 6 · Lo que dicen las fuentes.

	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, confianza, resumen, estado_revision)
	values
		(v_fuente_nt, v_forma, '§ 207, p. 283', 'alta',
		 'Llama endecha real a la composición formada por **una serie de cuartetos** de tres heptasílabos y un endecasílabo. Jerónimo Bermúdez y Cervantes la emplearon en versos sueltos, *abcD*; con rimas abrazadas, *abbA*, aparece al final de un romance del *Romancero general*. **Hacia mediados del siglo XVII se generalizó la forma asonantada a manera de romance, *abcB dBeB***, cultivada sobre todo por Trillo y Figueroa y por sor Juana Inés de la Cruz.', 'revisada'),
		(v_fuente_nt, v_forma, '§ 268, p. 333', 'alta',
		 'La define en cuartetas asonantes de tres heptasílabos y un endecasílabo, *abcB*, y añade que se destinaba de ordinario a **asuntos más graves** que los reservados a las endechas en simples versos de seis o siete sílabas.', 'revisada'),
		(v_fuente_nt, v_forma, 'Glosario, s. v. «endecha real»', 'alta',
		 'La resume como **romance heptasílabo** en que el último verso de cada cuarteta es endecasílabo, *abcB dbeB*, y anota que en algunos casos las estrofas llevan rimas cruzadas, *abaB*.', 'revisada'),
		(v_fuente_cap, v_forma, 'p. 189', 'alta',
		 'Se compone de tres heptasílabos seguidos de un endecasílabo **con la misma rima asonante en los versos pares de toda la composición**. Es la **unidad de composición** de una variedad del tipo especial de romance llamado endecha. La incluye entre las estrofas de cuatro versos.', 'revisada'),
		(v_fuente_dicc, v_forma, 's. v. «endecha real», p. 150', 'alta',
		 'Combinación estrófica de tres heptasílabos seguidos de un endecasílabo, con asonancia en los pares. Advierte que **el endecasílabo puede ocupar otro lugar**, que pares e impares pueden rimar por separado en consonante o en asonante, y que **puede encontrarse sin rima**.', 'revisada'),
		(v_fuente_dicc, v_forma, 's. v. «endecha real», p. 150', 'alta',
		 'Recoge tres nombres equivalentes: *cuarteto de endecha*, *endecha endecasílaba* y *endecha heroica*. El primero lo atribuye a Navarro Tomás.', 'revisada'),
		(v_fuente_dicc, v_forma, 's. v. «endecha», p. 148', 'alta',
		 'La endecha, sin más, es poema de asunto triste en forma de romancillo heptasílabo por lo general, aunque admite versos de cinco o de seis sílabas. Como el nombre se refiere sobre todo al asunto, pueden hallarse endechas en otras formas métricas.', 'revisada'),
		(v_fuente_jauralde, v_forma, '§ 3.6, «Cuartetas de heptasílabos»', 'alta',
		 'El cuarteto de tres heptasílabos y un endecasílabo, empleado en versos sueltos por Cervantes en *La entretenida* y por Jerónimo Bermúdez en *Nise laureada*, **se denominó endecha real cuando recibió rimas**. Lo cultivó sor Juana Inés de la Cruz, que también lo construyó con hexasílabos, y como forma extraña se jugó con variaciones de todo tipo.', 'revisada'),
		(v_fuente_quilis, v_forma, '§ 6.4.1, p. 163', 'media',
		 'No registra la endecha real. Llama **endecha** al romance cuyos versos constan de siete sílabas, y reserva *romancillo* para los de menos de siete.', 'revisada');

	-- 7 · Las relaciones. La que había se reescribe: ya no contrasta con el romance por el
	-- nivel, porque ahora comparten nivel, sino que sale de él.

	delete from public.forma_relaciones
	where (forma_origen_id = v_forma and forma_destino_id = v_romance)
		or (forma_origen_id = v_romance and forma_destino_id = v_forma);

	insert into public.forma_relaciones
		(forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
	values
		(v_forma, v_romance, 'derivada_de',
		 'Es un romance heptasílabo cuyo cuarto verso se alarga a endecasílabo. Conserva su asonancia sostenida en los pares y su extensión libre; lo que la separa es la heterometría regular.', 'revisada');

	-- Comprobación 1: la asonantada deja sueltos los tres heptasílabos.
	select count(*) into v_posiciones
	from public.esquema_rima_posiciones where esquema_rima_id = v_rima_asonantada and suelto;
	if v_posiciones <> 3 then
		raise exception 'La asonantada debería tener 3 versos sueltos y tiene %', v_posiciones;
	end if;

	-- Comprobación 2: ninguna rima de esta forma distingue clases por la caja. Si quedara una
	-- clase en mayúscula junto a la misma letra en minúscula, el trigger habría vuelto a tomar
	-- el arte del verso por una rima aparte.
	select count(*) into v_posiciones
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	where er.arquitectura_id = v_arq
		and p.clase_rima is not null
		and p.clase_rima <> lower(p.clase_rima);
	if v_posiciones > 0 then
		raise exception 'Quedan % posiciones cuya clase de rima solo se distingue por la caja', v_posiciones;
	end if;

	raise notice 'Endecha real · serie con asonancia enlazada, 4 variedades, 9 afirmaciones en 5 fuentes';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
