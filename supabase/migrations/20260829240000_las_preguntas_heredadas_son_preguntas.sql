-- Las preguntas heredadas son preguntas
--
-- Una parte que declara **ser** otra arquitectura toma prestado su repertorio de rima cuando la
-- unidad no declara la suya y la parte no tiene nada propio. Eso pasaba **solo en el cliente**: un
-- módulo se inventaba la pregunta para pintarla, el disparador y la vista de respuestas repetían la
-- búsqueda cada uno por su lado, y la ficha pública tenía una cuarta versión de la misma regla con
-- condiciones distintas. Cuatro escrituras de una sola idea.
--
-- Aquí se escribe **una vez**, donde vive el catálogo. `preguntas_metricas` es lo declarado más lo
-- heredado, y todo lo que leía preguntas pasa a leerla: las opciones, los rótulos, la validación y
-- la relectura de lo anotado.
--
-- **La identidad se deriva, como ya se derivaba la de las opciones.** El catálogo mintió ids antes
-- que nadie: `opciones_eleccion_metrica` construye el suyo con `md5(...)::uuid` sobre el contenido.
-- Una pregunta heredada usa la misma receta —la pregunta prestamista y la sección que la toma— así
-- que dos partes que reutilicen lo mismo no colisionan.
--
-- *Antes esto no se podía hacer: la respuesta guardaba una clave ajena a la tabla de preguntas y una
-- fila derivada no podía satisfacerla. Esa clave ajena la retiró C20 el mismo día.*
--
-- **Y las opciones salen solas.** La derivación resuelve los esquemas con
-- `coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)` desde la sección de la pregunta: si
-- la sección reutiliza, salen los esquemas del prestamista. Es exactamente el camino por el que
-- funcionan las preguntas copiadas a mano de la copla real y de la novena. **La heredada se comporta
-- igual que una copiada**, que es lo que el módulo del cliente decía querer ser.
--
-- Alcanza a **3 arquitecturas de 2 formas** —las dos oncenas y el septeto compuesto—, que hasta hoy
-- no podían guardar su rima, no salían en el demarcador y no aparecían en la ficha.

begin;

create or replace view public.preguntas_metricas as
-- Lo declarado, tal cual.
select
	g.grupo_eleccion_id,
	g.arquitectura_id,
	g.slug,
	g.ayuda_editor,
	g.dimension,
	g.alcance,
	g.seccion_id,
	g.selecciones_min,
	g.selecciones_max,
	g.permite_aplicar_global,
	g.activo,
	g.orden,
	g.created_at,
	g.updated_at,
	g.tipo_control,
	g.define_norma,
	g.rasgo_id,
	g.seccion_tratada_id,
	null::uuid as heredada_de
from public.grupos_eleccion_metrica g

union all

-- Y lo heredado: la pregunta del prestamista, apuntada a la parte que la toma.
select
	md5(g.grupo_eleccion_id::text || h.seccion_id::text)::uuid as grupo_eleccion_id,
	h.arquitectura_id,
	g.slug,
	g.ayuda_editor,
	g.dimension,
	'unidad'::text as alcance,
	h.seccion_id,
	g.selecciones_min,
	g.selecciones_max,
	g.permite_aplicar_global,
	g.activo,
	g.orden,
	g.created_at,
	g.updated_at,
	g.tipo_control,
	g.define_norma,
	g.rasgo_id,
	g.seccion_tratada_id,
	g.arquitectura_id as heredada_de
