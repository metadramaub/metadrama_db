-- Quilis tiene una estrofa de ocho versos, no dos, y sus cautelas vuelven a su sitio
--
-- Las siete afirmaciones de Quilis que la auditoría dejó en pie. David aprobó cada texto con el
-- viejo y el nuevo delante, el 15 y el 16 de septiembre de 2026.
--
-- ══ El par de las estrofas de ocho versos
--
-- Las fichas de la copla castellana y la de arte menor decían lo mismo en espejo: «La trata bajo
-- "octavilla", junto a la copla de arte menor» y «La trata bajo "octavilla", junto a la copla
-- castellana». **Quilis tiene una sola estrofa de ocho versos, la octavilla.** Fuimos nosotros
-- quienes partimos su único pasaje en dos fichas para que encajara con nuestras dos formas, y
-- luego cada una tuvo que explicar que estaba «junto a» la otra: el mismo párrafo contado dos
-- veces, y ninguna de las dos diciendo lo que él dice.
--
-- Y no es solo que no use el nombre. Los dos esquemas que da —«la combinación de su rima suele
-- ser: `abbecdde`, o `ababbccb`», leído en el PDF, hoja 55, p. 108— **comparten rima entre las dos
-- mitades**: la `e` de los versos cuarto y octavo en el primero, la `b` en el segundo. Compartir
-- rima es exactamente lo que el catálogo usa para excluir la copla castellana, que se define por
-- estrenar cuatro rimas independientes. Su octavilla no es la castellana con otro nombre: es la
-- otra estrofa.
--
--   8e712f47  Copla castellana → **silencio de una línea**, sin describir nada. Una ficha de
--             ausencia necesita decir cuál es la ausencia y con qué se comprueba, y nada más.
--   77da08e6  Copla de arte menor → se queda con la descripción entera, que es donde sus esquemas
--             caen de verdad. Sale «junto a la copla castellana» y sale «la de tres rimas», que
--             era taxonomía nuestra puesta en su boca.
--
-- ══ Dos endurecimientos
--
--   0c07cb3f  Décima. Quilis escribe «**Generalmente**, el tema de la estrofa se plantea en los
--             cuatro primeros versos» y la ficha lo daba como si fuera siempre.
--   f4f86489  Lira. «**Parece que** este tipo de estrofa fue ideada en Italia por BERNARDO DE
--             TASSO»: un dato de autoría histórica dado como conjetura, que la ficha convertía en
--             atribución firme.
--
-- ══ Una mezcla, una invención y media verdad
--
--   45f13be6  Copla manriqueña. La ficha le atribuía a las Coplas de Manrique el esquema `aabccb`.
--             Ese es el de «A sus ojos», de Unamuno, que Quilis cita dos párrafos después como
--             variante moderna con los quebrados en el segundo y el quinto verso. El de «¿Qué se
--             hicieron las damas…» lo marca él verso a verso delante de cada línea, y es `abcabc`.
--   e708120e  Octava aguda. La ficha decía que «no la separa de las demás estrofas de ocho versos:
--             las trata todas bajo "octavilla"». Es falso: tiene epígrafe y nombre propios en el
--             § 5.4.7.3, «Octava italiana u octava aguda», p. 107.
--   236c4eee  Oncena. «No registra las estrofas de once versos» es cierto —«oncena» y «undécima»
--             tienen cero apariciones—, pero «pasa de las de diez a las de doce» no: tampoco hay
--             estrofas de doce. Su clasificación termina en las de diez y sigue el capítulo del
--             poema.
--
-- **Sobre cómo se redactan estas correcciones.** Dos borradores decían cosas como «da el origen
-- como conjetura y no como hecho» o «le da epígrafe y nombre propios», que solo se entienden si
-- uno ha leído la versión anterior —un lector que no existe—. El texto de una afirmación dice lo
-- que la fuente dice; las ausencias se señalan y las presencias se cuentan y ya está.

begin;

