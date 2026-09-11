-- El cierre del terceto encadenado es un remate de un verso, no un serventesio
--
-- **Corrección de modelo.** Desde el 1 de agosto de 2026 las dos arquitecturas declaraban su
-- cierre como una estrofa de cuatro versos que reutilizaba el cuarteto —o la redondilla en arte
-- menor—. Se hizo para «decir qué es esa cola en vez de contarla», y decía de más: convertía el
-- último terceto en otra estrofa.
--
-- No lo es. La tirada final `CDCD` **se lee** como un serventesio, pero métricamente es `CDC`
-- más un verso: la rima `C` no nace ahí, llega encadenada del terceto anterior. Lo dice la fuente
-- que el propio catálogo ya cita en pp. 92-93 —«la última estrofa es de cuatro versos porque en
-- realidad es un terceto al que se añade uno más para cerrar la rima que quedaba pendiente»— y lo
-- contradecía la estructura.
--
-- El cierre pasa entonces a lo que es: un **remate** de un solo verso, del mismo tipo que los de
-- la canción y la sextina, opcional como hasta ahora y sin reutilizar ninguna otra arquitectura.
-- La forma no se compone de un cuarteto ni deriva de él; el parecido es de lectura y vive donde
-- corresponde, en la prosa y en las dos relaciones entre formas, que se conservan reescritas.
--
-- **Y la cadena pasa a exigir dos tercetos.** Con uno solo no hay rima prestada que cerrar, así
-- que un pasaje de tres versos es un terceto y uno de cuatro, una estrofa cruzada: ni el uno ni
-- el otro son esta forma. La regla de longitud lo deriva de `repeticiones_min`, de modo que el
-- mínimo sube solo de 3 a 6 versos y el demarcador deja de admitir esos dos casos.
--
-- Lo que **no** cambia: el cierre sigue siendo opcional, las dos congruencias siguen siendo
-- excluyentes —`3n ≡ 0` y `3n+1 ≡ 1` en módulo 3, igual que antes con `3n+4`— y por tanto el
-- rango del pasaje sigue decidiendo por sí solo si el remate está.
--
-- **Nada anotado depende de esto**: ninguna de las siete anotaciones de la forma realiza la
-- sección de cierre, ninguna respuesta ni equivalencia apunta a ella, y la forma no pregunta nada
-- al editor. Aun así, las guardas de más abajo **ejecutan** la regla de longitud en vez de
-- comprobar solo el dato.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La estructura: dos tercetos como mínimo, y un remate de un verso
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_inesperadas integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «terceto_encadenado».';
	end if;

	-- Guarda: las dos secciones de cierre están como las dejó el 19 de agosto, o ya migradas.
	select count(*) into v_inesperadas
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma
		and s.slug in ('serventesio', 'remate')
		and not (
			(s.slug = 'serventesio' and s.versos_min = 4 and s.versos_max = 4)
			or (s.slug = 'remate' and s.versos_min = 1 and s.versos_max = 1)
		);

	if v_inesperadas > 0 then
		raise exception 'Alguna sección de cierre del encadenado no está como se esperaba.';
	end if;

	update public.estructuras_secciones s
	set slug = 'remate',
		tipo_seccion = 'remate',
		nombre = 'Remate',
		versos_min = 1,
		versos_max = 1,
		arquitectura_referenciada_id = null,
		nota = 'Un solo verso que recupera la rima central del último terceto, la única que la cadena deja sin resolver. Leído junto a ese terceto suena como una estrofa cruzada de cuatro versos, y así lo describen las fuentes; pero sigue siendo un terceto más un verso, porque la primera rima de esa tirada no nace ahí: llega encadenada del terceto anterior.'
	from public.arquitecturas_forma a
	where a.arquitectura_id = s.arquitectura_id
		and a.forma_id = v_forma
		and s.slug in ('serventesio', 'remate');

	-- La cadena necesita dos eslabones para que haya rima prestada.
	update public.estructuras_secciones s
	set repeticiones_min = 2
	from public.arquitecturas_forma a
	where a.arquitectura_id = s.arquitectura_id
		and a.forma_id = v_forma
		and s.slug = 'terceto';

	if (
		select count(*)
		from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where a.forma_id = v_forma
			and s.slug = 'remate'
			and s.tipo_seccion = 'remate'
			and s.versos_min = 1 and s.versos_max = 1
			and coalesce(s.repeticiones_min, 0) = 0 and s.repeticiones_max = 1
			and s.arquitectura_referenciada_id is null
	) <> 2 then
		raise exception 'Los dos remates del encadenado no quedaron como se esperaba.';
	end if;

	if (
		select count(*)
		from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where a.forma_id = v_forma and s.slug = 'terceto' and s.repeticiones_min = 2
	) <> 2 then
		raise exception 'Las dos cadenas del encadenado no exigen dos tercetos.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Los esquemas de rima dejan de anunciar un cierre que ya no es estrofa
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actualizados integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;

	update public.esquemas_rima r
	set slug = 'encadenado',
		nombre = 'Encadenamiento consonante'
	from public.arquitecturas_forma a
	where a.arquitectura_id = r.arquitectura_id
		and a.forma_id = v_forma
		and r.slug in ('encadenado-con-serventesio', 'encadenado');

	get diagnostics v_actualizados = row_count;
	if v_actualizados <> 2 then
		raise exception 'Se esperaban dos esquemas de rima del encadenado y se tocaron %', v_actualizados;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La prosa, que decía que la cadena cierra en serventesio
