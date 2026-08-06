-- La octava real: definición, descripciones y las seis fuentes.
--
-- Octava forma de la revisión, y la segunda de estructura simple: una arquitectura, un metro,
-- una rima, sin secciones ni variedades. Tenía una sola afirmación.
--
-- 1 · **El esquema estaba escrito tres veces**: en la definición, en la descripción de la
--     arquitectura y en la de la rima, además de en la propia notación que la ficha imprime.
--     Y las denominaciones iban en prosa —«También recibe los nombres de octava rima y octava
--     heroica»— cuando ya están las tres registradas en su tabla.
--
-- 2 · **La arquitectura es única**: nada que distinguir de ninguna hermana, se queda vacía.
--
-- 3 · **La descripción de la rima** decía «Alternancia ABABAB en los seis primeros versos y
--     pareado final CC», que es leer la notación en voz alta. Pasa a decir lo que la notación
--     no dice: que ese pareado es lo estable de la estrofa, y lo que las variaciones respetan.
--
-- Lo que las fuentes añaden, y una pregunta que dejan abierta:
--
-- · **El esquema no es tan fijo como el catálogo lo declara.** El Diccionario dice que «es
--   posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros
--   versos», y Jauralde que la octava «recibió variaciones de todo tipo a lo largo del tiempo,
--   conservando casi siempre de manera fija el pareado final». El catálogo declara solo
--   ABABABCC. No se cambia nada: se registra y se lleva a `cuestiones-para-el-ip.md`.
--
-- · **Si es una estrofa o dos.** Caparrós 2014 remite en nota a la discusión —Lázaro Carreter,
--   1983— sobre si la octava real es una estrofa o la unión de dos, y el Diccionario observa
--   que suele subdividirse en dos grupos de cuatro versos según el contenido. El catálogo la
--   trata como una sola unidad de ocho y no declara secciones.
--
-- Y una limpieza: el vocabulario legado tenía `octava_real` y `octava_real_regular` con la
-- **misma definición palabra por palabra**. De ahí salió la denominación «Octava real
-- regular», que no nombra nada distinto de la forma. Se retira.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'octava_real';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if v_forma is null or v_arq is null then
		raise exception 'Falta la octava real o su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de ocho versos endecasílabos con rima consonante repartida en tres clases: los seis primeros alternan dos y los dos últimos forman pareado con la tercera.'
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = null
	where arquitectura_id = v_arq;

	update public.esquemas_rima
	set descripcion = 'El pareado final es lo estable de la estrofa: cierra con una clase de rima que no ha sonado antes, y las variaciones documentadas alteran la alternancia de los seis primeros versos pero lo respetan.'
	where arquitectura_id = v_arq;

	-- «Octava real regular» no nombra nada distinto de la forma: venía de un término legado
	-- duplicado, con la misma definición palabra por palabra que `octava_real`.
	delete from public.denominaciones_metricas
	where forma_id = v_forma and slug_normalizado = 'octava_real_regular';

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- De dónde viene la estrofa, y quién la trajo.
		(v_quilis, v_forma, 'pp. 106-107',
			'Cuenta su formación: en el siglo XIV Boccaccio modificó en su Teseida la primitiva octava siciliana, de rima alternada, haciendo que los dos últimos versos fuesen pareados, y de ahí resultó ABABABCC. Con esa estructura la emplearon Boyardo, Bembo y Ariosto. En España la introdujo Boscán con su poema Octava rima, de más de cien estrofas, y Ercilla la consagró.',
			'alta'),

		-- Que el esquema admite más de lo que el catálogo declara.
		(v_dicc, v_forma, 'Entrada «octava real», p. 246',
			'Advierte que «es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos». Añade que la estrofa suele subdividirse en dos grupos de cuatro versos según su contenido, y que está tradicionalmente asociada a la poesía épica.',
			'alta'),

		-- Lo mismo, y qué es lo que no varía.
		(v_jauralde, v_forma, '«Estrofas» → «Octava real»',
			'Señala que la octava real clásica tiene la estructura ABABABCC pero recibió variaciones de todo tipo a lo largo del tiempo, conservando casi siempre de manera fija el pareado final.',
			'alta'),

		-- Y una discusión que el catálogo zanja sin decirlo.
		(v_cap14, v_forma, 'p. 202, nota 180',
			'Remite a la discusión sobre si la octava real es una estrofa o la unión de dos, planteada por Lázaro Carreter en 1983, y pone como ejemplo el comienzo de La Araucana de Ercilla.',
			'alta'),

		-- Que no se apagó con el Siglo de Oro.
		(v_navarro, v_forma, '§ 226',
			'La señala como la estrofa endecasílaba de forma orgánica que se mantuvo con más firmeza en su antiguo nivel, y sigue su uso en cantos heroicos y en composiciones de carácter filosófico o novelesco hasta Andrés Bello.',
			'alta'),

		-- La definición escueta de quien la usa para datar.
		(v_mb, v_forma, 'Cap. V, «Octavas (reales)»',
			'La definen sin variantes: ocho endecasílabos ABABABCC.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Octava real · definición, rima y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
