-- El endecasílabo encadenado es una forma, no un rasgo opcional del suelto
--
-- «Endecasílabo suelto» llevaba un rasgo opcional, `encadenamiento_interior`, para el endecasílabo
-- en que la rima final de cada verso vuelve en el interior del siguiente. Pero eso no es un suelto
-- con algo más: es una serie en la que **todo rima**, aunque no entre finales de verso, y la única
-- fuente que lo mete entre los sueltos —Morley y Bruerton, «Rima interna en sueltos»— cuenta
-- pasajes enteros encadenados. Navarro Tomás lo trata aparte, como «endecasílabo de rima
-- encadenada» (§§ 114 y 166), y Caparrós y el *Diccionario* como una modalidad de la rima interna.
-- El vocabulario legado ya lo separaba: `endecasilabo_suelto_encadenado`, con la definición exacta
-- —sílabas 6-7, a veces 4-5— y el ejemplo de *Adonis y Venus*. Decidido con David el 18 de
-- septiembre de 2026, con las cuatro fuentes leídas en su página.
--
-- La forma nueva, `endecasilabo_encadenado`, tiene una arquitectura con el rasgo de encadenamiento
-- **definitorio** —y por tanto sin pregunta—, más las dos opcionales que comparte con el suelto:
-- dístico final y final esdrújulo. Sin densidad de rima ni organización en pareados: la densidad
-- se lee como rima de finales, y aquí no la hay. El suelto pierde el rasgo y su pregunta.
--
-- Las seis anotaciones que marcaron el encadenamiento pasan a la forma nueva —dos fuera de las
-- obras de prueba: *Adonis y Venus* vv. 792-851 y *Prueba* vv. 56-75— y pierden las respuestas que
-- la forma nueva no pregunta: el encadenamiento (ahora definitorio), la densidad y los pareados.
-- Conservan dístico y esdrújulo. Las otras 28 se quedan en el suelto sin tocar.
--
-- Quilis y Jauralde no la registran, y la afirmación de cada uno lo dice sin más.

begin;

