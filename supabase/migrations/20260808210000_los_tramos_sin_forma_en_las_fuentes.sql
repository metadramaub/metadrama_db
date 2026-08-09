-- Los dos tramos sin forma contrastados con las seis fuentes autorizadas.
--
-- Se dejaron para el final porque **no tienen norma que contrastar**: no son formas métricas
-- sino salidas del registrador para cuando el pasaje no conserva una identidad reconocible. Esa
-- decisión es metodológica del proyecto y ninguna fuente la toma por él. Lo que sí hacen las
-- fuentes es documentar los dos conceptos, y de ahí salen tres cosas.
--
-- 1. **Queda resuelta la duda del IP sobre el nombre «Verso aislado».** Se dudaba si debía ser
--    la etiqueta pública definitiva. El Diccionario registra la entrada «verso único», que
--    atribuye a Navarro Tomás y define como «verso que no se integra en la estructura de una
--    estrofa», y al explicarla emplea literalmente la expresión **«un verso aislado»**. El
--    nombre elegido no es una invención del catálogo: es el término con el que la bibliografía
--    describe el concepto. Se conserva, y «Verso único» se declara como denominación.
--
-- 2. **La versificación irregular excluye la combinación de verso largo y quebrado, y eso es un
--    límite operativo que conviene tener escrito.** El Diccionario advierte expresamente que la
--    combinación de versos largos con sus quebrados —octosílabo y tetrasílabo, endecasílabo y
--    heptasílabo, alejandrino y heptasílabo— **no se considera versificación irregular**, y
--    Caparrós 2014 lo repite al definir la versificación regular como la que obedece a una regla
--    de igualdad o proporcionalidad. Es justamente el caso de la copla de pie quebrado y de la
--    sextilla de pie quebrado: un pasaje 8-8-4 no es irregular por serlo. La definición lo dice
--    ahora, porque es el error de registro más fácil de cometer.
--
-- 3. Jauralde discrepa del nombre y merece constar: dice que suele darse el nombre de
--    versificación irregular a un conjunto o poema que no busca ninguna proporción aparente,
--    pero que él prefiere para esos casos «verso libre o liberado». El catálogo conserva
--    «Versificación irregular» porque es el término de las otras fuentes y el del vocabulario
--    legado, y registra la divergencia.
--
-- Ni Quilis ni Morley y Bruerton tratan ninguno de los dos conceptos como categoría de
-- registro: Quilis describe la irregularidad dentro de sistemas concretos y Morley y Bruerton
-- clasifican todo pasaje de Lope en alguna forma métrica. Ese silencio se declara también,
-- porque significa que la salida del registrador es una decisión del proyecto y no un término
-- que la bibliografía le ofreciera hecho.
--
-- No se toca ninguna secuencia real. Sigue habiendo un uso legado de `irregular`.

begin;

