-- El slug de la seguidilla gitana no finge seis versos.
--
-- Su esquema métrico se llamaba `6-6-10-11-12-6`, que se lee como una secuencia de **seis**
-- posiciones cuando la gitana tiene **cuatro**: el tercer verso admite diez, once o doce sílabas,
-- y esas tres son alternativas de una misma posición, no tres posiciones seguidas. El `nombre` ya
-- lo decía bien —`6-6-(10/11/12)-6`— y la rejilla lo dibuja bien desde que agrupa por
-- `alternativa`; el que engañaba era el slug.
--
-- Pasa a `6-6-10u11u12-6`, que se lee «seis, seis, diez u once o doce, seis» y conserva la
-- convención de guiones de los demás esquemas métricos —`7-5-7-5`, `8-8-4-8-8-4`—.
--
-- Renombrar es seguro: lo que se guarda de una elección apunta al identificador del esquema, no a
-- su slug, y las opciones del editor se derivan en ejecución.

do $$
declare
	tocadas integer;
begin
	update public.esquemas_metricos em
	set slug = '6-6-10u11u12-6', updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'gitana' and em.slug = '6-6-10-11-12-6';

	get diagnostics tocadas = row_count;
	if tocadas <> 1 then
		raise exception 'se esperaba renombrar un esquema y se renombraron %', tocadas;
	end if;
end;
$$;

-- La guarda comprueba lo que el slug decía mal: que las posiciones son cuatro y no seis, y que la
-- tercera es la que lleva las tres alternativas.
do $$
declare
	posiciones integer;
	alternativas integer;
begin
	select count(distinct p.posicion), max(cuenta)
	into posiciones, alternativas
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	join lateral (
		select count(*) cuenta
		from public.esquema_metrico_posiciones x
		where x.esquema_metrico_id = p.esquema_metrico_id and x.posicion = p.posicion
	) c on true
	where f.slug = 'seguidilla' and a.slug = 'gitana' and em.slug = '6-6-10u11u12-6';

	if posiciones <> 4 then
		raise exception 'la seguidilla gitana tiene % posiciones y su slug supone cuatro', posiciones;
	end if;
	if alternativas <> 3 then
		raise exception 'se esperaban tres alternativas en la posición tercera y hay %', alternativas;
	end if;
end;
$$;
