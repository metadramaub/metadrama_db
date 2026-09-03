-- La propuesta no adivina el arte de un tramo
--
-- Al darle arquitecturas a la versificación irregular apareció un efecto que no se veía antes,
-- porque antes no había ninguna: la secuencia de *El mágico prodigioso* vv. 2191–2201, anotada con
-- el término escueto `irregular`, **pasó a proponerse como «De arte menor»**. Nadie reclama ese
-- término; lo que reclama la forma es el nivel de arriba, y al no traer arquitectura la propuesta
-- caía en su respaldo: elegir entre las arquitecturas compatibles por longitud, ordenadas, y quedarse
-- con la primera.
--
-- Ese respaldo está bien donde una forma tiene variantes que la longitud distingue —una silva, una
-- sextina—, porque entonces la elección no es arbitraria y además se revisa a mano. **En un tramo sin
-- forma no distingue nada**: sus arquitecturas son artes, y la longitud del pasaje no dice de cuál
-- se trata. Elegir la primera sería inventarse el dato.
--
-- Así que el respaldo deja de aplicarse a los tramos. El término escueto vuelve a proponer forma sin
-- arquitectura, que es lo que se sabe de él, y los tres términos de arte siguen llegando por la vía
-- directa, que no usa este camino.

begin;

create or replace view public.propuesta_metrica_secuencia as
WITH RECURSIVE reclamaciones AS (
         SELECT f_1.origen_termino_id AS termino_id,
            f_1.forma_id,
            NULL::uuid AS arquitectura_id,
            NULL::text AS detalle,
            1 AS prioridad
           FROM formas_metricas f_1
          WHERE f_1.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT f_1.forma_id,
            f_1.forma_id,
            NULL::uuid AS uuid,
            NULL::text AS text,
            2
           FROM formas_metricas f_1
             JOIN vocabularios v ON v.termino_id = f_1.forma_id
        UNION ALL
         SELECT a.origen_termino_id,
            a.forma_id,
            a.arquitectura_id,
            NULL::text AS text,
            1
           FROM arquitecturas_forma a
          WHERE a.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT e.origen_termino_id,
            arq.forma_id,
            e.arquitectura_id,
            ('esquema de rima «'::text || e.nombre) || '»'::text,
            1
           FROM esquemas_rima e
             JOIN arquitecturas_forma arq ON arq.arquitectura_id = e.arquitectura_id
          WHERE e.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT va.origen_termino_id,
            arq.forma_id,
            va.arquitectura_id,
            ('variedad «'::text || va.nombre) || '»'::text,
            1
           FROM variedades_arquitectura va
             JOIN arquitecturas_forma arq ON arq.arquitectura_id = va.arquitectura_id
          WHERE va.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT d.origen_termino_id,
            COALESCE(d.forma_id, arq.forma_id) AS "coalesce",
            d.arquitectura_id,
            NULL::text AS text,
            3
           FROM denominaciones_metricas d
             LEFT JOIN arquitecturas_forma arq ON arq.arquitectura_id = d.arquitectura_id
          WHERE d.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT rv.origen_termino_id,
            NULL::uuid AS uuid,
            NULL::uuid AS uuid,
            (r_1.nombre || ' = '::text) || rv.nombre,
            4
           FROM rasgo_valores rv
             JOIN rasgos_metricos r_1 ON r_1.rasgo_id = rv.rasgo_id
          WHERE rv.origen_termino_id IS NOT NULL
        UNION ALL
         SELECT m.origen_termino_id,
            NULL::uuid AS uuid,
            NULL::uuid AS uuid,
            ('metro «'::text || m.nombre) || '»'::text,
            4
           FROM metros m
          WHERE m.origen_termino_id IS NOT NULL
        ), reclamacion AS (
         SELECT DISTINCT ON (reclamaciones.termino_id) reclamaciones.termino_id,
            reclamaciones.forma_id,
            reclamaciones.arquitectura_id,
            reclamaciones.detalle
           FROM reclamaciones
          ORDER BY reclamaciones.termino_id, (reclamaciones.forma_id IS NULL), reclamaciones.prioridad
        ), ascendencia AS (
         SELECT v.termino_id AS origen,
            v.termino_id AS actual,
            0 AS salto
           FROM vocabularios v
          WHERE v.categoria::text = 'estrofa_tipo'::text
        UNION ALL
         SELECT a.origen,
            padre.termino_id,
            a.salto + 1
           FROM ascendencia a
             JOIN vocabularios hijo ON hijo.termino_id = a.actual
             JOIN vocabularios padre ON padre.termino_id = hijo.termino_padre_id
          WHERE a.salto < 8
        ), heredada AS (
         SELECT DISTINCT ON (a.origen) a.origen AS termino_id,
            r_1.forma_id,
            r_1.arquitectura_id,
            v.termino AS desde
           FROM ascendencia a
             JOIN reclamacion r_1 ON r_1.termino_id = a.actual
             JOIN vocabularios v ON v.termino_id = a.actual
          WHERE a.salto > 0 AND r_1.forma_id IS NOT NULL
          ORDER BY a.origen, a.salto
        ), resolucion AS (
         SELECT v.termino_id,
                CASE
                    WHEN d.forma_id IS NOT NULL THEN 'directa'::text
                    WHEN d.termino_id IS NOT NULL AND h.forma_id IS NOT NULL THEN 'rasgo'::text
                    WHEN d.termino_id IS NOT NULL THEN 'rasgo'::text
                    WHEN h.forma_id IS NOT NULL THEN 'ascendencia'::text
                    ELSE 'sin_destino'::text
                END AS via,
            COALESCE(d.forma_id, h.forma_id) AS forma_id,
                CASE
                    WHEN d.forma_id IS NOT NULL THEN d.arquitectura_id
                    ELSE h.arquitectura_id
                END AS arquitectura_id,
            d.detalle,
                CASE
                    WHEN d.forma_id IS NULL THEN h.desde
                    ELSE NULL::character varying
                END AS heredado_de
           FROM vocabularios v
             LEFT JOIN reclamacion d ON d.termino_id = v.termino_id
             LEFT JOIN heredada h ON h.termino_id = v.termino_id
          WHERE v.categoria::text = 'estrofa_tipo'::text
        )
 SELECT s.secuencia_id,
    s.obra_id,
    s.v_ini,
    s.v_fin,
    s.estrofa_tipo_id,
    voc.termino AS termino_legado,
    f.forma_id AS forma_propuesta_id,
    f.nombre AS forma_propuesta,
    COALESCE(arq_directa.arquitectura_id, arq_compatible.arquitectura_id) AS arquitectura_propuesta_id,
    COALESCE(arq_directa.nombre, arq_compatible.nombre) AS arquitectura_propuesta,
    COALESCE(r.via, 'sin_tipo'::text) AS via,
    r.detalle,
    r.heredado_de,
        CASE
            WHEN f.forma_id IS NULL THEN NULL::boolean
            WHEN arq_directa.arquitectura_id IS NOT NULL THEN regla_directa.arquitectura_id IS NULL OR (s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos AND ((s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos) = regla_directa.residuo_versos
            ELSE arq_compatible.compatible
        END AS longitud_compatible,
        CASE
            WHEN f.forma_id IS NULL THEN NULL::text
            WHEN arq_directa.arquitectura_id IS NOT NULL AND regla_directa.arquitectura_id IS NOT NULL AND NOT ((s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos AND ((s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos) = regla_directa.residuo_versos) THEN format('La arquitectura «%s» no admite una secuencia de %s versos: %s.'::text, arq_directa.nombre, s.v_fin - s.v_ini + 1, regla_directa.explicacion)
            WHEN r.arquitectura_id IS NULL AND NOT arq_compatible.compatible THEN format('Ninguna arquitectura activa de «%s» admite una secuencia de %s versos.'::text, f.nombre, s.v_fin - s.v_ini + 1)
            ELSE NULL::text
        END AS motivo_revision
   FROM secuencias_metricas s
     LEFT JOIN vocabularios voc ON voc.termino_id = s.estrofa_tipo_id
     LEFT JOIN resolucion r ON r.termino_id = s.estrofa_tipo_id
     LEFT JOIN formas_metricas f ON f.forma_id = r.forma_id
     LEFT JOIN arquitecturas_forma arq_directa ON arq_directa.arquitectura_id = r.arquitectura_id
     LEFT JOIN arquitecturas_reglas_longitud regla_directa ON regla_directa.arquitectura_id = arq_directa.arquitectura_id
     LEFT JOIN LATERAL ( SELECT a.arquitectura_id,
            a.nombre,
            regla.arquitectura_id IS NULL OR (s.v_fin - s.v_ini + 1) >= regla.minimo_versos AND ((s.v_fin - s.v_ini + 1) % regla.modulo_versos) = regla.residuo_versos AS compatible
           FROM arquitecturas_forma a
             LEFT JOIN arquitecturas_reglas_longitud regla ON regla.arquitectura_id = a.arquitectura_id
          WHERE a.forma_id = f.forma_id AND a.activo AND r.arquitectura_id IS NULL AND f.tipo_registro <> 'sin_forma'
          ORDER BY (regla.arquitectura_id IS NULL OR (s.v_fin - s.v_ini + 1) >= regla.minimo_versos AND ((s.v_fin - s.v_ini + 1) % regla.modulo_versos) = regla.residuo_versos) DESC, a.principal DESC, a.orden
         LIMIT 1) arq_compatible ON true;;

do $comprobacion$
declare
	v_arte text;
	v_forma text;
	v_directas integer;
	v_filas integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee la vista**, que es lo único que prueba que sigue en pie.
	select p.forma_propuesta, p.arquitectura_propuesta
	into v_forma, v_arte
	from public.propuesta_metrica_secuencia p
	where p.termino_legado = 'irregular';

	if v_forma is distinct from 'Versificación irregular' then
		raise exception 'El término escueto ya no propone su forma, sino «%».', v_forma;
	end if;

	if v_arte is not null then
		raise exception 'El término escueto sigue adivinando el arte: «%».', v_arte;
	end if;

	-- Y los tres que sí lo declaran no se han movido.
	select count(*) into v_directas
	from public.propuesta_metrica_secuencia p
	where p.termino_legado in ('irregular_arte_menor', 'irregular_arte_mayor', 'irregular_mixto')
		and p.arquitectura_propuesta_id is not null;

	if v_directas <> 8 then
		raise exception 'Solo % de las 8 secuencias de arte conocido conservan su arquitectura.', v_directas;
	end if;

	select count(*) into v_filas from public.propuesta_metrica_secuencia;
	raise notice 'La propuesta responde % filas; el término escueto ya no adivina y las 8 de arte conocido siguen.', v_filas;
end
$comprobacion$;

commit;
