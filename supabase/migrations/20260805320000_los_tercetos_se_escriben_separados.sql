-- Los tercetos del soneto se escriben separados, como los cuartetos.
--
-- La ficha enseña ahora la rima de los cuartetos y la de los tercetos juntas, bajo su parte,
-- y al verlas en la misma columna se nota que no se escriben igual: los cuartetos dicen
-- «ABBA ABBA» y los tercetos `CDEDCE` de corrido. Son dos tercetos, y así se lee mal —invita
-- a contarlos como un bloque de seis, que es justamente lo que el catálogo no quiere decir—.
--
-- Se separan con el espacio que ya usa la prosa de sus descripciones, que llevan tiempo
-- diciendo «CDE y DCE». La notación es una etiqueta y no se parsea en ningún sitio: se
-- comprobó al alinear `abba|acca` en la redondilla.
--
-- No se usa `|` ni `:` porque no son bloques ni una pausa dentro de un bloque: son dos
-- unidades de tres versos, y la separación es la misma que ya hacen los cuartetos con un
-- espacio.

begin;

do $$
declare
	v_arq uuid;
	v_mal integer;
begin
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = (select forma_id from public.formas_metricas where slug = 'soneto');

	if v_arq is null then
		raise exception 'Falta la arquitectura del soneto';
	end if;

	update public.esquemas_rima
	set notacion = left(notacion, 3) || ' ' || right(notacion, 3)
	where arquitectura_id = v_arq
		and notacion ~ '^[A-Z]{6}$';

	-- Y las opciones que el editor ve, para que digan lo mismo que la ficha.
	update public.opciones_eleccion_metrica o
	set nombre = regexp_replace(o.nombre, '^([A-Z]{3})([A-Z]{3})', '\1 \2')
	from public.grupos_eleccion_metrica g
	where g.grupo_eleccion_id = o.grupo_eleccion_id
		and g.arquitectura_id = v_arq
		and o.nombre ~ '^[A-Z]{6}';

	select count(*) into v_mal
	from public.esquemas_rima
	where arquitectura_id = v_arq and notacion ~ '^[A-Z]{6}$';

	if v_mal > 0 then
		raise exception 'Quedan % esquemas del soneto escritos de corrido', v_mal;
	end if;

	raise notice 'Tercetos del soneto separados: CDC DCD, CDE CDE, CDE DCE, CDC EDE';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
