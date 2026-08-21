-- La doble sextilla sale de la sextilla
--
-- Última de las seis, y la que cierra la incoherencia que las demás dejaron a la vista. **La misma
-- oposición se repetía en el catálogo a ocho, a diez y a doce versos, resuelta de tres maneras
-- distintas**: dos semiestrofas que comparten una rima, frente a dos que no comparten ninguna.
--
-- | versos | enlazadas | independientes |
-- | --- | --- | --- |
-- | 8 | era una arquitectura de la redondilla | no existía |
-- | 10 | **décima**, forma | **copla real**, forma |
-- | 12 | no existe | era una arquitectura de la sextilla |
--
-- A diez eran formas; a ocho y a doce, arquitecturas escondidas dentro de la estrofa mitad. Y
-- Navarro pone las tres en la misma serie al explicar por qué la manriqueña separa sus dos
-- sextillas: «desligaba una sextilla de otra con separación semejante a la practicada entre **las
-- redondillas de la copla castellana y las quintillas de la copla real**».
--
-- **El criterio que el IP fijó el 21 de agosto de 2026**, y que estas seis migraciones aplican: lo
-- que hace forma aparte es la articulación —cuántos miembros, de qué tamaño y si comparten rima—;
-- la medida y la disposición son arquitectura; el nombre no decide nada. Con un indicio duro: **una
-- arquitectura no cambia la extensión de la unidad de su forma**, y esta declaraba
-- `unidad_versos = 12` dentro de una forma cuya unidad es 6.
--
-- La arquitectura se muda entera —basta cambiarle la forma, y con ella viajan sus esquemas, sus
-- secciones, su grupo y sus rasgos, sin tocar ninguna clave ajena—, y gana lo que le faltaba:
-- definición propia, sus dos sextillas declaradas como partes que reutilizan la simple, sus nombres
-- y sus seis fuentes.
--
-- **Su descripción decía lo contrario de lo que esta migración hace, y se reescribe.** Decía: «no
-- es una estrofa distinta de la simple: la medida y la rima se organizan exactamente igual […] lo
-- único que las enlaza es el sentido». Es cierto de la agrupación, y por eso la definición nueva lo
-- conserva —es el mismo caso que la copla castellana frente a dos redondillas seguidas—; lo que no
-- se sostiene es tratarlo distinto según el número de versos.
--
-- *El nombre se reparte, y las dos fichas lo dicen.* Quilis y Domínguez Caparrós llaman manriqueña
-- a la estrofa de seis; Navarro Tomás y Jauralde, a la agrupación de doce. Las denominaciones
-- quedan en las dos, cada una con su ficha explicándolo.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid := 'abf2d2e7-2726-45db-b1e8-acf5219c4c4b';
	v_sextilla uuid;
	v_simple uuid;
	v_espanola uuid := 'bf56b9c7-1261-41db-8a0c-d82529f88dd3';
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_actual text;
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de doce versos formada por dos sextillas de pie quebrado seguidas, con sus rimas '
		|| 'independientes: ninguna pasa de la primera a la segunda. Es la estrofa de las *Coplas* '
		|| 'de Jorge Manrique a la muerte de su padre, y su disposición más conocida reparte los '
		|| 'doce versos en cuatro tercetos correlativos, `abc:abc-def:def`, con el tercer verso de '
		|| 'cada terceto quebrado. La tradición documenta antes otras: sextillas de dos rimas '
		|| 'repetidas en las dos mitades, o con el orden invertido en la segunda. Métricamente no '
		|| 'se distingue de dos sextillas puestas una detrás de otra —la medida y la rima se '
		|| 'organizan igual, y lo que corre de una a otra es el sentido del texto—, y esa es '
		|| 'también la relación de la copla castellana con dos redondillas y de la copla real con '
		|| 'dos quintillas: lo que une las semiestrofas es la manera en que el poema las agrupa.';

	c_descripcion constant text :=
		'Doce versos en dos sextillas de pie quebrado. Cada una lleva sus propias consonancias y '
		|| 'ninguna vuelve de la primera a la segunda, que es lo que las individualiza; el quiebro '
		|| 'cierra cada terceto.';

	c_nota_simple constant text :=
		'Es la sextilla más conocida, y la que dio fama a la estrofa: Jorge Manrique la empleó en '
		|| 'las coplas por la muerte de su padre, agrupada de dos en dos. El quiebro cae normalmente '
		|| 'en el tercer verso y el sexto, pero la tradición lo documenta también en otras '
		|| 'posiciones. El nombre de manriqueña se reparte: Quilis y Domínguez Caparrós lo dan a '
		|| 'esta estrofa de seis, y Navarro Tomás y Jauralde a la agrupación de doce.';
