begin;

-- Una configuración puede admitir varios patrones métricos y varios patrones
-- de rima sin que todas sus combinaciones sean válidas. Esta tabla representa
-- únicamente las parejas documentadas y evita tanto el producto cartesiano
-- falso como la creación de configuraciones artificiales.
create table public.combinaciones_patrones_configuracion (
	combinacion_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	slug text not null check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	patron_metrico_id uuid not null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete restrict,
	patron_rima_id uuid not null references public.patrones_rima (patron_rima_id)
		on update cascade on delete restrict,
	preferente boolean not null default false,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (configuracion_id, slug),
	unique (configuracion_id, patron_metrico_id, patron_rima_id)
);

comment on table public.combinaciones_patrones_configuracion is
	'Parejas admitidas de patrón métrico y patrón de rima dentro de una configuración. No crean formas ni configuraciones nuevas.';

create or replace function public.validar_combinacion_patrones_configuracion()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_metrica_id uuid;
	v_configuracion_rima_id uuid;
begin
	select configuracion_id into v_configuracion_metrica_id
	from public.patrones_metricos
	where patron_metrico_id = new.patron_metrico_id;

	select configuracion_id into v_configuracion_rima_id
	from public.patrones_rima
	where patron_rima_id = new.patron_rima_id;

	if v_configuracion_metrica_id is distinct from new.configuracion_id
		or v_configuracion_rima_id is distinct from new.configuracion_id
	then
		raise exception
			'Los patrones de la combinación deben pertenecer a su misma configuración';
	end if;

	return new;
end;
$$;

create trigger trigger_combinaciones_patrones_validar
before insert or update on public.combinaciones_patrones_configuracion
for each row execute function public.validar_combinacion_patrones_configuracion();

create trigger trigger_combinaciones_patrones_updated_at
before update on public.combinaciones_patrones_configuracion
for each row execute function public.actualizar_updated_at();

create trigger trigger_combinaciones_patrones_catalogo_revision
after insert or update or delete on public.combinaciones_patrones_configuracion
for each statement execute function public.marcar_catalogo_metrico_actualizado();

alter table public.combinaciones_patrones_configuracion enable row level security;

create policy combinaciones_patrones_configuracion_admin_ip
	on public.combinaciones_patrones_configuracion
	for all to authenticated
	using (public.auth_is_admin_or_ip())
	with check (public.auth_is_admin_or_ip());

grant select, insert, update, delete
	on table public.combinaciones_patrones_configuracion
	to authenticated;

create index combinaciones_patrones_configuracion_idx
	on public.combinaciones_patrones_configuracion (configuracion_id, orden);

-- Las preguntas editoriales pueden apuntar a la combinación completa.
do $$
declare
	v_constraint text;
begin
	for v_constraint in
		select constraint_record.conname
		from pg_constraint constraint_record
		where constraint_record.conrelid = 'public.grupos_eleccion_metrica'::regclass
			and constraint_record.contype = 'c'
			and pg_get_constraintdef(constraint_record.oid) like '%dimension%'
	loop
		execute format(
			'alter table public.grupos_eleccion_metrica drop constraint %I',
			v_constraint
		);
	end loop;
end;
$$;

alter table public.grupos_eleccion_metrica
	add constraint grupos_eleccion_metrica_dimension_check
	check (dimension in (
		'metro',
		'rima',
		'combinacion',
		'estructura',
		'repeticion',
		'rasgo'
	));

alter table public.opciones_eleccion_metrica
	add column combinacion_id uuid null
		references public.combinaciones_patrones_configuracion (combinacion_id)
		on update cascade on delete restrict;

do $$
declare
	v_constraint text;
begin
	for v_constraint in
		select constraint_record.conname
		from pg_constraint constraint_record
		where constraint_record.conrelid = 'public.opciones_eleccion_metrica'::regclass
			and constraint_record.contype = 'c'
			and pg_get_constraintdef(constraint_record.oid) like '%num_nonnulls%'
	loop
		execute format(
			'alter table public.opciones_eleccion_metrica drop constraint %I',
			v_constraint
		);
	end loop;
end;
$$;

alter table public.opciones_eleccion_metrica
	add constraint opciones_eleccion_metrica_un_objetivo_check
	check (
		num_nonnulls(
			metro_id,
			patron_metrico_id,
			patron_rima_id,
			combinacion_id,
			seccion_id,
			patron_repeticion_id,
			rasgo_id,
			valor_rasgo_id
		) = 1
	);

