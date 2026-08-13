-- Las reutilizaciones entre formas tienen también su correspondencia ontológica.
--
-- La sección conserva la precisión de arquitectura: qué realización concreta se reutiliza.
-- `forma_relaciones` conserva el significado y la navegación inversa: qué formas componen o
-- explican a otra. No se duplican las relaciones en sentido inverso porque la lectura pública
-- ya distingue el origen y el destino de una sola fila.

do $$
declare
	v_novena uuid;
	v_decima uuid;
	v_terceto_encadenado uuid;
	v_cuarteto uuid;
	v_redondilla uuid;
	v_quintilla uuid;
	v_relaciones integer;
begin
	select forma_id into v_novena from public.formas_metricas where slug = 'novena';
	select forma_id into v_decima from public.formas_metricas where slug = 'decima';
	select forma_id into v_terceto_encadenado
	from public.formas_metricas where slug = 'terceto_encadenado';
	select forma_id into v_cuarteto from public.formas_metricas where slug = 'cuarteto';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';

	if num_nonnulls(
		v_novena,
		v_decima,
		v_terceto_encadenado,
		v_cuarteto,
		v_redondilla,
		v_quintilla
	) <> 6 then
		raise exception 'faltan formas necesarias para completar las relaciones estructurales';
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
			v_novena,
			v_redondilla,
			'compuesta_por',
			1,
			1,
			null,
			'La copla novena combina una redondilla y una quintilla; sus dos arquitecturas invierten el orden de los componentes.',
			'revisada'
		),
		(
			v_novena,
			v_quintilla,
			'compuesta_por',
			1,
			1,
			null,
			'La copla novena combina una redondilla y una quintilla; sus dos arquitecturas invierten el orden de los componentes.',
			'revisada'
		),
		(
			v_decima,
			v_redondilla,
			'compuesta_por',
			1,
			2,
			1,
			'La espinela articula dos redondillas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.',
			'revisada'
		),
		(
			v_terceto_encadenado,
			v_redondilla,
			'relacionada_con',
			null,
			null,
			null,
			'La arquitectura octosilábica cierra la cadena con una redondilla cruzada, equivalente funcional del serventesio final de la endecasilábica.',
			'revisada'
		),
		(
			v_cuarteto,
			v_redondilla,
			'relacionada_con',
			null,
			null,
			null,
			'Comparten la organización de cuatro versos consonantes en dos clases de rima; se distinguen por el arte mayor o menor de sus versos.',
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
	where (
		(forma_origen_id = v_novena and forma_destino_id in (v_redondilla, v_quintilla)
			and tipo_relacion = 'compuesta_por')
		or (forma_origen_id = v_decima and forma_destino_id = v_redondilla
			and tipo_relacion = 'compuesta_por')
		or (forma_origen_id = v_terceto_encadenado and forma_destino_id = v_redondilla
			and tipo_relacion = 'relacionada_con')
		or (forma_origen_id = v_cuarteto and forma_destino_id = v_redondilla
			and tipo_relacion = 'relacionada_con')
	);

	if v_relaciones <> 5 then
		raise exception 'se esperaban cinco relaciones nuevas o actualizadas y quedaron %',
			v_relaciones;
	end if;
end;
$$;
