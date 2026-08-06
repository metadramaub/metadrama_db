-- Seis criterios de prosa, aplicados al catálogo entero y no solo al soneto.
--
-- Salieron revisando el soneto, pero cuatro de los seis alcanzaban a formas que ya estaban
-- revisadas y a otras que aún no se han tocado. Se aplican de una vez para no dejar el
-- catálogo hablando de dos maneras distintas mientras dure el barrido.
--
-- 1 · **«Sexteto» no se dice de los tercetos del soneto.** Aquí son dos tercetos, porque así
--     se separan las posiciones y así se vinculan las secciones. Que una fuente los llame
--     sexteto es cosa suya y sale en su cita; en la prosa del proyecto confunde.
--
-- 2 · **`ABBA ABBA CDC DCD` es el regular.** Se sigue a Quilis, que lo da como esquema del
--     soneto clásico. Jauralde da `CDE DCE`: se señala que difiere, sin equipararlos, porque
--     el catálogo tiene que marcar uno.
--
-- 3 · **«Reutiliza» no se entiende sin decir qué se reutiliza.** Aparecía en seis sitios, y
--     en cuatro con «configuración», que es vocabulario retirado. Ahora cada uno nombra la
--     forma con la que se relaciona.
--
--     Y se retira «el soneto no se formó sumando cuartetos», que además de oscura es falsa
--     tal como se lee: el soneto sí está hecho de dos cuartetos y dos tercetos. Lo que la
--     frase quería decir —que el catálogo no deriva el soneto de la forma «cuarteto», sino
--     que ambos comparten un repertorio— no cabe en una nota de sección y no hace falta.
--
-- 4 · **Un rasgo no cuenta cuándo se rellena.** «Especialización transversal que solo se
--     declara cuando caracteriza la secuencia» describe el formulario, y en tres casos añadía
--     de qué término legado venía, que es historia de la migración. Pasa a decir qué es el
--     rasgo en esa forma.
--
-- 5 · **Una afirmación de fuente no opina sobre el catálogo.** Era lo más extendido: 19
--     afirmaciones acababan valorando qué hace el proyecto —«el catálogo conserva», «el
--     catálogo es aquí más amplio», «METADRAMA adopta actualmente»— o comentando la
--     bibliografía. Una afirmación dice lo que la fuente dice; contrastar dos fuentes entre sí
--     vale, opinar del catálogo no. Donde la divergencia con el catálogo importaba, se queda
--     el dato de la fuente y se va el juicio.
--
-- 6 · **No dar por sabido lo que no se ha dicho.** «Repite la definición del Diccionario»
--     supone que el lector sabe que hay otra obra del mismo autor así llamada. Cada afirmación
--     se lee sola, bajo su propia cita.

begin;

-- ---------------------------------------------------------------------------
-- 1 y 2 · Los tercetos del soneto, y cuál es el regular
-- ---------------------------------------------------------------------------

do $$
declare
	v_forma uuid;
	v_arq uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'soneto';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;

	update public.formas_metricas
	set definicion = 'Composición fija de catorce versos endecasílabos con rima consonante, repartida en dos cuartetos y dos tercetos. Los ocho primeros versos llevan dos clases de rima, abrazadas —ABBA ABBA— en la disposición regular, aunque también se documenta la cruzada. Los dos tercetos llevan dos o tres clases distintas de las anteriores, y su disposición varía: es la única parte del soneto que no está fijada de antemano.'
	where forma_id = v_forma;

	update public.esquemas_rima
	set descripcion = case notacion
		when 'CDCDCD' then
			'Disposición regular: los dos tercetos alternan las mismas dos clases de rima, sin tercera, de modo que son CDC y DCD.'
		when 'CDECDE' then
			'El segundo terceto repite el orden del primero con las mismas tres clases: CDE y CDE.'
		when 'CDEDCE' then
			'Tres clases de rima cuyo orden se invierte en el segundo terceto: CDE y DCE.'
		when 'CDCEDE' then
			'La primera clase enmarca el primer terceto y las otras dos se emparejan en el segundo: CDC y EDE.'
		else descripcion
	end
	where arquitectura_id = v_arq;

	update public.estructuras_secciones
	set nota = 'El esquema de rima no se declara en la sección porque entrelaza los dos tercetos: lo que distingue a las cuatro disposiciones es cómo se responden entre sí, y eso no cabe en tres versos.'
	where arquitectura_id = v_arq and slug = 'terceto';
end $$;

-- ---------------------------------------------------------------------------
-- 3 · Reutilizar, diciendo qué
-- ---------------------------------------------------------------------------