do $$
declare
	v_castellana constant uuid := '8e712f47-d5db-4bdb-af0a-568a88a71dec';
	v_artemenor constant uuid := '77da08e6-6402-468f-9b74-3e7c74846a46';
	v_manriquena constant uuid := '45f13be6-e13e-420e-8e53-b9aa0bcff2b5';
	v_decima constant uuid := '0c07cb3f-5168-49ca-87cb-7096467f38a0';
	v_lira constant uuid := 'f4f86489-f0e1-409e-975f-0626617c13ab';
	v_oncena constant uuid := '236c4eee-6924-4a37-b077-7de9025f09b1';
	v_octava constant uuid := 'e708120e-9bd2-491c-ad72-6ccc7f48d617';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que las siete están donde se cree antes de tocar ninguna.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1969
		and a.afirmacion_id in (v_castellana, v_artemenor, v_manriquena, v_decima, v_lira, v_oncena, v_octava);
	if v_cuantas <> 7 then
		raise exception 'Esperaba 7 afirmaciones de Quilis 1969 y encuentro %.', v_cuantas;
	end if;

	-- Y que las dos del par de ocho versos siguen diciéndose la una a la otra.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where (afirmacion_id = v_castellana and resumen like '%junto a la copla de arte menor%')
		or (afirmacion_id = v_artemenor and resumen like '%junto a la copla castellana%');
	if v_cuantas <> 2 then
		raise exception 'El par de las estrofas de ocho versos no está como espero.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'No registra una estrofa de ocho versos con cuatro rimas independientes: su única estrofa '
			'de ocho versos es la octavilla, cuyas dos combinaciones de rima comparten rima entre las '
			'dos mitades.',
		localizador = '§ 5.4.7.4, «Octavilla», p. 108'
	where afirmacion_id = v_castellana;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Su estrofa de ocho versos es la octavilla, que hace derivar de la duplicación de una '
			'redondilla o de la combinación de dos, porque durante la Edad Media la redondilla «no tuvo '
			'vida independiente». De su rima dice que «suele ser» `abbecdde` o `ababbccb`, y la '
			'ejemplifica con una estrofa del Marqués de Santillana. Añade que cuando los octosílabos '
			'alternan con versos de cuatro sílabas se originan las coplas de pie quebrado, muy '
			'difundidas en el siglo XV y principios del XVI, y cita el *Diálogo de Bías contra Fortuna* '
			'y los *Proverbios morales* de Santillana.',
		localizador = '§ 5.4.7.4, pp. 108-109'
	where afirmacion_id = v_artemenor;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Lo trata como la variante más conocida de la sextilla y le da tres nombres a la vez: '
			'«Copla de pie quebrado, Copla de Jorge Manrique o Estrofa manriqueña». La describe como '
			'estrofa de seis versos que difiere de la sextilla común en que el tercero y el sexto son '
			'tetrasílabos en lugar de octosílabos, y le reconoce «antigua tradición románica», con las '
			'primeras muestras castellanas en el Arcipreste de Hita. Cita «¿Qué se hicieron las '
			'damas…», cuyo esquema marca verso a verso como `abcabc`, y recoge como variante moderna la '
			'de Unamuno en *A sus ojos*, con los quebrados en el segundo y el quinto y rima `aabccb`. '
			'La agrupación de doce no recibe en su exposición nombre ni epígrafe propio.'
	where afirmacion_id = v_manriquena;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Describe la estrofa como dos redondillas de rima abrazada, abba y cddc, unidas por dos '
			'versos de enlace que repiten la rima última de la primera y la primera de la segunda. '
			'Añade que **generalmente** el tema se plantea en los cuatro primeros versos y que la '
			'transición del pensamiento cae en el quinto, y que por su perfección se ha comparado la '
			'estrofa con el soneto.'
	where afirmacion_id = v_decima;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'Da como origen posible de la estrofa a Bernardo de Tasso en Italia, y su introducción en '
			'España a Garcilaso de la Vega: «parece que este tipo de estrofa fue ideada en Italia por '
			'BERNARDO DE TASSO, e introducida en España por GARCILASO DE LA VEGA».'
	where afirmacion_id = v_lira;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'No registra las estrofas de once versos. Su clasificación por número de versos termina en '
			'las de diez —copla real, décima y ovillejo— y de ahí pasa al capítulo del poema, sin '
			'epígrafe para las de once ni para las de doce.',
		localizador = '§ 5.4, «Formas estróficas», que termina en el § 5.4.8'
	where afirmacion_id = v_oncena;

	update public.afirmaciones_fuentes_metricas
	set resumen =
			'La llama «octava italiana u octava aguda», la fecha en el Neoclasicismo y sitúa su mayor '
			'difusión y popularidad en el Romanticismo. Da como combinación de su rima `ABBC''DEEC`, '
			'con el cuarto y el octavo versos agudos, y anota que a veces son heptasílabos en lugar de '
			'endecasílabos.',
		localizador = '§ 5.4.7.3, p. 107'
	where afirmacion_id = v_octava;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que ya no queda nada de lo que se retira.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_castellana, v_artemenor, v_manriquena, v_decima, v_lira, v_oncena, v_octava)
		and (resumen like '%junto a la copla%'
			or resumen like '%la de tres rimas%'
			or resumen like '%las trata todas bajo%'
			or resumen like '%a las de doce sin epígrafe intermedio%');
	if v_cuantas > 0 then
		raise exception 'Sigue habiendo % afirmaciones con alguna de las cláusulas retiradas.', v_cuantas;
	end if;

	-- Que las dos cautelas están.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where (afirmacion_id = v_decima and resumen like '%**generalmente**%')
		or (afirmacion_id = v_lira and resumen like '%parece que este tipo de estrofa%');
	if v_cuantas <> 2 then
		raise exception 'Alguna de las dos cautelas no ha entrado: cuadran %.', v_cuantas;
	end if;

	-- Que el par de ocho versos quedó repartido: el silencio corto en la castellana y la
	-- descripción en la de arte menor, no las dos cosas en las dos.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_castellana
		and resumen like '%No registra una estrofa de ocho versos con cuatro rimas independientes%'
		and resumen not like '%Bías contra Fortuna%'
		and length(resumen) < 260;
	if v_cuantas <> 1 then
		raise exception 'La copla castellana no ha quedado como silencio corto.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_artemenor
		and resumen like '%abbecdde%'
		and resumen like '%Bías contra Fortuna%'
		and resumen like '%Marqués de Santillana%';
	if v_cuantas <> 1 then
		raise exception 'La copla de arte menor no ha quedado con la descripción entera.';
	end if;

	-- Y los esquemas que cada una tiene que llevar.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where (afirmacion_id = v_manriquena and resumen like '%`abcabc`%' and resumen like '%`aabccb`%')
		or (afirmacion_id = v_octava and resumen like '%ABBC''DEEC%');
	if v_cuantas <> 2 then
		raise exception 'Falta algún esquema de rima: cuadran %.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
