-- Tres correcciones de cómo se codifica la medida, salidas de auditar las posiciones.
--
-- 1 · La repetición se declara en un solo sitio.
--
--    `tipo_secuencia = 'ciclo'` ya dice que las posiciones se repiten: es lo que separa un
--    ciclo de una `secuencia`, que se recorre una vez. Pero cinco esquemas repetían además
--    esa afirmación en `grupo_repeticion = 'todos_los_versos'` y otros veintiséis no, sin
--    criterio: los cinco vienen de las migraciones de la sextina, el romance heroico y los
--    romancillos, tres sesiones que decidieron por separado. Dentro del propio romance, tres
--    arquitecturas lo declaraban y la octosílaba —la principal— no.
--
--    Nadie lee esa columna: solo se expone como campo editable en el gestor. Se vacía, y la
--    repetición queda dicha donde se decide, no en dos sitios que pueden discrepar. La
--    columna se conserva para cuando aparezca un esquema en que solo repita una parte.
--
-- 2 · La copla real no declaraba su medida.
--
--    Era la única forma con unidad acotada sin ningún esquema métrico. Son diez octosílabos,
--    y así lo dice el término legado del que sale: «tirada de estrofas de diez versos […]
--    sin versos de pie quebrado».
--
-- 3 · El quebrado de la copla real admite cuatro o cinco sílabas.
--
--    La pregunta ofrecía solo tetrasílabos en las diez posiciones, pero la sextilla de pie
--    quebrado ya declara las dos medidas en sus posiciones de quebrado, y el término legado
--    de la copla de pie quebrado dice «habitualmente tetrasílabos o pentasílabos». Morley y
--    Bruerton, en las coplas de pie quebrado: «octosílabos combinados con su quebrado de
--    cuatro (o cinco) sílabas». Mismo fenómeno codificado de dos maneras; se iguala por la
--    que sigue a las fuentes.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Una sola declaración de la repetición
-- ---------------------------------------------------------------------------

do $$
declare
	v_limpiadas integer;
begin
	update public.esquema_metrico_posiciones p
	set grupo_repeticion = null
	from public.esquemas_metricos em
	where em.esquema_metrico_id = p.esquema_metrico_id
		and em.tipo_secuencia = 'ciclo'
		and p.grupo_repeticion is not null;

	get diagnostics v_limpiadas = row_count;
	raise notice 'Posiciones que repetían la declaración de ciclo: %', v_limpiadas;

	if exists (
		select 1
		from public.esquema_metrico_posiciones p
		join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id
		where em.tipo_secuencia = 'ciclo' and p.grupo_repeticion is not null
	) then
		raise exception 'Sigue habiendo ciclos que declaran la repetición dos veces';
	end if;
end $$;

comment on column public.esquema_metrico_posiciones.grupo_repeticion is
	'Agrupa posiciones que repiten juntas dentro de un esquema en que solo repite una parte. No se usa para decir que el esquema entero se repite: eso lo dice `esquemas_metricos.tipo_secuencia = ciclo`.';

-- ---------------------------------------------------------------------------
-- 2 · La copla real declara sus diez octosílabos
-- ---------------------------------------------------------------------------

do $$
declare
	v_arquitectura uuid;
	v_esquema uuid;
	v_octosilabo uuid;
begin
	select a.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_real' and a.slug = 'octosilabica_consonante';

	select metro_id into v_octosilabo
	from public.metros where silabas = 8 and tipo = 'simple' limit 1;

	if v_arquitectura is null or v_octosilabo is null then
		raise exception 'Falta la arquitectura de la copla real o el metro octosílabo';
	end if;

	if exists (
		select 1 from public.esquemas_metricos where arquitectura_id = v_arquitectura
	) then
		raise notice 'La copla real ya tenía esquema métrico: no se toca.';
		return;
	end if;

	insert into public.esquemas_metricos
		(arquitectura_id, nombre, slug, ambito, tipo_secuencia, descripcion)
	values (
		v_arquitectura,
		'Diez octosílabos',
		'8-repetido',
		'unidad',
		'ciclo',
		'Un octosílabo en cada una de las diez posiciones. Uno o dos versos pueden aparecer quebrados, y eso se responde al anotar.'
	)
	returning esquema_metrico_id into v_esquema;

	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, alternativa, metro_id)
	values (v_esquema, 1, 1, v_octosilabo);

	raise notice 'Creado el esquema métrico de la copla real.';
end $$;

-- ---------------------------------------------------------------------------
-- 3 · El quebrado admite cuatro o cinco sílabas
-- ---------------------------------------------------------------------------

do $$
declare
	v_grupo uuid;
	v_pentasilabo uuid;
	v_creadas integer := 0;
	v_posicion integer;
	v_orden integer;
begin
	select g.grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_real' and g.activo and g.nombre ilike '%quebrado%';

	select metro_id into v_pentasilabo
	from public.metros where silabas = 5 and tipo = 'simple' limit 1;

	if v_grupo is null or v_pentasilabo is null then
		raise exception 'Falta la pregunta de los quebrados o el metro pentasílabo';
	end if;

	select coalesce(max(orden), 0) into v_orden
	from public.opciones_eleccion_metrica where grupo_eleccion_id = v_grupo;

	for v_posicion in 1..10 loop
		if exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = v_grupo
				and o.posicion_unidad = v_posicion
				and o.metro_id = v_pentasilabo
		) then
			continue;
		end if;

		v_orden := v_orden + 1;
		insert into public.opciones_eleccion_metrica
			(grupo_eleccion_id, slug, nombre, metro_id, posicion_unidad, orden, activo)
		values (
			v_grupo,
			'verso-' || v_posicion || '-5-silabas',
			'Verso ' || v_posicion || ': 5 sílabas',
			v_pentasilabo,
			v_posicion,
			v_orden,
			true
		);
		v_creadas := v_creadas + 1;
	end loop;

	raise notice 'Opciones de quebrado pentasílabo añadidas: %', v_creadas;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
