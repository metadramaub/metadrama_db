-- El quiebro admitido no cambia la medida
--
-- Al preguntar el IP si el pie quebrado se declararía en la quintilla «sin transformar la medida en
-- combinación de tal y quebrados», se comprobó que el catálogo tenía **tres aparatos distintos para
-- el mismo rasgo**, y que cuatro de ellos los había introducido yo en las formas creadas el 21 y el
-- 22 de agosto:
--
-- | Cómo se declaraba | Formas | Qué decía la ficha en MEDIDA |
-- | --- | --- | --- |
-- | Solo el rasgo | redondilla, novena | «Fijo · 8» |
-- | Rasgo + opciones métricas con rol | copla castellana, copla de arte menor, septilla, oncena | «Variable · verso a verso · 8 de base, con quebrados de 4» |
-- | Lo anterior + pregunta de posiciones | copla real | igual, y el editor marca qué versos se quiebran |
--
-- Las cuatro del medio anunciaban una **medida mixta por norma** donde el quiebro es solo admitido
-- o habitual. La redondilla, con el mismo rasgo y la misma modalidad, dice «8».
--
-- **La regla que se fija**, y que esta migración deja comprobada:
--
-- > **Quiebro definitorio** → va en las posiciones del esquema métrico, que dicen dónde cae.
-- > **Quiebro admitido o habitual** → va solo como rasgo; la medida sigue siendo la de la forma.
--
-- La copla real queda como única excepción, y no por la norma sino por el registro: su grupo
-- `posiciones_pie_quebrado` existe para que el editor diga en qué versos cayó el quiebro. Eso es un
-- caso del pendiente que revisa qué se pregunta y qué no en los rasgos, no una manera distinta de
-- declarar la norma.
--
-- **Y la quintilla lo admite ya.** Lo pedía Navarro Tomás en un pasaje que **no estaba recogido en
-- ninguna ficha del catálogo**: al resumir el período renacentista escribe que «**la quintilla con
-- verso inicial quebrado fue la estrofa más usada por Castillejo**». Hasta hoy el catálogo sostenía
-- lo contrario —que la tradición no describe la quintilla quebrada como estrofa suelta sino como
-- mitad de la copla real—, y esa nota se corrige. La afirmación entra donde le toca, con su
-- localizador.

begin;

do $$
declare
	v_quintilla uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_copla_real uuid;
	v_actual text;
	v_n integer;
	v_fila text[];

	c_nota_quintilla constant text :=
		'La tradición documenta la quintilla con el primer verso quebrado como estrofa suelta, y no '
		|| 'solo como mitad de una copla mayor: fue la más usada por Castillejo. El quiebro es '
		|| 'tetrasílabo y la medida de la estrofa sigue siendo la suya.';

	c_afirmacion constant text :=
		'Al resumir el período renacentista registra el uso suelto de la quintilla quebrada: '
		|| 'mientras decaen las coplas reales y castellanas y aumentan «las redondillas y quintillas '
		|| 'emancipadas», **«la quintilla con verso inicial quebrado fue la estrofa más usada por '
		|| 'Castillejo»**. En el mismo pasaje anota que el teatro dio preferencia a las estrofas '
		|| 'octosílabas enlazadas de seis y siete versos, que llevan esa misma quintilla dentro.';

	c_nota_copla_real constant text :=
		'Las dos quintillas se separan por una pausa estructural y conservan rimas independientes. '
		|| 'El pie quebrado de la quintilla no nace aquí —Navarro Tomás la documenta suelta y '
		|| 'quebrada, la más usada por Castillejo—, pero es en la copla real donde el catálogo '
		|| 'pregunta en qué versos cae.';
