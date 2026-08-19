-- El soneto dice la regla de sus tercetos
--
-- Es la forma más limpia del catálogo: solo cinco textos de prosa. Pero su definición estaba
-- casi entera dibujada —los catorce versos, los endecasílabos, el régimen, el reparto en
-- cuartetos y tercetos, `ABBA ABBA`, la cruzada como excepcional y hasta los rótulos «una de 2»
-- y «una de 4»— y le faltaba lo único que explica por qué esa parte varía y las demás no.
--
-- Esa regla la da el *Diccionario*: los tercetos toman dos o tres clases nuevas y las reparten
-- como sea **con tal de que no haya más de dos versos seguidos con la misma rima**. Con ella la
-- definición deja de enumerar lo dibujado y dice de dónde salen las cuatro disposiciones —y de
-- paso responde a la duda de si su repertorio es abierto: lo es, porque hay una regla y no una
-- lista.
--
-- La arquitectura, que no decía nada, recoge lo histórico, que hoy solo se lee al final entre
-- las fuentes.
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
		'Composición fija de catorce versos endecasílabos con rima consonante, repartida en dos cuartetos y dos tercetos. Los ocho primeros versos llevan dos clases de rima, abrazadas —ABBA ABBA— en la disposición regular, aunque también se documenta la cruzada. Los dos tercetos llevan dos o tres clases distintas de las anteriores, y su disposición varía: es la única parte del soneto que no está fijada de antemano.';
	v_nuevo constant text :=
		'Composición de catorce versos endecasílabos repartidos en dos cuartetos y dos tercetos. Los cuartetos comparten sus dos clases de rima y llevan casi siempre la misma disposición; los tercetos toman dos o tres clases nuevas y las reparten con una sola condición, que no haya más de dos versos seguidos con la misma rima. De ahí que sea la única parte del soneto que no está fijada de antemano.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'soneto' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «soneto».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del soneto no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura, que estaba sin describir
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_nuevo constant text :=
		'Boscán y Garcilaso son sus introductores efectivos: Santillana lo había intentado un siglo antes, pero aquel ensayo no tuvo continuidad. En el Barroco alcanza su mayor auge.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'soneto' and a.slug = 'endecasilabica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa soneto/endecasilabica_consonante.';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;

	if v_actual is not null and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no estaba vacía. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La nota de posición métrica, invisible y dibujada
--
-- «Este modelo se repite en los catorce versos de la composición» no llega al navegador —la
-- función pública no envía esta columna— y lo dice la fila «Medida», que los pinta uno a uno.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperada constant text := 'Este modelo se repite en los catorce versos de la composición.';
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'soneto' and activo;

	select count(*) into v_ajenas
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and p.nota is not null and p.nota is distinct from v_esperada;

	if v_ajenas > 0 then
		raise exception 'El soneto tiene % notas de posición métrica distintas de la esperada.', v_ajenas;
	end if;

	update public.esquema_metrico_posiciones p
	set nota = null
	from public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = p.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and p.nota is not null;

	select count(*) into v_restantes
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and p.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de posición métrica en el soneto.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · Las dos notas de relación dicen qué se hereda y qué no
--
-- «Forman los ocho primeros versos» y «los seis últimos» está en la fila «Partes» y en el
-- dibujo. Lo que no está en ninguna parte es lo que de verdad importa de la reutilización: el
-- soneto toma de esas formas la medida, la extensión y la identidad, **pero no la rima**, que
-- declara él. Es además la única forma del catálogo donde la parte que reutiliza trae sus
-- propios esquemas: en las otras diecisiete la rima sí se hereda.
-- ---------------------------------------------------------------------------
do $$
declare
	v_soneto uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_soneto from public.formas_metricas where slug = 'soneto' and activo;

	for fila in
		select *
		from (values
			(
				'cuarteto',
				'Los dos cuartetos forman los ocho primeros versos y comparten sus dos clases de rima.',
				'El soneto no hereda del cuarteto su rima, solo su medida y su extensión: las dos clases las declara él, y son las mismas en los dos cuartetos.'
			),
			(
				'terceto',
				'Los dos tercetos forman los seis últimos versos y entrelazan entre sí sus clases de rima.',
				'El soneto no hereda del terceto su rima, solo su medida y su extensión: las dos o tres clases las declara él, y son las mismas en los dos tercetos.'
			)
		) as t(destino, viejo, nuevo)
	loop
		select r.nota into v_actual
		from public.forma_relaciones r
		join public.formas_metricas d on d.forma_id = r.forma_destino_id
		where r.forma_origen_id = v_soneto and d.slug = fila.destino;

		if not found then
			raise exception 'No existe la relación del soneto con «%».', fila.destino;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La nota de la relación con «%» no es la esperada. Dice: %', fila.destino, v_actual;
		end if;

		update public.forma_relaciones r
		set nota = fila.nuevo
		from public.formas_metricas d
		where d.forma_id = r.forma_destino_id
			and r.forma_origen_id = v_soneto
			and d.slug = fila.destino;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · La afirmación duplicada de Morley y Bruerton
--
-- Había dos, del mismo autor y el mismo localizador, y la que colgaba de `abbaabba` repetía la
-- primera mitad de la que cuelga de la forma. Se retira la parcial; la completa se queda porque
-- es la que dice «advierten que hay otras», que es lo que sostiene la duda del repertorio.
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_borradas integer;
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'soneto' and er.slug = 'abbaabba';

	if v_esquema is null then
		raise exception 'No existe el esquema «abbaabba» del soneto.';
	end if;

	delete from public.afirmaciones_fuentes_metricas
	where esquema_rima_id = v_esquema
		and fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid
		and resumen = 'Describen los ocho primeros versos del soneto como de rígido orden ABBAABBA, frente a los tercetos, que son la parte variable.';

	get diagnostics v_borradas = row_count;

	if v_borradas not in (0, 1) then
		raise exception 'Se esperaba una afirmación duplicada o ninguna; se borraron %.', v_borradas;
	end if;

	-- Era la única que colgaba de ese esquema: la del Diccionario sobre ABAB ABAB cuelga del
	-- esquema cruzado, no de este. El testimonio no se pierde, sigue en la afirmación de la forma.
	if (
		select count(*) from public.afirmaciones_fuentes_metricas where esquema_rima_id = v_esquema
	) <> 0 then
		raise exception 'El esquema «abbaabba» conserva afirmaciones que no se esperaban.';
	end if;

	-- Y la completa, la que dice «advierten que hay otras», sigue en su sitio.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'soneto'
			and af.fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid
			and af.resumen ilike '%dvierten que hay otras%'
	) then
		raise exception 'La afirmación completa de Morley y Bruerton ha desaparecido.';
	end if;
end $$;

commit;
