-- Los quebrados de la manriqueña dicen cuánto miden
--
-- En la copla manriqueña **se sabe dónde van los quebrados** —la norma los fija en los versos 3, 6, 9
-- y 12— pero no si son tetrasílabos o pentasílabos. El esquema métrico ya lo declara: esas cuatro
-- posiciones traen dos alternativas, `alternativa 1 = 4` y `alternativa 2 = 5`. Lo que faltaba es la
-- pregunta: la arquitectura **no tenía ningún grupo de elección de metro**, así que el editor no podía
-- registrar cuál de las dos lee, y esa es la única variación que la forma admite en su medida.
--
-- Por eso la pregunta es **por la medida, no por la posición**: no se marca dónde hay quebrado —eso ya
-- lo dice la norma—, se dice cuánto mide cada uno de los que la norma pone.
--
-- No hace falta escribir ninguna opción: `opciones_eleccion_derivadas()` tiene una rama que, para un
-- grupo de metro cuyo esquema no declara medida uniforme, ofrece **las posiciones del esquema que
-- admiten más de un metro**. Aquí eso son exactamente las cuatro. Con `selecciones_min` igual a
-- `selecciones_max` la pantalla las pide todas y no entra en el modo de «marcar excepciones», que es
-- el de la copla castellana y aquí no viene a cuento.
--
-- **Le pasa igual a la sextilla de pie quebrado**, que es la mitad de esta y tiene dos posiciones con
-- alternativa: entra en la misma migración porque es el mismo hueco y el mismo arreglo.
--
-- Se añaden además los **roles del esquema** —dominante 8, quebrado 4 y 5—, que es como lo declaran
-- las otras diez arquitecturas con quebrados. Sin ellos la pantalla no sabe cuál es la medida de base
-- y no puede pintar los octosílabos que no se preguntan. No duplica opciones: la rama que deriva
-- opciones desde los roles solo actúa cuando el esquema declara `medida_uniforme`, y estos dos la
-- tienen en nulo.

begin;

do $$
declare
	v_arq record;
	v_octo uuid;
	v_tetra uuid;
	v_penta uuid;
	v_grupo uuid;
	v_posiciones integer;
begin
	select metro_id into v_octo from public.metros where silabas = 8 and nombre = 'Octosílabo';
	select metro_id into v_tetra from public.metros where silabas = 4 and nombre = 'Tetrasílabo';
	select metro_id into v_penta from public.metros where silabas = 5 and nombre = 'Pentasílabo';
	if v_octo is null or v_tetra is null or v_penta is null then
		raise exception 'Faltan los metros de 8, 4 o 5 sílabas.';
	end if;

	for v_arq in
		select a.arquitectura_id, f.nombre as forma, em.esquema_metrico_id, em.medida_uniforme
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		where f.nombre in ('Copla manriqueña', 'Sextilla')
			and a.nombre = 'De pie quebrado'
	loop
		-- **Se comprueba el supuesto antes de apoyarse en él.** La rama que deriva las opciones solo
		-- actúa con `medida_uniforme` en nulo; si algún día deja de estarlo, esta migración habría
		-- creado una pregunta sin opciones.
		if v_arq.medida_uniforme is not null then
			raise exception '% declara medida_uniforme = %, y entonces la pregunta no derivaría sus opciones de las alternativas.',
				v_arq.forma, v_arq.medida_uniforme;
		end if;

		select count(*) into v_posiciones
		from (
			select p.posicion
			from public.esquema_metrico_posiciones p
			where p.esquema_metrico_id = v_arq.esquema_metrico_id
			group by p.posicion
			having count(distinct p.metro_id) > 1
		) alternativas;

		if v_posiciones = 0 then
			raise exception 'El esquema de % no tiene ninguna posición con alternativa.', v_arq.forma;
		end if;

		-- Los roles del esquema, si no están.
		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, rol, orden)
		values
			(v_arq.esquema_metrico_id, v_octo, 'dominante', 1),
			(v_arq.esquema_metrico_id, v_tetra, 'quebrado', 2),
			(v_arq.esquema_metrico_id, v_penta, 'quebrado', 3)
		on conflict do nothing;

		-- Y la pregunta, si no está.
		select grupo_eleccion_id into v_grupo
		from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq.arquitectura_id and slug = 'medida_de_los_quebrados';

		if v_grupo is null then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, tipo_control,
				selecciones_min, selecciones_max, permite_aplicar_global, define_norma,
				activo, orden, ayuda_editor
			)
			values (
				v_arq.arquitectura_id,
				'medida_de_los_quebrados',
				'metro',
				'unidad',
				'opciones',
				v_posiciones,
				v_posiciones,
				true,
				false,
				true,
				2,
				'La norma ya dice qué versos van quebrados; lo que no fija es cuánto miden. Indica si cada uno es de cuatro o de cinco sílabas.'
			);
		else
			update public.grupos_eleccion_metrica
			set selecciones_min = v_posiciones, selecciones_max = v_posiciones, activo = true
			where grupo_eleccion_id = v_grupo;
		end if;
	end loop;
end $$;

do $$
declare
	v_fila record;
	v_esperadas integer;
	v_reales integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la vista**, que es lo que va a leer la aplicación: un grupo bien insertado con una
	-- función que no lo contemple sería una pregunta vacía en pantalla.
	for v_fila in
		select f.nombre as forma, g.grupo_eleccion_id, g.selecciones_min
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where g.slug = 'medida_de_los_quebrados' and a.nombre = 'De pie quebrado'
	loop
		select count(*) into v_reales
		from public.opciones_eleccion_metrica o
		where o.grupo_eleccion_id = v_fila.grupo_eleccion_id;

		-- Dos metros por cada posición con alternativa.
		v_esperadas := v_fila.selecciones_min * 2;
		if v_reales <> v_esperadas then
			raise exception 'La pregunta de % ofrece % opciones y se esperaban %.',
				v_fila.forma, v_reales, v_esperadas;
		end if;

		-- Y son de 4 y de 5, no de otra cosa.
		if exists (
			select 1 from public.opciones_eleccion_metrica o
			join public.metros m on m.metro_id = o.metro_id
			where o.grupo_eleccion_id = v_fila.grupo_eleccion_id and m.silabas not in (4, 5)
		) then
			raise exception 'La pregunta de % ofrece medidas que no son de 4 ni de 5 sílabas.', v_fila.forma;
		end if;
	end loop;

	-- La manriqueña pregunta por sus cuatro quebrados, y la sextilla por sus dos.
	select count(*) into v_reales
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.slug = 'medida_de_los_quebrados' and g.activo
		and ((f.nombre = 'Copla manriqueña' and g.selecciones_min = 4)
			or (f.nombre = 'Sextilla' and g.selecciones_min = 2));

	if v_reales <> 2 then
		raise exception 'Se esperaban las dos preguntas —manriqueña de 4 y sextilla de 2— y hay %.', v_reales;
	end if;
end $$;

commit;
