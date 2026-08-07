-- El Diccionario define primero la composición, no la estrofa.
--
-- La revisión conjunta dejó su afirmación en la Sextina estrófica porque la misma entrada
-- distingue también los sentidos «sexteto», «sexta rima» y «sextina real». El destino hacía
-- invisible en la ficha de la composición la fuente que más explícitamente la define como 39
-- endecasílabos. La afirmación se mueve a la composición y conserva en el resumen la
-- distinción terminológica.
--
-- La auditoría mostró además que la nueva estrofa declaraba `sin_rima` solo en la arquitectura.
-- Se explicitan sus seis finales sueltos como `------`: no es una rima nueva, sino la
-- representación computable de que ninguna de las seis palabras finales rima con otra.

begin;

do $$
declare
	v_composicion uuid;
	v_estrofa uuid;
	v_arquitectura uuid;
	v_diccionario uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_sin_rima uuid;
	v_esquema uuid;
	v_n integer;
begin
	select forma_id into v_composicion
	from public.formas_metricas where slug = 'sextina';

	select forma_id into v_estrofa
	from public.formas_metricas where slug = 'sextina_estrofa';

	select arquitectura_id, tipo_rima_id into v_arquitectura, v_sin_rima
	from public.arquitecturas_forma
	where forma_id = v_estrofa and slug = 'endecasilabica_sin_rima';

	if num_nonnulls(v_composicion, v_estrofa, v_arquitectura, v_sin_rima) <> 4
		or not exists (
			select 1 from public.fuentes_metricas where fuente_id = v_diccionario
		)
	then
		raise exception 'Falta alguna de las dos Sextinas, su arquitectura o el Diccionario';
	end if;

	update public.afirmaciones_fuentes_metricas
	set forma_id = v_composicion,
		resumen = 'Define primero la sextina como composición de 39 endecasílabos en seis estrofas y un remate, con las seis palabras finales sometidas a la permutación canónica. Registra además otros sentidos del nombre —sexteto y sexta rima— y remite «sextina real» a sexta rima.',
		updated_at = now()
	where fuente_id = v_diccionario and forma_id = v_estrofa;

	if not found then
		raise exception 'No se encontró en la Sextina estrófica la afirmación del Diccionario';
	end if;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id,
		ambito, modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values (
		v_arquitectura,
		'sin_rima',
		'Sin rima convencional',
		'------',
		v_sin_rima,
		'unidad',
		'definitoria',
		'secuencia',
		'Los seis versos terminan en palabras distintas, sin correspondencia de rima entre ellas.',
		'revisada'
	)
	returning esquema_rima_id into v_esquema;

	select count(*) into v_n
	from public.esquema_rima_posiciones
	where esquema_rima_id = v_esquema
		and suelto
		and clase_rima is null;

	if v_n <> 6 then
		raise exception 'El esquema sin rima debe generar seis posiciones sueltas y generó %', v_n;
	end if;

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where fuente_id = v_diccionario and forma_id = v_composicion;

	if v_n <> 1 then
		raise exception 'El Diccionario debe aparecer una vez en la ficha de la composición';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
