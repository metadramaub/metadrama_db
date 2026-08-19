-- La redondilla dice por qué su doble es una sola estrofa
--
-- Su prosa era corta y estaba casi bien; lo que fallaba era otra cosa. La descripción del
-- esquema de la doble enlazada es **invisible** y decía por cuarta vez lo que ya dicen la
-- rejilla, las dos notas de enlace y la descripción de su arquitectura. Se va.
--
-- Lo demás se mejora sin recortar: la definición añade que las dos disposiciones conviven y las
-- otras dos medidas; la octosilábica cuenta que la estrofa llegó a dar nombre al verso; la
-- hexasilábica y la heptasilábica explican por qué solo una de las dos tiene nombre propio; y la
-- doble enlazada dice lo único que le faltaba, que es qué la separa de dos redondillas seguidas.
--
-- La relación con el cuarteto recoge la confusión que un anotador se encuentra de verdad: que
-- «serventesio» se ha usado para la redondilla cruzada aunque corresponda al cuarteto.
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
		'Estrofa de cuatro versos de arte menor con rima consonante repartida en dos clases, sin ningún verso suelto. La disposición puede ser abrazada (abba) o cruzada (abab). El octosílabo es su realización no marcada.';
	v_nuevo constant text :=
		'Estrofa de cuatro versos de arte menor con rima consonante repartida en dos clases, sin ningún verso suelto. La disposición puede ser abrazada (abba) o cruzada (abab), y las dos aparecen en una misma composición. El octosílabo es su realización no marcada; el heptasílabo y el hexasílabo son mucho menos frecuentes.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'redondilla' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «redondilla».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la redondilla no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Las cuatro descripciones de arquitectura
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'redondilla' and activo;

	for fila in
		select *
		from (values
			(
				'octosilabica',
				'Realización no marcada, que la tradición nombra redondilla mayor. Con el romance y la décima, uno de los tres moldes del diálogo en la comedia nueva.',
				'Realización no marcada de la redondilla, que la tradición nombra redondilla mayor. Con el romance y la décima, uno de los tres moldes del diálogo en la comedia nueva. Su arraigo llegó al punto de dar nombre al verso: el octosílabo se llamó también «verso de redondilla mayor».'
			),
			(
				'hexasilabica',
				'Realización ocasional, que la tradición nombra redondilla menor y que la lírica popular cultivó con preferencia.',
				'Realización ocasional, que la tradición nombra redondilla menor. Fue la lírica popular la que la cultivó con preferencia, y de ahí que tenga nombre propio mientras la heptasílaba no lo tiene.'
			),
			(
				'heptasilabica',
				'Realización ocasional, que la bibliografía registra junto a la hexasílaba como alternativa poco frecuente a la octosílaba.',
				'Realización ocasional, la más rara de las tres medidas. La tradición no le dio nombre propio ni un ámbito distinto: aparece junto a la hexasílaba como alternativa a la octosílaba.'
			),
			(
				'doble_enlazada',
				'Dos redondillas abrazadas que comparten la rima exterior: la segunda no estrena sus dos clases, sino solo una.',
				'Dos redondillas abrazadas que comparten la rima exterior: la segunda no estrena sus dos clases, sino solo una. Es la que la tradición llamó redondilla doble, y ese enlace es lo que la separa de dos redondillas puestas una detrás de otra.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» de la redondilla.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de redondilla/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La descripción invisible del esquema de la doble enlazada
--
-- No llega a pantalla, y lo que dice está en la rejilla `a b b a a c c a`, en las dos notas de
-- enlace impresas debajo y en la descripción de su arquitectura.
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_actual text;
	v_esperada constant text :=
		'Dos redondillas abrazadas enlazadas mediante la clase exterior a.';
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'redondilla' and er.slug = 'abbaacca';

	if v_esquema is null then
		raise exception 'No existe el esquema «abbaacca» de la redondilla.';
	end if;

	select descripcion into v_actual from public.esquemas_rima where esquema_rima_id = v_esquema;

	if v_actual is not null and v_actual is distinct from v_esperada then
		raise exception 'La descripción de «abbaacca» no es la esperada. Dice: %', v_actual;
	end if;

	update public.esquemas_rima set descripcion = null where esquema_rima_id = v_esquema;

	-- Las dos notas de enlace **se conservan**: dicen bien lo que la redacción automática diría
	-- mal, porque aquí no hay repetición de una unidad sino dos redondillas dentro de una estrofa.
	if (
		select count(*) from public.esquema_rima_enlaces
		where esquema_rima_id = v_esquema and nota is not null
	) <> 2 then
		raise exception 'Las dos notas de enlace de la doble enlazada ya no están.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La relación con el cuarteto recoge la confusión de «serventesio»
--
-- Las relaciones son bidireccionales, así que se mejora la que existe en vez de crear otra.
-- ---------------------------------------------------------------------------
do $$
declare
	v_cuarteto uuid;
	v_redondilla uuid;
	v_actual text;
	v_viejo constant text :=
		'Comparten la organización de cuatro versos consonantes en dos clases de rima; se distinguen por el arte mayor o menor de sus versos.';
	v_nuevo constant text :=
		'Comparten la organización de cuatro versos consonantes en dos clases de rima, abrazadas o cruzadas, y solo las separa el arte del verso: mayor en el cuarteto, menor en la redondilla. Por eso el nombre de una disposición sirve para las dos, y «serventesio» se ha usado alguna vez para la redondilla cruzada aunque corresponda más propiamente al cuarteto.';
begin
	select forma_id into v_cuarteto from public.formas_metricas where slug = 'cuarteto' and activo;
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla' and activo;

	select nota into v_actual
	from public.forma_relaciones
	where forma_origen_id = v_cuarteto and forma_destino_id = v_redondilla;

	if not found then
		raise exception 'No existe la relación del cuarteto con la redondilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la relación no es la esperada. Dice: %', v_actual;
	end if;

	update public.forma_relaciones
	set nota = v_nuevo
	where forma_origen_id = v_cuarteto and forma_destino_id = v_redondilla;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · La afirmación que se justificaba a sí misma
--
-- Decía «el proyecto la registra como nombre equivalente…», que es el catálogo hablando de sí
-- mismo, y su primera mitad la dice mejor otra afirmación del mismo autor que además añade el
-- uso: «Reserva "cuarteta" para la disposición cruzada… se usa normalmente en poesía narrativa
-- y en los diálogos del teatro».
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_borradas integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'redondilla' and activo;

	delete from public.afirmaciones_fuentes_metricas af
	using public.esquemas_rima er, public.arquitecturas_forma a
	where af.esquema_rima_id = er.esquema_rima_id
		and a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and af.resumen like 'Documenta la denominación cuarteta%';

	get diagnostics v_borradas = row_count;

	if v_borradas > 1 then
		raise exception 'Se esperaba una afirmación o ninguna; se borraron %.', v_borradas;
	end if;

	-- La que se queda, que es la que dice más.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and resumen ilike '%Reserva «cuarteta» para la disposición cruzada%'
	) then
		raise exception 'La afirmación del Diccionario sobre la cuarteta ha desaparecido.';
	end if;
end $$;

commit;
