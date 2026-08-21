-- La silva arromanzada entra con su nombre
--
-- Última de A3, y la que **prueba el criterio por el lado difícil**. No es una medida: es un
-- **régimen nuevo** en una forma que hasta hoy declaraba «rima Consonante» en sus cuatro
-- arquitecturas. Por la regla fijada el 22 de agosto de 2026, lo que compromete la norma solo entra
-- si una fuente **lo enuncia como regla o le da nombre**, y aquí las dos cosas se cumplen: el
-- *Diccionario* le dedica entrada propia.
--
-- > «**silva arromanzada.** Silva en que todos los versos pares llevan la misma rima asonante.»
--
-- *El ejemplo que trae es de Antonio Machado —«A un viejo y distinguido señor»— y por tanto del
-- siglo XX. No la descalifica: lo que el criterio pesa no es la fecha del ejemplo sino si la fuente
-- define o ensaya, y aquí define, con nombre propio y con entrada. Es exactamente el caso contrario
-- al de la décima asonante, que ninguna fuente registra y que Jauralde presenta como un ensayo de
-- Jorge Guillén «en vez de en consonante, que era lo tradicional».*
--
-- **La estructura es la del romance dentro de una silva**: los versos pares comparten una misma
-- asonancia y los impares quedan sueltos, `[-a]…`, sobre la mezcla libre de siete y once. De ahí
-- que se declare como el romance —ciclo con enlace entre vueltas y la pregunta de las vocales— y
-- no como las otras cuatro silvas, que fijan su grado de pareados.
--
-- Y **la duda que estaba anotada desde el 9 de agosto queda respondida**: sí, la silva pasa a
-- declarar dos regímenes, como ya hacen el villancico y la canción petrarquista.

begin;

