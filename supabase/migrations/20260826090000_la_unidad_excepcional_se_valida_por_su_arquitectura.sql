-- La unidad excepcional se valida por su arquitectura, no por la de la secuencia
--
-- Segunda mitad de B5. La primera —`20260825410000`— dejó que una realización declarara una
-- arquitectura **intercalable** de su misma forma: la décima aumentada entre décimas normales, que
-- Morley y Bruerton documentan y que no es una desviación, porque la norma admite la estrofa larga.
--
-- Pero las dos guardas que comprueban la estructura seguían midiéndolo todo contra la arquitectura
-- de la secuencia, y al guardar la primera tirada con una aumentada saltaron las dos:
--
--   «La sección realizada no pertenece a la arquitectura seleccionada»
--   «Cada unidad necesita al menos 1 realizaciones de "Primera redondilla"»
--
-- Y con razón, según lo que sabían: la espinela son tres secciones —4 + 2 + 4— y la aumentada dos
-- —4 + 8—. Ninguna de las dos partes de la aumentada pertenece a la espinela, y ninguna de las tres
-- de la espinela aparece bajo la aumentada.
--
-- **Lo que cambia.** Las dos guardas dejan de preguntar «¿es esta la arquitectura de la secuencia?»
-- y pasan a preguntar «¿es esta la arquitectura de la unidad de la que cuelga?». Para casi todas las
-- unidades la respuesta es la misma, porque casi ninguna declara nada; solo cambia para la que sí.
--
-- *Lo que no cambia:* que la arquitectura declarada sea legítima —misma forma, intercalable, y solo
-- en la realización de la unidad— lo sigue comprobando `validar_arquitectura_de_realizacion()`, que
-- entró con la migración anterior y aquí no se toca. Esta migración da por bueno lo que aquella ya
-- validó.

begin;

do $$
declare
	v_escenario_id uuid;
	v_autor uuid;
	v_forma_id uuid;
	v_espinela uuid;
	v_aumentada uuid;
	v_secuencia uuid;
	v_unidad uuid;
	v_seccion record;
	v_error text;
	v_cursor integer;
	v_orden integer;
