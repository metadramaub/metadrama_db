begin;

-- Una elección posicional puede señalar un metro concreto o la presencia de
-- un rasgo normalizado en esa posición. Esto permite registrar las posiciones
-- de pie quebrado sin crear un rasgo distinto para cada verso.
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

	if v_alcance <> 'unidad' or v_seccion_id is null then
		raise exception
			'Una elección posicional debe pertenecer a una clase de unidad concreta';
	end if;

	if (v_dimension = 'metro' and new.metro_id is null)
		or (v_dimension = 'rasgo' and new.rasgo_id is null)
		or v_dimension not in ('metro', 'rasgo')
	then
		raise exception
			'Una elección posicional debe asignar un metro o un rasgo según la dimensión del grupo';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_validar_posicion_opcion_eleccion_metrica
	on public.opciones_eleccion_metrica;

create trigger trigger_validar_posicion_opcion_eleccion_metrica
before insert or update of grupo_eleccion_id, posicion_unidad, metro_id, rasgo_id
on public.opciones_eleccion_metrica
for each row
execute function public.validar_posicion_opcion_eleccion_metrica();

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_tipo_consonante_id uuid;
	v_metro_8_id uuid;
	v_rasgo_pie_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_seccion_id uuid;
	v_grupo_medidas_id uuid;
	v_grupo_posiciones_id uuid;
	v_total_medidas integer;
	v_metro record;
	v_posicion integer;
