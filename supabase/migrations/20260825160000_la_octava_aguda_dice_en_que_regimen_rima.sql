-- La octava aguda dice en qué régimen rima
--
-- Paso 7b de B1, cinco de diez. Toca 6 arquitecturas: 6 con lista y salida abierta.
--
-- La octava aguda es el caso raro del reparto: **sus dos esquemas comparten notación**. Los dos son
-- `---a---a` —solo riman los versos que cierran cada semiestrofa— y lo único que los separa es el
-- régimen, consonante o asonante. El editor no podía decir cuál había leído en ninguna de las seis
-- medidas.
--
-- *Decisión del IP el 25 de agosto de 2026: siendo la diferencia de asonante frente a consonante, la
-- pregunta es de rima.* Va con lista y salida, como las demás.
--
-- **De comprobar este caso salió la regla 3 bis** de [criterios de nivel § 3.3](../../docs/dominio-metrico/criterios-de-nivel.md):
-- lo escrito se casa con lo catalogado por la pareja notación **y** régimen, nunca por la notación
-- sola, o el catálogo colapsaría dos disposiciones que la tradición separa. Y mientras el control
-- abierto no pregunte el régimen, ante estas dos no elige ninguna: pide que se marque en la lista.
--
-- *El rasgo `final_acentual: agudo` sigue sin preguntarse en las seis, y es correcto: ahí el agudo es
-- definitorio, y dónde cae ya lo dice el propio esquema.*
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
	select forma_id into v_forma from public.formas_metricas where slug = 'octava_aguda' and activo;
	if v_forma is null then
		raise exception 'La forma «octava_aguda» no está activa.';
	end if;

	foreach v_par slice 1 in array array[
		array['endecasilabica', 'opciones_y_esquema', '2'],
		array['decasilabica', 'opciones_y_esquema', '2'],
		array['octosilabica', 'opciones_y_esquema', '2'],
		array['heptasilabica', 'opciones_y_esquema', '2'],
		array['hexasilabica', 'opciones_y_esquema', '2'],
		array['pentasilabica', 'opciones_y_esquema', '2']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de octava_aguda no está activa.', v_par[1];
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

		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and dimension = 'rima' and activo
		) then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
				permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
			)
			values (
				v_arq, 'esquema_rima', 'rima', 'unidad', 1, 1,
				true, true, 1, v_par[2], false, 'Riman en agudo los versos que cierran cada semiestrofa. Marca si lo hacen en consonante o en asonante.'
			);
		else
			update public.grupos_eleccion_metrica
			set tipo_control = v_par[2], ayuda_editor = coalesce(ayuda_editor, 'Riman en agudo los versos que cierran cada semiestrofa. Marca si lo hacen en consonante o en asonante.')
			where arquitectura_id = v_arq and dimension = 'rima' and activo;
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
	if v_total <> 12 then
		raise exception 'Las preguntas de octava_aguda ofrecen % opciones, y se esperaban 12.', v_total;
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
		raise exception '% arquitecturas de octava_aguda siguen sin preguntar su rima.', v_n;
	end if;

	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('octava_aguda') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de octava_aguda ha dejado de responder.';
	end if;
end $$;

commit;
