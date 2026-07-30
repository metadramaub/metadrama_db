begin;

do $$
declare
	v_termino_raiz_id uuid := '07176066-61f6-4b5c-a118-2ae49de4562a'::uuid;
	v_termino_heptasilabo_id uuid := '07d78e10-159e-4a29-837b-4bf46015d9cb'::uuid;
	v_termino_hexasilabo_id uuid := '5c86e84e-b988-4c00-8b92-d8ba80c04e65'::uuid;
	v_forma_romance_id uuid;
	v_config_heroica_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_id uuid;
	v_asonante_id uuid;
	v_rasgo_asonancia_id uuid;
	v_grupo_id uuid;
	v_fuente_id uuid;
	v_total integer;
	v_variante record;
begin
	select forma_id into v_forma_romance_id
	from public.formas_metricas
	where slug = 'romance';

	select configuracion_id into v_config_heroica_id
	from public.configuraciones_forma
	where forma_id = v_forma_romance_id
		and slug = 'endecasilabico_heroico';

	select termino_id into v_asonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'asonante'
	limit 1;

	select rasgo_id into v_rasgo_asonancia_id
	from public.rasgos_metricos
	where slug = 'vocales_asonancia';

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_forma_romance_id is null
		or v_config_heroica_id is null
		or v_asonante_id is null
		or v_rasgo_asonancia_id is null
		or v_fuente_id is null
	then
		raise exception
			'Falta Romance, su configuración heroica, la rima asonante, el rasgo vocales_asonancia o la fuente bibliográfica';
	end if;

	if not exists (
		select 1
		from public.formas_metricas
		where forma_id = v_termino_raiz_id
			and slug = 'romancillo'
	) then
		raise exception 'No se encontró la forma importada romancillo';
	end if;

	select count(*) into v_total
	from public.configuraciones_forma
	where forma_id = v_termino_raiz_id;

	if v_total <> 3 then
		raise exception
			'Se esperaban tres configuraciones importadas de romancillo y se encontraron %',
			v_total;
	end if;

	if not exists (
		select 1
		from public.configuraciones_forma
		where forma_id = v_termino_raiz_id
			and origen_termino_id = v_termino_heptasilabo_id
	) or not exists (
		select 1
		from public.configuraciones_forma
		where forma_id = v_termino_raiz_id
			and origen_termino_id = v_termino_hexasilabo_id
	) then
		raise exception 'No se encontraron las configuraciones importadas hexasílaba y heptasílaba';
	end if;

	delete from public.migracion_termino_destinos
	where termino_id in (
		v_termino_raiz_id,
		v_termino_heptasilabo_id,
		v_termino_hexasilabo_id
	);

	-- La antigua raíz mezcla dos medidas. Se retira como entidad duplicada, pero
	-- su término permanece en la matriz para revisar las secuencias que solo
	-- declaren esa raíz cuando llegue la migración de los datos editoriales.
	delete from public.formas_metricas
	where forma_id = v_termino_raiz_id;

	update public.formas_metricas
	set
		definicion = 'Serie indefinida de versos isométricos en la que los versos pares comparten una misma rima asonante y los impares quedan sueltos. El catálogo distingue configuraciones exactas de seis, siete, ocho y once sílabas.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_romance_id;

	update public.configuraciones_forma
	set
		orden = 4,
		updated_at = now()
	where configuracion_id = v_config_heroica_id;

	for v_variante in
		select *
		from (
			values
				(
					v_termino_hexasilabo_id,
					'hexasilabico_romancillo'::text,
					'Romancillo hexasílabo'::text,
					6,
					2,
					'p. 227'::text,
					'Denomina romancillo al romance compuesto en versos de menos de siete sílabas; esta configuración concreta la realización hexasílaba reconocida por el proyecto.'::text
				),
				(
					v_termino_heptasilabo_id,
					'heptasilabico_romancillo'::text,
					'Romancillo heptasílabo'::text,
					7,
					3,
					'p. 226'::text,
					'Denomina endecha al romance compuesto en versos de siete sílabas; el proyecto conserva Romancillo heptasílabo como nombre preferente y registra Endecha como denominación equivalente.'::text
				)
		) as variante(
			termino_id,
			slug,
			nombre,
			silabas,
			orden,
			localizador,
			resumen_fuente
		)
	loop
		select termino_id into v_metro_id
		from public.vocabularios
		where categoria = 'metro'
			and activo
			and numero_silabas = v_variante.silabas
		order by created_at
		limit 1;

		if v_metro_id is null then
			raise exception 'No se encontró el metro de % sílabas', v_variante.silabas;
		end if;

		insert into public.configuraciones_forma (
			forma_id,
			slug,
			nombre,
			descripcion,
			principal,
			demarcable,
			grado,
			tipo_rima_id,
			numero_versos,
			estado_revision,
			activo,
			orden,
			origen_termino_id
		)
		values (
			v_forma_romance_id,
			v_variante.slug,
			v_variante.nombre,
			format(
				'Serie abierta de versos de %s sílabas, con una misma asonancia en los versos pares y versos impares sueltos.',
				v_variante.silabas
			),
			false,
			true,
			'canonica',
			v_asonante_id,
			null,
			'revisada',
			true,
			v_variante.orden,
			v_variante.termino_id
		)
		returning configuracion_id into v_configuracion_id;

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
			format('%s repetido', initcap(v_variante.nombre)),
			'serie',
			'secuencia_repetible',
			format(
				'Un verso de %s sílabas por cada posición del ciclo, repetido durante toda la serie.',
				v_variante.silabas
			),
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;

		insert into public.patron_metrico_posiciones (
			patron_metrico_id,
			posicion,
			metro_id,
			opcional,
			grupo_repeticion,
			alternativa,
			nota
		)
		values (
			v_patron_metrico_id,
			1,
			v_metro_id,
			false,
			'todos_los_versos',
			1,
			'El ciclo métrico de un solo verso se repite durante toda la serie.'
		);

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
			'Asonancia en los versos pares',
			'-a-a-a…',
			v_asonante_id,
			'serie',
			'secuencia_repetible',
			'fijo',
			'Ciclo de dos versos: el impar queda suelto y el par mantiene la misma clase de asonancia durante toda la serie.',
			'revisada'
		)
		returning patron_rima_id into v_patron_rima_id;

		delete from public.patron_rima_posiciones
		where patron_rima_id = v_patron_rima_id;

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
		values
			(
				v_patron_rima_id,
				1,
				1,
				'final',
				null,
				true,
				false,
				'Verso impar suelto.'
			),
			(
				v_patron_rima_id,
				1,
				2,
				'final',
				'a',
				false,
				false,
				'Verso par con la misma asonancia en cada repetición del ciclo.'
			);

		insert into public.configuracion_rasgos (
			configuracion_id,
			rasgo_id,
			modalidad,
			nota
		)
		values (
			v_configuracion_id,
			v_rasgo_asonancia_id,
			'admitida',
			'La realización concreta declara las vocales de la asonancia sin crear una configuración distinta.'
		);

		insert into public.grupos_eleccion_metrica (
			configuracion_id,
			slug,
			nombre,
			ayuda_editor,
			dimension,
			alcance,
			selecciones_min,
			selecciones_max,
			permite_aplicar_global,
			tipo_control,
			estado_revision,
			activo,
			orden
		)
		values (
			v_configuracion_id,
			'vocales_asonancia',
			'¿Qué vocales caracterizan la asonancia?',
			'Selecciona las vocales que comparten los versos pares.',
			'rasgo',
			'secuencia',
			1,
			1,
			false,
			'opciones',
			'revisada',
			true,
			1
		)
		returning grupo_eleccion_id into v_grupo_id;

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
			valor.orden
		from public.rasgo_valores valor
		where valor.rasgo_id = v_rasgo_asonancia_id
			and valor.activo
		order by valor.orden, valor.nombre;

		insert into public.denominaciones_metricas (
			configuracion_id,
			nombre,
			slug_normalizado,
			tipo_alias,
			idioma,
			preferente
		)
		values
			(
				v_configuracion_id,
				'Endecha',
				'endecha',
				'equivalente',
				'es',
				false
			),
			(
				v_configuracion_id,
				'Romance endecha',
				'romance_endecha',
				'equivalente',
				'es',
				false
			);

		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			configuracion_id,
			localizador,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_id,
			v_configuracion_id,
			v_variante.localizador,
			v_variante.resumen_fuente,
			'alta',
			'revisada'
		);

		update public.migracion_terminos_metricos
		set
			clasificacion_decidida = 'C',
			propuesta = format(
				'Transformar en la configuración %s de Romance.',
				v_variante.nombre
			),
			certeza = 'alta',
			requiere_revision = false,
			estado_revision = 'revisada',
			updated_at = now()
		where termino_id = v_variante.termino_id;

		insert into public.migracion_termino_destinos (
			termino_id,
			tipo_operacion,
			configuracion_id,
			nota
		)
		values (
			v_variante.termino_id,
			'transformar',
			v_configuracion_id,
			format(
				'La futura migración conserva la clasificación mediante Romance + configuración %s.',
				v_variante.nombre
			)
		);
	end loop;

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'D',
		propuesta = 'Retirar como forma autónoma. Su significado es ambiguo entre las configuraciones hexasílaba y heptasílaba de Romance.',
		certeza = 'alta',
		requiere_revision = true,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_termino_raiz_id;

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		configuracion_id,
		nota
	)
	select
		v_termino_raiz_id,
		'revisar',
		configuracion_id,
		'Una secuencia antigua declarada solo como Romancillo necesita determinar su medida antes de asignar esta configuración.'
	from public.configuraciones_forma
	where forma_id = v_forma_romance_id
		and slug in ('hexasilabico_romancillo', 'heptasilabico_romancillo');
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 41,
	actualizado_en = now()
where id = true;

commit;
