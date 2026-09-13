-- El villancico moderno de Navarro Tomás es un ejemplo aislado, no una modalidad general
--
-- La afirmación del villancico cerraba atribuyendo a Navarro Tomás, «como modalidad moderna
-- general», una cuarteta octosilábica seguida por un estribillo en cuarteta hexasílaba. No lo dice
-- en ninguno de los seis §§ que se le citan, y lo que sí dice lo contradice tres veces.
--
-- El § 494, el ejemplo moderno que da como forma clásica, describe la *Gacela del mercado
-- matutino* de García Lorca: «El estribillo es una cuarteta **heptasílaba**, el cuerpo de la
-- canción consiste en una redondilla octosílaba». O sea que **el estribillo va delante**, no
-- detrás, y es heptasílabo, no hexasílabo. Y el § 446, el otro ejemplo moderno —*Verde verderol*,
-- de Juan Ramón Jiménez—, lo llama expresamente «ejemplo aislado de esta antigua forma de canción
-- en el presente período»: lo contrario de una modalidad general.
--
-- Lo encontró la pasada A el 12 de septiembre de 2026 y se confirmó leyendo los dos §§ en el PDF
-- al comprobar la muestra. El resto de la afirmación, que es larga, está bien documentado, y la
-- lectura ciega la llama «la forma mejor y más extensamente documentada» de su lote: el defecto
-- era una sola cláusula final.
--
-- Se retira lo falso y se recoge en su lugar lo que la fuente sí dice, que es más: los dos
-- ejemplos con su estructura y la advertencia de que el moderno es aislado. El localizador no
-- cambia, porque ya citaba los §§ 446 y 494.
--
-- Texto anterior, por si hiciera falta:
--   «… ampliación o supresión del enlace y la vuelta, repeticiones parciales o totales y, como
--    modalidad moderna general, una cuarteta octosilábica seguida por un estribillo en cuarteta
--    hexasílaba.»

begin;

do $$
declare
	v_villancico constant uuid := 'cfc21591-c376-422c-bebb-66847d70869b';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	join public.formas_metricas fo using (forma_id)
	where a.afirmacion_id = v_villancico and f.anio = 1972 and fo.nombre = 'Villancico';
	if v_cuantas <> 1 then
		raise exception 'No encuentro la afirmación del villancico de Navarro Tomás.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Reconstruye su evolución desde la cantiga medieval y documenta una gran variedad histórica. '
		'Presenta como modelo preferente del siglo XVI el estribillo de tres versos, la mudanza en '
		'redondilla y el enlace, vuelta y represa; junto a abba registra abab y la forma asonantada '
		'abcb. Recoge estribillos de dos a siete versos, mudanzas excepcionales de seis, ampliación o '
		'supresión del enlace y la vuelta, y repeticiones parciales o totales. De los dos ejemplos '
		'modernos que recoge, el del § 494 —la *Gacela del mercado matutino* de García Lorca— lleva '
		'«estribillo… cuarteta heptasílaba» y «el cuerpo de la canción… redondilla octosílaba»; y del '
		'§ 446 —*Verde verderol*, de Juan Ramón Jiménez, con pareado de versos desiguales como '
		'estribillo— dice que es «ejemplo aislado de esta antigua forma de canción en el presente '
		'período».'
	where afirmacion_id = v_villancico;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que la cláusula falsa ya no está, que lo que la sustituye sí, y que no se ha perdido por el
	-- camino lo que la afirmación documentaba bien.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_villancico and resumen ilike '%modalidad moderna general%';
	if v_cuantas > 0 then
		raise exception 'Sigue ahí la modalidad moderna general.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_villancico
		and resumen ilike '%cuarteta heptasílaba%'
		and resumen ilike '%ejemplo aislado%';
	if v_cuantas <> 1 then
		raise exception 'No ha entrado lo que la fuente sí dice.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_villancico
		and resumen ilike '%cantiga medieval%'
		and resumen ilike '%estribillo de tres versos%';
	if v_cuantas <> 1 then
		raise exception 'Se ha perdido lo que la afirmación documentaba bien.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
