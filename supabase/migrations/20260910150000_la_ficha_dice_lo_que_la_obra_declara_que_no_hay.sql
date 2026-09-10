-- La ficha dice lo que la obra declara que no hay
--
-- Marcar «no tiene figuras de donaire» en una obra no es un dato suelto: el disparador
-- `obra_declara_por_sus_secuencias` escribe `sin_intervencion` en todas las secuencias que
-- callaban. Cuando la ficha pública se puso a mostrar también dónde **no** ocurre cada fenómeno,
-- esas obras pasaron a enseñar cuarenta secuencias que dicen lo mismo sin decir por qué lo dicen.
--
-- Con las tres marcas en la ficha, el índice lo dice una vez y no lista nada. La productora de
-- dominio no se toca —son trescientas líneas y el dato es de la fila `obras`, que ya está leída—:
-- se añade en el envoltorio, junto al correo que allí mismo se retira.

create or replace function public.ficha_publica_json(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $productora$
declare
	v_payload jsonb;
	v_sequence jsonb;
	v_sequences jsonb := '[]'::jsonb;
	v_structural_level text;
	v_obra public.obras%rowtype;
begin
	v_payload := public.ficha_publica_dominio_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	-- La cuenta sirve para editar; no es por sí sola un canal público de contacto.
	v_payload := v_payload #- '{obra,autor_ficha_email_publico}';

	select * into v_obra from public.obras where obra_id = p_obra_id;

	v_payload := jsonb_set(
		v_payload,
		'{obra}',
		(v_payload -> 'obra') || jsonb_build_object(
			'sin_figuras_donaire', coalesce(v_obra.sin_figuras_donaire, false),
			'sin_personajes_sobrenaturales', coalesce(v_obra.sin_personajes_sobrenaturales, false),
			'sin_eventos_sobrenaturales', coalesce(v_obra.sin_eventos_sobrenaturales, false)
		),
		true
	);

	for v_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{metrica,secuencias}', '[]'::jsonb))
	loop
		v_structural_level := null;

		select fm.nivel_estructural
		into v_structural_level
		from public.arquitecturas_forma architecture
		join public.formas_metricas fm on fm.forma_id = architecture.forma_id
		where architecture.arquitectura_id = nullif(v_sequence ->> 'arquitectura_id', '')::uuid;

		v_sequence := v_sequence || jsonb_build_object(
			'nivel_estructural', v_structural_level,
			'esquemas_rima', public.ficha_publica_enriquece_respuestas(v_sequence -> 'esquemas_rima'),
			'rasgos', public.ficha_publica_enriquece_respuestas(v_sequence -> 'rasgos'),
			'metros', public.ficha_publica_enriquece_respuestas(v_sequence -> 'metros'),
			'variedades', public.ficha_publica_enriquece_respuestas(v_sequence -> 'variedades')
		);

		v_sequences := v_sequences || jsonb_build_array(v_sequence);
	end loop;

	return jsonb_set(v_payload, '{metrica,secuencias}', v_sequences, true);
end;
$productora$;

revoke all on function public.ficha_publica_json(uuid, boolean)
	from public, anon, authenticated;

-- Las fichas guardadas no esperan a la próxima edición de su obra.
do $rehacer$
declare
	v_obra uuid;
begin
	for v_obra in
		select r.obra_id from public.obras_resumen r where r.ficha is not null
	loop
		perform public.recompute_obra_resumen_metricas(v_obra);
	end loop;
end;
$rehacer$;

-- **La guarda ejecuta lo que toca.** Un cuerpo entrecomillado no se revalida al reescribirlo, así
-- que la productora se hace correr sobre una obra real y se comprueba el dato en la ficha guardada.
do $guarda$
declare
	v_obra uuid;
	v_ficha jsonb;
begin
	select obra_id into v_obra from public.obras limit 1;

	if v_obra is null then
		raise notice 'No hay obras: la productora no se prueba aquí.';
		return;
	end if;

	v_ficha := public.ficha_publica_json(v_obra, true);

	if v_ficha #> '{obra,sin_figuras_donaire}' is null
		or v_ficha #> '{obra,sin_personajes_sobrenaturales}' is null
		or v_ficha #> '{obra,sin_eventos_sobrenaturales}' is null
	then
		raise exception 'La productora no devuelve lo que la obra declara que no tiene.';
	end if;

	if v_ficha #> '{obra,autor_ficha_email_publico}' is not null then
		raise exception 'La productora ha vuelto a exponer el correo de la cuenta.';
	end if;

	if exists (
		select 1 from public.obras_resumen
		where ficha is not null and ficha #> '{obra,sin_figuras_donaire}' is null
	) then
		raise exception 'Alguna ficha guardada sigue sin decir lo que su obra declara.';
	end if;

	raise notice 'La ficha declara lo que la obra no tiene.';
end
$guarda$;
