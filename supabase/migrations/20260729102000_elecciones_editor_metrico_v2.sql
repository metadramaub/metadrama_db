begin;

-- Capa aditiva entre la norma del catálogo y las desviaciones observadas.
-- No modifica obras, secuencias_metricas ni ninguna tabla utilizada por el
-- editor de producción.

create table public.grupos_eleccion_metrica (
	grupo_eleccion_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	slug text not null check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	ayuda_editor text null,
	dimension text not null
		check (dimension in ('metro', 'rima', 'estructura', 'repeticion', 'rasgo')),
	alcance text not null default 'secuencia'
		check (alcance in ('secuencia', 'unidad')),
	seccion_id uuid null references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict,
	selecciones_min integer not null default 1 check (selecciones_min >= 0),
	selecciones_max integer not null default 1 check (selecciones_max > 0),
	permite_aplicar_global boolean not null default false,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (selecciones_min <= selecciones_max),
	check (
		(alcance = 'secuencia' and seccion_id is null)
		or alcance = 'unidad'
	),
	unique (configuracion_id, slug)
);

comment on table public.grupos_eleccion_metrica is
	'Preguntas editoriales derivables del catálogo cuando una configuración admite varias realizaciones relevantes. No representan desviaciones.';

create table public.opciones_eleccion_metrica (
	opcion_eleccion_id uuid primary key default gen_random_uuid(),
	grupo_eleccion_id uuid not null references public.grupos_eleccion_metrica (grupo_eleccion_id)
		on update cascade on delete cascade,
	slug text not null check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	metro_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete restrict,
	patron_metrico_id uuid null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete restrict,
	patron_rima_id uuid null references public.patrones_rima (patron_rima_id)
		on update cascade on delete restrict,
	seccion_id uuid null references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict,
	patron_repeticion_id uuid null references public.patrones_repeticion (patron_repeticion_id)
		on update cascade on delete restrict,
	rasgo_id uuid null references public.rasgos_metricos (rasgo_id)
		on update cascade on delete restrict,
	valor_rasgo_id uuid null references public.rasgo_valores (valor_id)
		on update cascade on delete restrict,
	activo boolean not null default true,
	orden integer null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (
		num_nonnulls(
			metro_id,
			patron_metrico_id,
			patron_rima_id,
			seccion_id,
			patron_repeticion_id,
			rasgo_id,
			valor_rasgo_id
		) = 1
	),
	unique (grupo_eleccion_id, slug)
);

comment on table public.opciones_eleccion_metrica is
	'Valores controlados de una pregunta editorial. Cada opción referencia una entidad normalizada del catálogo.';

create table public.escenarios_editor_metrico (
	escenario_id uuid primary key default gen_random_uuid(),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	created_by uuid not null default auth.uid() references public.editores (user_id)
		on update cascade on delete restrict,
	updated_by uuid not null default auth.uid() references public.editores (user_id)
		on update cascade on delete restrict,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

comment on table public.escenarios_editor_metrico is
	'Contenedores de prueba del editor métrico V2. No son obras y nunca alimentan fichas, buscadores ni resúmenes públicos.';

create table public.secuencias_editor_metrico (
	secuencia_prueba_id uuid primary key default gen_random_uuid(),
	escenario_id uuid not null references public.escenarios_editor_metrico (escenario_id)
		on update cascade on delete cascade,
	orden integer not null default 1 check (orden > 0),
	v_ini integer not null check (v_ini > 0),
	v_fin integer not null check (v_fin >= v_ini),
	forma_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete restrict,
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete restrict,
	observaciones text null,
	created_by uuid not null default auth.uid() references public.editores (user_id)
		on update cascade on delete restrict,
	updated_by uuid not null default auth.uid() references public.editores (user_id)
		on update cascade on delete restrict,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (escenario_id, orden)
);

create table public.unidades_editor_metrico (
	unidad_prueba_id uuid primary key,
	secuencia_prueba_id uuid not null references public.secuencias_editor_metrico (secuencia_prueba_id)
		on update cascade on delete cascade,
	unidad_padre_id uuid null references public.unidades_editor_metrico (unidad_prueba_id)
		on update cascade on delete cascade,
	seccion_id uuid not null references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict,
	orden integer not null check (orden > 0),
	v_ini integer not null check (v_ini > 0),
	v_fin integer not null check (v_fin >= v_ini),
	etiqueta text null,
	observaciones text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (unidad_padre_id is null or unidad_padre_id <> unidad_prueba_id),
	unique (secuencia_prueba_id, orden)
);

comment on table public.unidades_editor_metrico is
	'Realizaciones internas de secciones del catálogo, como una cabeza o cada copla de un villancico.';

create table public.elecciones_editor_metrico (
	eleccion_prueba_id uuid primary key default gen_random_uuid(),
	secuencia_prueba_id uuid not null references public.secuencias_editor_metrico (secuencia_prueba_id)
		on update cascade on delete cascade,
	unidad_prueba_id uuid null references public.unidades_editor_metrico (unidad_prueba_id)
		on update cascade on delete cascade,
	grupo_eleccion_id uuid not null references public.grupos_eleccion_metrica (grupo_eleccion_id)
		on update cascade on delete restrict,
	opcion_eleccion_id uuid not null references public.opciones_eleccion_metrica (opcion_eleccion_id)
		on update cascade on delete restrict,
	observaciones text null,
	created_at timestamptz not null default now()
);

create unique index elecciones_editor_metrico_secuencia_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		grupo_eleccion_id,
		opcion_eleccion_id
	)
	where unidad_prueba_id is null;

