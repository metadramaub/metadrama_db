-- La sextilla de pie quebrado tiene tres disposiciones, no una
--
-- Ofrecía solo `abcabc`, y las fuentes nombran tres. El *Diccionario de métrica española*, en sus
-- entradas de la sextilla: «la sextilla de pie quebrado la describe como copla de pie quebrado en
-- dos semiestrofas de tres versos, **con disposiciones `aabaab`, `aabccb` o `abcabc`**». Y Navarro
-- Tomás lo confirma desde el otro lado: las coplas de pie quebrado son «sextillas simétricas cuyos
-- versos tercero y sexto son menores, con **disposición más usual `abc:abc`**», y advierte que «el
-- orden de las rimas varía de una composición a otra».
--
-- Así que `abcabc` se queda **habitual**, que es lo que la fuente dice —la más usual—, y entran
-- `aabaab` y `aabccb` como **admitidas**. Con eso la pregunta pasa de ofrecer una disposición a
-- ofrecer tres, que es lo que la hace tener sentido.
--
-- **No entra `ababab`**, la cuarta que tiene la sextilla octosilábica: las fuentes la documentan
-- para la sextilla de octosílabos plenos —la alterna del repertorio juglaresco y del *Libro de Buen
-- Amor*— y no para el pie quebrado. Copiar las cuatro habría sido pasarse.
--
-- Las dos nuevas son consonantes, como la que ya había. **Sus posiciones no se escriben**: las
-- materializa `esquemas_rima_sincronizar_posiciones_fijas` desde la notación, y la comprobación de
-- abajo las cuenta, que es la manera de saber que el disparador corrió. Los quiebros no se tocan:
-- siguen declarados en el tercer verso y el sexto.

begin;

do $$
declare
	v_arquitectura uuid;
	v_tipo_rima uuid;
	v_esquema uuid;
	v_caso record;
begin
	select a.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'De pie quebrado';

	if v_arquitectura is null then
		raise exception 'No está la sextilla de pie quebrado: revisa el catálogo antes de seguir.';
	end if;

	-- El régimen se toma de la disposición que ya tiene, para no inventarlo.
	select er.tipo_rima_id into v_tipo_rima
	from public.esquemas_rima er
	where er.arquitectura_id = v_arquitectura and er.notacion = 'abcabc';

	if v_tipo_rima is null then
		raise exception 'La sextilla de pie quebrado no declara abcabc, que es de donde se toma el régimen.';
	end if;

	for v_caso in
		select * from (values ('aabaab'), ('aabccb')) as t(notacion)
	loop
		select er.esquema_rima_id into v_esquema
		from public.esquemas_rima er
		where er.arquitectura_id = v_arquitectura and er.notacion = v_caso.notacion;

		if v_esquema is not null then
			raise notice 'La sextilla de pie quebrado ya declara %.', v_caso.notacion;
			continue;
		end if;

		insert into public.esquemas_rima
			(arquitectura_id, slug, notacion, modalidad, tipo_secuencia, tipo_rima_id)
		values
			(v_arquitectura, v_caso.notacion, v_caso.notacion, 'admitida', 'secuencia', v_tipo_rima)
		returning esquema_rima_id into v_esquema;
	end loop;
end $$;

do $$
declare
	v_notaciones text[];
	v_habitual text;
	v_ofrecidas integer;
	v_posiciones integer;
	v_octo integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la función que deriva las opciones**, leyendo la vista: una disposición que se
	-- declara pero no se ofrece no serviría de nada.
	select array_agg(er.notacion order by er.notacion) into v_notaciones
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'De pie quebrado' and er.notacion is not null;

	if v_notaciones is distinct from array['aabaab', 'aabccb', 'abcabc'] then
		raise exception 'La sextilla de pie quebrado declara %, y debía declarar las tres del Diccionario.', v_notaciones;
	end if;

	select er.notacion into v_habitual
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'De pie quebrado' and er.modalidad = 'habitual';

	if v_habitual is distinct from 'abcabc' then
		raise exception 'La más usual de la sextilla de pie quebrado es «%», y debía ser abcabc.', coalesce(v_habitual, 'ninguna');
	end if;

	select count(*) into v_ofrecidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'De pie quebrado' and g.dimension = 'rima';

	if v_ofrecidas <> 3 then
		raise exception 'La sextilla de pie quebrado ofrece % disposiciones, y debía ofrecer 3.', v_ofrecidas;
	end if;

	-- Las dos nuevas se dibujan verso a verso: sin posiciones, la rejilla no las pinta.
	select count(*) into v_posiciones
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'De pie quebrado' and er.notacion in ('aabaab', 'aabccb');

	if v_posiciones <> 12 then
		raise exception 'Las dos disposiciones nuevas tienen % posiciones, y debían tener 12.', v_posiciones;
	end if;

	-- Y la sextilla octosilábica conserva sus cuatro: no se le ha quitado ni añadido nada.
	select count(*) into v_octo
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Sextilla' and a.nombre = 'Octosilábica' and er.notacion is not null;

	if v_octo <> 4 then
		raise exception 'La sextilla octosilábica declara % disposiciones, y debía conservar 4.', v_octo;
	end if;
end $$;

commit;
