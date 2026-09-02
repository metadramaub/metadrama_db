-- El septeto-lira pregunta su disposición de rima
--
-- Declara `ababbcc` como **habitual** —«Alterna con pareado final»— y no lo preguntaba: el editor
-- daba por hecho que el pasaje rima así, sin manera de confirmarlo ni de decir otra cosa. Y
-- `habitual` significa justamente que es la corriente, no la única.
--
-- Contado sobre el catálogo, de las arquitecturas activas sin pregunta de rima **es la única en ese
-- caso**. Las otras cuatro que declaran un esquema no definitorio y tampoco preguntan tienen razones:
--
--   * el **endecasílabo suelto** y las dos **silvas** abiertas declaran esquemas de secuencia
--     `abierta` y sin posiciones —«predominio de versos sueltos», «consonante de orden libre»—, así
--     que no hay disposición que ofrecer: lo que se pregunta allí son rasgos;
--   * el **sexteto-lira** sí tiene tres disposiciones con posiciones, pero su rima se elige por la
--     variedad, que es la cuestión de qué es una variedad que está planteada al IP.
--
-- Se le crea la pregunta con la misma forma que la de la décima-lira, que es su hermana en la serie
-- alirada: repertorio y **salida abierta**, obligatoria. El repertorio sale solo —la función que
-- deriva las opciones ofrece los esquemas de secuencia, y `ababbcc` lo es—, así que la pregunta
-- nace con una opción y el campo para escribir otra.

begin;

do $$
declare
	v_arquitectura uuid;
	v_esquemas integer;
begin
	select a.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Septeto-lira' and a.nombre = 'Heterométrica consonante';

	if v_arquitectura is null then
		raise exception 'No está el septeto-lira: revisa el catálogo antes de seguir.';
	end if;

	-- La disposición que se va a ofrecer tiene que existir y no ser definitoria: una definitoria no
	-- se ofrece nunca, y el disparador lo rechazaría.
	select count(*) into v_esquemas
	from public.esquemas_rima er
	where er.arquitectura_id = v_arquitectura
		and er.tipo_secuencia not in ('abierta', 'restricciones')
		and er.modalidad <> 'definitoria';

	if v_esquemas <> 1 then
		raise exception 'El septeto-lira tiene % disposiciones ofrecibles, y se esperaba 1.', v_esquemas;
	end if;

	if exists (
		select 1 from public.grupos_eleccion_metrica
		where arquitectura_id = v_arquitectura and dimension = 'rima'
	) then
		raise notice 'El septeto-lira ya pregunta su disposición de rima.';
	else
		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, tipo_control,
			selecciones_min, selecciones_max, permite_aplicar_global, define_norma, orden,
			ayuda_editor, activo
		)
		values (
			v_arquitectura, 'disposicion_rima', 'rima', 'unidad', 'opciones_y_esquema',
			1, 1, true, false, 1,
			'Marca la disposición si es la documentada. Si la estrofa rima de otro modo, escríbelo: el catálogo solo tiene testimonio de una.',
			true
		);
	end if;
end $$;

do $$
declare
	v_control text;
	v_min integer;
	v_max integer;
	v_opciones integer;
	v_notacion text;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la función que deriva las opciones**, leyendo la vista: una pregunta sin
	-- repertorio no serviría de nada, y eso solo se sabe corriéndola.
	select g.tipo_control, g.selecciones_min, g.selecciones_max
	into v_control, v_min, v_max
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Septeto-lira' and g.dimension = 'rima' and g.activo;

	if v_control is distinct from 'opciones_y_esquema' or v_min <> 1 or v_max <> 1 then
		raise exception 'La pregunta del septeto-lira quedó como % y % a % respuestas.', v_control, v_min, v_max;
	end if;

	select count(*), min(o.nombre) into v_opciones, v_notacion
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Septeto-lira' and g.dimension = 'rima';

	if v_opciones <> 1 then
		raise exception 'El septeto-lira ofrece % disposiciones, y debía ofrecer 1.', v_opciones;
	end if;

	if v_notacion not like '%ababbcc%' then
		raise exception 'La disposición que ofrece el septeto-lira es «%», y se esperaba ababbcc.', v_notacion;
	end if;
end $$;

commit;
