-- Toda pregunta de rima admite declarar otra
--
-- Paso 7a de B1, y el único cambio mecánico de todo el reparto: las veinticinco preguntas de rima
-- que ya ofrecen una lista pasan a ofrecer además la salida para escribir la que se haya visto.
-- **No se crea ninguna opción, no se crea ningún esquema y no se toca ninguna respuesta.** El editor
-- sigue viendo exactamente lo mismo, con un campo debajo.
--
-- Va en una sola migración y no en veintidós porque no afirma nada del corpus: es la consecuencia
-- directa de la regla 2 de [criterios de nivel § 3.3](../../docs/dominio-metrico/criterios-de-nivel.md)
-- —donde la norma acota un repertorio, el control es `opciones_y_esquema`— aplicada sin excepción a
-- todas las que lo cumplen. Las que quedan fuera se resuelven forma por forma, porque cada una sí
-- afirma algo.
--
-- Las veintidós arquitecturas: copla de arte mayor, copla manriqueña, copla real (2), cuarteto,
-- cuarteto-lira, décima-lira, endecha real, novena (4), octava-lira, pareado, quintilla (3),
-- redondilla (3), soneto (2), terceto endecasilábico y villancico (2).
--
-- **Y no era solo cambiar una columna.** El primer intento de esta migración movió los veinticinco
-- grupos y se paró en su propia guarda: los veinticinco habían quedado sin lista. La razón es que
-- `opciones_eleccion_metrica` **no es una tabla sino una vista** sobre `opciones_eleccion_derivadas()`,
-- que deriva las opciones del catálogo y filtra por `g.tipo_control = 'opciones'` en **seis ramas**
-- —rima, medida por conjunto, medida por posición, rasgo, repetición y combinación—. Con el control
-- nuevo, las 491 opciones vivas pasaban a 392: las de la rima desaparecían enteras.
--
-- Así que la función se reescribe primero, admitiendo los dos controles que ofrecen lista, y solo
-- después se mueven los grupos. Es la regla dura del proyecto en acción: **ningún documento vale
-- hasta comprobarlo contra la base**, y la comprobación es contar las opciones antes y después.
--
-- *Por qué es seguro sobre dato vivo.* La respuesta guardada no apunta al grupo sino al esquema
-- elegido —`elecciones_editor_metrico` lo dice desde que se separó de las opciones—, así que cambiar
-- cómo se pregunta no toca lo respondido. Y el disparador exige que estos grupos admitan una sola
-- respuesta: las veinticinco la admiten, y la guarda lo comprueba antes de mover nada.

begin;

do $$
declare
	v_esperados integer;
	v_movidos integer;
	v_n integer;
	v_opciones_antes integer;
	v_opciones_despues integer;
	v_respuestas_antes integer;
	v_respuestas_despues integer;
