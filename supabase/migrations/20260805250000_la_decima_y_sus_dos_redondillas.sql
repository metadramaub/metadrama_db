-- La décima: definición, partes declaradas y las seis fuentes.
--
-- Tercera forma de la revisión, 18 secuencias. Y la que mejor ilustra la norma, porque su
-- prosa llevaba tiempo diciendo cosas que el dato no declaraba.
--
-- 1 · **La notación no llevaba la pausa.** Las dos descripciones de arquitectura escribían
--     «rima abba:accddc» y «abba:accddeed», con los dos puntos, mientras `notacion` decía
--     `abbaaccddc` y `abbaaccddeed` sin ellos. La pausa tras el cuarto verso es lo más
--     característico de la estrofa —el único punto en que las seis fuentes coinciden— y vivía
--     en una descripción en vez de en la notación.
--
-- 2 · **Las partes no estaban declaradas.** La definición dice «articulada en 4 + 2 + 4» y
--     «los dos versos centrales enlazan la primera redondilla con la segunda», y Quilis lo
--     dice con las mismas palabras: «está formada por dos redondillas, con rima abrazada,
--     abba y cddc, y uniéndolas, dos versos de enlace que repiten las rimas última y primera
--     de cada redondilla, ac». Eso son tres secciones con nombre, y las diez posiciones las
--     tenían a null.
--
-- 3 · **La definición hablaba del catálogo** en su última frase, y las descripciones repetían
--     la notación en prosa en vez de decir qué distingue a cada realización.
--
-- Sobre la aumentada: lo que crece es el miembro final, de cuatro versos a seis, con una
-- clase de rima nueva. La primera redondilla y el enlace no se tocan. Por eso sus secciones
-- son las mismas salvo la última, que ya no es una redondilla y se llama por su función.
--
-- Las fuentes, esta vez, no coinciden en dos puntos, y las dos discrepancias se registran:
--
--   · **Si la pausa es obligatoria.** El Diccionario y Caparrós 2014 dicen que tras el cuarto
--     verso «debe» haber una pausa de sentido. Morley y Bruerton dicen que es característica
--     «aunque no es obligatoria». El catálogo la declara como pausa, no como requisito: es lo
--     que permite anotar los casos en que un dramaturgo la salta.
--   · **Si Espinel la inventó.** Quilis y Jauralde se la atribuyen sin más; el Diccionario
--     dice que no fue el primero pero sí quien la consagró; Caparrós 2014 recoge ejemplos
--     anteriores y el papel de Baltasar del Alcázar. Se registran las tres posiciones.

begin;

