-- El final acentual es una capa, no una manera de construir la tirada
--
-- El perfil de la ficha agrupa los rasgos de secuencia por combinación: cada combinación es un tipo
-- de secuencia. Pero no todos los rasgos dicen qué tipo de secuencia es. La densidad de rima, la
-- organización en pareados, el dístico final o el encadenamiento describen **cómo está construida**
-- la tirada; el final esdrújulo o agudo es **una capa que se le añade** y que admiten formas muy
-- distintas —la octava, el suelto, el soneto—. Metido en la combinación, un suelto con final
-- esdrújulo parecía otra clase de suelto.
--
-- No se deduce de nada que ya hubiera. La modalidad no sirve: la rima esporádica del suelto también
-- es «admitida» y sí describe su construcción. Y en la octava aguda el final agudo es definitorio,
-- pero lo es de esa arquitectura, no del rasgo: sigue siendo una capa. Lo que distingue al final
-- acentual es el rasgo mismo, así que se declara en el rasgo, **obligatoria y sin valor por
-- defecto**, como la escala.

alter table public.rasgos_metricos
	add column if not exists naturaleza text;

update public.rasgos_metricos
set naturaleza = case when slug = 'final_acentual' then 'capa' else 'construccion' end
where naturaleza is null;

alter table public.rasgos_metricos
	alter column naturaleza set not null;

alter table public.rasgos_metricos
	drop constraint if exists rasgos_metricos_naturaleza_check;
alter table public.rasgos_metricos
	add constraint rasgos_metricos_naturaleza_check
	check (naturaleza in ('construccion', 'capa'));

comment on column public.rasgos_metricos.naturaleza is
	'construccion: describe cómo está hecha la secuencia (la combinación de estos es su tipo). capa: se añade encima y no cambia su tipo (el final acentual).';

-- La ficha la lleva en cada respuesta de rasgo, como `rasgo_naturaleza`. Es la definición de
-- `20260924140000` con ese campo añadido.
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
						respuesta.value || jsonb_build_object(
							'rasgo_escala', rasgo.escala_recuento,
							'rasgo_naturaleza', rasgo.naturaleza
						)
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

-- **La guarda ejecuta lo que toca**: el valor de cada rasgo, y la productora sobre una obra con
-- rasgos, comprobando que todos salen con su naturaleza.
do $guarda$
declare
	v_obra uuid;
	v_sin int;
begin
	if exists (
		select 1 from public.rasgos_metricos
		where (slug = 'final_acentual') <> (naturaleza = 'capa')
	) then
		raise exception 'La naturaleza de algún rasgo no es la acordada.';
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

	select count(*) into v_sin
	from jsonb_array_elements(public.ficha_publica_json(v_obra, true) #> '{metrica,secuencias}') s,
		jsonb_array_elements(coalesce(s -> 'rasgos', '[]'::jsonb)) rasgo
	where coalesce(rasgo ->> 'rasgo_naturaleza', '') not in ('construccion', 'capa')
		or coalesce(rasgo ->> 'rasgo_escala', '') not in ('verso', 'secuencia');

	if v_sin > 0 then
		raise exception '% respuestas de rasgo de % salen sin naturaleza o sin escala.', v_sin, v_obra;
	end if;

	if exists (
		select 1
		from public.obras_resumen r,
			jsonb_array_elements(coalesce(r.ficha #> '{metrica,secuencias}', '[]'::jsonb)) s,
			jsonb_array_elements(coalesce(s -> 'rasgos', '[]'::jsonb)) rasgo
		where r.ficha is not null and rasgo -> 'rasgo_naturaleza' is null
	) then
		raise exception 'Alguna ficha guardada tiene rasgos sin naturaleza.';
	end if;

	raise notice 'El final acentual es una capa.';
end
$guarda$;
