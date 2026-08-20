-- El catálogo no lleva su propio estado de revisión
--
-- `estado_revision` se retira de las doce tablas del dominio métrico. No es una limpieza
-- estética: la columna prometía algo que no cumplía, y lo que guardaba era ruido.
--
-- **No la escribía nadie.** Sus únicos escritores eran las seis pantallas del gestor mutable, que
-- se retiró el 11 de agosto de 2026 justamente para que todo pasara por migración. Desde
-- entonces ninguna ruta las monta: son código muerto, y se van con la columna.
--
-- **No la leía casi nadie.** De todo el SQL vivo, un solo sitio la miraba:
-- `regla_longitud_arquitectura_metrica` filtraba `estado_revision <> 'retirada'` sobre los
-- esquemas de rima y los métricos. Ningún esquema ha estado nunca retirado, así que ese filtro
-- no excluyó jamás una fila. Ni la ficha pública, ni el editor, ni el demarcador, ni el auditor
-- la consultaban.
--
-- **Y lo que decía era falso.** El 20 de agosto de 2026, `terceto_encadenado` y `pareado` tenían
-- arquitecturas en `borrador` —el terceto encadenado se había revisado a fondo el día anterior—,
-- y `verso_aislado` e `irregular` seguían en `revisada` mientras las veintiséis formas estaban en
-- `aprobada`. No registraba un estado: registraba cuándo tocó cada fila por última vez una
-- pantalla que ya no existe.
--
-- **La revisión es la migración.** Desde que el catálogo solo cambia por aquí, cada cambio queda
-- revisado en `git` con su razón escrita. Una columna por fila que diga «borrador, revisada,
-- aprobada» duplica el historial sin que nada la compruebe.
--
-- Lo que sí se queda es **`activo`**, que es el interruptor de verdad: lo filtran nueve funciones
-- y es lo que permitió retirar la copla de pie quebrado de la ficha, del catálogo y del
-- demarcador a la vez. La norma queda así: **una forma o una arquitectura se retiran con `activo
-- = false`; lo que cuelga de una arquitectura se retira con ella; y un esquema, una sección o una
-- variedad sueltos se borran, porque todas las claves ajenas del editor son `on delete restrict`
-- y la base impide sola borrar lo que una anotación use.**
--
-- **Cuidado con la homónima:** `permissions.ts` y `/dashboard/vocabularios` mencionan un
-- `estado_revision` que **no es este** — es una categoría del vocabulario legado, el flujo de las
-- obras. No se toca.
--
-- La vista y la función se recrean sin la columna **y se ejecutan** en la guarda: un cuerpo
-- entrecomillado no se revalida al borrar una columna, y esta trampa ya ha mordido cuatro veces.

begin;

-- `propuesta_elecciones_secuencia` se apoya en la vista de grupos resueltos aunque no use la
-- columna: hay que apartarla para recrear la de abajo, y vuelve tal cual al final.
drop view if exists public.propuesta_elecciones_secuencia;
drop view if exists public.grupos_eleccion_metrica_resueltos;

alter table public.afirmaciones_fuentes_metricas drop column if exists estado_revision;
alter table public.arquitecturas_forma drop column if exists estado_revision;
alter table public.esquemas_metricos drop column if exists estado_revision;
alter table public.esquemas_rima drop column if exists estado_revision;
alter table public.forma_relaciones drop column if exists estado_revision;
alter table public.formas_metricas drop column if exists estado_revision;
alter table public.grupos_eleccion_metrica drop column if exists estado_revision;
alter table public.metros drop column if exists estado_revision;
alter table public.rasgos_metricos drop column if exists estado_revision;
alter table public.repeticiones_metricas drop column if exists estado_revision;
alter table public.tradiciones_metricas drop column if exists estado_revision;
alter table public.variedades_arquitectura drop column if exists estado_revision;

