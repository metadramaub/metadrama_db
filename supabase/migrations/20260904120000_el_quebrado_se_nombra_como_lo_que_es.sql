-- El quebrado se nombra como lo que es
--
-- **F16.** La pregunta se llamaba «Medida de los quebrados», y eso da por hecho que hay quebrados y
-- que lo que falta es medirlos. En las nueve arquitecturas que la ofrecen el quiebro es **opcional**
-- —`admitida` en siete, `habitual` en las dos oncenas— y lo corriente es que no haya ninguno: la
-- definición de la copla real lo dice con todas las letras, «el quiebro, cuando lo hay».
--
-- Pasa a llamarse **«Pie quebrado»**, que es como lo nombra el recuadro de la norma —«Pie quebrado ·
-- admitido; de 4 o 5 sílabas»— y como lo nombran las fuentes. El rótulo es derivado, así que cambia
-- en las nueve a la vez.
--
-- *La otra mitad de F16 es de interfaz y va aparte: la rejilla de versos deja de venir desplegada.*

begin;

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
                    WHEN g.tipo_control = 'serie_medidas'::text THEN 'Medida de cada verso'::text
                    WHEN m.quebrados THEN 'Pie quebrado'::text
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

do $comprobacion$
declare
	v_rotulos integer;
	v_viejo integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee la vista**, que es donde vive el rótulo y lo único que prueba que compila.
	select count(*) into v_rotulos
	from public.grupos_eleccion_metrica_resueltos
	where slug = 'posiciones_pie_quebrado' and nombre = 'Pie quebrado' and activo;

	if v_rotulos <> 9 then
		raise exception 'Se rotulan como «Pie quebrado» % preguntas, y son 9.', v_rotulos;
	end if;

	select count(*) into v_viejo
	from public.grupos_eleccion_metrica_resueltos
	where nombre like '%Medida de los quebrados%';

	if v_viejo <> 0 then
		raise exception 'Quedan % preguntas llamándose «Medida de los quebrados».', v_viejo;
	end if;

	-- Y el resto de rótulos de metro no se ha movido: la medida de cada verso sigue diciéndose.
	if not exists (
		select 1 from public.grupos_eleccion_metrica_resueltos
		where dimension = 'metro' and nombre like 'Medida de%' and activo
	) then
		raise exception 'Se han llevado por delante los rótulos de medida.';
	end if;

	raise notice 'Las 9 preguntas del quiebro se llaman ya «Pie quebrado».';
end
$comprobacion$;

commit;
