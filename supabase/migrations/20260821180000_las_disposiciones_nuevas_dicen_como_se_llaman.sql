-- Las disposiciones nuevas dicen cómo se llaman
--
-- Repaso de las seis formas creadas hoy, mirando sus fichas servidas. Dos cosas se leían mal.
--
-- 1. **Las disposiciones salían con la notación cruda por nombre.** En la copla castellana la
--    columna de rima imprimía «abba|cddc · habitual», «abab|cdcd · admitida»… y la regla que el IP
--    fijó al revisar la endecha real es que **cada fila se lea sola**: el nombre dice la
--    disposición, y la notación y el régimen la confirman al lado. Se nombran las doce que
--    faltaban, en la copla castellana, la copla de arte menor y la septilla. La doble sextilla ya
--    tenía el suyo —«Manriqueña»— y la octava aguda también.
--
-- 2. **Las seis arquitecturas de la octava aguda repetían la misma descripción palabra por
--    palabra**, de modo que la ficha decía seis veces lo mismo y no decía lo único que las
--    distingue, que es su medida y dónde está documentada. Cada una dice ahora la suya, con el
--    ejemplo que trae Jauralde cuando lo hay.

begin;

do $$
declare
	v_n integer;
	v_fila text[];
begin
	-- --------------------------------------------------- 1. Los nombres de las disposiciones
	foreach v_fila slice 1 in array array[
		array['copla_castellana', 'abbacddc', 'Las dos abrazadas'],
		array['copla_castellana', 'ababcdcd', 'Las dos cruzadas'],
		array['copla_castellana', 'abbacdcd', 'Abrazada y cruzada'],
		array['copla_castellana', 'ababcddc', 'Cruzada y abrazada'],
		array['copla_de_arte_menor', 'abbaacca', 'Abrazadas, con la exterior compartida'],
		array['copla_de_arte_menor', 'ababbaab', 'Cruzada y abrazada, sin estrenar rima'],
		array['copla_de_arte_menor', 'ababbccb', 'Cruzadas, con una rima compartida'],
		array['septilla', 'abbacca', 'Terceto a la rima exterior'],
		array['septilla', 'abbaccb', 'Terceto a la rima interior'],
		array['septilla', 'ababcbc', 'Cruzada, terceto alterno'],
		array['septilla', 'ababccb', 'Cruzada, terceto a la interior'],
		array['septilla', 'abababb', 'Terceto sin rima nueva']
	] loop
		update public.esquemas_rima er set nombre = v_fila[3]
		from public.arquitecturas_forma a, public.formas_metricas f
		where a.arquitectura_id = er.arquitectura_id
			and f.forma_id = a.forma_id
			and f.slug = v_fila[1]
			and er.slug = v_fila[2];
	end loop;

	-- Ninguna disposición de las seis formas nuevas se queda sin nombre.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug in ('copla_castellana', 'copla_de_arte_menor', 'septilla', 'oncena',
			'octava_aguda', 'doble_sextilla')
		and er.nombre is null;
	if v_n <> 0 then
		raise exception 'Quedan % disposiciones sin nombre en las formas nuevas.', v_n;
	end if;

	-- ------------------------------------------ 2. Cada arquitectura de la aguda dice la suya
	foreach v_fila slice 1 in array array[
		array['endecasilabica',
			'Ocho endecasílabos en dos semiestrofas de cuatro. Riman entre sí el cuarto y el octavo, '
			|| 'en aguda; los demás quedan a lo que traiga el poema. Es la modalidad de arte mayor, '
			|| 'la que la tradición llama octava aguda sin apellido.'],
		array['decasilabica',
			'La misma figura en decasílabos, que es la otra medida de arte mayor documentada: riman '
			|| 'entre sí el cuarto verso y el octavo, en aguda, y los demás quedan libres.'],
		array['octosilabica',
			'La más frecuente de las de arte menor, y la que suele llamarse octavilla aguda a secas: '
			|| 'ocho octosílabos con la rima aguda en el cuarto y el octavo. En ella está *El reo de '
			|| 'muerte* de Espronceda, que Jauralde llama también copla castellana aguda.'],
		array['heptasilabica',
			'Ocho heptasílabos con la rima aguda en los versos de cierre. Es la medida de *La orgía* '
			|| 'de Zorrilla, del pleno Romanticismo.'],
		array['hexasilabica',
			'Ocho hexasílabos con la rima aguda en los versos de cierre; se documenta también en el '
			|| 'periodo romántico.'],
		array['pentasilabica',
			'Ocho pentasílabos con la rima aguda en los versos de cierre. Es, con la octosilábica y '
			|| 'la heptasilábica, una de las tres medidas en que esta estrofa se cultivó sobre todo.']
	] loop
		update public.arquitecturas_forma a set descripcion = v_fila[2]
		from public.formas_metricas f
		where f.forma_id = a.forma_id and f.slug = 'octava_aguda' and a.slug = v_fila[1];
	end loop;

	-- Las seis dicen cosas distintas.
	select count(distinct a.descripcion) into v_n
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'octava_aguda' and a.activo;
	if v_n <> 6 then
		raise exception 'Las arquitecturas de la octava aguda dicen % cosas distintas, no seis.', v_n;
	end if;

	-- ------------------------------------------------------------------ Comprobación
	foreach v_fila slice 1 in array array[
		array['copla_castellana'], array['copla_de_arte_menor'], array['septilla'],
		array['octava_aguda'], array['oncena'], array['doble_sextilla']
	] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
