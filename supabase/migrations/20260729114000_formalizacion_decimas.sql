begin;

-- La sucesión histórica no equivale a derivación directa: permite expresar
-- reemplazos de uso documentados sin atribuir una invención individual ni una
-- genealogía exclusiva.
alter table public.forma_relaciones
	drop constraint if exists forma_relaciones_tipo_relacion_check;

alter table public.forma_relaciones
	add constraint forma_relaciones_tipo_relacion_check
		check (tipo_relacion in (
			'subtipo_de',
			'variante_historica_de',
			'derivada_de',
			'compuesta_por',
			'sucede_historicamente_a',
			'relacionada_con',
			'contrasta_con',
			'equivalente_de'
		));

do $$
declare
	v_termino_decima_id uuid := 'd8382ff9-249f-4d47-a69e-4c3f7410cb39'::uuid;
	v_forma_espinela_id uuid;
	v_forma_aumentada_id uuid;
	v_forma_copla_real_id uuid;
	v_config_espinela_id uuid;
	v_config_aumentada_id uuid;
	v_familia_id uuid;
	v_metro_8_id uuid;
	v_consonante_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_raiz_id uuid;
	v_fuente_trapero_id uuid;
	v_fuente_morley_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_espinela_id
	from public.formas_metricas
	where slug = 'decima_espinela';

	select forma_id into v_forma_aumentada_id
	from public.formas_metricas
	where slug = 'decima_aumentada';

	select forma_id into v_forma_copla_real_id
	from public.formas_metricas
	where slug = 'copla_real';

	if num_nonnulls(
		v_forma_espinela_id,
		v_forma_aumentada_id,
		v_forma_copla_real_id
	) <> 3 then
		raise exception
			'Faltan la décima espinela, la décima aumentada o la copla real en el catálogo';
	end if;

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 8
		and activo
	limit 1;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and termino = 'consonante'
		and activo
	limit 1;

	if v_metro_8_id is null
		or v_consonante_id is null
	then
		raise exception
			'Falta el octosílabo o la rima consonante';
	end if;

	insert into public.familias_metricas (
		familia_id,
		slug,
		nombre,
		descripcion,
		estado_revision,
		activo,
		origen_termino_id
	)
	values (
		v_termino_decima_id,
		'decimas',
		'Décimas',
		'Familia de estrofas de arte menor emparentadas por la tradición de la décima. Reúne formas con identidad y arquitectura propias; la familia no es seleccionable como forma.',
		'revisada',
		true,
		v_termino_decima_id
	)
	on conflict (familia_id) do update
	set
		slug = excluded.slug,
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		origen_termino_id = excluded.origen_termino_id,
		updated_at = now()
	returning familia_id into v_familia_id;

	delete from public.familias_formas
	where familia_id = v_familia_id;

	insert into public.familias_formas (
		familia_id,
		forma_id,
		es_principal,
		orden,
		nota
	)
	values
		(
			v_familia_id,
			v_forma_espinela_id,
			true,
			1,
			'Forma canónica dominante en el uso moderno de la denominación décima.'
		),
		(
			v_familia_id,
			v_forma_copla_real_id,
			false,
			2,
			'Modalidad histórica de diez versos articulada como dos quintillas.'
		),
		(
			v_familia_id,
			v_forma_aumentada_id,
			false,
			3,
			'Extensión documentada de doce versos vinculada estructuralmente con la espinela.'
		);

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_espinela_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración importada para décima espinela y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_espinela_id
	from public.configuraciones_forma
	where forma_id = v_forma_espinela_id;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_aumentada_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración importada para décima aumentada y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_config_aumentada_id
	from public.configuraciones_forma
	where forma_id = v_forma_aumentada_id;

	-- Solo elimina escenarios del editor V2. Las secuencias reales continúan
	-- vinculadas al vocabulario antiguo y no se tocan en esta fase.
	delete from public.secuencias_editor_metrico
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	delete from public.grupos_eleccion_metrica
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	delete from public.estructuras_secciones
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	delete from public.patrones_repeticion
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	delete from public.patrones_rima
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	delete from public.patrones_metricos
	where configuracion_id in (v_config_espinela_id, v_config_aumentada_id);

	update public.formas_metricas
	set
		nombre = 'Décima espinela',
		definicion = 'Estrofa de diez versos octosílabos con rima consonante abbaaccddc, articulada en 4 + 2 + 4 y con pausa característica tras el cuarto verso. Los dos versos centrales enlazan la primera redondilla con la segunda.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_espinela_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabica_abbaaccddc',
		nombre = 'Octosilábica abbaaccddc',
		descripcion = 'Diez octosílabos consonantes con pausa tras el cuarto verso y estructura 4 + 2 + 4.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 10,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_espinela_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_espinela_id,
		'Diez octosílabos',
		'estrofa',
		'secuencia_fija',
		'Un octosílabo en cada una de las diez posiciones.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id
	)
	select v_patron_metrico_id, posicion, v_metro_8_id
	from generate_series(1, 10) posicion;

	insert into public.patrones_rima (
		configuracion_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_espinela_id,
		'Esquema fijo abbaaccddc',
		'abbaaccddc',
		v_consonante_id,
		'estrofa',
		'secuencia_fija',
		'fijo',
		'La pausa estructural se produce tras abba; los versos centrales ac enlazan los dos bloques.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	update public.patron_rima_posiciones
	set
		bloque = case
			when posicion <= 4 then 1
			when posicion <= 6 then 2
			else 3
		end,
		posicion = case
			when posicion <= 4 then posicion
			when posicion <= 6 then posicion - 4
			else posicion - 6
		end,
		seccion = case
			when posicion <= 4 then 'primera_redondilla'
			when posicion <= 6 then 'enlace'
			else 'segunda_redondilla'
		end
	where patron_rima_id = v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		nota
	)
	values (
		v_config_espinela_id,
		'decima_espinela',
		'Décima espinela',
		1,
		1,
		null,
		'Unidad repetible de diez versos.'
	)
	returning seccion_id into v_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		seccion_padre_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values
		(
			v_config_espinela_id,
			v_raiz_id,
			'primera_redondilla',
			'Primera redondilla',
			1,
			1,
			1,
			4,
			4,
			'Primer bloque abba, seguido de la pausa característica.'
		),
		(
			v_config_espinela_id,
			v_raiz_id,
			'enlace',
			'Enlace',
			2,
			1,
			1,
			2,
			2,
			'Versos centrales ac que enlazan ambos bloques.'
		),
		(
			v_config_espinela_id,
			v_raiz_id,
			'segunda_redondilla',
			'Segunda redondilla',
			3,
			1,
			1,
			4,
			4,
			'Bloque final cddc.'
		);

	update public.formas_metricas
	set
		nombre = 'Décima aumentada',
		definicion = 'Estrofa de doce versos octosílabos con rima consonante abbaaccddeed y pausa característica tras el cuarto verso. Amplía en dos versos el cierre de la décima espinela.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_aumentada_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabica_abbaaccddeed',
		nombre = 'Octosilábica abbaaccddeed',
		descripcion = 'Doce octosílabos consonantes con pausa tras el cuarto verso y estructura 4 + 2 + 6.',
		principal = true,
		demarcable = true,
		grado = 'fija',
		tipo_rima_id = v_consonante_id,
		numero_versos = 12,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_aumentada_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_config_aumentada_id,
		'Doce octosílabos',
		'estrofa',
		'secuencia_fija',
		'Un octosílabo en cada una de las doce posiciones.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id
	)
	select v_patron_metrico_id, posicion, v_metro_8_id
	from generate_series(1, 12) posicion;

	insert into public.patrones_rima (
		configuracion_id,
		nombre,
		esquema,
		tipo_rima_id,
		ambito,
		comportamiento,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_config_aumentada_id,
		'Esquema fijo abbaaccddeed',
		'abbaaccddeed',
		v_consonante_id,
		'estrofa',
		'secuencia_fija',
		'fijo',
		'Conserva el arranque abbaacc de la espinela y amplía el cierre a ddeed.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	update public.patron_rima_posiciones
	set
		bloque = case
			when posicion <= 4 then 1
			when posicion <= 6 then 2
			else 3
		end,
		posicion = case
			when posicion <= 4 then posicion
			when posicion <= 6 then posicion - 4
			else posicion - 6
		end,
		seccion = case
			when posicion <= 4 then 'primera_redondilla'
			when posicion <= 6 then 'enlace'
			else 'cierre_aumentado'
		end
	where patron_rima_id = v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		nota
	)
	values (
		v_config_aumentada_id,
		'decima_aumentada',
		'Décima aumentada',
		1,
		1,
		null,
		'Unidad repetible de doce versos.'
	)
	returning seccion_id into v_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		seccion_padre_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values
		(
			v_config_aumentada_id,
			v_raiz_id,
			'primera_redondilla',
			'Primera redondilla',
			1,
			1,
			1,
			4,
			4,
			'Primer bloque abba, seguido de la pausa característica.'
		),
		(
			v_config_aumentada_id,
			v_raiz_id,
			'enlace',
			'Enlace',
			2,
			1,
			1,
			2,
			2,
			'Versos centrales ac.'
		),
		(
			v_config_aumentada_id,
			v_raiz_id,
			'cierre_aumentado',
			'Cierre aumentado',
			3,
			1,
			1,
			6,
			6,
			'Bloque final cddeed.'
		);

	delete from public.forma_relaciones
	where (
		forma_origen_id = v_forma_copla_real_id
		and forma_destino_id = v_forma_espinela_id
		and tipo_relacion = 'contrasta_con'
	) or (
		forma_origen_id = v_forma_espinela_id
		and forma_destino_id = v_forma_copla_real_id
		and tipo_relacion = 'contrasta_con'
	);

	insert into public.forma_relaciones (
		forma_origen_id,
		forma_destino_id,
		tipo_relacion,
		nota,
		estado_revision
	)
	values
		(
			v_forma_espinela_id,
			v_forma_copla_real_id,
			'sucede_historicamente_a',
			'La espinela reemplaza progresivamente a la copla real como modalidad dominante de décima entre finales del siglo XVI y las primeras décadas del XVII. No se afirma una invención individual ni una derivación exclusiva.',
			'revisada'
		),
		(
			v_forma_aumentada_id,
			v_forma_espinela_id,
			'derivada_de',
			'Conserva el arranque abbaacc y amplía el cierre de la espinela de cuatro a seis versos.',
			'revisada'
		)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set
		nota = excluded.nota,
		estado_revision = excluded.estado_revision;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'G',
		propuesta = 'Transformar la antigua raíz duplicada en la familia estructural no seleccionable Décimas.',
		certeza = 'alta',
		requiere_revision = false
	where termino_id = v_termino_decima_id;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = 'F',
		propuesta = case termino.termino
			when 'decima_espinela'
				then 'Conservar como forma fija de diez octosílabos con esquema abbaaccddc y estructura 4 + 2 + 4.'
			else
				'Conservar como forma fija documentada de doce octosílabos con esquema abbaaccddeed.'
		end,
		certeza = 'alta',
		requiere_revision = false
	from public.vocabularios termino
	where migracion.termino_id = termino.termino_id
		and termino.termino in ('decima_espinela', 'decima_aumentada');

	delete from public.migracion_termino_destinos
	where termino_id = v_termino_decima_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		familia_id,
		nota
	)
	values (
		v_termino_decima_id,
		'transformar',
		v_familia_id,
		'La raíz antigua describía ya una espinela; se conserva como traza de la familia y no como forma duplicada.'
	);

	select fuente_id into v_fuente_trapero_id
	from public.fuentes_metricas
	where autoria = 'Maximiano Trapero'
		and titulo = 'Origen y triunfo de la décima'
	limit 1;

	if v_fuente_trapero_id is null then
		insert into public.fuentes_metricas (
			tipo,
			autoria,
			titulo,
			anio,
			publicacion,
			url,
			cita,
			nota
		)
		values (
			'monografía',
			'Maximiano Trapero',
			'Origen y triunfo de la décima',
			2015,
			'Universitat de València',
			null,
			'Trapero, Maximiano. Origen y triunfo de la décima: revisión de un tópico de cuatro siglos y noticias de nuevas, primeras e inéditas décimas. València: Universitat de València, 2015.',
			'Estudio monográfico sobre la historia de las modalidades de la décima y la consolidación de la espinela.'
		)
		returning fuente_id into v_fuente_trapero_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_trapero_id
			and familia_id = v_familia_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			familia_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_trapero_id,
			v_familia_id,
			'Estudio completo; especialmente la revisión histórica de la copla real y la espinela',
			'Distingue modalidades históricas de décima y documenta la sustitución progresiva de la copla real por la espinela, cuyos primeros testimonios preceden a la publicación de Espinel.',
			'alta',
			'revisada'
		);
	end if;

	select fuente_id into v_fuente_morley_id
	from public.fuentes_metricas
	where autoria = 'S. Griswold Morley y Courtney Bruerton'
		and titulo = 'Cronología de las comedias de Lope de Vega'
	limit 1;

	if v_fuente_morley_id is null then
		insert into public.fuentes_metricas (
			tipo,
			autoria,
			titulo,
			anio,
			publicacion,
			cita,
			nota
		)
		values (
			'monografía',
			'S. Griswold Morley y Courtney Bruerton',
			'Cronología de las comedias de Lope de Vega',
			1968,
			'Madrid, Gredos',
			'Morley, S. Griswold, y Courtney Bruerton. Cronología de las comedias de Lope de Vega. Madrid: Gredos, 1968.',
			'Fuente especializada en la métrica dramática de Lope de Vega.'
		)
		returning fuente_id into v_fuente_morley_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_morley_id
			and forma_id = v_forma_aumentada_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			forma_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_morley_id,
			v_forma_aumentada_id,
			'p. 38',
			'Documenta la décima aumentada ABBA:ACCDDEED de doce versos como suficientemente frecuente para no considerarla defectuosa y señala su aparición entre pasajes de décimas normales.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 25,
	actualizado_en = now()
where id = true;

commit;
