-- El catálogo de formas se lee sin sesión, y se cierra al apagar la sección
--
-- `/formas` estaba abierto en `/dashboard/publicacion` con `scope_minimo = 'anon'` desde el 14 de
-- agosto de 2026 y aun así respondía «0 formas» en el listado y 404 en cada ficha. No era el flag:
-- las 23 tablas del catálogo métrico tenían RLS activa y **una sola política** cada una,
-- `<tabla>_admin_ip TO authenticated USING (auth_is_admin_or_ip())`. El anónimo no tenía política
-- y leía cero filas; el editor con sesión tampoco, porque `auth_is_admin_or_ip()` es falso para su
-- rol. Es decir: el catálogo público era de admin e IP, y de nadie más, dijera lo que dijera el
-- interruptor.
--
-- Lo que no hacía falta tocar, comprobado antes de escribir esto: los `GRANT` de `SELECT` para
-- `anon` y `authenticated` ya existían en las 23 tablas; las dos RPC son `SECURITY INVOKER` y
-- ejecutables por `anon`, que es el diseño correcto —manda la RLS, no la función—; y la vista
-- `opciones_eleccion_metrica` es `security_invoker=on` sobre `opciones_eleccion_derivadas()`, que
-- solo lee tablas de esas 23, así que se arregla sola y no necesita política propia.
--
-- **La regla vive en el predicado, no en la aplicación.** Es el patrón de `obras_publicas_select`,
-- que exige `visible_publico` y estado publicado en la propia política. Aquí la condición es que
-- la sección `formas` esté activa y abierta a `anon`, de modo que apagarla en
-- `/dashboard/publicacion` **cierra también la consulta**: no basta con dejar de pintar la página,
-- porque con la clave anónima se puede llamar a PostgREST sin pasar por `/acceso`. Abrir ahora no
-- es, por tanto, una puerta de un solo sentido.
--
-- Lo que **no** entra en el predicado es `activo`. Hoy no cambiaría nada —hay 0 filas inactivas en
-- las ocho tablas que tienen esa columna— y sería una trampa futura: desactivar un metro dejaría
-- en blanco una columna de la rejilla en vez de retirar una forma. El filtrado por `activo` ya lo
-- hacen las RPC, que es su sitio.
--
-- La política `admin_ip` se queda en las 23: las políticas se suman con OR, así que admin e IP
-- conservan su acceso completo aunque la sección esté cerrada.

-- La condición de apertura, en un solo sitio. `security definer` para que no dependa de que el
-- lector pueda leer `secciones_publicas`, y `stable` para que se evalúe una vez por sentencia y no
-- una vez por fila.
create or replace function public.catalogo_metrico_publico()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select exists (
		select 1
		from public.secciones_publicas
		where seccion_id = 'formas'
			and activa
			and scope_minimo = 'anon'
	);
$$;

comment on function public.catalogo_metrico_publico() is
	'Si el catálogo de formas está abierto al visitante anónimo. Gobierna la RLS de las 23 tablas del catálogo métrico, de modo que apagar la sección «formas» en /dashboard/publicacion cierra el dato y no solo la página.';

grant execute on function public.catalogo_metrico_publico() to anon, authenticated;

do $$
declare
	-- Las 23 tablas que leen `get_catalogo_formas_publicas` y
	-- `get_forma_metrica_publica_jerarquica`, esta última a través de `get_forma_metrica_publica`.
	tablas text[] := array[
		'afirmaciones_fuentes_metricas',
		'arquitectura_rasgos',
		'arquitecturas_forma',
		'denominaciones_metricas',
		'esquema_metrico_opciones',
		'esquema_metrico_posiciones',
		'esquema_rima_enlaces',
		'esquema_rima_posiciones',
		'esquema_rima_restricciones',
		'esquemas_metricos',
		'esquemas_rima',
		'estructuras_secciones',
		'forma_relaciones',
		'formas_metricas',
		'formas_tradiciones',
		'fuentes_metricas',
		'grupos_eleccion_metrica',
		'metros',
		'rasgo_valores',
		'rasgos_metricos',
		'repeticiones_metricas',
		'tradiciones_metricas',
		'variedades_arquitectura'
	];
	t text;
	n integer;
begin
	foreach t in array tablas loop
		if to_regclass('public.' || t) is null then
			raise exception 'La tabla «%» no existe: la lista del catálogo se ha quedado vieja.', t;
		end if;

		-- `create policy` no admite `if not exists`, así que se rehace para poder repetir la
		-- migración sin que falle.
		execute format('drop policy if exists %I on public.%I', t || '_publico', t);
		execute format(
			'create policy %I on public.%I for select to anon, authenticated using (public.catalogo_metrico_publico())',
			t || '_publico', t
		);
	end loop;

	select count(*) into n
	from pg_policy pol
	join pg_class c on c.oid = pol.polrelid
	join pg_namespace ns on ns.oid = c.relnamespace
	where ns.nspname = 'public' and c.relname = any (tablas) and pol.polname like '%\_publico';
	if n <> array_length(tablas, 1) then
		raise exception 'Se esperaban % políticas públicas y se crearon %.', array_length(tablas, 1), n;
	end if;

	-- La política de admin/IP tiene que seguir en pie en las 23: si se hubiera perdido, admin e IP
	-- dejarían de ver el catálogo cerrado.
	select count(*) into n
	from pg_policy pol
	join pg_class c on c.oid = pol.polrelid
	join pg_namespace ns on ns.oid = c.relnamespace
	where ns.nspname = 'public' and c.relname = any (tablas) and pol.polname like '%\_admin\_ip';
	if n <> array_length(tablas, 1) then
		raise exception 'Faltan políticas admin_ip: se esperaban % y hay %.', array_length(tablas, 1), n;
	end if;
