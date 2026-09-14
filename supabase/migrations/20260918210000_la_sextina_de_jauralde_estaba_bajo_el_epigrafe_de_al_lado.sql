-- La sextina de Jauralde estaba bajo el epígrafe de al lado
--
-- **Última laguna de la fase 4.** Con ella, las nueve quedan escritas.
--
-- Jauralde promete «espacio aparte a las variedades históricamente más importantes, como son la
-- sextina, la endecha real, la copla de pie quebrado», y cumple. Pero el espacio que le da **se
-- titula «Sexta rima»**, y el epígrafe que titula «Sextina real», que lo precede, describe otra
-- estrofa: el sexteto endecasílabo `ABABCC`. Los dos nombres están intercambiados respecto del uso
-- corriente.
--
-- Por eso la celda salía vacía y por eso el contador de menciones no ayudaba: bajo «Sextina real»
-- hay una estrofa que no es esta, y bajo «Sexta rima» está esta sin que su nombre aparezca en el
-- rótulo.
--
-- **Solo el epub lo distingue.** Los dos son `h3`, dentro de los sextetos endecasilábicos y
-- dodecasilábicos, y el volcado aplana los niveles: ahí un rótulo del cuerpo y un epígrafe se leen
-- igual. Es la tercera vez en esta auditoría que el epub decide algo que el `.txt` no podía.
--
-- ══ Por qué la última frase de la afirmación va dentro
--
-- Decir que «Sextina real» describe otra estrofa parece comparar fuentes, que no toca. No lo es:
-- **los dos epígrafes son suyos, del mismo libro**. No se enfrenta a Jauralde con nadie, se dice
-- cómo está ordenado su libro. Y es lo único que impide que quien vaya a consultarlo desde esta
-- ficha aterrice en la estrofa que no es.
--
-- La ficha vecina —la sextina como estrofa— ya decía la otra mitad desde su lado: «usa "sextina
-- real" para un sexteto endecasilábico ABABCC con pareado final. Es otra estrofa —la sexta rima— y
-- no la sextina». Ahora el enredo queda contado por los dos extremos.
--
-- Texto aprobado por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := (select forma_id from public.formas_metricas where slug = 'sextina');
	v_estrofa constant uuid := (select forma_id from public.formas_metricas where slug = 'sextina_estrofa');
	v_jaur constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2020);
	v_localizador constant text := 'Apartado «Sexta rima», entre las estrofas de seis versos';
	v_resumen constant text :=
		'La cuenta entre «las variedades históricamente más importantes» a las que promete «espacio '
		'aparte», junto a la endecha real y la copla de pie quebrado. Ese espacio existe, pero **lo '
		'titula «Sexta rima»**, y bajo ese rótulo cita la definición de Domínguez Caparrós —«poema de '
		'treinta y nueve endecasílabos, dividido en seis estrofas de seis versos y un remate de tres '
		'versos. Los versos de cada una de las estrofas no riman entre sí, pero todos los versos '
		'repiten la misma palabra final de los versos de las otras estrofas en un orden distinto»— y '
		'sigue su historia: «utilizada por algunos poetas del siglo XVI, como Fernando de Herrera; '
		'retomada modernamente por algunos versificadores hábiles, como Gerardo Diego en su *Fábula de '
		'Equis y Zeda* o en el *Madrigal a Conchita Cintrón*», y anota que el uso de Jaime Gil de '
		'Biedma en *Apología y petición* «ha provocado su relativa frecuencia entre poetas actuales». '
		'El epígrafe «Sextina real», que lo precede, describe otra estrofa: el sexteto endecasílabo '
		'`ABABCC`.';
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_forma is null or v_estrofa is null or v_jaur is null then
		raise exception 'No encuentro las dos sextinas o la fuente de 2020.';
	end if;

	-- Que es la composición y no la estrofa homónima, que es justo lo que aquí se puede confundir.
	select count(*) into v_n from public.formas_metricas
	where forma_id = v_forma and nivel_estructural = 'composicion';
	if v_n <> 1 then
		raise exception 'La forma «sextina» no es la composición; no la toco.';
	end if;

	-- Que hoy habla con cinco voces y le falta justo la de Jauralde.
	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 5 then
		raise exception 'La sextina habla con % fuentes y esperaba cinco.', v_n;
	end if;
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma and fuente_id = v_jaur;
	if v_n <> 0 then
		raise exception 'La sextina ya tiene afirmación de Jauralde.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values (v_jaur, v_forma, v_localizador, v_resumen, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que quedó exactamente con el texto aprobado.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_jaur
		and localizador = v_localizador and resumen = v_resumen;
	if v_n <> 1 then
		raise exception 'La afirmación no ha quedado con el texto aprobado.';
	end if;

	-- Que la composición habla ya con las seis: es de las pocas que no tienen ningún silencio.
	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La sextina habla con % fuentes y esperaba las seis.', v_n;
	end if;

	-- Y que el enredo queda contado por los dos extremos: esta ficha avisa de que el espacio está
	-- bajo «Sexta rima», y la de la estrofa, de que «Sextina real» es otra cosa.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_jaur and resumen like '%Sextina real%';
	if v_n <> 1 then
		raise exception 'La afirmación nueva no avisa del epígrafe vecino.';
	end if;
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_estrofa and a.fuente_id = v_jaur
		and a.resumen like '%sexta rima%';
	if v_n <> 1 then
		raise exception 'La ficha de la estrofa ha dejado de avisar de lo mismo desde su lado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
