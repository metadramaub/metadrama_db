begin;

-- El pareado es una forma general: dos versos que riman, sea cual sea su medida.
--
-- Tenía cinco arquitecturas y ninguna decía bien lo que el pareado es. `principal` no
-- declaraba nada —ni metro, ni rima, ni secciones—; `hexasilabico` y `octosilabico` eran
-- dos medidas concretas dentro del arte menor, que es exactamente lo que el vocabulario
-- anterior registraba como **subtipos** de `pareado_de_arte_menor`; y `arte_menor`
-- declaraba el conjunto de medidas sin ninguna disposición de rima.
--
-- Quedan dos arquitecturas, y el corte entre ellas es el que la tradición hace: arte menor
-- y arte mayor. No es la medida exacta, porque el pareado no tiene repertorio cerrado de
-- medidas —el de arte mayor suele ser endecasílabo y los de arte menor hexasílabos u
-- octosílabos, pero podrían aparecer otros—. La medida exacta la declara el pasaje, así que
-- se pregunta, y se pregunta por posición para que el dístico heterométrico se pueda
-- registrar.
--
-- La disposición, en cambio, no admite variación: dos versos que riman solo pueden rimar
-- entre sí. Por eso el esquema es `aa` y es fijo. Lo que queda abierto en el arte menor es
-- el **tipo** de rima, que la fuente heredada dejó marcado como «otras»; el de arte mayor
-- sí declara consonancia.

do $$
declare
	v_forma uuid;
	v_menor uuid;
	v_mayor uuid;
	v_esquema uuid;
	v_grupo uuid;
	v_consonante uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';

	select arquitectura_id into v_menor
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'arte_menor';

	select arquitectura_id into v_mayor
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'endecasilabico';

	select tipo_rima_id into v_consonante
	from public.esquemas_rima where arquitectura_id = v_mayor and slug = 'pareados-sistematicos';

	-- ---------------------------------------------------------------------
	-- Lo que sobra
	-- ---------------------------------------------------------------------

	delete from public.arquitecturas_forma
	where forma_id = v_forma and slug in ('principal', 'hexasilabico', 'octosilabico');

	-- ---------------------------------------------------------------------
	-- Arte menor
	-- ---------------------------------------------------------------------

	update public.arquitecturas_forma
	set nombre = 'De arte menor',
		descripcion = 'Dos versos de arte menor que riman entre sí. La medida la declara el pasaje.',
		principal = true,
		grado = 'canonica',
		unidad_versos_min = 2,
		unidad_versos_max = 2,
		orden = 1
	where arquitectura_id = v_menor;

	-- El esquema de rima deja de estar vacío: la disposición de un dístico es `aa` y no
	-- puede ser otra. El tipo sigue sin declararse, que es lo que dice la fuente.
	update public.esquemas_rima
	set slug = 'aa',
		nombre = null,
		notacion = 'aa',
		ambito = 'estrofa',
		fijeza = 'fijo',
		comportamiento = 'secuencia_fija',
		estado_revision = 'revisada'
	where arquitectura_id = v_menor and slug = 'sin-declarar';

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_menor, 'medida_del_pareado', '¿Qué miden los dos versos?',
		'Señala la medida de cada verso. Si el dístico es isométrico, ambas son la misma.',
		'metro', 'unidad', 'opciones', 2, 2, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, posicion_unidad, orden
	)
	select
		v_grupo,
		format('verso_%s_%s', posicion.n, metro.slug),
		format('Verso %s · %s', posicion.n, lower(metro.nombre)),
		metro.metro_id,
		posicion.n,
		posicion.n * 100 + metro.silabas
	from generate_series(1, 2) as posicion(n)
	cross join public.metros metro
	where metro.silabas <= 8 and metro.activo;

	-- ---------------------------------------------------------------------
	-- Arte mayor
	-- ---------------------------------------------------------------------

	update public.arquitecturas_forma
	set slug = 'arte_mayor',
		nombre = 'De arte mayor',
		descripcion = 'Dos versos de arte mayor con rima consonante. Suelen ser endecasílabos, pero la medida la declara el pasaje.',
		principal = false,
		grado = 'canonica',
		unidad_versos_min = 2,
		unidad_versos_max = 2,
		orden = 2
	where arquitectura_id = v_mayor;

	-- El endecasílabo repetido era la medida de la serie que se disolvió aquí. La
	-- arquitectura general declara el conjunto de medidas de arte mayor que conoce.
	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos where arquitectura_id = v_mayor;

	delete from public.esquema_metrico_posiciones where esquema_metrico_id = v_esquema;

	update public.esquemas_metricos
	set slug = 'conjunto-11-12-14',
		nombre = 'De 11 a 14 sílabas',
		tipo = 'conjunto_permitido',
		ambito = 'estrofa'
	where esquema_metrico_id = v_esquema;

	insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
	select v_esquema, metro.metro_id, row_number() over (order by metro.silabas, metro.tipo)
	from public.metros metro
	where metro.silabas >= 9 and metro.activo;

	update public.esquemas_rima
	set slug = 'aa',
		nombre = null,
		notacion = 'AA',
		ambito = 'estrofa',
		fijeza = 'fijo',
		comportamiento = 'secuencia_fija',
		tipo_rima_id = v_consonante,
		estado_revision = 'revisada'
	where arquitectura_id = v_mayor and slug = 'pareados-sistematicos';

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_mayor, 'medida_del_pareado', '¿Qué miden los dos versos?',
		'Señala la medida de cada verso. Si el dístico es isométrico, ambas son la misma.',
		'metro', 'unidad', 'opciones', 2, 2, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, posicion_unidad, orden
	)
	select
		v_grupo,
		format('verso_%s_%s', posicion.n, metro.slug),
		format('Verso %s · %s', posicion.n, lower(metro.nombre)),
		metro.metro_id,
		posicion.n,
		posicion.n * 100 + metro.silabas
	from generate_series(1, 2) as posicion(n)
	cross join public.metros metro
	where metro.silabas >= 9 and metro.activo;
end;
$$;

do $$
declare
	v_arqs integer;
	v_vacios integer;
begin
	select count(*) into v_arqs
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'pareado';
	if v_arqs <> 2 then
		raise exception 'El pareado debe quedar con dos arquitecturas y tiene %', v_arqs;
	end if;

	select count(*) into v_vacios
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'pareado' and esquema.notacion is null;
	if v_vacios <> 0 then
		raise exception 'Quedan % esquemas de rima del pareado sin notación', v_vacios;
	end if;
end;
$$;

commit;
