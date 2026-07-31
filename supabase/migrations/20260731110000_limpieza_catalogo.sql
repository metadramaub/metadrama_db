begin;

-- Bloque D de la migración estructural del dominio métrico: la limpieza.
--
-- Tres residuos del vocabulario anterior y una deuda de nombres.
--
-- La familia agrupaba formas por parecido. La ontología no la reconoce: contar por
-- «décimas» o por «formas con estribillo» es una categoría del estudio, no de la métrica, y
-- las relaciones tipadas dicen con más precisión qué une a la espinela con la copla real.
-- Las tres familias pobladas —tercetos, pareados, décimas— no aportan ningún vínculo que
-- `forma_relaciones` no exprese ya: `terceto_encadenado relacionada_con terceto`,
-- `pareados_endecasilabos relacionada_con pareado`, `decima_espinela
-- sucede_historicamente_a copla_real` y `decima_aumentada derivada_de decima_espinela`.
--
-- La pertenencia a una tradición no se tipifica. `formas_tradiciones` obligaba a un
-- `tipo_relacion` que el dato de origen no tiene —la nota ya dice si la forma nació allí o
-- se aclimató— y su `es_principal` protegía una invariante vacía: la pertenencia es única.
--
-- Una denominación apunta al nivel exacto que nombra, y le faltaban dos cosas: poder
-- nombrar una variedad, y distinguir el nombre **posterior** —moderno, aplicado
-- retrospectivamente— del equivalente. «Cuarteta» estaba registrada como equivalente, lo
-- que afirma que así se llamaba en el Siglo de Oro a la redondilla cruzada.
--
-- Y ciento y pico restricciones, índices, políticas y disparadores seguían nombrando
-- configuraciones, patrones, combinaciones y unidades. Un renombrado de tabla no los
-- arrastra, y quien lea el esquema no debería tener que traducir.

-- ---------------------------------------------------------------------------
-- 1 · Las familias desaparecen
-- ---------------------------------------------------------------------------

-- Lo que colgaba de una familia pasa a colgar de la forma que la representaba.
update public.afirmaciones_fuentes_metricas afirmacion
set forma_id = (
		select vinculo.forma_id
		from public.familias_formas vinculo
		where vinculo.familia_id = afirmacion.familia_id
		order by vinculo.es_principal desc, vinculo.orden nulls last
		limit 1
	),
	familia_id = null
where afirmacion.familia_id is not null;

update public.migracion_termino_destinos destino
set forma_id = (
		select vinculo.forma_id
		from public.familias_formas vinculo
		where vinculo.familia_id = destino.familia_id
		order by vinculo.es_principal desc, vinculo.orden nulls last
		limit 1
	),
	familia_id = null,
	nota = btrim(
		coalesce(destino.nota, '') ||
		' La familia deja de existir: la traza apunta a la forma que la representaba.'
	)
where destino.familia_id is not null;

do $$
declare
	v_huerfanos integer;
begin
	select count(*) into v_huerfanos
	from public.afirmaciones_fuentes_metricas
	where familia_id is not null and forma_id is null;
	if v_huerfanos > 0 then
		raise exception '% afirmaciones se quedarían sin destino al retirar las familias', v_huerfanos;
	end if;

	select count(*) into v_huerfanos
	from public.migracion_termino_destinos
	where familia_id is not null and forma_id is null and tipo_operacion <> 'retirar';
	if v_huerfanos > 0 then
		raise exception '% destinos de migración se quedarían sin destino', v_huerfanos;
	end if;
end;
$$;

alter table public.afirmaciones_fuentes_metricas
	drop constraint afirmaciones_fuentes_metricas_check,
	drop column familia_id;

alter table public.afirmaciones_fuentes_metricas
	add constraint afirmaciones_fuentes_metricas_check check (
		num_nonnulls(
			forma_id, tradicion_id, arquitectura_id,
			esquema_metrico_id, esquema_rima_id, rasgo_id
		) = 1
	);

alter table public.migracion_termino_destinos
	drop constraint migracion_termino_destinos_un_destino_check,
	drop column familia_id;

alter table public.migracion_termino_destinos
	add constraint migracion_termino_destinos_un_destino_check check (
		tipo_operacion = 'retirar'
		or num_nonnulls(
			forma_id, arquitectura_id, esquema_metrico_id, esquema_rima_id,
			variedad_id, rasgo_id, valor_rasgo_id, alias_id
		) = 1
	);

drop table public.familias_formas;
drop table public.familias_metricas;

-- ---------------------------------------------------------------------------
-- 2 · La pertenencia a una tradición no se tipifica
-- ---------------------------------------------------------------------------

