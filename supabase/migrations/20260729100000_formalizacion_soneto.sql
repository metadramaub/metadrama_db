begin;

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_metro_11_id uuid;
	v_consonante_id uuid;
	v_rasgo_final_id uuid;
	v_valor_esdrujulo_id uuid;
	v_termino_esdrujulo_id uuid;
	v_fuente_dominguez_id uuid;
	v_total integer;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'soneto';

	if v_forma_id is null then
		raise exception 'No se encontró la forma soneto en el catálogo métrico';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para soneto y se encontraron %',
			v_total;
	end if;

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id;

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

	if v_metro_11_id is null or v_consonante_id is null then
		raise exception 'Falta el metro endecasílabo o el tipo de rima consonante';
	end if;

	update public.formas_metricas
	set
		nombre = 'Soneto',
		definicion = 'Composición fija de catorce versos endecasílabos con rima consonante, organizada en dos cuartetos de rima abrazada ABBA ABBA y dos tercetos finales de disposición variable. El catálogo reconoce actualmente cuatro esquemas para los tercetos.',
		nivel_estructural = 'composicion',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		slug = 'endecasilabo_consonante',
		nombre = 'Soneto endecasílabo consonante',
		descripcion = 'Configuración de catorce endecasílabos: dos cuartetos ABBA ABBA y dos tercetos cuyo esquema se elige entre los patrones reconocidos.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_consonante_id,
		numero_versos = 14,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_id;

	select count(*) into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	if v_total = 0 then
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
			'Endecasílabo en las catorce posiciones',
			'composicion',
			'secuencia_repetible',
			'El mismo modelo endecasílabo se aplica a los catorce versos fijados por la configuración.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;
	elsif v_total = 1 then
		select patron_metrico_id into v_patron_metrico_id
		from public.patrones_metricos
		where configuracion_id = v_configuracion_id;

		update public.patrones_metricos
		set
			nombre = 'Endecasílabo en las catorce posiciones',
			ambito = 'composicion',
			tipo = 'secuencia_repetible',
			descripcion = 'El mismo modelo endecasílabo se aplica a los catorce versos fijados por la configuración.',
			estado_revision = 'revisada'
		where patron_metrico_id = v_patron_metrico_id;
	else
		raise exception
			'La configuración del soneto tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	delete from public.patron_metrico_opciones
	where patron_metrico_id = v_patron_metrico_id;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_id;

	insert into public.patron_metrico_posiciones (
		patron_metrico_id,
		posicion,
		metro_id,
		opcional,
		alternativa,
		nota
	)
	values (
		v_patron_metrico_id,
		1,
		v_metro_11_id,
		false,
		1,
		'Este modelo se repite en los catorce versos de la composición.'
	);

	select count(*) into v_total
	from public.patrones_rima patron
	join public.vocabularios termino
		on termino.termino_id = patron.origen_termino_id
	where patron.configuracion_id = v_configuracion_id
		and termino.termino in (
			'soneto_regular_ABBAABBACDCDCD',
			'soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE',
			'soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE',
			'soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE'
		);

	if v_total <> 4 then
		raise exception
			'Se esperaban cuatro patrones de rima heredados del soneto y se encontraron %',
			v_total;
	end if;

	update public.patrones_rima patron
	set
		nombre = case termino.termino
			when 'soneto_regular_ABBAABBACDCDCD'
				then 'Tercetos de rima cruzada (CDCDCD)'
			when 'soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE'
				then 'Tercetos de rima paralela (CDECDE)'
			when 'soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE'
				then 'Tercetos de rima conclusiva (CDEDCE)'
			when 'soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE'
				then 'Tercetos de rima nuclear (CDCEDE)'
		end,
		esquema = case termino.termino
			when 'soneto_regular_ABBAABBACDCDCD' then 'ABBAABBACDCDCD'
			when 'soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE'
				then 'ABBAABBACDECDE'
			when 'soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE'
				then 'ABBAABBACDEDCE'
			when 'soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE'
				then 'ABBAABBACDCEDE'
		end,
		tipo_rima_id = v_consonante_id,
		ambito = 'composicion',
		comportamiento = 'secuencia_fija',
		fijeza = case
			when termino.termino = 'soneto_regular_ABBAABBACDCDCD'
				then 'preferente'
			else 'admitido'
		end,
		descripcion = case termino.termino
			when 'soneto_regular_ABBAABBACDCDCD'
				then 'Dos cuartetos ABBA ABBA y dos tercetos con alternancia CDCDCD. Se conserva como patrón preferente por su denominación heredada «regular».'
			when 'soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE'
				then 'Dos cuartetos ABBA ABBA y dos tercetos de rima paralela CDE CDE.'
			when 'soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE'
				then 'Dos cuartetos ABBA ABBA y dos tercetos de rima conclusiva CDE DCE.'
			when 'soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE'
				then 'Dos cuartetos ABBA ABBA y dos tercetos de rima nuclear CDC EDE.'
		end,
		estado_revision = 'revisada'
	from public.vocabularios termino
	where patron.origen_termino_id = termino.termino_id
		and patron.configuracion_id = v_configuracion_id
		and termino.termino in (
			'soneto_regular_ABBAABBACDCDCD',
			'soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE',
			'soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE',
			'soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE'
		);

	delete from public.patron_rima_enlaces enlace
	using public.patrones_rima patron
	where enlace.patron_rima_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;

	delete from public.patron_rima_restricciones restriccion
	using public.patrones_rima patron
	where restriccion.patron_rima_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;

	delete from public.patron_rima_posiciones posicion
	using public.patrones_rima patron
	where posicion.patron_rima_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;

	insert into public.patron_rima_posiciones (
		patron_rima_id,
		bloque,
		seccion,
		posicion,
		ubicacion,
		clase_rima,
		suelto,
		opcional,
		nota
	)
	select
		patron.patron_rima_id,
		case
			when serie.posicion_global <= 4 then 1
			when serie.posicion_global <= 8 then 2
			when serie.posicion_global <= 11 then 3
			else 4
		end,
		case
			when serie.posicion_global <= 4 then 'cuarteto_1'
			when serie.posicion_global <= 8 then 'cuarteto_2'
			when serie.posicion_global <= 11 then 'terceto_1'
			else 'terceto_2'
		end,
		case
			when serie.posicion_global <= 4 then serie.posicion_global
			when serie.posicion_global <= 8 then serie.posicion_global - 4
			when serie.posicion_global <= 11 then serie.posicion_global - 8
			else serie.posicion_global - 11
		end,
		'final',
		substring(patron.esquema from serie.posicion_global for 1),
		false,
		false,
		concat('Posición ', serie.posicion_global, ' de la composición.')
	from public.patrones_rima patron
	cross join generate_series(1, 14) as serie(posicion_global)
	where patron.configuracion_id = v_configuracion_id
		and patron.origen_termino_id is not null;

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

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
	values
		(
			v_configuracion_id,
			'cuarteto',
			'Cuartetos',
			1,
			2,
			2,
			4,
			4,
			'Dos cuartetos iniciales con rima abrazada ABBA ABBA.'
		),
		(
			v_configuracion_id,
			'terceto',
			'Tercetos',
			2,
			2,
			2,
			3,
			3,
			'Dos tercetos finales cuya distribución de rima depende del patrón elegido.'
		);

	select rasgo_id into v_rasgo_final_id
	from public.rasgos_metricos
	where slug = 'final_acentual';

	select valor.valor_id into v_valor_esdrujulo_id
	from public.rasgo_valores valor
	join public.rasgos_metricos rasgo on rasgo.rasgo_id = valor.rasgo_id
	where rasgo.slug = 'final_acentual'
		and valor.slug = 'esdrujulo';

	select termino_id into v_termino_esdrujulo_id
	from public.vocabularios
	where categoria = 'estrofa_tipo'
		and termino = 'soneto_de_esdrújulos';

	if v_rasgo_final_id is null
		or v_valor_esdrujulo_id is null
		or v_termino_esdrujulo_id is null
	then
		raise exception
			'No se encontró el rasgo final_acentual, el valor esdrujulo o su término heredado';
	end if;

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
		'Especialización transversal heredada de soneto_de_esdrújulos. Solo se declara en la secuencia cuando resulta caracterizadora.'
	)
	on conflict (configuracion_id, rasgo_id, modalidad) do update
	set
		valor_id = excluded.valor_id,
		nota = excluded.nota;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = case
			when termino.termino = 'soneto' then 'F'
			when termino.termino = 'soneto_de_esdrújulos' then 'R'
			else 'P'
		end,
		propuesta = case
			when termino.termino = 'soneto'
				then 'Conservar como composición fija de catorce endecasílabos.'
			when termino.termino = 'soneto_de_esdrújulos'
				then 'Transformar en el rasgo transversal final_acentual = esdrujulo.'
			else 'Transformar en patrón de rima admitido de la configuración endecasílaba.'
		end,
		certeza = 'alta',
		requiere_revision = false
	from public.vocabularios termino
	where migracion.termino_id = termino.termino_id
		and (
			termino.termino = 'soneto'
			or termino.termino like 'soneto_%'
		);

	select fuente_id into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
		raise exception
			'No se encontró la fuente Métrica española de Domínguez Caparrós (2014)';
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and forma_id = v_forma_id
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
			v_fuente_dominguez_id,
			v_forma_id,
			'pp. 218-221',
			'Define el soneto clásico como composición de catorce endecasílabos con rima consonante: ocho versos iniciales, normalmente ABBA ABBA, y seis finales con dos o tres rimas de distribución variable. Documenta asimismo variantes históricas que METADRAMA no incorpora automáticamente.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 13,
	actualizado_en = now()
where id = true;

commit;
