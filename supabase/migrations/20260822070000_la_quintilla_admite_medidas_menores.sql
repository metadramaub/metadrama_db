-- La quintilla admite medidas menores
--
-- Segunda de A3. La quintilla tenía **una sola arquitectura**, octosilábica, siendo la única de las
-- estrofas breves de arte menor que no declaraba sus otras medidas: la redondilla tiene tres —8, 7
-- y 6— y la sextilla, otras tres.
--
-- Y no es que las fuentes las documenten de pasada: **el *Diccionario* las mete en la definición**.
-- «Quintilla. Combinación estrófica de cinco versos octosílabos, **o menores**, con dos rimas
-- consonantes distintas; no pueden rimar más de dos versos seguidos; no debe terminar en un
-- pareado, y ningún verso debe quedar sin rima». Las cuatro condiciones no dependen de la medida, y
-- por eso las dos arquitecturas nuevas traen la misma norma que la octosílaba.
--
-- Jauralde ejemplifica la hexasilábica con la *Cantiga de serrana de la Tablada* del Arcipreste de
-- Hita, y documenta también las heptasilábicas.
--
-- **Se declaran las dos concretas que la bibliografía nombra** —hexasílaba y heptasílaba—, y la
-- definición dice «arte menor» para no cerrar la puerta a la pentasílaba o la tetrasílaba, más
-- raras: es el criterio que el IP fijó el 22 de agosto de 2026 para todo A3.
--
-- **Las nueve disposiciones se copian, no se reescriben.** Las ocho tipologías y el esquema abierto
-- con sus tres restricciones son la norma de la forma, no de una medida, y el editor tiene que
-- poder elegir una en cualquiera de las tres. Copiarlas desde la octosilábica es además lo que hace
-- la redondilla con sus dos disposiciones en cada medida.

begin;

