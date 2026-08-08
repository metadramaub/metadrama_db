-- El sexteto contrastado con las seis fuentes autorizadas.
--
-- El catálogo lo definía como estrofa de seis versos de arte mayor con rima consonante y
-- disposición variable, y solo declaraba la afirmación de Caparrós 2014. La lectura de las
-- seis fuentes obliga a corregir cuatro cosas.
--
-- 1. La delimitación por arte mayor es del proyecto, no de la bibliografía. El Diccionario
--    advierte que «a veces se aplica también este término a la estrofa cuando está compuesta
--    en versos de arte menor», y Caparrós 2014 llama sexteto a la estrofa «de arte mayor, o
--    de arte mayor y menor combinados entre sí». Jauralde aparta un grupo de «sextetos
--    mixtos» y Navarro Tomás documenta sextetos que mezclan heptasílabos y endecasílabos. El
--    criterio del IP para el corpus se conserva —la heterometría regular con endecasílabo
--    pertenece al sexteto-lira, y el arte menor a la sextilla—, pero deja de presentarse como
--    si fuera la definición común: la definición dice ahora que el isosilabismo es lo que el
--    catálogo exige, y cada afirmación deja ver dónde su fuente es más amplia.
--
-- 2. La consonancia tampoco es universal en las fuentes. Navarro Tomás registra la estrofa
--    asonante abcbDB de Darío y tipos que dejan sueltos varios versos. En el corpus áureo la
--    consonancia es la norma, de modo que se mantiene en las arquitecturas y la excepción
--    queda documentada en la afirmación que la recoge.
--
-- 3. El repertorio de medidas 11-12-14 es un recorte del corpus. Jauralde describe además
--    sextetos eneasilábicos, decasilábicos y pentadecasilábicos. Las tres arquitecturas se
--    conservan porque son las que el corpus documenta; su descripción dice de qué medida es
--    cada una y cuándo se cultivó, que es lo que las distingue entre sí.
--
-- 4. El nombre de la variedad ABABCC está disputado y el catálogo solo recogía una lectura.
--    Caparrós 2014, el Diccionario y Navarro Tomás la llaman sexta rima. Jauralde la llama
--    sextina real y reserva «sexta rima» para la composición de treinta y nueve versos que el
--    catálogo registra como Sextina; el Diccionario, que remite «sextina real» y «sextina
--    antigua» a sexta rima, confirma que ambos nombres circulan para la misma estrofa. Se
--    conserva «Sexta rima» como nombre de la variedad, por ser el mayoritario, y los otros dos
--    se declaran como denominaciones para que la discrepancia sea consultable. La relación con
--    la Sextina explica que el nombre compartido no significa forma compartida.
--
-- Quilis es la única de las seis que no define el sexteto como estrofa general: entre las
-- estrofas de seis versos pasa de la sextina al sexteto-lira, la sexta rima y la sextilla.
-- Morley y Bruerton emplean «sexteto» solo para los seis versos que siguen a los cuartetos
-- del soneto. Las dos ausencias se registran igual que una definición, porque miden hasta qué
-- punto la forma general está fijada y confirman que no es una unidad del repertorio áureo.
--
-- No se toca ninguna secuencia real. Ningún término legado propone hoy la forma Sexteto: los
-- usos de sexteto en las obras son todos de sexteto_lira, que es otra forma.

begin;