create or replace function public.validar_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_dimension text;
	v_configuracion_id uuid;
	v_seccion_grupo_id uuid;
	v_configuracion_referenciada_id uuid;
	v_objetivo_configuracion_id uuid;
	v_rasgo_id uuid;
begin
	select
		grupo.dimension,
		grupo.configuracion_id,
		grupo.seccion_id,
		seccion.configuracion_referenciada_id
	into
		v_dimension,
		v_configuracion_id,
		v_seccion_grupo_id,
		v_configuracion_referenciada_id
	from public.grupos_eleccion_metrica grupo
	left join public.estructuras_secciones seccion
		on seccion.seccion_id = grupo.seccion_id
	where grupo.grupo_eleccion_id = new.grupo_eleccion_id;

	if v_dimension = 'metro'
		and num_nonnulls(new.metro_id, new.patron_metrico_id) <> 1
	then
		raise exception 'Una opción de medida debe apuntar a un metro o patrón métrico';
	elsif v_dimension = 'rima' and new.patron_rima_id is null then
		raise exception 'Una opción de rima debe apuntar a un patrón de rima';
	elsif v_dimension = 'combinacion' and new.combinacion_id is null then
		raise exception 'Una opción combinada debe apuntar a una combinación de patrones';
	elsif v_dimension = 'estructura' and new.seccion_id is null then
		raise exception 'Una opción estructural debe apuntar a una sección';
	elsif v_dimension = 'repeticion' and new.patron_repeticion_id is null then
		raise exception 'Una opción de repetición debe apuntar a un patrón de repetición';
	elsif v_dimension = 'rasgo'
		and num_nonnulls(new.rasgo_id, new.valor_rasgo_id) <> 1
	then
		raise exception
			'Una opción de rasgo debe apuntar a un rasgo booleano o a un valor controlado';
	end if;

	if new.patron_metrico_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_metricos
		where patron_metrico_id = new.patron_metrico_id;
	elsif new.patron_rima_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_rima
		where patron_rima_id = new.patron_rima_id;
	elsif new.combinacion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.combinaciones_patrones_configuracion
		where combinacion_id = new.combinacion_id;
	elsif new.seccion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.estructuras_secciones
		where seccion_id = new.seccion_id;
	elsif new.patron_repeticion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_repeticion
		where patron_repeticion_id = new.patron_repeticion_id;
	elsif new.valor_rasgo_id is not null then
		select rasgo_id into v_rasgo_id
		from public.rasgo_valores
		where valor_id = new.valor_rasgo_id;
	end if;

	if v_objetivo_configuracion_id is not null
		and v_objetivo_configuracion_id is distinct from v_configuracion_id
		and (
			v_seccion_grupo_id is null
			or v_objetivo_configuracion_id is distinct from v_configuracion_referenciada_id
		)
	then
		raise exception
			'La opción no pertenece a la configuración del grupo ni a la configuración reutilizada por su sección';
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

-- La traza debe poder conducir una antigua subforma a la combinación exacta.
alter table public.migracion_termino_destinos
	add column combinacion_id uuid null
		references public.combinaciones_patrones_configuracion (combinacion_id)
		on update cascade on delete cascade;

do $$
declare
	v_constraint text;
begin
	for v_constraint in
		select constraint_record.conname
		from pg_constraint constraint_record
		where constraint_record.conrelid = 'public.migracion_termino_destinos'::regclass
			and constraint_record.contype = 'c'
			and pg_get_constraintdef(constraint_record.oid) like '%num_nonnulls%'
	loop
		execute format(
			'alter table public.migracion_termino_destinos drop constraint %I',
			v_constraint
		);
	end loop;
end;
$$;