create view public.grupos_eleccion_metrica_resueltos as
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
                    WHEN m.posicional THEN 'Medida de cada verso'::text
                    ELSE 'Medida de los versos'::text
                END
                WHEN 'combinacion'::text THEN 'Variedad'::text
                ELSE NULL::text
            END)
        END AS nombre
   FROM grupos_eleccion_metrica g
     LEFT JOIN estructuras_secciones s ON s.seccion_id = g.seccion_id
     LEFT JOIN estructuras_secciones st ON st.seccion_id = g.seccion_tratada_id
     LEFT JOIN rasgos_metricos rm ON rm.rasgo_id = g.rasgo_id
     LEFT JOIN LATERAL ( SELECT COALESCE(bool_and(o.posicion_unidad IS NOT NULL), false) AS posicional,
            COALESCE(bool_and(eo.rol = 'quebrado'::text), false) AS quebrados
           FROM opciones_eleccion_metrica o
             LEFT JOIN esquemas_metricos em ON em.arquitectura_id = g.arquitectura_id
             LEFT JOIN esquema_metrico_opciones eo ON eo.esquema_metrico_id = em.esquema_metrico_id AND eo.metro_id = o.metro_id
          WHERE o.grupo_eleccion_id = g.grupo_eleccion_id) m ON g.dimension = 'metro'::text
     LEFT JOIN LATERAL ( SELECT ms.nombre
           FROM repeticiones_metricas rp
             JOIN estructuras_secciones ms ON ms.seccion_id = rp.materializa_seccion_id
          WHERE rp.arquitectura_id = g.arquitectura_id
         LIMIT 1) rep ON g.dimension = 'repeticion'::text;;