begin
	insert into public.formas_metricas (
		forma_id, slug, nombre, definicion, nivel_estructural,
		seleccionable, residual, estado_revision, activo, orden, origen_termino_id
	)
	values (
		'352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid,
		'copla_de_pie_quebrado',
		'Copla de pie quebrado',
		'Estrofa de cinco a doce versos que combina octosílabos con versos más breves, habitualmente tetrasílabos o pentasílabos. Se usa como salida residual cuando la realización no corresponde a una forma tipificada más precisa del catálogo.',
		'estrofa',
		true,
		true,
		'revisada',
		true,
		340,
		'352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid
	)
	on conflict (slug) do update set
		nombre = excluded.nombre,
		definicion = excluded.definicion,
		nivel_estructural = excluded.nivel_estructural,
		seleccionable = excluded.seleccionable,
		residual = excluded.residual,
		estado_revision = excluded.estado_revision,
		activo = excluded.activo,
		orden = excluded.orden,
		origen_termino_id = excluded.origen_termino_id,
		updated_at = now()
	returning forma_id into v_forma_id;

	select termino_id into v_tipo_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and (
			lower(coalesce(etiqueta, termino)) like '%consonant%'
			or lower(termino) like '%consonant%'
		)
	order by created_at
	limit 1;

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro' and numero_silabas = 8
	order by created_at
	limit 1;

	select rasgo_id into v_rasgo_pie_id
	from public.rasgos_metricos
	where slug = 'pie_quebrado';

	if num_nonnulls(v_tipo_consonante_id, v_metro_8_id, v_rasgo_pie_id) <> 3 then
		raise exception
			'Faltan el tipo de rima consonante, el metro de 8 sílabas o el rasgo pie_quebrado';
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id and slug = 'variable_5_12';

	if v_configuracion_id is null then
		insert into public.configuraciones_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, grado,
			tipo_rima_id, numero_versos, estado_revision, activo, orden
		)
		values (
			v_forma_id,
			'variable_5_12',
			'Realización no tipificada de 5 a 12 versos',
			'Una o más coplas de extensión variable, con octosílabos dominantes y pies quebrados cuya medida y posición se registran en cada unidad.',
			true,
			true,
			'admitida',
			v_tipo_consonante_id,
			null,
			'revisada',
			true,
			1
		)
		returning configuracion_id into v_configuracion_id;
	else
		update public.configuraciones_forma
		set nombre = 'Realización no tipificada de 5 a 12 versos',
			descripcion = 'Una o más coplas de extensión variable, con octosílabos dominantes y pies quebrados cuya medida y posición se registran en cada unidad.',
			principal = true,
			demarcable = true,
			grado = 'admitida',
			tipo_rima_id = v_tipo_consonante_id,
			numero_versos = null,
			estado_revision = 'revisada',
			activo = true,
			orden = 1,
			updated_at = now()
		where configuracion_id = v_configuracion_id;
	end if;

	delete from public.secuencias_editor_metrico
	where configuracion_id = v_configuracion_id;
	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id;
	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;
	delete from public.patrones_rima
	where configuracion_id = v_configuracion_id;
	delete from public.patrones_metricos
	where configuracion_id = v_configuracion_id;
	delete from public.configuracion_rasgos
	where configuracion_id = v_configuracion_id;

	insert into public.patrones_metricos (
		configuracion_id, nombre, ambito, tipo, descripcion, estado_revision
	)
	values (
		v_configuracion_id,
		'Octosílabos con pies quebrados',
		'estrofa',
		'conjunto_permitido',
		'El octosílabo es la medida dominante; los versos de menos de ocho sílabas pueden actuar como pies quebrados.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id, metro_id, orden, nota
	)
	select
		v_patron_metrico_id,
		termino_id,
		numero_silabas,
		case
			when numero_silabas = 8 then 'Medida dominante.'
			when numero_silabas in (4, 5) then 'Medida habitual del pie quebrado.'
			else 'Otra medida breve admitida en la salida residual.'
		end
	from public.vocabularios
	where categoria = 'metro'
		and numero_silabas between 2 and 8
	order by numero_silabas, created_at;

	insert into public.patrones_rima (
		configuracion_id, nombre, esquema, tipo_rima_id, ambito,
		comportamiento, fijeza, descripcion, estado_revision
	)
	values (
		v_configuracion_id,
		'Distribución variable',
		null,
		v_tipo_consonante_id,
		'estrofa',
		'libre',
		'libre',
		'La salida residual no presupone un esquema fijo de rima consonante.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id, tipo_seccion, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max,
		patron_metrico_id, patron_rima_id, nota
	)
	values (
		v_configuracion_id,
		'copla_pie_quebrado',
		'Copla',
		1,
		1,
		null,
		5,
		12,
		v_patron_metrico_id,
		v_patron_rima_id,
		'Cada unidad se registra por separado; el editor fija su extensión observada.'
	)
	returning seccion_id into v_seccion_id;

	insert into public.configuracion_rasgos (
		configuracion_id, rasgo_id, modalidad, nota
	)
	values (
		v_configuracion_id,
		v_rasgo_pie_id,
		'definitoria',
		'La realización combina una medida octosilábica dominante con versos más breves.'
	);

	select count(*) into v_total_medidas
	from public.vocabularios
	where categoria = 'metro' and numero_silabas between 2 and 7;

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		seccion_id, selecciones_min, selecciones_max, permite_aplicar_global,
		estado_revision, activo, orden
	)
	values (
		v_configuracion_id,
		'medidas_pies_quebrados',
		'¿Qué medida tienen los pies quebrados?',
		'Puedes elegir más de una si en esta copla aparecen quebrados de medidas distintas.',
		'metro',
		'unidad',
		v_seccion_id,
		1,
		greatest(1, v_total_medidas),
		true,
		'revisada',
		true,
		1
	)
	returning grupo_eleccion_id into v_grupo_medidas_id;

	for v_metro in
		select termino_id, numero_silabas
		from public.vocabularios
		where categoria = 'metro' and numero_silabas between 2 and 7
		order by
			case when numero_silabas = 4 then 1
				when numero_silabas = 5 then 2
				else 3 end,
			numero_silabas,
			created_at
	loop
		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, descripcion, metro_id, orden
		)
		values (
			v_grupo_medidas_id,
			format('%s_silabas_%s', v_metro.numero_silabas, v_metro.termino_id),
			format('%s sílabas%s', v_metro.numero_silabas,
				case when v_metro.numero_silabas in (4, 5) then ' · habitual' else '' end),
			case
				when v_metro.numero_silabas in (4, 5)
					then 'Medida habitual del pie quebrado.'
				else 'Otra medida breve observada en esta realización.'
			end,
			v_metro.termino_id,
			case when v_metro.numero_silabas = 4 then 1
				when v_metro.numero_silabas = 5 then 2
				else v_metro.numero_silabas + 10 end
		);
	end loop;

	insert into public.grupos_eleccion_metrica (
		configuracion_id, slug, nombre, ayuda_editor, dimension, alcance,
		seccion_id, selecciones_min, selecciones_max, permite_aplicar_global,
		estado_revision, activo, orden
	)
	values (
		v_configuracion_id,
		'posiciones_pies_quebrados',
		'¿Qué versos son los pies quebrados?',
		'Marca sus posiciones dentro de esta copla. Debe quedar al menos un octosílabo.',
		'rasgo',
		'unidad',
		v_seccion_id,
		1,
		11,
		false,
		'revisada',
		true,
		2
	)
	returning grupo_eleccion_id into v_grupo_posiciones_id;

	for v_posicion in 1..12 loop
		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, descripcion,
			rasgo_id, posicion_unidad, orden
		)
		values (
			v_grupo_posiciones_id,
			format('posicion_%s', v_posicion),
			format('Verso %s', v_posicion),
			'Esta posición contiene un pie quebrado.',
			v_rasgo_pie_id,
			v_posicion,
			v_posicion
		);
	end loop;

	delete from public.migracion_termino_destinos
	where termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid;

	insert into public.migracion_termino_destinos (
		termino_id, tipo_operacion, forma_id, nota
	)
	values (
		'352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid,
		'conservar',
		v_forma_id,
		'Se conserva como salida editorial residual. El rasgo pie_quebrado continúa normalizado y reutilizable por las formas tipificadas.'
	);

	update public.migracion_terminos_metricos
	set clasificacion_decidida = 'E',
		propuesta = 'Conservar como forma residual seleccionable para coplas de 5 a 12 versos con pie quebrado que no correspondan a una forma tipificada más precisa.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a'::uuid;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 23,
	actualizado_en = now()
where id = true;

commit;
