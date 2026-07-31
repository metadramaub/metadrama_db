begin;

-- El terceto encadenado octosílabo declara la misma norma en su medida.
--
-- El terceto octosílabo adapta a los octosílabos españoles los tercetos encadenados
-- endecasílabos de raíz italiana, y no cambia nada más: el mismo encadenamiento, el mismo
-- cierre en serventesio, las mismas dos secciones. Es, por tanto, una arquitectura por
-- medida —como las cuatro del romance o las tres de la redondilla—, y estaba a medias:
-- declaraba su esquema métrico y nada más. Ni rima, ni secciones.
--
-- El esquema se copia en vez de reutilizarse porque un esquema pertenece a una sola
-- arquitectura. Es el precio conocido de repartir por medidas: el romance lo paga con
-- cuatro copias de su asonancia y la redondilla con dos disposiciones por medida.
--
-- La notación va en minúsculas porque el arte menor se escribe así.

do $$
declare
	v_octosilabico uuid;
	v_endecasilabico uuid;
	v_origen uuid;
	v_destino uuid;
	v_metrico uuid;
begin
	select arquitectura.arquitectura_id into v_octosilabico
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado' and arquitectura.slug = 'octosilabico';

	select arquitectura.arquitectura_id into v_endecasilabico
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado' and arquitectura.slug = 'endecasilabico_consonante';

	select esquema_rima_id into v_origen
	from public.esquemas_rima where arquitectura_id = v_endecasilabico;

	select esquema_metrico_id into v_metrico
	from public.esquemas_metricos where arquitectura_id = v_octosilabico;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, fijeza,
		comportamiento, estado_revision
	)
	select
		v_octosilabico, origen.slug, origen.nombre,
		'aba | bcb | cdc | … | yzyz',
		origen.tipo_rima_id, origen.ambito, origen.fijeza, origen.comportamiento, 'revisada'
	from public.esquemas_rima origen
	where origen.esquema_rima_id = v_origen
	returning esquema_rima_id into v_destino;

	-- Si algún disparador hubiera derivado posiciones de la notación, se descartan: las del
	-- encadenado se declaran a mano porque nombran la sección a la que pertenecen.
	delete from public.esquema_rima_posiciones where esquema_rima_id = v_destino;

	insert into public.esquema_rima_posiciones (
		esquema_rima_id, bloque, seccion, posicion, ubicacion, clase_rima, suelto, opcional, nota
	)
	select v_destino, origen.bloque, origen.seccion, origen.posicion, origen.ubicacion,
		origen.clase_rima, origen.suelto, origen.opcional, origen.nota
	from public.esquema_rima_posiciones origen
	where origen.esquema_rima_id = v_origen;

	insert into public.esquema_rima_enlaces (
		esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
		desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino,
		tipo_enlace, obligatorio, nota
	)
	select v_destino, origen.bloque_origen, origen.posicion_origen, origen.ubicacion_origen,
		origen.desplazamiento_bloque, origen.bloque_destino, origen.posicion_destino,
		origen.ubicacion_destino, origen.tipo_enlace, origen.obligatorio, origen.nota
	from public.esquema_rima_enlaces origen
	where origen.esquema_rima_id = v_origen;

	-- Las dos secciones apuntan al esquema métrico y al de rima de su propia arquitectura.
	insert into public.estructuras_secciones (
		arquitectura_id, seccion_padre_id, tipo_seccion, nombre, orden, repeticiones_min,
		repeticiones_max, versos_min, versos_max, esquema_metrico_id, esquema_rima_id, nota
	)
	select v_octosilabico, null, origen.tipo_seccion, origen.nombre, origen.orden,
		origen.repeticiones_min, origen.repeticiones_max, origen.versos_min, origen.versos_max,
		v_metrico, v_destino, origen.nota
	from public.estructuras_secciones origen
	where origen.arquitectura_id = v_endecasilabico;
end;
$$;

do $$
declare
	v_posiciones integer;
	v_enlaces integer;
	v_secciones integer;
begin
	select
		count(*) filter (where true),
		(select count(*) from public.esquema_rima_enlaces enlace
			join public.esquemas_rima esquema on esquema.esquema_rima_id = enlace.esquema_rima_id
			join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = esquema.arquitectura_id
			where arquitectura.slug = 'octosilabico'
				and arquitectura.forma_id = (select forma_id from public.formas_metricas where slug = 'terceto_encadenado')),
		(select count(*) from public.estructuras_secciones seccion
			join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = seccion.arquitectura_id
			where arquitectura.slug = 'octosilabico'
				and arquitectura.forma_id = (select forma_id from public.formas_metricas where slug = 'terceto_encadenado'))
	into v_posiciones, v_enlaces, v_secciones
	from public.esquema_rima_posiciones posicion
	join public.esquemas_rima esquema on esquema.esquema_rima_id = posicion.esquema_rima_id
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = esquema.arquitectura_id
	where arquitectura.slug = 'octosilabico'
		and arquitectura.forma_id = (select forma_id from public.formas_metricas where slug = 'terceto_encadenado');

	if v_posiciones <> 3 or v_enlaces <> 2 or v_secciones <> 2 then
		raise exception 'El encadenado octosílabo debe tener 3 posiciones, 2 enlaces y 2 secciones; tiene %, % y %',
			v_posiciones, v_enlaces, v_secciones;
	end if;
end;
$$;

commit;
