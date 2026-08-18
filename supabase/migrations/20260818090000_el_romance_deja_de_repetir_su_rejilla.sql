-- El romance deja de repetir su rejilla
--
-- La forma más frecuente del corpus dramático decía cuatro veces en prosa lo que su figura ya
-- dibuja: cuatro descripciones de esquema idénticas («Ciclo de dos versos…»), cuatro notas de
-- posición idénticas («Verso impar suelto.») y cuatro notas de rasgo que contaban cuándo se
-- rellena el formulario. Todo eso se retira, y lo que se conserva se mejora: la definición
-- explica lo único que la rejilla no dibuja —que la asonancia es única y que su cambio delimita
-- el pasaje— y cada arquitectura dice lo suyo en vez de repetir la fila «Medida» y la línea
-- «También».
--
-- Las afirmaciones se ajustan a la regla 4: dicen lo que dice su fuente y nada más. Y la
-- datación del romance heroico baja de la forma a la arquitectura endecasilábica, que es de
-- quien habla.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición de la forma
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Serie abierta de versos isométricos en la que los pares comparten una misma asonancia y los impares quedan sueltos. Su extensión no está fijada de antemano. El octosílabo es su realización no marcada —cuando se dice «romance» sin más, se entiende octosílabo—, y las demás medidas reciben nombre propio.';
	v_nuevo constant text :=
		'Serie de versos isométricos en la que los pares comparten una misma asonancia y los impares quedan sueltos. Esa asonancia es única y no cambia: es lo que mantiene unida la serie, y un romance acaba justamente donde empieza otra. El octosílabo es su realización no marcada —cuando se dice «romance» sin más, se entiende octosílabo—, y las demás medidas reciben nombre propio.';
begin
	select forma_id into v_forma
	from public.formas_metricas
	where slug = 'romance' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «romance».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del romance no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Las cuatro descripciones de arquitectura
