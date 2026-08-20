-- La sextilla manriqueña dice cómo rima
--
-- Segunda vuelta sobre la sextilla, el 20 de agosto de 2026. La primera revisó su prosa; esta
-- corrige lo que apareció al revisar el sexteto y tirar del hilo manriqueño.
--
-- 1. **El agujero de densidad.** La `octosilabica` —la principal— y la `doble_pie_quebrado` no
--    declaraban `densidad_de_rima`, y las otras tres sí. No era una decisión: el aviso
--    `patron_rima_sin_regla` se apaga en cuanto hay *o* una restricción *o* un esquema concreto,
--    y las dos tenían esquemas concretos. Pero un esquema concreto no dice nada de la
--    disposición abierta, que es la que la norma declara. Se declara en las cinco.
--
-- 2. **Los nombres de esquema truncaban a la fuente y luego la repetían.** Se leía «Alterna ·
--    también Sextilla alterna», porque el `nombre` era nuestra abreviación del nombre que la
--    denominación ya traía con su fuente —Baehr recogido por Domínguez Caparrós, y Navarro Tomás
--    para la simétrica—. Se quita el `nombre` de los tres y habla la denominación, que es lo que
--    ya hace el `ABABCC` del sexteto con «Sexta rima». «Sextilla simétrica» pasa a preferente
--    sobre «Sextilla paralela»: la usan dos fuentes frente a una.
--
-- 3. **La estrofa de Manrique no decía cómo rimaba Manrique.** La arquitectura `pie_quebrado`
--    lleva los tres alias manriqueños y no declaraba ningún esquema concreto. El *Diccionario* lo
--    da con todas las letras: «Copla de pie quebrado en la que se combinan dos grupos de tres
--    versos —en cada grupo hay dos octosílabos seguidos de un tetrasílabo— con el siguiente
--    esquema de distribución de la rima consonante: abcabc». Es la misma disposición que la
--    octosilábica llama «Sextilla correlativa», y con esa denominación se declara.
--
-- 4. **La doble no puede dejar de ser manriqueña.** La restricción `excluye_esquema` decía que la
--    disposición abierta de la doble no puede coincidir con la manriqueña, y eso no lo sostiene
--    ninguna fuente: `abcabc:defdef` es justamente la de Manrique. Venía del vocabulario legado,
--    donde `doble_sextilla_alternativa` se definía como «Para el resto de casos» — un cajón
--    residual convertido en regla. Es el mismo error inductivo que esta forma ya se quitó en
--    agosto, cuando dejó de convertir su muestra en norma. Se retira.
--
-- 5. **«Copla manriqueña» estaba dos veces en la misma ficha**, sobre la arquitectura de seis y
--    sobre el esquema de doce, señalando cosas distintas. Se retira la del esquema —que además
--    no tiene fuente— y la descripción de la doble recoge el desacuerdo real de la bibliografía,
--    que es lo que le hace falta al lector: manriqueñas son las dos, la estrofa es técnicamente
--    la sextilla, y si se llama así a la agrupación de doce es porque en las *Coplas* el sentido
--    pasa de una a la otra — no las rimas, que se quedan en la suya.
--
-- Ninguna anotación usa estas formas: el corpus no tiene todavía ninguna sextilla.

begin;

