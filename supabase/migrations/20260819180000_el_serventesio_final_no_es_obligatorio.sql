-- El serventesio final del terceto encadenado no es obligatorio
--
-- **Corrección de modelo.** Las dos arquitecturas declaraban su sección de cierre con
-- `repeticiones_min = 1`, de modo que el catálogo exigía un serventesio —o una redondilla
-- cruzada— al final de toda cadena. No lo es: la serie puede terminar sin ese cierre. Pasa a
-- `repeticiones_min = 0` y la ficha lo lee como opcional, igual que el remate de la canción.
--
-- Tres textos daban el cierre por hecho y se ajustan con él, porque si no la prosa contradiría
-- al dato: la definición de la forma y las descripciones de sus dos arquitecturas.
--
-- **El demarcador y el editor V2 quedan pendientes de revisar por esto**, anotado en
-- CONTEXTO-PARA-CONTINUAR. No se tocan aquí para no salirse de la revisión del catálogo.
--
-- Aparte, la prosa del terceto: se retira una nota de posición invisible, se acortan las dos
-- descripciones de esquema —que decían la rejilla y repetían la renovación de rima que la ficha
-- deriva sola desde el 19 de agosto— y su definición crece con las dos notaciones y el nombre
-- que la tradición da al terceto de arte menor.
--
-- Y la relación entre las dos formas explica por fin **por qué son dos**: no es que una se
-- repita y la otra no —una tirada de quintillas también se repite—, es que la cadena no se deja
-- cortar. Por eso el encadenado no declara extensión de unidad y la quintilla sí.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El cierre pasa a ser opcional
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_afectadas integer;
	v_obligatorias integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «terceto_encadenado».';
	end if;

	-- Guarda: solo se tocan las secciones de cierre, y solo si están como se espera.
	select count(*) into v_afectadas
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma
		and s.slug = 'serventesio'
		and s.repeticiones_min not in (0, 1);

	if v_afectadas > 0 then
		raise exception 'Alguna sección de cierre tiene repeticiones_min inesperado.';
	end if;

	update public.estructuras_secciones s
	set repeticiones_min = 0
	from public.arquitecturas_forma a
	where a.arquitectura_id = s.arquitectura_id
		and a.forma_id = v_forma
		and s.slug = 'serventesio';

	select count(*) into v_obligatorias
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.slug = 'serventesio' and s.repeticiones_min <> 0;

	if v_obligatorias > 0 then
		raise exception 'Quedan % cierres obligatorios en el terceto encadenado.', v_obligatorias;
	end if;

	-- Y siguen siendo dos, una por arquitectura, con tope de una aparición.
	if (
		select count(*) from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where a.forma_id = v_forma and s.slug = 'serventesio' and s.repeticiones_max = 1
	) <> 2 then
		raise exception 'Las dos secciones de cierre no están como se esperaba.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Los tres textos que daban el cierre por hecho
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace no se cierra hasta el final, donde un verso más recupera la rima pendiente. Se cataloga aparte del terceto porque la rima cruza el límite de la unidad: la serie entera es una sola unidad abierta, no una sucesión de estrofas que puedan contarse por separado.';
	v_nuevo constant text :=
		'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace queda pendiente hasta el final, y puede cerrarse con un verso más que recupera la rima suelta, formando un serventesio; pero la serie puede terminar sin ese cierre. Se cataloga aparte del terceto porque la rima cruza el límite de la unidad: la serie entera es una sola unidad abierta, no una sucesión de estrofas que puedan contarse por separado.';
	fila record;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del terceto encadenado no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;

	for fila in
		select *
		from (values
			(
				'endecasilabica_consonante',
				'Realización principal de origen italiano: serie de endecasílabos consonantes enlazados de tres en tres y cerrada con un serventesio.',
				'Realización principal de origen italiano: serie de endecasílabos consonantes enlazados de tres en tres, que puede cerrarse con un serventesio.'
			),
			(
				'octosilabica_consonante',
				'Adaptación al metro español de la serie italiana: conserva el encadenamiento consonante, lo realiza en octosílabos y cierra con una cuarteta.',
				'Adaptación al metro español de la serie italiana: conserva el encadenamiento consonante, lo realiza en octosílabos y puede cerrar con una redondilla cruzada.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» del terceto encadenado.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de terceto_encadenado/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · Por qué son dos formas y no dos arquitecturas
--
-- La duda es legítima porque la redondilla doble enlazada sí vive dentro de la redondilla. Lo
-- que las separa no es que una se repita —una tirada de quintillas también se repite— sino que
-- la cadena **no se deja cortar**: por eso la quintilla declara `unidad_versos = 5` y cuántas
-- hay se deriva, y el encadenado no declara ninguna.
-- ---------------------------------------------------------------------------
do $$
declare
	v_encadenado uuid;
	v_terceto uuid;
	v_actual text;
	v_viejo constant text :=
		'Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente; por eso constituye una serie indivisible y no una repetición de tercetos independientes.';
	v_nuevo constant text :=
		'Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente, de modo que la serie no se deja cortar en estrofas contables: es una sola unidad abierta. Por eso figuran como formas distintas y no como dos realizaciones de una sola: el terceto es una estrofa y el encadenado, una serie.';
begin
	select forma_id into v_encadenado
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;
	select forma_id into v_terceto
	from public.formas_metricas where slug = 'terceto' and activo;

	select nota into v_actual
	from public.forma_relaciones
	where forma_origen_id = v_encadenado and forma_destino_id = v_terceto;

	if not found then
		raise exception 'No existe la relación del terceto encadenado con el terceto.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la relación no es la esperada. Dice: %', v_actual;
	end if;

	update public.forma_relaciones
	set nota = v_nuevo
	where forma_origen_id = v_encadenado and forma_destino_id = v_terceto;

	-- La frase afirma que uno declara extensión de unidad y el otro no: se comprueba.
	if (
		select count(*) from public.arquitecturas_forma
		where forma_id = v_encadenado and activo and unidad_versos_min is not null
	) <> 0 then
		raise exception 'El terceto encadenado declara extensión de unidad y la nota dice que no.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La definición del terceto
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de tres versos endecasílabos en la que dos riman en consonante y el tercero queda suelto. Rara vez aparece aislada: lo normal es que se suceda en series o entre en la composición de otra forma, como los dos tercetos del soneto. Cuando las unidades se enlazan por la rima, la serie resultante es el terceto encadenado, que se cataloga aparte.';
	v_nuevo constant text :=
		'Estrofa de tres versos endecasílabos en la que dos riman en consonante y el tercero queda suelto, sea el primero (–AA) o el central (A–A). Rara vez aparece aislada: lo normal es que se suceda en series o que entre en la composición de otra forma, como los dos tercetos del soneto. En versos de arte menor recibe nombre propio: tercetillo, tercerilla o tercerillo. Cuando las unidades se enlazan por la rima, la serie resultante es el terceto encadenado, que es otra forma porque deja de ser una estrofa.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'terceto' and activo;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del terceto no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · La nota de posición métrica y las dos glosas de esquema
--
-- La nota es invisible y la dice la fila «Medida». Las glosas leían la rejilla en voz alta y
-- repetían la renovación de rima, que la ficha deriva sola desde el 19 de agosto: se quedan con
-- lo único que distingue una disposición de la otra.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperada constant text := 'Posición endecasilábica fija del terceto.';
	v_actual text;
	fila record;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'terceto' and activo;

	update public.esquema_metrico_posiciones p
	set nota = null
	from public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = p.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and p.nota = v_esperada;

	select count(*) into v_restantes
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and p.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de posición métrica en el terceto.', v_restantes;
	end if;

	for fila in
		select *
		from (values
			(
				'primer-verso-suelto',
				'Cada terceto deja suelto el primer verso y hace rimar entre sí el segundo y el tercero. La clase de rima se renueva en cada unidad porque no existe enlace entre bloques.',
				'El verso suelto es el primero.'
			),
			(
				'verso-central-suelto',
				'Cada terceto hace rimar sus versos primero y tercero y deja suelto el verso central. La clase de rima se renueva en cada unidad porque no existe enlace entre bloques.',
				'El verso suelto es el central.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select er.descripcion into v_actual
		from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_forma and er.slug = fila.slug;

		if not found then
			raise exception 'No existe el esquema «%» del terceto.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La glosa de «%» no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.esquemas_rima er
		set descripcion = fila.nuevo
		from public.arquitecturas_forma a
		where a.arquitectura_id = er.arquitectura_id
			and a.forma_id = v_forma
			and er.slug = fila.slug;
	end loop;
end $$;

commit;