--
-- Cada una decía la medida —que la fila «Medida» ya imprime— y los nombres alternativos —que
-- la línea «También» ya imprime, y más completos—. Se quedan con lo que solo ellas pueden
-- decir: la frecuencia en la comedia, el arte mayor y la fecha, y qué significa «romancillo».
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance' and activo;

	for fila in
		select *
		from (values
			(
				'octosilabica',
				'Realización no marcada del romance, y la más frecuente en el teatro del Siglo de Oro.',
				'La más frecuente del teatro del Siglo de Oro: con la redondilla y la décima, uno de los tres moldes del diálogo de la comedia nueva.'
			),
			(
				'endecasilabica',
				'Romance en endecasílabos, el único de arte mayor. Se conoce como romance heroico o romance real.',
				'El único romance de arte mayor, y el más tardío: no se generaliza hasta la segunda mitad del siglo XVII.'
			),
			(
				'heptasilabica',
				'Romance en heptasílabos. La tradición lo llama romancillo, y endecha cuando el asunto es luctuoso.',
				'El romancillo por antonomasia. Cuando el asunto es luctuoso recibe el nombre de endecha, que apunta al tema antes que a la medida.'
			),
			(
				'hexasilabica',
				'Romance en hexasílabos, que la tradición cuenta también entre los romancillos.',
				'El otro romancillo, junto al heptasílabo: la tradición aplica ese nombre a toda medida menor que el octosílabo.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» del romance.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de romance/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · Las cuatro descripciones de esquema de rima
--
-- «Ciclo de dos versos: el impar queda suelto y el par lleva la asonancia» dice cuatro cosas
-- —el ciclo, su longitud, el suelto y la asonancia— y la rejilla dibuja las cuatro. Con ellas
-- desaparece el botón «Qué distingue», que no abría más que esto.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperado constant text :=
		'Ciclo de dos versos: el impar queda suelto y el par lleva la asonancia.';
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance' and activo;

	select count(*) into v_ajenas
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and er.descripcion is not null
		and er.descripcion is distinct from v_esperado;

	if v_ajenas > 0 then
		raise exception 'El romance tiene % descripciones de esquema de rima distintas de la esperada.', v_ajenas;
	end if;

	update public.esquemas_rima er
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and er.descripcion is not null;

	select count(*) into v_restantes
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and er.descripcion is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % descripciones de esquema de rima en el romance.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · Las cuatro notas de posición
--
-- «Verso impar suelto.» repite el guion de la primera posición del ciclo. Además el camino
-- público no las lee en ningún punto: la función de la ficha no envía esta columna.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperado constant text := 'Verso impar suelto.';
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance' and activo;

	select count(*) into v_ajenas
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er using (esquema_rima_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and p.nota is not null
		and p.nota is distinct from v_esperado;

	if v_ajenas > 0 then
		raise exception 'El romance tiene % notas de posición distintas de la esperada.', v_ajenas;
	end if;

	update public.esquema_rima_posiciones p
	set nota = null
	from public.esquemas_rima er, public.arquitecturas_forma a
	where er.esquema_rima_id = p.esquema_rima_id
		and a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and p.nota is not null;

	select count(*) into v_restantes
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er using (esquema_rima_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and p.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de posición en el romance.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · Las cuatro notas de rasgo
--
-- Contaban cuándo se rellena el campo y qué decidió el proyecto al no levantar una forma por
-- cada asonancia. Ninguna de las dos cosas cabe en el catálogo, y lo que quedaba de contenido
-- lo dice el grado de determinación «Variable · una posibilidad».
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'La realización concreta debe declarar las vocales de la asonancia sin crear una subforma de romance.',
		'La realización concreta declara las vocales de la asonancia sin crear una configuración distinta.',
		'La realización concreta declara las vocales de la asonancia sin crear una forma distinta.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance' and activo;

	select count(*) into v_ajenas
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and ar.nota is not null
		and not (ar.nota = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'El romance tiene % notas de rasgo distintas de las esperadas.', v_ajenas;
	end if;

	update public.arquitectura_rasgos ar
	set nota = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = ar.arquitectura_id
		and a.forma_id = v_forma
		and ar.nota is not null;

	select count(*) into v_restantes
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and ar.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de rasgo en el romance.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · Las afirmaciones dicen lo que dice su fuente
--
-- Tres arrastraban una coda nuestra: la lectura del corpus en Quilis, el comentario sobre
-- nuestra propia definición en el Diccionario y la justificación de por qué «endecha» figura
-- como denominación. Las tres se van; la caracterización que sostenían vive ahora en la
-- descripción de la arquitectura correspondiente, sin firma, como pide la regla 9.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
	v_id uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance' and activo;

	for fila in
		select *
		from (values
			(
				'51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid,
				'pp. 150-151',
				'Sitúa en el Barroco el punto culminante del desarrollo del romance, tanto en el de tipo popular como en el culto. Es la razón de que sea la forma más frecuente del corpus.',
				'Sitúa en el Barroco el punto culminante del desarrollo del romance, tanto en el de tipo popular como en el culto.'
			),
			(
				'2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid,
				'Entrada «romance», p. 363',
				'Añade dos rasgos que la definición no recoge: el romance puede estar dividido por el sentido en grupos de cuatro versos, y admite estribillos o canciones intercalados, sean octosílabos o de otra medida.',
				'El romance puede estar dividido por el sentido en grupos de cuatro versos, y admite estribillos o canciones intercalados, sean octosílabos o de otra medida.'
			),
			(
				'2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid,
				'«Series» → «El romance y el romancillo»',
				'Extiende el nombre de romancillo a los pentasílabos y tetrasílabos, además del heptasílabo y el hexasílabo. Sitúa el romance heroico en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores.',
				'Extiende el nombre de romancillo a los pentasílabos y tetrasílabos, además del heptasílabo y el hexasílabo.'
			)
		) as t(fuente, localizador, viejo, nuevo)
	loop
		select afirmacion_id, resumen into v_id, v_actual
		from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma
			and fuente_id = fila.fuente
			and localizador = fila.localizador;

		if v_id is null then
			raise exception 'No existe la afirmación del romance con localizador «%».', fila.localizador;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La afirmación «%» no es la esperada. Dice: %', fila.localizador, v_actual;
		end if;

		update public.afirmaciones_fuentes_metricas
		set resumen = fila.nuevo
		where afirmacion_id = v_id;
	end loop;
end $$;

-- La del Diccionario sobre la endecha cuelga de la arquitectura heptasilábica, no de la forma.
do $$
declare
	v_arq uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'«Endecha» nombra el asunto antes que la forma. Es un poema de tema luctuoso que suele componerse en romancillo heptasílabo, pero admite versos de cinco o de seis sílabas y pareados de doce, y hay endechas en redondillas o en versos sueltos. Por eso figura aquí como denominación y no como identidad de la arquitectura.';
	v_nuevo constant text :=
		'Es un poema de tema luctuoso que suele componerse en romancillo heptasílabo, pero admite versos de cinco o de seis sílabas y pareados de doce, y hay endechas en redondillas o en versos sueltos.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'romance' and a.slug = 'heptasilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa romance/heptasilabica.';
	end if;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where arquitectura_id = v_arq
		and fuente_id = '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid
		and localizador = 'Entrada «endecha», p. 148';

	if v_id is null then
		raise exception 'No existe la afirmación del Diccionario sobre la endecha en romance/heptasilabica.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación sobre la endecha no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

-- ---------------------------------------------------------------------------
-- 7 · La datación del romance heroico baja a su arquitectura
--
-- Jauralde decía dos cosas en una sola afirmación colgada de la forma: la extensión del nombre
-- «romancillo» —que es de la forma— y la fecha del romance heroico —que solo es de la
-- endecasilábica—. La segunda pasa a colgar de ella, que es donde el lector la necesita.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_resumen constant text :=
		'Sitúa el romance heroico en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores.';
	v_existe integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'romance' and a.slug = 'endecasilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa romance/endecasilabica.';
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, arquitectura_id, localizador, resumen, confianza, estado_revision
	)
	select
		'2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid,
		v_arq,
		'«Series» → «El romance y el romancillo»',
		v_resumen,
		'alta',
		'aprobada'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where arquitectura_id = v_arq
			and fuente_id = '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid
			and localizador = '«Series» → «El romance y el romancillo»'
	);

	select count(*) into v_existe
	from public.afirmaciones_fuentes_metricas
	where arquitectura_id = v_arq
		and fuente_id = '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid
		and resumen = v_resumen;

	if v_existe <> 1 then
		raise exception 'La afirmación de Jauralde sobre el romance heroico aparece % veces.', v_existe;
	end if;
end $$;

commit;