do $$
declare
	v_forma uuid;
	v_octo uuid;
	v_quebrado uuid;
	v_doble uuid;
	v_fuente_dicc uuid;
	v_abcabc uuid;
	v_manriquena uuid;
	v_actual text;
	v_n integer;

	c_nota_densidad constant text :=
		'La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.';

	c_doble constant text :=
		'Dos sextillas de pie quebrado seguidas. No es una estrofa distinta de la simple: la medida '
		|| 'y la rima se organizan exactamente igual, y las rimas de la primera no pasan a la '
		|| 'segunda. Lo único que las enlaza es el sentido, que en las *Coplas* de Jorge Manrique '
		|| 'corre de una a otra sin cerrarse en la primera, y por eso la tradición suele llamar '
		|| 'manriqueña a esta agrupación de doce versos. Manriqueñas lo son las dos: la estrofa es '
		|| 'técnicamente la sextilla, y así la nombran Quilis y Domínguez Caparrós, mientras que '
		|| 'Navarro Tomás y Jauralde prefieren contar los doce.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sextilla';
	if v_forma is null then
		raise exception 'No existe la forma «sextilla».';
	end if;

	select arquitectura_id into v_octo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica' and activo;
	select arquitectura_id into v_quebrado from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'pie_quebrado' and activo;
	select arquitectura_id into v_doble from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'doble_pie_quebrado' and activo;

	if v_octo is null or v_quebrado is null or v_doble is null then
		raise exception 'Faltan arquitecturas activas de la sextilla.';
	end if;

	-- ------------------------------------------- 1. La densidad, en las cinco arquitecturas
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	select a.arquitectura_id, rm.rasgo_id, rv.valor_id, 'definitoria', c_nota_densidad
	from public.arquitecturas_forma a
	cross join public.rasgos_metricos rm
	join public.rasgo_valores rv on rv.rasgo_id = rm.rasgo_id and rv.slug = 'total'
	where a.arquitectura_id in (v_octo, v_doble) and rm.slug = 'densidad_de_rima'
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update set nota = excluded.nota;

	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_forma
		and a.activo
		and rm.slug = 'densidad_de_rima'
		and rv.slug = 'total'
		and ar.modalidad = 'definitoria';
	if v_n <> 5 then
		raise exception 'Declaran densidad total % arquitecturas de la sextilla, no las cinco.', v_n;
	end if;

	-- --------------------------------- 2. El nombre lo pone la denominación, no la abreviación
	update public.esquemas_rima
	set nombre = null
	where arquitectura_id = v_octo and slug in ('ababab', 'abcabc', 'aabccb');

	-- Y cada uno conserva el nombre de la tradición, que es el que ahora se ve.
	select count(*) into v_n
	from public.esquemas_rima er
	where er.arquitectura_id = v_octo
		and er.slug in ('ababab', 'abcabc', 'aabccb')
		and er.nombre is null
		and exists (
			select 1 from public.denominaciones_metricas d
			where d.esquema_rima_id = er.esquema_rima_id
		);
	if v_n <> 3 then
		raise exception 'Solo % de los tres esquemas nombrados cede su nombre a su denominación.', v_n;
	end if;

	update public.denominaciones_metricas
	set preferente = (slug_normalizado = 'sextilla_simetrica')
	where esquema_rima_id = (
		select esquema_rima_id from public.esquemas_rima
		where arquitectura_id = v_octo and slug = 'aabccb'
	);

	-- ---------------------------------- 3. La estrofa de Manrique declara su disposición
	select fuente_id into v_fuente_dicc
	from public.fuentes_metricas
	where autoria = 'José Domínguez Caparrós' and anio = 2016;

	if v_fuente_dicc is null then
		raise exception 'No está el Diccionario de métrica española de 2016 entre las fuentes.';
	end if;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
		estado_revision
	)
	select v_quebrado, 'abcabc', null, 'abcabc', a.tipo_rima_id, 'habitual', 'secuencia', 'revisada'
	from public.arquitecturas_forma a
	where a.arquitectura_id = v_quebrado
	on conflict (arquitectura_id, slug) do update
		set nombre = excluded.nombre,
			notacion = excluded.notacion,
			modalidad = excluded.modalidad,
			tipo_secuencia = excluded.tipo_secuencia;

	select esquema_rima_id into v_abcabc
	from public.esquemas_rima where arquitectura_id = v_quebrado and slug = 'abcabc';

	-- El disparador reparte la notación en posiciones. Se comprueba lo que ha escrito.
	if (
		select string_agg(clase_rima, '' order by posicion)
		from public.esquema_rima_posiciones where esquema_rima_id = v_abcabc
	) is distinct from 'abcabc' then
		raise exception 'Las posiciones de la disposición manriqueña no dicen abcabc.';
	end if;

	insert into public.denominaciones_metricas
		(esquema_rima_id, nombre, slug_normalizado, preferente, fuente_id)
	values (v_abcabc, 'Sextilla correlativa', 'sextilla_correlativa', true, v_fuente_dicc)
	-- El índice que garantiza el nombre único por esquema es parcial, así que la inferencia
	-- necesita repetir su predicado.
	on conflict (esquema_rima_id, slug_normalizado) where esquema_rima_id is not null do update
		set nombre = excluded.nombre,
			preferente = excluded.preferente,
			fuente_id = excluded.fuente_id;

	-- ------------------------- 4. La doble no deja de ser doble por ser manriqueña
	delete from public.esquema_rima_restricciones r
	using public.esquemas_rima er
	where er.esquema_rima_id = r.esquema_rima_id
		and er.arquitectura_id = v_doble
		and r.tipo = 'excluye_esquema';

	-- La de regularidad se queda: dice algo verdadero y no es residual.
	if not exists (
		select 1 from public.esquema_rima_restricciones r
		join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
		where er.arquitectura_id = v_doble and r.tipo = 'regularidad'
	) then
		raise exception 'La doble sextilla ha perdido su restricción de regularidad.';
	end if;
	if exists (
		select 1 from public.esquema_rima_restricciones r
		join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
		where er.arquitectura_id = v_doble and r.tipo = 'excluye_esquema'
	) then
		raise exception 'La doble sextilla sigue excluyendo la disposición manriqueña.';
	end if;

	-- --------------------- 5. «Copla manriqueña» deja de estar dos veces en la misma ficha
	select esquema_rima_id into v_manriquena
	from public.esquemas_rima where arquitectura_id = v_doble and slug = 'abcabc-defdef';

	if v_manriquena is null then
		raise exception 'No existe el esquema manriqueño de la doble sextilla.';
	end if;

	delete from public.denominaciones_metricas
	where esquema_rima_id = v_manriquena and slug_normalizado = 'copla_manriquena';

	-- El nombre sigue donde las fuentes lo ponen: en la arquitectura de seis versos.
	if not exists (
		select 1 from public.denominaciones_metricas
		where arquitectura_id = v_quebrado and slug_normalizado = 'copla_manriquena'
	) then
		raise exception 'La arquitectura de pie quebrado ha perdido el alias «Copla manriqueña».';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_doble;
	if v_actual not like '%Dos sextillas que el sentido enlaza%' and v_actual is distinct from c_doble
	then
		raise exception 'La descripción de la doble sextilla no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_doble where arquitectura_id = v_doble;
end $$;

commit;
