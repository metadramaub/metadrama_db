-- La mudanza del villancico se parece a la redondilla, pero no es una redondilla
--
-- Corrección del vínculo que se acaba de declarar. Se creó como `compuesta_por`, por analogía con
-- la décima y la novena, y el auditor lo rechazó con razón: **cuando una forma declara
-- `compuesta_por`, sus secciones deben reutilizar la arquitectura del componente mediante
-- `arquitectura_referenciada_id`, no copiar sus esquemas** (D8, «Componente copiado en lugar de
-- reutilizado»). Copiar obliga a mantener el repertorio en dos sitios y rompe la comparación.
--
-- Y aquí reutilizar es imposible, por dos razones comprobadas contra la base:
--
-- 1. **La mudanza no tiene una medida fija.** Va en octosílabos o en hexasílabos, y el editor la
--    elige. La redondilla tiene una arquitectura por medida —octosilábica, hexasilábica,
--    heptasilábica— y `arquitectura_referenciada_id` apunta a una sola. No hay ninguna que valga
--    para las dos.
--
-- 2. **La mudanza admite `-a-a`, y ninguna redondilla la admite.** Las tres arquitecturas de la
--    redondilla declaran `abba` y `abab`, las dos consonantes. La disposición asonantada del
--    villancico no es una redondilla: es una cuarteta asonantada, y por eso no está —ni debe
--    estar— en el repertorio de la otra forma.
--
-- Lo que hay entre las dos formas es parecido, no composición: la mudanza del villancico *se
-- organiza como* una redondilla, y en el caso más corriente lo es, pero la forma no está hecha de
-- redondillas del modo en que la décima y la novena sí lo están. `relacionada_con` es el tipo que
-- el catálogo ya usa para esto mismo: `cuarteto` y `terceto_encadenado` se relacionan así con la
-- redondilla. El vínculo se sigue leyendo por los dos extremos y la nota no cambia.

begin;

do $$
declare
	v_forma uuid;
	v_redondilla uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'villancico';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	if v_forma is null or v_redondilla is null then
		raise exception 'Falta el villancico o la redondilla.';
	end if;

	-- Las dos razones por las que no puede ser composición, comprobadas y no supuestas.
	select count(distinct em.esquema_metrico_id) into v_n
	from public.esquema_metrico_opciones o
	join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	where a.forma_id = v_forma;
	if v_n = 0 then
		raise exception 'El villancico ha dejado de ofrecer medida.';
	end if;
	if not exists (
		select 1 from public.esquema_metrico_opciones o
		join public.metros m on m.metro_id = o.metro_id
		join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
		join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
		where a.forma_id = v_forma and m.silabas = 6
	) then
		raise exception 'El villancico ya no admite hexasílabos: revisar este vínculo.';
	end if;

	if exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_redondilla and er.notacion = '-a-a'
	) then
		raise exception 'La redondilla admite ahora la asonantada: revisar este vínculo.';
	end if;

	-- ------------------------------------------------------------ El vínculo, en su tipo
	update public.forma_relaciones set tipo_relacion = 'relacionada_con'
	where forma_origen_id = v_forma and forma_destino_id = v_redondilla
		and tipo_relacion in ('compuesta_por', 'relacionada_con');

	select count(*) into v_n
	from public.forma_relaciones
	where forma_origen_id = v_forma and forma_destino_id = v_redondilla;
	if v_n <> 1 then
		raise exception 'Hay % vínculos del villancico a la redondilla, no uno.', v_n;
	end if;
	if exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and tipo_relacion = 'compuesta_por'
	) then
		raise exception 'El villancico sigue declarándose compuesto de otra forma.';
	end if;

	-- ------------------------------------------------------------------ Comprobación
	foreach v_n in array array[1, 2] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(
					case v_n when 1 then 'villancico' else 'redondilla' end
				) -> 'relaciones'
			) r
			where r ->> 'tipo_relacion' = 'relacionada_con'
				and (r ->> 'nota') like 'La mudanza del villancico%'
		) then
			raise exception 'Una de las dos fichas no recoge el vínculo con su nota.';
		end if;
	end loop;
end $$;

commit;
