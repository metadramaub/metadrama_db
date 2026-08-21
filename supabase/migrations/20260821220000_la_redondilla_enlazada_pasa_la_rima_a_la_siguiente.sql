-- La redondilla enlazada pasa la rima a la siguiente
--
-- Tercera de las cinco, y primera de las tres **estrofas enlazadas** que describe Navarro Tomás en
-- su § 131. Son una familia de series en que la rima no se agota dentro de la estrofa sino que
-- **pasa de una a la siguiente**, y él explica para qué: «se hizo de varios modos el enlace de las
-- estrofas, **no como mera gala métrica** a la manera del encadenado de la gaya ciencia, **sino
-- como recurso para dar a la versificación movimiento flexible y corrido**».
--
-- Y en su recorrido del período dice algo que decide su entrada en este catálogo: **«el teatro dio
-- preferencia a las estrofas octosílabas enlazadas de seis y siete versos»**.
--
-- Esta es la más simple de las tres: «una especie de redondilla cuyo último verso es un pie
-- quebrado que introduce un nuevo consonante con el cual rima el principio de la redondilla
-- siguiente: `abbc-cdde-effg`, etc.», en una poesía del *Cancionero de Pedro del Pozo* y en otra
-- del *Cancionero de Évora*.
--
-- **Se registra como serie y no como estrofa**, igual que el terceto encadenado: la unidad se
-- repite y el enlace solo existe entre unidades, de modo que una sola no es la forma. La notación
-- de ciclo la escribe como aquel, `[abbc]…`, y las clases que no riman dentro de la unidad son las
-- que enlazan fuera: se dice en la prosa, porque **el catálogo todavía no sabe declarar que la rima
-- final de una unidad vuelve en la primera de la siguiente** — queda anotado en pendientes.
--
-- *Solo Navarro la documenta. Las otras cinco fuentes no la tratan, y así consta.*

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_redondilla uuid;
	v_encadenado uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_espanola uuid := 'bf56b9c7-1261-41db-8a0c-d82529f88dd3';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_octosilabo uuid := '82bd7a89-675e-41a9-9324-538589731000';
	v_tetrasilabo uuid := 'b7d3c277-feaf-4f2f-905a-cfddc45773c4';
	v_rasgo_quebrado uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Serie de estrofas de cuatro versos octosílabos en que **la rima pasa de una estrofa a la '
		|| 'siguiente**: los dos versos centrales riman entre sí, el cuarto es un pie quebrado que '
		|| 'estrena una clase, y con esa clase abre la estrofa siguiente, cuyo primer verso rima '
		|| 'con él. Así encadenadas, `abbc-cdde-effg`, ninguna estrofa se cierra sobre sí misma y la '
		|| 'serie corre sin pausa. El enlace no es adorno métrico: la tradición lo emplea para dar '
		|| 'a la versificación un movimiento flexible y corrido, y de ahí que estas series se '
		|| 'prefirieran en el teatro. Es la más simple de las tres estrofas enlazadas, y la única '
		|| 'que pasa la rima hacia delante desde su verso quebrado.';
