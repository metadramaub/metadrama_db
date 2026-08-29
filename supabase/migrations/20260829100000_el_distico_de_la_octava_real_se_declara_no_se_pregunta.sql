-- El dístico de la octava real se declara, no se pregunta
--
-- La arquitectura preguntaba al editor si veía el pareado final, y la respuesta **ya estaba dada
-- por los dos caminos posibles**:
--
--   1. Si elige el esquema catalogado, `ABABABCC` termina en `CC`.
--   2. Si escribe el esquema a mano —la arquitectura declara «Distribución variable» como salida
--      abierta—, la notación que escribe lo enseña igual: `ABBAABCC`.
--
-- No hay un tercer camino: la arquitectura tiene esos dos esquemas y ninguno más. Así que la
-- pregunta pedía leer otra vez algo que la propia respuesta de rima ya dice.
--
-- **Lo que se retira es la pregunta, no la declaración.** El dístico sigue siendo un rasgo de la
-- forma y hay que poder consultarlo: `arquitectura_rasgos` conserva su fila —valor «Presente»,
-- modalidad `habitual`—, que es de donde salen el recuadro de la norma del editor y la ficha
-- pública. `architectureTraitFacts` recorre esa tabla y solo descarta los `admitida` sin límite de
-- posiciones; un `habitual` sube siempre. Quien quiera saber cómo es generalmente una octava real
-- lo sigue leyendo.
--
-- **No se toca el endecasílabo suelto**, la otra arquitectura que declara este rasgo. Allí la
-- pregunta trabaja: es una serie sin esquema de rima, así que no hay notación de la que deducir el
-- pareado y preguntarlo es la única manera de registrarlo.

begin;

do $$
declare
	v_grupo uuid;
	v_declaracion uuid;
	v_respuestas integer;
	v_equivalencias integer;
	v_esquemas integer;
begin
	-- ------------------------------------------------------------------ Antes de borrar
	--
	-- La declaración tiene que estar en pie: si no estuviera, retirar la pregunta dejaría la forma
	-- sin decir en ninguna parte que lleva dístico, que es justo lo contrario de lo acordado.
	select ar.arquitectura_id into v_declaracion
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final'
		and f.nombre = 'Octava real'
		and a.nombre = 'Endecasilábica consonante'
		and ar.modalidad = 'habitual';

	if v_declaracion is null then
		raise exception 'La octava real no declara el dístico final como habitual: sin esa fila, quitar la pregunta borraría el dato.';
	end if;

	-- Y los dos caminos de los que se deduce siguen existiendo.
	select count(*) into v_esquemas
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Octava real';

	if v_esquemas <> 2 then
		raise exception 'La octava real tiene % esquemas de rima, no los 2 sobre los que se decidió esto.', v_esquemas;
	end if;

	select g.grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final'
		and f.nombre = 'Octava real'
		and a.nombre = 'Endecasilábica consonante';

	-- Idempotente: si ya se aplicó, no hay pregunta que quitar.
	if v_grupo is null then
		raise notice 'La octava real ya no pregunta el dístico final.';
		return;
	end if;

	-- Nada puede quedar huérfano. La clave de `anotacion_elecciones` es `restrict`, así que un
	-- borrado con respuestas fallaría; se comprueba aquí para decir por qué en vez de morir en la
	-- clave. Las equivalencias con el vocabulario legado sí caen en cascada, y por eso se miran.
	select count(*) into v_respuestas
	from public.anotacion_elecciones where grupo_eleccion_id = v_grupo;

	if v_respuestas > 0 then
		raise exception 'Hay % respuestas guardadas al dístico de la octava real: no se retira la pregunta sin decidir qué se hace con ellas.', v_respuestas;
	end if;

	select count(*) into v_equivalencias
	from public.equivalencias_respuestas_legadas where grupo_eleccion_id = v_grupo;

	if v_equivalencias > 0 then
		raise exception 'Hay % equivalencias legadas apuntando al dístico de la octava real, y caerían en cascada.', v_equivalencias;
	end if;

	delete from public.grupos_eleccion_metrica where grupo_eleccion_id = v_grupo;
end $$;

do $$
declare
	v_preguntas integer;
	v_declaracion text;
	v_suelto integer;
	v_rima integer;
	v_opciones integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee lo que ha quedado**, y se ejecuta lo que se toca: la vista de opciones es una
	-- función, y una función no está probada hasta que corre.
	select count(*) into v_preguntas
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final' and f.nombre = 'Octava real';

	if v_preguntas <> 0 then
		raise exception 'La octava real sigue preguntando el dístico final.';
	end if;

	-- La declaración, intacta: es lo que sostiene la norma y la ficha.
	select ar.modalidad into v_declaracion
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final' and f.nombre = 'Octava real';

	if v_declaracion is distinct from 'habitual' then
		raise exception 'La octava real ya no declara el dístico como habitual, sino %.', coalesce(v_declaracion, 'nada');
	end if;

	-- El endecasílabo suelto conserva la suya, que allí es la única manera de registrarlo.
	select count(*) into v_suelto
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final' and f.nombre = 'Endecasílabo suelto' and g.activo;

	if v_suelto <> 1 then
		raise exception 'El endecasílabo suelto tiene % preguntas de dístico final, y debía conservar 1.', v_suelto;
	end if;

	-- Y la octava real sigue preguntando lo que sí hay que preguntarle: su esquema de rima, con la
	-- opción catalogada que ofrece. Se lee de la vista derivada, que ejecuta la función.
	select count(*) into v_rima
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Octava real' and g.dimension = 'rima' and g.activo;

	select count(*) into v_opciones
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Octava real';

	if v_rima <> 1 or v_opciones < 1 then
		raise exception 'La octava real ha quedado con % preguntas de rima y % opciones derivadas.', v_rima, v_opciones;
	end if;
end $$;

commit;
