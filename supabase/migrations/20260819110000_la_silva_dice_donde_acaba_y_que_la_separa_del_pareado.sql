-- La silva dice dónde acaba y qué la separa del pareado
--
-- Su prosa menor era casi toda invisible: las seis notas y descripciones de esquema solo se
-- leían pulsando un icono, y dos de ellas repetían la fila que tenían encima.
--
-- Lo que se retira es lo dibujado; lo que se queda se afina. Y entra la relación que faltaba,
-- que responde a una pregunta legítima: si un pareado también puede combinar medidas distintas,
-- ¿en qué se diferencia de la silva de consonantes? **Morley y Bruerton lo reconocen ellos
-- mismos** —de su silva 1.ª escriben que «se podría llamar pareados de 7 y 11»—, y esa frase no
-- estaba en su afirmación. Se añade, y la relación explica el corte que el catálogo sí hace: la
-- silva fija la alternancia de siete y once y corre como serie; el pareado es una estrofa de dos
-- versos cuya medida declara el pasaje y que admite también asonancia.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Serie abierta de endecasílabos y heptasílabos —o solo de endecasílabos— con rima consonante dispuesta libremente y sin división posible en estrofas simétricas, que admite versos sueltos. Lo que cambia de una realización a otra es cuánto organizan los pareados la serie, desde el par sistemático hasta su ausencia. La rima es aquí condición: un pasaje de siete y once enteramente suelto no es una silva.';
	v_nuevo constant text :=
		'Serie de endecasílabos y heptasílabos —o solo de endecasílabos— con rima consonante dispuesta libremente, por lo que no se deja dividir en estrofas simétricas. Lo que cambia de una realización a otra es cuánto organizan los pareados la serie, desde el par sistemático hasta su ausencia. La rima es aquí condición: un pasaje enteramente suelto no es una silva.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «silva».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la silva no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Tres descripciones de arquitectura
