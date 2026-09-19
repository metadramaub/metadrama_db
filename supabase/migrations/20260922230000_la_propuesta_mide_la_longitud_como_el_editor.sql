-- La propuesta mide la longitud como la mide el editor
--
-- El 25 de agosto la regla de longitud ganó `desplazamientos`: el terceto encadenado declara
-- `[0, 1]` porque puede cerrar con un verso suelto, y 61 versos son veinte tercetos y su cierre.
-- El editor lo entiende desde entonces (`isMetricLengthCompatible`, en `metric-length.ts`), pero
-- `propuesta_metrica_secuencia` seguía comprobando `n % modulo = residuo` a secas, escrito tres
-- veces en su cuerpo. Resultado: los informes de migración daban por «sin equivalencia» seis
-- tercetos encadenados reales —uno de *El caballero de Olmedo*, cinco de *La gran Semíramis*— que
-- miden 37, 52, 61, 61, 61 y 73 versos: todos `3n + 1`, todos bien anotados.
--
-- Se saca la comprobación a una función, `longitud_encaja_en_regla`, que hace exactamente lo que
-- hace el editor: una longitud vale si **algún** desplazamiento la deja por encima del mínimo y
-- en el ciclo. La vista la llama en los tres sitios, y así la regla vive una sola vez en SQL.
--
-- **Se comprueba ejecutando.** Primero la función sobre la regla del terceto encadenado, con los
-- mismos casos que probó la migración de agosto; después la vista, contando cuántas secuencias
-- legadas quedan con la longitud incompatible: eran 21, y las seis que sobraban son tercetos.

begin;

-- ---------------------------------------------------------------------------
-- La comprobación, una sola vez
-- ---------------------------------------------------------------------------

create or replace function public.longitud_encaja_en_regla(
	p_versos integer,
	p_minimo integer,
	p_modulo integer,
	p_residuo integer,
	p_desplazamientos integer[]
) returns boolean
language sql
immutable
as $$
	-- Una regla sin desplazamientos declarados equivale a `[0]`: la longitud es el ciclo y nada más.
	-- El doble `mod` es el del editor: deja el resto en [0, modulo) aunque el sustraendo sea mayor
	-- que la longitud.
	select exists (
		select 1
		from unnest(coalesce(p_desplazamientos, array[0])) as d
		where p_modulo > 0
			and p_versos - d >= p_minimo
			and mod(mod(p_versos - d - p_residuo, p_modulo) + p_modulo, p_modulo) = 0
	);
$$;

comment on function public.longitud_encaja_en_regla(integer, integer, integer, integer, integer[]) is
	'Si una longitud cabe en una regla de longitud: por encima del mínimo y en el ciclo para alguno de sus desplazamientos. Es la misma lógica que isMetricLengthCompatible en el editor.';

-- ---------------------------------------------------------------------------
-- La vista, con la función en los tres sitios
-- ---------------------------------------------------------------------------

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
            WHEN arq_directa.arquitectura_id IS NOT NULL THEN regla_directa.arquitectura_id IS NULL
                OR public.longitud_encaja_en_regla(s.v_fin - s.v_ini + 1, regla_directa.minimo_versos, regla_directa.modulo_versos, regla_directa.residuo_versos, regla_directa.desplazamientos)
            ELSE arq_compatible.compatible
        END AS longitud_compatible,
        CASE
            WHEN f.forma_id IS NULL THEN NULL::text
            WHEN arq_directa.arquitectura_id IS NOT NULL AND regla_directa.arquitectura_id IS NOT NULL
                AND NOT public.longitud_encaja_en_regla(s.v_fin - s.v_ini + 1, regla_directa.minimo_versos, regla_directa.modulo_versos, regla_directa.residuo_versos, regla_directa.desplazamientos)
                THEN format('La arquitectura «%s» no admite una secuencia de %s versos: %s.'::text, arq_directa.nombre, s.v_fin - s.v_ini + 1, regla_directa.explicacion)
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
            regla.arquitectura_id IS NULL
                OR public.longitud_encaja_en_regla(s.v_fin - s.v_ini + 1, regla.minimo_versos, regla.modulo_versos, regla.residuo_versos, regla.desplazamientos) AS compatible
           FROM arquitecturas_forma a
             LEFT JOIN arquitecturas_reglas_longitud regla ON regla.arquitectura_id = a.arquitectura_id
          WHERE a.forma_id = f.forma_id AND a.activo AND r.arquitectura_id IS NULL AND f.tipo_registro <> 'sin_forma'
          ORDER BY (regla.arquitectura_id IS NULL
                OR public.longitud_encaja_en_regla(s.v_fin - s.v_ini + 1, regla.minimo_versos, regla.modulo_versos, regla.residuo_versos, regla.desplazamientos)) DESC, a.principal DESC, a.orden
         LIMIT 1) arq_compatible ON true;

