-- Lo que se responde en cada aparición no se aplica a todas.
--
-- Al implementar el alcance por realización apareció que el editor V2 **ya preguntaba por
-- aparición** sin saberlo: casa cada pregunta con las realizaciones de su sección, así que una
-- atada al ciclo de copla se hace en cada ciclo. Lo que no estaba bien era otra cosa.
--
-- `permite_aplicar_global` ofrece al editor un atajo: responder una vez y aplicar la respuesta a
-- todas las unidades. Es cómodo y correcto para la medida de una estrofa, que no cambia. Pero las
-- tres preguntas de la represa lo tenían puesto, **y son justo las que pueden dar una respuesta
-- distinta en cada ciclo**: Navarro Tomás documenta repeticiones parciales y totales dentro de la
-- misma composición. El atajo contradice el alcance.
--
-- Se apaga en las tres, y se prohíbe la combinación con una restricción, porque un atajo que
-- borra una distinción que acabamos de declarar volvería a ponerse solo.

begin;

update public.grupos_eleccion_metrica
set permite_aplicar_global = false,
	updated_at = now()
where alcance = 'realizacion' and permite_aplicar_global;

alter table public.grupos_eleccion_metrica
	drop constraint if exists grupos_eleccion_metrica_global_check;

alter table public.grupos_eleccion_metrica
	add constraint grupos_eleccion_metrica_global_check
	check (alcance <> 'realizacion' or not permite_aplicar_global);

do $$
declare
	v_n integer;
	v_grupo uuid;
	v_json jsonb;
begin
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where alcance = 'realizacion' and permite_aplicar_global;
	if v_n <> 0 then
		raise exception '% preguntas por aparición conservan el atajo global', v_n;
	end if;

	-- Las tres siguen siendo por aparición: esto apaga el atajo, no cambia el alcance.
	select count(*) into v_n from public.grupos_eleccion_metrica where alcance = 'realizacion';
	if v_n <> 3 then
		raise exception 'Hay % preguntas por aparición en vez de 3', v_n;
	end if;

	-- Y la restricción se ejerce, no se promete.
	select grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica where alcance = 'realizacion' limit 1;
	begin
		update public.grupos_eleccion_metrica
		set permite_aplicar_global = true
		where grupo_eleccion_id = v_grupo;
		raise exception 'La restricción admitió el atajo en una pregunta por aparición';
	exception
		when check_violation then
			null;
	end;

	-- La medida de la estrofa conserva el suyo, que es donde el atajo sirve.
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where permite_aplicar_global;
	if v_n = 0 then
		raise exception 'Ninguna pregunta conserva el atajo global; se ha apagado de más';
	end if;

	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ? 'choiceGroups') then
		raise exception 'El catálogo del demarcador salió sin grupos';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