update public.arquitecturas_forma a
set descripcion = 'Catorce endecasílabos consonantes repartidos en dos cuartetos y dos tercetos. Unos y otros riman como lo hacen el cuarteto y el terceto endecasílabos, que son formas del catálogo por derecho propio.'
from public.formas_metricas f
where f.forma_id = a.forma_id and f.slug = 'soneto';

update public.estructuras_secciones s
set nota = 'Los dos cuartetos comparten sus dos clases de rima, y riman como el cuarteto endecasílabo, que el catálogo recoge como forma aparte.'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where a.arquitectura_id = s.arquitectura_id and f.slug = 'soneto' and s.slug = 'cuarteto';

update public.estructuras_secciones s
set nota = 'Cinco octosílabos que riman como una quintilla, que el catálogo recoge como forma aparte.'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where a.arquitectura_id = s.arquitectura_id and f.slug = 'novena' and s.slug = 'quintilla';

update public.estructuras_secciones s
set nota = 'Cuatro octosílabos que riman como una redondilla, que el catálogo recoge como forma aparte.'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where a.arquitectura_id = s.arquitectura_id and f.slug = 'novena' and s.slug = 'redondilla';

update public.estructuras_secciones s
set nota = 'Los cuatro versos de la seguidilla simple, sobre los que se añade el estribillo.'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where a.arquitectura_id = s.arquitectura_id and f.slug = 'seguidilla' and s.slug = 'seguidilla_simple';

-- ---------------------------------------------------------------------------
-- 4 · El rasgo dice qué es, no cuándo se rellena
-- ---------------------------------------------------------------------------

update public.arquitectura_rasgos ar
set nota = 'Terminación esdrújula sostenida en los finales de verso.'
from public.rasgos_metricos r
where r.rasgo_id = ar.rasgo_id
	and r.nombre = 'Final acentual'
	and ar.nota ilike '%transversal%';

-- ---------------------------------------------------------------------------
-- 5 y 6 · Las afirmaciones dicen lo que dice su fuente
-- ---------------------------------------------------------------------------

do $$
declare
	v_quedan integer;
	v_detalle text;
