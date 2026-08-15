-- La arromanzada es una estrofa que encadena, no una serie
--
-- Corrige la arquitectura creada en `20260815090000`. Se le dejó la unidad abierta copiando al
-- romance, y el auditor lo cazó con **D4**: una arquitectura sin unidad declarada necesita
-- secciones de las que derivarla, y solo se exceptúan las formas de nivel `serie`. El romance lo
-- es; la seguidilla es `estrofa`, así que la excepción no la alcanza.
--
-- Y la regla tiene razón. La unidad de la arromanzada son los cuatro versos de la seguidilla
-- simple, como en las demás arquitecturas de la forma; lo que la convierte en serie no es una
-- extensión abierta sino que el ciclo vuelva con la misma asonancia, que ya lo dicen la notación
-- `[-a-a]…` y los dos enlaces con desplazamiento. Cuántas estrofas contiene el pasaje no se
-- declara: se deriva, como en todo el catálogo.
--
-- Efecto en la ficha: la extensión pasa de «serie abierta» a «4 versos», la rejilla dibuja las
-- cuatro columnas 7·5·7·5 sobre `– a – a` y debajo siguen leyéndose las dos frases derivadas de
-- los enlaces —el verso 2 y el verso 4 conservan su rima en cada repetición—, que es justo lo
-- que separa esta arquitectura de la simple.

do $$
declare
	v_arquitectura uuid;
	n integer;
begin
	select a.arquitectura_id into v_arquitectura
	from arquitecturas_forma a
	join formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'seguidilla' and a.slug = 'simple_arromanzada';

	if v_arquitectura is null then
		raise exception 'No existe la arquitectura «seguidilla/simple_arromanzada».';
	end if;

	update arquitecturas_forma set
		unidad_versos_min = 4,
		unidad_versos_max = 4,
		updated_at = now()
	where arquitectura_id = v_arquitectura
		and (
			(unidad_versos_min is null and unidad_versos_max is null)
			or (unidad_versos_min = 4 and unidad_versos_max = 4)
		);
	get diagnostics n = row_count;
	if n <> 1 then
		raise exception 'La unidad de la arromanzada no tenía el valor esperado (filas afectadas: %).', n;
	end if;

	-- Lo que sostiene la lectura de serie tiene que seguir en pie: el ciclo en la notación y los
	-- dos enlaces que lo encadenan. Sin ellos la arromanzada sería la simple repetida.
	select count(*) into n
	from esquemas_rima er
	join esquema_rima_enlaces l on l.esquema_rima_id = er.esquema_rima_id
	where er.arquitectura_id = v_arquitectura
		and er.notacion = '[-a-a]…'
		and l.desplazamiento_bloque = 1;
	if n <> 2 then
		raise exception 'La arromanzada debe conservar su ciclo y sus 2 enlaces encadenados, y tiene %.', n;
	end if;
end;
$$;
