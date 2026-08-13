-- El soneto declara también en la ontología las formas que componen sus secciones.
--
-- `arquitectura_referenciada_id` permite que los dos cuartetos y los dos tercetos reutilicen
-- sus repertorios respectivos. Esa reutilización resuelve la estructura concreta, pero no
-- sustituye la relación entre formas: `forma_relaciones` es la que permite leer desde el
-- cuarteto y el terceto que ambos entran en la composición del soneto.

do $$
declare
	v_soneto uuid;
	v_cuarteto uuid;
	v_terceto uuid;
	v_componentes_codificados integer;
	v_relaciones integer;
begin
	select forma_id into v_soneto
	from public.formas_metricas
	where slug = 'soneto';

	select forma_id into v_cuarteto
	from public.formas_metricas
	where slug = 'cuarteto';

	select forma_id into v_terceto
	from public.formas_metricas
	where slug = 'terceto';

	if num_nonnulls(v_soneto, v_cuarteto, v_terceto) <> 3 then
		raise exception 'faltan el soneto, el cuarteto o el terceto';
	end if;

	-- La relación ontológica se apoya en dos reutilizaciones efectivas de la arquitectura del
	-- soneto, no solo en el nombre heredado de sus secciones.
	select count(distinct forma_reutilizada) into v_componentes_codificados
	from (
		select reutilizada.forma_id as forma_reutilizada
		from public.estructuras_secciones s
		join public.arquitecturas_forma propia
			on propia.arquitectura_id = s.arquitectura_id
		join public.arquitecturas_forma reutilizada
			on reutilizada.arquitectura_id = s.arquitectura_referenciada_id
		where propia.forma_id = v_soneto
			and reutilizada.forma_id in (v_cuarteto, v_terceto)
	) componentes;

	if v_componentes_codificados <> 2 then
		raise exception 'el soneto no reutiliza hoy las arquitecturas de sus dos componentes';
	end if;

	insert into public.forma_relaciones (
		forma_origen_id,
		forma_destino_id,
		tipo_relacion,
		cantidad_min,
		cantidad_max,
		orden_composicion,
		nota,
		estado_revision
	)
	values
		(
			v_soneto,
			v_cuarteto,
			'compuesta_por',
			2,
			2,
			1,
			'Los dos cuartetos forman los ocho primeros versos y comparten sus dos clases de rima.',
			'revisada'
		),
		(
			v_soneto,
			v_terceto,
			'compuesta_por',
			2,
			2,
			2,
			'Los dos tercetos forman los seis últimos versos y entrelazan entre sí sus clases de rima.',
			'revisada'
		)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set cantidad_min = excluded.cantidad_min,
		cantidad_max = excluded.cantidad_max,
		orden_composicion = excluded.orden_composicion,
		nota = excluded.nota,
		estado_revision = excluded.estado_revision,
		updated_at = now();

	select count(*) into v_relaciones
	from public.forma_relaciones
	where forma_origen_id = v_soneto
		and forma_destino_id in (v_cuarteto, v_terceto)
		and tipo_relacion = 'compuesta_por'
		and cantidad_min = 2
		and cantidad_max = 2;

	if v_relaciones <> 2 then
		raise exception 'se esperaban dos relaciones compositivas del soneto y quedaron %',
			v_relaciones;
	end if;
end;
$$;
