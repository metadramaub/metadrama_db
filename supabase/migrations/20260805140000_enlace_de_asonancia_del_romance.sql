-- Las cuatro arquitecturas del romance declaran que la asonancia no cambia.
--
-- Solo la octosílaba lo declaraba. Hexasílabo, heptasílabo y endecasílabo —que llegaron
-- después, con los romancillos y el romance heroico— se quedaron sin el enlace, aunque su
-- definición es la misma: «octosílabos en tiradas de duración indeterminada, con la misma
-- asonancia en los versos pares», y el metro no cambia eso.
--
-- Importa porque la ausencia de enlace **significa algo**: es lo que distingue una serie que
-- mantiene la rima de otra que la estrena en cada bloque. La silva `[aA]…` no tiene enlace
-- porque cada pareado rima distinto; el romance `[-a]…` sí debe tenerlo. Sin él, el catálogo
-- afirma de tres romances que cambian de asonancia cada dos versos.
--
-- Se copia del que estaba bien en vez de escribirlo otra vez, que es lo que hizo que
-- divergieran.

begin;

do $$
declare
	v_modelo record;
	v_creados integer := 0;
	v_esquema record;
begin
	-- El modelo es la arquitectura del romance que sí lo declara, sea cual sea: buscarla por
	-- su slug haría depender la migración de un nombre que puede cambiar.
	select e.* into v_modelo
	from public.esquema_rima_enlaces e
	join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'romance'
	limit 1;

	if v_modelo is null then
		raise exception 'Ninguna arquitectura del romance declara el enlace: no hay modelo que copiar';
	end if;

	for v_esquema in
		select er.esquema_rima_id, a.nombre as arquitectura
		from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'romance'
			and not exists (
				select 1 from public.esquema_rima_enlaces e
				where e.esquema_rima_id = er.esquema_rima_id
			)
	loop
		insert into public.esquema_rima_enlaces (
			esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
			desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino,
			tipo_enlace, obligatorio, nota
		)
		values (
			v_esquema.esquema_rima_id, v_modelo.bloque_origen, v_modelo.posicion_origen,
			v_modelo.ubicacion_origen, v_modelo.desplazamiento_bloque, v_modelo.bloque_destino,
			v_modelo.posicion_destino, v_modelo.ubicacion_destino, v_modelo.tipo_enlace,
			v_modelo.obligatorio, v_modelo.nota
		);
		v_creados := v_creados + 1;
		raise notice 'Enlace de asonancia añadido a Romance · %', v_esquema.arquitectura;
	end loop;

	if v_creados = 0 then
		raise notice 'Las cuatro arquitecturas del romance ya declaraban su enlace.';
	end if;

	-- Ninguna arquitectura del romance puede quedar afirmando que estrena asonancia.
	if exists (
		select 1
		from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'romance'
			and not exists (
				select 1 from public.esquema_rima_enlaces e
				where e.esquema_rima_id = er.esquema_rima_id
			)
	) then
		raise exception 'Sigue habiendo romances sin enlace de asonancia';
	end if;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