alter table public.formas_tradiciones
	drop constraint formas_tradiciones_pkey,
	drop constraint formas_tradiciones_tipo_relacion_check,
	drop column tipo_relacion,
	drop column es_principal;

alter table public.formas_tradiciones
	add constraint formas_tradiciones_pkey primary key (forma_id, tradicion_id);

comment on table public.formas_tradiciones is
	'Ámbito histórico del que procede una forma. Es una pertenencia, no una herencia, y no se tipifica: pertenecer a dos tradiciones ya expresa que la forma nació en una y se aclimató en otra.';

-- ---------------------------------------------------------------------------
-- 3 · Las denominaciones nombran también variedades, y distinguen el nombre posterior
-- ---------------------------------------------------------------------------

alter table public.denominaciones_metricas
	add column variedad_id uuid
		references public.variedades_arquitectura (variedad_id)
		on update cascade on delete cascade;

alter table public.denominaciones_metricas
	drop constraint denominaciones_metricas_destino_check;

alter table public.denominaciones_metricas
	add constraint denominaciones_metricas_destino_check check (
		num_nonnulls(
			forma_id, arquitectura_id, esquema_metrico_id, esquema_rima_id,
			variedad_id, seccion_id, repeticion_id
		) = 1
	);

create unique index denominaciones_metricas_variedad_slug_idx
	on public.denominaciones_metricas (variedad_id, slug_normalizado)
	where variedad_id is not null;

alter table public.denominaciones_metricas
	drop constraint forma_aliases_tipo_alias_check;

alter table public.denominaciones_metricas
	add constraint forma_aliases_tipo_alias_check check (
		tipo_alias = any (array['equivalente', 'variante_grafica', 'historico', 'posterior', 'abreviatura'])
	);

comment on column public.denominaciones_metricas.tipo_alias is
	'Relación temporal del nombre con el corpus. «posterior» es el nombre moderno aplicado retrospectivamente, que no se usaba en el Siglo de Oro.';
comment on column public.denominaciones_metricas.variedad_id is
	'Variedad que la denominación nombra, cuando el nombre no designa la forma entera sino una pareja reconocida de esquemas.';

-- «Cuarteta» nombra la disposición `abab` de la redondilla, pero es un nombre moderno:
-- en el Siglo de Oro ambas disposiciones eran redondillas.
update public.denominaciones_metricas
set tipo_alias = 'posterior'
where slug_normalizado = 'cuarteta'
	and tipo_alias = 'equivalente';

do $$
begin
	if not exists (
		select 1 from public.denominaciones_metricas
		where slug_normalizado = 'cuarteta' and tipo_alias = 'posterior'
	) then
		raise exception 'No se reclasificó «Cuarteta» como denominación posterior';
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · Los nombres del esquema hablan el vocabulario de la ontología
--
-- Un renombrado de tabla arrastra las restricciones, los índices, las políticas y los
-- disparadores, pero no sus nombres. Se traducen aquí de una vez.
-- ---------------------------------------------------------------------------

create temporary table renombrado_de_identificadores (
	orden integer primary key,
	viejo text not null,
	nuevo text not null
) on commit drop;

insert into renombrado_de_identificadores (orden, viejo, nuevo) values
	-- Nombres de tabla, del más específico al más general.
	(10, 'combinaciones_patrones_configuracion', 'variedades_arquitectura'),
	(11, 'combinaciones_patrones_config', 'variedades_arquitectura'),
	(12, 'combinaciones_patrones', 'variedades_arquitectura'),
	(20, 'configuraciones_forma', 'arquitecturas_forma'),
	(21, 'configuracion_rasgos', 'arquitectura_rasgos'),
	(30, 'unidades_editor_metrico', 'realizaciones_editor_metrico'),
	(40, 'forma_aliases', 'denominaciones_metricas'),
	(50, 'patron_repeticion_posiciones', 'repeticion_posiciones'),
	(51, 'patrones_repeticion', 'repeticiones_metricas'),
	(60, 'patron_metrico_opciones', 'esquema_metrico_opciones'),
	(61, 'patron_metrico_posiciones', 'esquema_metrico_posiciones'),
	(62, 'patrones_metricos', 'esquemas_metricos'),
	(70, 'patron_rima_enlaces', 'esquema_rima_enlaces'),
	(71, 'patron_rima_posiciones', 'esquema_rima_posiciones'),
	(72, 'patron_rima_restricciones', 'esquema_rima_restricciones'),
	(73, 'patrones_rima', 'esquemas_rima'),
	-- Nombres de columna incrustados.
	(80, 'patron_repeticion_observado_id', 'repeticion_observada_id'),
	(81, 'patron_repeticion_id', 'repeticion_id'),
	(82, 'configuracion_referenciada', 'arquitectura_referenciada'),
	(83, 'configuracion_id', 'arquitectura_id'),
	(84, 'patron_metrico_id', 'esquema_metrico_id'),
	(85, 'patron_rima_id', 'esquema_rima_id'),
	(86, 'unidad_padre_id', 'realizacion_padre_id'),
	(87, 'unidad_prueba_id', 'realizacion_prueba_id'),
	(90, 'configuracion', 'arquitectura');

