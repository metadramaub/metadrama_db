-- Una secuencia no termina antes de empezar
--
-- `secuencias_metricas` era **la única tabla del proyecto con rango sin esa restricción**. La tienen
-- `anotacion_realizaciones`, `anotacion_elecciones`, `anotacion_desviaciones`, `anotaciones_metricas`,
-- `secuencias_caracterizaciones_rango` y `secuencias_subtipos_estrofa`; la de producción, no.
--
-- La sostenía solo el `refine` de zod del API. Y aguantó: **0 secuencias invertidas de 263**, y
-- ninguna con `n_versos` descuadrado. Pero es la tabla a la que escribe el editor nuevo, y el día
-- que entre por otra vía —un guion, un endpoint nuevo, la migración de anotaciones— no habría nada
-- que lo parara.
--
-- Salió recorriendo el formulario forma por forma: el campo del rango admitía un final anterior al
-- inicial, y **toda la pantalla razonaba sobre él** —en una forma de trece versos, 116–112 anunciaba
-- que «la estructura rebasa el rango en 39 versos»—. Eso se arregló en la interfaz; esto es la otra
-- mitad, la que no depende de por dónde se escriba.

begin;

do $$
declare
	v_invertidas integer;
begin
	if exists (
		select 1 from pg_constraint
		where conrelid = 'public.secuencias_metricas'::regclass
			and contype = 'c'
			and pg_get_constraintdef(oid) like '%v_fin%v_ini%'
	) then
		raise exception 'La restricción ya está puesta.';
	end if;

	-- **Se mira el dato antes de imponerlo.** Añadir una restricción que los datos incumplen falla
	-- entera, y en una tabla de producción conviene saber qué se va a encontrar.
	select count(*) into v_invertidas from public.secuencias_metricas where v_fin < v_ini;
	if v_invertidas > 0 then
		raise exception 'Hay % secuencias con el final antes del principio: revísalas antes.', v_invertidas;
	end if;
end $$;

alter table public.secuencias_metricas
	add constraint secuencias_metricas_rango_check check (v_fin >= v_ini);

do $$
declare
	v_error text;
	v_obra uuid;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta lo que se toca:** se intenta escribir una secuencia imposible y se comprueba que
	-- la base la rechaza. Lo que entra se deshace.
	select obra_id into v_obra from public.obras limit 1;
	if v_obra is null then
		raise exception 'No hay ninguna obra donde comprobarlo.';
	end if;

	begin
		insert into public.secuencias_metricas (obra_id, v_ini, v_fin, n_versos)
		values (v_obra, 300000, 299990, 1);
		raise exception 'La base ha admitido una secuencia que termina antes de empezar.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%secuencias_metricas_rango_check%' then
			raise exception 'Ha fallado por otra razón: %', v_error;
		end if;
	end;

	-- Y una normal sigue entrando.
	insert into public.secuencias_metricas (obra_id, v_ini, v_fin, n_versos)
	values (v_obra, 300000, 300003, 4);
	delete from public.secuencias_metricas where obra_id = v_obra and v_ini = 300000;
end $$;

commit;