from (
	select s.seccion_id, s.arquitectura_id, s.arquitectura_referenciada_id
	from public.estructuras_secciones s
	where s.arquitectura_referenciada_id is not null
		-- No hereda si la unidad ya declara su rima entera. Se exige que el esquema **tenga
		-- posiciones**: un patrón abierto y vacío no dice nada de la rima y no debe bloquear el
		-- préstamo. Es la diferencia que hace que el septeto compuesto herede y la copla
		-- castellana no.
		and not exists (
			select 1
			from public.esquemas_rima er
			join public.esquema_rima_posiciones p on p.esquema_rima_id = er.esquema_rima_id
			where er.arquitectura_id = s.arquitectura_id and er.seccion_id is null
		)
		-- Ni si la parte ya tiene rima suya, sea un esquema propio o una pregunta sobre ella:
		-- los cuartetos y los tercetos del soneto, las dos quintillas de la copla real.
		and not exists (
			select 1 from public.esquemas_rima er2
			where er2.arquitectura_id = s.arquitectura_id and er2.seccion_id = s.seccion_id
		)
		and not exists (
			select 1 from public.grupos_eleccion_metrica g2
			where g2.arquitectura_id = s.arquitectura_id
				and g2.activo
				and g2.dimension = 'rima'
				and (g2.seccion_id = s.seccion_id or g2.seccion_tratada_id = s.seccion_id)
		)
) h
join public.grupos_eleccion_metrica g
	on g.arquitectura_id = h.arquitectura_referenciada_id
	and g.activo
	-- Solo se hereda la rima, y solo la que el prestamista pregunta **de su unidad**: una que
	-- hable de una parte suya describe un interior que aquí no se materializa.
	and g.dimension = 'rima'
	and g.seccion_id is null
	and g.seccion_tratada_id is null;

comment on view public.preguntas_metricas is
	'Las preguntas del catálogo: las declaradas y las que una parte hereda de la arquitectura que reutiliza.';

