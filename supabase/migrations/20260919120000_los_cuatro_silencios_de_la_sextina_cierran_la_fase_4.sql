-- Los cuatro silencios de la sextina como estrofa, y con ellos cierra la fase 4
--
-- **Últimas cuatro celdas vacías de las 264.** Con esta migración ninguna forma del catálogo tiene
-- un hueco sin explicar frente a ninguna de sus seis fuentes.
--
-- Las cuatro dicen que esa fuente no da entidad propia a la estrofa de seis versos que forma la
-- sextina. Pero **ninguna calla sobre la sextina**: las cuatro la definen, y la definen como
-- composición. Lo que no hacen es aislar su unidad, que es un recorte del catálogo.
--
-- Por eso son cuatro textos y no uno: cada una describe la estrofa en un sitio distinto de su
-- definición, y **el *Diccionario* además usa el nombre para otra cosa**. Su entrada tiene dos
-- sentidos y el segundo remite a «sexteto», la estrofa de seis versos en general, que no es la
-- estrofa sin rima cuyas palabras finales permuta la composición. Un silencio redactado sin eso
-- habría ocultado que el nombre está ocupado dos veces en la misma entrada.
--
-- ══ Lo que queda dicho con esto, y va al IP
--
-- La `sextina_estrofa` queda con **cinco fuentes que no la aíslan y una que sí**: Quilis, § 5.4.5.1.
-- Jauralde usa «sextina real» para otra estrofa. Es el mismo caso que la derivación de la septilla,
-- sostenida también por un solo testimonio, y allí la nota lo dice con su nombre.
--
-- **La forma se queda**, y la razón es estructural antes que filológica: la sextina se declara
-- `compuesta_por` esta estrofa, de modo que sin ella la composición no estaría formada por nada. Lo
-- que va a `cuestiones-para-el-ip.md` no es si debe existir sino con qué apoyo se publica, que es
-- una fuente de seis.
--
-- Textos aprobados por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := (select forma_id from public.formas_metricas where slug = 'sextina_estrofa');
	v_composicion constant uuid := (select forma_id from public.formas_metricas where slug = 'sextina');
	v_loc_1968 constant text := 'Capítulo «Definición de las Formas Métricas», epígrafe «Sestina»';
	v_res_1968 constant text :=
		'No le da entidad propia. Define la composición —«una forma de *canzone* que consiste en seis '
		'estrofas de seis endecasílabos cada una. Las palabras finales de la primera estrofa se repiten '
		'en cada una de las otras, pero el orden de las palabras no es igual en ninguna, ni ninguna de '
		'las palabras finales riman en ninguna estrofa»— y describe la estrofa solo como su componente, '
		'sin nombrarla aparte.';
	v_loc_1972 constant text := '«Índice de estrofas», s. v. «Sextina», p. 535';
	v_res_1972 constant text :=
		'No le da entidad propia. Su «Índice de estrofas» define la sextina como «composición formada '
		'por seis estrofas de seis endecasílabos sueltos cada una, en las que se repiten como '
		'terminación de los versos las mismas seis palabras bajo seis combinaciones distintas», de modo '
		'que la estrofa queda descrita dentro de la composición y no como unidad con nombre.';
	v_loc_2014 constant text := 'p. 216';
	v_res_2014 constant text :=
		'No le da entidad propia. Define la sextina como «un poema de treinta y nueve endecasílabos, '
		'dividido en seis estrofas de seis versos y un remate de tres», y describe su estrofa de seis '
		'solo al enunciar la regla con que se permutan las palabras finales de una a otra.';
	v_loc_2016 constant text := 'Entrada «sextina», p. 391';
	v_res_2016 constant text :=
		'No le da entidad propia, y además usa el nombre para otra cosa. Su entrada recoge dos '
		'sentidos: el primero es la composición, «poema de treinta y nueve endecasílabos, dividido en '
		'seis estrofas de seis versos y un remate de tres versos», cuya estrofa describe solo como '
		'parte; el segundo remite a «**sexteto**», es decir, a la estrofa de seis versos en general, '
		'que no es la estrofa sin rima cuyas palabras finales permuta la composición.';
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_forma is null or v_composicion is null then
		raise exception 'No encuentro las dos sextinas.';
	end if;

	create temporary table silencios_sextina (
		anio integer not null,
		localizador text not null,
		resumen text not null
	) on commit drop;

	insert into silencios_sextina (anio, localizador, resumen)
	values
		(1968, v_loc_1968, v_res_1968),
		(1972, v_loc_1972, v_res_1972),
		(2014, v_loc_2014, v_res_2014),
		(2016, v_loc_2016, v_res_2016);

	-- Que las cuatro celdas están vacías y que la estrofa habla hoy con dos voces.
	select count(distinct a.fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_n <> 2 then
		raise exception 'La sextina como estrofa habla con % fuentes y esperaba dos.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	select fu.fuente_id, v_forma, t.localizador, t.resumen, 'alta'
	from silencios_sextina t
	join public.fuentes_metricas fu on fu.anio = t.anio;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que entraron las cuatro con su texto.
	select count(*) into v_n
	from silencios_sextina t
	join public.fuentes_metricas fu on fu.anio = t.anio
	join public.afirmaciones_fuentes_metricas a
		on a.forma_id = v_forma and a.fuente_id = fu.fuente_id
		and a.localizador = t.localizador and a.resumen = t.resumen;
	if v_n <> 4 then
		raise exception 'Entraron % de los cuatro silencios de la sextina.', v_n;
	end if;

	-- Que la del Diccionario avisa del segundo sentido, que es lo que la distingue de las otras tres.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas fu using (fuente_id)
	where a.forma_id = v_forma and fu.anio = 2016 and a.resumen like '%sexteto%';
	if v_n <> 1 then
		raise exception 'El silencio del Diccionario no avisa de su segundo sentido.';
	end if;

	-- Que la estrofa habla ya con las seis, y la composición también.
	select count(distinct a.fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_n <> 6 then
		raise exception 'La sextina como estrofa habla con % fuentes y esperaba las seis.', v_n;
	end if;

	-- Y que sigue siendo aquello de lo que la composición se declara compuesta, que es la razón de
	-- que la forma exista aunque solo una fuente la aísle.
	select count(*) into v_n
	from public.forma_relaciones
	where forma_origen_id = v_composicion and forma_destino_id = v_forma
		and tipo_relacion = 'compuesta_por';
	if v_n <> 1 then
		raise exception 'La sextina ha dejado de declararse compuesta por su estrofa.';
	end if;

	-- ══ Y el cierre de la fase 4: ninguna celda de la matriz queda vacía.
	select count(*) into v_n
	from public.formas_metricas f
	cross join public.fuentes_metricas fu
	where f.activo and not exists (
		select 1 from public.afirmaciones_fuentes_metricas a
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.esquemas_rima e on e.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma ar2 on ar2.arquitectura_id = e.arquitectura_id
		where a.fuente_id = fu.fuente_id
			and coalesce(a.forma_id, ar.forma_id, ar2.forma_id) = f.forma_id
	);
	if v_n <> 0 then
		raise exception 'Quedan % celdas de la matriz sin afirmación.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
