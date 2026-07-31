begin;

-- El pareado tiene una sola arquitectura.
--
-- Partirlo en arte menor y arte mayor aplicaba un criterio que el catálogo no usa en
-- ninguna otra forma: el arte no se modela, se deriva del metro. Y el corte tampoco
-- separaba regímenes de rima, porque el pareado admite consonancia y asonancia en
-- cualquiera de sus medidas —el endecasílabo suele ser consonante, pero eso es lo habitual,
-- no la norma—.
--
-- Lo que queda es lo que el pareado realmente declara: dos versos que riman entre sí. La
-- medida de cada uno y el tipo de rima los declara el pasaje, así que se preguntan. Que el
-- dístico sea de arte menor o mayor se lee en el metro elegido, como en el resto del
-- catálogo.

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_sobra uuid;
	v_esquema uuid;
	v_consonante uuid;
	v_asonante uuid;
	v_grupo uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';

	select arquitectura_id into v_arq
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'arte_menor';

	select arquitectura_id into v_sobra
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'arte_mayor';

	select esquema.tipo_rima_id into v_consonante
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and esquema.slug = 'abab'
	limit 1;

	select esquema.tipo_rima_id into v_asonante
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'romance' and esquema.slug = 'asonancia-pares'
	limit 1;

	delete from public.arquitecturas_forma where arquitectura_id = v_sobra;

	update public.arquitecturas_forma
	set slug = 'cualquier_medida',
		nombre = 'De cualquier medida',
		descripcion = 'Dos versos que riman entre sí. La medida de cada uno y el tipo de rima los declara el pasaje.',
		principal = true,
		grado = 'canonica'
	where arquitectura_id = v_arq;

	-- ---------------------------------------------------------------------
	-- La medida: todo el repertorio del catálogo
	-- ---------------------------------------------------------------------

	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos where arquitectura_id = v_arq;

	update public.esquemas_metricos
	set slug = 'conjunto-4-14',
		nombre = 'De 4 a 14 sílabas',
		tipo = 'conjunto_permitido',
		ambito = 'estrofa'
	where esquema_metrico_id = v_esquema;

	delete from public.esquema_metrico_opciones where esquema_metrico_id = v_esquema;

	insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
	select v_esquema, metro.metro_id, row_number() over (order by metro.silabas, metro.tipo)
	from public.metros metro
	where metro.activo;

	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug = 'medida_del_pareado';

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_arq, 'medida_del_pareado', '¿Qué miden los dos versos?',
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
	where metro.activo;

	-- ---------------------------------------------------------------------
	-- La rima: la disposición es fija, el tipo se pregunta
	-- ---------------------------------------------------------------------

	delete from public.esquemas_rima where arquitectura_id = v_arq;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, fijeza,
		comportamiento, estado_revision
	)
	values
		(v_arq, 'aa-consonante', 'Consonante', 'aa', v_consonante, 'estrofa', 'admitido', 'secuencia_fija', 'revisada'),
		(v_arq, 'aa-asonante', 'Asonante', 'aa', v_asonante, 'estrofa', 'admitido', 'secuencia_fija', 'revisada');

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_arq, 'tipo_de_rima', '¿Los dos versos riman en consonante o en asonante?',
		'El pareado admite ambas. El endecasílabo suele ser consonante, pero no lo exige.',
		'rima', 'unidad', 'opciones', 1, 1, true, 'revisada', true, 2
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, esquema_rima_id, orden
	)
	select
		v_grupo,
		case esquema.slug when 'aa-consonante' then 'consonante' else 'asonante' end,
		esquema.nombre,
		esquema.esquema_rima_id,
		case esquema.slug when 'aa-consonante' then 1 else 2 end
	from public.esquemas_rima esquema
	where esquema.arquitectura_id = v_arq;
end;
$$;

do $$
declare
	v_arqs integer;
	v_opciones integer;
begin
	select count(*) into v_arqs
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'pareado';
	if v_arqs <> 1 then
		raise exception 'El pareado debe quedar con una arquitectura y tiene %', v_arqs;
	end if;

	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'pareado' and grupo.slug = 'medida_del_pareado';
	if v_opciones <> 18 then
		raise exception 'Se esperaban 18 opciones de medida y hay %', v_opciones;
	end if;
end;
$$;

commit;
