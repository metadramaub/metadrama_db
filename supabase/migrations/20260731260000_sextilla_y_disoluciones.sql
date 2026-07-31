begin;

-- La sextilla por medidas, la doble como arquitectura suya, y dos formas que eran tiradas.
--
-- La sextilla isométrica preguntaba su medida entre 6, 7 y 8. Como toda forma isosilábica,
-- eso es arquitectura: una tirada no cambia de medida a mitad de camino.
--
-- La doble sextilla no es otra forma: es la sextilla con la unidad de doce, igual que la
-- redondilla doble es la redondilla con la unidad de ocho. Y la copla manriqueña no es
-- siquiera una arquitectura: es la doble respondiendo `abcabc:defdef`, un nombre que la
-- tradición dio a una disposición. Se registra como denominación de ese esquema.
--
-- `tercetos_sin_encadenar` y `pareados_endecasilabos` eran tiradas, no formas: una serie
-- cuya única sección se repite es N unidades de esa sección. El terceto encadenado sí es
-- forma aparte, porque su rima enlaza las unidades y la secuencia es una sola unidad
-- abierta.

-- ---------------------------------------------------------------------------
-- 1 · La sextilla isométrica se reparte por medidas
-- ---------------------------------------------------------------------------

do $$
declare
	v_isometrica uuid;
	v_forma uuid;
	v_medida record;
	v_destino uuid;
	v_metrico uuid;
begin
	select arquitectura.arquitectura_id, arquitectura.forma_id
	into v_isometrica, v_forma
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'sextilla' and arquitectura.slug = 'isometrica';

	-- El conjunto de medidas deja de tener sentido: cada arquitectura fija la suya.
	delete from public.esquemas_metricos
	where arquitectura_id = v_isometrica and tipo = 'conjunto_permitido';

	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_isometrica and slug = 'medida_comun';

	for v_medida in
		select * from (values
			(8, 'octosilabica', 'Octosilábica', 'octosílabos'),
			(7, 'heptasilabica', 'Heptasilábica', 'heptasílabos'),
			(6, 'hexasilabica', 'Hexasilábica', 'hexasílabos')
		) as m(silabas, slug, nombre, plural)
	loop
		if v_medida.silabas = 8 then
			-- La octosilábica hereda la identidad de la isométrica.
			update public.arquitecturas_forma
			set slug = v_medida.slug,
				nombre = v_medida.nombre,
				descripcion = 'Seis octosílabos con rima consonante de disposición variable.'
			where arquitectura_id = v_isometrica;
			v_destino := v_isometrica;
		else
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, grado,
				tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo
			)
			select
				v_forma, v_medida.slug, v_medida.nombre,
				format('Seis %s con rima consonante de disposición variable.', v_medida.plural),
				false, true, 'admitida', origen.tipo_rima_id, 6, 6, 'revisada', true
			from public.arquitecturas_forma origen
			where origen.arquitectura_id = v_isometrica
			returning arquitectura_id into v_destino;

			insert into public.esquemas_rima (
				arquitectura_id, slug, nombre, tipo_rima_id, ambito, fijeza, comportamiento, estado_revision
			)
			select v_destino, origen.slug, origen.nombre, origen.tipo_rima_id, origen.ambito,
				origen.fijeza, origen.comportamiento, origen.estado_revision
			from public.esquemas_rima origen
			where origen.arquitectura_id = v_isometrica;
		end if;

		insert into public.esquemas_metricos (
			arquitectura_id, slug, nombre, ambito, tipo, estado_revision
		)
		values (
			v_destino,
			array_to_string(array_fill(v_medida.silabas, array[6]), '-'),
			format('Seis %s', v_medida.plural),
			'estrofa', 'secuencia_fija', 'revisada'
		)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, posicion.n, metro.metro_id, 1
		from generate_series(1, 6) as posicion(n)
		join public.metros metro on metro.silabas = v_medida.silabas and metro.tipo = 'simple';
	end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · La doble sextilla pasa a ser arquitectura de la sextilla
-- ---------------------------------------------------------------------------

do $$
declare
	v_doble uuid;
	v_manriquena_forma uuid;
	v_manriquena_arq uuid;
	v_sextilla uuid;
	v_esquema uuid;
	v_grupo uuid;
	v_abierto uuid;
