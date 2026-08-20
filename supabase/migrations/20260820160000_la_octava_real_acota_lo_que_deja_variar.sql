-- La octava real acota lo que deja variar
--
-- Revisión de su prosa y de su norma de rima. La ficha decía **«Rima · No fijado»** y a renglón
-- seguido dibujaba `A B A B A B C C`: de las 57 arquitecturas activas era la única que salía así,
-- lo que ya avisaba de que era un hueco de dato y no una categoría en uso.
--
-- El hueco: el catálogo declaraba una sola disposición, `ABABABCC`, marcada `habitual`, y nada
-- más. La derivación —«un solo esquema cerrado y no definitorio»— concluye con razón que la norma
-- no fija nada. Y marcarlo `definitoria` habría sido falso, porque las fuentes documentan
-- variantes. Lo que dicen es más preciso:
--
--   * Morley y Bruerton la definen **sin variantes**, `ABABABCC`;
--   * el *Diccionario* advierte que «es posible, aunque no frecuente, encontrar otra disposición
--     de la rima **de los seis primeros versos**»;
--   * Jauralde, que «recibió variaciones de todo tipo a lo largo del tiempo, conservando casi
--     siempre de manera fija **el pareado final**».
--
-- O sea: la norma acota **tres clases de rima**, deja variar el orden de los seis primeros y
-- conserva el pareado. Eso es lo que se declara ahora, con un segundo esquema abierto de
-- modalidad `excepcional` y la restricción `numero_clases: 3`, y la fila pasa de «No fijado» a
-- **«Acotado»**. La restricción no se queda sin comprobar: el auditor contrasta `numero_clases`
-- contra los esquemas concretos de la arquitectura, y `ABABABCC` emplea exactamente tres.
--
-- La arquitectura era además una de las dos únicas activas sin descripción, así que la ficha
-- saltaba del nombre a la extensión. Ahora dice lo que las fuentes destacan y la definición no
-- cuenta: de dónde viene y para qué sirvió.
--
-- Y no tenía **ningún vínculo**. Se le dan los dos que las fuentes sostienen: el contraste con la
-- copla de arte mayor, que es la otra estrofa de ocho versos de arte mayor del catálogo, y el
-- parentesco con el sexteto, porque Jauralde describe la sexta rima como «un sexteto de
-- endecasílabos rimados a la manera de la octava real, con pareado final».
--
-- La afirmación de Caparrós 2014 se quedaba con la nota al pie —la remisión a Lázaro Carreter— y
-- dejaba fuera lo que la página afirma. Se completa con lo que dice el cuerpo.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_arte_mayor uuid;
	v_sexteto uuid;
	v_abierto uuid;
	v_concreto uuid;
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_actual text;
	v_n integer;

	c_descripcion constant text :=
		'La estrofa de la épica culta: Boccaccio la formó en la *Teseida* dando un pareado a los '
		|| 'dos últimos versos de la octava siciliana, Boscán la trajo a España y Ercilla la '
		|| 'consagró en *La Araucana*. Su prestigio la mantuvo en cantos heroicos y en materia '
		|| 'grave mucho después del Siglo de Oro.';

	c_nota_arte_mayor constant text :=
		'Las dos reparten ocho versos de arte mayor en dos mitades, y se separan por cómo las atan. '
		|| 'La copla de arte mayor las enlaza —una rima común a los dos cuartetos, y el cuarto '
		|| 'verso rimando con el quinto—, mientras que la octava real corre sobre dos rimas '
		|| 'alternas hasta cerrar con un pareado que estrena la tercera. Y la medida las separa '
		|| 'también: dodecasílabos partidos por cesura frente a endecasílabos.';

	c_nota_sexteto constant text :=
		'`ABABCC` y `ABABABCC` son la misma manera de rimar con dos versos de diferencia: '
		|| 'alternancia de dos clases y un pareado final que estrena la tercera. Por eso Jauralde '
		|| 'describe la sexta rima como un sexteto rimado a la manera de la octava real.';

	c_dc14 constant text :=
		'La define como combinación de ocho endecasílabos consonantes de esquema ABABABCC y recoge '
		|| '«octava rima» y «octava heroica» como sus otros nombres. La ejemplifica con el comienzo '
		|| 'de *La Araucana* de Ercilla, y remite en nota a la discusión de Lázaro Carreter sobre '
		|| 'si es una estrofa o la unión de dos.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'octava_real';
	select forma_id into v_arte_mayor from public.formas_metricas where slug = 'copla_de_arte_mayor';
	select forma_id into v_sexteto from public.formas_metricas where slug = 'sexteto';

	if v_forma is null or v_arte_mayor is null or v_sexteto is null then
		raise exception 'Falta la octava real, la copla de arte mayor o el sexteto.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica_consonante' and activo;
	if v_arq is null then
		raise exception 'La octava real no tiene su arquitectura activa.';
	end if;

	-- --------------------------------------- La norma declara lo que acota y lo que deja variar
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia
	)
	select v_arq, 'distribucion-variable', 'Distribución variable', null, a.tipo_rima_id,
		'excepcional', 'abierta'
	from public.arquitecturas_forma a
	where a.arquitectura_id = v_arq
	on conflict (arquitectura_id, slug) do update
		set nombre = excluded.nombre, modalidad = excluded.modalidad,
			tipo_secuencia = excluded.tipo_secuencia;

	select esquema_rima_id into v_abierto from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';

	if not exists (
		select 1 from public.esquema_rima_restricciones
		where esquema_rima_id = v_abierto and tipo = 'numero_clases'
	) then
		insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_numero)
		values (v_abierto, 'numero_clases', 3);
	else
		update public.esquema_rima_restricciones set valor_numero = 3
		where esquema_rima_id = v_abierto and tipo = 'numero_clases';
	end if;

	-- La restricción no es una opinión: se contrasta con la disposición que el catálogo declara.
	select esquema_rima_id into v_concreto from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'abababcc';

	if v_concreto is null then
		raise exception 'La octava real ha perdido su disposición ABABABCC.';
	end if;
	select count(distinct clase_rima) into v_n
	from public.esquema_rima_posiciones where esquema_rima_id = v_concreto;
	if v_n <> 3 then
		raise exception 'ABABABCC emplea % clases de rima, no las tres que la norma acota.', v_n;
	end if;

	-- ------------------------------------------------------------- La descripción que faltaba
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual is not null and v_actual is distinct from c_descripcion then
		raise exception 'La arquitectura ya tenía descripción. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_descripcion where arquitectura_id = v_arq;

	-- --------------------------------------------- La afirmación que se quedaba en la nota
	select resumen into v_actual from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_dc14;

	if not found then
		raise exception 'No existe la afirmación de Caparrós 2014 sobre la octava real.';
	end if;
	if v_actual not like 'Remite a la discusión%' and v_actual is distinct from c_dc14 then
		raise exception 'La afirmación de Caparrós 2014 no es la esperada. Dice: %', v_actual;
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = c_dc14
	where forma_id = v_forma and fuente_id = v_dc14;

	-- ------------------------------------------------------- Los dos vínculos que le faltaban
	if not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_arte_mayor)
			or (forma_origen_id = v_arte_mayor and forma_destino_id = v_forma)
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota)
		values (v_forma, v_arte_mayor, 'contrasta_con', c_nota_arte_mayor);
	else
		update public.forma_relaciones set nota = c_nota_arte_mayor
		where (forma_origen_id = v_forma and forma_destino_id = v_arte_mayor)
			or (forma_origen_id = v_arte_mayor and forma_destino_id = v_forma);
	end if;

	if not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_sexteto)
			or (forma_origen_id = v_sexteto and forma_destino_id = v_forma)
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota)
		values (v_forma, v_sexteto, 'relacionada_con', c_nota_sexteto);
	else
		update public.forma_relaciones set nota = c_nota_sexteto
		where (forma_origen_id = v_forma and forma_destino_id = v_sexteto)
			or (forma_origen_id = v_sexteto and forma_destino_id = v_forma);
	end if;

	-- ------------------------------------------------------------------- Comprobaciones
	-- La ficha trae ya las dos disposiciones y los dos vínculos.
	select count(*) into v_n
	from jsonb_array_elements(public.get_forma_metrica_publica('octava_real') -> 'esquemasRima');
	if v_n <> 2 then
		raise exception 'La octava real declara % esquemas de rima, no dos.', v_n;
	end if;

	select count(*) into v_n
	from jsonb_array_elements(public.get_forma_metrica_publica('octava_real') -> 'relaciones');
	if v_n <> 2 then
		raise exception 'La octava real tiene % vínculos, no dos.', v_n;
	end if;

	-- Y las dos fichas del otro extremo los recogen, porque las relaciones se leen por los dos.
	foreach v_actual in array array['copla_de_arte_mayor', 'sexteto'] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_actual) -> 'relaciones'
			) r
			where r ->> 'forma_origen_id' = v_forma::text
				or r ->> 'forma_destino_id' = v_forma::text
		) then
			raise exception 'La ficha de % no recoge su vínculo con la octava real.', v_actual;
		end if;
	end loop;
end $$;

commit;
