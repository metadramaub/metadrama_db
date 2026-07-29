begin;

-- Romance: la identidad de la forma no cambia con las vocales de la asonancia,
-- pero el dato observado sí debe quedar normalizado para filtrar y analizar.
do $$
declare
	v_configuracion_id uuid;
	v_rasgo_id uuid;
	v_grupo_id uuid;
	v_total_valores integer;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'romance'
		and configuracion.slug = 'octosilabico_asonante';

	select rasgo_id into v_rasgo_id
	from public.rasgos_metricos
	where slug = 'vocales_asonancia';

	if v_configuracion_id is null or v_rasgo_id is null then
		raise exception 'No se encontró la configuración del romance o el rasgo vocales_asonancia';
	end if;

	select count(*) into v_total_valores
	from public.rasgo_valores
	where rasgo_id = v_rasgo_id
		and activo;

	if v_total_valores = 0 then
		raise exception 'El rasgo vocales_asonancia no tiene valores activos';
	end if;

	insert into public.configuracion_rasgos (
		configuracion_id,
		rasgo_id,
		modalidad,
		nota
	)
	values (
		v_configuracion_id,
		v_rasgo_id,
		'admitida',
		'La realización concreta debe declarar las vocales de la asonancia sin crear una subforma de romance.'
	)
	on conflict (configuracion_id, rasgo_id, modalidad) do update
	set
		valor_id = null,
		valor_numero = null,
		valor_texto = null,
		nota = excluded.nota;

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
		'vocales_asonancia',
		'¿Qué vocales caracterizan la asonancia?',
		'Selecciona las vocales que comparten los versos pares. Esta elección no crea una forma distinta de romance.',
		'rasgo',
		'secuencia',
		1,
		1,
		'revisada',
		1,
		true
	)
	on conflict (configuracion_id, slug) do update
	set
		nombre = excluded.nombre,
		ayuda_editor = excluded.ayuda_editor,
		dimension = excluded.dimension,
		alcance = excluded.alcance,
		seccion_id = null,
		selecciones_min = excluded.selecciones_min,
		selecciones_max = excluded.selecciones_max,
		estado_revision = excluded.estado_revision,
		orden = excluded.orden,
		activo = excluded.activo
	returning grupo_eleccion_id into v_grupo_id;

	delete from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo_id;
	delete from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		valor_rasgo_id,
		orden
	)
	select
		v_grupo_id,
		valor.slug,
		valor.nombre,
		valor.descripcion,
		valor.valor_id,
		(row_number() over (order by coalesce(valor.orden, 999), valor.nombre))::integer
	from public.rasgo_valores valor
	where valor.rasgo_id = v_rasgo_id
		and valor.activo;
end;
$$;

-- Quintilla: la secuencia puede contener varias estrofas y cada una puede
-- realizar una tipología distinta. La unidad repetida sirve para localizar la
-- elección; numero_versos = 5 continúa siendo la única fuente de su tamaño.
do $$
declare
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_seccion_id uuid;
	v_grupo_id uuid;
	v_total_patrones integer;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'quintilla'
		and configuracion.slug = 'octosilabica_consonante';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración formalizada de la quintilla';
	end if;

	select patron_metrico_id into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id
	limit 1;

	select count(*) into v_total_patrones
	from public.patrones_rima
	where configuracion_id = v_configuracion_id
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

	if v_patron_metrico_id is null or v_total_patrones <> 8 then
		raise exception
			'La quintilla necesita un patrón métrico y ocho patrones de rima; se encontraron % patrones de rima',
			v_total_patrones;
	end if;

	select seccion_id into v_seccion_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id is null
		and tipo_seccion = 'quintilla';

	if v_seccion_id is null then
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
			nota
		)
		values (
			v_configuracion_id,
			'quintilla',
			'Quintilla',
			1,
			1,
			null,
			5,
			5,
			v_patron_metrico_id,
			'Unidad editorial repetida para registrar el esquema de cada estrofa dentro de una secuencia.'
		)
		returning seccion_id into v_seccion_id;
	else
		update public.estructuras_secciones
		set
			nombre = 'Quintilla',
			orden = 1,
			repeticiones_min = 1,
			repeticiones_max = null,
			versos_min = 5,
			versos_max = 5,
			patron_metrico_id = v_patron_metrico_id,
			nota = 'Unidad editorial repetida para registrar el esquema de cada estrofa dentro de una secuencia.'
		where seccion_id = v_seccion_id;
	end if;

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
		'esquema_rima',
		'¿Qué esquema de rima presenta esta quintilla?',
		'Se registra por estrofa. Puedes aplicar el mismo esquema a todas y corregir únicamente las que cambien.',
		'rima',
		'unidad',
		v_seccion_id,
		1,
		1,
		true,
		'revisada',
		1,
		true
	)
	on conflict (configuracion_id, slug) do update
	set
		nombre = excluded.nombre,
		ayuda_editor = excluded.ayuda_editor,
		dimension = excluded.dimension,
		alcance = excluded.alcance,
		seccion_id = excluded.seccion_id,
		selecciones_min = excluded.selecciones_min,
		selecciones_max = excluded.selecciones_max,
		permite_aplicar_global = excluded.permite_aplicar_global,
		estado_revision = excluded.estado_revision,
		orden = excluded.orden,
		activo = excluded.activo
	returning grupo_eleccion_id into v_grupo_id;

	delete from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo_id;
	delete from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		patron_rima_id,
		orden
	)
	select
		v_grupo_id,
		patron.esquema,
		patron.nombre,
		patron.descripcion,
		patron.patron_rima_id,
		case patron.esquema
			when 'ababa' then 1
			when 'abbab' then 2
			when 'abaab' then 3
			when 'aabab' then 4
			when 'aabba' then 5
			when 'abbaa' then 6
			when 'ababb' then 7
			when 'abbba' then 8
		end
	from public.patrones_rima patron
	where patron.configuracion_id = v_configuracion_id
		and patron.esquema in (
			'ababa',
			'abbab',
			'abaab',
			'aabab',
			'aabba',
			'abbaa',
			'ababb',
			'abbba'
		);
