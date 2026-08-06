-- Tres recipientes, y no uno, en la endecha real.
--
-- La revisión anterior metió en una sola arquitectura tres cosas que no caben juntas, y
-- atribuyó a sor Juana lo que las fuentes le atribuyen de otro modo. Se corrigen los cuatro
-- errores.
--
-- 1 · **El ciclo de cinco no es del mismo recipiente que el de cuatro.** `7-7-7-7-11` y
--     `7-7-7-11` son dos medidas distintas, y la medida no varía dentro de un pasaje: un
--     pasaje no pasa de cuartetos a quintetos a mitad. Los criterios de nivel lo resuelven sin
--     ambigüedad —«no varía → arquitectura»—, y es lo que el romance ya hace con sus cuatro
--     medidas. Pasa a arquitectura propia.
--
-- 2 · **Falta la hexasilábica.** Jauralde dice de la endecha real que sor Juana «también la
--     construyó con hexasílabos». Es una tercera medida, y por tanto una tercera arquitectura,
--     que no estaba declarada.
--
-- 3 · **La pregunta modelaba dos veces el mismo hecho.** El grupo `disposicion` ofrecía las
--     cinco variedades juntas con alcance de secuencia, mezclando lo que es elección de
--     arquitectura —la medida— con lo que es disposición de rima. El corolario «lo constante no
--     se pregunta» lo prohíbe: una alternativa estructural y constante en toda la secuencia debe
--     ser arquitectura, y elegirla *es* elegir la arquitectura. La excepción de ortogonalidad no
--     aplica: con tres arquitecturas no hay nada que multiplicar.
--
--     Queda una pregunta de rima por arquitectura, con las disposiciones que cada una admite, y
--     desaparecen las variedades, que existían solo para sostener aquella pregunta. Una
--     disposición de rima no crea nunca una arquitectura, y tampoco necesita una variedad
--     cuando ya es un esquema de rima de la suya.
--
-- 4 · **«No consta en el teatro español» no lo dice ninguna fuente.** Era inferencia propia, y
--     además opinaba sobre el corpus dentro de una descripción del catálogo. Sale.
--
-- Se añade además lo que Navarro Tomás documenta y se había perdido: que sor Juana hizo también
-- ese último verso decasílabo de dos adónicos, y que en los *Nocturnos de San Pedro* combina
-- endecha real y sexteto con un pie quebrado que repite en eco la rima del segundo heptasílabo
-- —la «variedad de la endecha real» que Jauralde trata entre las estrofas de seis versos—.
-- Las dos quedan como afirmación de fuente y no como arquitectura: son formas de seis versos, y
-- su sitio está en el sexteto cuando se revise.

begin;

