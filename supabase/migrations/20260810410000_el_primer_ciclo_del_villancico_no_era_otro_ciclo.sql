-- El primer ciclo del villancico no era otro ciclo.
--
-- La arquitectura de estribillo posterior tenía **el doble de estructura que la de estribillo
-- inicial para decir lo mismo**: diez secciones y ocho preguntas frente a seis y cinco. Las cuatro
-- secciones y las tres preguntas de más eran una copia del ciclo, hecha para poder decir que el
-- primero es distinto de los demás.
--
-- Y al compararlas campo a campo, tres de las cinco parejas **no decían nada distinto**:
-- `mudanza_inicial` y `mudanza` son las dos de 4 a 4 versos y comparten la nota palabra por
-- palabra; `enlace_vuelta_inicial` y `enlace_vuelta`, lo mismo; `copla_inicial` y `copla` solo se
-- separaban en la nota.
--
-- POR QUÉ EXISTÍA. Partir el árbol era la única manera de decir «la primera vez es distinta»
-- cuando no se podía hablar de apariciones. Desde `20260810390000` sí se puede: una pregunta se
-- responde en cada realización de su sección, y cuál es la primera sale del orden. La copia
-- dejó de hacer falta el mismo día en que se pudo preguntar por aparición.
--
-- QUEDA UN CICLO, de 1 a ∞, con su copla —su mudanza y su enlace— y su estribillo. La primera
-- aparición es la primera porque es la primera.
--
-- LO QUE SE PIERDE, Y VA ANOTADO. La estructura decía que el estribillo es obligatorio en el
-- primer ciclo (1-1) y opcional después (0-1). Con un solo ciclo no cabe distinguirlo, y queda en
-- 0-1. Nada lo validaba de todos modos, y desde ahora quien lo dice es la respuesta por aparición.
--
-- LAS DOS ARQUITECTURAS SE MANTIENEN. Que la diferencia entre ellas —dónde aparece el estribillo
-- por primera vez— pueda resolverse con una pregunta dentro de una sola arquitectura queda abierto,
-- porque el demarcador distingue por arquitectura y las fuentes presentan la cabeza inicial como el
-- modelo del villancico.
--
-- EL ORDEN IMPORTA. `repeticiones_metricas.extension_desde_seccion_id` borra en cascada, así que
-- borrar la sección del estribillo se llevaría por delante la repetición «se repite entero». Se
-- repunta antes de borrar, y una guarda comprueba que las once repeticiones siguen ahí.

begin;

do $$
declare
	v_arq uuid;
	v_estribillo_viejo uuid;
	v_estribillo uuid;
	v_primer_ciclo uuid;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and a.slug = 'estribillo_tras_primera_copla';

	select seccion_id into v_estribillo_viejo
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'estribillo';
	select seccion_id into v_estribillo
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'represa';
	select seccion_id into v_primer_ciclo
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'primer_ciclo';

	if v_estribillo_viejo is null or v_estribillo is null or v_primer_ciclo is null then
		raise exception 'No se encontraron las secciones del villancico posterior';
	end if;

	-- 1 · Lo que apuntaba a la primera aparición pasa a apuntar a la que queda.
	update public.repeticiones_metricas
	set extension_desde_seccion_id = v_estribillo, updated_at = now()
	where extension_desde_seccion_id = v_estribillo_viejo;

	update public.grupos_eleccion_metrica
	set seccion_id = v_estribillo, updated_at = now()
	where seccion_id = v_estribillo_viejo;

	-- 2 · Las tres preguntas duplicadas se van. Sus gemelas preguntan lo mismo.
	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq
		and slug in ('medida_mudanza_inicial', 'medida_enlace_vuelta_inicial', 'rima_primera_mudanza');

	-- 3 · Y el primer ciclo entero, que arrastra en cascada su copla, su mudanza, su enlace y la
	--     primera aparición del estribillo.
	delete from public.estructuras_secciones where seccion_id = v_primer_ciclo;

	-- 4 · El ciclo que queda pasa a ser el primero y deja de ser opcional.
	update public.estructuras_secciones
	set orden = 1,
		repeticiones_min = 1,
		nota = 'Unidad repetible formada por una copla y el estribillo que la sigue.',
		updated_at = now()
	where arquitectura_id = v_arq and slug = 'ciclo_copla';

	-- 5 · Y el estribillo se llama estribillo, no «represa»: es la misma sección en cada ciclo, y
	--     la primera aparición es la primera porque es la primera.
	update public.estructuras_secciones
	set slug = 'estribillo',
		nombre = 'Estribillo',
		nota = 'El estribillo que sigue a cada copla. En el primer ciclo es su primera aparición; en los siguientes, una reaparición que puede ser total, parcial o sobreentendida.',
		updated_at = now()
	where seccion_id = v_estribillo;

	-- 6 · La pregunta de la rima ya no es de «las mudanzas posteriores»: hay una sola mudanza.
	update public.grupos_eleccion_metrica
	set slug = 'rima_mudanza', updated_at = now()
	where arquitectura_id = v_arq and slug = 'rima_mudanzas_posteriores';
