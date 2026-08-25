-- La quintilla dice dónde cayó su quiebro
--
-- Paso 8c de B2, dos de siete. Toca 1 arquitectura de 5 versos.
--
-- La quintilla admite el quiebro desde el 22 de agosto de 2026, cuando se recogió el dato que no
-- estaba en ninguna ficha: Navarro Tomás escribe que «la quintilla con verso inicial quebrado fue la
-- estrofa más usada por Castillejo». Declararlo no bastaba: faltaba poder anotarlo.
--
-- **Lo que esta migración declara de la forma, y es lo único.** El esquema métrico gana su
-- repertorio: el octosílabo dominante y los dos quebrados que el IP abrió el 25 de agosto de 2026
-- —tetrasílabo **y pentasílabo**, porque lo que ninguna fuente fija no se acota, y porque el
-- *Diccionario* cuenta el pentasílabo como el mismo quebrado por sinafía y compensación—. Y
-- `medida_uniforme` pasa a `false`, que en un esquema con repertorio significa que la medida elegida
-- **no vale para todo el pasaje** sino verso a verso. Es lo que ya declara la copla real, que es la
-- única que preguntaba el quiebro desde antes.
--
-- **Lo que no cambia:** el rasgo `pie_quebrado` sigue con su modalidad y su nota; ninguna posición
-- del esquema se toca —la estrofa sigue siendo octosílaba—; y `posiciones_max` se queda vacío,
-- porque ninguna fuente da el número. El techo de registro se **deriva** de la unidad menos uno:
-- cualquier verso puede estarlo, pero no todos, o no sería una estrofa con quiebro sino otra medida.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_esquema uuid;
	v_octo uuid;
	v_tetra uuid;
	v_penta uuid;
	v_par text[];
	v_n integer;
	v_nota text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'quintilla' and activo;
	if v_forma is null then
		raise exception 'La forma «quintilla» no está activa.';
	end if;
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado' and activo;
	select metro_id into v_octo from public.metros where slug = 'octosilabo';
	select metro_id into v_tetra from public.metros where slug = 'tetrasilabo';
	select metro_id into v_penta from public.metros where slug = 'pentasilabo';
	if v_rasgo is null or v_octo is null or v_tetra is null or v_penta is null then
		raise exception 'Falta el rasgo del quiebro o alguno de los tres metros.';
	end if;

	foreach v_par slice 1 in array array[
		array['octosilabica_consonante', '5']
	] loop
		select arquitectura_id into v_arq
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_par[1] and activo;
		if v_arq is null then
			raise exception 'La arquitectura «%» de quintilla no está activa.', v_par[1];
		end if;

		-- Declara el quiebro, y no como definitorio: si lo fijara la norma iría en las posiciones
		-- del esquema y no habría nada que preguntar. Regla 4 del § 3.6.
		select count(*) into v_n
		from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo and modalidad <> 'definitoria';
		if v_n <> 1 then
			raise exception 'La arquitectura «%» no declara el quiebro como licencia (% filas).', v_par[1], v_n;
		end if;

		-- Ninguna fuente da el techo, así que no debe estar declarado. Si alguien lo declarase, esta
		-- migración derivaría uno distinto y se contradirían.
		select count(*) into v_n
		from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo and posiciones_max is not null;
		if v_n <> 0 then
			raise exception 'La arquitectura «%» declara un techo de quiebros que ninguna fuente da.', v_par[1];
		end if;

		select esquema_metrico_id into v_esquema
		from public.esquemas_metricos where arquitectura_id = v_arq;
		if v_esquema is null then
			raise exception 'La arquitectura «%» no tiene esquema métrico.', v_par[1];
		end if;

		-- El repertorio del esquema: el verso pleno y los dos quebrados.
		update public.esquemas_metricos set medida_uniforme = false where esquema_metrico_id = v_esquema;
		insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, rol, orden)
		values (v_esquema, v_octo, 'dominante', 1),
			(v_esquema, v_tetra, 'quebrado', 2),
			(v_esquema, v_penta, 'quebrado', 3)
		on conflict (esquema_metrico_id, metro_id) do update
			set rol = excluded.rol, orden = excluded.orden;

		-- La pregunta: qué versos se quebraron y con qué medida. El techo se deriva de la unidad
		-- menos uno, y va anotado como derivado en la ayuda.
		if not exists (
			select 1 from public.grupos_eleccion_metrica
			where arquitectura_id = v_arq and slug = 'posiciones_pie_quebrado' and activo
		) then
			insert into public.grupos_eleccion_metrica (
				arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
				permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
			)
			values (
				v_arq, 'posiciones_pie_quebrado', 'metro', 'unidad', 0, v_par[2]::integer - 1,
				true, true, 3, 'opciones', false,
				'El quiebro es una licencia, no la norma: marca los versos que veas acortados y su '
				|| 'medida, y deja la pregunta en blanco si no hay ninguno. Ninguna fuente dice '
				|| 'cuántos admite la forma, así que el máximo que ofrece la pantalla —'
				|| (v_par[2]::integer - 1)::text
				|| '— se deriva de que no pueden estarlo todos.'
			);
		end if;

		-- ------------------------------------------------------------------ Comprobaciones
		-- La pregunta sale con dos medidas por verso. Ejecutando la vista.
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.slug = 'posiciones_pie_quebrado' and g.activo and o.activo;
		if v_n <> v_par[2]::integer * 2 then
			raise exception 'La pregunta del quiebro en «%» ofrece % opciones, y debía ofrecer %.',
				v_par[1], v_n, v_par[2]::integer * 2;
		end if;

		-- Y las ofrece por posición, no como una medida para todo el pasaje.
		select count(*) into v_n
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		where g.arquitectura_id = v_arq and g.slug = 'posiciones_pie_quebrado' and g.activo
			and o.posicion_unidad is null;
		if v_n <> 0 then
			raise exception 'La pregunta del quiebro en «%» tiene % opciones sin verso.', v_par[1], v_n;
		end if;

		-- Las posiciones del esquema no se han tocado: la estrofa sigue midiendo lo que medía.
		select count(*) into v_n
		from public.esquema_metrico_posiciones p
		join public.metros m on m.metro_id = p.metro_id
		where p.esquema_metrico_id = v_esquema and m.slug <> 'octosilabo';
		if v_n <> 0 then
			raise exception 'El esquema de «%» ha dejado de ser octosílabo en % posiciones.', v_par[1], v_n;
		end if;
	end loop;

	-- ------------------------------------------- La nota, que afirmaba solo el tetrasílabo
	-- No se borra lo que dicen las fuentes: se separa de lo que el catálogo admite. La nota sigue
	-- diciendo que el quiebro documentado es tetrasílabo, y añade por qué se abre al pentasílabo.
	select nota into v_nota
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_forma and ar.rasgo_id = v_rasgo
	limit 1;
	if v_nota is null or v_nota not like '%tetrasílabo%' then
		raise exception 'La nota del quiebro de quintilla no es la que se esperaba: «%».', v_nota;
	end if;

	update public.arquitectura_rasgos ar
	set nota = 'La tradición documenta la quintilla con el primer verso quebrado como estrofa suelta, y no solo como mitad de una copla mayor: fue la más usada por Castillejo. El quiebro que documentan las fuentes es tetrasílabo, y la medida de la estrofa sigue siendo la suya. El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».'
	from public.arquitecturas_forma a
	where a.arquitectura_id = ar.arquitectura_id
		and a.forma_id = v_forma and ar.rasgo_id = v_rasgo;

	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_forma and ar.rasgo_id = v_rasgo and ar.nota like '%sinafía%';
	if v_n = 0 then
		raise exception 'La nota del quiebro de quintilla no recoge el pentasílabo.';
	end if;


	-- Y la ficha pública sigue respondiendo.
	if public.get_forma_metrica_publica('quintilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de quintilla ha dejado de responder.';
	end if;
end $$;

commit;