begin
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';
	select arquitectura_id into v_simple from public.arquitecturas_forma
	where forma_id = v_sextilla and slug = 'pie_quebrado';

	if v_sextilla is null or v_simple is null then
		raise exception 'Falta la sextilla o su arquitectura de pie quebrado.';
	end if;
	if not exists (select 1 from public.arquitecturas_forma where arquitectura_id = v_arq) then
		raise exception 'No existe la arquitectura doble que hay que mudar.';
	end if;

	-- Nada anotado depende de ella.
	select count(*) into v_n from public.secuencias_editor_metrico where arquitectura_id = v_arq;
	if v_n <> 0 then
		raise exception 'Hay % secuencias anotadas sobre la doble sextilla.', v_n;
	end if;

	-- ----------------------------------------------------------------------- La forma
	if exists (select 1 from public.formas_metricas where slug = 'doble_sextilla') then
		select forma_id into v_forma from public.formas_metricas where slug = 'doble_sextilla';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('doble_sextilla', 'Doble sextilla', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	-- ------------------------------------------------------- La arquitectura se muda entera
	-- Cambiar `forma_id` arrastra esquemas, secciones, grupo y rasgos sin tocar ninguna clave
	-- ajena: todos cuelgan de `arquitectura_id`, que no cambia.
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual not like '%No es una estrofa distinta de la simple%'
		and v_actual is distinct from c_descripcion
	then
		raise exception 'La descripción de la doble no es la esperada. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set
		forma_id = v_forma,
		nombre = 'De pie quebrado',
		descripcion = c_descripcion,
		principal = true,
		modalidad = 'habitual',
		orden = 1
	where arquitectura_id = v_arq;

	-- Sus dos partes pasan a reutilizar la sextilla simple, que es lo que realizan.
	update public.estructuras_secciones set arquitectura_referenciada_id = v_simple
	where arquitectura_id = v_arq and slug in ('primera_sextilla', 'segunda_sextilla');

	-- Y la simple explica el reparto del nombre.
	update public.arquitecturas_forma set descripcion = c_nota_simple where arquitectura_id = v_simple;

	-- -------------------------------------------------------------------- Los nombres
	foreach v_fila slice 1 in array array[
		array['Copla manriqueña', 'copla_manriquena'],
		array['Estrofa manriqueña', 'estrofa_manriquena'],
		array['Copla de Jorge Manrique', 'copla_de_jorge_manrique']
	] loop
		insert into public.denominaciones_metricas
			(forma_id, nombre, slug_normalizado, preferente, fuente_id)
		select v_forma, v_fila[1], v_fila[2], false, v_navarro
		where not exists (
			select 1 from public.denominaciones_metricas
			where forma_id = v_forma and slug_normalizado = v_fila[2]
		);
	end loop;

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§§ 67 y 68',
			'Le da epígrafe propio bajo «copla mixta»: «la estrofa de doce versos fue concebida '
			|| 'ordinariamente como una pareja de sextillas». Sigue su historia disposición a '
			|| 'disposición: en el *Cancionero de Baena* las dos sextillas se ajustan a dos únicas '
			|| 'rimas, con los quebrados en posición interior, `aab:aab-aab:aab`; en Villasandino el '
			|| 'orden se invierte en la segunda, `aab:aab-bba:bba`; Juan de Mena aplica rimas '
			|| 'distintas a cada sextilla sin mover el verso corto. Y hacia la mitad del siglo '
			|| 'aparece la que se impuso —cada sextilla con tres rimas correlativas propias y los '
			|| 'versos cortos al final de cada terceto, `abc:abc-def:def`—, registrada primero en '
			|| 'Juan de Mena y que «alcanzó fama permanente con las coplas de Jorge Manrique a la '
			|| 'muerte de su padre». Explica además por qué: al individualizar las rimas de cada '
			|| 'mitad, esa forma «desligaba una sextilla de otra con separación semejante a la '
			|| 'practicada entre las redondillas de la copla castellana y las quintillas de la copla '
			|| 'real».'],
		array[v_jauralde::text, 'Apartado «Coplas de pie quebrado»',
			'Cuenta los doce: dice que aunque «se presenta muchas veces como octavilla de pie '
			|| 'quebrado, su forma más habitual es la de doble sextilla con seis rimas», y señala '
			|| 'que el Romanticismo imitó después la sextilla simple.'],
		array[v_quilis::text, '§ 5.4.5.4',
			'Cuenta los seis: describe la copla de pie quebrado como estrofa de seis versos y '
			|| 'atribuye su fama a haberla empleado Jorge Manrique en sus *Coplas*, citando el '
			|| 'pasaje «¿Qué se hicieron las damas…» con el esquema `aabccb`. La agrupación de doce '
			|| 'no recibe en su exposición nombre ni epígrafe propio.'],
		array[v_dc16::text, 's. v. «copla de pie quebrado» y «copla mixta»',
			'Cuenta también los seis: la manriqueña es para él la estrofa de pie quebrado. Su '
			|| 'entrada «copla mixta» sí contempla la agrupación de doce, al definirla como '
			|| 'combinación «dividida en dos semiestrofas de distinta extensión **o en dos '
			|| 'sextillas**».'],
		array[v_dc14::text, 'pp. 200 y ss.',
			'Describe la estrofa manriqueña como sextilla de pie quebrado, sin epígrafe para la '
			|| 'pareja de doce versos.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»',
			'No la separan. Definen «coplas de pie quebrado» como octosílabos combinados con su '
			|| 'quebrado de cuatro o cinco sílabas «en estrofas (en Lope) de cinco a doce versos», '
			|| 'de modo que la agrupación de doce cae dentro de ese rango sin nombre propio.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ El vínculo
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_sextilla, 'compuesta_por',
		'Cada mitad es una sextilla de pie quebrado entera, con sus consonancias propias. Que '
		|| 'ninguna rima pase de una a otra es lo que las individualiza, y lo que hace de la '
		|| 'agrupación una estrofa de doce y no una serie de sextillas: lo que corre entre ellas es '
		|| 'el sentido del texto.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_sextilla
	);

	-- ------------------------------------------------------------------ Comprobaciones
	-- La sextilla vuelve a medir seis versos en todas sus arquitecturas.
	if exists (
		select 1 from public.arquitecturas_forma
		where forma_id = v_sextilla and activo and unidad_versos_max > 6
	) then
		raise exception 'La sextilla sigue teniendo una arquitectura de más de seis versos.';
	end if;
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_sextilla and activo;
	if v_n <> 4 then
		raise exception 'La sextilla queda con % arquitecturas, no las cuatro.', v_n;
	end if;

	-- Y la doble se llevó todo lo suyo.
	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'La doble sextilla llegó con % disposiciones, no las dos.', v_n;
	end if;
	if not exists (
		select 1 from public.estructuras_secciones
		where arquitectura_id = v_arq and arquitectura_referenciada_id = v_simple
	) then
		raise exception 'Las dos sextillas no reutilizan la simple.';
	end if;
	select count(*) into v_n
	from public.estructuras_secciones where arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'La doble sextilla tiene % partes, no las dos.', v_n;
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La doble sextilla cita % fuentes, no las seis.', v_n;
	end if;

	-- Ninguna arquitectura activa cambia ya la extensión de la unidad de su forma **salvo en las
	-- tres formas donde la tradición documenta la misma forma en extensiones distintas**. Al
	-- escribir esta comprobación se dio por sentada una sola excepción, la décima aumentada, y la
	-- base dijo que son tres: se enumeran, para que la cuarta se note.
	--
	--   · décima     — la aumentada estira el miembro final y se intercala entre décimas normales
	--   · sextina    — la doble de Montemayor y la doble petrarquista repiten la composición entera
	--   · seguidilla — la simple, la de tres versos, la compuesta, la chamberga y la gitana son la
	--                  misma forma en extensiones que la tradición nombra por separado
	select string_agg(x.slug, ', ' order by x.slug) into v_actual
	from (
		select f.slug
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where a.activo and f.activo and a.unidad_versos_max is not null
		group by f.forma_id, f.slug
		having count(distinct a.unidad_versos_max) > 1
	) x;
	if v_actual is distinct from 'decima, seguidilla, sextina' then
		raise exception 'Extensiones distintas en «%»: deberían ser las tres documentadas.', v_actual;
	end if;

	foreach v_fila slice 1 in array array[array['doble_sextilla'], array['sextilla']] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
