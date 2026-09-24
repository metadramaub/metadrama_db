-- Cada rasgo dice en qué se cuenta
--
-- El perfil métrico de la ficha sumaba los versos de las secuencias que tenían cada valor de rasgo.
-- Para la asonancia es correcto: una tirada tiene una sola asonancia, y un romance en é-o de 340
-- versos son 340 versos en é-o. Para el resto falseaba: «densidad de rima mayoritaria» no dice qué
-- versos riman, y el final esdrújulo se marca para la secuencia, no verso a verso.
--
-- La escala es una decisión sobre el rasgo y la necesitan todos los que cuentan rasgos —la ficha,
-- el laboratorio, los perfiles de autor—, así que va en el catálogo y no en el código de una
-- pantalla. **Obligatoria y sin valor por defecto**: un rasgo nuevo tiene que decir la suya.
--
-- - `verso`: el valor caracteriza los versos que cubre y se puede sumar en versos. La asonancia
--   cuenta los versos de la tirada, no solo los que riman: es lo que describe la asonancia, y así
--   las asonancias de un romance suman sus versos. El pie quebrado se anota verso a verso como
--   metro con posición, y se cuenta en versos por esa vía.
-- - `secuencia`: es un juicio sobre la secuencia entera y solo se cuentan secuencias. El dístico
--   final son los dos últimos versos, pero contarlos no dice nada que no diga el número de
--   secuencias.

alter table public.rasgos_metricos
	add column if not exists escala_recuento text;

update public.rasgos_metricos
set escala_recuento = case
	when slug in ('vocales_asonancia', 'pie_quebrado') then 'verso'
	else 'secuencia'
end
where escala_recuento is null;

alter table public.rasgos_metricos
	alter column escala_recuento set not null;

alter table public.rasgos_metricos
	drop constraint if exists rasgos_metricos_escala_recuento_check;
alter table public.rasgos_metricos
	add constraint rasgos_metricos_escala_recuento_check
	check (escala_recuento in ('verso', 'secuencia'));

comment on column public.rasgos_metricos.escala_recuento is
	'En qué se cuenta el rasgo: verso (su valor caracteriza los versos que cubre) o secuencia (juicio sobre la secuencia entera).';

-- La ficha la lleva en cada respuesta de rasgo, como `rasgo_escala`. Es la definición de
-- `20260924100000` con ese campo añadido.
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
			'sin_eventos_sobrenaturales', coalesce(v_obra.sin_eventos_sobrenaturales, false),
			'fecha_publicacion', v_obra.fecha_publicacion
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
			'rasgos', (
				select coalesce(
					jsonb_agg(
						respuesta.value || jsonb_build_object('rasgo_escala', rasgo.escala_recuento)
						order by respuesta.ordinality
					),
					'[]'::jsonb
				)
				from jsonb_array_elements(
					coalesce(public.ficha_publica_enriquece_respuestas(v_sequence -> 'rasgos'), '[]'::jsonb)
				) with ordinality as respuesta(value, ordinality)
				left join public.rasgos_metricos rasgo on rasgo.slug = respuesta.value ->> 'rasgo_slug'
			),
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

-- **La guarda ejecuta lo que toca**: la escala de cada rasgo, y la productora sobre una obra que
-- tenga rasgos anotados, comprobando que todos salen con la suya.
do $guarda$
declare
	v_obra uuid;
	v_sin_escala int;
begin
	if exists (
		select 1 from public.rasgos_metricos
		where slug in ('vocales_asonancia', 'pie_quebrado') and escala_recuento <> 'verso'
	) or exists (
		select 1 from public.rasgos_metricos
		where slug not in ('vocales_asonancia', 'pie_quebrado') and escala_recuento <> 'secuencia'
	) then
		raise exception 'La escala de algún rasgo no es la acordada.';
	end if;

	select r.obra_id into v_obra
	from public.obras_resumen r
	where r.ficha is not null
		and exists (
			select 1
			from jsonb_array_elements(coalesce(r.ficha #> '{metrica,secuencias}', '[]'::jsonb)) s,
				jsonb_array_elements(coalesce(s -> 'rasgos', '[]'::jsonb)) rasgo
		)
	limit 1;

	if v_obra is null then
		raise notice 'Ninguna ficha guardada tiene rasgos: la productora no se prueba aquí.';
		return;
	end if;

	select count(*) into v_sin_escala
	from jsonb_array_elements(public.ficha_publica_json(v_obra, true) #> '{metrica,secuencias}') s,
		jsonb_array_elements(coalesce(s -> 'rasgos', '[]'::jsonb)) rasgo
	where coalesce(rasgo ->> 'rasgo_escala', '') not in ('verso', 'secuencia');

	if v_sin_escala > 0 then
		raise exception '% respuestas de rasgo de % salen sin escala.', v_sin_escala, v_obra;
	end if;

	if exists (
		select 1
		from public.obras_resumen r,
			jsonb_array_elements(coalesce(r.ficha #> '{metrica,secuencias}', '[]'::jsonb)) s,
			jsonb_array_elements(coalesce(s -> 'rasgos', '[]'::jsonb)) rasgo
		where r.ficha is not null and rasgo -> 'rasgo_escala' is null
	) then
		raise exception 'Alguna ficha guardada tiene rasgos sin escala.';
	end if;

	raise notice 'Cada rasgo dice en qué se cuenta.';
end
$guarda$;