end;
$$;

-- La comprobación que de verdad importa: **leer el catálogo como lo lee un visitante**. Una
-- política que no cubra alguna de las 23 no rompe nada visible desde `postgres`, y devolvería una
-- ficha a medias en la web. Cada cifra de aquí abajo obliga a una tabla distinta a estar abierta.
-- Se vuelve al rol de partida **nombrándolo**, no con `reset role`: la CLI de Supabase aplica la
-- migración con un rol elevado sobre una conexión cuyo rol de acceso es otro, así que `reset role`
-- deja la sesión en el de acceso y la propia CLI ya no puede escribir su registro en
-- `supabase_migrations`. Costó un intento fallido —que revirtió entero, sin dejar nada a medias—.
do $$
declare
	rol_previo text := current_user;
	listado integer;
	seg jsonb;
	n integer;
begin
	execute 'set local role anon';

	listado := jsonb_array_length(public.get_catalogo_formas_publicas() -> 'formas');
	if listado <> 29 then
		raise exception 'El anónimo ve % formas en el listado y debería ver 29.', listado;
	end if;

	seg := public.get_forma_metrica_publica_jerarquica('seguidilla');

	-- Cada cifra obliga a una tabla distinta: arquitecturas_forma · esquemas_rima ·
	-- esquemas_metricos · esquema_metrico_posiciones · esquema_rima_posiciones ·
	-- esquema_rima_enlaces · estructuras_secciones · denominaciones_metricas ·
	-- afirmaciones_fuentes_metricas con fuentes_metricas · forma_relaciones ·
	-- opciones_eleccion_metrica (la vista, y con ella metros y grupos_eleccion_metrica) ·
	-- formas_tradiciones con tradiciones_metricas.
	if jsonb_array_length(seg -> 'arquitecturas') <> 7
		or jsonb_array_length(seg -> 'esquemasRima') <> 7
		or jsonb_array_length(seg -> 'esquemasMetricos') <> 7
		or jsonb_array_length(seg -> 'posicionesMetricas') <> 40
		or jsonb_array_length(seg -> 'posicionesRimaCompletas') <> 36
		or jsonb_array_length(seg -> 'enlacesRima') <> 2
		or jsonb_array_length(seg -> 'secciones') <> 4
		or jsonb_array_length(seg -> 'denominaciones') <> 6
		or jsonb_array_length(seg -> 'afirmaciones') <> 16
		or jsonb_array_length(seg -> 'relaciones') <> 1
		or jsonb_array_length(seg -> 'opcionesEleccion') <> 3
		or jsonb_array_length(seg -> 'formasTradiciones') <> 1
		or jsonb_array_length(seg -> 'tradiciones') <> 1
	then
		raise exception 'La ficha de la seguidilla llega incompleta al anónimo: %',
			jsonb_build_object(
				'arquitecturas', jsonb_array_length(seg -> 'arquitecturas'),
				'esquemasRima', jsonb_array_length(seg -> 'esquemasRima'),
				'esquemasMetricos', jsonb_array_length(seg -> 'esquemasMetricos'),
				'posicionesMetricas', jsonb_array_length(seg -> 'posicionesMetricas'),
				'posicionesRimaCompletas', jsonb_array_length(seg -> 'posicionesRimaCompletas'),
				'enlacesRima', jsonb_array_length(seg -> 'enlacesRima'),
				'secciones', jsonb_array_length(seg -> 'secciones'),
				'denominaciones', jsonb_array_length(seg -> 'denominaciones'),
				'afirmaciones', jsonb_array_length(seg -> 'afirmaciones'),
				'relaciones', jsonb_array_length(seg -> 'relaciones'),
				'opcionesEleccion', jsonb_array_length(seg -> 'opcionesEleccion'),
				'formasTradiciones', jsonb_array_length(seg -> 'formasTradiciones'),
				'tradiciones', jsonb_array_length(seg -> 'tradiciones')
			);
	end if;

	-- Las cuatro tablas que la seguidilla no ejercita, cada una en la forma que sí la usa.
	n := jsonb_array_length(public.get_forma_metrica_publica_jerarquica('soneto') -> 'arquitecturaRasgos');
	if n <> 1 then raise exception 'arquitectura_rasgos cerrada al anónimo (soneto: %).', n; end if;

	n := jsonb_array_length(public.get_forma_metrica_publica_jerarquica('sexteto_lira') -> 'variedades');
	if n <> 7 then raise exception 'variedades_arquitectura cerrada al anónimo (sexteto_lira: %).', n; end if;

	n := jsonb_array_length(public.get_forma_metrica_publica_jerarquica('villancico') -> 'repeticiones');
	if n <> 4 then raise exception 'repeticiones_metricas cerrada al anónimo (villancico: %).', n; end if;

	n := jsonb_array_length(public.get_forma_metrica_publica_jerarquica('silva') -> 'restriccionesRima');
	if n <> 3 then raise exception 'esquema_rima_restricciones cerrada al anónimo (silva: %).', n; end if;

	n := jsonb_array_length(public.get_forma_metrica_publica_jerarquica('copla_de_pie_quebrado') -> 'opcionesMetricas');
	if n <> 3 then raise exception 'esquema_metrico_opciones cerrada al anónimo (copla de pie quebrado: %).', n; end if;

	execute format('set local role %I', rol_previo);
exception
	when others then
		-- Que una comprobación falle no debe dejar la sesión hablando como el visitante: se
		-- recupera el rol y se vuelve a lanzar el error tal cual.
		execute format('set local role %I', rol_previo);
		raise;
end;
$$;
