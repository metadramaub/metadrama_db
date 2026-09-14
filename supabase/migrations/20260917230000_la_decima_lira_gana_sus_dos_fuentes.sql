-- La décima-lira gana sus dos fuentes, y el catálogo se queda sin formas mudas
--
-- Segunda laguna de la fase 4, y la última forma del catálogo sin una sola afirmación. Su
-- definición cerraba diciendo «ninguna de las fuentes del catálogo la describe; su testimonio viene
-- del corpus», y su arquitectura, que el catálogo recogía «la única disposición de la que hay
-- testimonio». Las dos fuentes que siguen desmienten lo primero y matizan lo segundo.
--
-- ══ El *Diccionario* le dedica entrada propia
--
-- «décima-estancia», p. 110, con definición, ejemplo de Esteban Manuel de Villegas y una nota final
-- que importa: «puede constituir una estrofa de la canción a la italiana».
--
-- **Y el ejemplo cae del lado alirado por la regla del propio catálogo.** Sus cinco rimas se
-- entrelazan a lo largo de los diez versos —`7a 11B 11C 7d 11B 7a 11C 7e 7d 11E`— sin repetir
-- cabeza y sin eslabón: es la casilla «no repite / no trae» de la tabla de zona gris que el IP tiene
-- planteada, donde no hay discusión. De modo que la fuente describe esta forma aunque la nombre
-- estancia.
--
-- **La entrada atribuye el término a Navarro Tomás y él no lo usa.** No aparece «décima-estancia»
-- en su *Métrica española*, ni en el texto ni en su «Índice de estrofas», cuya única entrada
-- «Décima» es la de los diez octosílabos. Eso entra en la afirmación: no es comparar lo que dos
-- fuentes opinan —que no toca—, sino registrar que una fuente atribuye a otra algo que esa no dice,
-- y quien consulte la atribución no lo va a encontrar.
--
-- ══ Navarro documenta una estrofa de diez versos, y la llama estancia
--
-- § 285, «Estancia», nota al pie: José Joaquín Pesado empleó en sus *Consejos de un padre a su
-- hija* «una estancia de diez versos pareados, `AaBBCCddEE`». Comprobado en el PDF, hoja 342, que
-- lleva impreso el número 351.
--
-- ══ Lo que no se toca, y por qué
--
-- **El esquema `aBaBcDcDeE` se queda como está**, con su descripción intacta: viene de la edición de
-- *Elisa Dido* y eso sigue siendo cierto. Los dos esquemas nuevos —el del ejemplo de Villegas y el
-- de Pesado— **no entran como esquemas de rima**, por la misma razón que en la novena-lira: las dos
-- fuentes llaman estancia a lo que el catálogo llama décima-lira, y dónde cae la frontera lo decide
-- el IP. Están en la voz de quien los da, que es donde no comprometen nada.
--
-- **Y la definición no menciona ninguna de las dos.** Las definiciones son del catálogo y no
-- discuten fuentes: eso vive en la sección de fuentes. Solo sale de ella la frase que era falsa.
--
-- Todo lo documentado para el IP está en `cuestiones-para-el-ip.md`, «Lira, sexteto-lira y
-- septeto-lira» 1bis y «Canción petrarquista» 6.
--
-- Textos aprobados por David el 17 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := '8fcdc19c-0792-48ee-96dd-f6123f95c1b2';
	v_arq constant uuid := 'fbd3a5d3-dddd-4ffb-a93b-9040c160052e';
	v_dicc constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2016);
	v_navarro constant uuid := (select fuente_id from public.fuentes_metricas where anio = 1972);
	v_loc_dicc constant text := 'Entrada «décima-estancia», p. 110';
	v_loc_nav constant text := '§ 285, «Estancia», pp. 350-351';
	v_definicion constant text :=
		'Estrofa de diez versos que mezcla endecasílabos y heptasílabos y rima en consonante. Pertenece '
		'a la serie de las estrofas aliradas: tiene la materia de la canción italiana y no se ordena '
		'como una estancia, porque no trae eslabón —el verso que abriría la segunda mitad retomando la '
		'rima con que se cerró la primera—. Es la de la serie que más se confunde con una canción, '
		'hasta el punto de que la tradición crítica la llama «décima-estancia»: el patrón `aBaBcDcDeE` '
		'que recoge el catálogo repite la cabeza como lo haría una fronte partida en dos piedi, y solo '
		'la ausencia de eslabón la separa de una estancia de diez versos.';
	v_descripcion constant text :=
		'Diez versos de siete y once sílabas con rima consonante. La norma no fija la proporción de '
		'cada medida ni el reparto de las rimas; el catálogo recoge un patrón documentado y admite que '
		'aparezcan otros.';
	v_res_dicc constant text :=
		'Le da entrada propia bajo el nombre «décima-estancia», que atribuye a Navarro Tomás —quien no '
		'lo emplea en su *Métrica española*, ni en el texto ni en su «Índice de estrofas»—, y la define '
		'como «combinación estrófica de diez versos, heptasílabos y endecasílabos, rimados en '
		'consonante. Ni el número de endecasílabos y heptasílabos, ni el orden de las rimas están '
		'preestablecidos». La ejemplifica con una estrofa de Esteban Manuel de Villegas cuyas cinco '
		'rimas se entrelazan a lo largo de los diez versos sin repetir disposición. Cierra la entrada '
		'anotando que «puede constituir una estrofa de la canción a la italiana».';
	v_res_nav constant text :=
		'En su epígrafe sobre la estancia, al seguir su decadencia en el Romanticismo, anota en nota al '
		'pie que el mexicano José Joaquín Pesado empleó en sus *Consejos de un padre a su hija* «una '
		'estancia de diez versos pareados, `AaBBCCddEE`».';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que la forma es la que creo y que sigue diciendo lo que se viene a quitar.
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma and nombre = 'Décima-lira'
		and definicion like '%Ninguna de las fuentes del catálogo la describe%';
	if v_cuantas <> 1 then
		raise exception 'La definición de la décima-lira no es la que espero; no la toco.';
	end if;

	select count(*) into v_cuantas
	from public.arquitecturas_forma
	where arquitectura_id = v_arq and forma_id = v_forma
		and descripcion like '%la única disposición de la que hay testimonio%';
	if v_cuantas <> 1 then
		raise exception 'La descripción de la arquitectura no es la que espero; no la toco.';
	end if;

	-- Y que hoy no tiene ninguna afirmación: era la última forma muda del catálogo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	where coalesce(a.forma_id, ar.forma_id) = v_forma;
	if v_cuantas <> 0 then
		raise exception 'La décima-lira ya tiene % afirmaciones; esta migración daba por hecho que ninguna.',
			v_cuantas;
	end if;

	if v_dicc is null or v_navarro is null then
		raise exception 'No encuentro las fuentes de 2016 y 1972.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.formas_metricas set definicion = v_definicion where forma_id = v_forma;
	update public.arquitecturas_forma set descripcion = v_descripcion where arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		(v_dicc, v_forma, v_loc_dicc, v_res_dicc, 'alta'),
		(v_navarro, v_forma, v_loc_nav, v_res_nav, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que los cuatro textos quedaron exactamente como David los aprobó.
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
	where forma_id = v_forma
		and ((fuente_id = v_dicc and localizador = v_loc_dicc and resumen = v_res_dicc)
			or (fuente_id = v_navarro and localizador = v_loc_nav and resumen = v_res_nav));
	if v_cuantas <> 2 then
		raise exception 'Las dos afirmaciones no han quedado con el texto aprobado: cuadran %.', v_cuantas;
	end if;

	-- Que la definición ya no afirma la ausencia que las dos fuentes desmienten, y que tampoco ha
	-- ganado discusión de fuentes: eso vive en la sección de fuentes, no en una definición.
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma
		and definicion not like '%Ninguna de las fuentes%'
		and definicion not like '%Diccionario%'
		and definicion like '%décima-estancia%';
	if v_cuantas <> 1 then
		raise exception 'La definición no ha quedado como se pretendía.';
	end if;

	-- Que la arquitectura no ha ganado esquemas: sigue con el suyo y solo con el suyo.
	select count(*) into v_cuantas
	from public.esquemas_rima where arquitectura_id = v_arq;
	if v_cuantas <> 1 then
		raise exception 'La arquitectura tiene % esquemas y debía seguir con uno.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.esquemas_rima where arquitectura_id = v_arq and notacion = 'ababcdcdee';
	if v_cuantas <> 1 then
		raise exception 'El esquema de la edición de Elisa Dido ha cambiado y no debía tocarse.';
	end if;

	-- Y que con esto no queda ninguna forma activa del catálogo sin fuente, que es lo que cierra.
	select count(*) into v_cuantas
	from public.formas_metricas f
	where f.activo and not exists (
		select 1 from public.afirmaciones_fuentes_metricas a
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.esquemas_rima e on e.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma ar2 on ar2.arquitectura_id = e.arquitectura_id
		where coalesce(a.forma_id, ar.forma_id, ar2.forma_id) = f.forma_id
	);
	if v_cuantas <> 0 then
		raise exception 'Todavía quedan % formas activas sin ninguna afirmación de fuente.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