do $$
declare
	v_forma uuid;
	v_octo uuid;
	v_arq uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_nuevo uuid;
	v_grupo public.grupos_eleccion_metrica%rowtype;
	v_actual text;
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de cinco versos de arte menor que riman en consonante sobre dos clases. Más que '
		|| 'por una disposición fija, la tradición la caracteriza por lo que procura evitar: tres '
		|| 'versos seguidos con la misma rima y el pareado final. De ahí salen sus cinco '
		|| 'disposiciones clásicas, aunque el uso documenta alguna más. Dentro de un mismo poema la '
		|| 'disposición puede cambiar de una quintilla a otra. El octosílabo es su realización no '
		|| 'marcada; el heptasílabo y el hexasílabo están documentados, y las fuentes la definen en '
		|| '«octosílabos o menores», de modo que medidas más breves no quedan excluidas por la '
		|| 'norma aunque el catálogo no las declare.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'quintilla';
	select arquitectura_id into v_octo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica_consonante' and activo;
	if v_octo is null then
		raise exception 'No aparece la quintilla octosilábica.';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like 'Estrofa de cinco versos octosílabos%' and v_actual is distinct from c_definicion
	then
		raise exception 'La definición de la quintilla no es la esperada. Empieza: %', left(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	select * into v_grupo from public.grupos_eleccion_metrica
	where arquitectura_id = v_octo and slug = 'esquema_rima';
	if not found then
		raise exception 'La quintilla octosilábica no tiene su pregunta de disposición.';
	end if;

	-- ------------------------------------------------- Las dos medidas que faltaban
	foreach v_fila slice 1 in array array[
		array['heptasilabica', 'Heptasilábica', '2', '4f2d2610-1e55-40a2-8ad4-e57708d80489',
			'La misma norma en heptasílabos. La documenta Jauralde entre las medidas en que la '
			|| 'quintilla se ha cultivado, junto a la hexasílaba.'],
		array['hexasilabica', 'Hexasilábica', '3', '6e6e3a7e-40d2-4aff-bab7-27044174b5e5',
			'La misma norma en hexasílabos. Es la medida de la *Cantiga de serrana de la Tablada* '
			|| 'del Arcipreste de Hita, que Jauralde cita como ejemplo temprano de la forma.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];

		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			select v_forma, v_fila[1], v_fila[2], v_fila[5], false, true, 'admitida',
				a.tipo_rima_id, true, v_fila[3]::integer, 5, 5
			from public.arquitecturas_forma a where a.arquitectura_id = v_octo
			returning arquitectura_id into v_arq;
		end if;

		-- La medida
		select esquema_metrico_id into v_metrico from public.esquemas_metricos
		where arquitectura_id = v_arq;
		if v_metrico is null then
			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido')
			returning esquema_metrico_id into v_metrico;

			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[4]::uuid, 1);
		end if;

		-- Las nueve disposiciones, copiadas de la octosilábica con sus restricciones
		for v_esquema in
			select esquema_rima_id from public.esquemas_rima where arquitectura_id = v_octo
		loop
			select esquema_rima_id into v_nuevo from public.esquemas_rima
			where arquitectura_id = v_arq
				and slug = (select slug from public.esquemas_rima where esquema_rima_id = v_esquema);

			if v_nuevo is null then
				insert into public.esquemas_rima (
					arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad,
					tipo_secuencia, descripcion
				)
				select v_arq, slug, nombre, notacion, tipo_rima_id, modalidad,
					tipo_secuencia, descripcion
				from public.esquemas_rima where esquema_rima_id = v_esquema
				returning esquema_rima_id into v_nuevo;

				insert into public.esquema_rima_restricciones
					(esquema_rima_id, tipo, valor_numero, valor_texto, descripcion)
				select v_nuevo, tipo, valor_numero, valor_texto, descripcion
				from public.esquema_rima_restricciones where esquema_rima_id = v_esquema;
			end if;
		end loop;

		-- Y su pregunta, para que el editor pueda elegir disposición también aquí
		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, dimension, alcance, seccion_id, selecciones_min,
			selecciones_max, permite_aplicar_global, activo, orden, tipo_control, define_norma,
			ayuda_editor
		)
		select v_arq, 'esquema_rima', v_grupo.dimension, v_grupo.alcance, null,
			v_grupo.selecciones_min, v_grupo.selecciones_max, v_grupo.permite_aplicar_global,
			v_grupo.activo, v_grupo.orden, v_grupo.tipo_control, v_grupo.define_norma,
			v_grupo.ayuda_editor
		where not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and slug = 'esquema_rima'
		);
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 3 then
		raise exception 'La quintilla tiene % arquitecturas, no las tres.', v_n;
	end if;

	-- Las tres declaran la misma norma: nueve disposiciones y las tres restricciones.
	if exists (
		select 1 from public.arquitecturas_forma a
		where a.forma_id = v_forma and a.activo
			and (select count(*) from public.esquemas_rima er
				where er.arquitectura_id = a.arquitectura_id) <> 9
	) then
		raise exception 'Alguna arquitectura de la quintilla no declara las nueve disposiciones.';
	end if;
	select count(*) into v_n
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma;
	if v_n <> 9 then
		raise exception 'La quintilla declara % restricciones, y deben ser nueve —tres por medida.', v_n;
	end if;

	-- Y las tres preguntan la disposición, que es lo único que la quintilla pregunta.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where a.forma_id = v_forma and g.activo;
	if v_n <> 3 then
		raise exception 'La quintilla tiene % preguntas, y debe tener una por medida.', v_n;
	end if;

	-- La copla real y la novena siguen reutilizando la octosilábica y solo la octosilábica.
	select count(*) into v_n
	from public.estructuras_secciones where arquitectura_referenciada_id = v_octo;
	if v_n < 4 then
		raise exception 'Las secciones que reutilizaban la quintilla octosilábica son ahora %.', v_n;
	end if;

	foreach v_fila slice 1 in array array[
		array['quintilla'], array['copla_real'], array['novena'], array['oncena'],
		array['sextilla_enlazada'], array['septilla_enlazada']
	] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