end;
$$;

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	-- Las dos arquitecturas quedan con un solo ciclo. No tienen el mismo número de secciones, y es
	-- correcto: la de estribillo inicial lleva la cabeza **fuera** del ciclo, porque precede a todas
	-- las coplas, y otra aparición dentro; la de estribillo posterior tiene una sola, dentro.
	select count(*), string_agg(a.slug || '=' || x.n, ', ' order by a.slug) into v_n, v_mal
	from (
		select s.arquitectura_id, count(*) n
		from public.estructuras_secciones s
		join public.arquitecturas_forma a2 on a2.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f2 on f2.forma_id = a2.forma_id
		where f2.slug = 'villancico'
		group by s.arquitectura_id
	) x
	join public.arquitecturas_forma a on a.arquitectura_id = x.arquitectura_id
	where (a.slug = 'estribillo_inicial' and x.n <> 6)
		or (a.slug = 'estribillo_tras_primera_copla' and x.n <> 5);
	if v_n <> 0 then
		raise exception '% arquitecturas del villancico con secciones inesperadas: %', v_n, v_mal;
	end if;

	-- Y ninguna tiene ya dos secciones de la misma clase colgando del mismo sitio, que era la copia.
	select count(*), string_agg(a.slug || '·' || x.tipo_seccion, ', ') into v_n, v_mal
	from (
		select s.arquitectura_id, s.seccion_padre_id, s.tipo_seccion, count(*) n
		from public.estructuras_secciones s
		join public.arquitecturas_forma a2 on a2.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f2 on f2.forma_id = a2.forma_id
		where f2.slug = 'villancico'
		group by 1, 2, 3
		having count(*) > 1
	) x
	join public.arquitecturas_forma a on a.arquitectura_id = x.arquitectura_id;
	if v_n <> 0 then
		raise exception '% clases de sección siguen duplicadas bajo el mismo padre: %', v_n, v_mal;
	end if;

	select count(*), string_agg(a.slug || '=' || x.n, ', ' order by a.slug) into v_n, v_mal
	from (
		select g.arquitectura_id, count(*) n
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a2 on a2.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f2 on f2.forma_id = a2.forma_id
		where f2.slug = 'villancico'
		group by g.arquitectura_id
	) x
	join public.arquitecturas_forma a on a.arquitectura_id = x.arquitectura_id
	where x.n <> 5;
	if v_n <> 0 then
		raise exception '% arquitecturas del villancico no tienen cinco preguntas: %', v_n, v_mal;
	end if;

	-- No queda ninguna sección «inicial» en el villancico.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and s.slug like '%_inicial';
	if v_n <> 0 then
		raise exception 'Quedan % secciones «inicial» en el villancico', v_n;
	end if;

	-- La cascada no se llevó ninguna repetición: siguen siendo once, y la que dependía de la
	-- sección borrada conserva su extensión.
	select count(*) into v_n from public.repeticiones_metricas;
	if v_n <> 11 then
		raise exception 'Las repeticiones son % en vez de 11', v_n;
	end if;

	-- Las tres «se repite entero» siguen tomando su extensión de un estribillo. Se compara por
	-- tipo y no por slug: dos de ellas apuntan a la sección que se llama «cabeza», que es el
	-- estribillo en su primera aparición.
	select count(*) into v_n
	from public.repeticiones_metricas r
	join public.estructuras_secciones s on s.seccion_id = r.extension_desde_seccion_id
	where r.slug = 'represa_total' and s.tipo_seccion = 'estribillo';
	if v_n <> 3 then
		raise exception '% represas totales toman su extensión de un estribillo en vez de 3', v_n;
	end if;

	-- El invariante de siempre: ninguna pregunta activa se queda sin opciones.
	select count(*), string_agg(g.slug, ', ' order by g.slug) into v_n, v_mal
	from public.grupos_eleccion_metrica g
	where g.tipo_control = 'opciones' and g.activo
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		);
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin opciones: %', v_n, v_mal;
	end if;

	-- Y la ficha del villancico sale entera.
	-- La ficha trae exactamente las secciones que hay en la base, sin escribir aquí el número:
	-- una cifra a mano en una guarda es otra cosa que se queda vieja.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and a.activo;

	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if coalesce(jsonb_array_length(v_json -> 'secciones'), 0) <> v_n then
		raise exception 'La ficha del villancico trae % secciones y la base tiene %',
			coalesce(jsonb_array_length(v_json -> 'secciones'), 0), v_n;
	end if;

	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ? 'sections') then
		raise exception 'El catálogo del demarcador salió sin secciones';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
