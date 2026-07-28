begin;

update public.catalogo_metrico_estado
set modelo_version = 4
where id;

do $$
declare
	v_forma_quintilla_id uuid;
	v_configuracion_quintilla_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_general_id uuid;
	v_metro_octosilabo_id uuid;
	v_tipo_consonante_id uuid;
	v_fuente_dominguez_id uuid;
	v_forma_romance_id uuid;
	v_patron_rima_romance_id uuid;
	v_total integer;
begin
	select forma_id
	into v_forma_quintilla_id
	from public.formas_metricas
	where slug = 'quintilla';

	if v_forma_quintilla_id is null then
		raise exception 'No se encontró la forma quintilla en el catálogo métrico';
	end if;

	select count(*)
	into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_quintilla_id;

	if v_total <> 1 then
		raise exception
			'Se esperaba una única configuración importada para quintilla y se encontraron %',
			v_total;
	end if;

	select configuracion_id
	into v_configuracion_quintilla_id
	from public.configuraciones_forma
	where forma_id = v_forma_quintilla_id;

	select count(*)
	into v_total
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único metro octosílabo activo y se encontraron %',
			v_total;
	end if;

	select termino_id
	into v_metro_octosilabo_id
	from public.vocabularios
	where categoria = 'metro'
		and activo
		and termino = 'octosilabo'
		and numero_silabas = 8;

	select count(*)
	into v_total
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	if v_total <> 1 then
		raise exception
			'Se esperaba un único tipo de rima consonante activo y se encontraron %',
			v_total;
	end if;

	select termino_id
	into v_tipo_consonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'consonante';

	update public.formas_metricas
	set
		nombre = 'Quintilla',
		definicion = 'Estrofa de cinco versos octosílabos con rima consonante distribuida en dos clases. El catálogo aurisecular conserva ocho tipologías de rima fijadas por el IP: siete ordinarias y la excepción documentada abbba.',
		nivel_estructural = 'estrofa',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_quintilla_id;

	update public.configuraciones_forma
	set
		slug = 'octosilabica_consonante',
		nombre = 'Quintilla octosilábica consonante',
		descripcion = 'Cinco versos octosílabos y dos clases de rima consonante. Las ocho distribuciones reconocidas se registran como patrones alternativos de esta configuración, no como formas ni configuraciones independientes.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_consonante_id,
		versos_min = 5,
		versos_max = 5,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_quintilla_id;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_quintilla_id;

	if v_total <> 1 then
		raise exception
			'La configuración de quintilla tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	select patron_metrico_id
	into v_patron_metrico_id
	from public.patrones_metricos
	where configuracion_id = v_configuracion_quintilla_id;

	update public.patrones_metricos
	set
		nombre = 'Cinco octosílabos',
		ambito = 'estrofa',
		tipo = 'secuencia_fija',
		longitud_minima = 5,
		longitud_maxima = 5,
		descripcion = 'Una posición octosilábica por cada uno de los cinco versos de la estrofa.',
		estado_revision = 'revisada'
	where patron_metrico_id = v_patron_metrico_id;

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
	select
		v_patron_metrico_id,
		posicion,
		v_metro_octosilabo_id,
		false,
		1,
		'Posición octosilábica fija de la quintilla.'
	from generate_series(1, 5) as posiciones(posicion);

	select count(*)
	into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_quintilla_id
		and origen_termino_id is null;

	if v_total <> 1 then
		raise exception
			'Se esperaba un único patrón general importado para quintilla y se encontraron %',
			v_total;
	end if;

	select patron_rima_id
	into v_patron_rima_general_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_quintilla_id
		and origen_termino_id is null;

	update public.patrones_rima
	set
		nombre = 'Criterio general del catálogo',
		esquema = null,
		tipo_rima_id = v_tipo_consonante_id,
		ambito = 'estrofa',
		comportamiento = 'restricciones',
		fijeza = 'preferente',
		descripcion = 'Las tipologías del IP emplean dos clases consonantes y no dejan versos sueltos. Como regla ordinaria no acumulan más de dos versos con la misma rima; abbba se conserva como excepción documentada. El catálogo aurisecular sí admite pareado final.',
		estado_revision = 'revisada'
	where patron_rima_id = v_patron_rima_general_id;

	delete from public.patron_rima_posiciones
	where patron_rima_id = v_patron_rima_general_id;

	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_rima_general_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_rima_general_id;

	insert into public.patron_rima_restricciones (
		patron_rima_id,
		tipo,
		valor_numero,
		valor_texto,
		descripcion,
		obligatoria
	)
	values
		(
			v_patron_rima_general_id,
			'numero_clases',
			2,
			null,
			'Las ocho tipologías distinguen dos clases de rima.',
			true
		),
		(
			v_patron_rima_general_id,
			'versos_sueltos',
			null,
			'ninguno',
			'Ninguna de las tipologías deja un verso suelto.',
			true
		),
		(
			v_patron_rima_general_id,
			'max_consecutivos',
			2,
			null,
			'Regla ordinaria del catálogo; la tipología abbba constituye la excepción explícita.',
			false
		);

	select count(*)
	into v_total
	from public.patrones_rima pr
	join public.vocabularios v on v.termino_id = pr.origen_termino_id
	where pr.configuracion_id = v_configuracion_quintilla_id
		and v.termino in (
			'quintilla_1_ababa',
			'quintilla_2_abbab',
			'quintilla_3_abaab',
			'quintilla_4_aabab',
			'quintilla_5_aabba',
			'quintilla_6_abbaa',
			'quintilla_7_ababb',
			'quintilla_8_abbba'
		);

	if v_total <> 8 then
		raise exception
			'Se esperaban ocho patrones importados de quintilla y se encontraron %',
			v_total;
	end if;

	with tipologias(termino, numero, esquema, excepcion) as (
		values
			('quintilla_1_ababa', 1, 'ababa', false),
			('quintilla_2_abbab', 2, 'abbab', false),
			('quintilla_3_abaab', 3, 'abaab', false),
			('quintilla_4_aabab', 4, 'aabab', false),
			('quintilla_5_aabba', 5, 'aabba', false),
			('quintilla_6_abbaa', 6, 'abbaa', false),
			('quintilla_7_ababb', 7, 'ababb', false),
			('quintilla_8_abbba', 8, 'abbba', true)
	)
	update public.patrones_rima pr
	set
		nombre = format('Tipología %s (%s)', t.numero, t.esquema),
		esquema = t.esquema,
		tipo_rima_id = v_tipo_consonante_id,
		ambito = 'estrofa',
		comportamiento = 'secuencia_fija',
		fijeza = 'admitido',
		descripcion = case
			when t.excepcion
				then 'Tipología excepcional documentada por el IP: presenta tres versos consecutivos con la misma rima.'
			else 'Tipología ordinaria del catálogo aurisecular fijada por el IP.'
		end,
		estado_revision = 'revisada'
	from public.vocabularios v
	join tipologias t on t.termino = v.termino
	where pr.origen_termino_id = v.termino_id
		and pr.configuracion_id = v_configuracion_quintilla_id;

	delete from public.patron_rima_restricciones r
	using public.patrones_rima pr
	join public.vocabularios v on v.termino_id = pr.origen_termino_id
	where r.patron_rima_id = pr.patron_rima_id
		and pr.configuracion_id = v_configuracion_quintilla_id
		and v.termino like 'quintilla\_%' escape '\';

	delete from public.patron_rima_enlaces e
	using public.patrones_rima pr
	join public.vocabularios v on v.termino_id = pr.origen_termino_id
	where e.patron_rima_id = pr.patron_rima_id
		and pr.configuracion_id = v_configuracion_quintilla_id
		and v.termino like 'quintilla\_%' escape '\';

	delete from public.patron_rima_posiciones p
	using public.patrones_rima pr
	join public.vocabularios v on v.termino_id = pr.origen_termino_id
	where p.patron_rima_id = pr.patron_rima_id
		and pr.configuracion_id = v_configuracion_quintilla_id
		and v.termino like 'quintilla\_%' escape '\';

	with tipologias(termino, esquema) as (
		values
			('quintilla_1_ababa', 'ababa'),
			('quintilla_2_abbab', 'abbab'),
			('quintilla_3_abaab', 'abaab'),
			('quintilla_4_aabab', 'aabab'),
			('quintilla_5_aabba', 'aabba'),
			('quintilla_6_abbaa', 'abbaa'),
			('quintilla_7_ababb', 'ababb'),
			('quintilla_8_abbba', 'abbba')
	)
	insert into public.patron_rima_posiciones (
		patron_rima_id,
		bloque,
		posicion,
		ubicacion,
		clase_rima,
		suelto,
		opcional,
		nota
	)
	select
		pr.patron_rima_id,
		1,
		posicion,
		'final',
		substring(t.esquema from posicion for 1),
		false,
		false,
		'Posición de la tipología de quintilla fijada por el IP.'
	from tipologias t
	join public.vocabularios v on v.termino = t.termino
	join public.patrones_rima pr on pr.origen_termino_id = v.termino_id
	cross join generate_series(1, 5) as posiciones(posicion);

	-- La fuente audiovisual usada en la primera prueba del romance era
	-- provisional. Se elimina junto con sus afirmaciones mediante la cascada.
	delete from public.fuentes_metricas
	where url = 'https://canal.uned.es/video/5c51a2f2b1111f890c8b457c';

	select fuente_id
	into v_fuente_dominguez_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_fuente_dominguez_id is null then
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
			'José Domínguez Caparrós',
			'Métrica española',
			2014,
			'Madrid: Universidad Nacional de Educación a Distancia',
			'Domínguez Caparrós, José. Métrica española. Nueva edición corregida y aumentada. Madrid: UNED, 2014.',
			'Fuente bibliográfica general. Sus normas se registran como contraste histórico y teórico; no sustituyen el criterio especializado del IP para el corpus aurisecular.'
		)
		returning fuente_id into v_fuente_dominguez_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_dominguez_id
			and forma_id = v_forma_quintilla_id
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
			v_forma_quintilla_id,
			'pp. 188 y 195',
			'Describe la quintilla general como cinco versos octosílabos o menores con dos rimas consonantes; prescribe un máximo de dos rimas consecutivas, ningún verso suelto y ausencia de pareado final. Advierte además que en el Siglo de Oro redondilla podía designar estrofas de cinco versos y otras combinaciones de arte menor. El catálogo del proyecto conserva el criterio específico del IP cuando difiere de esta norma general.',
			'alta',
			'revisada'
		);
	end if;

	select forma_id
	into v_forma_romance_id
	from public.formas_metricas
	where slug = 'romance';

	if v_forma_romance_id is not null then
		select pr.patron_rima_id
		into v_patron_rima_romance_id
		from public.patrones_rima pr
		join public.configuraciones_forma c on c.configuracion_id = pr.configuracion_id
		where c.forma_id = v_forma_romance_id
			and pr.comportamiento = 'secuencia_repetible'
		order by pr.updated_at desc
		limit 1;

		if not exists (
			select 1
			from public.afirmaciones_fuentes_metricas
			where fuente_id = v_fuente_dominguez_id
				and forma_id = v_forma_romance_id
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
				v_forma_romance_id,
				'p. 223',
				'Define el romance como una serie de extensión indeterminada de octosílabos, con una misma rima asonante en los versos pares y los impares sueltos.',
				'alta',
				'revisada'
			);
		end if;

		if v_patron_rima_romance_id is not null
			and not exists (
				select 1
				from public.afirmaciones_fuentes_metricas
				where fuente_id = v_fuente_dominguez_id
					and patron_rima_id = v_patron_rima_romance_id
			)
		then
			insert into public.afirmaciones_fuentes_metricas (
				fuente_id,
				patron_rima_id,
				localizador,
				resumen,
				confianza,
				estado_revision
			)
			values (
				v_fuente_dominguez_id,
				v_patron_rima_romance_id,
				'p. 223',
				'Los versos pares comparten una misma asonancia y los impares quedan sueltos.',
				'alta',
				'revisada'
			);
		end if;
	end if;
end;
$$;

commit;
