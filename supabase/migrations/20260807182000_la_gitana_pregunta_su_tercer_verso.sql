-- La variación del tercer verso de la seguidilla gitana debe llegar a la realización.
--
-- El esquema ya recogía diez, once y doce sílabas, pero no había ninguna pregunta que
-- permitiera escoger la medida observada. Se declaran las tres secuencias completas —no tres
-- fragmentos posicionales— y una elección de unidad. El endecasílabo ocupa el primer lugar
-- porque Quilis y Navarro Tomás lo presentan como la medida general; el decasílabo y el
-- dodecasílabo son alternativas documentadas.

begin;

do $$
declare
	v_arq uuid;
	v_esquema uuid;
	v_grupo uuid;
	v_m6 uuid;
	v_m10 uuid;
	v_m11 uuid;
	v_m12 uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'seguidilla' and a.slug = 'gitana';

	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos
	where arquitectura_id = v_arq and slug = '6-6-10-11-12-6';

	select metro_id into v_m6 from public.metros where slug = 'hexasilabo';
	select metro_id into v_m10 from public.metros where slug = 'decasilabo';
	select metro_id into v_m11 from public.metros where slug = 'endecasilabo';
	select metro_id into v_m12 from public.metros where slug = 'dodecasilabo';

	if num_nonnulls(v_arq, v_esquema, v_m6, v_m10, v_m11, v_m12) <> 6 then
		raise exception 'Falta la seguidilla gitana, su esquema o alguno de sus metros';
	end if;

	delete from public.esquema_metrico_posiciones
	where esquema_metrico_id = v_esquema;

	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, alternativa, nota)
	values
		(v_esquema, 1, v_m6, 1, 'Primer hexasílabo.'),
		(v_esquema, 2, v_m6, 1, 'Segundo hexasílabo.'),
		(v_esquema, 3, v_m11, 1, 'Medida general del tercer verso.'),
		(v_esquema, 4, v_m6, 1, 'Hexasílabo final.'),
		(v_esquema, 1, v_m6, 2, 'Primer hexasílabo.'),
		(v_esquema, 2, v_m6, 2, 'Segundo hexasílabo.'),
		(v_esquema, 3, v_m10, 2, 'Alternativa decasílaba del tercer verso.'),
		(v_esquema, 4, v_m6, 2, 'Hexasílabo final.'),
		(v_esquema, 1, v_m6, 3, 'Primer hexasílabo.'),
		(v_esquema, 2, v_m6, 3, 'Segundo hexasílabo.'),
		(v_esquema, 3, v_m12, 3, 'Alternativa dodecasílaba del tercer verso.'),
		(v_esquema, 4, v_m6, 3, 'Hexasílabo final.');

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, define_norma, permite_aplicar_global,
		orden, activo, estado_revision
	)
	values (
		v_arq,
		'medida_tercer_verso',
		'¿Cuántas sílabas tiene el tercer verso?',
		'La medida general es once sílabas; también se documentan realizaciones de diez y doce.',
		'metro', 'unidad', 'opciones', 1, 1, false, true, 1, true, 'revisada'
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, descripcion, metro_id, posicion_unidad, orden, activo
	)
	values
		(v_grupo, 'once_silabas', '11 sílabas', 'Medida general del tercer verso.',
		 v_m11, 3, 1, true),
		(v_grupo, 'diez_silabas', '10 sílabas', 'Alternativa decasílaba documentada.',
		 v_m10, 3, 2, true),
		(v_grupo, 'doce_silabas', '12 sílabas', 'Alternativa dodecasílaba recogida por el Diccionario.',
		 v_m12, 3, 3, true);

	select count(*) into v_n
	from public.esquema_metrico_posiciones
	where esquema_metrico_id = v_esquema;
	if v_n <> 12 then
		raise exception 'El esquema gitano debe declarar tres secuencias completas, no % posiciones', v_n;
	end if;

	select count(*) into v_n
	from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo and activo;
	if v_n <> 3 then
		raise exception 'La pregunta gitana debe ofrecer tres medidas, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
