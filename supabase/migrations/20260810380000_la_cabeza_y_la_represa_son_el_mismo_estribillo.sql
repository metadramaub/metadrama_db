-- La cabeza y la represa son el mismo estribillo.
--
-- El villancico tenía tres tipos de sección para una sola cosa. `cabeza` es «la primera aparición
-- del estribillo cuando ocupa la posición inicial»; `estribillo`, la primera aparición cuando va
-- detrás de la primera copla; `represa`, la reaparición. **Es el mismo contenido las tres veces**,
-- y lo que las separaba —dónde aparece— es ya lo que separa a las dos arquitecturas del villancico.
--
-- El IP lo confirmó el 10 de agosto de 2026: bajo las denominaciones son exactamente lo mismo, y
-- por eso la interfaz no dice «represa» —término poco conocido— sino «repetición del estribillo».
--
-- SE USA EL MECANISMO QUE YA ESTABA. `tipo_seccion` es la columna que dice que dos secciones son
-- la misma cosa en sitios distintos: `copla_inicial` es de tipo `copla`, `mudanza_inicial` es
-- `mudanza`, `enlace_vuelta_inicial` es `enlace_vuelta` y `terceto_final` es `remate`. Son las
-- cuatro únicas de las 61 en que el slug y el tipo difieren, y son este mismo caso. El slug y el
-- nombre siguen distinguiendo qué aparición es; el tipo dice que el contenido es uno.
--
-- EL ZÉJEL VA CON ÉL. Tiene la misma estructura —cabeza al principio y represa dentro del ciclo de
-- copla— y el mismo argumento le cabe entero; Jauralde lo llama «en realidad, un modo de
-- villancico». Dejarlo fuera crearía la incoherencia que esto viene a quitar.
--
-- LAS EXTENSIONES. La primera aparición del villancico queda en **2-4 versos**, que es lo que fija
-- Domínguez Caparrós en 2014 y 2016; Navarro Tomás recoge estribillos de dos a siete y esa
-- discrepancia queda anotada para el IP. La reaparición conserva un mínimo más bajo **y eso es
-- correcto, no un descuido**: una represa parcial trae solo una parte del estribillo, normalmente
-- sus últimos versos, así que puede tener menos versos que la primera aparición.
--
-- Lo que sí estaba mal es la arquitectura de estribillo posterior, donde las dos secciones eran
-- `1-∞`: sin suelo y sin techo. Se igualan a las de la otra.

begin;

-- 1 · Un solo tipo para el estribillo, en sus dos apariciones y en las dos formas.

update public.estructuras_secciones s
set tipo_seccion = 'estribillo',
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = s.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug in ('villancico', 'zejel')
	and s.tipo_seccion in ('cabeza', 'represa');

-- 2 · La arquitectura de estribillo posterior gana el suelo y el techo de la otra.

update public.estructuras_secciones s
set versos_min = 2,
	versos_max = 4,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = s.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug = 'villancico'
	and a.slug = 'estribillo_tras_primera_copla'
	and s.slug = 'estribillo';

update public.estructuras_secciones s
set versos_min = 1,
	versos_max = 4,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = s.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug = 'villancico'
	and a.slug = 'estribillo_tras_primera_copla'
	and s.slug = 'represa';

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	-- No queda ningún tipo `cabeza` ni `represa` en ninguna forma.
	select count(*), string_agg(distinct tipo_seccion, ', ') into v_n, v_mal
	from public.estructuras_secciones
	where tipo_seccion in ('cabeza', 'represa');
	if v_n <> 0 then
		raise exception 'Quedan % secciones de tipo «%»', v_n, v_mal;
	end if;

	-- Y las tres arquitecturas de estribillo repetido tienen sus dos apariciones, ni más ni menos.
	-- El filtro por forma no sobra: la seguidilla compuesta tiene también una sección de tipo
	-- `estribillo`, que es otro estribillo y aparece una sola vez.
	select count(*), string_agg(a.slug || '=' || x.n, ', ' order by a.slug) into v_n, v_mal
	from (
		select s.arquitectura_id, count(*) n
		from public.estructuras_secciones s
		join public.arquitecturas_forma a2 on a2.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f2 on f2.forma_id = a2.forma_id
		where s.tipo_seccion = 'estribillo' and f2.slug in ('villancico', 'zejel')
		group by s.arquitectura_id
	) x
	join public.arquitecturas_forma a on a.arquitectura_id = x.arquitectura_id
	where x.n <> 2;
	if v_n <> 0 then
		raise exception '% arquitecturas no tienen dos apariciones del estribillo: %', v_n, v_mal;
	end if;

	-- Las extensiones del villancico: la primera aparición 2-4 y la reaparición 1-4, en las dos.
	select count(*), string_agg(a.slug || '·' || s.slug || ' ' || s.versos_min || '-' || s.versos_max, ', ')
	into v_n, v_mal
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and s.tipo_seccion = 'estribillo'
		and not (
			(s.slug in ('cabeza', 'estribillo') and s.versos_min = 2 and s.versos_max = 4)
			or (s.slug = 'represa' and s.versos_min = 1 and s.versos_max = 4)
		);
	if v_n <> 0 then
		raise exception '% secciones del villancico con extensión inesperada: %', v_n, v_mal;
	end if;

	-- Y la ficha de las dos formas sigue saliendo con su árbol entero.
	foreach v_mal in array array['villancico', 'zejel'] loop
		select public.get_forma_metrica_publica_jerarquica(v_mal) into v_json;
		if coalesce(jsonb_array_length(v_json -> 'secciones'), 0) = 0 then
			raise exception 'La ficha de % salió sin secciones', v_mal;
		end if;
	end loop;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
