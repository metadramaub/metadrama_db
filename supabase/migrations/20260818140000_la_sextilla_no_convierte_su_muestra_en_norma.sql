-- La sextilla no convierte su muestra en norma
--
-- Rectifica `20260818130000`, del mismo día. Allí se declararon ocho restricciones —`ninguno`
-- de versos sueltos y `min_alternancias: 3` en los cuatro esquemas abiertos— y **estaban mal
-- fundadas**, cada una por su motivo.
--
-- `min_alternancias: 3` se derivó contando alternancias sobre las disposiciones que el catálogo
-- recoge. Pero esa lista no es una norma: es lo que la tradición ha nombrado. **Quilis lo dice
-- en su propia frase** —«con varias combinaciones de rima: aabaab, abcabc, ababab, **etc.**»—,
-- y el «etcétera» es la prueba de que la enumeración está abierta. Sacar un mínimo de ahí no es
-- leer una regla, es convertir una muestra en ley: cualquier sextilla documentada más adelante
-- que no llegara a tres alternancias saldría marcada como incumplimiento, cuando lo que fallaba
-- era la regla inventada.
--
-- La prueba material de que la muestra está incompleta la da el propio repertorio: `aabaab` lo
-- documentan Quilis y el *Diccionario* —este en la sextilla de pie quebrado, junto a `aabccb` y
-- `abcabc`— y no estaba recogido. Se añade aquí como cuarta disposición admitida.
--
-- `versos_sueltos: ninguno` estaba mal por otro motivo: **es una decisión de alcance escrita
-- como si fuera una norma**. Que el catálogo no admita todavía la sextilla de primer verso
-- suelto —fuera por criterio cronológico, porque el *Martín Fierro* es de 1872— no significa
-- que la forma lo prohíba; tres de las seis fuentes documentan justamente lo contrario. Una
-- cosa es «no se admite anotarlo» y otra «la forma no lo permite», y el catálogo solo puede
-- decir la segunda.
--
-- Lo que queda diciendo cómo se comporta la rima de estas arquitecturas es lo que ya lo decía
-- antes y no se inventó nada: los esquemas concretos de la octosilábica y el rasgo
-- `Densidad de rima: Total` de las otras tres. Son dos de las tres maneras que la decisión del
-- 10 de agosto de 2026 reconoce.
--
-- **No se tocan** las dos restricciones de `consonante-variable`, en la doble sextilla: esas no
-- son inducción sino la definición de la arquitectura —debe ser regular y no puede coincidir
-- con la manriqueña, que es el otro esquema—.
--
-- Las guardas admiten el estado anterior y el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Fuera las ocho restricciones inducidas
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_borradas integer;
	v_restantes integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «sextilla».';
	end if;

	with objetivo as (
		select r.restriccion_id
		from public.esquema_rima_restricciones r
		join public.esquemas_rima er using (esquema_rima_id)
		join public.arquitecturas_forma a using (arquitectura_id)
		where a.forma_id = v_forma
			and er.slug = 'distribucion-variable'
			and r.tipo in ('versos_sueltos', 'min_alternancias')
	)
	delete from public.esquema_rima_restricciones
	where restriccion_id in (select restriccion_id from objetivo);

	get diagnostics v_borradas = row_count;

	-- Idempotente: la primera vez borra ocho, la segunda ninguna.
	if v_borradas not in (0, 8) then
		raise exception 'Se esperaban 8 restricciones inducidas o ninguna; se borraron %.', v_borradas;
	end if;

	select count(*) into v_restantes
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er using (esquema_rima_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and er.slug = 'distribucion-variable';

	if v_restantes > 0 then
		raise exception 'Los esquemas abiertos de la sextilla conservan % restricciones.', v_restantes;
	end if;

	-- Las de la doble sextilla no son inducción y siguen ahí.
	if (
		select count(*)
		from public.esquema_rima_restricciones r
		join public.esquemas_rima er using (esquema_rima_id)
		join public.arquitecturas_forma a using (arquitectura_id)
		where a.forma_id = v_forma and er.slug = 'consonante-variable'
	) <> 2 then
		raise exception 'Las dos restricciones de la doble sextilla ya no están.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Entra `aabaab`, que dos fuentes documentan y faltaba
--
-- El trigger `esquemas_rima_sincronizar_posiciones_fijas` deriva sus seis posiciones de la
-- notación al insertarla, así que no se escriben a mano.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_tipo_rima uuid;
	v_esquema uuid;
	v_posiciones integer;
begin
	select a.arquitectura_id, a.tipo_rima_id into v_arq, v_tipo_rima
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'sextilla' and a.slug = 'octosilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa sextilla/octosilabica.';
	end if;

	insert into public.esquemas_rima (
		arquitectura_id, slug, notacion, tipo_secuencia, modalidad, tipo_rima_id, estado_revision
	)
	select v_arq, 'aabaab', 'aabaab', 'secuencia', 'admitida', v_tipo_rima, 'aprobada'
	where not exists (
		select 1 from public.esquemas_rima
		where arquitectura_id = v_arq and slug = 'aabaab'
	);

	select esquema_rima_id into v_esquema
	from public.esquemas_rima where arquitectura_id = v_arq and slug = 'aabaab';

	select count(*) into v_posiciones
	from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;

	if v_posiciones <> 6 then
		raise exception 'El esquema «aabaab» tiene % posiciones; se esperaban 6.', v_posiciones;
	end if;

	-- Y que digan lo que dice la notación, letra por letra: es lo que comprueba D14.
	if (
		select string_agg(coalesce(clase_rima, '-'), '' order by bloque, posicion)
		from public.esquema_rima_posiciones where esquema_rima_id = v_esquema
	) <> 'aabaab' then
		raise exception 'Las posiciones de «aabaab» no reproducen su notación.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La definición dice que el repertorio no está cerrado
--
-- Decía «siempre con dos o tres clases de rima», que era la misma inducción en prosa.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de seis versos de arte menor que riman todos en consonante. Su disposición no está fijada: la tradición documenta media docena, siempre con dos o tres clases de rima, y ha dado nombre propio a las más frecuentes —alterna, correlativa, simétrica—. Cuando el tercer verso y el sexto se quiebran en otros más breves resulta la sextilla de pie quebrado, de la que procede la copla de Jorge Manrique.';
	v_nuevo constant text :=
		'Estrofa de seis versos de arte menor que riman todos en consonante. Lo que no está fijado es su disposición, y esa libertad la define tanto como el número de versos: la tradición ha dado nombre a las más frecuentes —alterna, correlativa, simétrica— pero las enumera siempre en abierto, de modo que las recogidas aquí son las documentadas y no todas las posibles. Cuando el tercer verso y el sexto se quiebran en otros más breves resulta la sextilla de pie quebrado, de la que procede la copla de Jorge Manrique.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la sextilla no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La afirmación de Quilis conserva su «etcétera»
--
-- Es el dato que decide todo lo anterior, y estaba resumido sin él.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'Define la sextilla como estrofa de versos de arte menor con varias combinaciones de rima, y cita aabaab, abcabc y ababab. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez Caparrós escribe un guion.';
	v_nuevo constant text :=
		'Define la sextilla como estrofa de versos de arte menor «con varias combinaciones de rima: aabaab, abcabc, ababab, **etc.**». La enumeración queda expresamente abierta. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez Caparrós escribe un guion.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'sextilla' and activo;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;

	if v_id is null then
		raise exception 'No existe la afirmación de Quilis sobre la sextilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación de Quilis no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

commit;
