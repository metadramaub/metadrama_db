begin;

-- Una opción métrica puede afectar a una posición concreta de la unidad.
-- La posición complementa el metro normalizado; no crea diez rasgos ni diez
-- preguntas independientes.
alter table public.opciones_eleccion_metrica
	add column posicion_unidad integer null
		check (posicion_unidad is null or posicion_unidad > 0);

comment on column public.opciones_eleccion_metrica.posicion_unidad is
	'Posición relativa dentro de la unidad a la que se aplica el valor normalizado de la opción.';

create unique index opciones_eleccion_posicion_unidad_idx
	on public.opciones_eleccion_metrica (grupo_eleccion_id, posicion_unidad)
	where posicion_unidad is not null;

create or replace function public.validar_posicion_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_dimension text;
	v_alcance text;
	v_seccion_id uuid;
begin
	if new.posicion_unidad is null then
		return new;
	end if;

	select dimension, alcance, seccion_id
	into v_dimension, v_alcance, v_seccion_id
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id;

	if v_dimension <> 'metro'
		or v_alcance <> 'unidad'
		or v_seccion_id is null
		or new.metro_id is null
	then
		raise exception
			'Una elección posicional debe asignar un metro a una clase de unidad concreta';
	end if;

	return new;
end;
$$;

create trigger trigger_validar_posicion_opcion_eleccion_metrica
before insert or update of grupo_eleccion_id, posicion_unidad, metro_id
on public.opciones_eleccion_metrica
for each row
execute function public.validar_posicion_opcion_eleccion_metrica();

