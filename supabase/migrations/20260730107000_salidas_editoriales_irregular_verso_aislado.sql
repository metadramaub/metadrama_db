begin;

alter table public.formas_metricas
	add column tipo_registro text not null default 'forma'
		check (tipo_registro in ('forma', 'salida_editorial')),
	add constraint formas_metricas_salida_editorial_check
		check (
			tipo_registro = 'forma'
			or (residual and seleccionable)
		);

comment on column public.formas_metricas.tipo_registro is
	'Distingue las formas métricas de las salidas editoriales que comparten el selector por razones operativas, pero no poseen norma ni configuración.';

comment on table public.formas_metricas is
	'Formas métricas y salidas editoriales asignables, discriminadas por tipo_registro. No sustituye todavía estrofa_tipo en las secuencias.';

do $$
declare
	v_forma_irregular_id uuid;
	v_forma_verso_id uuid;
	v_fuente_id uuid;
begin
	select forma.forma_id into v_forma_irregular_id
	from public.formas_metricas forma
	join public.vocabularios termino
		on termino.termino_id = forma.origen_termino_id
	where termino.categoria = 'estrofa_tipo'
		and termino.termino = 'irregular';

	select forma.forma_id into v_forma_verso_id
	from public.formas_metricas forma
	join public.vocabularios termino
		on termino.termino_id = forma.origen_termino_id
	where termino.categoria = 'estrofa_tipo'
		and termino.termino = 'verso suelto';

	select fuente_id into v_fuente_id
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós'
		and titulo = 'Métrica española'
		and anio = 2014
	limit 1;

	if v_forma_irregular_id is null
		or v_forma_verso_id is null
		or v_fuente_id is null
	then
		raise exception
			'Falta la salida irregular, la salida verso suelto o la fuente Métrica española (2014)';
	end if;

	if exists (
		select 1
		from public.configuraciones_forma
		where forma_id in (v_forma_irregular_id, v_forma_verso_id)
	) then
		raise exception
			'Las salidas editoriales importadas no deben tener configuraciones normativas';
	end if;

	update public.formas_metricas
	set
		nombre = 'Versificación irregular',
		definicion = 'Pasaje de dos o más versos cuya organización métrica no permite reconocer razonablemente una forma del catálogo. Se utiliza solo cuando el conjunto no conserva una identidad conocida que pueda describirse mediante desviaciones localizadas.',
		nivel_estructural = 'serie',
		tipo_registro = 'salida_editorial',
		seleccionable = true,
		residual = true,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_irregular_id;

	update public.formas_metricas
	set
		slug = 'verso_aislado',
		nombre = 'Verso aislado',
		definicion = 'Un único verso que no puede integrarse en la forma métrica anterior ni en la siguiente y que tampoco constituye una desviación interna de ninguna de ellas.',
		nivel_estructural = 'verso',
		tipo_registro = 'salida_editorial',
		seleccionable = true,
		residual = true,
		estado_revision = 'revisada',
		activo = true,
		updated_at = now()
	where forma_id = v_forma_verso_id;

	insert into public.denominaciones_metricas (
		forma_id,
		nombre,
		slug_normalizado,
		tipo_alias,
		idioma,
		preferente
	)
	values
		(
			v_forma_irregular_id,
			'Irregular',
			'irregular',
			'historico',
			'es',
			false
		),
		(
			v_forma_verso_id,
			'Verso suelto',
			'verso_suelto',
			'historico',
			'es',
			false
		)
	on conflict do nothing;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id,
		forma_id,
		localizador,
		resumen,
		confianza,
		estado_revision
	)
	values
		(
			v_fuente_id,
			v_forma_irregular_id,
			'p. 159',
			'Distingue la versificación irregular o anisosilábica de las formas regulares por no obedecer a la regularidad silábica. La salida editorial del proyecto es más amplia y no se identifica automáticamente con una forma histórica concreta de versificación irregular.',
			'alta',
			'revisada'
		),
		(
			v_fuente_id,
			v_forma_verso_id,
			'p. 232',
			'Emplea verso suelto, libre o blanco para una serie de versos sin rima. Esta acepción métrica aconseja llamar Verso aislado a la salida editorial de un único verso no agrupable.',
			'alta',
			'revisada'
		);

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'E',
		propuesta = 'Conservar como salida editorial Versificación irregular, no como forma métrica ni como configuración.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_forma_irregular_id;

	update public.migracion_terminos_metricos migracion
	set
		clasificacion_decidida = 'D',
		propuesta = 'Fusionar con la salida Versificación irregular; la clase de arte se preservará o derivará de las medidas observadas, no como subtipo.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	from public.vocabularios termino
	where termino.termino_id = migracion.termino_id
		and termino.categoria = 'estrofa_tipo'
		and termino.termino in (
			'irregular_arte_mayor',
			'irregular_arte_menor',
			'irregular_mixto'
		);

	update public.migracion_terminos_metricos
	set
		clasificacion_decidida = 'E',
		propuesta = 'Conservar como salida editorial Verso aislado. Verso suelto queda como denominación histórica de la entrada heredada, no como nombre público preferente.',
		certeza = 'alta',
		requiere_revision = false,
		estado_revision = 'revisada',
		updated_at = now()
	where termino_id = v_forma_verso_id;

	delete from public.migracion_termino_destinos destino
	using public.vocabularios termino
	where termino.termino_id = destino.termino_id
		and termino.categoria = 'estrofa_tipo'
		and termino.termino in (
			'irregular',
			'irregular_arte_mayor',
			'irregular_arte_menor',
			'irregular_mixto',
			'verso suelto'
		);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	values
		(
			v_forma_irregular_id,
			'conservar',
			v_forma_irregular_id,
			'Se conserva como salida editorial discriminada, no como forma comparable.'
		),
		(
			v_forma_verso_id,
			'transformar',
			v_forma_verso_id,
			'La salida heredada Verso suelto pasa a llamarse Verso aislado para evitar la homonimia métrica.'
		);

	insert into public.migracion_termino_destinos (
		termino_id,
		tipo_operacion,
		forma_id,
		nota
	)
	select
		termino.termino_id,
		'fusionar',
		v_forma_irregular_id,
		'La clase de arte heredada deberá conservarse como observación o derivarse de las medidas de los versos.'
	from public.vocabularios termino
	where termino.categoria = 'estrofa_tipo'
		and termino.termino in (
			'irregular_arte_mayor',
			'irregular_arte_menor',
			'irregular_mixto'
		);
