-- La lira dice de dónde viene su nombre
--
-- Diez de sus dieciséis textos no se ven, y los diez repiten lo dibujado. **Las siete
-- descripciones de variedad son el caso más limpio de la revisión entera**: dicen «7-11-7-11-7-11
-- con rima ababcc», que es literalmente lo que la fila imprime al lado, en el mismo orden y con
-- las mismas cifras. Y las tres notas de posición de la lira no llegan siquiera al navegador; una
-- de ellas, «Tercer heptasílabo», está además en la cuarta posición y es ambigua se cuente como
-- se cuente.
--
-- Lo que se queda crece. La definición de la lira decía que «alterna heptasílabos y
-- endecasílabos», y `7 11 7 7 11` no alterna: tiene dos heptasílabos seguidos. Ahora da la
-- notación, de dónde viene el nombre —el primer verso de «A la flor de Gnido»— y qué salió de
-- ella. Su arquitectura, que estaba muda siendo la única, dice por qué es una sola.
--
-- Y la del sexteto-lira deja claro **qué es una variedad**: no una disposición de rima, sino una
-- pareja de medida y rima. Se comprueba con el dato: la misma disposición `ababcc` está en tres
-- variedades distintas, cada una con otro orden de medidas.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición de la lira
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de cinco versos que alterna heptasílabos y endecasílabos con rima consonante repartida en dos clases, y cierra en pareado.';
	v_nuevo constant text :=
		'Estrofa de cinco versos —7 11 7 7 11— con rima consonante repartida en dos clases y cierre en pareado: aBabB. La introdujo Garcilaso en la canción «A la flor de Gnido», y de su primer verso —«Si de mi baja lira»— toma el nombre; fray Luis de León la consagró hasta darle otro. Es el molde breve de la lírica renacentista española, y de ella salen el sexteto-lira, que la amplía a seis versos, y las estrofas aliradas en general.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'lira' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «lira».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la lira no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura de la lira, que estaba sin describir
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_nuevo constant text :=
		'Realización única de la lira: cinco versos con sus medidas y sus dos rimas siempre en el mismo orden. No hay variantes documentadas, y por eso la forma tiene una sola arquitectura.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'lira' and a.slug = 'heptasilabica_endecasilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa lira/heptasilabica_endecasilabica.';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;

	if v_actual is not null and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no estaba vacía. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;

	-- La descripción afirma que la lira tiene una sola arquitectura: se comprueba.
	if (
		select count(*) from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'lira' and a.activo
	) <> 1 then
		raise exception 'La lira ya no tiene una sola arquitectura.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La definición del sexteto-lira dice qué es una variedad
--
-- «Cada realización se registra por la tipología observada» es lenguaje de anotación, y además
-- «tipología» se usa en el catálogo para disposiciones de rima —las ocho de la quintilla—. Una
-- variedad es otra cosa: empareja medida **y** rima.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_disposiciones integer;
	v_viejo constant text :=
		'Lira de seis versos: estrofa de heptasílabos y endecasílabos con rima consonante en tres clases, cuyos cuatro primeros versos alternan o abrazan las dos primeras y cuyos dos últimos cierran con un pareado que introduce la tercera. El orden de las medidas y la disposición de las rimas varían conjuntamente, de modo que cada realización se registra por la tipología observada.';
	v_nuevo constant text :=
		'Lira de seis versos: estrofa de heptasílabos y endecasílabos con rima consonante en tres clases, cuyos cuatro primeros versos alternan o abrazan las dos primeras y cuyos dos últimos cierran con un pareado que introduce la tercera. Lo que cambia de una realización a otra no es solo la rima ni solo la medida, sino las dos a la vez: por eso sus siete variedades no son disposiciones de rima sino parejas de medida y rima, y la misma disposición ababcc aparece en tres de ellas con tres órdenes de medidas distintos. La más corriente es aBaBcC, la que fray Luis de León empleó en sus traducciones de Horacio, y lo único que la separa de la sexta rima italiana es que los endecasílabos impares se sustituyan por heptasílabos.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto_lira' and activo;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del sexteto-lira no es la esperada. Dice: %', v_actual;
	end if;

	-- La definición afirma que `ababcc` está en tres variedades: se comprueba antes de escribirlo.
	select count(*) into v_disposiciones
	from public.variedades_arquitectura v
	join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id
	join public.esquemas_rima er on er.esquema_rima_id = v.esquema_rima_id
	where a.forma_id = v_forma and v.activo and er.notacion = 'ababcc';

	if v_disposiciones <> 3 then
		raise exception 'La disposición ababcc está en % variedades, no en tres.', v_disposiciones;
	end if;

	if (
		select count(*) from public.variedades_arquitectura v
		join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id
		where a.forma_id = v_forma and v.activo
	) <> 7 then
		raise exception 'El sexteto-lira no tiene siete variedades.';
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La arquitectura del sexteto-lira pierde lo que ahora dice su definición
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_viejo constant text :=
		'Seis versos que combinan heptasílabos y endecasílabos y terminan en endecasílabo. La tipología determina conjuntamente el orden de las medidas y la distribución de las tres rimas.';
	v_nuevo constant text :=
		'Seis versos que combinan heptasílabos y endecasílabos y terminan siempre en endecasílabo.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and a.activo;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · Los diez textos que no se ven
--
-- Las siete descripciones de variedad y las tres notas de posición métrica de la lira.
-- ---------------------------------------------------------------------------
do $$
declare
	v_formas uuid[];
	v_restantes integer;
begin
	select array_agg(forma_id) into v_formas
	from public.formas_metricas where slug in ('lira', 'sexteto_lira') and activo;

	if array_length(v_formas, 1) <> 2 then
		raise exception 'No están las dos formas activas.';
	end if;

	update public.variedades_arquitectura v
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = v.arquitectura_id
		and a.forma_id = any (v_formas)
		and v.descripcion is not null;

	update public.esquema_metrico_posiciones p
	set nota = null
	from public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = p.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = any (v_formas)
		and p.nota is not null;

	select
		(select count(*) from public.variedades_arquitectura v join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id where a.forma_id = any (v_formas) and v.descripcion is not null)
		+ (select count(*) from public.esquema_metrico_posiciones p join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id where a.forma_id = any (v_formas) and p.nota is not null)
	into v_restantes;

	if v_restantes > 0 then
		raise exception 'Quedan % textos ocultos en la lira y el sexteto-lira.', v_restantes;
	end if;

	-- La nota del final acentual se conserva, como en el soneto y la canción.
	if (
		select count(*) from public.arquitectura_rasgos ar
		join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
		where a.forma_id = any (v_formas) and ar.nota is not null
	) <> 1 then
		raise exception 'La nota del final acentual ha desaparecido.';
	end if;
end $$;

commit;
