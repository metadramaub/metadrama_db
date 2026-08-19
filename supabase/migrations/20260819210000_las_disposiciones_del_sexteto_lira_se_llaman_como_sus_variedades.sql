-- Las disposiciones del sexteto-lira se llaman como sus variedades
--
-- Sus siete variedades se nombran con dos ejes: la **letra** es la disposición de rima y el
-- **número**, la variante de medida dentro de ella. Se comprueba sin excepción —A1, A2 y A3 usan
-- `ababcc`; B1 y B2, `abbacc`; C1 y C2, `aabbcc`—, pero las disposiciones se llamaban `R1`, `R2`
-- y `R3`, de modo que el mismo eje tenía **dos alfabetos** y ninguno remitía al otro: había que
-- descubrir que la A de «A1» es la R1.
--
-- Se renombran a `A`, `B` y `C`. Ahora el rótulo de la fila dice «A · habitual» y la variedad que
-- la usa se llama «A1», y se sigue viendo de un vistazo qué variedades comparten disposición, que
-- es para lo que servía el código.
--
-- **Se renombra en sitio, no se recrea nada**: seis anotaciones de prueba apuntan ya a estas
-- variedades y el catálogo se niega a borrar lo que una anotación use. Ninguna afirmación ni
-- denominación menciona los nombres viejos, y son los únicos esquemas del catálogo con nombre de
-- ese tipo.

begin;

do $$
declare
	v_arq uuid;
	fila record;
	v_actual text;
	v_pares integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa sexteto_lira/heterometrica_consonante.';
	end if;

	-- La correspondencia que justifica el renombrado: cada variedad usa la disposición cuya
	-- inicial lleva en el nombre. Si dejara de cumplirse, renombrar mentiría.
	select count(*) into v_pares
	from public.variedades_arquitectura v
	join public.esquemas_rima er on er.esquema_rima_id = v.esquema_rima_id
	where v.arquitectura_id = v_arq
		and v.activo
		and left(v.nombre, 1) = case er.notacion
			when 'ababcc' then 'A'
			when 'abbacc' then 'B'
			when 'aabbcc' then 'C'
		end;

	if v_pares <> 7 then
		raise exception 'Solo % de las siete variedades empiezan por la letra de su disposición.', v_pares;
	end if;

	for fila in
		select *
		from (values
			('ababcc', 'R1', 'A'),
			('abbacc', 'R2', 'B'),
			('aabbcc', 'R3', 'C')
		) as t(slug, viejo, nuevo)
	loop
		select nombre into v_actual
		from public.esquemas_rima
		where arquitectura_id = v_arq and slug = fila.slug;

		if not found then
			raise exception 'No existe el esquema «%» del sexteto-lira.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'El nombre del esquema «%» no es el esperado. Dice: %', fila.slug, v_actual;
		end if;

		update public.esquemas_rima
		set nombre = fila.nuevo
		where arquitectura_id = v_arq and slug = fila.slug;
	end loop;

	-- Y que no quede ninguno con el nombre viejo, aquí ni en ninguna otra forma.
	if exists (select 1 from public.esquemas_rima where nombre ~ '^R[0-9]+$') then
		raise exception 'Quedan esquemas de rima con nombre del tipo «Rn».';
	end if;

	-- Las seis anotaciones siguen apuntando a sus variedades: no se ha recreado nada.
	if (
		select count(*) from public.elecciones_editor_metrico e
		join public.variedades_arquitectura v on v.variedad_id = e.variedad_id
		where v.arquitectura_id = v_arq
	) <> 6 then
		raise exception 'Las anotaciones que usan estas variedades han cambiado de número.';
	end if;
end $$;

commit;
