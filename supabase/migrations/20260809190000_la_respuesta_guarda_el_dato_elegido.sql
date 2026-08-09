-- La respuesta del editor guarda el dato elegido, no la opción que lo ofrecía.
--
-- Hasta ahora `elecciones_editor_metrico` guardaba `opcion_eleccion_id`, y la opción, a su vez,
-- apuntaba a la entidad del catálogo —un metro, un esquema de rima, un valor de rasgo— más la
-- posición. Es decir: **la opción era un intermediario que no añadía información propia**, y la
-- respuesta dependía de él.
--
-- Eso tenía una consecuencia que bloqueaba el plan: mientras las respuestas apunten a opciones,
-- **las opciones no se pueden regenerar**, porque regenerarlas dejaría las respuestas
-- huérfanas. Guardar la entidad las suelta: a partir de aquí las preguntas pueden generarse,
-- cambiarse o retirarse sin tocar un solo dato guardado.
--
-- Qué cambia y qué no. La tabla guarda ahora la entidad y la posición. La opción sigue
-- existiendo y sigue siendo lo que el editor pinta, así que **el editor no cambia**: una vista
-- resuelve la entidad de vuelta a su opción para quien la necesite. Y la validación sigue
-- comprobando lo mismo que antes —que la elección esté admitida—, solo que ahora lo comprueba
-- sobre la entidad. Cuando las opciones pasen a derivarse, esa comprobación cambiará de fuente
-- sin tocar lo guardado.
--
-- La correspondencia es exacta en las cinco dimensiones, incluida la de repetición, donde cada
-- opción apunta a una repetición distinta —tres en el villancico, dos en el zéjel—, de modo que
-- guardar la repetición no pierde cuál de las tres se eligió. Lo que sí sigue viviendo en la
-- opción es **cómo se realiza** esa repetición: `materializa_seccion_id` y
-- `extension_desde_seccion_id`. Ese comportamiento tendrá que mudarse a `repeticiones_metricas`
-- antes de poder retirar las opciones, y es justo lo que anota la revisión transversal de las
-- reglas de repetición.
--
-- Las respuestas existentes se traspasan; no se pierde ninguna.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La respuesta apunta al catálogo
-- ---------------------------------------------------------------------------

alter table public.elecciones_editor_metrico
	add column if not exists metro_id uuid references public.metros (metro_id)
		on update cascade on delete restrict,
	add column if not exists esquema_metrico_id uuid
		references public.esquemas_metricos (esquema_metrico_id)
		on update cascade on delete cascade,
	add column if not exists esquema_rima_id uuid
		references public.esquemas_rima (esquema_rima_id)
		on update cascade on delete cascade,
	add column if not exists seccion_id uuid
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete cascade,
	add column if not exists repeticion_id uuid
		references public.repeticiones_metricas (repeticion_id)
		on update cascade on delete cascade,
	add column if not exists valor_rasgo_id uuid references public.rasgo_valores (valor_id)
		on update cascade on delete restrict,
	add column if not exists variedad_id uuid
		references public.variedades_arquitectura (variedad_id)
		on update cascade on delete cascade,
	add column if not exists posicion_unidad integer;

-- Se traspasa lo guardado: cada respuesta toma la entidad de la opción que había elegido.
update public.elecciones_editor_metrico e
set metro_id = o.metro_id,
	esquema_metrico_id = o.esquema_metrico_id,
	esquema_rima_id = o.esquema_rima_id,
	seccion_id = o.seccion_id,
	repeticion_id = o.repeticion_id,
	valor_rasgo_id = o.valor_rasgo_id,
	variedad_id = o.variedad_id,
	posicion_unidad = o.posicion_unidad
from public.opciones_eleccion_metrica o
where o.opcion_eleccion_id = e.opcion_eleccion_id;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.elecciones_editor_metrico
	where opcion_eleccion_id is not null
		and num_nonnulls(metro_id, esquema_metrico_id, esquema_rima_id, seccion_id,
			repeticion_id, valor_rasgo_id, variedad_id) = 0;
	if v_n <> 0 then
		raise exception 'Quedan % respuestas sin traspasar su entidad', v_n;
	end if;
end;
$$;

alter table public.elecciones_editor_metrico drop column opcion_eleccion_id;

alter table public.elecciones_editor_metrico
	add constraint elecciones_editor_metrico_una_entidad
	check (
		num_nonnulls(metro_id, esquema_metrico_id, esquema_rima_id, seccion_id,
			repeticion_id, valor_rasgo_id, variedad_id) <= 1
	);

comment on table public.elecciones_editor_metrico is
	'Lo que el editor eligió en una prueba, guardado como el dato del catálogo que eligió —un metro, un esquema, un valor de rasgo— y no como la opción que se lo ofrecía. Así las preguntas pueden regenerarse sin dejar huérfana ninguna respuesta.';

