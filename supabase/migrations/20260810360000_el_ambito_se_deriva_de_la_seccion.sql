-- El ámbito se deriva de la sección.
--
-- Con la migración anterior, decir «hablo de una sección» y apuntar a una sección son ya lo mismo
-- en las dos tablas de esquemas. Así que `ambito` no añade nada: **una fila habla de una parte
-- cuando señala una parte, y de la unidad cuando no señala ninguna**. Y `seccion_id` dice además
-- de cuál, que es lo que hacía falta.
--
-- En `repeticiones_metricas` la columna se va por otro motivo: no la leía nadie —ni una función,
-- ni una vista, ni el demarcador, ni la ficha, ni el editor V2— y `tipo` la determinaba, porque un
-- `estribillo` y una `seccion` son secciones por definición y una `palabra_final` es una palabra.
--
-- LO QUE GANA LA FICHA PÚBLICA es dejar de adivinar. Hasta hoy asignaba cada esquema de ámbito
-- sección a «la única sección que aún no tuviera rima» y, si había más de una candidata, se rendía
-- y lo dejaba sin parte. Ahora lo lee.
--
-- SOBRE CÓMO SE REESCRIBEN LAS DOS FUNCIONES. Son 251 y 172 líneas y el cambio es un identificador
-- en tres sitios, así que se toman con `pg_get_functiondef`, se sustituye el nombre y se ejecutan.
-- Transcribir cuatrocientas líneas a mano para cambiar tres palabras arriesga alterar algo sin
-- querer; así el resto queda literalmente idéntico. Cada sustitución se comprueba —si el texto
-- buscado no estaba, la migración no entra— y después **se ejecutan las dos**, que es lo único que
-- de verdad valida un cuerpo entrecomillado.

begin;

do $$
declare
	v_def text;
	v_previo text;
begin
	-- 1 · La ficha pública. `esquemas_rima_objetivo` ya arrastra la columna, porque toma `e.*`.
	select pg_get_functiondef(p.oid) into v_def
	from pg_proc p join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public' and p.proname = 'get_forma_metrica_publica';
	if v_def is null then
		raise exception 'No existe get_forma_metrica_publica';
	end if;
	v_previo := v_def;
	v_def := replace(v_def,
		'select esquema_rima_id, arquitectura_id, nombre, notacion, descripcion, ambito',
		'select esquema_rima_id, arquitectura_id, nombre, notacion, descripcion, seccion_id');
	if v_def = v_previo then
		raise exception 'No se encontró el select de esquemas de rima en get_forma_metrica_publica';
	end if;
	if v_def like '%ambito%' then
		raise exception 'Quedó un ámbito suelto en get_forma_metrica_publica';
	end if;
	execute v_def || ';';

	-- 2 · El demarcador. Dos esquemas pasan a proyectar su sección; la repetición no proyecta
	--     nada en su lugar, porque su tipo ya dice de qué habla.
	select pg_get_functiondef(p.oid) into v_def
	from pg_proc p join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public' and p.proname = 'obtener_catalogo_demarcador';
	if v_def is null then
		raise exception 'No existe obtener_catalogo_demarcador';
	end if;

	v_previo := v_def;
	v_def := replace(v_def,
		'select p.esquema_metrico_id, p.arquitectura_id, p.ambito',
		'select p.esquema_metrico_id, p.arquitectura_id, p.seccion_id');
	if v_def = v_previo then
		raise exception 'No se encontró el select de esquemas métricos del demarcador';
	end if;

	v_previo := v_def;
	v_def := replace(v_def,
		'r.tipo_rima_id, r.tipo_secuencia, r.ambito, r.modalidad',
		'r.tipo_rima_id, r.tipo_secuencia, r.seccion_id, r.modalidad');
	if v_def = v_previo then
		raise exception 'No se encontró el select de esquemas de rima del demarcador';
	end if;

	v_previo := v_def;
	v_def := replace(v_def,
		'r.tipo, r.nombre, r.descripcion, r.modalidad, r.ambito',
		'r.tipo, r.nombre, r.descripcion, r.modalidad');
	if v_def = v_previo then
		raise exception 'No se encontró el select de repeticiones del demarcador';
	end if;

	if v_def like '%ambito%' then
		raise exception 'Quedó un ámbito suelto en obtener_catalogo_demarcador';
	end if;
	execute v_def || ';';
end;
$$;

-- Ya nadie la nombra.

alter table public.esquemas_metricos drop column if exists ambito;
alter table public.esquemas_rima drop column if exists ambito;
alter table public.repeticiones_metricas drop column if exists ambito;

do $$
declare
	v_n integer;
	v_json jsonb;
	v_slug text;
	v_esquemas integer;
begin
	-- No queda columna…
	select count(*) into v_n
	from information_schema.columns
	where table_schema = 'public'
		and column_name = 'ambito'
		and table_name in ('esquemas_metricos', 'esquemas_rima', 'repeticiones_metricas');
	if v_n <> 0 then
		raise exception 'Quedan % columnas `ambito`', v_n;
	end if;

	-- …ni cuerpo que la nombre, que es donde se esconden.
	select count(*) into v_n
	from pg_proc p join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public' and p.prokind = 'f' and pg_get_functiondef(p.oid) like '%ambito%';
	if v_n <> 0 then
		raise exception '% funciones siguen nombrando `ambito`', v_n;
	end if;

	-- La ficha jerárquica de todas las formas, ejecutada, y con la rima intacta: los 87 esquemas
	-- siguen saliendo, ahora diciendo de qué parte son los diecisiete que son de una parte.
	v_esquemas := 0;
	for v_slug in select slug from public.formas_metricas loop
		select public.get_forma_metrica_publica_jerarquica(v_slug) into v_json;
		if v_json is null then
			raise exception 'La ficha jerárquica salió vacía para %', v_slug;
		end if;
		v_esquemas := v_esquemas + coalesce(jsonb_array_length(v_json -> 'esquemasRima'), 0);
	end loop;
	if v_esquemas < 87 then
		raise exception 'Las fichas proyectan % esquemas de rima, menos que los 87 del catálogo', v_esquemas;
	end if;

	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ?& array['metricPatterns', 'rhymePatterns', 'repetitions']) then
		raise exception 'El catálogo del demarcador salió sin sus claves';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