do $$
declare
	v_objeto record;
	v_par record;
	v_nuevo text;
	v_total integer := 0;
begin
	-- Restricciones. Renombrarlas arrastra el índice que las respalda.
	for v_objeto in
		select restriccion.conname as nombre, tabla.relname as tabla
		from pg_constraint restriccion
		join pg_class tabla on tabla.oid = restriccion.conrelid
		join pg_namespace espacio on espacio.oid = tabla.relnamespace
		where espacio.nspname = 'public'
	loop
		v_nuevo := v_objeto.nombre;
		for v_par in select viejo, nuevo from renombrado_de_identificadores order by orden loop
			v_nuevo := replace(v_nuevo, v_par.viejo, v_par.nuevo);
		end loop;
		v_nuevo := left(v_nuevo, 63);
		if v_nuevo <> v_objeto.nombre then
			execute format(
				'alter table public.%I rename constraint %I to %I',
				v_objeto.tabla, v_objeto.nombre, v_nuevo
			);
			v_total := v_total + 1;
		end if;
	end loop;

	-- Índices que no respaldan una restricción.
	for v_objeto in
		select indice.relname as nombre
		from pg_index definicion
		join pg_class indice on indice.oid = definicion.indexrelid
		join pg_namespace espacio on espacio.oid = indice.relnamespace
		where espacio.nspname = 'public'
			and not exists (
				select 1 from pg_constraint restriccion
				where restriccion.conindid = definicion.indexrelid
			)
	loop
		v_nuevo := v_objeto.nombre;
		for v_par in select viejo, nuevo from renombrado_de_identificadores order by orden loop
			v_nuevo := replace(v_nuevo, v_par.viejo, v_par.nuevo);
		end loop;
		v_nuevo := left(v_nuevo, 63);
		if v_nuevo <> v_objeto.nombre then
			execute format('alter index public.%I rename to %I', v_objeto.nombre, v_nuevo);
			v_total := v_total + 1;
		end if;
	end loop;

	-- Políticas de acceso.
	for v_objeto in
		select politica.polname as nombre, tabla.relname as tabla
		from pg_policy politica
		join pg_class tabla on tabla.oid = politica.polrelid
		join pg_namespace espacio on espacio.oid = tabla.relnamespace
		where espacio.nspname = 'public'
	loop
		v_nuevo := v_objeto.nombre;
		for v_par in select viejo, nuevo from renombrado_de_identificadores order by orden loop
			v_nuevo := replace(v_nuevo, v_par.viejo, v_par.nuevo);
		end loop;
		v_nuevo := left(v_nuevo, 63);
		if v_nuevo <> v_objeto.nombre then
			execute format(
				'alter policy %I on public.%I rename to %I',
				v_objeto.nombre, v_objeto.tabla, v_nuevo
			);
			v_total := v_total + 1;
		end if;
	end loop;

	-- Disparadores declarados, no los internos de las claves ajenas.
	for v_objeto in
		select disparador.tgname as nombre, tabla.relname as tabla
		from pg_trigger disparador
		join pg_class tabla on tabla.oid = disparador.tgrelid
		join pg_namespace espacio on espacio.oid = tabla.relnamespace
		where espacio.nspname = 'public'
			and not disparador.tgisinternal
	loop
		v_nuevo := v_objeto.nombre;
		for v_par in select viejo, nuevo from renombrado_de_identificadores order by orden loop
			v_nuevo := replace(v_nuevo, v_par.viejo, v_par.nuevo);
		end loop;
		v_nuevo := left(v_nuevo, 63);
		if v_nuevo <> v_objeto.nombre then
			execute format(
				'alter trigger %I on public.%I rename to %I',
				v_objeto.nombre, v_objeto.tabla, v_nuevo
			);
			v_total := v_total + 1;
		end if;
	end loop;

	raise notice 'Identificadores traducidos: %', v_total;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 47,
	actualizado_en = now()
where id = true;

commit;
