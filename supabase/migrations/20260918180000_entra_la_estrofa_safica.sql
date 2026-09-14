-- Entra la estrofa sáfica, que faltaba en el catálogo
--
-- La destapó la fase 4 de la auditoría de fuentes, al escribir las afirmaciones del cuarteto-lira:
-- **dos fuentes la subordinaban a esa forma y en el catálogo no existía en ninguna parte** —ni como
-- forma, ni como arquitectura, ni como denominación, ni como variedad—. Al mirar las seis resultó
-- ser una de las más documentadas de toda la bibliografía.
--
-- ══ Qué dice cada una, y por qué es forma y no arquitectura
--
--   1968  Morley y Bruerton — nada. Su repertorio es de lo que usa Lope.
--   1969  Quilis, § 5.4.3.4 — **sección propia**, hermana de «5.4.3.1 Cuarteto», «5.4.3.2
--         Redondilla» y «5.4.3.3 Seguidillas», que en este catálogo son formas.
--   1972  Navarro Tomás — **sección propia en los seis períodos** que recorre (§§ 119, 172, 239,
--         301, 374 y 468, según su «Índice de estrofas»), **y otra en cada uno para la estrofa de
--         Francisco de la Torre** (§§ 120, 173, 240, 302, 375 y 468), con entrada para cada una en
--         ese índice. Es el mismo trato que da a la octava aguda, que aquí es forma.
--   2014  Domínguez Caparrós, pp. 190-191 — «dos tipos de cuarteto lira son la estrofa sáfica y la
--         estrofa de Francisco de la Torre».
--   2016  *Diccionario*, pp. 175 y 180 — **entrada propia para cada una**, y de la segunda dice que
--         es «variante de la estrofa sáfica».
--   2020  Jauralde, «Cuartetos mixtos» — historia completa, de Antonio Agustín a Neruda.
--
-- **Todas las páginas se comprobaron en el original leyendo el número impreso**, no en el volcado:
-- Navarro hojas 206-207 y 525 del PDF (pies 213, 214 y 535); Quilis hojas 49-50 (pies 97 y 98);
-- Caparrós hojas 187-188 (pies 190 y 191); *Diccionario* hojas 177 y 182 (pies 175 y 180). Jauralde
-- se localiza por epígrafe, comprobado en el epub.
--
-- No entra como arquitectura del cuarteto-lira porque **rompe sus dos ejes a la vez**: no lleva
-- heptasílabo sino pentasílabo, y no lleva rima. Una arquitectura cambia un eje y conserva la
-- identidad de la forma —la espinela sigue siendo una décima octosílaba consonante—; esto no.
--
-- La de Francisco de la Torre sí es arquitectura, y lo dicen las fuentes: el *Diccionario* la llama
-- «variante de la estrofa sáfica» y Navarro, «construida sobre las mismas líneas de la sáfica, pero
-- distinta de ésta […] por terminar con un heptasílabo en lugar del adónico».
--
-- ══ Lo que se declara y lo que no
--
-- Se declara **la medida, que es fija** —`11 11 11 5` y `11 11 11 7`— y **la ausencia de rima**, que
-- es la norma: Navarro dice «los cuatro, sueltos» y el *Diccionario* «originariamente no lleva
-- rima».
--
-- De las realizaciones rimadas entra una sola, como `admitida`: la que **dos fuentes documentan
-- como regular desde el Neoclasicismo** —Quilis, «solían rimar el primero y tercer endecasílabos»;
-- Navarro, «desde el neoclasicismo se ha compuesto también con los versos rimados»—. **No entran**
-- la asonante, la rima interior del segundo verso con una palabra del tercero, ni la alterna
-- consonante o asonante de la de la Torre: el *Diccionario* las registra de pasada y con «hay quien
-- admite», y por [criterios de nivel § 3.6](../../docs/dominio-metrico/criterios-de-nivel.md) eso no
-- fija la norma. Quedan dichas en la definición y en la voz de quien las da. Es el mismo criterio
-- con que entró el cuarteto-lira.
--
-- ══ Y una cosa que no se esperaba
--
-- **Navarro la documenta en el teatro del XVI**: «Jerónimo Bermúdez intercaló tres composiciones en
-- estrofas sáficas en los coros de *Nise lastimosa*, actos II y III, y *Nise laureada*, acto III».
-- No es una estrofa de traducción horaciana y nada más: entra en el corpus dramático por la tragedia
-- renacentista, que es corpus de este proyecto.
--
-- Nivel, tipo y reparto forma/arquitectura decididos por David el 18 de septiembre de 2026, con los
-- textos a la vista.

