-- El puente con lo viejo también dice a qué respuesta equivale
--
-- Última pieza de C20. Desde que la respuesta **se describe a sí misma**, quedaba un sitio donde
-- seguía escrito el modelo anterior: `equivalencias_respuestas_legadas`, las 26 filas que traducen
-- el vocabulario legado a respuestas del catálogo nuevo. Cada una guardaba **la entidad que afirma**
-- —eso ya estaba bien— **y además el identificador de la pregunta**, con clave ajena a
-- `grupos_eleccion_metrica`.
--
-- Sobra, y estorba de dos maneras:
--
-- 1. **No puede nombrar una pregunta heredada.** El identificador de una heredada se deriva con
--    `md5(...)` y no existe como fila, así que ninguna clave ajena lo alcanza. Hoy no hay ninguna
--    entre las 26, pero la rima de la oncena y la del septeto compuesto son exactamente eso, y
--    migrar sus secuencias exigiría inventar una fila de pregunta que C20 acaba de dejar de
--    necesitar.
-- 2. **Duplica el emparejamiento.** Al migrar una secuencia legada hay que escribir en
--    `anotacion_elecciones`, que pide dimensión y parte. Con la pregunta por delante, esa
--    conversión sería un segundo sitio donde vive la misma regla.
--
-- La equivalencia pasa a decir lo mismo que una respuesta: **de qué habla** —arquitectura,
-- dimensión, parte de la unidad y parte tratada— y **qué afirma** —la entidad, que ya guardaba—.
--
-- **Se comprueba fila a fila, y de dos maneras.** Antes de tocar nada se guarda lo que la vista de
-- propuestas responde hoy; después se comprueba que responde exactamente lo mismo, fila a fila, y
-- que las 26 equivalencias resuelven a la misma pregunta y a la misma opción que resolvían. Medido
-- fuera, sobre la base viva, el emparejamiento nuevo devuelve las mismas 26 ternas: ni pierde ni
-- añade ninguna.
--
-- *Sobre `seccion_id`:* ninguna de las 26 la usa, y podría no existir. Va porque sin ella el
-- emparejamiento no se puede escribir como lo escribe el resolutor de respuestas —`g.seccion_id`
-- contra la sección de la unidad—, y tendría que decir `is null`, que deja fuera en silencio a las
-- preguntas de una parte. Una regla, una forma.

begin;

-- ---------------------------------------------------------------------------
-- Las coordenadas de la respuesta
-- ---------------------------------------------------------------------------

alter table public.equivalencias_respuestas_legadas
	add column if not exists arquitectura_id uuid,
	add column if not exists dimension text,
	add column if not exists seccion_id uuid,
	add column if not exists seccion_tratada_id uuid;

comment on column public.equivalencias_respuestas_legadas.arquitectura_id is
	'La arquitectura de cuya norma habla la respuesta.';
comment on column public.equivalencias_respuestas_legadas.dimension is
	'De qué habla: metro, rima, repeticion, rasgo o combinacion. Los mismos valores que una respuesta anotada.';
comment on column public.equivalencias_respuestas_legadas.seccion_id is
	'La parte cuyas unidades responden, si la pregunta va dentro de una parte.';
comment on column public.equivalencias_respuestas_legadas.seccion_tratada_id is
	'La parte de la que habla, cuando la respuesta se da en la unidad: los cuartetos y los tercetos del soneto.';

do $traslado$
declare
	v_sin_coordenadas integer;
	v_movidas integer;
