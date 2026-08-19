-- La quintilla se define por lo que evita
--
-- Es la única forma del catálogo cuyas restricciones declaradas describen en vez de inducir, y
-- conviene dejar escrito por qué: **aquí las fuentes sí enuncian la regla**. Quilis «deriva las
-- disposiciones de las dos prohibiciones y concluye que las combinaciones posibles son cinco», y
-- el *Diccionario* fija cuatro condiciones. Nada que ver con el «etc.» de la sextilla.
--
-- Pero el catálogo admite ocho disposiciones, no cinco, así que la prosa **no puede enunciar las
-- prohibiciones como ley y desmentirse tres líneas después**. La definición pasa a decir que la
-- tradición la caracteriza por lo que procura evitar, y que el uso documenta alguna más.
--
-- Se corrige además una lectura equivocada de la marca `excepcional`. Son **cuatro** las que la
-- llevan, no tres, y no significan lo mismo: `aabab` es una de las cinco clásicas y está marcada
-- porque Morley y Bruerton la dan por «muy rara». En esta forma `excepcional` mide **frecuencia**,
-- no infracción, y solo tres de las cuatro se apartan además de la regla.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición no se cierra más de lo que la forma se cierra
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de cinco versos octosílabos con rima consonante repartida en dos clases, cada una en dos versos por lo menos: ninguno queda suelto.';
	v_nuevo constant text :=
		'Estrofa de cinco versos octosílabos que riman en consonante sobre dos clases. Más que por una disposición fija, la tradición la caracteriza por lo que procura evitar: tres versos seguidos con la misma rima y el pareado final. De ahí salen sus cinco disposiciones clásicas, aunque el uso documenta alguna más. Dentro de un mismo poema la disposición puede cambiar de una quintilla a otra.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'quintilla' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «quintilla».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la quintilla no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura, que estaba sin describir
--
-- Es la única de la forma y no decía nada. Aquí va lo que el lector ve y no entiende: por qué
-- hay ocho disposiciones si la regla da cinco, y qué marca exactamente «excepcional».
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_nuevo constant text :=
		'Es de las estrofas más usadas del teatro del Siglo de Oro, sobre todo en los pasajes narrativos y líricos. De sus ocho disposiciones, la primera es con diferencia la más corriente y cuatro se marcan como excepcionales por lo poco que aparecen: una lo es aun siendo de las clásicas, y las otras tres se apartan además de la regla —dos cierran en pareado y una repite la misma rima en tres versos seguidos—.';
	v_excepcionales integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa quintilla/octosilabica_consonante.';
	end if;

	-- La descripción afirma un recuento: se comprueba contra el dato antes de escribirlo.
	select count(*) into v_excepcionales
	from public.esquemas_rima
	where arquitectura_id = v_arq and modalidad = 'excepcional';

	if v_excepcionales <> 4 then
		raise exception 'La quintilla tiene % disposiciones excepcionales; la descripción dice cuatro.', v_excepcionales;
	end if;

	if (
		select count(*) from public.esquemas_rima
		where arquitectura_id = v_arq and tipo_secuencia = 'secuencia'
	) <> 8 then
		raise exception 'La quintilla no tiene ocho disposiciones concretas.';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;

	if v_actual is not null and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no estaba vacía. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La glosa de «Tipología 2» sobra, y la de «Tipología 8» dice más
