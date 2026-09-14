-- Cada fuente habla con su voz, y la seguidilla real de Jauralde es la gitana
--
-- Tres afirmaciones cuyo texto no se sostenía. Las tres las aprobó David el 15 de septiembre de
-- 2026, con el texto viejo y el nuevo delante.
--
-- **`ac2eb17b` · Seguidilla · Jauralde.** La ficha enumeraba «la compuesta, la chamberga, la
-- gitana, la real 10-6-10-6». Dos cosas mal en una lista. Dentro del apartado «Seguidillas» el
-- libro dice: «Seguidilla real, **como la denomina sor Juana Inés de la Cruz, o gitana, en la
-- terminología de Augusto Ferrán**» —o sea que la real y la gitana **son la misma estrofa con dos
-- nombres**, y el catálogo las contaba como dos variedades—. Y el esquema 10-6-10-6 no es de esa
-- estrofa ni de ese apartado: aparece en un capítulo distinto sobre combinaciones con el
-- decasílabo, a propósito de Gabriel y Galán. La pasada A y la C llegaron a lo mismo por separado.
--
-- **`4ebe5647` · Septeto-lira · Caparrós 2014.** Cerraba diciendo que la estrofa de siete versos
-- «sí [la] recoge en el *Diccionario*». Es verdad, pero es una afirmación **sobre otro libro** metida
-- en la voz de este, y así presentada parece de Caparrós 2014, que no dice nada de eso ahí. Es la
-- misma familia del «s. v. "cuarteto alirado", recogido en el Diccionario» que lleva una ficha de
-- Navarro Tomás: vocabulario importado. Lo que el *Diccionario* recoja se dice en la afirmación
-- del *Diccionario*, que existe.
--
-- **`31d4d03b` · Soneto · Jauralde.** Cerraba con «donde Quilis da CDC DCD». La comparación es
-- buena y por eso se discutió antes de quitarla, pero no cabe aquí, y la razón de fondo es que
-- **la sección ya compara por sí sola**: «Lo que dicen las fuentes» pone las seis una debajo de
-- otra en la misma ficha, de modo que quien lee el soneto ve el `CDC DCD` de Quilis y el
-- `CDE DCE` de Jauralde sin que nadie se lo diga. Escribirlo dentro de una de las dos duplica en
-- prosa lo que hace la disposición, se lee como si lo dijera Jauralde, y no escala: hacerlo
-- siempre son seis fuentes comparándose entre sí y mantenidas a mano. El contraste no se pierde;
-- lo sigue haciendo la estructura.

begin;

do $$
declare
	v_seguidilla constant uuid := 'ac2eb17b-b34e-4821-bb8b-8dce99a6ac83';
	v_septeto constant uuid := '4ebe5647-0099-40ff-bd47-8ae8a86ec2e0';
	v_soneto constant uuid := '31d4d03b-3276-4ae5-9f01-df97d9c87593';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Se exige el texto viejo entero antes de tocar: si alguien lo ha retocado, esta migración se
	-- para en vez de machacarlo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where (afirmacion_id = v_seguidilla and resumen like '%la gitana, la real 10-6-10-6%')
		or (afirmacion_id = v_septeto and resumen like '%que sí recoge en el *Diccionario*%')
		or (afirmacion_id = v_soneto and resumen like '%donde Quilis da CDC DCD%');
	if v_cuantas <> 3 then
		raise exception 'Esperaba las 3 afirmaciones con su texto antiguo y encuentro %.', v_cuantas;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Describe la cuarteta de versos largos y cortos, normalmente 7-5-7-5 con asonancia en los '
		'pares, y subraya su fluctuación histórica. Recoge la compuesta, la chamberga, la que llama '
		'seguidilla real —la misma que Augusto Ferrán denomina gitana— y la extensión en series '
		'arromanzadas.'
	where afirmacion_id = v_seguidilla;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Describe la canción alirada y sus estrofas —el cuarteto lira entre ellas— sin dar epígrafe '
		'propio a la de siete versos.'
	where afirmacion_id = v_septeto;

	update public.afirmaciones_fuentes_metricas
	set resumen =
		'Sitúa la entrada del soneto con el endecasílabo desde Italia en el primer Renacimiento, y '
		'precisa que Imperial y Santillana lo cultivaron en el siglo XV con un tono marcadamente '
		'medieval que los relegó a antiguallas cuando Boscán y Garcilaso compusieron los suyos. Da '
		'como forma clásica ABBA ABBA CDE DCE.'
	where afirmacion_id = v_soneto;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que lo que sobraba no está.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id in (v_seguidilla, v_septeto, v_soneto)
		and (resumen like '%10-6-10-6%'
			or resumen like '%recoge en el *Diccionario*%'
			or resumen like '%Quilis%');
	if v_cuantas > 0 then
		raise exception 'Todavía queda alguna de las tres cláusulas retiradas.';
	end if;

	-- Y que no se ha perdido por el camino lo que las tres decían bien.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where (afirmacion_id = v_seguidilla
			and resumen like '%Augusto Ferrán denomina gitana%'
			and resumen like '%la chamberga%'
			and resumen like '%series arromanzadas%')
		or (afirmacion_id = v_septeto
			and resumen like '%el cuarteto lira entre ellas%'
			and resumen like '%sin dar epígrafe propio a la de siete versos%')
		or (afirmacion_id = v_soneto
			and resumen like '%Imperial y Santillana%'
			and resumen like '%ABBA ABBA CDE DCE%');
	if v_cuantas <> 3 then
		raise exception 'Alguna de las tres ha perdido lo que decía bien: cuadran %.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