begin;

do $$
declare
	v_forma uuid;
	v_safica uuid;
	v_torre uuid;
	v_metrico uuid;
	v_cuarteto_lira uuid;
	v_sin_rima constant uuid := '587b9a6c-41e8-4e36-9807-da49f19647a6';
	v_consonante constant uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_endeca uuid;
	v_penta uuid;
	v_hepta uuid;
	v_mb constant uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis constant uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro constant uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_capar constant uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dicc constant uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jaur constant uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_antes bigint;
	v_despues bigint;

	c_definicion constant text :=
		'Estrofa de cuatro versos que imita la sáfica clásica: tres endecasílabos y un verso corto '
		|| 'que los remata. Nació sin rima, con los cuatro versos sueltos, y desde el Neoclasicismo se '
		|| 'compone también rimada. Los tres endecasílabos son del tipo sáfico, con acento en cuarta y '
		|| 'octava, y el cuarto verso es un pentasílabo dactílico, el adónico, acentuado en primera y '
		|| 'cuarta. Entró en castellano hacia 1540 por imitación de los metros clásicos, y se cultivó '
		|| 'sin interrupción hasta la poesía contemporánea.';
	c_desc_safica constant text :=
		'Tres endecasílabos sáficos y un pentasílabo adónico. La norma no pide rima: los cuatro versos '
		|| 'nacieron sueltos, y la rima que se les añade desde el Neoclasicismo es realización y no '
		|| 'regla.';
	c_desc_torre constant text :=
		'La misma estrofa con un heptasílabo en lugar del adónico, y con los endecasílabos libres de '
		|| 'la acentuación sáfica. La introdujo el bachiller Francisco de la Torre en dos de sus odas, '
		|| 'y la tradición le reconoce nombre propio.';