do $$
declare
	v_forma uuid;
	v_arq_4 uuid;
	v_arq_5 uuid;
	v_arq_6 uuid;
	v_metrico_5 uuid;
	v_metrico_6 uuid;
	v_rima_5 uuid;
	v_rima_6 uuid;
	v_rasgo_vocales uuid;
	v_grupo uuid;
	v_nuevo_grupo uuid;
	v_arq_nueva uuid;
	v_asonantada uuid;
	v_suelta uuid;
	v_cruzada uuid;
	v_abrazada uuid;
	v_fuente_nt uuid;
	v_fuente_jauralde uuid;
	v_vocales integer;
	v_sobran integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecha_real';
	select fuente_id into v_fuente_nt from public.fuentes_metricas where anio = 1972;
	select fuente_id into v_fuente_jauralde from public.fuentes_metricas where anio = 2020;

	select arquitectura_id into v_arq_4
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heptasilabica_con_endecasilabo';

	select rasgo_id into v_rasgo_vocales from public.rasgos_metricos where slug = 'vocales_asonancia';

	-- ------------------------------------------------------------------
	-- 1 · Fuera el andamiaje: la pregunta que mezclaba medida y rima, y las
	--     variedades que solo existían para poblarla.
	-- ------------------------------------------------------------------

	delete from public.opciones_eleccion_metrica o
	using public.grupos_eleccion_metrica g
	where o.grupo_eleccion_id = g.grupo_eleccion_id
		and g.arquitectura_id = v_arq_4
		and g.slug = 'disposicion';

	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq_4 and slug = 'disposicion';

	delete from public.variedades_arquitectura where arquitectura_id = v_arq_4;

	-- Los dos esquemas que describen recipientes de otra medida se van con ellos.
	select esquema_metrico_id into v_metrico_5
	from public.esquemas_metricos where arquitectura_id = v_arq_4 and nombre = '7-7-7-7-11';

	select esquema_rima_id into v_rima_5
	from public.esquemas_rima where arquitectura_id = v_arq_4 and slug = 'redondilla_con_endecasilabo';

	-- ------------------------------------------------------------------
	-- 2 · La arquitectura de cinco versos, con lo que ya estaba escrito.
	-- ------------------------------------------------------------------

	insert into public.arquitecturas_forma
		(forma_id, slug, nombre, descripcion, principal, demarcable, modalidad, activo, orden, estado_revision)
	values
		(v_forma, 'heptasilabica_con_endecasilabo_de_cinco', 'Heptasilábica de cinco versos',
		 'Una redondilla heptasílaba y un endecasílabo final, repetidos durante toda la serie.',
		 false, true, 'excepcional', true, 2, 'revisada')
	returning arquitectura_id into v_arq_5;

	update public.esquemas_metricos
	set arquitectura_id = v_arq_5,
		slug = 'redondilla_con_endecasilabo',
		descripcion = 'Ciclo de cinco posiciones: cuatro heptasílabos y un endecasílabo.'
	where esquema_metrico_id = v_metrico_5;

	update public.esquemas_rima
	set arquitectura_id = v_arq_5,
		nombre = 'Redondilla con endecasílabo',
		modalidad = 'definitoria',
		descripcion = 'Una redondilla heptasílaba seguida de un endecasílabo que repite la rima de su primer verso.'
	where esquema_rima_id = v_rima_5;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	values (v_arq_5, v_rasgo_vocales, 'admitida',
		'La realización concreta declara las vocales que asuenan, sin crear una forma distinta.')
	on conflict do nothing;

	-- ------------------------------------------------------------------
	-- 3 · La hexasilábica, que faltaba.
	-- ------------------------------------------------------------------

	insert into public.arquitecturas_forma
		(forma_id, slug, nombre, descripcion, principal, demarcable, modalidad, activo, orden, estado_revision)
	values
		(v_forma, 'hexasilabica_con_endecasilabo', 'Hexasilábica con endecasílabo final',
		 'Tres hexasílabos y un endecasílabo por cuarteto, repetidos durante toda la serie.',
		 false, true, 'excepcional', true, 3, 'revisada')
	returning arquitectura_id into v_arq_6;

	insert into public.esquemas_metricos
		(arquitectura_id, nombre, slug, ambito, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq_6, '6-6-6-11', 'hexasilabica_con_endecasilabo', 'unidad', 'ciclo',
		 'Ciclo de cuatro posiciones: tres hexasílabos y un endecasílabo.', 'revisada')
	returning esquema_metrico_id into v_metrico_6;

	insert into public.esquemas_rima
		(arquitectura_id, nombre, slug, notacion, ambito, modalidad, tipo_secuencia, descripcion, estado_revision)
	values
		(v_arq_6, 'Asonancia sostenida en los versos cuartos', 'asonantada', '[---a]…', 'unidad',
		 'definitoria', 'ciclo',
		 'Una sola asonancia recorre la composición entera, en el endecasílabo que cierra cada cuarteto. Los tres hexasílabos quedan sueltos.', 'revisada')
	returning esquema_rima_id into v_rima_6;

	delete from public.esquema_rima_posiciones where esquema_rima_id = v_rima_6;
	insert into public.esquema_rima_posiciones
		(esquema_rima_id, bloque, seccion, posicion, ubicacion, clase_rima, suelto, opcional)
	values
		(v_rima_6, 1, null, 1, 'final', null, true, false),
		(v_rima_6, 1, null, 2, 'final', null, true, false),
		(v_rima_6, 1, null, 3, 'final', null, true, false),
		(v_rima_6, 1, null, 4, 'final', 'a', false, false);

	insert into public.esquema_rima_enlaces
		(esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
		 bloque_destino, posicion_destino, ubicacion_destino,
		 desplazamiento_bloque, tipo_enlace, obligatorio, nota)
	values
		(v_rima_6, 1, 4, 'final', 1, 4, 'final', 1, 'misma_rima', true,
		 'La asonancia del endecasílabo se mantiene en el cuarteto siguiente y en todos los demás.');

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	values (v_arq_6, v_rasgo_vocales, 'admitida',
		'La realización concreta declara las vocales que asuenan, sin crear una forma distinta.')
	on conflict do nothing;

	-- ------------------------------------------------------------------
	-- 4 · La pregunta que queda: qué disposición de rima, en la arquitectura
	--     de cuatro versos, que es la única que admite varias.
	-- ------------------------------------------------------------------

	select esquema_rima_id into v_asonantada from public.esquemas_rima where arquitectura_id = v_arq_4 and slug = 'asonantada';
	select esquema_rima_id into v_suelta from public.esquemas_rima where arquitectura_id = v_arq_4 and slug = 'suelta';
	select esquema_rima_id into v_cruzada from public.esquemas_rima where arquitectura_id = v_arq_4 and slug = 'cruzada';
	select esquema_rima_id into v_abrazada from public.esquemas_rima where arquitectura_id = v_arq_4 and slug = 'abrazada';

	if v_asonantada is null or v_suelta is null or v_cruzada is null or v_abrazada is null then
		raise exception 'Falta alguna de las cuatro disposiciones de la arquitectura de cuatro versos';
	end if;

	insert into public.grupos_eleccion_metrica
		(arquitectura_id, seccion_id, slug, nombre, ayuda_editor, dimension, alcance,
		 tipo_control, selecciones_min, selecciones_max, define_norma, permite_aplicar_global,
		 orden, activo, estado_revision)
	values
		(v_arq_4, null, 'disposicion_rima', '¿Cómo riman los cuartetos?',
		 'La asonancia sostenida es la forma corriente: una sola rima en el endecasílabo, mantenida durante todo el pasaje. Las otras tres cierran la rima dentro de cada cuarteto o prescinden de ella.',
		 'rima', 'secuencia', 'opciones', 1, 1, false, false, 1, true, 'revisada')
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica
		(grupo_eleccion_id, slug, nombre, descripcion, esquema_rima_id, orden, activo)
	values
		(v_grupo, 'asonantada', 'Asonancia sostenida',
		 'Una sola asonancia en el endecasílabo de cada cuarteto, que recorre el pasaje entero. Los tres heptasílabos quedan sueltos.',
		 v_asonantada, 1, true),
		(v_grupo, 'suelta', 'Sin rima',
		 'Los cuatro versos sueltos. Es la forma con que la combinación se empleó antes de recibir rimas.',
		 v_suelta, 2, true),
		(v_grupo, 'cruzada', 'Cruzada',
		 'El segundo heptasílabo rima con el endecasílabo, y la rima no pasa al cuarteto siguiente.',
		 v_cruzada, 3, true),
		(v_grupo, 'abrazada', 'Abrazada',
		 'El endecasílabo cierra con la rima del primer heptasílabo y los dos centrales riman entre sí.',
		 v_abrazada, 4, true);

	-- Y las vocales de la asonancia en las dos arquitecturas nuevas, con el mismo vocabulario
	-- que ya usan el romance y la de cuatro versos.
	foreach v_arq_nueva in array array[v_arq_5, v_arq_6]
	loop
		insert into public.grupos_eleccion_metrica
			(arquitectura_id, seccion_id, slug, nombre, ayuda_editor, dimension, alcance,
			 tipo_control, selecciones_min, selecciones_max, define_norma, permite_aplicar_global,
			 orden, activo, estado_revision)
		values
			(v_arq_nueva, null, 'vocales_asonancia', '¿Qué vocales caracterizan la asonancia?',
			 'Selecciona las vocales que comparten los endecasílabos. Esta elección no crea una forma distinta de endecha real.',
			 'rasgo', 'secuencia', 'opciones', 1, 1, false, false, 2, true, 'revisada')
		returning grupo_eleccion_id into v_nuevo_grupo;

		insert into public.opciones_eleccion_metrica
			(grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden, activo)
		select v_nuevo_grupo, o.slug, o.nombre, o.descripcion, o.valor_rasgo_id, o.orden, o.activo
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq_4 and g.slug = 'vocales_asonancia';
	end loop;

	-- ------------------------------------------------------------------
	-- 5 · Lo que las fuentes dicen de sor Juana, sin lo que yo les hice decir.
	-- ------------------------------------------------------------------

	update public.esquemas_rima
	set descripcion = 'Una redondilla heptasílaba seguida de un endecasílabo que repite la rima de su primer verso. Es una de las variedades métricas que sor Juana Inés de la Cruz introdujo en sus endechas.'
	where esquema_rima_id = v_rima_5;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, confianza, resumen, estado_revision)
	values
		(v_fuente_nt, v_forma, '§ 207, p. 283', 'alta',
		 'Sor Juana Inés de la Cruz **introdujo en sus endechas otras variedades métricas**: en unos casos formó la estrofa con una redondilla heptasílaba seguida de un endecasílabo, *abbaA*; en otras hizo que ese último verso fuera un **decasílabo compuesto de dos adónicos**. Dos poesías de sus *Nocturnos de San Pedro* presentan una combinación de endecha real y sexteto, con un tercer verso como pie quebrado que repite en eco la rima del segundo heptasílabo.', 'revisada'),
		(v_fuente_jauralde, v_forma, '§ 3.6, «Cuartetas de heptasílabos»', 'alta',
		 'Sor Juana Inés de la Cruz **también la construyó con hexasílabos**.', 'revisada'),
		(v_fuente_jauralde, v_forma, '«Variedad de la endecha real», entre las estrofas de seis versos', 'alta',
		 'Trata aparte una **variedad de seis versos**: las variantes que sor Juana ensayó sobre la forma clásica «con frecuencia alcanzaron al sexteto». Fue abundante a finales del siglo XVII y durante el XVIII —Vaca de Guzmán, Andrés Bello— y la cultivó con frecuencia Iriarte. Cuenta la endecha real entre las variedades históricamente más importantes, junto a la sextina y la copla de pie quebrado.', 'revisada');

	-- ------------------------------------------------------------------
	-- Comprobaciones
	-- ------------------------------------------------------------------

	-- Ninguna arquitectura de esta forma puede quedar sin rima declarada (D2b).
	select count(*) into v_sobran
	from public.arquitecturas_forma a
	where a.forma_id = v_forma
		and not exists (select 1 from public.esquemas_rima er where er.arquitectura_id = a.arquitectura_id);
	if v_sobran > 0 then
		raise exception '% arquitecturas de la endecha real no declaran cómo rima', v_sobran;
	end if;

	-- Cada arquitectura declara exactamente un esquema métrico: la medida es lo que las separa.
	select count(*) into v_sobran
	from public.arquitecturas_forma a
	where a.forma_id = v_forma
		and (select count(*) from public.esquemas_metricos em where em.arquitectura_id = a.arquitectura_id) <> 1;
	if v_sobran > 0 then
		raise exception '% arquitecturas de la endecha real no declaran una sola medida', v_sobran;
	end if;

	-- Las tres admiten el rasgo de las vocales, que es lo que se pregunta por secuencia.
	select count(*) into v_vocales
	from public.arquitectura_rasgos r
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	where a.forma_id = v_forma and r.rasgo_id = v_rasgo_vocales;
	if v_vocales <> 3 then
		raise exception 'Se esperaban 3 arquitecturas con vocales de asonancia y hay %', v_vocales;
	end if;

	-- Y las tres ofrecen el mismo repertorio de vocales, que es el del romance.
	select count(*) into v_sobran
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where a.forma_id = v_forma
		and g.slug = 'vocales_asonancia'
		and (select count(*) from public.opciones_eleccion_metrica o
		     where o.grupo_eleccion_id = g.grupo_eleccion_id) <> 19;
	if v_sobran > 0 then
		raise exception '% grupos de vocales no ofrecen las 19 asonancias', v_sobran;
	end if;

	raise notice 'Endecha real · 3 arquitecturas (7-7-7-11, 7-7-7-7-11, 6-6-6-11), 1 pregunta de rima, 12 afirmaciones';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
