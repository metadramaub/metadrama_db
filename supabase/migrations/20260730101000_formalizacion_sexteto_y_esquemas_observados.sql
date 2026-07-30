begin;

-- Algunas formas abiertas admiten un esquema de rima que no constituye una
-- opción catalogable previa. El grupo sigue declarando la pregunta y su
-- alcance, pero la elección guarda un valor textual validado y normalizado.
alter table public.grupos_eleccion_metrica
	add column tipo_control text not null default 'opciones'
		check (tipo_control in ('opciones', 'esquema_rima'));

comment on column public.grupos_eleccion_metrica.tipo_control is
	'Control editorial: selección entre opciones normalizadas o introducción de un esquema de rima observado.';

alter table public.elecciones_editor_metrico
	alter column opcion_eleccion_id drop not null,
	add column valor_texto text null,
	add constraint elecciones_editor_metrico_valor_check
		check (
			num_nonnulls(opcion_eleccion_id, valor_texto) = 1
			and (valor_texto is null or btrim(valor_texto) <> '')
		);

comment on column public.elecciones_editor_metrico.valor_texto is
	'Valor observado validado para controles abiertos, actualmente esquemas de rima.';

drop index if exists public.elecciones_editor_metrico_secuencia_idx;
drop index if exists public.elecciones_editor_metrico_unidad_idx;

create unique index elecciones_editor_metrico_secuencia_opcion_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		grupo_eleccion_id,
		opcion_eleccion_id
	)
	where unidad_prueba_id is null and opcion_eleccion_id is not null;

create unique index elecciones_editor_metrico_unidad_opcion_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		unidad_prueba_id,
		grupo_eleccion_id,
		opcion_eleccion_id
	)
	where unidad_prueba_id is not null and opcion_eleccion_id is not null;

create unique index elecciones_editor_metrico_secuencia_texto_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		grupo_eleccion_id
	)
	where unidad_prueba_id is null and valor_texto is not null;

create unique index elecciones_editor_metrico_unidad_texto_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		unidad_prueba_id,
		grupo_eleccion_id
	)
	where unidad_prueba_id is not null and valor_texto is not null;

create or replace function public.validar_grupo_eleccion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_seccion uuid;
begin
	if new.seccion_id is not null then
		select configuracion_id
		into v_configuracion_seccion
		from public.estructuras_secciones
		where seccion_id = new.seccion_id;

		if v_configuracion_seccion is distinct from new.configuracion_id then
			raise exception 'La sección de alcance no pertenece a la configuración del grupo';
		end if;
	end if;

	if new.tipo_control = 'esquema_rima' then
		if new.dimension <> 'rima' then
			raise exception 'Un control de esquema debe pertenecer a la dimensión de rima';
		end if;
		if new.selecciones_min <> 1 or new.selecciones_max <> 1 then
			raise exception 'Un control de esquema necesita exactamente una respuesta';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_maximo integer;
	v_tipo_control text;
	v_longitud_esperada integer;
	v_total integer;