begin
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	select metro_id into v_penta from public.metros where slug = 'pentasilabo';
	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select forma_id into v_cuarteto_lira from public.formas_metricas where slug = 'cuarteto_lira';
	if v_endeca is null or v_penta is null or v_hepta is null or v_cuarteto_lira is null then
		raise exception 'Falta algún metro o el cuarteto-lira, del que esta forma se declara vecina.';
	end if;

	-- Que de verdad no existía en ninguna parte, que es lo que motiva la migración.
	select count(*) into v_n from public.formas_metricas where slug = 'estrofa_safica';
	if v_n <> 0 then
		raise exception 'La estrofa sáfica ya existe; esta migración daba por hecho que no.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ══════════════════════════════════════════════════════════ La forma
	insert into public.formas_metricas
		(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
	values ('estrofa_safica', 'Estrofa sáfica', c_definicion, 'estrofa', 'forma', true)
	returning forma_id into v_forma;

	-- ══════════════════════════════════════════════════════════ Arquitectura 1 · Sáfica
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max, intercalable
	)
	values (
		v_forma, 'safica', 'Sáfica', c_desc_safica, true, true, 'habitual',
		v_sin_rima, true, 1, 4, 4, false
	)
	returning arquitectura_id into v_safica;

	insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug, medida_uniforme)
	values (v_safica, 'secuencia', '11-11-11-5', false)
	returning esquema_metrico_id into v_metrico;
	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_metrico, 1, v_endeca, 1), (v_metrico, 2, v_endeca, 1),
		(v_metrico, 3, v_endeca, 1), (v_metrico, 4, v_penta, 1);

	-- La norma: cuatro versos sueltos. **Las posiciones no se insertan**: el disparador
	-- `esquemas_rima_sincronizar_posiciones_fijas` las deriva de la notación, y hacerlo a mano choca
	-- con la clave única. Se comprueban abajo, que es lo que toca.
	insert into public.esquemas_rima
		(arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion)
	values (
		v_safica, 'sin_rima', 'Sin rima · cuatro versos sueltos', '----', v_sin_rima,
		'definitoria', 'secuencia',
		'Los cuatro versos van sueltos, que es como la estrofa entró en castellano y como la definen '
		|| 'las fuentes.'
	);

	-- La realización rimada que dos fuentes dan como regular desde el Neoclasicismo.
	insert into public.esquemas_rima
		(arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion)
	values (
		v_safica, 'a-a-', 'Consonante en el primero y el tercero · a-a-', 'a-a-', v_consonante,
		'admitida', 'secuencia',
		'Riman los endecasílabos primero y tercero, y quedan sueltos el segundo y el adónico. Es la '
		|| 'forma rimada que Quilis y Navarro Tomás documentan como corriente desde el Neoclasicismo.'
	);

	-- ══════════════════════════════════════════════════════════ Arquitectura 2 · De la Torre
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max, intercalable
	)
	values (
		v_forma, 'de_la_torre', 'De Francisco de la Torre', c_desc_torre, false, true, 'admitida',
		v_sin_rima, true, 2, 4, 4, false
	)
	returning arquitectura_id into v_torre;

	insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug, medida_uniforme)
	values (v_torre, 'secuencia', '11-11-11-7', false)
	returning esquema_metrico_id into v_metrico;
	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_metrico, 1, v_endeca, 1), (v_metrico, 2, v_endeca, 1),
		(v_metrico, 3, v_endeca, 1), (v_metrico, 4, v_hepta, 1);

	insert into public.esquemas_rima
		(arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion)
	values (
		v_torre, 'sin_rima', 'Sin rima · cuatro versos sueltos', '----', v_sin_rima,
		'definitoria', 'secuencia',
		'Los cuatro versos van sueltos. El *Diccionario* la define «sin rima entre sí», y Navarro '
		|| 'Tomás, en «endecasílabos sueltos».'
	);

	-- ══════════════════════════════════════════════════════════ Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values
		(v_forma, 'Estrofa sáfica', 'estrofa_safica', true, v_dicc),
		(v_forma, 'Sáfico-adónico', 'safico_adonico', false, v_dicc),
		(v_forma, 'Oda sáfica', 'oda_safica', false, v_dicc);

	insert into public.denominaciones_metricas
		(forma_id, arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
	values
		(null, v_torre, 'Estrofa de Francisco de la Torre', 'estrofa_de_francisco_de_la_torre',
			false, v_dicc),
		(null, v_torre, 'Estrofa de la Torre', 'estrofa_de_la_torre', false, v_navarro);

	-- ══════════════════════════════════════════════════════════ Lo que dicen las fuentes
	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
	(v_navarro, v_forma, '§§ 119 y 120, pp. 212-214, e «Índice de estrofas», p. 535',
		'Le da sección propia en los seis períodos que recorre —según su «Índice de estrofas», §§ 119, '
		|| '172, 239, 301, 374 y 468— y otra, en cada uno, a la estrofa de Francisco de la Torre. La '
		|| 'define como estrofa que «consta de cuatro versos sueltos, los tres primeros endecasílabos '
		|| 'sáficos y el cuarto pentasílabo dactílico, llamado generalmente adónico», y en el índice '
		|| 'añade que «desde el neoclasicismo se ha compuesto también con los versos rimados». De la de '
		|| 'la Torre dice que su autor «empleó en dos de sus odas una estrofa en endecasílabos sueltos '
		|| 'construida sobre las mismas líneas de la sáfica, pero distinta de ésta por servirse con '
		|| 'libertad de todas las variedades rítmicas del metro ordinario y por terminar con un '
		|| 'heptasílabo en lugar del adónico». Sitúa su entrada en castellano en una poesía de 1540 de '
		|| 'Antonio Agustín, arzobispo de Tarragona, seguida por el Brocense en su traducción de la oda '
		|| '«Rectius vives». Y la documenta en el teatro: «Jerónimo Bermúdez intercaló tres '
		|| 'composiciones en estrofas sáficas en los coros de *Nise lastimosa*, actos II y III, y *Nise '
		|| 'laureada*, acto III».',
		'alta'),
	(v_quilis, v_forma, '§ 5.4.3.4, pp. 97-98',
		'La sitúa entre las estrofas de cuatro versos, junto al cuarteto, la redondilla y las '
		|| 'seguidillas: «originaria de Italia, trata de imitar los metros clásicos. Aparece en España '
		|| 'en el siglo XVI. Consta de tres endecasílabos sáficos y un pentasílabo con acento en la '
		|| 'primera sílaba (adónico)». Sigue su rima: «en un principio, la estrofa no tenía rima; a '
		|| 'partir del Neoclasicismo solían rimar el primero y tercer endecasílabos». Y anota que '
		|| 'Unamuno «demostró gran interés por este tipo de estrofa: la cultivó intensamente e '
		|| 'introdujo en ella varias modificaciones». La ejemplifica con Esteban Manuel de Villegas y '
		|| 'con el propio Unamuno.',
		'alta'),
	(v_dicc, v_forma, 'Entradas «estrofa sáfica», p. 180, y «estrofa de Francisco de la Torre», p. 175',
		'Le da entrada propia: «combinación estrófica de tres versos endecasílabos —casi siempre de los '
		|| 'que llevan acento en cuarta y octava sílabas— y un pentasílabo —con acento en primera y '
		|| 'cuarta sílabas—. Originariamente no lleva rima, aunque es posible encontrar esta estrofa '
		|| 'con rima consonante o asonante, o con rima interior del segundo verso con una palabra del '
		|| 'tercero». Añade que «es una especie de cuarteto-lira» y que «es una estrofa de carácter '
		|| 'lírico que muy frecuentemente se ha empleado en traducciones de poetas clásicos, a quienes '
		|| 'intenta imitar», y recoge como otros términos «oda sáfica», «sáfico-adónico» y «versos '
		|| 'sáficos». A la estrofa de Francisco de la Torre le da entrada aparte: «estrofa compuesta de '
		|| 'tres endecasílabos seguidos de un heptasílabo, y sin rima entre sí. Es una clase de estrofa '
		|| 'lírica —especie de cuarteto-lira— y variante de la estrofa sáfica. Hay quien admite la rima '
		|| 'consonante alterna, e incluso la rima asonante alterna».',
		'alta'),
	(v_capar, v_forma, 'pp. 190-191',
		'La subordina al cuarteto lira: «dos tipos de cuarteto lira son la estrofa sáfica y la estrofa '
		|| 'de Francisco de la Torre». Define la primera como «la combinación de tres endecasílabos '
		|| '—generalmente del tipo sáfico— y un pentasílabo con acento en la primera sílaba. No lleva '
		|| 'rima, aunque a veces se puede encontrar con ella, o con rima interna del segundo verso con '
		|| 'una palabra del tercero», y da por prototipo los «Sáficos» de Esteban Manuel de Villegas, '
		|| 'en la segunda parte de *Las eróticas o amatorias*. De la segunda dice que «es una variante '
		|| 'de la sáfica, de la que se diferencia solo por tener el cuarto verso heptasílabo», con '
		|| 'ejemplo de su «Oda 4».',
		'alta'),
	(v_jaur, v_forma, 'Apartado «Cuartetos mixtos»',
		'La cuenta entre las estrofas clásicas de las que derivan los cuartetos mixtos —«la llamada '
		|| 'estrofa de la Torre, la estrofa sáfica, la alcaica»— y le da esquema al emparentarla con el '
		|| 'cuarteto-lira: `11A 11B 11B 5a`. La describe como estrofa que «consta en su forma más pura '
		|| 'de tres endecasílabos sáficos blancos y un pentasílabo adónico», y le traza la historia '
		|| 'entera: «incorporada a nuestro repertorio durante el periodo áureo por poetas cultos a lo '
		|| 'largo del siglo XVI (Antonio Agustín, El Brocense), fue luego cultivada por Baltasar del '
		|| 'Alcázar (*A Cupido*) y Esteban Manuel de Villegas; se propagó durante el siglo XVIII como '
		|| 'uno de los grandes hallazgos métricos que trataban de imitar ritmos clásicos. Recogida por '
		|| 'los románticos (Zorrilla, Avellaneda, Bermúdez de Castro…), se cultivó escasamente durante '
		|| 'el modernismo, aunque Unamuno la convirtió en base de muchos de sus experimentos '
		|| 'métricos». La ejemplifica con Villegas, con Meléndez Valdés «en donde se apreciará ya la '
		|| 'inserción de la rima» y con José Hierro. Y anota que «las variedades alargadas de la '
		|| 'estrofa sáfica, alcaica, de la Torre, etc., alcanzan fácilmente los cinco versos».',
		'alta');

	-- ══════════════════════════════════════════════════════════ El vínculo con el cuarteto-lira
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values (
		v_forma, v_cuarteto_lira, 'relacionada_con',
		'Las fuentes no la sitúan igual. El *Diccionario* dice que la sáfica «es una especie de '
		|| 'cuarteto-lira» y Domínguez Caparrós que «dos tipos de cuarteto lira son la estrofa sáfica y '
		|| 'la estrofa de Francisco de la Torre»; Navarro Tomás y Quilis la tratan aparte, con sección '
		|| 'propia. El catálogo la registra como forma porque no comparte con el cuarteto-lira ni la '
		|| 'medida del verso corto —pentasílabo frente a heptasílabo— ni el régimen, que aquí es la '
		|| 'ausencia de rima.'
	);

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n from public.formas_metricas
	where forma_id = v_forma and activo and nivel_estructural = 'estrofa' and tipo_registro = 'forma'
		and definicion = c_definicion;
	if v_n <> 1 then
		raise exception 'La forma no ha quedado como se pretendía.';
	end if;

	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 2 then
		raise exception 'La estrofa sáfica tiene % arquitecturas y esperaba dos.', v_n;
	end if;

	-- Que la medida es la que dicen las fuentes, verso a verso.
	select count(*) into v_n
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos e using (esquema_metrico_id)
	join public.metros m on m.metro_id = p.metro_id
	where e.arquitectura_id = v_safica
		and ((p.posicion in (1, 2, 3) and m.slug = 'endecasilabo')
			or (p.posicion = 4 and m.slug = 'pentasilabo'));
	if v_n <> 4 then
		raise exception 'La sáfica no ha quedado en 11-11-11-5: cuadran % posiciones.', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos e using (esquema_metrico_id)
	join public.metros m on m.metro_id = p.metro_id
	where e.arquitectura_id = v_torre
		and ((p.posicion in (1, 2, 3) and m.slug = 'endecasilabo')
			or (p.posicion = 4 and m.slug = 'heptasilabo'));
	if v_n <> 4 then
		raise exception 'La de la Torre no ha quedado en 11-11-11-7: cuadran % posiciones.', v_n;
	end if;

	-- Que el disparador ha derivado bien las posiciones de las tres notaciones.
	select count(*) into v_n
	from public.esquema_rima_posiciones p
	join public.esquemas_rima e using (esquema_rima_id)
	where e.arquitectura_id in (v_safica, v_torre) and e.slug = 'sin_rima' and p.suelto;
	if v_n <> 8 then
		raise exception 'Los versos sueltos han dado % posiciones y esperaba ocho.', v_n;
	end if;
	select count(*) into v_n
	from public.esquema_rima_posiciones p
	join public.esquemas_rima e using (esquema_rima_id)
	where e.arquitectura_id = v_safica and e.slug = 'a-a-'
		and ((p.posicion in (1, 3) and p.clase_rima = 'a' and not p.suelto)
			or (p.posicion in (2, 4) and p.suelto));
	if v_n <> 4 then
		raise exception 'La disposición «a-a-» no ha quedado bien: cuadran % posiciones.', v_n;
	end if;

	-- Que las dos arquitecturas declaran la ausencia de rima como norma.
	select count(*) into v_n from public.esquemas_rima
	where arquitectura_id in (v_safica, v_torre) and modalidad = 'definitoria'
		and tipo_rima_id = v_sin_rima;
	if v_n <> 2 then
		raise exception 'Alguna arquitectura no declara los versos sueltos como norma.';
	end if;

	-- Que entra una sola realización rimada, y en la sáfica.
	select count(*) into v_n from public.esquemas_rima
	where arquitectura_id in (v_safica, v_torre) and modalidad <> 'definitoria';
	if v_n <> 1 then
		raise exception 'Han entrado % realizaciones rimadas y solo debía entrar una.', v_n;
	end if;

	-- Que habla con las cinco fuentes que la documentan, y que el silencio de Morley y Bruerton
	-- sigue sin registrarse aquí: entrará con la tanda de los silencios de la fase 4.
	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 5 then
		raise exception 'La estrofa sáfica habla con % fuentes y esperaba cinco.', v_n;
	end if;
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma and fuente_id = v_mb;
	if v_n <> 0 then
		raise exception 'Morley y Bruerton tiene afirmación aquí y no debía.';
	end if;

	-- Que la documentación teatral entra, que es lo que la hace interesante para este proyecto.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and resumen like '%Nise lastimosa%';
	if v_n <> 1 then
		raise exception 'No ha entrado el testimonio teatral de Jerónimo Bermúdez.';
	end if;

	-- Y que el catálogo sube de 43 a 44 unidades activas.
	select count(*) into v_n from public.formas_metricas where activo;
	if v_n <> 44 then
		raise exception 'El catálogo tiene % unidades activas y esperaba 44.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
