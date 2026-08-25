-- La vuelta del villancico declara su medida
--
-- B7, y es un descuido de una línea. Al partir «Enlace o vuelta» en dos el 21 de agosto de 2026
-- (`20260821090000`), la sección `enlace` se obtuvo **transformando** la que existía —y conservó su
-- `esquema_metrico_id`— mientras que la `vuelta` se **insertó nueva**, sin él. Sus cuatro hermanas
-- —cabeza, mudanza, enlace y represa— apuntan a `conjunto-6-8`.
--
-- Que es descuido y no decisión lo prueba el zéjel: su vuelta, que no se tocó ese día, **sí** lo
-- declara.
--
-- **No afecta al formulario**, y por eso no se vio: la medida de la vuelta la pregunta su propio
-- grupo `medida_vuelta`, que deriva sus opciones del esquema de la arquitectura y no de la sección.
-- Lo que sí queda mal es todo lo que lee la sección —la rejilla, el recuadro de la norma del editor
-- y la ficha pública—, donde la vuelta sale sin medida mientras el resto de la copla la tiene.

begin;

do $$
declare
	v_forma uuid;
	v_esquema uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'villancico' and activo;
	if v_forma is null then
		raise exception 'El villancico no está activo.';
	end if;

	-- Las dos vueltas están hoy sin esquema, y sus hermanas con él. Si alguien lo arregló antes,
	-- esta migración sobra y conviene saberlo.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.slug = 'vuelta' and s.esquema_metrico_id is null;
	if v_n <> 2 then
		raise exception '% vueltas del villancico están sin esquema métrico, y se esperaban 2.', v_n;
	end if;

	-- Se toma el esquema de la propia arquitectura, que es el que declaran las hermanas: no se
	-- inventa uno ni se copia el de otra forma.
	for v_esquema in
		select a.arquitectura_id from public.arquitecturas_forma a
		where a.forma_id = v_forma and a.activo
	loop
		update public.estructuras_secciones s
		set esquema_metrico_id = (
			select hermana.esquema_metrico_id
			from public.estructuras_secciones hermana
			where hermana.arquitectura_id = v_esquema
				and hermana.slug = 'mudanza'
				and hermana.esquema_metrico_id is not null
		)
		where s.arquitectura_id = v_esquema and s.slug = 'vuelta';
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.slug = 'vuelta' and s.esquema_metrico_id is null;
	if v_n <> 0 then
		raise exception 'Quedan % vueltas sin esquema métrico.', v_n;
	end if;

	-- Y apuntan al mismo que sus hermanas, no a otro cualquiera.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.esquemas_metricos em on em.esquema_metrico_id = s.esquema_metrico_id
	where a.forma_id = v_forma and s.slug = 'vuelta' and em.arquitectura_id = a.arquitectura_id;
	if v_n <> 2 then
		raise exception 'Solo % vueltas apuntan al esquema de su propia arquitectura.', v_n;
	end if;

	-- Ninguna parte de la copla se queda ya sin medida, que es lo que se venía a arreglar.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and a.activo
		and s.slug in ('cabeza', 'estribillo', 'mudanza', 'enlace', 'vuelta', 'represa')
		and s.esquema_metrico_id is null;
	if v_n <> 0 then
		raise exception '% partes del villancico siguen sin medida.', v_n;
	end if;

	if public.get_forma_metrica_publica('villancico') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del villancico ha dejado de responder.';
	end if;
end $$;

commit;
