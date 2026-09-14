-- La sextina y el zéjel de Jauralde declaran ya todos sus sitios
--
-- Último tramo de la localización ciega sobre las afirmaciones que tenían el localizador en duda.
--
--   7d6ea13a  Sextina  «Sextina real» → «Sextina real» y «Sexta rima»
--             La afirmación dice dos cosas: que Jauralde llama «sextina real» a un sexteto
--             endecasilábico ABABCC, y que **la sextina de verdad** —la que no rima dentro de la
--             estrofa y repite las palabras finales— es otra cosa. Lo primero está bajo «Sextina
--             real»; lo segundo, bajo **«Sexta rima»**, donde cita la definición de Domínguez
--             Caparrós: «Poema de treinta y nueve endecasílabos, dividido en seis estrofas de seis
--             versos y un remate de tres versos. Los versos de cada una de las estrofas no riman
--             entre sí, pero todos los versos repiten la misma palabra final…».
--
--             Conviene dejar constancia de cómo se encontró, porque una búsqueda razonable no da
--             con ello: ese pasaje **no contiene la palabra «sextina»**, ni nombra a Arnaut
--             Daniel, ni dice «palabras-rima». Buscando esos términos se concluye que Jauralde
--             anuncia dedicarle espacio aparte a la sextina y no lo hace, que es justo lo
--             contrario de lo que pasa. Lo encontró la pasada C leyendo los epígrafes de la
--             familia de seis versos uno por uno.
--
--   e2c60b96  Zéjel  «Zéjel» y «Villancico»
--                  → «Zéjel», «Estrofas con estribillo» y «Estrofas mayores formadas por tercetos
--                    o por tercetillos»
--             Sus tres aserciones están en tres sitios. El cuerpo de la definición —cabeza,
--             mudanza de terceto monorrimo, vuelta, `aa:bbba`— bajo «Zéjel». La reserva del
--             término villancico para las mudanzas no monorrimas, en el cuerpo de «Estrofas con
--             estribillo». Y que el terceto monorrimo fue la forma primitiva de su cuerpo, en
--             «Estrofas mayores formadas por tercetos o por tercetillos», en otro capítulo.
--             **«Villancico» no es un epígrafe de este libro**: se comprobó buscándolo como línea
--             de encabezado, igual que los otros cuatro títulos inventados que ya se corrigieron
--             en esta fuente.
--
-- Los cinco títulos nuevos se han verificado como líneas de encabezado del volcado. No se toca una
-- palabra de prosa.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['7d6ea13a-0ddd-4cf0-9871-a6eaa0fe162c',
			'Apartado «Sextina real»',
			'Apartados «Sextina real» y «Sexta rima»'],
		array['e2c60b96-8587-4c74-958a-550b808ccbcb',
			'Apartados «Zéjel» y «Villancico»',
			'Apartados «Zéjel», «Estrofas con estribillo» y «Estrofas mayores formadas por tercetos o por tercetillos»']
	];
	v_fila text[];
	v_ids uuid[] := '{}';
	v_cuantas integer;
	v_puestos integer := 0;
	v_resumen_antes text;
	v_resumen_despues text;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	foreach v_fila slice 1 in array v_cambios loop
		v_ids := v_ids || (v_fila[1])::uuid;
	end loop;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_antes
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where afirmacion_id = (v_fila[1])::uuid and localizador = v_fila[2];
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				left(v_fila[1], 8), v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3]
		where afirmacion_id = (v_fila[1])::uuid;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where afirmacion_id = (v_fila[1])::uuid and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Ya no debe quedar ninguna afirmación de Jauralde citando un apartado «Villancico», que no
	-- existe en el libro.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2020 and a.localizador like '%«Villancico»%';
	if v_cuantas <> 0 then
		raise exception 'Quedan % afirmaciones de Jauralde citando un apartado «Villancico».', v_cuantas;
	end if;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_despues
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);
	if v_resumen_despues is distinct from v_resumen_antes then
		raise exception 'Ha cambiado el texto de alguna afirmación, y esta migración solo movía localizadores.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
