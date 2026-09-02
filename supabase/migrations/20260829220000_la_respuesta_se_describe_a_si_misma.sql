-- La respuesta se describe a sí misma
--
-- Hasta hoy una respuesta decía «soy la respuesta a **esta pregunta**», guardando el identificador
-- del grupo de elección. Pasa a decir «**esta realización, en la dimensión rima, es este esquema**».
--
-- **Las preguntas no desaparecen**: siguen siendo la declaración del catálogo de qué se pregunta,
-- con qué control y cuántas respuestas caben. Lo único que cambia es la clave de la respuesta.
--
-- **Por qué.** Guardar el puntero a la pregunta tenía tres consecuencias:
--
--   1. **El catálogo quedaba congelado por las anotaciones.** La clave ajena es `restrict`: con una
--      obra anotada no se podría retirar ni reorganizar una pregunta sin tocar sus respuestas.
--   2. **La reutilización no cabía.** Una pregunta prestada no tiene fila, así que no tiene
--      identidad, así que no se podía guardar: la oncena y el septeto compuesto no podían anotar su
--      rima. Aquí se cierra.
--   3. **Los tramos sin forma no podían preguntar nada**, porque toda pregunta cuelga de una
--      arquitectura y ellos no tienen ninguna.
--
-- **No es un cambio de rumbo, sino terminar algo a medias.** `anotacion_desviaciones` ya se guarda
-- así —con su `dimension` y sin puntero a la pregunta— y `anotacion_elecciones_resueltas` ya derivaba
-- la opción casando las entidades. El código ya sabía que la respuesta es la entidad.
--
-- **No hay migración de datos.** Las tres anotaciones existentes son de prueba, con siete respuestas
-- entre todas, y se borran: la edición está pausada y ninguna obra se ha migrado todavía.
--
-- **Lo que sostiene la clave nueva.** (realización, dimensión) casi basta, y lo que falta ya estaba:
--
--   * los **rasgos** se distinguen por su valor, que pertenece a un solo rasgo —el endecasílabo
--     suelto tiene cinco preguntas de rasgo y ninguna ambigüedad—;
--   * las **posiciones** por `posicion_unidad`, que ya existía;
--   * y el **soneto**, único caso en que la respuesta se guarda en la unidad pero habla de una parte,
--     por `seccion_tratada_id`, que se añade aquí. Son **2 preguntas en todo el catálogo**.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Fuera los datos de prueba
-- ---------------------------------------------------------------------------

delete from public.anotaciones_metricas;

-- ---------------------------------------------------------------------------
-- 2 · La firma de una respuesta, para comparar realizaciones entre sí
-- ---------------------------------------------------------------------------

create or replace function public.firma_de_eleccion(e public.anotacion_elecciones)
returns text
language sql
immutable
set search_path to 'public'
as $firma$
	select coalesce(
		e.esquema_rima_id::text, e.metro_id::text, e.esquema_metrico_id::text,
		e.valor_rasgo_id::text, e.variedad_id::text, e.repeticion_id::text,
		e.seccion_id::text, e.valor_texto
	) || ':' || coalesce(e.posicion_unidad::text, '');
$firma$;

comment on function public.firma_de_eleccion(public.anotacion_elecciones) is
	'Lo que una respuesta afirma, en una cadena comparable: su entidad —o lo escrito— y su posición.';

-- ---------------------------------------------------------------------------
-- 3 · La tabla se describe sola
-- ---------------------------------------------------------------------------

drop view if exists public.anotacion_elecciones_resueltas;

alter table public.anotacion_elecciones
	add column if not exists dimension text,
	add column if not exists seccion_tratada_id uuid
		references public.estructuras_secciones (seccion_id) on update cascade on delete restrict;

alter table public.anotacion_elecciones
	alter column dimension set not null,
	drop column if exists grupo_eleccion_id;