do $$
declare
	v_forma uuid;
	v_libre uuid;
	v_romance uuid;
	v_romance_arq uuid;
	v_arq uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_nuevo uuid;
	v_asonante uuid := 'c5b9a139-a184-471a-b7a7-aa65ed377e85';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_hepta uuid := '4f2d2610-1e55-40a2-8ad4-e57708d80489';
	v_endeca uuid := '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
	v_actual text;
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Serie de endecasílabos y heptasílabos —o solo de endecasílabos— con rima dispuesta '
		|| 'libremente, por lo que no se deja dividir en estrofas simétricas. Lo corriente es que '
		|| 'rime en consonante, y entonces lo que cambia de una realización a otra es cuánto '
		|| 'organizan los pareados la serie, desde el par sistemático hasta su ausencia. La '
		|| 'tradición registra además una realización asonantada, la silva arromanzada, en que la '
		|| 'rima se reduce a una misma asonancia en todos los versos pares y los impares quedan '
		|| 'sueltos. La rima es aquí condición: un pasaje enteramente suelto no es una silva.';

	c_descripcion constant text :=
		'Todos los versos pares llevan la misma rima asonante y los impares quedan sueltos, sobre '
		|| 'la mezcla libre de siete y once. Es la figura del romance dentro de una silva: lo que la '
		|| 'separa de las otras cuatro no es cuánta rima hay sino dónde cae y de qué clase es.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva';
	select arquitectura_id into v_libre from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'libre' and activo;
	select forma_id into v_romance from public.formas_metricas where slug = 'romance';
	select arquitectura_id into v_romance_arq from public.arquitecturas_forma
	where forma_id = v_romance and slug = 'octosilabica' and activo;
	if v_libre is null or v_romance_arq is null then
		raise exception 'Falta la silva libre o el romance octosilábico.';
	end if;

	-- La forma pasa a declarar dos regímenes: hasta hoy las cuatro eran consonantes.
	select count(distinct tipo_rima_id) into v_n
	from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 1 then
		raise exception 'La silva ya declaraba % regímenes; esta migración esperaba uno.', v_n;
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%no es una silva.' then
		raise exception 'La definición de la silva no es la esperada. Acaba: %', right(v_actual, 40);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'arromanzada';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'arromanzada', 'Arromanzada', c_descripcion, false, true, 'admitida',
			v_asonante, true, 50, null, null)
		returning arquitectura_id into v_arq;

		-- La medida: la mezcla libre de siete y once, como la libre y la de orden libre
		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);

		-- La rima: la figura del romance, con su enlace entre vueltas
		select esquema_rima_id into v_esquema from public.esquemas_rima
		where arquitectura_id = v_romance_arq and tipo_secuencia = 'ciclo'
		limit 1;
		if v_esquema is null then
			raise exception 'El romance ha dejado de tener su ciclo de asonancia.';
		end if;

		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		select v_arq, er.slug, 'Asonancia en los pares', er.notacion, er.tipo_rima_id,
			'definitoria', er.tipo_secuencia,
			'Los pares comparten una misma asonancia de principio a fin de la serie; los impares '
			|| 'quedan sueltos. Es lo único que la norma fija de su rima.'
		from public.esquemas_rima er where er.esquema_rima_id = v_esquema
		returning esquema_rima_id into v_nuevo;

		insert into public.esquema_rima_posiciones
			(esquema_rima_id, bloque, posicion, seccion, clase_rima, suelto, opcional, nota)
		select v_nuevo, bloque, posicion, seccion, clase_rima, suelto, opcional, nota
		from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;

		insert into public.esquema_rima_enlaces (
			esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
			desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino, nota
		)
		select v_nuevo, bloque_origen, posicion_origen, ubicacion_origen, desplazamiento_bloque,
			bloque_destino, posicion_destino, ubicacion_destino, nota
		from public.esquema_rima_enlaces where esquema_rima_id = v_esquema;

		-- Y las vocales, que es lo que hay que registrar cuando la rima es asonante
		insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, valor_id, nota)
		select v_arq, ar.rasgo_id, ar.modalidad, ar.valor_id, ar.nota
		from public.arquitectura_rasgos ar where ar.arquitectura_id = v_romance_arq;

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, seccion_id, selecciones_min, selecciones_max,
			permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
		)
		select v_arq, g.slug, g.dimension, g.alcance, null, g.selecciones_min, g.selecciones_max,
			g.permite_aplicar_global, g.activo, g.orden, g.tipo_control, g.define_norma,
			g.ayuda_editor
		from public.grupos_eleccion_metrica g where g.arquitectura_id = v_romance_arq;
	end if;

	-- ------------------------------------------------------------------- El nombre y la fuente
	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_arq, 'Silva arromanzada', 'silva_arromanzada', false, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where arquitectura_id = v_arq and slug_normalizado = 'silva_arromanzada'
	);

	-- ------------------------------------------------------------------ El vínculo
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_romance, 'relacionada_con',
		'La silva arromanzada toma del romance su figura de rima: una misma asonancia en todos los '
		|| 'versos pares, con los impares sueltos. Lo que la separa es la medida —el romance es '
		|| 'isosilábico y la silva mezcla siete y once— y que aquí esa figura es una realización '
		|| 'entre otras, no la norma de la forma.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_romance)
			or (forma_origen_id = v_romance and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 5 then
		raise exception 'La silva tiene % arquitecturas, no las cinco.', v_n;
	end if;

	-- La forma declara ahora los dos regímenes, y la nueva es la única asonante.
	select string_agg(distinct v.termino, ' o ' order by v.termino) into v_actual
	from public.arquitecturas_forma a
	join public.vocabularios v on v.termino_id = a.tipo_rima_id
	where a.forma_id = v_forma and a.activo;
	if v_actual is distinct from 'asonante o consonante' then
		raise exception 'La silva declara «%», y deberían ser los dos regímenes.', v_actual;
	end if;

	-- Su rima cicla y conserva la asonancia entre vueltas, como la del romance.
	if not exists (
		select 1 from public.esquemas_rima er
		join public.esquema_rima_enlaces e on e.esquema_rima_id = er.esquema_rima_id
		where er.arquitectura_id = v_arq and e.desplazamiento_bloque = 1
	) then
		raise exception 'La silva arromanzada no conserva su asonancia entre vueltas.';
	end if;

	-- Y pregunta las vocales, sin las cuales la asonancia no queda registrada.
	if not exists (
		select 1 from public.grupos_eleccion_metrica
		where arquitectura_id = v_arq and dimension = 'rasgo' and activo
	) then
		raise exception 'La silva arromanzada no pregunta las vocales de su asonancia.';
	end if;

	foreach v_fila slice 1 in array array[array['silva'], array['romance'], array['endecasilabo_suelto']] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
