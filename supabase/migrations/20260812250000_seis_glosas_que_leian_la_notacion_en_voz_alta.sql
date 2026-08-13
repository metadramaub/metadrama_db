-- Seis glosas que leían la notación en voz alta.
--
-- Primera tanda de la revisión una a una de `esquemas_rima.descripcion` con el IP. Las seis
-- describían en palabras lo que la figura dibuja y acababan repitiendo la propia notación:
--
--   · las tres redondillas abrazadas —el **mismo texto copiado tres veces**, una por medida—,
--     que decían «la primera clase abre y cierra, y encierra dentro un pareado de la segunda»,
--     que es leer `abba`;
--   · tres de los cuatro tercetos del soneto, que terminaban en «de modo que son CDC y DCD»,
--     «: CDC y EDE» y «: CDE y CDE» después de haber descrito el dibujo.
--
-- La cuarta disposición de tercetos, `cdedce`, se decide aparte, y las de los cuartetos se
-- quedan: dicen cuál es la normal y qué observaron Morley y Bruerton.

do $$
declare
	vaciadas integer;
begin
	with objetivo(forma_slug, arquitectura_slug, esquema_slug) as (values
		('redondilla', 'octosilabica', 'abba'),
		('redondilla', 'heptasilabica', 'abba'),
		('redondilla', 'hexasilabica', 'abba'),
		('soneto', 'endecasilabica_consonante', 'cdcdcd'),
		('soneto', 'endecasilabica_consonante', 'cdcede'),
		('soneto', 'endecasilabica_consonante', 'cdecde')
	)
	update public.esquemas_rima er
	set descripcion = null, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	where er.arquitectura_id = a.arquitectura_id and er.slug = o.esquema_slug
		and er.descripcion is not null;

	get diagnostics vaciadas = row_count;
	if vaciadas <> 6 then
		raise exception 'se esperaban seis glosas y se vaciaron %', vaciadas;
	end if;
end;
$$;

do $$
declare
	quedan integer;
begin
	-- Lo que no entraba en la tanda tiene que seguir donde estaba: la de los cuartetos abrazados
	-- —que cita a Morley y Bruerton— y la cuarta disposición de tercetos, aún sin decidir.
	select count(*) into quedan
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'soneto' and er.slug in ('abbaabba', 'cdedce')
		and er.descripcion is not null;
	if quedan <> 2 then
		raise exception 'las dos glosas del soneto que se quedaban son %, y deberían ser 2', quedan;
	end if;
end;
$$;
