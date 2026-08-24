-- El sexteto-lira estrena su octava variedad
--
-- El IP añadió al vocabulario legado `sexteto_lira_a4_aBaBCC` mientras se construía el catálogo
-- nuevo, y se quedó sin destino: la arquitectura heterométrica consonante tiene siete variedades
-- —A1 a A3, B1 y B2, C1 y C2— y esta es la octava.
--
-- Una variedad del sexteto-lira es un **par**: un esquema métrico y uno de rima. La familia A
-- comparte la rima `ababcc` y se distingue por dónde caen los heptasílabos:
--
-- | | Rima | Medidas |
-- |---|---|---|
-- | A1 · aBaBcC | ababcc | 7-11-7-11-7-11 |
-- | A2 · AbaBcC | ababcc | 11-7-7-11-7-11 |
-- | A3 · abaBcC | ababcc | 7-7-7-11-7-11 |
-- | **A4 · aBaBCC** | ababcc | **7-11-7-11-11-11** |
--
-- Lo propio de A4 es que **el pareado que cierra es enteramente endecasílabo**, como ya ocurre en
-- B2 y en C2 sobre otras rimas. El esquema métrico que necesita no existía; el de rima sí.
--
-- La usa una secuencia real: *La gran Semíramis*, vv. 1374-1487, 114 versos —diecinueve estrofas
-- justas—.

begin;

do $$
declare
	v_arq uuid;
	v_metrico uuid;
	v_rima uuid;
	v_variedad uuid;
	v_termino uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and a.activo;
	if v_arq is null then
		raise exception 'No existe la arquitectura heterométrica del sexteto-lira.';
	end if;

	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select termino_id into v_termino from public.vocabularios
	where termino = 'sexteto_lira_a4_aBaBCC' and categoria = 'estrofa_tipo';
	if v_hepta is null or v_endeca is null or v_termino is null then
		raise exception 'Falta el heptasílabo, el endecasílabo o el término legado.';
	end if;

	-- La arquitectura tenía siete variedades antes de esta.
	select count(*) into v_n from public.variedades_arquitectura
	where arquitectura_id = v_arq and activo;
	if v_n not in (7, 8) then
		raise exception 'El sexteto-lira tiene % variedades; se esperaban siete u ocho.', v_n;
	end if;

	-- ------------------------------------------------------------------ El esquema métrico
	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq and slug = '7-11-7-11-11-11';
	if v_metrico is null then
		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'secuencia', '7-11-7-11-11-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id)
		values (v_metrico, 1, v_hepta), (v_metrico, 2, v_endeca), (v_metrico, 3, v_hepta),
			(v_metrico, 4, v_endeca), (v_metrico, 5, v_endeca), (v_metrico, 6, v_endeca);
	end if;

	-- ------------------------------------------------------------------ La variedad
	select esquema_rima_id into v_rima from public.esquemas_rima
	where arquitectura_id = v_arq and notacion = 'ababcc';
	if v_rima is null then
		raise exception 'El sexteto-lira ha dejado de tener la rima ababcc de la familia A.';
	end if;

	select variedad_id into v_variedad from public.variedades_arquitectura
	where arquitectura_id = v_arq and slug = 'a4_aBaBCC';
	if v_variedad is null then
		insert into public.variedades_arquitectura (
			arquitectura_id, slug, nombre, descripcion, esquema_metrico_id, esquema_rima_id,
			activo, orden, modalidad, origen_termino_id
		)
		values (
			v_arq, 'a4_aBaBCC', 'A4 · aBaBCC',
			'Cierra con un pareado enteramente endecasílabo, sobre la misma alternancia de siete y '
			|| 'once de las demás de su familia.',
			v_metrico, v_rima, true, 4, 'admitida', v_termino
		)
		returning variedad_id into v_variedad;

		-- El orden de las que venían detrás se corre para dejarle su sitio en la familia.
		update public.variedades_arquitectura set orden = orden + 1
		where arquitectura_id = v_arq and variedad_id <> v_variedad and orden >= 4;
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.variedades_arquitectura
	where arquitectura_id = v_arq and activo;
	if v_n <> 8 then
		raise exception 'El sexteto-lira se ha quedado con % variedades, no con ocho.', v_n;
	end if;

	-- Sus seis posiciones dicen las medidas que dice su nombre.
	select count(*) into v_n from public.esquema_metrico_posiciones
	where esquema_metrico_id = v_metrico;
	if v_n <> 6 then
		raise exception 'El esquema métrico de A4 tiene % posiciones, no seis.', v_n;
	end if;

	if exists (
		select 1 from public.esquema_metrico_posiciones
		where esquema_metrico_id = v_metrico and posicion in (1, 3) and metro_id <> v_hepta
	) or exists (
		select 1 from public.esquema_metrico_posiciones
		where esquema_metrico_id = v_metrico and posicion in (2, 4, 5, 6) and metro_id <> v_endeca
	) then
		raise exception 'Las medidas de A4 no son las de aBaBCC.';
	end if;

	-- Y la secuencia real que la usaba deja de quedarse sin variedad.
	if not exists (
		select 1 from public.propuesta_elecciones_secuencia pe
		join public.propuesta_metrica_secuencia p on p.secuencia_id = pe.secuencia_id
		where p.estrofa_tipo_id = v_termino
	) then
		raise exception 'La secuencia de A4 sigue sin recibir propuesta.';
	end if;

	if public.get_forma_metrica_publica('sexteto_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del sexteto-lira ha dejado de responder.';
	end if;
end $$;

commit;
