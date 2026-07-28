begin;

alter table public.catalogo_metrico_estado
	add column modelo_version integer not null default 1;

update public.catalogo_metrico_estado
set modelo_version = 2
where id;

-- Separa la lógica de distribución de la rima de su grado de obligatoriedad.
-- `pendiente_revision` solo sirve para conservar sin inventar los patrones
-- importados que todavía no tienen posiciones o restricciones formalizadas.
alter table public.patrones_rima
	add column comportamiento text null;

update public.patrones_rima pr
set comportamiento = case
	when pr.fijeza = 'libre' then 'libre'
	when exists (
		select 1
		from public.patron_rima_restricciones r
		where r.patron_rima_id = pr.patron_rima_id
	) then 'restricciones'
	when nullif(btrim(pr.esquema), '') is not null then 'secuencia_fija'
	else 'pendiente_revision'
end;

alter table public.patrones_rima
	alter column comportamiento set default 'secuencia_fija',
	alter column comportamiento set not null,
	add constraint patrones_rima_comportamiento_check
		check (
			comportamiento in (
				'secuencia_fija',
				'secuencia_repetible',
				'restricciones',
				'libre',
				'pendiente_revision'
			)
		);

comment on column public.patrones_rima.comportamiento is
	'Forma computable de la distribución: secuencia fija, ciclo repetible, restricciones combinatorias o distribución libre. pendiente_revision solo conserva importaciones aún no formalizadas.';

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_metrico_id uuid;
	v_patron_rima_id uuid;
	v_metro_octosilabo_id uuid;
	v_tipo_asonante_id uuid;
	v_fuente_id uuid;
	v_total integer;
begin
	select forma_id
	into v_forma_id
	from public.formas_metricas
	where slug = 'romance';

	if v_forma_id is null then
		raise exception 'No se encontró la forma romance en el catálogo métrico';
	end if;

	select count(*)
	into v_total
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'principal';

	if v_total <> 1 then
		raise exception
			'Se esperaba una configuración principal importada para romance y se encontraron %',
			v_total;
	end if;

	select configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'principal';

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
		and termino = 'asonante';

	if v_total <> 1 then
		raise exception
			'Se esperaba un único tipo de rima asonante activo y se encontraron %',
			v_total;
	end if;

	select termino_id
	into v_tipo_asonante_id
	from public.vocabularios
	where categoria = 'tipo_rima'
		and activo
		and termino = 'asonante';

	update public.formas_metricas
	set
		nombre = 'Romance',
		definicion = 'Serie indefinida de versos octosílabos en la que los versos pares comparten una misma rima asonante y los impares quedan sueltos.',
		nivel_estructural = 'serie',
		seleccionable = true,
		residual = false,
		estado_revision = 'revisada',
		activo = true
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		nombre = 'Romance octosilábico asonante',
		descripcion = 'Configuración canónica del romance: serie abierta de octosílabos, con una misma asonancia en los versos pares y versos impares sueltos.',
		principal = true,
		demarcable = true,
		grado = 'canonica',
		tipo_rima_id = v_tipo_asonante_id,
		versos_min = null,
		versos_max = null,
		estado_revision = 'revisada',
		activo = true
	where configuracion_id = v_configuracion_id;

	select count(*)
	into v_total
	from public.patrones_metricos
	where configuracion_id = v_configuracion_id;

	if v_total = 0 then
		insert into public.patrones_metricos (
			configuracion_id,
			ambito,
			tipo,
			descripcion,
			estado_revision
		)
		values (
			v_configuracion_id,
			'serie',
			'secuencia_repetible',
			'Un verso octosílabo por cada posición del ciclo, repetido durante toda la serie.',
			'revisada'
		)
		returning patron_metrico_id into v_patron_metrico_id;
	elsif v_total = 1 then
		select patron_metrico_id
		into v_patron_metrico_id
		from public.patrones_metricos
		where configuracion_id = v_configuracion_id;

		update public.patrones_metricos
		set
			ambito = 'serie',
			tipo = 'secuencia_repetible',
			longitud_minima = null,
			longitud_maxima = null,
			descripcion = 'Un verso octosílabo por cada posición del ciclo, repetido durante toda la serie.',
			estado_revision = 'revisada'
		where patron_metrico_id = v_patron_metrico_id;
	else
		raise exception
			'La configuración del romance tiene % patrones métricos; deben revisarse antes de normalizarla',
			v_total;
	end if;

	delete from public.patron_metrico_posiciones
	where patron_metrico_id = v_patron_metrico_id;

	delete from public.patron_metrico_opciones
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
		v_metro_octosilabo_id,
		false,
		1,
		'El ciclo métrico de un solo verso se repite durante toda la serie.'
	);

	select count(*)
	into v_total
	from public.patrones_rima
	where configuracion_id = v_configuracion_id;

	if v_total = 0 then
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
			v_tipo_asonante_id,
			'serie',
			'secuencia_repetible',
			'fijo',
			'Ciclo de dos versos: el impar queda suelto y el par mantiene la misma clase de asonancia durante toda la serie.',
			'revisada'
		)
		returning patron_rima_id into v_patron_rima_id;
	elsif v_total = 1 then
		select patron_rima_id
		into v_patron_rima_id
		from public.patrones_rima
		where configuracion_id = v_configuracion_id;

		update public.patrones_rima
		set
			nombre = 'Asonancia en los versos pares',
			esquema = '-a-a-a…',
			tipo_rima_id = v_tipo_asonante_id,
			ambito = 'serie',
			comportamiento = 'secuencia_repetible',
			fijeza = 'fijo',
			descripcion = 'Ciclo de dos versos: el impar queda suelto y el par mantiene la misma clase de asonancia durante toda la serie.',
			estado_revision = 'revisada'
		where patron_rima_id = v_patron_rima_id;
	else
		raise exception
			'La configuración del romance tiene % patrones de rima; deben revisarse antes de normalizarla',
			v_total;
	end if;

	delete from public.patron_rima_enlaces
	where patron_rima_id = v_patron_rima_id;

	delete from public.patron_rima_restricciones
	where patron_rima_id = v_patron_rima_id;

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

	select fuente_id
	into v_fuente_id
	from public.fuentes_metricas
	where url = 'https://canal.uned.es/video/5c51a2f2b1111f890c8b457c'
	limit 1;

	if v_fuente_id is null then
		insert into public.fuentes_metricas (
			tipo,
			autoria,
			titulo,
			anio,
			publicacion,
			url,
			nota
		)
		values (
			'vídeo divulgativo',
			'Clara Isabel Martínez Cantón',
			'¿Qué es un romance?',
			2019,
			'Canal UNED',
			'https://canal.uned.es/video/5c51a2f2b1111f890c8b457c',
			'Fuente institucional utilizada para la primera formalización revisada del romance.'
		)
		returning fuente_id into v_fuente_id;
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_id
			and forma_id = v_forma_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			forma_id,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_id,
			v_forma_id,
			'El romance es una serie de extensión indefinida, normalmente octosilábica, con una misma rima asonante en los versos pares y versos impares sueltos.',
			'alta',
			'revisada'
		);
	end if;

	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where fuente_id = v_fuente_id
			and patron_rima_id = v_patron_rima_id
	) then
		insert into public.afirmaciones_fuentes_metricas (
			fuente_id,
			patron_rima_id,
			resumen,
			confianza,
			estado_revision
		)
		values (
			v_fuente_id,
			v_patron_rima_id,
			'Los versos pares mantienen una misma asonancia y los impares quedan sueltos.',
			'alta',
			'revisada'
		);
	end if;
end;
$$;

commit;
