-- La canción empieza en nueve: tres formas donde había una, y la frontera con las aliradas
--
-- Hasta hoy «Canción petrarquista» era una sola forma con tres arquitecturas —«Estancias
-- consonantes variables», «Regular de 13 versos» y «Sin rima, con pareado final»— y su estancia
-- admitía de cinco a veinte versos, que es el intervalo de la definición de Morley y Bruerton y el
-- de ninguna otra fuente. Con eso una estrofa de cinco a ocho versos de siete y once era a la vez
-- lira, sexteto-lira, septeto-lira u octava-lira y canción, y lo que separaba una cosa de otra era
-- el eslabón, un criterio que ninguna de las seis fuentes usa y que las dos que lo describen dicen
-- expresamente que no es obligatorio.
--
-- Decidido con David el 17 de septiembre de 2026, contrastando las seis fuentes y, para el techo,
-- el «Estudio de las estrofas» de Morley y Bruerton (pp. 175–178), que no está volcado a texto:
--
--   · **Canción** (`cancion`, nueva) recibe entera la arquitectura de estancias variables, con la
--     estancia en **9–15** versos. El suelo es el de cuatro de las seis fuentes y separa la canción
--     de las aliradas; el techo es el del corpus dramático: los trece tipos de canción rimada que
--     Morley y Bruerton cuentan en Lope van de siete a quince, y la más larga es la «mezclada» de
--     13, 13, 13, 14 y 15 de *El verdadero amante*. Fronte y sirima pasan a opcionales, como ya lo
--     era el eslabón: una estancia sin partición reconocible sigue siendo estancia.
--   · **Canción petrarquista** (`cancion_petrarquista`, conserva slug y URL) se queda solo con la
--     regular de trece. Las fuentes usan «petrarquista» como sinónimo de «canción a la italiana»;
--     aquí el apellido se reserva para la estancia que viene literalmente de Petrarca, y la ficha
--     lo dice.
--   · **Canción sin rima** (`cancion_sin_rima`, nueva) recibe «Sin rima, con pareado final». Su
--     única fuente le da entrada aparte y la llama también «Canción libre»; sus estancias van de
--     **7 a 20** —*La pastoral de Jacinto*, «13 × 6 más 14 más 20»— y recibe un remate opcional
--     como las otras dos.
--   · **El remate no es obligatorio** en ninguna: Morley y Bruerton dan la regular de Lope «sin
--     envío».
--   · **La frontera con las aliradas es la extensión, y de nueve en adelante la articulación**: una
--     estrofa de nueve o diez de siete y once consonantes es canción si una fronte de dos *piedi*
--     unidos por la rima y una sirima la articulan como estancia, y novena- o décima-lira si se
--     considera una estrofa sin partes. Un pareado final no constituye por sí solo una sirima. Las
--     dos disposiciones de nueve de Navarro Tomás admiten ambas lecturas y no se declaran como
--     patrón de ninguna forma.
--   · **La lira se explica como estancia recortada** —«media estancia», dice el *Diccionario*— y
--     de ahí que la serie alirada creciera hasta el tamaño en que empieza la estancia. Se cuenta en
--     la lira y en la canción; las demás aliradas ya remiten a ello.
--
-- Las ocho anotaciones que cuelgan de «Estancias consonantes variables» cambian de forma con su
-- arquitectura. Son todas de obras de prueba y en dos de ellas las estancias miden cinco y ocho:
-- se regeneran con `npm run aplicar:guiones` en el mismo cambio, porque la base no valida la
-- extensión de una sección sobre lo anotado y no hay nada que la migración pueda corregir sola.
--
-- El plan completo, con cada decisión y su fuente:
-- docs/dominio-metrico/historico/cancion-y-liras-2026-09-17.md

begin;

do $$
declare
	v_petr uuid;
	v_cancion uuid;
	v_sin_rima uuid;
	v_lira uuid;
	v_silva uuid;
	v_cuarteto_lira uuid;
	v_septeto_lira uuid;
	v_octava_lira uuid;
	v_novena_lira uuid;
	v_decima_lira uuid;
	v_arq_var uuid;
	v_arq_reg uuid;
	v_arq_sr uuid;
	v_termino_petr uuid;
	v_italiana constant uuid := 'af269fe5-f67f-4991-9dc2-49ea12c40abd';
	v_mb constant uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_navarro constant uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dicc constant uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_n integer;
	v_antes bigint;
	v_despues bigint;
	v_nota_remate text;
	v_s record;