-- ---------------------------------------------------------------------------
-- 2 · Una vista devuelve la opción, para quien siga necesitándola
-- ---------------------------------------------------------------------------

create or replace view public.elecciones_editor_metrico_resueltas as
select e.*, o.opcion_eleccion_id
from public.elecciones_editor_metrico e
left join public.opciones_eleccion_metrica o
	on o.grupo_eleccion_id = e.grupo_eleccion_id
	and o.metro_id is not distinct from e.metro_id
	and o.esquema_metrico_id is not distinct from e.esquema_metrico_id
	and o.esquema_rima_id is not distinct from e.esquema_rima_id
	and o.seccion_id is not distinct from e.seccion_id
	and o.repeticion_id is not distinct from e.repeticion_id
	and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
	and o.variedad_id is not distinct from e.variedad_id
	and o.posicion_unidad is not distinct from e.posicion_unidad;

comment on view public.elecciones_editor_metrico_resueltas is
	'Las respuestas con la opción que hoy las ofrece, resuelta desde la entidad que guardan. Existe para que el editor siga pintando opciones mientras las haya; cuando se generen, esta vista las resolverá igual.';

grant select on public.elecciones_editor_metrico_resueltas to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · La validación comprueba la entidad, no la identidad de la opción
-- ---------------------------------------------------------------------------

create or replace function public.validar_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_arquitectura_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_padre_unidad uuid;
	v_maximo integer;
	v_tipo_control text;
	v_longitud_esperada integer;
	v_total integer;
	v_entidades integer;
begin
	select arquitectura_id into v_arquitectura_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select alcance, seccion_id, selecciones_max, tipo_control
	into v_alcance, v_seccion_grupo, v_maximo, v_tipo_control
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and arquitectura_id = v_arquitectura_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la arquitectura seleccionada';
	end if;

	v_entidades := num_nonnulls(
		new.metro_id, new.esquema_metrico_id, new.esquema_rima_id, new.seccion_id,
		new.repeticion_id, new.valor_rasgo_id, new.variedad_id
	);

	if v_tipo_control = 'opciones' then
		if v_entidades <> 1 or new.valor_texto is not null then
			raise exception 'Esta pregunta necesita un dato normalizado del catálogo';
		end if;
		-- La elección tiene que estar entre las admitidas por la pregunta. Hoy las admitidas
		-- son las opciones declaradas; cuando se deriven, esta comprobación mirará ahí sin que
		-- cambie nada de lo guardado.
		if not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = new.grupo_eleccion_id
				and o.activo
				and o.metro_id is not distinct from new.metro_id
				and o.esquema_metrico_id is not distinct from new.esquema_metrico_id
				and o.esquema_rima_id is not distinct from new.esquema_rima_id
				and o.seccion_id is not distinct from new.seccion_id
				and o.repeticion_id is not distinct from new.repeticion_id
				and o.valor_rasgo_id is not distinct from new.valor_rasgo_id
				and o.variedad_id is not distinct from new.variedad_id
				and o.posicion_unidad is not distinct from new.posicion_unidad
		) then
			raise exception 'La elección no está admitida por esta pregunta';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		if v_entidades <> 0 or new.valor_texto is null then
			raise exception 'Esta pregunta necesita un esquema de rima escrito';
		end if;
	end if;

	if v_alcance = 'unidad' then
		if new.realizacion_prueba_id is null then
			raise exception 'La elección de unidad necesita una realización';
		end if;

		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre_unidad, v_longitud_esperada
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;

		if v_seccion_grupo is null then
			if v_padre_unidad is not null then
				raise exception 'La pregunta se refiere a la unidad y no a una de sus partes';
			end if;
		elsif v_seccion_grupo is distinct from v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		select v_fin - v_ini + 1
		into v_longitud_esperada
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = new.secuencia_prueba_id;
	end if;

	if v_tipo_control = 'esquema_rima'
		and length(replace(new.valor_texto, ':', '')) <> v_longitud_esperada
	then
		raise exception
			'El esquema de rima debe tener % posiciones y tiene %',
			v_longitud_esperada,
			length(replace(new.valor_texto, ':', ''));
	end if;

	select count(*)
	into v_total
	from public.elecciones_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id
		and grupo_eleccion_id = new.grupo_eleccion_id
		and realizacion_prueba_id is not distinct from new.realizacion_prueba_id
		and eleccion_prueba_id <> new.eleccion_prueba_id;

	if v_total + 1 > v_maximo then
		raise exception 'La elección supera la cardinalidad máxima del grupo';
	end if;

	return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 4 · La función de guardado resuelve la opción a su dato