--
-- Cuatro textos daban por hecho que el cierre es una estrofa de cuatro versos: la definición de
-- la forma, las descripciones de sus dos arquitecturas y las notas de sus dos relaciones. Ninguno
-- se acorta: lo que hay que explicar ahora es más, no menos, porque el parecido con el cuarteto
-- se mantiene y hay que decir por qué no es identidad.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace queda pendiente hasta el final, y puede cerrarse con un verso más que recupera la rima suelta, formando un serventesio; pero la serie puede terminar sin ese cierre. Se cataloga aparte del terceto porque la rima cruza el límite de la unidad: la serie entera es una sola unidad abierta, no una sucesión de estrofas que puedan contarse por separado.';
	v_nuevo constant text :=
		'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace queda pendiente hasta el final, donde puede cerrarse con un verso más —el remate, que la tradición llama también estrambote— que recupera la rima suelta; pero la serie puede terminar sin él. Ese verso no convierte al último terceto en otra estrofa: la tirada final se lee como un cuarteto cruzado, y así la describen las fuentes, pero métricamente es un terceto más uno, porque su primera rima llega encadenada del terceto anterior y no nace ahí. La cadena necesita al menos dos tercetos: con uno solo no hay rima prestada que cerrar. Se cataloga aparte del terceto porque la rima cruza el límite de la unidad: la serie entera es una sola unidad abierta, no una sucesión de estrofas que puedan contarse por separado.';
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
				'Realización principal de origen italiano: serie de endecasílabos consonantes enlazados de tres en tres, que puede cerrarse con un serventesio.',
				'Realización principal de origen italiano: serie de endecasílabos consonantes enlazados de tres en tres, que puede cerrarse con un verso de remate. Con él, la tirada final se lee como un serventesio sin dejar de ser un terceto y un verso.'
			),
			(
				'octosilabica_consonante',
				'Adaptación al metro español de la serie italiana: conserva el encadenamiento consonante, lo realiza en octosílabos y puede cerrar con una redondilla cruzada.',
				'Adaptación al metro español de la serie italiana: conserva el encadenamiento consonante, lo realiza en octosílabos y puede cerrarse con un verso de remate. Con él, la tirada final se lee como una redondilla cruzada sin dejar de ser un terceto y un verso.'
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

-- Las dos relaciones se quedan, y se quedan como lo que son: un parecido de lectura. No son
-- `compuesta_por` ni lo eran; lo que sobraba era la nota, que hablaba de un cierre que la cadena
-- ya no tiene.
do $$
declare
	v_encadenado uuid;
	v_actual text;
	fila record;
begin
	select forma_id into v_encadenado
	from public.formas_metricas where slug = 'terceto_encadenado' and activo;

	for fila in
		select *
		from (values
			(
				'cuarteto',
				'El cierre cruzado recibe el nombre correspondiente al arte de sus cuatro versos: serventesio en la arquitectura endecasilábica y redondilla cruzada en la octosilábica.',
				'La cadena no compone cuartetos, pero acaba pareciéndolo: cerrada con su verso de remate, la tirada final se lee como una estrofa cruzada de cuatro versos, que en la arquitectura endecasilábica se llamaría serventesio. El parecido es de lectura y no de estructura, porque la primera rima de esa tirada viene encadenada del terceto anterior en vez de abrirse allí.'
			),
			(
				'redondilla',
				'La arquitectura octosilábica cierra la cadena con una redondilla cruzada, equivalente funcional del serventesio final de la endecasilábica.',
				'El mismo parecido de lectura que con el cuarteto, en arte menor: la arquitectura octosilábica cerrada con su verso de remate termina en una tirada que suena a redondilla cruzada, aunque siga siendo un terceto y un verso.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select r.nota into v_actual
		from public.forma_relaciones r
		join public.formas_metricas destino on destino.forma_id = r.forma_destino_id
		where r.forma_origen_id = v_encadenado and destino.slug = fila.slug;

		if not found then
			raise exception 'No existe la relación del terceto encadenado con «%».', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La nota de la relación con «%» no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.forma_relaciones r
		set nota = fila.nuevo
		from public.formas_metricas destino
		where destino.forma_id = r.forma_destino_id
			and r.forma_origen_id = v_encadenado
			and destino.slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La guarda que ejecuta: la regla de longitud, calculada de verdad
--
-- Un cuerpo entrecomillado no se revalida solo, y esta migración no toca ninguna función; pero la
-- regla se **deriva** de lo que acaba de cambiar, así que se llama y se comprueba lo que devuelve.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq record;
	v_regla record;
begin
	for v_arq in
		select a.arquitectura_id, a.slug
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'terceto_encadenado' and a.activo
	loop
		select * into v_regla
		from public.regla_longitud_arquitectura_metrica(v_arq.arquitectura_id) limit 1;

		if not found then
			raise exception 'La arquitectura «%» dejó de producir regla de longitud.', v_arq.slug;
		end if;

		if v_regla.modulo_versos <> 3 or v_regla.residuo_versos <> 0 then
			raise exception 'La regla de «%» debe ser 3n y es %n+%',
				v_arq.slug, v_regla.modulo_versos, v_regla.residuo_versos;
		end if;

		if v_regla.minimo_versos <> 6 then
			raise exception 'El mínimo de «%» debe ser 6 versos —dos tercetos— y es %',
				v_arq.slug, v_regla.minimo_versos;
		end if;

		if v_regla.desplazamientos is distinct from array[0, 1] then
			raise exception 'Los desplazamientos de «%» deben ser {0,1} y son %',
				v_arq.slug, v_regla.desplazamientos;
		end if;
	end loop;
end $$;

-- Y ninguna anotación puede quedar por debajo de lo que la estructura exige ahora.
do $$
declare
	v_flojas integer;
begin
	select count(*) into v_flojas
	from (
		select r.realizacion_padre_id
		from public.anotacion_realizaciones r
		join public.estructuras_secciones s on s.seccion_id = r.seccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'terceto_encadenado' and s.slug = 'terceto'
		group by r.realizacion_padre_id
		having count(*) < 2
	) escasas;

	if v_flojas > 0 then
		raise exception '% unidades anotadas tienen menos de dos tercetos', v_flojas;
	end if;
end $$;

update public.catalogo_metrico_estado
set modelo_version = 59,
	revision = revision + 1,
	actualizado_en = now();

commit;
