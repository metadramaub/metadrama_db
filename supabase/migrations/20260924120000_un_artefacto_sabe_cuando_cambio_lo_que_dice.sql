-- Un artefacto sabe cuándo cambió lo que dice
--
-- La ficha quería decir «actualizada el …», y `generado_en` no sirve para eso: la cola de
-- «Actualizar datos públicos» recalcula todas las obras publicadas cada vez, y cada guardado lo
-- pone a `now()`. Diría cuándo alguien pulsó el botón, no cuándo cambió lo publicado.
--
-- `contenido_cambiado_en` solo se mueve cuando el JSON guardado es distinto del que había. El JSON
-- de una ficha no lleva nada que varíe de un cálculo a otro, así que recalcular una obra que no ha
-- cambiado la deja como estaba. Cuenta como cambio cualquier cosa que cambie lo publicado: la
-- anotación, y también un nombre de forma corregido en el catálogo, que cambia las fichas que lo
-- usan. Para quien lee es lo honesto: lo que tiene delante ya no es lo de antes.

alter table public.artefactos_publicos
	add column if not exists contenido_cambiado_en timestamptz;

-- Lo que ya hay no sabe cuándo cambió por última vez: su mejor aproximación es cuándo se generó.
update public.artefactos_publicos
set contenido_cambiado_en = generado_en
where contenido_cambiado_en is null;

alter table public.artefactos_publicos
	alter column contenido_cambiado_en set default now(),
	alter column contenido_cambiado_en set not null;

comment on column public.artefactos_publicos.contenido_cambiado_en is
	'Última vez que cambió el payload guardado. A diferencia de generado_en, no se mueve al recalcular sin cambios.';

create or replace function public.guardar_artefacto_publico(
	p_clave text,
	p_tipo text,
	p_entidad_id uuid,
	p_alcance text,
	p_payload jsonb,
	p_version_esquema integer default 1
)
returns void
language sql
security definer
set search_path = public
as $$
	insert into public.artefactos_publicos (
		clave, tipo, entidad_id, alcance, version_esquema, payload, sucio, generado_en,
		contenido_cambiado_en
	) values (
		p_clave, p_tipo, p_entidad_id, p_alcance, p_version_esquema, p_payload, false, now(), now()
	)
	on conflict (clave) do update set
		tipo = excluded.tipo,
		entidad_id = excluded.entidad_id,
		alcance = excluded.alcance,
		version_esquema = excluded.version_esquema,
		payload = excluded.payload,
		sucio = false,
		generado_en = now(),
		contenido_cambiado_en = case
			when artefactos_publicos.payload is distinct from excluded.payload
				or artefactos_publicos.version_esquema is distinct from excluded.version_esquema
			then now()
			else artefactos_publicos.contenido_cambiado_en
		end;
$$;

revoke all on function public.guardar_artefacto_publico(text, text, uuid, text, jsonb, integer)
	from public, anon, authenticated;
grant execute on function public.guardar_artefacto_publico(text, text, uuid, text, jsonb, integer)
	to service_role;

-- **La guarda ejecuta lo que toca**, sobre un artefacto real y dentro de un punto de retorno. Como
-- `now()` es la misma en toda la transacción, la fecha se marca antes con un valor imposible: si
-- guardar lo mismo la cambia, o guardar otra cosa no la cambia, se nota.
do $guarda$
declare
	v_artefacto public.artefactos_publicos%rowtype;
	v_fecha timestamptz;
begin
	select * into v_artefacto from public.artefactos_publicos limit 1;
	if v_artefacto.clave is null then
		raise notice 'No hay artefactos con los que probar el guardado.';
		return;
	end if;

	begin
		update public.artefactos_publicos
		set contenido_cambiado_en = '2000-01-01'
		where clave = v_artefacto.clave;

		perform public.guardar_artefacto_publico(
			v_artefacto.clave, v_artefacto.tipo, v_artefacto.entidad_id, v_artefacto.alcance,
			v_artefacto.payload, v_artefacto.version_esquema
		);
		select contenido_cambiado_en into v_fecha
		from public.artefactos_publicos where clave = v_artefacto.clave;
		if v_fecha <> '2000-01-01'::timestamptz then
			raise exception 'Guardar el mismo contenido ha movido la fecha de cambio.';
		end if;

		perform public.guardar_artefacto_publico(
			v_artefacto.clave, v_artefacto.tipo, v_artefacto.entidad_id, v_artefacto.alcance,
			v_artefacto.payload || jsonb_build_object('_guarda', true), v_artefacto.version_esquema
		);
		select contenido_cambiado_en into v_fecha
		from public.artefactos_publicos where clave = v_artefacto.clave;
		if v_fecha = '2000-01-01'::timestamptz then
			raise exception 'Guardar un contenido distinto no ha movido la fecha de cambio.';
		end if;

		raise exception 'guarda_deshecha';
	exception when raise_exception then
		if sqlerrm <> 'guarda_deshecha' then
			raise;
		end if;
	end;

	if exists (select 1 from public.artefactos_publicos where contenido_cambiado_en is null) then
		raise exception 'Hay artefactos sin fecha de cambio.';
	end if;

	raise notice 'El artefacto sabe cuándo cambió lo que dice.';
end
$guarda$;