begin
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select forma_id into v_encadenado from public.formas_metricas where slug = 'terceto_encadenado';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';
	if v_redondilla is null or v_encadenado is null or v_rasgo_quebrado is null then
		raise exception 'Falta la redondilla, el terceto encadenado o el rasgo del quiebro.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'redondilla_enlazada') then
		select forma_id into v_forma from public.formas_metricas where slug = 'redondilla_enlazada';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('redondilla_enlazada', 'Redondilla enlazada', c_definicion, 'serie', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'octosilabica_con_quebrado';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'octosilabica_con_quebrado', 'Octosilábica con quebrado',
			'Tres octosílabos y un cuarto verso quebrado que cierra la estrofa estrenando una clase '
			|| 'de rima. Los versos segundo y tercero riman entre sí; el primero recoge la clase que '
			|| 'quedó abierta en la estrofa anterior, y el cuarto abre la que recogerá la siguiente.',
			true, true, 'habitual', v_consonante, true, 1, 4, 4)
		returning arquitectura_id into v_arq;
	end if;

	-- La medida, con el quebrado en su posición
	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq;
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq, 'secuencia', '8-8-8-4')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, x.posicion, x.metro, 1
		from (values (1, v_octosilabo), (2, v_octosilabo), (3, v_octosilabo), (4, v_tetrasilabo))
			as x(posicion, metro);
	end if;

	-- La disposición, con el ciclo que la repite
	select esquema_rima_id into v_esquema from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'enlazada';
	if v_esquema is null then
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
			descripcion
		)
		values (v_arq, 'enlazada', 'Enlazada por el quebrado', '[abbc]…', v_consonante,
			'definitoria', 'ciclo',
			'Dentro de la estrofa solo riman entre sí el segundo verso y el tercero. La primera '
			|| 'clase y la cuarta no quedan sueltas: la primera recoge la que abrió el quebrado de '
			|| 'la estrofa anterior, y la cuarta la pasa a la siguiente.')
		returning esquema_rima_id into v_esquema;

		insert into public.esquema_rima_posiciones
			(esquema_rima_id, bloque, posicion, clase_rima, nota)
		values
			(v_esquema, 1, 1, 'a', 'Recoge la clase que abrió el quebrado de la estrofa anterior.'),
			(v_esquema, 1, 2, 'b', null),
			(v_esquema, 1, 3, 'b', null),
			(v_esquema, 1, 4, 'c', 'Quebrado: estrena la clase con que abre la estrofa siguiente.');
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, posiciones_max, nota)
	select v_arq, v_rasgo_quebrado, 'definitoria', 1,
		'El cuarto verso es quebrado, y no es un adorno: es el que lleva la rima a la estrofa '
		|| 'siguiente.'
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§ 131',
			'Es la única fuente que la describe. La sitúa entre las estrofas enlazadas, cuyo '
			|| 'propósito explica: «se hizo de varios modos el enlace de las estrofas, no como mera '
			|| 'gala métrica a la manera del encadenado de la gaya ciencia, sino como recurso para '
			|| 'dar a la versificación movimiento flexible y corrido». De esta dice que una poesía '
			|| 'del *Cancionero de Pedro del Pozo* «se sirve de una especie de redondilla cuyo '
			|| 'último verso es un pie quebrado que introduce un nuevo consonante con el cual rima '
			|| 'el principio de la redondilla siguiente: `abbc-cdde-effg`», y encuentra el mismo '
			|| 'procedimiento en otra composición del *Cancionero de Évora*. En su recorrido del '
			|| 'período añade lo que justifica estas formas en un catálogo de verso dramático: «el '
			|| 'teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».'],
		array[v_dc16::text, 's. v. «copla encadenada» y «copla capfinida»',
			'No la registra. Su repertorio de enlaces entre estrofas es el de la gaya ciencia —la '
			|| 'copla encadenada, en la que hay lexaprén—, que Navarro Tomás distingue expresamente '
			|| 'de estas series enlazadas.'],
		array[v_dc14::text, 'Índice de estrofas',
			'No la registra. Su recorrido de las combinaciones estróficas no contempla series en '
			|| 'que la rima pase de una estrofa a la siguiente, fuera del terceto encadenado.'],
		array[v_quilis::text, '§ 5.4',
			'No la registra. Entre las estrofas de cuatro versos describe la redondilla, la '
			|| 'cuarteta, la seguidilla y el cuarteto, todas cerradas sobre sí mismas.'],
		array[v_jauralde::text, 'Apartado «Estrofas de cuatro versos»',
			'No la registra con nombre ni epígrafe propio.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas»',
			'No la registran. Su repertorio de metros españoles no distingue las redondillas '
			|| 'enlazadas de las sueltas.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ Los vínculos
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, x.destino, x.tipo, x.nota
	from (values
		(v_redondilla, 'relacionada_con',
			'Navarro la llama «una especie de redondilla», y de la redondilla tiene la extensión y '
			|| 'el par de versos centrales rimados. Pero no es una redondilla: la redondilla cierra '
			|| 'sus dos clases dentro de sí, y esta deja abiertas la primera y la última, que son '
			|| 'las que la atan a las estrofas vecinas.'),
		(v_encadenado, 'relacionada_con',
			'Son las dos maneras que el catálogo registra de encadenar una serie por la rima. En el '
			|| 'terceto encadenado el enlace es la rima central, que vuelve como exterior de la '
			|| 'unidad siguiente; aquí es el verso quebrado del final, que abre la clase con que '
			|| 'empieza la estrofa que viene.')
	) as x(destino, tipo, nota)
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = x.destino)
			or (forma_origen_id = x.destino and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	if not exists (
		select 1 from public.formas_metricas
		where forma_id = v_forma and nivel_estructural = 'serie'
	) then
		raise exception 'La redondilla enlazada no ha quedado registrada como serie.';
	end if;

	select count(*) into v_n
	from public.esquema_rima_posiciones where esquema_rima_id = v_esquema;
	if v_n <> 4 then
		raise exception 'La disposición dibuja % posiciones, no las cuatro.', v_n;
	end if;

	-- Dentro de la unidad solo rima un par: lo demás enlaza fuera, y por eso es serie.
	select count(*) into v_n
	from (
		select p.clase_rima from public.esquema_rima_posiciones p
		where p.esquema_rima_id = v_esquema
		group by p.clase_rima having count(*) > 1
	) x;
	if v_n <> 1 then
		raise exception 'La unidad rima % pares dentro de sí, y debe rimar uno solo.', v_n;
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La redondilla enlazada cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('redondilla_enlazada') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la redondilla enlazada no responde.';
	end if;
end $$;

commit;
