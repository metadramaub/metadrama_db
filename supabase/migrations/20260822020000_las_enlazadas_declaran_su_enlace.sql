-- Las enlazadas declaran su enlace
--
-- Segunda corrección vista en la ficha, y esta era peor que la anterior: la rejilla imprimía bajo
-- las tres estrofas enlazadas la frase **«La rima se renueva en cada repetición»**, que es
-- exactamente lo contrario de lo que las define.
--
-- No es un fallo del módulo. `MetricPositionGrid.svelte` deriva esa frase de un silencio razonado:
-- «el modelo declara la conservación **en positivo**, con `esquema_rima_enlaces`; la renovación era
-- su silencio, y el silencio no se distingue de un dato que falta». Un ciclo que rima y no declara
-- ningún enlace se lee, con razón, como un ciclo que estrena rimas cada vuelta. **El dato que
-- faltaba era el enlace**, y el catálogo lo tiene desde julio: es el mismo mecanismo con que el
-- terceto encadenado dice «la rima del verso 2 vuelve en el verso 1 de la repetición siguiente», y
-- con el que el romance dice que su verso 2 conserva la rima.
--
-- Las tres lo declaran ahora, cada una desde el verso que cierra su vuelta hasta el primero de la
-- siguiente, que es el verso de enlace:
--
-- | Forma | Enlace |
-- | --- | --- |
-- | Redondilla enlazada | del cuarto —el quebrado— al primero de la vuelta siguiente |
-- | Sextilla enlazada | del sexto al primero |
-- | Septilla enlazada | del séptimo al primero |
--
-- *Queda dicho por los dos lados: la nota de la posición dice de dónde viene la rima del primer
-- verso, y el enlace dice adónde va la del último. Con esto se cierra la primera mitad del apunte
-- A2ter; lo que sigue abierto es solo que la rejilla no sabe **colorear** la clase que viene de la
-- vuelta anterior, y eso ya no engaña a nadie porque el pie lo explica.*

begin;

do $$
declare
	v_esquema uuid;
	v_n integer;
	v_fila text[];
begin
	foreach v_fila slice 1 in array array[
		array['redondilla_enlazada', '4',
			'El cuarto verso es el quebrado: estrena la rima con que abre la estrofa siguiente.'],
		array['sextilla_enlazada', '6',
			'El sexto verso cierra con la rima del quebrado, y es la que recoge el primer verso de '
			|| 'la estrofa siguiente.'],
		array['septilla_enlazada', '7',
			'El séptimo verso cierra la quintilla, y su rima es la que recoge el primer verso de la '
			|| 'estrofa siguiente.']
	] loop
		select er.esquema_rima_id into v_esquema
		from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = v_fila[1] and er.slug = 'enlazada';

		if v_esquema is null then
			raise exception 'No aparece la disposición enlazada de %.', v_fila[1];
		end if;

		-- El verso que cierra la vuelta debe existir y ser el último.
		if not exists (
			select 1 from public.esquema_rima_posiciones
			where esquema_rima_id = v_esquema and posicion = v_fila[2]::integer
		) then
			raise exception 'La disposición de % no llega al verso %.', v_fila[1], v_fila[2];
		end if;

		insert into public.esquema_rima_enlaces (
			esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
			desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino, nota
		)
		select v_esquema, 1, v_fila[2]::integer, 'final', 1, 1, 1, 'final', v_fila[3]
		where not exists (
			select 1 from public.esquema_rima_enlaces where esquema_rima_id = v_esquema
		);
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Las tres declaran un enlace, y ninguno es interior: es lo que las hace series enlazadas.
	select count(*) into v_n
	from public.esquema_rima_enlaces e
	join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug in ('redondilla_enlazada', 'sextilla_enlazada', 'septilla_enlazada')
		and e.desplazamiento_bloque = 1 and e.posicion_destino = 1;
	if v_n <> 3 then
		raise exception 'Solo % de las tres enlazadas declara su enlace.', v_n;
	end if;

	-- Y el origen de cada enlace es el último verso de su vuelta, no otro.
	if exists (
		select 1
		from public.esquema_rima_enlaces e
		join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug in ('redondilla_enlazada', 'sextilla_enlazada', 'septilla_enlazada')
			and e.posicion_origen <> (
				select max(p.posicion) from public.esquema_rima_posiciones p
				where p.esquema_rima_id = er.esquema_rima_id
			)
	) then
		raise exception 'Alguna enlazada enlaza desde un verso que no cierra su vuelta.';
	end if;

	foreach v_fila slice 1 in array array[
		array['redondilla_enlazada'], array['sextilla_enlazada'], array['septilla_enlazada']
	] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_fila[1]) -> 'enlacesRima'
			)
		) then
			raise exception 'La ficha de % no trae su enlace de rima.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