CREATE OR REPLACE FUNCTION public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
 RETURNS TABLE(modulo_versos integer, residuo_versos integer, minimo_versos integer, origen text, explicacion text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare
	v_unidad_min integer;
	v_unidad_max integer;
	v_total_secciones integer;
	v_secciones_no_derivables integer;
	v_secciones_abiertas integer;
	v_longitud_abierta integer;
	v_longitud_minima integer;
	v_longitud_fija integer;
	v_total_patrones integer;
	v_patrones_con_posiciones integer;
	v_longitudes_distintas integer;
	v_longitud_ciclo integer;
begin
	select arquitectura.unidad_versos_min, arquitectura.unidad_versos_max
	into v_unidad_min, v_unidad_max
	from public.arquitecturas_forma arquitectura
	where arquitectura.arquitectura_id = p_arquitectura_id
		and arquitectura.activo;

	if not found then
		return;
	end if;

	if v_unidad_min is not null then
		if v_unidad_min = v_unidad_max and v_unidad_min > 1 then
			return query
			select
				v_unidad_min,
				0,
				v_unidad_min,
				'unidad'::text,
				format('unidades completas de %s versos', v_unidad_min);
		elsif v_unidad_max > v_unidad_min then
			-- Una unidad de extensión variable no produce congruencia: solo su mínimo.
			return query
			select
				1,
				0,
				v_unidad_min,
				'unidad'::text,
				format('unidades de %s a %s versos', v_unidad_min, v_unidad_max);
		end if;
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (
			where seccion.versos_min is null
				or seccion.versos_max is null
				or seccion.versos_min <> seccion.versos_max
				or (
					seccion.repeticiones_max is not null
					and coalesce(seccion.repeticiones_min, 0) <> seccion.repeticiones_max
				)
		)::integer,
		count(*) filter (where seccion.repeticiones_max is null)::integer,
		max(seccion.versos_min) filter (where seccion.repeticiones_max is null)::integer,
		coalesce(
			sum(seccion.versos_min * coalesce(seccion.repeticiones_min, 0)),
			0
		)::integer,
		coalesce(
			sum(
				seccion.versos_min * coalesce(seccion.repeticiones_min, 0)
			) filter (where seccion.repeticiones_max is not null),
			0
		)::integer
	into
		v_total_secciones,
		v_secciones_no_derivables,
		v_secciones_abiertas,
		v_longitud_abierta,
		v_longitud_minima,
		v_longitud_fija
	from public.estructuras_secciones seccion
	where seccion.arquitectura_id = p_arquitectura_id
		and seccion.seccion_padre_id is null;

	if v_total_secciones > 0 and v_secciones_no_derivables = 0 then
		if v_secciones_abiertas = 0 and v_longitud_minima > 1 then
			return query
			select
				v_longitud_minima,
				0,
				v_longitud_minima,
				'secciones_fijas'::text,
				format('estructuras completas de %s versos', v_longitud_minima);
			return;
		elsif v_secciones_abiertas = 1 and v_longitud_abierta > 1 then
			return query
			select
				v_longitud_abierta,
				mod(v_longitud_fija, v_longitud_abierta),
				v_longitud_minima,
				'secciones_repetibles'::text,
				case
					when v_longitud_fija = 0 then
						format('bloques completos de %s versos', v_longitud_abierta)
					else
						format(
							'bloques completos de %s versos más %s %s fijo%s',
							v_longitud_abierta,
							v_longitud_fija,
							case when v_longitud_fija = 1 then 'verso' else 'versos' end,
							case when v_longitud_fija = 1 then '' else 's' end
						)
				end;
			return;
		end if;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			rima.esquema_rima_id,
			count(posicion.posicion_id)::integer as longitud
		from public.esquemas_rima rima
		left join public.esquema_rima_posiciones posicion
			on posicion.esquema_rima_id = rima.esquema_rima_id
		where rima.arquitectura_id = p_arquitectura_id
			and rima.tipo_secuencia = 'ciclo'
		group by rima.esquema_rima_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_rima'::text,
			format('ciclos completos de rima de %s versos', v_longitud_ciclo);
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			metrico.esquema_metrico_id,
			count(posicion.posicion_id)::integer as longitud
		from public.esquemas_metricos metrico
		left join public.esquema_metrico_posiciones posicion
			on posicion.esquema_metrico_id = metrico.esquema_metrico_id
		where metrico.arquitectura_id = p_arquitectura_id
			and metrico.tipo_secuencia = 'ciclo'
		group by metrico.esquema_metrico_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_metrico'::text,
			format('ciclos métricos completos de %s versos', v_longitud_ciclo);
	end if;
end;
$function$
;

create view public.propuesta_elecciones_secuencia as
 WITH derivado AS (
         SELECT er.origen_termino_id AS termino_id,
            o_1.grupo_eleccion_id,
            o_1.opcion_eleccion_id
           FROM esquemas_rima er
             JOIN opciones_eleccion_metrica o_1 ON o_1.esquema_rima_id = er.esquema_rima_id
          WHERE er.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT rv.origen_termino_id,
            o_1.grupo_eleccion_id,
            o_1.opcion_eleccion_id
           FROM rasgo_valores rv
             JOIN opciones_eleccion_metrica o_1 ON o_1.valor_rasgo_id = rv.valor_id
          WHERE rv.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT va.origen_termino_id,
            o_1.grupo_eleccion_id,
            o_1.opcion_eleccion_id
           FROM variedades_arquitectura va
             JOIN opciones_eleccion_metrica o_1 ON o_1.variedad_id = va.variedad_id
          WHERE va.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT m.origen_termino_id,
            o_1.grupo_eleccion_id,
            o_1.opcion_eleccion_id
           FROM metros m
             JOIN opciones_eleccion_metrica o_1 ON o_1.metro_id = m.metro_id
          WHERE m.origen_termino_id IS NOT NULL
        ), declarado AS (
         SELECT e.termino_id,
            e.grupo_eleccion_id,
            o_1.opcion_eleccion_id
           FROM equivalencias_respuestas_legadas e
             JOIN opciones_eleccion_metrica o_1 ON o_1.grupo_eleccion_id = e.grupo_eleccion_id AND NOT o_1.metro_id IS DISTINCT FROM e.metro_id AND NOT o_1.esquema_rima_id IS DISTINCT FROM e.esquema_rima_id AND NOT o_1.valor_rasgo_id IS DISTINCT FROM e.valor_rasgo_id AND NOT o_1.variedad_id IS DISTINCT FROM e.variedad_id AND NOT o_1.repeticion_id IS DISTINCT FROM e.repeticion_id AND NOT o_1.posicion_unidad IS DISTINCT FROM e.posicion_unidad
        ), reclamado AS (
         SELECT derivado.termino_id,
            derivado.grupo_eleccion_id,
            derivado.opcion_eleccion_id
           FROM derivado
        UNION
         SELECT declarado.termino_id,
            declarado.grupo_eleccion_id,
            declarado.opcion_eleccion_id
           FROM declarado
        )
 SELECT p.secuencia_id,
    g.grupo_eleccion_id,
    g.nombre AS pregunta,
    r.opcion_eleccion_id,
    o.nombre AS respuesta,
    g.alcance
   FROM propuesta_metrica_secuencia p
     JOIN reclamado r ON r.termino_id = p.estrofa_tipo_id
     JOIN grupos_eleccion_metrica_resueltos g ON g.grupo_eleccion_id = r.grupo_eleccion_id AND g.arquitectura_id = p.arquitectura_propuesta_id AND g.activo
     JOIN opciones_eleccion_metrica o ON o.opcion_eleccion_id = r.opcion_eleccion_id
     LEFT JOIN arquitecturas_forma a ON a.arquitectura_id = p.arquitectura_propuesta_id
  WHERE g.alcance = 'secuencia'::text OR g.alcance = 'unidad'::text AND a.unidad_versos_min IS NOT NULL AND (p.v_fin - p.v_ini + 1) = a.unidad_versos_min;;

do $$
declare
	v_n integer;
	v_arq uuid;
	v_regla record;
begin
	-- La columna no queda en ninguna tabla del dominio. La homónima del vocabulario legado es
	-- una **categoría** de `vocabularios`, no una columna, y por eso no aparece aquí.
	select count(*) into v_n
	from information_schema.columns
	where table_schema = 'public'
		and column_name = 'estado_revision'
		and table_name in (
			'afirmaciones_fuentes_metricas', 'arquitecturas_forma', 'esquemas_metricos',
			'esquemas_rima', 'forma_relaciones', 'formas_metricas', 'grupos_eleccion_metrica',
			'metros', 'rasgos_metricos', 'repeticiones_metricas', 'tradiciones_metricas',
			'variedades_arquitectura', 'grupos_eleccion_metrica_resueltos'
		);
	if v_n <> 0 then
		raise exception 'Quedan % columnas «estado_revision» en el dominio métrico.', v_n;
	end if;

	-- La vista se consulta, no se da por buena: se acaba de recrear. Su invariante no es un
	-- número sino una correspondencia — decora cada grupo y no filtra ninguno.
	select (select count(*) from public.grupos_eleccion_metrica_resueltos)
		- (select count(*) from public.grupos_eleccion_metrica)
	into v_n;
	if v_n <> 0 then
		raise exception 'La vista de grupos resueltos no cubre uno a uno la tabla (difiere en %).', v_n;
	end if;
	if not exists (
		select 1 from public.grupos_eleccion_metrica_resueltos
		where nombre = 'Medida de los quebrados'
	) then
		raise exception 'La vista ha dejado de nombrar la pregunta de los quebrados.';
	end if;

	-- Y la función se ejecuta sobre una arquitectura de cada clase de regla, que es donde el
	-- cuerpo entrecomillado se rompería sin avisar: la que deriva de la unidad y la que deriva
	-- de un ciclo de rima, que es la rama donde vivía el filtro retirado.
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto' and a.activo;

	select * into v_regla from public.regla_longitud_arquitectura_metrica(v_arq);
	if v_regla.origen is null then
		raise exception 'La regla de longitud del soneto no devuelve nada.';
	end if;

	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'romance' and a.slug = 'octosilabica' and a.activo;

	select * into v_regla from public.regla_longitud_arquitectura_metrica(v_arq);
	if v_regla.origen is distinct from 'ciclo_rima' then
		raise exception 'El romance ya no deriva su longitud del ciclo de rima, sino de «%».',
			coalesce(v_regla.origen, 'nada');
	end if;

	-- La dependiente vuelve a existir y se consulta.
	perform 1 from public.propuesta_elecciones_secuencia limit 1;

	-- Y la ficha pública sigue en pie: es lo que más columnas selecciona del catálogo.
	if public.get_forma_metrica_publica('sextilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la sextilla ha dejado de responder.';
	end if;
end $$;

commit;
