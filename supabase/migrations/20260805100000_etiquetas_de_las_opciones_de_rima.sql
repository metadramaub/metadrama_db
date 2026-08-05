-- Las opciones de esquema de rima se llaman como el esquema que eligen.
--
-- Seis de las ocho opciones de la quintilla estaban etiquetadas con nombres de redondilla:
-- «Redondilla cruzada · abab (cuarteta)» nombraba a la vez las tipologías 1, 4 y 7, y
-- «Redondilla abrazada · abba» a la 2, la 5 y la 6. El `esquema_rima_id` al que apuntan
-- siempre fue el correcto, así que nada de lo guardado está mal; lo que era imposible es
-- elegir a sabiendas, porque el editor veía tres opciones idénticas.
--
-- Pasa en los cinco sitios donde se elige un esquema de quintilla: la propia quintilla, las
-- dos quintillas de la copla real y las dos arquitecturas de la novena.
--
-- La etiqueta se deriva del esquema en vez de escribirse a mano, que es lo que permitió que
-- divergieran. Solo se tocan los grupos donde una etiqueta nombraba más de un esquema: los
-- que ya estaban bien —los del soneto, por ejemplo— se quedan como están.

begin;

do $$
declare
	v_afectadas integer;
	v_restantes integer;
begin
	with grupos_con_etiqueta_ambigua as (
		select grupo_eleccion_id
		from public.opciones_eleccion_metrica
		where esquema_rima_id is not null
		group by grupo_eleccion_id, nombre
		having count(distinct esquema_rima_id) > 1
	)
	update public.opciones_eleccion_metrica o
	set nombre = er.nombre || coalesce(' · ' || er.notacion, '')
	from public.esquemas_rima er
	where er.esquema_rima_id = o.esquema_rima_id
		and o.grupo_eleccion_id in (select grupo_eleccion_id from grupos_con_etiqueta_ambigua)
		and o.nombre is distinct from er.nombre || coalesce(' · ' || er.notacion, '');

	get diagnostics v_afectadas = row_count;

	-- Nada debe quedar con una etiqueta que nombre dos esquemas distintos.
	select count(*) into v_restantes
	from (
		select grupo_eleccion_id
		from public.opciones_eleccion_metrica
		where esquema_rima_id is not null
		group by grupo_eleccion_id, nombre
		having count(distinct esquema_rima_id) > 1
	) pendientes;

	if v_restantes > 0 then
		raise exception 'Siguen quedando % etiquetas que nombran más de un esquema', v_restantes;
	end if;

	raise notice 'Etiquetas corregidas: %', v_afectadas;
end $$;

-- El catálogo cambió: el demarcador compilado queda desactualizado.
update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