begin
	-- Lo que hay, y que es lo que la cabecera describe.
	select count(*) into v_esperados
	from public.grupos_eleccion_metrica
	where dimension = 'rima' and tipo_control = 'opciones' and activo;
	if v_esperados <> 25 then
		raise exception 'Hay % preguntas de rima con lista, y se esperaban 25.', v_esperados;
	end if;

	-- El disparador exige una sola respuesta. Si alguna admitiera varias, esta migración la
	-- rompería, así que se para antes en vez de descubrirlo a mitad.
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where dimension = 'rima' and tipo_control = 'opciones' and activo and selecciones_max <> 1;
	if v_n <> 0 then
		raise exception '% preguntas de rima admiten más de una respuesta y no pueden llevar salida abierta.', v_n;
	end if;

	-- La función que se va a reescribir es la que se espera: seis ramas, todas atadas al control
	-- antiguo. Si ya la hubiera tocado alguien, esta migración sobra y conviene saberlo.
	select count(*) into v_n
	from pg_proc
	where proname = 'opciones_eleccion_derivadas'
		and prosrc like '%tipo_control = ''opciones''%';
	if v_n <> 1 then
		raise exception 'La derivación de opciones no es la esperada.';
	end if;

	select count(*) into v_opciones_antes from public.opciones_eleccion_metrica where activo;
	select count(*) into v_respuestas_antes from public.elecciones_editor_metrico;

	-- ------------------------------------------- Primero, de dónde salen las opciones
	-- Seis ramas, y las seis atadas al control antiguo. Se reescriben admitiendo los dos que
	-- ofrecen lista. La función se copia del catálogo vivo y solo se cambia esa condición: no hay
	-- nada más que tocar aquí, y transcribirla a mano sería inventar diferencias.
	CREATE OR REPLACE FUNCTION public.opciones_eleccion_derivadas()
	 RETURNS TABLE(grupo_eleccion_id uuid, etiqueta text, descripcion text, metro_id uuid, esquema_metrico_id uuid, esquema_rima_id uuid, seccion_id uuid, repeticion_id uuid, valor_rasgo_id uuid, variedad_id uuid, posicion_unidad integer, materializa_seccion_id uuid, extension_desde_seccion_id uuid, orden integer)
	 LANGUAGE sql
	 STABLE
	 SET search_path TO 'public'
	AS $derivadas$
		-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
		-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
		select g.grupo_eleccion_id,
			-- El régimen entra en la etiqueta cuando la arquitectura no declara uno solo: si sus
			-- disposiciones varían, es lo que las distingue, y sin él el pareado ofrecía dos opciones
			-- llamadas «aa». Es la misma regla que la ficha pública aplica a cada fila de rima.
			concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''),
				case when a.tipo_rima_id is null then (
					select tr.etiqueta from public.vocabularios tr where tr.termino_id = er.tipo_rima_id
				) end)::text,
			er.descripcion,
			null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
			null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by er.notacion, er.slug)::integer
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_rima er
			on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
		where g.dimension = 'rima' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and er.tipo_secuencia not in ('abierta', 'restricciones')
			and er.seccion_id is not distinct from g.seccion_tratada_id

		union all

		select g.grupo_eleccion_id,
			case when pos.posicion is null then adm.nombre
				else 'Verso ' || pos.posicion || ' · ' || adm.nombre end::text,
			null::text,
			adm.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, pos.posicion, null::uuid, null::uuid,
			row_number() over (
				partition by g.grupo_eleccion_id order by pos.posicion, adm.silabas
			)::integer
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join lateral (
			select eo.metro_id, mt.silabas, mt.nombre
			from public.esquema_metrico_opciones eo
			join public.metros mt on mt.metro_id = eo.metro_id
			where eo.esquema_metrico_id = em.esquema_metrico_id
				and (
					not exists (
						select 1 from public.esquema_metrico_opciones e2
						where e2.esquema_metrico_id = em.esquema_metrico_id and e2.rol is not null
					)
					or eo.rol = 'quebrado'
				)
		) adm on true
		join lateral (
			select case when em.medida_uniforme then null::integer else n end as posicion
			from generate_series(
				1,
				case when em.medida_uniforme then 1
					else coalesce(
						s.versos_max,
						(
							select sum(h.versos_max)::integer
							from public.estructuras_secciones h
							where h.seccion_padre_id = s.seccion_id
						),
						a.unidad_versos_max,
						1
					) end
			) as n
		) pos on true
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is not null

		union all

		select g.grupo_eleccion_id,
			('Verso ' || p.posicion || ' · ' || mt.nombre)::text,
			null::text,
			p.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
			p.alternativa::integer
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
		join public.metros mt on mt.metro_id = p.metro_id
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is null
			and p.posicion in (
				select p2.posicion from public.esquema_metrico_posiciones p2
				where p2.esquema_metrico_id = em.esquema_metrico_id
				group by p2.posicion having count(distinct p2.metro_id) > 1
			)

		union all

		select g.grupo_eleccion_id,
			case when adm.valores = 1 then r.nombre else adm.nombre end::text,
			adm.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
		from public.grupos_eleccion_metrica g
		join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
		join lateral (
			select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
				rv.descripcion,
				(select count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
					as valores
			from public.arquitectura_rasgos ar
			join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
			where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = g.rasgo_id
				and (ar.valor_id is null or ar.valor_id = rv.valor_id)
		) adm on true
		where g.dimension = 'rasgo' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and g.rasgo_id is not null

		union all

		select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			rp.repeticion_id, null::uuid, null::uuid, null::integer,
			rp.materializa_seccion_id, rp.extension_desde_seccion_id,
			row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.grupos_eleccion_metrica g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.grupos_eleccion_metrica g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$derivadas$
;

	-- ------------------------------------------------------- Y ahora sí, los grupos
	update public.grupos_eleccion_metrica
	set tipo_control = 'opciones_y_esquema'
	where dimension = 'rima' and tipo_control = 'opciones' and activo;
	get diagnostics v_movidos = row_count;

	-- ------------------------------------------------------------------ Comprobaciones
	if v_movidos <> v_esperados then
		raise exception 'Se han movido % preguntas de las % que había.', v_movidos, v_esperados;
	end if;

	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where dimension = 'rima' and tipo_control = 'opciones' and activo;
	if v_n <> 0 then
		raise exception 'Quedan % preguntas de rima sin la salida abierta.', v_n;
	end if;

	-- **La comprobación que faltaba la primera vez.** Ni una opción se pierde por el camino.
	select count(*) into v_opciones_despues from public.opciones_eleccion_metrica where activo;
	if v_opciones_despues <> v_opciones_antes then
		raise exception 'Las opciones vivas han pasado de % a %.', v_opciones_antes, v_opciones_despues;
	end if;

	-- Ninguna pregunta híbrida se queda sin lista: eso sería un abierto mal declarado.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	where g.tipo_control = 'opciones_y_esquema'
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id and o.activo
		);
	if v_n <> 0 then
		raise exception '% preguntas híbridas han quedado sin lista.', v_n;
	end if;

	-- Nada fuera de la rima se ha movido.
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where dimension <> 'rima' and tipo_control <> 'opciones';
	if v_n <> 0 then
		raise exception '% preguntas de otra dimensión llevan un control de esquema.', v_n;
	end if;

	-- Ni una respuesta anotada se ha perdido.
	select count(*) into v_respuestas_despues from public.elecciones_editor_metrico;
	if v_respuestas_despues <> v_respuestas_antes then
		raise exception 'Las respuestas anotadas han pasado de % a %.', v_respuestas_antes, v_respuestas_despues;
	end if;

	-- La vista que el editor lee sigue rotulándolas como lista, no como campo abierto.
	select count(*) into v_n
	from public.grupos_eleccion_metrica_resueltos
	where tipo_control = 'opciones_y_esquema' and nombre like '%Esquema de rima observado%';
	if v_n <> 0 then
		raise exception '% preguntas híbridas se rotulan como si fueran solo campo abierto.', v_n;
	end if;
end $$;

commit;
