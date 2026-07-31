begin;

-- La medida de una forma isosilábica es arquitectura.
--
-- Una tirada de redondillas no cambia de medida a mitad de camino: si cambia, ha empezado
-- otra secuencia. Lo mismo el sexteto como unidad estrófica. Preguntarlo era tratar como
-- elección algo que la norma no deja variar, y dejaba el mismo hecho en dos niveles
-- distintos según la forma: arquitectura en el romance y en el terceto encadenado, pregunta
-- en la redondilla y en el sexteto.
--
-- El precio es que un esquema de rima pertenece a una sola arquitectura, así que `abba` y
-- `abab` se repiten en cada medida de la redondilla. El romance ya lo paga con cuatro copias
-- de su asonancia. Los slugs hacen visible que son la misma disposición.
--
-- Y con el sexteto repartido por medidas, la sexta rima —el sexteto clásico— deja de ser
-- forma: es el sexteto endecasílabo que responde `ABABCC`. Se registra como variedad
-- reconocida, con su denominación, que es lo que la variedad existe para decir.

-- ---------------------------------------------------------------------------
-- 1 · La redondilla: una arquitectura por medida
-- ---------------------------------------------------------------------------

do $$
declare
	v_simple uuid;
	v_forma uuid;
	v_medida record;
	v_nueva uuid;
	v_grupo uuid;
	v_abba uuid;
	v_abab uuid;
begin
	select arquitectura.arquitectura_id, arquitectura.forma_id
	into v_simple, v_forma
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and arquitectura.slug = 'simple';

	if v_simple is null then
		raise exception 'No se encontró la arquitectura simple de la redondilla';
	end if;

	-- La octosilábica hereda la identidad de `simple`: así la denominación «Cuarteta», que
	-- apunta a su esquema cruzado, no se queda sin destino.
	update public.arquitecturas_forma
	set slug = 'octosilabica',
		nombre = 'Octosilábica',
		descripcion = 'Cuatro octosílabos.'
	where arquitectura_id = v_simple;

	for v_medida in
		select * from (values (7, 'heptasilabica', 'Heptasilábica'), (6, 'hexasilabica', 'Hexasilábica'))
			as m(silabas, slug, nombre)
	loop
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, grado,
			unidad_versos_min, unidad_versos_max, estado_revision, activo
		)
		values (
			v_forma, v_medida.slug, v_medida.nombre,
			format('Cuatro versos de %s sílabas.', v_medida.silabas),
			false, true, 'admitida', 4, 4, 'revisada', true
		)
		returning arquitectura_id into v_nueva;

		-- El esquema métrico de esa medida se traslada; no se copia.
		update public.esquemas_metricos esquema
		set arquitectura_id = v_nueva
		where esquema.arquitectura_id = v_simple
			and esquema.slug = format('%s-%s-%s-%s', v_medida.silabas, v_medida.silabas, v_medida.silabas, v_medida.silabas);

		-- Las dos disposiciones sí se copian: un esquema pertenece a una arquitectura.
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, fijeza,
			comportamiento, estado_revision
		)
		select v_nueva, origen.slug, origen.nombre, origen.notacion, origen.tipo_rima_id,
			origen.ambito, origen.fijeza, origen.comportamiento, origen.estado_revision
		from public.esquemas_rima origen
		where origen.arquitectura_id = v_simple;

		select esquema_rima_id into v_abba
		from public.esquemas_rima where arquitectura_id = v_nueva and slug = 'abba';
		select esquema_rima_id into v_abab
		from public.esquemas_rima where arquitectura_id = v_nueva and slug = 'abab';

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
			selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
		)
		select v_nueva, origen.slug, origen.nombre, origen.ayuda_editor, origen.dimension,
			origen.alcance, origen.tipo_control, origen.selecciones_min, origen.selecciones_max,
			origen.permite_aplicar_global, origen.estado_revision, origen.activo, origen.orden
		from public.grupos_eleccion_metrica origen
		where origen.arquitectura_id = v_simple and origen.slug = 'disposicion_rima'
		returning grupo_eleccion_id into v_grupo;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, descripcion, esquema_rima_id, activo, orden
		)
		select
			v_grupo, origen.slug, origen.nombre, origen.descripcion,
			case when origen.slug like '%abba%' or lower(origen.nombre) like '%abraz%' then v_abba else v_abab end,
			origen.activo, origen.orden
		from public.opciones_eleccion_metrica origen
		join public.grupos_eleccion_metrica grupo
			on grupo.grupo_eleccion_id = origen.grupo_eleccion_id
		where grupo.arquitectura_id = v_simple and grupo.slug = 'disposicion_rima';
	end loop;

	-- La medida deja de preguntarse.
	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_simple and slug = 'medida_redondilla';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · El sexteto: una arquitectura por medida de arte mayor
-- ---------------------------------------------------------------------------

do $$
declare
	v_actual uuid;
	v_forma uuid;
	v_medida record;
	v_nueva uuid;
	v_metrico uuid;
	v_rima uuid;