begin
	-- ------------------------------------------------------------------ El traslado
	--
	-- Solo hay algo que trasladar mientras exista la columna vieja. Si ya se retiró, esta
	-- migración vuelve a pasar sin hacer nada.
	if not exists (
		select 1 from information_schema.columns
		where table_schema = 'public'
			and table_name = 'equivalencias_respuestas_legadas'
			and column_name = 'grupo_eleccion_id'
	) then
		raise notice 'El puente ya habla de respuestas: no hay nada que trasladar.';
		return;
	end if;

	-- Lo que la vista de propuestas responde **hoy**, para comprobar después que responde igual.
	create temporary table equivalencias_antes on commit drop as
	select * from public.propuesta_elecciones_secuencia;

	-- Y a qué resuelve hoy cada equivalencia, que es lo que no puede cambiar.
	execute $sql$
		create temporary table reclamado_antes on commit drop as
		select e.termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
		from public.equivalencias_respuestas_legadas e
		join public.opciones_eleccion_metrica o
			on o.grupo_eleccion_id = e.grupo_eleccion_id
			and o.metro_id is not distinct from e.metro_id
			and o.esquema_rima_id is not distinct from e.esquema_rima_id
			and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
			and o.variedad_id is not distinct from e.variedad_id
			and o.repeticion_id is not distinct from e.repeticion_id
			and o.posicion_unidad is not distinct from e.posicion_unidad
	$sql$;

	execute $sql$
		update public.equivalencias_respuestas_legadas e
		set arquitectura_id = g.arquitectura_id,
			dimension = g.dimension,
			seccion_id = g.seccion_id,
			seccion_tratada_id = g.seccion_tratada_id
		from public.grupos_eleccion_metrica g
		where g.grupo_eleccion_id = e.grupo_eleccion_id
	$sql$;

	get diagnostics v_movidas = row_count;

	select count(*) into v_sin_coordenadas
	from public.equivalencias_respuestas_legadas
	where arquitectura_id is null or dimension is null;

	if v_sin_coordenadas > 0 then
		raise exception '% equivalencias se han quedado sin arquitectura o sin dimensión.', v_sin_coordenadas;
	end if;

	raise notice 'Trasladadas % equivalencias.', v_movidas;
end
$traslado$;

do $ataduras$
begin
	-- ------------------------------------------------------------------ Lo que ya no puede fallar
	--
	-- Las mismas ataduras que lleva una respuesta anotada: la dimensión de un vocabulario cerrado,
	-- y la entidad atada a su dimensión.
	if not exists (
		select 1 from pg_constraint
		where conrelid = 'public.equivalencias_respuestas_legadas'::regclass
			and conname = 'equivalencias_respuestas_legadas_dimension_check'
	) then
		alter table public.equivalencias_respuestas_legadas
			alter column arquitectura_id set not null,
			alter column dimension set not null,
			add constraint equivalencias_respuestas_legadas_dimension_check
				check (dimension in ('metro', 'rima', 'repeticion', 'rasgo', 'combinacion')),
			add constraint equivalencias_respuestas_legadas_entidad_dimension_check
				check (
					(metro_id is null or dimension = 'metro')
					and (esquema_rima_id is null or dimension = 'rima')
					and (valor_rasgo_id is null or dimension = 'rasgo')
					and (repeticion_id is null or dimension = 'repeticion')
					and (variedad_id is null or dimension = 'combinacion')
				),
			add constraint equivalencias_respuestas_legadas_arquitectura_id_fkey
				foreign key (arquitectura_id) references public.arquitecturas_forma (arquitectura_id)
				on update cascade on delete cascade,
			add constraint equivalencias_respuestas_legadas_seccion_id_fkey
				foreign key (seccion_id) references public.estructuras_secciones (seccion_id)
				on update cascade on delete cascade,
			add constraint equivalencias_respuestas_legadas_seccion_tratada_id_fkey
				foreign key (seccion_tratada_id) references public.estructuras_secciones (seccion_id)
				on update cascade on delete cascade;
	end if;
end
$ataduras$;

-- ---------------------------------------------------------------------------
-- La propuesta empareja por lo que la equivalencia afirma
-- ---------------------------------------------------------------------------