begin
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';

	select arquitectura.arquitectura_id into v_doble
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'doble_sextilla';

	select forma.forma_id, arquitectura.arquitectura_id
	into v_manriquena_forma, v_manriquena_arq
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'copla_manriqueña';

	-- El esquema de la manriqueña se traslada antes de que su forma desaparezca.
	update public.esquemas_rima
	set arquitectura_id = v_doble
	where arquitectura_id = v_manriquena_arq
		and notacion = 'abcabc:defdef'
	returning esquema_rima_id into v_esquema;

	-- «Otro esquema regular» deja de ser una restricción en prosa: con las dos disposiciones
	-- juntas, lo que la norma dice es que la rima es consonante y la disposición abierta.
	delete from public.esquema_rima_restricciones
	where esquema_rima_id in (
		select esquema_rima_id from public.esquemas_rima
		where arquitectura_id = v_doble and notacion is distinct from 'abcabc:defdef'
	);

	update public.esquemas_rima
	set notacion = null,
		slug = 'consonante-variable',
		nombre = 'Distribución consonante variable',
		fijeza = 'libre',
		comportamiento = 'libre'
	where arquitectura_id = v_doble and notacion is distinct from 'abcabc:defdef'
	returning esquema_rima_id into v_abierto;

	-- La arquitectura cambia de forma y de nombre; conserva sus secciones y sus rasgos.
	update public.arquitecturas_forma
	set forma_id = v_sextilla,
		slug = 'doble_pie_quebrado',
		nombre = 'Doble, de pie quebrado',
		descripcion = 'Doce versos en dos sextillas de pie quebrado. La disposición abcabc:defdef es la que la tradición llama copla manriqueña.',
		principal = false
	where arquitectura_id = v_doble;

	-- Marcar si la copla responde a la disposición manriqueña.
	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_doble, 'esquema_rima', 'Disposición de la rima',
		'Marca la disposición si es la manriqueña; déjalo vacío si es otra regular.',
		'rima', 'unidad', 'opciones', 0, 1, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, esquema_rima_id, orden)
	values (v_grupo, 'abcabc-defdef', 'abcabc:defdef', v_esquema, 1);

	insert into public.denominaciones_metricas (esquema_rima_id, nombre, slug_normalizado, tipo_alias, idioma)
	values (v_esquema, 'Copla manriqueña', 'copla_manriquena', 'equivalente', 'es');

	delete from public.formas_metricas where forma_id = v_manriquena_forma;
	delete from public.formas_metricas where slug = 'doble_sextilla';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Dos formas que eran tiradas
-- ---------------------------------------------------------------------------

-- El pareado gana la arquitectura endecasílaba que tenía la serie.
do $$
declare
	v_pareado uuid;
	v_serie uuid;
begin
	select forma_id into v_pareado from public.formas_metricas where slug = 'pareado';

	select arquitectura.arquitectura_id into v_serie
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'pareados_endecasilabos';

	update public.arquitecturas_forma
	set forma_id = v_pareado,
		slug = 'endecasilabico',
		nombre = 'Endecasílabo',
		descripcion = 'Dos endecasílabos consonantes. Una serie de pareados endecasílabos es una tirada de esta unidad.',
		unidad_versos_min = 2,
		unidad_versos_max = 2,
		principal = false
	where arquitectura_id = v_serie;

	-- La sección `pareado` de la serie decía que la unidad se repite: eso lo dice el rango.
	delete from public.estructuras_secciones where arquitectura_id = v_serie;

	delete from public.formas_metricas where slug = 'pareados_endecasilabos';
end;
$$;

-- Los tercetos sin encadenar son N tercetos: sus dos disposiciones se trasladan al terceto.
do $$
declare
	v_terceto uuid;
	v_serie uuid;
begin
	select arquitectura.arquitectura_id into v_terceto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto';

	select arquitectura.arquitectura_id into v_serie
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'tercetos_sin_encadenar';

	update public.esquemas_rima
	set arquitectura_id = v_terceto,
		ambito = 'estrofa',
		comportamiento = 'secuencia_fija'
	where arquitectura_id = v_serie;

	delete from public.formas_metricas where slug = 'tercetos_sin_encadenar';
end;
$$;

do $$
declare
	v_formas integer;
begin
	select count(*) into v_formas from public.formas_metricas where tipo_registro = 'forma';
	if v_formas <> 25 then
		raise exception 'Se esperaban 25 formas y hay %', v_formas;
	end if;
end;
$$;

commit;