--
-- La primera lee la figura en voz alta: las cuatro primeras celdas son `abba` y la quinta `b`.
-- La segunda conserva lo único que no se deriva —que es la única con tres rimas seguidas— y
-- añade que las fuentes no se ponen de acuerdo sobre si es intencionada, que es lo que explica
-- su marca sin repetir el testimonio de ninguna.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	fila record;
	v_actual text;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and a.activo;

	for fila in
		select *
		from (values
			(
				'abbab',
				'La segunda clase se abraza en el centro y vuelve a cerrar: abba más un verso que retoma la segunda.',
				null::text
			),
			(
				'abbba',
				'Tres versos seguidos con la misma rima, lo que ninguna otra disposición admite.',
				'Ninguna otra disposición repite la misma rima en tres versos seguidos. Se ha documentado muy poco, y las fuentes no coinciden en si es intencionada.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.esquemas_rima
		where arquitectura_id = v_arq and slug = fila.slug;

		if not found then
			raise exception 'No existe la disposición «%» de la quintilla.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La glosa de «%» no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.esquemas_rima
		set descripcion = fila.nuevo
		where arquitectura_id = v_arq and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · El esquema abierto dice de frente que su criterio es más ancho
--
-- Decía que «las ocho tipologías declaradas son las que la cumplen», que es circular: el
-- criterio se eligió para que cupieran las ocho.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_viejo constant text :=
		'La norma no fija cuál de las disposiciones admitidas presenta la estrofa: fija qué las hace admisibles. Las ocho tipologías declaradas son las que la cumplen.';
	v_nuevo constant text :=
		'El criterio declarado es más amplio que la regla clásica: la admite entera y deja pasar además las tres disposiciones que la tradición documenta incumpliéndola, como el final en pareado.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and a.activo;

	select descripcion into v_actual
	from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';

	if not found then
		raise exception 'No existe el esquema abierto de la quintilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La descripción del esquema abierto no es la esperada. Dice: %', v_actual;
	end if;

	update public.esquemas_rima
	set descripcion = v_nuevo
	where arquitectura_id = v_arq and slug = 'distribucion-variable';
end $$;

-- ---------------------------------------------------------------------------
-- 5 · De dónde viene la quintilla, y hasta dónde llega ese origen
--
-- Navarro Tomás § 62 sostiene que se formó sobre la redondilla por adición de un verso. La nota
-- dice también lo que el origen no explica: solo la mitad de sus disposiciones conservan una
-- redondilla en los cuatro primeros versos —`ababa`, `abbab`, `abbaa` y `ababb`—; las otras
-- cuatro reparten las dos clases de un modo que la redondilla no admite.
-- ---------------------------------------------------------------------------
do $$
declare
	v_quintilla uuid;
	v_redondilla uuid;
	v_nota constant text :=
		'Se formó añadiendo un quinto verso a la redondilla, y de ahí que comparta con ella sus dos clases de rima. El origen no alcanza, sin embargo, a todas sus disposiciones: solo la mitad conserva una redondilla en los cuatro primeros versos, y las demás reparten las dos clases de un modo que la redondilla no admite.';
begin
	select forma_id into v_quintilla
	from public.formas_metricas where slug = 'quintilla' and activo;
	select forma_id into v_redondilla
	from public.formas_metricas where slug = 'redondilla' and activo;

	if v_redondilla is null then
		raise exception 'No existe la forma activa «redondilla».';
	end if;

	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
	)
	select v_quintilla, v_redondilla, 'derivada_de', v_nota, 'aprobada'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_quintilla
			and forma_destino_id = v_redondilla
			and tipo_relacion = 'derivada_de'
	);

	update public.forma_relaciones
	set nota = v_nota
	where forma_origen_id = v_quintilla
		and forma_destino_id = v_redondilla
		and tipo_relacion = 'derivada_de';

	if (
		select count(*) from public.forma_relaciones
		where forma_origen_id = v_quintilla and forma_destino_id = v_redondilla
	) <> 1 then
		raise exception 'La relación con la redondilla no quedó una y sola una.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · La afirmación de Morley y Bruerton se lee sola
--
-- Empezaba con «las mismas siete combinaciones», remitiendo a la de Navarro Tomás, que en la
-- ficha aparece **después** porque es de 1972 y esta de 1968.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'Dan las mismas siete combinaciones y precisan que Rengifo, en su *Arte poética* de 1592, recoge solo las cinco primeras y en ese orden, omitiendo las dos que acaban en pareado, que se hallan alguna vez pero con muy poca frecuencia. Sobre su uso: la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara. Registran además que alguna vez aparece el tipo ABBBA, y lo atribuyen a un error de imprenta o a una adaptación especial para expresar un pensamiento.';
	v_nuevo constant text :=
		'Dan siete combinaciones y precisan que Rengifo, en su *Arte poética* de 1592, recoge solo las cinco primeras y en ese orden, omitiendo las dos que acaban en pareado, que se hallan alguna vez pero con muy poca frecuencia. Sobre su uso: la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara. Registran además que alguna vez aparece el tipo ABBBA, y lo atribuyen a un error de imprenta o a una adaptación especial para expresar un pensamiento.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'quintilla' and activo;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;

	if v_id is null then
		raise exception 'No existe la afirmación de Morley y Bruerton sobre la quintilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación de Morley y Bruerton no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

commit;