begin
	select arquitectura.arquitectura_id, arquitectura.forma_id
	into v_actual, v_forma
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sexteto';

	for v_medida in
		select * from (values
			(11, 'endecasilabica', 'Endecasilábica', true),
			(12, 'dodecasilabica', 'Dodecasilábica', false),
			(14, 'alejandrina', 'Alejandrina', false)
		) as m(silabas, slug, nombre, principal)
	loop
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, grado,
			unidad_versos_min, unidad_versos_max, estado_revision, activo
		)
		values (
			v_forma, v_medida.slug, v_medida.nombre,
			format('Seis versos de %s sílabas con rima consonante.', v_medida.silabas),
			false, true, 'admitida', 6, 6, 'revisada', true
		)
		returning arquitectura_id into v_nueva;

		insert into public.esquemas_metricos (
			arquitectura_id, slug, nombre, ambito, tipo, estado_revision
		)
		select
			v_nueva,
			array_to_string(array_fill(v_medida.silabas, array[6]), '-'),
			format('Seis %s', case v_medida.silabas when 11 then 'endecasílabos' when 12 then 'dodecasílabos' else 'alejandrinos' end),
			'estrofa', 'secuencia_fija', 'revisada'
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, posicion.n, metro.metro_id, 1
		from generate_series(1, 6) as posicion(n)
		join public.metros metro on metro.silabas = v_medida.silabas and metro.tipo = 'simple';

		-- La disposición sigue siendo abierta: el sexteto admite cualquiera consonante.
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, ambito, fijeza, comportamiento, estado_revision
		)
		values (
			v_nueva, 'consonante-variable', 'Distribución consonante variable',
			'estrofa', 'libre', 'libre', 'revisada'
		)
		returning esquema_rima_id into v_rima;

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
			selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
		)
		values (
			v_nueva, 'esquema_rima_observado', 'Esquema de rima observado',
			'Escribe seis posiciones con letras y guiones, por ejemplo AABCCB.',
			'rima', 'unidad', 'esquema_rima', 1, 1, true, 'revisada', true, 1
		);
	end loop;

	-- La arquitectura antigua, con su conjunto de medidas y su pregunta, desaparece.
	delete from public.arquitecturas_forma where arquitectura_id = v_actual;

	update public.arquitecturas_forma
	set principal = true
	where forma_id = v_forma and slug = 'endecasilabica';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · La sexta rima es una variedad del sexteto endecasílabo
-- ---------------------------------------------------------------------------

do $$
declare
	v_sexteto uuid;
	v_sexta_rima_forma uuid;
	v_termino uuid;
	v_metrico uuid;
	v_rima uuid;
	v_variedad uuid;
begin
	select arquitectura.arquitectura_id into v_sexteto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sexteto' and arquitectura.slug = 'endecasilabica';

	select forma_id, origen_termino_id into v_sexta_rima_forma, v_termino
	from public.formas_metricas where slug = 'sexta_rima';

	select esquema_metrico_id into v_metrico
	from public.esquemas_metricos where arquitectura_id = v_sexteto;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, ambito, fijeza, comportamiento, estado_revision
	)
	values (v_sexteto, 'ababcc', null, 'ABABCC', 'estrofa', 'admitido', 'secuencia_fija', 'revisada')
	returning esquema_rima_id into v_rima;

	insert into public.variedades_arquitectura (
		arquitectura_id, slug, nombre, descripcion, esquema_metrico_id, esquema_rima_id,
		preferente, estado_revision, activo, orden, origen_termino_id
	)
	values (
		v_sexteto, 'sexta_rima', 'Sexta rima',
		'Sexteto endecasílabo con disposición ABABCC, la variedad que la tradición nombra sexta rima o sexteto clásico. Procede de la sestina rima italiana.',
		v_metrico, v_rima, true, 'revisada', true, 1, v_termino
	)
	returning variedad_id into v_variedad;

	insert into public.denominaciones_metricas (variedad_id, nombre, slug_normalizado, tipo_alias, idioma)
	values
		(v_variedad, 'Sexta rima', 'sexta_rima', 'equivalente', 'es'),
		(v_variedad, 'Sexteto clásico', 'sexteto_clasico', 'equivalente', 'es');

	-- La forma desaparece: su relación de subtipo con el sexteto se va con ella.
	delete from public.formas_metricas where forma_id = v_sexta_rima_forma;
end;
$$;

do $$
declare
	v_total integer;
begin
	select count(*) into v_total
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla';
	if v_total <> 4 then
		raise exception 'La redondilla debe tener cuatro arquitecturas y tiene %', v_total;
	end if;

	select count(*) into v_total
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sexteto';
	if v_total <> 3 then
		raise exception 'El sexteto debe tener tres arquitecturas y tiene %', v_total;
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'sexta_rima') then
		raise exception 'La sexta rima sigue siendo una forma';
	end if;
end;
$$;

commit;