begin
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_copla_real from public.formas_metricas where slug = 'copla_real';
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_quintilla and slug = 'octosilabica_consonante' and activo;

	if v_arq is null or v_rasgo is null or v_copla_real is null then
		raise exception 'Falta la quintilla octosilábica, el rasgo del quiebro o la copla real.';
	end if;

	-- --------------------------------------------- 1. La quintilla admite el quiebro
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	select v_arq, v_rasgo, 'admitida', c_nota_quintilla
	where not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo
	);

	-- Su medida no cambia: la quintilla sigue siendo isosilábica.
	if exists (
		select 1 from public.esquema_metrico_opciones o
		join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
		where em.arquitectura_id = v_arq
	) then
		raise exception 'La quintilla ha ganado opciones métricas y debía quedarse isosilábica.';
	end if;

	-- El dato que lo sostiene, en su sitio.
	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	select v_navarro, v_quintilla, '§ 154, «Resumen» del período renacentista', c_afirmacion, 'alta'
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_quintilla and fuente_id = v_navarro
			and localizador like '§ 154%'
	);

	-- Y la nota de la copla real deja de decir lo contrario.
	update public.forma_relaciones set nota = c_nota_copla_real
	where forma_origen_id = v_copla_real and forma_destino_id = v_quintilla
		and tipo_relacion = 'compuesta_por';

	if exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_copla_real and forma_destino_id = v_quintilla
			and nota like '%no describe la quintilla quebrada como estrofa suelta%'
	) then
		raise exception 'La copla real sigue negando que la quintilla se quiebre suelta.';
	end if;

	-- ----------------------------- 2. Las cuatro que anunciaban medida mixta dejan de hacerlo
	foreach v_fila slice 1 in array array[
		array['copla_castellana'], array['copla_de_arte_menor'], array['septilla'], array['oncena']
	] loop
		delete from public.esquema_metrico_opciones o
		using public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
		where o.esquema_metrico_id = em.esquema_metrico_id
			and a.arquitectura_id = em.arquitectura_id
			and f.forma_id = a.forma_id
			and f.slug = v_fila[1];

		update public.esquemas_metricos em set medida_uniforme = null
		from public.arquitecturas_forma a, public.formas_metricas f
		where a.arquitectura_id = em.arquitectura_id
			and f.forma_id = a.forma_id
			and f.slug = v_fila[1];
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	-- La regla, comprobada sobre el catálogo entero: ninguna forma con el quiebro admitido o
	-- habitual declara opciones métricas de quebrado, salvo la copla real, que pregunta posiciones.
	select string_agg(distinct f.slug, ', ' order by f.slug) into v_actual
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join public.esquema_metrico_opciones o on o.esquema_metrico_id = em.esquema_metrico_id
	where rm.slug = 'pie_quebrado' and ar.modalidad in ('admitida', 'habitual')
		and a.activo and f.activo and o.rol = 'quebrado';
	if v_actual is distinct from 'copla_real' then
		raise exception 'Declaran quebrado en la medida sin ser definitorio: %', coalesce(v_actual, 'ninguna');
	end if;

	-- Y las que lo tienen definitorio siguen diciendo dónde cae, en sus posiciones métricas.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'pie_quebrado' and ar.modalidad = 'definitoria' and a.activo and f.activo
		and exists (
			select 1 from public.esquema_metrico_posiciones p
			join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id
			join public.metros m on m.metro_id = p.metro_id
			where em.arquitectura_id = a.arquitectura_id and m.silabas < 8
		);
	-- Son cinco: la sextilla de pie quebrado, la copla manriqueña y las tres enlazadas.
	if v_n <> 5 then
		raise exception 'Solo % de las formas con quiebro definitorio dice dónde cae.', v_n;
	end if;

	-- La quintilla lo admite y sigue midiendo lo suyo.
	if not exists (
		select 1 from public.arquitectura_rasgos
		where arquitectura_id = v_arq and rasgo_id = v_rasgo and modalidad = 'admitida'
	) then
		raise exception 'La quintilla no ha quedado admitiendo el pie quebrado.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_quintilla;
	if v_n <> 6 then
		raise exception 'La quintilla cita % fuentes distintas, no las seis.', v_n;
	end if;

	foreach v_fila slice 1 in array array[
		array['quintilla'], array['copla_castellana'], array['copla_de_arte_menor'],
		array['septilla'], array['oncena'], array['copla_real']
	] loop
		if public.get_forma_metrica_publica(v_fila[1]) -> 'formas' = '[]'::jsonb then
			raise exception 'La ficha de % ha dejado de responder.', v_fila[1];
		end if;
	end loop;
end $$;

commit;
