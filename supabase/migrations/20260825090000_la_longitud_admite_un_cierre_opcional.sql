-- La longitud admite un cierre opcional
--
-- B4, primera mitad. El 19 de agosto de 2026 (`20260819180000`) el serventesio del terceto
-- encadenado pasó a `repeticiones_min = 0`, porque la cadena puede terminar sin él. El dato quedó
-- bien y **la regla de longitud se dio la vuelta en silencio**.
--
-- `regla_longitud_arquitectura_metrica` clasifica cada sección raíz en «derivable» o no, y contaba
-- como no derivable toda sección con `repeticiones_min <> repeticiones_max`. Con el cambio, el
-- serventesio entró en ese saco, la rama de secciones se descartó **entera** y la función cayó
-- hasta la de `ciclo_rima`, que solo ve el terceto. Resultado:
--
--   antes del 19 de agosto   módulo 3, residuo 1, mínimo 7   →  solo 3n+4
--   desde el 19 de agosto    módulo 3, residuo 0, mínimo 3   →  solo 3n
--
-- **Ninguna de las dos es correcta.** Si el cierre es opcional las longitudes admitidas son `3n`
-- *y* `3n+4`, y un solo par de módulo y residuo no puede expresar las dos. Nadie lo notó porque la
-- función siguió devolviendo una regla plausible: es exactamente el fallo que la regla dura del
-- proyecto anticipa —una función SQL no está probada hasta que se ejecuta—, y por eso las guardas
-- de esta migración **llaman a la función** en vez de mirar el dato.
--
-- Lo que se rompía con eso, hoy, en producción del editor de prueba: el endpoint devuelve 422 ante
-- cualquier cadena que termine en serventesio. La secuencia 1 del escenario Prueba1 —vv. 13-79,
-- **67 versos** = 21 tercetos + serventesio— no se podría guardar.
--
-- **La forma de arreglarlo.** La función gana una columna `desplazamientos integer[]`: los totales
-- que las secciones **opcionales de extensión fija** pueden añadir al bloque periódico. Para el
-- terceto encadenado es `{0,4}` —sin cierre, o con él—. Para las otras ochenta y nueve
-- arquitecturas es `{0}` y no cambia nada, que es lo que comprueba la guarda.
--
-- Se calculan como **sumas de subconjuntos**, no como un caso especial de una sola sección. Hoy
-- solo el terceto encadenado tiene esta forma, pero dejar el caso general escrito evita que la
-- próxima arquitectura con dos partes opcionales vuelva a caer por el desagüe sin avisar.
--
-- *Nota sobre el orden de las operaciones.* La función no admite `create or replace` porque cambia
-- su tipo de retorno, y de ella cuelga una cadena de vistas: `arquitecturas_reglas_longitud`, sobre
-- ella `propuesta_metrica_secuencia`, y sobre esa `propuesta_elecciones_secuencia`. Hay que tirarlas
-- todas y rehacerlas, y no del mismo modo.
--
-- La de reglas **se reescribe**, porque su definición actual nombra el alias del LATERAL con cinco
-- columnas y la función pasa a devolver seis: restaurarla verbatim fallaría. Las que cuelgan de ella
-- no cambian en nada, así que **se capturan y se restauran verbatim** con `pg_get_viewdef`, con sus
-- opciones y sus permisos: son cientos de líneas y transcribirlas sería meter una fuente de error
-- donde no hay nada que cambiar.
--
-- Y la cadena **se recorre, no se enumera**. El primer intento de esta migración nombraba las dos
-- vistas que había mirado y falló contra la tercera, que no había mirado. Recorrerla deja de ser un
-- problema la próxima vez que alguien apile una vista más.

begin;

do $$
declare
	v_dependientes jsonb := '[]'::jsonb;
	v_vista jsonb;
	v_i integer;
	v_arq_endeca uuid;
	v_arq_octo uuid;
	v_regla record;
	v_n integer;
	v_antes jsonb;
	v_despues jsonb;
	v_caso integer[];
	v_admite boolean;
