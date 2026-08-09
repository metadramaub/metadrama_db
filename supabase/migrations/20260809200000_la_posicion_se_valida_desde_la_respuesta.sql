-- La validación de la posición lee la respuesta, no la opción.
--
-- `validar_posicion_eleccion_editor_metrico` es el segundo disparador de
-- `elecciones_editor_metrico` y se quedó atrás al soltar la respuesta de la opción: seguía
-- leyendo `new.opcion_eleccion_id`, una columna que ya no existe. Cualquier intento de guardar
-- habría fallado.
--
-- No lo detectaron ni `db push` ni las pruebas, porque una función de PL/pgSQL no se compila
-- hasta que se ejecuta y ninguna prueba escribe en esa tabla. Lo destapó una inserción de
-- prueba contra la base.
--
-- Es el disparador que impide responder sobre un verso que no existe —«el verso 11 es
-- tetrasílabo» en una copla de cinco— y que se repita la respuesta para una misma posición. Es
-- la única comprobación que el catálogo no puede hacer por sí solo, porque la unidad de la copla
-- de pie quebrado es un rango y solo al guardar se sabe cuántos versos tiene esa realización
-- concreta.
--
-- Ahora la posición sale de la propia respuesta, así que la comprobación es más directa y deja
-- de depender de que exista una opción.

begin;

create or replace function public.validar_posicion_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_versos integer;
	v_repetida integer;
begin
	if new.posicion_unidad is null or new.realizacion_prueba_id is null then
		return new;
	end if;

	select v_fin - v_ini + 1 into v_versos
	from public.realizaciones_editor_metrico
	where realizacion_prueba_id = new.realizacion_prueba_id;

	if v_versos is not null and new.posicion_unidad > v_versos then
		raise exception
			'La posición % no existe: la realización tiene % versos',
			new.posicion_unidad, v_versos;
	end if;

	select count(*) into v_repetida
	from public.elecciones_editor_metrico eleccion
	where eleccion.realizacion_prueba_id = new.realizacion_prueba_id
		and eleccion.grupo_eleccion_id = new.grupo_eleccion_id
		and eleccion.eleccion_prueba_id is distinct from new.eleccion_prueba_id
		and eleccion.posicion_unidad = new.posicion_unidad;

	if v_repetida > 0 then
		raise exception 'Ya hay una respuesta para la posición %', new.posicion_unidad;
	end if;

	return new;
end;
$function$;

-- Comprobación en vivo: ninguna función puede seguir citando la columna retirada.
do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from pg_proc p
	join pg_namespace n on n.oid = p.pronamespace
	where n.nspname = 'public'
		and p.prokind = 'f'
		and pg_get_functiondef(p.oid) like '%new.opcion_eleccion_id%';
	if v_n <> 0 then
		raise exception 'Quedan % funciones citando new.opcion_eleccion_id', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
