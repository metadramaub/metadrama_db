-- La sextilla declara lo que su norma acota
--
-- Cuatro de sus esquemas abiertos decían «distribución variable» y nada más, de modo que la
-- ficha imprimía en rojo «El catálogo no declara restricciones». Era el pendiente 12ter, y al
-- ir a las seis fuentes salió que **la respuesta no era la que ese apunte suponía**: a
-- diferencia de la quintilla, cuyas fuentes prohíben tres versos seguidos con la misma rima,
-- ninguna fuente enuncia una regla para la sextilla. Quilis dice «varias combinaciones de
-- rima», el Diccionario «variadas disposiciones» y Jauralde que «la disposición de las rimas
-- varía de una a otra composición».
--
-- Así que lo declarable no se transcribe de una regla: se deriva del repertorio documentado.
-- Da dos restricciones y media. Las dos: **ningún verso suelto** y **al menos tres
-- alternancias**, que es el mínimo de todas las disposiciones documentadas —`aabaab` 3,
-- `aabccb` 3, `aababa` 4, `ababab` 5, `abcabc` 5—. La media: las clases de rima son **dos o
-- tres**, y `numero_clases` solo admite un valor, así que no se declara y se dice en la
-- definición. No se usa `max_consecutivos` porque `incumple`, en el auditor, no lo evalúa:
-- sería una norma sin guarda.
--
-- **Los versos sueltos quedan fuera por criterio cronológico**, por decisión del IP. Tres
-- fuentes documentan una sextilla con el primer verso sin rima —Caparrós 2014 la escribe
-- `- a a b b a`, Quilis la marca `abbccb` llamando `a` a una clase que aparece una sola vez, y
-- Navarro Tomás dice «con el primer verso suelto»—, pero es el *Martín Fierro*, de 1872: el
-- mismo corte que dejó fuera las disposiciones hexasílabas de Navarro Tomás y los ejemplos
-- tardíos del romance heroico. El caso se conserva en las afirmaciones y queda anotado en
-- cuestiones para el IP.
--
-- Y se corrige un error de hecho: la hexasilábica decía que Rubén Darío «tomó el nombre de
-- lay». El Diccionario dice lo contrario —es forma medieval de origen francoprovenzal
-- «imitada por Rubén Darío en el ejemplo citado»—, así que el nombre no es suyo.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición de la forma
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de seis versos de arte menor con rima consonante cuya disposición no está fijada. La tradición ha nombrado algunas de sus disposiciones —alterna, correlativa, simétrica— y admite que uno o más versos se quiebren en otros más breves, que es la variedad de la que procede la copla manriqueña.';
	v_nuevo constant text :=
		'Estrofa de seis versos de arte menor que riman todos en consonante. Su disposición no está fijada: la tradición documenta media docena, siempre con dos o tres clases de rima, y ha dado nombre propio a las más frecuentes —alterna, correlativa, simétrica—. Cuando el tercer verso y el sexto se quiebran en otros más breves resulta la sextilla de pie quebrado, de la que procede la copla de Jorge Manrique.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «sextilla».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la sextilla no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Las cinco descripciones de arquitectura
