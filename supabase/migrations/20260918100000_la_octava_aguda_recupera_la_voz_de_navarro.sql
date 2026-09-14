-- La octava aguda recupera la voz de Navarro Tomás
--
-- **La mayor laguna de la fase 4.** Veintinueve menciones en el libro y ninguna afirmación en la
-- ficha. No era un descuido de una línea: Navarro le da **epígrafe propio a cada una de sus dos
-- ramas en cada período** —§§ 227 y 245 en el Neoclasicismo, 288 y 309 en el Romanticismo, 381 en
-- el Modernismo— y **entrada doble en su «Índice de estrofas»**, una para la de arte mayor y otra
-- para la de arte menor, que es exactamente el reparto de las seis arquitecturas de esta ficha.
--
-- Las dos entradas del índice remiten a doce secciones. Se comprobaron una a una: **once están**
-- —227, 245, 261, 269, 270, 272, 288, 309, 342, 381 y 434— y la del § 265 no aparece en el volcado,
-- que ahí es corto y pudo perderla el escaneo. No se cita esa.
--
-- ══ Lo que aporta y no tenía la ficha
--
-- **El nombre bermudina**, por Salvador Bermúdez de Castro, que la cultivó en endecasílabos.
--
-- **Un reparo al nombre de italiana**, que va dentro de su afirmación aunque contradiga a las otras
-- dos fuentes que sí lo usan —Quilis la llama «octava italiana u octava aguda» y Caparrós dice que
-- en arte menor se llama «octavilla aguda u octava italiana»—. No es comparación nuestra: es lo que
-- Navarro escribe en su propio índice, y el lector que vea las cuatro voces juntas hará la
-- comparación solo.
--
-- **La escala métrica entera**, del endecasílabo al trisílabo, con testimonio en cada peldaño.
--
-- **Y una frase sobre el teatro** (§ 309), que es lo que convierte esta laguna en la peor de todas:
-- una afirmación sobre esta forma **en el corpus de este proyecto**, que llevaba ahí desde el
-- principio sin que nadie la recogiera.
--
-- ══ Lo que queda anotado y no se toca
--
-- Navarro documenta la forma en **dos medidas que el catálogo no tiene**: eneasílaba —su índice
-- define la rama mayor como «de nueve o más sílabas», y el § 342 da cinco octavas agudas de *La
-- cruz*, de la Avellaneda— y trisílaba, § 272. Las seis arquitecturas de la ficha van del
-- endecasílabo al pentasílabo. **Añadir arquitecturas es asunto de catálogo y no de esta
-- auditoría**, así que queda en `cuestiones-para-el-ip.md`.

begin;

do $$
declare
	v_forma constant uuid := (select forma_id from public.formas_metricas where nombre = 'Octava aguda');
	v_navarro constant uuid := (select fuente_id from public.fuentes_metricas where anio = 1972);
	v_localizador constant text := '«Índice de estrofas», s. vv. «Octava aguda» y «Octavilla aguda», y §§ 227, 245, 288, 309 y 381';
	v_resumen constant text :=
		'Trata por separado las dos ramas y les da nombre y epígrafe propios: «octava aguda» las de '
		'nueve o más sílabas y «octavilla aguda» las de ocho o menos, con sección para cada una en el '
		'Neoclasicismo y en el Romanticismo, y para la octavilla también en el Modernismo. Da el '
		'esquema de las dos, `ABBÉ:CDDÉ` y `abbé:cddé`, y recoge sus variedades: en la endecasílaba, '
		'las que enlazan las semiestrofas por la rima, `ABBÉ:ACCÉ` y `ABBÉ:CBBÉ`, y la de heptasílabos '
		'agudos en los versos cuarto y octavo, `ABBé:CDDé`, «hecha famosa por Pastor Díaz en *La '
		'mariposa negra*»; en la octavilla, la de versos primero y quinto sueltos —«que había de '
		'convertirse en el esquema más corriente»—, la de todos rimados, `abbé:accé`, la alterna '
		'`abaé:cdcé` y la de semiestrofas monorrimas, `aaaé:bbbé`. A la endecasílaba, «cultivada '
		'especialmente por Salvador Bermúdez de Castro, se le llamó también **bermudina**». Y objeta al '
		'nombre de italiana: «el calificativo de italianas que suele darse a la octava y octavilla '
		'agudas no las distingue de la octava real, también de origen italiano». La documenta en toda '
		'la escala del verso, del endecasílabo al trisílabo: en eneasílabos dactílicos, «la Avellaneda '
		'en cinco octavas agudas de *La cruz*» (§ 342); en hexasílabos, Lista en su traducción del '
		'salmo *Domini est terra* (§ 269); en pentasílabos, *Amor aldeano* de Moratín padre (§ 270); y '
		'en trisílabos, Sánchez Barbero, «en cuatro octavillas agudas cuyas semiestrofas terminan '
		'alternativamente en las palabras *amor*, *honor*» (§ 272). Sobre su uso teatral: «el teatro no '
		'solía emplear la octavilla aguda sino en números cantables como el himno del drama *Baltasar*, '
		'II, 4, de la Avellaneda, y el coro de *Saúl*, III, 1, de la misma autora, o en pasajes '
		'líricos, como la carta de don Juan a doña Inés en *Don Juan Tenorio*, III, 3, de Zorrilla».';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_forma is null or v_navarro is null then
		raise exception 'No encuentro la octava aguda o la fuente de 1972.';
	end if;

	-- Que hoy tiene las cuatro que se le conocen y ninguna de Navarro, que es el punto de partida.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_cuantas <> 4 then
		raise exception 'Esperaba 4 afirmaciones en la octava aguda y encuentro %.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma and fuente_id = v_navarro;
	if v_cuantas <> 0 then
		raise exception 'La octava aguda ya tiene afirmación de Navarro Tomás.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values (v_navarro, v_forma, v_localizador, v_resumen, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que quedó exactamente con el texto que David aprobó.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_navarro
		and localizador = v_localizador and resumen = v_resumen;
	if v_cuantas <> 1 then
		raise exception 'La afirmación de Navarro no ha quedado con el texto aprobado.';
	end if;

	-- Y que la ficha habla ya con cinco voces. **Cinco y no seis**: esta guarda se escribió pidiendo
	-- las seis y falló, que es como se comprobó que la sexta no faltaba por descuido. Morley y
	-- Bruerton no tiene afirmación aquí porque no es un manual de métrica sino el repertorio de las
	-- formas que usa Lope, y la octava aguda es estrofa del XVIII: su silencio es de los que hay que
	-- registrar como tales, y entrará con la tanda de los veinte silencios justificados de la fase 4.
	select count(distinct fuente_id) into v_cuantas
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_cuantas <> 5 then
		raise exception 'La octava aguda habla con % fuentes y esperaba cinco.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.forma_id = v_forma and f.anio = 1968;
	if v_cuantas <> 0 then
		raise exception 'Morley y Bruerton tiene ya afirmación aquí; esta migración daba por hecho que no.';
	end if;

	-- Que entra lo que solo dice Navarro: el nombre bermudina, el reparo al de italiana y el teatro.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_navarro
		and resumen like '%bermudina%'
		and resumen like '%no las distingue de la octava real%'
		and resumen like '%el teatro no solía emplear la octavilla aguda%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación no trae las tres cosas que solo dice Navarro.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