begin
	select configuracion_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select alcance, seccion_id, selecciones_max, tipo_control
	into v_alcance, v_seccion_grupo, v_maximo, v_tipo_control
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and configuracion_id = v_configuracion_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la configuración seleccionada';
	end if;

	if v_tipo_control = 'opciones' then
		if new.opcion_eleccion_id is null or new.valor_texto is not null then
			raise exception 'Esta pregunta necesita una opción normalizada';
		end if;
		if not exists (
			select 1 from public.opciones_eleccion_metrica
			where opcion_eleccion_id = new.opcion_eleccion_id
				and grupo_eleccion_id = new.grupo_eleccion_id
				and activo
		) then
			raise exception 'La opción no pertenece al grupo de elección';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		if new.opcion_eleccion_id is not null or new.valor_texto is null then
			raise exception 'Esta pregunta necesita un esquema de rima observado';
		end if;
		new.valor_texto := upper(regexp_replace(btrim(new.valor_texto), '\s+', '', 'g'));
		if new.valor_texto !~ '^[A-Z-]+$' then
			raise exception 'El esquema de rima solo admite letras y guiones';
		end if;
	else
		raise exception 'Tipo de control editorial no reconocido';
	end if;

	if v_alcance = 'secuencia' and new.unidad_prueba_id is not null then
		raise exception 'Una elección de secuencia no puede vincularse a una unidad';
	elsif v_alcance = 'unidad' and new.unidad_prueba_id is null then
		raise exception 'Una elección de unidad necesita una unidad concreta';
	end if;

	if new.unidad_prueba_id is not null then
		select seccion_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_longitud_esperada
		from public.unidades_editor_metrico
		where unidad_prueba_id = new.unidad_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if v_seccion_unidad is null then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
		if v_seccion_grupo is not null and v_seccion_grupo <> v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		select v_fin - v_ini + 1
		into v_longitud_esperada
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = new.secuencia_prueba_id;
	end if;

	if v_tipo_control = 'esquema_rima'
		and length(new.valor_texto) <> v_longitud_esperada
	then
		raise exception
			'El esquema de rima debe tener % posiciones y tiene %',
			v_longitud_esperada,
			length(new.valor_texto);
	end if;

	select count(*)
	into v_total
	from public.elecciones_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id
		and grupo_eleccion_id = new.grupo_eleccion_id
		and unidad_prueba_id is not distinct from new.unidad_prueba_id
		and eleccion_prueba_id <> new.eleccion_prueba_id;

	if v_total + 1 > v_maximo then
		raise exception 'La elección supera la cardinalidad máxima del grupo';
	end if;

	return new;
end;
$$;