alter table public.anotacion_elecciones
	drop constraint if exists anotacion_elecciones_dimension_check,
	add constraint anotacion_elecciones_dimension_check
		check (dimension = any (array['metro', 'rima', 'repeticion', 'rasgo', 'combinacion'])),
	drop constraint if exists anotacion_elecciones_entidad_dimension_check,
	add constraint anotacion_elecciones_entidad_dimension_check check (
		(esquema_rima_id is null or dimension = 'rima')
		and (metro_id is null or dimension = 'metro')
		and (esquema_metrico_id is null or dimension = 'metro')
		and (valor_rasgo_id is null or dimension = 'rasgo')
		and (repeticion_id is null or dimension = 'repeticion')
		and (variedad_id is null or dimension = 'combinacion')
		and (seccion_id is null or dimension in ('repeticion', 'metro', 'rima'))
	);

comment on column public.anotacion_elecciones.dimension is
	'De qué habla la respuesta. Con la realización y la entidad, la hace legible sin consultar ninguna pregunta.';
comment on column public.anotacion_elecciones.seccion_tratada_id is
	'La parte de la que habla, cuando la respuesta se guarda en la unidad: los cuartetos y los tercetos del soneto.';

-- ---------------------------------------------------------------------------
-- 4 · La opción se deriva, que es lo que el formulario pinta
-- ---------------------------------------------------------------------------

create view public.anotacion_elecciones_resueltas as
select e.*,
	(
		select o.opcion_eleccion_id
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.anotaciones_metricas am on am.anotacion_id = e.anotacion_id
		left join public.anotacion_realizaciones rz on rz.realizacion_id = e.realizacion_id
		left join public.estructuras_secciones sp on sp.seccion_id = rz.seccion_id
		where g.activo
			and g.dimension = e.dimension
			and g.seccion_tratada_id is not distinct from e.seccion_tratada_id
			and (
				(
					g.arquitectura_id = am.arquitectura_id
					and g.seccion_id is not distinct from (
						case when rz.realizacion_padre_id is not null then rz.seccion_id end
					)
				)
				or (g.arquitectura_id = sp.arquitectura_referenciada_id and g.seccion_id is null)
			)
			and o.metro_id is not distinct from e.metro_id
			and o.esquema_metrico_id is not distinct from e.esquema_metrico_id
			and o.esquema_rima_id is not distinct from e.esquema_rima_id
			and o.seccion_id is not distinct from e.seccion_id
			and o.repeticion_id is not distinct from e.repeticion_id
			and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
			and o.variedad_id is not distinct from e.variedad_id
			and o.posicion_unidad is not distinct from e.posicion_unidad
		limit 1
	) as opcion_eleccion_id
from public.anotacion_elecciones e;

comment on view public.anotacion_elecciones_resueltas is
	'Las respuestas con la opción que el formulario pintó, derivada de la entidad y de la pregunta que hoy le corresponde.';

-- ---------------------------------------------------------------------------
-- 5 · Validar sin preguntar por el grupo
-- ---------------------------------------------------------------------------

create or replace function public.validar_anotacion_eleccion()
returns trigger
language plpgsql
set search_path to 'public'
as $validar$
declare
	v_arquitectura uuid;
	v_seccion_unidad uuid;
	v_padre uuid;
	v_arq_reutilizada uuid;
	v_longitud integer;
	v_entidades integer;
	v_escrito integer;
	v_admitida boolean;
