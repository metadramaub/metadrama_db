-- Las medidas que le faltaban al catálogo
--
-- Cierra A3 en su parte de medida, con el criterio que el IP fijó el 22 de agosto de 2026 y que
-- quedó escrito en [criterios de nivel § 3.6]: **la medida no compromete la norma**. Una
-- arquitectura que solo cambia el metro no afirma nada nuevo sobre la forma, así que se declara
-- cuando alguna fuente la documenta con epígrafe y ejemplo, sin criterio de fecha, y la ficha dice
-- quién y cuándo. Lo que sí fija la norma —disposiciones, restricciones, regímenes, rasgos
-- definitorios— se acota aparte y no entra aquí.
--
-- Tres formas ganan las medidas que la bibliografía les documenta y el catálogo no tenía.
--
-- **Sextilla · tetrasilábica y pentasilábica.** El IP las había dejado fuera el 18 de agosto por
-- criterio de corpus, anotándolas como «posible ampliación futura»; con el criterio nuevo entran.
-- Jauralde les da epígrafe propio: la tetrasílaba con Rubén Darío —«Lirio cárdeno, / lirio blanco,
-- / lirio azul…»— y la pentasílaba con Mario Hernández, *Guirnalda*, de *Sombras y variaciones*.
--
-- **Romance · pentasilábico y tetrasilábico.** El *Diccionario* define el romancillo por extensión
-- abierta —«romance en versos de **menos de ocho sílabas**»—, de modo que las dos caen dentro de su
-- propia definición. Jauralde documenta los pentasílabos en el XVIII —Meléndez Valdés, Iglesias de
-- la Casa, y las fábulas de Iriarte y Hartzenbusch— y los tetrasílabos en Rubén Darío, «Una noche /
-- tuve un sueño».
--
-- **Décima · pentasilábica, hexasilábica, heptasilábica y endecasilábica.** Y aquí hay que
-- corregir algo que se dijo al abrir esta tanda: **no son todas del siglo XX**. Jauralde les da
-- epígrafe con ejemplo, y dos son de fuente áurea o dieciochesca:
--
-- | Medida | Quién la firma en Jauralde |
-- | --- | --- |
-- | Hexasilábica | **Góngora**, con estribillo |
-- | Endecasilábica | **Meléndez Valdés**, *Elegía moral a la Virtud*, y Rubén Darío |
-- | Pentasilábica | Concha Méndez |
-- | Heptasilábica | Luis García Montero |
--
-- *No entra la tetrasilábica*: Jauralde la nombra de paso, dentro de la frase en que cuenta que
-- Darío escribió «un poema a modo de escala métrica con décimas, empezando por décima de bisílabo,
-- luego trisílabo, etc.». Eso documenta el experimento, no la estrofa — es el corolario del
-- criterio. *Y tampoco entra la décima asonante*, que es régimen y no medida: ninguna fuente la
-- registra y Jauralde la marca como ensayo «en vez de en consonante, que era lo tradicional».

begin;

do $$
declare
	v_forma uuid;
	v_modelo uuid;
	v_arq uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_nuevo uuid;
	v_rasgo uuid;
	v_valor uuid;
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_actual text;
	v_n integer;
	v_fila text[];
	v_hepta uuid := '4f2d2610-1e55-40a2-8ad4-e57708d80489';
	v_hexa uuid := '6e6e3a7e-40d2-4aff-bab7-27044174b5e5';
	v_penta uuid := 'eac128ba-e438-49b4-8a13-057733271b38';
	v_tetra uuid := 'b7d3c277-feaf-4f2f-905a-cfddc45773c4';
	v_endeca uuid := '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
