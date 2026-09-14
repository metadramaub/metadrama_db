-- La novena-lira deja de decir que ninguna fuente la describe
--
-- Primera laguna de la fase 4 que se escribe, y la que justifica la fase entera: **comprobar que
-- una afirmación dice la verdad no comprueba que existan las que faltan**.
--
-- La novena-lira era una de las dos formas del catálogo sin una sola afirmación, y su definición
-- explicaba por qué: «a diferencia de las demás de su serie, ninguna de las fuentes del catálogo la
-- describe ni le da nombre», de modo que se registraba por coherencia de serie y no por testimonio.
-- Su arquitectura remataba la idea: «de esta forma no se conoce ninguna disposición documentada».
--
-- **Las dos cosas son falsas.** Navarro Tomás, § 161, titulado «Estrofas aliradas», recorre el tipo
-- métrico del sexteto en adelante y termina en dos estrofas de nueve versos, que presenta como «una
-- nueva reelaboración de este modelo» —el modelo son las dos aliradas de ocho que el catálogo ya
-- recoge como octava-lira—: `abCabCcdD`, de Francisco de Figueroa en su imitación de la oda
-- horaciana *Oh, navis*, y `AbCAbCcdD`, en la poesía 120 de Góngora.
--
-- No lo encontró ninguna de las tres pasadas, y no podía encontrarlo el contador de menciones de la
-- fase 4, que dio cero: **«Novena-lira» es nombre nuestro para algo que Navarro describe sin
-- bautizar**. Es el límite del método, y queda escrito en el plan.
--
-- ══ Por qué los esquemas van a la afirmación y no a la arquitectura
--
-- Porque **a qué forma pertenecen es lo que está en discusión**. En los dos, el verso séptimo repite
-- la rima con que se cierra la cabeza, y la regla de este catálogo asigna eso a la canción; Navarro
-- los pone entre las aliradas. Ninguna de las seis fuentes usa el eslabón como criterio y dos lo
-- niegan expresamente —Caparrós y el *Diccionario* dicen que «aunque no es obligatorio, es
-- frecuente»—, mientras que las tres que dan criterio dan la extensión y la sitúan en nueve versos,
-- que es justo la de estas dos estrofas.
--
-- Eso lo decide el IP, y está documentado con lo que dice cada fuente en `cuestiones-para-el-ip.md`,
-- «Canción petrarquista» 6. Hasta entonces la arquitectura sigue declarando solo extensión, materia
-- y régimen, y los dos esquemas viven donde no comprometen nada: en la voz de quien los da.
--
-- **La afirmación tampoco dice que el séptimo verso repita la rima de la cabeza.** Es análisis
-- nuestro, no de Navarro, y una afirmación de fuente recoge lo que la fuente dice.
--
-- Textos aprobados por David el 17 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := '01c1c1ef-c0b4-4060-ab29-5921f2216548';
	v_arq constant uuid := '4ff724c6-9874-4cf6-8742-eef7f5b48be0';
	v_navarro constant uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_localizador constant text := '§ 161, «Estrofas aliradas», pp. 256-257';
	v_definicion constant text :=
		'Estrofa de nueve versos que mezcla endecasílabos y heptasílabos en proporción variable y rima '
		'en consonante, sin que la norma fije cómo se reparten las rimas. Pertenece a la serie de las '
		'estrofas aliradas: tiene la materia de la canción italiana —siete y once consonantes, '
		'repetidos sin cambio de una estrofa a otra— y no se ordena como una estancia, porque no trae '
		'eslabón. Navarro Tomás la describe entre las estrofas aliradas y documenta dos disposiciones.';
	v_descripcion constant text :=
		'Nueve versos de siete y once sílabas en proporción variable, con rima consonante. La norma no '
		'fija ni cuántos versos son de cada medida ni cómo se reparten las rimas, de modo que lo único '
		'que declara son la extensión, la materia y el régimen.';
	v_resumen constant text :=
		'La describe dentro de su epígrafe «Estrofas aliradas» y la presenta como «una nueva '
		'reelaboración de este modelo», siendo el modelo las dos estrofas aliradas de ocho versos que '
		'acaba de describir —la de Jáuregui en su traducción de *Sic te, dive*, `abCabCdD`, y la de '
		'Cervantes en una escena de *La entretenida*, `ABcABcDD`—. Da dos disposiciones de nueve: '
		'`abCabCcdD`, que Francisco de Figueroa emplea en su imitación de la oda horaciana *Oh, navis*, '
		'y `AbCAbCcdD`, la misma bajo otra forma, en la poesía 120 de Góngora.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que la forma es la que creo y que sigue diciendo lo que se viene a quitar.
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma and nombre = 'Novena-lira'
		and definicion like '%ninguna de las fuentes del catálogo la describe ni le da nombre%';
	if v_cuantas <> 1 then
		raise exception 'La definición de la novena-lira no es la que espero; no la toco.';
	end if;

	select count(*) into v_cuantas
	from public.arquitecturas_forma
	where arquitectura_id = v_arq and forma_id = v_forma
		and descripcion like '%no se conoce ninguna disposición documentada%';
	if v_cuantas <> 1 then
		raise exception 'La descripción de la arquitectura no es la que espero; no la toco.';
	end if;

	-- Y que hoy no tiene ninguna afirmación, que es el punto de partida.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_cuantas <> 0 then
		raise exception 'La novena-lira ya tiene % afirmaciones; esta migración daba por hecho que ninguna.',
			v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.formas_metricas set definicion = v_definicion where forma_id = v_forma;
	update public.arquitecturas_forma set descripcion = v_descripcion where arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values (v_navarro, v_forma, v_localizador, v_resumen, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que los tres textos quedaron exactamente como David los aprobó.
	select count(*) into v_cuantas
	from public.formas_metricas where forma_id = v_forma and definicion = v_definicion;
	if v_cuantas <> 1 then
		raise exception 'La definición no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.arquitecturas_forma where arquitectura_id = v_arq and descripcion = v_descripcion;
	if v_cuantas <> 1 then
		raise exception 'La descripción de la arquitectura no ha quedado con el texto aprobado.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_navarro
		and resumen = v_resumen and localizador = v_localizador;
	if v_cuantas <> 1 then
		raise exception 'La afirmación de Navarro no ha quedado con el texto aprobado.';
	end if;

	-- Que la forma deja de estar muda: era una de las dos sin ninguna fuente.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_cuantas <> 1 then
		raise exception 'La novena-lira ha quedado con % afirmaciones y esperaba una.', v_cuantas;
	end if;

	-- Que ni la definición ni la arquitectura siguen afirmando la ausencia que las fuentes desmienten.
	select count(*) into v_cuantas
	from public.formas_metricas f
	join public.arquitecturas_forma a using (forma_id)
	where f.forma_id = v_forma
		and f.definicion not like '%ninguna de las fuentes%'
		and a.descripcion not like '%no se conoce ninguna disposición%';
	if v_cuantas <> 1 then
		raise exception 'Sigue habiendo texto diciendo que ninguna fuente la documenta.';
	end if;

	-- Y que la arquitectura no ha ganado esquemas: los dos de Navarro viven en la afirmación, porque
	-- a qué forma pertenecen lo decide el IP.
	select count(*) into v_cuantas
	from public.esquemas_rima where arquitectura_id = v_arq and notacion is not null;
	if v_cuantas <> 0 then
		raise exception 'La arquitectura tiene % esquemas con notación y no debía ganar ninguno.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
