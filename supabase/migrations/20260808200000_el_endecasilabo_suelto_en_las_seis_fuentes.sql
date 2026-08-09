-- El endecasílabo suelto contrastado con las seis fuentes autorizadas.
--
-- Se dejó expresamente para el final por decisión del IP, por ser el más problemático. Tras
-- leer las seis, el problema resulta menor de lo temido: **las fuentes coinciden con lo que el
-- catálogo ya modela** y, sobre todo, dan el criterio cuantitativo que faltaba.
--
-- 1. **La restricción `versos_sueltos = predominantes` tiene ahora fuente y umbral.** El
--    catálogo decía «predominan los versos sueltos» sin poder apoyarlo en nadie. Morley y
--    Bruerton, describiendo la versificación de Lope, lo cuantifican: clasifican un pasaje como
--    sueltos «cuando el porcentaje de los versos rimados es menos de 50». Eso es exactamente lo
--    que el catálogo quería decir, y ahora se puede citar. No se convierte el umbral en dato
--    computable —el catálogo no cuenta versos rimados— pero deja de ser una afirmación huérfana.
--
-- 2. **Los tres rasgos del catálogo están documentados, y eso valida el modelo.** Morley y
--    Bruerton dicen que cada pasaje acaba generalmente en un pareado —el rasgo `distico_final`—
--    y que en las últimas comedias de Lope se insertaban con frecuencia creciente dísticos en
--    el conjunto del pasaje —el rasgo `organizacion_en_pareados` con valor «ocasionales»—. Los
--    dos rasgos que el catálogo pregunta son los dos que la fuente del corpus observa.
--
-- 3. Tiene nombres y no tenía ninguno: **verso blanco**, **verso suelto** y **poema de verso
--    suelto**, que el Diccionario da como términos de la misma realidad. Se codifican como
--    denominaciones de la forma.
--
-- 4. Es forma del teatro áureo, y conviene que conste. Navarro Tomás dedica su § 118 al
--    endecasílabo suelto y documenta que Jerónimo Bermúdez compuso en él sus tragedias *Nise
--    lastimosa* y *Nise laureada*, de 1577, mezclando además endecasílabos y heptasílabos
--    sueltos. Es el respaldo de que la forma pertenece a un catálogo de verso dramático.
--
-- 5. Queda anotada una tensión que **no se resuelve aquí**: Caparrós 2014 llama al verso suelto
--    «una clase de silva», y el catálogo los tiene como formas distintas relacionadas por
--    `contrasta_con`. La relación ya dice en qué se diferencian —predominio de sueltos frente a
--    predominio de rimados—, que es justamente el eje que Morley y Bruerton cuantifican. No se
--    fusionan: el criterio del proyecto separa por cuánto organiza la rima la serie, y las seis
--    fuentes no lo contradicen; lo que hace Caparrós es clasificar, no identificar.
--
-- 6. La bibliografía documenta series sueltas de otras medidas —heptasílabos de Francisco de la
--    Torre, octosílabos de Hurtado de Mendoza, pentasílabos en el Diccionario— que esta forma no
--    cubre, por ser endecasilábica por definición. Queda como duda para el IP.
--
-- No se toca ninguna secuencia real: las seis que hoy usan `endecasilabo_suelto_puro` siguen
-- resolviendo igual.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas
	where slug = 'endecasilabo_suelto';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica';

	if num_nonnulls(
		v_forma, v_arq, v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 8 then
		raise exception 'Falta el endecasílabo suelto vigente, su arquitectura o una fuente';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	update public.formas_metricas
	set definicion = 'Serie abierta de endecasílabos sin rima regular, en la que los versos sueltos predominan sobre los rimados. Admite pareados intercalados de manera ocasional y suele cerrarse con un dístico; una modalidad encadena la rima final de cada verso con el interior del siguiente. Nació del intento renacentista de acercar el verso romance al latino, que prescinde de la rima.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Serie abierta de endecasílabos en la que predominan los versos sueltos. Los pareados intercalados, el dístico final y el encadenamiento interior los observa el editor.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- Los nombres con que la bibliografía designa esta misma realidad.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Verso suelto', 'verso_suelto', false, v_dicc),
		(v_forma, 'Verso blanco', 'verso_blanco', false, v_dicc),
		(v_forma, 'Poema de verso suelto', 'poema_de_verso_suelto', false, v_dicc);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafe «Sueltos»',
		 'Los definen como endecasílabos sin rima y precisan el criterio con que clasifican un pasaje: lo cuentan como sueltos cuando el porcentaje de los versos rimados es menor del 50 por ciento. Observan que cada pasaje acaba generalmente en un pareado y que en las últimas comedias de Lope de Vega se insertaban con frecuencia creciente dísticos en el conjunto de cada pasaje.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 6.4.3',
		 'Explica que en la Italia del siglo XVI aparecen composiciones caracterizadas por la ausencia de rima entre sus versos, los *versi sciolti*, por imitación de la poesía latina clásica o por exigencias de la música, y que Boscán introduce esta forma en España empleando el endecasílabo. Señala que el poema de versos sueltos se usó para epístolas y sátiras, y a veces en poemas líricos o narrativos, y que resulta muy útil para las traducciones, donde la búsqueda de la rima puede resultar forzada.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§ 118',
		 'Explica que el endecasílabo sin rima nació del intento renacentista de asemejar la versificación romance a la latina y que los poetas italianos del siglo XVI lo introdujeron en traducciones. Boscán fue el primero en aplicarlo en español, en su *Historia de Leandro y Ero*, seguido por Garcilaso en la epístola dirigida a él y por Hernando de Acuña, fray Luis de León, Agustín de Rojas y Francisco de la Torre. Advierte que requiere una clara construcción rítmica para suplir la ausencia de rima. Documenta su uso dramático: Jerónimo Bermúdez compuso en endecasílabos sueltos *Nise lastimosa* y *Nise laureada*, de 1577, donde además mezcló endecasílabos y heptasílabos sueltos.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 232-233',
		 'Presenta el verso suelto, libre o blanco como una clase de silva en la que ninguno de los versos de la serie lleva rima. Señala que, aunque Francisco de la Torre ensayó el heptasílabo sin rima, la forma más frecuente es la serie de endecasílabos solos o con algún heptasílabo, que su modelo es italiano y que la introduce Garcilaso en su «Epístola a Boscán». Añade que por carecer de rima se consideró más cercano al verso latino, por lo que se emplea en traducciones y se aconseja para asuntos heroicos.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entrada «verso suelto»',
		 'Lo define como clase de verso regular que no lleva rima y señala que sus formas más frecuentes son las series de endecasílabos, heptasílabos y pentasílabos, solos o combinados entre sí, sobre modelo italiano. Explica que al renunciar a uno de los elementos rítmicos exige estar más trabajado, porque cualquier prosaísmo se nota enseguida, y que por eso se tuvo por más difícil que el verso rimado. Recoge poema de verso suelto, poesía suelta y verso blanco como otros términos.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados sobre la rima y el verso libre',
		 'Distingue la desaparición sistemática de la rima, que llama verso blanco, de la esporádica, que llama verso suelto, y advierte que ninguna de las dos configura por sí sola un verso libre, porque el verso puede mantener intacta su estructura silábica y tonal al margen de la rima. Explica que desde el siglo XVI se conoce el verso blanco como serie de versos que no riman, y que en ella la percepción de la serie descansa en la igualdad silábica: una sucesión indeterminada de endecasílabos forma poema porque todos comparten medida y periodo rítmico.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El Endecasílabo suelto debe tener seis afirmaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.denominaciones_metricas where forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'El Endecasílabo suelto debe declarar tres denominaciones, no %', v_n;
	end if;

	-- Los tres rasgos que el editor observa siguen siendo los mismos.
	select count(*) into v_n from public.arquitectura_rasgos where arquitectura_id = v_arq;
	if v_n <> 3 then
		raise exception 'El Endecasílabo suelto debe conservar sus tres rasgos, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
