-- Se retira «Los ramilletes de Madrid (prueba)».
--
-- Es la obra de pruebas del proyecto y sus datos son inventados. Estaba contaminando todo
-- lo que se mide sobre el corpus: 44 de las 260 secuencias métricas eran suyas, y siete
-- términos legados parecían en uso cuando solo los usaba ella.
--
-- **Esto borra datos y no se deshace.** Todas las claves ajenas hacia `obras` son
-- `on delete cascade`, así que basta con borrar la obra: se van con ella sus jornadas,
-- secuencias, subtipos, caracterizaciones, atribuciones, comentarios y su fila de resumen.
--
-- Efecto secundario que conviene saber: `decima`, `romance`, `octava_real`,
-- `pareado_octosilabo`, `terceto`, `soneto` y `silva` se quedan sin ninguna secuencia real.
-- Eran las raíces genéricas que solo esta obra escogía; el corpus de verdad siempre elige
-- una hija concreta. Ver docs/dominio-metrico/equivalencias-pendientes.md.

begin;

do $$
declare
	v_obra uuid;
	v_titulo text;
	v_secuencias integer;
begin
	select obra_id, titulo into v_obra, v_titulo
	from public.obras
	where titulo = 'Los ramilletes de Madrid (prueba)';

	if v_obra is null then
		raise notice 'La obra de pruebas ya no está: no hay nada que retirar.';
		return;
	end if;

	select count(*) into v_secuencias
	from public.secuencias_metricas where obra_id = v_obra;

	-- Nadie debería estar anotándola en sombra, pero si lo estuviera, la cascada se llevaría
	-- también ese trabajo sin avisar.
	if exists (
		select 1
		from public.secuencias_editor_metrico sem
		join public.secuencias_metricas sm on sm.secuencia_id = sem.secuencia_id
		where sm.obra_id = v_obra
	) then
		raise exception 'La obra de pruebas tiene anotaciones en sombra: revísalas antes de retirarla';
	end if;

	delete from public.obras where obra_id = v_obra;

	raise notice 'Retirada «%» con sus % secuencias métricas.', v_titulo, v_secuencias;
end $$;

commit;

-- Los precomputados que la mencionaban se rehacen. `obras_resumen` se fue en la cascada,
-- pero el perfil del autor al que estaba atribuida sigue contándola.
select public.recompute_all();
