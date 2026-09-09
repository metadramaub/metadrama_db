-- El correo de la cuenta no es un contacto público
--
-- La ficha ya publica el nombre que el editor ha elegido para firmarla y su ORCID. El correo, en
-- cambio, se tomaba directamente de la cuenta asignada a la obra: que la clave histórica se llamara
-- `autor_ficha_email_publico` no constituía consentimiento para exponerlo. Se retira tanto de la
-- productora como de las fichas ya precomputadas. Si algún día se ofrece contacto directo, necesitará
-- un campo propio y una decisión expresa de quien firma.

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
begin
	v_payload := public.ficha_publica_dominio_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	-- La cuenta sirve para editar; no es por sí sola un canal público de contacto.
	v_payload := v_payload #- '{obra,autor_ficha_email_publico}';

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

-- Las fichas publicadas no esperan al próximo recompute para dejar de llevar el correo.
update public.obras_resumen
set ficha = ficha #- '{obra,autor_ficha_email_publico}'
where ficha #> '{obra,autor_ficha_email_publico}' is not null;

do $guarda$
declare
	v_obra uuid;
begin
	select obra_id into v_obra from public.obras limit 1;
	if v_obra is not null
		and public.ficha_publica_json(v_obra, true) #> '{obra,autor_ficha_email_publico}' is not null
	then
		raise exception 'La productora sigue exponiendo el correo de la cuenta.';
	end if;

	if exists (
		select 1 from public.obras_resumen
		where ficha #> '{obra,autor_ficha_email_publico}' is not null
	) then
		raise exception 'Alguna ficha precomputada sigue exponiendo el correo de la cuenta.';
	end if;
end
$guarda$;
