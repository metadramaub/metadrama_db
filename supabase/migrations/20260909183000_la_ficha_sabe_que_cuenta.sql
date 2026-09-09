-- La ficha sabe qué está contando
--
-- Una elección no siempre habla de la misma escala: los rasgos suelen describir una tirada,
-- el metro puede responderse verso a verso y la rima puede pertenecer a una estrofa completa,
-- a una sección repetible o a varias secciones complementarias. La productora anterior conservaba
-- la realización, pero no decía qué sección materializaba esa realización. Sin ese dato, el cliente
-- podía recomponer un soneto y una copla real, pero confundía las estancias repetidas de la canción.

alter function public.ficha_publica_json(uuid, boolean)
	rename to ficha_publica_dominio_json;

revoke all on function public.ficha_publica_dominio_json(uuid, boolean)
	from public, anon, authenticated;

create or replace function public.ficha_publica_enriquece_respuestas(p_items jsonb)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
	select coalesce(
		jsonb_agg(
			item || jsonb_build_object(
				'realizacion_seccion_id', section_ref.seccion_id,
				'realizacion_seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
				'realizacion_seccion_tipo', section_ref.tipo_seccion,
				'realizacion_seccion_orden', section_ref.orden,
				'realizacion_seccion_repeticiones_min', section_ref.repeticiones_min,
				'realizacion_seccion_repeticiones_max', section_ref.repeticiones_max,
				'realizacion_seccion_arquitectura_referenciada_id', section_ref.arquitectura_referenciada_id
			)
			order by item_order
		),
		'[]'::jsonb
	)
	from jsonb_array_elements(coalesce(p_items, '[]'::jsonb))
		with ordinality as items(item, item_order)
	left join public.anotacion_realizaciones realization
		on realization.realizacion_id = nullif(item ->> 'realizacion_id', '')::uuid
	left join public.estructuras_secciones section_ref
		on section_ref.seccion_id = realization.seccion_id;
$function$;

revoke all on function public.ficha_publica_enriquece_respuestas(jsonb)
	from public, anon, authenticated;

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

-- El portero conserva el nombre público y delega en la productora enriquecida.
create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $portero$
begin
	if not exists (
		select 1
		from public.obras o
		where o.obra_id = p_obra_id
			and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
	) then
		return null;
	end if;

	return public.ficha_publica_json(p_obra_id, p_include_hidden);
end;
$portero$;

grant execute on function public.get_obra_ficha_publica(uuid, boolean)
	to anon, authenticated, service_role;

-- Las fichas publicadas se actualizan ahora; no esperan a la siguiente edición de cada obra.
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

