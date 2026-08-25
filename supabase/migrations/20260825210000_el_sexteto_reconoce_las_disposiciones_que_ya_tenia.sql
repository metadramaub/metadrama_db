-- El sexteto reconoce las disposiciones que ya tenía
--
-- Paso 7b de B1, diez de diez. Toca 2 arquitecturas: 2 con lista y salida abierta.
--
-- El sexteto era la única forma que resolvía bien la rima abierta —campo libre en sus tres
-- arquitecturas— y aun así perdía dato: la alejandrina tiene catalogado `AABCCB` y la endecasilábica
-- `ABABCC`, la sexta rima, y **ninguna de las dos se ofrecía**. Un editor que leyera una sexta rima
-- escribía `ABABCC` a mano y el catálogo la guardaba como texto, sin reconocer la disposición que él
-- mismo tiene declarada.
--
-- Por la regla 2 del § 3.3, una arquitectura con disposición catalogada tiene repertorio, aunque sea
-- de una: el control pasa a ser híbrido y la ofrece, con la salida abierta intacta debajo.
--
-- **La dodecasilábica se queda como está**, con campo abierto puro: no tiene ninguna disposición
-- catalogada, y ofrecer una lista vacía sería declarar un repertorio que no existe.
--
-- **Las opciones no se crean: se derivan.** `opciones_eleccion_metrica` es una vista sobre
-- `opciones_eleccion_derivadas()`, que ofrece los esquemas concretos de la arquitectura —o los de la
-- que reutiliza la sección— y deja fuera los patrones abiertos. Crear la pregunta basta; la guarda
-- **consulta la vista** para comprobar que cada una sale con las opciones que le tocan, porque una
-- pregunta declarada y sin lista no está probada.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_par text[];
	v_n integer;
	v_total integer := 0;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto' and activo;
	if v_forma is null then
		raise exception 'La forma «sexteto» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['alejandrina', 'opciones_y_esquema', '1'],
		array['endecasilabica', 'opciones_y_esquema', '1']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de sexteto no está activa.', v_par[1];
		end if;

		-- El repertorio vivo es el que la cabecera describe. Si alguien lo cambió, esta migración
		-- ofrecería otra cosa de la que dice ofrecer.
		select count(*) into v_n
		from public.esquemas_rima
		where arquitectura_id = v_arq
			and tipo_secuencia not in ('abierta', 'restricciones')
			and seccion_id is null;
		if v_n <> v_par[3]::integer then
			raise exception 'La arquitectura «%» tiene % disposiciones catalogadas, y se esperaban %.',
				v_par[1], v_n, v_par[3];
		end if;

		-- Aquí la pregunta ya existe: lo que cambia es que pase a ofrecer lo que el catálogo
		-- tiene, en vez de solo dejar escribirlo.
		update public.grupos_eleccion_metrica
		set tipo_control = v_par[2]
		where arquitectura_id = v_arq and dimension = 'rima' and activo;
		if not found then
			raise exception 'La arquitectura «%» no tiene la pregunta de rima que se esperaba.', v_par[1];
		end if;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Ejecutando la vista, no leyendo el catálogo.
	for v_arq in
		select a.arquitectura_id from public.arquitecturas_forma a
		where a.forma_id = v_forma and a.activo
			and exists (
				select 1 from public.grupos_eleccion_metrica g
				where g.arquitectura_id = a.arquitectura_id and g.dimension = 'rima' and g.activo
			)
	loop
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.dimension = 'rima' and g.activo and o.activo;
		v_total := v_total + v_n;
	end loop;
	if v_total <> 2 then
		raise exception 'Las preguntas de sexteto ofrecen % opciones, y se esperaban 2.', v_total;
	end if;

	-- Ninguna arquitectura de la forma se queda sin poder registrar su rima.
	select count(*) into v_n
	from public.arquitecturas_forma a
	where a.forma_id = v_forma and a.activo
		and not exists (
			select 1 from public.grupos_eleccion_metrica g
			where g.arquitectura_id = a.arquitectura_id and g.dimension = 'rima' and g.activo
		)

	;
	if v_n <> 0 then
		raise exception '% arquitecturas de sexteto siguen sin preguntar su rima.', v_n;
	end if;

	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('sexteto') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de sexteto ha dejado de responder.';
	end if;
end $$;

commit;