do $$
declare
	v_suelto uuid;
	v_encadenado uuid;
	v_arq_suelto uuid;
	v_arq uuid;
	v_em_suelto uuid;
	v_em uuid;
	v_er uuid;
	v_rasgo_enc uuid;
	v_valor_enc uuid;
	v_grupo_enc uuid;
	v_termino constant uuid := '56ad5023-e0a2-486e-ad32-a4f36037deef';
	v_italiana constant uuid := 'af269fe5-f67f-4991-9dc2-49ea12c40abd';
	v_consonante constant uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_mb constant uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis constant uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro constant uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_capar constant uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dicc constant uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jaur constant uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_reales integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- ══════════════════════════════════════════════════════════ Lo que tiene que estar
	select forma_id into v_suelto from public.formas_metricas where slug = 'endecasilabo_suelto' and activo;
	if v_suelto is null then raise exception 'No está el endecasílabo suelto.'; end if;
	if exists (select 1 from public.formas_metricas where slug = 'endecasilabo_encadenado') then
		raise exception 'Ya existe «endecasilabo_encadenado».';
	end if;
	select arquitectura_id into v_arq_suelto from public.arquitecturas_forma
	where forma_id = v_suelto and slug = 'endecasilabica' and activo and principal;
	if v_arq_suelto is null then raise exception 'El suelto no tiene su arquitectura «endecasilabica».'; end if;
	select esquema_metrico_id into v_em_suelto from public.esquemas_metricos where arquitectura_id = v_arq_suelto;
	if v_em_suelto is null then raise exception 'El suelto no tiene esquema métrico.'; end if;
	select rasgo_id into v_rasgo_enc from public.rasgos_metricos where slug = 'encadenamiento_interior';
	select valor_id into v_valor_enc from public.rasgo_valores where rasgo_id = v_rasgo_enc and slug = 'presente';
	select grupo_eleccion_id into v_grupo_enc from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq_suelto and rasgo_id = v_rasgo_enc;
	if v_rasgo_enc is null or v_valor_enc is null or v_grupo_enc is null then
		raise exception 'El rasgo de encadenamiento, su valor «presente» o su pregunta no están donde se esperaba.';
	end if;
	if (select count(*) from public.arquitectura_rasgos where rasgo_id = v_rasgo_enc) <> 1 then
		raise exception 'El rasgo de encadenamiento debía estar en una sola arquitectura.';
	end if;
	if (select termino from public.vocabularios where termino_id = v_termino) <> 'endecasilabo_suelto_encadenado' then
		raise exception 'El término legado no es el esperado.';
	end if;
	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_suelto) <> 6 then
		raise exception 'El suelto debía tener seis afirmaciones.';
	end if;

	-- Las anotaciones con encadenamiento marcado: seis, dos de ellas fuera de las obras de prueba.
	create temp table encadenadas on commit drop as
		select distinct e.anotacion_id
		from public.anotacion_elecciones e
		where e.valor_rasgo_id = v_valor_enc;
	select count(*) into v_n from encadenadas;
	select count(*) into v_reales
	from encadenadas x
	join public.anotaciones_metricas am on am.anotacion_id = x.anotacion_id
	join public.secuencias_metricas s on s.secuencia_id = am.secuencia_id
	join public.obras o on o.obra_id = s.obra_id
	where o.titulo not ilike '%(prueba)%';
	if v_n <> 6 or v_reales <> 2 then
		raise exception 'Se esperaban 6 anotaciones encadenadas (2 fuera de pruebas) y hay % (%).', v_n, v_reales;
	end if;
	if exists (select 1 from encadenadas x join public.anotaciones_metricas am on am.anotacion_id = x.anotacion_id
		where am.arquitectura_id <> v_arq_suelto) then
		raise exception 'Alguna anotación encadenada no es del suelto.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ══════════════════════════════════════════════════════════ La forma y su arquitectura
	insert into public.formas_metricas (slug, nombre, definicion, nivel_estructural, tipo_registro, activo, origen_termino_id)
	values (
		'endecasilabo_encadenado', 'Endecasílabo encadenado',
		$p$Serie de endecasílabos sin estrofa en la que cada verso rima con el interior del siguiente: la rima final de un verso vuelve en las sílabas sexta y séptima del que viene detrás —con menor frecuencia en la cuarta y quinta—, de modo que ningún verso queda sin rima y la serie va encadenada de uno en uno. Los finales de verso no riman entre sí, y por eso comparte con el endecasílabo suelto la falta de estrofa y la ausencia de rima final; lo que la separa es que aquí todo rima. Es el *endecasillabo incatenato* que Sannazaro y otros italianos aplicaron a la poesía dramática; en castellano lo estableció Garcilaso en buena parte de su segunda égloga, tuvo cierta boga entre finales del siglo XVI y principios del XVII, y Lope lo empleó en unas pocas comedias entre 1593 y hacia 1612. La rima fracciona el verso y fija la cesura tras la séptima sílaba aun cuando el sentido la pondría en otro sitio.$p$,
		'serie', 'forma', true, v_termino
	) returning forma_id into v_encadenado;
	insert into public.formas_tradiciones (forma_id, tradicion_id) values (v_encadenado, v_italiana);

	insert into public.arquitecturas_forma
		(forma_id, slug, nombre, descripcion, principal, demarcable, modalidad, tipo_rima_id, activo, orden, intercalable)
	values (
		v_encadenado, 'endecasilabica', 'Endecasílabo',
		$p$Endecasílabos en serie, cada uno rimado con el interior del siguiente. La medida es fija y el encadenamiento es la norma: lo único que se pregunta es si cierra en dístico y si sostiene el final esdrújulo.$p$,
		true, true, 'habitual', v_consonante, true, 1, false
	) returning arquitectura_id into v_arq;

	-- El mismo esquema métrico que el suelto: endecasílabo repetido.
	insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug, medida_uniforme, nombre, descripcion)
	select v_arq, tipo_secuencia, slug, medida_uniforme, nombre, descripcion
	from public.esquemas_metricos where esquema_metrico_id = v_em_suelto
	returning esquema_metrico_id into v_em;
	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, opcional, grupo_repeticion, alternativa, nota)
	select v_em, posicion, metro_id, opcional, grupo_repeticion, alternativa, nota
	from public.esquema_metrico_posiciones where esquema_metrico_id = v_em_suelto;

	-- La rima, abierta: no hay notación de finales que la diga.
	insert into public.esquemas_rima (arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion)
	values (
		v_arq, 'rima-encadenada', 'Rima encadenada al interior del verso siguiente', null, v_consonante, 'definitoria', 'abierta',
		$p$La rima final de cada verso se repite en el interior del siguiente, en las sílabas sexta y séptima —a veces en la cuarta y quinta—. Entre finales de verso no hay rima, así que ninguna notación por finales la recoge.$p$
	) returning esquema_rima_id into v_er;
	insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, descripcion)
	values (v_er, 'otra', 'Cada verso rima, con el interior del siguiente; los finales de verso no riman entre sí.');

	-- Rasgos: el encadenamiento, definitorio y sin pregunta; dístico y esdrújulo, como en el suelto.
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values (v_arq, v_rasgo_enc, v_valor_enc, 'definitoria', 'La rima final de cada verso vuelve en el interior del siguiente: es lo que hace encadenada a la serie.');
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota, posiciones_max)
	select v_arq, ar.rasgo_id, ar.valor_id, ar.modalidad, ar.nota, ar.posiciones_max
	from public.arquitectura_rasgos ar join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	where ar.arquitectura_id = v_arq_suelto and r.slug in ('distico_final', 'final_acentual');
	insert into public.grupos_eleccion_metrica
		(arquitectura_id, slug, dimension, alcance, seccion_id, tipo_control, selecciones_min, selecciones_max,
		 permite_aplicar_global, define_norma, activo, orden, ayuda_editor, rasgo_id, seccion_tratada_id)
	select v_arq, g.slug, g.dimension, g.alcance, null, g.tipo_control, g.selecciones_min, g.selecciones_max,
		g.permite_aplicar_global, g.define_norma, g.activo, g.orden, g.ayuda_editor, g.rasgo_id, null
	from public.grupos_eleccion_metrica g join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	where g.arquitectura_id = v_arq_suelto and r.slug in ('distico_final', 'final_acentual');
	if (select count(*) from public.grupos_eleccion_metrica where arquitectura_id = v_arq) <> 2 then
		raise exception 'La arquitectura nueva debía recibir dos preguntas.';
	end if;

	-- ══════════════════════════════════════════════════════════ Las anotaciones encadenadas
	-- Fuera lo que la forma nueva no pregunta: encadenamiento (definitorio), densidad y pareados.
	delete from public.anotacion_elecciones e
	using encadenadas x, public.rasgo_valores v, public.rasgos_metricos r
	where e.anotacion_id = x.anotacion_id
		and v.valor_id = e.valor_rasgo_id and r.rasgo_id = v.rasgo_id
		and r.slug in ('encadenamiento_interior', 'densidad_de_rima', 'organizacion_en_pareados');
	update public.anotaciones_metricas am
	set forma_id = v_encadenado, arquitectura_id = v_arq
	from encadenadas x where am.anotacion_id = x.anotacion_id;
	-- Lo que conservan pasa por su disparador contra la arquitectura nueva.
	update public.anotacion_elecciones e set dimension = e.dimension
	from encadenadas x where e.anotacion_id = x.anotacion_id;

	-- ══════════════════════════════════════════════════════════ El suelto, sin el encadenamiento
	if exists (select 1 from public.anotacion_elecciones where valor_rasgo_id = v_valor_enc) then
		raise exception 'Queda alguna respuesta de encadenamiento fuera de las anotaciones movidas.';
	end if;
	delete from public.grupos_eleccion_metrica where grupo_eleccion_id = v_grupo_enc;
	delete from public.arquitectura_rasgos where arquitectura_id = v_arq_suelto and rasgo_id = v_rasgo_enc;
	update public.formas_metricas
	set definicion = replace(definicion,
		' Admite pareados intercalados de manera ocasional y suele cerrarse con un dístico; una modalidad encadena la rima final de cada verso con el interior del siguiente.',
		' Admite pareados intercalados de manera ocasional y suele cerrarse con un dístico.')
	where forma_id = v_suelto and definicion like '%una modalidad encadena la rima final de cada verso con el interior del siguiente.%';
	get diagnostics v_n = row_count;
	if v_n <> 1 then raise exception 'La definición del suelto no decía lo que se esperaba.'; end if;

	-- ══════════════════════════════════════════════════════════ Denominaciones, relación, afirmaciones
	insert into public.denominaciones_metricas (forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values
		(v_encadenado, 'Endecasílabo de rima encadenada', 'endecasilabo_de_rima_encadenada', false, v_navarro),
		(v_encadenado, 'Rima interna en sueltos', 'rima_interna_en_sueltos', false, v_mb),
		(v_encadenado, 'Endecasillabo incatenato', 'endecasillabo_incatenato', false, v_mb),
		(v_encadenado, 'Encadenamiento', 'encadenamiento', false, v_dicc);

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values (v_encadenado, v_suelto, 'contrasta_con',
		$p$Comparten la serie sin estrofa y sin rima entre los finales de verso; los separa que en el encadenado todos los versos riman, cada uno con el interior del siguiente, y en el suelto la rima falta o es esporádica.$p$);

	insert into public.afirmaciones_fuentes_metricas (fuente_id, forma_id, localizador, resumen, confianza)
	values
	(v_navarro, v_encadenado, '§§ 114 y 166, pp. 209 y 258',
		$p$Presenta el endecasílabo de rima encadenada como una forma italiana que Sannazaro y otros poetas de fines del XV y principios del XVI aplicaron sobre todo a la poesía dramática, derivada de la técnica trovadoresca: cada verso lleva una rima interior que repite la final del verso anterior, en italiano en las sílabas 4-5 o 6-7. Garcilaso la empleó con el enlace en 6-7 en gran parte de su segunda égloga, y fue la que menos éxito tuvo de las formas que ensayó; Boscán no la usó. Advierte que la rima fracciona el verso y deforma su unidad, y separa de este procedimiento otro encadenamiento que repite la rima de cada verso al principio del siguiente, como el *leixa-prende*, documentado en un soneto de 1588. En el Siglo de Oro tuvo cierta boga entre finales del XVI y principios del XVII —Villalba y Estaña hacia 1580, Pedro de Padilla en 1582, una alusión de Cervantes en el *Viaje del Parnaso*, comedias de Lope entre 1593 y 1612 y varias obras de Tirso—, siempre en la modalidad de Garcilaso, con la rima en las sílabas 6-7 del verso siguiente; en conjunto, «escasa acogida».$p$, 'alta'),
	(v_mb, v_encadenado, 'Estudio de las estrofas, «Rima interna en sueltos», pp. 173-174',
		$p$Lo tratan como una rima interna dentro de los sueltos: en unas pocas comedias Lope imitó el *endecasillabo incatenato* italiano rimando las sílabas décima y undécima de un verso con la sexta y séptima del siguiente, y mucho menos a menudo con la cuarta y quinta; la rima mantiene su posición aunque el sentido pusiera la cesura en otro sitio. Cuentan por comedia cuántos versos del pasaje llevan la rima, y en varias —*Adonis y Venus*, *El caballero del milagro*, *El enemigo engañado*, *El mayordomo de la duquesa*, *Las mudanzas de fortuna*, *El animal de Hungría*, *Don Lope de Cardona*— el pasaje entero va encadenado, mientras en otras solo lo va una parte. La rima interna es sobre todo anterior a 1604: la primera comedia fechada es *El favor agradecido*, de 1593, y la última segura *La hermosa Ester*, de 1610, con 1612 —cuando Lope empezó a escribir silva de tercer tipo— como fecha más tardía posible.$p$, 'alta'),
	(v_capar, v_encadenado, 'p. 120',
		$p$No la trata como forma sino como una modalidad de la rima interna, que llega a la poesía española con las formas italianas del siglo XVI: rimar el final de un verso con el primer hemistiquio del siguiente. Sitúa el modelo español en la *Égloga II* de Garcilaso, en cuatro tramos largos del poema. En nota añade un uso aislado del mismo enlace fuera de la serie: en la «Canción de Grisóstomo» del *Quijote*, canción en estancias de endecasílabos, el penúltimo verso de cada estancia rima solo con el primer hemistiquio del siguiente.$p$, 'alta'),
	(v_dicc, v_encadenado, 'Entradas «rima interna», pp. 336-337, y «encadenamiento», p. 137',
		$p$No le da entrada propia: es el primero de los tres tipos de rima interna entre versos distintos que distingue, la que enlaza el final de un verso con el final de hemistiquio del siguiente, «ya de forma continuada, ya ocasionalmente dentro del poema». Lo ejemplifica con endecasílabos de la *Égloga II* de Garcilaso, en los que la rima final de cada verso vuelve tras la sexta sílaba del siguiente. La entrada «encadenamiento» remite, en su primer sentido, a la rima interna en general.$p$, 'alta'),
	(v_quilis, v_encadenado, '§ 2.3.4, p. 37',
		$p$No la registra: su «rima encadenada» es la disposición cruzada `abab`.$p$, 'alta'),
	(v_jaur, v_encadenado, '—',
		$p$No la registra.$p$, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones, ejecutando lo que se toca
	if (select count(*) from public.anotaciones_metricas where forma_id = v_encadenado) <> 6 then
		raise exception 'La forma nueva debía recibir seis anotaciones.';
	end if;
	if exists (select 1 from public.anotaciones_metricas am join encadenadas x on x.anotacion_id = am.anotacion_id
		where am.arquitectura_id <> v_arq) then
		raise exception 'Alguna anotación movida no apunta a la arquitectura nueva.';
	end if;
	update public.anotaciones_metricas set forma_id = forma_id where forma_id = v_encadenado;
	if (select count(*) from public.anotaciones_metricas where arquitectura_id = v_arq_suelto) <> 28 then
		raise exception 'El suelto debía quedarse con 28 anotaciones.';
	end if;
	if exists (select 1 from public.arquitectura_rasgos where arquitectura_id = v_arq_suelto and rasgo_id = v_rasgo_enc)
		or exists (select 1 from public.grupos_eleccion_metrica where arquitectura_id = v_arq_suelto and rasgo_id = v_rasgo_enc) then
		raise exception 'El suelto conserva el encadenamiento.';
	end if;
	if (select count(*) from public.afirmaciones_fuentes_metricas where forma_id = v_encadenado) <> 6 then
		raise exception 'La forma nueva debía tener seis afirmaciones.';
	end if;

	perform public.get_forma_metrica_publica_jerarquica('endecasilabo_encadenado');
	perform public.get_forma_metrica_publica_jerarquica('endecasilabo_suelto');
	perform public.obtener_catalogo_demarcador();

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % -> %', v_antes, v_despues;
	end if;
	raise notice 'Endecasílabo encadenado (%): 6 anotaciones movidas; revisión % -> %.', v_encadenado, v_antes, v_despues;
end $$;

commit;
