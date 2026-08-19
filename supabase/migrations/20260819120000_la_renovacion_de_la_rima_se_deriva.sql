-- La renovación de la rima se deriva, y la silva regular declara su densidad
--
-- **La nota sobra porque la ficha ya lo dice.** El modelo declara la conservación de rima entre
-- repeticiones **en positivo**, con `esquema_rima_enlaces`: por eso el romance imprime «El verso
-- 2 conserva su rima en cada repetición». La renovación era el silencio, y un silencio no se
-- distingue de un dato que falta. Desde ahora la rejilla lo deriva —ciclo que rima y sin ningún
-- enlace declarado— y lo imprime, así que la nota de la silva regular queda repetida.
--
-- El criterio queda escrito en el modelo aplicado. Y lleva una condición que no sobra: **el
-- ciclo tiene que rimar**. La `suelta` de la endecha real es `[----]…`, con las cuatro
-- posiciones sueltas, y allí hablar de renovar la rima no significaría nada. Son los dos únicos
-- ciclos sin enlaces del catálogo, y solo uno de ellos rima.
--
-- Aparte, la silva de consonantes pasa a declarar su densidad de rima. Era la única de las
-- cuatro que no lo hacía, y en esta forma la densidad **sí discrimina**: es uno de los dos ejes
-- con que se separan sus arquitecturas. No es una obligación de catálogo —`densidad_de_rima` lo
-- declaran ocho formas y las demás no lo necesitan, porque su rima no varía en densidad—, pero
-- dentro de la silva el hueco se leía como olvido. Si todos los versos van en pareado, la
-- densidad es total por definición.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Fuera la nota que la ficha ya deriva
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_actual text;
	v_esperada constant text := 'La clase de rima se renueva en cada bloque.';
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'silva' and a.slug = 'consonante_regular' and er.slug = 'pareados-regulares';

	if v_esquema is null then
		raise exception 'No existe el esquema «pareados-regulares» de la silva.';
	end if;

	select descripcion into v_actual from public.esquemas_rima where esquema_rima_id = v_esquema;

	if v_actual is not null and v_actual is distinct from v_esperada then
		raise exception 'La descripción de «pareados-regulares» no es la esperada. Dice: %', v_actual;
	end if;

	-- La derivación solo funciona si el ciclo sigue sin enlaces: es lo que la produce.
	if (
		select count(*) from public.esquema_rima_enlaces where esquema_rima_id = v_esquema
	) <> 0 then
		raise exception 'El ciclo de la silva regular declara enlaces: entonces conserva la rima, no la renueva.';
	end if;

	update public.esquemas_rima set descripcion = null where esquema_rima_id = v_esquema;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · La silva de consonantes declara su densidad
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_rasgo uuid;
	v_valor uuid;
	v_declaradas integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'silva' and a.slug = 'consonante_regular' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa silva/consonante_regular.';
	end if;

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'densidad_de_rima';
	select valor_id into v_valor
	from public.rasgo_valores where rasgo_id = v_rasgo and slug = 'total';

	if v_valor is null then
		raise exception 'No existe el valor «total» de densidad_de_rima.';
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad)
	select v_arq, v_rasgo, v_valor, 'definitoria'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo
	);

	-- Las cuatro arquitecturas de la silva declaran ya su densidad.
	select count(distinct a.arquitectura_id) into v_declaradas
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'silva' and a.activo and ar.rasgo_id = v_rasgo;

	if v_declaradas <> 4 then
		raise exception 'Solo % arquitecturas de la silva declaran densidad de rima; se esperaban 4.', v_declaradas;
	end if;
end $$;

commit;
