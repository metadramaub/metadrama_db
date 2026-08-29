-- Los quiebros de la oncena, también en el orden al revés
--
-- La oncena en orden 6-5 quedó fuera de la declaración del 29 de agosto por un reparo que no valía.
-- Se objetó que la afirmación de fuente para ese orden recoge `ababba:babba` y `abaaab:cdccd` **sin
-- quebrados**, y eso no dice nada: **un esquema de rima no declara medidas**. De una notación de
-- rima no se puede concluir que los versos fueran plenos.
--
-- Y la misma fuente afirma lo contrario en general: «la estrofa de once con quebrados fue más
-- corriente que la de octosílabos plenos».
--
-- Lo que sitúa los quiebros es la estructura, no la notación: son **los que cierran cada terceto de
-- la sextilla**. En el orden 5-6 la sextilla va detrás y caen en el octavo y el undécimo, que ya se
-- declararon; en el orden 6-5 va delante, así que caen en el **tercero y el sexto**. Es la misma
-- sextilla de pie quebrado colocada en otro sitio.
--
-- Se declaran igual que las cuatro anteriores: los once versos, con el octosílabo en los plenos y
-- las dos medidas del quiebro en el tercero y el sexto. El rasgo sigue `habitual` con su
-- `posiciones_max`, y el octosílabo en la posición declarada es la respuesta de que ahí no hay
-- quiebro. No se borra ninguna fila.

begin;

do $$
declare
	v_esquema uuid;
	v_versos integer;
	v_octo uuid;
	v_tetra uuid;
	v_penta uuid;
	v_posicion integer;
begin
	select metro_id into v_octo from public.metros where silabas = 8 and tipo = 'simple' and activo;
	select metro_id into v_tetra from public.metros where silabas = 4 and tipo = 'simple' and activo;
	select metro_id into v_penta from public.metros where silabas = 5 and tipo = 'simple' and activo;

	if v_octo is null or v_tetra is null or v_penta is null then
		raise exception 'Faltan el octosílabo, el tetrasílabo o el pentasílabo en el catálogo de metros.';
	end if;

	select em.esquema_metrico_id, a.unidad_versos_max into v_esquema, v_versos
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Oncena' and a.nombre = 'Sextilla + quintilla';

	if v_esquema is null then
		raise exception 'No está el esquema métrico de la oncena en orden 6-5.';
	end if;

	if v_versos <> 11 then
		raise exception 'La oncena en orden 6-5 mide % versos, y son 11.', v_versos;
	end if;

	for v_posicion in 1..v_versos loop
		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
		values (v_esquema, v_posicion, v_octo, false, 1)
		on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
	end loop;

	foreach v_posicion in array array[3, 6] loop
		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
		values (v_esquema, v_posicion, v_tetra, true, 2)
		on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
		values (v_esquema, v_posicion, v_penta, true, 3)
		on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
	end loop;

	update public.esquemas_metricos
	set medida_uniforme = null
	where esquema_metrico_id = v_esquema;
end $$;

do $$
declare
	v_ofrecidas integer[];
	v_medidas integer;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la función**, leyendo la vista derivada.
	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_ofrecidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Oncena' and a.nombre = 'Sextilla + quintilla' and g.dimension = 'metro';

	if v_ofrecidas is distinct from array[3, 6] then
		raise exception 'La oncena en orden 6-5 ofrece el quiebro en %, y debía ofrecerlo en el 3 y el 6.', v_ofrecidas;
	end if;

	select count(distinct o.metro_id) into v_medidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Oncena' and a.nombre = 'Sextilla + quintilla' and g.dimension = 'metro'
		and o.posicion_unidad = 3;

	if v_medidas <> 3 then
		raise exception 'La oncena en orden 6-5 ofrece % medidas en el tercer verso, y debían ser 3.', v_medidas;
	end if;

	-- El otro orden sigue como se declaró ayer: no se ha tocado de refilón.
	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_ofrecidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Oncena' and a.nombre = 'Quintilla + sextilla' and g.dimension = 'metro';

	if v_ofrecidas is distinct from array[8, 11] then
		raise exception 'La oncena en orden 5-6 ofrece el quiebro en %, y debía seguir en el 8 y el 11.', v_ofrecidas;
	end if;
end $$;

commit;
