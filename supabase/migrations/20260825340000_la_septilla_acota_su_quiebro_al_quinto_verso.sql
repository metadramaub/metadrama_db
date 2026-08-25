-- La septilla acota su quiebro al quinto verso
--
-- Corrección de la regla 5 bis, decidida por el IP el 25 de agosto de 2026, unas horas después de
-- aplicarla. Toca 1 arquitectura de septilla.
--
-- **La distinción que faltaba.** Se había escrito que las notas del quiebro dicen *dónde* se
-- documenta y no *cuántos* admite la forma, y que por eso ninguna daba techo. Es verdad a medias:
--
-- > Si sabemos **exactamente dónde** aparecen los quebrados, sabemos cuántos versos lo son.
-- > Si sabemos **dónde pueden o suelen** aparecer, no sabemos las posiciones exactas y entonces
-- > tampoco el máximo.
--
-- La nota dice que el quiebro se documenta **en el quinto verso, el primero del terceto**. Un verso
-- nombrado es un quiebro contado.
--
-- Tres de las nueve se quedan sin techo, y con razón: la redondilla, porque Navarro Tomás la
-- documenta «**sin fijar** en qué versos cae el quiebro»; y la copla castellana y la copla de arte
-- menor, porque documentan **alternancia** de versos plenos y quebrados, que dice dónde pueden caer
-- y no dónde caen.
--
-- *Consecuencia que conviene tener presente:* el techo acota también lo que el editor puede marcar,
-- así que un pasaje con más quiebros de los que la fuente documenta no cabrá como respuesta normal.
-- Es lo correcto en este modelo —lo que excede la norma se registra como **desviación**—, pero es un
-- cambio real respecto de esta mañana, cuando estas seis admitían cualquier número.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_par text[];
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'septilla' and activo;
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado' and activo;
	if v_forma is null or v_rasgo is null then
		raise exception 'Falta la forma «septilla» o el rasgo del quiebro.';
	end if;

	foreach v_par slice 1 in array array[
		array['octosilabica', '1']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de septilla no está activa.', v_par[1];
		end if;

		-- El quiebro es licencia y la pregunta existe: si no, esta migración acotaría la nada.
		select count(*) into v_n
		from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo and modalidad <> 'definitoria';
		if v_n <> 1 then
			raise exception 'La arquitectura «%» no declara el quiebro como licencia.', v_par[1];
		end if;
		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and slug = 'posiciones_pie_quebrado' and activo
		) then
			raise exception 'La arquitectura «%» no pregunta dónde cayó el quiebro.', v_par[1];
		end if;

		update public.arquitectura_rasgos
		set posiciones_max = v_par[2]::integer
		where arquitectura_id = v_arq and rasgo_id = v_rasgo;

		-- Lo que la forma declara y lo que el editor puede marcar tienen que decir lo mismo.
		update public.grupos_eleccion_metrica
		set selecciones_max = v_par[2]::integer,
			ayuda_editor = 'El quiebro es una licencia, no la norma: marca los versos que veas '
				|| 'acortados y su medida, y deja la pregunta en blanco si no hay ninguno. Las '
				|| 'fuentes documentan '
				|| case when v_par[2] = '1' then 'uno' else v_par[2] end
				|| case when v_par[2] = '1' then ' solo' else ' como mucho' end
				|| '; si el pasaje trae más, regístralo como desviación.'
		where arquitectura_id = v_arq and slug = 'posiciones_pie_quebrado' and activo;

		-- ------------------------------------------------------------------ Comprobaciones
		select count(*) into v_n
		from public.arquitectura_rasgos ar
		join public.grupos_eleccion_metrica g
			on g.arquitectura_id = ar.arquitectura_id and g.slug = 'posiciones_pie_quebrado' and g.activo
		where ar.arquitectura_id = v_arq and ar.rasgo_id = v_rasgo
			and ar.posiciones_max = v_par[2]::integer
			and g.selecciones_max = v_par[2]::integer
			and g.selecciones_min = 0;
		if v_n <> 1 then
			raise exception 'El techo de «%» no ha quedado en % en los dos sitios.', v_par[1], v_par[2];
		end if;

		-- Y la pregunta sigue ofreciendo un verso por posición: acotar cuántos no cambia dónde.
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.slug = 'posiciones_pie_quebrado' and g.activo
			and o.activo and o.posicion_unidad is not null;
		if v_n = 0 then
			raise exception 'La pregunta de «%» ha dejado de ofrecer posiciones.', v_par[1];
		end if;
	end loop;

	if public.get_forma_metrica_publica('septilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de septilla ha dejado de responder.';
	end if;
end $$;

commit;