do $$
declare
	v_forma_id uuid;
	v_config_provisional_id uuid;
	v_config_sin_id uuid;
	v_config_con_id uuid;
	v_tipo_rima_id uuid;
	v_metro_4_id uuid;
	v_metro_8_id uuid;
	v_patron_metrico_sin_id uuid;
	v_patron_metrico_con_id uuid;
	v_raiz_sin_id uuid;
	v_raiz_con_id uuid;
	v_primera_sin_id uuid;
	v_segunda_sin_id uuid;
	v_primera_con_id uuid;
	v_segunda_con_id uuid;
	v_rasgo_pie_id uuid;
	v_grupo_id uuid;
	v_patron_rima_id uuid;
	v_configuracion_id uuid;
	v_esquema record;
	v_fuente_trapero_id uuid;
	v_fuente_utrera_id uuid;
	v_forma_decima_id uuid;
	v_forma_quintilla_id uuid;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'copla_real';

	if v_forma_id is null then
		raise exception 'No se encontró la forma copla_real';
	end if;

	select configuracion_id into v_config_sin_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id = '08317ef5-a679-4ede-854a-87887ff221e3'::uuid;

	select configuracion_id into v_config_con_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id = 'b30e8a01-94d9-40ec-a3ef-222ca3f9f484'::uuid;

	select configuracion_id into v_config_provisional_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id is null
	order by principal desc, created_at
	limit 1;

	select coalesce(
		(select tipo_rima_id from public.configuraciones_forma where configuracion_id = v_config_sin_id),
		(select tipo_rima_id from public.configuraciones_forma where configuracion_id = v_config_con_id),
		(select tipo_rima_id from public.configuraciones_forma where configuracion_id = v_config_provisional_id)
	) into v_tipo_rima_id;

	select termino_id into v_metro_4_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 4
	limit 1;

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas = 8
	limit 1;

	if num_nonnulls(
		v_config_sin_id,
		v_config_con_id,
		v_tipo_rima_id,
		v_metro_4_id,
		v_metro_8_id
	) <> 5 then
		raise exception 'La importación de la copla real está incompleta';
	end if;

	delete from public.secuencias_editor_metrico
	where configuracion_id in (
		v_config_sin_id,
		v_config_con_id,
		v_config_provisional_id
	);

	delete from public.grupos_eleccion_metrica
	where configuracion_id in (v_config_sin_id, v_config_con_id);

	delete from public.estructuras_secciones
	where configuracion_id in (v_config_sin_id, v_config_con_id);

	delete from public.patrones_repeticion
	where configuracion_id in (v_config_sin_id, v_config_con_id);

	delete from public.patrones_rima
	where configuracion_id in (v_config_sin_id, v_config_con_id);

	delete from public.patrones_metricos
	where configuracion_id in (v_config_sin_id, v_config_con_id);

	update public.configuraciones_forma
	set principal = false
	where forma_id = v_forma_id;

	if v_config_provisional_id is not null then
		delete from public.configuraciones_forma
		where configuracion_id = v_config_provisional_id;
	end if;

	update public.formas_metricas
	set
		nombre = 'Copla real',
		definicion = 'Estrofa de diez versos de arte menor organizada en dos quintillas, con pausa estructural tras el quinto verso y rima consonante de distribución variable. En el catálogo del proyecto se reconocen una configuración octosilábica y otra con uno o dos versos tetrasílabos de pie quebrado.',
		nivel_estructural = 'estrofa',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'sin_pie_quebrado',
		nombre = 'No: diez octosílabos',
		descripcion = 'Diez versos octosílabos distribuidos en dos quintillas de cinco versos.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_rima_id,
		numero_versos = 10,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_sin_id;

	update public.configuraciones_forma
	set
		slug = 'con_pie_quebrado',
		nombre = 'Sí: uno o dos versos tetrasílabos',
		descripcion = 'Diez versos distribuidos en dos quintillas; uno o dos son tetrasílabos de pie quebrado y los restantes son octosílabos.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_tipo_rima_id,
		numero_versos = 10,
		estado_revision = 'revisada',
		activo = true,
		orden = 2,
		updated_at = now()
	where configuracion_id = v_config_con_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_sin_id,
		'Diez octosílabos',
		'estrofa',
		'secuencia_fija',
		'Un octosílabo en cada una de las diez posiciones.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_sin_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id, posicion, metro_id
	)
	select v_patron_metrico_sin_id, posicion, v_metro_8_id
	from generate_series(1, 10) posicion;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_config_con_id,
		'Octosílabos con uno o dos pies quebrados',
		'estrofa',
		'conjunto_permitido',
		'Los versos son octosílabos salvo una o dos posiciones tetrasílabas elegidas en cada copla real.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_con_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id, metro_id, orden, nota
	)
	values
		(v_patron_metrico_con_id, v_metro_8_id, 1, 'Medida de los versos no quebrados.'),
		(v_patron_metrico_con_id, v_metro_4_id, 2, 'Medida de las posiciones de pie quebrado.');

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_sin_id,
		'copla_real',
		'Copla real',
		1,
		1,
		null,
		'Unidad repetible de diez versos formada por dos quintillas.'
	)
	returning seccion_id into v_raiz_sin_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values
		(
			v_config_sin_id, v_raiz_sin_id, 'primera_quintilla', 'Primera quintilla', 1,
			1, 1, 5, 5,
			'Primer miembro de la estructura 5 + 5.'
		),
		(
			v_config_sin_id, v_raiz_sin_id, 'segunda_quintilla', 'Segunda quintilla', 2,
			1, 1, 5, 5,
			'Segundo miembro, después de la pausa estructural.'
		);

	select seccion_id into v_primera_sin_id
	from public.estructuras_secciones
	where configuracion_id = v_config_sin_id
		and seccion_padre_id = v_raiz_sin_id
		and tipo_seccion = 'primera_quintilla';

	select seccion_id into v_segunda_sin_id
	from public.estructuras_secciones
	where configuracion_id = v_config_sin_id
		and seccion_padre_id = v_raiz_sin_id
		and tipo_seccion = 'segunda_quintilla';

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, nota
	)
	values (
		v_config_con_id,
		'copla_real',
		'Copla real',
		1,
		1,
		null,
		'Unidad repetible de diez versos formada por dos quintillas.'
	)
	returning seccion_id into v_raiz_con_id;

	insert into public.estructuras_secciones (
		configuracion_id, seccion_padre_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, nota
	)
	values
		(
			v_config_con_id, v_raiz_con_id, 'primera_quintilla', 'Primera quintilla', 1,
			1, 1, 5, 5,
			'Primer miembro de la estructura 5 + 5.'
		),
		(
			v_config_con_id, v_raiz_con_id, 'segunda_quintilla', 'Segunda quintilla', 2,
			1, 1, 5, 5,
			'Segundo miembro, después de la pausa estructural.'
		);

	select seccion_id into v_primera_con_id
	from public.estructuras_secciones
	where configuracion_id = v_config_con_id
		and seccion_padre_id = v_raiz_con_id
		and tipo_seccion = 'primera_quintilla';

	select seccion_id into v_segunda_con_id
	from public.estructuras_secciones
	where configuracion_id = v_config_con_id
		and seccion_padre_id = v_raiz_con_id
		and tipo_seccion = 'segunda_quintilla';

	for v_configuracion_id in
		select unnest(array[v_config_sin_id, v_config_con_id])
	loop
		for v_esquema in
			select item.valor as esquema, item.orden
			from unnest(array[
				'ababa', 'abbab', 'abaab', 'aabab',
				'aabba', 'abbaa', 'ababb', 'abbba'
			]) with ordinality as item(valor, orden)
		loop
			insert into public.patrones_rima (
				configuracion_id, nombre, esquema, tipo_rima_id, ambito,
				comportamiento, fijeza, descripcion, estado_revision
			)
			values (
				v_configuracion_id,
				'Quintilla ' || v_esquema.esquema,
				v_esquema.esquema,
				v_tipo_rima_id,
				'seccion',
				'secuencia_fija',
				'admitido',
				'Esquema de cinco versos reconocido por el proyecto para uno de los dos miembros de la copla real.',
				'revisada'
			)
			returning patron_rima_id into v_patron_rima_id;

			-- El disparador sincronizar_posiciones_patron_rima_fijo crea las
			-- cinco posiciones a partir del esquema. Aquí solo se precisa su
			-- función dentro de la copla real.
			update public.patron_rima_posiciones
			set seccion = 'quintilla'
			where patron_rima_id = v_patron_rima_id;
		end loop;
	end loop;

	for v_configuracion_id, v_grupo_id in
		select v_config_sin_id, v_raiz_sin_id
		union all
		select v_config_con_id, v_raiz_con_id
	loop
		insert into public.grupos_eleccion_metrica (
			configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
			selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
		)
		values (
			v_configuracion_id,
			'rima_primera_quintilla',
			'¿Qué esquema tiene la primera quintilla?',
			'Elige la distribución observada en los versos 1–5 de cada unidad.',
			'rima',
			'unidad',
			v_grupo_id,
			1,
			1,
			true,
			'revisada',
			1
		)
		returning grupo_eleccion_id into v_grupo_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, patron_rima_id, orden
		)
		select
			v_grupo_id,
			patron.esquema,
			patron.esquema,
			patron.patron_rima_id,
			array_position(
				array['ababa', 'abbab', 'abaab', 'aabab', 'aabba', 'abbaa', 'ababb', 'abbba'],
				patron.esquema
			)
		from public.patrones_rima patron
		where patron.configuracion_id = v_configuracion_id
			and patron.comportamiento = 'secuencia_fija';

		insert into public.grupos_eleccion_metrica (
			configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
			selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
		)
		values (
			v_configuracion_id,
			'rima_segunda_quintilla',
			'¿Qué esquema tiene la segunda quintilla?',
			'Elige la distribución observada en los versos 6–10 de cada unidad.',
			'rima',
			'unidad',
			case
				when v_configuracion_id = v_config_sin_id then v_raiz_sin_id
				else v_raiz_con_id
			end,
			1,
			1,
			true,
			'revisada',
			2
		)
		returning grupo_eleccion_id into v_grupo_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, patron_rima_id, orden
		)
		select
			v_grupo_id,
			patron.esquema,
			patron.esquema,
			patron.patron_rima_id,
			array_position(
				array['ababa', 'abbab', 'abaab', 'aabab', 'aabba', 'abbaa', 'ababb', 'abbba'],
				patron.esquema
			)
		from public.patrones_rima patron
		where patron.configuracion_id = v_configuracion_id
			and patron.comportamiento = 'secuencia_fija';
	end loop;

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, orden
	)
	values (
		v_config_con_id,
		'posiciones_pie_quebrado',
		'¿Qué versos son de pie quebrado?',
		'Marca una o dos posiciones. Los demás versos se interpretan como octosílabos.',
		'metro',
		'unidad',
		v_raiz_con_id,
		1,
		2,
		true,
		'revisada',
		3
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, posicion_unidad, orden
	)
	select
		v_grupo_id,
		'verso_' || posicion,
		'Verso ' || posicion || ': 4 sílabas',
		v_metro_4_id,
		posicion,
		posicion
	from generate_series(1, 10) posicion;

	insert into public.rasgos_metricos (
		slug, nombre, descripcion, tipo_valor, observabilidad,
		demarcable, estado_revision, activo
	)
	values (
		'pie_quebrado',
		'Pie quebrado',
		'Presencia normativa de uno o más versos de medida inferior a la dominante en posiciones declaradas.',
		'booleano',
		'directa',
		true,
		'revisada',
		true
	)
	on conflict (slug) do update
	set
		nombre = excluded.nombre,
		descripcion = excluded.descripcion,
		tipo_valor = excluded.tipo_valor,
		observabilidad = excluded.observabilidad,
		demarcable = excluded.demarcable,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		updated_at = now()
	returning rasgo_id into v_rasgo_pie_id;

	insert into public.configuracion_rasgos (
		configuracion_id, rasgo_id, modalidad, nota
	)
	values (
		v_config_con_id,
		v_rasgo_pie_id,
		'definitoria',
		'Se deriva de la configuración y de las posiciones tetrasílabas elegidas; no se pregunta de nuevo.'
	)
	on conflict (configuracion_id, rasgo_id, modalidad) do update
	set nota = excluded.nota;

	select forma_id into v_forma_decima_id
	from public.formas_metricas
	where slug in ('decima', 'decima_espinela')
	order by slug = 'decima_espinela' desc
	limit 1;

	if v_forma_decima_id is not null then
		insert into public.forma_relaciones (
			forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
		)
		values (
			v_forma_id,
			v_forma_decima_id,
			'contrasta_con',
			'Ambas tienen diez versos; la copla real se articula como 5 + 5, mientras la espinela presenta su pausa característica tras el cuarto verso.',
			'revisada'
		)
		on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
		set
			nota = excluded.nota,
			estado_revision = excluded.estado_revision;
	end if;

	select forma_id into v_forma_quintilla_id
	from public.formas_metricas
	where slug = 'quintilla'
	limit 1;

	if v_forma_quintilla_id is not null then
		insert into public.forma_relaciones (
			forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
		)
		values (
			v_forma_id,
			v_forma_quintilla_id,
			'relacionada_con',
			'La copla real se organiza como dos quintillas sucesivas; la relación expresa composición estructural, no subordinación entre formas.',
			'revisada'
		)
		on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
		set
			nota = excluded.nota,
			estado_revision = excluded.estado_revision;
	end if;

	select fuente_id into v_fuente_trapero_id
	from public.fuentes_metricas
	where autoria = 'Maximiano Trapero'
		and titulo = 'La primera copla real en la poesía castellana'
	limit 1;

	if v_fuente_trapero_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, url, cita, nota
		)
		values (
			'artículo',
			'Maximiano Trapero',
			'La primera copla real en la poesía castellana',
			2017,
			'Analecta Malacitana, 39 (1-2), pp. 27-61',
			'https://accedacris.ulpgc.es/handle/10553/73005',
			'Trapero, Maximiano. «La primera copla real en la poesía castellana». Analecta Malacitana, 39.1-2 (2016-2017), pp. 27-61.',
			'Publicación académica especializada depositada en el repositorio institucional de la Universidad de Las Palmas de Gran Canaria.'
		)
		returning fuente_id into v_fuente_trapero_id;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_trapero_id,
		v_forma_id,
		'pp. 31-34',
		'Caracteriza la copla real por la estructura fija de doble quintilla, el predominio de cuatro rimas y la libertad de combinación dentro de cada quintilla; documenta la pausa 5 + 5 frente a otras décimas.',
		'alta',
		'revisada'
	);

	select fuente_id into v_fuente_utrera_id
	from public.fuentes_metricas
	where autoria = 'María Victoria Utrera Torremocha'
		and titulo = 'Métrica y poética en «Nocturno yanqui», de Luis Cernuda'
	limit 1;

	if v_fuente_utrera_id is null then
		insert into public.fuentes_metricas (
			tipo, autoria, titulo, anio, publicacion, doi, url, cita, nota
		)
		values (
			'artículo',
			'María Victoria Utrera Torremocha',
			'Métrica y poética en «Nocturno yanqui», de Luis Cernuda',
			2006,
			'Rhythmica. Revista Española de Métrica Comparada, 3-4, pp. 283-303',
			'10.5944/rhythmica.13137',
			'https://revistas.uned.es/index.php/rhythmica/article/view/13137',
			'Utrera Torremocha, María Victoria. «Métrica y poética en “Nocturno yanqui”, de Luis Cernuda». Rhythmica, 3-4 (2006), pp. 283-303.',
			'Fuente académica para la variabilidad histórica y el carácter posicional del pie quebrado; no atribuye por sí sola esta configuración a la copla real del proyecto.'
		)
		returning fuente_id into v_fuente_utrera_id;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, rasgo_id, localizador, resumen, confianza, estado_revision
	)
	values (
		v_fuente_utrera_id,
		v_rasgo_pie_id,
		'pp. 285-287',
		'Documenta que las coplas de pie quebrado se distinguen por la colocación de versos cortos en posiciones concretas y que esas posiciones varían históricamente según la forma.',
		'alta',
		'revisada'
	);

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'F',
		propuesta = 'Conservar como forma de diez versos y estructura 5 + 5, con configuraciones normalizadas con y sin pie quebrado.',
		certeza = 'alta',
		requiere_revision = true,
		updated_at = now()
	where termino_id = v_forma_id;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'C',
		propuesta = 'Configuración con uno o dos tetrasílabos cuyas posiciones se registran en cada unidad.',
		certeza = 'alta',
		requiere_revision = true,
		updated_at = now()
	where termino_id = 'b30e8a01-94d9-40ec-a3ef-222ca3f9f484'::uuid;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'C',
		propuesta = 'Configuración isométrica de diez octosílabos.',
		certeza = 'alta',
		requiere_revision = false,
		updated_at = now()
	where termino_id = '08317ef5-a679-4ede-854a-87887ff221e3'::uuid;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 21,
	actualizado_en = now()
where id = true;

commit;
