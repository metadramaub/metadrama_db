-- La novena en orden 5+4 no admite quiebro
--
-- Declaraba el pie quebrado como `admitida` y lo preguntaba en sus nueve versos, y **ninguna fuente
-- lo documenta**. Lo decía su propia nota: la posición salía de trasladar a este orden lo que sí se
-- lee en el otro, donde el quiebro abre la quintilla. Es un razonamiento correcto y sigue siendo una
-- suposición, y el catálogo declara lo que las fuentes documentan.
--
-- **La novena en orden 4+5 no se toca**: allí hay una realización leída —Jauralde recoge de
-- Castillejo «8a 8b 8b 8a 4c 8c 8d 8d 8c»— y sus quiebros se declararon en el quinto verso el 29 de
-- agosto de 2026.
--
-- Se retiran tres filas, y no cuelga nada de ellas: cero respuestas guardadas y cero equivalencias
-- con el vocabulario legado. Se conserva el rol `dominante` del octosílabo, así que la arquitectura
-- pasa a afirmar lo que sí está documentado: nueve octosílabos.
--
-- **Los dos textos que se pierden quedan aquí**, porque razonan el caso y volver a ponerlo es
-- copiarlos:
--
--   `arquitectura_rasgos.nota`:
--   «En el orden 5+4 ninguna fuente documenta un ejemplo con quebrado. Por el patrón que sí se
--   documenta —el quebrado abre la quintilla—, caería en el primer verso de la estrofa, que es donde
--   la quintilla empieza con este orden. Sigue siendo uno solo.»
--
--   `grupos_eleccion_metrica.ayuda_editor` de `posiciones_pie_quebrado`:
--   «El quiebro es una licencia, no la norma: marca los versos que veas acortados y su medida, y
--   deja la pregunta en blanco si no hay ninguno. Las fuentes documentan uno solo; si el pasaje trae
--   más, regístralo como desviación.»
--
-- Si aparece un ejemplo leído, se reponen: la fila del rasgo con `admitida` y `posiciones_max: 1`,
-- los dos roles de quiebro, y las posiciones declaradas en el verso que documente —previsiblemente
-- el primero, que es donde empieza la quintilla con este orden—.

begin;

do $$
declare
	v_arquitectura uuid;
	v_rasgo uuid;
	v_esquema uuid;
	v_grupo uuid;
	v_respuestas integer;
	v_equivalencias integer;
	v_roles integer;
begin
	select a.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Novena' and a.nombre = 'Quintilla + redondilla';

	if v_arquitectura is null then
		raise exception 'No está la novena en orden 5+4: revisa el catálogo antes de seguir.';
	end if;

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';
	if v_rasgo is null then
		raise exception 'No está el rasgo pie_quebrado.';
	end if;

	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos where arquitectura_id = v_arquitectura;

	-- ------------------------------------------------------------------ 1 · la pregunta
	select g.grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica g
	where g.arquitectura_id = v_arquitectura and g.dimension = 'metro' and g.rasgo_id is null;

	if v_grupo is null then
		raise notice 'La novena en orden 5+4 ya no pregunta la medida de los quebrados.';
	else
		select count(*) into v_respuestas
		from public.anotacion_elecciones where grupo_eleccion_id = v_grupo;
		if v_respuestas > 0 then
			raise exception 'Hay % respuestas guardadas a la medida de los quebrados de la novena 5+4.', v_respuestas;
		end if;

		select count(*) into v_equivalencias
		from public.equivalencias_respuestas_legadas where grupo_eleccion_id = v_grupo;
		if v_equivalencias > 0 then
			raise exception 'Hay % equivalencias legadas apuntando a esa pregunta, y caerían en cascada.', v_equivalencias;
		end if;

		delete from public.grupos_eleccion_metrica where grupo_eleccion_id = v_grupo;
	end if;

	-- ------------------------------------------------------------------ 2 · la declaración
	delete from public.arquitectura_rasgos
	where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo;

	-- ------------------------------------------------------------------ 3 · los dos roles de quiebro
	--
	-- El `dominante` se queda: es lo que dice que la estrofa es octosilábica.
	if v_esquema is not null then
		delete from public.esquema_metrico_opciones
		where esquema_metrico_id = v_esquema and rol = 'quebrado';

		select count(*) into v_roles
		from public.esquema_metrico_opciones
		where esquema_metrico_id = v_esquema and rol = 'dominante';

		if v_roles < 1 then
			raise exception 'La novena en orden 5+4 se ha quedado sin medida dominante.';
		end if;
	end if;
end $$;

do $$
declare
	v_rasgos integer;
	v_preguntas integer;
	v_opciones integer;
	v_otra_rasgo integer;
	v_otra_versos integer[];
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee lo que ha quedado**, y por la vista derivada, que ejecuta la función de opciones.
	select count(*) into v_rasgos
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'pie_quebrado' and f.nombre = 'Novena' and a.nombre = 'Quintilla + redondilla';

	if v_rasgos <> 0 then
		raise exception 'La novena en orden 5+4 sigue declarando el pie quebrado.';
	end if;

	select count(*) into v_preguntas
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Novena' and a.nombre = 'Quintilla + redondilla' and g.dimension = 'metro';

	if v_preguntas <> 0 then
		raise exception 'La novena en orden 5+4 sigue preguntando por la medida.';
	end if;

	-- Y no ofrece ninguna opción de metro, que es lo que se comprueba ejecutando la función.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Novena' and a.nombre = 'Quintilla + redondilla' and g.dimension = 'metro';

	if v_opciones <> 0 then
		raise exception 'La novena en orden 5+4 aún deriva % opciones de metro.', v_opciones;
	end if;

	-- ------------------------------------------------------------------ Y la otra novena, intacta
	select count(*) into v_otra_rasgo
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'pie_quebrado' and f.nombre = 'Novena' and a.nombre = 'Redondilla + quintilla';

	if v_otra_rasgo <> 1 then
		raise exception 'La novena en orden 4+5 debía conservar su pie quebrado, y tiene % filas.', v_otra_rasgo;
	end if;

	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_otra_versos
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Novena' and a.nombre = 'Redondilla + quintilla' and g.dimension = 'metro';

	if v_otra_versos is distinct from array[5] then
		raise exception 'La novena en orden 4+5 ofrece el quiebro en %, y debía seguir en el quinto verso.', v_otra_versos;
	end if;
end $$;

commit;
