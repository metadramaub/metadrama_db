-- Las enlazadas se dibujan como la serie que son
--
-- Corrección de las tres migraciones anteriores, vista en la ficha servida. Las tres estrofas
-- enlazadas se crearon como series —`nivel_estructural = 'serie'`, con su esquema de rima cíclico—
-- pero declarando además la extensión de la unidad, `unidad_versos_min = unidad_versos_max`. Con
-- eso, la ficha las pintaba como **estrofas cerradas**: la extensión decía «Fijo · 6 versos», que
-- se lee como si la serie entera midiera seis, y la rejilla no dibujaba el ciclo.
--
-- El motivo está en `src/lib/metrica/rejilla.ts` y es una decisión deliberada de ese módulo: cuando
-- el esquema elegido es cíclico, el esqueleto de secciones se descarta, y entonces **una unidad de
-- extensión fija manda sobre el ciclo** —toma las columnas de ella y deja `cicla = false`—. El
-- terceto encadenado, que es la otra serie encadenada del catálogo, no declara extensión de unidad
-- y por eso sí cicla: su ficha muestra el ⟳ y las flechas de enlace entre vueltas.
--
-- Las tres pasan a lo mismo: **la extensión no se declara, porque una serie no la tiene**. Las
-- columnas salen del esquema, que ya dice cuántos versos trae cada vuelta, y las partes —el verso
-- de enlace, el quebrado, la redondilla o la quintilla— siguen leyéndose en su bloque.
--
-- *Lo que la rejilla sigue sin poder dibujar es el enlace mismo: la clase que aparece una sola vez
-- dentro del ciclo es la que viene de la estrofa anterior, y el módulo solo sabe derivar el camino
-- contrario —una clase que vuelve en la vuelta siguiente, como la del terceto encadenado—. Va en
-- las notas de posición y en la prosa, y queda anotado en pendientes.*

begin;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_n integer;
	v_fila text[];
begin
	foreach v_fila slice 1 in array array[
		array['redondilla_enlazada', '4'], array['sextilla_enlazada', '6'],
		array['septilla_enlazada', '7']
	] loop
		select a.arquitectura_id into v_arq
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = v_fila[1] and a.activo;

		if v_arq is null then
			raise exception 'No aparece la arquitectura de %.', v_fila[1];
		end if;

		-- La declaraba fija en tantos versos como trae una vuelta, o ya está retirada.
		select coalesce(unidad_versos_max::text, 'nula') into v_actual
		from public.arquitecturas_forma where arquitectura_id = v_arq;
		if v_actual not in (v_fila[2], 'nula') then
			raise exception 'La unidad de % mide %, y no es lo esperado.', v_fila[1], v_actual;
		end if;

		update public.arquitecturas_forma
		set unidad_versos_min = null, unidad_versos_max = null
		where arquitectura_id = v_arq;

		-- Y su esquema sigue siendo cíclico y trayendo las columnas de la vuelta.
		if not exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = v_arq and er.tipo_secuencia = 'ciclo'
				and (select count(*) from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id) = v_fila[2]::integer
		) then
			raise exception 'El esquema de % ha dejado de dibujar su vuelta.', v_fila[1];
		end if;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Ninguna serie del catálogo declara ya extensión de unidad: es lo que las hace series.
	select string_agg(f.slug, ', ' order by f.slug) into v_actual
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where a.activo and f.activo and f.nivel_estructural = 'serie'
		and a.unidad_versos_max is not null;
	if v_actual is not null then
		raise exception 'Estas series todavía declaran extensión de unidad: %', v_actual;
	end if;

	-- Y las tres enlazadas conservan sus partes, que el ciclo no borra.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug in ('sextilla_enlazada', 'septilla_enlazada');
	if v_n <> 5 then
		raise exception 'Las dos enlazadas con partes tienen %, y deben ser cinco.', v_n;
	end if;

	foreach v_fila slice 1 in array array[
		array['redondilla_enlazada'], array['sextilla_enlazada'], array['septilla_enlazada']
	] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