begin
	select arquitectura_id, v_fin - v_ini + 1
	into v_arquitectura, v_longitud
	from public.anotaciones_metricas
	where anotacion_id = new.anotacion_id;

	v_entidades := num_nonnulls(
		new.metro_id, new.esquema_metrico_id, new.esquema_rima_id, new.seccion_id,
		new.repeticion_id, new.valor_rasgo_id, new.variedad_id
	);

	if v_entidades = 0 and new.valor_texto is null then
		raise exception 'Una respuesta sin dato no se guarda';
	end if;

	if new.realizacion_id is not null then
		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre, v_longitud
		from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_id and anotacion_id = new.anotacion_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
	end if;

	if v_arquitectura is null then
		return new;
	end if;

	select arquitectura_referenciada_id into v_arq_reutilizada
	from public.estructuras_secciones
	where seccion_id = v_seccion_unidad;

	if v_entidades = 1 then
		select exists (
			select 1
			from public.opciones_eleccion_metrica o
			join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
			where g.activo
				and g.dimension = new.dimension
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and (
					(
						g.arquitectura_id = v_arquitectura
						and g.seccion_id is not distinct from (
							case when v_padre is not null then v_seccion_unidad end
						)
					)
					or (g.arquitectura_id = v_arq_reutilizada and g.seccion_id is null)
				)
				and o.metro_id is not distinct from new.metro_id
				and o.esquema_metrico_id is not distinct from new.esquema_metrico_id
				and o.esquema_rima_id is not distinct from new.esquema_rima_id
				and o.seccion_id is not distinct from new.seccion_id
				and o.repeticion_id is not distinct from new.repeticion_id
				and o.valor_rasgo_id is not distinct from new.valor_rasgo_id
				and o.variedad_id is not distinct from new.variedad_id
				and o.posicion_unidad is not distinct from new.posicion_unidad
		) into v_admitida;

		if not v_admitida then
			raise exception 'La respuesta no está admitida por la norma de esta arquitectura en la dimensión %', new.dimension;
		end if;
	else
		select exists (
			select 1
			from public.grupos_eleccion_metrica g
			where g.activo
				and g.dimension = new.dimension
				and g.tipo_control in ('esquema_rima', 'opciones_y_esquema')
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and (
					(
						g.arquitectura_id = v_arquitectura
						and g.seccion_id is not distinct from (
							case when v_padre is not null then v_seccion_unidad end
						)
					)
					or (g.arquitectura_id = v_arq_reutilizada and g.seccion_id is null)
				)
		) into v_admitida;

		if not v_admitida then
			raise exception 'Esta arquitectura no admite escribir la respuesta en la dimensión %', new.dimension;
		end if;

		v_escrito := length(regexp_replace(new.valor_texto, '[:|[:space:]]', '', 'g'));
		if v_longitud is not null and v_escrito <> v_longitud then
			raise exception 'El esquema de rima debe tener % posiciones y tiene %', v_longitud, v_escrito;
		end if;
	end if;

	return new;
end;
$validar$;

-- ---------------------------------------------------------------------------
-- 6 · Una posición no se responde dos veces
-- ---------------------------------------------------------------------------

create or replace function public.validar_posicion_anotacion_eleccion()
returns trigger
language plpgsql
set search_path to 'public'
as $posicion$
declare
	v_versos integer;
	v_repetida integer;
begin
	if new.posicion_unidad is null or new.realizacion_id is null then
		return new;
	end if;

	select v_fin - v_ini + 1 into v_versos
	from public.anotacion_realizaciones
	where realizacion_id = new.realizacion_id;

	if v_versos is not null and new.posicion_unidad > v_versos then
		raise exception
			'La posición % no existe: la realización tiene % versos',
			new.posicion_unidad, v_versos;
	end if;

	select count(*) into v_repetida
	from public.anotacion_elecciones eleccion
	where eleccion.realizacion_id = new.realizacion_id
		and eleccion.dimension = new.dimension
		and eleccion.seccion_tratada_id is not distinct from new.seccion_tratada_id
		and eleccion.eleccion_id is distinct from new.eleccion_id
		and eleccion.posicion_unidad = new.posicion_unidad;

	if v_repetida > 0 then
		raise exception 'Ya hay una respuesta para la posición %', new.posicion_unidad;
	end if;

	return new;
end;
$posicion$;

