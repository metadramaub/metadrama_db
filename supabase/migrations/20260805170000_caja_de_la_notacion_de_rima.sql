-- La caja de la notación de rima dice el arte del verso, y hay que respetarla.
--
-- En métrica española la mayúscula marca arte mayor y la minúscula arte menor. No es
-- decoración: `aA` son un heptasílabo y un endecasílabo que riman, y escribirlo `AA` pierde
-- la mitad de lo que dice.
--
-- 1 · Se deshace un error de la migración anterior. Bajar los slugs de las variedades del
--     sexteto-lira a minúsculas dejó `a1_ababcc`, `a2_ababcc` y `a3_ababcc` idénticos: la
--     caja era lo único que separaba `aBaBcC` de `AbaBcC` y de `abaBcC`. Se reconstruyen
--     desde el nombre, que sí la conservó. La convención de slug en minúsculas vale para el
--     texto descriptivo; una notación de rima es otra cosa y conserva su caja.
--
-- 2 · Tres esquemas tenían la caja equivocada, comprobado contra la medida de cada posición:
--
--     · Canción petrarquista, `ABCABC:CDEEDFF` sobre 7-7-11-7-7-11-7-7-7-7-11-7-11. Nueve de
--       sus trece posiciones son heptasílabas y estaban en mayúscula. La forma correcta es
--       `abCabC:cdeeDfF`, que es justo lo que decía el término legado del que salió,
--       `cancion_regular_abCabC_cdeeDfF`: la caja se perdió al normalizar.
--     · Endecha real, `-a-a` sobre 7-7-7-11. El cuarto verso es endecasílabo: `-a-A`.
--     · Romance endecasílabo, `[-a]…`. Es el romance heroico: `[-A]…`. Sus hermanos
--       hexasílabo, heptasílabo y octosílabo son arte menor y se quedan como están.

begin;

do $$
declare
	v_slugs integer;
	v_mal integer;
begin
	-- 1 · Reconstruir los slugs de variedad desde el nombre, que conservó la caja.
	--     «A1 · aBaBcC» → `a1_aBaBcC`
	update public.variedades_arquitectura v
	set slug = lower(split_part(v.nombre, ' · ', 1)) || '_' || split_part(v.nombre, ' · ', 2)
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where a.arquitectura_id = v.arquitectura_id
		and f.slug = 'sexteto_lira'
		and split_part(v.nombre, ' · ', 2) <> '';
	get diagnostics v_slugs = row_count;

	if exists (
		select 1
		from public.variedades_arquitectura v
		join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id
		group by a.arquitectura_id, v.slug
		having count(*) > 1
	) then
		raise exception 'Dos variedades de una misma arquitectura comparten slug';
	end if;

	-- 2 · Corregir la caja donde contradice la medida.
	update public.esquemas_rima set notacion = 'abCabC:cdeeDfF'
	where notacion = 'ABCABC:CDEEDFF';

	update public.esquemas_rima set notacion = '-a-A'
	where notacion = '-a-a'
		and arquitectura_id in (
			select a.arquitectura_id from public.arquitecturas_forma a
			join public.formas_metricas f on f.forma_id = a.forma_id
			where f.slug = 'endecha_real'
		);

	update public.esquemas_rima set notacion = '[-A]…'
	where notacion = '[-a]…'
		and arquitectura_id in (
			select a.arquitectura_id from public.arquitecturas_forma a
			join public.formas_metricas f on f.forma_id = a.forma_id
			where f.slug = 'romance' and a.slug = 'endecasilabica'
		);

	raise notice 'Slugs de variedad reconstruidos con su caja: %', v_slugs;

	-- Comprobación general, pero solo donde la caja está determinada: una arquitectura con un
	-- único esquema métrico. Cuando tiene varios —el sexteto-lira tiene cinco, M1 a M5—, la
	-- rima es independiente del metro y la caja no se decide hasta combinarlos en una
	-- variedad; comprobarla en el esquema cruzaría todas las medidas contra todas las rimas.
	with simbolos as (
		select
			er.esquema_rima_id,
			er.arquitectura_id,
			s.ord,
			s.simbolo
		from public.esquemas_rima er
		cross join lateral (
			select ord, simbolo
			from regexp_matches(er.notacion, '([A-Za-z-])', 'g') with ordinality as t(m, ord),
				lateral (select m[1] as simbolo) x
		) s
		where er.notacion is not null
	),
	arquitecturas_de_un_solo_metro as (
		select arquitectura_id
		from public.esquemas_metricos
		group by arquitectura_id
		having count(*) = 1
	),
	medidas as (
		select
			em.arquitectura_id,
			p.posicion,
			m.silabas,
			count(*) over (partition by em.arquitectura_id) as total
		from public.esquema_metrico_posiciones p
		join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id
		join public.metros m on m.metro_id = p.metro_id
		join arquitecturas_de_un_solo_metro u on u.arquitectura_id = em.arquitectura_id
		where p.alternativa = 1
	)
	select count(*) into v_mal
	from simbolos s
	join medidas d
		on d.arquitectura_id = s.arquitectura_id
		and (d.total = 1 or d.posicion = s.ord)
	where s.simbolo <> '-'
		and (d.silabas >= 9) <> (s.simbolo = upper(s.simbolo));

	if v_mal > 0 then
		raise exception 'Quedan % posiciones con la caja contraria a su medida', v_mal;
	end if;

	-- Donde la arquitectura tiene varios esquemas métricos, la caja se comprueba en la
	-- variedad, que es la que fija metro y rima a la vez.
	with simbolos as (
		select v.variedad_id, v.esquema_metrico_id, s.ord, s.simbolo
		from public.variedades_arquitectura v
		cross join lateral (
			select ord, m[1] as simbolo
			from regexp_matches(split_part(v.nombre, ' · ', 2), '([A-Za-z-])', 'g')
				with ordinality as t(m, ord)
		) s
		where split_part(v.nombre, ' · ', 2) <> ''
	)
	select count(*) into v_mal
	from simbolos s
	join public.esquema_metrico_posiciones p
		on p.esquema_metrico_id = s.esquema_metrico_id
		and p.posicion = s.ord
		and p.alternativa = 1
	join public.metros m on m.metro_id = p.metro_id
	where s.simbolo <> '-'
		and (m.silabas >= 9) <> (s.simbolo = upper(s.simbolo));

	if v_mal > 0 then
		raise exception 'Quedan % posiciones de variedad con la caja contraria a su medida', v_mal;
	end if;
end $$;

comment on column public.variedades_arquitectura.slug is
	'Minúsculas y sin tildes en la parte descriptiva, pero **la notación de rima conserva su caja**: la mayúscula marca arte mayor y la minúscula arte menor, y perderla borra la mitad de lo que dice.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
