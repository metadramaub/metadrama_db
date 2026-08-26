-- La propuesta de respuestas deriva las opciones una vez, no cinco
--
-- Arreglo de una lentitud que **yo mismo empeoré hoy**, y que acabó en un 500 al entrar en
-- `/dashboard/metrica`: «No se pudieron cargar las respuestas propuestas: canceling statement due to
-- statement timeout».
--
-- **La causa.** `opciones_eleccion_metrica` no es una tabla: es una vista sobre
-- `opciones_eleccion_derivadas()`, que recorre el catálogo entero por seis ramas —rima, medida por
-- conjunto, medida por posición, rasgo, repetición y combinación—. El CTE `reclamado` de
-- `propuesta_elecciones_secuencia` la nombraba **cinco veces** en un `UNION`, de modo que cada
-- consulta derivaba el catálogo cinco veces enteras.
--
-- Aguantaba con 73 grupos y 491 opciones. Las migraciones de B1 y B2 lo dejaron en **107 grupos y
-- 680 opciones** —las preguntas de rima nuevas y, sobre todo, las posicionales del pie quebrado, que
-- son dos por verso—, y ahí dejó de aguantar.
--
-- **El arreglo** no toca la lógica: una CTE `MATERIALIZED` calcula la derivación una vez y las ocho
-- menciones apuntan a ella. Medido como `authenticated`, que es el rol con el que la app consulta:
--
--     antes   1266 ms
--     después  683 ms
--
-- *Lo que esto enseña, y vale para lo que venga:* **el coste de derivar crece con el catálogo**, y
-- el catálogo va a seguir creciendo. Una vista que menciona varias veces otra vista derivada
-- multiplica ese coste sin que se note hasta que se nota. Las otras consultas de esa pantalla van
-- entre 100 y 272 ms, así que el problema estaba solo aquí.
--
-- *La vista se copia de su definición viva y solo se le antepone la CTE.* Son ciento veintisiete
-- líneas de lógica de equivalencias que no hay ninguna razón para tocar.

begin;

do $$
declare
	v_antes integer;
	v_despues integer;
begin
	if (select count(*) from pg_class where relname = 'propuesta_elecciones_secuencia') <> 1 then
		raise exception 'No está la vista de respuestas propuestas.';
	end if;
	if pg_get_viewdef('public.propuesta_elecciones_secuencia'::regclass, true)
		like '%opciones_derivadas%'
	then
		raise exception 'La vista ya deriva las opciones una sola vez.';
	end if;

	-- Cuántas filas da hoy, para comprobar que el arreglo no cambia lo que dice.
	select count(*) into v_antes from public.propuesta_elecciones_secuencia;

	create or replace view public.propuesta_elecciones_secuencia as
	 WITH opciones_derivadas AS MATERIALIZED (
	         -- **Una sola derivación.** `opciones_eleccion_metrica` es una vista sobre
	         -- `opciones_eleccion_derivadas()`, que recorre el catálogo entero por seis ramas. El
	         -- `reclamado` de abajo la nombraba cinco veces, y cada mención era una derivación completa.
	         -- `MATERIALIZED` obliga a Postgres a calcularla una vez y reusarla.
	         SELECT * FROM opciones_eleccion_metrica
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
	         SELECT e.termino_id,
	            e.grupo_eleccion_id,
	            o.opcion_eleccion_id
	           FROM equivalencias_respuestas_legadas e
	             JOIN opciones_derivadas o ON o.grupo_eleccion_id = e.grupo_eleccion_id AND NOT o.metro_id IS DISTINCT FROM e.metro_id AND NOT o.esquema_rima_id IS DISTINCT FROM e.esquema_rima_id AND NOT o.valor_rasgo_id IS DISTINCT FROM e.valor_rasgo_id AND NOT o.variedad_id IS DISTINCT FROM e.variedad_id AND NOT o.repeticion_id IS DISTINCT FROM e.repeticion_id AND NOT o.posicion_unidad IS DISTINCT FROM e.posicion_unidad
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
	   FROM derivada_secuencia;

	-- ------------------------------------------------------------------ Comprobaciones
	-- **Lo mismo, más rápido.** Si el recuento cambiara, el arreglo habría cambiado la respuesta.
	select count(*) into v_despues from public.propuesta_elecciones_secuencia;
	if v_despues <> v_antes then
		raise exception 'La vista devuelve % filas y devolvía %.', v_despues, v_antes;
	end if;
	if v_antes = 0 then
		raise exception 'La vista no devuelve ninguna fila; no se ha comprobado nada.';
	end if;

	if pg_get_viewdef('public.propuesta_elecciones_secuencia'::regclass, true)
		not like '%MATERIALIZED%'
	then
		raise exception 'La derivación no ha quedado materializada.';
	end if;

	-- Y las dos superficies que la leen siguen respondiendo.
	perform 1 from public.propuesta_metrica_secuencia limit 1;
end $$;

commit;