end;
$$;

alter table public.secuencias_editor_metrico
	alter column configuracion_id drop not null;

create or replace function public.validar_secuencia_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_tipo_registro text;
	v_slug text;
begin
	select tipo_registro, slug
	into v_tipo_registro, v_slug
	from public.formas_metricas
	where forma_id = new.forma_id
		and activo
		and seleccionable;

	if v_tipo_registro is null then
		raise exception 'La entrada métrica no está activa o no es seleccionable';
	end if;

	if v_tipo_registro = 'salida_editorial' then
		if new.configuracion_id is not null then
			raise exception 'Una salida editorial no admite configuración normativa';
		end if;
		if v_slug = 'verso_aislado' and new.v_fin <> new.v_ini then
			raise exception 'Verso aislado debe abarcar exactamente un verso';
		end if;
		if v_slug = 'irregular' and new.v_fin - new.v_ini + 1 < 2 then
			raise exception 'Versificación irregular debe abarcar al menos dos versos';
		end if;
		return new;
	end if;

	if new.configuracion_id is null or not exists (
		select 1
		from public.configuraciones_forma configuracion
		where configuracion.configuracion_id = new.configuracion_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
	) then
		raise exception 'La configuración no pertenece a una forma activa y seleccionable';
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
	v_configuracion_id uuid;
begin
	select v_ini, v_fin, configuracion_id
	into v_secuencia_ini, v_secuencia_fin, v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if v_configuracion_id is null then
		raise exception 'Una salida editorial no admite desviaciones respecto de una norma inexistente';
	end if;
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

create or replace function public.validar_forma_salida_editorial()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	if new.tipo_registro = 'salida_editorial' and exists (
		select 1
		from public.configuraciones_forma
		where forma_id = new.forma_id
	) then
		raise exception 'Una salida editorial no puede tener configuraciones normativas';
	end if;
	return new;
end;
$$;

create trigger trigger_validar_forma_salida_editorial
before insert or update of tipo_registro on public.formas_metricas
for each row execute function public.validar_forma_salida_editorial();

create or replace function public.validar_configuracion_forma_no_editorial()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	if exists (
		select 1
		from public.formas_metricas
		where forma_id = new.forma_id
			and tipo_registro = 'salida_editorial'
	) then
		raise exception 'Una salida editorial no puede tener configuraciones normativas';
	end if;
	return new;
end;
$$;

create trigger trigger_validar_configuracion_forma_no_editorial
before insert or update of forma_id on public.configuraciones_forma
for each row execute function public.validar_configuracion_forma_no_editorial();

update public.catalogo_metrico_estado
set
	modelo_version = 42,
	actualizado_en = now()
where id = true;

commit;