create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
	v_secuencia_id uuid;
	v_item jsonb;
	v_grupo record;
	v_total integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
			using errcode = '42501';
	end if;

	v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;

	if v_secuencia_id is null then
		insert into public.secuencias_editor_metrico (
			escenario_id, orden, v_ini, v_fin, forma_id, configuracion_id,
			observaciones, created_by, updated_by
		)
		values (
			(p_datos ->> 'escenario_id')::uuid,
			(p_datos ->> 'orden')::integer,
			(p_datos ->> 'v_ini')::integer,
			(p_datos ->> 'v_fin')::integer,
			(p_datos ->> 'forma_id')::uuid,
			(p_datos ->> 'configuracion_id')::uuid,
			nullif(btrim(p_datos ->> 'observaciones'), ''),
			auth.uid(),
			auth.uid()
		)
		returning secuencia_prueba_id into v_secuencia_id;
	else
		update public.secuencias_editor_metrico
		set
			escenario_id = (p_datos ->> 'escenario_id')::uuid,
			orden = (p_datos ->> 'orden')::integer,
			v_ini = (p_datos ->> 'v_ini')::integer,
			v_fin = (p_datos ->> 'v_fin')::integer,
			forma_id = (p_datos ->> 'forma_id')::uuid,
			configuracion_id = (p_datos ->> 'configuracion_id')::uuid,
			observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
			updated_by = auth.uid()
		where secuencia_prueba_id = v_secuencia_id
			and exists (
				select 1 from public.escenarios_editor_metrico
				where escenario_id = (p_datos ->> 'escenario_id')::uuid
			);

		if not found then
			raise exception 'Secuencia métrica de prueba no encontrada';
		end if;
	end if;

	delete from public.desviaciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.elecciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.unidades_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
	loop
		insert into public.unidades_editor_metrico (
			unidad_prueba_id, secuencia_prueba_id, unidad_padre_id, seccion_id,
			orden, v_ini, v_fin, etiqueta, observaciones
		)
		values (
			(v_item ->> 'unidad_prueba_id')::uuid,
			v_secuencia_id,
			nullif(v_item ->> 'unidad_padre_id', '')::uuid,
			(v_item ->> 'seccion_id')::uuid,
			(v_item ->> 'orden')::integer,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			nullif(btrim(v_item ->> 'etiqueta'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
	loop
		insert into public.elecciones_editor_metrico (
			secuencia_prueba_id,
			unidad_prueba_id,
			grupo_eleccion_id,
			opcion_eleccion_id,
			valor_texto,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'unidad_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			nullif(v_item ->> 'opcion_eleccion_id', '')::uuid,
			nullif(btrim(v_item ->> 'valor_texto'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
	loop
		insert into public.desviaciones_editor_metrico (
			secuencia_prueba_id, unidad_prueba_id, v_ini, v_fin, dimension,
			relacion_norma, metro_observado_id, patron_rima_observado_id,
			seccion_observada_id, patron_repeticion_observado_id,
			valor_rasgo_observado_id, observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'unidad_prueba_id', '')::uuid,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			v_item ->> 'dimension',
			v_item ->> 'relacion_norma',
			nullif(v_item ->> 'metro_observado_id', '')::uuid,
			nullif(v_item ->> 'patron_rima_observado_id', '')::uuid,
			nullif(v_item ->> 'seccion_observada_id', '')::uuid,
			nullif(v_item ->> 'patron_repeticion_observado_id', '')::uuid,
			nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_grupo in
		select *
		from public.grupos_eleccion_metrica
		where configuracion_id = (p_datos ->> 'configuracion_id')::uuid
			and activo
			and alcance = 'secuencia'
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id
			and unidad_prueba_id is null;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	for v_grupo in
		select grupo.*, unidad.unidad_prueba_id
		from public.unidades_editor_metrico unidad
		join public.grupos_eleccion_metrica grupo
			on grupo.configuracion_id = (p_datos ->> 'configuracion_id')::uuid
			and grupo.activo
			and grupo.alcance = 'unidad'
			and (grupo.seccion_id is null or grupo.seccion_id = unidad.seccion_id)
		where unidad.secuencia_prueba_id = v_secuencia_id
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and unidad_prueba_id = v_grupo.unidad_prueba_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	return v_secuencia_id;
end;
$$;

revoke all on function public.guardar_secuencia_editor_metrico_prueba(jsonb) from public;
grant execute on function public.guardar_secuencia_editor_metrico_prueba(jsonb) to authenticated;

do $$
declare
	v_termino_id uuid := '20fcf1bf-2aa8-4a6f-a190-db5f1a88f274'::uuid;
	v_forma_id uuid;
	v_forma_sexta_rima_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_consonante_id uuid;
	v_seccion_id uuid;
	v_grupo_metros_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'sexteto';

	if v_forma_id is null or v_forma_id <> v_termino_id then
		raise exception 'No se encontró la forma sexteto con el UUID legado esperado';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para sexteto y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	if v_consonante_id is null then
		raise exception 'No se encontró el tipo de rima consonante';
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

	update public.formas_metricas
	set
		nombre = 'Sexteto',
		definicion = 'Estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante y disposición variable. En el catálogo se utiliza para realizaciones que no corresponden a una forma más específica, como la sexta rima.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = true,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'arte_mayor_consonante_variable',
		nombre = 'Arte mayor consonante variable',
		descripcion = 'Unidad de seis versos de arte mayor. El editor registra las medidas presentes y el esquema consonante observado.',
		principal = true,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = 6,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_configuracion_id;

	insert into public.patrones_metricos (
		configuracion_id,
		nombre,
		ambito,
		tipo,
		descripcion,
		estado_revision
	)
	values (
		v_configuracion_id,
		'Conjunto de medidas de arte mayor',
		'estrofa',
		'conjunto_permitido',
		'Los seis versos son de arte mayor; pueden compartir medida o combinar varias medidas admitidas.',
		'revisada'
	)
	returning patron_metrico_id into v_patron_metrico_id;

	insert into public.patron_metrico_opciones (
		patron_metrico_id,
		metro_id,
		orden,
		nota
	)
	select
		v_patron_metrico_id,
		termino_id,
		numero_silabas,
		case when numero_silabas = 11
			then 'Medida habitual según el criterio del proyecto.'
			else 'Otra medida de arte mayor admitida.'
		end
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and numero_silabas > 8
	order by numero_silabas, created_at;

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
		v_configuracion_id,
		'Distribución consonante variable',
		null,
		v_consonante_id,
		'estrofa',
		'libre',
		'libre',
		'El sexteto no presupone un esquema fijo; la realización observada se registra en cada unidad.',
		'revisada'
	)
	returning patron_rima_id into v_patron_rima_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		patron_metrico_id,
		patron_rima_id,
		nota
	)
	values (
		v_configuracion_id,
		'sexteto',
		'Sexteto',
		1,
		1,
		null,
		6,
		6,
		v_patron_metrico_id,
		v_patron_rima_id,
		'Unidad repetible de seis versos; las medidas y la distribución de la rima se registran por unidad.'
	)
	returning seccion_id into v_seccion_id;

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		seccion_id,
		selecciones_min,
		selecciones_max,
		permite_aplicar_global,
		tipo_control,
		estado_revision,
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'medidas_presentes',
		'¿Qué medida o medidas aparecen?',
		'Selecciona una sola si todos los versos tienen la misma medida. Puedes aplicar la respuesta a toda la tirada.',
		'metro',
		'unidad',
		v_seccion_id,
		1,
		6,
		true,
		'opciones',
		'revisada',
		1,
		true
	)
	returning grupo_eleccion_id into v_grupo_metros_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		metro_id,
		orden
	)
	select
		v_grupo_metros_id,
		format('%s_silabas', numero_silabas),
		coalesce(nullif(etiqueta, ''), termino),
		case when numero_silabas = 11
			then 'Medida habitual del sexteto en el criterio del proyecto.'
			else 'Medida de arte mayor presente en esta unidad.'
		end,
		termino_id,
		numero_silabas
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and numero_silabas > 8
	order by numero_silabas, created_at;

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		seccion_id,
		selecciones_min,
		selecciones_max,
		permite_aplicar_global,
		tipo_control,
		estado_revision,
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'esquema_rima_observado',
		'¿Qué esquema de rima presenta?',
		'Escribe seis posiciones con letras y guiones, por ejemplo AABCCB. La aplicación elimina espacios y normaliza las letras a mayúsculas.',
		'rima',
		'unidad',
		v_seccion_id,
		1,
		1,
		true,
		'esquema_rima',
		'revisada',
		2,
		true
	);

	select forma_id into v_forma_sexta_rima_id
	from public.formas_metricas
	where slug = 'sexta_rima';

	if v_forma_sexta_rima_id is null then
		raise exception 'No se encontró la forma sexta_rima formalizada';
	end if;

	insert into public.forma_relaciones (
		forma_origen_id,
		forma_destino_id,
		tipo_relacion,
		nota,
		estado_revision
	)
	values (
		v_forma_sexta_rima_id,
		v_forma_id,
		'subtipo_de',
		'La sexta rima fija como ABABCC una realización endecasilábica que satisface la definición general de sexteto; en el registrador se elige siempre la forma más específica.',
		'revisada'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do update
	set
		nota = excluded.nota,
		estado_revision = excluded.estado_revision;

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_id is null then
		raise exception
			'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	update public.afirmaciones_fuentes_metricas
	set
		localizador = 'p. 198',
		resumen = 'Define el sexteto como estrofa de seis versos de arte mayor o combinación de arte mayor y menor. El catálogo conserva la delimitación más estricta del proyecto: arte mayor y rima consonante.',
		confianza = 'alta',
		estado_revision = 'revisada',
		updated_at = now()
	where fuente_id = v_fuente_id
		and forma_id = v_forma_id;

	if not found then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			forma_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_id,
			v_forma_id,
			'p. 198',
			'Define el sexteto como estrofa de seis versos de arte mayor o combinación de arte mayor y menor. El catálogo conserva la delimitación más estricta del proyecto: arte mayor y rima consonante.',
			'alta',
			'revisada'
		);
	end if;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'E',
		propuesta = 'Conservar como forma residual seleccionable de seis versos de arte mayor, rima consonante y disposición variable.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_termino_id;

	delete from public.migracion_termino_destinos
	where termino_id = v_termino_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values (
		v_termino_id,
		'conservar',
		v_forma_id,
		'La entrada se conserva como salida residual positiva; medidas y esquema se registran por cada unidad observada.'
	);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 36,
	actualizado_en = now()
where id = true;

commit;
