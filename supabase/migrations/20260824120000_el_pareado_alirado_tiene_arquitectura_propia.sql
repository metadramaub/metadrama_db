-- El pareado alirado tiene arquitectura propia
--
-- El IP añadió `pareado_alirado` al vocabulario legado y se quedó sin destino. Cabía ya en la
-- arquitectura «De cualquier medida», que declara `medida_uniforme = false` y ofrece nueve metros
-- entre los que están el heptasílabo y el endecasílabo: un pareado de siete y once **se podía
-- anotar** desde el primer día.
--
-- Pero cabía como cabe cualquier otra mezcla, y esta tiene nombre propio. **Decisión del IP el 24
-- de agosto de 2026:** arquitectura aparte, para que anotarlo sea elegir entre 7-11 y 11-7 y no
-- entre las noventa combinaciones que permite la otra. La de cualquier medida se queda como está,
-- para las mezclas que no son esta.
--
-- **No es forma aparte, y conviene decir por qué**, porque el caso se parece al de las aliradas y
-- se resuelve al revés. Por el criterio de [nivel § 3.1](../../docs/dominio-metrico/criterios-de-nivel.md),
-- lo que hace forma aparte es la articulación —cuántos miembros y cómo se reparten—; la medida es
-- arquitectura. En la serie alirada lo que cambia de una forma a otra es **el número de versos**, y
-- por eso lira, sexteto-lira y septeto-lira son formas distintas. Aquí solo cambia **la medida** de
-- los dos versos de un pareado, que sigue siendo un pareado. Mismo criterio, resultado contrario.
--
-- **Y hay que separarlo de la silva, con la que se pisa.** Una *serie* de pareados de siete y once
-- ya está en el catálogo: es la silva consonante regular, que «alterna heptasílabo y endecasílabo
-- en pareados que se suceden sin excepción». El pareado alirado es la estrofa suelta —la coda de
-- dos versos con que se cierra un pasaje—; en cuanto se encadena, es silva. Las dos descripciones
-- lo dicen para que nadie tenga que adivinarlo.
--
-- *Sobre las fuentes:* ninguna de las seis registra el «pareado alirado» con ese nombre. Las seis
-- documentan el pareado de siete y once como material de la silva y como cierre de las estrofas
-- aliradas —«suele ser seña de identidad de la lira frente a otras estrofas la de terminar en
-- pareado», Jauralde—, pero como estrofa independiente entra por coherencia del sistema. Queda
-- dicho en su descripción, no escondido.

begin;

