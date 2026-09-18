-- La fronte puede ir sin pies, y el remate declara medida y rima
--
-- Dos cosas que salieron el 18 de septiembre de 2026 al anotar la primera canción con el catálogo
-- nuevo, decididas con David:
--
-- 1. **Los piedi de la fronte pasan a opcionales.** Colgaban de la fronte con `1–1`, de modo que la
--    base no admitía una fronte sin sus dos pies. Pero una fronte puede verse clara y sus pies no:
--    las fuentes hablan de una fronte «formada por dos pies, normalmente de tres versos», y ese
--    «normalmente» es lo que el dato tiene que dejar registrar. Solo en «Estancias consonantes
--    variables»: en la regular de trece los pies son fijos por definición.
--
-- 2. **El remate no tenía dónde decir su medida ni su rima.** Ninguna de las tres canciones le
--    preguntaba nada, así que de un remate leído solo quedaba cuántos versos tiene (cuestión 5 de
--    la canción en cuestiones para el IP). Entran dos preguntas por arquitectura, sin `define_norma`
--    porque el remate no fija patrón: la medida de cada verso —que la vista deriva del esquema
--    «conjunto 7·11» de la arquitectura— y el esquema de rima escrito. La regular de trece no tenía
--    esquema conjunto, porque su estancia está fijada verso a verso: recibe uno atado a la sección
--    del remate, que es el único sitio donde su medida varía. La canción sin rima solo pregunta la
--    medida: su remate, como sus estancias, no rima.

begin;

do $$
declare
	v_hepta constant uuid := '4f2d2610-1e55-40a2-8ad4-e57708d80489';
	v_endeca constant uuid := '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
	v_arq record;
	v_remate uuid;
	v_esquema uuid;
	v_n integer;
	v_antes bigint;
	v_despues bigint;
	v_opciones integer;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ══════════════════════════════════════════════════════════ 1 · Los piedi, opcionales
	update public.estructuras_secciones s
	set repeticiones_min = 0
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where s.arquitectura_id = a.arquitectura_id
		and f.slug = 'cancion' and a.slug = 'estancias_consonantes_variables'
		and s.slug in ('primer_pie', 'segundo_pie') and s.repeticiones_min = 1;
	get diagnostics v_n = row_count;
	if v_n <> 2 then
		raise exception 'Se esperaba hacer opcionales dos piedi y se tocaron %.', v_n;
	end if;

	-- ══════════════════════════════════════════════════════════ 2 · El remate pregunta
	for v_arq in
		select a.arquitectura_id, a.slug, f.slug as forma
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug in ('cancion', 'cancion_petrarquista', 'cancion_sin_rima') and a.activo
	loop
		select seccion_id into v_remate from public.estructuras_secciones
		where arquitectura_id = v_arq.arquitectura_id and slug = 'remate';
		if v_remate is null then
			raise exception 'La arquitectura % no tiene remate.', v_arq.slug;
		end if;
		if exists (select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq.arquitectura_id and slug in ('medida_remate', 'esquema_rima_remate')) then
			raise exception 'La arquitectura % ya pregunta por el remate.', v_arq.slug;
		end if;

		-- La regular de trece no tiene esquema conjunto del que derivar 7 u 11 por verso.
		if v_arq.slug = 'regular_13_versos' then
			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug, medida_uniforme, seccion_id, descripcion)
			values (v_arq.arquitectura_id, 'conjunto', 'conjunto-7-11-remate', false, v_remate,
				'Las medidas que admite el remate: heptasílabos y endecasílabos en el orden que traiga, como en la estancia, pero sin fijarlo.')
			returning esquema_metrico_id into v_esquema;
			insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
			values (v_esquema, v_hepta, 1), (v_esquema, v_endeca, 2);
		end if;

		insert into public.grupos_eleccion_metrica
			(arquitectura_id, slug, dimension, alcance, seccion_id, tipo_control,
			 selecciones_min, selecciones_max, permite_aplicar_global, define_norma, activo, orden, ayuda_editor)
		select v_arq.arquitectura_id, 'medida_remate', 'metro', 'unidad', v_remate, 'opciones',
			1, s.versos_max, false, false, true, 90,
			'El remate no repite el patrón de la estancia: indica qué mide cada uno de sus versos.'
		from public.estructuras_secciones s where s.seccion_id = v_remate;

		if v_arq.forma <> 'cancion_sin_rima' then
			insert into public.grupos_eleccion_metrica
				(arquitectura_id, slug, dimension, alcance, seccion_id, tipo_control,
				 selecciones_min, selecciones_max, permite_aplicar_global, define_norma, activo, orden, ayuda_editor)
			values (v_arq.arquitectura_id, 'esquema_rima_remate', 'rima', 'unidad', v_remate, 'esquema_rima',
				1, 1, false, false, true, 91,
				'Escribe una letra por verso: minúscula para arte menor y mayúscula para arte mayor. El remate suele tomar sus rimas de la estancia, o abrir con un verso suelto.');
		end if;

		-- Ejecutado: la vista deriva opciones de medida para cada verso del remate.
		select count(*) into v_opciones
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq.arquitectura_id and g.slug = 'medida_remate';
		if v_opciones < 2 then
			raise exception 'El remate de % no ofrece medidas por verso: la vista derivó % opciones.', v_arq.slug, v_opciones;
		end if;
	end loop;

	-- Lo que leen la ficha, el editor y el demarcador.
	perform public.get_forma_metrica_publica_jerarquica('cancion');
	perform public.get_forma_metrica_publica_jerarquica('cancion_petrarquista');
	perform public.get_forma_metrica_publica_jerarquica('cancion_sin_rima');
	perform public.obtener_catalogo_demarcador();

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % -> %', v_antes, v_despues;
	end if;
end $$;

commit;
