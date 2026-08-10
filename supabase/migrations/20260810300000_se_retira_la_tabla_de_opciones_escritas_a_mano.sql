-- Se retira la tabla de las opciones escritas a mano.
--
-- `opciones_eleccion_metrica_manual` guardaba las 405 respuestas del editor tal como se
-- escribieron hasta el 9 de agosto de 2026, cuando pasaron a derivarse del catálogo. Se conservó
-- apartada para poder comparar, con el compromiso de retirarla «cuando la derivación se haya
-- usado con datos reales».
--
-- Ya se usó: el guardado se ejercitó contra la vista el 9, con una inserción real que comprobó
-- que la respuesta admitida entra, que la que la pregunta no ofrece se rechaza y que el
-- identificador derivado resuelve a su dato. Y desde entonces la derivación ha sostenido cuatro
-- migraciones más sin que las 405 opciones ni las 91 respuestas propuestas se movieran.
--
-- Se va con ella `comparar_opciones_eleccion_metrica()`, que existía solo para contrastar las dos,
-- y **dos disparadores que llevaban un día validando una tabla que nadie escribe**:
-- `validar_opcion_eleccion_metrica` y `validar_posicion_opcion_eleccion_metrica`. Se cuelgan de
-- la tabla, así que caen con ella; sus funciones se retiran aparte porque no las usa nadie más.
--
-- Lo que hubo está en el historial: la tabla se creó y se pobló migración a migración, y el
-- commit que la apartó explica por qué. Guardar una copia inerte «por si acaso» es justo lo que
-- convierte un catálogo en dos.

begin;

drop function if exists public.comparar_opciones_eleccion_metrica();

drop table public.opciones_eleccion_metrica_manual;

drop function if exists public.validar_opcion_eleccion_metrica();
drop function if exists public.validar_posicion_opcion_eleccion_metrica();

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from information_schema.tables
	where table_schema = 'public' and table_name = 'opciones_eleccion_metrica_manual';
	if v_n <> 0 then
		raise exception 'La tabla apartada sigue ahí';
	end if;

	-- Y lo que de verdad importa: la vista que la sustituyó sigue dando lo mismo.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then
		raise exception 'Las opciones derivadas dejaron de ser 405 y son %', v_n;
	end if;

	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'Las respuestas propuestas dejaron de ser 91 y son %', v_n;
	end if;

	select count(*) into v_n from public.elecciones_editor_metrico_resueltas
	where opcion_eleccion_id is null;
	if v_n <> 0 then
		raise exception '% respuestas guardadas dejaron de resolverse a una opción', v_n;
	end if;

	-- Ninguna función puede seguir nombrándola.
	select count(*) into v_n
	from pg_proc p join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public' and p.prokind = 'f'
		and pg_get_functiondef(p.oid) ilike '%opciones_eleccion_metrica_manual%';
	if v_n <> 0 then
		raise exception '% funciones siguen citando la tabla retirada', v_n;
	end if;
end;
$$;

commit;
