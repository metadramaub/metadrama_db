-- El cuarteto-lira gana las dos voces que le faltaban
--
-- Dos lagunas de la fase 4 en la menor de las estrofas aliradas, que pasa de tres afirmaciones
-- —Navarro y dos del *Diccionario*— a cinco.
--
--   2020  Jauralde, apartado «Cuartetos mixtos». Comprobado en el epub, donde es un `h6` propio: el
--         volcado aplana los niveles y ahí no se distingue de un rótulo del cuerpo.
--   2014  Domínguez Caparrós, pp. 190-191. Comprobado en el PDF, hojas 187 y 188.
--
-- **La de Caparrós la había dado por vacía el contador de la fase 4**, y no lo estaba: el catálogo
-- escribe «Cuarteto-lira» y él escribe «cuarteto lira», sin guion. Se arregló el contador tratando
-- el guion como espacio, y por eso esta celda apareció. Queda escrito en el plan como uno de los dos
-- fallos que marcan el límite del método.
--
-- ══ Lo que aportan
--
-- **Jauralde, el uso teatral**: «particularmente efectivos fueron sus quiebros para amoldarse a los
-- diálogos teatrales…; hasta Campoamor los empleó». Es la segunda forma de esta tanda —tras la
-- octava aguda— en la que una fuente habla del corpus de este proyecto sin que la ficha lo recogiera.
--
-- **Caparrós, el encuadre y los ejemplos**: la sitúa como «una de las estrofas de la canción
-- alirada», y documenta con Espronceda la consonante y con Bécquer la asonante en los pares, que la
-- ficha declaraba sin testimonio.
--
-- ══ Dos cosas que salen de aquí, se anotan y no se tocan
--
-- **La estrofa sáfica no existe en el catálogo** —ni forma, ni arquitectura, ni denominación, ni
-- variedad— y las dos fuentes la meten debajo de esta: Caparrós dice que es uno de los dos tipos de
-- cuarteto lira y Jauralde la pone entre las clásicas de las que derivan los cuartetos mixtos. Con
-- ella entra la **estrofa de Francisco de la Torre**, que Caparrós define como su variante de cuarto
-- verso heptasílabo.
--
-- **Y Jauralde relaciona esta forma con la endecha real por la proporción de las medidas**: «cuando
-- sobre la misma estructura de cuatro versos impares lo que domina es el heptasílabo sobre el
-- endecasílabo se prefiere hablar de cuartetos de endecha». El catálogo las tiene separadas y sin
-- relación declarada.
--
-- Las dos van a `cuestiones-para-el-ip.md`: crear formas y declarar relaciones es asunto de
-- catálogo, no de esta auditoría.
--
-- Textos aprobados por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := (select forma_id from public.formas_metricas where nombre = 'Cuarteto-lira');
	v_jaur constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2020);
	v_capar constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2014);
	v_loc_2020 constant text := 'Apartado «Cuartetos mixtos»';
	v_loc_2014 constant text := 'pp. 190-191';
	v_res_2020 constant text :=
		'Lo trata dentro de los cuartetos mixtos, que define como las estrofas de endecasílabos con uno '
		'o dos versos quebrados —heptasílabos o pentasílabos— derivadas de las clásicas: «la llamada '
		'estrofa de la Torre, la estrofa sáfica, la alcaica». Del cuarteto-lira dice que es '
		'«combinación de heptasílabos y endecasílabos, con rimas preferentemente consonánticas», y le '
		'traza genealogía: «se remontan a las versiones horacianas de fray Luis de León y Medrano; e '
		'incluso a la estrofa sáfica (`11A 11B 11B 5a`) o a un intento de imitación de la estrofa '
		'alcaica (`11A 11B 7b 7a`)», con larga vida después, recuperados por los poetas del siglo XVIII '
		'y explorados en sus posibilidades sonoras durante el Romanticismo. Sobre su uso teatral: '
		'«particularmente efectivos fueron sus quiebros para amoldarse a los diálogos teatrales…; hasta '
		'Campoamor los empleó para algunas de sus famosas composiciones». Y distingue por la proporción '
		'de las medidas: «cuando sobre la misma estructura de cuatro versos impares lo que domina es el '
		'heptasílabo sobre el endecasílabo se prefiere hablar de cuartetos de endecha».';
	v_res_2014 constant text :=
		'Lo encuadra —«el cuarteto lira, una de las estrofas de la canción alirada»— y lo define: '
		'«combina heptasílabos y endecasílabos que riman en consonante: `ABAB`, o `ABBA`. Puede '
		'encontrarse con rima asonante y con algún verso suelto». Lo ejemplifica con la elegía «A la '
		'patria» de Espronceda y, para la asonante en los pares, con la rima XVIII de Bécquer. Y le '
		'subordina dos estrofas clásicas: «dos tipos de cuarteto lira son la estrofa sáfica y la '
		'estrofa de Francisco de la Torre» —la sáfica, tres endecasílabos y un pentasílabo acentuado en '
		'la primera sílaba, normalmente sin rima; la de Francisco de la Torre, su variante con el '
		'cuarto verso heptasílabo—.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_forma is null or v_jaur is null or v_capar is null then
		raise exception 'No encuentro el cuarteto-lira o alguna de las dos fuentes.';
	end if;

	-- Que hoy habla con dos voces —Navarro y el Diccionario— y con ninguna de estas dos.
	select count(distinct a.fuente_id) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_cuantas <> 2 then
		raise exception 'El cuarteto-lira habla con % fuentes y esperaba dos.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma and a.fuente_id in (v_jaur, v_capar);
	if v_cuantas <> 0 then
		raise exception 'Alguna de las dos fuentes tiene ya afirmación aquí.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		(v_jaur, v_forma, v_loc_2020, v_res_2020, 'alta'),
		(v_capar, v_forma, v_loc_2014, v_res_2014, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las dos quedaron exactamente con el texto que David aprobó.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and ((fuente_id = v_jaur and localizador = v_loc_2020 and resumen = v_res_2020)
			or (fuente_id = v_capar and localizador = v_loc_2014 and resumen = v_res_2014));
	if v_cuantas <> 2 then
		raise exception 'Las dos afirmaciones no han quedado con el texto aprobado: cuadran %.', v_cuantas;
	end if;

	-- Que la ficha habla ya con cuatro voces. **Cuatro y no seis**: ni Morley y Bruerton ni Quilis
	-- registran esta forma, y esos dos silencios entrarán con la tanda de los de la fase 4.
	select count(distinct a.fuente_id) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_cuantas <> 4 then
		raise exception 'El cuarteto-lira habla con % fuentes y esperaba cuatro.', v_cuantas;
	end if;

	-- Que entra lo que hacía falta de cada una: el uso teatral y el encuadre en la canción alirada.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and ((fuente_id = v_jaur and resumen like '%diálogos teatrales%')
			or (fuente_id = v_capar and resumen like '%una de las estrofas de la canción alirada%'));
	if v_cuantas <> 2 then
		raise exception 'Falta el uso teatral o el encuadre en la canción alirada.';
	end if;

	-- Y que la estrofa sáfica sigue sin existir en el catálogo: entra en la voz de las dos fuentes que
	-- la subordinan a esta forma, y crearla o no es decisión del IP.
	select count(*) into v_cuantas
	from public.formas_metricas where nombre ilike '%sáfic%';
	if v_cuantas <> 0 then
		raise exception 'Hay ya % formas sáficas; esta migración daba por hecho que ninguna.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
