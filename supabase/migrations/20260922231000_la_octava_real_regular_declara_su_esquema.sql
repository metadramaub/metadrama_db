-- La octava real regular declara su esquema
--
-- `octava_real_regular` es el término legado más usado sin destino: doce secuencias en cinco
-- obras, unas ciento quince octavas. Su definición dice lo que es —«estrofa formada por ocho
-- endecasílabos con rima ABABABCC»— y lo repite en el propio dato, `patron_especifico`. Sin
-- destino, la propuesta lo resolvía por ascendencia hasta la forma y dejaba el esquema de rima
-- sin responder: el informe de migración se lo iba a pedir al editor octava por octava.
--
-- Se hace lo mismo que con `redondilla_regular`, que es el caso hermano: la arquitectura reclama el
-- término, y una fila de `equivalencias_respuestas_legadas` declara el esquema que el término
-- afirma. Es una respuesta **derivada**, no anotada: el cuestionario la enseña rellena para que
-- quien anotó confirme que ninguna de sus octavas rimaba de otra manera y eligió «regular» sin
-- reparar en que decía ABABABCC.
--
-- **Se comprueba leyendo las dos vistas**: las doce secuencias pasan a resolver por la vía directa,
-- y `propuesta_elecciones_secuencia` responde el esquema en cada una de sus unidades.

begin;

do $migracion$
declare
	v_termino uuid;
	v_arquitectura uuid;
	v_esquema uuid;
	v_directas integer;
	v_unidades integer;
	v_respuestas integer;
begin
	select v.termino_id into v_termino
	from public.vocabularios v
	where v.categoria = 'estrofa_tipo' and v.termino = 'octava_real_regular';

	select a.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'octava_real' and a.activo
	order by a.principal desc, a.orden
	limit 1;

	select e.esquema_rima_id into v_esquema
	from public.esquemas_rima e
	where e.arquitectura_id = v_arquitectura and e.notacion = 'ABABABCC';

	if v_termino is null or v_arquitectura is null or v_esquema is null then
		raise exception 'Falta el término (%), la arquitectura (%) o el esquema ABABABCC (%).',
			v_termino, v_arquitectura, v_esquema;
	end if;

	-- ------------------------------------------------------------------ La arquitectura reclama el término
	update public.arquitecturas_forma a
	set origen_termino_id = v_termino
	where a.arquitectura_id = v_arquitectura and a.origen_termino_id is null;

	-- ------------------------------------------------------------------ Y el término afirma su esquema
	insert into public.equivalencias_respuestas_legadas (
		termino_id, arquitectura_id, dimension, esquema_rima_id, nota
	)
	select v_termino, v_arquitectura, 'rima', v_esquema,
		'El término legado declara su disposición en el propio dato: patron_especifico = «ABABABCC», y su definición dice «rima ABABABCC».'
	where not exists (
		select 1 from public.equivalencias_respuestas_legadas e
		where e.termino_id = v_termino and e.esquema_rima_id = v_esquema
	);

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se leen las vistas.** Las doce secuencias resuelven ya por la vía directa, con esta
	-- arquitectura.
	select count(*) into v_directas
	from public.propuesta_metrica_secuencia p
	where p.termino_legado = 'octava_real_regular'
		and p.via = 'directa'
		and p.arquitectura_propuesta_id = v_arquitectura;

	if v_directas <> 12 then
		raise exception 'Solo % de las 12 secuencias de octava_real_regular resuelven por la vía directa.',
			v_directas;
	end if;

	-- Y cada una de sus octavas llega con el esquema respondido: tantas respuestas derivadas como
	-- unidades de ocho versos caben en las doce secuencias.
	select coalesce(sum((p.v_fin - p.v_ini + 1) / 8), 0) into v_unidades
	from public.propuesta_metrica_secuencia p
	where p.termino_legado = 'octava_real_regular';

	select count(*) into v_respuestas
	from public.propuesta_elecciones_secuencia r
	join public.propuesta_metrica_secuencia p on p.secuencia_id = r.secuencia_id
	where p.termino_legado = 'octava_real_regular'
		and r.opcion_eleccion_id in (
			select o.opcion_eleccion_id from public.opciones_eleccion_metrica o
			where o.esquema_rima_id = v_esquema
		)
		and r.origen = 'derivada'
		and r.alcance = 'unidad';

	if v_respuestas <> v_unidades or v_unidades = 0 then
		raise exception 'La propuesta responde el esquema en % unidades y las secuencias tienen %.',
			v_respuestas, v_unidades;
	end if;

	raise notice 'octava_real_regular resuelve directa a la arquitectura y responde ABABABCC en % octavas.',
		v_respuestas;
end
$migracion$;

commit;