end;
$$;

-- Tercetos sin encadenar: los dos patrones son realizaciones alternativas de
-- una única configuración y se eligen una vez para la serie.
do $$
declare
	v_configuracion_id uuid;
	v_grupo_id uuid;
	v_total_patrones integer;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'tercetos_sin_encadenar'
		and configuracion.slug = 'endecasilabico_consonante';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración de tercetos sin encadenar';
	end if;

	select count(*) into v_total_patrones
	from public.patrones_rima
	where configuracion_id = v_configuracion_id
		and esquema in ('A-A | B-B | C-C | …', '-AA | -BB | -CC | …');

	if v_total_patrones <> 2 then
		raise exception
			'Se esperaban dos patrones de tercetos sin encadenar y se encontraron %',
			v_total_patrones;
	end if;

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
		'disposicion_rima',
		'¿Qué disposición de rima organiza los tercetos?',
		'Selecciona qué posición queda suelta en las unidades de la serie. Las rimas no enlazan entre tercetos.',
		'rima',
		'secuencia',
		1,
		1,
		'revisada',
		1,
		true
	)
	on conflict (configuracion_id, slug) do update
	set
		nombre = excluded.nombre,
		ayuda_editor = excluded.ayuda_editor,
		dimension = excluded.dimension,
		alcance = excluded.alcance,
		seccion_id = null,
		selecciones_min = excluded.selecciones_min,
		selecciones_max = excluded.selecciones_max,
		estado_revision = excluded.estado_revision,
		orden = excluded.orden,
		activo = excluded.activo
	returning grupo_eleccion_id into v_grupo_id;

	delete from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo_id;
	delete from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		patron_rima_id,
		orden
	)
	select
		v_grupo_id,
		case
			when patron.esquema like 'A-A%' then 'verso_central_suelto'
			else 'primer_verso_suelto'
		end,
		case
			when patron.esquema like 'A-A%' then 'A-A · verso central suelto'
			else '-AA · primer verso suelto'
		end,
		patron.descripcion,
		patron.patron_rima_id,
		case when patron.esquema like 'A-A%' then 1 else 2 end
	from public.patrones_rima patron
	where patron.configuracion_id = v_configuracion_id
		and patron.esquema in ('A-A | B-B | C-C | …', '-AA | -BB | -CC | …');
end;
$$;

-- El final esdrújulo se registra solo cuando caracteriza la realización. La
-- ausencia de respuesta significa que la secuencia cumple la norma no marcada.
do $$
declare
	v_rasgo_id uuid;
	v_valor_id uuid;
	v_configuracion record;
	v_grupo_id uuid;
begin
	select rasgo_id into v_rasgo_id
	from public.rasgos_metricos
	where slug = 'final_acentual';

	select valor_id into v_valor_id
	from public.rasgo_valores
	where rasgo_id = v_rasgo_id
		and slug = 'esdrujulo';

	if v_rasgo_id is null or v_valor_id is null then
		raise exception 'No se encontró final_acentual = esdrujulo';
	end if;

	for v_configuracion in
		select
			configuracion.configuracion_id,
			forma.slug as forma_slug,
			case when forma.slug = 'soneto' then 2 else 1 end as orden
		from public.configuraciones_forma configuracion
		join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
		where (
			forma.slug = 'soneto'
			and configuracion.slug = 'endecasilabo_consonante'
		) or (
			forma.slug = 'terceto'
			and configuracion.slug = 'endecasilabico_consonante'
		)
	loop
		insert into public.configuracion_rasgos (
			configuracion_id,
			rasgo_id,
			valor_id,
			modalidad,
			nota
		)
		values (
			v_configuracion.configuracion_id,
			v_rasgo_id,
			v_valor_id,
			'admitida',
			'Especialización transversal que solo se declara cuando caracteriza la secuencia.'
		)
		on conflict (configuracion_id, rasgo_id, modalidad) do update
		set
			valor_id = excluded.valor_id,
			valor_numero = null,
			valor_texto = null,
			nota = excluded.nota;

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
			v_configuracion.configuracion_id,
			'final_acentual_destacado',
			'¿Presenta un final acentual destacado?',
			'Déjalo sin marcar cuando no sea una característica de la secuencia.',
			'rasgo',
			'secuencia',
			0,
			1,
			'revisada',
			v_configuracion.orden,
			true
		)
		on conflict (configuracion_id, slug) do update
		set
			nombre = excluded.nombre,
			ayuda_editor = excluded.ayuda_editor,
			dimension = excluded.dimension,
			alcance = excluded.alcance,
			seccion_id = null,
			selecciones_min = excluded.selecciones_min,
			selecciones_max = excluded.selecciones_max,
			estado_revision = excluded.estado_revision,
			orden = excluded.orden,
			activo = excluded.activo
		returning grupo_eleccion_id into v_grupo_id;

		delete from public.elecciones_editor_metrico
		where grupo_eleccion_id = v_grupo_id;
		delete from public.opciones_eleccion_metrica
		where grupo_eleccion_id = v_grupo_id;

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id,
			slug,
			nombre,
			descripcion,
			valor_rasgo_id,
			orden
		)
		values (
			v_grupo_id,
			'esdrujulo',
			'Mayoría de finales esdrújulos',
			'Los finales esdrújulos caracterizan mayoritariamente la secuencia.',
			v_valor_id,
			1
		);
	end loop;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 18,
	actualizado_en = now()
where id = true;

commit;