-- ---------------------------------------------------------------------------
-- Las opciones se derivan también para las preguntas heredadas
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.opciones_eleccion_derivadas()
 RETURNS TABLE(grupo_eleccion_id uuid, etiqueta text, descripcion text, metro_id uuid, esquema_metrico_id uuid, esquema_rima_id uuid, seccion_id uuid, repeticion_id uuid, valor_rasgo_id uuid, variedad_id uuid, posicion_unidad integer, materializa_seccion_id uuid, extension_desde_seccion_id uuid, orden integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
		-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
		-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
		select g.grupo_eleccion_id,
			-- El régimen entra en la etiqueta cuando la arquitectura no declara uno solo: si sus
			-- disposiciones varían, es lo que las distingue, y sin él el pareado ofrecía dos opciones
			-- llamadas «aa». Es la misma regla que la ficha pública aplica a cada fila de rima.
			concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''),
				case when a.tipo_rima_id is null then (
					select tr.etiqueta from public.vocabularios tr where tr.termino_id = er.tipo_rima_id
				) end)::text,
			er.descripcion,
			null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
			null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (
				partition by g.grupo_eleccion_id order by er.nombre nulls last, er.notacion, er.slug
			)::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_rima er
			on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
		where g.dimension = 'rima' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and er.tipo_secuencia not in ('abierta', 'restricciones')
			and er.seccion_id is not distinct from g.seccion_tratada_id

		union all

		select g.grupo_eleccion_id,
			case when pos.posicion is null then adm.nombre
				else 'Verso ' || pos.posicion || ' · ' || adm.nombre end::text,
			null::text,
			adm.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, pos.posicion, null::uuid, null::uuid,
			row_number() over (
				partition by g.grupo_eleccion_id order by pos.posicion, adm.silabas
			)::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join lateral (
			select eo.metro_id, mt.silabas, mt.nombre
			from public.esquema_metrico_opciones eo
			join public.metros mt on mt.metro_id = eo.metro_id
			where eo.esquema_metrico_id = em.esquema_metrico_id
				and (
					not exists (
						select 1 from public.esquema_metrico_opciones e2
						where e2.esquema_metrico_id = em.esquema_metrico_id and e2.rol is not null
					)
					or eo.rol = 'quebrado'
				)
		) adm on true
		join lateral (
			select case when em.medida_uniforme then null::integer else n end as posicion
			from generate_series(
				1,
				case when em.medida_uniforme then 1
					else coalesce(
						s.versos_max,
						(
							select sum(h.versos_max)::integer
							from public.estructuras_secciones h
							where h.seccion_padre_id = s.seccion_id
						),
						a.unidad_versos_max,
						1
					) end
			) as n
		) pos on true
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is not null

		union all

		select g.grupo_eleccion_id,
			('Verso ' || p.posicion || ' · ' || mt.nombre)::text,
			null::text,
			p.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
			p.alternativa::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
		join public.metros mt on mt.metro_id = p.metro_id
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is null
			and p.posicion in (
				select p2.posicion from public.esquema_metrico_posiciones p2
				where p2.esquema_metrico_id = em.esquema_metrico_id
				group by p2.posicion having count(distinct p2.metro_id) > 1
			)

		union all

		select g.grupo_eleccion_id,
			case when adm.valores = 1 then r.nombre else adm.nombre end::text,
			adm.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
		from public.preguntas_metricas g
		join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
		join lateral (
			select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
				rv.descripcion,
				(select count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
					as valores
			from public.arquitectura_rasgos ar
			join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
			where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = g.rasgo_id
				and (ar.valor_id is null or ar.valor_id = rv.valor_id)
		) adm on true
		where g.dimension = 'rasgo' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and g.rasgo_id is not null

		union all

		select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			rp.repeticion_id, null::uuid, null::uuid, null::integer,
			rp.materializa_seccion_id, rp.extension_desde_seccion_id,
			row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.preguntas_metricas g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.preguntas_metricas g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$function$;

-- ---------------------------------------------------------------------------
-- Y los rótulos, que la heredada compone igual desde su sección
-- ---------------------------------------------------------------------------

create or replace view public.grupos_eleccion_metrica_resueltos as
SELECT g.grupo_eleccion_id,
    g.arquitectura_id,
    g.slug,
    g.ayuda_editor,
    g.dimension,
    g.alcance,
    g.seccion_id,
    g.selecciones_min,
    g.selecciones_max,
    g.permite_aplicar_global,
    g.activo,
    g.orden,
    g.created_at,
    g.updated_at,
    g.tipo_control,
    g.define_norma,
    g.rasgo_id,
    g.seccion_tratada_id,
        CASE
            WHEN g.dimension = 'rasgo'::text THEN rm.nombre
            WHEN g.dimension = 'repeticion'::text THEN rep.nombre
            ELSE concat_ws(' · '::text, COALESCE(s.nombre, st.nombre),
            CASE g.dimension
                WHEN 'rima'::text THEN
                CASE
                    WHEN g.tipo_control = 'esquema_rima'::text THEN 'Esquema de rima observado'::text
                    ELSE 'Esquema de rima'::text
                END
                WHEN 'metro'::text THEN
                CASE
                    WHEN m.quebrados THEN 'Medida de los quebrados'::text
                    WHEN m.posicional AND m.posiciones = 1 THEN 'Medida del verso '::text || m.primera_posicion
                    WHEN m.posicional THEN 'Medida de cada verso'::text
                    ELSE 'Medida de los versos'::text
                END
                WHEN 'combinacion'::text THEN 'Variedad'::text
                ELSE NULL::text
            END)
        END AS nombre
   FROM preguntas_metricas g
     LEFT JOIN estructuras_secciones s ON s.seccion_id = g.seccion_id
     LEFT JOIN estructuras_secciones st ON st.seccion_id = g.seccion_tratada_id
     LEFT JOIN rasgos_metricos rm ON rm.rasgo_id = g.rasgo_id
     LEFT JOIN LATERAL ( SELECT COALESCE(bool_and(o.posicion_unidad IS NOT NULL), false) AS posicional,
            COALESCE(bool_or(eo.rol = 'quebrado'::text), false) AS quebrados,
            count(DISTINCT o.posicion_unidad) FILTER (WHERE o.posicion_unidad IS NOT NULL) AS posiciones,
            min(o.posicion_unidad) AS primera_posicion
           FROM opciones_eleccion_metrica o
             LEFT JOIN esquemas_metricos em ON em.arquitectura_id = g.arquitectura_id
             LEFT JOIN esquema_metrico_opciones eo ON eo.esquema_metrico_id = em.esquema_metrico_id AND eo.metro_id = o.metro_id
          WHERE o.grupo_eleccion_id = g.grupo_eleccion_id) m ON g.dimension = 'metro'::text
     LEFT JOIN LATERAL ( SELECT ms.nombre
           FROM repeticiones_metricas rp
             JOIN estructuras_secciones ms ON ms.seccion_id = rp.materializa_seccion_id
          WHERE rp.arquitectura_id = g.arquitectura_id
         LIMIT 1) rep ON g.dimension = 'repeticion'::text;;

-- ---------------------------------------------------------------------------
-- El invariante alcanza a las heredadas
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.preguntas_que_ofrecen_una_definitoria()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
	v_mal text;
	v_n integer;
begin
	-- La pregunta se hace sobre las opciones **derivadas**, que es lo que la aplicación lee: un
	-- esquema puede estar bien escrito y aun así acabar ofrecido por la función que las genera.
	select count(*), string_agg(distinct linea, '; ')
	into v_n, v_mal
	from (
		select f.nombre || ' · ' || a.nombre || ' · ' || g.slug as linea
		from public.preguntas_metricas g
		join public.opciones_eleccion_metrica o on o.grupo_eleccion_id = g.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		left join public.repeticiones_metricas rm on rm.repeticion_id = o.repeticion_id
		left join public.variedades_arquitectura va on va.variedad_id = o.variedad_id
		-- **Solo las filas con `valor_id`.** Sin él la modalidad habla del rasgo entero y no de
		-- ninguna opción, así que un rasgo definitorio con sus valores elegibles sigue siendo
		-- correcto: lo que caracteriza la arquitectura es que ese rasgo cuente, no cuál de sus
		-- valores se lea.
		left join public.arquitectura_rasgos ar
			on ar.arquitectura_id = g.arquitectura_id
			and ar.rasgo_id = g.rasgo_id
			and ar.valor_id = o.valor_rasgo_id
		where g.activo
			and 'definitoria' in (
				coalesce(er.modalidad, ''),
				coalesce(rm.modalidad, ''),
				coalesce(va.modalidad, ''),
				coalesce(ar.modalidad, '')
			)
	) malas;

	if v_n = 0 then
		return null;
	end if;
	return v_n || ' pregunta(s): ' || v_mal;
end;
$function$;


-- ---------------------------------------------------------------------------
-- La validación busca en un solo sitio
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

	-- Un tramo sin forma no declara arquitectura: su respuesta se sostiene sola.
	if v_arquitectura is null then
		return new;
	end if;

	if v_entidades = 1 then
		-- ¿La ofrece el catálogo? Se busca entre las preguntas de la arquitectura, **heredadas
		-- incluidas**: ya no hace falta preguntar aparte por lo que la parte reutiliza.
		select exists (
			select 1
			from public.opciones_eleccion_metrica o
			join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
			where g.activo
				and g.arquitectura_id = v_arquitectura
				and g.dimension = new.dimension
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and g.seccion_id is not distinct from (
					case when v_padre is not null then v_seccion_unidad end
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
			from public.preguntas_metricas g
			where g.activo
				and g.arquitectura_id = v_arquitectura
				and g.dimension = new.dimension
				and g.tipo_control in ('esquema_rima', 'opciones_y_esquema')
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and g.seccion_id is not distinct from (
					case when v_padre is not null then v_seccion_unidad end
				)
		) into v_admitida;

		if not v_admitida then
			raise exception 'Esta arquitectura no admite escribir la respuesta en la dimensión %', new.dimension;
		end if;

		-- Una notación se lee verso a verso. Se descuentan los separadores que la propia notación
		-- trae —`abcabc|defdef`, `abba:cdcd`— y los espacios.
		v_escrito := length(regexp_replace(new.valor_texto, '[:|[:space:]]', '', 'g'));
		if v_longitud is not null and v_escrito <> v_longitud then
			raise exception 'El esquema de rima debe tener % posiciones y tiene %', v_longitud, v_escrito;
		end if;
	end if;

	return new;
end;
$validar$;

-- ---------------------------------------------------------------------------
-- Y la relectura también
-- ---------------------------------------------------------------------------

drop view if exists public.anotacion_elecciones_resueltas;

create view public.anotacion_elecciones_resueltas as
select
	e.*,
	resuelta.grupo_eleccion_id,
	resuelta.opcion_eleccion_id
from public.anotacion_elecciones e
join public.anotaciones_metricas am on am.anotacion_id = e.anotacion_id
left join public.anotacion_realizaciones rz on rz.realizacion_id = e.realizacion_id
left join lateral (
	select g.grupo_eleccion_id, o.opcion_eleccion_id
	from public.preguntas_metricas g
	left join public.opciones_eleccion_metrica o
		on o.grupo_eleccion_id = g.grupo_eleccion_id
		and o.metro_id is not distinct from e.metro_id
		and o.esquema_metrico_id is not distinct from e.esquema_metrico_id
		and o.esquema_rima_id is not distinct from e.esquema_rima_id
		and o.seccion_id is not distinct from e.seccion_id
		and o.repeticion_id is not distinct from e.repeticion_id
		and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
		and o.variedad_id is not distinct from e.variedad_id
		and o.posicion_unidad is not distinct from e.posicion_unidad
	where g.activo
		and g.arquitectura_id = am.arquitectura_id
		and g.dimension = e.dimension
		and g.seccion_tratada_id is not distinct from e.seccion_tratada_id
		and g.seccion_id is not distinct from (
			case when rz.realizacion_padre_id is not null then rz.seccion_id end
		)
		-- Un rasgo se distingue por su valor, que pertenece a uno solo: el endecasílabo suelto
		-- tiene cinco preguntas de rasgo y ninguna ambigüedad.
		and (
			e.dimension <> 'rasgo'
			or exists (
				select 1 from public.rasgo_valores rv
				where rv.valor_id = e.valor_rasgo_id and rv.rasgo_id = g.rasgo_id
			)
		)
	order by (o.opcion_eleccion_id is not null) desc, g.orden nulls last
	limit 1
) resuelta on true;

comment on view public.anotacion_elecciones_resueltas is
	'Las respuestas con la pregunta y la opción que les corresponden hoy, derivadas de lo que cada una afirma.';

do $comprobacion$
declare
	v_heredadas integer;
	v_opciones integer;
	v_definitorias text;
	v_filas integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta todo lo que se ha tocado**, porque una vista o una función mal escritas
	-- compilan igual y solo fallan al leerse.
	select count(*) into v_heredadas
	from public.preguntas_metricas where heredada_de is not null;

	if v_heredadas <> 6 then
		raise exception 'Se heredan % preguntas, y eran 6: las cuatro de las oncenas y las dos del septeto compuesto.', v_heredadas;
	end if;

	-- Las opciones de una pregunta heredada salen solas, por la sección que reutiliza.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica o
	join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.heredada_de is not null;

	if v_opciones < 1 then
		raise exception 'Las preguntas heredadas no ofrecen ninguna opción: la derivación no las alcanza.';
	end if;

	raise notice 'Las 6 preguntas heredadas ofrecen % opciones en total.', v_opciones;

	-- El invariante sigue en pie: ninguna pregunta ofrece una definitoria, tampoco las heredadas.
	select public.preguntas_que_ofrecen_una_definitoria() into v_definitorias;
	if v_definitorias is not null and btrim(v_definitorias) <> '' then
		raise exception 'Alguna pregunta ofrece una definitoria: %', v_definitorias;
	end if;

	-- Y los rótulos se componen igual: la heredada dice de qué parte habla.
	if not exists (
		select 1 from public.grupos_eleccion_metrica_resueltos g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = 'Oncena' and g.dimension = 'rima' and g.nombre like '%·%'
	) then
		raise exception 'La oncena no ofrece preguntas de rima con el nombre de su parte.';
	end if;

	select count(*) into v_filas from public.anotacion_elecciones_resueltas;
	raise notice 'La vista de respuestas resuelve y devuelve % filas.', v_filas;
end
$comprobacion$;

commit;