--
-- La endecasilábica **no se toca**: su frase sobre el corte con el endecasílabo suelto es la
-- frontera del catálogo y ya estaba bien dicha.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva' and activo;

	for fila in
		select *
		from (values
			(
				'consonante_irregular',
				'Heptasílabos y endecasílabos sin orden fijo de medida ni de rima, con versos sueltos entre los rimados. Es la silva ordinaria, y la más frecuente del corpus.',
				'Es la silva ordinaria y la más frecuente del corpus: la de las *Soledades*. Los pareados dominan sin llegar a formar pauta.'
			),
			(
				'consonante_regular',
				'Alterna heptasílabo y endecasílabo en pareados que se suceden sin excepción, de modo que el pareado funciona aquí como unidad. Es la que la tradición llama silva de consonantes.',
				'Alterna heptasílabo y endecasílabo en pareados que se suceden sin excepción, de modo que el pareado funciona aquí como unidad. Es la única silva que se ajusta a un esquema.'
			),
			(
				'libre',
				'Realización de siete y once cuya rima no llega a formar pareados. «Libre» nombra aquí ese extremo de la escala; no la silva libre moderna, que es una serie de medidas mezcladas y por lo común sin rima.',
				'«Libre» nombra aquí el extremo de la escala en que la rima, mayoritaria o total, no llega a formar pareados; no la silva libre moderna, que es una serie de medidas mezcladas y por lo común sin rima.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» de la silva.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de silva/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · Las dos descripciones de esquema métrico
--
-- «Cada verso puede ser heptasílabo o endecasílabo sin una secuencia posicional fija» es
-- literalmente la fila «Medida — Variable · verso a verso · 7 · 11 sílabas».
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperada constant text :=
		'Cada verso puede ser heptasílabo o endecasílabo sin una secuencia posicional fija.';
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva' and activo;

	select count(*) into v_ajenas
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and em.descripcion is not null
		and em.descripcion is distinct from v_esperada;

	if v_ajenas > 0 then
		raise exception 'La silva tiene % descripciones de esquema métrico distintas de la esperada.', v_ajenas;
	end if;

	update public.esquemas_metricos em
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and em.descripcion is not null;

	select count(*) into v_restantes
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and em.descripcion is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % descripciones de esquema métrico en la silva.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · Las notas de rasgo
--
-- Se retira la de la silva regular, que repite el valor `Regulares`, la banda «pareado» y la
-- fila «Partes». Se acorta la de la de orden libre, quitando lo que dice su propio valor. **Se
-- conservan** la de la libre —porque `Ninguna` no significa cero pareados, y eso no se deriva—
-- y la de la endecasilábica, cuyo intervalo del 50 al 98 % aclara justo donde hace falta.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_actual text;
	v_viejo constant text :=
		'Los pareados predominan, pero no forman una pauta regular ni excluyen otros enlaces.';
	v_nuevo constant text := 'No forman pauta regular ni excluyen otros enlaces.';
	v_borradas integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva' and activo;
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'organizacion_en_pareados';

	if v_rasgo is null then
		raise exception 'No existe el rasgo «organizacion_en_pareados».';
	end if;

	-- La de la silva regular se va.
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	where a.forma_id = v_forma and a.slug = 'consonante_regular';

	update public.arquitectura_rasgos
	set nota = null
	where arquitectura_id = v_arq
		and rasgo_id = v_rasgo
		and nota is distinct from null
		and nota = 'El pareado constituye la unidad regular de organización de esta arquitectura.';
	get diagnostics v_borradas = row_count;

	if v_borradas not in (0, 1) then
		raise exception 'Se esperaba una nota en la silva regular; se tocaron %.', v_borradas;
	end if;

	if (
		select nota from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo
	) is not null then
		raise exception 'La nota de la silva regular sigue ahí.';
	end if;

	-- La de la de orden libre se acorta.
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	where a.forma_id = v_forma and a.slug = 'consonante_irregular';

	select nota into v_actual
	from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la silva de orden libre no es la esperada. Dice: %', v_actual;
	end if;

	update public.arquitectura_rasgos
	set nota = v_nuevo
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;

	-- Y las dos que se conservan siguen ahí.
	if (
		select count(*)
		from public.arquitectura_rasgos ar
		join public.arquitecturas_forma a using (arquitectura_id)
		where a.forma_id = v_forma and ar.nota is not null
	) <> 3 then
		raise exception 'La silva no conserva las tres notas de rasgo esperadas.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · La afirmación de Morley y Bruerton recoge que ellos ya vieron el solape
--
-- De su silva 1.ª escriben «se podría llamar pareados de 7 y 11», y esa frase es justamente la
-- que responde a por qué la silva de consonantes y el pareado se parecen tanto.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'Distinguen cuatro tipos: la silva de consonantes aAbBcC; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**.';
	v_nuevo constant text :=
		'Distinguen cuatro tipos: la silva de consonantes aAbBcC, de la que dicen que «se podría llamar pareados de 7 y 11»; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva' and activo;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;

	if v_id is null then
		raise exception 'No existe la afirmación de Morley y Bruerton sobre la silva.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación de Morley y Bruerton no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · Qué separa la silva del pareado
--
-- La silva no declaraba ninguna relación. Esta explica el corte que el catálogo hace y que ya
-- estaba operativo en la ayuda del editor sin leerse en ninguna ficha.
-- ---------------------------------------------------------------------------
do $$
declare
	v_silva uuid;
	v_pareado uuid;
	v_nota constant text :=
		'En el fondo son la misma figura: la silva de consonantes podría llamarse pareados de siete y once. Lo que las separa es que la silva fija esa alternancia y corre como serie abierta, mientras que el pareado es una estrofa de dos versos cuya medida declara cada pasaje y que admite también asonancia. De ahí que una serie de solo endecasílabos con pareados sistemáticos se registre como tirada de pareados y no como silva: sin heterometría no queda nada que las distinga.';
begin
	select forma_id into v_silva from public.formas_metricas where slug = 'silva' and activo;
	select forma_id into v_pareado from public.formas_metricas where slug = 'pareado' and activo;

	if v_pareado is null then
		raise exception 'No existe la forma activa «pareado».';
	end if;

	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
	)
	select v_silva, v_pareado, 'contrasta_con', v_nota, 'aprobada'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_silva
			and forma_destino_id = v_pareado
			and tipo_relacion = 'contrasta_con'
	);

	update public.forma_relaciones
	set nota = v_nota
	where forma_origen_id = v_silva
		and forma_destino_id = v_pareado
		and tipo_relacion = 'contrasta_con';

	if (
		select count(*) from public.forma_relaciones
		where forma_origen_id = v_silva and forma_destino_id = v_pareado
	) <> 1 then
		raise exception 'La relación con el pareado no quedó una y sola una.';
	end if;
end $$;

commit;
