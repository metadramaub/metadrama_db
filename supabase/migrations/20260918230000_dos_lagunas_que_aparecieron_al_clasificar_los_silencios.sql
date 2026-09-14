-- Dos lagunas que aparecieron al clasificar los silencios
--
-- La fase 4 daba por cerradas sus nueve lagunas. Al ir a justificar, una por una, por qué cada
-- fuente calla donde calla, salieron estas dos: **una que estaba en la lista y no se escribió, y
-- otra que nadie podía ver**.
--
-- ══ `irregular` · Quilis 1969, §§ 3.0, p. 39, y 6.4.4, p. 168
--
-- Estaba entre las nueve desde el principio y se quedó sin escribir por un error de recuento al dar
-- la tanda por terminada. Comprobado en el PDF: hojas 20 y 85, con los pies «39» y «168».
--
-- ══ `octava_lira` · Jauralde 2020, apartado «Formas mixtas» de las estrofas de ocho versos
--
-- **Esta no la vio nadie, y el motivo importa**: Jauralde llama a la forma «octetos-lira», y
-- «octeto» no era ninguna de las denominaciones del catálogo. El contador de menciones de la fase 4
-- busca las denominaciones que el catálogo conoce, de modo que dio cero y la celda pasó por
-- silencio justificado.
--
-- Es **el tercer fallo del método por la misma causa**, y los tres quedan escritos en el plan: el
-- guion de «cuarteto lira», el nombre propio de «Novena-lira» —nuestro, no de nadie— y ahora el
-- sinónimo que no teníamos. Por eso se añade «Octeto-lira» como denominación: para que la próxima
-- vez el contador lo encuentre.
--
-- Y confirma desde el dato lo que se anotó para el IP: Jauralde enumera aliradas hasta el octeto y
-- define la estancia «por encima de los ocho versos (para diferenciarla de las liras)». Su serie no
-- se corta por falta de casos, se corta donde empieza a llamarlo canción.
--
-- **No se le atribuye esquema de rima.** Jauralde imprime las medidas verso a verso pero no las
-- letras, y las que se deducen del ejemplo de Góngora serían lectura nuestra.
--
-- Textos aprobados por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_irregular constant uuid := (select forma_id from public.formas_metricas where slug = 'irregular');
	v_octava constant uuid := (select forma_id from public.formas_metricas where slug = 'octava_lira');
	v_quilis constant uuid := (select fuente_id from public.fuentes_metricas where anio = 1969);
	v_jaur constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2020);
	v_loc_quilis constant text := '§§ 3.0, p. 39, y 6.4.4, p. 168';
	v_loc_jaur constant text := 'Apartado «Formas mixtas», entre las estrofas de ocho versos';
	v_res_quilis constant text :=
		'La define por oposición y le da nombre: «a la versificación regular o silábica se contrapone '
		'la versificación irregular o libre, en la que el número de sílabas es totalmente '
		'indeterminado, pero que puede manifestarse bajo un cierto ritmo acentual (versificación '
		'rítmica) o bajo agrupaciones periódicas de ciertos grupos fónicos (versificación periódica)». '
		'Le dedica después un apartado propio, «Poemas de versos libres», donde enumera cinco rasgos '
		'—«ausencia de estrofas; ausencia de rima; ausencia de medida en los versos; ruptura sintáctica '
		'de la frase; aislamiento de la palabra»— y advierte que «todavía falta un estudio de conjunto '
		'y profundo sobre este tipo de poemas».';
	v_res_jaur constant text :=
		'Los llama **octetos-lira** y los trata entre las formas mixtas de las estrofas de ocho versos: '
		'«más escasos que las liras con menor número de versos, los octetos-lira aparecen en poetas más '
		'tardíos de nuestro Siglo de Oro, por ejemplo, en Quevedo ("Sencilla significación de afecto '
		'amoroso…") y Góngora». Transcribe de Góngora un octeto de medida `7 7 11 7 7 11 7 11`, y '
		'registra otra realización de José Martí, «octeto de seis heptasílabos rematados con dos '
		'endecasílabos».';
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_irregular is null or v_octava is null or v_quilis is null or v_jaur is null then
		raise exception 'Falta alguna de las dos formas o de las dos fuentes.';
	end if;

	-- Que las dos celdas están hoy vacías, que es lo que se viene a llenar.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where (coalesce(a.forma_id, ar.forma_id) = v_irregular and a.fuente_id = v_quilis)
		or (coalesce(a.forma_id, ar.forma_id) = v_octava and a.fuente_id = v_jaur);
	if v_n <> 0 then
		raise exception 'Alguna de las dos celdas tiene ya afirmación.';
	end if;

	-- Y que «Octeto-lira» no estaba, que es lo que explica que nadie la encontrara.
	select count(*) into v_n from public.denominaciones_metricas
	where forma_id = v_octava and nombre ilike '%octeto%';
	if v_n <> 0 then
		raise exception 'La denominación «Octeto-lira» ya existía; entonces el contador debió verla.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		(v_quilis, v_irregular, v_loc_quilis, v_res_quilis, 'alta'),
		(v_jaur, v_octava, v_loc_jaur, v_res_jaur, 'alta');

	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values (v_octava, 'Octeto-lira', 'octeto_lira', false, v_jaur);

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las dos quedaron exactamente con el texto aprobado.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where (forma_id = v_irregular and fuente_id = v_quilis
			and localizador = v_loc_quilis and resumen = v_res_quilis)
		or (forma_id = v_octava and fuente_id = v_jaur
			and localizador = v_loc_jaur and resumen = v_res_jaur);
	if v_n <> 2 then
		raise exception 'Las dos afirmaciones no han quedado con el texto aprobado: cuadran %.', v_n;
	end if;

	-- Que la versificación irregular habla ya con las seis: no le queda ningún silencio.
	select count(distinct a.fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_irregular;
	if v_n <> 6 then
		raise exception 'La versificación irregular habla con % fuentes y esperaba las seis.', v_n;
	end if;

	-- Que la octava-lira pasa de dos voces a tres.
	select count(distinct a.fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_octava;
	if v_n <> 3 then
		raise exception 'La octava-lira habla con % fuentes y esperaba tres.', v_n;
	end if;

	-- Y que la denominación entra, para que el contador la encuentre la próxima vez.
	select count(*) into v_n from public.denominaciones_metricas
	where forma_id = v_octava and nombre = 'Octeto-lira' and fuente_id = v_jaur;
	if v_n <> 1 then
		raise exception 'La denominación «Octeto-lira» no ha entrado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
