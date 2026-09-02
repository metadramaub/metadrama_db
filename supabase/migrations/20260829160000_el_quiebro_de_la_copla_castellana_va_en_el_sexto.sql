-- El quiebro de la copla castellana va en el sexto verso
--
-- Preguntaba el quiebro en los ocho versos y admitía hasta siete, y las fuentes documentan uno, en
-- un sitio. La duda venía de su nota, que reunía dos cosas: «Se documenta en el sexto verso, y
-- también alternando versos plenos y quebrados en las dos semiestrofas». Al ir a las afirmaciones se
-- ve que son dos pasajes distintos y que hablan de cosas distintas.
--
--   * **Navarro Tomás § 65**, que trata la copla castellana: «Santillana la usa en las coplas sobre
--     el Condestable y, **con el sexto verso quebrado**, en el *Diálogo de Bías contra Fortuna* y en
--     los *Gozos de Nuestra Señora*». Un verso nombrado y dos obras.
--   * **Navarro Tomás § 5.4.7.4**, que explica de dónde sale un nombre: «cuando los octosílabos
--     alternan con versos de cuatro sílabas **se originan las coplas de pie quebrado**», y cita el
--     mismo *Diálogo de Bías*.
--
-- Las dos citan la misma obra, y § 65 dice cómo es: una copla castellana con el sexto verso
-- quebrado. La frase del § 5.4.7.4 no documenta una segunda realización de esta forma, sino el
-- origen del nombre «coplas de pie quebrado» —y eso el modelo ya lo resolvió el 20 de agosto de
-- 2026, cuando la copla de pie quebrado dejó de ser una forma porque «no es una estrofa: es una
-- propiedad de cualquier estrofa octosilábica». La alternancia es lo que afirma el rasgo, no una
-- posición de esta arquitectura.
--
-- Así que se cierra como las cinco anteriores: **el sexto verso**, y `posiciones_max` de nulo a
-- **1**, que es lo que dice la propia nota —«suele ser uno solo»—. La pregunta pasa de admitir siete
-- respuestas a admitir una. Un quiebro en otro verso, o una copla alternada, se leen como
-- desviación.
--
-- **La copla de arte menor no entra**, aunque su nota diga algo parecido: su fuente dice «admite
-- versos quebrados de cuatro sílabas» y **no nombra ningún verso**, así que preguntar en los ocho es
-- lo correcto. Lo de «alternando» de su nota viene del mismo § 5.4.7.4.
--
-- No se borra ninguna fila: las posiciones que faltan se añaden y la que ya había se respeta.

begin;

do $$
declare
	v_arquitectura uuid;
	v_esquema uuid;
	v_rasgo uuid;
	v_versos integer;
	v_octo uuid;
	v_tetra uuid;
	v_penta uuid;
	v_posicion integer;
begin
	select a.arquitectura_id, a.unidad_versos_max into v_arquitectura, v_versos
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla castellana' and a.nombre = 'Octosilábica';

	if v_arquitectura is null then
		raise exception 'No está la copla castellana octosilábica: revisa el catálogo antes de seguir.';
	end if;

	if v_versos <> 8 then
		raise exception 'La copla castellana mide % versos, y son 8.', v_versos;
	end if;

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';
	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos where arquitectura_id = v_arquitectura;

	if v_esquema is null then
		raise exception 'La copla castellana no tiene esquema métrico.';
	end if;

	select metro_id into v_octo from public.metros where silabas = 8 and tipo = 'simple' and activo;
	select metro_id into v_tetra from public.metros where silabas = 4 and tipo = 'simple' and activo;
	select metro_id into v_penta from public.metros where silabas = 5 and tipo = 'simple' and activo;

	if v_octo is null or v_tetra is null or v_penta is null then
		raise exception 'Faltan el octosílabo, el tetrasílabo o el pentasílabo en el catálogo de metros.';
	end if;

	-- ------------------------------------------------------------------ 1 · dónde cae
	for v_posicion in 1..v_versos loop
		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
		values (v_esquema, v_posicion, v_octo, false, 1)
		on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
	end loop;

	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
	values (v_esquema, 6, v_tetra, true, 2)
	on conflict (esquema_metrico_id, alternativa, posicion) do nothing;

	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
	values (v_esquema, 6, v_penta, true, 3)
	on conflict (esquema_metrico_id, alternativa, posicion) do nothing;

	update public.esquemas_metricos
	set medida_uniforme = null
	where esquema_metrico_id = v_esquema;

	-- ------------------------------------------------------------------ 2 · cuántos
	update public.arquitectura_rasgos
	set posiciones_max = 1
	where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo;

	update public.grupos_eleccion_metrica
	set selecciones_max = 1
	where arquitectura_id = v_arquitectura and dimension = 'metro';
end $$;

do $$
declare
	v_versos integer[];
	v_medidas integer;
	v_max integer;
	v_sel integer;
	v_menor integer[];
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la función**, leyendo la vista derivada, no la tabla que se acaba de escribir.
	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_versos
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla castellana' and g.dimension = 'metro';

	if v_versos is distinct from array[6] then
		raise exception 'La copla castellana ofrece el quiebro en %, y debía ofrecerlo solo en el sexto.', v_versos;
	end if;

	select count(distinct o.metro_id) into v_medidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla castellana' and g.dimension = 'metro';

	if v_medidas <> 3 then
		raise exception 'La copla castellana ofrece % medidas en el sexto verso, y debían ser 3.', v_medidas;
	end if;

	-- El máximo declarado y el de la pregunta dicen lo mismo: uno.
	select ar.posiciones_max into v_max
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'pie_quebrado' and f.nombre = 'Copla castellana';

	select g.selecciones_max into v_sel
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla castellana' and g.dimension = 'metro';

	if v_max <> 1 or v_sel <> 1 then
		raise exception 'La copla castellana declara % quiebros y admite % respuestas, y debían ser 1 y 1.', v_max, v_sel;
	end if;

	-- Y la copla de arte menor sigue preguntando en los ocho, que es lo que su fuente sostiene.
	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_menor
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla de arte menor' and g.dimension = 'metro';

	if v_menor is distinct from array[1, 2, 3, 4, 5, 6, 7, 8] then
		raise exception 'La copla de arte menor ofrece el quiebro en %, y debía seguir ofreciéndolo en los ocho.', v_menor;
	end if;
end $$;

commit;
