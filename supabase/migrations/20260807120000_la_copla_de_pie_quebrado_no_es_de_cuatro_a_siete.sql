-- La copla de pie quebrado no tiene quebrados de cuatro a siete sílabas.
--
-- La revisión contra las seis fuentes confirma dos partes distintas del dato actual.
--
-- 1 · **La salida general de cinco a doce versos se conserva.** No es una deducción nueva:
--     responde al criterio original del IP para el corpus. Morley y Bruerton ofrecen además el
--     apoyo preciso para Lope: octosílabos combinados con quebrados de cuatro o cinco sílabas,
--     en estrofas de cinco a doce versos. Navarro Tomás y el Diccionario muestran que «copla de
--     pie quebrado» tuvo numerosas realizaciones y no designó únicamente la sextilla manriqueña.
--
--     La definición dice qué es la combinación. La descripción de la arquitectura dice qué uso
--     hace de ella el proyecto: recibe las unidades que no corresponden a la arquitectura simple
--     ni a la doble de pie quebrado de la sextilla. Esta prioridad clasificatoria no crea una
--     relación `subtipo_de` ni `compuesta_por`; la revisión general de relaciones queda aparte.
--
-- 2 · **Se retira la falsa horquilla de cuatro a siete.** El esquema había convertido la
--     definición general de «verso quebrado» —un verso breve combinado con otro mayor— en cuatro
--     medidas posibles del quebrado del octosílabo. Las fuentes no sostienen esa extrapolación.
--     Para el octosílabo, la medida general es cuatro. El pentasílabo aparece como alternativa,
--     explicada históricamente por sinafía o compensación; Morley y Bruerton lo incluyen de forma
--     expresa en Lope. Hexasílabo y heptasílabo no son quebrados del octosílabo en esta norma.
--
-- Se eliminan por tanto 24 opciones editoriales —seis y siete sílabas en las doce posiciones— y
-- las dos medidas del esquema. La consulta previa en vivo dio cero usos en el editor V2, en las
-- propuestas y en las equivalencias; la migración repite esa comprobación y se detiene si el dato
-- ha cambiado. Quedan 24 opciones: cuatro o cinco sílabas en cada una de las doce posiciones.
--
-- El demarcador todavía no sabe que esta forma es una salida general: el antiguo grado de
-- especificación se retiró precisamente porque nunca intervenía en la puntuación. Este defecto se
-- documenta para resolverlo en el motor, no se disfraza mediante una relación entre formas.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_esquema_metrico uuid;
	v_esquema_rima uuid;
	v_grupo uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_usos integer;
	v_n integer;
