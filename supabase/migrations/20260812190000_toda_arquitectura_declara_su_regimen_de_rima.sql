-- Toda arquitectura declara su régimen de rima, en el nivel que le corresponde.
--
-- Al enseñar por fin el tipo de rima en la ficha salió que ocho arquitecturas no lo declaraban.
-- Mirándolo de cerca no eran ocho huecos: `esquemas_rima` **también** lo declara, y en 81 de 87
-- lo tiene. El régimen vive en dos niveles y cada forma lo pone donde le toca:
--
--   · en la **arquitectura**, cuando su régimen es uno;
--   · en la **disposición**, cuando dentro de la arquitectura varía.
--
-- Dos de los ocho estaban bien callados: el villancico admite `abba` y `abab` consonantes junto
-- a la asonantada `abcb` —Navarro Tomás registra las tres—, y la canción sin rima tiene el cuerpo
-- sin rimar y un pareado final consonante. Reducir eso a un valor sería falsearlo.
--
-- Los seis restantes sí faltaban, y esta migración los declara con la fuente delante:
--
--   · **Redondilla heptasílaba y hexasílaba → consonante.** Jauralde registra las tres medidas
--     como la misma estrofa y Morley y Bruerton la dan «ocasionalmente de seis o siete sílabas».
--     Sus cuatro esquemas ya eran consonantes.
--   · **Endecha real hexasílaba → asonante.** Navarro Tomás § 207: «se generalizó la forma
--     asonantada a manera de romance, abcB dBeB».
--   · **Endecasílabo suelto → sin rima.** Morley y Bruerton lo definen como «endecasílabos sin
--     rima»; Domínguez Caparrós (2014, p. 232) como la silva «en la que ninguno de los versos de
--     la serie lleva rima». Que admita consonancias esporádicas es cosa del rasgo de densidad.
--   · **Endecha real de cinco versos → consonante.** Navarro Tomás § 207 describe la variedad de
--     sor Juana como «una **redondilla** heptasílaba seguida por un endecasílabo, abbaA», y él
--     reserva ese término para la consonante: cuando hay sustitución por asonancia lo dice
--     expresamente. Es la única de las seis que no se deduce sola, y la aprobó el IP.
--   · **Las tres disposiciones de la endecha heptasílaba**, que hasta ahora heredaban: la
--     `suelta` **no rima** —§ 207: «Bermúdez y Cervantes habían empleado esta combinación en
--     versos sueltos, abcD»— y por eso las otras dos necesitan decir que sí asuenan.

do $$
declare
	tocadas integer;
begin
	-- Nivel arquitectura: régimen único.
	with correcciones(forma_slug, arquitectura_slug, termino) as (values
		('redondilla', 'heptasilabica', 'consonante'),
		('redondilla', 'hexasilabica', 'consonante'),
		('endecha_real', 'hexasilabica_con_endecasilabo', 'asonante'),
		('endecha_real', 'heptasilabica_con_endecasilabo_de_cinco', 'consonante'),
		('endecasilabo_suelto', 'endecasilabica', 'sin_rima')
	)
	update public.arquitecturas_forma a
	set tipo_rima_id = v.termino_id, updated_at = now()
	from correcciones c
	join public.formas_metricas f on f.slug = c.forma_slug
	join public.vocabularios v on v.termino = c.termino and v.categoria = 'tipo_rima'
	where a.forma_id = f.forma_id and a.slug = c.arquitectura_slug and a.tipo_rima_id is null;
	get diagnostics tocadas = row_count;
	if tocadas <> 5 then
		raise exception 'se esperaban 5 arquitecturas por declarar y se actualizaron %', tocadas;
	end if;

	-- Nivel disposición: dentro de la endecha heptasílaba el régimen varía, así que las tres lo
	-- dicen. La `suelta` es la razón: sin ella bastaría con la arquitectura.
	with correcciones(forma_slug, arquitectura_slug, esquema_slug, termino) as (values
		('endecha_real', 'heptasilabica_con_endecasilabo', 'suelta', 'sin_rima'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'cruzada', 'asonante'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'abrazada', 'asonante'),
		('endecha_real', 'hexasilabica_con_endecasilabo', 'asonantada', 'asonante'),
		('endecha_real', 'heptasilabica_con_endecasilabo_de_cinco', 'redondilla_con_endecasilabo', 'consonante'),
		('endecasilabo_suelto', 'endecasilabica', 'versos-sueltos', 'sin_rima')
	)
	update public.esquemas_rima er
	set tipo_rima_id = v.termino_id, updated_at = now()
	from correcciones c
	join public.formas_metricas f on f.slug = c.forma_slug
	join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.slug = c.arquitectura_slug
	join public.vocabularios v on v.termino = c.termino and v.categoria = 'tipo_rima'
	where er.arquitectura_id = a.arquitectura_id
		and er.slug = c.esquema_slug
		and er.tipo_rima_id is null;
	get diagnostics tocadas = row_count;
	if tocadas <> 6 then
		raise exception 'se esperaban 6 disposiciones por declarar y se actualizaron %', tocadas;
	end if;
end;
$$;

-- La guarda es el criterio entero, no las once filas que se acaban de tocar: **ninguna
-- arquitectura activa puede quedarse sin régimen de rima en los dos niveles a la vez**. Es lo
-- que a partir de ahora comprueba también `D15` de `npm run audit:metrica`.
do $$
declare
	huerfana record;
begin
	select f.slug as forma, a.slug as arquitectura
	into huerfana
	from public.formas_metricas f
	join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.activo
	where f.activo
		and a.tipo_rima_id is null
		and exists (select 1 from public.esquemas_rima er where er.arquitectura_id = a.arquitectura_id)
		and exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = a.arquitectura_id and er.tipo_rima_id is null
		)
	limit 1;

	if found then
		raise exception 'la arquitectura %/% no declara su régimen de rima ni arriba ni en todas sus disposiciones',
			huerfana.forma, huerfana.arquitectura;
	end if;
end;
$$;
