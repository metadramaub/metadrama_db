-- La cruzada de la endecha cruza de verdad, y admite las dos rimas.
--
-- La disposición `cruzada` de la endecha real guardaba `-a-A`: impares sueltos y una sola clase
-- en los pares. Eso no es cruzar —es lo mismo que hace la `asonantada`, solo que sin pasar al
-- cuarteto siguiente—, y su propia glosa se contradecía al citar `abaB` como notación de las
-- fuentes.
--
-- El **Diccionario de métrica española** de Domínguez Caparrós, entrada «endecha real», lo dice
-- sin ambigüedad: «Riman en asonante los versos pares. El verso endecasílabo puede ocupar otro
-- lugar; y pueden rimar, **en consonante o en asonante, los versos pares, por un lado, y los
-- impares, por otro**». Los pares por un lado y los impares por otro son dos clases: `abaB`.
-- Navarro Tomás § 207 da la abrazada y la asonantada pero no una cruzada; Jauralde la cuenta
-- entre las variaciones «de todo tipo» que admitió la forma; Quilis no registra la endecha real.
--
-- Se corrigen las posiciones y, como el Diccionario admite los dos regímenes, la cruzada se
-- desdobla en dos disposiciones con la misma notación —igual que el pareado, que ya tiene su
-- `aa-asonante` y su `aa-consonante`—: la asonante queda como admitida, por ser la de la forma,
-- y la consonante entra como excepcional.

do $$
declare
	endecha_arq uuid;
	cruzada_id uuid;
	nueva_id uuid;
	consonante uuid;
	tocadas integer;
begin
	select a.arquitectura_id into endecha_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo';

	select esquema_rima_id into cruzada_id
	from public.esquemas_rima where arquitectura_id = endecha_arq and slug = 'cruzada';
	if cruzada_id is null then
		raise exception 'no se encontró la disposición cruzada de la endecha real';
	end if;

	select termino_id into consonante
	from public.vocabularios where categoria = 'tipo_rima' and termino = 'consonante';

	-- 1 · Los impares no quedan sueltos: comparten su propia clase. Las posiciones **no se tocan
	--     a mano**: `esquemas_rima_sincronizar_posiciones_fijas` las regenera desde la notación,
	--     que es justamente lo que garantiza que las dos digan lo mismo (D14).
	update public.esquemas_rima
	set notacion = 'abaB', nombre = 'Cruzada asonante', updated_at = now()
	where esquema_rima_id = cruzada_id;

	select count(*) into tocadas
	from public.esquema_rima_posiciones where esquema_rima_id = cruzada_id;
	if tocadas <> 4 then
		raise exception 'la cruzada quedó con % posiciones y debería tener cuatro', tocadas;
	end if;

	-- 2 · La misma disposición en consonante, que el Diccionario admite y es lo excepcional.
	insert into public.esquemas_rima
		(arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, estado_revision)
	values (
		endecha_arq, 'cruzada-consonante', 'Cruzada consonante', 'abaB', consonante,
		'excepcional', 'secuencia', 'revisada'
	)
	returning esquema_rima_id into nueva_id;

	select count(*) into tocadas
	from public.esquema_rima_posiciones where esquema_rima_id = nueva_id;
	if tocadas <> 4 then
		raise exception 'la cruzada consonante quedó con % posiciones y debería tener cuatro', tocadas;
	end if;
end;
$$;

-- 3 · La atestación del *Romancero general* es un dato de fuente, no una glosa: estaba en el
--     texto de Navarro Tomás § 207 y no se había registrado. Entra donde le toca, y solo
--     entonces se retira de la descripción del esquema.
do $$
declare
	navarro uuid;
	endecha uuid;
begin
	select fuente_id into navarro from public.fuentes_metricas
	where autoria ilike '%Navarro Tom%' limit 1;
	select forma_id into endecha from public.formas_metricas where slug = 'endecha_real';
	if navarro is null or endecha is null then
		raise exception 'no se encontró la fuente de Navarro Tomás o la endecha real';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where fuente_id = navarro and forma_id = endecha and resumen ilike '%Romancero general%'
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza, estado_revision)
		values (
			navarro, endecha, '§ 207, p. 283',
			'Documenta la disposición abrazada **abbA** como parte final de un romance del *Romancero general*, núm. 414, y recuerda que Jerónimo Bermúdez y Cervantes habían empleado antes la combinación en versos sueltos, abcD.',
			'alta', 'revisada'
		);
	end if;
end;
$$;

-- 4 · Dos glosas que ya no dicen nada propio.
do $$
declare
	vaciadas integer;
	segundas integer;
begin
	-- La de la endecha abrazada describía `abbA` en palabras y citaba el Romancero, que acaba de
	-- entrar como afirmación de fuente.
	update public.esquemas_rima er
	set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo'
		and er.slug = 'abrazada' and er.descripcion is not null;
	get diagnostics vaciadas = row_count;

	-- La del sexteto-lira decía «Tres pareados consecutivos aa bb cc», que es su notación.
	update public.esquemas_rima er
	set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and er.slug = 'aabbcc' and er.descripcion is not null;
	get diagnostics segundas = row_count;
	vaciadas := vaciadas + segundas;

	if vaciadas <> 2 then
		raise exception 'se esperaban dos glosas y se vaciaron %', vaciadas;
	end if;
end;
$$;

-- La guarda ejecuta el criterio de D14 sobre lo que se acaba de tocar: la notación y las clases
-- de las dos cruzadas tienen que decir lo mismo.
do $$
declare
	descuadre text;
begin
	select er.slug into descuadre
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'endecha_real' and er.slug in ('cruzada', 'cruzada-consonante')
		and regexp_replace(er.notacion, '[^a-zA-Z]', '', 'g') <> coalesce((
			select string_agg(p.clase_rima, '' order by p.bloque, p.posicion)
			from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id and p.clase_rima is not null
		), '')
	limit 1;
	if descuadre is not null then
		raise exception 'la notación y las clases no cuadran en %', descuadre;
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where resumen ilike '%Romancero general%'
	) then
		raise exception 'la atestación del Romancero general no quedó registrada';
	end if;
end;
$$;
