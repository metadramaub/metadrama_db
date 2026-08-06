-- La silva: definición, descripciones y las seis fuentes.
--
-- Cuarta forma de la revisión, 12 secuencias. La primera en la que las fuentes obligan a
-- registrar cosas que el catálogo **no** recoge, en vez de a corregir lo que recoge.
--
-- Lo primero fue una sospecha equivocada, y conviene dejarla escrita. Vistas solo por sus
-- esquemas, «Consonante de orden libre» y «Libre» parecían la misma arquitectura: mismo
-- conjunto métrico de siete y once, misma rima consonante sin notación. No lo son. Las separa
-- el rasgo `Organización en pareados`, que declaran las dos —Predominantes y Ninguna— y que
-- es el eje real de esta forma. Mirar los esquemas y no los rasgos daba una duplicación que
-- no existe.
--
-- Lo que sí había que arreglar es que ese eje se dijera **tres veces**: como valor del rasgo,
-- como nota del rasgo y otra vez en la descripción de la arquitectura. La ficha imprime las
-- dos primeras, así que la tercera sobra. Y la de «Consonante de orden libre» acababa en
-- «Cuánto organizan los pareados la serie lo observa el editor», que habla del registrador y
-- no de la silva.
--
-- Lo que las fuentes añaden y el catálogo no tiene:
--
-- · **La silva sin rima.** El Diccionario dice que «también se considera silva la combinación
--   de endecasílabos y heptasílabos sin rima», y Jauralde que la silva moderna es normalmente
--   de versos blancos. El catálogo exige rima consonante en las cuatro arquitecturas, y con
--   razón para este corpus: Navarro Tomás data en 1588 la práctica de Lope de intercalar
--   pareados en pasajes de siete y once **sueltos**, de modo que en la comedia lo que separa
--   la silva del pasaje suelto es justamente que haya rima. Se registra la definición amplia
--   como afirmación, y la definición del catálogo dice de qué silva habla.
--
-- · **La silva 4 de Morley y Bruerton** —siete y once mezclados, todas las rimas en los
--   pares— sigue sin estar en el catálogo. Ya figuraba como pregunta al IP; ahora figura
--   además como afirmación, para que se lea en la ficha aunque no se modele.
--
-- · **«Silva libre» no significa en la bibliografía lo que significa aquí.** El Diccionario
--   recoge la de Isabel Paraíso: versos de distinta medida, par e impar, sin estrofas y
--   generalmente sin rima, con subtipos impar, par, híbrida y mixta. La arquitectura «Libre»
--   del catálogo es de siete y once con rima consonante: otra cosa. Esto responde con fuente
--   la primera pregunta abierta de la silva en `cuestiones-para-el-ip.md`, y la descripción
--   de la arquitectura lo advierte.

begin;

