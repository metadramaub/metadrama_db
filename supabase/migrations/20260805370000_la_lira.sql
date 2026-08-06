-- La lira: definición, descripciones y las seis fuentes.
--
-- Séptima forma de la revisión, y la primera de las estructuralmente simples: una
-- arquitectura, un esquema métrico, un esquema de rima, sin secciones ni variedades. Tenía
-- una sola afirmación.
--
-- 1 · **La definición escribía el esquema dos veces** —«rima consonante aBabB y patrón métrico
--     7-11-7-7-11»— y la ficha lo imprime debajo, en Medida y en Rima. Además arrastraba las
--     denominaciones en prosa, cuando `denominaciones_metricas` existe para eso y la lira no
--     tenía ninguna registrada.
--
-- 2 · **La arquitectura repetía el esquema una tercera vez** con «Configuración», que es
--     vocabulario retirado. La lira tiene una sola arquitectura: nada que distinguir, se queda
--     vacía.
--
-- 3 · **La descripción de la rima estaba mal.** Decía «b en los versos 2, 4 y 5», que es cierto
--     de la clase pero mezcla lo que la notación ya separa: en `aBabB` el 2 y el 5 son
--     endecasílabos —mayúscula— y el 4 heptasílabo. Enumerar posiciones no añade nada a una
--     notación de cinco letras que se lee de un vistazo. Pasa a decir lo que la notación no
--     dice: que la estrofa cierra en pareado, que es lo que Jauralde señala como su seña de
--     identidad.
--
-- Sobre el nombre hay una discrepancia que conviene registrar y que **no** obliga a cambiar
-- nada: Morley y Bruerton llaman «lira» a la estrofa de **seis** versos aBaBcC —el sexteto-lira
-- del catálogo— y reservan para esta de cinco el nombre «quintilla de Fray Luis de León».
-- Comprobado que la equivalencia no las cruza: `lira` y `sexteto_lira` son términos legados
-- distintos y cada uno tiene su forma. Jauralde, por su parte, la llama «quinteto-lira o lira
-- propiamente dicha».

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
	select forma_id into v_forma from public.formas_metricas where slug = 'lira';
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
		raise exception 'Falta la lira o su arquitectura';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- 1 · La definición dice qué es, y calla lo que la ficha imprime debajo.
	update public.formas_metricas
	set definicion = 'Estrofa de cinco versos que alterna heptasílabos y endecasílabos con rima consonante repartida en dos clases, y cierra en pareado.'
	where forma_id = v_forma;

	-- 2 · Arquitectura única: nada que distinguir.
	update public.arquitecturas_forma
	set descripcion = null
	where arquitectura_id = v_arq;

	-- 3 · La rima dice lo que su notación no dice.
	update public.esquemas_rima
	set descripcion = 'Los dos últimos versos comparten clase de rima, de modo que la estrofa cierra en pareado. Es lo que la distingue de las demás combinaciones de heptasílabo y endecasílabo en cinco versos.'
	where arquitectura_id = v_arq;

	-- Las denominaciones, a su tabla.
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, tipo_alias, preferente)
	values
		(v_forma, 'Lira garcilasiana', 'lira_garcilasiana', 'equivalente', false),
		(v_forma, 'Estrofa de fray Luis de León', 'estrofa_de_fray_luis_de_leon', 'equivalente', false),
		(v_forma, 'Quinteto-lira', 'quinteto_lira', 'equivalente', false),
		(v_forma, 'Quintilla de Fray Luis de León', 'quintilla_de_fray_luis_de_leon', 'historico', false)
	on conflict do nothing;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- De dónde viene la estrofa y de dónde su nombre.
		(v_dicc, v_forma, 'Entrada «lira», p. 224',
			'Bernardo Tasso había usado ya este esquema en italiano, y Garcilaso lo introdujo en castellano en la canción «A la flor de Gnido», de cuyo primer verso —«Si de mi baja lira»— toma la estrofa su nombre. Cita a Dámaso Alonso sobre su éxito: frente a la larga estrofa petrarquesca, que «es una invitación a la palabrería», la lira ofrecía un molde breve ajustado al modelo horaciano que el Renacimiento quería imitar.',
			'alta'),

		-- Lo mismo, y el número de la canción.
		(v_cap14, v_forma, 'p. 196',
			'Precisa que la composición en que Garcilaso la introdujo es su Canción V, y recoge «lira garcilasiana» y «estrofa de fray Luis de León» como otros nombres de la estrofa.',
			'alta'),

		-- La misma atribución, desde otra fuente.
		(v_quilis, v_forma, 'pp. 100-101',
			'Atribuye la invención de la estrofa a Bernardo Tasso en Italia y su introducción en España a Garcilaso.',
			'alta'),

		-- Lo que la distingue, según quien más la mira de cerca.
		(v_jauralde, v_forma, '«Estrofas» → quintetos mixtos',
			'La llama quinteto-lira o lira propiamente dicha, y la sitúa entre los quintetos mixtos, es decir, los que quiebran el verso largo con uno más breve. Señala que terminar en pareado suele ser su seña de identidad frente a otras estrofas.',
			'alta'),

		-- Que no se apagó con el Siglo de Oro.
		(v_navarro, v_forma, '§ 462',
			'Sigue el rastro de la lira renacentista hasta el siglo XX: la emplearon García Lorca en una oda de homenaje a fray Luis de León y el argentino Ricardo E. Molinari, y observa que vuelve a cultivarse con vitalidad en la poesía de su tiempo.',
			'alta'),

		-- Y un aviso de nombre, que importa para leerlos a ellos.
		(v_mb, v_forma, 'Cap. V, «Liras»',
			'Reservan el nombre de lira para la estrofa de **seis** versos aBaBcC, y llaman a esta de cinco «quintilla de Fray Luis de León». Añaden que todas las liras no son más que formas especializadas de la canzone italiana.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Lira · definición, rima, 4 denominaciones y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
