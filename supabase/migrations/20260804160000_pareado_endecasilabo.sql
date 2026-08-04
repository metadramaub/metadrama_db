-- El pareado endecasílabo es una estrofa de dos versos, no el extremo de una serie.
--
-- Morley y Bruerton usan «pareados de 11» para el extremo del continuo endecasilábico: una
-- tirada larga en la que casi todos los versos riman. Pero la única secuencia del corpus
-- anotada como `pareado_endecasilabo` mide **dos versos** y está aislada entre dos romances
-- octosílabos (El conde de Sex, vv. 1887-1888, entre un romance e-a y uno e-e). No es una
-- tirada: es un dístico, probablemente cerrando escena.
--
-- Le corresponde por tanto la forma Pareado, que el catálogo define a propósito más ancha
-- que M&B —«estrofa de dos versos, de igual o diferente medida»— porque ellos clasifican
-- pasajes para estadística y aquí se describen estrofas.
--
-- El vocabulario viejo tenía dos raíces para la misma estrofa, `pareado_de_arte_menor` y
-- `pareado_endecasilabo`, separadas solo por la medida. La medida es hoy una respuesta.

begin;

do $$
declare
	v_forma uuid;
	v_termino uuid;
	v_grupo_rima uuid;
	v_grupo_medida uuid;
	v_consonante uuid;
	v_once_1 uuid;
	v_once_2 uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';
	select termino_id into v_termino from public.vocabularios
	where categoria = 'estrofa_tipo' and termino = 'pareado_endecasilabo';

	if v_forma is null or v_termino is null then
		raise exception 'Falta la forma Pareado o el término pareado_endecasilabo';
	end if;

	-- La forma no reclamaba ningún término legado. Reclama esta raíz, que no tiene padre del
	-- que heredar; `pareado_de_arte_menor` sigue reclamando la arquitectura y por él resuelven
	-- sus dos hijos.
	update public.formas_metricas
	set origen_termino_id = v_termino
	where forma_id = v_forma and origen_termino_id is null;

	select g.grupo_eleccion_id into v_grupo_rima
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where a.forma_id = v_forma and g.activo and g.nombre ilike '%consonante o en asonante%';

	select g.grupo_eleccion_id into v_grupo_medida
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where a.forma_id = v_forma and g.activo and g.nombre ilike '%miden los dos versos%';

	if v_grupo_rima is null or v_grupo_medida is null then
		raise exception 'No se encontraron las preguntas del pareado';
	end if;

	select opcion_eleccion_id into v_consonante from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_rima and nombre = 'Consonante';
	select opcion_eleccion_id into v_once_1 from public.opciones_eleccion_metrica o
	join public.metros m on m.metro_id = o.metro_id
	where o.grupo_eleccion_id = v_grupo_medida and o.posicion_unidad = 1 and m.silabas = 11;
	select opcion_eleccion_id into v_once_2 from public.opciones_eleccion_metrica o
	join public.metros m on m.metro_id = o.metro_id
	where o.grupo_eleccion_id = v_grupo_medida and o.posicion_unidad = 2 and m.silabas = 11;

	if v_consonante is null or v_once_1 is null or v_once_2 is null then
		raise exception 'No se encontraron las opciones de consonante o de endecasílabo';
	end if;

	insert into public.equivalencias_respuestas_legadas
		(termino_id, grupo_eleccion_id, opcion_eleccion_id, nota)
	values
		(v_termino, v_grupo_rima, v_consonante,
			'Un pareado endecasílabo rima siempre en consonante: es lo que lo constituye.'),
		(v_termino, v_grupo_medida, v_once_1,
			'El término declara la medida: los dos versos son endecasílabos.'),
		(v_termino, v_grupo_medida, v_once_2,
			'El término declara la medida: los dos versos son endecasílabos.')
	on conflict do nothing;

	raise notice 'Pareado endecasílabo resuelto: forma Pareado con medida 11 + 11 y rima consonante.';
end $$;

commit;