do $$
declare
	v_forma uuid;
	v_espinela uuid;
	v_aumentada uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_rima_esp uuid;
	v_rima_aum uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'decima';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	select arquitectura_id into v_espinela from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'espinela';
	select arquitectura_id into v_aumentada from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'aumentada';

	if v_forma is null or v_espinela is null or v_aumentada is null then
		raise exception 'Falta la décima o alguna de sus dos arquitecturas';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	select esquema_rima_id into v_rima_esp from public.esquemas_rima
	where arquitectura_id = v_espinela;
	select esquema_rima_id into v_rima_aum from public.esquemas_rima
	where arquitectura_id = v_aumentada;

	-- 1 · La pausa, a la notación.
	update public.esquemas_rima set notacion = 'abba:accddc' where esquema_rima_id = v_rima_esp;
	update public.esquemas_rima set notacion = 'abba:accddeed' where esquema_rima_id = v_rima_aum;

	-- 2 · Las tres partes que la prosa venía nombrando.
	update public.esquema_rima_posiciones
	set seccion = case
		when posicion <= 4 then 'primera_redondilla'
		when posicion <= 6 then 'versos_de_enlace'
		else 'segunda_redondilla'
	end
	where esquema_rima_id = v_rima_esp;

	update public.esquema_rima_posiciones
	set seccion = case
		when posicion <= 4 then 'primera_redondilla'
		when posicion <= 6 then 'versos_de_enlace'
		else 'cierre'
	end
	where esquema_rima_id = v_rima_aum;

	update public.esquema_rima_posiciones
	set nota = 'Repite la rima última de la primera redondilla y anuncia la primera de la segunda.'
	where esquema_rima_id in (v_rima_esp, v_rima_aum) and posicion in (5, 6);

	update public.esquema_rima_posiciones
	set nota = 'El miembro final crece de cuatro versos a seis con una clase de rima nueva; la primera redondilla y el enlace no cambian.'
	where esquema_rima_id = v_rima_aum and posicion = 7;

	-- 3 · La definición dice qué es la décima, y cada arquitectura qué la distingue.
	update public.formas_metricas
	set definicion = 'Estrofa de diez versos octosílabos con rima consonante formada por dos redondillas abrazadas y dos versos de enlace entre ellas, que repiten la rima última de la primera y anuncian la primera de la segunda: abba, ac, cddc. Tras el cuarto verso se abre una pausa de sentido, y es esa pausa la que la separa de la copla real, que también son diez octosílabos pero se articula en 5 + 5.'
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Realización canónica, la que Espinel divulgó y a la que la estrofa debe su otro nombre.'
	where arquitectura_id = v_espinela;

	update public.arquitecturas_forma
	set descripcion = 'Alarga el miembro final de cuatro versos a seis, con una clase de rima nueva; la primera redondilla y los versos de enlace no cambian. Aparece intercalada entre décimas normales, no como forma aparte.'
	where arquitectura_id = v_aumentada;

	-- Las denominaciones que la bibliografía documenta y el catálogo no tenía.
	insert into public.denominaciones_metricas
		(arquitectura_id, nombre, slug_normalizado, tipo_alias, preferente)
	values
		(v_espinela, 'Espinela', 'espinela', 'equivalente', false),
		(v_espinela, 'Décima clásica', 'decima_clasica', 'equivalente', false),
		(v_espinela, 'Redondilla de diez versos', 'redondilla_de_diez_versos', 'historico', false)
	on conflict do nothing;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma where forma_id = v_forma
		);

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	values
		-- La lectura que el catálogo adopta, dicha con todas las letras.
		(v_quilis, v_forma, null, 'p. 110',
			'Describe la estrofa como dos redondillas de rima abrazada, abba y cddc, unidas por dos versos de enlace que repiten la rima última de la primera y la primera de la segunda. Añade que el tema se plantea en los cuatro primeros versos y que la transición del pensamiento cae en el quinto, y que por su perfección se ha comparado la estrofa con el soneto.',
			'alta'),

		-- El nombre que le puso quien la divulgó, y que confirma esa misma lectura.
		(v_navarro, v_forma, null, '§ 185',
			'Recoge que el nombre que Espinel dio a la estrofa fue simplemente «redondilla de diez versos», y cita el Laurel de Apolo de Lope reclamando que se llamen espinelas por él. Que su propio autor la nombrara desde la redondilla respalda leerla como dos redondillas enlazadas y no como dos quintillas.',
			'alta'),

		-- La pausa como requisito.
		(v_dicc, v_forma, null, 'Entrada «décima espinela», p. 109',
			'Sostiene que tras el cuarto verso **debe** haber una pausa de sentido, y describe el movimiento del pensamiento: las ideas avanzan hasta el cuarto verso y descienden en los seis siguientes sin introducir ideas nuevas. Añade que Espinel no fue el primero en usarla, pero sí quien la consagró y divulgó.',
			'alta'),

		-- La misma exigencia, y lo que se sabe hoy sobre su origen.
		(v_cap14, v_forma, null, 'p. 205',
			'Repite que tras el cuarto verso debe haber pausa de sentido, y matiza el origen: hay algún ejemplo anterior a Espinel, y Micó destaca el papel de Baltasar del Alcázar y su cultivo de la novena en la constitución de la estrofa.',
			'alta'),

		-- Por qué aparece en el teatro, que es lo que este corpus recoge.
		(v_dicc, v_forma, null, 'Entrada «décima espinela», p. 109',
			'Registra que Lope recomendaba las décimas para las quejas, y que fuera del teatro se emplean, por su concisión, en composiciones ingeniosas y de carácter epigramático.',
			'alta'),

		-- Cuándo aparece, y hasta dónde llega fuera de lo que el catálogo recoge.
		(v_jauralde, v_forma, null, '«Estrofas de diez versos»',
			'Sitúa su aparición muy a finales del siglo XVI, tardía respecto de las demás estrofas octosílabas, y señala que se hizo popularísima para toda circunstancia, incluidos los parlamentos teatrales. Registra además realizaciones que el catálogo no recoge —tetrasílabas, hexasílabas, endecasílabas— y décimas rimadas en asonante, todas posteriores al corpus.',
			'alta'),

		-- La lectura alternativa, y el estatuto de la aumentada.
		(v_mb, v_forma, null, 'Cap. V, «Décima (espinela)»',
			'Leen la estrofa como combinación de dos quintillas, la n.º 6 y la n.º 5, y consideran la pausa tras el cuarto verso característica «aunque no obligatoria», donde el Diccionario y Caparrós 2014 la exigen. El catálogo sigue la lectura por redondillas, que sitúa la frontera de la rima donde cae la pausa.',
			'alta'),

		(v_mb, null, v_aumentada, 'Cap. V, «Décima (espinela)»',
			'Registran la décima aumentada de doce versos, ABBA: ACCDDEED, y advierten que es demasiado frecuente para considerarla defectuosa: aparece en medio de pasajes de décimas normales. Es la razón de que figure como arquitectura y no como error de anotación.',
			'alta');
	get diagnostics v_n = row_count;

	raise notice 'Décima · notación con pausa, tres secciones por arquitectura, 3 denominaciones y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