begin
	-- Las que escribí en esta revisión.
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Describen los ocho primeros versos como de **rígido orden** ABBAABBA y solo variables los dos tercetos, de los que dan cuatro disposiciones: la A es CDCDCD, la B CDECDE, la C CDEDCE y la D CDCEDE. Advierten que hay otras y remiten al estudio de Dorothy C. Clarke sobre las rimas de los tercetos en el soneto áureo.'
	where resumen ilike '%rígido orden%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Sitúa la entrada del soneto con el endecasílabo desde Italia en el primer Renacimiento, y precisa que Imperial y Santillana lo cultivaron en el siglo XV con un tono marcadamente medieval que los relegó a antiguallas cuando Boscán y Garcilaso compusieron los suyos. Da como forma clásica ABBA ABBA CDE DCE, donde Quilis da CDC DCD.'
	where resumen ilike '%antiguallas%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Define el soneto como poema de catorce versos de arte mayor formado por catorce endecasílabos en su forma clásica, y añade una condición que no es métrica sino de composición: debe tener unidad temática y un desarrollo completo.'
	where resumen ilike '%Repite la definición del Diccionario%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Reservan el nombre para la disposición abrazada: cuatro octosílabos ABBA, ocasionalmente de seis o siete sílabas. No incluyen la cruzada, que tratan aparte.'
	where resumen ilike '%Reservan el nombre para la disposición abrazada%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Leen la estrofa como combinación de dos quintillas, la n.º 6 y la n.º 5, y consideran la pausa tras el cuarto verso característica «aunque no obligatoria», donde Domínguez Caparrós la exige en las dos obras suyas que el catálogo cita.'
	where resumen ilike '%aunque no obligatoria%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Trata la cuarteta como variante de la redondilla y no como estrofa independiente.'
	where resumen ilike '%Trata la cuarteta como variante%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Registra tres medidas: frecuentemente octosílaba, pero también heptasílaba y hexasílaba. Señala que la comedia nueva encumbró su uso hasta equipararla, con el romance y las décimas, al habla coloquial en prosa.'
	where resumen ilike '%Registra las tres medidas del catálogo%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Extiende el nombre de romancillo a los pentasílabos y tetrasílabos, además del heptasílabo y el hexasílabo. Sitúa el romance heroico en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores.'
	where resumen ilike '%además del heptasílabo y el hexasílabo que recoge el catálogo%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Sitúa la aparición de la décima muy a finales del siglo XVI, tardía respecto de las demás estrofas octosílabas, y señala que se hizo popularísima para toda circunstancia, incluidos los parlamentos teatrales. Registra realizaciones tetrasílabas, hexasílabas y endecasílabas, y décimas rimadas en asonante.'
	where resumen ilike '%tardía respecto de las demás estrofas octosílabas%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Admite como silva también la combinación de endecasílabos y heptasílabos **sin rima**. Recoge además «silva imperfecta» y «canción libre» como otros nombres de la forma.'
	where resumen ilike '%que el catálogo deja fuera porque en la comedia%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Registra la silva arromanzada o silva-romance, en la que todos los versos pares llevan una misma rima **asonante**.'
	where resumen ilike '%sus cuatro realizaciones son consonantes%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Distinguen cuatro tipos: la silva de consonantes aAbBcC; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**.'
	where resumen ilike '%el vocabulario del proyecto llegó a copiar%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Define la redondilla incluyendo las dos disposiciones bajo un mismo nombre, y advierte que en los tratadistas del Siglo de Oro el término era mucho más amplio: abarcaba también la quintilla, la sextilla, la septilla y la octavilla. Añade que modernamente se ha empleado además la rima asonante.'
	where resumen ilike '%que el catálogo no admite en esta forma%';

	-- Las que venían de antes de esta revisión.
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Documenta el encadenamiento ABA BCB CDC… y el cierre YZYZ.'
	where resumen ilike '%METADRAMA adopta%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Describe el verso suelto, libre o blanco como una serie sin rima, y señala como realización más frecuente la serie de endecasílabos solos o con algún heptasílabo.'
	where resumen ilike '%El catálogo conserva el alcance específico%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Explica que «novena» designa en general una estrofa de nueve versos, y documenta la combinación de redondilla y quintilla.'
	where resumen ilike '%El catálogo adopta el alcance octosilábico%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Define el sexteto como estrofa de seis versos de arte mayor, o combinación de arte mayor y menor.'
	where resumen ilike '%El catálogo conserva la delimitación más estricta%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Distingue la versificación irregular o anisosilábica de las formas regulares por no obedecer a la regularidad silábica.'
	where resumen ilike '%La salida editorial del proyecto es más amplia%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Documenta la silva de consonantes como modalidad ajustada a esquemas de pareados o tercetos.'
	where resumen ilike '%METADRAMA formaliza%';

	-- Las dos que lo citaban dentro de una subordinada, donde una comprobación por prefijo no
	-- llega. Se reescriben enteras en vez de recortarlas.
	update public.afirmaciones_fuentes_metricas
	set resumen = 'Describe la seguidilla simple como 7-5-7-5 con asonancia en los pentasílabos pares, y la compuesta como adición de un estribillo 5-7-5 con asonancia entre sus extremos. Documenta además fluctuaciones de medida y casos de consonancia.'
	where resumen ilike '%Describe la seguidilla simple%';

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Leen la estrofa como combinación de dos quintillas, la n.º 6 y la n.º 5, y consideran la pausa tras el cuarto verso característica «aunque no obligatoria», donde Domínguez Caparrós la exige en las dos obras suyas que aquí se citan.'
	where resumen ilike '%Leen la estrofa como combinación de dos quintillas%';

	-- Y un barrido final para lo que quede con esa forma en cualquier otro sitio.
	update public.afirmaciones_fuentes_metricas
	set resumen = regexp_replace(resumen, '\s*(El catálogo|METADRAMA)[^.]*\.', '', 'g')
	where resumen ilike '%el catálogo%' or resumen ilike '%METADRAMA%';

	-- Comprobación: ninguna afirmación habla ya del catálogo ni del proyecto.
	select count(*), string_agg(left(resumen, 60), ' · ')
	into v_quedan, v_detalle
	from public.afirmaciones_fuentes_metricas
	where resumen ilike '%el catálogo%'
		or resumen ilike '%METADRAMA%'
		or resumen ilike '%del proyecto%'
		or resumen ilike '%aquí llevan%';

	if v_quedan > 0 then
		raise exception 'Quedan % afirmaciones que hablan del catálogo: %', v_quedan, v_detalle;
	end if;

	raise notice 'Afirmaciones limpias de juicios sobre el catálogo';
end $$;

comment on column public.afirmaciones_fuentes_metricas.resumen is
	'Lo que la fuente **añade** a la definición, no una paráfrasis suya. Si al leerla no se sabe nada que no dijera ya la definición, la afirmación sobra. Dice lo que la fuente dice: contrastarla con otra fuente vale, opinar sobre el catálogo no, y valorar la bibliografía tampoco. Se lee sola, bajo su propia cita, así que no da por sabido nada que no esté dicho en ella. Se aspira a que las seis fuentes digan algo de cada forma; la que no tenga nada propio que decir, se calla.';

comment on column public.arquitectura_rasgos.nota is
	'Qué es ese rasgo en esta arquitectura. Ni cuándo se rellena ni de qué término legado vino: eso es el formulario y la migración, y ninguno de los dos se cuenta aquí.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
