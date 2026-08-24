-- La canción de estancias variables declara sus partes
--
-- La arquitectura `estancias_consonantes_variables` tenía solo dos secciones —«Estancia (5-20 vv)»
-- y «Remate»— y **ninguna ordenación por dentro**. Sin fronte, sin piedi, sin eslabón y sin sirima,
-- una canción de ocho versos era indistinguible de una octava-lira: misma materia, misma extensión,
-- misma rima, y nada que las separase.
--
-- Es el agujero que dejaba fuera del catálogo a los tres términos legados que dependen de ella
-- —`cancion_de_8_versos`, `cancion_de_9_versos` y `cancion_de_15_versos`—, cuya definición dice que
-- siguen «el modelo de la canzone petrarquista» con esa medida.
--
-- **La ordenación se declara con horquillas, no con medidas fijas.** Es lo que significa el nombre
-- de la arquitectura: lo que se repite sin cambio de una estancia a otra no son unas medidas
-- concretas sino la articulación, y las medidas las fija cada canción —de ahí que la estancia lleve
-- `primera_realizacion_define_patron`—. Las horquillas se derivan de la propia estancia y no añaden
-- nada que las fuentes no digan:
--
-- | Parte | Versos | Por qué |
-- |---|---|---|
-- | Fronte | 4-18 | dos piedi de dos versos como mínimo; como máximo, lo que deja una sirima de uno |
-- | Primer pie / segundo pie | 2-9 | un pie de un solo verso no es un pie; el máximo es la mitad de la fronte |
-- | Eslabón | 1 | siempre mide un verso |
-- | Sirima | 1-16 | lo que queda cuando la fronte es la menor posible |
--
-- **El eslabón se declara opcional** —`repeticiones_min = 0`—, y esto es una decisión, no un
-- descuido. En la tradición italiana la chiave lo es: una canción sin ella no deja de ser canción.
-- Lo que el criterio del 24 de agosto de 2026 fija es **cómo se nombra por defecto** lo que no la
-- trae, que preferentemente será alirado. Los dos planos no se confunden: la estructura admite el
-- caso raro y la nomenclatura elige por defecto. Por eso la arquitectura regular de trece versos
-- **conserva su eslabón obligatorio** —forma parte de su esquema fijo, `abCabC:cdeeDfF`, donde
-- quitarlo dejaría doce versos— y solo se relaja aquí, donde nada está fijo.

begin;

do $$
declare
	v_arq uuid;
	v_estancia uuid;
	v_fronte uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'cancion_petrarquista' and a.slug = 'estancias_consonantes_variables'
		and a.activo;
	if v_arq is null then
		raise exception 'No existe la canción de estancias variables.';
	end if;

	select seccion_id into v_estancia from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'estancia';
	if v_estancia is null then
		raise exception 'La canción variable ha perdido su estancia.';
	end if;

	-- Tenía dos secciones y ninguna dentro de la estancia: si ya tuviera más, alguien la tocó.
	select count(*) into v_n from public.estructuras_secciones
	where arquitectura_id = v_arq;
	if v_n not in (2, 7) then
		raise exception 'La canción variable tiene % secciones; se esperaban dos o las siete.', v_n;
	end if;

	-- ------------------------------------------------------------------ La ordenación
	if not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq and slug = 'fronte'
	) then
		insert into public.estructuras_secciones (
			arquitectura_id, seccion_padre_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max,
			primera_realizacion_define_patron, nota
		)
		values (
			v_arq, v_estancia, 'fronte', 'fronte', 'Fronte', 1, 1, 1, 4, 18, false,
			'Primera parte de la estancia, partida en dos piedi de igual medida y disposición. '
			|| 'Cuánto miden lo fija cada canción.'
		)
		returning seccion_id into v_fronte;

		insert into public.estructuras_secciones (
			arquitectura_id, seccion_padre_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max,
			primera_realizacion_define_patron, nota
		)
		values
			(v_arq, v_fronte, 'pie', 'primer_pie', 'Primer pie', 1, 1, 1, 2, 9, false,
				'Los dos piedi miden lo mismo y riman igual; cambian los sonidos, no la figura.'),
			(v_arq, v_fronte, 'pie', 'segundo_pie', 'Segundo pie', 2, 1, 1, 2, 9, false,
				'Repite la medida y la disposición del primero. Es lo que hace estancia a la '
				|| 'estancia.'),
			(v_arq, v_estancia, 'eslabon', 'eslabon', 'Eslabón', 2, 0, 1, 1, 1, false,
				'Verso que abre la sirima retomando la rima con que se cerró la fronte —la chiave—. '
				|| 'Es lo que separa una estancia de una estrofa alirada, y en la tradición italiana '
				|| 'es habitual pero no obligatorio: una canción sin él no deja de serlo, aunque '
				|| 'este catálogo llame alirado por defecto a lo que no lo trae.'),
			(v_arq, v_estancia, 'sirima', 'sirima', 'Sirima', 3, 1, 1, 1, 16, false,
				'Segunda parte de la estancia, con rimas nuevas y sin la simetría de la fronte.');
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.estructuras_secciones where arquitectura_id = v_arq;
	if v_n <> 7 then
		raise exception 'La canción variable tiene % secciones, no las siete.', v_n;
	end if;

	-- Los dos piedi cuelgan de la fronte y miden lo mismo: si no, no hay estancia.
	select count(*) into v_n from public.estructuras_secciones s
	join public.estructuras_secciones p on p.seccion_id = s.seccion_padre_id
	where s.arquitectura_id = v_arq and s.tipo_seccion = 'pie' and p.slug = 'fronte';
	if v_n <> 2 then
		raise exception 'La fronte de la canción variable tiene % piedi, no dos.', v_n;
	end if;

	if exists (
		select 1 from public.estructuras_secciones a
		join public.estructuras_secciones b on b.arquitectura_id = a.arquitectura_id
			and b.tipo_seccion = 'pie' and b.seccion_id <> a.seccion_id
		where a.arquitectura_id = v_arq and a.tipo_seccion = 'pie'
			and (a.versos_min <> b.versos_min or a.versos_max <> b.versos_max)
	) then
		raise exception 'Los dos piedi de la canción variable no admiten la misma medida.';
	end if;

	-- El eslabón queda opcional aquí, y obligatorio en la regular de trece versos.
	select repeticiones_min into v_n from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'eslabon';
	if v_n <> 0 then
		raise exception 'El eslabón de la canción variable no ha quedado opcional.';
	end if;

	select s.repeticiones_min into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.slug = 'regular_13_versos' and s.slug = 'eslabon';
	if v_n <> 1 then
		raise exception 'El eslabón de la canción regular ha dejado de ser obligatorio.';
	end if;

	-- Las horquillas dejan caber la estancia más corta que la arquitectura admite, la de cinco
	-- versos: cuatro de fronte, sin eslabón, uno de sirima.
	select (select versos_min from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = 'fronte')
		+ (select versos_min from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = 'sirima')
	into v_n;
	if v_n > 5 then
		raise exception 'Las partes suman % versos como mínimo, y la estancia admite cinco.', v_n;
	end if;

	if public.get_forma_metrica_publica('cancion_petrarquista') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la canción ha dejado de responder.';
	end if;
end $$;

commit;
