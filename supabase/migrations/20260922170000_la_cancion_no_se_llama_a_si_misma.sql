-- La canción no se llama a sí misma, y los piedi suelen medir lo mismo
--
-- Al partir la canción petrarquista (`20260922160000`), las tres denominaciones de la forma vieja
-- viajaron a la nueva forma **Canción**. Una de ellas sobra ahí: «Canción», de Morley y Bruerton,
-- informaba cuando la forma se llamaba «Canción petrarquista» y ahora repite su nombre. David la
-- retira el 18 de septiembre de 2026. Quedan «Canción a la italiana» y «Canción extensa», las dos
-- del *Diccionario*: la segunda es un término de Dorothy C. Clarke que el *Diccionario* recoge como
-- entrada de remisión a «canción a la italiana», y se conserva porque está en la fuente.
--
-- Y los dos piedi de la fronte dejan de medir «lo mismo» por norma: ninguna de las seis fuentes lo
-- exige —Caparrós y el *Diccionario* dicen «dos pies, normalmente de tres versos, unidos por la
-- rima»— y el dato tampoco lo obliga, porque las dos secciones admiten de 2 a 9 versos cada una sin
-- guarda que las iguale. La prosa pasa a decir lo que las fuentes dicen: suelen medir lo mismo.

begin;

do $$
declare
	v_cancion uuid;
	v_n integer;
begin
	select forma_id into v_cancion from public.formas_metricas where slug = 'cancion' and activo;
	if v_cancion is null then
		raise exception 'No está la forma «cancion».';
	end if;

	delete from public.denominaciones_metricas
	where forma_id = v_cancion and slug_normalizado = 'cancion';
	get diagnostics v_n = row_count;
	if v_n <> 1 then
		raise exception 'Se esperaba retirar una denominación y se retiraron %.', v_n;
	end if;

	if (select count(*) from public.denominaciones_metricas
		where forma_id = v_cancion
			and slug_normalizado in ('cancion_a_la_italiana', 'cancion_extensa')) <> 2 then
		raise exception 'La canción debía conservar «Canción a la italiana» y «Canción extensa».';
	end if;

	update public.formas_metricas
	set definicion = replace(definicion,
		'una **fronte**, hecha de dos *piedi* de igual medida y unidos por la rima,',
		'una **fronte**, hecha de dos *piedi* unidos por la rima, que suelen medir lo mismo,')
	where forma_id = v_cancion
		and definicion like '%dos *piedi* de igual medida y unidos por la rima%';
	get diagnostics v_n = row_count;
	if v_n <> 1 then
		raise exception 'La definición de la canción no decía «de igual medida» donde se esperaba.';
	end if;

	update public.estructuras_secciones s
	set nota = case s.slug
		when 'fronte' then 'Primera parte de la estancia, partida en dos piedi unidos por la rima, que suelen medir lo mismo. Cuánto miden lo fija cada canción.'
		when 'primer_pie' then 'Los dos piedi van unidos por la rima —comparten sus clases, no necesariamente en el mismo orden— y suelen medir lo mismo.'
		when 'segundo_pie' then 'Comparte las rimas del primero, en el mismo orden o permutadas, y suele medir lo que él.'
	end
	from public.arquitecturas_forma a
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = v_cancion
		and a.slug = 'estancias_consonantes_variables'
		and s.slug in ('fronte', 'primer_pie', 'segundo_pie');
	get diagnostics v_n = row_count;
	if v_n <> 3 then
		raise exception 'Se esperaban tres notas de sección y se reescribieron %.', v_n;
	end if;

	perform public.get_forma_metrica_publica_jerarquica('cancion');
end $$;

commit;