do $$
declare
	v_forma uuid;
	v_libre uuid;
	v_arq uuid;
	v_metrico uuid;
	v_rima uuid;
	v_grupo uuid;
	v_consonante uuid;
	v_hepta uuid;
	v_endeca uuid;
	v_termino uuid;
	v_silva uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';
	select arquitectura_id into v_libre from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'cualquier_medida' and activo;
	if v_libre is null then
		raise exception 'No existe la arquitectura de cualquier medida del pareado.';
	end if;

	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select termino_id into v_termino from public.vocabularios
	where termino = 'pareado_alirado' and categoria = 'estrofa_tipo';
	select tipo_rima_id into v_consonante from public.arquitecturas_forma
	where arquitectura_id = v_libre;
	if v_hepta is null or v_endeca is null or v_termino is null then
		raise exception 'Falta el heptasílabo, el endecasílabo o el término legado.';
	end if;

	-- La de cualquier medida admite mezcla: si dejara de admitirla, esta migración sobraría.
	if not exists (
		select 1 from public.esquemas_metricos
		where arquitectura_id = v_libre and medida_uniforme is false
	) then
		raise exception 'La arquitectura de cualquier medida ya no admite mezclar medidas.';
	end if;

	-- El régimen consonante se toma del que ya declara el pareado, no se inventa.
	if v_consonante is null then
		select tipo_rima_id into v_consonante from public.esquemas_rima
		where arquitectura_id = v_libre and notacion = 'aa' limit 1;
	end if;
	if v_consonante is null then
		raise exception 'No se pudo averiguar el régimen consonante del pareado.';
	end if;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'alirado';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (
			v_forma, 'alirado', 'Alirado',
			'Los dos versos son uno heptasílabo y otro endecasílabo, en cualquiera de los dos '
			|| 'órdenes, con rima consonante. Es la unidad mínima de la mezcla italiana, y aparece '
			|| 'suelta como coda de un pasaje o como cierre de una estrofa alirada. En cuanto los '
			|| 'pareados se suceden y organizan la serie, el pasaje deja de ser una estrofa y es '
			|| 'una silva consonante regular.',
			false, true, 'admitida', v_consonante, true, 20, 2, 2
		)
		returning arquitectura_id into v_arq;

		-- La medida: siete y once, sin fijar el orden, que es lo único que hay que elegir
		insert into public.esquemas_metricos
			(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
		values (v_arq, 'conjunto', 'conjunto-7-11', false)
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
		values (v_metrico, v_hepta, 1), (v_metrico, v_endeca, 2);

		-- La rima, que aquí es lo único que la norma fija del todo
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values (
			v_arq, 'aa', 'Pareado', 'aa', v_consonante, 'definitoria', 'secuencia',
			'Los dos versos riman entre sí en consonante. Es lo que hace pareado al pareado.'
		)
		returning esquema_rima_id into v_rima;

		-- Y la pregunta: cuál de los dos versos es el heptasílabo
		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
			permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
		)
		values (
			v_arq, 'medida_del_pareado', 'metro', 'unidad', 2, 2, true, true, 1, 'opciones', false,
			'Marca la medida de cada uno de los dos versos: 7-11 u 11-7.'
		)
		returning grupo_eleccion_id into v_grupo;

		update public.arquitecturas_forma set origen_termino_id = v_termino
		where arquitectura_id = v_arq;
	end if;

	-- ------------------------------------------------------------------ El nombre
	-- Una denominación apunta a un solo destino: aquí, a la arquitectura.
	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, preferente)
	select v_arq, 'Pareado alirado', 'pareado_alirado', false
	where not exists (
		select 1 from public.denominaciones_metricas
		where arquitectura_id = v_arq and slug_normalizado = 'pareado_alirado'
	);

	-- ------------------------------------------------------------------ La frontera con la silva
	select forma_id into v_silva from public.formas_metricas where slug = 'silva';
	if v_silva is not null then
		insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
		select v_forma, v_silva, 'relacionada_con',
			'El pareado de siete y once es la unidad de la silva consonante regular, que los '
			|| 'sucede sin excepción. Lo que separa una cosa de otra no es la medida ni la rima, '
			|| 'que son las mismas, sino que aquí el pareado está suelto y allí organiza la serie.'
		where not exists (
			select 1 from public.forma_relaciones
			where (forma_origen_id = v_forma and forma_destino_id = v_silva)
				or (forma_origen_id = v_silva and forma_destino_id = v_forma)
		);
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma
	where forma_id = v_forma and activo;
	if v_n <> 2 then
		raise exception 'El pareado tiene % arquitecturas, no las dos.', v_n;
	end if;

	-- La nueva ofrece exactamente dos medidas, ni una más.
	select count(*) into v_n
	from public.esquema_metrico_opciones o
	join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
	where em.arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'El pareado alirado ofrece % medidas, no las dos.', v_n;
	end if;

	-- Y su pregunta ofrece las cuatro respuestas que salen de esas dos medidas en dos versos.
	select count(*) into v_n from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id = v_arq;
	if v_n <> 4 then
		raise exception 'La pregunta del pareado alirado ofrece % opciones, no las cuatro.', v_n;
	end if;

	-- La de cualquier medida no ha perdido nada por el camino.
	select count(*) into v_n
	from public.esquema_metrico_opciones o
	join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
	where em.arquitectura_id = v_libre;
	if v_n < 9 then
		raise exception 'La arquitectura de cualquier medida se ha quedado con % medidas.', v_n;
	end if;

	if public.get_forma_metrica_publica('pareado') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del pareado ha dejado de responder.';
	end if;
end $$;

commit;