-- ---------------------------------------------------------------------------

create or replace function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_secuencia_id uuid;
	v_escenario_id uuid;
	v_real_id uuid;
	v_real record;
	v_v_ini integer;
	v_v_fin integer;
	v_item jsonb;
	v_grupo record;
	v_total integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
			using errcode = '42501';
	end if;

	v_secuencia_id := nullif(p_datos ->> 'secuencia_prueba_id', '')::uuid;
	v_escenario_id := nullif(p_datos ->> 'escenario_id', '')::uuid;
	v_real_id := nullif(p_datos ->> 'secuencia_id', '')::uuid;

	if num_nonnulls(v_escenario_id, v_real_id) <> 1 then
		raise exception 'Una prueba cuelga de un escenario o de una secuencia real, nunca de las dos ni de ninguna';
	end if;

	v_v_ini := (p_datos ->> 'v_ini')::integer;
	v_v_fin := (p_datos ->> 'v_fin')::integer;

	if v_escenario_id is not null then
		if not exists (
			select 1 from public.escenarios_editor_metrico
			where escenario_id = v_escenario_id
		) then
			raise exception 'El escenario de prueba no existe';
		end if;
	else
		select s.secuencia_id, s.obra_id, s.v_ini, s.v_fin
		into v_real
		from public.secuencias_metricas s
		where s.secuencia_id = v_real_id;

		if not found then
			raise exception 'La secuencia real que se quiere anotar no existe';
		end if;

		-- El interruptor es por obra: anotar en sombra una obra que nadie ha abierto sería
		-- empezar la migración por la puerta de atrás.
		if not exists (
			select 1 from public.obras_editor_metrico_v2
			where obra_id = v_real.obra_id
		) then
			raise exception 'La obra de esta secuencia no está abierta al editor V2';
		end if;

		-- El rango lo manda la secuencia real. La sombra dice qué es ese pasaje, no dónde
		-- empieza: si además se moviera, el contraste entre modelos no compararía lo mismo.
		v_v_ini := v_real.v_ini;
		v_v_fin := v_real.v_fin;
	end if;

	if v_secuencia_id is null then
		insert into public.secuencias_editor_metrico (
			escenario_id, secuencia_id, orden, v_ini, v_fin, forma_id, arquitectura_id,
			observaciones, created_by, updated_by
		)
		values (
			v_escenario_id,
			v_real_id,
			coalesce((p_datos ->> 'orden')::integer, 1),
			v_v_ini,
			v_v_fin,
			(p_datos ->> 'forma_id')::uuid,
			nullif(p_datos ->> 'arquitectura_id', '')::uuid,
			nullif(btrim(p_datos ->> 'observaciones'), ''),
			auth.uid(),
			auth.uid()
		)
		returning secuencia_prueba_id into v_secuencia_id;
	else
		update public.secuencias_editor_metrico
		set
			escenario_id = v_escenario_id,
			secuencia_id = v_real_id,
			orden = coalesce((p_datos ->> 'orden')::integer, orden),
			v_ini = v_v_ini,
			v_fin = v_v_fin,
			forma_id = (p_datos ->> 'forma_id')::uuid,
			arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid,
			observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
			updated_by = auth.uid()
		where secuencia_prueba_id = v_secuencia_id;

		if not found then
			raise exception 'Secuencia métrica de prueba no encontrada';
		end if;
	end if;

	delete from public.desviaciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.elecciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;
	delete from public.realizaciones_editor_metrico
	where secuencia_prueba_id = v_secuencia_id;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
	loop
		insert into public.realizaciones_editor_metrico (
			realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id,
			orden, v_ini, v_fin, etiqueta, observaciones
		)
		values (
			(v_item ->> 'realizacion_prueba_id')::uuid,
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_padre_id', '')::uuid,
			nullif(v_item ->> 'seccion_id', '')::uuid,
			(v_item ->> 'orden')::integer,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			nullif(btrim(v_item ->> 'etiqueta'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
	loop
		-- El formulario sigue enviando la opción que el editor pulsó, pero lo que se guarda es
		-- el dato del catálogo que esa opción representa. Cuando la respuesta es abierta no hay
		-- opción que resolver y el texto viaja tal cual.
		insert into public.elecciones_editor_metrico (
			secuencia_prueba_id,
			realizacion_prueba_id,
			grupo_eleccion_id,
			metro_id,
			esquema_metrico_id,
			esquema_rima_id,
			seccion_id,
			repeticion_id,
			valor_rasgo_id,
			variedad_id,
			posicion_unidad,
			valor_texto,
			observaciones
		)
		select
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
			(v_item ->> 'grupo_eleccion_id')::uuid,
			o.metro_id,
			o.esquema_metrico_id,
			o.esquema_rima_id,
			o.seccion_id,
			o.repeticion_id,
			o.valor_rasgo_id,
			o.variedad_id,
			o.posicion_unidad,
			nullif(btrim(v_item ->> 'valor_texto'), ''),
			nullif(btrim(v_item ->> 'observaciones'), '')
		from (select nullif(v_item ->> 'opcion_eleccion_id', '')::uuid as elegida) k
		left join public.opciones_eleccion_metrica o
			on o.opcion_eleccion_id = k.elegida;
	end loop;

	for v_item in
		select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
	loop
		insert into public.desviaciones_editor_metrico (
			secuencia_prueba_id, realizacion_prueba_id, v_ini, v_fin, dimension,
			relacion_norma, metro_observado_id, esquema_rima_observado_id,
			seccion_observada_id, repeticion_observada_id,
			valor_rasgo_observado_id, observaciones
		)
		values (
			v_secuencia_id,
			nullif(v_item ->> 'realizacion_prueba_id', '')::uuid,
			(v_item ->> 'v_ini')::integer,
			(v_item ->> 'v_fin')::integer,
			v_item ->> 'dimension',
			v_item ->> 'relacion_norma',
			nullif(v_item ->> 'metro_observado_id', '')::uuid,
			nullif(v_item ->> 'esquema_rima_observado_id', '')::uuid,
			nullif(v_item ->> 'seccion_observada_id', '')::uuid,
			nullif(v_item ->> 'repeticion_observada_id', '')::uuid,
			nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
			nullif(btrim(v_item ->> 'observaciones'), '')
		);
	end loop;

	for v_grupo in
		select *
		from public.grupos_eleccion_metrica
		where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
			and activo
			and alcance = 'secuencia'
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id
			and realizacion_prueba_id is null;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	-- Una pregunta sin sección se aplica a la unidad entera, que es la realización que no
	-- cuelga de ninguna otra.
	for v_grupo in
		select grupo.*, unidad.realizacion_prueba_id
		from public.realizaciones_editor_metrico unidad
		join public.grupos_eleccion_metrica grupo
			on grupo.arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
			and grupo.activo
			and grupo.alcance = 'unidad'
			and (
				(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
				or grupo.seccion_id = unidad.seccion_id
			)
		where unidad.secuencia_prueba_id = v_secuencia_id
	loop
		select count(*) into v_total
		from public.elecciones_editor_metrico
		where secuencia_prueba_id = v_secuencia_id
			and realizacion_prueba_id = v_grupo.realizacion_prueba_id
			and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

		if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
			raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
				v_grupo.nombre,
				v_grupo.selecciones_min,
				v_grupo.selecciones_max;
		end if;
	end loop;

	-- Lo que declara la norma no puede contradecirse dentro de la unidad que lo contiene.
	-- Se comparan conjuntos completos de respuestas, porque una pregunta puede admitir
	-- varias —la medida de cada posición de la estancia, por ejemplo—.
	for v_grupo in
		select *
		from public.grupos_eleccion_metrica
		where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
			and activo
			and define_norma
	loop
		with recursive ascendencia as (
			select
				realizacion_prueba_id,
				realizacion_prueba_id as unidad_id
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = v_secuencia_id
				and realizacion_padre_id is null
			union all
			select
				hija.realizacion_prueba_id,
				ascendencia.unidad_id
			from public.realizaciones_editor_metrico hija
			join ascendencia
				on ascendencia.realizacion_prueba_id = hija.realizacion_padre_id
			where hija.secuencia_prueba_id = v_secuencia_id
		),
		firmas as (
			select
				-- Una pregunta anclada en una sección se compara dentro de su unidad; una
				-- pregunta de la unidad entera, dentro de la secuencia.
				case when v_grupo.seccion_id is not null then ascendencia.unidad_id end as contenedor,
				eleccion.realizacion_prueba_id,
				string_agg(
					coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto),
					'|' order by coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto)
				) as firma
			from public.elecciones_editor_metrico eleccion
			join ascendencia
				on ascendencia.realizacion_prueba_id = eleccion.realizacion_prueba_id
			where eleccion.secuencia_prueba_id = v_secuencia_id
				and eleccion.grupo_eleccion_id = v_grupo.grupo_eleccion_id
			group by 1, 2
		)
		select count(*)
		into v_total
		from (
			select contenedor
			from firmas
			group by contenedor
			having count(distinct firma) > 1
		) discrepancias;

		if v_total > 0 then
			raise exception
				'La pregunta «%» declara la norma del pasaje: debe responderse igual en todas sus realizaciones',
				v_grupo.nombre;
		end if;
	end loop;

	return v_secuencia_id;
end;
$function$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