begin
	select forma_id into v_forma
	from public.formas_metricas
	where slug = 'copla_de_pie_quebrado';

	select arquitectura_id into v_arq
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica_con_quebrados';

	select esquema_metrico_id into v_esquema_metrico
	from public.esquemas_metricos
	where arquitectura_id = v_arq;

	select esquema_rima_id into v_esquema_rima
	from public.esquemas_rima
	where arquitectura_id = v_arq;

	select grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug = 'medidas_pies_quebrados';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if num_nonnulls(v_forma, v_arq, v_esquema_metrico, v_esquema_rima, v_grupo) <> 5 then
		raise exception 'Falta la copla de pie quebrado o alguna entidad de su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- Ninguna respuesta puede desaparecer con las opciones de seis y siete sílabas.
	select
		(select count(*)
		 from public.elecciones_editor_metrico e
		 join public.opciones_eleccion_metrica o using (opcion_eleccion_id)
		 join public.metros m using (metro_id)
		 where o.grupo_eleccion_id = v_grupo and m.slug in ('hexasilabo', 'heptasilabo'))
		+
		(select count(*)
		 from public.propuesta_elecciones_secuencia p
		 join public.opciones_eleccion_metrica o using (opcion_eleccion_id)
		 join public.metros m using (metro_id)
		 where o.grupo_eleccion_id = v_grupo and m.slug in ('hexasilabo', 'heptasilabo'))
		+
		(select count(*)
		 from public.equivalencias_respuestas_legadas e
		 join public.opciones_eleccion_metrica o using (opcion_eleccion_id)
		 join public.metros m using (metro_id)
		 where o.grupo_eleccion_id = v_grupo and m.slug in ('hexasilabo', 'heptasilabo'))
	into v_usos;

	if v_usos <> 0 then
		raise exception 'Hay % usos de opciones hexasílabas o heptasílabas; no se eliminan', v_usos;
	end if;

	-- La definición métrica y el uso editorial del recipiente general.
	update public.formas_metricas
	set definicion = 'Combinación estrófica de versos octosílabos y pies quebrados tetrasílabos o pentasílabos, con rima consonante y disposición variable.',
		estado_revision = 'aprobada'
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Unidades de cinco a doce versos en las que predominan los octosílabos y los pies quebrados ocupan posiciones variables. El catálogo las registra aquí cuando no corresponden a la arquitectura simple ni a la doble de pie quebrado de la sextilla.',
		estado_revision = 'revisada'
	where arquitectura_id = v_arq;

	-- El esquema ya no presenta como quebrados del octosílabo los versos de seis y siete.
	delete from public.esquema_metrico_opciones o
	using public.metros m
	where o.esquema_metrico_id = v_esquema_metrico
		and o.metro_id = m.metro_id
		and m.slug in ('hexasilabo', 'heptasilabo');

	update public.esquema_metrico_opciones o
	set nota = case m.slug
		when 'tetrasilabo' then 'Medida general del pie quebrado del octosílabo.'
		when 'pentasilabo' then 'Alternativa documentada; históricamente puede resolverse mediante sinafía o compensación con el octosílabo anterior.'
		when 'octosilabo' then 'Medida dominante de la estrofa.'
		else o.nota
	end
	from public.metros m
	where o.esquema_metrico_id = v_esquema_metrico
		and o.metro_id = m.metro_id;

	update public.esquemas_metricos
	set nombre = 'Octosílabos con quebrados de 4 o 5 sílabas',
		slug = 'octosilabos-con-quebrados-4-5',
		descripcion = 'El octosílabo es la medida dominante. Los pies quebrados son tetrasílabos o pentasílabos; la métrica histórica explica el pentasílabo mediante sinafía o compensación con el octosílabo anterior.',
		estado_revision = 'revisada'
	where esquema_metrico_id = v_esquema_metrico;

	update public.esquemas_rima
	set descripcion = 'La rima es consonante, sin una disposición fija entre las posiciones de la unidad.',
		estado_revision = 'revisada'
	where esquema_rima_id = v_esquema_rima;

	-- El registrador conserva las doce posiciones, pero solo ofrece las dos medidas admitidas.
	delete from public.opciones_eleccion_metrica o
	using public.metros m
	where o.grupo_eleccion_id = v_grupo
		and o.metro_id = m.metro_id
		and m.slug in ('hexasilabo', 'heptasilabo');

	update public.opciones_eleccion_metrica o
	set descripcion = case m.slug
		when 'tetrasilabo' then 'Pie quebrado de cuatro sílabas.'
		when 'pentasilabo' then 'Pie quebrado de cinco sílabas.'
		else o.descripcion
	end
	from public.metros m
	where o.grupo_eleccion_id = v_grupo
		and o.metro_id = m.metro_id;

	update public.grupos_eleccion_metrica
	set ayuda_editor = 'Señala qué versos son quebrados y si tienen cuatro o cinco sílabas. El resto son octosílabos.',
		estado_revision = 'revisada'
	where grupo_eleccion_id = v_grupo;

	-- Las seis fuentes autorizadas. Cada afirmación se limita a lo que dice su fuente.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza, estado_revision)
	values
		(v_mb, v_forma, 'Cap. V, «Coplas de pie quebrado»',
			'Las define, para Lope de Vega, como octosílabos combinados con su quebrado de cuatro o cinco sílabas, en estrofas de cinco a doce versos.',
			'alta', 'revisada'),
		(v_quilis, v_forma, 'pp. 104 y 108',
			'Presenta como realización más conocida la sextilla con los versos tercero y sexto tetrasílabos; documenta también una variante con los quebrados en segundo y quinto lugar y octavillas que alternan octosílabos y tetrasílabos.',
			'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 69 y 130',
			'Establece cuatro sílabas como medida general del quebrado del octosílabo y señala que tres y cinco fueron menos corrientes. El pentasílabo aparece como forma alternativa y complementaria del tetrasílabo. En el Renacimiento el pie quebrado intervino en varias clases de coplas; su manifestación más frecuente fue la doble sextilla, aunque también se usó la sextilla independiente.',
			'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 66 y 196',
			'La copla de Jorge Manrique combina octosílabos y tetrasílabos con rima consonante en el esquema `8a 8b 4c 8a 8b 4c`. Cuando el quebrado presenta cinco sílabas métricas, explica la medida mediante sinafía o compensación con el octosílabo anterior.',
			'alta', 'revisada'),
		(v_dicc, v_forma, 'Entradas «copla de pie quebrado», p. 91, y «quebrado», pp. 292–293',
			'La define como combinación estrófica de octosílabos con rima consonante en la que aparece algún tetrasílabo; subraya su gran variedad de formas y señala la sextilla como una de las más frecuentes. Al definir el verso quebrado, identifica el tetrasílabo como quebrado del octosílabo.',
			'alta', 'revisada'),
		(v_jauralde, v_forma, '«Estrofas de seis versos»',
			'Considera las coplas de pie quebrado sextillas simétricas cuyos versos tercero y sexto son menores. Da como disposición más usual octosílabos quebrados por tetrasílabos, con rimas variables entre composiciones, y explica el pentasílabo mediante compensación. Documenta además combinaciones y variantes modernas, incluso con versos blancos.',
			'alta', 'revisada');

	-- ------------------------------------------------------------------
	-- Comprobaciones
	-- ------------------------------------------------------------------

	-- El esquema tiene exactamente las tres medidas que describe: dominante y dos quebrados.
	select count(*) into v_n
	from public.esquema_metrico_opciones o
	join public.metros m using (metro_id)
	where o.esquema_metrico_id = v_esquema_metrico
		and m.slug in ('tetrasilabo', 'pentasilabo', 'octosilabo');
	if v_n <> 3 then
		raise exception 'Se esperaban 3 medidas en el esquema y hay %', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_metrico_opciones
	where esquema_metrico_id = v_esquema_metrico;
	if v_n <> 3 then
		raise exception 'El esquema conserva % medidas en vez de 3', v_n;
	end if;

	-- Doce posiciones por dos medidas, y ninguna posición incompleta.
	select count(*) into v_n
	from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo;
	if v_n <> 24 then
		raise exception 'Se esperaban 24 opciones editoriales y hay %', v_n;
	end if;

	select count(*) into v_n
	from (
		select posicion_unidad
		from public.opciones_eleccion_metrica o
		join public.metros m using (metro_id)
		where o.grupo_eleccion_id = v_grupo
		group by posicion_unidad
		having count(*) <> 2
			or count(*) filter (where m.slug = 'tetrasilabo') <> 1
			or count(*) filter (where m.slug = 'pentasilabo') <> 1
	) posiciones_incorrectas;
	if v_n <> 0 then
		raise exception '% posiciones no ofrecen exactamente cuatro y cinco sílabas', v_n;
	end if;

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'Se esperaban 6 afirmaciones de fuente y hay %', v_n;
	end if;

	if exists (
		select 1
		from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma
			and resumen ~* '(catálogo|proyecto|base de datos|migración)'
	) then
		raise exception 'Una afirmación de fuente opina sobre el catálogo o la implementación';
	end if;

	raise notice 'Copla de pie quebrado · 5–12 versos, quebrados de 4 o 5 sílabas, 24 opciones y 6 afirmaciones';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
