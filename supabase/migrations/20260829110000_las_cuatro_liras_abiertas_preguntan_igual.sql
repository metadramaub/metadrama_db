-- Las cuatro liras abiertas preguntan igual
--
-- El cuarteto-lira, la octava-lira, la novena-lira y la décima-lira se crearon el 24 de agosto de
-- 2026 al sistematizar entera la serie alirada, y sin embargo preguntaban su rima de tres maneras:
--
--   | forma          | repertorio | salida abierta | obligatoria |
--   |----------------|------------|----------------|-------------|
--   | Cuarteto-lira  | 2          | sí             | sí          |
--   | Octava-lira    | 2          | sí             | sí          |
--   | Décima-lira    | 1          | sí             | **no**      |
--   | Novena-lira    | 0          | **solo**       | sí          |
--
-- Las cuatro son formas de **norma abierta**: lo que las define es la combinación de heptasílabo y
-- endecasílabo, no una disposición de rima. Lo que hay catalogado es lo que se ha documentado hasta
-- hoy, y puede crecer. Así que las cuatro han de comportarse igual: **el repertorio que haya, la
-- salida abierta siempre, y responder es obligatorio**.
--
--   1. **La décima-lira pasa a obligatoria.** Tener una sola disposición documentada no es razón
--      para dejar sin registrar cómo rima el pasaje: si no es la catalogada, se escribe.
--   2. **La novena-lira pasa al control híbrido.** Hoy solo deja escribir, porque su único esquema
--      es «Distribución variable», de secuencia `abierta`, y la función que deriva las opciones no
--      ofrece las abiertas. Sigue sin repertorio que enseñar —eso es un hecho del catálogo, no de
--      la pregunta— pero deja de ser un control aparte: el día que aparezca una disposición
--      documentada, se ofrece sola.
--
-- **Del lado del editor**, un grupo híbrido sin ninguna opción se pinta como el campo escrito a
-- secas, sin desplegable vacío delante. Va en el mismo cambio, en `MetricChoiceField`.

begin;

do $$
declare
	v_grupo uuid;
	v_min integer;
	v_control text;
	v_opciones integer;
begin
	-- ------------------------------------------------ 1 · la décima-lira, obligatoria
	select g.grupo_eleccion_id, g.selecciones_min, g.tipo_control
		into v_grupo, v_min, v_control
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Décima-lira' and g.dimension = 'rima';

	if v_grupo is null then
		raise exception 'La décima-lira no tiene pregunta de rima: revisa el catálogo antes de seguir.';
	end if;

	if v_control <> 'opciones_y_esquema' then
		raise exception 'La pregunta de rima de la décima-lira es % y se esperaba opciones_y_esquema.', v_control;
	end if;

	if v_min = 1 then
		raise notice 'La rima de la décima-lira ya era obligatoria.';
	elsif v_min <> 0 then
		raise exception 'La rima de la décima-lira exigía % respuestas, que no es lo que se acordó cambiar.', v_min;
	else
		update public.grupos_eleccion_metrica
		set selecciones_min = 1
		where grupo_eleccion_id = v_grupo;
	end if;

	-- ------------------------------------------------ 2 · la novena-lira, al control híbrido
	select g.grupo_eleccion_id, g.tipo_control into v_grupo, v_control
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Novena-lira' and g.dimension = 'rima';

	if v_grupo is null then
		raise exception 'La novena-lira no tiene pregunta de rima: revisa el catálogo antes de seguir.';
	end if;

	if v_control = 'opciones_y_esquema' then
		raise notice 'La novena-lira ya usaba el control híbrido.';
	elsif v_control <> 'esquema_rima' then
		raise exception 'La pregunta de rima de la novena-lira es %, que no es lo que se acordó cambiar.', v_control;
	else
		update public.grupos_eleccion_metrica
		set tipo_control = 'opciones_y_esquema'
		where grupo_eleccion_id = v_grupo;
	end if;

	-- Su único esquema sigue siendo el abierto, así que no debe aparecer repertorio: si apareciera,
	-- querría decir que el catálogo cambió y esta migración estaría razonando sobre otra cosa.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica where grupo_eleccion_id = v_grupo;

	if v_opciones <> 0 then
		raise exception 'La novena-lira ofrece ahora % opciones de rima, y no debía ofrecer ninguna.', v_opciones;
	end if;
end $$;

do $$
declare
	v_fila record;
	v_abiertas integer := 0;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee lo que ha quedado**, recorriendo las cuatro, y por la vista derivada, que ejecuta la
	-- función de opciones en vez de dar por bueno lo que se pretendía escribir.
	for v_fila in
		select f.nombre as forma, g.tipo_control, g.selecciones_min, g.selecciones_max,
			(select count(*) from public.opciones_eleccion_metrica o
				where o.grupo_eleccion_id = g.grupo_eleccion_id) as opciones
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where g.dimension = 'rima' and g.activo
			and f.nombre in ('Cuarteto-lira', 'Octava-lira', 'Novena-lira', 'Décima-lira')
	loop
		v_abiertas := v_abiertas + 1;

		if v_fila.tipo_control <> 'opciones_y_esquema' then
			raise exception '% pregunta la rima con %, y las cuatro debían usar el control híbrido.',
				v_fila.forma, v_fila.tipo_control;
		end if;

		if v_fila.selecciones_min <> 1 or v_fila.selecciones_max <> 1 then
			raise exception '% pide entre % y % respuestas de rima, y debían ser exactamente 1.',
				v_fila.forma, v_fila.selecciones_min, v_fila.selecciones_max;
		end if;

		-- La novena sigue sin repertorio; las otras tres conservan el suyo.
		if v_fila.forma = 'Novena-lira' and v_fila.opciones <> 0 then
			raise exception 'La novena-lira ha aparecido con % opciones.', v_fila.opciones;
		end if;

		if v_fila.forma <> 'Novena-lira' and v_fila.opciones < 1 then
			raise exception '% se ha quedado sin repertorio de rima.', v_fila.forma;
		end if;
	end loop;

	if v_abiertas <> 4 then
		raise exception 'Se han comprobado % preguntas de rima de las liras abiertas, y son 4.', v_abiertas;
	end if;
end $$;

commit;
