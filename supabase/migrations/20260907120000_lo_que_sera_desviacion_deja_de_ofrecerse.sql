-- Lo que será desviación deja de ofrecerse
--
-- La caracterización por rango se estaba usando para dos cosas distintas. Una es suya —qué se hace
-- con la voz dentro del pasaje: se canta, se habla en prosa, se evoca a otro personaje—. La otra es
-- **una desviación de la norma métrica** —un verso hipermétrico, una rima defectuosa, una laguna—,
-- que no tenía dónde ponerse cuando estas filas se escribieron y ahora sí lo tiene:
-- `anotacion_desviaciones`, con su dimensión, su relación con la norma y su rango.
--
-- Aquí se retiran del selector las que ya no son de este mecanismo, según el reparto decidido el 3
-- de agosto de 2026 en `docs/dominio-metrico/plan-desviaciones-y-caracterizaciones.md`:
--
--   * las cinco irregularidades métricas —hipométrico, hipermétrico, rima defectuosa, patrón
--     alternativo y laguna— y su agrupador;
--   * los dos finales acentuales y el suyo, que pasan a ser valores del rasgo `final_acentual`.
--
-- **No se borra ni una fila.** Las 209 que hay siguen donde están, se siguen leyendo en el editor y
-- en la ficha, y se pueden corregir o borrar: solo dejan de poder **elegirse de nuevo**. Su
-- traslado a desviaciones se hace obra por obra con quien la anotó, y necesita que la secuencia
-- tenga antes su forma del catálogo nuevo —una desviación cuelga de una anotación, no de una
-- secuencia—, así que no puede adelantarse aquí.
--
-- Queda ofreciéndose lo que de verdad es una caracterización por rango: cantado, prosa y la
-- evocación métrica, que llegó en la migración anterior.

begin;

update public.vocabularios
set activo = false, updated_at = now()
where categoria = 'caracterizacion_rango'
  and termino in (
	'irregularidades_metricas', 'hipometrico', 'hipermetrico', 'rima_defectuosa',
	'patron_alternativo', 'laguna',
	'final_acentual', 'mayoria_agudas', 'mayoria_esdrujulas'
  );

-- ---------------------------------------------------------------------------
-- La guarda
--
-- Comprueba las dos mitades: que el selector ofrece exactamente lo que tiene que ofrecer —es la
-- misma consulta que hace el servidor: categoría y `activo`— y que lo retirado **se sigue leyendo**
-- donde ya está escrito, ejecutando la ficha de una obra que lo usa.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_ofrecidos text;
	v_admin uuid;
	v_obra uuid;
	v_ficha jsonb;
	v_retiradas integer;
	v_en_ficha integer;
begin
	select string_agg(termino, ', ' order by termino)
	into v_ofrecidos
	from public.vocabularios
	where categoria = 'caracterizacion_rango' and activo;

	if v_ofrecidos is distinct from 'cantado, evocacion_metrica, fenomenos_enunciativos, prosa' then
		raise exception 'El selector ofrecería: %', coalesce(v_ofrecidos, '(nada)');
	end if;

	-- La ficha se ejecuta con la identidad de un admin: sin ella devuelve nulo y no se comprueba
	-- nada. Solo dentro de esta transacción.
	select e.user_id into v_admin
	from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
	limit 1;

	if v_admin is null then
		raise notice 'No hay ningún admin: la lectura no se comprueba aquí.';
		return;
	end if;

	perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

	select sm.obra_id, count(*)
	into v_obra, v_retiradas
	from public.secuencias_caracterizaciones_rango c
	join public.secuencias_metricas sm on sm.secuencia_id = c.secuencia_id
	join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
	where not v.activo
	  and public.can_view_obra_ficha_publica(sm.obra_id, true)
	group by sm.obra_id
	order by count(*) desc
	limit 1;

	if v_obra is null then
		raise notice 'Ninguna obra visible usa los términos retirados: no hay lectura que comprobar.';
		perform set_config('request.jwt.claims', '', true);
		return;
	end if;

	v_ficha := public.get_obra_ficha_publica_base_without_slugs(v_obra, true);

	if v_ficha is null then
		raise exception 'La ficha de la obra % devolvió nulo', v_obra;
	end if;

	-- Lo retirado se sigue leyendo: cada fila llega a la ficha con su nombre, no en blanco.
	select count(*)
	into v_en_ficha
	from jsonb_array_elements(v_ficha -> 'metrica' -> 'secuencias') sec,
	     jsonb_array_elements(sec -> 'caracterizaciones_rango') car
	join public.vocabularios v
		on v.termino_id = (car ->> 'tipo_caracterizacion_rango_id')::uuid
	where not v.activo
	  and coalesce(car ->> 'tipo_caracterizacion_rango_term', '') not in ('', 'sin_tipo');

	if v_en_ficha <> v_retiradas then
		raise exception 'La obra % guarda % caracterizaciones retiradas y la ficha lee %',
			v_obra, v_retiradas, v_en_ficha;
	end if;

	perform set_config('request.jwt.claims', '', true);
	raise notice 'Retiradas del selector; la obra % sigue leyendo sus % caracterizaciones', v_obra, v_en_ficha;
end
$guarda$;

commit;
