begin;

-- Una sección puede realizar una configuración ya formalizada de otra forma.
-- Esto permite componer la novena con redondilla y quintilla sin copiar sus
-- repertorios de patrones ni convertir esas partes en texto libre.
alter table public.estructuras_secciones
	add column configuracion_referenciada_id uuid null
		references public.configuraciones_forma (configuracion_id)
		on update cascade on delete restrict;

comment on column public.estructuras_secciones.configuracion_referenciada_id is
	'Configuración métrica que esta sección realiza como componente. Sus patrones pueden reutilizarse en las elecciones editoriales de la sección.';

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

do $$
declare
	v_termino_raiz_id uuid := '54e94efa-c638-4da8-ab2c-9e90f7ac0fc1'::uuid;
	v_termino_canonica_id uuid := 'df41918d-3b73-4732-a6ba-800222acf5b6'::uuid;
	v_termino_invertida_id uuid := 'b53dcb8e-1769-4634-8b77-980268767055'::uuid;
	v_forma_id uuid;
	v_config_raiz_id uuid;
	v_config_canonica_importada_id uuid;
	v_config_invertida_id uuid;
	v_config_redondilla_id uuid;
	v_config_quintilla_id uuid;
	v_metro_8_id uuid;
	v_consonante_id uuid;
	v_patron_metrico_id uuid;
	v_seccion_raiz_id uuid;
	v_seccion_redondilla_id uuid;
	v_seccion_quintilla_id uuid;
	v_grupo_redondilla_id uuid;
	v_grupo_quintilla_id uuid;
	v_fuente_id uuid;
	v_configuracion_id uuid;
	v_invertida boolean;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'novena';

	if v_forma_id is null or v_forma_id <> v_termino_raiz_id then
		raise exception 'No se encontró la forma novena con el UUID legado esperado';
	end if;

	select configuracion_id into v_config_raiz_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id is null;

	select configuracion_id into v_config_canonica_importada_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id = v_termino_canonica_id;

	select configuracion_id into v_config_invertida_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and origen_termino_id = v_termino_invertida_id;

	if num_nonnulls(
		v_config_raiz_id,
		v_config_canonica_importada_id,
		v_config_invertida_id
	) <> 3 then
		raise exception
			'No se encontraron las tres configuraciones provisionales esperadas para novena';
	end if;

	-- La configuración genérica importada se convierte en la canónica. Cualquier
	-- escenario V2 que hubiese elegido la fila hija conserva el rango y la forma;
	-- sus unidades y respuestas provisionales se regenerarán desde el contrato
	-- revisado, porque apuntaban a entidades de la configuración eliminada.
	delete from public.elecciones_editor_metrico eleccion
	using public.secuencias_editor_metrico secuencia
	where eleccion.secuencia_prueba_id = secuencia.secuencia_prueba_id
		and secuencia.configuracion_id = v_config_canonica_importada_id;

	delete from public.desviaciones_editor_metrico desviacion
	using public.secuencias_editor_metrico secuencia
	where desviacion.secuencia_prueba_id = secuencia.secuencia_prueba_id
		and secuencia.configuracion_id = v_config_canonica_importada_id;

	delete from public.unidades_editor_metrico unidad
	using public.secuencias_editor_metrico secuencia
	where unidad.secuencia_prueba_id = secuencia.secuencia_prueba_id
		and secuencia.configuracion_id = v_config_canonica_importada_id;

	update public.secuencias_editor_metrico
	set configuracion_id = v_config_raiz_id
	where configuracion_id = v_config_canonica_importada_id;

	delete from public.configuraciones_forma
	where configuracion_id = v_config_canonica_importada_id;

	update public.configuraciones_forma
	set origen_termino_id = v_termino_canonica_id
	where configuracion_id = v_config_raiz_id;

	select configuracion.configuracion_id into v_config_redondilla_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'redondilla'
		and configuracion.slug = 'simple';

	select configuracion.configuracion_id into v_config_quintilla_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'quintilla'
		and configuracion.slug = 'octosilabica_consonante';

	select termino_id into v_metro_8_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	select termino_id into v_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	if v_config_redondilla_id is null
		or v_config_quintilla_id is null
		or v_metro_8_id is null
		or v_consonante_id is null
	then
		raise exception
			'Falta la configuración simple de redondilla, la quintilla, el octosílabo o la rima consonante';
	end if;

	select count(*) into v_total
	from public.patrones_rima
	where configuracion_id = v_config_redondilla_id
		and esquema in ('abba', 'abab');

	if v_total <> 2 then
		raise exception
			'La sección redondilla necesita los patrones abba y abab; se encontraron %',
			v_total;
	end if;

	select count(*) into v_total
	from public.patrones_rima
	where configuracion_id = v_config_quintilla_id
		and esquema in (
			'ababa',
			'abbab',
			'abaab',
			'aabab',
			'aabba',
			'abbaa',
			'ababb',
			'abbba'
		);

	if v_total <> 8 then
		raise exception
			'La sección quintilla necesita los ocho patrones reconocidos; se encontraron %',
			v_total;
	end if;

	delete from public.grupos_eleccion_metrica
	where configuracion_id in (v_config_raiz_id, v_config_invertida_id);

	delete from public.estructuras_secciones
	where configuracion_id in (v_config_raiz_id, v_config_invertida_id);

	delete from public.patrones_repeticion
	where configuracion_id in (v_config_raiz_id, v_config_invertida_id);

	delete from public.patrones_rima
	where configuracion_id in (v_config_raiz_id, v_config_invertida_id);

	delete from public.patrones_metricos
	where configuracion_id in (v_config_raiz_id, v_config_invertida_id);

	update public.formas_metricas
	set
		nombre = 'Novena',
		definicion = 'Estrofa de nueve versos octosílabos con rima consonante, organizada por lo general como unión de una redondilla y una quintilla, en este orden o en el inverso. El catálogo del proyecto reconoce ambas disposiciones.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'redondilla_quintilla',
		nombre = 'Redondilla + quintilla',
		descripcion = 'Nueve octosílabos consonantes distribuidos en una redondilla de cuatro versos seguida de una quintilla de cinco.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_consonante_id,
		numero_versos = 9,
		estado_revision = 'revisada',
		activo = true,
		orden = 1,
		updated_at = now()
	where configuracion_id = v_config_raiz_id;

	update public.configuraciones_forma
	set
		slug = 'quintilla_redondilla',
		nombre = 'Quintilla + redondilla',
		descripcion = 'Nueve octosílabos consonantes distribuidos en una quintilla de cinco versos seguida de una redondilla de cuatro.',
		principal = false,
		demarcable = true,
		grado = 'admitida',
		tipo_rima_id = v_consonante_id,
		numero_versos = 9,
		estado_revision = 'revisada',
		activo = true,
		orden = 2,
		updated_at = now()
	where configuracion_id = v_config_invertida_id;

	for v_configuracion_id, v_invertida in
		select v_config_raiz_id, false
		union all
		select v_config_invertida_id, true
	loop
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
			'Nueve octosílabos',
			'estrofa',
			'secuencia_fija',
			'Una posición octosilábica fija por cada uno de los nueve versos.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;

		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id,
			opcional,
			alternativa,
			nota
		)
		select
			v_patron_metrico_id,
			posicion,
			v_metro_8_id,
			false,
			1,
			'Posición octosilábica fija de la novena.'
		from generate_series(1, 9) as serie(posicion);

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
			'novena',
			'Novena',
			1,
			1,
			null,
			null,
			null,
			'Unidad repetible de nueve versos cuya extensión se deriva de sus dos componentes.'
		)
		returning seccion_id into v_seccion_raiz_id;

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
			configuracion_referenciada_id,
			nota
		)
		values (
			v_configuracion_id,
			v_seccion_raiz_id,
			'redondilla',
			'Redondilla',
			case when v_invertida then 2 else 1 end,
			1,
			1,
			4,
			4,
			v_config_redondilla_id,
			'Componente que reutiliza la configuración simple de redondilla.'
		)
		returning seccion_id into v_seccion_redondilla_id;

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
			configuracion_referenciada_id,
			nota
		)
		values (
			v_configuracion_id,
			v_seccion_raiz_id,
			'quintilla',
			'Quintilla',
			case when v_invertida then 1 else 2 end,
			1,
			1,
			5,
			5,
			v_config_quintilla_id,
			'Componente que reutiliza la configuración octosilábica consonante de quintilla.'
		)
		returning seccion_id into v_seccion_quintilla_id;

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
			'esquema_redondilla',
			'¿Qué esquema presenta la redondilla?',
			'Elige la disposición de rima de los cuatro primeros o últimos versos, según la configuración.',
			'rima',
			'unidad',
			v_seccion_redondilla_id,
			1,
			1,
			true,
			'revisada',
			case when v_invertida then 2 else 1 end,
			true
		)
		returning grupo_eleccion_id into v_grupo_redondilla_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id,
			slug,
			nombre,
			descripcion,
			patron_rima_id,
			orden
		)
		select
			v_grupo_redondilla_id,
			patron.esquema,
			case patron.esquema
				when 'abba' then 'Abrazada · abba'
				else 'Cruzada · abab'
			end,
			patron.descripcion,
			patron.patron_rima_id,
			case patron.esquema when 'abba' then 1 else 2 end
		from public.patrones_rima patron
		where patron.configuracion_id = v_config_redondilla_id
			and patron.esquema in ('abba', 'abab');

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
			'esquema_quintilla',
			'¿Qué esquema presenta la quintilla?',
			'Elige una de las ocho tipologías reconocidas actualmente por el proyecto.',
			'rima',
			'unidad',
			v_seccion_quintilla_id,
			1,
			1,
			true,
			'revisada',
			case when v_invertida then 1 else 2 end,
			true
		)
		returning grupo_eleccion_id into v_grupo_quintilla_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id,
			slug,
			nombre,
			descripcion,
			patron_rima_id,
			orden
		)
		select
			v_grupo_quintilla_id,
			patron.esquema,
			concat('Tipología ', orden_tipologia.orden, ' · ', patron.esquema),
			patron.descripcion,
			patron.patron_rima_id,
			orden_tipologia.orden
		from public.patrones_rima patron
		join (
			values
				('ababa', 1),
				('abbab', 2),
				('abaab', 3),
				('aabab', 4),
				('aabba', 5),
				('abbaa', 6),
				('ababb', 7),
				('abbba', 8)
		) as orden_tipologia(esquema, orden)
			on orden_tipologia.esquema = patron.esquema
		where patron.configuracion_id = v_config_quintilla_id;
	end loop;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case migracion.termino_id
			when v_termino_raiz_id then 'F'
			else 'C'
		end,
		propuesta = case migracion.termino_id
			when v_termino_raiz_id
				then 'Conservar como forma de nueve octosílabos consonantes con dos configuraciones estructurales.'
			when v_termino_canonica_id
				then 'Transformar en la configuración redondilla + quintilla.'
			else
				'Transformar en la configuración quintilla + redondilla.'
		end,
		certeza = 'alta',
		requiere_revision = false
	where migracion.termino_id in (
		v_termino_raiz_id,
		v_termino_canonica_id,
		v_termino_invertida_id
	);

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_raiz_id,
		v_termino_canonica_id,
		v_termino_invertida_id
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values (
		v_termino_raiz_id,
		'conservar',
		v_forma_id,
		'La antigua raíz aporta la identidad común Novena.'
	);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		configuracion_id,
		nota
	)
	values
		(
			v_termino_canonica_id,
			'transformar',
			v_config_raiz_id,
			'La antigua novena canónica pasa a ser la configuración redondilla + quintilla.'
		),
		(
			v_termino_invertida_id,
			'transformar',
			v_config_invertida_id,
			'La antigua novena invertida pasa a ser la configuración quintilla + redondilla.'
		);

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

	if exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_id
			and forma_id = v_forma_id
	) then
		update public.afirmaciones_fuentes_metricas
		set
			localizador = 'p. 204',
			resumen = 'Explica que novena designa en general una estrofa de nueve versos y documenta la combinación redondilla + quintilla. El catálogo adopta el alcance octosilábico consonante fijado por el proyecto y reconoce también el orden inverso.',
			confianza = 'alta',
			estado_revision = 'revisada',
			updated_at = now()
		where fuente_id = v_fuente_id
			and forma_id = v_forma_id;
	else
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
			'p. 204',
			'Explica que novena designa en general una estrofa de nueve versos y documenta la combinación redondilla + quintilla. El catálogo adopta el alcance octosilábico consonante fijado por el proyecto y reconoce también el orden inverso.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 32,
	actualizado_en = now()
where id = true;

commit;