begin
	-- ============================================================ 1 · La sextilla
	select forma_id into v_forma from public.formas_metricas where slug = 'sextilla';
	select arquitectura_id into v_modelo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'hexasilabica' and activo;
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'densidad_de_rima';
	select valor_id into v_valor from public.rasgo_valores where rasgo_id = v_rasgo and slug = 'total';
	if v_modelo is null or v_valor is null then
		raise exception 'Falta la sextilla hexasilábica o el valor total de la densidad.';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual like '%copla de Jorge Manrique.' then
		update public.formas_metricas set definicion = replace(
			v_actual,
			'Cuando el tercer verso',
			'Se cultiva de ocho a cuatro sílabas, y las más breves son tardías. Cuando el tercer verso'
		) where forma_id = v_forma;
	end if;

	foreach v_fila slice 1 in array array[
		array['pentasilabica', 'Pentasilábica', '5', v_penta::text,
			'La misma norma en pentasílabos. Es medida tardía en esta estrofa: el ejemplo que la '
			|| 'documenta es de finales del siglo XX.'],
		array['tetrasilabica', 'Tetrasilábica', '6', v_tetra::text,
			'La más breve de las sextillas, y la más tardía: la trae el Modernismo, con rimas agudas '
			|| 'insistentes en la línea del lay hexasílabo.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];
		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			select v_forma, v_fila[1], v_fila[2], v_fila[5], false, true, 'admitida',
				a.tipo_rima_id, true, v_fila[3]::integer, 6, 6
			from public.arquitecturas_forma a where a.arquitectura_id = v_modelo
			returning arquitectura_id into v_arq;

			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido') returning esquema_metrico_id into v_metrico;
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[4]::uuid, 1);

			insert into public.esquemas_rima (
				arquitectura_id, slug, nombre, tipo_rima_id, modalidad, tipo_secuencia, descripcion
			)
			select v_arq, er.slug, er.nombre, er.tipo_rima_id, er.modalidad, er.tipo_secuencia,
				er.descripcion
			from public.esquemas_rima er
			where er.arquitectura_id = v_modelo and er.slug = 'distribucion-variable';

			insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, valor_id, nota)
			select v_arq, v_rasgo, 'definitoria', v_valor, ar.nota
			from public.arquitectura_rasgos ar
			where ar.arquitectura_id = v_modelo and ar.rasgo_id = v_rasgo;
		end if;
	end loop;

	-- ============================================================ 2 · El romance
	select forma_id into v_forma from public.formas_metricas where slug = 'romance';
	select arquitectura_id into v_modelo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'hexasilabica' and activo;
	if v_modelo is null then
		raise exception 'Falta el romance hexasilábico.';
	end if;

	foreach v_fila slice 1 in array array[
		array['pentasilabica', 'Pentasilábica', '5', v_penta::text, 'Romancillo pentasílabo',
			'romancillo_pentasilabo',
			'Otro romancillo: la misma serie asonantada en pentasílabos. La cultivaron los poetas '
			|| 'del siglo XVIII —Meléndez Valdés, Iglesias de la Casa— y las fábulas de Iriarte y '
			|| 'Hartzenbusch.'],
		array['tetrasilabica', 'Tetrasilábica', '6', v_tetra::text, 'Romancillo tetrasílabo',
			'romancillo_tetrasilabo',
			'La más breve de las series asonantadas. Es tardía: la documenta el Modernismo.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];
		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			select v_forma, v_fila[1], v_fila[2], v_fila[7], false, true, 'admitida',
				a.tipo_rima_id, true, v_fila[3]::integer, a.unidad_versos_min, a.unidad_versos_max
			from public.arquitecturas_forma a where a.arquitectura_id = v_modelo
			returning arquitectura_id into v_arq;

			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido') returning esquema_metrico_id into v_metrico;
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[4]::uuid, 1);

			-- El ciclo de la asonancia en los pares, con su enlace entre vueltas
			for v_esquema in
				select esquema_rima_id from public.esquemas_rima where arquitectura_id = v_modelo
			loop
				insert into public.esquemas_rima (
					arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad,
					tipo_secuencia, descripcion
				)
				select v_arq, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
					descripcion
				from public.esquemas_rima where esquema_rima_id = v_esquema
				returning esquema_rima_id into v_nuevo;

				insert into public.esquema_rima_posiciones
					(esquema_rima_id, bloque, posicion, seccion, clase_rima, suelto, opcional, nota)
				select v_nuevo, bloque, posicion, seccion, clase_rima, suelto, opcional, nota
				from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;

				insert into public.esquema_rima_enlaces (
					esquema_rima_id, bloque_origen, posicion_origen, ubicacion_origen,
					desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino, nota
				)
				select v_nuevo, bloque_origen, posicion_origen, ubicacion_origen,
					desplazamiento_bloque, bloque_destino, posicion_destino, ubicacion_destino, nota
				from public.esquema_rima_enlaces where esquema_rima_id = v_esquema;
			end loop;

			-- Las vocales de la asonancia, que es lo que el romance pregunta
			insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, valor_id, nota)
			select v_arq, ar.rasgo_id, ar.modalidad, ar.valor_id, ar.nota
			from public.arquitectura_rasgos ar where ar.arquitectura_id = v_modelo;

			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, seccion_id, selecciones_min,
				selecciones_max, permite_aplicar_global, activo, orden, tipo_control, define_norma,
				ayuda_editor
			)
			select v_arq, g.slug, g.dimension, g.alcance, null, g.selecciones_min,
				g.selecciones_max, g.permite_aplicar_global, g.activo, g.orden, g.tipo_control,
				g.define_norma, g.ayuda_editor
			from public.grupos_eleccion_metrica g where g.arquitectura_id = v_modelo;

			insert into public.denominaciones_metricas
				(arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
			values (v_arq, v_fila[5], v_fila[6], false, v_dc16);
		end if;
	end loop;

	-- ============================================================ 3 · La décima
	select forma_id into v_forma from public.formas_metricas where slug = 'decima';
	select arquitectura_id into v_modelo from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'espinela' and activo;
	if v_modelo is null then
		raise exception 'Falta la espinela.';
	end if;

	foreach v_fila slice 1 in array array[
		array['endecasilabica', 'Endecasilábica', '3', v_endeca::text,
			'La espinela en verso largo. La documentan la *Elegía moral a la Virtud* de Meléndez '
			|| 'Valdés y, después, las «baladas» de Rubén Darío.'],
		array['heptasilabica', 'Heptasilábica', '4', v_hepta::text,
			'La espinela en heptasílabos, documentada con estribillo en la poesía contemporánea.'],
		array['hexasilabica', 'Hexasilábica', '5', v_hexa::text,
			'La espinela en hexasílabos. **Góngora la escribe con estribillo**, de modo que la '
			|| 'medida es del Siglo de Oro y no una prueba tardía.'],
		array['pentasilabica', 'Pentasilábica', '6', v_penta::text,
			'La más breve de las décimas documentadas, ya del siglo XX.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];
		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			select v_forma, v_fila[1], v_fila[2], v_fila[5], false, true, 'admitida',
				a.tipo_rima_id, true, v_fila[3]::integer, 10, 10
			from public.arquitecturas_forma a where a.arquitectura_id = v_modelo
			returning arquitectura_id into v_arq;

			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido') returning esquema_metrico_id into v_metrico;
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[4]::uuid, 1);

			for v_esquema in
				select esquema_rima_id from public.esquemas_rima where arquitectura_id = v_modelo
			loop
				insert into public.esquemas_rima (
					arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad,
					tipo_secuencia, descripcion
				)
				select v_arq, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
					descripcion
				from public.esquemas_rima where esquema_rima_id = v_esquema;
			end loop;

			insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, valor_id, nota)
			select v_arq, ar.rasgo_id, ar.modalidad, ar.valor_id, ar.nota
			from public.arquitectura_rasgos ar where ar.arquitectura_id = v_modelo;
		end if;
	end loop;

	-- La afirmación de Jauralde sobre la décima recoge lo que sostiene estas cuatro
	update public.afirmaciones_fuentes_metricas set resumen =
		'Recorre la historia de la estrofa: aparición tardía, «muy a finales del siglo XVI», con '
		|| 'Vicente Espinel en sus *Diversas rimas* (1591), y el nombre de espinela desde *La '
		|| 'Dorotea* de Lope; popularísima desde entonces «para todo tipo de circunstancias, '
		|| 'incluyendo los parlamentos teatrales». **Le documenta cuatro medidas además de la '
		|| 'octosílaba, cada una con ejemplo**: hexasilábica con estribillo en **Góngora**, '
		|| 'endecasilábica en la *Elegía moral a la Virtud* de **Meléndez Valdés** y en las '
		|| '«baladas» de Rubén Darío, pentasilábica en Concha Méndez y heptasilábica en Luis García '
		|| 'Montero. Registra también experimentos que no son realizaciones de la forma: la escala '
		|| 'métrica de Darío «empezando por décima de bisílabo, luego trisílabo», las décimas en '
		|| 'verso blanco y las asonantadas de Jorge Guillén en *Cántico*, que él mismo describe '
		|| 'como ensayo frente a la consonancia, «que era lo tradicional».'
	where forma_id = v_forma and fuente_id = v_jauralde;

	-- ============================================================ Comprobaciones
	select string_agg(f.slug || '=' || x.medidas, ' · ' order by f.slug) into v_actual
	from public.formas_metricas f
	join lateral (
		select string_agg(distinct m.silabas::text, ',' order by m.silabas::text) medidas
		from public.arquitecturas_forma a
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
		join public.metros m on m.metro_id = p.metro_id
		where a.forma_id = f.forma_id and a.activo
	) x on true
	where f.slug in ('sextilla', 'romance', 'decima');
	if v_actual is distinct from 'decima=11,5,6,7,8 · romance=11,4,5,6,7,8 · sextilla=4,5,6,7,8' then
		raise exception 'Las medidas quedaron en «%», que no es lo esperado.', v_actual;
	end if;

	-- Ninguna de las nuevas trae disposición, restricción ni régimen que la forma no tuviera.
	select count(distinct er.tipo_rima_id) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'decima';
	if v_n <> 1 then
		raise exception 'La décima declara % regímenes, y debe seguir declarando uno.', v_n;
	end if;

	-- El romance sigue preguntando sus vocales en todas las medidas.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'romance' and g.activo and g.dimension = 'rasgo';
	if v_n <> 6 then
		raise exception 'El romance pregunta las vocales en % medidas, no en las seis.', v_n;
	end if;

	foreach v_fila slice 1 in array array[
		array['sextilla'], array['romance'], array['decima'], array['copla_manriquena'],
		array['sextilla_enlazada'], array['copla_real']
	] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