create or replace view public.propuesta_elecciones_secuencia as
 WITH opciones_derivadas AS MATERIALIZED (
         SELECT opciones_eleccion_metrica.opcion_eleccion_id,
            opciones_eleccion_metrica.grupo_eleccion_id,
            opciones_eleccion_metrica.slug,
            opciones_eleccion_metrica.nombre,
            opciones_eleccion_metrica.descripcion,
            opciones_eleccion_metrica.metro_id,
            opciones_eleccion_metrica.esquema_metrico_id,
            opciones_eleccion_metrica.esquema_rima_id,
            opciones_eleccion_metrica.seccion_id,
            opciones_eleccion_metrica.repeticion_id,
            opciones_eleccion_metrica.rasgo_id,
            opciones_eleccion_metrica.valor_rasgo_id,
            opciones_eleccion_metrica.activo,
            opciones_eleccion_metrica.orden,
            opciones_eleccion_metrica.created_at,
            opciones_eleccion_metrica.updated_at,
            opciones_eleccion_metrica.materializa_seccion_id,
            opciones_eleccion_metrica.extension_desde_seccion_id,
            opciones_eleccion_metrica.posicion_unidad,
            opciones_eleccion_metrica.variedad_id
           FROM opciones_eleccion_metrica
        ), reclamado AS (
         SELECT er.origen_termino_id AS termino_id,
            o.grupo_eleccion_id,
            o.opcion_eleccion_id
           FROM esquemas_rima er
             JOIN opciones_derivadas o ON o.esquema_rima_id = er.esquema_rima_id
          WHERE er.origen_termino_id IS NOT NULL
        UNION
         SELECT rv.origen_termino_id,
            o.grupo_eleccion_id,
            o.opcion_eleccion_id
           FROM rasgo_valores rv
             JOIN opciones_derivadas o ON o.valor_rasgo_id = rv.valor_id
          WHERE rv.origen_termino_id IS NOT NULL
        UNION
         SELECT va.origen_termino_id,
            o.grupo_eleccion_id,
            o.opcion_eleccion_id
           FROM variedades_arquitectura va
             JOIN opciones_derivadas o ON o.variedad_id = va.variedad_id
          WHERE va.origen_termino_id IS NOT NULL
        UNION
         SELECT m.origen_termino_id,
            o.grupo_eleccion_id,
            o.opcion_eleccion_id
           FROM metros m
             JOIN opciones_derivadas o ON o.metro_id = m.metro_id
          WHERE m.origen_termino_id IS NOT NULL
        UNION
         -- La equivalencia ya no nombra una pregunta: dice **de qué habla** —arquitectura,
         -- dimensión y parte— y **qué afirma**, igual que una respuesta anotada. La pregunta se
         -- deriva aquí, y por eso alcanza también a las heredadas, que no tienen fila propia.
         SELECT e.termino_id,
            g.grupo_eleccion_id,
            o.opcion_eleccion_id
           FROM equivalencias_respuestas_legadas e
             JOIN preguntas_metricas g ON g.arquitectura_id = e.arquitectura_id AND g.dimension = e.dimension AND NOT g.seccion_id IS DISTINCT FROM e.seccion_id AND NOT g.seccion_tratada_id IS DISTINCT FROM e.seccion_tratada_id AND g.activo
             JOIN opciones_derivadas o ON o.grupo_eleccion_id = g.grupo_eleccion_id AND NOT o.metro_id IS DISTINCT FROM e.metro_id AND NOT o.esquema_rima_id IS DISTINCT FROM e.esquema_rima_id AND NOT o.valor_rasgo_id IS DISTINCT FROM e.valor_rasgo_id AND NOT o.variedad_id IS DISTINCT FROM e.variedad_id AND NOT o.repeticion_id IS DISTINCT FROM e.repeticion_id AND NOT o.posicion_unidad IS DISTINCT FROM e.posicion_unidad
        ), base AS (
         SELECT p.secuencia_id,
            p.estrofa_tipo_id,
            p.v_ini,
            p.v_fin,
            p.arquitectura_propuesta_id,
            a.unidad_versos_min AS unidad
           FROM propuesta_metrica_secuencia p
             LEFT JOIN arquitecturas_forma a ON a.arquitectura_id = p.arquitectura_propuesta_id
        ), unidades AS (
         SELECT b.secuencia_id,
            b.estrofa_tipo_id,
            b.arquitectura_propuesta_id,
            b.v_ini + (i.i - 1) * b.unidad AS unidad_v_ini,
            b.v_ini + i.i * b.unidad - 1 AS unidad_v_fin
           FROM base b
             CROSS JOIN LATERAL generate_series(1, (b.v_fin - b.v_ini + 1) / b.unidad) i(i)
          WHERE b.unidad IS NOT NULL AND b.unidad > 0 AND (b.v_fin - b.v_ini + 1) >= b.unidad
        ), anotada AS (
         SELECT DISTINCT b.secuencia_id,
            g.grupo_eleccion_id,
            g.nombre AS pregunta,
            o.opcion_eleccion_id,
            o.nombre AS respuesta,
            g.alcance,
            t.v_ini AS unidad_v_ini,
            t.v_fin AS unidad_v_fin
           FROM base b
             JOIN secuencias_subtipos_estrofa t ON t.secuencia_id = b.secuencia_id
             JOIN esquemas_rima er ON er.origen_termino_id = t.subtipo_estrofa_id
             JOIN opciones_derivadas o ON o.esquema_rima_id = er.esquema_rima_id
             JOIN grupos_eleccion_metrica_resueltos g ON g.grupo_eleccion_id = o.grupo_eleccion_id AND g.arquitectura_id = b.arquitectura_propuesta_id AND g.activo AND g.alcance = 'unidad'::text
        ), derivada_unidad AS (
         SELECT u.secuencia_id,
            g.grupo_eleccion_id,
            g.nombre AS pregunta,
            r.opcion_eleccion_id,
            o.nombre AS respuesta,
            g.alcance,
            u.unidad_v_ini,
            u.unidad_v_fin
           FROM unidades u
             JOIN reclamado r ON r.termino_id = u.estrofa_tipo_id
             JOIN grupos_eleccion_metrica_resueltos g ON g.grupo_eleccion_id = r.grupo_eleccion_id AND g.arquitectura_id = u.arquitectura_propuesta_id AND g.activo AND g.alcance = 'unidad'::text
             JOIN opciones_derivadas o ON o.opcion_eleccion_id = r.opcion_eleccion_id
          WHERE NOT (EXISTS ( SELECT 1
                   FROM anotada an
                  WHERE an.secuencia_id = u.secuencia_id AND an.grupo_eleccion_id = g.grupo_eleccion_id))
        ), derivada_secuencia AS (
         SELECT b.secuencia_id,
            g.grupo_eleccion_id,
            g.nombre AS pregunta,
            r.opcion_eleccion_id,
            o.nombre AS respuesta,
            g.alcance,
            NULL::integer AS unidad_v_ini,
            NULL::integer AS unidad_v_fin
           FROM base b
             JOIN reclamado r ON r.termino_id = b.estrofa_tipo_id
             JOIN grupos_eleccion_metrica_resueltos g ON g.grupo_eleccion_id = r.grupo_eleccion_id AND g.arquitectura_id = b.arquitectura_propuesta_id AND g.activo AND g.alcance <> 'unidad'::text
             JOIN opciones_derivadas o ON o.opcion_eleccion_id = r.opcion_eleccion_id
        )
 SELECT anotada.secuencia_id,
    anotada.grupo_eleccion_id,
    anotada.pregunta,
    anotada.opcion_eleccion_id,
    anotada.respuesta,
    anotada.alcance,
    anotada.unidad_v_ini,
    anotada.unidad_v_fin,
    'anotada'::text AS origen
   FROM anotada