begin
	-- ══════════════════════════════════════════════════════════ Lo que tiene que estar
	select forma_id, origen_termino_id into v_petr, v_termino_petr
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;
	select forma_id into v_lira from public.formas_metricas where slug = 'lira' and activo;
	select forma_id into v_silva from public.formas_metricas where slug = 'silva' and activo;
	select forma_id into v_cuarteto_lira from public.formas_metricas where slug = 'cuarteto_lira' and activo;
	select forma_id into v_septeto_lira from public.formas_metricas where slug = 'septeto_lira' and activo;
	select forma_id into v_octava_lira from public.formas_metricas where slug = 'octava_lira' and activo;
	select forma_id into v_novena_lira from public.formas_metricas where slug = 'novena_lira' and activo;
	select forma_id into v_decima_lira from public.formas_metricas where slug = 'decima_lira' and activo;
	if v_petr is null or v_lira is null or v_silva is null or v_cuarteto_lira is null
		or v_septeto_lira is null or v_octava_lira is null or v_novena_lira is null
		or v_decima_lira is null then
		raise exception 'Falta alguna de las formas que esta migración toca.';
	end if;
	if v_termino_petr is null then
		raise exception 'La canción petrarquista no declara término legado, y esta migración lo traslada.';
	end if;

	select arquitectura_id into v_arq_var from public.arquitecturas_forma
	where forma_id = v_petr and slug = 'estancias_consonantes_variables' and activo;
	select arquitectura_id into v_arq_reg from public.arquitecturas_forma
	where forma_id = v_petr and slug = 'regular_13_versos' and activo and principal;
	select arquitectura_id into v_arq_sr from public.arquitecturas_forma
	where forma_id = v_petr and slug = 'sin_rima_con_pareado_final' and activo;
	if v_arq_var is null or v_arq_reg is null or v_arq_sr is null then
		raise exception 'La canción petrarquista no tiene las tres arquitecturas que esta migración reparte.';
	end if;

	if exists (select 1 from public.formas_metricas where slug in ('cancion', 'cancion_sin_rima')) then
		raise exception 'Ya existe «cancion» o «cancion_sin_rima»; esta migración daba por hecho que no.';
	end if;

	-- Los valores vivos exactos que se van a cambiar.
	select count(*) into v_n from public.anotaciones_metricas where arquitectura_id = v_arq_var;
	if v_n <> 8 then
		raise exception 'Se esperaban 8 anotaciones de estancias variables y hay %.', v_n;
	end if;
	if exists (
		select 1 from public.anotaciones_metricas a
		join public.secuencias_metricas s using (secuencia_id)
		join public.obras o using (obra_id)
		where a.arquitectura_id = v_arq_var and o.titulo not ilike '%(prueba)%'
	) then
		raise exception 'Hay una canción anotada en una obra que no es de prueba: hay que mirarla antes de mover nada.';
	end if;
	if not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq_var and slug = 'estancia' and versos_min = 5 and versos_max = 20
	) or not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq_var and slug = 'fronte' and repeticiones_min = 1
	) or not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq_var and slug = 'sirima' and repeticiones_min = 1
	) or not exists (
		select 1 from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq_var and slug = 'medida_estancia'
			and selecciones_min = 5 and selecciones_max = 20
	) then
		raise exception 'La arquitectura de estancias variables no tiene los rangos 5–20 y 1–1 que esta migración cambia.';
	end if;
	if not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq_sr and slug = 'estancia' and versos_min is null and versos_max is null
	) or exists (
		select 1 from public.estructuras_secciones where arquitectura_id = v_arq_sr and slug = 'remate'
	) then
		raise exception 'La arquitectura sin rima no está como esta migración la esperaba.';
	end if;
	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_petr) <> 6 then
		raise exception 'La canción petrarquista debía tener seis afirmaciones.';
	end if;

	select nota into v_nota_remate from public.estructuras_secciones
	where arquitectura_id = v_arq_var and slug = 'remate';

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ══════════════════════════════════════════════════════════ Las dos formas nuevas
	insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
	values (
		'cancion', 'Canción',
		$p$Composición en estancias: una estrofa larga de heptasílabos y endecasílabos con rima consonante que el poeta dispone a su gusto en la primera y repite sin cambio en todas las demás, tres por lo menos. La estancia mide de nueve a quince versos y suele ordenarse en dos partes: una **fronte**, hecha de dos *piedi* de igual medida y unidos por la rima, y una **sirima** de rimas nuevas, que a menudo se abre con un verso —el **eslabón**, *volta* o *chiave*— que retoma la rima con que se cerró la fronte. Esa ordenación es frecuente, no obligatoria: una estancia sin eslabón, o sin partición reconocible, sigue siendo estancia. La composición suele cerrarse con un fragmento de estancia más breve, el **remate**, envío o *commiato*, en el que el poeta se dirige a menudo a la propia canción; tampoco él es obligatorio. De su estancia salió, recortada a cinco versos, la lira, y de la lira la serie de estrofas aliradas, que tienen su misma materia sin su ordenación y que crecieron hasta rozar su tamaño: por eso los tratados llaman «canción alirada» a la composición hecha con ellas. «Canción» a secas designa esta forma de tradición italiana, no la canción medieval del siglo XV.$p$,
		'composicion', 'forma', true
	)
	returning forma_id into v_cancion;

	insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
	values (
		'cancion_sin_rima', 'Canción sin rima',
		$p$Composición en estancias de heptasílabos y endecasílabos sin rima, salvo el pareado consonante con que cada estancia termina. La estancia mide de siete a veinte versos y repite en todas las demás la distribución de medidas que fijó la primera; el pareado final es lo que hace estancia a cada estrofa y composición al conjunto. Es forma del teatro: los tratados de métrica no la registran, porque describen la canción como forma siempre rimada, y se conoce por el recuento de las estrofas sin rima de las comedias.$p$,
		'composicion', 'forma', true
	)
	returning forma_id into v_sin_rima;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_cancion, v_italiana), (v_sin_rima, v_italiana);

	-- ══════════════════════════════════════════════════════════ La petrarquista, reducida
	update public.formas_metricas
	set definicion = $p$Canción cuya estancia es la regular de trece versos, `abCabC:cdeeDfF` sobre la medida `7 7 11 7 7 11 7 7 7 7 11 7 11`, repetida tres veces por lo menos, con remate o sin él. Es la estancia que Garcilaso tomó de la canción undécima de Petrarca para su segunda égloga, la que Herrera empleó en su canción quinta y la más frecuente en la comedia del Siglo de Oro. Su fronte son dos *piedi* de tres versos unidos por la rima, `abC` y `abC`; el séptimo verso, heptasílabo, rima con el último de la fronte y abre ya la sirima, y por eso es el eslabón; la sirima cierra con dos pareados y un endecasílabo suelto de remate de estancia. El nombre, que los tratados aplican a la canción italiana en general, designa aquí solo esta estancia, la que viene literalmente de Petrarca.$p$,
		origen_termino_id = null
	where forma_id = v_petr;

	update public.formas_metricas set origen_termino_id = v_termino_petr where forma_id = v_cancion;

	-- ══════════════════════════════════════════════════════════ Las arquitecturas se reparten
	-- Primero la arquitectura, después las anotaciones: `validar_anotacion_metrica` exige que la
	-- arquitectura pertenezca a la forma de la anotación.
	update public.arquitecturas_forma
	set forma_id = v_cancion, principal = true, orden = 1,
		descripcion = $p$El caso general: la estancia se inventa para cada canción y no hay dos iguales. Mide de nueve a quince versos: el suelo la separa de las estrofas aliradas, y el techo es el de la canción dramática. Fuera del teatro las hay más largas —la canción cuarta de Garcilaso tiene ocho estancias de veinte versos—, y quedan en las fuentes de esta ficha aunque el catálogo no las admita.$p$
	where arquitectura_id = v_arq_var;

	update public.anotaciones_metricas set forma_id = v_cancion where arquitectura_id = v_arq_var;

	update public.arquitecturas_forma
	set forma_id = v_sin_rima, principal = true, modalidad = 'habitual', orden = 1,
		descripcion = $p$Estancia de siete a veinte versos de siete y once sílabas, sin rima salvo el pareado consonante con que termina; la distribución de medidas la fija la primera estancia y la repiten las demás. Lo único variable es la medida de cada verso y, cuando se sostiene, la terminación esdrújula.$p$
	where arquitectura_id = v_arq_sr;

	update public.arquitecturas_forma
	set orden = 1,
		descripcion = $p$Trece versos, `7 7 11 7 7 11 7 7 7 7 11 7 11`, con la rima `abCabC:cdeeDfF`: fronte de dos *piedi* de tres versos, eslabón heptasílabo y sirima de seis versos con dos pareados y endecasílabo final. Medida y rima están fijas en todas las posiciones, de modo que la norma no deja nada por elegir; solo el remate, cuando lo hay, varía en extensión.$p$
	where arquitectura_id = v_arq_reg;

	-- ══════════════════════════════════════════════════════════ Estancias variables: 9–15, partición opcional
	update public.estructuras_secciones set versos_min = 9, versos_max = 15
	where arquitectura_id = v_arq_var and slug = 'estancia';
	update public.estructuras_secciones set repeticiones_min = 0, versos_max = 14,
		nota = $p$Primera parte de la estancia, partida en dos piedi de igual medida y unidos por la rima. Cuánto miden lo fija cada canción.$p$
	where arquitectura_id = v_arq_var and slug = 'fronte';
	update public.estructuras_secciones set repeticiones_min = 0, versos_max = 11
	where arquitectura_id = v_arq_var and slug = 'sirima';
	update public.estructuras_secciones set versos_max = 15
	where arquitectura_id = v_arq_var and slug = 'remate';
	update public.estructuras_secciones
	set nota = $p$Los dos piedi miden lo mismo y van unidos por la rima: comparten sus clases, no necesariamente en el mismo orden.$p$
	where arquitectura_id = v_arq_var and slug = 'primer_pie';
	update public.estructuras_secciones
	set nota = $p$Mide lo que el primero y comparte sus rimas, en el mismo orden o permutadas.$p$
	where arquitectura_id = v_arq_var and slug = 'segundo_pie';
	update public.estructuras_secciones
	set nota = $p$Verso que abre la sirima retomando la rima con que se cerró la fronte —la *chiave* o *volta*—. Habitual, no obligatorio: una estancia sin él no deja de serlo.$p$
	where arquitectura_id = v_arq_var and slug = 'eslabon';
	update public.grupos_eleccion_metrica set selecciones_min = 9, selecciones_max = 15
	where arquitectura_id = v_arq_var and slug = 'medida_estancia';

	-- ══════════════════════════════════════════════════════════ Sin rima: 7–20 y remate
	update public.estructuras_secciones set versos_min = 7, versos_max = 20
	where arquitectura_id = v_arq_sr and slug = 'estancia';
	update public.estructuras_secciones set versos_min = 5
	where arquitectura_id = v_arq_sr and slug = 'cuerpo';
	update public.grupos_eleccion_metrica set selecciones_min = 7, selecciones_max = 20
	where arquitectura_id = v_arq_sr and slug = 'medida_estancia';
	insert into public.estructuras_secciones
		(arquitectura_id, seccion_padre_id, tipo_seccion, slug, nombre, orden,
		 repeticiones_min, repeticiones_max, versos_min, versos_max, nota,
		 primera_realizacion_define_patron)
	values
		(v_arq_sr, null, 'remate', 'remate', 'Remate o envío', 2, 0, 1, 1, 20, v_nota_remate, false);

	-- ══════════════════════════════════════════════════════════ Denominaciones
	update public.denominaciones_metricas set forma_id = v_cancion where forma_id = v_petr;
	insert into public.denominaciones_metricas (forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values
		(v_petr, 'Canción regular', 'cancion_regular', false, v_mb),
		(v_sin_rima, 'Canción libre', 'cancion_libre', false, v_mb),
		(v_lira, 'Media estancia', 'media_estancia', false, v_dicc);
	update public.denominaciones_metricas set fuente_id = v_dicc
	where forma_id = v_decima_lira and slug_normalizado = 'decima_estancia' and fuente_id is null;

	-- ══════════════════════════════════════════════════════════ Afirmaciones
	-- Las cinco que describen la canción en general se van con ella; la de Morley y Bruerton se
	-- reescribe con el «Estudio de las estrofas», que es donde está la horquilla real.
	update public.afirmaciones_fuentes_metricas set forma_id = v_cancion
	where forma_id = v_petr and fuente_id <> v_mb;
	update public.afirmaciones_fuentes_metricas
	set forma_id = v_cancion,
		localizador = 'Cap. V, «Canción (Canzone)», p. 40, y «Estudio de las estrofas», «Canción», pp. 175-176',
		resumen = $p$Definen la canción como versos de siete y once sílabas agrupados en estrofas «de 5 a 20 versos», con un tipo de rima fijo e idéntico en cada estrofa de un mismo pasaje, y advierten que rara vez se encuentra un pasaje de rima mezclada. Su relación de los «trece tipos diferentes de estrofa de canción» que Lope empleó va, sin embargo, de siete a quince versos: de siete, `aBabBcC` y `AabBCdC`; de ocho, `ABCABCDD` y `abbaCcDD`; de nueve, `aBaBbcddC`; de diez, `aBaBcdcCd`; de once, `aXa:bbcddCeE` y `ABCABCcdDEE`; y una «mezclada» de 13, 13, 13, 14 y 15 versos en *El verdadero amante*. Ninguno de esos tipos aparece en más de una comedia, todos son anteriores a 1620, y Lope «fue más aficionado a ella en los años anteriores a 1604 que después».$p$
	where forma_id = v_petr and fuente_id = v_mb;

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	values
	(v_mb, v_petr, 'Cap. V, «Canción (Canzone)», p. 40, y «Estudio de las estrofas», «Canción», pp. 175-177',
		$p$«La más frecuente, con mucho, es la estrofa de 13 versos de la *Canzone XI* de Petrarca (“Chiare, fresche e dolci acque”): abCabC:cdeeDfF, sin envío. Usamos la palabra “regular” para referirnos a ella». La encuentran en dieciséis comedias de su Tabla I y otras dieciséis de la Tabla II, «normalmente para monólogo», con ejemplos de diálogo, y las últimas comedias fechadas en las que aparece no son posteriores a 1620.$p$,
		'alta'),
	(v_navarro, v_petr, '§ 108, pp. 205-206',
		$p$Documenta que la estancia `abCabC:cdeeDfF` de la segunda égloga de Garcilaso «tenía por modelo la de la canción undécima del Petrarca», que Herrera la usó y que fue imitada después en numerosas ocasiones; y que las canciones de Garcilaso son en su mayor parte de no más de cuatro o cinco estancias de trece versos.$p$,
		'alta'),
	(v_mb, v_sin_rima, 'Cap. V, «Canción sin rima», p. 41, y «Estudio de las estrofas», «Canción sin rima», pp. 177-178',
		$p$«La estrofa sin rima, que llamamos aquí Canción Libre o Sin Rima»: versos italianos de siete y once sílabas sin rima, «menos en el pareado final». La usaron en Italia Ludovico Martelli, en castellano Jerónimo Bermúdez en *Nise laureada* (1577) y Lope de Vega, «y por ningún otro poeta español que sepamos». Sus estancias en Lope van de siete a veinte versos —*La pastoral de Jacinto*, «13 × 6 más 14 más 20»—, en *La fábula de Perseo* van «13, 14, esdrújulos», y no hay ningún caso posterior a 1611: «parece que este tipo de estrofa fue una innovación que no gustó». Remiten a un estudio de Morley sobre las estrofas sin rima en las comedias de Lope, Coimbra, 1934.$p$,
		'alta');

	-- ══════════════════════════════════════════════════════════ Relaciones
	update public.forma_relaciones
	set forma_origen_id = v_cancion,
		nota = $p$Por debajo de los nueve versos una estrofa de heptasílabos y endecasílabos consonantes, repetida sin cambio, es alirada, y la lira es la menor de esas estrofas después del cuarteto-lira: una estancia reducida a su mínimo. Es el límite en el que coinciden cuatro de las seis fuentes, y el único que Jauralde Pou razona, al situar la estancia «normalmente por encima de los ocho versos, para diferenciarla de las liras».$p$
	where forma_origen_id = v_petr and forma_destino_id = v_lira and tipo_relacion = 'contrasta_con';

	update public.forma_relaciones set forma_origen_id = v_cancion
	where forma_origen_id = v_petr and forma_destino_id = v_silva and tipo_relacion = 'contrasta_con';

	update public.forma_relaciones
	set forma_destino_id = v_cancion,
		nota = $p$A partir de los nueve versos las dos formas coinciden en materia y en extensión y solo se distinguen por la articulación interna: la estancia se compone de una fronte de dos *piedi* unidos por la rima y una sirima de rimas nuevas; la décima-lira es una estrofa sin partes. El pareado final no constituye por sí solo una sirima. El patrón `aBaBcDcDeE` que el catálogo recoge repite en sus versos quinto a octavo la figura de los cuatro primeros, pero con rimas nuevas, y por eso no forma fronte.$p$
	where forma_origen_id = v_decima_lira and forma_destino_id = v_petr and tipo_relacion = 'relacionada_con';

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values
	(v_petr, v_cancion, 'subtipo_de',
		$p$La estancia regular de trece versos, `abCabC:cdeeDfF`, es la realización más frecuente de la canción y se registra aparte porque su extensión es fija donde la de la canción varía; una arquitectura no cambia la extensión de la unidad de su forma. Las fuentes usan «petrarquista» como sinónimo de «canción a la italiana»: aquí el apellido se reserva para la estancia que viene literalmente de Petrarca, y los nombres generales se registran en la canción.$p$),
	(v_sin_rima, v_cancion, 'contrasta_con',
		$p$Misma materia, misma repetición del patrón que fijó la primera estancia y mismo cierre en pareado; lo que las separa es el régimen. La canción es siempre consonante y esta no rima salvo en el pareado final. Solo Morley y Bruerton la registran, y la registran con epígrafe propio.$p$),
	(v_sin_rima, v_silva, 'contrasta_con',
		$p$Las dos combinan heptasílabos y endecasílabos y las dos pueden no rimar. La diferencia es que aquí hay estancia: una estrofa de medida fijada por la primera, repetida sin cambio y cerrada cada vez por un pareado, con lo que el conjunto es una composición; la silva es una serie sin unidad que se repita, y su pareado, cuando lo hay, cierra la serie y no una estrofa.$p$),
	(v_cancion, v_novena_lira, 'contrasta_con',
		$p$A partir de los nueve versos las dos formas coinciden en materia y en extensión —heptasílabos y endecasílabos consonantes, repetidos sin cambio de una estrofa a otra— y solo se distinguen por la articulación interna: la estancia se compone de una fronte de dos *piedi* unidos por la rima y una sirima de rimas nuevas, con eslabón o sin él; la novena-lira es una estrofa sin partes. El pareado final no constituye por sí solo una sirima, puesto que cierra también las estrofas aliradas menores. Las dos disposiciones de nueve versos que Navarro Tomás describe entre las aliradas, `abCabCcdD` y `AbCAbCcdD`, admiten ambas lecturas.$p$),
	(v_cancion, v_octava_lira, 'contrasta_con',
		$p$Las dos formas comparten la materia, y la extensión es el criterio que las separa: el catálogo sitúa el límite inferior de la estancia en nueve versos, de acuerdo con cuatro de sus seis fuentes, de modo que una estrofa de ocho de heptasílabos y endecasílabos consonantes, repetida sin cambio, se registra como octava-lira con independencia de su disposición de rimas. La delimitación no es unánime en la bibliografía: Morley y Bruerton cuentan como canción dos estrofas de ocho de Lope de Vega, `abbaCcDD` en *El castigo sin venganza*, que aquí corresponde a la octava-lira, y `ABCABCDD` en *Barlaán y Josafat*, que por ser toda de endecasílabos queda fuera de la serie alirada.$p$),
	(v_cancion, v_septeto_lira, 'contrasta_con',
		$p$Por debajo de los nueve versos una estrofa de heptasílabos y endecasílabos consonantes, repetida sin cambio, pertenece a la serie alirada. Morley y Bruerton cuentan como canción dos estrofas de siete de Lope de Vega: `aBabBcC` en *Vida y muerte del rey Bamba*, que es la disposición documentada del septeto-lira, y `AabBCdC` en *La condesa Matilde*, siete versos cerrados en endecasílabo que su norma admite.$p$);

	update public.forma_relaciones
	set nota = $p$Las dos cierran la serie alirada por arriba y las dos caen ya en la franja en la que la canción es posible. Solo las separa la extensión, diez versos frente a nueve. Navarro Tomás documenta dos disposiciones de nueve y una de diez, `AaBBCCddEE`, y el *Diccionario* da entrada propia a la de diez con el nombre «décima-estancia».$p$
	where forma_origen_id = v_decima_lira and forma_destino_id = v_novena_lira and tipo_relacion = 'relacionada_con';

	update public.forma_relaciones
	set nota = $p$Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho; pero a los nueve la canción ya es posible y a los ocho no. La octava tiene disposiciones documentadas y una invariante —cierra en pareado—; de la novena, Navarro Tomás documenta dos, y las dos se dejan leer también como estancias.$p$
	where forma_origen_id = v_novena_lira and forma_destino_id = v_octava_lira and tipo_relacion = 'relacionada_con';

	-- ══════════════════════════════════════════════════════════ Las aliradas, sin el eslabón
	update public.formas_metricas
	set definicion = $p$Estrofa de nueve versos que mezcla endecasílabos y heptasílabos en proporción variable y rima en consonante, sin que la norma fije cómo se reparten las rimas. Pertenece a la serie de las estrofas aliradas: la misma materia de la canción, siete y once consonantes repetidos sin cambio de una estrofa a otra, sin la ordenación de la estancia. Es la primera extensión en la que la duda con la canción se plantea, porque a los nueve versos una estancia ya es posible: es novena-lira cuando se considera una estrofa sin partes, y canción cuando una fronte de dos *piedi* y una sirima la articulan como estancia.$p$
	where forma_id = v_novena_lira;

	update public.formas_metricas
	set definicion = $p$Estrofa de diez versos que mezcla endecasílabos y heptasílabos y rima en consonante. Pertenece a la serie de las estrofas aliradas —la materia de la canción, siete y once consonantes repetidos sin cambio, sin la ordenación de la estancia— y, como la novena, cae en la franja en la que una estancia es posible: es décima-lira cuando se considera una estrofa sin partes, y canción cuando una fronte de dos *piedi* y una sirima la articulan como estancia. La tradición crítica la llama también «décima-estancia», por lo cerca que queda de una estancia de diez versos.$p$
	where forma_id = v_decima_lira;

	update public.formas_metricas
	set definicion = $p$Estrofa de ocho versos que mezcla endecasílabos y heptasílabos y reparte cuatro rimas consonantes en disposiciones variables, con una condición que no falla: los dos últimos versos forman pareado. Es la mayor de las estrofas aliradas: tiene la materia de la canción, siete y once consonantes repetidos sin cambio de una estrofa a otra, y le falta su ordenación. Que cierre en pareado no la acerca a la estancia —el sexteto-lira también cierra así—, y hasta los ocho versos no cabe canción: la estancia empieza en nueve.$p$
	where forma_id = v_octava_lira;

	update public.formas_metricas
	set definicion = replace(definicion,
		' En una estrofa tan breve la diferencia no llega a plantearse, porque no hay sitio para una fronte partida en dos piedi y una sirima con eslabón.',
		'')
	where forma_id = v_cuarteto_lira
		and definicion like '%no hay sitio para una fronte partida en dos piedi y una sirima con eslabón.%';

	update public.formas_metricas
	set definicion = $p$Estrofa de cinco versos —7 11 7 7 11— con rima consonante repartida en dos clases y cierre en pareado, aBabB. Es una estancia de canción reducida a su mínimo, y por eso se la ha llamado también «media estancia»: la misma materia, heptasílabos y endecasílabos consonantes, fijada en una estrofa breve que se repite sin cambio. Bernardo Tasso la había usado en italiano, y Garcilaso la introdujo en castellano en la canción «A la flor de Gnido», de cuyo primer verso —«Si de mi baja lira»— toma el nombre. Fray Luis de León la consagró como molde de la oda horaciana, donde la estancia larga sobraba, hasta darle otro nombre. De ella salen el sexteto-lira, que la amplía a seis versos, y la serie entera de estrofas aliradas, que fue creciendo estrofa a estrofa hasta el tamaño en que empieza la estancia y que en el Barroco la desplazó.$p$
	where forma_id = v_lira;

	-- Los esquemas de la novena y la décima descansaban en el criterio del eslabón.
	update public.esquemas_rima e
	set descripcion = $p$La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las rimas. Las dos disposiciones de nueve versos que Navarro Tomás describe entre las aliradas, `abCabCcdD` y `AbCAbCcdD`, admiten las dos lecturas: como estrofa sin partes, o como estancia con fronte `abC|abC`, eslabón y una sirima reducida a un pareado, que es un cierre débil para sostener por sí solo la articulación. Por eso no se declaran como patrón de esta forma ni de la canción.$p$
	from public.arquitecturas_forma a
	where e.arquitectura_id = a.arquitectura_id and a.forma_id = v_novena_lira
		and e.slug = 'distribucion-variable';

	update public.esquemas_rima e
	set descripcion = $p$Dos parejas de rima cruzada y un pareado final. En el testimonio que la documenta los heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo testimonio y no basta para fijar esa alternancia como norma. Sus versos quinto a octavo repiten la figura de los cuatro primeros con rimas nuevas: es un parecido con la fronte, no una fronte, porque los dos *piedi* comparten las rimas y estos bloques no.$p$
	from public.arquitecturas_forma a
	where e.arquitectura_id = a.arquitectura_id and a.forma_id = v_decima_lira
		and e.slug = 'ababcdcdee';

	-- Las afirmaciones de la lira que faltaban por contar el origen.
	update public.afirmaciones_fuentes_metricas
	set localizador = '§§ 111, 190 y 462',
		resumen = $p$Garcilaso «introdujo esta estrofa en castellano con la Canción de Gnido», y «recibió el nombre de lira por la mención de este instrumento al principio de la citada poesía»; la idea «pudo recogerla Garcilaso de Bernardo Tasso, quien había usado esa misma estrofa en una poesía de sus *Amori*, 1534». «Apenas practicada en Italia, fue acogida con especial predilección por los poetas españoles», y después de Garcilaso la emplearon Hernando de Acuña, Montemayor y fray Luis. En el Barroco «disminuyó notoriamente la lira de Garcilaso. Se dio preferencia a las estrofas aliradas de seis o más versos en combinaciones diferentes». Sigue su rastro hasta el siglo XX, en una oda de García Lorca a fray Luis y en el argentino Ricardo E. Molinari, y añade que «últimamente **parece** renacer con nueva vitalidad en repetidas manifestaciones».$p$
	where forma_id = v_lira and fuente_id = v_navarro and localizador = '§ 462';

	update public.afirmaciones_fuentes_metricas
	set resumen = resumen || $p$ Recoge «media estancia» entre sus otros nombres, y en una segunda acepción llama lira a la «estrofa formada por cuatro, cinco, seis o siete versos, endecasílabos y heptasílabos, con dos o tres rimas consonantes», de combinaciones variadas que «suelen terminar en un pareado», y que «constituye la estrofa de la canción alirada».$p$
	where forma_id = v_lira and fuente_id = v_dicc and localizador like 'Entrada «lira»%'
		and resumen not like '%media estancia%';

	-- ══════════════════════════════════════════════════════════ Comprobaciones, ejecutando lo que se toca
	if (select count(*) from public.arquitecturas_forma where forma_id = v_petr and activo) <> 1
		or (select count(*) from public.arquitecturas_forma where forma_id = v_cancion and activo and principal) <> 1
		or (select count(*) from public.arquitecturas_forma where forma_id = v_sin_rima and activo and principal) <> 1 then
		raise exception 'El reparto de arquitecturas no quedó como se esperaba.';
	end if;
	if (select count(*) from public.anotaciones_metricas where forma_id = v_cancion) <> 8
		or exists (select 1 from public.anotaciones_metricas
			where forma_id = v_petr and arquitectura_id is distinct from v_arq_reg) then
		raise exception 'Las anotaciones no cambiaron de forma con su arquitectura.';
	end if;
	-- Cada anotación sigue siendo válida para el disparador que la vigila: se reescribe a sí misma.
	update public.anotaciones_metricas set forma_id = forma_id where forma_id = v_cancion;
	-- Y la estructura de cada una se vuelve a validar con la fronte y la sirima ya opcionales.
	for v_s in select anotacion_id from public.anotaciones_metricas where forma_id = v_cancion loop
		perform public.validar_estructura_anotacion(v_s.anotacion_id);
	end loop;

	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_cancion) <> 6
		or (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_petr) <> 2
		or (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_sin_rima) <> 1 then
		raise exception 'Las afirmaciones no quedaron repartidas 6 / 2 / 1.';
	end if;
	if (select count(*) from public.forma_relaciones where forma_origen_id = v_cancion or forma_destino_id = v_cancion) <> 8 then
		raise exception 'La canción debía quedar con ocho relaciones.';
	end if;
	if exists (select 1 from public.forma_relaciones
		where (forma_origen_id = v_petr or forma_destino_id = v_petr)
			and not (forma_origen_id = v_petr and forma_destino_id = v_cancion)) then
		raise exception 'La petrarquista conserva alguna relación que debía irse con la canción.';
	end if;
	if (select origen_termino_id from public.formas_metricas where forma_id = v_cancion) <> v_termino_petr then
		raise exception 'El término legado no viajó a la canción.';
	end if;
	if exists (select 1 from public.formas_metricas
		where forma_id in (v_novena_lira, v_decima_lira, v_octava_lira, v_cuarteto_lira)
			and definicion ilike '%eslabón%') then
		raise exception 'Alguna alirada sigue definiéndose por el eslabón.';
	end if;
	if not exists (select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq_sr and slug = 'remate' and repeticiones_min = 0) then
		raise exception 'La sin rima no recibió su remate.';
	end if;
	if not exists (select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_lira and fuente_id = v_navarro and localizador = '§§ 111, 190 y 462') then
		raise exception 'La afirmación de Navarro sobre la lira no se reescribió.';
	end if;
	if not exists (select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_lira and fuente_id = v_dicc and resumen like '%media estancia%') then
		raise exception 'La afirmación del Diccionario sobre la lira no se completó.';
	end if;

	-- Lo que leen la ficha y el demarcador, ejecutado sobre las ocho fichas tocadas.
	perform public.get_forma_metrica_publica_jerarquica('cancion');
	perform public.get_forma_metrica_publica_jerarquica('cancion_petrarquista');
	perform public.get_forma_metrica_publica_jerarquica('cancion_sin_rima');
	perform public.get_forma_metrica_publica_jerarquica('lira');
	perform public.get_forma_metrica_publica_jerarquica('cuarteto_lira');
	perform public.get_forma_metrica_publica_jerarquica('octava_lira');
	perform public.get_forma_metrica_publica_jerarquica('novena_lira');
	perform public.get_forma_metrica_publica_jerarquica('decima_lira');
	perform public.obtener_catalogo_demarcador();

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % -> %', v_antes, v_despues;
	end if;

	raise notice 'Canción (%), Canción petrarquista (%) y Canción sin rima (%): revisión % -> %.',
		v_cancion, v_petr, v_sin_rima, v_antes, v_despues;
end $$;

commit;