-- ---------------------------------------------------------------------------
-- 7 · El guardado escribe la dimensión y cuenta por ella
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.guardar_anotacion_metrica(p_datos jsonb)
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
		v_secuencia_id := nullif(p_datos ->> 'anotacion_id', '')::uuid;
		v_escenario_id := nullif(p_datos ->> 'escenario_id', '')::uuid;
		v_real_id := nullif(p_datos ->> 'secuencia_id', '')::uuid;

		if num_nonnulls(v_escenario_id, v_real_id) <> 1 then
			raise exception 'Una prueba cuelga de un escenario o de una secuencia real, nunca de las dos ni de ninguna';
		end if;

		v_v_ini := (p_datos ->> 'v_ini')::integer;
		v_v_fin := (p_datos ->> 'v_fin')::integer;

		if v_escenario_id is not null then
			-- **El laboratorio sigue siendo de admin e IP.** Un escenario de pruebas no es de nadie,
			-- así que no hay obra de la que colgar un permiso.
			if not public.auth_is_admin_or_ip() then
				raise exception 'Solo admin o IP pueden usar el editor de pruebas'
					using errcode = '42501';
			end if;
			if not exists (
				select 1 from public.anotacion_escenarios_prueba
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

			-- **El permiso se pide sobre la obra**, no sobre el rol: admin o IP con cualquiera, y el
			-- editor con la suya. Es el mismo predicado que gobierna sus políticas y el que ya regía
			-- `secuencias_metricas` desde siempre.
			if not public.auth_puede_editar_obra(v_real.obra_id) then
				raise exception 'No puedes anotar las secuencias de esta obra'
					using errcode = '42501';
			end if;

			-- **Todas las obras se anotan con el catálogo nuevo.** Aquí hubo un interruptor por obra,
			-- de cuando la anotación en sombra iba a ser el camino de la migración. Dejó de serlo el
			-- 27 de agosto de 2026: migrar se hace a mano, con el informe por obra delante, así que
			-- no hay obras «abiertas» y otras que no.

			-- El rango lo manda la secuencia real. La sombra dice qué es ese pasaje, no dónde
			-- empieza: si además se moviera, el contraste entre modelos no compararía lo mismo.
			v_v_ini := v_real.v_ini;
			v_v_fin := v_real.v_fin;
		end if;

		if v_secuencia_id is null then
			insert into public.anotaciones_metricas (
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
			returning anotacion_id into v_secuencia_id;
		else
			update public.anotaciones_metricas
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
			where anotacion_id = v_secuencia_id;

			if not found then
				raise exception 'Secuencia métrica de prueba no encontrada';
			end if;
		end if;

		delete from public.anotacion_desviaciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_elecciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_realizaciones
		where anotacion_id = v_secuencia_id;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
		loop
			insert into public.anotacion_realizaciones (
				realizacion_id, anotacion_id, realizacion_padre_id, seccion_id,
				orden, v_ini, v_fin, etiqueta, observaciones, arquitectura_id
			)
			values (
				(v_item ->> 'realizacion_id')::uuid,
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_padre_id', '')::uuid,
				nullif(v_item ->> 'seccion_id', '')::uuid,
				(v_item ->> 'orden')::integer,
				(v_item ->> 'v_ini')::integer,
				(v_item ->> 'v_fin')::integer,
				nullif(btrim(v_item ->> 'etiqueta'), ''),
				nullif(btrim(v_item ->> 'observaciones'), ''),
				-- La arquitectura de la unidad cuando no es la de su secuencia: la décima aumentada
				-- entre décimas normales. Nulo es el caso corriente, y el disparador comprueba que sea
				-- de la misma forma y esté declarada intercalable.
				nullif(v_item ->> 'arquitectura_id', '')::uuid
			);
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
		loop
			-- El formulario sigue enviando la opción que el editor pulsó, pero lo que se guarda es
			-- el dato del catálogo que esa opción representa. Cuando la respuesta es abierta no hay
			-- opción que resolver y el texto viaja tal cual.
			insert into public.anotacion_elecciones (
				anotacion_id,
				realizacion_id,
				dimension,
				seccion_tratada_id,
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
				nullif(v_item ->> 'realizacion_id', '')::uuid,
				-- La dimensión la manda el formulario; si no viene, se toma de la pregunta que
				-- ofrecía la opción, que es de donde salía antes el grupo.
				coalesce(nullif(v_item ->> 'dimension', ''), g.dimension),
				coalesce(nullif(v_item ->> 'seccion_tratada_id', '')::uuid, g.seccion_tratada_id),
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
				on o.opcion_eleccion_id = k.elegida
			left join public.grupos_eleccion_metrica g
				on g.grupo_eleccion_id = o.grupo_eleccion_id;
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
		loop
			insert into public.anotacion_desviaciones (
				anotacion_id, realizacion_id, v_ini, v_fin, dimension,
				relacion_norma, metro_observado_id, esquema_rima_observado_id,
				seccion_observada_id, repeticion_observada_id,
				valor_rasgo_observado_id, observaciones
			)
			values (
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_id', '')::uuid,
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
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and alcance = 'secuencia'
		loop
			-- Se cuenta por lo que la respuesta dice de sí misma: su dimensión, la parte de la que
			-- habla y, en los rasgos, de cuál se trata —que lo dice el valor elegido—.
			select count(*) into v_total
			from public.anotacion_elecciones e
			where e.anotacion_id = v_secuencia_id
				and e.realizacion_id is null
				and e.dimension = v_grupo.dimension
				and e.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
				and (
					v_grupo.dimension <> 'rasgo'
					or exists (
						select 1 from public.rasgo_valores rv
						where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = v_grupo.rasgo_id
					)
				);

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
			select grupo.*, unidad.realizacion_id
			from public.anotacion_realizaciones unidad
			join public.grupos_eleccion_metrica_resueltos grupo
				on grupo.arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and grupo.activo
				and grupo.alcance = 'unidad'
				and (
					(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
					or grupo.seccion_id = unidad.seccion_id
				)
			where unidad.anotacion_id = v_secuencia_id
		loop
			select count(*) into v_total
			from public.anotacion_elecciones e
			where e.anotacion_id = v_secuencia_id
				and e.realizacion_id = v_grupo.realizacion_id
				and e.dimension = v_grupo.dimension
				and e.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
				and (
					v_grupo.dimension <> 'rasgo'
					or exists (
						select 1 from public.rasgo_valores rv
						where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = v_grupo.rasgo_id
					)
				);

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
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and define_norma
		loop
			with recursive ascendencia as (
				select
					realizacion_id,
					realizacion_id as unidad_id
				from public.anotacion_realizaciones
				where anotacion_id = v_secuencia_id
					and realizacion_padre_id is null
				union all
				select
					hija.realizacion_id,
					ascendencia.unidad_id
				from public.anotacion_realizaciones hija
				join ascendencia
					on ascendencia.realizacion_id = hija.realizacion_padre_id
				where hija.anotacion_id = v_secuencia_id
			),
			firmas as (
				select
					-- Una pregunta anclada en una sección se compara dentro de su unidad; una
					-- pregunta de la unidad entera, dentro de la secuencia.
					case when v_grupo.seccion_id is not null then ascendencia.unidad_id end as contenedor,
					eleccion.realizacion_id,
					-- La firma se arma con lo que la respuesta guarda —la entidad, o lo escrito—, y
					-- no con la opción, que ya no se guarda y había que derivar de una vista.
					string_agg(
						public.firma_de_eleccion(eleccion),
						'|' order by public.firma_de_eleccion(eleccion)
					) as firma
				from public.anotacion_elecciones eleccion
				join ascendencia
					on ascendencia.realizacion_id = eleccion.realizacion_id
				where eleccion.anotacion_id = v_secuencia_id
					and eleccion.dimension = v_grupo.dimension
					and eleccion.seccion_tratada_id is not distinct from v_grupo.seccion_tratada_id
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


do $comprobacion$
declare
	v_col integer;
	v_grupo integer;
	v_filas integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- La columna se fue y la dimensión está, obligatoria.
	select count(*) into v_grupo
	from information_schema.columns
	where table_name = 'anotacion_elecciones' and column_name = 'grupo_eleccion_id';

	if v_grupo <> 0 then
		raise exception 'anotacion_elecciones sigue apuntando a la pregunta.';
	end if;

	select count(*) into v_col
	from information_schema.columns
	where table_name = 'anotacion_elecciones'
		and column_name in ('dimension', 'seccion_tratada_id')
		and (column_name <> 'dimension' or is_nullable = 'NO');

	if v_col <> 2 then
		raise exception 'Faltan la dimensión o la sección tratada, o la dimensión admite nulos.';
	end if;

	-- **Se ejecuta la vista**, que es donde vive la derivación de la opción: una vista que no
	-- resuelve compila igual, y solo se sabe leyéndola.
	select count(*) into v_filas from public.anotacion_elecciones_resueltas;
	raise notice 'La vista de respuestas resuelve y devuelve % filas.', v_filas;

	-- No queda ninguna anotación de prueba.
	if exists (select 1 from public.anotaciones_metricas) then
		raise exception 'Han quedado anotaciones sin borrar.';
	end if;
end
$comprobacion$;

commit;
