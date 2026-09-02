-- Una pregunta de medida se llama por lo que pregunta
--
-- Dos rótulos que decían lo que no es.
--
--   1. **«Medida de cada verso» cuando solo se pregunta uno.** La seguidilla gitana pregunta la
--      medida de su **tercer verso** —el largo, de diez, once o doce sílabas— y los otros tres los
--      fija la norma. El rótulo hablaba de todos.
--   2. **«Medida de cada verso» donde antes decía «Medida de los quebrados».** Le pasó el 29 de
--      agosto de 2026 a las seis arquitecturas que declararon dónde cae su quiebro: al declarar la
--      posición, esta ofrece **también el octosílabo** —que es la respuesta de que ahí no hay
--      quiebro— y el rótulo se decidía con `bool_and(rol = 'quebrado')`, que dejó de cumplirse.
--
-- Se arreglan los dos donde se deciden, que es la vista que resuelve el nombre:
--
--   * `bool_and` pasa a `bool_or`: una pregunta que ofrece **algún** quebrado es la pregunta del
--     quiebro, aunque ofrezca al lado la medida plena.
--   * y una pregunta posicional de **una sola posición** se llama por su verso: «Medida del verso 3».
--
-- La seguidilla gitana no ofrece ningún quebrado —sus tres opciones son de diez, once y doce
-- sílabas, sin rol— así que cae en el segundo rótulo, que es el suyo.

begin;

CREATE OR REPLACE VIEW public.grupos_eleccion_metrica_resueltos AS
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
                    WHEN m.posicional AND m.posiciones = 1 THEN 'Medida del verso ' || m.primera_posicion
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


do $$
declare
	v_fila record;
	v_leidas integer := 0;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la vista**, que es donde vive el rótulo.
	for v_fila in
		select * from (values
			('Quintilla', 'Octosilábica consonante', 'Medida de los quebrados'),
			('Septilla', 'Octosilábica', 'Medida de los quebrados'),
			('Copla castellana', 'Octosilábica', 'Medida de los quebrados'),
			('Novena', 'Redondilla + quintilla', 'Medida de los quebrados'),
			('Oncena', 'Quintilla + sextilla', 'Medida de los quebrados'),
			('Oncena', 'Sextilla + quintilla', 'Medida de los quebrados'),
			('Copla manriqueña', 'De pie quebrado', 'Medida de los quebrados'),
			('Redondilla', 'Octosilábica', 'Medida de los quebrados'),
			('Seguidilla', 'Gitana', 'Medida del verso 3')
		) as t(forma, arquitectura, rotulo)
	loop
		v_leidas := v_leidas + 1;
		if not exists (
			select 1 from public.grupos_eleccion_metrica_resueltos g
			join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
			join public.formas_metricas f on f.forma_id = a.forma_id
			where f.nombre = v_fila.forma and a.nombre = v_fila.arquitectura
				and g.dimension = 'metro' and g.nombre = v_fila.rotulo
		) then
			raise exception '% · % no se llama «%»; se llama «%».',
				v_fila.forma, v_fila.arquitectura, v_fila.rotulo,
				(select g.nombre from public.grupos_eleccion_metrica_resueltos g
					join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
					join public.formas_metricas f on f.forma_id = a.forma_id
					where f.nombre = v_fila.forma and a.nombre = v_fila.arquitectura and g.dimension = 'metro');
		end if;
	end loop;

	if v_leidas <> 9 then
		raise exception 'Se han comprobado % rótulos y son 9.', v_leidas;
	end if;

	-- Y las aliradas, que preguntan todos sus versos y no tienen quiebro, siguen como estaban.
	if not exists (
		select 1 from public.grupos_eleccion_metrica_resueltos g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = 'Novena-lira' and g.dimension = 'metro' and g.nombre = 'Medida de cada verso'
	) then
		raise exception 'La novena-lira ha dejado de llamar a su pregunta «Medida de cada verso».';
	end if;
end $$;

commit;