UNION ALL
 SELECT derivada_unidad.secuencia_id,
    derivada_unidad.grupo_eleccion_id,
    derivada_unidad.pregunta,
    derivada_unidad.opcion_eleccion_id,
    derivada_unidad.respuesta,
    derivada_unidad.alcance,
    derivada_unidad.unidad_v_ini,
    derivada_unidad.unidad_v_fin,
    'derivada'::text AS origen
   FROM derivada_unidad
UNION ALL
 SELECT derivada_secuencia.secuencia_id,
    derivada_secuencia.grupo_eleccion_id,
    derivada_secuencia.pregunta,
    derivada_secuencia.opcion_eleccion_id,
    derivada_secuencia.respuesta,
    derivada_secuencia.alcance,
    derivada_secuencia.unidad_v_ini,
    derivada_secuencia.unidad_v_fin,
    'derivada'::text AS origen
   FROM derivada_secuencia;;

-- ---------------------------------------------------------------------------
-- Y se retira lo que ya no se usa
-- ---------------------------------------------------------------------------

alter table public.equivalencias_respuestas_legadas
	drop column if exists grupo_eleccion_id;

do $comprobacion$
declare
	v_reclamado integer;
	v_perdidas integer;
	v_sobrantes integer;
	v_antes integer;
	v_despues integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la vista**, que es lo único que prueba que sigue en pie: una vista mal escrita
	-- se crea igual y solo falla al leerse.
	select count(*) into v_despues from public.propuesta_elecciones_secuencia;

	if to_regclass('pg_temp.reclamado_antes') is null then
		raise notice 'La vista responde con % filas. Sin instantánea previa: nada que comparar.', v_despues;
		return;
	end if;

	-- Cada una de las 26 debe resolver a la misma pregunta y a la misma opción que resolvía.
	with ahora as (
		select e.termino_id, g.grupo_eleccion_id, o.opcion_eleccion_id
		from public.equivalencias_respuestas_legadas e
		join public.preguntas_metricas g
			on g.arquitectura_id = e.arquitectura_id
			and g.dimension = e.dimension
			and g.seccion_id is not distinct from e.seccion_id
			and g.seccion_tratada_id is not distinct from e.seccion_tratada_id
			and g.activo
		join public.opciones_eleccion_metrica o
			on o.grupo_eleccion_id = g.grupo_eleccion_id
			and o.metro_id is not distinct from e.metro_id
			and o.esquema_rima_id is not distinct from e.esquema_rima_id
			and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
			and o.variedad_id is not distinct from e.variedad_id
			and o.repeticion_id is not distinct from e.repeticion_id
			and o.posicion_unidad is not distinct from e.posicion_unidad
	)
	select
		(select count(*) from ahora),
		(select count(*) from (select * from reclamado_antes except select * from ahora) x),
		(select count(*) from (select * from ahora except select * from reclamado_antes) x)
	into v_reclamado, v_perdidas, v_sobrantes;

	if v_perdidas > 0 or v_sobrantes > 0 then
		raise exception 'El puente ha cambiado de destino: % equivalencias se pierden y % aparecen de la nada.',
			v_perdidas, v_sobrantes;
	end if;

	-- Y la vista de propuestas responde exactamente lo mismo, fila a fila.
	select count(*) into v_antes from equivalencias_antes;
	select count(*) into v_perdidas
	from (select * from equivalencias_antes except select * from public.propuesta_elecciones_secuencia) x;
	select count(*) into v_sobrantes
	from (select * from public.propuesta_elecciones_secuencia except select * from equivalencias_antes) x;

	if v_perdidas > 0 or v_sobrantes > 0 then
		raise exception 'La propuesta ya no dice lo mismo: % filas se pierden y % aparecen.',
			v_perdidas, v_sobrantes;
	end if;

	raise notice 'Las % equivalencias resuelven igual y la propuesta responde las mismas % filas.',
		v_reclamado, v_antes;
end
$comprobacion$;

commit;
