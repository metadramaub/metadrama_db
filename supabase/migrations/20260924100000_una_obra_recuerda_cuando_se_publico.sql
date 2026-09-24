-- Una obra recuerda cuándo se publicó
--
-- La cabecera de la ficha decía «Última modificación», que es `obras.updated_at`: cambia con
-- cualquier escritura en la fila —el estado, el editor asignado— y no con la anotación, que vive en
-- otras tablas. Lo que el lector quiere saber primero es desde cuándo está publicada.
--
-- `fecha_cambio_estado` no sirve: se sobrescribe en cada cambio, y una obra que vuelve a borrador y
-- se republica pierde la fecha en que salió. Hace falta una columna que se ponga **la primera vez**
-- que la obra pasa a publicada y no se toque más. La pone un disparador y no el endpoint de estado,
-- para que valga igual por cualquier camino que cambie el estado.

alter table public.obras
	add column if not exists fecha_publicacion timestamptz;

comment on column public.obras.fecha_publicacion is
	'La primera vez que la obra pasó a publicada. La pone un disparador y no cambia después.';

create or replace function public.obra_recuerda_su_publicacion()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
	-- Una vez puesta no se mueve, la escriba quien la escriba.
	if tg_op = 'UPDATE' and old.fecha_publicacion is not null then
		new.fecha_publicacion := old.fecha_publicacion;
		return new;
	end if;

	if new.fecha_publicacion is null and exists (
		select 1
		from public.vocabularios estado
		where estado.termino_id = new.estado
			and estado.categoria = 'estado'
			and lower(estado.termino) = 'publicado'
	) then
		new.fecha_publicacion := now();
	end if;

	return new;
end;
$$;

drop trigger if exists trg_obras_recuerda_su_publicacion on public.obras;
create trigger trg_obras_recuerda_su_publicacion
	before insert or update on public.obras
	for each row execute function public.obra_recuerda_su_publicacion();

-- Las ya publicadas toman la mejor fecha que hay: la del último cambio de estado, que para una obra
-- publicada una sola vez es la de su publicación. **Sin disparadores**: rellenar una columna nueva
-- no es modificar la obra, y no debe mover `updated_at` ni marcar nada como pendiente de recalcular.
alter table public.obras disable trigger user;

update public.obras obra
set fecha_publicacion = coalesce(obra.fecha_cambio_estado, obra.updated_at, obra.created_at)
from public.vocabularios estado
where estado.termino_id = obra.estado
	and estado.categoria = 'estado'
	and lower(estado.termino) = 'publicado'
	and obra.fecha_publicacion is null;

alter table public.obras enable trigger user;

-- La ficha la lleva en `obra`, junto a lo demás que el envoltorio lee de la fila. Es la definición
-- de `20260910150000` con la fecha añadida.
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

-- **La guarda ejecuta lo que toca**: publica de verdad una obra que no lo está, comprueba que el
-- disparador pone la fecha y que después no se deja mover, y lo deshace todo al final.
do $guarda$
declare
	v_publicado uuid;
	v_obra uuid;
	v_fecha timestamptz;
	v_ficha jsonb;
begin
	if exists (
		select 1
		from public.obras obra
		join public.vocabularios estado on estado.termino_id = obra.estado
		where estado.categoria = 'estado'
			and lower(estado.termino) = 'publicado'
			and obra.fecha_publicacion is null
	) then
		raise exception 'Hay obras publicadas sin fecha de publicación.';
	end if;

	select termino_id into v_publicado
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	select obra.obra_id into v_obra
	from public.obras obra
	where obra.estado is distinct from v_publicado
		and obra.fecha_publicacion is null
	limit 1;

	if v_publicado is null or v_obra is null then
		raise notice 'No hay obra sin publicar con la que probar el disparador.';
	else
		begin
			update public.obras set estado = v_publicado where obra_id = v_obra;
			select fecha_publicacion into v_fecha from public.obras where obra_id = v_obra;
			if v_fecha is null then
				raise exception 'El disparador no pone la fecha al publicar.';
			end if;

			update public.obras set fecha_publicacion = '2000-01-01' where obra_id = v_obra;
			if (select fecha_publicacion from public.obras where obra_id = v_obra) is distinct from v_fecha then
				raise exception 'La fecha de publicación se ha dejado mover.';
			end if;

			raise exception 'guarda_deshecha';
		exception when raise_exception then
			if sqlerrm <> 'guarda_deshecha' then
				raise;
			end if;
		end;
	end if;

	select obra_id into v_obra from public.obras limit 1;
	if v_obra is not null then
		v_ficha := public.ficha_publica_json(v_obra, true);
		if not ((v_ficha -> 'obra') ? 'fecha_publicacion') then
			raise exception 'La productora no devuelve la fecha de publicación.';
		end if;
	end if;

	if exists (
		select 1 from public.obras_resumen
		where ficha is not null and not ((ficha -> 'obra') ? 'fecha_publicacion')
	) then
		raise exception 'Alguna ficha guardada sigue sin fecha de publicación.';
	end if;

	raise notice 'La obra recuerda cuándo se publicó.';
end
$guarda$;