begin
	select arquitectura_id into v_arq_endeca
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante' and a.activo;
	select arquitectura_id into v_arq_octo
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante' and a.activo;
	if v_arq_endeca is null or v_arq_octo is null then
		raise exception 'El terceto encadenado no tiene sus dos arquitecturas activas.';
	end if;

	-- El dato de partida es el que describe la cabecera: cierre opcional, cuatro versos fijos.
	select count(*) into v_n
	from public.estructuras_secciones s
	where s.arquitectura_id in (v_arq_endeca, v_arq_octo)
		and s.slug = 'serventesio'
		and s.versos_min = 4 and s.versos_max = 4
		and s.repeticiones_min = 0 and s.repeticiones_max = 1;
	if v_n <> 2 then
		raise exception 'El serventesio no es un cierre opcional de cuatro versos en las dos arquitecturas (% de 2).', v_n;
	end if;

	-- Y hoy la función dice lo que no debe. Si alguien lo arregló antes, esta migración sobra y
	-- conviene saberlo en vez de pisarlo.
	select * into v_regla from public.regla_longitud_arquitectura_metrica(v_arq_endeca);
	if v_regla.origen is distinct from 'ciclo_rima'
		or v_regla.modulo_versos is distinct from 3
		or v_regla.residuo_versos is distinct from 0
	then
		raise exception 'La regla de longitud del terceto encadenado ya no es la esperada: % / módulo % / residuo %.',
			v_regla.origen, v_regla.modulo_versos, v_regla.residuo_versos;
	end if;

	-- Retrato de todas las reglas vivas, para comprobar después que solo cambian las dos.
	select jsonb_object_agg(r.arquitectura_id::text, to_jsonb(r) - 'arquitectura_id' - 'arquitectura_nombre')
	into v_antes
	from public.arquitecturas_reglas_longitud r;

	-- ------------------------------------------- Las vistas que cuelgan, tal como están
	-- Se recorre la cadena entera desde la vista de reglas, en orden de dependencia, y de cada una
	-- se guarda su definición, si es `security_invoker` y quién puede leerla. La de reglas **no**
	-- entra aquí: no puede restaurarse desde su definición actual, porque esa nombra el alias del
	-- LATERAL con cinco columnas y la función pasa a devolver seis. Se reescribe.
	with recursive cadena as (
		select 'arquitecturas_reglas_longitud'::name as vista, 0 as nivel
		union all
		select dependiente.relname, cadena.nivel + 1
		from cadena
		join pg_class origen
			on origen.relname = cadena.vista and origen.relnamespace = 'public'::regnamespace
		join pg_depend d on d.refobjid = origen.oid
		join pg_rewrite r on d.objid = r.oid
		join pg_class dependiente
			on dependiente.oid = r.ev_class
			and dependiente.relkind = 'v'
			and dependiente.relnamespace = 'public'::regnamespace
		where dependiente.relname <> cadena.vista and cadena.nivel < 20
	), niveles as (
		select vista, max(nivel) as nivel from cadena where nivel > 0 group by vista
	)
	select coalesce(jsonb_agg(
		jsonb_build_object(
			'nombre', niveles.vista,
			'nivel', niveles.nivel,
			'definicion', pg_get_viewdef(('public.' || quote_ident(niveles.vista))::regclass, true),
			'security_invoker', coalesce((
				select bool_or(option_value = 'true')
				from pg_options_to_table(c.reloptions)
				where option_name = 'security_invoker'
			), false),
			'permisos', coalesce((
				select jsonb_agg(distinct g.grantee)
				from information_schema.role_table_grants g
				where g.table_schema = 'public' and g.table_name = niveles.vista
					and g.privilege_type = 'SELECT'
			), '[]'::jsonb)
		) order by niveles.nivel
	), '[]'::jsonb)
	into v_dependientes
	from niveles
	join pg_class c
		on c.relname = niveles.vista and c.relnamespace = 'public'::regnamespace;

	if jsonb_array_length(v_dependientes) = 0 then
		raise exception 'No cuelga ninguna vista de las reglas de longitud; algo ha cambiado.';
	end if;

	-- Se tiran de la más dependiente a la menos, y la función al final.
	for v_i in reverse jsonb_array_length(v_dependientes) - 1 .. 0 loop
		execute format('drop view public.%I', v_dependientes -> v_i ->> 'nombre');
	end loop;
	drop view public.arquitecturas_reglas_longitud;
	drop function public.regla_longitud_arquitectura_metrica(uuid);

	-- ------------------------------------------------------------------- La función nueva
	create function public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
	returns table (
		modulo_versos integer,
		residuo_versos integer,
		minimo_versos integer,
		origen text,
		explicacion text,
		desplazamientos integer[]
	)
	language plpgsql
	stable
	set search_path to 'public'
	as $funcion$
	declare
		v_unidad_min integer;
		v_unidad_max integer;
		v_total_secciones integer;
		v_secciones_no_derivables integer;
		v_secciones_abiertas integer;
		v_longitud_abierta integer;
		v_longitud_minima integer;
		v_longitud_fija integer;
		v_total_patrones integer;
		v_patrones_con_posiciones integer;
		v_longitudes_distintas integer;
		v_longitud_ciclo integer;
		v_opcionales integer[];
		v_desplazamientos integer[];
		v_opcional integer;
		v_cola text;
	begin
		select arquitectura.unidad_versos_min, arquitectura.unidad_versos_max
		into v_unidad_min, v_unidad_max
		from public.arquitecturas_forma arquitectura
		where arquitectura.arquitectura_id = p_arquitectura_id
			and arquitectura.activo;

		if not found then
			return;
		end if;

		if v_unidad_min is not null then
			if v_unidad_min = v_unidad_max and v_unidad_min > 1 then
				return query
				select
					v_unidad_min,
					0,
					v_unidad_min,
					'unidad'::text,
					format('unidades completas de %s versos', v_unidad_min),
					array[0];
			elsif v_unidad_max > v_unidad_min then
				-- Una unidad de extensión variable no produce congruencia: solo su mínimo.
				return query
				select
					1,
					0,
					v_unidad_min,
					'unidad'::text,
					format('unidades de %s a %s versos', v_unidad_min, v_unidad_max),
					array[0];
			end if;
			return;
		end if;

		-- Las secciones opcionales de extensión fija —cero o una vez, siempre los mismos versos—
		-- no impiden derivar la longitud: **la desplazan**. Se recogen aparte para sumarlas
		-- después, y dejan de contar como secciones no derivables, que es lo que en agosto de 2026
		-- tiró la rama entera al descartarlas.
		select coalesce(array_agg(seccion.versos_min order by seccion.orden), array[]::integer[])
		into v_opcionales
		from public.estructuras_secciones seccion
		where seccion.arquitectura_id = p_arquitectura_id
			and seccion.seccion_padre_id is null
			and seccion.versos_min is not null
			and seccion.versos_min = seccion.versos_max
			and coalesce(seccion.repeticiones_min, 0) = 0
			and seccion.repeticiones_max = 1;

		select
			count(*)::integer,
			count(*) filter (
				where seccion.versos_min is null
					or seccion.versos_max is null
					or seccion.versos_min <> seccion.versos_max
					or (
						seccion.repeticiones_max is not null
						and coalesce(seccion.repeticiones_min, 0) <> seccion.repeticiones_max
						and not (
							coalesce(seccion.repeticiones_min, 0) = 0
							and seccion.repeticiones_max = 1
						)
					)
			)::integer,
			count(*) filter (where seccion.repeticiones_max is null)::integer,
			max(seccion.versos_min) filter (where seccion.repeticiones_max is null)::integer,
			coalesce(
				sum(seccion.versos_min * coalesce(seccion.repeticiones_min, 0)),
				0
			)::integer,
			coalesce(
				sum(
					seccion.versos_min * coalesce(seccion.repeticiones_min, 0)
				) filter (where seccion.repeticiones_max is not null),
				0
			)::integer
		into
			v_total_secciones,
			v_secciones_no_derivables,
			v_secciones_abiertas,
			v_longitud_abierta,
			v_longitud_minima,
			v_longitud_fija
		from public.estructuras_secciones seccion
		where seccion.arquitectura_id = p_arquitectura_id
			and seccion.seccion_padre_id is null;

		-- Todos los totales que las partes opcionales pueden añadir, como sumas de subconjuntos.
		-- Con una sola parte son dos: sin ella y con ella.
		v_desplazamientos := array[0];
		foreach v_opcional in array v_opcionales loop
			select array_agg(distinct suma order by suma)
			into v_desplazamientos
			from (
				select unnest(v_desplazamientos) as suma
				union all
				select unnest(v_desplazamientos) + v_opcional
			) sumas;
		end loop;

		if cardinality(v_desplazamientos) = 1 then
			v_cola := '';
		elsif cardinality(v_desplazamientos) = 2 then
			v_cola := format(', con un cierre opcional de %s versos', v_desplazamientos[2]);
		else
			v_cola := format(
				', con cierres opcionales que suman %s versos',
				array_to_string(v_desplazamientos[2:], ', ')
			);
		end if;

		if v_total_secciones > 0 and v_secciones_no_derivables = 0 then
			if v_secciones_abiertas = 0 and v_longitud_minima > 1 then
				return query
				select
					v_longitud_minima,
					0,
					v_longitud_minima,
					'secciones_fijas'::text,
					format('estructuras completas de %s versos', v_longitud_minima) || v_cola,
					v_desplazamientos;
				return;
			elsif v_secciones_abiertas = 1 and v_longitud_abierta > 1 then
				return query
				select
					v_longitud_abierta,
					mod(v_longitud_fija, v_longitud_abierta),
					v_longitud_minima,
					'secciones_repetibles'::text,
					case
						when v_longitud_fija = 0 then
							format('bloques completos de %s versos', v_longitud_abierta)
						else
							format(
								'bloques completos de %s versos más %s %s fijo%s',
								v_longitud_abierta,
								v_longitud_fija,
								case when v_longitud_fija = 1 then 'verso' else 'versos' end,
								case when v_longitud_fija = 1 then '' else 's' end
							)
					end || v_cola,
					v_desplazamientos;
				return;
			end if;
		end if;

		select
			count(*)::integer,
			count(*) filter (where patron.longitud > 0)::integer,
			count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
			min(patron.longitud) filter (where patron.longitud > 0)::integer
		into
			v_total_patrones,
			v_patrones_con_posiciones,
			v_longitudes_distintas,
			v_longitud_ciclo
		from (
			select
				rima.esquema_rima_id,
				count(posicion.posicion_id)::integer as longitud
			from public.esquemas_rima rima
			left join public.esquema_rima_posiciones posicion
				on posicion.esquema_rima_id = rima.esquema_rima_id
			where rima.arquitectura_id = p_arquitectura_id
				and rima.tipo_secuencia = 'ciclo'
			group by rima.esquema_rima_id
		) patron;

		if v_total_patrones > 0
			and v_total_patrones = v_patrones_con_posiciones
			and v_longitudes_distintas = 1
			and v_longitud_ciclo > 1
		then
			return query
			select
				v_longitud_ciclo,
				0,
				v_longitud_ciclo,
				'ciclo_rima'::text,
				format('ciclos completos de rima de %s versos', v_longitud_ciclo) || v_cola,
				v_desplazamientos;
			return;
		end if;

		select
			count(*)::integer,
			count(*) filter (where patron.longitud > 0)::integer,
			count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
			min(patron.longitud) filter (where patron.longitud > 0)::integer
		into
			v_total_patrones,
			v_patrones_con_posiciones,
			v_longitudes_distintas,
			v_longitud_ciclo
		from (
			select
				metrico.esquema_metrico_id,
				count(posicion.posicion_id)::integer as longitud
			from public.esquemas_metricos metrico
			left join public.esquema_metrico_posiciones posicion
				on posicion.esquema_metrico_id = metrico.esquema_metrico_id
			where metrico.arquitectura_id = p_arquitectura_id
				and metrico.tipo_secuencia = 'ciclo'
			group by metrico.esquema_metrico_id
		) patron;

		if v_total_patrones > 0
			and v_total_patrones = v_patrones_con_posiciones
			and v_longitudes_distintas = 1
			and v_longitud_ciclo > 1
		then
			return query
			select
				v_longitud_ciclo,
				0,
				v_longitud_ciclo,
				'ciclo_metrico'::text,
				format('ciclos métricos completos de %s versos', v_longitud_ciclo) || v_cola,
				v_desplazamientos;
		end if;
	end;
	$funcion$;

	-- ------------------------------------------------------------- Las vistas, de vuelta
	-- La de reglas, escrita: gana `desplazamientos` **al final**, que es donde no mueve de sitio
	-- ninguna columna que alguien lea por posición.
	create view public.arquitecturas_reglas_longitud
	with (security_invoker = true) as
	select
		arquitectura.arquitectura_id,
		arquitectura.nombre as arquitectura_nombre,
		regla.modulo_versos,
		regla.residuo_versos,
		regla.minimo_versos,
		regla.origen,
		regla.explicacion,
		regla.desplazamientos
	from public.arquitecturas_forma arquitectura
	cross join lateral public.regla_longitud_arquitectura_metrica(arquitectura.arquitectura_id)
		regla(modulo_versos, residuo_versos, minimo_versos, origen, explicacion, desplazamientos)
	where arquitectura.activo;

	grant all on public.arquitecturas_reglas_longitud to anon, authenticated, service_role;

	-- Y las que colgaban, verbatim y en orden, cada una con lo que tenía.
	for v_i in 0 .. jsonb_array_length(v_dependientes) - 1 loop
		v_vista := v_dependientes -> v_i;
		execute format(
			'create view public.%I as %s',
			v_vista ->> 'nombre',
			v_vista ->> 'definicion'
		);
		if (v_vista ->> 'security_invoker')::boolean then
			execute format('alter view public.%I set (security_invoker = true)', v_vista ->> 'nombre');
		end if;
		execute format(
			'grant all on public.%I to %s',
			v_vista ->> 'nombre',
			(select string_agg(quote_ident(rol), ', ')
			 from jsonb_array_elements_text(v_vista -> 'permisos') as rol)
		);
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Ejecutando, no leyendo el catálogo: el cuerpo entrecomillado de arriba no lo revalida nadie.
	for v_regla in
		select * from public.arquitecturas_reglas_longitud r
		where r.arquitectura_id in (v_arq_endeca, v_arq_octo)
	loop
		if v_regla.modulo_versos <> 3
			or v_regla.residuo_versos <> 0
			or v_regla.minimo_versos <> 3
			or v_regla.desplazamientos is distinct from array[0, 4]
		then
			raise exception 'El terceto encadenado sigue mal: módulo %, residuo %, mínimo %, desplazamientos %.',
				v_regla.modulo_versos, v_regla.residuo_versos, v_regla.minimo_versos, v_regla.desplazamientos;
		end if;
		if v_regla.explicacion not like '%cierre opcional de 4 versos%' then
			raise exception 'La explicación no dice que el cierre es opcional: «%».', v_regla.explicacion;
		end if;
	end loop;

	-- Y ninguna otra arquitectura se mueve. `desplazamientos` es columna nueva, así que se compara
	-- lo que ya existía.
	select jsonb_object_agg(
		r.arquitectura_id::text,
		to_jsonb(r) - 'arquitectura_id' - 'arquitectura_nombre' - 'desplazamientos'
	)
	into v_despues
	from public.arquitecturas_reglas_longitud r
	where r.arquitectura_id not in (v_arq_endeca, v_arq_octo);

	if v_despues is distinct from (v_antes - v_arq_endeca::text - v_arq_octo::text) then
		raise exception 'Alguna regla de longitud ajena al terceto encadenado ha cambiado.';
	end if;

	select count(*) into v_n
	from public.arquitecturas_reglas_longitud r
	where r.desplazamientos is distinct from array[0]
		and r.arquitectura_id not in (v_arq_endeca, v_arq_octo);
	if v_n <> 0 then
		raise exception '% arquitecturas ajenas declaran desplazamientos, y ninguna debería.', v_n;
	end if;

	-- Las longitudes de verdad, resueltas con la misma lógica que aplicará el editor: una
	-- longitud vale si algún desplazamiento la deja en el ciclo y por encima del mínimo.
	select * into v_regla from public.arquitecturas_reglas_longitud r
	where r.arquitectura_id = v_arq_endeca;
	foreach v_caso slice 1 in array array[
		array[66, 1],   -- 22 tercetos, sin cierre
		array[67, 1],   -- 21 tercetos y serventesio: lo que el editor rechazaba
		array[7, 1],    -- un terceto y su cierre, el mínimo con serventesio
		array[3, 1],    -- un terceto suelto
		array[4, 0],    -- un serventesio sin cadena delante: no es la forma
		array[68, 0],   -- ni 3n ni 3n+4
		array[2, 0]     -- por debajo del mínimo
	] loop
		v_admite := exists (
			select 1 from unnest(v_regla.desplazamientos) as d
			where v_caso[1] - d >= v_regla.minimo_versos
				and mod(v_caso[1] - d - v_regla.residuo_versos, v_regla.modulo_versos) = 0
		);
		if v_admite <> (v_caso[2] = 1) then
			raise exception 'La regla resuelve mal % versos: da %, esperaba %.',
				v_caso[1], v_admite, v_caso[2] = 1;
		end if;
	end loop;

	-- Y las que colgaban siguen respondiendo. Consultarlas es la única prueba de que volvieron
	-- enteras: existir, existirían igual con el cuerpo roto.
	for v_i in 0 .. jsonb_array_length(v_dependientes) - 1 loop
		execute format('select 1 from public.%I limit 1', v_dependientes -> v_i ->> 'nombre');
	end loop;

	select count(*) into v_n
	from pg_class
	where relnamespace = 'public'::regnamespace
		and relkind = 'v'
		and relname in (
			select jsonb_array_elements_text(jsonb_path_query_array(v_dependientes, '$[*].nombre'))
		);
	if v_n <> jsonb_array_length(v_dependientes) then
		raise exception 'Han vuelto % vistas de las % que colgaban.', v_n, jsonb_array_length(v_dependientes);
	end if;
end $$;

commit;