create unique index elecciones_editor_metrico_unidad_idx
	on public.elecciones_editor_metrico (
		secuencia_prueba_id,
		unidad_prueba_id,
		grupo_eleccion_id,
		opcion_eleccion_id
	)
	where unidad_prueba_id is not null;

create table public.desviaciones_editor_metrico (
	desviacion_prueba_id uuid primary key default gen_random_uuid(),
	secuencia_prueba_id uuid not null references public.secuencias_editor_metrico (secuencia_prueba_id)
		on update cascade on delete cascade,
	unidad_prueba_id uuid null references public.unidades_editor_metrico (unidad_prueba_id)
		on update cascade on delete cascade,
	v_ini integer not null check (v_ini > 0),
	v_fin integer not null check (v_fin >= v_ini),
	dimension text not null
		check (dimension in ('medida', 'rima', 'estructura', 'repeticion', 'rasgo')),
	relacion_norma text not null
		check (relacion_norma in (
			'diferente',
			'menor_que_norma',
			'mayor_que_norma',
			'falta_elemento_esperado',
			'aparece_elemento_no_esperado',
			'ruptura',
			'omision',
			'adicion',
			'sustitucion',
			'otra'
		)),
	metro_observado_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete restrict,
	patron_rima_observado_id uuid null references public.patrones_rima (patron_rima_id)
		on update cascade on delete restrict,
	seccion_observada_id uuid null references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict,
	patron_repeticion_observado_id uuid null references public.patrones_repeticion (patron_repeticion_id)
		on update cascade on delete restrict,
	valor_rasgo_observado_id uuid null references public.rasgo_valores (valor_id)
		on update cascade on delete restrict,
	observaciones text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

comment on table public.desviaciones_editor_metrico is
	'Diferencias respecto de la configuración y de las elecciones admitidas. Se mantienen separadas de las realizaciones ordinarias.';

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
	return new;
end;
$$;

create or replace function public.validar_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_dimension text;
	v_configuracion_id uuid;
	v_objetivo_configuracion_id uuid;
	v_rasgo_id uuid;
begin
	select dimension, configuracion_id
	into v_dimension, v_configuracion_id
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id;

	if v_dimension = 'metro' and num_nonnulls(new.metro_id, new.patron_metrico_id) <> 1 then
		raise exception 'Una opción de medida debe apuntar a un metro o patrón métrico';
	elsif v_dimension = 'rima' and new.patron_rima_id is null then
		raise exception 'Una opción de rima debe apuntar a un patrón de rima';
	elsif v_dimension = 'estructura' and new.seccion_id is null then
		raise exception 'Una opción estructural debe apuntar a una sección';
	elsif v_dimension = 'repeticion' and new.patron_repeticion_id is null then
		raise exception 'Una opción de repetición debe apuntar a un patrón de repetición';
	elsif v_dimension = 'rasgo' and num_nonnulls(new.rasgo_id, new.valor_rasgo_id) <> 1 then
		raise exception 'Una opción de rasgo debe apuntar a un rasgo booleano o a un valor controlado';
	end if;

	if new.patron_metrico_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_metricos where patron_metrico_id = new.patron_metrico_id;
	elsif new.patron_rima_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_rima where patron_rima_id = new.patron_rima_id;
	elsif new.seccion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.estructuras_secciones where seccion_id = new.seccion_id;
	elsif new.patron_repeticion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_repeticion where patron_repeticion_id = new.patron_repeticion_id;
	elsif new.valor_rasgo_id is not null then
		select rasgo_id into v_rasgo_id
		from public.rasgo_valores where valor_id = new.valor_rasgo_id;
	end if;

	if v_objetivo_configuracion_id is not null
		and v_objetivo_configuracion_id is distinct from v_configuracion_id
	then
		raise exception 'La opción no pertenece a la configuración del grupo';
	end if;

	if v_dimension = 'rasgo' then
		v_rasgo_id := coalesce(new.rasgo_id, v_rasgo_id);
		if not exists (
			select 1
			from public.configuracion_rasgos
			where configuracion_id = v_configuracion_id
				and rasgo_id = v_rasgo_id
		) then
			raise exception 'El rasgo de la opción no está admitido por la configuración';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_secuencia_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	if not exists (
		select 1
		from public.configuraciones_forma configuracion
		join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
		where configuracion.configuracion_id = new.configuracion_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
			and forma.activo
			and forma.seleccionable
	) then
		raise exception 'La configuración no pertenece a una forma activa y seleccionable';
	end if;
	return new;
end;
$$;

create or replace function public.validar_unidad_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_id uuid;
	v_secuencia_ini integer;
	v_secuencia_fin integer;
begin
	select configuracion_id, v_ini, v_fin
	into v_configuracion_id, v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if not exists (
		select 1 from public.estructuras_secciones
		where seccion_id = new.seccion_id
			and configuracion_id = v_configuracion_id
	) then
		raise exception 'La sección de la unidad no pertenece a la configuración seleccionada';
	end if;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La unidad debe quedar dentro del rango de la secuencia';
	end if;

	if new.unidad_padre_id is not null and not exists (
		select 1 from public.unidades_editor_metrico
		where unidad_prueba_id = new.unidad_padre_id
			and secuencia_prueba_id = new.secuencia_prueba_id
	) then
		raise exception 'La unidad superior debe pertenecer a la misma secuencia';
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
	v_total integer;
begin
	select configuracion_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select alcance, seccion_id, selecciones_max
	into v_alcance, v_seccion_grupo, v_maximo
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and configuracion_id = v_configuracion_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la configuración seleccionada';
	end if;

	if not exists (
		select 1 from public.opciones_eleccion_metrica
		where opcion_eleccion_id = new.opcion_eleccion_id
			and grupo_eleccion_id = new.grupo_eleccion_id
			and activo
	) then
		raise exception 'La opción no pertenece al grupo de elección';
	end if;

	if v_alcance = 'secuencia' and new.unidad_prueba_id is not null then
		raise exception 'Una elección de secuencia no puede vincularse a una unidad';
	elsif v_alcance = 'unidad' and new.unidad_prueba_id is null then
		raise exception 'Una elección de unidad necesita una unidad concreta';
	end if;

	if new.unidad_prueba_id is not null then
		select seccion_id into v_seccion_unidad
		from public.unidades_editor_metrico
		where unidad_prueba_id = new.unidad_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if v_seccion_unidad is null then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
		if v_seccion_grupo is not null and v_seccion_grupo <> v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
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

create or replace function public.validar_desviacion_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_secuencia_ini integer;
	v_secuencia_fin integer;
begin
	select v_ini, v_fin
	into v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La desviación debe quedar dentro del rango de la secuencia';
	end if;
	if new.unidad_prueba_id is not null and not exists (
		select 1 from public.unidades_editor_metrico
		where unidad_prueba_id = new.unidad_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id
	) then
		raise exception 'La unidad de la desviación no pertenece a la secuencia';
	end if;
	return new;
end;
$$;

create trigger trigger_validar_grupo_eleccion_metrica
before insert or update on public.grupos_eleccion_metrica
for each row execute function public.validar_grupo_eleccion_metrica();

create trigger trigger_validar_opcion_eleccion_metrica
before insert or update on public.opciones_eleccion_metrica
for each row execute function public.validar_opcion_eleccion_metrica();

create trigger trigger_validar_secuencia_editor_metrico
before insert or update on public.secuencias_editor_metrico
for each row execute function public.validar_secuencia_editor_metrico();

create trigger trigger_validar_unidad_editor_metrico
before insert or update on public.unidades_editor_metrico
for each row execute function public.validar_unidad_editor_metrico();

create trigger trigger_validar_eleccion_editor_metrico
before insert or update on public.elecciones_editor_metrico
for each row execute function public.validar_eleccion_editor_metrico();

create trigger trigger_validar_desviacion_editor_metrico
before insert or update on public.desviaciones_editor_metrico
for each row execute function public.validar_desviacion_editor_metrico();

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
	v_seccion record;
	v_total integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
			using errcode = '42501';
	end if;

	v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;

	if v_secuencia_id is null then
		insert into public.secuencias_editor_metrico (
			escenario_id,
			orden,
			v_ini,
			v_fin,
			forma_id,
			configuracion_id,
			observaciones,
			created_by,
			updated_by
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
			unidad_prueba_id,
			secuencia_prueba_id,
			unidad_padre_id,
			seccion_id,
			orden,
			v_ini,
			v_fin,
			etiqueta,
			observaciones
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

	-- Solo se exige materializar una sección cuando alguna pregunta por unidad
	-- depende de ella. Las secciones fijas sin decisiones editoriales se derivan
	-- de la configuración y no obligan a repetir datos.
	for v_seccion in
		select distinct
			seccion.seccion_id,
			seccion.nombre,
			seccion.tipo_seccion,
			coalesce(seccion.repeticiones_min, 0) as repeticiones_min,
			seccion.repeticiones_max
		from public.estructuras_secciones seccion
		join public.grupos_eleccion_metrica grupo
			on grupo.configuracion_id = seccion.configuracion_id
			and grupo.alcance = 'unidad'
			and grupo.seccion_id = seccion.seccion_id
			and grupo.activo
		where seccion.configuracion_id = (p_datos ->> 'configuracion_id')::uuid
	loop
		select count(*) into v_total
		from public.unidades_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and seccion_id = v_seccion.seccion_id;

		if v_total < v_seccion.repeticiones_min then
			raise exception 'La sección «%» necesita al menos % unidades',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_min;
		end if;
		if v_seccion.repeticiones_max is not null
			and v_total > v_seccion.repeticiones_max
		then
			raise exception 'La sección «%» admite como máximo % unidades',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_max;
		end if;
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
	loop
		insert into public.elecciones_editor_metrico (
			secuencia_prueba_id,
			unidad_prueba_id,
			grupo_eleccion_id,
			opcion_eleccion_id,
			observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'unidad_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			(v_item ->> 'opcion_eleccion_id')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
	loop
		insert into public.desviaciones_editor_metrico (
			secuencia_prueba_id,
			unidad_prueba_id,
			v_ini,
			v_fin,
			dimension,
			relacion_norma,
			metro_observado_id,
			patron_rima_observado_id,
			seccion_observada_id,
			patron_repeticion_observado_id,
			valor_rasgo_observado_id,
			observaciones
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
		select
			grupo.*,
			unidad.unidad_prueba_id
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
	v_table text;
begin
	foreach v_table in array array[
		'grupos_eleccion_metrica',
		'opciones_eleccion_metrica',
		'escenarios_editor_metrico',
		'secuencias_editor_metrico',
		'unidades_editor_metrico',
		'elecciones_editor_metrico',
		'desviaciones_editor_metrico'
	]
	loop
		execute format('alter table public.%I enable row level security', v_table);
		execute format(
			'create policy %I on public.%I for all to authenticated using (public.auth_is_admin_or_ip()) with check (public.auth_is_admin_or_ip())',
			v_table || '_admin_ip',
			v_table
		);
		execute format(
			'grant select, insert, update, delete on table public.%I to authenticated',
			v_table
		);
	end loop;
end;
$$;

do $$
declare
	v_table text;
begin
	foreach v_table in array array[
		'grupos_eleccion_metrica',
		'opciones_eleccion_metrica',
		'escenarios_editor_metrico',
		'secuencias_editor_metrico',
		'unidades_editor_metrico',
		'desviaciones_editor_metrico'
	]
	loop
		execute format(
			'create trigger %I before update on public.%I for each row execute function public.actualizar_updated_at()',
			'trigger_' || v_table || '_updated_at',
			v_table
		);
	end loop;
end;
$$;

create trigger trigger_grupos_eleccion_catalogo_revision
after insert or update or delete on public.grupos_eleccion_metrica
for each statement execute function public.marcar_catalogo_metrico_actualizado();

create trigger trigger_opciones_eleccion_catalogo_revision
after insert or update or delete on public.opciones_eleccion_metrica
for each statement execute function public.marcar_catalogo_metrico_actualizado();

create index grupos_eleccion_configuracion_idx
	on public.grupos_eleccion_metrica (configuracion_id, alcance, orden);
create index opciones_eleccion_grupo_idx
	on public.opciones_eleccion_metrica (grupo_eleccion_id, orden);
create index secuencias_editor_metrico_escenario_idx
	on public.secuencias_editor_metrico (escenario_id, orden);
create index unidades_editor_metrico_secuencia_idx
	on public.unidades_editor_metrico (secuencia_prueba_id, orden);
create index elecciones_editor_metrico_secuencia_grupo_idx
	on public.elecciones_editor_metrico (secuencia_prueba_id, grupo_eleccion_id);
create index desviaciones_editor_metrico_secuencia_idx
	on public.desviaciones_editor_metrico (secuencia_prueba_id, v_ini);

-- Primera traducción completa al editor: villancico.
do $$
declare
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_abba_id uuid;
	v_patron_rima_abab_id uuid;
	v_patron_repeticion_total_id uuid;
	v_patron_repeticion_parcial_id uuid;
	v_patron_repeticion_implicita_id uuid;
	v_seccion_copla_id uuid;
	v_seccion_enlace_id uuid;
	v_seccion_vuelta_id uuid;
	v_metro_6_id uuid;
	v_metro_8_id uuid;
	v_grupo_id uuid;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'villancico'
		and configuracion.slug = 'estructura_habitual';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración formalizada del villancico';
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id
		and tipo = 'conjunto_permitido';

	select patron_rima_id into v_patron_rima_abba_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id and esquema = 'abba';

	select patron_rima_id into v_patron_rima_abab_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id and esquema = 'abab';

	select seccion_id into v_seccion_copla_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id is null
		and tipo_seccion = 'copla';

	select seccion_id into v_seccion_enlace_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_seccion_copla_id
		and tipo_seccion = 'enlace';

	select seccion_id into v_seccion_vuelta_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_seccion_copla_id
		and tipo_seccion = 'vuelta';

	select opcion.metro_id into v_metro_6_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_id
		and metro.numero_silabas = 6;

	select opcion.metro_id into v_metro_8_id
	from public.patron_metrico_opciones opcion
	join public.vocabularios metro on metro.termino_id = opcion.metro_id
	where opcion.patron_metrico_id = v_patron_metrico_id
		and metro.numero_silabas = 8;

	select patron_repeticion_id into v_patron_repeticion_total_id
	from public.patrones_repeticion
	where configuracion_id = v_configuracion_id
	order by created_at
	limit 1;

	if num_nonnulls(
		v_patron_metrico_id,
		v_patron_rima_abba_id,
		v_patron_rima_abab_id,
		v_seccion_copla_id,
		v_seccion_enlace_id,
		v_seccion_vuelta_id,
		v_metro_6_id,
		v_metro_8_id,
		v_patron_repeticion_total_id
	) <> 9 then
		raise exception 'La formalización del villancico está incompleta para generar sus preguntas editoriales';
	end if;

	update public.patrones_repeticion
	set
		regla = 'Tras cada copla se repite completo el estribillo inicial.',
		fijeza = 'admitida',
		descripcion = 'Realización con repetición íntegra del estribillo.',
		estado_revision = 'revisada'
	where patron_repeticion_id = v_patron_repeticion_total_id;

	insert into public.patrones_repeticion (
		configuracion_id,
		tipo,
		ambito,
		regla,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_configuracion_id,
		'estribillo',
		'composicion',
		'Tras cada copla se repite solo una parte del estribillo inicial.',
		'admitida',
		'Realización con repetición parcial del estribillo.',
		'revisada'
	)
	returning patron_repeticion_id into v_patron_repeticion_parcial_id;

	insert into public.patrones_repeticion (
		configuracion_id,
		tipo,
		ambito,
		regla,
		fijeza,
		descripcion,
		estado_revision
	)
	values (
		v_configuracion_id,
		'estribillo',
		'composicion',
		'Tras cada copla el estribillo queda sobreentendido sin repetirse materialmente.',
		'admitida',
		'Realización con repetición implícita del estribillo.',
		'revisada'
	)
	returning patron_repeticion_id into v_patron_repeticion_implicita_id;

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		selecciones_min,
		selecciones_max,
		estado_revision,
		orden
	)
	values (
		v_configuracion_id,
		'medidas_realizadas',
		'¿Qué medidas aparecen?',
		'Marca hexasílabos, octosílabos o ambas opciones si la secuencia combina las dos medidas admitidas.',
		'metro',
		'secuencia',
		1,
		2,
		'revisada',
		1
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, metro_id, orden
	)
	values
		(v_grupo_id, 'hexasilabo', '6 sílabas', v_metro_6_id, 1),
		(v_grupo_id, 'octosilabo', '8 sílabas', v_metro_8_id, 2);

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
		estado_revision,
		orden
	)
	values (
		v_configuracion_id,
		'rima_mudanza',
		'¿Qué patrón tiene la mudanza?',
		'Se registra en cada copla. Puede aplicarse la misma respuesta a todas y corregir solo las excepciones.',
		'rima',
		'unidad',
		v_seccion_copla_id,
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
	values
		(v_grupo_id, 'abba', 'abba — redondilla', v_patron_rima_abba_id, 1),
		(v_grupo_id, 'abab', 'abab — cuarteta', v_patron_rima_abab_id, 2);

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
		estado_revision,
		orden
	)
	values (
		v_configuracion_id,
		'presencia_enlace',
		'¿Hay enlace?',
		'La ausencia de selección significa que esta copla no presenta enlace.',
		'estructura',
		'unidad',
		v_seccion_copla_id,
		0,
		1,
		true,
		'revisada',
		3
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, seccion_id, orden
	)
	values (v_grupo_id, 'presente', 'Sí, hay enlace', v_seccion_enlace_id, 1);

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
		estado_revision,
		orden
	)
	values (
		v_configuracion_id,
		'presencia_vuelta',
		'¿Hay vuelta?',
		'La ausencia de selección significa que esta copla no presenta vuelta.',
		'estructura',
		'unidad',
		v_seccion_copla_id,
		0,
		1,
		true,
		'revisada',
		4
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, seccion_id, orden
	)
	values (v_grupo_id, 'presente', 'Sí, hay vuelta', v_seccion_vuelta_id, 1);

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
		estado_revision,
		orden
	)
	values (
		v_configuracion_id,
		'repeticion_estribillo',
		'¿Cómo se recupera el estribillo?',
		'Selecciona la realización observada tras esta copla.',
		'repeticion',
		'unidad',
		v_seccion_copla_id,
		1,
		1,
		true,
		'revisada',
		5
	)
	returning grupo_eleccion_id into v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, patron_repeticion_id, orden
	)
	values
		(v_grupo_id, 'total', 'Repetición total', v_patron_repeticion_total_id, 1),
		(v_grupo_id, 'parcial', 'Repetición parcial', v_patron_repeticion_parcial_id, 2),
		(v_grupo_id, 'implicita', 'Repetición implícita', v_patron_repeticion_implicita_id, 3);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 15,
	actualizado_en = now()
where id = true;

commit;
