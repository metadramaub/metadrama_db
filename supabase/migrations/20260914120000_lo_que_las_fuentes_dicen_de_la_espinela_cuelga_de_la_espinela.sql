-- Lo que las fuentes dicen de la espinela cuelga de la espinela, y la silva arromanzada de la suya
--
-- Una afirmación cuelga de **una** cosa: la forma, una arquitectura, un esquema de rima, un rasgo
-- o una tradición. Cuando su texto habla solo de una realización que el catálogo tiene levantada
-- como arquitectura y aun así cuelga de la forma, pasan dos cosas a la vez: la ficha de esa
-- arquitectura se queda sin la fuente que la documenta, y la de la forma se queda con una fuente
-- que no habla de ella.
--
-- **Ningún verificador de las dos pasadas vio este defecto**, porque a los dos se les pidió juzgar
-- el texto de una ficha contra su fuente y de qué columna cuelga no se lee en el texto. Lo
-- encontró la comprobación mecánica de anclaje —`npm run senales:mecanicas`—, que cruza dos
-- señales: que la afirmación nombre con una denominación de dos palabras o más una sola
-- arquitectura de su forma, y que la misma fuente sí haya anclado otras. De los 29 candidatos que
-- levanta, 24 resultaron estar bien colgados al leerlos: hablan de la forma entera y nombran una
-- realización de paso. Estos cinco no.
--
-- **La silva arromanzada** (`514aa1c0`) es el caso que destapó la comprobación, y el más claro: la
-- afirmación entera es «Registra la silva arromanzada o silva-romance, en la que todos los versos
-- pares llevan una misma rima asonante», sobre la entrada «silva arromanzada» del *Diccionario*,
-- mientras sus dos hermanas de esa misma fuente —la silva libre y la de consonantes— sí cuelgan
-- cada una de la suya.
--
-- **Las cuatro de la espinela** son las cuatro fuentes que hablan de la décima de Espinel y no de
-- la décima en general:
--
--   3ac1b32a  Morley y Bruerton, cuyo epígrafe es literalmente «Décima (espinela)» y cuyo texto
--             trata la pausa tras el cuarto verso. Su hermana ya cuelga de «Aumentada».
--   7834edd3  Navarro Tomás § 185, sobre el nombre que Espinel dio a la estrofa —«redondilla de
--             diez versos»— y sobre leerla como dos redondillas enlazadas.
--   b9107b9b  y  962207aa, las dos sobre la entrada «décima espinela» del *Diccionario*, p. 109.
--
-- David aprobó el cambio el 14 de septiembre de 2026, con el argumento de que es lo normal:
-- la espinela es la décima más habitual, y que las fuentes hablen de ella es lo esperable.
--
-- **Lo que se ve al publicar.** La Décima no se queda sin sección: conserva tres afirmaciones a
-- nivel de forma —Quilis 1969, Caparrós 2014 y Jauralde 2020— y gana cuatro en la espinela, que
-- antes no tenía ninguna. La Silva conserva seis y la arromanzada pasa de cero a una.
--
-- No se toca una sola palabra de prosa: solo de qué cuelga cada afirmación.

begin;

do $$
declare
	v_espinela constant uuid := '3b903fc5-7dfd-49b3-9089-548fe394966e';
	v_arromanzada constant uuid := '7aff44ee-86bf-4b97-8605-d256056fcd73';
	v_de_espinela constant uuid[] := array[
		'3ac1b32a-ceaa-41c6-bc13-9b1afd0af64d'::uuid,
		'7834edd3-b126-41e0-afd9-50fa9571d80e'::uuid,
		'b9107b9b-e9bf-4e02-a0b2-3db525a08b19'::uuid,
		'962207aa-0c06-4374-802a-ab3308045795'::uuid
	];
	v_de_silva constant uuid := '514aa1c0-01d2-4941-9be0-f47d9d3a3336';
	v_cuantas integer;
	v_decima_antes integer;
	v_silva_antes integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- ------------------------------------------------------------------ Antes de tocar
	--
	-- Que las dos arquitecturas de destino existen y son las que se cree, y que las cinco
	-- afirmaciones están donde se cree que están. Una migración que mueve filas sin comprobar de
	-- dónde salen puede vaciar una ficha sin que se entere nadie.
	select count(*) into v_cuantas
	from public.arquitecturas_forma ar
	join public.formas_metricas fo using (forma_id)
	where (ar.arquitectura_id = v_espinela and fo.nombre = 'Décima' and ar.nombre = 'Espinela')
		or (ar.arquitectura_id = v_arromanzada and fo.nombre = 'Silva' and ar.nombre = 'Arromanzada');
	if v_cuantas <> 2 then
		raise exception 'No encuentro las arquitecturas de destino: esperaba 2 y hay %.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where a.afirmacion_id = any(v_de_espinela) and fo.nombre = 'Décima';
	if v_cuantas <> 4 then
		raise exception 'Esperaba 4 afirmaciones de la Décima colgadas de la forma y hay %.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where a.afirmacion_id = v_de_silva and fo.nombre = 'Silva';
	if v_cuantas <> 1 then
		raise exception 'No encuentro la afirmación de la silva arromanzada colgada de la Silva.';
	end if;

	-- Cuántas cuelgan hoy de cada forma. **Se cuenta, no se escribe a mano**: la primera versión
	-- de esta migración llevaba los números contados a ojo y se equivocaba en uno, con lo que la
	-- guarda tumbó un cambio que estaba bien. Lo que hay que comprobar no es un número, es que de
	-- cada forma salgan exactamente las que se mueven y ni una más.
	select count(*) into v_decima_antes
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where fo.nombre = 'Décima';

	select count(*) into v_silva_antes
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where fo.nombre = 'Silva';

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ------------------------------------------------------------------ El cambio
	--
	-- La tabla tiene un CHECK de `num_nonnulls(...) = 1`, así que soltar la forma y tomar la
	-- arquitectura tiene que ser la misma sentencia.
	update public.afirmaciones_fuentes_metricas
	set forma_id = null, arquitectura_id = v_espinela
	where afirmacion_id = any(v_de_espinela);

	update public.afirmaciones_fuentes_metricas
	set forma_id = null, arquitectura_id = v_arromanzada
	where afirmacion_id = v_de_silva;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que las cinco han llegado a su sitio y ninguna se quedó colgando de la forma.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_de_espinela)
		and arquitectura_id = v_espinela
		and forma_id is null;
	if v_cuantas <> 4 then
		raise exception 'Solo % de las 4 afirmaciones cuelgan ya de la espinela.', v_cuantas;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_de_silva
		and arquitectura_id = v_arromanzada
		and forma_id is null;
	if v_cuantas <> 1 then
		raise exception 'La silva arromanzada no ha llegado a su arquitectura.';
	end if;

	-- Y que las dos formas conservan lo que tienen que conservar. Es la comprobación que importa
	-- de verdad: mover mal estas cinco no rompe nada visible, solo vacía una ficha en silencio.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where fo.nombre = 'Décima';
	if v_cuantas <> v_decima_antes - 4 then
		raise exception 'La Décima tenía % afirmaciones de forma y ahora tiene %, no %.',
			v_decima_antes, v_cuantas, v_decima_antes - 4;
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.formas_metricas fo using (forma_id)
	where fo.nombre = 'Silva';
	if v_cuantas <> v_silva_antes - 1 then
		raise exception 'La Silva tenía % afirmaciones de forma y ahora tiene %, no %.',
			v_silva_antes, v_cuantas, v_silva_antes - 1;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