do $comprobacion$
declare
	v_regla record;
	v_caso integer[];
	v_incompatibles integer;
	v_tercetos_mal integer;
	v_soneto_15 boolean;
begin
	-- ------------------------------------------------------------------ La función
	--
	-- Los mismos casos con que se probó la regla del terceto encadenado el 25 de agosto, ahora
	-- contra la función que los va a resolver en la vista.
	select r.* into v_regla
	from public.arquitecturas_reglas_longitud r
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado'
	order by a.principal desc, a.orden
	limit 1;

	if v_regla.desplazamientos is distinct from array[0, 1] then
		raise exception 'La regla del terceto encadenado no declara [0, 1] sino %: la prueba no vale.',
			v_regla.desplazamientos;
	end if;

	foreach v_caso slice 1 in array array[
		array[61, 1],   -- veinte tercetos y su cierre: lo que la vista rechazaba
		array[63, 1],   -- veintiún tercetos, sin cierre
		array[62, 0],   -- ni 3n ni 3n+1
		array[7, 1],    -- un terceto y su cierre, sobre el mínimo
		array[4, 0],    -- un terceto y su cierre, por debajo del mínimo
		array[3, 0]     -- por debajo del mínimo
	] loop
		if public.longitud_encaja_en_regla(
			v_caso[1], v_regla.minimo_versos, v_regla.modulo_versos, v_regla.residuo_versos,
			v_regla.desplazamientos
		) <> (v_caso[2] = 1) then
			raise exception 'longitud_encaja_en_regla resuelve mal % versos: esperaba %.',
				v_caso[1], v_caso[2] = 1;
		end if;
	end loop;

	-- Sin desplazamientos declarados vale [0]: cinco versos son una quintilla, seis no.
	if not public.longitud_encaja_en_regla(5, 5, 5, 0, null)
		or public.longitud_encaja_en_regla(6, 5, 5, 0, null) then
		raise exception 'Sin desplazamientos la función no equivale a [0].';
	end if;

	-- ------------------------------------------------------------------ La vista
	--
	-- **Se lee**, que es lo único que prueba que sigue en pie. Ningún terceto encadenado legado
	-- puede quedar incompatible: los seis miden 3n o 3n+1.
	select count(*) into v_tercetos_mal
	from public.propuesta_metrica_secuencia p
	where p.forma_propuesta = 'Terceto encadenado'
		and p.via <> 'sin_tipo'
		and p.longitud_compatible = false;

	if v_tercetos_mal <> 0 then
		raise exception '% tercetos encadenados legados siguen con la longitud incompatible.',
			v_tercetos_mal;
	end if;

	-- Y lo que estaba mal de verdad sigue estándolo: el soneto de 15 versos de *La gran Semíramis*.
	select p.longitud_compatible into v_soneto_15
	from public.propuesta_metrica_secuencia p
	join public.obras o on o.obra_id = p.obra_id
	where o.titulo = 'La gran Semíramis' and p.v_ini = 1488 and p.v_fin = 1502;

	if v_soneto_15 is distinct from false then
		raise exception 'El soneto de 15 versos ya no se marca para revisar: la función es demasiado permisiva.';
	end if;

	-- Eran 21 secuencias legadas con la longitud incompatible; seis eran tercetos.
	select count(*) into v_incompatibles
	from public.propuesta_metrica_secuencia p
	where p.via <> 'sin_tipo' and p.longitud_compatible = false;

	if v_incompatibles <> 15 then
		raise exception 'Quedan % secuencias legadas con la longitud incompatible; se esperaban 15.',
			v_incompatibles;
	end if;

	raise notice 'La propuesta mide la longitud con desplazamientos: quedan % secuencias legadas por revisar de longitud.',
		v_incompatibles;
end
$comprobacion$;

commit;