--
-- Todas abrían diciendo la medida, que la fila «Medida» dibuja, y tres de ellas repetían los
-- nombres que ya imprime la línea «También». Se quedan con lo suyo, y la hexasilábica corrige
-- lo que atribuía mal a Rubén Darío.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	for fila in
		select *
		from (values
			(
				'octosilabica',
				'Seis octosílabos. Es la medida más documentada y la que sostiene las disposiciones con nombre propio.',
				'La medida más documentada y la única con disposiciones de nombre propio. Con los octosílabos enteros, sin quebrar, se usó poco: la sextilla octosilábica vive sobre todo dentro de la copla de pie quebrado.'
			),
			(
				'pie_quebrado',
				'Dos grupos de tres versos, cada uno cerrado por un verso más breve que los octosílabos que lo preceden. Es la sextilla de la que procede la copla de Jorge Manrique.',
				'Es la sextilla más conocida, y la que dio fama a la estrofa: Jorge Manrique la empleó en las coplas por la muerte de su padre. El quiebro cae normalmente en el tercer verso y el sexto, pero la tradición lo documenta también en otras posiciones.'
			),
			(
				'doble_pie_quebrado',
				'Doce versos en dos sextillas de pie quebrado. La disposición abcabc:defdef es la que la tradición llama copla manriqueña.',
				'Dos sextillas que el sentido enlaza en una sola estrofa, aunque cada una conserve sus propias rimas.'
			),
			(
				'heptasilabica',
				'Seis heptasílabos.',
				'Las fuentes la reconocen como medida de la sextilla, pero solo la ejemplifican con poesía moderna.'
			),
			(
				'hexasilabica',
				'Seis hexasílabos, medida de la que Rubén Darío tomó el nombre de lay.',
				'La medida del lay, canción amorosa breve de origen francoprovenzal con insistentes rimas agudas. Es forma medieval, poco usada en castellano, que Rubén Darío imitó siglos después.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» de la sextilla.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de sextilla/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La disposición manriqueña se llama por su nombre
--
-- El esquema `abcabc|defdef` no tenía `nombre`, así que la ficha lo rotulaba con su notación y
-- la restricción que lo excluye tenía que explicarse en prosa —«la disposición manriqueña, que
-- es el otro esquema de esta arquitectura»—. Con el nombre declarado, la frase derivada dice
-- ya «No puede coincidir con «Manriqueña»» y la prosa sobra. Es la regla 1 al revés: una nota
-- no debe llevar un dato que el catálogo puede declarar.
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_actual text;
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'sextilla' and a.slug = 'doble_pie_quebrado' and er.slug = 'abcabc-defdef';

	if v_esquema is null then
		raise exception 'No existe el esquema «abcabc-defdef» de la sextilla.';
	end if;

	select nombre into v_actual from public.esquemas_rima where esquema_rima_id = v_esquema;
	if v_actual is not null and v_actual is distinct from 'Manriqueña' then
		raise exception 'El esquema «abcabc-defdef» ya tiene nombre: %', v_actual;
	end if;

	update public.esquemas_rima set nombre = 'Manriqueña' where esquema_rima_id = v_esquema;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · Las cuatro descripciones de esquema de rima
--
-- Las tres de disposiciones concretas leen en prosa la figura que hay encima: que la simétrica
-- son dos mitades con la misma disposición interna, que la correlativa repite sus tres rimas en
-- el mismo orden, que las dos sextillas de la manriqueña no comparten rima. La cuarta resumía
-- las dos restricciones que se imprimen a su lado.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Dos mitades de tres versos con la misma disposición interna, enlazadas por la rima que cierra cada una.',
		'Tres rimas que reaparecen en el mismo orden en la segunda mitad, de modo que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto.',
		'Cada sextilla emplea tres clases de rima distintas de las de la otra.',
		'El patrón debe ser regular y no coincidir con el patrón manriqueño.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	select count(*) into v_ajenas
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and er.descripcion is not null
		and not (er.descripcion = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La sextilla tiene % descripciones de esquema de rima distintas de las esperadas.', v_ajenas;
	end if;

	update public.esquemas_rima er
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and er.descripcion is not null;

	select count(*) into v_restantes
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and er.descripcion is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % descripciones de esquema de rima en la sextilla.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · Las dos descripciones de restricción
--
-- Con el nombre del esquema declarado, las dos redacciones por tipo dicen lo mismo sin
-- escribirlo: «No puede coincidir con «Manriqueña»» y «La disposición debe ser regular, aunque
-- el catálogo no fije cuál». Las restricciones estructuradas **se conservan**.
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_ajenas integer;
	v_esperadas constant text[] := array[
		'No puede coincidir con la disposición manriqueña, que es el otro esquema de esta arquitectura.',
		'La disposición debe ser regular, aunque la norma no fije cuál.'
	];
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'sextilla' and a.slug = 'doble_pie_quebrado' and er.slug = 'consonante-variable';

	if v_esquema is null then
		raise exception 'No existe el esquema «consonante-variable» de la sextilla.';
	end if;

	select count(*) into v_ajenas
	from public.esquema_rima_restricciones
	where esquema_rima_id = v_esquema
		and descripcion is not null
		and not (descripcion = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La sextilla tiene % descripciones de restricción distintas de las esperadas.', v_ajenas;
	end if;

	update public.esquema_rima_restricciones
	set descripcion = null
	where esquema_rima_id = v_esquema and descripcion is not null;

	if (select count(*) from public.esquema_rima_restricciones where esquema_rima_id = v_esquema) <> 2 then
		raise exception 'Las dos restricciones de la doble sextilla no siguen ahí.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · Los cuatro esquemas abiertos declaran su norma
--
-- Cierra el pendiente 12ter para la sextilla. `min_alternancias` es el mínimo del repertorio
-- documentado y `versos_sueltos` queda en «ninguno» por el criterio cronológico. `D13`
-- contrastará las tres disposiciones concretas de la octosilábica contra este criterio:
-- `ababab` da 2 clases y 5 alternancias, `abcabc` 3 y 5, `aabccb` 3 y 3. Ninguna lo rompe.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_esquema uuid;
	v_cuantos integer := 0;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	for fila in
		select a.slug, er.esquema_rima_id
		from public.esquemas_rima er
		join public.arquitecturas_forma a using (arquitectura_id)
		where a.forma_id = v_forma and er.slug = 'distribucion-variable' and a.activo
	loop
		v_esquema := fila.esquema_rima_id;

		insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_texto)
		select v_esquema, 'versos_sueltos', 'ninguno'
		where not exists (
			select 1 from public.esquema_rima_restricciones
			where esquema_rima_id = v_esquema and tipo = 'versos_sueltos'
		);

		insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_numero)
		select v_esquema, 'min_alternancias', 3
		where not exists (
			select 1 from public.esquema_rima_restricciones
			where esquema_rima_id = v_esquema and tipo = 'min_alternancias'
		);

		v_cuantos := v_cuantos + 1;
	end loop;

	if v_cuantos <> 4 then
		raise exception 'Se esperaban 4 esquemas abiertos de la sextilla; se encontraron %.', v_cuantos;
	end if;

	-- Una guarda que comprueba lo que toca: ninguno de los cuatro se queda sin norma.
	if exists (
		select 1
		from public.esquemas_rima er
		join public.arquitecturas_forma a using (arquitectura_id)
		where a.forma_id = v_forma
			and er.tipo_secuencia = 'abierta'
			and not exists (
				select 1 from public.esquema_rima_restricciones r
				where r.esquema_rima_id = er.esquema_rima_id
			)
	) then
		raise exception 'Algún esquema abierto de la sextilla sigue sin declarar restricciones.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 7 · Las dos descripciones de esquema métrico
--
-- Decían en qué posiciones caen los quebrados, que es lo que la rejilla dibuja con sus celdas
-- «4/5». Y ninguna de las dos llegaba al navegador.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Dos sextillas con pies quebrados en las posiciones 3, 6, 9 y 12.',
		'Los pies quebrados ocupan las posiciones tercera y sexta.'
	];
	v_ajenas integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	select count(*) into v_ajenas
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and em.descripcion is not null
		and not (em.descripcion = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La sextilla tiene % descripciones de esquema métrico distintas de las esperadas.', v_ajenas;
	end if;

	update public.esquemas_metricos em
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and em.descripcion is not null;
end $$;

-- ---------------------------------------------------------------------------
-- 8 · Las cinco notas de rasgo
--
-- Cuatro contaban de dónde se deriva el dato —«Se deriva del patrón métrico», «Se deriva de las
-- posiciones métricas»— o repetían la densidad que la fila ya imprime. La quinta llevaba dentro
-- un hecho que no se deriva de nada, que el quiebro cae también en otras posiciones, y ese sube
-- a la descripción de su arquitectura.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Se deriva del patrón métrico 8-8-4-8-8-4. Tercero y sexto son las posiciones típicas, pero no las únicas que la tradición documenta.',
		'Se deriva de las posiciones métricas 3, 6, 9 y 12.',
		'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	select count(*) into v_ajenas
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and ar.nota is not null
		and not (ar.nota = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La sextilla tiene % notas de rasgo distintas de las esperadas.', v_ajenas;
	end if;

	update public.arquitectura_rasgos ar
	set nota = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = ar.arquitectura_id
		and a.forma_id = v_forma
		and ar.nota is not null;

	select count(*) into v_restantes
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and ar.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de rasgo en la sextilla.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 9 · Con qué se relaciona
--
-- No tenía ninguna relación, y son las dos que sitúan la forma: el sexteto es su equivalente de
-- arte mayor, y la sextilla de pie quebrado es el caso más frecuente de la copla de pie
-- quebrado, que el catálogo registra aparte.
-- ---------------------------------------------------------------------------
do $$
declare
	v_sextilla uuid;
	fila record;
begin
	select forma_id into v_sextilla
	from public.formas_metricas where slug = 'sextilla' and activo;

	for fila in
		select *
		from (values
			(
				'sexteto',
				'contrasta_con',
				'La misma estrofa de seis versos, separada por el arte de sus versos: se llama sextilla cuando son de arte menor y sexteto cuando son de arte mayor o mezclan las dos medidas.'
			),
			(
				'copla_de_pie_quebrado',
				'relacionada_con',
				'La sextilla de pie quebrado es la más frecuente de las coplas de pie quebrado, que es la forma general de la estrofa octosilábica con algún verso quebrado y admite otras extensiones.'
			)
		) as t(destino, tipo, nota)
	loop
		insert into public.forma_relaciones (
			forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
		)
		select
			v_sextilla,
			(select forma_id from public.formas_metricas where slug = fila.destino and activo),
			fila.tipo,
			fila.nota,
			'aprobada'
		where not exists (
			select 1 from public.forma_relaciones
			where forma_origen_id = v_sextilla
				and forma_destino_id = (select forma_id from public.formas_metricas where slug = fila.destino)
				and tipo_relacion = fila.tipo
		);

		update public.forma_relaciones
		set nota = fila.nota
		where forma_origen_id = v_sextilla
			and forma_destino_id = (select forma_id from public.formas_metricas where slug = fila.destino)
			and tipo_relacion = fila.tipo;
	end loop;

	if (select count(*) from public.forma_relaciones where forma_origen_id = v_sextilla) <> 2 then
		raise exception 'La sextilla no tiene sus dos relaciones.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 10 · Lo que las fuentes añaden y el catálogo no declara
--
-- El verso suelto queda fuera del catálogo por criterio cronológico, así que su testimonio
-- tiene que estar completo en las afirmaciones: la notación exacta de Caparrós y el desacuerdo
-- de Quilis, que lee la misma estrofa marcando ese verso como una clase que no vuelve. Y se
-- añade la entrada del Diccionario sobre el lay, que es de donde salía —mal atribuido— Rubén
-- Darío.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_id uuid;
	v_actual text;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	for fila in
		select *
		from (values
			(
				'1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid,
				'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, y con un poema de Manuel Machado compuesto en heptasílabos. Describe la copla de Jorge Manrique como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c y recoge que se ha considerado también estrofa de doce versos cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada una.',
				'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, cuyo esquema escribe `- a a b b a`: el primer verso queda sin rima. El poema de Manuel Machado que cita en heptasílabos rima `aababa`. Describe la copla de Jorge Manrique como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c y recoge que se ha considerado también estrofa de doce versos cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada una.'
			),
			(
				'51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid,
				'Define la sextilla como estrofa de versos de arte menor con varias combinaciones de rima, y cita aabaab, abcabc y ababab. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos.',
				'Define la sextilla como estrofa de versos de arte menor con varias combinaciones de rima, y cita aabaab, abcabc y ababab. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez Caparrós escribe un guion.'
			)
		) as t(fuente, viejo, nuevo)
	loop
		select afirmacion_id, resumen into v_id, v_actual
		from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = fila.fuente;

		if v_id is null then
			raise exception 'Falta una afirmación esperada de la sextilla.';
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'Una afirmación de la sextilla no es la esperada. Dice: %', v_actual;
		end if;

		update public.afirmaciones_fuentes_metricas set resumen = fila.nuevo where afirmacion_id = v_id;
	end loop;
end $$;

-- El lay, en la arquitectura de la que habla, y con lo que el Diccionario dice de verdad.
do $$
declare
	v_arq uuid;
	v_resumen constant text :=
		'Define el lay como poema breve de asunto amoroso que suele emplear la sextilla hexasílaba con dos rimas consonantes agudas, una en los versos primero, segundo, cuarto y quinto y otra en el tercero y el sexto, es decir `aabaab`. Añade que es forma medieval de origen francoprovenzal, menos usada en castellano que en las literaturas de donde procede, e imitada por Rubén Darío en el ejemplo que cita.';
	v_cuantas integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'sextilla' and a.slug = 'hexasilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa sextilla/hexasilabica.';
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, arquitectura_id, localizador, resumen, confianza, estado_revision
	)
	select
		'2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid,
		v_arq,
		'Entrada «lay», p. 148',
		v_resumen,
		'alta',
		'aprobada'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where arquitectura_id = v_arq
			and fuente_id = '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid
			and localizador = 'Entrada «lay», p. 148'
	);

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where arquitectura_id = v_arq and resumen = v_resumen;

	if v_cuantas <> 1 then
		raise exception 'La afirmación del lay aparece % veces.', v_cuantas;
	end if;
end $$;

commit;