do $$
declare
	v_irregular uuid;
	v_aislado uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_irregular from public.formas_metricas where slug = 'irregular';
	select forma_id into v_aislado from public.formas_metricas where slug = 'verso_aislado';

	if num_nonnulls(
		v_irregular, v_aislado, v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 8 then
		raise exception 'Faltan los tramos sin forma vigentes o una fuente autorizada';
	end if;

	-- La definición incorpora el límite que las fuentes marcan: el quebrado no es irregular.
	update public.formas_metricas
	set definicion = 'Pasaje de dos o más versos cuya organización métrica no permite reconocer razonablemente una forma del catálogo. Se utiliza solo cuando el conjunto no conserva una identidad conocida que pueda describirse mediante desviaciones localizadas. La combinación regular de un verso largo con su quebrado —octosílabo y tetrasílabo, endecasílabo y heptasílabo— no es versificación irregular: obedece a una proporción y pertenece a la forma que la declara.',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_irregular;

	update public.formas_metricas
	set definicion = 'Un único verso que no puede integrarse en la forma métrica anterior ni en la siguiente y que tampoco constituye una desviación interna de ninguna de ellas.',
		estado_revision = 'revisada',
		updated_at = now()
	where forma_id = v_aislado;

	-- «Verso único» es el término con que la bibliografía nombra este caso.
	delete from public.denominaciones_metricas where forma_id = v_aislado;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values (v_aislado, 'Verso único', 'verso_unico', false, v_dicc);

	delete from public.denominaciones_metricas where forma_id = v_irregular;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values (v_irregular, 'Versificación anisosilábica', 'versificacion_anisosilabica', false, v_dicc);

	-- Versificación irregular: las cuatro fuentes que tratan el concepto.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_irregular;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_navarro, v_irregular, '§ 6',
		 'Al clasificar los versos por su medida llama libres a los amétricos que no obedecen ni a igualdad de número de sílabas ni a uniformidad de cláusulas, y considera modalidad semilibre el verso fluctuante, cuya ametría no excede de un margen relativamente limitado en torno a determinadas medidas con las que a veces coincide. Trata así la irregularidad como una clase de verso, no como una categoría en la que clasificar un pasaje.',
		 'alta', 'revisada'),
		(v_cap14, v_irregular, 'pp. 45-46 y 159',
		 'Hace del número de sílabas el criterio que distingue versificación regular e irregular: en la regular, el número de sílabas de los distintos versos obedece a una regla de igualdad o de proporcionalidad, y esta última cubre expresamente el caso de los versos largos mezclados con sus quebrados. Clasifica dentro de la irregular la versificación fluctuante, la acentual, la libre, la de cláusulas y los intentos de versificación cuantitativa.',
		 'alta', 'revisada'),
		(v_dicc, v_irregular, 'Entrada «versificación irregular»',
		 'La define como la que no se rige por el principio de igualdad o regularidad en el número de sílabas métricas de los versos que forman la composición. Advierte expresamente que la combinación de versos largos con sus quebrados —octosílabo y tetrasílabo, endecasílabo y heptasílabo, alejandrino y heptasílabo— no se considera versificación irregular. Enumera como tipos clasificables la versificación fluctuante, la acentual, la libre, la de cláusulas y los intentos de versificación cuantitativa, y recoge «anisosilabismo» como otro término.',
		 'alta', 'revisada'),
		(v_jauralde, v_irregular, 'Apartado sobre el verso libre',
		 'Observa que suele darse el nombre de versificación irregular no al verso suelto, sino a un conjunto o poema cuando no busca ningún tipo de proporción aparente, y declara que él prefiere para esos casos el nombre de «verso libre o liberado». Precisa que el verso libre se produce cuando el número de sílabas es desigual y el sistema de acentos no es igual ni proporcional; si la medida es igual o proporcional pero el sistema tonal no se adecua a los patrones tradicionales, los versos serán extraños o irregulares, no libres.',
		 'alta', 'revisada');

	-- Verso aislado: las dos fuentes que documentan el verso que no se integra en estrofa.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_aislado;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_navarro, v_aislado, '§ 76',
		 'Al describir la glosa explica que la del mote comprendía regularmente tres partes y que la primera era el mote, en un solo verso, seguido de una paráfrasis breve en redondilla o quintilla que terminaba repitiéndolo. El verso único queda así integrado en una composición mayor sin pertenecer a la estrofa que lo glosa.',
		 'alta', 'revisada'),
		(v_dicc, v_aislado, 'Entrada «verso único»',
		 'Recoge de Navarro Tomás el verso único, definido como el que no se integra en la estructura de una estrofa, y observa que desde el punto de vista rítmico siempre podrá discutirse si un verso aislado es realmente un verso, puesto que falta la repetición, base del ritmo. Señala que el mote es el caso más apreciable, por seguirle una glosa en verso, y que proverbios, refranes y pensamientos condensados adoptan con frecuencia el esquema rítmico de un verso de estructura definida.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_irregular;
	if v_n <> 4 then
		raise exception 'La Versificación irregular debe tener cuatro afirmaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_aislado;
	if v_n <> 2 then
		raise exception 'El Verso aislado debe tener dos afirmaciones, no %', v_n;
	end if;

	-- Siguen sin ser formas: ninguna arquitectura, ni norma que declarar.
	select count(*) into v_n from public.arquitecturas_forma
	where forma_id in (v_irregular, v_aislado);
	if v_n <> 0 then
		raise exception 'Los tramos sin forma no pueden tener arquitecturas, y hay %', v_n;
	end if;

	select count(*) into v_n from public.formas_metricas
	where forma_id in (v_irregular, v_aislado) and tipo_registro = 'sin_forma';
	if v_n <> 2 then
		raise exception 'Los dos tramos deben conservar tipo_registro = sin_forma';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