do $$
declare
	v_forma uuid;
	v_endeca uuid;
	v_dodeca uuid;
	v_alejandrina uuid;
	v_variedad uuid;
	v_sextina uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sexteto';
	select arquitectura_id into v_endeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica';
	select arquitectura_id into v_dodeca from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'dodecasilabica';
	select arquitectura_id into v_alejandrina from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'alejandrina';
	select variedad_id into v_variedad from public.variedades_arquitectura
	where arquitectura_id = v_endeca and slug = 'sexta_rima';
	-- La composición de treinta y nueve versos, no la estrofa homónima de seis.
	select forma_id into v_sextina from public.formas_metricas where slug = 'sextina';

	if num_nonnulls(
		v_forma, v_endeca, v_dodeca, v_alejandrina, v_variedad, v_sextina,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 12 then
		raise exception 'Falta el sexteto vigente, una de sus partes o una fuente autorizada';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- La definición dice qué es la forma y qué exige el catálogo, sin enumerar lo que la
	-- ficha lista debajo ni contar de qué término legado vino.
	update public.formas_metricas
	set definicion = 'Estrofa de seis versos isosilábicos de arte mayor con rima consonante, cuya disposición no está fijada. Es una forma general: la norma exige la consonancia y la igualdad de medida, pero no un orden de rimas, de modo que cada realización se registra por el esquema observado. La disposición ABABCC, la más difundida, recibe el nombre de sexta rima.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	-- Cada descripción dice lo que distingue a esa medida de sus hermanas.
	update public.arquitecturas_forma
	set descripcion = 'Seis endecasílabos. Es la realización más frecuente y la única que el Siglo de Oro documenta, aunque con escasez.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_endeca;

	update public.arquitecturas_forma
	set descripcion = 'Seis dodecasílabos, medida que cultivaron sobre todo los poetas modernistas.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_dodeca;

	update public.arquitecturas_forma
	set descripcion = 'Seis alejandrinos, a menudo repartidos en dos semiestrofas simétricas de tres versos cuyos finales riman entre sí en agudo.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_alejandrina;

	-- La variedad explica su disposición sin repetir la definición de la forma.
	update public.variedades_arquitectura
	set descripcion = 'Los cuatro primeros versos alternan dos rimas y los dos últimos cierran con un pareado de tercera rima, ABABCC, la disposición de la octava real reducida a seis versos.',
		estado_revision = 'revisada',
		updated_at = now()
	where variedad_id = v_variedad;

	-- Los otros nombres que la bibliografía da a esta variedad. El destino es la variedad, y
	-- solo la variedad: la restricción de la tabla admite un único destino por denominación.
	delete from public.denominaciones_metricas where variedad_id = v_variedad;
	insert into public.denominaciones_metricas (
		variedad_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_variedad, 'Sexteto clásico', 'sexteto_clasico', false, null),
		(v_variedad, 'Sextina real', 'sextina_real', false, v_jauralde),
		(v_variedad, 'Sextina antigua', 'sextina_antigua', false, v_dicc);

	-- El nombre compartido con la Sextina no significa forma compartida.
	delete from public.forma_relaciones
	where forma_origen_id = v_forma and forma_destino_id = v_sextina
		and tipo_relacion = 'contrasta_con';
	insert into public.forma_relaciones (
		forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
	)
	values (
		v_forma, v_sextina, 'contrasta_con',
		'Parte de la bibliografía llama sexta rima a la composición de treinta y nueve versos y sextina real a la estrofa ABABCC de seis. Son formas distintas: la composición encadena seis estrofas y un remate repitiendo las mismas palabras finales, sin que sus versos rimen entre sí; la estrofa de seis versos rima en consonante y puede repetirse libremente.',
		'revisada'
	);

	-- Una afirmación autosuficiente por cada una de las seis fuentes: dice lo que dice su
	-- fuente, sin opinar sobre el catálogo ni dar por sabido lo dicho en otra.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas», epígrafe «Soneto»',
		 'En su repertorio de las formas métricas de Lope de Vega, «sexteto» nombra únicamente los seis versos que siguen a los dos cuartetos del soneto, cuyas rimas describen como variables: CDCDCD, CDECDE, CDEDCE, CDCEDE y otras. No figura entre las estrofas del repertorio dramático.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 5.4.5',
		 'Entre las estrofas de seis versos registra la sextina, el sexteto-lira, la sexta rima y la sextilla, sin definir un sexteto general que las abarque. Describe la sexta rima como estrofa de procedencia italiana formada por seis endecasílabos que riman ABABCC, de poco uso en el Barroco y mayor difusión en el Neoclasicismo; admite variantes como el endecasílabo oxítono, una combinación que empareja los dos primeros versos y los dos siguientes dejando rimar entre sí los agudos tercero y sexto, y la introducción de un verso de arte menor.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 160, 228 y 367',
		 'Señala que el sexteto de endecasílabos ABABCC se usó poco en el Siglo de Oro, frente a su frecuencia en italiano, y que progresó en el Neoclasicismo con variantes como ABBACC. En el modernismo cuenta manifestaciones escasas y muy diversas: la estrofa asonante de heptasílabos y endecasílabos abcbDB, los tipos simétricos de dos semiestrofas AAB:CCB y AaB:CcB, y la disposición de rimas alternas ABABAB.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 198-199',
		 'Llama sexteto a la estrofa de seis versos cuando son de arte mayor, o de arte mayor y menor combinados entre sí, y reserva el nombre de sextilla para la de arte menor. Define la sexta rima como el sexteto de endecasílabos con esquema ABABCC. Recoge además el sexteto de alejandrinos que tiene agudos y rimados entre sí los versos tercero y sexto.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entradas «sexteto» y «sexta rima»',
		 'Define el sexteto como estrofa de seis versos de arte mayor, normalmente endecasílabos, con rima consonante que puede adoptar variadas disposiciones, y advierte que a veces el término se aplica también a la estrofa compuesta en versos de arte menor. La sexta rima es el sexteto de endecasílabos que rima el primero con el tercero, el segundo con el cuarto y el quinto con el sexto, con modificaciones posibles del esquema e introducción de heptasílabos desde el Romanticismo. Tipifica además el sexteto agudo, el alterno, el correlativo, el enlazado, el libre y el simétrico.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Estrofas de seis versos», «Sextetos» y «Sextina real»',
		 'Distingue las sextillas, de arte menor, de los sextetos, de arte mayor, y aparta como grupo propio los sextetos mixtos, los sextetos-lira y los simétricos, compuestos por dos series de tres versos. Describe sextetos eneasilábicos, decasilábicos, endecasilábicos, dodecasilábicos, de alejandrinos y pentadecasilábicos. Llama sextina real al sexteto de endecasílabos rimado a la manera de la octava real con pareado final, ABABCC, y lo documenta en Herrera, Cervantes, Lope de Vega y Bocángel.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El Sexteto debe tener seis afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n from public.afirmaciones_fuentes_metricas a
	where a.forma_id = v_forma
		and a.fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'Las seis afirmaciones del Sexteto deben ser de seis fuentes distintas';
	end if;

	select count(*) into v_n from public.denominaciones_metricas
	where variedad_id = v_variedad;
	if v_n <> 3 then
		raise exception 'La sexta rima debe declarar tres denominaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.arquitecturas_forma
	where forma_id = v_forma and activo;
	if v_n <> 3 then
		raise exception 'El Sexteto debe tener tres arquitecturas activas, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