alter table public.migracion_termino_destinos
	add constraint migracion_termino_destinos_un_destino_check
	check (
		tipo_operacion = 'retirar'
		or num_nonnulls(
			forma_id,
			familia_id,
			configuracion_id,
			patron_metrico_id,
			patron_rima_id,
			combinacion_id,
			rasgo_id,
			valor_rasgo_id,
			alias_id
		) = 1
	);

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_metro_7_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_rasgo_final_id uuid;
	v_valor_esdrujulo_id uuid;
	v_seccion_id uuid;
	v_grupo_tipologia_id uuid;
	v_grupo_final_id uuid;
	v_fuente_id uuid;
	v_total integer;
	v_patron record;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'sexteto_lira';

	if v_forma_id is null then
		raise exception 'No se encontró la forma importada sexteto_lira';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración importada para sexteto-lira y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	select count(*) into v_total
	from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'El sexteto-lira tiene % preguntas editoriales previas que deben revisarse manualmente',
			v_total;
	end if;

	select count(*) into v_total
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

	if v_total <> 0 then
		raise exception
			'El sexteto-lira tiene % secciones previas que deben revisarse manualmente',
			v_total;
	end if;

	select termino_id into v_metro_7_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'heptasilabo'
		and numero_silabas = 7;

	select termino_id into v_metro_11_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'endecasilabo'
		and numero_silabas = 11;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	select rasgo_id into v_rasgo_final_id
	from public.rasgos_metricos
	where slug = 'final_acentual';

	select valor_id into v_valor_esdrujulo_id
	from public.rasgo_valores
	where rasgo_id = v_rasgo_final_id
		and slug = 'esdrujulo';

	if v_metro_7_id is null
		or v_metro_11_id is null
		or v_consonante_id is null
		or v_rasgo_final_id is null
		or v_valor_esdrujulo_id is null
	then
		raise exception
			'Falta heptasílabo, endecasílabo, consonante o final_acentual = esdrujulo';
	end if;

	-- Solo afecta al entorno de prueba V2. Las secuencias reales siguen usando
	-- el vocabulario anterior y no se modifican en esta fase.
	delete from public.desviaciones_editor_metrico desviacion
	using public.patrones_rima patron
	where desviacion.patron_rima_observado_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;

	delete from public.migracion_termino_destinos destino
	using public.vocabularios termino
	where destino.termino_id = termino.termino_id
		and (
			termino.termino = 'sexteto_lira'
			or termino.termino like 'sexteto_lira_%'
		);

	delete from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	delete from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	update public.formas_metricas
	set
		nombre = 'Sexteto-lira',
		definicion = 'Estrofa de seis versos heptasílabos y endecasílabos con rima consonante distribuida en tres clases. Los dos versos finales forman un pareado con la tercera rima. El catálogo del proyecto reconoce actualmente siete tipologías que combinan cinco patrones métricos y tres distribuciones de rima.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'heterometrica_consonante',
		nombre = 'Heterométrica consonante',
		descripcion = 'Seis versos heptasílabos y endecasílabos; la tipología determina conjuntamente el orden métrico y la distribución de tres rimas.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
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
	values
		(v_configuracion_id, 'M1 · 7-11-7-11-7-11', 'estrofa', 'secuencia_fija', 'Alternancia de heptasílabos y endecasílabos.', 'revisada'),
		(v_configuracion_id, 'M2 · 11-7-7-11-7-11', 'estrofa', 'secuencia_fija', 'Endecasílabos en las posiciones 1, 4 y 6.', 'revisada'),
		(v_configuracion_id, 'M3 · 7-7-7-11-7-11', 'estrofa', 'secuencia_fija', 'Endecasílabos en las posiciones 4 y 6.', 'revisada'),
		(v_configuracion_id, 'M4 · 7-7-7-7-7-11', 'estrofa', 'secuencia_fija', 'Cinco heptasílabos y endecasílabo final.', 'revisada'),
		(v_configuracion_id, 'M5 · 11-7-7-11-11-11', 'estrofa', 'secuencia_fija', 'Endecasílabos en las posiciones 1, 4, 5 y 6.', 'revisada');

	for v_patron in
		select
			patron_metrico_id,
			nombre,
			case nombre
				when 'M1 · 7-11-7-11-7-11' then array[7, 11, 7, 11, 7, 11]
				when 'M2 · 11-7-7-11-7-11' then array[11, 7, 7, 11, 7, 11]
				when 'M3 · 7-7-7-11-7-11' then array[7, 7, 7, 11, 7, 11]
				when 'M4 · 7-7-7-7-7-11' then array[7, 7, 7, 7, 7, 11]
				else array[11, 7, 7, 11, 11, 11]
			end as medidas
		from public.patrones_metricos
		where configuracion_id = v_configuracion_id
	loop
		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id,
			opcional,
			alternativa,
			nota
		)
		select
			v_patron.patron_metrico_id,
			posicion,
			case v_patron.medidas[posicion]
				when 7 then v_metro_7_id
				else v_metro_11_id
			end,
			false,
			1,
			'Posición fija de la tipología de sexteto-lira.'
		from generate_series(1, 6) as serie(posicion);
	end loop;

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
	values
		(v_configuracion_id, 'R1 · ababcc', 'ababcc', v_consonante_id, 'estrofa', 'secuencia_fija', 'preferente', 'Alternancia abab en los cuatro primeros versos y pareado final cc.', 'revisada'),
		(v_configuracion_id, 'R2 · abbacc', 'abbacc', v_consonante_id, 'estrofa', 'secuencia_fija', 'admitido', 'Rima abrazada abba en los cuatro primeros versos y pareado final cc.', 'revisada'),
		(v_configuracion_id, 'R3 · aabbcc', 'aabbcc', v_consonante_id, 'estrofa', 'secuencia_fija', 'admitido', 'Tres pareados consecutivos aa bb cc.', 'revisada');

	-- El disparador sincronizar_posiciones_patron_rima_fijo ya ha creado las
	-- seis posiciones a partir de cada esquema. Aquí solo se precisa su
	-- organización interna; volver a insertarlas violaría la clave única.
	update public.patron_rima_posiciones posicion
	set
		bloque = case when posicion.posicion <= 4 then 1 else 2 end,
		seccion = case
			when posicion.posicion <= 4 then 'cuerpo'
			else 'pareado_final'
		end,
		nota = case
			when posicion.posicion <= 4 then 'Posición del cuerpo de cuatro versos.'
			else 'Posición del pareado final.'
		end
	from public.patrones_rima patron
	where posicion.patron_rima_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;

	select count(*) into v_total
	from public.patron_rima_posiciones posicion
	join public.patrones_rima patron
		on patron.patron_rima_id = posicion.patron_rima_id
	where patron.configuracion_id = v_configuracion_id;

	if v_total <> 18 then
		raise exception
			'Se esperaban dieciocho posiciones de rima para el sexteto-lira y se encontraron %',
			v_total;
	end if;

	insert into public.combinaciones_patrones_configuracion (
		configuracion_id,
		slug,
		nombre,
		descripcion,
		patron_metrico_id,
		patron_rima_id,
		preferente,
		estado_revision,
		activo,
		orden,
		origen_termino_id
	)
	select
		v_configuracion_id,
		tipologia.slug,
		tipologia.nombre,
		tipologia.descripcion,
		metrico.patron_metrico_id,
		rima.patron_rima_id,
		tipologia.preferente,
		'revisada',
		true,
		tipologia.orden,
		termino.termino_id
	from (
		values
			('sexteto_lira_a1_aBaBcC', 'a1_aBaBcC', 'A1 · aBaBcC', '7-11-7-11-7-11 con rima ababcc.', 'M1 · 7-11-7-11-7-11', 'ababcc', true, 1),
			('sexteto_lira_a2_AbaBcC', 'a2_AbaBcC', 'A2 · AbaBcC', '11-7-7-11-7-11 con rima ababcc.', 'M2 · 11-7-7-11-7-11', 'ababcc', false, 2),
			('sexteto_lira_a3_abaBcC', 'a3_abaBcC', 'A3 · abaBcC', '7-7-7-11-7-11 con rima ababcc.', 'M3 · 7-7-7-11-7-11', 'ababcc', false, 3),
			('sexteto_lira_b1_abbacC', 'b1_abbacC', 'B1 · abbacC', '7-7-7-7-7-11 con rima abbacc.', 'M4 · 7-7-7-7-7-11', 'abbacc', false, 4),
			('sexteto_lira_b2_AbbACC', 'b2_AbbACC', 'B2 · AbbACC', '11-7-7-11-11-11 con rima abbacc.', 'M5 · 11-7-7-11-11-11', 'abbacc', false, 5),
			('sexteto_lira_c1_AabBcC', 'c1_AabBcC', 'C1 · AabBcC', '11-7-7-11-7-11 con rima aabbcc.', 'M2 · 11-7-7-11-7-11', 'aabbcc', false, 6),
			('sexteto_lira_c2_AabBCC', 'c2_AabBCC', 'C2 · AabBCC', '11-7-7-11-11-11 con rima aabbcc.', 'M5 · 11-7-7-11-11-11', 'aabbcc', false, 7)
	) as tipologia(
		termino,
		slug,
		nombre,
		descripcion,
		patron_metrico,
		patron_rima,
		preferente,
		orden
	)
	join public.vocabularios termino
		on termino.categoria = 'estrofa_tipo'
		and termino.termino = tipologia.termino
	join public.patrones_metricos metrico
		on metrico.configuracion_id = v_configuracion_id
		and metrico.nombre = tipologia.patron_metrico
	join public.patrones_rima rima
		on rima.configuracion_id = v_configuracion_id
		and rima.esquema = tipologia.patron_rima;

	select count(*) into v_total
	from public.combinaciones_patrones_configuracion
	where configuracion_id = v_configuracion_id;

	if v_total <> 7 then
		raise exception
			'Se esperaban siete tipologías combinadas de sexteto-lira y se crearon %',
			v_total;
	end if;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values (
		v_configuracion_id,
		'sexteto_lira',
		'Sexteto-lira',
		1,
		1,
		null,
		6,
		6,
		'Unidad repetible de seis versos; permite registrar la tipología de cada estrofa.'
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
		estado_revision,
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'tipologia',
		'¿Qué tipología de sexteto-lira presenta?',
		'La fórmula reúne en una sola elección la medida y la rima. Puedes aplicarla a toda la tirada y cambiar únicamente las estrofas que difieran.',
		'combinacion',
		'unidad',
		v_seccion_id,
		1,
		1,
		true,
		'revisada',
		1,
		true
	)
	returning grupo_eleccion_id into v_grupo_tipologia_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		combinacion_id,
		orden
	)
	select
		v_grupo_tipologia_id,
		combinacion.slug,
		combinacion.nombre,
		combinacion.descripcion,
		combinacion.combinacion_id,
		combinacion.orden
	from public.combinaciones_patrones_configuracion combinacion
	where combinacion.configuracion_id = v_configuracion_id
	order by combinacion.orden;

	insert into public.configuracion_rasgos (
		configuracion_id,
		rasgo_id,
		valor_id,
		modalidad,
		nota
	)
	values (
		v_configuracion_id,
		v_rasgo_final_id,
		v_valor_esdrujulo_id,
		'admitida',
		'Especialización transversal heredada de sexteto_lira_de_esdrujulos. Solo se declara cuando caracteriza la secuencia.'
	)
	on conflict (configuracion_id, rasgo_id, modalidad) do update
	set
		valor_id = excluded.valor_id,
		valor_numero = null,
		valor_texto = null,
		nota = excluded.nota,
		updated_at = now();

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
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'final_acentual_destacado',
		'¿Presenta un final acentual destacado?',
		'Déjalo sin marcar cuando no sea una característica de la secuencia.',
		'rasgo',
		'secuencia',
		0,
		1,
		'revisada',
		2,
		true
	)
	returning grupo_eleccion_id into v_grupo_final_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		valor_rasgo_id,
		orden
	)
	values (
		v_grupo_final_id,
		'esdrujulo',
		'Mayoría de finales esdrújulos',
		'Los finales esdrújulos caracterizan mayoritariamente la secuencia.',
		v_valor_esdrujulo_id,
		1
	);

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case
			when termino.termino = 'sexteto_lira' then 'F'
			when termino.termino = 'sexteto_lira_de_esdrujulos' then 'R'
			else 'P'
		end,
		propuesta = case
			when termino.termino = 'sexteto_lira'
				then 'Conservar como forma de seis versos con una configuración heterométrica consonante.'
			when termino.termino = 'sexteto_lira_de_esdrujulos'
				then 'Transformar en el rasgo transversal final_acentual = esdrujulo.'
			else
				'Transformar en una combinación admitida de patrón métrico y patrón de rima.'
		end,
		certeza = 'alta',
		requiere_revision = false
	from public.vocabularios termino
	where migracion.termino_id = termino.termino_id
		and (
			termino.termino = 'sexteto_lira'
			or termino.termino like 'sexteto_lira_%'
		);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	select
		termino_id,
		'conservar',
		v_forma_id,
		'La raíz anterior aporta la identidad Sexteto-lira.'
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'sexteto_lira';

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		combinacion_id,
		nota
	)
	select
		combinacion.origen_termino_id,
		'transformar',
		combinacion.combinacion_id,
		'La antigua subforma pasa a ser una tipología combinada admitida.'
	from public.combinaciones_patrones_configuracion combinacion
	where combinacion.configuracion_id = v_configuracion_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		valor_rasgo_id,
		nota
	)
	select
		termino_id,
		'transformar',
		v_valor_esdrujulo_id,
		'La antigua subforma pasa al rasgo transversal de final acentual.'
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'sexteto_lira_de_esdrujulos';

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
		resumen = 'Define el sexteto-lira como combinación de heptasílabos y endecasílabos con rima consonante y señala que puede presentar distintos esquemas. Las siete tipologías concretas proceden del criterio estructurado por el proyecto.',
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
			'Define el sexteto-lira como combinación de heptasílabos y endecasílabos con rima consonante y señala que puede presentar distintos esquemas. Las siete tipologías concretas proceden del criterio estructurado por el proyecto.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 34,
	actualizado_en = now()
where id = true;

commit;