do $$
declare
	v_forma uuid;
	v_regular uuid;
	v_irregular uuid;
	v_endeca uuid;
	v_libre uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	select arquitectura_id into v_regular from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'consonante_regular';
	select arquitectura_id into v_irregular from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'consonante_irregular';
	select arquitectura_id into v_endeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica';
	select arquitectura_id into v_libre from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'libre';

	if num_nonnulls(v_forma, v_regular, v_irregular, v_endeca, v_libre) <> 5 then
		raise exception 'Falta la silva o alguna de sus cuatro arquitecturas';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición: qué es la silva, y de qué silva habla el catálogo.
	update public.formas_metricas
	set definicion = 'Serie abierta de endecasílabos y heptasílabos —o solo de endecasílabos— con rima consonante dispuesta libremente y sin división posible en estrofas simétricas, que admite versos sueltos. Lo que cambia de una realización a otra es cuánto organizan los pareados la serie, desde el par sistemático hasta su ausencia. La rima es aquí condición: un pasaje de siete y once enteramente suelto no es una silva.'
	where forma_id = v_forma;

	-- Cada arquitectura dice lo suyo, y calla el grado de pareados, que declara el rasgo.
	update public.arquitecturas_forma
	set descripcion = 'Alterna heptasílabo y endecasílabo en pareados que se suceden sin excepción, de modo que el pareado funciona aquí como unidad. Es la que la tradición llama silva de consonantes.'
	where arquitectura_id = v_regular;

	update public.arquitecturas_forma
	set descripcion = 'Heptasílabos y endecasílabos sin orden fijo de medida ni de rima, con versos sueltos entre los rimados. Es la silva ordinaria, y la más frecuente del corpus.'
	where arquitectura_id = v_irregular;

	update public.arquitecturas_forma
	set descripcion = 'Serie exclusivamente endecasilábica. Es la realización más tardía en la comedia: aparece unos quince años después que la de siete y once.'
	where arquitectura_id = v_endeca;

	update public.arquitecturas_forma
	set descripcion = 'Realización de siete y once cuya rima no llega a formar pareados. «Libre» nombra aquí ese extremo de la escala; no la silva libre moderna, que es una serie de medidas mezcladas y por lo común sin rima.'
	where arquitectura_id = v_libre;

	-- Al esquema métrico de la libre le faltaba la descripción que sus hermanas sí tienen.
	update public.esquemas_metricos em
	set descripcion = 'Cada verso puede ser heptasílabo o endecasílabo sin una secuencia posicional fija.'
	where em.arquitectura_id = v_libre and em.descripcion is null;

	-- Las denominaciones que el Diccionario documenta.
	insert into public.denominaciones_metricas
		(forma_id, arquitectura_id, nombre, slug_normalizado, tipo_alias, preferente)
	values
		(v_forma, null, 'Silva imperfecta', 'silva_imperfecta', 'equivalente', false),
		(v_forma, null, 'Canción libre', 'cancion_libre', 'equivalente', false),
		(null, v_regular, 'Silva de consonantes', 'silva_de_consonantes', 'equivalente', false)
	on conflict do nothing;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma where forma_id = v_forma
		);

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	values
		-- Hasta dónde llega el nombre fuera de este corpus.
		(v_dicc, v_forma, null, 'Entrada «silva», p. 394',
			'Admite como silva también la combinación de endecasílabos y heptasílabos **sin rima**, que el catálogo deja fuera porque en la comedia ese pasaje se anota como serie suelta. Recoge además «silva imperfecta» y «canción libre» como otros nombres de la forma.',
			'alta'),

		-- Por qué la regular declara el pareado como sección.
		(v_dicc, null, v_regular, 'Entrada «silva de consonantes», p. 397',
			'Sostiene que la silva de consonantes es «en realidad una forma estructurada en pareados, que constituyen su unidad estrófica». De ahí que esta arquitectura, sola entre las cuatro, declare el pareado como parte de su esquema de rima.',
			'alta'),

		-- El aviso de nombre.
		(v_dicc, null, v_libre, 'Entrada «silva libre», p. 398',
			'Recoge la silva libre de Isabel Paraíso: composición de versos de distinta medida, par e impar, que no se organiza en estrofas y generalmente prescinde de la rima, con subtipos impar, par, híbrida y mixta. Es un concepto del verso libre contemporáneo y no coincide con la arquitectura que aquí lleva ese nombre.',
			'alta'),

		-- Una realización que el catálogo no recoge, y que no es la de Morley y Bruerton.
		(v_dicc, v_forma, null, 'Entrada «silva arromanzada», p. 395',
			'Registra la silva arromanzada o silva-romance, en la que todos los versos pares llevan una misma rima **asonante**. El catálogo no la recoge: sus cuatro realizaciones son consonantes.',
			'alta'),

		-- Qué hacen los poetas con una serie que no admite estrofas.
		(v_quilis, v_forma, null, 'p. 164',
			'Matiza que, siendo la silva un poema no estrófico, los poetas suelen dividirla en formas **paraestróficas** desiguales que recuerdan las estancias de la canción. La agrupación existe, pues, aunque no sea regular ni se pueda declarar de antemano.',
			'alta'),

		-- Cómo entra en la comedia, que es lo que este corpus recoge.
		(v_navarro, v_forma, null, '§ 158',
			'Data la silva teatral con precisión: desde 1588 Lope intercaló pareados en los pasajes de sus comedias escritos en endecasílabos y heptasílabos **sueltos**; la silva de endecasílabos solos aparece desde 1604, en Don Juan de Austria en Flandes; y la silva ordinaria de siete y once es la de las Soledades de Góngora, compuesta la primera en 1613. La silva dramática nace, por tanto, de rimar un pasaje que antes iba suelto.',
			'alta'),

		-- Lo que la define, y la excepción que confirma la regla.
		(v_cap14, v_forma, null, 'p. 228',
			'Fija como característica de la silva que sea imposible dividirla en estrofas simétricas y que pueda llevar versos sin rima. Señala que la silva de consonantes es la excepción, porque se ajusta al esquema de pareados o tercetos, y pone como ejemplo el comienzo de La vida es sueño de Calderón.',
			'alta'),

		-- El nombre y su suerte en el teatro.
		(v_jauralde, v_forma, null, '«Series» → «Silva»',
			'Describe la silva primitiva como heptasílabos y endecasílabos con rima consonante dispuesta de manera aleatoria, y sitúa su origen a comienzos del siglo XVII, con Quevedo antes de las Soledades. Registra que la combinación de siete y once acabó llamándose silva de consonantes y se adoptó como variedad teatral, y que la silva moderna, de base 4-7-11-14, es normalmente de versos blancos.',
			'alta'),

		-- La tipología sobre la que se data a Lope, y el tipo que aquí falta.
		(v_mb, v_forma, null, 'Cap. V, «Silva»',
			'Distinguen cuatro tipos: la silva de consonantes aAbBcC; los versos de siete y once mezclados irregularmente, con algunos sin rima; los de once sílabas solos, la mayoría rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**. El catálogo recoge los tres primeros; el cuarto no está modelado ni aparece en el corpus.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Silva · definición, 4 descripciones, 3 denominaciones y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