begin
	-- ------------------------------------------------------------------ Antes de tocar nada
	if to_regprocedure('public.validar_realizacion_editor_metrico()') is null then
		raise exception 'No está la guarda de la realización.';
	end if;
	if to_regprocedure('public.validar_estructura_secuencia_editor_metrico(uuid)') is null then
		raise exception 'No está la guarda de la estructura.';
	end if;

	-- La aumentada tiene que estar declarada intercalable: si no, esta migración no arregla nada
	-- y estaría relajando dos guardas a cambio de nada.
	select a.arquitectura_id into v_aumentada
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'decima' and a.nombre = 'Aumentada' and a.intercalable;
	if v_aumentada is null then
		raise exception 'La décima aumentada no está declarada intercalable.';
	end if;

	select a.arquitectura_id, a.forma_id into v_espinela, v_forma_id
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'decima' and a.nombre = 'Espinela';
	if v_espinela is null then
		raise exception 'No está la espinela.';
	end if;

	-- ------------------------------------------------------------------ La guarda de cada fila
	--
	-- Una sección se realiza dentro de una unidad. Cuál sea la arquitectura buena depende de esa
	-- unidad, así que se sube por la cadena de realizaciones hasta encontrarla: una sección raíz
	-- cuelga de la unidad misma; una interna, de la realización de su sección superior.
	create or replace function public.validar_realizacion_editor_metrico()
	returns trigger
	language plpgsql
	set search_path to 'public'
	as $fn$
	declare
		v_arquitectura_id uuid;
		v_arquitectura_unidad uuid;
		v_arquitectura_efectiva uuid;
		v_secuencia_ini integer;
		v_secuencia_fin integer;
		v_seccion_padre_esperada uuid;
		v_seccion_padre_real uuid;
		v_padre_ini integer;
		v_padre_fin integer;
	begin
		select arquitectura_id, v_ini, v_fin
		into v_arquitectura_id, v_secuencia_ini, v_secuencia_fin
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = new.secuencia_prueba_id;

		if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
			raise exception 'La realización debe quedar dentro del rango de la secuencia';
		end if;

		-- Una realización sin sección es la realización de la unidad que define la forma.
		if new.seccion_id is null then
			if new.realizacion_padre_id is not null then
				raise exception 'La realización de la unidad no cuelga de ninguna otra';
			end if;
			return new;
		end if;

		if new.realizacion_padre_id is null then
			raise exception 'Una sección se realiza siempre dentro de una unidad';
		end if;

		-- **La arquitectura de la unidad de la que cuelga esta sección.** Se sube por la cadena
		-- hasta la realización sin padre, que es la de la unidad. Casi siempre no declara nada y
		-- manda la de la secuencia; cuando declara una intercalada, manda la suya.
		with recursive cadena as (
			select realizacion_prueba_id, realizacion_padre_id, arquitectura_id
			from public.realizaciones_editor_metrico
			where realizacion_prueba_id = new.realizacion_padre_id
				and secuencia_prueba_id = new.secuencia_prueba_id
			union all
			select superior.realizacion_prueba_id,
				superior.realizacion_padre_id,
				superior.arquitectura_id
			from public.realizaciones_editor_metrico superior
			join cadena on cadena.realizacion_padre_id = superior.realizacion_prueba_id
			where superior.secuencia_prueba_id = new.secuencia_prueba_id
		)
		select arquitectura_id into v_arquitectura_unidad
		from cadena
		where realizacion_padre_id is null;

		v_arquitectura_efectiva := coalesce(v_arquitectura_unidad, v_arquitectura_id);

		select seccion_padre_id
		into v_seccion_padre_esperada
		from public.estructuras_secciones
		where seccion_id = new.seccion_id
			and arquitectura_id = v_arquitectura_efectiva;

		if not found then
			raise exception 'La sección realizada no pertenece a la arquitectura seleccionada';
		end if;

		select seccion_id, v_ini, v_fin
		into v_seccion_padre_real, v_padre_ini, v_padre_fin
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_padre_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if not found then
			raise exception 'La realización superior debe pertenecer a la misma secuencia';
		end if;
		-- Una sección raíz cuelga de la unidad, cuya realización no tiene sección; una sección
		-- interna cuelga de la realización de su sección superior.
		if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
			raise exception 'La realización superior no corresponde a la jerarquía de la sección';
		end if;
		if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
			raise exception 'La sección interna debe quedar dentro del rango de su unidad';
		end if;

		return new;
	end;
	$fn$;

	-- ------------------------------------------------------------------ La guarda del conjunto
	--
	-- Comprobaba que **cada** unidad tuviera las secciones raíz de la arquitectura de la
	-- secuencia. Ahora recorre unidad por unidad y le pide las de la suya.
	create or replace function public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid)
	returns void
	language plpgsql
	set search_path to 'public'
	as $fn$
	declare
		v_configuracion_id uuid;
		v_seccion record;
		v_unidad record;
		v_padre record;
		v_total integer;
	begin
		select arquitectura_id into v_configuracion_id
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = p_secuencia_id;

		if v_configuracion_id is null then
			return;
		end if;

		-- Las secciones raíz, cada unidad contra las de su propia arquitectura.
		for v_unidad in
			select realizacion_prueba_id,
				coalesce(arquitectura_id, v_configuracion_id) as arquitectura_id
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and realizacion_padre_id is null
				and seccion_id is null
		loop
			for v_seccion in
				select *
				from public.estructuras_secciones
				where arquitectura_id = v_unidad.arquitectura_id
					and seccion_padre_id is null
			loop
				select count(*) into v_total
				from public.realizaciones_editor_metrico
				where secuencia_prueba_id = p_secuencia_id
					and realizacion_padre_id = v_unidad.realizacion_prueba_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
					raise exception 'Cada unidad admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;

		-- Las secciones internas se buscan por su sección superior, que ya identifica una sola
		-- arquitectura: basta con mirar las de todas las que están en juego en esta secuencia.
		for v_seccion in
			select s.*
			from public.estructuras_secciones s
			where s.seccion_padre_id is not null
				and s.arquitectura_id in (
					select v_configuracion_id
					union
					select arquitectura_id
					from public.realizaciones_editor_metrico
					where secuencia_prueba_id = p_secuencia_id
						and arquitectura_id is not null
				)
		loop
			for v_padre in
				select realizacion_prueba_id
				from public.realizaciones_editor_metrico
				where secuencia_prueba_id = p_secuencia_id
					and seccion_id = v_seccion.seccion_padre_id
			loop
				select count(*) into v_total
				from public.realizaciones_editor_metrico
				where secuencia_prueba_id = p_secuencia_id
					and realizacion_padre_id = v_padre.realizacion_prueba_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad superior necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null
					and v_total > v_seccion.repeticiones_max
				then
					raise exception 'Cada unidad superior admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;
	end;
	$fn$;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta lo que se toca.** Un cuerpo entrecomillado no se revalida al reemplazarlo, así
	-- que las dos guardas se prueban sobre datos de verdad: se escribe la tirada que antes no se
	-- podía escribir —cinco espinelas y una aumentada, 62 versos— y se deshace al final.

	select escenario_id, created_by into v_escenario_id, v_autor
	from public.escenarios_editor_metrico limit 1;
	if v_escenario_id is null then
		raise exception 'No hay ningún escenario de prueba donde comprobarlo.';
	end if;
	-- `created_by` lo pone `auth.uid()`, que en una migración es nulo: se hereda el del escenario.
	if v_autor is null then
		select created_by into v_autor from public.secuencias_editor_metrico
		where created_by is not null limit 1;
	end if;
	if v_autor is null then
		raise exception 'No hay ningún autor con quien firmar la comprobación.';
	end if;

	insert into public.secuencias_editor_metrico
		(escenario_id, orden, v_ini, v_fin, forma_id, arquitectura_id, observaciones,
		 created_by, updated_by)
	values (v_escenario_id, 9999, 100001, 100062, v_forma_id, v_espinela,
		'Comprobación de la migración; se deshace.', v_autor, v_autor)
	returning secuencia_prueba_id into v_secuencia;

	v_cursor := 100001;
	-- `orden` es único dentro de la secuencia, así que lo lleva un contador corrido y no el
	-- índice de cada bucle.
	v_orden := 0;
	for v_indice in 1..6 loop
		insert into public.realizaciones_editor_metrico
			(realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id, orden,
			 v_ini, v_fin, arquitectura_id)
		values (
			gen_random_uuid(), v_secuencia, null, null, v_orden + 1, v_cursor,
			v_cursor + case when v_indice = 6 then 11 else 9 end,
			case when v_indice = 6 then v_aumentada else null end
		)
		returning realizacion_prueba_id into v_unidad;
		v_orden := v_orden + 1;

		-- Y sus partes, las de la arquitectura que le toque a cada una.
		for v_seccion in
			select *
			from public.estructuras_secciones
			where arquitectura_id = case when v_indice = 6 then v_aumentada else v_espinela end
				and seccion_padre_id is null
			order by orden
		loop
			insert into public.realizaciones_editor_metrico
				(realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id,
				 orden, v_ini, v_fin)
			values (gen_random_uuid(), v_secuencia, v_unidad, v_seccion.seccion_id,
				v_orden + 1, v_cursor, v_cursor + v_seccion.versos_min - 1);
			v_orden := v_orden + 1;
			v_cursor := v_cursor + v_seccion.versos_min;
		end loop;
	end loop;

	-- Y las guardas diferidas —la de la arquitectura declarada y la de la extensión del patrón—
	-- se fuerzan aquí en vez de esperar al `commit`: así se ejecutan sobre estas filas y no sobre
	-- ninguna otra, y si algo chirría lo dice esta migración y no el primer editor que guarde.
	set constraints all immediate;

	-- La de la estructura se llama además a mano, que es lo que hace el disparador.
	perform public.validar_estructura_secuencia_editor_metrico(v_secuencia);

	if v_cursor <> 100063 then
		raise exception 'La tirada de prueba mide % versos y debía medir 62.', v_cursor - 100001;
	end if;

	-- Y lo contrario también debe seguir fallando: una sección de la aumentada bajo una espinela.
	begin
		insert into public.realizaciones_editor_metrico
			(realizacion_prueba_id, secuencia_prueba_id, realizacion_padre_id, seccion_id,
			 orden, v_ini, v_fin)
		select gen_random_uuid(), v_secuencia,
			(select realizacion_prueba_id from public.realizaciones_editor_metrico
			 where secuencia_prueba_id = v_secuencia and seccion_id is null and arquitectura_id is null
			 order by v_ini limit 1),
			seccion_id, v_orden + 1, 100001, 100004
		from public.estructuras_secciones
		where arquitectura_id = v_aumentada and seccion_padre_id is null
		order by orden limit 1;
		raise exception 'La guarda ha dejado colgar una sección de la aumentada bajo una espinela.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%no pertenece a la arquitectura seleccionada%' then
			raise exception 'La guarda ha fallado por otra razón: %', v_error;
		end if;
	end;

	delete from public.realizaciones_editor_metrico where secuencia_prueba_id = v_secuencia;
	delete from public.secuencias_editor_metrico where secuencia_prueba_id = v_secuencia;
	-- Y se vacía la cola otra vez, para no dejarle al `commit` eventos de filas que ya no están.
	set constraints all immediate;
end $$;

commit;
